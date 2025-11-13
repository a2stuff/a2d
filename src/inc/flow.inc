;;; ============================================================
;;;
;;; Flow Control
;;;
;;; ============================================================

;;; Macros that provide higher level flow control without resorting to
;;; throw-away labels, and generally improve readability.

;;; ============================================================
;;;
;;; Conditional Branching
;;;
;;; ============================================================

;;; * IF cond / ELSE_IF cond / ELSE / END_IF
;;; * DO / CONTINUE_IF cond / BREAK_IF cond / WHILE cond
;;;   * or REPEAT / UNTIL cond if you prefer
;;; * RTS_IF cond
;;;
;;; Conditions take the form of flag tests or register comparisons.
;;;
;;; Conditions can be prepended with NOT to invert meaning.
;;;
;;; Flag tests: ZS ZC CS CC VS VC NS NC
;;; (Aliases: EQ, NE, ZERO, NOT_ZERO, LT, GE, POS, NEG, PLUS, MINUS)
;;;
;;; Register comparisons: <register> <operator> <argument>
;;; e.g. "IF A = #25"
;;; Operators: =, <>, <, >= (aliases: EQ, NE, LT, GE)
;;;
;;; Also: IN, BETWEEN (and NOT_IN, NOT_BETWEEN)
;;; e.g. "IF A IN #1, #2, #3"
;;; e.g. "IF A BETWEEN #'A', #'Z'"

;;; ============================================================
;;; Infrastructure
;;; ============================================================

;;; Set context
.macro _FLOW_STATEMENT name
    .define __flow_statement__ name
    __FLOW_LOG__ name
.endmacro

;;; Increment a numeric variable; if not initialized, treated as 0
.macro __INC_IDENT__ ident
    .if .not(.defined(ident))
        ident .set 0
    .endif
        ident .set ident + 1
.endmacro

;;; Decrement a numeric variable
.macro __DEC_IDENT__ ident
        ident .set ident - 1
.endmacro

;;; Change to 1 to enable logging
.define __flow_debug__ 0

;;; If debugging enabled, log a message
.macro __FLOW_LOG__ msg
    .if __flow_debug__
        .out msg
    .endif
.endmacro


;;; ============================================================
;;; Expression Parsing
;;; ============================================================

;;; '@' is used for numeric variables so they do not interfere with
;;; cheap local labels in user code.

;;; Constants defined with macros rather than numeric variables so we
;;; don't need to worry about scoping.
.define __flow_expr_type_error__ 0
.define __flow_expr_type_flag_test__ 1
.define __flow_expr_type_comparison__ 2
.define __flow_expr_type_in_list__ 3
.define __flow_expr_type_between__ 4

.macro __SET_BOPS__ bop1, bop2
  .undef __flow_branchOp1__
  .define __flow_branchOp1__ bop1
  .undef __flow_branchOp2__
  .define __flow_branchOp2__ bop2
.endmacro

.macro __SET_COP__ reg, cop
  .undef __flow_register_name__
  .define __flow_register_name__ reg
  .undef __flow_compareOp__
  .define __flow_compareOp__ cop
.endmacro

.macro __RESULT_FLAG_TEST__ name, bop1, bop2
  .undef __flow_flag_test_name__
  .define __flow_flag_test_name__ name
  __SET_BOPS__ bop1, bop2
  @__flow_expr_type__ .set __flow_expr_type_flag_test__
  @__flow_break_loop_flag__ .set 1
.endmacro

.macro __RESULT_COMPARISON__ op, bop1, bop2
  .undef __flow_comparison_operator_name__
  .define __flow_comparison_operator_name__ op
  __SET_BOPS__ bop1, bop2
  @__flow_expr_type__ .set __flow_expr_type_comparison__
  @__flow_break_loop_flag__ .set 1
.endmacro

.macro __RESULT_IN__ op
  .undef __flow_comparison_operator_name__
  .define __flow_comparison_operator_name__ op
  @__flow_expr_type__ .set __flow_expr_type_in_list__
  @__flow_break_loop_flag__ .set 1
.endmacro

.macro __RESULT_BETWEEN__ op
  .undef __flow_comparison_operator_name__
  .define __flow_comparison_operator_name__ op
  @__flow_expr_type__ .set __flow_expr_type_between__
  @__flow_break_loop_flag__ .set 1
.endmacro


;;; FUTURE: Actually look at multiple expressions
.macro _FLOW_PARSE_EXPR_LOOP expr, tindex
  .undef __flow_token__
  .define __flow_token__ .mid(tindex, 1, {expr})
  .undef __flow_next_token__
  .define __flow_next_token__ .mid(tindex+1, 1, {expr})

  .if .xmatch({__flow_token__}, NOT)
    @__flow_expr_invert_flag__ .set .not(@__flow_expr_invert_flag__)

;;; Flag tests

  .elseif .xmatch({__flow_token__}, ZS)
    __RESULT_FLAG_TEST__ "ZS", BEQ, BNE
  .elseif .xmatch({__flow_token__}, ZC)
    __RESULT_FLAG_TEST__ "ZC", BNE, BEQ
  .elseif .xmatch({__flow_token__}, CS)
    __RESULT_FLAG_TEST__ "CS", BCS, BCC
  .elseif .xmatch({__flow_token__}, CC)
    __RESULT_FLAG_TEST__ "CC", BCC, BCS
  .elseif .xmatch({__flow_token__}, NS)
    __RESULT_FLAG_TEST__ "NS", BMI, BPL
  .elseif .xmatch({__flow_token__}, NC)
    __RESULT_FLAG_TEST__ "NC", BPL, BMI
  .elseif .xmatch({__flow_token__}, VS)
    __RESULT_FLAG_TEST__ "VS", BVS, BVC
  .elseif .xmatch({__flow_token__}, VC)
    __RESULT_FLAG_TEST__ "VC", BVC, BVS

;;; Register compares

  .elseif .xmatch({__flow_token__}, A) .or .xmatch({__flow_token__}, X) .or .xmatch({__flow_token__}, Y)

        ;; Determine the compare opcodes from the register
    .if .xmatch({__flow_token__}, A)
      __SET_COP__ "A", CMP
    .elseif .xmatch({__flow_token__}, X)
      __SET_COP__ "X", CPX
    .elseif .xmatch({__flow_token__}, Y)
      __SET_COP__ "Y", CPY
    .else
      .fatal "unreachable"
    .endif

        ;; Determine the expression type from the comparison operator
    .if .xmatch({__flow_next_token__}, IN)
      __RESULT_IN__ "IN"
    .elseif .xmatch({__flow_next_token__}, NOT_IN)
      __RESULT_IN__ "NOT_IN"
      @__flow_expr_invert_flag__ .set .not(@__flow_expr_invert_flag__)
    .elseif .xmatch({__flow_next_token__}, BETWEEN)
      __RESULT_BETWEEN__ "BETWEEN"
    .elseif .xmatch({__flow_next_token__}, NOT_BETWEEN)
      __RESULT_BETWEEN__ "NOT_BETWEEN"
      @__flow_expr_invert_flag__ .set .not(@__flow_expr_invert_flag__)
    .elseif .xmatch({__flow_next_token__}, =) .or .xmatch({__flow_next_token__}, EQ)
      __RESULT_COMPARISON__ "=", BEQ, BNE
    .elseif .xmatch({__flow_next_token__}, <>) .or .xmatch({__flow_next_token__}, NE)
      __RESULT_COMPARISON__ "<>", BNE, BEQ
    .elseif .xmatch({__flow_next_token__}, <) .or .xmatch({__flow_next_token__}, LT)
      __RESULT_COMPARISON__ "<", BCC, BCS
    .elseif .xmatch({__flow_next_token__}, >=) .or .xmatch({__flow_next_token__}, GE)
      __RESULT_COMPARISON__ ">=", BCS, BCC
    .elseif .xmatch({__flow_next_token__}, >)
      .error .sprintf("%s: Greater-than operator ('>') not supported", __flow_statement__)
      @__flow_expr_type__ .set __flow_expr_type_error__
      .exitmacro
    .elseif .xmatch({__flow_next_token__}, <=)
      .error .sprintf("%s: Less-than-or-equal operator ('<=') not supported", __flow_statement__)
      @__flow_expr_type__ .set __flow_expr_type_error__
      .exitmacro
    .else
      .error .sprintf("%s: No operator match after register %s", __flow_statement__, __flow_register_name__)
      @__flow_expr_type__ .set __flow_expr_type_error__
      .exitmacro
    .endif

    .undef __flow_comparison_operand__
    .define __flow_comparison_operand__ .mid(@__flow_current_index__+2, 9999, {expr})

  .else
    .error .sprintf("%s: No expression match", __flow_statement__)
      @__flow_expr_type__ .set __flow_expr_type_error__
    .exitmacro
  .endif

.endmacro

.macro _FLOW_PARSE_EXPR expr, reg, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
        ;; Non-numeric variables set during expression parsing
  .define __flow_compareOp__ __nothing__ ; token, e.g. CMP
  .define __flow_branchOp1__ __nothing__ ; token, e.g. BCC
  .define __flow_branchOp2__ __nothing__ ; token, e.g. BCS - the opposite
  .define __flow_flag_test_name__ __nothing__ ; string, e.g. "CS"
  .define __flow_comparison_operand__ __nothing__ ; token list, e.g. var+Type::member
  .define __flow_comparison_operator_name__ __nothing__ ; string, e.g. ">="
  .define __flow_token__ __nothing__
  .define __flow_next_token__ __nothing__
  .define __flow_register_name__ __nothing__

        ;; Numeric variables set during expression parsing
  @__flow_expr_type__ .set 0
  @__flow_expr_invert_flag__ .set 0 ; flipped when "NOT" is seen

        ;; Parse expression
  .ifblank expr
    .error .sprintf("%s: empty expression", __flow_statement__)
    @__flow_expr_type__ .set __flow_expr_type_error__
    .exitmacro
  .endif

  @__flow_break_loop_flag__ .set 0
  .repeat .tcount({expr}), tindex
    .if .not(@__flow_break_loop_flag__)
    @__flow_current_index__ .set tindex
    _FLOW_PARSE_EXPR_LOOP {expr}, tindex
    .endif
  .endrepeat

        ;; Validation
  .if @__flow_expr_type__ = __flow_expr_type_flag_test__
    .if .tcount({expr}) > @__flow_current_index__ + 1
      .error .sprintf("%s: Unexpected tokens after flag test '%s'", __flow_statement__, __flow_flag_test_name__)
      @__flow_expr_type__ .set __flow_expr_type_error__
      .exitmacro
    .endif
     .ifnblank reg
       .error .sprintf("%s: Unexpected arguments after flag test '%s'", __flow_statement__, __flow_flag_test_name__)
       @__flow_expr_type__ .set __flow_expr_type_error__
       .exitmacro
     .endif
  .elseif @__flow_expr_type__ = __flow_expr_type_comparison__
    .if .match({__flow_comparison_operand__}, 0)
      .error .sprintf("%s: Numeric literal in '%s' comparison; did you mean '#%s'?", __flow_statement__, __flow_comparison_operator_name__, .string(__flow_comparison_operand__))
      @__flow_expr_type__ .set __flow_expr_type_error__
      .exitmacro
    .endif
    .ifnblank reg
      .if .not(.xmatch({reg}, X) .or .xmatch({reg}, Y))
        .error .sprintf("%s: Unexpected non-index register after comparison '%s'", __flow_statement__, __flow_comparison_operator_name__)
        @__flow_expr_type__ .set __flow_expr_type_error__
        .exitmacro
      .endif
    .endif
    .ifnblank arg2
      .error .sprintf("%s: Unexpected arguments after comparison '%s'", __flow_statement__, __flow_comparison_operator_name__)
      @__flow_expr_type__ .set __flow_expr_type_error__
      .exitmacro
    .endif
  .elseif @__flow_expr_type__ = __flow_expr_type_in_list__
    ;; no validation
  .elseif @__flow_expr_type__ = __flow_expr_type_between__
    .if .not(.xmatch(.mid(0, 1, {__flow_comparison_operand__}), #))
      .error .sprintf("%s: Expected immediate 1st argument for '%s'", __flow_statement__, __flow_comparison_operator_name__)
      @__flow_expr_type__ .set __flow_expr_type_error__
      .exitmacro
    .endif
    .ifblank reg
      .error .sprintf("%s: Expected 2nd argument for '%s'", __flow_statement__, __flow_comparison_operator_name__)
      @__flow_expr_type__ .set __flow_expr_type_error__
      .exitmacro
    .elseif .not(.xmatch(.mid(0, 1, {reg}), #))
      .error .sprintf("%s: Expected immediate 2nd argument for '%s'", __flow_statement__, __flow_comparison_operator_name__)
      @__flow_expr_type__ .set __flow_expr_type_error__
      .exitmacro
    .endif
  .elseif @__flow_expr_type__ = __flow_expr_type_error__
        ;; hit if an error happens before @__flow_expr_type__ is set
  .else
    .fatal "unreached"
  .endif
.endmacro

.macro _FLOW_PARSE_CLEANUP
  .undef __flow_compareOp__
  .undef __flow_branchOp1__
  .undef __flow_branchOp2__
  .undef __flow_flag_test_name__
  .undef __flow_comparison_operand__
  .undef __flow_comparison_operator_name__
  .undef __flow_register_name__
  .undef __flow_token__
  .undef __flow_next_token__
.endmacro

.macro _FLOW_END_STATEMENT
  .undef __flow_statement__
.endmacro


;;; ============================================================
;;; Code Generation
;;; ============================================================

;;; "Branch if true" generator (e.g. for WHILE where the body is repeated)
.macro _FLOW_CODEGEN_BIT target,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  .if @__flow_expr_type__ = __flow_expr_type_flag_test__
        _BOP_HELPER target
  .elseif @__flow_expr_type__ = __flow_expr_type_comparison__
     .ifblank arg2              ; register
        __flow_compareOp__ __flow_comparison_operand__
     .else
        __flow_compareOp__ __flow_comparison_operand__, arg2
     .endif
        _BOP_HELPER target
  .elseif @__flow_expr_type__ = __flow_expr_type_in_list__
        _IN_HELPER target,__flow_comparison_operand__,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  .elseif @__flow_expr_type__ = __flow_expr_type_between__
        _BETWEEN_HELPER target,__flow_comparison_operand__,arg2
  .endif
.endmacro

;;; "Branch if false" generator (e.g. for IF where the body is skipped)
.macro _FLOW_CODEGEN_BIF target,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  .if @__flow_expr_type__ = __flow_expr_type_flag_test__
        _NOT_BOP_HELPER target
  .elseif @__flow_expr_type__ = __flow_expr_type_comparison__
     .ifblank arg2              ; register
        __flow_compareOp__ __flow_comparison_operand__
     .else
        __flow_compareOp__ __flow_comparison_operand__, arg2
     .endif
        _NOT_BOP_HELPER target
  .elseif @__flow_expr_type__ = __flow_expr_type_in_list__
        _NOT_IN_HELPER target,__flow_comparison_operand__,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  .elseif @__flow_expr_type__ = __flow_expr_type_between__
        _NOT_BETWEEN_HELPER target,__flow_comparison_operand__,arg2
  .endif
.endmacro

;;; Helpers for branching to `target`
.macro _BOP_HELPER target
  .if !@__flow_expr_invert_flag__
     .if .def(target) .and .const((*-2)-(target)) .and ((*+2)-(target) > 127)
        __flow_branchOp2__ *+5
        jmp     target
     .else
        __flow_branchOp1__ target
     .endif
  .else
     .if .def(target) .and .const((*-2)-(target)) .and ((*+2)-(target) > 127)
        __flow_branchOp1__ *+5
        jmp     target
     .else
        __flow_branchOp2__ target
     .endif
  .endif
.endmacro
.macro _NOT_BOP_HELPER target
  .if !@__flow_expr_invert_flag__
     .if .def(target) .and .const((*-2)-(target)) .and ((*+2)-(target) > 127)
        __flow_branchOp1__ *+5
        jmp     target
     .else
        __flow_branchOp2__ target
     .endif
  .else
     .if .def(target) .and .const((*-2)-(target)) .and ((*+2)-(target) > 127)
        __flow_branchOp2__ *+5
        jmp     target
     .else
        __flow_branchOp1__ target
     .endif
  .endif
.endmacro

;;; Helper for branching to `target` when a value is not in a list.
.macro _IN_HELPER target,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  .if !@__flow_expr_invert_flag__
        _IN_HELPER2 target,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  .else
        _NOT_IN_HELPER2 target,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  .endif
.endmacro
.macro _NOT_IN_HELPER target,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  .if !@__flow_expr_invert_flag__
        _NOT_IN_HELPER2 target,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  .else
        _IN_HELPER2 target,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  .endif
.endmacro

;;; Codegen for "branch if in list"
.macro _IN_HELPER2 target,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
        __flow_compareOp__ arg1
        BEQ     target
    .ifnblank arg2
        _IN_HELPER2 target,arg2,arg3,arg4,arg5,arg6,arg7,arg8
    .endif
.endmacro

;;; Codegen for "branch if not in list"
.macro _NOT_IN_HELPER2 target,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
        .local stay
        _NOT_IN_HELPER3 stay,target,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
stay:
.endmacro
.macro _NOT_IN_HELPER3 eq_target,ne_target,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
        __flow_compareOp__ arg1
    .ifnblank arg2
        BEQ     eq_target
        _NOT_IN_HELPER3 eq_target,ne_target,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9
    .else
        BNE     ne_target
    .endif
.endmacro

;;; Helper for branching to `target` when a value is between two values
.macro _BETWEEN_HELPER target,lower,upper
  .if !@__flow_expr_invert_flag__
        _BETWEEN_HELPER2 target,lower,upper
  .else
        _NOT_BETWEEN_HELPER2 target,lower,upper
  .endif
.endmacro

;;; Helper for branching to `target` when a value is not between two values
.macro _NOT_BETWEEN_HELPER target,lower,upper
  .if !@__flow_expr_invert_flag__
        _NOT_BETWEEN_HELPER2 target,lower,upper
  .else
        _BETWEEN_HELPER2 target,lower,upper
  .endif
.endmacro

;;; Codegen for "branch if between"
.macro _BETWEEN_HELPER2 target,lower,upper
        .local stay
        __flow_compareOp__ lower
        BCC     stay
        __flow_compareOp__ upper+1
        BCC     target
stay:
.endmacro

;;; Codegen for "branch if not between"
.macro _NOT_BETWEEN_HELPER2 target,lower,upper
        __flow_compareOp__ lower
        BCC     target
        __flow_compareOp__ upper+1
        BCS     target
.endmacro


;;; ============================================================
;;; Glue it all together
;;; ============================================================

;;; Parse expression and generate code with "branch if true" semantics
.macro _FLOW_PARSE_AND_GEN_BIT target,expr,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  _FLOW_PARSE_EXPR {expr},arg2,arg3,arg4,arg5,arg6,arg7,arg8
  _FLOW_CODEGEN_BIT target,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  _FLOW_PARSE_CLEANUP
.endmacro

;;; Parse expression and generate code with "branch if false" semantics
.macro _FLOW_PARSE_AND_GEN_BIF target,expr,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  _FLOW_PARSE_EXPR {expr},arg2,arg3,arg4,arg5,arg6,arg7,arg8
  _FLOW_CODEGEN_BIF target,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  _FLOW_PARSE_CLEANUP
.endmacro


;;; ============================================================
;;; IF / ELSE_IF / ELSE / END_IF
;;; ============================================================
;;;
;;; Usage:
;;;     IF <condition>
;;;     ...
;;;     ELSE <condition> ; optional
;;;     ...
;;;     ELSE ; optional
;;;     ...
;;;     END_IF
;;;
;;; Macros:
;;;     IF
;;;     ELSE_IF
;;;     ELSE
;;;     END_IF

;;; A numeric variable for the current nesting depth of flow control
;;; structures. Incremented when entering a structure, decremented
;;; when leaving.
.define __flow_branch_depth__ ::__branch_depth__

;;; A numeric variable for the "Nth" flow control structure (if,
;;; do/while, etc) at depth D. Used to mint various identifiers unique
;;; to each, without using scopes. Incremented when entering a
;;; structure.
.define __flow_branch_count_at_depth__ ::.ident(.sprintf("__flow_branch_cad_%d__", __flow_branch_depth__))

;;; Produce a unique identifier within this flow control structure.
;;; Usage: `__flow_branch_ident__ {"else"}`
.define __flow_branch_ident__(prefix) ::.ident(.sprintf("__flow_branch_id_%s_%d_%d__", prefix, __flow_branch_depth__, __flow_branch_count_at_depth__))

;;; Produce unique identifiers for the end of each block
.define __flow_branch_ident_counter__ __flow_branch_ident__ {"counter"}
.define __flow_branch_ident_block__ __flow_branch_ident__ {.sprintf("eob%d", __flow_branch_ident_counter__)}

.macro IF expr,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  _FLOW_STATEMENT "IF"

        __INC_IDENT__ __flow_branch_depth__
        __INC_IDENT__ __flow_branch_count_at_depth__
        __INC_IDENT__ __flow_branch_ident_counter__

        .local no_match
        no_match := __flow_branch_ident_block__

        _FLOW_PARSE_AND_GEN_BIF no_match,{expr},arg2,arg3,arg4,arg5,arg6,arg7,arg8

  _FLOW_END_STATEMENT
.endmacro

.macro ELSE_IF expr,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  _FLOW_STATEMENT "ELSE_IF"

        jmp     __flow_branch_ident__ {"endif"}
        __flow_branch_ident_block__ := *
        __INC_IDENT__ __flow_branch_ident_counter__

        .local no_match
        no_match := __flow_branch_ident_block__

        _FLOW_PARSE_AND_GEN_BIF no_match,{expr},arg2,arg3,arg4,arg5,arg6,arg7,arg8

  _FLOW_END_STATEMENT
.endmacro

.macro ELSE
        __FLOW_LOG__ "else"
        jmp     __flow_branch_ident__ {"endif"}
        __flow_branch_ident_block__ := *
.endmacro

.macro END_IF
        __FLOW_LOG__ "endif"

    .ifndef __flow_branch_ident_block__
        __FLOW_LOG__ "no else"
        __flow_branch_ident_block__ := *
    .endif

        __flow_branch_ident__ {"endif"} := *
        .refto __flow_branch_ident__ {"endif"}

        __DEC_IDENT__ __flow_branch_depth__
.endmacro

.macro ENDIF
        .error "Do you mean END_IF ?"
        .exitmacro
.endmacro


;;; ============================================================
;;; DO / CONTINUE_IF / BREAK_IF / WHILE or REPEAT / UNTIL
;;; ============================================================

;;; Usage:
;;;     DO
;;;     ...
;;;     BREAK_IF <condition> ; optional
;;;     ...
;;;     CONTINUE_IF <condition> ; optional
;;;     ...
;;;     WHILE <condition>
;;;
;;;     REPEAT
;;;     ...
;;;     BREAK_IF <condition> ; optional
;;;     ...
;;;     CONTINUE_IF <condition> ; optional
;;;     ...
;;;     UNTIL <condition>
;;;
;;; Macros:
;;;     DO                 aliases: REPEAT
;;;     WHILE
;;;     UNTIL
;;;
;;;     CONTINUE_IF
;;;     BREAK_IF

;;; A numeric variable for the current nesting depth of flow control
;;; structures. Incremented when entering a structure, decremented
;;; when leaving.
.define __flow_loop_depth__ ::__loop_depth__

;;; A numeric variable for the "Nth" flow control structure (if,
;;; do/while, etc) at depth D. Used to mint various identifiers unique
;;; to each, without using scopes. Incremented when entering a
;;; structure.
.define __flow_loop_count_at_depth__ ::.ident(.sprintf("__flow_loop_cad_%d__", __flow_loop_depth__))

;;; Produce a unique identifier within this flow control structure.
;;; Usage: `__flow_loop_ident__ {"else"}`
.define __flow_loop_ident__(prefix) ::.ident(.sprintf("__flow_loop_id_%s_%d_%d__", prefix, __flow_loop_depth__, __flow_loop_count_at_depth__))

;;; Produce unique identifiers for the end of each block
.define __flow_loop_ident_counter__ __flow_loop_ident__ {"counter"}
.define __flow_loop_ident_block__ __flow_loop_ident__ {.sprintf("eol%d", __flow_loop_ident_counter__)}

.macro DO
        __INC_IDENT__ __flow_loop_depth__
        __INC_IDENT__ __flow_loop_count_at_depth__

        __FLOW_LOG__ "do"
        __flow_loop_ident__ {"do_while"} := *
.endmacro

.define REPEAT DO

.macro CONTINUE_IF expr,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  _FLOW_STATEMENT "CONTINUE_IF"

        .local @continue
        @continue := __flow_loop_ident__ {"do_while"}

        _FLOW_PARSE_AND_GEN_BIT @continue,{expr},arg2,arg3,arg4,arg5,arg6,arg7,arg8

  _FLOW_END_STATEMENT
.endmacro

.macro BREAK_IF expr,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  _FLOW_STATEMENT "BREAK_IF"

        .local @break
        @break := __flow_loop_ident__ {"break"}

        _FLOW_PARSE_AND_GEN_BIT @break,{expr},arg2,arg3,arg4,arg5,arg6,arg7,arg8

  _FLOW_END_STATEMENT
.endmacro

.macro WHILE expr,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  _FLOW_STATEMENT "WHILE"

        .local continue
        continue := __flow_loop_ident__ {"do_while"}

        _FLOW_PARSE_AND_GEN_BIT continue,{expr},arg2,arg3,arg4,arg5,arg6,arg7,arg8

        __flow_loop_ident__ {"break"} := *
        .refto __flow_loop_ident__ {"break"}

        __DEC_IDENT__ __flow_loop_depth__

  _FLOW_END_STATEMENT
.endmacro

.macro UNTIL expr,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  _FLOW_STATEMENT "UNTIL"

        ;; Note that "do_while" is still used for minting identifiers
        ;; so that DO and REPEAT remain synonyms and helpers can be
        ;; shared between WHILE and UNTIL.

        .local continue
        continue := __flow_loop_ident__ {"do_while"}

        _FLOW_PARSE_AND_GEN_BIF continue,{expr},arg2,arg3,arg4,arg5,arg6,arg7,arg8

        __flow_loop_ident__ {"break"} := *
        .refto __flow_loop_ident__ {"break"}

        __DEC_IDENT__ __flow_loop_depth__

  _FLOW_END_STATEMENT
.endmacro

;;; ============================================================
;;; RTS_IF
;;; ============================================================

;;; Macros:
;;;     RTS_IF

.macro RTS_IF expr,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  _FLOW_STATEMENT "RTS_IF"

        .local skip

        _FLOW_PARSE_AND_GEN_BIF skip,{expr},arg2,arg3,arg4,arg5,arg6,arg7,arg8

        rts
        skip := *

  _FLOW_END_STATEMENT
.endmacro


;;; ============================================================
;;; Flag Aliases
;;; ============================================================

.define EQ       ZS
.define ZERO     ZS
.define NE       ZC
.define NOT_ZERO ZC
.define NEG      NS
.define POS      NC
.define GE       CS
.define LT       CC

;;; ============================================================
;;; Compatibility Macros
;;; ============================================================

;;; e.g. IF_EQ, IF_A_LT, etc

.macro _FLOW_DEFINE_FLAG_MACROS_ cond
        .define .ident(.sprintf("IF_%s", cond)) IF .ident(cond)
        .define .ident(.sprintf("ELSE_IF_%s", cond)) ELSE_IF .ident(cond)
        .define .ident(.sprintf("WHILE_%s", cond)) WHILE .ident(cond)
        .define .ident(.sprintf("UNTIL_%s", cond)) UNTIL .ident(cond)
        .define .ident(.sprintf("CONTINUE_IF_%s", cond)) CONTINUE_IF .ident(cond)
        .define .ident(.sprintf("BREAK_IF_%s", cond)) BREAK_IF .ident(cond)
        .define .ident(.sprintf("RTS_IF_%s", cond)) RTS_IF .ident(cond)
.endmacro
.macro _FLOW_DEFINE_COMPARE_MACROS_ cond
        .define .ident(.sprintf("IF_A_%s", cond)) IF A .ident(cond)
        .define .ident(.sprintf("ELSE_IF_A_%s", cond)) ELSE_IF A .ident(cond)
        .define .ident(.sprintf("WHILE_A_%s", cond)) WHILE A .ident(cond)
        .define .ident(.sprintf("UNTIL_A_%s", cond)) UNTIL A .ident(cond)
        .define .ident(.sprintf("CONTINUE_IF_A_%s", cond)) CONTINUE_IF A .ident(cond)
        .define .ident(.sprintf("BREAK_IF_A_%s", cond)) BREAK_IF A .ident(cond)
        .define .ident(.sprintf("RTS_IF_A_%s", cond)) RTS_IF A .ident(cond)

        .define .ident(.sprintf("IF_X_%s", cond)) IF X.ident(cond)
        .define .ident(.sprintf("ELSE_IF_X_%s", cond)) ELSE_IF X.ident(cond)
        .define .ident(.sprintf("WHILE_X_%s", cond)) WHILE X.ident(cond)
        .define .ident(.sprintf("UNTIL_X_%s", cond)) UNTIL X.ident(cond)
        .define .ident(.sprintf("CONTINUE_IF_X_%s", cond)) CONTINUE_IF X.ident(cond)
        .define .ident(.sprintf("BREAK_IF_X_%s", cond)) BREAK_IF X.ident(cond)
        .define .ident(.sprintf("RTS_IF_X_%s", cond)) RTS_IF X.ident(cond)

        .define .ident(.sprintf("IF_Y_%s", cond)) IF Y .ident(cond)
        .define .ident(.sprintf("ELSE_IF_Y_%s", cond)) ELSE_IF Y .ident(cond)
        .define .ident(.sprintf("WHILE_Y_%s", cond)) WHILE Y .ident(cond)
        .define .ident(.sprintf("UNTIL_Y_%s", cond)) UNTIL Y .ident(cond)
        .define .ident(.sprintf("CONTINUE_IF_Y_%s", cond)) CONTINUE_IF Y .ident(cond)
        .define .ident(.sprintf("BREAK_IF_Y_%s", cond)) BREAK_IF Y .ident(cond)
        .define .ident(.sprintf("RTS_IF_Y_%s", cond)) RTS_IF Y .ident(cond)
.endmacro

_FLOW_DEFINE_FLAG_MACROS_ "ZS"
_FLOW_DEFINE_FLAG_MACROS_ "ZC"
_FLOW_DEFINE_FLAG_MACROS_ "CS"
_FLOW_DEFINE_FLAG_MACROS_ "CC"
_FLOW_DEFINE_FLAG_MACROS_ "VS"
_FLOW_DEFINE_FLAG_MACROS_ "VC"
_FLOW_DEFINE_FLAG_MACROS_ "NS"
_FLOW_DEFINE_FLAG_MACROS_ "NC"

_FLOW_DEFINE_FLAG_MACROS_ "EQ"
_FLOW_DEFINE_FLAG_MACROS_ "ZERO"
_FLOW_DEFINE_FLAG_MACROS_ "NE"
_FLOW_DEFINE_FLAG_MACROS_ "NOT_ZERO"
_FLOW_DEFINE_FLAG_MACROS_ "GE"
_FLOW_DEFINE_FLAG_MACROS_ "LT"
_FLOW_DEFINE_FLAG_MACROS_ "MINUS"
_FLOW_DEFINE_FLAG_MACROS_ "NEG"
_FLOW_DEFINE_FLAG_MACROS_ "PLUS"
_FLOW_DEFINE_FLAG_MACROS_ "POS"

_FLOW_DEFINE_COMPARE_MACROS_ "EQ"
_FLOW_DEFINE_COMPARE_MACROS_ "NE"
_FLOW_DEFINE_COMPARE_MACROS_ "LT"
_FLOW_DEFINE_COMPARE_MACROS_ "GE"


.macro IF_A_EQ_ONE_OF arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
        IF A IN arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
.endmacro

.macro IF_A_NE_ALL_OF arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
        IF A NOT_IN arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
.endmacro

;;; ============================================================
;;;
;;; Function Calls
;;;
;;; ============================================================

;;; * CALL proc, args...
;;; * TAIL_CALL proc, args...
;;; * RETURN args...
;;;
;;; Args take the form of (pseudo-)register or flag assigments, and
;;; loads/clears/sets are emitted in the order given. CALL produces
;;; a JSR, TAIL_CALL produces a JMP, and RETURN produces RTS.
;;;
;;; Registers/pseudo-registers are: A, X, Y, AX, AY, XY, YA
;;; Expressions can be anything supported by the LD* ops/pseudo-ops.
;;; e.g. CALL Proc, AX=ptr, Y=#kOptions
;;;
;;; Flags are: C, D
;;; Expressions must be constant (e.g. 0, 1, kConst, etc)
;;; e.g. CALL Proc, C=1

.macro CALL target,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9
    _FLOW_STATEMENT "CALL"
    _CALL_HELPER {arg1},{arg2},{arg3},{arg4},{arg5},{arg6},{arg7},{arg8},{arg9}
        jsr     target
    _FLOW_END_STATEMENT
.endmacro

.macro TAIL_CALL target,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9
    _FLOW_STATEMENT "TAIL_CALL"
    _CALL_HELPER {arg1},{arg2},{arg3},{arg4},{arg5},{arg6},{arg7},{arg8},{arg9}
        jmp     target
    _FLOW_END_STATEMENT
.endmacro

.macro RETURN arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9
    _FLOW_STATEMENT "RETURN"
    _CALL_HELPER {arg1},{arg2},{arg3},{arg4},{arg5},{arg6},{arg7},{arg8},{arg9}
        rts
    _FLOW_END_STATEMENT
.endmacro

.macro _CALL_HELPER arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9
    .ifblank arg1
        ;; nothing
    .elseif .xmatch({arg2},X) .or .xmatch({arg2},Y)
        ;; Allow calling like: A=table,x
        _CALL_SETUP
        _CALL_EXPR {arg1,arg2}
        _CALL_CLEANUP
        _CALL_HELPER {arg3},{arg4},{arg5},{arg6},{arg7},{arg8},{arg9}
    .else
        _CALL_SETUP
        _CALL_EXPR {arg1}
        _CALL_CLEANUP
        _CALL_HELPER {arg2},{arg3},{arg4},{arg5},{arg6},{arg7},{arg8},{arg9}
    .endif
.endmacro

.define __flow_call_load_type_register__ 1
.define __flow_call_load_type_flag__ 2

.macro _CALL_SETUP
    .define __flow_opcode__ __nothing__
    .define __flow_register_name__ __nothing__
.endmacro
.macro _CALL_CLEANUP
    .undef __flow_opcode__
    .undef __flow_register_name__
.endmacro

.macro _CALL_EXPR arg

        ;; --------------------------------------------------
        ;; Parsing

        ;; '@' is used for numeric variables so they don't interfere
        ;; with cheap local labels in user code.

    .local @__flow_call_load_type__

    .if .xmatch(.left(1,{arg}), A)
      .undef __flow_register_name__
      .undef __flow_opcode__
      .define __flow_register_name__ "A"
      .define __flow_opcode__ LDA
      @__flow_call_load_type__ .set __flow_call_load_type_register__
    .elseif .xmatch(.left(1,{arg}), X)
      .undef __flow_register_name__
      .undef __flow_opcode__
      .define __flow_register_name__ "X"
      .define __flow_opcode__ LDX
      @__flow_call_load_type__ .set __flow_call_load_type_register__
    .elseif .xmatch(.left(1,{arg}), Y)
      .undef __flow_register_name__
      .undef __flow_opcode__
      .define __flow_register_name__ "Y"
      .define __flow_opcode__ LDY
      @__flow_call_load_type__ .set __flow_call_load_type_register__
    .elseif .xmatch(.left(1,{arg}), AX)
      .undef __flow_register_name__
      .undef __flow_opcode__
      .define __flow_register_name__ "AX"
      .define __flow_opcode__ ldax
      @__flow_call_load_type__ .set __flow_call_load_type_register__
    .elseif .xmatch(.left(1,{arg}), AY)
      .undef __flow_register_name__
      .undef __flow_opcode__
      .define __flow_register_name__ "AY"
      .define __flow_opcode__ lday
      @__flow_call_load_type__ .set __flow_call_load_type_register__
    .elseif .xmatch(.left(1,{arg}), YA)
      .undef __flow_register_name__
      .undef __flow_opcode__
      .define __flow_register_name__ "YA"
      .define __flow_opcode__ ldya
      @__flow_call_load_type__ .set __flow_call_load_type_register__
    .elseif .xmatch(.left(1,{arg}), XY)
      .undef __flow_register_name__
      .undef __flow_opcode__
      .define __flow_register_name__ "XY"
      .define __flow_opcode__ ldxy
      @__flow_call_load_type__ .set __flow_call_load_type_register__
    .elseif .xmatch(.left(1,{arg}), C)
      .undef __flow_register_name__
      .define __flow_register_name__ "C"
      @__flow_call_load_type__ .set __flow_call_load_type_flag__
    .elseif .xmatch(.left(1,{arg}), D)
      .undef __flow_register_name__
      .define __flow_register_name__ "D"
      @__flow_call_load_type__ .set __flow_call_load_type_flag__
    .else
      .error .sprintf("%s: Expected 'reg=...'", __flow_statement__)
      .exitmacro
    .endif

        ;; --------------------------------------------------
        ;; Validation

    .if .not(.xmatch(.mid(1,1,{arg}), =))
      .error .sprintf("%s: Expected '%s=...'", __flow_statement__, __flow_register_name__)
      .exitmacro
    .endif

    .if @__flow_call_load_type__ = __flow_call_load_type_register__
      .if .match(.mid(2,1,{arg}), 0)
        .error .sprintf("%s: Numeric literal in '%s=expr' assignment; did you mean '#%s'?", __flow_statement__, __flow_register_name__, .string(.mid(2,1,{arg})))
        .exitmacro
      .endif
      .if .match(.mid(2,1,{arg}), kDummyConstant)
        .if .strat(.string(.mid(2,1,{arg})), 0) = 'k' .and .strat(.string(.mid(2,1,{arg})), 1) >= 'A' .and .strat(.string(.mid(2,1,{arg})), 1) <= 'Z'
          .error .sprintf("%s: Constant in '%s=expr' assignment; did you mean '#%s'?", __flow_statement__, __flow_register_name__, .string(.mid(2,1,{arg})))
          .exitmacro
        .endif
      .endif
    .elseif @__flow_call_load_type__ = __flow_call_load_type_flag__
      .if .tcount({arg}) <> 3
        .error .sprintf("%s: Unexpected tokens after '%s=...'", __flow_statement__, __flow_register_name__)
        .exitmacro
      .endif

      .if .not(.const(.mid(2,9999,{arg})))
        .error .sprintf("%s: Expected constant expression after '%s='", __flow_statement__, __flow_register_name__)
        .exitmacro
      .elseif .mid(2,9999,{arg})
        .if .xmatch(__flow_register_name__, "C")
          .undef __flow_opcode__
          .define __flow_opcode__ SEC
        .elseif .xmatch(__flow_register_name__, "D")
          .undef __flow_opcode__
          .define __flow_opcode__ SED
        .endif
      .else
        .if .xmatch(__flow_register_name__, "C")
          .undef __flow_opcode__
          .define __flow_opcode__ CLC
        .elseif .xmatch(__flow_register_name__, "D")
          .undef __flow_opcode__
          .define __flow_opcode__ CLD
        .endif
      .endif

    .else
      .fatal "unreached"
    .endif

        ;; --------------------------------------------------
        ;; Code generation

    .if @__flow_call_load_type__ = __flow_call_load_type_register__
        __flow_opcode__     .mid(2,9999,{arg})
    .elseif @__flow_call_load_type__ = __flow_call_load_type_flag__
        __flow_opcode__
    .else
      .fatal "unreached"
    .endif
.endmacro
