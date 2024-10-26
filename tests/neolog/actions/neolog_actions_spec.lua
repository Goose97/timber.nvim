local assert = require("luassert")
local spy = require("luassert.spy")
local neolog = require("neolog")
local actions = require("neolog.actions")
local utils = require("neolog.utils")
local highlight = require("neolog.highlight")
local helper = require("tests.neolog.helper")

describe("neolog.actions.insert_log", function()
  before_each(function()
    neolog.setup()
  end)

  it("supports %identifier in log template", function()
    neolog.setup({
      log_templates = {
        testing = {
          javascript = [[console.log("%identifier", %identifier)]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
          // Comment
          const fo|o = "bar"
        ]],
      filetype = "javascript",
      action = function()
        actions.insert_log({ template = "testing", position = "below" })
      end,
      expected = [[
          // Comment
          const foo = "bar"
          console.log("foo", foo)
        ]],
    })
  end)

  it("supports %line_number in log template", function()
    neolog.setup({
      log_templates = {
        testing = {
          javascript = [[console.log("%line_number", %identifier)]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
          // Comment
          const fo|o = "bar"
        ]],
      filetype = "javascript",
      action = function()
        actions.insert_log({ template = "testing", position = "below" })
      end,
      expected = [[
          // Comment
          const foo = "bar"
          console.log("2", foo)
        ]],
    })
  end)

  describe("supports %insert_cursor in log template", function()
    describe("move the the %insert_cursor placeholder and go to insert mode after inserting the log", function()
      it("supports single line template", function()
        neolog.setup({
          log_templates = {
            testing = {
              javascript = [[console.log("%identifier %insert_cursor", %identifier)]],
            },
          },
        })

        helper.assert_scenario({
          input = [[
          const fo|o = "bar"
          const bar = "foo"
        ]],
          filetype = "javascript",
          action = function()
            actions.insert_log({
              template = "testing",
              position = "below",
            })

            vim.defer_fn(function()
              vim.api.nvim_feedkeys("abc", "n", false)
            end, 0)
          end,
          expected = function()
            helper.wait(20)

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

        -- Wait for Neovim to actually stop insert mode
        vim.cmd("stopinsert")
        helper.wait(20)
      end)

      it("supports single line template", function()
        neolog.setup({
          log_templates = {
            testing = {
              javascript = [[
                // Comment above
                console.log("%identifier %insert_cursor", %identifier)
                // Comment below
              ]],
            },
          },
        })

        helper.assert_scenario({
          input = [[
            const fo|o = "bar"
            const bar = "foo"
          ]],
          filetype = "javascript",
          action = function()
            actions.insert_log({
              template = "testing",
              position = "below",
            })

            vim.defer_fn(function()
              vim.api.nvim_feedkeys("abc", "n", false)
            end, 0)
          end,
          expected = function()
            helper.wait(20)

            local mode = vim.api.nvim_get_mode().mode
            assert.are.same("i", mode)

            local output = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            local expected = {
              [[const foo = "bar"]],
              [[// Comment above]],
              [[console.log("foo abc", foo)]],
              [[// Comment below]],
              [[const bar = "foo"]],
            }
            assert.are.same(expected, output)
          end,
        })

        -- Wait for Neovim to actually stop insert mode
        vim.cmd("stopinsert")
        helper.wait(20)
      end)
    end)

    it("chooses the first statement if there are multiple", function()
      neolog.setup({
        log_templates = {
          testing = {
            javascript = [[console.log("%identifier %insert_cursor", %identifier)]],
          },
        },
      })

      helper.assert_scenario({
        input = [[
          const fo|o = bar + baz
        ]],
        filetype = "javascript",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({
            template = "testing",
            position = "below",
          })

          vim.defer_fn(function()
            vim.api.nvim_feedkeys("abc", "n", false)
          end, 0)
        end,
        expected = function()
          helper.wait(20)

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

      -- Wait for Neovim to actually stop insert mode
      vim.cmd("stopinsert")
      helper.wait(20)
    end)
  end)

  describe("supports log template that doesn't contain %identifier", function()
    it("inserts the log statement at the above line if position is 'above'", function()
      neolog.setup({
        log_templates = {
          plain = {
            javascript = [[console.log("Custom log %line_number")]],
          },
        },
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ template = "plain", position = "below" })
        end,
        expected = [[
          // Comment
          const foo = "bar"
          console.log("Custom log 3")
        ]],
      })
    end)
    it("inserts the log statement at the above line if position is 'above'", function()
      neolog.setup({
        log_templates = {
          plain = {
            javascript = [[console.log("Custom log %line_number")]],
          },
        },
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ template = "plain", position = "above" })
        end,
        expected = [[
          // Comment
          console.log("Custom log 2")
          const foo = "bar"
        ]],
      })
    end)
  end)

  describe("a log target belongs to multiple log containers", function()
    it("chooses the deepest container", function()
      neolog.setup({
        log_templates = {
          testing = {
            javascript = [[console.log("Testing", %identifier)]],
          },
        },
      })

      local input = [[
        const foo = {
          bar: () => {
            const ba|z = 123
          },
        };
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "javascript",
        action = function()
          actions.insert_log({ template = "testing", position = "below" })
        end,
        expected = [[
          const foo = {
            bar: () => {
              const baz = 123
              console.log("Testing", baz)
            },
          };
        ]],
      })

      helper.assert_scenario({
        input = input,
        filetype = "javascript",
        action = function()
          vim.cmd("normal! Vap")
          actions.insert_log({ template = "testing", position = "below" })
        end,
        expected = [[
          const foo = {
            bar: () => {
              const baz = 123
              console.log("Testing", baz)
            },
          };
          console.log("Testing", foo)
        ]],
      })
    end)
  end)

  it("calls highlight.highlight_insert for inserted line", function()
    neolog.setup()

    local highlight_spy = spy.on(highlight, "highlight_insert")

    helper.assert_scenario({
      input = [[
          // Comment
          const fo|o = "foo"
        ]],
      filetype = "javascript",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = function()
        assert.spy(highlight_spy).was_called(1)
        assert.spy(highlight_spy).was_called_with(2, 2)
      end,
    })

    highlight_spy:clear()

    helper.assert_scenario({
      input = [[
          // Comment
          const fo|o = bar + baz
        ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = function()
        assert.spy(highlight_spy).was_called(3)
        assert.spy(highlight_spy).was_called_with(2, 2)
        assert.spy(highlight_spy).was_called_with(3, 3)
        assert.spy(highlight_spy).was_called_with(4, 4)
      end,
    })

    highlight_spy:clear()
  end)

  it("supports dot repeat", function()
    helper.assert_scenario({
      input = [[
        // Comment
        const fo|o = bar + baz
      ]],
      filetype = "javascript",
      action = function()
        actions.insert_log({ position = "below" })
        vim.cmd("normal! 2w.2w.")
      end,
      expected = [[
        // Comment
        const foo = bar + baz
        console.log("baz", baz)
        console.log("bar", bar)
        console.log("foo", foo)
      ]],
    })
  end)

  describe("handles user errors", function()
    it("notifies when the filetype is not recognized", function()
      local notify_spy = spy.on(utils, "notify")

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = bar + baz
        ]],
        filetype = "unknown",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert.spy(notify_spy).was_called_with("Treesitter cannot determine language for current buffer", "error")
          notify_spy:clear()
        end,
      })
    end)

    it("notifies when the log template is not found", function()
      local notify_spy = spy.on(utils, "notify")

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = bar + baz
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ template = "unknown", position = "below" })
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert.spy(notify_spy).was_called_with("Log template 'unknown' is not found", "error")
          notify_spy:clear()
        end,
      })
    end)

    it("notifies when the filetype is not recognized", function()
      neolog.setup({
        log_templates = {
          testing = {},
        },
      })
      local notify_spy = spy.on(utils, "notify")

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = bar + baz
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ template = "testing", position = "below" })
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert
            .spy(notify_spy)
            .was_called_with("Log template 'testing' does not have 'javascript' language template", "error")
          notify_spy:clear()
        end,
      })
    end)
  end)

  describe("preserves the cursor position after inserting", function()
    it("supports single line template", function()
      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = function()
          local cursor_position = vim.fn.getpos(".")
          assert.are.same({ 2, 8 }, vim.list_slice(cursor_position, 2, 3))
        end,
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "above" })
        end,
        expected = function()
          local cursor_position = vim.fn.getpos(".")
          assert.are.same({ 3, 8 }, vim.list_slice(cursor_position, 2, 3))
        end,
      })
    end)

    it("supports multi line template", function()
      neolog.setup({
        log_templates = {
          default = {
            javascript = [[
              console.group("Test")
              console.log("FOO")
              console.log("%identifier", %identifier)
              console.groupEnd()
            ]],
          },
        },
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = function()
          local cursor_position = vim.fn.getpos(".")
          assert.are.same({ 2, 8 }, vim.list_slice(cursor_position, 2, 3))
        end,
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "above" })
        end,
        expected = function()
          local cursor_position = vim.fn.getpos(".")
          assert.are.same({ 6, 8 }, vim.list_slice(cursor_position, 2, 3))
        end,
      })
    end)
  end)

  it("supports multi lines template", function()
    neolog.setup({
      log_templates = {
        default = {
          javascript = [[
            console.group("Test")
            console.log("FOO")
            console.log("%identifier", %identifier)
            console.groupEnd()
          ]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        // Comment
        const fo|o = "foo"
        const bar = "bar"
      ]],
      filetype = "javascript",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        // Comment
        const foo = "foo"
        console.group("Test")
        console.log("FOO")
        console.log("foo", foo)
        console.groupEnd()
        const bar = "bar"
      ]],
    })
  end)

  describe("supports surround log", function()
    it("specifies before and after templates", function()
      neolog.setup({
        log_templates = {
          testing1 = {
            javascript = [[console.log("Testing")]],
          },
          testing2 = {
            javascript = [[console.log("%identifier", %identifier)]],
          },
        },
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "surround", templates = { before = "testing1", after = "testing2" } })
        end,
        expected = [[
          // Comment
          console.log("Testing")
          const foo = "foo"
          console.log("foo", foo)
          const bar = "bar"
        ]],
      })
    end)

    it("defaults to `default` if not specified before and after templates", function()
      neolog.setup({
        log_templates = {
          default = {
            javascript = [[console.log("%identifier", %identifier)]],
          },
        },
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "surround", templates = {} })
        end,
        expected = [[
          // Comment
          console.log("foo", foo)
          const foo = "foo"
          console.log("foo", foo)
          const bar = "bar"
        ]],
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "surround", templates = { after = "default" } })
        end,
        expected = [[
          // Comment
          console.log("foo", foo)
          const foo = "foo"
          console.log("foo", foo)
          const bar = "bar"
        ]],
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "surround", templates = { before = "default" } })
        end,
        expected = [[
          // Comment
          console.log("foo", foo)
          const foo = "foo"
          console.log("foo", foo)
          const bar = "bar"
        ]],
      })
    end)

    it("notifies when templates is used with position other than 'surround'", function()
      neolog.setup()

      local notify_spy = spy.on(utils, "notify")
      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "above", templates = { before = "default", after = "default" } })
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert.spy(notify_spy).was_called_with("'templates' can only be used with position 'surround'", "warn")
          notify_spy:clear()
        end,
      })
    end)

    it("notifies when position is 'surround' but DOES NOT specify templates", function()
      neolog.setup()

      local notify_spy = spy.on(utils, "notify")
      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "surround" })
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert.spy(notify_spy).was_called_with("'templates' must be specified when position is 'surround'", "error")
          notify_spy:clear()
        end,
      })
    end)
  end)

  it("supports operator mode", function()
    vim.keymap.set("n", "gl", function()
      return actions.insert_log({ operator = true, position = "below" })
    end, { expr = true })

    helper.assert_scenario({
      input = [[
        function foo(ba|r, baz) {
          return null
        }
      ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal gli(")
      end,
      expected = [[
        function foo(bar, baz) {
          console.log("bar", bar)
          console.log("baz", baz)
          return null
        }
      ]],
    })

    helper.assert_scenario({
      input = [[
        const foo = "foo"
        const bar = "ba|r"
      ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal glk")
      end,
      expected = [[
        const foo = "foo"
        console.log("foo", foo)
        const bar = "bar"
        console.log("bar", bar)
      ]],
    })
  end)
end)

describe("neolog.actions.insert_batch_log", function()
  before_each(function()
    neolog.setup({
      log_templates = {
        default = {
          javascript = [[console.log("%identifier", %identifier)]],
        },
      },
    })
    actions.clear_batch()
  end)

  it("supports adding log targets to the batch, getting batch size, and clearing batch", function()
    local input = [[
      // Comment
      const fo|o = "foo"
      const bar = "bar"
      const baz = "baz"
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "javascript",
      action = function()
        actions.add_log_targets_to_batch()
      end,
      expected = function()
        assert.are.same(1, actions.get_batch_size())
        actions.clear_batch()
        assert.are.same(0, actions.get_batch_size())
      end,
    })

    helper.assert_scenario({
      input = input,
      filetype = "javascript",
      action = function()
        vim.cmd("normal! V2j")
        actions.add_log_targets_to_batch()
      end,
      expected = function()
        assert.are.same(3, actions.get_batch_size())
        actions.clear_batch()
        assert.are.same(0, actions.get_batch_size())
      end,
    })
  end)

  it("supports insert batch log with auto_add", function()
    helper.assert_scenario({
      input = [[
        // Comment
        const foo = "foo"
        const bar = "bar"
        const ba|z = "baz"
      ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal! V2k")
        actions.insert_batch_log({ auto_add = true })
      end,
      expected = [[
        // Comment
        const foo = "foo"
        const bar = "bar"
        const baz = "baz"
        console.log({ "foo": foo, "bar": bar, "baz": baz })
      ]],
    })

    helper.assert_scenario({
      input = [[
        function foo(bar, ba|z) {
          return null
        }
      ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal! V")
        actions.insert_batch_log({ auto_add = true })
      end,
      expected = [[
        function foo(bar, baz) {
          console.log({ "bar": bar, "baz": baz })
          return null
        }
      ]],
    })
  end)

  it("exits Visual mode after adding targets to the batch", function()
    local input = [[
      // Comment
      const fo|o = "foo"
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "javascript",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
      end,
      expected = function()
        local mode = vim.api.nvim_get_mode().mode
        assert.are.same("n", mode)
      end,
    })
  end)

  it("clears log batch after insert the log", function()
    local input = [[
      // Comment
      const fo|o = "foo"
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "javascript",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = function()
        assert.are.same(0, actions.get_batch_size())
      end,
    })
  end)

  it("notifies when batch is empty", function()
    local input = [[
      // Comment
      const fo|o = "foo"
    ]]

    local notify_spy = spy.on(utils, "notify")

    helper.assert_scenario({
      input = input,
      filetype = "javascript",
      action = function()
        actions.insert_batch_log()
      end,
      expected = function()
        assert.spy(notify_spy).was_called(1)
        assert.spy(notify_spy).was_called_with("Log batch is empty", "warn")
      end,
    })

    notify_spy:clear()
  end)

  it("only supports %identifier inside %repeat", function()
    neolog.setup({
      batch_log_templates = {
        default = {
          javascript = [[console.log("%identifier", { %repeat<"%identifier": %identifier><, > })]],
        },
      },
    })

    local input = [[
      const fo|o = "foo"
      const bar = "bar"
      const baz = "baz"
    ]]

    local notify_spy = spy.on(utils, "notify")

    helper.assert_scenario({
      input = input,
      filetype = "javascript",
      action = function()
        vim.cmd("normal! V2j")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = function()
        assert.spy(notify_spy).was_called(1)
        assert
          .spy(notify_spy)
          .was_called_with("Cannot use %identifier placeholder outside %repeat placeholder", "error")
        notify_spy:clear()
      end,
    })
  end)

  it("supports dot repeat", function()
    local input = [[
      // Comment
      const fo|o = "foo"
    ]]

    local notify_spy = spy.on(utils, "notify")

    helper.assert_scenario({
      input = input,
      filetype = "javascript",
      action = function()
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        // Comment
        const foo = "foo"
        console.log({ "foo": foo })
      ]],
    })

    -- Dot repeat the action. Now the batch is empty, it should notify the user
    vim.cmd("normal! .")
    assert.spy(notify_spy).was_called(1)
    assert.spy(notify_spy).was_called_with("Log batch is empty", "warn")
    notify_spy:clear()
  end)

  describe("handles user errors", function()
    it("notifies when the filetype is not recognized", function()
      local notify_spy = spy.on(utils, "notify")

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = bar + baz
        ]],
        filetype = "unknown",
        action = function()
          actions.add_log_targets_to_batch()
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert.spy(notify_spy).was_called_with("Treesitter cannot determine language for current buffer", "error")
          notify_spy:clear()
        end,
      })
    end)

    it("notifies when the log template is not found", function()
      local notify_spy = spy.on(utils, "notify")

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = bar + baz
        ]],
        filetype = "javascript",
        action = function()
          actions.add_log_targets_to_batch()
          actions.insert_batch_log({ template = "unknown" })
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert.spy(notify_spy).was_called_with("Log template 'unknown' is not found", "error")
          notify_spy:clear()
        end,
      })
    end)

    it("notifies when the filetype is not recognized", function()
      local notify_spy = spy.on(utils, "notify")

      neolog.setup({
        batch_log_templates = {
          testing = {},
        },
      })
      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = bar + baz
        ]],
        filetype = "javascript",
        action = function()
          actions.add_log_targets_to_batch()
          actions.insert_batch_log({ template = "testing" })
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert
            .spy(notify_spy)
            .was_called_with("Batch log template 'testing' does not have 'javascript' language template", "error")
          notify_spy:clear()
        end,
      })
    end)
  end)

  it("supports operator mode", function()
    vim.keymap.set("n", "gl", function()
      return actions.insert_batch_log({ operator = true })
    end, { expr = true })

    helper.assert_scenario({
      input = [[
        function foo(ba|r, baz) {
          return null
        }
      ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal gli(")
      end,
      expected = [[
        function foo(bar, baz) {
          console.log({ "bar": bar, "baz": baz })
          return null
        }
      ]],
    })

    helper.assert_scenario({
      input = [[
        const foo = "foo"
        const bar = "ba|r"
        const baz = "baz"
      ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal glip")
      end,
      expected = [[
        const foo = "foo"
        const bar = "bar"
        const baz = "baz"
        console.log({ "foo": foo, "bar": bar, "baz": baz })
      ]],
    })
  end)
end)

describe("neolog.actions.add_log_targets_to_batch", function()
  before_each(function()
    neolog.setup()
    actions.clear_batch()
  end)

  it("calls highlight.highlight_add_to_batch for each target", function()
    local highlight_spy = spy.on(highlight, "highlight_add_to_batch")

    helper.assert_scenario({
      input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal! Vj")
        actions.add_log_targets_to_batch()
      end,
      expected = function()
        assert.spy(highlight_spy).was_called(2)
      end,
    })

    highlight_spy:clear()
  end)

  it("preserves the cursor position after adding in visual mode", function()
    helper.assert_scenario({
      input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal! Vj")
        actions.add_log_targets_to_batch()
      end,
      expected = function()
        assert.are.same(2, actions.get_batch_size())

        local cursor_position = vim.fn.getpos(".")
        assert.are.same({ 3, 8 }, vim.list_slice(cursor_position, 2, 3))
      end,
    })
  end)

  it("supports dot repeat", function()
    helper.assert_scenario({
      input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
      filetype = "javascript",
      action = function()
        actions.add_log_targets_to_batch()
        vim.cmd("normal! j.")
      end,
      expected = function()
        assert.are.same(2, actions.get_batch_size())
      end,
    })
  end)

  describe("handles user errors", function()
    it("notifies when the filetype is not recognized", function()
      local notify_spy = spy.on(utils, "notify")

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = bar + baz
        ]],
        filetype = "unknown",
        action = function()
          actions.add_log_targets_to_batch()
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert.spy(notify_spy).was_called_with("Treesitter cannot determine language for current buffer", "error")
          notify_spy:clear()
        end,
      })
    end)
  end)

  it("supports operator mode", function()
    vim.keymap.set("n", "gl", function()
      return actions.add_log_targets_to_batch({ operator = true })
    end, { expr = true })

    helper.assert_scenario({
      input = [[
        const fo|oooo = "foo"
        const barrrrr = "bar"
        const bazzzzz = "baz"
      ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal glip")
      end,
      expected = function()
        assert.are.same(3, actions.get_batch_size())
      end,
    })
  end)
end)
