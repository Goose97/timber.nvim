local neolog = require("neolog")
local helper = require("tests.neolog.helper")
local actions = require("neolog.actions")
local assert = require("luassert")

describe("javascript single log", function()
  before_each(function()
    neolog.setup({
      log_templates = {
        default = {
          javascript = [[console.log("%identifier", %identifier)]],
        },
      },
    })
  end)

  it("supports variable declaration", function()
    helper.assert_scenario({
      input = [[
        const fo|o = "bar"
      ]],
      filetype = "javascript",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        const foo = "bar"
        console.log("foo", foo)
      ]],
    })
  end)

  it("supports variable assignment", function()
    helper.assert_scenario({
      input = [[
        const foo = "bar"
        fo|o = "baz"
      ]],
      filetype = "javascript",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        const foo = "bar"
        foo = "baz"
        console.log("foo", foo)
      ]],
    })
  end)

  it("supports array destructuring assignment", function()
    local input = [[
      const [fo|o] = ["bar"]
    ]]

    local expected = [[
      const [foo] = ["bar"]
      console.log("foo", foo)
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "javascript",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = expected,
    })
  end)

  describe("supports object destructuring assignment", function()
    it("supports explicit syntax", function()
      local input = [[
        const { foo: ba|r } = {}
      ]]

      local expected = [[
        const { foo: bar } = {}
        console.log("bar", bar)
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = expected,
      })
    end)

    it("supports shorthand syntax", function()
      local input = [[
        const { fo|o } = {}
      ]]

      local expected = [[
        const { foo } = {}
        console.log("foo", foo)
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = expected,
      })
    end)
  end)

  describe("supports function parameters", function()
    it("supports plain parameters", function()
      local input = [[
        function foo(ba|r) {
          return null
        }
      ]]

      local expected = [[
        function foo(bar) {
          console.log("bar", bar)
          return null
        }
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = expected,
      })

      input = [[
        function foo(bar, ba|z) {
          return null
        }
      ]]

      expected = [[
        function foo(bar, baz) {
          console.log("baz", baz)
          return null
        }
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = expected,
      })
    end)

    it("supports object destructuring parameters", function()
      local input = [[
        function foo({ bar: ba|r }) {
          return null
        }
      ]]

      local expected = [[
        function foo({ bar: bar }) {
          console.log("bar", bar)
          return null
        }
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = expected,
      })
    end)

    it("supports object destructuring shorthand parameters", function()
      local input = [[
        function foo({ ba|r }) {
          return null
        }
      ]]

      local expected = [[
        function foo({ bar }) {
          console.log("bar", bar)
          return null
        }
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = expected,
      })
    end)
  end)

  describe("supports identifier nested in complex expressions", function()
    it("supports ternary operator", function()
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
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = expected1,
      })

      helper.assert_scenario({
        input = input,
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "above" })
        end,
        expected = expected2,
      })
    end)

    it("supports object values", function()
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
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = expected1,
      })

      helper.assert_scenario({
        input = input,
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "above" })
        end,
        expected = expected2,
      })
    end)

    it("supports function invocations", function()
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
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = expected1,
      })

      helper.assert_scenario({
        input = input,
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "above" })
        end,
        expected = expected2,
      })
    end)
  end)

  describe("supports try/catch statement", function()
    it("supports plain parameters", function()
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
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = expected,
      })
    end)

    it("supports object destructuring parameters", function()
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
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = expected,
      })
    end)

    it("supports object destructuring shorthand parameters", function()
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
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = expected,
      })
    end)
  end)

  it("supports if statement", function()
    local input = [[
      if (fo|o > 1 && bar < baz) {
        return null
      }
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "javascript",
      action = function()
        actions.insert_log({ position = "below" })
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
      filetype = "javascript",
      action = function()
        vim.cmd("normal! vi(")
        actions.insert_log({ position = "below" })
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
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
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
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "above" })
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
      helper.assert_scenario({
        input = [[
          switch (foo) {
            case ba|r:
              break
            case "baz":
              break
          }
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
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
        filetype = "javascript",
        action = function()
          vim.cmd("normal! vi{V")
          actions.insert_log({ position = "below" })
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

  describe("supports for loop statement", function()
    it("supports normal for loop", function()
      helper.assert_scenario({
        input = [[
          for (let i = 0; i < fo|o; i++) {
            break
          }
        ]],
        filetype = "javascript",
        action = function()
          vim.cmd("normal! vi(")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          for (let i = 0; i < foo; i++) {
            console.log("i", i)
            console.log("i", i)
            console.log("foo", foo)
            console.log("i", i)
            break
          }
        ]],
      })
    end)

    it("supports for of loop", function()
      helper.assert_scenario({
        input = [[
          for (let fo|o of bar) {
            break
          }
        ]],
        filetype = "javascript",
        action = function()
          vim.cmd("normal! vi(")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          for (let foo of bar) {
            console.log("foo", foo)
            console.log("bar", bar)
            break
          }
        ]],
      })
    end)

    it("supports for in loop", function()
      helper.assert_scenario({
        input = [[
          for (let fo|o in bar) {
            break
          }
        ]],
        filetype = "javascript",
        action = function()
          vim.cmd("normal! vi(")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          for (let foo in bar) {
            console.log("foo", foo)
            console.log("bar", bar)
            break
          }
        ]],
      })
    end)
  end)

  describe("supports import statements", function()
    it("supports plain imports", function()
      helper.assert_scenario({
        input = [[
          import f|oo from 'bar'
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
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
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          console.log("foo", foo)
          import foo from 'bar'
        ]],
      })
    end)

    it("supports named imports", function()
      helper.assert_scenario({
        input = [[
          import { fo|o } from 'bar'
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
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
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          console.log("foo", foo)
          import { foo } from 'bar'
        ]],
      })
    end)

    it("supports named alias imports", function()
      helper.assert_scenario({
        input = [[
          import { foo as b|ar } from 'bar'
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
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
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          console.log("bar", bar)
          import { foo as bar } from 'bar'
        ]],
      })
    end)

    it("supports namespace imports", function()
      helper.assert_scenario({
        input = [[
          import * as f|oo from 'bar'
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
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
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "above" })
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
      helper.assert_scenario({
        input = [[
          const foo = ba|r.bar
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          const foo = bar.bar
          console.log("bar", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          const foo = bar.ba|z.baf
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          const foo = bar.baz.baf
          console.log("bar.baz", bar.baz)
        ]],
      })

      helper.assert_scenario({
        input = [[
          const foo = ba|r.bar
        ]],
        filetype = "javascript",
        action = function()
          vim.cmd("normal! v$")
          actions.insert_log({ position = "below" })
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
        filetype = "javascript",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          const foo = bar.bar
          console.log("foo", foo)
          console.log("bar.bar", bar.bar)
        ]],
      })
    end)

    it("DOES NOT support dot member access as function in call expression", function()
      helper.assert_scenario({
        input = [[
          const foo = bar.bar1.bar2(ba|z.baz1)
        ]],
        filetype = "javascript",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          const foo = bar.bar1.bar2(baz.baz1)
          console.log("foo", foo)
          console.log("baz.baz1", baz.baz1)
        ]],
      })
    end)

    it("supports bracket member access", function()
      helper.assert_scenario({
        input = [[
          const foo = ba|r["bar"]
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          const foo = bar["bar"]
          console.log("bar", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          const foo = bar["ba|z"]["baf"]
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          const foo = bar["baz"]["baf"]
          console.log("bar["baz"]", bar["baz"])
        ]],
      })

      helper.assert_scenario({
        input = [[
          const foo = ba|r["bar"]
        ]],
        filetype = "javascript",
        action = function()
          vim.cmd("normal! v$")
          actions.insert_log({ position = "below" })
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
        filetype = "javascript",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          const foo = bar["bar"]
          console.log("foo", foo)
          console.log("bar["bar"]", bar["bar"])
        ]],
      })
    end)

    it("DOES NOT support bracket member access as function in call expression", function()
      helper.assert_scenario({
        input = [[
          const foo = bar["bar1"]["bar2"](ba|z.baz1)
        ]],
        filetype = "javascript",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          const foo = bar["bar1"]["bar2"](baz.baz1)
          console.log("foo", foo)
          console.log("baz.baz1", baz.baz1)
        ]],
      })
    end)
  end)

  describe("supports visual selection log", function()
    it("supports variable declaration", function()
      helper.assert_scenario({
        input = [[
          const |a = b + c
          const a1 = {b: b1, c: c1}
        ]],
        filetype = "javascript",
        action = function()
          vim.cmd("normal! v$")
          actions.insert_log({ position = "below" })
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
        filetype = "javascript",
        action = function()
          vim.cmd("normal! v$")
          actions.insert_log({ position = "above" })
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
        filetype = "javascript",
        action = function()
          vim.cmd("normal! Vk")
          actions.insert_log({ position = "below" })
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
        filetype = "javascript",
        action = function()
          vim.cmd("normal! Vk")
          actions.insert_log({ position = "above" })
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
      helper.assert_scenario({
        input = [[
          function foo(a, b|, { c: c1, d: d1 }) {
            return null
          }
        ]],
        filetype = "javascript",
        action = function()
          vim.cmd("normal! vi)")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          function foo(a, b, { c: c1, d: d1 }) {
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

describe("javascript batch log", function()
  before_each(function()
    actions.clear_batch()
  end)

  it("supports batch log", function()
    neolog.setup({
      batch_log_templates = {
        default = {
          javascript = [[console.log("Testing %line_number", { %repeat<"%identifier": %identifier><, > })]],
        },
      },
    })

    local input = [[
      const fo|o = "foo"
      const bar = "bar"
      const baz = "baz"
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "javascript",
      action = function()
        vim.cmd("normal! V2j")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        const foo = "foo"
        const bar = "bar"
        const baz = "baz"
        console.log("Testing 4", { "foo": foo, "bar": bar, "baz": baz })
      ]],
    })
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

    helper.assert_scenario({
      input = input,
      filetype = "javascript",
      action = function()
        vim.cmd("normal! V2j")
        actions.add_log_targets_to_batch()
      end,
      expected = function()
        assert.has_error(function()
          actions.insert_batch_log()
        end, "%identifier placeholder can only be used inside %repeat placeholder")
      end,
    })
  end)
end)
