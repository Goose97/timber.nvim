local assert = require("luassert")
local utils = require("timber.utils")
local helper = require("tests.timber.helper")

describe("timber.utils", function()
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

  describe("ranges_include", function()
    it("returns true for range1 includes range2", function()
      -- -----
      -- -----
      assert.is.True(utils.range_include({ 1, 2, 4, 4 }, { 1, 2, 4, 4 }))

      -- ------
      --  ----
      assert.is.True(utils.range_include({ 0, 2, 4, 4 }, { 1, 2, 3, 4 }))
    end)

    it("returns false for non-overlapping ranges", function()
      -- ------
      --  -------
      assert.is.False(utils.range_include({ 2, 2, 4, 4 }, { 3, 3, 5, 5 }))

      --  -------
      -- ------
      assert.is.False(utils.range_include({ 3, 3, 5, 5 }, { 2, 2, 4, 4 }))

      --  ----
      -- ------
      assert.is.False(utils.range_include({ 2, 2, 4, 4 }, { 0, 0, 5, 5 }))
    end)
  end)

  describe("get_selection_range", function()
    it("returns the cursor position for normal mode", function()
      helper.assert_scenario({
        input = [[
          // Comment
          cons|t foo = "bar"
        ]],
        filetype = "typescript",
        expected = function()
          local range = utils.get_selection_range()
          assert.are.same({ 1, 3, 1, 3 }, range)
        end,
      })
    end)

    it("returns the visual selection range for visual mode", function()
      helper.assert_scenario({
        input = [[
          // Comment
          cons|t foo = "bar"
          const bar = "baz"
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal! v5lj")
        end,
        expected = function()
          local range = utils.get_selection_range()
          assert.are.same({ 1, 3, 2, 8 }, range)
        end,
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const foo = "bar"
          const bar = "|baz"
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal! v6hk")
        end,
        expected = function()
          local range = utils.get_selection_range()
          assert.are.same({ 1, 6, 2, 12 }, range)
        end,
      })
    end)

    it("returns the visual line selection range for visual line mode", function()
      helper.assert_scenario({
        input = [[
          // Comment
          cons|t foo = "bar"
          const bar = "baz"
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal! Vj")
        end,
        expected = function()
          local range = utils.get_selection_range()
          assert.are.same({ 1, 0, 2, vim.v.maxcol }, range)
        end,
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const foo = "bar"
          const bar = "|baz"
        ]],
        filetype = "typescript",
        action = function()
          vim.cmd("normal! Vk")
        end,
        expected = function()
          local range = utils.get_selection_range()
          assert.are.same({ 1, 0, 2, vim.v.maxcol }, range)
        end,
      })
    end)
  end)
end)
