local neolog = require("neolog")
local helper = require("tests.neolog.helper")
local actions = require("neolog.actions")
local assert = require("luassert")

describe("neolog.actions", function()
  before_each(function()
    neolog.setup()
  end)

  it("supports %identifier in label template", function()
    helper.assert_scenario({
      input = [[
          // Comment
          const fo|o = "bar"
        ]],
      filetype = "javascript",
      action = function()
        actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
      end,
      expected = [[
          // Comment
          const foo = "bar"
          console.log("foo", foo)
        ]],
    })
  end)

  it("supports %line_number in label template", function()
    helper.assert_scenario({
      input = [[
          // Comment
          const fo|o = "bar"
        ]],
      filetype = "javascript",
      action = function()
        actions.add_log({ log_template = [[console.log("%line_number", %identifier)]], position = "below" })
      end,
      expected = [[
          // Comment
          const foo = "bar"
          console.log("2", foo)
        ]],
    })
  end)

  describe("supports %insert_cursor in label template", function()
    it("move the the %insert_cursor placeholder and go to insert mode after inserting the log", function()
      helper.assert_scenario({
        input = [[
          const fo|o = "bar"
          const bar = "foo"
        ]],
        filetype = "javascript",
        action = function()
          actions.add_log({
            log_template = [[console.log("%identifier %insert_cursor", %identifier)]],
            position = "below",
          })

          vim.api.nvim_feedkeys("abc", "n", false)
        end,
        expected = function()
          local co = coroutine.running()

          -- Neovim doesn't move into insert mode immediately
          -- Sleep a bit
          vim.defer_fn(function()
            coroutine.resume(co)
          end, 100)

          coroutine.yield()

          local mode = vim.api.nvim_get_mode().mode
          assert.are.same("i", mode)

          local output = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          local expected = {
            [[const foo = "bar"]],
            [[console.log("foo abc", foo)]],
            [[const bar = "foo"]],
          }
          assert.are.same(expected, output)
        end,
      })
    end)

    it("chooses the first statement if there are multiple", function()
      helper.assert_scenario({
        input = [[
          const fo|o = bar + baz
        ]],
        filetype = "javascript",
        action = function()
          vim.cmd("normal! V")
          actions.add_log({
            log_template = [[console.log("%identifier %insert_cursor", %identifier)]],
            position = "below",
          })

          vim.api.nvim_feedkeys("abc", "n", false)
        end,
        expected = function()
          local co = coroutine.running()

          -- Neovim doesn't move into insert mode immediately
          -- Sleep a bit
          vim.defer_fn(function()
            coroutine.resume(co)
          end, 100)

          coroutine.yield()

          local mode = vim.api.nvim_get_mode().mode
          assert.are.same("i", mode)

          local output = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          local expected = {
            [[const foo = bar + baz]],
            [[console.log("foo abc", foo)]],
            [[console.log("bar ", bar)]],
            [[console.log("baz ", baz)]],
          }
          assert.are.same(expected, output)
        end,
      })
    end)
  end)
end)
