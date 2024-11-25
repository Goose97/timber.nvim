local utils = require("timber.utils")

---@class Timber.Buffers.LogPlaceholderEntries
---@field body string
---@field source_name string
---@field timestamp integer

---@class Timber.Buffers.LogPlaceholder
---@field id Timber.Watcher.LogPlaceholderId? The log placeholder id. It is only set when the log template has %watcher_marker_start
---@field bufnr number
---@field line number 0-indexed line number. The line number is only correct when the placeholder is newly created. Overtime, after updates, the real line number will be shifted.
---@field extmark_id? integer
---@field entries Timber.Buffers.LogPlaceholderEntries[]

---@class Timber.Buffers.LogPlaceholderRegistry
---@field placeholders Timber.Buffers.LogPlaceholder[] List of log placeholders
local LogPlaceholderRegistry = {}
function LogPlaceholderRegistry.new()
  local o = {
    placeholders = {},
  }

  setmetatable(o, LogPlaceholderRegistry)
  LogPlaceholderRegistry.__index = LogPlaceholderRegistry
  return o
end

---@class Timber.Buffers
---@field log_placeholders Timber.Buffers.LogPlaceholderRegistry
---@field seen_buffers integer[] Buffers has been opened and processed
---@field attached_buffers integer[] Buffers currently being attached to
---@field pending_log_entries Timber.Watcher.LogEntry[] Log entries that didn't have a corresponding placeholder. They will be processed once the placeholder is created
---@field placeholder_render_timer any Timer to keep updating the placeholder snippet
local M = {
  log_placeholders = LogPlaceholderRegistry.new(),
  seen_buffers = {},
  attached_buffers = {},
  pending_log_entries = {},
}

---Find a log placeholder by id
---@param id Timber.Watcher.LogPlaceholderId
---@return Timber.Buffers.LogPlaceholder?
function LogPlaceholderRegistry:get(id)
  for _, placeholder in ipairs(self.placeholders) do
    if placeholder.id == id then
      return placeholder
    end
  end
end

---Add a log placeholder to the registry. Noop if the placeholder already exists
---@param placeholder Timber.Buffers.LogPlaceholder
function LogPlaceholderRegistry:add(placeholder)
  local existing = placeholder.id and self:get(placeholder.id) or nil
  if not existing then
    table.insert(self.placeholders, placeholder)
  end
end

---Remove a log placeholder
---@param id Timber.Watcher.LogPlaceholderId
function LogPlaceholderRegistry:remove(id)
  self.placeholders = utils.array_filter(self.placeholders, function(placeholder)
    return placeholder.id ~= id
  end)
end

---Remove a log placeholder by extmark id. The extmark id is unique to a buffer so we need to pass in bufnr as well
---@param extmark_id integer
---@param bufnr integer
function LogPlaceholderRegistry:remove_by_extmark_id(extmark_id, bufnr)
  self.placeholders = utils.array_filter(self.placeholders, function(placeholder)
    return placeholder.extmark_id ~= extmark_id or placeholder.bufnr ~= bufnr
  end)
end

---Return all log placeholders in a buffer
---@param bufnr integer
function LogPlaceholderRegistry:buffer_placeholders(bufnr)
  return utils.array_filter(self.placeholders, function(placeholder)
    return placeholder.bufnr == bufnr
  end)
end

---@param line string
---@return string? placeholder_id
local function parse_log_placeholder(line)
  local pattern = string.format("🪵(%s)|", string.rep("[A-Z0-9]", 3))
  return string.match(line, pattern)
end

---@param content string
---@param bufnr integer
---@param line integer 0-indexed line number
---@return Timber.Watcher.LogPlaceholderId? placeholder_id
local function process_line(content, bufnr, line)
  local placeholder_id = parse_log_placeholder(content)

  if placeholder_id and not M.log_placeholders:get(placeholder_id) then
    vim.schedule(function()
      M.new_log_placeholder({ id = placeholder_id, bufnr = bufnr, line = line, entries = {} })
    end)

    return placeholder_id
  end
end

---@param timestamp integer
local function relative_time(timestamp)
  local current_time = os.time()
  local elapsed = current_time - timestamp

  local breakpoints = {
    { elapsed = 30, text = "Just now" },
    { elapsed = 300, text = ">30 seconds ago" },
    { elapsed = 900, text = ">5 minutes ago" },
  }

  for _, breakpoint in ipairs(breakpoints) do
    if elapsed < breakpoint.elapsed then
      return breakpoint.text
    end
  end

  return ">15 minutes ago"
end

---@param log_placeholder Timber.Buffers.LogPlaceholder
local function render_placeholder_snippet(log_placeholder)
  local content = log_placeholder.entries[#log_placeholder.entries]
  if not content then
    return
  end

  local is_loaded = vim.api.nvim_buf_is_loaded(log_placeholder.bufnr)
  if not is_loaded then
    return
  end

  local preview_snippet_length = require("timber.config").config.log_watcher.preview_snippet_length
  local snippet = content.body

  if #snippet > preview_snippet_length then
    snippet = string.sub(content.body, 1, preview_snippet_length) .. "..."
  end

  local mark =
    vim.api.nvim_buf_get_extmark_by_id(log_placeholder.bufnr, M.log_placeholder_ns, log_placeholder.extmark_id, {})

  if mark and #mark > 0 then
    ---@type integer, integer
    local row, col = unpack(mark, 1, 2)

    vim.api.nvim_buf_set_extmark(log_placeholder.bufnr, M.log_placeholder_ns, row, col, {
      id = log_placeholder.extmark_id,
      virt_text = {
        { "■ " .. snippet, "Timber.LogPlaceholderSnippet" },
        { " " .. relative_time(content.timestamp), "Timber.LogPlaceholderTime" },
      },
      virt_text_pos = "eol",
    })
  end
end

---@param log_placeholder Timber.Buffers.LogPlaceholder
local function remove_placeholder_snippet(log_placeholder)
  local is_loaded = vim.api.nvim_buf_is_loaded(log_placeholder.bufnr)
  if not is_loaded then
    return
  end

  local mark =
    vim.api.nvim_buf_get_extmark_by_id(log_placeholder.bufnr, M.log_placeholder_ns, log_placeholder.extmark_id, {})

  if mark and #mark > 0 then
    ---@type integer, integer
    local row, col = unpack(mark, 1, 2)

    vim.api.nvim_buf_set_extmark(log_placeholder.bufnr, M.log_placeholder_ns, row, col, {
      id = log_placeholder.extmark_id,
    })
  end
end

---@param bufnr number
---@return boolean found_any_placeholders
local function process_buffer(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local found_any = false

  for i, line in ipairs(lines) do
    local placeholder_id = process_line(line, bufnr, i - 1)
    if placeholder_id then
      found_any = true
    end
  end

  return found_any
end

local function detach_buffer(bufnr)
  local index = utils.array_find_index(M.attached_buffers, function(v)
    return v == bufnr
  end)

  -- There's no API to detach a buffer. We will return false in the next on_lines callback
  if index then
    table.remove(M.attached_buffers, index)
  end
end

local function on_lines(_, bufnr, _, first_line, last_line, new_last_line, _)
  -- local index = utils.array_find_index(M.attached_buffers, function(v)
  --   return v == bufnr
  -- end)
  --
  -- if not index then
  --   -- Detach the buffer
  --   return true
  -- end

  -- Process each line in the changed region
  for lnum = first_line, new_last_line - 1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1]
    process_line(line, bufnr, lnum)
  end

  -- Handle deleted lines
  if last_line > new_last_line then
    -- The deleted line may shifted some placeholders to the next line.
    -- The algorithm is as follows:
    --   1. Get the placeholder of the next line by parsing the content
    --   2. Get all placeholders on the next line by getting extmarks
    --   3. Subtract 2 to 1, we get the extmarks that are deleted
    local line_content = vim.api.nvim_buf_get_lines(bufnr, last_line - 1, last_line, false)[1]

    local line_placeholder = line_content and parse_log_placeholder(line_content)
    local marks = vim.api.nvim_buf_get_extmarks(
      bufnr,
      M.log_placeholder_ns,
      { new_last_line, 0 },
      { new_last_line, -1 },
      {}
    )

    marks = utils.array_filter(marks, function(mark)
      if line_placeholder == nil then
        return true
      end

      return mark[1] ~= M.log_placeholders:get(line_placeholder).extmark_id
    end)

    for _, mark in ipairs(marks) do
      local mark_id = mark[1]

      vim.schedule(function()
        vim.api.nvim_buf_del_extmark(bufnr, M.log_placeholder_ns, mark_id)
        M.log_placeholders:remove_by_extmark_id(mark_id, bufnr)

        local remaining = M.log_placeholders:buffer_placeholders(bufnr)
        if #remaining == 0 then
          detach_buffer(bufnr)
        end
      end)
    end
  end
end

local function attach_buffer(bufnr)
  if vim.list_contains(M.attached_buffers, bufnr) then
    return
  end

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = on_lines,
    on_reload = function()
      process_buffer(bufnr)
    end,
  })

  table.insert(M.attached_buffers, bufnr)
end

---Callback for log entry received
--- @param entry Timber.Watcher.LogEntry
function M.receive_log_entry(entry)
  local log_placeholder = M.log_placeholders:get(entry.log_placeholder_id)

  if log_placeholder then
    table.insert(
      log_placeholder.entries,
      { body = entry.payload, source_name = entry.source_name, timestamp = entry.timestamp }
    )

    vim.schedule(function()
      render_placeholder_snippet(log_placeholder)
    end)
  else
    -- Save the log entry for later
    table.insert(M.pending_log_entries, entry)
  end
end

---@param log_placeholder Timber.Buffers.LogPlaceholder
function M.new_log_placeholder(log_placeholder)
  if log_placeholder.id and M.log_placeholders:get(log_placeholder.id) then
    return
  end

  local extmark_id =
    vim.api.nvim_buf_set_extmark(log_placeholder.bufnr, M.log_placeholder_ns, log_placeholder.line, 0, {})

  log_placeholder.extmark_id = extmark_id
  M.log_placeholders:add(log_placeholder)
  attach_buffer(log_placeholder.bufnr)

  -- Check the pending log entries and process ones targeting this placeholder
  for _, entry in ipairs(M.pending_log_entries) do
    if entry.log_placeholder_id == log_placeholder.id then
      M.receive_log_entry(entry)
    end
  end

  M.pending_log_entries = utils.array_filter(M.pending_log_entries, function(entry)
    return entry.log_placeholder_id ~= log_placeholder.id
  end)
end

---@param entries Timber.Buffers.LogPlaceholderEntries[]
---@return string[] lines
---@return integer[] separators 0-indexed line numbers of separator lines
---@return boolean has_total_entries
local function prepare_floating_window_content(entries)
  local entry_lines = {}
  for _, content in ipairs(entries) do
    table.insert(entry_lines, vim.split(content.body, "\n"))
  end

  -- Get the max width of the content
  local max_width = 0
  for _, lines in ipairs(entry_lines) do
    for _, line in ipairs(lines) do
      max_width = math.max(max_width, #line)
    end
  end

  local has_total_entries = #entries > 1
  local buf_content = {}
  local separators = {}
  local line_count = 0

  local total_entries_line
  if has_total_entries then
    total_entries_line = utils.string_left_pad(string.format("%d entries", #entries), max_width)
    table.insert(buf_content, total_entries_line)
    line_count = line_count + 1
  end

  for i, lines in ipairs(entry_lines) do
    vim.list_extend(buf_content, lines)
    line_count = line_count + #lines

    if i < #entries then
      local separator_width = math.max(max_width, #total_entries_line)
      table.insert(buf_content, string.rep("─", separator_width))
      table.insert(separators, line_count)
      line_count = line_count + 1
    end
  end

  return buf_content, separators, has_total_entries
end

---Render a floating window showing placeholder content
---@param placeholder Timber.Buffers.LogPlaceholder
---@param opts? { silent?: boolean }
local function show_placeholder_full_content(placeholder, opts)
  opts = vim.tbl_extend("force", { silent = false }, opts or {})

  if not placeholder.entries or #placeholder.entries == 0 then
    if not opts.silent then
      utils.notify("Log placeholder has no content", "warn")
    end

    return
  end

  local lines, separators, has_total_entries = prepare_floating_window_content(placeholder.entries)

  local window_config = {
    relative = "cursor",
    anchor = "SW",
    row = 0,
    col = 0,
    focusable = true,
    style = "minimal",
    border = "single",
    title = placeholder.entries[1].source_name,
  }

  local bufnr = vim.lsp.util.open_floating_preview(lines, "plaintext", window_config)

  if has_total_entries then
    vim.api.nvim_buf_add_highlight(bufnr, M.log_placeholder_ns, "Timber.LogPlaceholderTotalEntries", 0, 0, -1)
  end

  for _, i in ipairs(separators) do
    vim.api.nvim_buf_add_highlight(bufnr, M.log_placeholder_ns, "Timber.LogPlaceholderSeparator", i, 0, -1)
  end
end

---@param opts? { silent?: boolean }
function M.open_float(opts)
  opts = vim.tbl_extend("force", { silent = false }, opts or {})

  local current_line = vim.fn.getline(".")
  local placeholder_id = parse_log_placeholder(current_line)

  if not placeholder_id then
    if not opts.silent then
      utils.notify("No log placeholder found", "warn")
    end

    return
  end

  local placeholder = M.log_placeholders:get(placeholder_id)
  if placeholder then
    show_placeholder_full_content(placeholder, { silent = opts.silent })
  else
    error(string.format("Log placeholder %s does not exist", placeholder_id))
  end
end

local function update_placeholders_snippet()
  for _, i in pairs(M.log_placeholders.placeholders) do
    render_placeholder_snippet(i)
  end
end

---Get all log statement line numbers in the current buffer or all buffers
---@param bufnr number? Buffer number. If not provided, return results for all buffers
---@return table<integer, integer[]> lines_per_bufnr 0-indexed line numbers grouped by buffers
function M.get_log_statement_lines(bufnr)
  local grouped = utils.array_group_by(M.log_placeholders.placeholders, function(placeholder)
    return placeholder.bufnr
  end)

  local to_lines = function(items)
    local lines = {}
    for _, placeholder in ipairs(items) do
      local pos =
        vim.api.nvim_buf_get_extmark_by_id(placeholder.bufnr, M.log_placeholder_ns, placeholder.extmark_id, {})
      table.insert(lines, pos[1])
    end

    return lines
  end

  if bufnr then
    return grouped[bufnr] and { [bufnr] = to_lines(grouped[bufnr]) } or {}
  else
    local result = {}
    for _bufnr, _placeholders in pairs(grouped) do
      result[_bufnr] = to_lines(_placeholders)
    end

    return result
  end
end

function M.clear_logs()
  for _, log_placeholder in pairs(M.log_placeholders) do
    log_placeholder.entries = {}
    remove_placeholder_snippet(log_placeholder)
  end
end

function M.setup()
  vim.api.nvim_set_hl(0, "Timber.LogPlaceholderSnippet", { link = "DiagnosticVirtualTextInfo", default = true })
  vim.api.nvim_set_hl(0, "Timber.LogPlaceholderTime", { italic = true })
  vim.api.nvim_set_hl(0, "Timber.LogPlaceholderTotalEntries", { link = "CursorLineNr" })
  vim.api.nvim_set_hl(0, "Timber.LogPlaceholderSeparator", { link = "FloatBorder" })

  M.log_placeholder_ns = vim.api.nvim_create_namespace("timber.log_placeholder")

  vim.api.nvim_create_autocmd("BufRead", {
    callback = function(args)
      local bufnr = args.buf
      if vim.list_contains(M.seen_buffers, bufnr) then
        return
      end

      -- We only attach to the buffer if it contains a log placeholder
      local found_any_placeholders = process_buffer(bufnr)
      if found_any_placeholders then
        attach_buffer(bufnr)
      end

      table.insert(M.seen_buffers, bufnr)
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    callback = function(args)
      detach_buffer(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    callback = function(args)
      detach_buffer(args.buf)
    end,
  })

  -- Timer loop to keep updating the placeholder snippets
  M.placeholder_render_timer = vim.uv.new_timer()
  M.placeholder_render_timer:start(0, 10000, vim.schedule_wrap(update_placeholders_snippet))
end

return M
