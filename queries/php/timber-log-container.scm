; Expression statements
(
  (expression_statement) @log_container
  (#make-logable-range! @log_container "outer")
)

; Function declarations
(function_definition
  parameters: (formal_parameters) @log_container
  body: (compound_statement) @a
  (#make-logable-range! @a "inner" 1 -1)
)

; Method declarations
(method_declaration
  parameters: (formal_parameters) @log_container
  body: (compound_statement) @a
  (#make-logable-range! @a "inner" 1 -1)
)

; Anonymous functions
(anonymous_function
  parameters: (formal_parameters) @log_container
  body: (compound_statement) @a
  (#make-logable-range! @a "inner" 1 -1)
)

; Arrow functions (short closures)
(
  (arrow_function) @log_container
  (#make-logable-range! @log_container "outer")
)

; If statements
(
  (if_statement
    condition: (_) @log_container
    body: (compound_statement) @a
    (#make-logable-range! @a "inner" 1 -1)
  ) @b
  (#make-logable-range! @b "before")
)

; Else if clause
(else_if_clause
  condition: (_) @log_container
  body: (compound_statement) @a
  (#make-logable-range! @a "inner" 1 -1)
)

; Foreach statements — include the whole header (iterable + key/value
; bindings) as the container so $items, $key, $value are all log targets.
(foreach_statement
  body: (compound_statement) @a
  (#make-logable-range! @a "inner" 1 -1)
  (#make-logable-range! @log_container "before")
) @log_container

; For statements
(for_statement
  (_) @log_container
  body: (compound_statement) @a
  (#make-logable-range! @a "inner" 1 -1)
)

; While statements
(
  (while_statement
    condition: (_) @log_container
    body: (compound_statement) @a
    (#make-logable-range! @a "inner" 1 -1)
  ) @b
  (#make-logable-range! @b "before")
)

; Switch case clauses
(case_statement
  value: (_) @log_container
  (_) @a
  (#make-logable-range! @a "inner")
)

; Default case — log the enclosing switch's condition at the end of the
; default body. This is how the switch condition variable gets logged for
; a `switch ($foo)`.
(switch_statement
  condition: (_) @log_container
  body: (switch_block
    (default_statement) @a
  )
  (#make-logable-range! @a "after")
)

; Match expressions (PHP 8.0+)
(
  (match_expression
    condition: (_) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

; Try-catch statements
(try_statement
  body: (compound_statement) @log_container
  (#make-logable-range! @log_container "inner" 1 -1)
)

(catch_clause
  name: (variable_name) @log_container
  body: (compound_statement) @a
  (#make-logable-range! @a "inner" 1 -1)
)

; Function call arguments
(
  (function_call_expression
    arguments: (arguments) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)
