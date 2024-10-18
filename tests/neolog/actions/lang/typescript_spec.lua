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
        function foo(bar: string) {
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

      input = [[
        function foo(bar: string, ba|z: number) {
          return null
        }
      ]]

      expected = [[
        function foo(bar: string, baz: number) {
          console.log("baz", baz)
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

    it("supports object destructuring parameters", function()
      local actions = require("neolog.actions")

      local input = [[
        function foo({ bar: ba|r }: string) {
          return null
        }
      ]]

      local expected = [[
        function foo({ bar: bar }: string) {
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

    it("supports object destructuring shorthand parameters", function()
      local actions = require("neolog.actions")

      local input = [[
        function foo({ ba|r }: string) {
          return null
        }
      ]]

      local expected = [[
        function foo({ bar }: string) {
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

    it("supports optional parameters", function()
      local actions = require("neolog.actions")

      local input = [[
        function foo(ba|r?: string) {
          return null
        }
      ]]

      local expected = [[
        function foo(bar?: string) {
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

      input = [[
        function foo(bar?: string, ba|z?: number) {
          return null
        }
      ]]

      expected = [[
        function foo(bar?: string, baz?: number) {
          console.log("baz", baz)
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

  describe("supports identifier nested in complex expressions", function()
    it("supports ternary operator", function()
      local actions = require("neolog.actions")

      local input = [[
        const foo =
          predicate ?
            ba|r :
            baz
      ]]

      local expected1 = [[
        const foo =
          predicate ?
            ba|r :
            baz
        console.log("bar", bar)
      ]]

      local expected2 = [[
        console.log("bar", bar)
        const foo =
          predicate ?
            ba|r :
            baz
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.add_log("%identifier", "below")
        end,
        expected = expected1,
      })

      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.add_log("%identifier", "above")
        end,
        expected = expected2,
      })
    end)

    it("supports object values", function()
      local actions = require("neolog.actions")

      local input = [[
        const foo = {
          bar: bar,
          baz: ba|z,
        }
      ]]

      local expected1 = [[
        const foo = {
          bar: bar,
          baz: ba|z,
        }
        console.log("baz", baz)
      ]]

      local expected2 = [[
        console.log("baz", baz)
        const foo = {
          bar: bar,
          baz: ba|z,
        }
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.add_log("%identifier", "below")
        end,
        expected = expected1,
      })

      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.add_log("%identifier", "above")
        end,
        expected = expected2,
      })
    end)

    it("supports function invocations", function()
      local actions = require("neolog.actions")

      local input = [[
        const foo = foo(bar, ba|z)
      ]]

      local expected1 = [[
        const foo = foo(bar, ba|z)
        console.log("baz", baz)
      ]]

      local expected2 = [[
        console.log("baz", baz)
        const foo = foo(bar, ba|z)
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.add_log("%identifier", "below")
        end,
        expected = expected1,
      })

      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.add_log("%identifier", "above")
        end,
        expected = expected2,
      })
    end)
  end)

  describe("supports try/catch clause", function()
    it("supports plain parameters", function()
      local actions = require("neolog.actions")

      local input = [[
        try {
          throw new Error("foo")
        } catch (err|or) {
          throw error
        }
      ]]

      local expected = [[
        try {
          throw new Error("foo")
        } catch (err|or) {
          console.log("error", error)
          throw error
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
    it("supports object destructuring parameters", function()
      local actions = require("neolog.actions")

      local input = [[
        try {
          throw new Error("foo")
        } catch ({ error: er|r }) {
          throw error
        }
      ]]

      local expected = [[
        try {
          throw new Error("foo")
        } catch ({ error: err }) {
          console.log("err", err)
          throw error
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

    it("supports object destructuring shorthand parameters", function()
      local actions = require("neolog.actions")

      local input = [[
        try {
          throw new Error("foo")
        } catch ({ err|or }) {
          throw error
        }
      ]]

      local expected = [[
        try {
          throw new Error("foo")
        } catch ({ error }) {
          console.log("error", error)
          throw error
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

  describe("supports import statements", function()
    it("supports plain imports", function()
      local actions = require("neolog.actions")

      helper.assert_scenario({
        input = [[
          import f|oo from 'bar'
        ]],
        filetype = "typescript",
        action = function()
          actions.add_log("%identifier", "below")
        end,
        expected = [[
          import foo from 'bar'
          console.log("foo", foo)
        ]],
      })

      helper.assert_scenario({
        input = [[
          import f|oo from 'bar'
        ]],
        filetype = "typescript",
        action = function()
          actions.add_log("%identifier", "above")
        end,
        expected = [[
          console.log("foo", foo)
          import foo from 'bar'
        ]],
      })
    end)

    it("supports named imports", function()
      local actions = require("neolog.actions")

      helper.assert_scenario({
        input = [[
          import { fo|o } from 'bar'
        ]],
        filetype = "typescript",
        action = function()
          actions.add_log("%identifier", "below")
        end,
        expected = [[
          import { foo } from 'bar'
          console.log("foo", foo)
        ]],
      })

      helper.assert_scenario({
        input = [[
          import { fo|o } from 'bar'
        ]],
        filetype = "typescript",
        action = function()
          actions.add_log("%identifier", "above")
        end,
        expected = [[
          console.log("foo", foo)
          import { foo } from 'bar'
        ]],
      })
    end)

    it("supports named alias imports", function()
      local actions = require("neolog.actions")

      helper.assert_scenario({
        input = [[
          import { foo as b|ar } from 'bar'
        ]],
        filetype = "typescript",
        action = function()
          actions.add_log("%identifier", "below")
        end,
        expected = [[
          import { foo as bar } from 'bar'
          console.log("bar", bar)
        ]],
      })
      helper.assert_scenario({
        input = [[
          import { foo as b|ar } from 'bar'
        ]],
        filetype = "typescript",
        action = function()
          actions.add_log("%identifier", "above")
        end,
        expected = [[
          console.log("bar", bar)
          import { foo as bar } from 'bar'
        ]],
      })
    end)

    it("supports namespace imports", function()
      local actions = require("neolog.actions")

      helper.assert_scenario({
        input = [[
          import * as f|oo from 'bar'
        ]],
        filetype = "typescript",
        action = function()
          actions.add_log("%identifier", "below")
        end,
        expected = [[
          import * as foo from 'bar'
          console.log("foo", foo)
        ]],
      })
      helper.assert_scenario({
        input = [[
          import * as f|oo from 'bar'
        ]],
        filetype = "typescript",
        action = function()
          actions.add_log("%identifier", "above")
        end,
        expected = [[
          console.log("foo", foo)
          import * as foo from 'bar'
        ]],
      })
    end)
  end)
end)
