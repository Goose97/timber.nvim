local neolog = require("neolog")
local helper = require("tests.neolog.helper")
local actions = require("neolog.actions")

describe("typescript single log", function()
  before_each(function()
    neolog.setup({
      log_templates = {
        default = {
          typescript = [[console.log("%identifier", %identifier)]],
        },
      },
    })
  end)

  require("tests.neolog.actions.lang.javascript_base")("typescript")
end)

describe("typescript batch log", function()
  before_each(function()
    actions.clear_batch()
  end)

  it("supports batch log", function()
    neolog.setup({
      batch_log_templates = {
        default = {
          typescript = [[console.log("Testing %line_number", { %repeat<"%identifier": %identifier><, > })]],
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
      filetype = "typescript",
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
end)
