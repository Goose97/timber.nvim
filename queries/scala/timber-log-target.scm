(
  (identifier) @log_target
  (#not-field-of-parent? @log_target call_expression function)
  (#not-field-of-parent? @log_target function_definition name)
  (#not-field-of-parent? @log_target field_expression field)
  (#not-field-of-parent? @log_target infix_expression operator)
)

(
  (field_expression) @log_target
  (#not-field-of-parent? @log_target call_expression function)
)
