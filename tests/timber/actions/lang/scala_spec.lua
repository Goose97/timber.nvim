local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("scala single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          scala = [[println(s"%log_target: ${%log_target}")]],
        },
      },
    })
  end)

  it("supports val declaration", function()
    helper.assert_scenario({
      input = [[
        val fo|o = "bar"
      ]],
      filetype = "scala",
      action = function()
        actions.insert_log({ position = "below" })
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        println(s"foo: ${foo}")
        val foo = "bar"
        println(s"foo: ${foo}")
      ]],
    })

    helper.assert_scenario({
      input = [[
        val (fo|o, bar) = (1, 2)
      ]],
      filetype = "scala",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        val (foo, bar) = (1, 2)
        println(s"foo: ${foo}")
        println(s"bar: ${bar}")
      ]],
    })
  end)

  it("supports var declaration", function()
    helper.assert_scenario({
      input = [[
        var fo|o = "bar"
      ]],
      filetype = "scala",
      action = function()
        actions.insert_log({ position = "below" })
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        println(s"foo: ${foo}")
        var foo = "bar"
        println(s"foo: ${foo}")
      ]],
    })
  end)

  it("supports variable assignment", function()
    helper.assert_scenario({
      input = [[
        var foo = "bar"
        fo|o = "baz"
      ]],
      filetype = "scala",
      action = function()
        actions.insert_log({ position = "below" })
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        var foo = "bar"
        println(s"foo: ${foo}")
        foo = "baz"
        println(s"foo: ${foo}")
      ]],
    })
  end)

  describe("supports function parameters", function()
    it("supports named function", function()
      helper.assert_scenario({
        input = [[
          def foo(ba|r: Int, baz: String): Int = {
            return bar
          }
        ]],
        filetype = "scala",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          def foo(bar: Int, baz: String): Int = {
            println(s"bar: ${bar}")
            println(s"baz: ${baz}")
            return bar
          }
        ]],
      })
    end)

    it("supports anonymous function", function()
      helper.assert_scenario({
        input = [[
          val sum = (fo|o: Int, bar: Int) => {
            foo + bar
          }
        ]],
        filetype = "scala",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          val sum = (foo: Int, bar: Int) => {
            println(s"foo: ${foo}")
            println(s"bar: ${bar}")
            foo + bar
          }
          println(s"sum: ${sum}")
        ]],
      })
    end)
  end)

  it("DOES NOT support single function name", function()
    helper.assert_scenario({
      input = [[
        val foo = ba|r(1)
      ]],
      filetype = "scala",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        val foo = bar(1)
      ]],
    })

    helper.assert_scenario({
      input = [[
        val foo = bar.ba|z(1)
      ]],
      filetype = "scala",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        val foo = bar.baz(1)
      ]],
    })

    helper.assert_scenario({
      input = [[
        val foo = ba|r.baz(1)
      ]],
      filetype = "scala",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        val foo = bar.baz(1)
        println(s"bar: ${bar}")
      ]],
    })
  end)

  it("supports function return statement", function()
    helper.assert_scenario({
      input = [[
        def test() = {
          val foo = 1
          return fo|o + 1
        }
      ]],
      filetype = "scala",
      action = function()
        actions.insert_log({ position = "below" })
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        def test() = {
          val foo = 1
          println(s"foo: ${foo}")
          return foo + 1
          println(s"foo: ${foo}")
        }
      ]],
    })

    helper.assert_scenario({
      input = [[
        val foo = bar.ba|z(1)
      ]],
      filetype = "scala",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        val foo = bar.baz(1)
      ]],
    })
  end)

  it("supports if statement", function()
    helper.assert_scenario({
      input = [[
        if (fo|o < 0) {
          println("Number is negative")
        } else if (foo == 0) {
          println("Number is zero")
        } else {
          println("Number is positive")
        }
      ]],
      filetype = "scala",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        if (foo < 0) {
          println(s"foo: ${foo}")
          println("Number is negative")
        } else if (foo == 0) {
          println(s"foo: ${foo}")
          println("Number is zero")
        } else {
          println("Number is positive")
        }
      ]],
    })

    helper.assert_scenario({
      input = [[
        if (fo|o < 0) {
          println("Number is negative")
        }
      ]],
      filetype = "scala",
      action = function()
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        println(s"foo: ${foo}")
        if (foo < 0) {
          println("Number is negative")
        }
      ]],
    })
  end)

  it("supports match expression", function()
    helper.assert_scenario({
      input = [[
        fo|o match {
          case 1 => "one"
          case 2 => "two"
          case _ => "many"
        }
      ]],
      filetype = "scala",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        println(s"foo: ${foo}")
        foo match {
          case 1 => "one"
          case 2 => "two"
          case _ => "many"
        }
        println(s"foo: ${foo}")
      ]],
    })

    helper.assert_scenario({
      input = [[
        foo match {
          case |a => {
            println(a)
          }
          case _ => println("something else")
        }
      ]],
      filetype = "scala",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo match {
          case a => {
            println(s"a: ${a}")
            println(a)
          }
          case _ => println("something else")
        }
      ]],
    })
  end)

  it("supports for loop", function()
    helper.assert_scenario({
      input = [[
        for (i| <- 1 to 5) {
          println(i)
        }
      ]],
      filetype = "scala",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        for (i <- 1 to 5) {
          println(s"i: ${i}")
          println(i)
        }
      ]],
    })
  end)

  it("supports while loop", function()
    helper.assert_scenario({
      input = [[
        var count = 0
        while (co|unt < 3) {
          count += 1
        }
      ]],
      filetype = "scala",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        var count = 0
        while (count < 3) {
          println(s"count: ${count}")
          count += 1
        }
      ]],
    })
  end)

  it("supports try/catch expression", function()
    helper.assert_scenario({
      input = [[
        val a = "a"
        try {
          Integer.parseInt(a|)
        } catch {
          case e: NumberFormatException => println("not a number")
        }
      ]],
      filetype = "scala",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        val a = "a"
        try {
          Integer.parseInt(a)
          println(s"a: ${a}")
        } catch {
          case e: NumberFormatException => println("not a number")
        }
      ]],
    })

    helper.assert_scenario({
      input = [[
        try {
          Integer.parseInt("a")
        } catch {
          case |e: NumberFormatException => {
            println("not a number")
          }
        }
      ]],
      filetype = "scala",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        try {
          Integer.parseInt("a")
        } catch {
          case e: NumberFormatException => {
            println(s"e: ${e}")
            println("not a number")
          }
        }
      ]],
    })
  end)

  describe("supports identifier nested in complex expressions", function()
    it("supports class constructor", function()
      helper.assert_scenario({
        input = [[
          val animal = new Dog(na|me)
        ]],
        filetype = "scala",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          val animal = new Dog(name)
          println(s"name: ${name}")
        ]],
      })
    end)

    it("supports function invocations", function()
      helper.assert_scenario({
        input = [[
          foo(ba|r, baz)
        ]],
        filetype = "scala",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo(bar, baz)
          println(s"bar: ${bar}")
          println(s"baz: ${baz}")
        ]],
      })
    end)
  end)

  it("supports member access expression", function()
    helper.assert_scenario({
      input = [[
        val foo = ba|r.baz
      ]],
      filetype = "scala",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        val foo = bar.baz
        println(s"bar: ${bar}")
      ]],
    })

    helper.assert_scenario({
      input = [[
        val foo = bar.ba|z.baf
      ]],
      filetype = "scala",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        val foo = bar.baz.baf
        println(s"bar.baz: ${bar.baz}")
      ]],
    })

    helper.assert_scenario({
      input = [[
        val foo = ba|r.bar
      ]],
      filetype = "scala",
      action = function()
        vim.cmd("normal! v$")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        val foo = bar.bar
        println(s"bar: ${bar}")
      ]],
    })

    helper.assert_scenario({
      input = [[
        val foo = ba|r.bar
      ]],
      filetype = "scala",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        val foo = bar.bar
        println(s"foo: ${foo}")
        println(s"bar.bar: ${bar.bar}")
      ]],
    })
  end)
end)

describe("scala batch log", function()
  it("supports batch log", function()
    timber.setup({
      batch_log_templates = {
        default = {
          scala = [[println(s"%repeat<%log_target=${%log_target}><, >")]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        val fo|o = bar + baz
      ]],
      filetype = "scala",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        val foo = bar + baz
        println(s"foo=${foo}, bar=${bar}, baz=${baz}")
      ]],
    })
  end)
end)
