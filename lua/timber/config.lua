local utils = require("timber.utils")

---@class Timber.Highlight.Config
---@field on_insert? boolean Whether to highlight the log target when inserting the log. Defaults to `true`
---@field on_add_to_batch? boolean Whether to highlight the log target when adding to the batch. Defaults to `true`
---@field on_summary_show_entry? boolean Whether to highlight the line when showing the entry in the log summary. Defaults to `true`
---@field duration number The timeout in ms for highlighting

---@class Timber.Watcher.Config
---@field enabled? boolean Whether to enable log watcher. Defaults to `false`
---@field sources table<string, Timber.Watcher.SourceSpec> The sources to watch
---@field preview_snippet_length? integer The length of the preview snippet display as extmarks. Defaults to `32`

---@class Timber.Summary.Config
---@field keymaps { [ "show_entry" | "jump_to_entry" | "next_entry" | "prev_entry" | "close" ]: string | boolean }
---@field default_keymaps_enabled boolean Whether to enable default keymaps in the summary window. Defaults to `true`
---@field win { width: number | number[], position: "left" | "right", opts: table }

---@class Timber.Config
---@field log_templates { [string]: Timber.LogTemplates }
---@field log_marker string? The marker for the %log_marker placeholder. Defaults to `🪵`
---@field batch_log_templates { [string]: Timber.LogTemplates }
---@field template_placeholders table<string, fun(Timber.Actions.Context): string>
---@field highlight Timber.Highlight.Config
---@field keymaps { [Timber.Action | Timber.Operator]: string | boolean }
---@field default_keymaps_enabled boolean Whether to enable default keymaps. Defaults to `true`
---@field log_watcher Timber.Watcher.Config
---@field log_summary Timber.Summary.Config

---@type Timber.Config
local default_config = {
  log_templates = {
    default = {
      -- Templates with auto_import: when inserting a log statement, the import line is inserted automatically
      -- javascript = {
      --   [[logger.info('hello world')]],
      --   auto_import = [[const logger = require('pino')()]]
      -- }
      javascript = [[console.log("%log_target", %log_target)]],
      typescript = [[console.log("%log_target", %log_target)]],
      astro = [[console.log("%log_target", %log_target)]],
      vue = [[console.log("%log_target", %log_target)]],
      jsx = [[console.log("%log_target", %log_target)]],
      tsx = [[console.log("%log_target", %log_target)]],
      lua = [[print("%log_target", %log_target)]],
      luau = [[print("%log_target", %log_target)]],
      ruby = [[puts("%log_target #{%log_target}")]],
      elixir = [[IO.inspect(%log_target, label: "%log_target")]],
      go = [[log.Printf("%log_target: %v\n", %log_target)]],
      rust = [[println!("%log_target: {:#?}", %log_target);]],
      python = [[print(f"{%log_target=}")]],
      c = [[printf("%log_target: %s\n", %log_target);]],
      cpp = [[std::cout << "%log_target: " << %log_target << std::endl;]],
      java = [[System.out.println("%log_target: " + %log_target);]],
      c_sharp = [[Console.WriteLine($"%log_target: {%log_target}");]],
      odin = [[fmt.printfln("%log_target: %v", %log_target)]],
      bash = [[echo "%log_target: ${%log_target}"]],
      swift = [[print("%log_target:", %log_target)]],
      kotlin = [[println("%log_target: ${%log_target}")]],
      scala = [[println(s"%log_target: ${%log_target}")]],
      dart = [[print("%log_target: ${%log_target}");]],
      php = [[error_log("%log_target: " . print_r(%log_target));]],
    },
    plain = {
      javascript = [[console.log("%insert_cursor")]],
      typescript = [[console.log("%insert_cursor")]],
      astro = [[console.log("%insert_cursor")]],
      vue = [[console.log("%insert_cursor")]],
      jsx = [[console.log("%insert_cursor")]],
      tsx = [[console.log("%insert_cursor")]],
      lua = [[print("%insert_cursor")]],
      luau = [[print("%insert_cursor")]],
      ruby = [[puts("%insert_cursor")]],
      elixir = [[IO.puts(%insert_cursor)]],
      go = [[log.Println("%insert_cursor")]],
      rust = [[println!("%insert_cursor");]],
      python = [[print(f"%insert_cursor")]],
      c = [[printf("%insert_cursor \n");]],
      cpp = [[std::cout << "%insert_cursor" << std::endl;]],
      java = [[System.out.println("%insert_cursor");]],
      c_sharp = [[Console.WriteLine("%insert_cursor");]],
      odin = [[fmt.println("%insert_cursor")]],
      bash = [[echo "%insert_cursor"]],
      swift = [[print("%insert_cursor")]],
      kotlin = [[println("%insert_cursor")]],
      scala = [[println("%insert_cursor")]],
      dart = [[print("%insert_cursor");]],
      php = [[error_log("%insert_cursor");]],
    },
  },
  batch_log_templates = {
    default = {
      javascript = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
      typescript = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
      astro = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
      vue = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
      jsx = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
      tsx = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
      lua = [[print(string.format("%repeat<%log_target=%s><, >", %repeat<%log_target><, >))]],
      luau = [[print(`%repeat<%log_target={%log_target}><, >`)]],
      ruby = [[puts("%repeat<%log_target: #{%log_target}><, >")]],
      elixir = [[IO.inspect({ %repeat<%log_target><, > })]],
      go = [[log.Printf("%repeat<%log_target: %v><, >\n", %repeat<%log_target><, >)]],
      rust = [[println!("%repeat<%log_target: {:#?}><, >", %repeat<%log_target><, >);]],
      python = [[print(f"%repeat<{%log_target=}><, >")]],
      c = [[printf("%repeat<%log_target: %s><, >\n", %repeat<%log_target><, >);]],
      cpp = [[std::cout %repeat<<< "%log_target: " << %log_target>< << "\n  " > << std::endl;]],
      java = [[System.out.printf("%repeat<%log_target=%s><, >%n", %repeat<%log_target><, >);]],
      c_sharp = [[Console.WriteLine($"%repeat<%log_target: {%log_target}><, >");]],
      odin = [[fmt.printfln("%repeat<%log_target: %v><, >", %repeat<%log_target><, >)]],
      bash = [[echo "%repeat<%log_target: ${%log_target}><, >"]],
      swift = [[print("%repeat<%log_target: %log_target><, >")]],
      kotlin = [[println("%repeat<%log_target=${%log_target}><, >")]],
      scala = [[println(s"%repeat<%log_target=${%log_target}><, >")]],
      dart = [[print(s"%repeat<%log_target=${%log_target}><, >");]],
      php = [[error_log(%repeat<"%log_target: " . print_r(%log_target)>< . "\n" . >);]],
    },
  },
  template_placeholders = {
    filename = function()
      return vim.fn.expand("%:t")
    end,
    -- Custom placeholder. For example, this can be used in log templates as %truncated_line
    -- truncated_line = function(ctx)
    --   local line = ctx.log_target:start()
    --   return nvim_buf_get_lines(0, line - 1, line, false)[1]:sub(1, 16)
    -- end,
  },
  -- The string to search for when deleting or commenting log statements
  -- Can be used in log templates as %log_marker placeholder
  log_marker = "🪵",
  -- Controls the flash highlight
  highlight = {
    -- After a log statement is inserted
    on_insert = true,
    -- After a log target is added to a batch
    on_add_to_batch = true,
    -- After a log entry is shown/jumped to in the summary panel
    on_summary_show_entry = true,
    -- The duration of the flash highlight
    duration = 500,
  },
  keymaps = {
    -- Set to false to disable the default keymap for specific actions
    -- insert_log_below = false,
    insert_log_below = "glj",
    insert_log_above = "glk",
    insert_plain_log_below = "glo",
    insert_plain_log_above = "gl<S-o>",
    insert_batch_log = "glb",
    add_log_targets_to_batch = "gla",
    insert_log_below_operator = "g<S-l>j",
    insert_log_above_operator = "g<S-l>k",
    insert_batch_log_operator = "g<S-l>b",
    add_log_targets_to_batch_operator = "g<S-l>a",
  },
  -- Set to false to disable all default keymaps
  default_keymaps_enabled = true,
  log_watcher = {
    enabled = false,
    sources = {},
    -- The length of the preview snippet display as extmarks
    preview_snippet_length = 32,
  },
  log_summary = {
    -- Keymaps for the summary window
    keymaps = {
      show_entry = "<CR>",
      jump_to_entry = "o",
      next_entry = "]]",
      prev_entry = "[[",
      show_help = "?",
      close = "q",
    },
    -- Set to false to disable all default keymaps in the summary window
    default_keymaps_enabled = true,
    win = {
      -- Control the width of the summary window
      -- They can be a single integer (number of columns)
      -- or a float from 0 to 1 (percentage of the current window width e.g. 0.4 for 40%)
      -- or an array of mixed types
      -- width = {60, 0.4} means "the lesser of 60 columns and 40% of the current window width"
      width = { 60, 0.4 },
      -- Determines where the summary window will be opened: left, right
      position = "left",
      -- Customize the window options
      opts = {},
    },
  },
}

---@class TimberConfigModule
---@field config Timber.Config
local M = {}

---@param template_set string
---@param kind "single" | "batch"
---@return Template? log_template, string? lang, boolean? treesitter_supported
function M.get_lang_log_template(template_set, kind)
  local treesitter_supported = true

  local lang = utils.get_lang(vim.bo.filetype)
  if not lang then
    if kind == "batch" then
      utils.notify(string.format("Treesitter parser for %s language is not found", vim.bo.filetype), "error")
      return
    else
      lang = vim.bo.filetype
      treesitter_supported = false
    end
  end

  local log_template_set = (kind == "single" and M.config.log_templates or M.config.batch_log_templates)[template_set]
  if not log_template_set then
    utils.notify(string.format("Log template '%s' is not found", template_set), "error")
    return
  end

  ---@type Template
  local log_template_lang = log_template_set[lang]
  if not log_template_lang then
    utils.notify(
      string.format(
        "%s '%s' does not have '%s' language template",
        kind == "single" and "Log template" or "Batch log template",
        template_set,
        lang
      ),
      "error"
    )
    return
  end

  return log_template_lang, lang, treesitter_supported
end

local function setup_keymap(name, rhs, opts)
  local keymaps = M.config.keymaps

  local user_keymap = keymaps[name]

  -- If keymap is disabled by user, skip it
  if not user_keymap then
    return
  end

  local mode = opts.mode
  opts.mode = nil
  vim.keymap.set(mode, user_keymap, rhs, opts)
end

local function setup_keymaps()
  setup_keymap("insert_log_below", function()
    require("timber.actions").insert_log({
      position = "below",
    })
  end, { mode = { "n", "v" }, desc = "Insert log statement below" })

  setup_keymap("insert_log_above", function()
    require("timber.actions").insert_log({
      position = "above",
    })
  end, { mode = { "n", "v" }, desc = "Insert log statement above" })

  setup_keymap("insert_plain_log_below", function()
    require("timber.actions").insert_log({
      template = "plain",
      position = "below",
    })
  end, { mode = "n", desc = "Insert log plain statement below" })

  setup_keymap("insert_plain_log_above", function()
    require("timber.actions").insert_log({
      template = "plain",
      position = "above",
    })
  end, { mode = "n", desc = "Insert log plain statement above" })

  setup_keymap("insert_batch_log", function()
    require("timber.actions").insert_batch_log()
  end, { mode = "n" })

  setup_keymap("insert_batch_log", function()
    require("timber.actions").insert_batch_log({ auto_add = true })
  end, { mode = "v", desc = "Insert batch log statement below" })

  setup_keymap("add_log_targets_to_batch", function()
    require("timber.actions").add_log_targets_to_batch()
  end, { mode = { "n", "v" }, desc = "Add log targets to batch" })

  setup_keymap("insert_log_below_operator", function()
    return require("timber.actions").insert_log({
      position = "below",
      operator = true,
    })
  end, { mode = "n", expr = true, desc = "Insert log statement below operator" })

  setup_keymap("insert_log_above_operator", function()
    return require("timber.actions").insert_log({
      position = "above",
      operator = true,
    })
  end, { mode = "n", expr = true, desc = "Insert log statement above operator" })

  setup_keymap("insert_batch_log_operator", function()
    return require("timber.actions").insert_batch_log({
      operator = true,
    })
  end, { mode = "n", expr = true, desc = "Insert batch log statement below operator" })

  setup_keymap("add_log_targets_to_batch_operator", function()
    return require("timber.actions").insert_batch_log({
      operator = true,
    })
  end, { mode = "n", expr = true, desc = "Add log targets to batch operator" })
end

-- This function is used during testing
function M.reset_default_key_mappings()
  local reset_keymap = function(lhs, modes)
    for _, mode in ipairs(modes) do
      if vim.fn.maparg(lhs, mode) ~= "" then
        vim.keymap.del(mode, lhs)
      end
    end
  end

  reset_keymap("glj", { "n", "v" })
  reset_keymap("glk", { "n", "v" })
  reset_keymap("glo", { "n" })
  reset_keymap("gl<S-o>", { "n" })
  reset_keymap("gla", { "n", "v" })
  reset_keymap("glb", { "n", "v" })
  reset_keymap("g<S-l>j", { "n" })
  reset_keymap("g<S-l>k", { "n" })
  reset_keymap("g<S-l>a", { "n" })
  reset_keymap("g<S-l>b", { "n" })
end

---@param config Timber.InitConfig?
function M.setup(config)
  local base_config = vim.deepcopy(default_config)
  local user_config = config or {}
  local default_keymaps_enabled = user_config.default_keymaps_enabled == nil and base_config.default_keymaps_enabled
    or user_config.default_keymaps_enabled

  if not default_keymaps_enabled then
    base_config.keymaps = {}
  end

  M.config = vim.tbl_deep_extend("force", base_config, user_config)
  setup_keymaps()
end

return M
