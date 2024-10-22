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
