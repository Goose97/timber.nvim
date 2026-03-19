local watcher = require("timber.watcher")
local utils = require("timber.utils")

local M = {}

---@class Timber.Watcher.Sources.Neotest
---@field on_log_capture function Callback when receiving log result
local SourceNeotest = {}

function SourceNeotest:start()
  M.singleton = self
end

function SourceNeotest:stop()
  M.singleton = nil
end

---@param text string
function SourceNeotest:capture_log_entries(text)
  local id_pattern = string.format("%s(%s)", watcher.MARKER, string.rep("[A-Z0-9]", watcher.ID_LENGTH))
  local pattern = id_pattern .. "(.-)%1"

  for id, content in string.gmatch(text, pattern) do
    self.on_log_capture(id, content)
  end
end

---@param source_spec Timber.Watcher.Sources.NeotestSpec
---@param on_log_capture fun(log_entry: Timber.Watcher.LogEntry)
function M.new(source_spec, on_log_capture)
  local o = {
    on_log_capture = on_log_capture,
  }

  setmetatable(o, SourceNeotest)
  SourceNeotest.__index = SourceNeotest
  return o
end

function M.consumer(client)
  client.listeners.results = function(_, results, partial)
    if partial then
      return
    end

    if not M.singleton then
      vim.schedule(function()
        utils.notify("Neotest source is not started. Please add neotest source to the watcher config", "warn")
      end)

      return
    end

    local seen = {}

    for _, result in pairs(results) do
      if result.output then
        if not seen[result.output] then
          seen[result.output] = true

          local file = assert(io.open(result.output, "rb"))
          local content = file:read("*all")
          file:close()

          M.singleton:capture_log_entries(content)
        end
      end
    end
  end

  return {}
end

return M
