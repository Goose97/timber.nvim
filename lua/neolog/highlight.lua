---@class NeologHighlight
---@field duration number
---@field on_add_to_batch boolean
---@field on_insert_log boolean
---@field hl_insert integer
---@field hl_add_to_batch integer
---@field timer any
local M = {}

---@param log_target TSNode
function M.highlight_add_to_batch(log_target)
  local srow, scol, erow, ecol = log_target:range()
  vim.highlight.range(
    0,
    M.hl_add_to_batch,
    "NeologAddToBatch",
    { srow, scol },
    { erow, ecol },
    { regtype = "v", inclusive = false }
  )

  M.timer:start(
    M.duration,
    0,
    vim.schedule_wrap(function()
      vim.api.nvim_buf_clear_namespace(0, M.hl_add_to_batch, 0, -1)
    end)
  )
end

---@param opts NeologHighlightConfig
function M.setup(opts)
  M.duration = opts.duration
  M.on_add_to_batch = opts.on_add_to_batch
  M.on_insert_log = opts.on_insert_log

  M.hl_insert = vim.api.nvim_create_namespace("neolog.insert_log")
  M.hl_add_to_batch = vim.api.nvim_create_namespace("neolog.add_to_batch")
  M.timer = vim.uv.new_timer()

  vim.api.nvim_set_hl(0, "NeologInsertLog", { link = "Search", default = true })
  vim.api.nvim_set_hl(0, "NeologAddToBatch", { link = "Search", default = true })
end

return M
