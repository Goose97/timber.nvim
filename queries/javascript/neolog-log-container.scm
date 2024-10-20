([
  (lexical_declaration)
  (return_statement)
  (expression_statement)
  (import_statement)
]) @log_container

(function_declaration
  parameters: (formal_parameters) @log_container
  body: (statement_block) @logable_range (#adjust-range! @logable_range 1 -1)
)

(try_statement
  handler: (catch_clause
    parameter: (_) @log_container
    body: (statement_block) @logable_range (#adjust-range! @logable_range 1 -1)
  )
)

(if_statement
  condition: (parenthesized_expression) @log_container
  consequence: (statement_block) @logable_range (#adjust-range! @logable_range 1 -1)
)

(switch_statement
  value: (parenthesized_expression) @log_container
)

(switch_statement
  body: (switch_body
    (switch_case
      value: (_) @log_container
      body: (statement_block) @logable_range (#adjust-range! @logable_range 1 -1)
    )
  )
)

(switch_statement
  body: (switch_body
    (switch_case
      value: (_) @log_container
      body: (_) @logable_range (#not-match? @logable_range "^\\{")
    )
  )
)
