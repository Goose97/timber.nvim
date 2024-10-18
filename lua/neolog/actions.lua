---@class NeologActions
--- @field log_templates NeologLogTemplates
local M = {}

local LANGUAGE_SPEC = {
  typescript = {
    identifier = { "identifier", "shorthand_property_identifier_pattern" },
    container = { "lexical_declaration", "return_statement", "expression_statement" },
  },
  tsx = {
    identifier = { "identifier", "shorthand_property_identifier_pattern" },
    container = { "lexical_declaration", "return_statement", "expression_statement" },
  },
}

local utils = require("neolog.utils")
local ts_utils = require("nvim-treesitter.ts_utils")

--- Build the log label from template. Support special placeholers:
---   %identifier: the identifier text
---   %fn_name: the enclosing function name. If there's none, replaces with empty string
---   %line_number: the line_number number
---@param label_template string
---@param log_target_node TSNode
---@return string
local function build_log_label(label_template, log_target_node)
  local label = label_template

  if string.find(label, "%%identifier") then
    local bufnr = vim.api.nvim_get_current_buf()
    local identifier_text = vim.treesitter.get_node_text(log_target_node, bufnr)
    label = string.gsub(label, "%%identifier", identifier_text)
  end

  if string.find(label, "%%line_number") then
    local start_row = log_target_node:start()
    label = string.gsub(label, "%%line_number", start_row + 1)
  end

  return label
end

---@param label_text string
---@param identifier_text string
---@return string
local function build_log_statement(label_text, identifier_text)
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local template = M.log_templates[lang]

  template = string.gsub(template, "%%label", label_text)
  template = string.gsub(template, "%%identifier", identifier_text)

  return template
end

---@param line_number number
local function indent_line_number(line_number)
  local current_pos = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, { line_number, 0 })
  vim.cmd("normal! ==")
  vim.api.nvim_win_set_cursor(0, current_pos)
end

---@param label_template string
---@param log_target_node TSNode
---@param insert_line number
local function insert_log_statement(label_template, log_target_node, insert_line)
  local bufnr = vim.api.nvim_get_current_buf()
  local identifier_text = vim.treesitter.get_node_text(log_target_node, bufnr)
  local log_label = build_log_label(label_template, log_target_node)
  local log_statement = build_log_statement(log_label, identifier_text)
  vim.api.nvim_buf_set_lines(bufnr, insert_line, insert_line, false, { log_statement })
  indent_line_number(insert_line + 1)
end

--- Traverse up the tree from the current node to find the container node
---@param position position
---@return boolean, TSNode?, number?
local function resolve_log_target_fallback(position)
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local spec = LANGUAGE_SPEC[lang]
  if not spec then
    return false
  end

  local current_node = ts_utils.get_node_at_cursor()

  if not current_node then
    return false
  end

  if not utils.array_includes(spec.identifier, current_node:type()) then
    return false
  end

  local log_target = current_node

  -- Traverse up the tree to find the container node
  ---@type TSNode?
  local log_container_node = current_node
  repeat
    log_container_node = log_container_node and log_container_node:parent()
  until log_container_node == nil or require("custom.utils").array_includes(spec.container, log_container_node:type())

  if log_container_node then
    local insert_line = position == "above" and log_container_node:start() or log_container_node:end_() + 1
    return true, log_target, insert_line
  else
    return false
  end
end

--- Add log statement for the current identifier at the cursor
--- @alias position "above" | "below"
--- @param label_template string
--- @param position position
function M.add_log(label_template, position)
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  if not lang then
    vim.notify("Cannot determine language for current buffer", vim.log.levels.ERROR)
    return
  end

  local query = vim.treesitter.query.get(lang, "neolog")
  if not query then
    vim.notify(string.format("logging_framework doesn't support %s language", lang), vim.log.levels.ERROR)
    return
  end

  local template = M.log_templates[lang]
  if not template then
    vim.notify(string.format("Log template for %s language is not found", lang), vim.log.levels.ERROR)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local parser = vim.treesitter.get_parser(bufnr, lang)
  local tree = parser:parse()[1]
  local root = tree:root()

  local log_target_node
  local insert_line

  -- Only process first match
  for _, match, metadata in query:iter_matches(root, bufnr, 0, 1) do
    ---@type TSNode
    local log_target_capture = match[utils.get_key_by_value(query.captures, "log_target")]

    ---@type TSNode
    local logable_range = match[utils.get_key_by_value(query.captures, "logable_range")]

    insert_line = metadata.adjusted_logable_range and metadata.adjusted_logable_range[1] or logable_range:start()
    log_target_node = log_target_capture
  end

  if not log_target_node then
    local success, _log_target_node, _insert_line = resolve_log_target_fallback(position)
    if success then
      log_target_node = _log_target_node
      insert_line = _insert_line
    end
  end

  if log_target_node and insert_line then
    insert_log_statement(label_template, log_target_node, insert_line)
  else
    vim.notify("Cursor is not inside a valid log target", vim.log.levels.INFO)
  end
end

-- Register the custom predicate
---@param templates NeologLogTemplates
function M.setup(templates)
  M.log_templates = templates

  -- Register the custom predicate
  vim.treesitter.query.add_predicate("contains-cursor?", function(match, _, _, predicate)
    local node = match[predicate[2]]
    local cursor = vim.api.nvim_win_get_cursor(0)
    return vim.treesitter.node_contains(node, { cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2] })
  end, { force = true })

  -- Register the custom directive
  vim.treesitter.query.add_directive("adjust-range!", function(match, _, _, predicate, metadata)
    local capture_id = predicate[2]

    ---@type TSNode
    local node = match[capture_id]

    -- Get the adjustment values from the predicate arguments
    local start_adjust = tonumber(predicate[3]) or 0
    local end_adjust = tonumber(predicate[4]) or 0

    -- Get the original range
    local start_row, start_col, end_row, end_col = node:range()

    -- Adjust the range
    local adjusted_start_row = math.max(0, start_row + start_adjust) -- Ensure we don't go below 0
    local adjusted_end_row = math.max(adjusted_start_row, end_row + end_adjust) -- Ensure end is not before start

    -- Store the adjusted range in metadata
    metadata.adjusted_logable_range = { adjusted_start_row, start_col, adjusted_end_row, end_col }
  end, { force = true })
end

return M
