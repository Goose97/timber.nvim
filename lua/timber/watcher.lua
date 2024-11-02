---@class Timber.Watcher.LogEntry
---@field log_placeholder_id string
---@field payload string
---@field source_name string
---@field timestamp integer

---@alias Timber.Watcher.LogPlaceholderId string

local sources = require("timber.watcher.sources")
local buffers = require("timber.buffers")

local M = { MARKER = "🪵", ID_LENGTH = 3 }

function M.generate_unique_id()
  local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  local id = ""

  for _ = 1, M.ID_LENGTH, 1 do
    local random_index = math.random(1, #chars)
    id = id .. string.sub(chars, random_index, random_index)
  end

  return id
end

---Generate marker start and end strings
---@return string start_marker, string end_marker, string marker_id
function M.generate_marker_pairs()
  local id = M.generate_unique_id()
  local start = M.MARKER .. id .. "|"
  local end_ = "|" .. id
  return start, end_, id
end

function M.stop()
  sources.stop()
end

---@param source_specs Timber.Watcher.SourceSpecs
function M.setup(source_specs)
  math.randomseed(os.time())

  sources.setup({
    sources = source_specs,
    on_log_capture = function(log_entry)
      buffers.receive_log_entry(log_entry)
    end,
  })
end

return M
