local actions = require("neolog.actions")

---@alias NeologLogTemplates { [string]: string }

---@class Config
---@field log_templates NeologLogTemplates
local default_config = {
  log_templates = {
    javascript = [[console.log("%identifier", %identifier)]],
    typescript = [[console.log("%identifier", %identifier)]],
    jsx = [[console.log("%identifier", %identifier)]],
    tsx = [[console.log("%identifier", %identifier)]],
    lua = [[print("%identifier", %identifier)]],
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
