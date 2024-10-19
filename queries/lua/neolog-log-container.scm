([
  (variable_declaration)
]) @log_container

; Assignment without variable declaration
(
  (assignment_statement) @log_container
  (#not-has-parent? @log_container variable_declaration)
)

(function_call
  arguments: (arguments) @log_container)

(function_declaration
  parameters: (parameters) @log_container
  body: (block) @logable_range
)
