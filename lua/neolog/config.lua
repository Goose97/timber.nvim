local utils = require("neolog.utils")

---@alias Template string
---@alias NeologLogTemplates { [string]: Template }

---@class NeologHighlightConfig
---@field on_insert? boolean Whether to highlight the log target when inserting the log. Defaults to `true`
---@field on_add_to_batch? boolean Whether to highlight the log target when adding to the batch. Defaults to `true`
---@field duration number The timeout in ms for highlighting

---@class NeologWatcherConfig
---@field enabled? boolean Whether to enable log watcher. Defaults to `false`
---@field sources SourceSpecs The sources to watch
---@field preview_snippet_length? integer The length of the preview snippet display as extmarks. Defaults to `32`

---@alias NeologAction 'insert_log_below' | 'insert_log_above' | 'insert_batch_log' | 'add_log_targets_to_batch'
---@alias NeologOperator 'insert_log_below_operator' | 'insert_log_above_operator' | 'insert_batch_log_operator' | 'add_log_targets_to_batch_operator'

---@class NeologConfig
---@field log_templates { [string]: NeologLogTemplates }
---@field batch_log_templates { [string]: NeologLogTemplates }
---@field highlight NeologHighlightConfig
---@field keymaps { [NeologAction | NeologOperator]: string }
---@field default_keymaps_enabled boolean Whether to enable default keymaps. Defaults to `true`
---@field log_watcher NeologWatcherConfig

---@type NeologConfig
local default_config = {
  log_templates = {
    default = {
      javascript = [[console.log("%identifier", %identifier)]],
      typescript = [[console.log("%identifier", %identifier)]],
      jsx = [[console.log("%identifier", %identifier)]],
      tsx = [[console.log("%identifier", %identifier)]],
      lua = [[print("%identifier", %identifier)]],
    },
  },
  batch_log_templates = {
    default = {
      javascript = [[console.log({ %repeat<"%identifier": %identifier><, > })]],
      typescript = [[console.log({ %repeat<"%identifier": %identifier><, > })]],
      jsx = [[console.log({ %repeat<"%identifier": %identifier><, > })]],
      tsx = [[console.log({ %repeat<"%identifier": %identifier><, > })]],
      lua = [[print(string.format("%repeat<%identifier=%s><, >", %repeat<%identifier><, >))]],
    },
  },
  highlight = {
    on_insert = true,
    on_add_to_batch = true,
    duration = 500,
  },
  keymaps = {
    insert_log_below = "glj",
    insert_log_above = "glk",
    insert_batch_log = "glb",
    add_log_targets_to_batch = "gla",
    insert_log_below_operator = "g<S-l>j",
    insert_log_above_operator = "g<S-l>k",
    insert_batch_log_operator = "g<S-l>b",
    add_log_targets_to_batch_operator = "g<S-l>a",
  },
  default_keymaps_enabled = true,
  log_watcher = {
    enabled = false,
    sources = {},
    preview_snippet_length = 32,
  },
}

---@class NeologConfigModule
---@field config NeologConfig
local M = {}

---@param template_set string
---@param kind "single" | "batch"
---@return string?, string?
function M.get_lang_log_template(template_set, kind)
  local lang = utils.get_lang(vim.bo.filetype)
  if not lang then
    utils.notify("Treesitter cannot determine language for current buffer", "error")
    return
  end

  local log_template_set = (kind == "single" and M.config.log_templates or M.config.batch_log_templates)[template_set]
  if not log_template_set then
    utils.notify(string.format("Log template '%s' is not found", template_set), "error")
    return
  end

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

  return log_template_lang, lang
end

local function setup_keymap(name, lhs, rhs, opts)
  local keymaps = M.config.keymaps

  local user_keymap = keymaps[name]

  -- If keymap is disabled by user, skip it
  if not user_keymap then
    return
  end

  local mode = opts.mode
  opts.mode = nil
  vim.keymap.set(mode, user_keymap or lhs, rhs, opts)
end

local function setup_keymaps()
  setup_keymap("insert_log_below", "glj", function()
    require("neolog.actions").insert_log({
      position = "below",
    })
  end, { mode = { "n", "v" } })

  setup_keymap("insert_log_above", "glk", function()
    require("neolog.actions").insert_log({
      position = "above",
    })
  end, { mode = { "n", "v" } })

  setup_keymap("insert_batch_log", "glb", function()
    require("neolog.actions").insert_batch_log()
  end, { mode = "n" })

  setup_keymap("insert_batch_log", "glb", function()
    require("neolog.actions").insert_batch_log({ auto_add = true })
  end, { mode = "v" })

  setup_keymap("add_log_targets_to_batch", "gla", function()
    require("neolog.actions").add_log_targets_to_batch()
  end, { mode = { "n", "v" } })

  setup_keymap("insert_log_below_operator", "g<S-l>j", function()
    return require("neolog.actions").insert_log({
      position = "below",
      operator = true,
    })
  end, { mode = "n" })

  setup_keymap("insert_log_above_operator", "g<S-l>k", function()
    return require("neolog.actions").insert_log({
      position = "above",
      operator = true,
    })
  end, { mode = "n" })
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
  reset_keymap("gla", { "n", "v" })
  reset_keymap("glb", { "n", "v" })
  reset_keymap("g<S-l>j", { "n" })
  reset_keymap("g<S-l>k", { "n" })
  reset_keymap("g<S-l>a", { "n" })
  reset_keymap("g<S-l>b", { "n" })
end

---@param config NeologInitConfig?
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
