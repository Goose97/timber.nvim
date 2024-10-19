; This workaround for the fact that field name and field value are both identifiers
; We need to distinguish between them
(
  ([
    (identifier)
  ]) @log_target
  (#not-has-parent? @log_target field)
  (#not-has-parent? @log_target dot_index_expression)
  (#not-has-parent? @log_target bracket_index_expression)
)

(field
  value: (identifier) @log_target)

(dot_index_expression
  table: ([
    (identifier)
    (dot_index_expression)
  ]) @log_target
)

(bracket_index_expression
  table: ([
    (identifier)
    (bracket_index_expression)
  ]) @log_target
)

(expression_list
   value: ([
     (dot_index_expression)
     (bracket_index_expression)
   ]) @log_target)
