local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("odin single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          odin = [[fmt.printf("%log_target: %v\n", %log_target)]],
        },
      },
    })
  end)

  it("supports variable declaration", function()
    helper.assert_scenario({
      input = [[
        fo|o: int = "bar"
      ]],
      filetype = "odin",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        fmt.printf("foo: %v\n", foo)
        foo: int = "bar"
        fmt.printf("foo: %v\n", foo)
      ]],
    })

    helper.assert_scenario({
      input = [[
        main :: proc() {
          fo|o: int = "bar"
        }
      ]],
      filetype = "odin",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        main :: proc() {
          fmt.printf("foo: %v\n", foo)
          foo: int = "bar"
          fmt.printf("foo: %v\n", foo)
        }
      ]],
    })
  end)

  it("supports constant declaration", function()
    helper.assert_scenario({
      input = [[
        PI :: math.PI
      ]],
      filetype = "odin",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        fmt.printf("PI: %v\n", PI)
        PI :: math.PI
        fmt.printf("PI: %v\n", PI)
      ]],
    })
  end)

  it("supports variable assignments", function()
    helper.assert_scenario({
      input = [[
        fo|o := "bar"
      ]],
      filetype = "odin",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        fmt.printf("foo: %v\n", foo)
        foo := "bar"
        fmt.printf("foo: %v\n", foo)
      ]],
    })

    helper.assert_scenario({
      input = [[
        main :: proc() {
          fo|o := "bar"
        }
      ]],
      filetype = "odin",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        main :: proc() {
          fmt.printf("foo: %v\n", foo)
          foo := "bar"
          fmt.printf("foo: %v\n", foo)
        }
      ]],
    })
  end)

  describe("supports function parameters", function()
    it("supports named proc", function()
      helper.assert_scenario({
        input = [[
          foo :: proc(ba|r: string, baz: string) -> int {
            return
          }
        ]],
        filetype = "odin",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo :: proc(bar: string, baz: string) -> int {
            fmt.printf("bar: %v\n", bar)
            fmt.printf("baz: %v\n", baz)
            return
          }
        ]],
      })
    end)

    it("supports anonymous proc", function()
      helper.assert_scenario({
        input = [[
          multiply := proc(a|, b: int) -> int {
            return a * b
          }
        ]],
        filetype = "odin",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          multiply := proc(a, b: int) -> int {
            fmt.printf("a: %v\n", a)
            fmt.printf("b: %v\n", b)
            return a * b
          }
          fmt.printf("multiply: %v\n", multiply)
        ]],
      })
    end)
  end)

  it("supports function call", function()
    helper.assert_scenario({
      input = [[
        foo(b|ar, baz)
      ]],
      filetype = "odin",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo(bar, baz)
        fmt.printf("bar: %v\n", bar)
        fmt.printf("baz: %v\n", baz)
      ]],
    })

    helper.assert_scenario({
      input = [[
        fo|o.bar(baz)
      ]],
      filetype = "odin",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo.bar(baz)
        fmt.printf("foo: %v\n", foo)
      ]],
    })
  end)

  it("supports if else statements", function()
    helper.assert_scenario({
      input = [[
        main :: proc() {
          if fo|o > 1 {
            return true
          } else if bar < 0 {
            return false
          } else {
            return nil
          }
        }
      ]],
      filetype = "odin",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        main :: proc() {
          if foo > 1 {
            fmt.printf("foo: %v\n", foo)
            return true
          } else if bar < 0 {
            fmt.printf("bar: %v\n", bar)
            return false
          } else {
            return nil
          }
        }
      ]],
    })
  end)

  it("supports for loop", function()
    helper.assert_scenario({
      input = [[
        main :: proc() {
          for i := 0; i < le|n; i += 1 {
            continue
          }
        }
      ]],
      filetype = "odin",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        main :: proc() {
          for i := 0; i < len; i += 1 {
            fmt.printf("i: %v\n", i)
            fmt.printf("i: %v\n", i)
            fmt.printf("len: %v\n", len)
            fmt.printf("i: %v\n", i)
            continue
          }
        }
      ]],
    })

    helper.assert_scenario({
      input = [[
        main :: proc() {
          for ite|m, idx in items {
              continue
          }
        }
      ]],
      filetype = "odin",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        main :: proc() {
          for item, idx in items {
              fmt.printf("item: %v\n", item)
              fmt.printf("idx: %v\n", idx)
              fmt.printf("items: %v\n", items)
              continue
          }
        }
      ]],
    })
  end)

  it("supports switch statement", function()
    helper.assert_scenario({
      input = [[
        main :: proc() {
          switch va|l {
          case foo:
            return
          case bar: {
            break
          }
          case:
            return
          }
        }
      ]],
      filetype = "odin",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        main :: proc() {
          switch val {
          case foo:
            fmt.printf("foo: %v\n", foo)
            return
          case bar: {
            fmt.printf("bar: %v\n", bar)
            break
          }
          case:
            return
          }
          fmt.printf("val: %v\n", val)
        }
      ]],
    })
  end)

  describe("supports member access expression", function()
    it("supports dot member access", function()
      helper.assert_scenario({
        input = [[
           foo := ba|r.bar
        ]],
        filetype = "odin",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo := bar.bar
          fmt.printf("bar: %v\n", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          foo := bar.ba|z.baf
        ]],
        filetype = "odin",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo := bar.baz.baf
          fmt.printf("bar.baz: %v\n", bar.baz)
        ]],
      })

      helper.assert_scenario({
        input = [[
          foo := ba|r.bar
        ]],
        filetype = "odin",
        action = function()
          vim.cmd("normal! v$")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo := bar.bar
          fmt.printf("bar: %v\n", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          foo := ba|r.bar
        ]],
        filetype = "odin",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo := bar.bar
          fmt.printf("foo: %v\n", foo)
          fmt.printf("bar.bar: %v\n", bar.bar)
        ]],
      })
    end)

    it("supports bracket member access", function()
      helper.assert_scenario({
        input = [[
          local foo = ba|r["bar"]
        ]],
        filetype = "lua",
        action = function()
          actions.insert_log({ position = "below" })
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
          actions.insert_log({ position = "below" })
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
          actions.insert_log({ position = "below" })
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
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          local foo = bar["bar"]
          print("foo", foo)
          print("bar["bar"]", bar["bar"])
        ]],
      })
    end)
  end)
end)

describe("supports batch log", function()
  it("supports batch log", function()
    timber.setup({
      batch_log_templates = {
        default = {
          odin = [[fmt.printf("%repeat<%log_target: %v><, >\n", %repeat<%log_target><, >)]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        fo|o := bar + baz
      ]],
      filetype = "odin",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        foo := bar + baz
        fmt.printf("foo: %v, bar: %v, baz: %v\n", foo, bar, baz)
      ]],
    })
  end)
end)
