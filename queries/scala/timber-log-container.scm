(class_definition
  parameters: (class_parameters) @log_container
  body: (template_body) @body
  (#make-logable-range! @body "inner" 1 -1)
)

(
  [
    (val_definition)
    (var_definition)
    (return_expression)
    (call_expression)
    (import_declaration)
    (assignment_expression)
  ] @log_container
  (#make-logable-range! @log_container "outer")
)

(function_definition
  parameters: (parameters) @log_container
  body: (block) @body
  (#make-logable-range! @body "inner" 1 -1)
)

(function_definition
  parameters: (parameters) @log_container
  body: (_) @body
  (#not-match? @body "^\\{")
  (#make-logable-range! @body "inner")
)

(lambda_expression
  parameters: (_) @log_container
  (block) @body
  (#make-logable-range! @body "inner" 1 -1)
)

; if expression with block body
(
  (if_expression
    condition: (_) @log_container
    consequence: (block) @body
    (#make-logable-range! @body "inner" 1 -1)
  ) @a
  (#make-logable-range! @a "before")
)

; if expression with single statement body
(if_expression
  condition: (_) @log_container
  consequence: (_) @body
  (#not-match? @body "^\\{")
  (#make-logable-range! @body "outer")
)

(
  (for_expression
    enumerators: (_) @log_container
    body: (block) @body
    (#make-logable-range! @body "inner" 1 -1)
  ) @a
  (#make-logable-range! @a "before")
)

(
  (while_expression
    condition: (_) @log_container
    body: (block) @body
    (#make-logable-range! @body "inner" 1 -1)
  ) @a
  (#make-logable-range! @a "before")
)

(try_expression
  body: (block) @log_container
  (#make-logable-range! @log_container "inner" 1 -1)
)

(try_expression
  (catch_clause
    (case_block
      (case_clause
        pattern: (_) @log_container
        body: (block) @body
      )
      (#make-logable-range! @body "inner" 1 -1)
    )
  )
)

(
  (match_expression
    value: (_) @log_container
  ) @a
  (#make-logable-range! @a "outer")
)

(match_expression
  body: (case_block
    (case_clause
      pattern: (_) @log_container
      body: (block) @body
      (#make-logable-range! @body "inner" 1 -1)
    )
  )
)

(block
  (infix_expression) @log_container
  (#make-logable-range! @log_container "outer")
)
