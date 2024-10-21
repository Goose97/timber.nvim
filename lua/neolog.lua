local actions = require("neolog.actions")

---@alias Template string

---@alias NeologLogTemplates { [string]: Template }

---@class Config
---@field log_templates { [string]: NeologLogTemplates }
---@field batch_log_templates { [string]: NeologLogTemplates }

---@type Config
local default_config = {
  log_templates = {
    default = {
      javascript = [[console.log("%identifier", %identifier)]],
      typescript = [[console.log("%identifier", %identifier)]],
      jsx = [[console.log("%identifier", %identifier)]],
      tsx = [[console.log("%identifier", %identifier)]],
      lua = [[print("%identifier", %identifier)]],
    },
  },
  batch_log_templates = {
    default = {
      javascript = [[console.log({ %repeat<"%identifier": %identifier><, > })]],
      typescript = [[console.log({ %repeat<"%identifier": %identifier><, > })]],
      jsx = [[console.log({ %repeat<"%identifier": %identifier><, > })]],
      tsx = [[console.log({ %repeat<"%identifier": %identifier><, > })]],
    },
  },
}

---@class MyModule
---@field config Config
local M = {}

---@class InitConfig The optional version of Config
---@field log_templates? { [string]: NeologLogTemplates }
---@field batch_log_templates? { [string]: NeologLogTemplates }
---@param config InitConfig?
M.setup = function(config)
  M.config = vim.tbl_deep_extend("force", default_config, config or {})

  actions.setup(M.config.log_templates, M.config.batch_log_templates)
end

return M
