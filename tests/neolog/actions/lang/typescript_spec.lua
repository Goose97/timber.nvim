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

  describe("supports switch statement", function()
    it("supports switch head", function()
      local input = [[
        switch (fo|o) {
          case bar:
            break
          case "baz":
            break
        }
      ]]

      -- This is invalid syntax but it's a delibarate choice
      -- We want the switch statement log contaienr to be more granular
      -- So instead of matching the whole switch statement, we match against switch head
      -- and individual clauses
      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          switch (foo) {
            console.log("foo", foo)
            case bar:
              break
            case "baz":
              break
          }
        ]],
      })

      helper.assert_scenario({
        input = input,
        filetype = "typescript",
        action = function()
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          console.log("foo", foo)
          switch (foo) {
            case bar:
              break
            case "baz":
              break
          }
        ]],
      })
    end)

    it("supports switch clause", function()
      helper.assert_scenario({
        input = [[
          switch (foo) {
            case ba|r:
              break
            case "baz":
              break
          }
        ]],
        filetype = "typescript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          switch (foo) {
            case bar:
              console.log("bar", bar)
              break
            case "baz":
              break
          }
        ]],
      })

      helper.assert_scenario({
        input = [[
          switch (foo) {
            case (ba|r + baz): {
              break
            }
            case "baz":
              const baz = "baz"
              break
          }
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal! vi{V")
          actions.insert_log({ position = "below" })
        end,
        -- Again, don't know why indentation is off
        expected = [[
          switch (foo) {
            case (bar + baz): {
              console.log("bar", bar)
              console.log("baz", baz)
              break
            }
            case "baz":
              const baz = "baz"
            console.log("baz", baz)
              break
          }
        ]],
      })
    end)
  end)
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
