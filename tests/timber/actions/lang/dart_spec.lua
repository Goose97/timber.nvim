local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("dart single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          dart = [[print("%log_target: ${%log_target}");]],
        },
      },
    })
  end)

  it("supports variable declaration", function()
    helper.assert_scenario({
      input = [[
        void main() {
          var fo|o = "bar";
        }
      ]],
      filetype = "dart",
      action = function()
        actions.insert_log({ position = "below" })
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        void main() {
          print("foo: ${foo}");
          var foo = "bar";
          print("foo: ${foo}");
        }
      ]],
    })

    helper.assert_scenario({
      input = [[
        void main() {
          var fo|o = 1, bar = 2, baz = 3;
        }
      ]],
      filetype = "dart",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        void main() {
          var foo = 1, bar = 2, baz = 3;
          print("foo: ${foo}");
          print("bar: ${bar}");
          print("baz: ${baz}");
        }
      ]],
    })
  end)

  it("supports variable assignment", function()
    helper.assert_scenario({
      input = [[
        void main() {
          var foo = "bar";
          fo|o = "baz";
        }
      ]],
      filetype = "dart",
      action = function()
        actions.insert_log({ position = "below" })
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        void main() {
          var foo = "bar";
          print("foo: ${foo}");
          foo = "baz";
          print("foo: ${foo}");
        }
      ]],
    })
  end)

  describe("supports function parameters", function()
    it("supports named function", function()
      helper.assert_scenario({
        input = [[
          void foo(int ba|r, String baz) {
            return;
          }
        ]],
        filetype = "dart",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          void foo(int bar, String baz) {
            print("bar: ${bar}");
            print("baz: ${baz}");
            return;
          }
        ]],
      })
    end)

    it("supports anonymous function", function()
      helper.assert_scenario({
        input = [[
          var sum = (int fo|o, int bar) {
            return foo + bar;
          };
        ]],
        filetype = "dart",
        action = function()
          vim.cmd("normal! vi(")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          var sum = (int foo, int bar) {
            print("foo: ${foo}");
            print("bar: ${bar}");
            return foo + bar;
          };
        ]],
      })
    end)

    it("supports method function", function()
      helper.assert_scenario({
        input = [[
          class Foo {
            int Sum(int ba|r) {
              return bar;
            }
          }
        ]],
        filetype = "dart",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          class Foo {
            int Sum(int bar) {
              print("bar: ${bar}");
              return bar;
            }
          }
        ]],
      })
    end)
  end)

  -- it("DOES NOT support single function name", function()
  --   helper.assert_scenario({
  --     input = [[
  --       var foo = ba|r(1);
  --     ]],
  --     filetype = "dart",
  --     action = function()
  --       actions.insert_log({ position = "below" })
  --     end,
  --     expected = [[
  --       var foo = bar(1);
  --     ]],
  --   })
  --
  --   helper.assert_scenario({
  --     input = [[
  --       var foo = bar.ba|z(1);
  --     ]],
  --     filetype = "dart",
  --     action = function()
  --       actions.insert_log({ position = "below" })
  --     end,
  --     expected = [[
  --       var foo = bar.baz(1);
  --     ]],
  --   })
  --
  --   helper.assert_scenario({
  --     input = [[
  --       var foo = ba|r.baz(1);
  --     ]],
  --     filetype = "dart",
  --     action = function()
  --       actions.insert_log({ position = "below" })
  --     end,
  --     expected = [[
  --       var foo = bar.baz(1);
  --       print("bar: ${bar}");
  --     ]],
  --   })
  -- end)
  --
  it("supports function return statement", function()
    helper.assert_scenario({
      input = [[
        void test() {
          var foo = 1;
          return fo|o + 1;
        }
      ]],
      filetype = "dart",
      action = function()
        actions.insert_log({ position = "below" })
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        void test() {
          var foo = 1;
          print("foo: ${foo}");
          return foo + 1;
          print("foo: ${foo}");
        }
      ]],
    })
  end)

  it("supports if statement", function()
    helper.assert_scenario({
      input = [[
        if (fo|o < 0) {
          print("Number is negative");
        } else if (foo == 0) {
          print("Number is zero");
        } else {
          print("Number is positive");
        }
      ]],
      filetype = "dart",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        if (foo < 0) {
          print("foo: ${foo}");
          print("Number is negative");
        } else if (foo == 0) {
          print("Number is zero");
        } else {
          print("Number is positive");
        }
      ]],
    })

    helper.assert_scenario({
      input = [[
        if (foo < 0) {
          print("Number is negative");
        } else if (fo|o == 0) {
          print("Number is zero");
        } else {
          print("Number is positive");
        }
      ]],
      filetype = "dart",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        if (foo < 0) {
          print("Number is negative");
        } else if (foo == 0) {
          print("foo: ${foo}");
          print("Number is zero");
        } else {
          print("Number is positive");
        }
      ]],
    })
  end)

  it("supports switch statement", function()
    helper.assert_scenario({
      input = [[
        void main() {
          switch (fo|o) {
          case 1:
            return foo + 1;
          case 2:
            return foo + 2;
          default:
            return foo + 3;
          }
        }
      ]],
      filetype = "dart",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        void main() {
          print("foo: ${foo}");
          switch (foo) {
          case 1:
            return foo + 1;
          case 2:
            return foo + 2;
          default:
            return foo + 3;
          }
          print("foo: ${foo}");
        }
      ]],
    })

    helper.assert_scenario({
      input = [[
        void main() {
          var a = 1;
          switch (foo) {
          case a|: {
            return foo + 1;
          }
          case 2:
            return foo + 2;
          default:
            return foo + 3;
          }
        }
      ]],
      filetype = "dart",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        void main() {
          var a = 1;
          switch (foo) {
          case a: {
            print("a: ${a}");
            return foo + 1;
          }
          case 2:
            return foo + 2;
          default:
            return foo + 3;
          }
        }
      ]],
    })
  end)

  it("supports for loop statement", function()
    helper.assert_scenario({
      input = [[
        void main() {
          for (var i| = 0; i < 5; i++) {
            print("Count: ${i}");
          }
        }
      ]],
      filetype = "dart",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        void main() {
          for (var i = 0; i < 5; i++) {
            print("i: ${i}");
            print("i: ${i}");
            print("i: ${i}");
            print("Count: ${i}");
          }
        }
      ]],
    })
  end)

  it("supports while loop", function()
    helper.assert_scenario({
      input = [[
        var count = 0;
        while (co|unt < 3) {
          count++;
        }
      ]],
      filetype = "dart",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        var count = 0;
        while (count < 3) {
          print("count: ${count}");
          count++;
        }
      ]],
    })
  end)

  it("supports for-in loop", function()
    helper.assert_scenario({
      input = [[
        void main() {
          var numbers = [1, 2, 3, 4, 5];
          for (var val|ue in numbers) {
            return;
          }
        }
      ]],
      filetype = "dart",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        void main() {
          var numbers = [1, 2, 3, 4, 5];
          for (var value in numbers) {
            print("value: ${value}");
            print("numbers: ${numbers}");
            return;
          }
        }
      ]],
    })
  end)

  it("supports try-catch statement", function()
    helper.assert_scenario({
      input = [[
        try {
          //
        } on E|xception catch (e) {
          return;
        }
      ]],
      filetype = "dart",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        try {
          //
        } on Exception catch (e) {
          print("e: ${e}");
          return;
        }
      ]],
    })
  end)

  describe("supports identifier nested in complex expressions", function()
    it("supports class constructor", function()
      helper.assert_scenario({
        input = [[
          void main() {
            var animal = Dog(breed: na|me);
          }
        ]],
        filetype = "dart",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          void main() {
            var animal = Dog(breed: name);
            print("name: ${name}");
          }
        ]],
      })
    end)

    it("supports function invocations", function()
      helper.assert_scenario({
        input = [[
          void main() {
            foo(ba|r, baz);
          }
        ]],
        filetype = "dart",
        action = function()
          vim.cmd("normal! vi(")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          void main() {
            foo(bar, baz);
            print("bar: ${bar}");
            print("baz: ${baz}");
          }
        ]],
      })
    end)
  end)

  -- it("supports member access expression", function()
  --   helper.assert_scenario({
  --     input = [[
  --       var foo = ba|r.baz;
  --     ]],
  --     filetype = "dart",
  --     action = function()
  --       actions.insert_log({ position = "below" })
  --     end,
  --     expected = [[
  --       var foo = bar.baz;
  --       print("bar: ${bar}");
  --     ]],
  --   })
  --
  --   helper.assert_scenario({
  --     input = [[
  --       var foo = bar.ba|z.baf;
  --     ]],
  --     filetype = "dart",
  --     action = function()
  --       actions.insert_log({ position = "below" })
  --     end,
  --     expected = [[
  --       var foo = bar.baz.baf;
  --       print("bar.baz: ${bar.baz}");
  --     ]],
  --   })
  --
  --   helper.assert_scenario({
  --     input = [[
  --       var foo = ba|r.bar;
  --     ]],
  --     filetype = "dart",
  --     action = function()
  --       vim.cmd("normal! v$")
  --       actions.insert_log({ position = "below" })
  --     end,
  --     expected = [[
  --       var foo = bar.bar;
  --       print("bar: ${bar}");
  --     ]],
  --   })
  --
  --   helper.assert_scenario({
  --     input = [[
  --       var foo = ba|r.bar;
  --     ]],
  --     filetype = "dart",
  --     action = function()
  --       vim.cmd("normal! V")
  --       actions.insert_log({ position = "below" })
  --     end,
  --     expected = [[
  --       var foo = bar.bar;
  --       print("foo: ${foo}");
  --       print("bar.bar: ${bar.bar}");
  --     ]],
  --   })
  -- end)
end)

describe("dart batch log", function()
  it("supports batch log", function()
    timber.setup({
      batch_log_templates = {
        default = {
          dart = [[print("%repeat<%log_target=${%log_target}><, >");]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        void main() {
          var fo|o = bar + baz;
        }
      ]],
      filetype = "dart",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        void main() {
          var foo = bar + baz;
          print("foo=${foo}, bar=${bar}, baz=${baz}");
        }
      ]],
    })
  end)
end)
