local actions = require("neolog.actions")

---@alias NeologLogTemplates { [string]: string }

---@class Config
---@field log_templates NeologLogTemplates
local default_config = {
  log_templates = {
    javascript = [[console.log("%label", %identifier)]],
    typescript = [[console.log("%label", %identifier)]],
    jsx = [[console.log("%label", %identifier)]],
    tsx = [[console.log("%label", %identifier)]],
    lua = [[print("%label", %identifier)]],
  },
}

---@class MyModule
---@field config Config
local M = {}

---@param config Config?
M.setup = function(config)
  M.config = vim.tbl_deep_extend("force", default_config, config or {})

  actions.setup(M.config.log_templates)
end

return M
