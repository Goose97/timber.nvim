local neolog = require("neolog")
local helper = require("tests.neolog.helper")
local actions = require("neolog.actions")

describe("neolog", function()
  it("provides default config", function()
    neolog.setup()

    helper.assert_scenario({
      input = [[
        const fo|o = "bar"
      ]],
      filetype = "typescript",
      action = function()
        actions.add_log({ position = "below" })
      end,
      expected = [[
        const foo = "bar"
        console.log("foo", foo)
      ]],
    })
  end)

  it("allows customize log templates", function()
    neolog.setup({
      log_templates = { typescript = [[console.log("%identifier bar 123", %identifier)]] },
    })

    helper.assert_scenario({
      input = [[
        const fo|o = "bar"
      ]],
      filetype = "typescript",
      action = function()
        actions.add_log({ position = "below" })
      end,
      expected = [[
        const foo = "bar"
        console.log("foo bar 123", foo)
      ]],
    })
  end)

  it("allows override log templates with opts", function()
    neolog.setup({
      log_templates = { typescript = [[console.log("%identifier bar 123", %identifier)]] },
    })

    helper.assert_scenario({
      input = [[
        const fo|o = "bar"
      ]],
      filetype = "typescript",
      action = function()
        actions.add_log({
          log_template = [[console.log("%identifier bar 456", %identifier)]],
          position = "below",
        })
      end,
      expected = [[
        const foo = "bar"
        console.log("foo bar 456", foo)
      ]],
    })
  end)
end)
