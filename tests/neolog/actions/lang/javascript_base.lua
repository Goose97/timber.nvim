local helper = require("tests.neolog.helper")
local actions = require("neolog.actions")

---@param language string
local run = function(language)
  it("supports variable declaration", function()
    helper.assert_scenario({
      input = [[
        const fo|o = "bar"
      ]],
      filetype = language,
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
      filetype = language,
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
      filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        console.log("baz", baz)
        function foo(bar, baz) {
          return null
        }
      ]]

      helper.assert_scenario({
        input = input,
        filetype = language,
        action = function()
          actions.insert_log({ position = "above" })
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = expected1,
      })

      helper.assert_scenario({
        input = input,
        filetype = language,
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
        filetype = language,
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = expected1,
      })

      helper.assert_scenario({
        input = input,
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
      filetype = language,
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
      filetype = language,
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

    helper.assert_scenario({
      input = input,
      filetype = language,
      action = function()
        vim.cmd("normal! vi(")
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        console.log("foo", foo)
        console.log("bar", bar)
        console.log("baz", baz)
        if (foo > 1 && bar < baz) {
          return null
        }
      ]],
    })
  end)

  it("supports arguments in call expression", function()
    helper.assert_scenario({
      input = [[
        foo(ba|r, baz)
      ]],
      filetype = language,
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo(bar, baz)
        console.log("bar", bar)
        console.log("baz", baz)
      ]],
    })

    helper.assert_scenario({
      input = [[
        foo.bar(ba|z)
      ]],
      filetype = language,
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo.bar(baz)
        console.log("baz", baz)
      ]],
    })

    helper.assert_scenario({
      input = [[
        foo.bar(ba|z).then(baf)
      ]],
      filetype = language,
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo.bar(baz).then(baf)
        console.log("baz", baz)
        console.log("baf", baf)
      ]],
    })

    helper.assert_scenario({
      input = [[
        foo({ foo: foo, bar: bar.b|az }).then(baf)
      ]],
      filetype = language,
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo({ foo: foo, bar: bar.baz }).then(baf)
        console.log("foo", foo)
        console.log("bar.baz", bar.baz)
        console.log("baf", baf)
      ]],
    })
  end)

  describe("supports for loop statement", function()
    it("supports normal for loop", function()
      helper.assert_scenario({
        input = [[
          for (let i = 0; i < fo|o; i++) {
            break
          }
        ]],
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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

  describe("supports while loop statement", function()
    it("supports while loop", function()
      helper.assert_scenario({
        input = [[
          while (fo|o > 1 && bar < baz) {
            return null
          }
        ]],
        filetype = language,
        action = function()
          vim.cmd("normal! vi(")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          while (foo > 1 && bar < baz) {
            console.log("foo", foo)
            console.log("bar", bar)
            console.log("baz", baz)
            return null
          }
        ]],
      })
    end)

    it("DOES NOT support while loop with single expression body", function()
      helper.assert_scenario({
        input = [[
          while (fo|o > 1 && bar < baz) foo += 1
        ]],
        filetype = language,
        action = function()
          vim.cmd("normal! vi(")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          while (foo > 1 && bar < baz) foo += 1
        ]],
      })
    end)

    it("supports do while loop", function()
      helper.assert_scenario({
        input = [[
          do {
            foo -= 1
          } while (fo|o > bar)
        ]],
        filetype = language,
        action = function()
          vim.cmd("normal! vi(")
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          do {
            console.log("foo", foo)
            console.log("bar", bar)
            foo -= 1
          } while (foo > bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          do {
            foo -= 1
          } while (fo|o > bar)
        ]],
        filetype = "javascript",
        action = function()
          vim.cmd("normal! vi(")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          do {
            foo -= 1
          } while (foo > bar)
          console.log("foo", foo)
          console.log("bar", bar)
        ]],
      })
    end)

    it("DOES NOT support do while loop with single expression body", function()
      helper.assert_scenario({
        input = [[
          do
            foo -= 1
          while (fo|o > bar)
        ]],
        filetype = language,
        action = function()
          vim.cmd("normal! vi(")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          do
            foo -= 1
          while (foo > bar)
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
        filetype = language,
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
end

return run
