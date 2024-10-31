(shorthand_property_identifier_pattern) @log_target

; Not function name in call expression foo(bar)
(
  (identifier) @log_target
  (#not-field-of-parent? @log_target call_expression function)
  ; This one is for typescript, but let's keep it here for now
  (#not-field-of-ancestor? @log_target call_expression type_arguments)
)

; Simple member expression
(
  ([
    (identifier)
    (member_expression
      object: [
       (identifier)
       (member_expression)
       (subscript_expression)
      ]
      property: (property_identifier)
    )
    (subscript_expression
      object: [
       (identifier)
       (member_expression)
       (subscript_expression)
      ]
      index: (_)
    )
  ]) @log_target
  (#has-ancestor? @log_target arguments)
)

; Simple member expression
(
  ([
    (member_expression
      object: [
       (identifier)
       (member_expression)
       (subscript_expression)
      ]
      property: (property_identifier)
    )
    (subscript_expression
      object: [
       (identifier)
       (member_expression)
       (subscript_expression)
      ]
      index: (_)
    )
  ]) @log_target
  (#not-field-of-parent? @log_target call_expression function)
)
