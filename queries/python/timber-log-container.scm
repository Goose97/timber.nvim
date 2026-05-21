(
  (expression_statement) @log_container
  (#make-logable-range! @log_container "outer")
)

(function_definition
  parameters: (parameters) @log_container
  body: (block) @a
  (#make-logable-range! @a "inner")
)

(lambda
  parameters: (lambda_parameters) @log_container
  body: (parenthesized_expression) @a
  (#make-logable-range! @a "inner" 1 -1)
)

(
  (if_statement
    condition: (_) @log_container
    consequence: (block) @a
    (#make-logable-range! @a "inner")
  ) @b
  (#make-logable-range! @b "before")
)

(elif_clause
  condition: (_) @log_container
  consequence: (block) @a
  (#make-logable-range! @a "inner")
)

(for_statement
  left: (_) @log_container
  body: (block) @a
  (#make-logable-range! @a "inner")
)

(
  (for_statement
    right: (_) @log_container
    body: (block) @a
    (#make-logable-range! @a "inner")
  ) @b
  (#make-logable-range! @b "before")
)

(with_statement
  (with_clause) @log_container
  body: (block) @a
  (#make-logable-range! @a "inner")
)

(
  (while_statement
    condition: (_) @log_container
    body: (block) @a
    (#make-logable-range! @a "inner")
  ) @b
  (#make-logable-range! @b "before")
)

(
 (call
   arguments: (argument_list) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

(
 (match_statement
   subject: (_) @log_container
  ) @a
 (#make-logable-range! @a "outer")
)

; `case_pattern` is a supertype that isn't matchable by name in current
; tree-sitter-python; use the wildcard for the first named child.
(case_clause
  . (_) @log_container
  consequence: (block) @a
  (#make-logable-range! @a "inner")
)
