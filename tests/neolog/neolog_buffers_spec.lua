local assert = require("luassert")
local spy = require("luassert.spy")
local neolog = require("neolog")
local buffers = require("neolog.buffers")
local watcher = require("neolog.watcher")
local utils = require("neolog.utils")
local helper = require("tests.neolog.helper")

local function get_extmarks(line, details)
  details = details == nil and false or details
  local bufnr = vim.api.nvim_get_current_buf()
  return vim.api.nvim_buf_get_extmarks(
    bufnr,
    buffers.log_placeholder_ns,
    { line, 0 },
    { line, -1 },
    { details = details }
  )
end

local function nums_of_windows()
  local current_tabpage = vim.api.nvim_get_current_tabpage()
  local wins = vim.api.nvim_tabpage_list_wins(current_tabpage)
  return #wins
end

describe("neolog.buffers autocmd", function()
  before_each(function()
    buffers.setup()
  end)

  describe("BufRead", function()
    it("parses the placeholders when entering buffers", function()
      local id1 = watcher.generate_unique_id()
      local id2 = watcher.generate_unique_id()

      helper.assert_scenario({
        input = string.format(
          [[
            const foo = "bar"
            console.log("%s%s|")
            console.log("%s%s|")
          ]],
          watcher.MARKER,
          id1,
          watcher.MARKER,
          id2
        ),
        input_cursor = false,
        filetype = "typescript",
        expected = function()
          -- Internally, we add the placeholder in the next tick using vim.schedule, hence the wait
          helper.wait(20)
          assert.is.Not.Nil(buffers.log_placeholders[id1])
          assert.is.Not.Nil(buffers.log_placeholders[id2])
        end,
      })
    end)

    describe("given the buffer has some placeholders", function()
      it("attaches to the buffer and deletes the placeholder when the log statement is deleted", function()
        local id1 = watcher.generate_unique_id()
        local id2 = watcher.generate_unique_id()

        helper.assert_scenario({
          input = string.format(
            [[
              const foo = "bar"
              console.log("%s%s|")
              console.log("%s%s|")
              const bar = "foo"
            ]],
            watcher.MARKER,
            id1,
            watcher.MARKER,
            id2
          ),
          input_cursor = false,
          filetype = "typescript",
          action = function()
            helper.wait(20)
            vim.cmd("normal! 2Gdd")
            helper.wait(20)
          end,
          expected = function()
            assert.is.Nil(buffers.log_placeholders[id1])
            assert.is.Not.Nil(buffers.log_placeholders[id2])

            assert.equals(#get_extmarks(0), 0)
            assert.equals(#get_extmarks(1), 1)
            assert.equals(#get_extmarks(2), 0)
          end,
        })

        local id3 = watcher.generate_unique_id()
        local id4 = watcher.generate_unique_id()

        helper.assert_scenario({
          input = string.format(
            [[
              const foo = "bar"
              console.log("%s%s|")
              console.log("%s%s|")
              const bar = "foo"
            ]],
            watcher.MARKER,
            id3,
            watcher.MARKER,
            id4
          ),
          input_cursor = false,
          filetype = "typescript",
          action = function()
            helper.wait(20)
            vim.cmd("normal! 2Gdj")
            helper.wait(20)
          end,
          expected = function()
            assert.is.Nil(buffers.log_placeholders[id3])
            assert.is.Nil(buffers.log_placeholders[id4])

            assert.equals(#get_extmarks(0), 0)
            assert.equals(#get_extmarks(1), 0)
          end,
        })
      end)

      it("attaches to the buffer and adds the placeholder when the log statement is inserted", function()
        local id1 = watcher.generate_unique_id()
        local id2 = watcher.generate_unique_id()

        helper.assert_scenario({
          input = string.format(
            [[
              const foo = "bar"
              console.log("%s%s|")
              const bar = "foo"
            ]],
            watcher.MARKER,
            id1
          ),
          input_cursor = false,
          filetype = "typescript",
          action = function()
            helper.wait(20)
            vim.fn.setreg("a", string.format([[console.log("%s%s|")]], watcher.MARKER, id2), "V")
            vim.cmd([[normal! 2G"ap]])
            helper.wait(20)
          end,
          expected = function()
            assert.is.Not.Nil(buffers.log_placeholders[id1])
            assert.is.Not.Nil(buffers.log_placeholders[id2])

            assert.equals(#get_extmarks(1), 1)
            assert.equals(#get_extmarks(2), 1)
          end,
        })
      end)
    end)

    describe("given the buffer has NO placeholders", function()
      it("DOES NOT attach to the buffer and react to buffer changes", function()
        local id = watcher.generate_unique_id()

        helper.assert_scenario({
          input = [[
            const fo|o = "bar"
            const bar = "foo"
          ]],
          filetype = "typescript",
          action = function()
            vim.fn.setreg("a", string.format([[console.log("%s%s|")]], watcher.MARKER, id), "V")
            vim.cmd([[normal! "ap]])
            helper.wait(20)
          end,
          expected = function()
            assert.is.Nil(buffers.log_placeholders[id])

            assert.equals(#get_extmarks(1), 0)
          end,
        })
      end)
    end)
  end)

  describe("BufDelete", function()
    it("detaches the buffer", function()
      local id = watcher.generate_unique_id()

      helper.assert_scenario({
        input = string.format(
          [[
            const foo = "bar"
            console.log("%s%s|")
          ]],
          watcher.MARKER,
          id
        ),
        input_cursor = false,
        filetype = "typescript",
        expected = function()
          helper.wait(20)
          local bufnr = vim.api.nvim_get_current_buf()
          assert.is.True(vim.list_contains(buffers.attached_buffers, bufnr))
          -- I don't know why :bdelete doesn't trigger the BufDelete autocmd
          -- Maybe it has something to do with the way we create the buffer for testing?
          vim.api.nvim_exec_autocmds("BufDelete", { buffer = bufnr })
          assert.is_not.True(vim.list_contains(buffers.attached_buffers, bufnr))
        end,
      })
    end)
  end)

  describe("BufWipeout", function()
    it("detaches the buffer", function()
      local id = watcher.generate_unique_id()

      helper.assert_scenario({
        input = string.format(
          [[
            const foo = "bar"
            console.log("%s%s|")
          ]],
          watcher.MARKER,
          id
        ),
        input_cursor = false,
        filetype = "typescript",
        expected = function()
          helper.wait(20)
          local bufnr = vim.api.nvim_get_current_buf()
          assert.is.True(vim.list_contains(buffers.attached_buffers, bufnr))
          vim.cmd("bwipeout")
          assert.is_not.True(vim.list_contains(buffers.attached_buffers, bufnr))
        end,
      })
    end)
  end)
end)

describe("neolog.buffers.new_log_placeholder", function()
  before_each(function()
    buffers.setup()
  end)

  it("adds the placeholder to the registry", function()
    local id = watcher.generate_unique_id()
    buffers.new_log_placeholder({ id = id, bufnr = 1, line = 1, contents = {} })

    assert.is.Not.Nil(buffers.log_placeholders[id])
  end)

  it("attaches to the buffer and reacts to buffer changes", function()
    local id = watcher.generate_unique_id()

    helper.assert_scenario({
      input = [[const fo|o = "bar"]],
      filetype = "typescript",
      action = function()
        local bufnr = vim.api.nvim_get_current_buf()
        buffers.new_log_placeholder({ id = "foo", bufnr = bufnr, line = 0, contents = {} })
        vim.fn.setreg("a", string.format([[console.log("%s%s|")]], watcher.MARKER, id), "V")
        vim.cmd([[normal! "ap]])
        helper.wait(20)
        vim.cmd("normal! 1Gdd")
      end,
      expected = function()
        -- Internally, we add the placeholder in the next tick using vim.schedule, hence the wait
        helper.wait(20)
        assert.is.Nil(buffers.log_placeholders.foo)
        assert.is.Not.Nil(buffers.log_placeholders[id])
      end,
    })
  end)
end)

describe("neolog.buffers.on_log_entry_received", function()
  before_each(function()
    buffers.setup()
  end)

  describe("given the log entry has a corresponding placeholder", function()
    it("renders the placeholder preview snippet", function()
      neolog.setup()
      local id = watcher.generate_unique_id()

      helper.assert_scenario({
        input = string.format(
          [[
            const foo = "bar"
            console.log("%s%s|")
            const bar = "foo"
          ]],
          watcher.MARKER,
          id
        ),
        input_cursor = false,
        filetype = "typescript",
        action = function()
          helper.wait(20)
          buffers.on_log_entry_received({
            log_placeholder_id = id,
            payload = "foo",
            source_name = "Test",
            timestamp = os.time(),
          })
          helper.wait(20)
        end,
        expected = function()
          local marks = get_extmarks(1, true)
          local snippet = marks[1][4].virt_text[1][1]
          local snippet_time = marks[1][4].virt_text[2][1]

          assert.equals(#marks, 1)
          assert.is.Not.Nil(string.find(snippet, "foo"))
          assert.equals(vim.trim(snippet_time), "Just now")
        end,
      })
    end)

    it("uses the latest entry as the placeholder preview snippet", function()
      neolog.setup()
      local id = watcher.generate_unique_id()

      helper.assert_scenario({
        input = string.format(
          [[
            const foo = "bar"
            console.log("%s%s|")
            const bar = "foo"
          ]],
          watcher.MARKER,
          id
        ),
        input_cursor = false,
        filetype = "typescript",
        action = function()
          helper.wait(20)
          buffers.on_log_entry_received({
            log_placeholder_id = id,
            payload = "foo",
            source_name = "Test",
            timestamp = os.time(),
          })
          helper.wait(20)
          buffers.on_log_entry_received({
            log_placeholder_id = id,
            payload = "bar",
            source_name = "Test",
            timestamp = os.time(),
          })
          helper.wait(20)
        end,
        expected = function()
          local marks = get_extmarks(1, true)
          local snippet = marks[1][4].virt_text[1][1]
          local snippet_time = marks[1][4].virt_text[2][1]

          assert.equals(#marks, 1)
          assert.is.Not.Nil(string.find(snippet, "bar"))
          assert.equals(vim.trim(snippet_time), "Just now")
        end,
      })
    end)

    describe("given the payload is longer than `log_watcher.preview_snippet_length` characters", function()
      it("renders the first `log_watcher.preview_snippet_length` characters", function()
        neolog.setup({
          log_watcher = {
            preview_snippet_length = 8,
          },
        })

        local id = watcher.generate_unique_id()

        helper.assert_scenario({
          input = string.format(
            [[
              const foo = "bar"
              console.log("%s%s|")
              const bar = "foo"
            ]],
            watcher.MARKER,
            id
          ),
          input_cursor = false,
          filetype = "typescript",
          action = function()
            helper.wait(20)
            buffers.on_log_entry_received({
              log_placeholder_id = id,
              payload = "foo_123456789_123456890",
              source_name = "Test",
              timestamp = os.time(),
            })
            helper.wait(20)
          end,
          expected = function()
            local marks = get_extmarks(1, true)
            local snippet = marks[1][4].virt_text[1][1]

            assert.equals(#marks, 1)
            assert.is.Not.Nil(string.find(snippet, "foo_1234"))
          end,
        })
      end)
    end)
  end)

  describe("given the log entry has NO corresponding placeholder", function()
    it("saves the log entry and renders it once the placeholder is created", function()
      neolog.setup()
      local id = watcher.generate_unique_id()
      buffers.on_log_entry_received({
        log_placeholder_id = id,
        payload = "foo",
        source_name = "Test",
        timestamp = os.time(),
      })

      helper.assert_scenario({
        input = string.format(
          [[
            const foo = "bar"
            console.log("%s%s|")
            const bar = "foo"
          ]],
          watcher.MARKER,
          id
        ),
        input_cursor = false,
        filetype = "typescript",
        expected = function()
          helper.wait(20)
          local marks = get_extmarks(1, true)
          local snippet = marks[1][4].virt_text[1][1]

          assert.equals(#marks, 1)
          assert.is.Not.Nil(string.find(snippet, "foo"))
          assert.is.equals(#buffers.pending_log_entries, 0)
        end,
      })
    end)
  end)
end)

describe("neolog.buffers.open_float", function()
  before_each(function()
    buffers.setup()
  end)

  describe("given the current line has a log placeholder", function()
    describe("given the placeholder has some contents", function()
      it("shows all the contents in a floating window", function()
        local id = watcher.generate_unique_id()

        helper.assert_scenario({
          input = string.format(
            [[
              const foo = "bar"
              console.log("%s%s|")
              const bar = "foo"
            ]],
            watcher.MARKER,
            id
          ),
          input_cursor = false,
          filetype = "typescript",
          action = function()
            helper.wait(20)
            buffers.on_log_entry_received({
              log_placeholder_id = id,
              payload = "foo_1",
              source_name = "Test",
              timestamp = os.time(),
            })
            buffers.on_log_entry_received({
              log_placeholder_id = id,
              payload = "foo_2",
              source_name = "Test",
              timestamp = os.time(),
            })
            -- Open the float window, and focus to it
            vim.cmd("normal! 2G")
            buffers.open_float()
            vim.cmd("wincmd w")
          end,
          expected = function()
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            local content = table.concat(lines, "")

            assert.is_not.Nil(string.match(content, "2 entries"))
            assert.is_not.Nil(string.match(content, "foo_1"))
            assert.is_not.Nil(string.match(content, "foo_2"))
          end,
        })

        -- Close the float window
        vim.cmd("q!")
      end)

      it("hides the floating window when users move the cursor", function()
        local id = watcher.generate_unique_id()

        helper.assert_scenario({
          input = string.format(
            [[
              const foo = "bar"
              console.log("%s%s|")
              const bar = "foo"
            ]],
            watcher.MARKER,
            id
          ),
          input_cursor = false,
          filetype = "typescript",
          action = function()
            helper.wait(20)
            buffers.on_log_entry_received({
              log_placeholder_id = id,
              payload = "foo_123456789_123456890",
              source_name = "Test",
              timestamp = os.time(),
            })
            -- Open the float window, and focus to it
            vim.cmd("normal! 2G")
            buffers.open_float()
          end,
          expected = function()
            assert.equals(2, nums_of_windows())
            -- Move the cursor
            vim.cmd("normal! j")
            helper.wait(20)
            assert.equals(1, nums_of_windows())
          end,
        })
      end)
    end)

    describe("given the placeholder has NO contents", function()
      it("notifies users with a warning message", function()
        local id = watcher.generate_unique_id()
        local notify_spy = spy.on(utils, "notify")

        helper.assert_scenario({
          input = string.format(
            [[
              const foo = "bar"
              console.log("%s%s|")
              const bar = "foo"
            ]],
            watcher.MARKER,
            id
          ),
          input_cursor = false,
          filetype = "typescript",
          action = function()
            helper.wait(20)
            -- Open the float window
            vim.cmd("normal! 2G")
            buffers.open_float()
          end,
          expected = function()
            assert.spy(notify_spy).was_called(1)
            assert.spy(notify_spy).was_called_with("Log placeholder has no content", "warn")
            notify_spy:clear()
          end,
        })
      end)
    end)
  end)

  describe("given the current line has NO log placeholder", function()
    it("notifies users with a warning message", function()
      local id = watcher.generate_unique_id()
      local notify_spy = spy.on(utils, "notify")

      helper.assert_scenario({
        input = string.format(
          [[
              const foo = "bar"
              const bar = "foo"
            ]],
          watcher.MARKER,
          id
        ),
        input_cursor = false,
        filetype = "typescript",
        action = function()
          helper.wait(20)
          -- Open the float window
          vim.cmd("normal! 2G")
          buffers.open_float()
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert.spy(notify_spy).was_called_with("No log placeholder found", "warn")
          notify_spy:clear()
        end,
      })
    end)
  end)
end)
