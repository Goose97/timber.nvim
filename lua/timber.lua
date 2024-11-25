local config_mod = require("timber.config")
local actions = require("timber.actions")
local highlight = require("timber.highlight")
local buffers = require("timber.buffers")
local watcher = require("timber.watcher")

local M = {}

---@class Timber.InitConfig The optional version of Config
---@field log_templates? { [string]: Timber.LogTemplates }
---@field batch_log_templates? { [string]: Timber.LogTemplates }
---@field keymaps? { [Timber.Action | Timber.Operator]: string }
---@field default_keymaps_enabled? boolean Whether to enable default keymaps. Defaults to `true`
---@param config Timber.InitConfig?
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
