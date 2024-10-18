local utils = require("neolog.utils")
local assert = require("luassert")

describe("neolog.utils", function()
  describe("ranges_intersect", function()
    it("returns true for overlapping ranges", function()
      -- -----
      -- -----
      assert.is.True(utils.ranges_intersect({ 1, 2, 4, 4 }, { 1, 2, 4, 4 }))

      -- ------
      --  ----
      assert.is.True(utils.ranges_intersect({ 0, 2, 4, 4 }, { 1, 2, 3, 4 }))

      --  ----
      -- ------
      assert.is.True(utils.ranges_intersect({ 2, 2, 4, 4 }, { 0, 0, 5, 5 }))

      --  -------
      -- ------
      assert.is.True(utils.ranges_intersect({ 2, 2, 8, 8 }, { 0, 0, 5, 5 }))

      -- ------
      --  -------
      assert.is.True(utils.ranges_intersect({ 2, 2, 4, 4 }, { 3, 3, 5, 5 }))

      -- -----
      --     -----
      assert.is.True(utils.ranges_intersect({ 1, 2, 4, 4 }, { 4, 4, 5, 5 }))
    end)

    it("returns false for non-overlapping ranges", function()
      -- -----
      --       -----
      assert.is.False(utils.ranges_intersect({ 1, 2, 4, 4 }, { 4, 7, 5, 5 }))
      assert.is.False(utils.ranges_intersect({ 1, 2, 4, 4 }, { 5, 7, 6, 5 }))

      --       -----
      -- -----
      assert.is.False(utils.ranges_intersect({ 4, 7, 5, 5 }, { 1, 2, 4, 4 }))
      assert.is.False(utils.ranges_intersect({ 5, 7, 6, 5 }, { 1, 2, 4, 4 }))
    end)
  end)
end)
