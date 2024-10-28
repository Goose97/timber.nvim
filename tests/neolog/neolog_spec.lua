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
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        const foo = "bar"
        console.log("foo", foo)
      ]],
    })

    helper.assert_scenario({
      input = [[
        const fo|o = "bar"
      ]],
      filetype = "typescript",
      action = function()
        actions.insert_log({ template = "default", position = "below" })
      end,
      expected = [[
        const foo = "bar"
        console.log("foo", foo)
      ]],
    })
  end)

  describe("provides default keymaps", function()
    after_each(function()
      require("neolog.config").reset_default_key_mappings()
    end)

    it("setups default keymaps when `default_keymaps_enabled` is not specified", function()
      neolog.setup({
        log_templates = {
          default = {
            typescript = [[console.log("%identifier", %identifier)]],
          },
        },
        batch_log_templates = {
          default = {
            typescript = [[console.log({ %repeat<"%identifier": %identifier><, > })]],
          },
        },
      })

      helper.assert_scenario({
        input = [[
          const fo|o = "bar"
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal glj")
          vim.cmd("normal glk")
          vim.cmd("normal gla")
          vim.cmd("normal glb")
        end,
        expected = [[
          console.log("foo", foo)
          const foo = "bar"
          console.log({ "foo": foo })
          console.log("foo", foo)
        ]],
      })
    end)

    it("setups default keymaps when `default_keymaps_enabled` is true", function()
      neolog.setup({
        log_templates = {
          default = {
            typescript = [[console.log("%identifier", %identifier)]],
          },
        },
        batch_log_templates = {
          default = {
            typescript = [[console.log({ %repeat<"%identifier": %identifier><, > })]],
          },
        },
        default_keymaps_enabled = true,
      })

      helper.assert_scenario({
        input = [[
          const fo|o = "bar"
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal glj")
          vim.cmd("normal glk")
          vim.cmd("normal gla")
          vim.cmd("normal glb")
        end,
        expected = [[
          console.log("foo", foo)
          const foo = "bar"
          console.log({ "foo": foo })
          console.log("foo", foo)
        ]],
      })
    end)

    it("setups default keymaps when `default_keymaps_enabled` is false", function()
      neolog.setup({
        log_templates = {
          default = {
            typescript = [[console.log("%identifier", %identifier)]],
          },
        },
        batch_log_templates = {
          default = {
            typescript = [[console.log({ %repeat<"%identifier": %identifier><, > })]],
          },
        },
        default_keymaps_enabled = false,
      })

      helper.assert_scenario({
        input = [[
          const fo|o = "bar"
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal glj")
          vim.cmd("normal glk")
          vim.cmd("normal gla")
          vim.cmd("normal glb")
        end,
        expected = [[
          const foo = "bar"
        ]],
      })
    end)
  end)

  describe("allows configure custom keymaps", function()
    before_each(function()
      neolog.setup({
        log_templates = {
          default = {
            typescript = [[console.log("%identifier", %identifier)]],
          },
        },
        batch_log_templates = {
          default = {
            typescript = [[console.log({ %repeat<"%identifier": %identifier><, > })]],
          },
        },
        keymaps = {
          insert_log_below = "lj",
          insert_log_above = "lk",
        },
      })
    end)

    after_each(function()
      require("neolog.config").reset_default_key_mappings()
    end)

    it("disable default keymaps", function()
      helper.assert_scenario({
        input = [[
          const fo|o = "bar"
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal glj")
          vim.cmd("normal glk")
        end,
        expected = [[
          const foo = "bar"
        ]],
      })
    end)

    it("overrides default keymaps with the new keymaps", function()
      helper.assert_scenario({
        input = [[
          const fo|o = "bar"
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal lj")
          vim.cmd("normal lk")
        end,
        expected = [[
          console.log("foo", foo)
          const foo = "bar"
          console.log("foo", foo)
        ]],
      })
    end)
  end)

  it("allows configure multiple log templates", function()
    neolog.setup({
      log_templates = {
        with_bar_123 = { typescript = [[console.log("%identifier bar 123", %identifier)]] },
      },
    })

    helper.assert_scenario({
      input = [[
        const fo|o = "bar"
      ]],
      filetype = "typescript",
      action = function()
        actions.insert_log({ template = "with_bar_123", position = "below" })
      end,
      expected = [[
        const foo = "bar"
        console.log("foo bar 123", foo)
      ]],
    })
  end)
end)
