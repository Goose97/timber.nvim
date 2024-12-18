(
  [
    (property_declaration)
    (assignment)
  ] @log_container
  (#make-logable-range! @log_container "outer")
)

(
  (control_transfer_statement) @log_container
  (#make-logable-range! @log_container "before")
)

(function_declaration
  (parameter) @log_container
  body: (function_body) @a
  (#make-logable-range! @a "inner" 1 -1)
)

(if_statement
  condition: (_) @log_container
  (_) @a
  (#make-logable-range! @a "inner")
)

(
  (switch_statement
    expr: (simple_identifier) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

(switch_entry
  (switch_pattern) @log_container
  (_) @a
  (#make-logable-range! @a "inner")
)

(for_statement
  item: (_) @log_container
  collection: (_)
  (_) @a
  (#make-logable-range! @a "inner")
)

(for_statement
  item: (_)
  collection: (_) @log_container
  (_) @a
  (#make-logable-range! @a "inner")
)

(while_statement
  condition: (_) @log_container
  (_) @a
  (#make-logable-range! @a "inner")
)

(
  (repeat_while_statement
    (_) @a
    condition: (_) @log_container
  ) @b
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @b "after")
)

(
  (init_declaration
    (parameter) @log_container
    body: (function_body) @a
  )
  (#make-logable-range! @a "inner" 1 -1)
)

(
  (lambda_literal
    type: (lambda_function_type
      (lambda_function_type_parameters) @log_container
    )
    (_) @a
  )
  (#make-logable-range! @a "inner")
)
