local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("swift single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          swift = [[print("%log_target:", %log_target)]],
        },
      },
    })
  end)

  it("supports variable declaration", function()
    helper.assert_scenario({
      input = [[
        let fo|o = "bar"
      ]],
      filetype = "swift",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        print("foo:", foo)
        let foo = "bar"
        print("foo:", foo)
      ]],
    })

    helper.assert_scenario({
      input = [[
        var fo|o = "bar"
      ]],
      filetype = "swift",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        print("foo:", foo)
        var foo = "bar"
        print("foo:", foo)
      ]],
    })
  end)

  it("supports variable assignment", function()
    helper.assert_scenario({
      input = [[
        var foo = "bar"
        fo|o = "baz"
      ]],
      filetype = "swift",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        var foo = "bar"
        print("foo:", foo)
        foo = "baz"
        print("foo:", foo)
      ]],
    })
  end)

  it("supports return statement", function()
    helper.assert_scenario({
      input = [[
        func foo() -> Int {
          return bar + b|az
        }
      ]],
      filetype = "swift",
      action = function()
        actions.insert_log({ position = "below" })
        vim.cmd("normal! V")
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        func foo() -> Int {
          print("bar:", bar)
          print("baz:", baz)
          return bar + baz
        }
      ]],
    })
  end)

  it("supports function parameters", function()
    helper.assert_scenario({
      input = [[
        func foo(ba|r: String, baz: String) {
          return nil
        }
      ]],
      filetype = "swift",
      action = function()
        actions.insert_log({ position = "above" })
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        func foo(bar: String, baz: String) {
          print("bar:", bar)
          print("baz:", baz)
          return nil
        }
      ]],
    })
  end)

  it("supports init function parameters", function()
    helper.assert_scenario({
      input = [[
        class Animal {
          var name: String

          init(na|me: String) {
            self.name = name
          }
        }
      ]],
      filetype = "swift",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        class Animal {
          var name: String

          init(name: String) {
            print("name:", name)
            self.name = name
          }
        }
      ]],
    })
  end)

  it("supports lambda function parameters", function()
    helper.assert_scenario({
      input = [[
        let multiply = { (a|: Int, b: Int) -> Int in
          return a * b
        }
      ]],
      filetype = "swift",
      action = function()
        actions.insert_log({ position = "above" })
        vim.cmd("normal! vi(")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        let multiply = { (a: Int, b: Int) -> Int in
          print("a:", a)
          print("b:", b)
          return a * b
        }
      ]],
    })
  end)

  it("supports if-else statement", function()
    helper.assert_scenario({
      input = [[
        if fo|o > bar {
          baz()
        } else if qux {
          quux()
        } else {
          corge()
        }
      ]],
      filetype = "swift",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        if foo > bar {
          print("foo:", foo)
          print("bar:", bar)
          baz()
        } else if qux {
          print("qux:", qux)
          quux()
        } else {
          corge()
        }
      ]],
    })
  end)

  it("supports switch statement", function()
    helper.assert_scenario({
      input = [[
        switch fo|o {
        case .bar:
          baz()
        case .qux:
          quux()
        default:
          corge()
        }
      ]],
      filetype = "swift",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        switch foo {
        case .bar:
          print("bar:", bar)
          baz()
        case .qux:
          print("qux:", qux)
          quux()
        default:
          corge()
        }
        print("foo:", foo)
      ]],
    })
  end)

  it("supports for loop", function()
    helper.assert_scenario({
      input = [[
        for ite|m in items {
          process(item)
        }
      ]],
      filetype = "swift",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        for item in items {
          print("item:", item)
          print("items:", items)
          process(item)
        }
      ]],
    })
  end)

  it("supports while loop", function()
    helper.assert_scenario({
      input = [[
        while conditio|n {
          process()
        }
      ]],
      filetype = "swift",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        while condition {
          print("condition:", condition)
          process()
        }
      ]],
    })
  end)

  it("supports repeat loop", function()
    helper.assert_scenario({
      input = [[
        repeat {
          print("At least once")
        } while fo|o > bar
      ]],
      filetype = "swift",
      action = function()
        actions.insert_log({ position = "below" })
        vim.cmd("normal! V")
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        repeat {
          print("At least once")
          print("foo:", foo)
          print("bar:", bar)
        } while foo > bar
        print("foo:", foo)
      ]],
    })
  end)

  it("supports dot member access", function()
    helper.assert_scenario({
      input = [[
        let foo = ba|r.bar
      ]],
      filetype = "swift",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        let foo = bar.bar
        print("bar:", bar)
      ]],
    })

    helper.assert_scenario({
      input = [[
        let foo = bar.ba|z.baf
      ]],
      filetype = "swift",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        let foo = bar.baz.baf
        print("bar.baz:", bar.baz)
      ]],
    })

    helper.assert_scenario({
      input = [[
        let foo = ba|r.bar
      ]],
      filetype = "swift",
      action = function()
        vim.cmd("normal! v$")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        let foo = bar.bar
        print("bar:", bar)
      ]],
    })

    helper.assert_scenario({
      input = [[
        let foo = ba|r.bar
      ]],
      filetype = "swift",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        let foo = bar.bar
        print("foo:", foo)
        print("bar.bar:", bar.bar)
      ]],
    })
  end)
end)

describe("swift batch log", function()
  it("supports batch log", function()
    timber.setup({
      batch_log_templates = {
        default = {
          swift = [[print("%repeat<%log_target: %log_target><, >")]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        let fo|o = bar + baz
      ]],
      filetype = "swift",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        let foo = bar + baz
        print("foo: foo, bar: bar, baz: baz")
      ]],
    })
  end)
end)
