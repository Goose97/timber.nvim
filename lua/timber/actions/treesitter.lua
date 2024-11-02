local M = {}

local utils = require("timber.utils")

---Sort the given nodes in the order that they would appear in a preorder traversal
---@param nodes TSNode[]
---@return TSNode[]
function M.sort_ts_nodes_preorder(nodes)
  return utils.array_sort_with_index(nodes, function(a, b)
    local result = utils.compare_ts_node_start(a[1], b[1])
    if result == "equal" then
      result = utils.compare_ts_node_end(a[1], b[1])

      -- It the containers have exactly the same range, sort by the appearance order
      return result == "equal" and a[2] < b[2] or result == "after"
    else
      return result == "before"
    end
  end)
end

---@alias logable_range {[1]: number, [2]: number}
---@param lang string
---@param range {[1]: number, [2]: number, [3]: number, [4]: number}
---@return {container: TSNode, logable_range: logable_range?}[]
function M.query_log_target_container(lang, range)
  local bufnr = vim.api.nvim_get_current_buf()
  local parser = vim.treesitter.get_parser(bufnr, lang)
  local tree = parser:parse()[1]
  local root = tree:root()

  local query = vim.treesitter.query.get(lang, "timber-log-container")
  if not query then
    vim.notify(string.format("timber doesn't support %s language", lang), vim.log.levels.ERROR)
    return {}
  end

  local containers = {}

  for _, match, metadata in query:iter_matches(root, bufnr, 0, -1) do
    ---@type TSNode
    local log_container = match[utils.get_key_by_value(query.captures, "log_container")]

    if log_container and utils.ranges_intersect(utils.get_ts_node_range(log_container), range) then
      ---@type TSNode?
      local logable_range = match[utils.get_key_by_value(query.captures, "logable_range")]

      local logable_range_col_range

      if metadata.adjusted_logable_range then
        logable_range_col_range = {
          metadata.adjusted_logable_range[1],
          metadata.adjusted_logable_range[3],
        }
      elseif logable_range then
        logable_range_col_range = { logable_range:start(), logable_range:end_() }
      end

      table.insert(containers, { container = log_container, logable_range = logable_range_col_range })
    end
  end

  return containers
end

---Find all the log target nodes in the given containers
---A log target can belong to multiple containers. In this case, we pick the deepest container
---@param containers TSNode[]
---@param lang string
---@return {container: TSNode, log_targets: TSNode[]}[]
function M.find_log_targets(containers, lang)
  local query = vim.treesitter.query.get(lang, "timber-log-target")
  if not query then
    vim.notify(string.format("timber doesn't support %s language", lang), vim.log.levels.ERROR)
    return {}
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local entries = {}

  ---@type { [string]: TSNode }
  local log_targets_table = {}

  for _, container in ipairs(containers) do
    for _, node in query:iter_captures(container, bufnr, 0, -1) do
      table.insert(entries, { log_container = container, log_target = node })
      log_targets_table[node:id()] = node
    end
  end

  -- Group by log target
  local grouped_log_targets = utils.array_group_by(entries, function(i)
    return i.log_target:id()
  end, function(i)
    return i.log_container
  end)

  local grouped_log_containers = {}

  -- If there's multiple containers for the same log target, pick the deepest container
  for log_target_id, log_containers in pairs(grouped_log_targets) do
    local sorted_group = M.sort_ts_nodes_preorder(log_containers)
    local deepest_container = sorted_group[#sorted_group]

    local log_target = log_targets_table[log_target_id]
    if grouped_log_containers[deepest_container] then
      table.insert(grouped_log_containers[deepest_container].log_targets, log_target)
    else
      grouped_log_containers[deepest_container] = { container = deepest_container, log_targets = { log_target } }
    end
  end

  return utils.table_values(grouped_log_containers)
end

---Check if the given node:
---  1. Has a parent node of type `parent_type`
---  2. Is a field `field_name` of the parent node
---@param node TSNode?
---@param parent_type string
---@param field_name string
---@return boolean
local function is_node_field_of_parent(node, parent_type, field_name)
  if not node then
    return false
  end

  local parent = node:parent()
  if not parent or parent:type() ~= parent_type then
    return false
  end

  local field_nodes = parent:field(field_name)
  return vim.list_contains(field_nodes, node)
end

---Check if the given node:
---  1. Has an ancestor node of type `ancestor_type`
---  2. Is in the subtree of field `field_name` of the ancestor node
---@param node TSNode?
---@param ancestor_type string
---@param field_name string
---@return boolean
local function is_node_field_of_ancestor(node, ancestor_type, field_name)
  local current = node

  while current do
    if is_node_field_of_parent(current, ancestor_type, field_name) then
      return true
    end

    current = current:parent()
  end

  return false
end

function M.setup()
  -- Adjust the range of the node
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

  -- Similar to has-parent?, but also check the node is a field of the parent
  vim.treesitter.query.add_predicate("field-of-parent?", function(match, _, _, predicate)
    local node = match[predicate[2]]
    local parent_type = predicate[3]
    local field_name = predicate[4]

    return is_node_field_of_parent(node, parent_type, field_name)
  end, { force = true })

  -- The negation of field-of-parent?
  vim.treesitter.query.add_predicate("not-field-of-parent?", function(match, _, _, predicate)
    local node = match[predicate[2]]
    local parent_type = predicate[3]
    local field_name = predicate[4]

    return not is_node_field_of_parent(node, parent_type, field_name)
  end, { force = true })

  -- Similar to has-ancestor?, but also check the node is in a field of the ancestor subtree
  vim.treesitter.query.add_predicate("field-of-ancestor?", function(match, _, _, predicate)
    local node = match[predicate[2]]
    local ancestor_type = predicate[3]
    local field_name = predicate[4]

    return is_node_field_of_ancestor(node, ancestor_type, field_name)
  end, { force = true })

  vim.treesitter.query.add_predicate("not-field-of-ancestor?", function(match, _, _, predicate)
    local node = match[predicate[2]]
    local ancestor_type = predicate[3]
    local field_name = predicate[4]

    return not is_node_field_of_ancestor(node, ancestor_type, field_name)
  end, { force = true })
end

return M
