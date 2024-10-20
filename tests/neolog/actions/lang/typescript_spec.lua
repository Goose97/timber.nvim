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
        actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
      end,
      expected = expected,
    })
  end)

  it("supports variable assignment", function()
    local actions = require("neolog.actions")

    helper.assert_scenario({
      input = [[
        const foo = "bar"
        fo|o = "baz"
      ]],
      filetype = "typescript",
      action = function()
        actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
      end,
      expected = [[
        const foo = "bar"
        foo = "baz"
        console.log("foo", foo)
      ]],
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
        actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
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
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
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
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
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
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
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
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
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
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
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
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
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
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
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
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
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
            bar :
            baz
        console.log("bar", bar)
      ]]

      local expected2 = [[
        console.log("bar", bar)
        const foo =
          predicate ?
            bar :
            baz
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
        end,
        expected = expected1,
      })

      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "above" })
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
          baz: baz,
        }
        console.log("baz", baz)
      ]]

      local expected2 = [[
        console.log("baz", baz)
        const foo = {
          bar: bar,
          baz: baz,
        }
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
        end,
        expected = expected1,
      })

      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "above" })
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
        const foo = foo(bar, baz)
        console.log("baz", baz)
      ]]

      local expected2 = [[
        console.log("baz", baz)
        const foo = foo(bar, baz)
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
        end,
        expected = expected1,
      })

      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "above" })
        end,
        expected = expected2,
      })
    end)
  end)

  describe("supports try/catch statement", function()
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
        } catch (error) {
          console.log("error", error)
          throw error
        }
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
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
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
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
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
        end,
        expected = expected,
      })
    end)
  end)

  it("supports if statement", function()
    local actions = require("neolog.actions")

    local input = [[
      if (fo|o > 1 && bar < baz) {
        return null
      }
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "typescript",
      action = function()
        actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
      end,
      expected = [[
        if (foo > 1 && bar < baz) {
          console.log("foo", foo)
          return null
        }
      ]],
    })

    helper.assert_scenario({
      input = input,
      filetype = "typescript",
      action = function()
        vim.cmd("normal! vi(")
        actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
      end,
      expected = [[
        if (foo > 1 && bar < baz) {
          console.log("foo", foo)
          console.log("bar", bar)
          console.log("baz", baz)
          return null
        }
      ]],
    })
  end)

  describe("supports switch statement", function()
    it("supports switch head", function()
      local actions = require("neolog.actions")

      local input = [[
        switch (fo|o) {
          case bar:
            break
          case "baz":
            break
        }
      ]]

      -- This is invalid syntax but it's a delibarate choice
      -- We want the switch statement log contaienr to be more granular
      -- So instead of matching the whole switch statement, we match against switch head
      -- and individual clauses
      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          switch (foo) {
            console.log("foo", foo)
            case bar:
              break
            case "baz":
              break
          }
        ]],
      })

      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "above" })
        end,
        expected = [[
          console.log("foo", foo)
          switch (foo) {
            case bar:
              break
            case "baz":
              break
          }
        ]],
      })
    end)

    it("supports switch clause", function()
      local actions = require("neolog.actions")

      helper.assert_scenario({
        input = [[
          switch (foo) {
            case ba|r:
              break
            case "baz":
              break
          }
        ]],
        filetype = "typescript",
        action = function()
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          switch (foo) {
            case bar:
              console.log("bar", bar)
              break
            case "baz":
              break
          }
        ]],
      })

      -- TODO: figure out why indentation is off with inner switch clause
      helper.assert_scenario({
        input = [[
          switch (foo) {
            case (ba|r + baz): {
              break
            }
            case "baz":
              const baz = "baz"
              break
          }
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal! vi{V")
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          switch (foo) {
            case (bar + baz): {
              console.log("bar", bar)
              console.log("baz", baz)
              break
            }
            case "baz":
              const baz = "baz"
            console.log("baz", baz)
              break
          }
        ]],
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
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
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
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "above" })
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
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
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
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "above" })
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
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
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
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "above" })
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
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
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
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "above" })
        end,
        expected = [[
          console.log("foo", foo)
          import * as foo from 'bar'
        ]],
      })
    end)
  end)

  describe("supports member access expression", function()
    it("supports dot member access", function()
      local actions = require("neolog.actions")

      helper.assert_scenario({
        input = [[
          const foo = ba|r.bar
        ]],
        filetype = "typescript",
        action = function()
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          const foo = bar.bar
          console.log("bar", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          const foo = ba|r.bar
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal! v$")
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          const foo = bar.bar
          console.log("bar", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          const foo = ba|r.bar
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal! V")
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          const foo = bar.bar
          console.log("foo", foo)
          console.log("bar.bar", bar.bar)
        ]],
      })
    end)

    it("supports bracket member access", function()
      local actions = require("neolog.actions")

      helper.assert_scenario({
        input = [[
          const foo = ba|r["bar"]
        ]],
        filetype = "typescript",
        action = function()
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          const foo = bar["bar"]
          console.log("bar", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          const foo = ba|r["bar"]
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal! v$")
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          const foo = bar["bar"]
          console.log("bar", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          const foo = ba|r["bar"]
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal! V")
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          const foo = bar["bar"]
          console.log("foo", foo)
          console.log("bar["bar"]", bar["bar"])
        ]],
      })
    end)
  end)

  describe("supports visual selection log", function()
    it("supports variable declaration", function()
      local actions = require("neolog.actions")

      helper.assert_scenario({
        input = [[
          const |a = b + c
          const a1 = {b: b1, c: c1}
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal! v$")
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          const a = b + c
          console.log("a", a)
          console.log("b", b)
          console.log("c", c)
          const a1 = {b: b1, c: c1}
        ]],
      })

      helper.assert_scenario({
        input = [[
          const |a = b + c
          const a1 = {b: b1, c: c1}
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal! v$")
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "above" })
        end,
        expected = [[
          console.log("a", a)
          console.log("b", b)
          console.log("c", c)
          const a = b + c
          const a1 = {b: b1, c: c1}
        ]],
      })

      helper.assert_scenario({
        input = [[
          const a = b + c
          const a1 = {b: b|1, c: c1}
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal! Vk")
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          const a = b + c
          console.log("a", a)
          console.log("b", b)
          console.log("c", c)
          const a1 = {b: b1, c: c1}
          console.log("a1", a1)
          console.log("b1", b1)
          console.log("c1", c1)
        ]],
      })

      helper.assert_scenario({
        input = [[
          const a = b + c
          const a1 = {b: b|1, c: c1}
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal! Vk")
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "above" })
        end,
        expected = [[
          console.log("a", a)
          console.log("b", b)
          console.log("c", c)
          const a = b + c
          console.log("a1", a1)
          console.log("b1", b1)
          console.log("c1", c1)
          const a1 = {b: b1, c: c1}
        ]],
      })
    end)

    it("supports function parameters", function()
      local actions = require("neolog.actions")

      helper.assert_scenario({
        input = [[
          function foo(a: string, b: st|ring, { c: c1, d: d1 }: any) {
            return null
          }
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal! vi)")
          actions.add_log({ log_template = [[console.log("%identifier", %identifier)]], position = "below" })
        end,
        expected = [[
          function foo(a: string, b: string, { c: c1, d: d1 }: any) {
            console.log("a", a)
            console.log("b", b)
            console.log("c1", c1)
            console.log("d1", d1)
            return null
          }
        ]],
      })
    end)
  end)
end)
