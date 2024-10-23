local M = {}

-- Do nothing.
M.NOOP = function() end

function M.array_find(array, predicate)
  for i, v in ipairs(array) do
    if predicate(v, i) then
      return v
    end
  end

  return nil
end

function M.array_map(array, mapper)
  local result = {}

  for i, v in ipairs(array) do
    table.insert(result, mapper(v, i))
  end

  return result
end

function M.array_filter(array, predicate)
  local result = {}

  for i, v in ipairs(array) do
    if predicate(v, i) then
      table.insert(result, v)
    end
  end

  return result
end

function M.array_any(array, predicate)
  for i, v in ipairs(array) do
    if predicate(v, i) then
      return true
    end
  end

  return false
end

function M.array_group_by(array, key_function, value_function)
  local result = {}

  key_function = key_function or function(v)
    return v
  end

  value_function = value_function or function(v)
    return v
  end

  for _, v in ipairs(array) do
    local key = key_function(v)
    local value = value_function(v)

    if result[key] then
      table.insert(result[key], value)
    else
      result[key] = { value }
    end
  end

  return result
end

function M.array_sort_with_index(array, comparator)
  local with_index = M.array_map(array, function(v, i)
    return { v, i }
  end)

  table.sort(with_index, comparator)

  return M.array_map(with_index, function(item)
    return item[1]
  end)
end

function M.table_values(t)
  local result = {}

  for _, v in pairs(t) do
    table.insert(result, v)
  end

  return result
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

---Check if range1 includes range2
---@param range1 {[1]: number, [2]: number, [3]: number, [4]: number}
---@param range2 {[1]: number, [2]: number, [3]: number, [4]: number}
---@return boolean
function M.range_include(range1, range2)
  if range_start_before(range2, range1) then
    return false
  end

  -- range1 starts before range2
  -- For range1 to include range2, range1 must end after range2 end
  if range1[3] == range2[3] then
    return range1[4] >= range2[4]
  else
    return range1[3] >= range2[3]
  end
end

---Return the 0-indexed range of the selection range
---If is in normal, return the range of the current Treesitter node. If no node found,
---return the position of the cursor
---If is in visual, return the range of the visual selection
---If is in visual line, return the range of the visual line selection
---@return {[1]: number, [2]: number, [3]: number, [4]: number}
function M.get_selection_range()
  local mode = vim.api.nvim_get_mode().mode
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

---Given a Treesitter node, return the (0,0)-indexed range of the node
function M.get_ts_node_range(node)
  local srow, scol, erow, ecol = node:range()
  -- Minus 1 because the end is non-inclusive
  return { srow, scol, erow, ecol - 1 }
end

---Given two Treesitter nodes a and b, check if node_a starts before node_b
---@param node_a TSNode
---@param node_b TSNode
---@return "before" | "equal" | "after"
function M.compare_ts_node_start(node_a, node_b)
  local srow_a, scol_a = node_a:start()
  local srow_b, scol_b = node_b:start()
  if srow_a == srow_b then
    if scol_a == scol_b then
      return "equal"
    elseif scol_a < scol_b then
      return "before"
    else
      return "after"
    end
  end

  if srow_a < srow_b then
    return "before"
  else
    return "after"
  end
end

---Given two Treesitter nodes a and b, check if node_a ends before node_b
---@param node_a TSNode
---@param node_b TSNode
---@return "before" | "equal" | "after"
function M.compare_ts_node_end(node_a, node_b)
  local erow_a, ecol_a = node_a:end_()
  local erow_b, ecol_b = node_b:end_()

  if erow_a == erow_b then
    if ecol_a == ecol_b then
      return "equal"
    elseif ecol_a < ecol_b then
      return "before"
    else
      return "after"
    end
  end

  if erow_a < erow_b then
    return "before"
  else
    return "after"
  end
end

---Trim the redundant whitespaces from the input lines and calculate indentation
---@param input string
---@return string[]
function M.process_multiline_string(input)
  -- Remove trailing whitespaces
  input = input:gsub("%s+$", "")
  local lines = vim.split(input, "\n", { trimempty = true })
  local smallest_indent

  for _, line in ipairs(lines) do
    -- Count the number of leading whitespaces
    -- Don't consider indent of empty lines
    local leading_whitespaces = line:match("^%s*")
    if #leading_whitespaces ~= line:len() then
      smallest_indent = smallest_indent and math.min(smallest_indent, #leading_whitespaces) or #leading_whitespaces
    end
  end

  return M.array_map(lines, function(line)
    return line:sub(smallest_indent + 1)
  end)
end

---@param message string|string[]
---@param level "info" | "warn" | "error"
function M.notify(message, level)
  -- Construct message chunks
  local message_with_hl = type(message) == "string" and { { message } } or message
  ---@cast message_with_hl string[]

  local hl_group = {
    info = "None",
    warn = "WarningMsg",
    error = "ErrorMsg",
  }
  table.insert(message_with_hl, 1, { "(neolog) ", hl_group[level] })

  -- Echo. Force redraw to ensure that it is effective (`:h echo-redraw`)
  vim.cmd([[echo '' | redraw]])
  vim.api.nvim_echo(message_with_hl, true, {})
end

return M
