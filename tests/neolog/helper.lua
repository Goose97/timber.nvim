local assert = require("luassert")

local M = {}

---Setup a buffer with the given input and filetype.
---@param lines string[]
---@param cursor {[1]: number, [2]: number}?
---@param filetype string
local function setup_buffer(lines, cursor, filetype)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("filetype", filetype, { buf = buf })
  vim.api.nvim_set_option_value("shiftwidth", 2, { buf = buf })

  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
  -- vim.api.nvim_command("buffer " .. buf)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_exec_autocmds("BufRead", { buffer = buf })
  if cursor then
    vim.api.nvim_win_set_cursor(0, cursor)
  end
end

---Assert the output of the current buffer.
---@param lines string[]
local function assert_buf_output(lines)
  local output = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  assert.are.same(lines, output)
end

---Trim the redundant whitespaces from the input lines.
---@param input string
---@param parse_cursor? boolean
---@return string[], {[1]: number, [2]: number}?
local function parse_input(input, parse_cursor)
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

  local cursor

  for i, line in ipairs(lines) do
    line = line:sub(smallest_indent + 1)

    if parse_cursor then
      local start_index = line:find("|")
      if start_index then
        cursor = { i, start_index - 2 }
        line = line:sub(1, cursor[2] + 1) .. line:sub(cursor[2] + 3)
      end
    end

    lines[i] = line
  end

  return lines, cursor
end

---@class Scenario
---@field input string
---@field input_cursor? boolean
---@field filetype string
---@field action function?
---@field expected string | function

---Given an input, execute a callback, and assert the expected output.
---The input supports specifying the cursor position with a pipe character.
---The cursor will be on the letter before the pipe character.
---In this example, the cursor is at position {1, 7} (at the first o in foo)
---  const fo|o = "bar"
---  const bar = "baz"
---@param scenario Scenario
function M.assert_scenario(scenario)
  scenario = vim.tbl_extend("force", { input_cursor = true }, scenario)

  local input_lines, cursor = parse_input(scenario.input, scenario.input_cursor)
  local utils = require("neolog.utils")
  setup_buffer(input_lines, cursor, scenario.filetype)

  if scenario.action then
    scenario.action()
  end

  local expected = scenario.expected
  if type(expected) == "function" then
    expected()
  else
    local expected_lines, cursor1 = parse_input(expected, scenario.input_cursor)

    if cursor1 then
      error("Unexpected cursor position in scenario.expected")
    end

    assert_buf_output(expected_lines)
  end
end

---@param duration number in milliseconds
function M.wait(duration)
  local co = coroutine.running()

  -- Neovim doesn't move into visual mode immediately
  -- Sleep a bit
  vim.defer_fn(function()
    coroutine.resume(co)
  end, duration)

  coroutine.yield()
end

return M
