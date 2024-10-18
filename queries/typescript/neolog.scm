; function required parameters
(function_declaration
  parameters:
    (formal_parameters
      (required_parameter
        pattern: ([
          ; function foo(bar, baz) {}
          (identifier) @log_target

          ; function foo({ bar: bar }) {}
          (object_pattern
            (pair_pattern
              value: (identifier) @log_target
            )
          )

          ; function foo({ bar }) {}
          (object_pattern
            (shorthand_property_identifier_pattern) @log_target
          )
        ])
      )
    ) (#contains-cursor? @log_target)
  body: (statement_block) @logable_range (#adjust-range! @logable_range 1 -1)
)

; function optional parameters
(function_declaration
  parameters:
    (formal_parameters
      (optional_parameter
        pattern: (identifier) @log_target (#contains-cursor? @log_target))
    )
  body: (statement_block) @logable_range (#adjust-range! @logable_range 1 -1)
)

; try/catch clause
(try_statement
  handler: (catch_clause
    parameter: ([
      ; catch(error) {}
      (identifier) @log_target

      ; catch({ error: err }) {}
      (object_pattern
        (pair_pattern
          value: (identifier) @log_target
        )
      )

      ; catch({ error }) {}
      (object_pattern
        (shorthand_property_identifier_pattern) @log_target
      )
    ]) (#contains-cursor? @log_target)
    body: (statement_block) @logable_range (#adjust-range! @logable_range 1 -1)
  )
)
