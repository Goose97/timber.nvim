; This workaround for the fact that field name and field value are both identifiers
; We need to distinguish between them
(
  ([
    (identifier)
  ]) @log_target
  (#not-has-parent? @log_target field)
  (#not-has-parent? @log_target dot_index_expression)
  (#not-has-parent? @log_target bracket_index_expression)
  (#not-eq? @log_target "_")
)

(field
  value: (identifier) @log_target)

(
  (dot_index_expression
    table: (identifier) @log_target
  ) @parent
  (#not-field-of-ancestor? @parent function_call name)
)

(
  (bracket_index_expression
    table: (identifier) @log_target
  ) @parent
  (#not-field-of-ancestor? @parent function_call name)
)

(
 ([
  (dot_index_expression)
  (bracket_index_expression)
 ]) @log_target
 (#not-field-of-ancestor? @log_target function_call name)
)
