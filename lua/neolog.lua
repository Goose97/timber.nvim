local actions = require("neolog.actions")
local highlight = require("neolog.highlight")

---@class NeologModule
local M = {}

---@class NeologInitConfig The optional version of Config
---@field log_templates? { [string]: NeologLogTemplates }
---@field batch_log_templates? { [string]: NeologLogTemplates }
---@field keymaps? { [NeologAction | NeologOperator]: string }
---@field default_keymaps_enabled? boolean Whether to enable default keymaps. Defaults to `true`
---@param config NeologInitConfig?
M.setup = function(config)
  require("neolog.config").setup(config)

  actions.setup()
  highlight.setup()
end

return M
