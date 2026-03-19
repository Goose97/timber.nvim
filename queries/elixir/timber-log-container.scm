(call
  target: (identifier) @function_name
  (arguments) @log_container
  (do_block) @block
  (#any-of? @function_name "def" "defp" "defmacro")
  (#make-logable-range! @block "inner" 1 - 1)
)

(
  (call
    target: (identifier) @function_name
    (arguments) @log_container
    (do_block) @block
    (#any-of? @function_name "if" "unless" "for" "with")
    (#make-logable-range! @block "inner" 1 - 1)
  ) @a
  (#make-logable-range! @a "before")
)

(
  (call
    target: (identifier) @function_name
    (arguments) @log_container
    (#any-of? @function_name "case" "cond" "assert")
  ) @a
  (#make-logable-range! @a "outer")
)

; Every expression under a do block is a potential log container
(call
  target: (identifier) @function_name
  (do_block
    (_) @log_container
    (#make-logable-range! @log_container "outer")
  )
  (#any-of? @function_name "def" "defp" "defmacro" "if" "unless" "for")
)

; Every expression under an else block is a potential log container
(call
  target: (identifier) @function_name
  (do_block
    (else_block
      (_) @log_container
      (#make-logable-range! @log_container "outer")
    )
  )
  (#any-of? @function_name "if" "unless")
)

; Function call
(
  (call
    target: (identifier) @function_name
    (arguments) @log_container
    (#not-any-of? @function_name "def" "defp" "defmacro" "if" "unless" "for" "case" "cond" "with")
  ) @a
  (#not-has-ancestor? @a call)
  (#make-logable-range! @a "outer")
)

; Anonymous function call
(
  (call
    target: (dot
      left: (identifier)
      !right
    )
    (arguments) @log_container
    (#not-has-ancestor? @log_container call)
  ) @a
  (#make-logable-range! @a "outer")
)

(stab_clause
  left: (arguments) @log_container
  right: (body) @logable_range
  (#make-logable-range! @logable_range "inner" 1 -1)
)

; Every expression under the stab clause body
(stab_clause
  right: (body
    (_) @log_container
    (#make-logable-range! @log_container "outer")
  )
)

; Pattern matching
(
 (binary_operator
   left: (_)
   "="
   right: (_)
 ) @log_container
 (#not-has-parent? @log_container arguments)
 (#make-logable-range! @log_container "outer")
)
