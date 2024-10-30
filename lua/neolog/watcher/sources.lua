---Manage sources for watcher
---Sources are data sources that can output log result. Supported sources are:
---  1. Filesystem

---@class SourceFilesystemSpec
---@field name string
---@field path string
---@field type "filesystem"

---@class NeologSourcesOpts
---@field sources SourceFilesystemSpec[]
---@field on_log_capture fun(log_entry: WatcherLogEntry)

local M = { sources = {} }

---@param opts NeologSourcesOpts
function M.setup(opts)
  for _, source in ipairs(opts.sources) do
    local source_module = require("neolog.watcher.sources." .. source.type)
    local source_instance = source_module.new(source, opts.on_log_capture)

    source_instance:start()
    table.insert(M.sources, source_instance)
  end
end

function M.stop()
  for _, source in ipairs(M.sources) do
    source:stop()
  end
end

return M
