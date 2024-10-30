local assert = require("luassert")
local watcher = require("neolog.watcher")
local helper = require("tests.neolog.helper")

local function create_temp_file()
  -- Get the system's temporary directory
  local temp_dir = vim.fn.tempname():match("(.*[/\\])")
  local filename = temp_dir .. "neolog_test_" .. os.time()

  -- Create the file
  local file = io.open(filename, "w")
  if file then
    file:close()
  else
    error("Failed to create file: " .. filename)
  end

  return filename
end

local function write_to_file(filename, content)
  local file = io.open(filename, "w")
  if file then
    file:write(content)
    file:close()
    return true
  else
    return false
  end
end

describe("neolog.watcher.sources.setup", function()
  describe("supports filesystem source", function()
    after_each(function()
      require("neolog.watcher.sources").stop()
    end)

    it("supports single line log", function()
      local file_path = create_temp_file()
      local specs = {
        {
          name = "Test log file",
          type = "filesystem",
          path = file_path,
        },
      }

      local received_log_entry = nil

      require("neolog.watcher.sources").setup({
        sources = specs,
        on_log_capture = function(log_entry)
          received_log_entry = log_entry
        end,
      })

      helper.wait(20)
      write_to_file(file_path, "Plain text\n")
      assert.is.Nil(received_log_entry)

      helper.wait(20)
      local start, end_, marker_id = watcher.generate_marker_pairs()
      write_to_file(file_path, string.format("%sHello World%s\n", start, end_))
      helper.wait(20)

      assert.is.Not.Nil(received_log_entry)

      ---@cast received_log_entry -nil
      assert.equals(received_log_entry.log_placeholder_id, marker_id)
      assert.equals(received_log_entry.payload, "Hello World")
      assert.equals(received_log_entry.source_name, "Test log file")
    end)

    it("supports multi line log", function()
      local file_path = create_temp_file()
      local specs = {
        {
          name = "Test log file",
          type = "filesystem",
          path = file_path,
        },
      }

      local received_log_entry = nil

      require("neolog.watcher.sources").setup({
        sources = specs,
        on_log_capture = function(log_entry)
          received_log_entry = log_entry
        end,
      })

      helper.wait(20)
      write_to_file(file_path, "Plain text\n")
      assert.is.Nil(received_log_entry)

      helper.wait(20)
      local start, end_, marker_id = watcher.generate_marker_pairs()
      write_to_file(file_path, string.format("%sHello World\nThis is the second line\nGoodbye World%s\n", start, end_))
      helper.wait(20)

      assert.is.Not.Nil(received_log_entry)

      ---@cast received_log_entry -nil
      assert.equals(received_log_entry.log_placeholder_id, marker_id)
      assert.are.same(
        vim.split(received_log_entry.payload, "\n"),
        { "Hello World", "This is the second line", "Goodbye World" }
      )
      assert.equals(received_log_entry.source_name, "Test log file")
    end)
  end)
end)
