; Outside of jsx element
; Not function name in call expression foo(bar)
(
  ([
    (identifier)
    (shorthand_property_identifier_pattern)
    (shorthand_property_identifier)
  ]) @log_target
  (#not-field-of-parent? @log_target call_expression function)
  (#not-has-ancestor? @log_target jsx_element)
  (#not-has-ancestor? @log_target jsx_self_closing_element)
)

; Inside of jsx expression but ignore opening and closing tags
(
  ([
    (identifier)
    (shorthand_property_identifier_pattern)
    (shorthand_property_identifier)
  ]) @log_target
  (#has-ancestor? @log_target jsx_expression)
  (#not-has-parent? @log_target jsx_opening_element)
  (#not-has-parent? @log_target jsx_closing_element)
  (#not-has-parent? @log_target jsx_self_closing_element)
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
  (#not-has-parent? @log_target jsx_opening_element)
  (#not-has-parent? @log_target jsx_closing_element)
  (#not-has-parent? @log_target jsx_self_closing_element)
)
