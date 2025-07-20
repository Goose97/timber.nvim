local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("dart single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          dart = [[print("%log_target:${%log_target}");]],
        },
      },
    })
  end)

  it("supports variable declaration", function()
    local input = [[
      final String fo|o = "bar";
    ]]

    local expected = [[
      String foo = "bar";
      print("foo:${foo}");
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "dart",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = expected,
    })
  end)
end)
