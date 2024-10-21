local assert = require("luassert")
local neolog = require("neolog")
local highlight = require("neolog.highlight")
local helper = require("tests.neolog.helper")

describe("neolog.highlight.highlight_add_to_batch", function()
  it("highlights the log targets just added", function()
    highlight.setup({ duration = 100 })

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
        local extmarks =
          vim.api.nvim_buf_get_extmarks(bufnr, highlight.hl_add_to_batch, 0, -1, { details = true, type = "highlight" })

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
    neolog.setup({ duration = 500 })

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
        local extmarks =
          vim.api.nvim_buf_get_extmarks(bufnr, highlight.hl_add_to_batch, 0, -1, { details = true, type = "highlight" })

        assert.equals(0, #extmarks)
      end,
    })
  end)
end)
