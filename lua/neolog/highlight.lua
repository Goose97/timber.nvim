---@class NeologHighlight
---@field config NeologHighlightConfig
---@field hl_insert integer
---@field hl_add_to_batch integer
---@field insert_hl_timer any
---@field add_to_batch_hl_timer any
local M = {}

---@param log_target TSNode
function M.highlight_add_to_batch(log_target)
  if not M.config.on_add_to_batch then
    return
  end

  local srow, scol, erow, ecol = log_target:range()
  vim.highlight.range(
    0,
    M.hl_add_to_batch,
    "NeologAddToBatch",
    { srow, scol },
    { erow, ecol },
    { regtype = "v", inclusive = false }
  )

  M.add_to_batch_hl_timer:start(
    M.config.duration,
    0,
    vim.schedule_wrap(function()
      vim.api.nvim_buf_clear_namespace(0, M.hl_add_to_batch, 0, -1)
    end)
  )
end

---@param start_line_number number 0-indexed
---@param end_line_number? number 0-indexed
function M.highlight_insert(start_line_number, end_line_number)
  if not M.config.on_insert then
    return
  end

  vim.highlight.range(
    0,
    M.hl_insert,
    "NeologInsert",
    { start_line_number, 0 },
    { end_line_number or start_line_number, 0 },
    { regtype = "V", inclusive = false }
  )

  M.insert_hl_timer:start(
    M.config.duration,
    0,
    vim.schedule_wrap(function()
      vim.api.nvim_buf_clear_namespace(0, M.hl_insert, 0, -1)
    end)
  )
end

---@param opts NeologHighlightConfig
function M.setup()
  M.config = require("neolog.config").config.highlight

  M.hl_insert = vim.api.nvim_create_namespace("neolog.insert_log")
  M.hl_add_to_batch = vim.api.nvim_create_namespace("neolog.add_to_batch")
  M.insert_hl_timer = vim.uv.new_timer()
  M.add_to_batch_hl_timer = vim.uv.new_timer()

  vim.api.nvim_set_hl(0, "NeologInsert", { link = "Search", default = true })
  vim.api.nvim_set_hl(0, "NeologAddToBatch", { link = "Search", default = true })
end

return M
