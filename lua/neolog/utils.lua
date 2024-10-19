local M = {}

function M.array_includes(array, value)
  for _, v in ipairs(array) do
    if v == value then
      return true
    end
  end

  return false
end

function M.get_key_by_value(t, value)
  for k, v in pairs(t) do
    if v == value then
      return k
    end
  end

  return nil
end

function M.dump(o, nest)
  nest = nest or 2
  if type(o) == "table" then
    local s = "{ " .. "\n" .. string.rep(" ", nest)
    for k, v in pairs(o) do
      if type(k) ~= "number" then
        k = '"' .. k .. '"'
      end
      s = s .. "[" .. k .. "] = " .. M.dump(v, nest + 2) .. "," .. "\n" .. string.rep(" ", nest)
    end
    return s .. "} "
  else
    return tostring(o)
  end
end

function M.log(message)
  local log_file_path = "/tmp/nvim_debug.log"
  local log_file = io.open(log_file_path, "a")
  io.output(log_file)
  io.write(M.dump(message) .. "\n")
  io.close(log_file)
end

local function range_start_before(range1, range2)
  if range1[1] == range2[1] then
    return range1[2] < range2[2]
  end

  return range1[1] < range2[1]
end

---Check if two ranges intersect
---@param range1 {[1]: number, [2]: number, [3]: number, [4]: number}
---@param range2 {[1]: number, [2]: number, [3]: number, [4]: number}
---@return boolean
function M.ranges_intersect(range1, range2)
  if range_start_before(range2, range1) then
    return M.ranges_intersect(range2, range1)
  end

  -- range1 starts before range2
  -- For two ranges to intersect, range1 must end after range2 start
  if range1[3] == range2[1] then
    return range1[4] >= range2[2]
  else
    return range1[3] >= range2[1]
  end
end

---Return the 0-indexed range of the selection range
---If is in normal, return the position of the cursor
---If is in visual, return the range of the visual selection
---If is in visual line, return the range of the visual line selection
---@return {[1]: number, [2]: number, [3]: number, [4]: number}
function M.get_selection_range()
  local mode = vim.api.nvim_get_mode().mode
  -- After exiting visual mode, these marks will be available
  -- (1,1)-indexed position
  local result1 = vim.fn.getpos("v")
  local result2 = vim.fn.getpos(".")
  local srow = result1[2]
  local scol = result1[3]
  local erow = result2[2]
  local ecol = result2[3]

  -- If we are selecting visual range from bottom to top (start after end),
  -- swap the start and end
  if srow > erow or srow == erow and scol > ecol then
    local temp = srow
    srow = erow
    erow = temp

    temp = scol
    scol = ecol
    ecol = temp
  end

  if mode == "v" then
    return { srow - 1, scol - 1, erow - 1, ecol - 1 }
  elseif mode == "V" then
    return { srow - 1, 0, erow - 1, vim.v.maxcol }
  else
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    return { cursor_pos[1] - 1, cursor_pos[2], cursor_pos[1] - 1, cursor_pos[2] }
  end
end

return M
