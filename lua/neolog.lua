local config_mod = require("neolog.config")
local actions = require("neolog.actions")
local highlight = require("neolog.highlight")
local buffers = require("neolog.buffers")
local watcher = require("neolog.watcher")

---@class NeologModule
local M = {}

---@class NeologInitConfig The optional version of Config
---@field log_templates? { [string]: NeologLogTemplates }
---@field batch_log_templates? { [string]: NeologLogTemplates }
---@field keymaps? { [NeologAction | NeologOperator]: string }
---@field default_keymaps_enabled? boolean Whether to enable default keymaps. Defaults to `true`
---@param config NeologInitConfig?
M.setup = function(config)
  config_mod.setup(config)

  actions.setup()
  highlight.setup()

  buffers.setup()
  if config_mod.config.log_watcher.enabled then
    watcher.setup(config_mod.config.log_watcher.sources)
  end
end

return M
