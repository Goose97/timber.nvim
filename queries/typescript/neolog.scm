; identifier is the log target

;; function foo(identifier: T)
(function_declaration
  parameters:
    (formal_parameters
      ([
        (required_parameter
          pattern: (identifier) @log_target (#contains-cursor? @log_target))
        (optional_parameter
          pattern: (identifier) @log_target (#contains-cursor? @log_target))
      ])
    )
  body: (statement_block) @logable_range (#adjust-range! @logable_range 1 -1)
)

;; function foo({ bar: baz }: T)
(function_declaration
  parameters:
    (formal_parameters
      (required_parameter
        pattern: (object_pattern
          (pair_pattern
            value: (identifier) @log_target (#contains-cursor? @log_target)
          )
        )
      )
    )
  body: (statement_block) @logable_range (#adjust-range! @logable_range 1 -1)
)

;; function foo({ bar }: T)
(function_declaration
  parameters:
    (formal_parameters
      (required_parameter
        pattern: (object_pattern
          (shorthand_property_identifier_pattern) @log_target (#contains-cursor? @log_target)
        )
      )
    )
  body: (statement_block) @logable_range (#adjust-range! @logable_range 1 -1)
)

;; function foo(identifier: T)
;(formal_parameters
;  (required_parameter
;    pattern: (object_pattern
;      (shorthand_property_identifier_pattern) @log_target
;    )
;  )
;) @container
;
;; catch(error) {}
;(
; (catch_clause
;    parameter: (identifier) @log_target
;    body: (statement_block) @container
;  )
;  (#set! log_placement "inner")
;)
