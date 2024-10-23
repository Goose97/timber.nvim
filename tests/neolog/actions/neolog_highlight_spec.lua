local assert = require("luassert")
local neolog = require("neolog")
local highlight = require("neolog.highlight")
local helper = require("tests.neolog.helper")

describe("neolog.highlight.highlight_add_to_batch", function()
  describe("on_add_to_batch is TRUE", function()
    it("highlights the given node", function()
      highlight.setup({ duration = 100, on_add_to_batch = true })

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

          highlight.highlight_add_to_batch(node)
        end,
        expected = function()
          local bufnr = vim.api.nvim_get_current_buf()
          local extmarks = vim.api.nvim_buf_get_extmarks(
            bufnr,
            highlight.hl_add_to_batch,
            0,
            -1,
            { details = true, type = "highlight" }
          )

          assert.equals(1, #extmarks)

          local _, start_row, start_col, details = unpack(extmarks[1])

          assert.equals(1, start_row)
          assert.equals(6, start_col)
          assert.equals(9, details.end_col)
          assert.equals("NeologAddToBatch", details.hl_group)
        end,
      })
    end)

    it("remove the highlight after the configured duration", function()
      neolog.setup({ duration = 500, on_add_to_batch = true })

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

          highlight.highlight_add_to_batch(node)
        end,
        expected = function()
          local bufnr = vim.api.nvim_get_current_buf()
          helper.wait(750)
          local extmarks = vim.api.nvim_buf_get_extmarks(
            bufnr,
            highlight.hl_add_to_batch,
            0,
            -1,
            { details = true, type = "highlight" }
          )

          assert.equals(0, #extmarks)
        end,
      })
    end)
  end)

  describe("on_add_to_batch is FALSE", function()
    it("DOES NOT highlight the given node", function()
      highlight.setup({ duration = 100, on_add_to_batch = false })

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

          highlight.highlight_add_to_batch(node)
        end,
        expected = function()
          local bufnr = vim.api.nvim_get_current_buf()
          local extmarks = vim.api.nvim_buf_get_extmarks(
            bufnr,
            highlight.hl_add_to_batch,
            0,
            -1,
            { details = true, type = "highlight" }
          )

          assert.equals(0, #extmarks)
        end,
      })
    end)
  end)
end)

describe("neolog.highlight.highlight_insert", function()
  describe("on_insert is TRUE", function()
    it("highlights the given line number", function()
      highlight.setup({ duration = 100, on_insert = true })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "bar"
          console.log("foo", foo)
        ]],
        filetype = "javascript",
        action = function()
          highlight.highlight_insert(3, 3)
        end,
        expected = function()
          local bufnr = vim.api.nvim_get_current_buf()
          local extmarks =
            vim.api.nvim_buf_get_extmarks(bufnr, highlight.hl_insert, 0, -1, { details = true, type = "highlight" })

          assert.equals(1, #extmarks)

          local _, start_row, start_col, details = unpack(extmarks[1])

          assert.equals(2, start_row)
          assert.equals(0, start_col)
          -- Because we are using V mode
          assert.equals(3, details.end_row)
          assert.equals("NeologInsert", details.hl_group)
        end,
      })
    end)

    it("remove the highlight after the configured duration", function()
      highlight.setup({ duration = 500, on_insert = true })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "bar"
          console.log("foo", foo)
        ]],
        filetype = "javascript",
        action = function()
          highlight.highlight_insert(3, 3)
        end,
        expected = function()
          -- Wait till duration passed
          helper.wait(750)

          local bufnr = vim.api.nvim_get_current_buf()
          local extmarks =
            vim.api.nvim_buf_get_extmarks(bufnr, highlight.hl_insert, 0, -1, { details = true, type = "highlight" })

          assert.equals(0, #extmarks)
        end,
      })
    end)
  end)

  describe("on_insert is FALSE", function()
    it("DOES NOT highlight the given line number", function()
      highlight.setup({ duration = 100, on_insert = false })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "bar"
          console.log("foo", foo)
        ]],
        filetype = "javascript",
        action = function()
          highlight.highlight_insert(3)
        end,
        expected = function()
          local bufnr = vim.api.nvim_get_current_buf()
          local extmarks =
            vim.api.nvim_buf_get_extmarks(bufnr, highlight.hl_insert, 0, -1, { details = true, type = "highlight" })

          assert.equals(0, #extmarks)
        end,
      })
    end)
  end)
end)
