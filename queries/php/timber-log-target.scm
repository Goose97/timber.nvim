; Variables (includes the $ prefix)
(
  (variable_name) @log_target
  (#not-field-of-parent? @log_target function_call_expression function)
  (#not-field-of-parent? @log_target scoped_property_access_expression name)
  (#not-field-of-parent? @log_target object_creation_expression)
  (#not-field-of-parent? @log_target named_argument name)
  ; Arrow functions are single-expression closures; treat the closure itself
  ; as opaque and log only what it's bound to (e.g. `$func`).
  (#not-has-ancestor? @log_target arrow_function)
)

; Member access expressions (e.g., $obj->property)
(
  (member_access_expression) @log_target
  (#not-field-of-ancestor? @log_target function_call_expression function)
)

; Scoped property access (e.g., Class::$property)
(
  (scoped_property_access_expression) @log_target
  (#not-field-of-ancestor? @log_target function_call_expression function)
)

; Subscript expressions (e.g., $array["key"])
(
  (subscript_expression) @log_target
  (#not-field-of-ancestor? @log_target function_call_expression function)
)

; Function call expressions (e.g., func())
; Only as a target when nested in a larger expression — when the call IS the
; statement, prefer logging its arguments individually instead.
(
  (function_call_expression) @log_target
  (#not-has-parent? @log_target expression_statement)
)

; Member call expressions (e.g., $obj->method())
(
  (member_call_expression) @log_target
  (#not-has-parent? @log_target expression_statement)
)

; Scoped call expressions (e.g., Class::method())
(
  (scoped_call_expression) @log_target
  (#not-has-parent? @log_target expression_statement)
)
