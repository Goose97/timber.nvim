---@class NeologActions
--- @field log_templates { [string]: NeologLogTemplates }
--- @field batch_log_templates { [string]: NeologLogTemplates }
--- @field batch TSNode[]
local M = { log_templates = {}, batch_log_templates = {}, batch = {} }

local highlight = require("neolog.highlight")
local treesitter = require("neolog.actions.treesitter")
local utils = require("neolog.utils")

---@class LogStatementInsert
---@field content string The log statement content
---@field row number The (0-indexed) row number to insert
---@field insert_cursor_offset number? The offset of the %insert_cursor placeholder if any
---@field log_target TSNode? The log target node

--- @alias LogPosition "above" | "below" | "surround"
--- @alias range {[1]: number, [2]: number, [3]: number, [4]: number}
--- @alias cursor_position {[1]: number, [2]: number}

--- @class InsertLogReturn
--- @field cursor_moved boolean Whether the cursor position was moved
--- @field inserted_lines integer[] (0-indexed) row numbers of inserted lines

---@class NeologActionsState
---@field current_command_arguments table
---@field current_command_arguments.insert_log? {[1]: InsertLogOptions, [2]: range, [3]: range}
---@field current_command_arguments.insert_batch_log? {[1]: InsertBatchLogOptions, [2]: range?}
---@field current_command_arguments.add_log_targets_to_batch? {[1]: AddLogTargetsToBatchOptions, [2]: range}
---@field current_selection_range {[1]: number, [2]: number, [3]: number, [4]: number}?

---@type NeologActionsState
local state = {
  current_command_arguments = {},
  current_selection_range = nil,
}

---@param callback string
local function make_dot_repeatable(callback)
  -- Reset the operatorfunc
  vim.go.operatorfunc = "v:lua.require'neolog.utils'.NOOP"
  vim.cmd("normal! g@l")
  vim.go.operatorfunc = "v:lua.require'neolog.actions'." .. callback
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
---   %identifier: the identifier text
---   %line_number: the line_number number
---   %insert_cursor: after inserting the log statement, go to insert mode and place the cursor here.
---     If there's multiple log statements, choose the first one
---@alias handler (fun(): string) | string
---@param log_template string
---@param handlers {identifier: handler, line_number: handler}
---@return string
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

  if string.find(log_template, "%%identifier") then
    local replacement = invoke_handler("identifier")
    log_template = string.gsub(log_template, "%%identifier", replacement)
  end

  if string.find(log_template, "%%line_number") then
    local replacement = invoke_handler("line_number")
    log_template = string.gsub(log_template, "%%line_number", replacement)
  end

  return log_template
end

---@param statements LogStatementInsert[]
---@return integer[] inserted_lines (0-indexed) row numbers of inserted lines
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

  local inserted_lines = {}

  -- Offset the row numbers
  local offset = 0
  local insert_cursor_pos

  for _, statement in ipairs(statements) do
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
      table.insert(inserted_lines, insert_line + i)
    end
  end

  return inserted_lines, insert_cursor_pos
end

---Perform post-insert operations:
---   1. Place the cursor at the insert_cursor placeholder if any
---   2. Move the cursor back to the original position if needed
---@param insert_cursor_pos {[1]: number, [2]: number}?
---@param original_cursor_position range?
---@param inserted_lines integer[]
local function after_insert_log_statements(insert_cursor_pos, original_cursor_position, inserted_lines)
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
end

---@param filetype string
---@return string?
local function get_lang(filetype)
  -- Treesitter doesn't support jsx directly but through tsx
  if filetype == "javascriptreact" then
    return "tsx"
  end

  return vim.treesitter.language.get_lang(vim.bo.filetype)
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
local function pick_best_node(nodes, selection_range)
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

---@param lang string
---@param selection_range range?
---@return {log_container: TSNode, logable_range: logable_range?, log_targets: TSNode[]}[]
local function capture_log_targets(lang, selection_range)
  local log_containers = treesitter.query_log_target_container(lang, selection_range)

  local result = {}

  local log_target_grouped_by_container = treesitter.find_log_targets(
    utils.array_map(log_containers, function(i)
      return i.container
    end),
    lang
  )

  for _, entry in ipairs(log_target_grouped_by_container) do
    -- Filter targets that intersect with the given range
    local log_targets = utils.array_filter(entry.log_targets, function(node)
      return utils.ranges_intersect(selection_range, utils.get_ts_node_range(node))
    end)

    -- For each group, we pick the "biggest" node
    -- A node is the biggest if it contains all other nodes in the group
    local groups = group_overlapping_log_targets(log_targets)
    log_targets = utils.array_map(groups, function(group)
      return pick_best_node(group, selection_range)
    end)

    local log_container = utils.array_find(log_containers, function(i)
      return i.container == entry.container
    end)
    ---@cast log_container -nil

    table.insert(result, {
      log_container = log_container.container,
      logable_range = log_container.logable_range,
      log_targets = log_targets,
    })
  end

  return result
end

---@param log_target TSNode
---@param log_container TSNode
---@param logable_range logable_range?
---@param position LogPosition
---@return integer
local function get_insert_row(log_target, log_container, logable_range, position)
  if not logable_range then
    return position == "above" and log_container:start() or log_container:end_() + 1
  end

  local srow = log_target:start()

  if srow <= logable_range[1] then
    return position == "above" and log_container:start() or logable_range[1]
  else
    return position == "above" and logable_range[1] or log_container:end_() + 1
  end
end

---@param log_template string
---@param lang string
---@param position LogPosition
---@param selection_range range
---@return LogStatementInsert[]
local function build_capture_log_statements(log_template, lang, position, selection_range)
  local to_insert = {}

  for _, entry in ipairs(capture_log_targets(lang, selection_range)) do
    local log_targets = entry.log_targets
    local log_container = entry.log_container
    local logable_range = entry.logable_range

    for _, log_target in ipairs(log_targets) do
      local content = resolve_template_placeholders(log_template, {
        identifier = function()
          local bufnr = vim.api.nvim_get_current_buf()
          return vim.treesitter.get_node_text(log_target, bufnr)
        end,
        line_number = function()
          return tostring(log_target:start() + 1)
        end,
      })

      local insert_row = get_insert_row(log_target, log_container, logable_range, position)

      table.insert(to_insert, {
        content = content,
        row = insert_row,
        insert_cursor_offset = nil,
        log_target = log_target,
      })
    end
  end

  return to_insert
end

---@param log_template string
---@param position LogPosition
---@return LogStatementInsert
local function build_non_capture_log_statement(log_template, position)
  local current_line = vim.fn.getpos(".")[2]
  local insert_row = position == "above" and current_line or current_line + 1
  local content = resolve_template_placeholders(log_template, {
    line_number = tostring(insert_row),
  })

  return {
    content = content,
    -- Minus cause the row is 0-indexed
    row = insert_row - 1,
    insert_cursor_offset = nil,
  }
end

---@param log_template string
---@param batch TSNode[]
---@param insert_line integer
---@return LogStatementInsert
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
  -- local current_line = vim.fn.getpos(".")[2]
  local result1 = resolve_template_placeholders(result, {
    identifier = function()
      utils.notify("Cannot use %identifier placeholder outside %repeat placeholder", "error")
      return "%identifier"
    end,
    line_number = tostring(insert_line + 1),
  })

  return {
    content = result1,
    -- Insert at the line below 0-indexed
    row = insert_line,
    insert_cursor_offset = nil,
  }
end

---@param template_set string
---@param kind "single" | "batch"
---@return string?, string?
local function get_lang_log_template(template_set, kind)
  local lang = get_lang(vim.bo.filetype)
  if not lang then
    utils.notify("Treesitter cannot determine language for current buffer", "error")
    return
  end

  local log_template_set = (kind == "single" and M.log_templates or M.batch_log_templates)[template_set]
  if not log_template_set then
    utils.notify(string.format("Log template '%s' is not found", template_set), "error")
    return
  end

  local log_template_lang = log_template_set[lang]
  if not log_template_lang then
    utils.notify(
      string.format(
        "%s '%s' does not have '%s' language template",
        kind == "single" and "Log template" or "Batch log template",
        template_set,
        lang
      ),
      "error"
    )
    return
  end

  return log_template_lang, lang
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
    local log_template_lang, lang = get_lang_log_template(template, "single")

    if not log_template_lang or not lang then
      return {}
    end

    -- There are two kinds of log statements:
    --   1. Capture log statements: log statements that contain %identifier placeholder
    --     We need to capture the log target in the selection range and replace it
    --   2. Non-capture log statements: log statements that don't contain %identifier placeholder
    --     We simply replace the placeholder text
    return log_template_lang:find("%%identifier")
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

  local inserted_lines, insert_cursor_pos = insert_log_statements(to_insert)
  after_insert_log_statements(insert_cursor_pos, original_cursor_position, inserted_lines)

  -- Prepare for dot repeat. We only preserve the opts
  make_dot_repeatable("__insert_log")
  state.current_command_arguments.insert_log = { opts, nil, nil }
end

--- Insert log statement for the current identifier at the cursor
--- @class InsertLogOptions
--- @field template string? Which template to use. Defaults to `default`
--- @field templates { before: string, after: string }? Which templates to use for the log statement. Only used when position is `surround`. Defaults to `{ before = "default", after = "default" }`
--- @field position LogPosition
--- @field operator? boolean Whether to go into operator mode
--- @param opts InsertLogOptions
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

  vim.go.operatorfunc = "v:lua.require'neolog.actions'.__insert_log"
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

  local log_template_lang, lang = get_lang_log_template(opts.template, "batch")
  if not log_template_lang or not lang then
    return
  end

  -- Insert 1 line after the selection range
  local to_insert = build_batch_log_statement(log_template_lang, M.batch, selection_range[3] + 1)
  local inserted_lines, insert_cursor_pos = insert_log_statements({ to_insert })
  after_insert_log_statements(insert_cursor_pos, nil, inserted_lines)
  M.clear_batch()

  make_dot_repeatable("__insert_batch_log")
end

--- Insert log statement for given batch
--- @class InsertBatchLogOptions
--- @field template string? Which template to use. Defaults to `default`
--- @field auto_add? boolean Whether to automatically add the log target to the batch. Defaults to `false`
--- @field operator? boolean Whether to go into operator mode. If `true`, it implies `auto_add` is `true`
--- @param opts InsertBatchLogOptions?
function M.insert_batch_log(opts)
  opts = vim.tbl_deep_extend("force", { template = "default", auto_add = false }, opts or {})
  if opts.operator then
    opts.auto_add = true
  end

  vim.go.operatorfunc = "v:lua.require'neolog.actions'.__insert_batch_log"
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

  local lang = get_lang(vim.bo.filetype)
  if not lang then
    utils.notify("Treesitter cannot determine language for current buffer", "error")
    return
  end

  ---@type TSNode[]
  local to_add = {}

  for _, entry in ipairs(capture_log_targets(lang, selection_range)) do
    for _, log_target in ipairs(entry.log_targets) do
      table.insert(to_add, log_target)
    end
  end

  to_add = treesitter.sort_ts_nodes_preorder(to_add)

  vim.list_extend(M.batch, to_add)

  for _, target in ipairs(to_add) do
    highlight.highlight_add_to_batch(target)
  end

  -- Prepare for dot repeat. Reset the arguments
  make_dot_repeatable("__add_log_targets_to_batch")
end

---@class AddLogTargetsToBatchOptions
---@field operator? boolean Whether to go into operator mode
---@param opts AddLogTargetsToBatchOptions?
function M.add_log_targets_to_batch(opts)
  opts = vim.tbl_deep_extend("force", { operator = false }, opts or {})
  local cursor_position = vim.fn.getpos(".")
  state.current_command_arguments.add_log_targets_to_batch = { opts, utils.get_selection_range(), cursor_position }

  vim.go.operatorfunc = "v:lua.require'neolog.actions'.__add_log_targets_to_batch"

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

-- Register the custom predicate
---@param templates { [string]: NeologLogTemplates }
---@param batch_templates { [string]: NeologLogTemplates }
function M.setup(templates, batch_templates)
  M.log_templates = templates
  M.batch_log_templates = batch_templates

  treesitter.setup()
end

return M
