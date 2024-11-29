---@class Timber.Actions.Module
--- @field batch TSNode[]
local M = { batch = {} }

local config = require("timber.config")
local highlight = require("timber.highlight")
local watcher = require("timber.watcher")
local buffers = require("timber.buffers")
local treesitter = require("timber.actions.treesitter")
local utils = require("timber.utils")

---@class Timber.Actions.PendingLogStatement The log statements to be inserted
---@field content string The log statement content
---@field row integer The (0-indexed) row number to insert
---@field insert_cursor_offset? integer The offset of the %insert_cursor placeholder if any
---@field log_target? TSNode The log target node
---@field inserted_rows? integer[] The actual row numbers of the inserted log statement. This field only exists when the insert is commited
---@field placeholder_id? string The log placeholder id if any

--- @alias Timber.Actions.LogPosition "above" | "below" | "surround"
--- @alias range {[1]: number, [2]: number, [3]: number, [4]: number}
--- @alias cursor_position {[1]: number, [2]: number}

---@class Timber.Actions.CurrentCommandArgument
---@field insert_log? {[1]: Timber.Actions.InsertLogOptions, [2]: range, [3]: range}
---@field insert_batch_log? {[1]: Timber.Actions.InsertBatchLogOptions, [2]: range?}
---@field add_log_targets_to_batch? {[1]: Timber.Actions.AddLogTargetsToBatchOptions, [2]: range}

---@class Timber.Actions.State
---@field current_command_arguments Timber.Actions.CurrentCommandArgument
---@field current_selection_range {[1]: number, [2]: number, [3]: number, [4]: number}?

---@type Timber.Actions.State
local state = {
  current_command_arguments = {},
  current_selection_range = nil,
}

---@param callback string
local function make_dot_repeatable(callback)
  -- Reset the operatorfunc
  vim.go.operatorfunc = "v:lua.require'timber.utils'.NOOP"
  vim.cmd("normal! g@l")
  vim.go.operatorfunc = "v:lua.require'timber.actions'." .. callback
end

---@param insert_line integer
---@return integer
local function get_current_indent(insert_line)
  -- From the insert line, walk down to find the first non-empty line
  -- Then walk up to find the first non-empty line
  -- Take the maximum of the two indentations
  local before = 0
  local after = 0

  for i = insert_line + 1, vim.fn.line("$"), 1 do
    local line = vim.fn.getline(i)
    if line ~= "" then
      after = vim.fn.indent(i)
      break
    end
  end

  for i = insert_line, 0, -1 do
    local line = vim.fn.getline(i)
    if line ~= "" then
      before = vim.fn.indent(i)
      break
    end
  end

  return math.max(before, after)
end

--- Build the log statement from template. Support special placeholers:
---   %log_target: the identifier text
---   %line_number: the line_number number
---   %insert_cursor: after inserting the log statement, go to insert mode and place the cursor here.
---     If there's multiple log statements, choose the first one
---   %watcher_marker_start and %watcher_marker_end: the start and end markers for timber.watchers
---@alias handler (fun(): string) | string
---@param log_template string
---@param handlers {identifier: handler, line_number: handler}
---@return string resolved_template, Timber.Watcher.LogPlaceholderId? placeholder_id
local function resolve_template_placeholders(log_template, handlers)
  ---@type fun(string): string
  local invoke_handler = function(handler_name)
    local handler = handlers[handler_name]
    if not handler then
      error(string.format("No handler for %s", handler_name))
    end

    if type(handler) == "function" then
      return handler()
    else
      return handler
    end
  end

  if string.find(log_template, "%%log_target") then
    local replacement = invoke_handler("identifier")
    log_template = string.gsub(log_template, "%%log_target", replacement)
  end

  if string.find(log_template, "%%line_number") then
    local replacement = invoke_handler("line_number")
    log_template = string.gsub(log_template, "%%line_number", replacement)
  end

  local placeholder_id
  if string.find(log_template, "%%watcher_marker_start") and string.find(log_template, "%%watcher_marker_end") then
    local start, end_, marker_id = watcher.generate_marker_pairs()
    log_template = string.gsub(log_template, "%%watcher_marker_start", start)
    log_template = string.gsub(log_template, "%%watcher_marker_end", end_)
    placeholder_id = marker_id
  end

  return log_template, placeholder_id
end

---@param statements Timber.Actions.PendingLogStatement[]
---@return Timber.Actions.PendingLogStatement[] after_insert_statements Updated statements after inserting
---@return {[1]: number, [2]: number}? insert_cursor_pos The insert cursor position trigger by %insert_cursor placeholder
local function insert_log_statements(statements)
  local bufnr = vim.api.nvim_get_current_buf()

  statements = utils.array_sort_with_index(statements, function(a, b)
    -- If two statements have the same row, sort by the appearance order of the log target
    local statement_a = a[1]
    local statement_b = b[1]

    if statement_a.row == statement_b.row then
      if not statement_a.log_target or not statement_b.log_target then
        return a[2] < b[2]
      end

      local a_row, a_col = statement_a.log_target:start()
      local b_row, b_col = statement_b.log_target:start()
      return a_row == b_row and a_col < b_col or a_row < b_row
    end

    return statement_a.row < statement_b.row
  end)

  -- Offset the row numbers
  local offset = 0
  local insert_cursor_pos

  for _, statement in ipairs(statements) do
    statement.inserted_rows = {}

    local insert_line = statement.row + offset
    local indentation = get_current_indent(insert_line)
    local lines = utils.process_multiline_string(statement.content)

    for i, line in ipairs(lines) do
      local insert_cursor_offset = string.find(line, "%%insert_cursor")
      if insert_cursor_offset then
        line = string.gsub(line, "%%insert_cursor", "")
        lines[i] = line

        if not insert_cursor_pos then
          insert_cursor_pos = { insert_line + i - 1, insert_cursor_offset }
        end
      end

      lines[i] = string.rep(" ", indentation) .. line
    end

    vim.api.nvim_buf_set_lines(bufnr, insert_line, insert_line, false, lines)

    highlight.highlight_insert(insert_line, insert_line + #lines - 1)
    offset = offset + #lines

    for i = 0, #lines - 1, 1 do
      table.insert(statement.inserted_rows, insert_line + i)
    end
  end

  return statements, insert_cursor_pos
end

---Perform post-insert operations:
---   1. Place the cursor at the insert_cursor placeholder if any
---   2. Move the cursor back to the original position if needed
---   3. Add the log placeholder to the buffer manager
---@param log_statements Timber.Actions.PendingLogStatement[] The log statements after inserted
---@param insert_cursor_pos {[1]: number, [2]: number}?
---@param original_cursor_position range?
local function after_insert_log_statements(log_statements, insert_cursor_pos, original_cursor_position)
  if insert_cursor_pos then
    -- We can't simply set the cursor because the line has been indented
    -- We do it via Vim motion:
    --   1. Jump to the insert line
    --   2. Move to the first character
    --   3. Move left by the offset
    --   4. Go to insert mode
    -- We need to defer because the function is executed in normal mode by g@ operator
    -- After the function is executed, we can go to insert mode
    vim.defer_fn(function()
      vim.cmd(string.format("normal! %dG^%dl", insert_cursor_pos[1] + 1, insert_cursor_pos[2] - 1))
      vim.cmd("startinsert")
    end, 0)
  elseif original_cursor_position then
    -- Move the cursor back to the original position
    -- The inserted lines above the cursor shift the cursor position away. We need to account for that
    local original_row = original_cursor_position[2] - 1
    local inserted_lines = {}
    for _, statement in ipairs(log_statements) do
      vim.list_extend(inserted_lines, statement.inserted_rows)
    end

    for _, line in ipairs(inserted_lines) do
      highlight.highlight_log_statement(line)
    end

    table.sort(inserted_lines, function(a, b)
      return a < b
    end)

    for _, i in ipairs(inserted_lines) do
      local need_to_shift = i <= original_row
      if need_to_shift then
        original_row = original_row + 1
      end
    end

    original_cursor_position[2] = original_row + 1

    -- This is a hack, we run the callback after the current command finish
    vim.defer_fn(function()
      vim.fn.setpos(".", original_cursor_position)
    end, 0)
  end

  -- Add the log placeholder to the buffer manager
  for _, log_statement in ipairs(log_statements) do
    buffers.new_log_placeholder({
      id = log_statement.placeholder_id,
      bufnr = vim.api.nvim_get_current_buf(),
      -- TODO: support multi line log statements
      line = log_statement.inserted_rows[1],
      entries = {},
    })
  end
end

---Group log targets that overlap with each other
---Due to the nature of the AST, if two nodes are overlapping, one must strictly
---include another
---@param log_targets TSNode[]
---@return TSNode[][]
local function group_overlapping_log_targets(log_targets)
  log_targets = treesitter.sort_ts_nodes_preorder(log_targets)

  local groups = {}

  ---@type TSNode[]
  local current_group = {}

  for _, log_target in ipairs(log_targets) do
    if #current_group == 0 then
      table.insert(current_group, log_target)
    else
      -- Check the current node with each node in the current group
      -- If it intersects with any of the node, it belongs to the current group
      -- If it not, move it into a new group
      local insersect_any = utils.array_any(current_group, function(node)
        return utils.ranges_intersect(utils.get_ts_node_range(node), utils.get_ts_node_range(log_target))
      end)

      if insersect_any then
        table.insert(current_group, log_target)
      else
        table.insert(groups, current_group)
        current_group = { log_target }
      end
    end
  end

  if #current_group > 0 then
    table.insert(groups, current_group)
  end

  return groups
end

---Given a group of nodes, pick the "best" node
---We sort the nodes by the selection range and pick the first node which is
---fully included in the selection range
---@param nodes TSNode[]
---@params selection_range {[1]: number, [2]: number, [3]: number, [4]: number}
---@return TSNode
local function pick_biggest_node(nodes, selection_range)
  if #nodes == 0 then
    error("nodes can't be empty")
  end

  if #nodes == 1 then
    return nodes[1]
  end

  nodes = treesitter.sort_ts_nodes_preorder(nodes)

  -- @type TSNode?
  local best_node = utils.array_find(nodes, function(node)
    return utils.range_include(selection_range, utils.get_ts_node_range(node))
  end)

  return best_node or nodes[#nodes]
end

---@param log_targets {log_container: TSNode, logable_range: logable_range?, log_target: TSNode}[]
---@param selection_range range
---@return {log_container: TSNode, logable_range: logable_range?, log_target: TSNode}[]
local function remove_overlapping_log_targets(log_targets, selection_range)
  local lookup_table = {}

  ---@type TSNode[]
  local log_targets_only = {}

  for _, i in ipairs(log_targets) do
    lookup_table[i.log_target:id()] = i
    table.insert(log_targets_only, i.log_target)
  end

  -- For each group, we pick the "biggest" node
  -- A node is the biggest if it contains all other nodes in the group
  local result = {}

  for _, group in ipairs(group_overlapping_log_targets(log_targets_only)) do
    local best = pick_biggest_node(group, selection_range)
    local full_entry = lookup_table[best:id()]
    table.insert(result, full_entry)
  end

  return result
end

---@param lang string
---@param selection_range range
---@return {log_container: TSNode, logable_ranges: logable_range[], log_target: TSNode}[]
local function capture_log_targets(lang, selection_range)
  local log_containers = treesitter.query_log_target_container(lang, selection_range)

  local log_target_grouped_by_container = treesitter.find_log_targets(
    utils.array_map(log_containers, function(i)
      return i.container
    end),
    lang
  )

  local log_targets = {}

  for _, entry in ipairs(log_target_grouped_by_container) do
    -- Filter targets that intersect with the given range
    local _log_targets = utils.array_filter(entry.log_targets, function(node)
      return utils.ranges_intersect(selection_range, utils.get_ts_node_range(node))
    end)

    local log_container = utils.array_find(log_containers, function(i)
      return i.container == entry.container
    end)
    ---@cast log_container -nil

    vim.list_extend(
      log_targets,
      utils.array_map(_log_targets, function(node)
        return {
          log_container = log_container.container,
          logable_ranges = log_container.logable_ranges,
          log_target = node,
        }
      end)
    )
  end

  return remove_overlapping_log_targets(log_targets, selection_range)
end

---@param log_target TSNode
---@param logable_ranges logable_range[]
---@param position Timber.Actions.LogPosition
---@return integer?
local function get_insert_row(log_target, logable_ranges, position)
  table.sort(logable_ranges, function(a, b)
    return a[1] < b[1]
  end)

  local target_row = log_target:start()

  if position == "above" then
    for i = #logable_ranges, 1, -1 do
      local range = logable_ranges[i]
      if range[2] <= target_row then
        return range[2]
      end
    end
  elseif position == "below" then
    for i = 1, #logable_ranges, 1 do
      local range = logable_ranges[i]
      if range[1] > target_row then
        return range[1]
      end
    end
  end
end

---@param log_template string
---@param lang string
---@param position Timber.Actions.LogPosition
---@param selection_range range
---@return Timber.Actions.PendingLogStatement[]
local function build_capture_log_statements(log_template, lang, position, selection_range)
  local to_insert = {}

  for _, entry in ipairs(capture_log_targets(lang, selection_range)) do
    local log_target = entry.log_target
    local logable_ranges = entry.logable_ranges

    local content, placeholder_id = resolve_template_placeholders(log_template, {
      identifier = function()
        local bufnr = vim.api.nvim_get_current_buf()
        return vim.treesitter.get_node_text(log_target, bufnr)
      end,
      line_number = function()
        return tostring(log_target:start() + 1)
      end,
    })

    local insert_row = get_insert_row(log_target, logable_ranges, position)

    if insert_row then
      table.insert(to_insert, {
        content = content,
        row = insert_row,
        insert_cursor_offset = nil,
        log_target = log_target,
        placeholder_id = placeholder_id,
      })
    else
      utils.notify(string.format("No logable ranges %s the log target", position), "warn")
    end
  end

  return to_insert
end

---@param log_template string
---@param position Timber.Actions.LogPosition
---@return Timber.Actions.PendingLogStatement
local function build_non_capture_log_statement(log_template, position)
  local current_line = vim.fn.getpos(".")[2]
  local insert_row = position == "above" and current_line or current_line + 1
  local content, placeholder_id = resolve_template_placeholders(log_template, {
    line_number = tostring(insert_row),
  })

  return {
    content = content,
    -- Minus cause the row is 0-indexed
    row = insert_row - 1,
    insert_cursor_offset = nil,
    placeholder_id = placeholder_id,
  }
end

---@param log_template string
---@param batch TSNode[]
---@param insert_line integer
---@return Timber.Actions.PendingLogStatement
local function build_batch_log_statement(log_template, batch, insert_line)
  local result = log_template

  -- First resolve %repeat placeholders
  while true do
    local start_pos, end_pos, repeat_item_template, separator = string.find(result, "%%repeat<(.-)><(.-)>")

    if not start_pos then
      break
    end

    local repeat_items = utils.array_map(batch, function(log_target)
      return (
        resolve_template_placeholders(repeat_item_template, {
          identifier = function()
            local bufnr = vim.api.nvim_get_current_buf()
            return vim.treesitter.get_node_text(log_target, bufnr)
          end,
          line_number = function()
            return tostring(log_target:start() + 1)
          end,
        })
      )
    end)

    local repeat_items_str = table.concat(repeat_items, separator)

    result = result:sub(1, start_pos - 1) .. repeat_items_str .. result:sub(end_pos + 1)
  end

  -- Then resolve the rest
  local content, placeholder_id = resolve_template_placeholders(result, {
    identifier = function()
      utils.notify("Cannot use %log_target placeholder outside %repeat placeholder", "error")
      return "%log_target"
    end,
    line_number = tostring(insert_line + 1),
  })

  return {
    content = content,
    -- Insert at the line below 0-indexed
    row = insert_line,
    insert_cursor_offset = nil,
    placeholder_id = placeholder_id,
  }
end

function M.__insert_log(motion_type)
  local opts = state.current_command_arguments.insert_log[1]
  local selection_range

  if opts.operator then
    selection_range = utils.get_operator_selection_range(motion_type)
  else
    -- If selection_range or original_cursor_position are nil, it means the user is dot repeating
    selection_range = state.current_command_arguments.insert_log[2] or utils.get_selection_range()
  end

  local original_cursor_position = state.current_command_arguments.insert_log[3] or vim.fn.getpos(".")

  local function build_to_insert(template, position)
    local log_template_lang, lang = config.get_lang_log_template(template, "single")

    if not log_template_lang or not lang then
      return {}
    end

    -- There are two kinds of log statements:
    --   1. Capture log statements: log statements that contain %log_target placeholder
    --     We need to capture the log target in the selection range and replace it
    --   2. Non-capture log statements: log statements that don't contain %log_target placeholder
    --     We simply replace the placeholder text
    return log_template_lang:find("%%log_target")
        and build_capture_log_statements(log_template_lang, lang, position, selection_range)
      or { build_non_capture_log_statement(log_template_lang, position) }
  end

  local to_insert = {}

  if opts.position == "surround" then
    local to_insert_before = build_to_insert(opts.templates.before, "above")
    local to_insert_after = build_to_insert(opts.templates.after, "below")
    to_insert = { unpack(to_insert_before), unpack(to_insert_after) }
  else
    if opts.templates then
      utils.notify("'templates' can only be used with position 'surround'", "warn")
    end

    to_insert = build_to_insert(opts.template, opts.position)
  end

  local after_inserted_statements, insert_cursor_pos = insert_log_statements(to_insert)
  after_insert_log_statements(after_inserted_statements, insert_cursor_pos, original_cursor_position)

  -- Prepare for dot repeat. We only preserve the opts
  make_dot_repeatable("__insert_log")
  state.current_command_arguments.insert_log = { opts, nil, nil }
end

--- Insert log statement for the current identifier at the cursor
--- @class Timber.Actions.InsertLogOptions
--- @field template string? Which template to use. Defaults to `default`
--- @field templates { before: string, after: string }? Which templates to use for the log statement. Only used when position is `surround`. Defaults to `{ before = "default", after = "default" }`
--- @field position Timber.Actions.LogPosition
--- @field operator? boolean Whether to go into operator mode
--- @param opts Timber.Actions.InsertLogOptions
function M.insert_log(opts)
  local cursor_position = vim.fn.getpos(".")
  opts = vim.tbl_deep_extend("force", { template = "default", operator = false }, opts or {})

  if opts.templates then
    opts.templates = vim.tbl_deep_extend("force", { before = "default", after = "default" }, opts.templates)
  end

  if opts.position == "surround" and not opts.templates then
    utils.notify("'templates' must be specified when position is 'surround'", "error")
    return
  end

  state.current_command_arguments.insert_log = { opts, utils.get_selection_range(), cursor_position }

  vim.go.operatorfunc = "v:lua.require'timber.actions'.__insert_log"
  if opts.operator then
    return "g@"
  else
    vim.cmd("normal! g@l")
  end
end

function M.__insert_batch_log(motion_type)
  local opts = state.current_command_arguments.insert_batch_log[1]
  local selection_range

  if opts.operator then
    selection_range = utils.get_operator_selection_range(motion_type)
  else
    -- If selection_range or original_cursor_position are nil, it means the user is dot repeating
    selection_range = state.current_command_arguments.insert_batch_log[2] or utils.get_selection_range()
  end

  if opts.auto_add then
    state.current_command_arguments.add_log_targets_to_batch = { { operator = false }, selection_range, nil }
    M.__add_log_targets_to_batch()
  end

  if #M.batch == 0 then
    utils.notify("Log batch is empty", "warn")
    return
  end

  local log_template_lang, lang = config.get_lang_log_template(opts.template, "batch")
  if not log_template_lang or not lang then
    return
  end

  -- Insert 1 line after the selection range
  local to_insert = build_batch_log_statement(log_template_lang, M.batch, selection_range[3] + 1)
  local after_insert_statements, insert_cursor_pos = insert_log_statements({ to_insert })
  after_insert_log_statements(after_insert_statements, insert_cursor_pos, nil)
  M.clear_batch()

  make_dot_repeatable("__insert_batch_log")
end

--- Insert log statement for given batch
--- @class Timber.Actions.InsertBatchLogOptions
--- @field template string? Which template to use. Defaults to `default`
--- @field auto_add? boolean Whether to automatically add the log target to the batch. Defaults to `false`
--- @field operator? boolean Whether to go into operator mode. If `true`, it implies `auto_add` is `true`
--- @param opts Timber.Actions.InsertBatchLogOptions?
function M.insert_batch_log(opts)
  opts = vim.tbl_deep_extend("force", { template = "default", auto_add = false }, opts or {})
  if opts.operator then
    opts.auto_add = true
  end

  vim.go.operatorfunc = "v:lua.require'timber.actions'.__insert_batch_log"
  state.current_command_arguments.insert_batch_log = { opts, utils.get_selection_range() }

  if opts.operator then
    return "g@"
  else
    vim.cmd("normal! g@l")
  end

  state.current_command_arguments.insert_batch_log = { opts, nil }
end

---Add log target to the log batch
function M.__add_log_targets_to_batch(motion_type)
  --- nil means the user is dot repeating
  local opts = state.current_command_arguments.add_log_targets_to_batch[1]
  local selection_range

  if opts.operator then
    selection_range = utils.get_operator_selection_range(motion_type)
  else
    -- If selection_range or original_cursor_position are nil, it means the user is dot repeating
    selection_range = state.current_command_arguments.add_log_targets_to_batch[2] or utils.get_selection_range()
  end

  local lang = utils.get_lang(vim.bo.filetype)
  if not lang then
    utils.notify(string.format("Treesitter parser for %s language is not found", vim.bo.filetype), "error")
    return
  end

  ---@type TSNode[]
  local to_add = {}

  for _, entry in ipairs(capture_log_targets(lang, selection_range)) do
    table.insert(to_add, entry.log_target)
  end

  to_add = treesitter.sort_ts_nodes_preorder(to_add)

  vim.list_extend(M.batch, to_add)

  for _, target in ipairs(to_add) do
    highlight.highlight_add_to_batch(target)
  end

  -- Prepare for dot repeat. Reset the arguments
  make_dot_repeatable("__add_log_targets_to_batch")
end

---@class Timber.Actions.AddLogTargetsToBatchOptions
---@field operator? boolean Whether to go into operator mode
---@param opts Timber.Actions.AddLogTargetsToBatchOptions?
function M.add_log_targets_to_batch(opts)
  opts = vim.tbl_deep_extend("force", { operator = false }, opts or {})
  local cursor_position = vim.fn.getpos(".")
  state.current_command_arguments.add_log_targets_to_batch = { opts, utils.get_selection_range(), cursor_position }

  vim.go.operatorfunc = "v:lua.require'timber.actions'.__add_log_targets_to_batch"

  if opts.operator then
    return "g@"
  else
    vim.cmd("normal! g@l")
  end

  state.current_command_arguments.add_log_targets_to_batch = { opts, nil, nil }
  vim.fn.setpos(".", cursor_position)
end

function M.get_batch_size()
  return #M.batch
end

function M.clear_batch()
  M.batch = {}
end

---@class Timber.Actions.ClearLogStatementsOptions
---@field global? boolean Whether to clear all buffers, or just the current buffer. Defaults to `false`
---@param opts Timber.Actions.ClearLogStatementsOptions?
function M.clear_log_statements(opts)
  opts = vim.tbl_deep_extend("force", { global = false }, opts or {})
  local lines_per_bufnr = buffers.get_log_statement_lines(not opts.global and vim.api.nvim_get_current_buf() or nil)

  for bufnr, lines in pairs(lines_per_bufnr) do
    -- Sort lines in descending order to avoid line number shifting
    table.sort(lines, function(a, b)
      return a > b
    end)

    -- Delete each line
    for _, line_num in ipairs(lines) do
      vim.api.nvim_buf_set_lines(bufnr, line_num, line_num + 1, false, {})
    end
  end
end

function M.setup()
  treesitter.setup()
end

return M
