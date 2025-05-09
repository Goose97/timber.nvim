local assert = require("luassert")
local timber = require("timber")
local highlight = require("timber.highlight")
local config = require("timber.config")
local helper = require("tests.timber.helper")

describe("timber.highlight._highlight_add_to_batch", function()
  describe("on_add_to_batch is TRUE", function()
    it("highlights the given node", function()
      config.setup({ highlight = { duration = 100, on_add_to_batch = true } })
      highlight.setup()

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "bar"
        ]],
        filetype = "javascript",
        action = function()
          -- Get the identifier node
          local bufnr = vim.api.nvim_get_current_buf()
          local parser = vim.treesitter.get_parser(bufnr, "javascript")
          local tree = parser:parse()[1]
          local root = tree:root()
          local node = root:named_child(1):named_child(0):named_child(0)

          if not node then
            error("Node not found")
          end

          highlight._highlight_add_to_batch(node)
        end,
        expected = function()
          local bufnr = vim.api.nvim_get_current_buf()
          local extmarks =
            vim.api.nvim_buf_get_extmarks(bufnr, highlight.flash_hl_ns, 0, -1, { details = true, type = "highlight" })

          assert.equals(1, #extmarks)

          local _, start_row, start_col, details = unpack(extmarks[1])

          assert.equals(1, start_row)
          assert.equals(6, start_col)
          assert.equals(9, details.end_col)
          assert.equals("Timber.AddToBatch", details.hl_group)
        end,
      })
    end)

    it("remove the highlight after the configured duration", function()
      config.setup({ highlight = { duration = 500, on_add_to_batch = true } })
      timber.setup()

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "bar"
        ]],
        filetype = "javascript",
        action = function()
          -- Get the identifier node
          local bufnr = vim.api.nvim_get_current_buf()
          local parser = vim.treesitter.get_parser(bufnr, "javascript")
          local tree = parser:parse()[1]
          local root = tree:root()
          local node = root:named_child(1):named_child(0):named_child(0)

          if not node then
            error("Node not found")
          end

          highlight._highlight_add_to_batch(node)
        end,
        expected = function()
          local bufnr = vim.api.nvim_get_current_buf()
          helper.wait(750)
          local extmarks =
            vim.api.nvim_buf_get_extmarks(bufnr, highlight.flash_hl_ns, 0, -1, { details = true, type = "highlight" })

          assert.equals(0, #extmarks)
        end,
      })
    end)
  end)

  describe("on_add_to_batch is FALSE", function()
    it("DOES NOT highlight the given node", function()
      config.setup({ highlight = { duration = 100, on_add_to_batch = false } })
      highlight.setup()

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "bar"
        ]],
        filetype = "javascript",
        action = function()
          -- Get the identifier node
          local bufnr = vim.api.nvim_get_current_buf()
          local parser = vim.treesitter.get_parser(bufnr, "javascript")
          local tree = parser:parse()[1]
          local root = tree:root()
          local node = root:named_child(1):named_child(0):named_child(0)

          if not node then
            error("Node not found")
          end

          highlight._highlight_add_to_batch(node)
        end,
        expected = function()
          local bufnr = vim.api.nvim_get_current_buf()
          local extmarks =
            vim.api.nvim_buf_get_extmarks(bufnr, highlight.flash_hl_ns, 0, -1, { details = true, type = "highlight" })

          assert.equals(0, #extmarks)
        end,
      })
    end)
  end)
end)

describe("timber.highlight.highlight_lines", function()
  describe("on_insert is TRUE", function()
    it("highlights the given line number", function()
      config.setup({ highlight = { duration = 100, on_insert = true } })
      highlight.setup()

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "bar"
          console.log("foo", foo)
        ]],
        filetype = "javascript",
        action = function()
          highlight.highlight_lines(0, 3, 3, "Timber.Insert", false)
        end,
        expected = function()
          local bufnr = vim.api.nvim_get_current_buf()
          local extmarks =
            vim.api.nvim_buf_get_extmarks(bufnr, highlight.flash_hl_ns, 0, -1, { details = true, type = "highlight" })

          assert.equals(1, #extmarks)

          local _, start_row, start_col, details = unpack(extmarks[1])

          assert.equals(3, start_row)
          assert.equals(0, start_col)
          -- Because we are using V mode
          assert.equals(3, details.end_row)
          assert.equals("Timber.Insert", details.hl_group)
        end,
      })
    end)

    it("remove the highlight after the configured duration", function()
      config.setup({ highlight = { duration = 500, on_insert = true } })
      highlight.setup()

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "bar"
          console.log("foo", foo)
        ]],
        filetype = "javascript",
        action = function()
          highlight.highlight_lines(0, 3, 3, "Timber.Insert", false)
        end,
        expected = function()
          -- Wait till duration passed
          helper.wait(750)

          local bufnr = vim.api.nvim_get_current_buf()
          local extmarks =
            vim.api.nvim_buf_get_extmarks(bufnr, highlight.flash_hl_ns, 0, -1, { details = true, type = "highlight" })

          assert.equals(0, #extmarks)
        end,
      })
    end)
  end)

  describe("on_insert is FALSE", function()
    it("DOES NOT highlight the given line number", function()
      config.setup({ highlight = { duration = 100, on_insert = false } })
      highlight.setup()

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "bar"
          console.log("foo", foo)
        ]],
        filetype = "javascript",
        action = function()
          highlight.highlight_lines(0, 3, 3, "Timber.Insert", false)
        end,
        expected = function()
          local bufnr = vim.api.nvim_get_current_buf()
          local extmarks =
            vim.api.nvim_buf_get_extmarks(bufnr, highlight.flash_hl_ns, 0, -1, { details = true, type = "highlight" })

          assert.equals(0, #extmarks)
        end,
      })
    end)
  end)
end)
