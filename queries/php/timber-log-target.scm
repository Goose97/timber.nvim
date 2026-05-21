; Variables (includes the $ prefix)
(
  (variable_name) @log_target
  (#not-field-of-parent? @log_target function_call_expression function)
  (#not-field-of-parent? @log_target member_access_expression object)
  (#not-field-of-parent? @log_target scoped_property_access_expression scope)
  (#not-field-of-parent? @log_target object_creation_expression)
  (#not-field-of-parent? @log_target named_argument name)
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
(
  (function_call_expression) @log_target
)

; Member call expressions (e.g., $obj->method())
(
  (member_call_expression) @log_target
)

; Scoped call expressions (e.g., Class::method())
(
  (scoped_call_expression) @log_target
)
