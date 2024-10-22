local helper = require("tests.neolog.helper")
local actions = require("neolog.actions")

---@param language string
local run = function(language)
  it("supports jsx expression", function()
    local input = [[
      function foo() {
        const a = 1

        return (
          <div>
            <div>{a| + 1}</div>
          </div>
        )
      }
    ]]

    local expected = [[
      function foo() {
        const a = 1

        console.log("a", a)
        return (
          <div>
            <div>{a + 1}</div>
          </div>
        )
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

    input = [[
      function foo() {
        const a = 1
        const el = (
          <div>
            <div>{a| + 1}</div>
          </div>
        )
      }
    ]]

    expected = [[
      function foo() {
        const a = 1
        const el = (
          <div>
            <div>{a + 1}</div>
          </div>
        )
        console.log("a", a)
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

  it("supports jsx attribute", function()
    local input = [[
      function foo() {
        return (
          <div className={a|}>
            <div>{b + 1}</div>
          </div>
        )
      }
    ]]

    local expected = [[
      function foo() {
        console.log("a", a)
        return (
          <div className={a}>
            <div>{b + 1}</div>
          </div>
        )
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

  it("DOES NOT support jsx opening and closing tags", function()
    helper.assert_scenario({
      input = [[
        const foo = <di|v>
          <div>{b + 1}</div>
        </div>
      ]],
      filetype = language,
      action = function()
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        const foo = <div>
          <div>{b + 1}</div>
        </div>
      ]],
    })

    helper.assert_scenario({
      input = [[
        const foo = <div>
          <div>{b + 1}</div>
        </di|v>
      ]],
      filetype = language,
      action = function()
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        const foo = <div>
          <div>{b + 1}</div>
        </div>
      ]],
    })

    helper.assert_scenario({
      input = [[
        const foo = <Foo.B|ar>123</Foo.Bar>
      ]],
      filetype = language,
      action = function()
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        const foo = <Foo.Bar>123</Foo.Bar>
      ]],
    })

    helper.assert_scenario({
      input = [[
        const foo = <Foo.Bar>123</Foo.Ba|r>
      ]],
      filetype = language,
      action = function()
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        const foo = <Foo.Bar>123</Foo.Bar>
      ]],
    })
  end)

  it("DOES NOT support jsx self closing tags", function()
    helper.assert_scenario({
      input = [[
        const foo = <inp|ut />
      ]],
      filetype = language,
      action = function()
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        const foo = <input />
      ]],
    })
  end)
end

return run
