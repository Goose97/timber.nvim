(
  [
    (import_or_export)
    (return_statement)
    (expression_statement)
    (part_directive)
    (part_of_directive)
    (local_variable_declaration)
  ] @log_container
  (#make-logable-range! @log_container "outer")
)

; switch statement (only log value in condition)
(
  (switch_statement
    condition: (parenthesized_expression) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

(switch_statement_case
  (constant_pattern) @log_container
  (block) @body
  (#make-logable-range! @body "inner" 1 -1)
)

(if_statement
  (_) @log_container
  consequence: (block) @body
  (#make-logable-range! @body "inner" 1 -1)
)

; function in class
(class_definition
  body: (class_body
    (method_signature 
      (function_signature
        (formal_parameter_list) @log_container
      )
    )
    .
    (function_body) @body
  )
  (#make-logable-range! @body "inner" 1 -1)
)

(function_expression
  parameters: (formal_parameter_list) @log_container
  body: (function_expression_body) @body
  (#make-logable-range! @body "inner" 1 -1)
)

(
 (function_signature
   (formal_parameter_list) @log_container
 )
 .
 (function_body
   (block) @body
 )
 (#make-logable-range! @body "inner" 1 -1)
)

; For statements
(for_statement
  (for_loop_parts) @log_container
  body: (block) @body
  (#make-logable-range! @log_container "inner" 1 -1)
)

; While statements
(
  (while_statement
    condition: (parenthesized_expression) @log_container
    body: (block) @body
    (#make-logable-range! @body "inner" 1 -1)
  ) @a
  (#make-logable-range! @a "before")
)

; Do-while statements
(
  (do_statement
    body: (block) @body
    condition: (parenthesized_expression) @log_container
    (#make-logable-range! @body "inner" 1 -1)
  ) @a
  (#make-logable-range! @a "after")
)

; Try statements
(try_statement
  (catch_clause) @log_container
  .
  (block) @body
  (#make-logable-range! @body "inner" 1 -1)
)
