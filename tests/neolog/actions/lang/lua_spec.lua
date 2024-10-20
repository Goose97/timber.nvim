local neolog = require("neolog")
local helper = require("tests.neolog.helper")

describe("lua", function()
  before_each(function()
    neolog.setup()
  end)

  it("supports variable declaration", function()
    local actions = require("neolog.actions")

    local input = [[
      local fo|o = "bar"
    ]]

    local expected = [[
      local foo = "bar"
      print("foo", foo)
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "lua",
      action = function()
        actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
      end,
      expected = expected,
    })

    expected = [[
      print("foo", foo)
      local foo = "bar"
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "lua",
      action = function()
        actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "above" })
      end,
      expected = expected,
    })
  end)

  it("supports variable assignment", function()
    local actions = require("neolog.actions")

    local input = [[
      local foo = "bar"
      fo|o = "baz"
    ]]

    local expected = [[
      local foo = "bar"
      foo = "baz"
      print("foo", foo)
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "lua",
      action = function()
        actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
      end,
      expected = expected,
    })

    expected = [[
      local foo = "bar"
      print("foo", foo)
      foo = "baz"
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "lua",
      action = function()
        actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "above" })
      end,
      expected = expected,
    })
  end)

  it("supports function parameters", function()
    local actions = require("neolog.actions")

    helper.assert_scenario({
      input = [[
        function foo(ba|r)
          return nil
        end
      ]],
      filetype = "lua",
      action = function()
        actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
      end,
      expected = [[
        function foo(bar)
          print("bar", bar)
          return nil
        end
      ]],
    })

    -- TODO: figure out why indentation is off with the closing parenthesis
    helper.assert_scenario({
      input = [[
        local function foo(
          ba|r,
          baz,
        )
          return nil
        end
      ]],
      filetype = "lua",
      action = function()
        vim.cmd("normal! Vj")
        actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "above" })
      end,
      expected = [[
        local function foo(
          bar,
          baz,
          )
          print("bar", bar)
          print("baz", baz)
          return nil
        end
      ]],
    })
  end)

  describe("supports identifier nested in complex expressions", function()
    it("supports ternary operator", function()
      local actions = require("neolog.actions")

      local input = [[
        local foo =
          predicate and
            ba|r or
            baz
      ]]

      local expected1 = [[
        local foo =
          predicate and
            bar or
            baz
            print("bar", bar)
      ]]

      local expected2 = [[
        print("bar", bar)
        local foo =
          predicate and
            bar or
            baz
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "lua",
        action = function()
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
        end,
        expected = expected1,
      })

      helper.assert_scenario({
        input = input,
        filetype = "lua",
        action = function()
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "above" })
        end,
        expected = expected2,
      })
    end)

    it("supports table constructor", function()
      local actions = require("neolog.actions")

      helper.assert_scenario({
        input = [[
        local foo = { bar = b|ar }
      ]],
        filetype = "lua",
        action = function()
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
        local foo = { bar = bar }
        print("bar", bar)
      ]],
      })

      helper.assert_scenario({
        input = [[
        local foo = { b|ar = bar }
      ]],
        filetype = "lua",
        action = function()
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
        local foo = { bar = bar }
      ]],
      })
    end)

    it("supports function invocations", function()
      local actions = require("neolog.actions")

      helper.assert_scenario({
        input = [[
        foo(ba|r, baz)
      ]],
        filetype = "lua",
        action = function()
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
        foo(bar, baz)
        print("bar", bar)
      ]],
      })

      helper.assert_scenario({
        input = [[
        foo(ba|r, baz)
      ]],
        filetype = "lua",
        action = function()
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "above" })
        end,
        expected = [[
        print("bar", bar)
        foo(bar, baz)
      ]],
      })

      helper.assert_scenario({
        input = [[
        foo(ba|r, baz)
      ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! V")
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
        foo(bar, baz)
        print("bar", bar)
        print("baz", baz)
      ]],
      })
    end)
  end)

  describe("supports member access expression", function()
    it("supports dot member access", function()
      local actions = require("neolog.actions")

      helper.assert_scenario({
        input = [[
          local foo = ba|r.bar
        ]],
        filetype = "lua",
        action = function()
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          local foo = bar.bar
          print("bar", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          local foo = bar.ba|z.baf
        ]],
        filetype = "lua",
        action = function()
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          local foo = bar.baz.baf
          print("bar.baz", bar.baz)
        ]],
      })

      helper.assert_scenario({
        input = [[
          local foo = ba|r.bar
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! v$")
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          local foo = bar.bar
          print("bar", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          local foo = ba|r.bar
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! V")
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          local foo = bar.bar
          print("foo", foo)
          print("bar.bar", bar.bar)
        ]],
      })
    end)

    it("supports bracket member access", function()
      local actions = require("neolog.actions")

      helper.assert_scenario({
        input = [[
          local foo = ba|r["bar"]
        ]],
        filetype = "lua",
        action = function()
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          local foo = bar["bar"]
          print("bar", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          local foo = bar["ba|z"]["baf"]
        ]],
        filetype = "lua",
        action = function()
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          local foo = bar["baz"]["baf"]
          print("bar["baz"]", bar["baz"])
        ]],
      })

      helper.assert_scenario({
        input = [[
          local foo = ba|r["bar"]
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! v$")
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          local foo = bar["bar"]
          print("bar", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          local foo = ba|r["bar"]
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! V")
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          local foo = bar["bar"]
          print("foo", foo)
          print("bar["bar"]", bar["bar"])
        ]],
      })
    end)
  end)

  describe("supports visual selection log", function()
    it("supports variable declaration", function()
      local actions = require("neolog.actions")

      helper.assert_scenario({
        input = [[
          local a = b| + c
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! v$")
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          local a = b + c
          print("b", b)
          print("c", c)
        ]],
      })

      helper.assert_scenario({
        input = [[
          local a = b| + c
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! v$")
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "above" })
        end,
        expected = [[
          print("b", b)
          print("c", c)
          local a = b + c
        ]],
      })

      helper.assert_scenario({
        input = [[
          local a = b + c
          local a1 = {b = b|1, c = c1}
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! Vk")
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          local a = b + c
          print("a", a)
          print("b", b)
          print("c", c)
          local a1 = {b = b1, c = c1}
          print("a1", a1)
          print("b1", b1)
          print("c1", c1)
        ]],
      })

      helper.assert_scenario({
        input = [[
          local a = b + c
          local a1 = {b = b|1, c = c1}
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! Vk")
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "above" })
        end,
        expected = [[
          print("a", a)
          print("b", b)
          print("c", c)
          local a = b + c
          print("a1", a1)
          print("b1", b1)
          print("c1", c1)
          local a1 = {b = b1, c = c1}
        ]],
      })
    end)

    it("supports function parameters", function()
      local actions = require("neolog.actions")

      helper.assert_scenario({
        input = [[
          function foo(a, b|, c)
            return nil
          end
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! vi)")
          actions.add_log({ log_template = [[print("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          function foo(a, b, c)
            print("a", a)
            print("b", b)
            print("c", c)
            return nil
          end
        ]],
      })
    end)
  end)
end)
