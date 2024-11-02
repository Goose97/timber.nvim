local Job = require("plenary.job")
local watcher = require("timber.watcher")

local M = {}

---@class Timber.Watcher.Sources.Filesystem
---@field name string Name of the source
---@field source string File path
---@field on_log_capture function Callback when receiving log result
---@field pid function File watcher process PID
---@field state.state "initial" | "pending" State of the file stream processor
---@field state.pending_log_item? string Pending log item ID which is being processed
---@field state.buffer string[] Pending log item content. Each string is a line of the file
local SourceFilesystem = { state = { state = "initial", pending_log_item = nil, buffer = {} } }

function SourceFilesystem:start()
  local job = Job:new({
    command = "tail",
    args = { "-f", "-n", "0", self.source },
    on_stdout = function(_, line, _)
      self:ingest(line)
    end,
  })

  job:start()
  self.pid = job.pid
end

function SourceFilesystem:ingest(line)
  if self.state.state == "initial" then
    local start_marker_pattern = string.format("^%s(%s)|", watcher.MARKER, string.rep("[A-Z0-9]", watcher.ID_LENGTH))
    local match = string.match(line, start_marker_pattern)

    if match then
      self.state.state = "pending"
      self.state.pending_log_item = match

      -- Replay the line because it might also contain the end marker
      -- The watcher marker emoji has length of 4 bytes
      local remaining = string.sub(line, watcher.ID_LENGTH + 4 + 2, -1)
      self:ingest(remaining)
    end
  elseif self.state.state == "pending" then
    local pending_log_item = self.state.pending_log_item
    local end_marker_pattern = string.format("|%s$", pending_log_item)
    local match = string.match(line, end_marker_pattern)
    local buffer = self.state.buffer

    if match then
      local remaining = string.sub(line, 1, -(string.len(match) + 1))
      table.insert(buffer, remaining)
      self.on_log_capture(pending_log_item, table.concat(buffer, "\n"))
      self:reset()
    else
      table.insert(buffer, line)
    end
  end
end

function SourceFilesystem:reset()
  self.state.state = "initial"
  self.state.pending_log_item = nil
  self.state.buffer = {}
end

function SourceFilesystem:stop()
  local handle = io.popen("kill " .. self.pid)
  if handle ~= nil then
    handle:close()
  end
end

---@param source_spec Timber.Watcher.Sources.FilesystemSpec
---@param on_log_capture fun(log_entry: Timber.Watcher.LogEntry)
function M.new(source_spec, on_log_capture)
  local o = {
    name = source_spec.name,
    source = source_spec.path,
    on_log_capture = on_log_capture,
  }

  setmetatable(o, SourceFilesystem)
  SourceFilesystem.__index = SourceFilesystem
  return o
end

return M
