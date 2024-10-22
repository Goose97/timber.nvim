(shorthand_property_identifier_pattern) @log_target

; Ignore function name in call expression foo(bar)
(
  (identifier) @log_target
  (#not-field-of-ancestor? @log_target call_expression function)
)

; Ignore function name in call expression foo.bar(baz)
(
  ([
    (member_expression)
    (subscript_expression)
  ]) @log_target
  (#not-field-of-ancestor? @log_target call_expression function)
)
