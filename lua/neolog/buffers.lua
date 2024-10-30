local utils = require("neolog.utils")

---@alias LogPlaceholderId string

---@class LogPlaceholderContent
---@field body string
---@field source_name string
---@field timestamp integer

---@class LogPlaceholder
---@field id LogPlaceholderId
---@field bufnr number
---@field line number 0-indexed line number. The line number is only correct when the placeholder is newly created. Overtime, after updates, the real line number will be shifted.
---@field extmark_id? integer
---@field contents LogPlaceholderContent[]

---@alias LogPlaceholderRegistry table<LogPlaceholderId, LogPlaceholder>

---@class Neolog.Buffers
---@field log_placeholders LogPlaceholderRegistry
---@field seen_buffers integer[] Buffers has been opened and processed
---@field attached_buffers integer[] Buffers currently being attached to
---@field pending_log_entries WatcherLogEntry[] Log entries that didn't have a corresponding placeholder. They will be processed once the placeholder is created
---@field placeholder_render_timer any Timer to keep updating the placeholder snippet
local M = { log_placeholders = {}, seen_buffers = {}, attached_buffers = {}, pending_log_entries = {} }

---@param line string
---@return string? placeholder_id
local function parse_log_placeholder(line)
  local pattern = string.format("🪵(%s)|", string.rep("[A-Z0-9]", 3))
  return string.match(line, pattern)
end

---@param content string
---@param bufnr integer
---@param line integer 0-indexed line number
---@return LogPlaceholderId? placeholder_id
local function process_line(content, bufnr, line)
  local placeholder_id = parse_log_placeholder(content)

  if placeholder_id and M.log_placeholders[placeholder_id] == nil then
    vim.schedule(function()
      M.new_log_placeholder({ id = placeholder_id, bufnr = bufnr, line = line, contents = {} })
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

---@param log_placeholder LogPlaceholder
local function render_placeholder_content(log_placeholder)
  -- TODO: Support multiple log entries. Right now, let's render only the latest one
  local content = log_placeholder.contents[1]
  if not content then
    return
  end

  local is_loaded = vim.api.nvim_buf_is_loaded(log_placeholder.bufnr)
  if not is_loaded then
    return
  end

  local preview_snippet_length = require("neolog.config").config.log_watcher.preview_snippet_length
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
        { "■ " .. snippet, "Neolog.LogPlaceholderSnippet" },
        { " " .. relative_time(content.timestamp), "Neolog.LogPlaceholderTime" },
      },
      virt_text_pos = "eol",
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

---@param extmark_id integer
---@param bufnr integer
local function delete_placeholder_by_extmark_id(extmark_id, bufnr)
  for placeholder_id, placeholder in pairs(M.log_placeholders) do
    if placeholder.extmark_id == extmark_id and placeholder.bufnr == bufnr then
      M.log_placeholders[placeholder_id] = nil
      break
    end
  end
end

local function on_lines(_, bufnr, _, first_line, last_line, new_last_line, _)
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

      return mark[1] ~= M.log_placeholders[line_placeholder].extmark_id
    end)

    for _, mark in ipairs(marks) do
      local mark_id = mark[1]

      vim.schedule(function()
        vim.api.nvim_buf_del_extmark(bufnr, M.log_placeholder_ns, mark_id)
        delete_placeholder_by_extmark_id(mark_id, bufnr)
      end)
    end
  end
end

---Callback for log entry received
--- @param entry WatcherLogEntry
function M.on_log_entry_received(entry)
  local log_placeholder = M.log_placeholders[entry.log_placeholder_id]

  if log_placeholder then
    table.insert(
      log_placeholder.contents,
      1,
      { body = entry.payload, source_name = entry.source_name, timestamp = entry.timestamp }
    )

    vim.schedule(function()
      render_placeholder_content(log_placeholder)
    end)
  else
    -- Save the log entry for later
    table.insert(M.pending_log_entries, entry)
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

---@param log_placeholder LogPlaceholder
function M.new_log_placeholder(log_placeholder)
  if M.log_placeholders[log_placeholder.id] then
    return
  end

  local extmark_id =
    vim.api.nvim_buf_set_extmark(log_placeholder.bufnr, M.log_placeholder_ns, log_placeholder.line, 0, {})

  log_placeholder.extmark_id = extmark_id
  M.log_placeholders[log_placeholder.id] = log_placeholder
  attach_buffer(log_placeholder.bufnr)

  -- Check the pending log entries and process ones targeting this placeholder
  for _, entry in ipairs(M.pending_log_entries) do
    if entry.log_placeholder_id == log_placeholder.id then
      M.on_log_entry_received(entry)
    end
  end

  M.pending_log_entries = utils.array_filter(M.pending_log_entries, function(entry)
    return entry.log_placeholder_id ~= log_placeholder.id
  end)
end

---Render a floating window showing placeholder content
---@param placeholder LogPlaceholder
---@param opts? { silent?: boolean }
local function show_placeholder_full_content(placeholder, opts)
  opts = vim.tbl_extend("force", { silent = false }, opts or {})

  local content = placeholder.contents and placeholder.contents[1]
  if not content then
    if not opts.silent then
      utils.notify("Log placeholder has no content", "warn")
    end

    return
  end

  local lines = vim.split(content.body, "\n")
  local win_width = vim.api.nvim_win_get_width(0)
  local win_height = vim.api.nvim_win_get_height(0)

  local content_width = 0
  for _, line in ipairs(lines) do
    content_width = math.max(content_width, #line)
  end

  -- Window width equals to the max of content width, clamp between 20 columns and 50% of screen width
  local width = math.min(math.max(content_width, 20), math.floor(win_width * 0.5))
  -- Window height equals to the min of the number of lines, up to 80% of screen height
  local height = math.min(#lines, math.floor(win_height * 0.8))

  local window_config = {
    relative = "cursor",
    anchor = "SW",
    row = 0,
    col = 0,
    height = height,
    width = width,
    focusable = true,
    style = "minimal",
    border = "single",
    title = content.source_name,
  }

  vim.lsp.util.open_floating_preview(lines, "plaintext", window_config)
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

  local placeholder = M.log_placeholders[placeholder_id]
  if placeholder then
    show_placeholder_full_content(placeholder, { silent = opts.silent })
  else
    error(string.format("Log placeholder %s does not exist", placeholder_id))
  end
end

local function update_placeholders_snippet()
  for _, log_placeholder in pairs(M.log_placeholders) do
    render_placeholder_content(log_placeholder)
  end
end

function M.setup()
  vim.api.nvim_set_hl(0, "Neolog.LogPlaceholderSnippet", { link = "DiagnosticVirtualTextInfo", default = true })
  vim.api.nvim_set_hl(0, "Neolog.LogPlaceholderTime", { italic = true })

  M.log_placeholder_ns = vim.api.nvim_create_namespace("neolog.log_placeholder")

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

  -- Timer loop to keep updating the placeholder snippets
  M.placeholder_render_timer = vim.uv.new_timer()
  M.placeholder_render_timer:start(0, 10000, vim.schedule_wrap(update_placeholders_snippet))
end

return M
