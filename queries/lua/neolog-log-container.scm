(variable_declaration) @log_container

; Assignment without variable declaration
(
  (assignment_statement) @log_container
  (#not-has-parent? @log_container variable_declaration)
)

(function_call
  arguments: (arguments) @log_container)

(function_declaration
  parameters: (parameters) @log_container
  body: (block) @logable_range
)

(if_statement
  condition: (_) @log_container
  consequence: (block) @logable_range
)

(if_statement
  alternative: (elseif_statement
    condition: (_) @log_container
    consequence: (block) @logable_range
  )
)

(for_statement
  clause: (for_generic_clause (variable_list) @log_container)
  body: (block) @logable_range
)

(for_statement
  clause: (for_numeric_clause) @log_container
  body: (block) @logable_range
)
