local neolog = require("neolog")
local helper = require("tests.neolog.helper")

describe("typescript", function()
  before_each(function()
    neolog.setup()
  end)

  it("supports variable declaration", function()
    local actions = require("neolog.actions")

    local input = [[
      const fo|o = "bar"
    ]]

    local expected = [[
      const foo = "bar"
      console.log("foo", foo)
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "typescript",
      action = function()
        actions.add_log("%identifier", "below")
      end,
      expected = expected,
    })
  end)

  it("supports array destructuring assignment", function()
    local actions = require("neolog.actions")

    local input = [[
      const [fo|o] = ["bar"]
    ]]

    local expected = [[
      const [foo] = ["bar"]
      console.log("foo", foo)
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "typescript",
      action = function()
        actions.add_log("%identifier", "below")
      end,
      expected = expected,
    })
  end)

  describe("supports object destructuring assignment", function()
    it("supports explicit syntax", function()
      local actions = require("neolog.actions")

      local input = [[
        const { foo: ba|r } = {}
      ]]

      local expected = [[
        const { foo: bar } = {}
        console.log("bar", bar)
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.add_log("%identifier", "below")
        end,
        expected = expected,
      })
    end)

    it("supports shorthand syntax", function()
      local actions = require("neolog.actions")

      local input = [[
        const { fo|o } = {}
      ]]

      local expected = [[
        const { foo } = {}
        console.log("foo", foo)
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.add_log("%identifier", "below")
        end,
        expected = expected,
      })
    end)
  end)

  describe("supports function parameters", function()
    it("supports plain parameters", function()
      local actions = require("neolog.actions")

      local input = [[
        function foo(ba|r: string) {
          return null
        }
      ]]

      local expected = [[
        function foo(ba|r: string) {
          console.log("bar", bar)
          return null
        }
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.add_log("%identifier", "below")
        end,
        expected = expected,
      })
    end)
  end)
end)
