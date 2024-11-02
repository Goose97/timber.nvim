local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("javascript single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          javascript = [[console.log("%identifier", %identifier)]],
        },
      },
    })
  end)

  require("tests.timber.actions.lang.javascript_base")("javascript")
end)

describe("javascript batch log", function()
  before_each(function()
    actions.clear_batch()
  end)

  it("supports batch log", function()
    timber.setup({
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
end)
