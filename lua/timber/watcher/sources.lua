---Manage sources for watcher
---Sources are data sources that can output log result. Supported sources are:
---  1. Filesystem

---@alias Timber.Watcher.SourceSpecs Timber.Watcher.Sources.FilesystemSpec[]
---
---@class Timber.Watcher.Sources.FilesystemSpec
---@field name string
---@field path string
---@field type "filesystem"

---@class Timber.Watcher.Sources.Opts
---@field sources Timber.Watcher.SourceSpecs
---@field on_log_capture fun(log_entry: Timber.Watcher.LogEntry)

local M = { sources = {} }

---@param opts Timber.Watcher.Sources.Opts
function M.setup(opts)
  for _, source in ipairs(opts.sources) do
    local source_module = require("timber.watcher.sources." .. source.type)
    local source_instance = source_module.new(source, function(placeholder_id, payload)
      opts.on_log_capture({
        log_placeholder_id = placeholder_id,
        payload = payload,
        source_name = source.name,
        timestamp = os.time(),
      })
    end)

    source_instance:start()
    table.insert(M.sources, source_instance)
  end

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = M.stop,
  })
end

function M.stop()
  for _, source in ipairs(M.sources) do
    source:stop()
  end
end

return M
