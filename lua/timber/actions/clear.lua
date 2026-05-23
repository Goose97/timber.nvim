local M = {}

local config = require("timber.config")
local utils = require("timber.utils")
local log_statements = require("timber.actions.log_statements")

-- Statement node types that typically contain log statements
local STATEMENT_TYPES = {
  -- JavaScript/TypeScript
  expression_statement = true,
  lexical_declaration = true,
  variable_declaration = true,
  -- Lua
  function_call = true,
  -- Python
  call = true,
  -- Go
  call_expression = true,
  -- Ruby
  method_call = true,
  -- Rust
  macro_invocation = true,
  -- Generic
  statement = true,
}

--- Find the statement node that contains the given position
---@param bufnr number
---@param line number 0-indexed line number
---@param log_marker string
---@return number start_line 0-indexed
---@return number end_line 0-indexed (exclusive)
local function find_statement_range(bufnr, line, log_marker)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    -- Fallback to single line if no parser
    return line, line + 1
  end

  -- Get the line content to find the marker position
  local line_content = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1] or ""
  local col = line_content:find(log_marker, 1, true)
  if not col then
    col = 0
  else
    col = col - 1 -- Convert to 0-indexed
  end

  -- Get the node at the marker position
  local node = vim.treesitter.get_node({ bufnr = bufnr, pos = { line, col } })
  if not node then
    return line, line + 1
  end

  -- Walk up the tree to find a statement node
  local current = node
  while current do
    local node_type = current:type()
    if STATEMENT_TYPES[node_type] then
      local start_row, _, end_row, _ = current:range()
      return start_row, end_row + 1
    end
    current = current:parent()
  end

  -- Fallback to single line if no statement found
  return line, line + 1
end

-- Using grep to search all files globally
local function clear_global(log_marker)
  local processed = {}
  local deleted_ranges = {} -- Track deleted ranges per buffer to avoid double-deletion

  for bufnr, lnum in log_statements.iter_global(log_marker) do
    deleted_ranges[bufnr] = deleted_ranges[bufnr] or {}

    -- Check if this line was already deleted as part of a multi-line statement
    local already_deleted = false
    for _, range in ipairs(deleted_ranges[bufnr]) do
      if lnum >= range[1] and lnum <= range[2] then
        already_deleted = true
        break
      end
    end

    if not already_deleted then
      local start_line, end_line = find_statement_range(bufnr, lnum - 1, log_marker)
      -- Adjust for previously deleted lines
      local offset = 0
      for _, range in ipairs(deleted_ranges[bufnr]) do
        if range[1] <= start_line then
          offset = offset + (range[2] - range[1] + 1)
        end
      end
      start_line = start_line - offset
      end_line = end_line - offset

      vim.api.nvim_buf_set_lines(bufnr, start_line, end_line, false, {})
      table.insert(deleted_ranges[bufnr], { lnum, lnum + (end_line - start_line - 1) })

      if not processed[bufnr] then
        processed[bufnr] = true
      end
    end
  end

  -- Save all modified buffers
  for bufnr, _ in pairs(processed) do
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd("silent! write")
    end)
  end
end

---@param opts {global: boolean}
function M.clear(opts)
  local log_marker = config.config.log_marker

  if not log_marker or log_marker == "" then
    utils.notify("config.log_marker is not configured", "warn")
    return
  end

  if opts.global then
    clear_global(log_marker)
  else
    local bufnr = vim.api.nvim_get_current_buf()
    local deleted_ranges = {}

    for linenr in log_statements.iter_local(log_marker) do
      -- Check if this line was already deleted as part of a multi-line statement
      local already_deleted = false
      for _, range in ipairs(deleted_ranges) do
        if linenr >= range[1] and linenr <= range[2] then
          already_deleted = true
          break
        end
      end

      if not already_deleted then
        local start_line, end_line = find_statement_range(bufnr, linenr - 1, log_marker)
        -- Adjust for previously deleted lines
        local offset = 0
        for _, range in ipairs(deleted_ranges) do
          if range[1] <= start_line + 1 then -- range uses 1-indexed
            offset = offset + (range[2] - range[1] + 1)
          end
        end
        start_line = start_line - offset
        end_line = end_line - offset

        vim.api.nvim_buf_set_lines(bufnr, start_line, end_line, false, {})
        table.insert(deleted_ranges, { linenr, linenr + (end_line - start_line - 1) })
      end
    end
  end
end

return M
