;;; ============================================================
;;; Flow Control
;;; ============================================================

;;; Macros that provide higher level flow control without resorting to
;;; throw-away labels.

;;; * IF expr / ELSE_IF expr / ELSE / END_IF
;;;   * and IF_A_EQ_ONE_OF as a common case
;;;   * and IF_A_NE_ALL_OF as a common case
;;; * DO / CONTINUE_IF expr / BREAK_IF expr / WHILE expr
;;;   * or REPEAT / UNTIL expr if you prefer
;;; * RTS_IF expr
;;;
;;; Expressions take the form of flag tests or register comparisons.
;;;
;;; Flag tests: ZS ZC CS CC VS VC NS NC
;;; (Aliases: EQ, NE, ZERO, NOT_ZERO, LT, GE, POS, NEG, PLUS, MINUS)
;;;
;;; Register comparisons: <register> <operator> <argument>
;;; e.g. "IF A = #25"
;;; Operators: =, <>, <, >= (aliases: EQ, NE, LT, GE)

;;; ============================================================
;;; Flow control infrastructure
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

.macro __SET_BOPS__ bop1, bop2
  .undef __flow_branchOp1__
  .undef __flow_branchOp2__
  .define __flow_branchOp1__ bop1
  .define __flow_branchOp2__ bop2
.endmacro

.macro __SET_COP__ reg, cop
  .define __flow_register_name__ reg
  .undef __flow_compareOp__
  .define __flow_compareOp__ cop
.endmacro

.macro __RESULT_FLAG_TEST__ bop1, bop2
  __SET_BOPS__ bop1, bop2
  __flow_expr_type__ .set ::__flow_expr_type_flag_test__
  __flow_break_loop_flag__ .set 1
.endmacro

.macro __RESULT_COMP_TEST__ bop1, bop2
  __SET_BOPS__ bop1, bop2
  __flow_expr_type__ .set ::__flow_expr_type_comparison__
  __flow_break_loop_flag__ .set 1
.endmacro

::__flow_expr_type_flag_test__ = 1
::__flow_expr_type_comparison__ = 2

;;; FUTURE: Actually look at multiple expressions
.macro _FLOW_PARSE_EXPR_LOOP expr, tindex
  .define __flow_token__ .mid(tindex, 1, {expr})
  .define __flow_next_token__ .mid(tindex+1, 1, {expr})
  .define __flow_comparison_operand__

;;; Flag tests

  .if     .xmatch({__flow_token__}, ZS)
    __RESULT_FLAG_TEST__ BEQ, BNE
  .elseif .xmatch({__flow_token__}, ZC)
    __RESULT_FLAG_TEST__ BNE, BEQ
  .elseif .xmatch({__flow_token__}, CS)
    __RESULT_FLAG_TEST__ BCS, BCC
  .elseif .xmatch({__flow_token__}, CC)
    __RESULT_FLAG_TEST__ BCC, BCS
  .elseif .xmatch({__flow_token__}, NS)
    __RESULT_FLAG_TEST__ BMI, BPL
  .elseif .xmatch({__flow_token__}, NC)
    __RESULT_FLAG_TEST__ BPL, BMI
  .elseif .xmatch({__flow_token__}, VS)
    __RESULT_FLAG_TEST__ BVS, BVC
  .elseif .xmatch({__flow_token__}, VC)
    __RESULT_FLAG_TEST__ BVC, BVS

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

        ;; Determine the branch opcodes from the comparison operator
    .if .xmatch({__flow_next_token__}, =) .or .xmatch({__flow_next_token__}, EQ)
      __RESULT_COMP_TEST__ BEQ, BNE
    .elseif .xmatch({__flow_next_token__}, <>) .or .xmatch({__flow_next_token__}, NE)
      __RESULT_COMP_TEST__ BNE, BEQ
    .elseif .xmatch({__flow_next_token__}, <) .or .xmatch({__flow_next_token__}, LT)
      __RESULT_COMP_TEST__ BCC, BCS
    .elseif .xmatch({__flow_next_token__}, >=) .or .xmatch({__flow_next_token__}, GE)
      __RESULT_COMP_TEST__ BCS, BCC
    .else
      .error .sprintf("%s: No operator match after register %s", __flow_statement__, __flow_register_name__)
    .endif

    .undef __flow_comparison_operand__
    .define __flow_comparison_operand__ .mid(__flow_current_index__+2, 9999, {expr})

    .undef __flow_register_name__

  .else
    .error .sprintf("%s: No expression match", __flow_statement__)
  .endif

  .undef __flow_token__
  .undef __flow_next_token__
.endmacro

.macro _FLOW_PARSE_EXPR expr, reg
  .define __flow_compareOp__ __nothing__
  .define __flow_branchOp1__ __nothing__
  .define __flow_branchOp2__ __nothing__

        ;; Parse expression
  .ifblank expr
    .error .sprintf("%s: empty expression", __flow_statement__)
  .endif

  __flow_expr_type__ .set 0
  __flow_break_loop_flag__ .set 0

  .repeat .tcount({expr}), tindex
    .if .not(__flow_break_loop_flag__)
    __flow_current_index__ .set tindex
    _FLOW_PARSE_EXPR_LOOP {expr}, tindex
    .endif
  .endrepeat

  .if __flow_expr_type__ = ::__flow_expr_type_flag_test__
    .if .tcount({expr}) > __flow_current_index__ + 1
      .error .sprintf("%s: Unexpected tokens after flag test '%s'", __flow_statement__, .string(.mid(__flow_current_index__, 1, {expr})))
    .endif
     .ifnblank reg
       .error .sprintf("%s: Unexpected arguments after flag test '%s'", __flow_statement__, .string(.mid(__flow_current_index__, 1, {expr})))
     .endif
  .elseif __flow_expr_type__ = ::__flow_expr_type_comparison__
     ;; no validation
  .else
     .fatal "unreached"
  .endif
.endmacro

.macro _FLOW_PARSE_CLEANUP
  .undef __flow_compareOp__
  .undef __flow_branchOp1__
  .undef __flow_branchOp2__
  .undef __flow_comparison_operand__
.endmacro

.macro _FLOW_END_STATEMENT
  .undef __flow_statement__
.endmacro

;;; ============================================================
;;; IF / ELSE_IF / ELSE / END_IF
;;; ============================================================
;;;
;;; Usage:
;;;     bit foo
;;;     IF NS
;;;     ...
;;;     ELSE IF VS ; optional
;;;     ...
;;;     ELSE ; optional
;;;     ...
;;;     END_IF
;;;
;;;     lda     foo
;;;     IF A = bar
;;;     ...
;;;     END_IF
;;;
;;;     IF_A_EQ_ONE_OF #CHAR_UP, #CHAR_DOWN
;;;     ...
;;;     END_IF
;;;
;;;     IF_A_NE_ALL_OF #ST_LINKED_DIRECTORY, #ST_VOLUME_DIRECTORY
;;;     ...
;;;     END_IF
;;;
;;; Macros:
;;;     IF
;;;     IF_A_EQ_ONE_OF
;;;     IF_A_NE_ALL_OF
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

.macro IF expr, reg
  _FLOW_STATEMENT "IF"
  _FLOW_PARSE_EXPR {expr}, reg

        __INC_IDENT__ __flow_branch_depth__
        __INC_IDENT__ __flow_branch_count_at_depth__
        __INC_IDENT__ __flow_branch_ident_counter__

  .if __flow_expr_type__ = ::__flow_expr_type_comparison__
     .ifblank reg
        __flow_compareOp__ __flow_comparison_operand__
     .else
        __flow_compareOp__ __flow_comparison_operand__, reg
     .endif
  .endif

        __flow_branchOp2__ __flow_branch_ident_block__

  _FLOW_PARSE_CLEANUP
  _FLOW_END_STATEMENT
.endmacro

.macro ELSE_IF expr, reg
  _FLOW_STATEMENT "ELSE_IF"
  _FLOW_PARSE_EXPR {expr}, reg

        jmp     __flow_branch_ident__ {"endif"}
        __flow_branch_ident_block__ := *
        __INC_IDENT__ __flow_branch_ident_counter__


  .if __flow_expr_type__ = ::__flow_expr_type_comparison__
     .ifblank reg
        __flow_compareOp__ __flow_comparison_operand__
     .else
        __flow_compareOp__ __flow_comparison_operand__, reg
     .endif
  .endif

        __flow_branchOp2__ __flow_branch_ident_block__

  _FLOW_PARSE_CLEANUP
  _FLOW_END_STATEMENT
.endmacro

.macro IF_A_EQ_ONE_OF arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
        __INC_IDENT__ __flow_branch_depth__
        __INC_IDENT__ __flow_branch_count_at_depth__
        __INC_IDENT__ __flow_branch_ident_counter__
        __FLOW_LOG__ "if_one_of"

        _IF_ONE_OF_HELPER_ arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
.endmacro

.macro _IF_ONE_OF_HELPER_ arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
        cmp     arg1
    .ifnblank arg2
        ;; NOTE: Branches to just after the BNE
        beq     __flow_branch_ident__ {"if_one_of_terminal"} + 2
        _IF_ONE_OF_HELPER_ arg2,arg3,arg4,arg5,arg6,arg7,arg8
    .else
        __flow_branch_ident__ {"if_one_of_terminal"} := *
        __INC_IDENT__ __flow_branch_ident_counter__
        bne __flow_branch_ident_block__
    .endif
.endmacro

.macro IF_A_NE_ALL_OF arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
        __INC_IDENT__ __flow_branch_depth__
        __INC_IDENT__ __flow_branch_count_at_depth__
        __INC_IDENT__ __flow_branch_ident_counter__
        __FLOW_LOG__ "if_not_one_of"

        _IF_NOT_ONE_OF_HELPER_ arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
.endmacro

.macro _IF_NOT_ONE_OF_HELPER_ arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
        cmp     arg1
        beq     __flow_branch_ident_block__
    .ifnblank arg2
        _IF_NOT_ONE_OF_HELPER_ arg2,arg3,arg4,arg5,arg6,arg7,arg8
    .endif
.endmacro

.macro ELSE
        __FLOW_LOG__ "else"
        jmp     __flow_branch_ident__ {"endif"}
        __flow_branch_ident_block__ := *
        __INC_IDENT__ __flow_branch_ident_counter__
.endmacro

.macro END_IF
    .ifndef __flow_branch_ident_block__
        __FLOW_LOG__ "no else"
        __flow_branch_ident_block__ := *
    .endif

        __FLOW_LOG__ "endif"

        __flow_branch_ident__ {"endif"} := *
        .refto __flow_branch_ident__ {"endif"}

        __DEC_IDENT__ __flow_branch_depth__
.endmacro

.macro ENDIF
        .error "Do you mean END_IF ?"
.endmacro


;;; ============================================================
;;; DO / CONTINUE_IF / BREAK_IF / WHILE or REPEAT / UNTIL
;;; ============================================================

;;; Usage:
;;;     ldx #17
;;;     DO
;;;     ...
;;;     BREAK_IF A = #89
;;;     ...
;;;     CONTINUE_IF VS
;;;     ...
;;;     dex
;;;     WHILE_POS
;;;
;;;     REPEAT
;;;     ...
;;;     BREAK_IF Y = #0
;;;     ...
;;;     UNTIL A = #'/'
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
.define __flow_loop_ident_block__ __flow_loop_ident__ {.sprintf("eob%d", __flow_loop_ident_counter__)}

.macro DO
        __INC_IDENT__ __flow_loop_depth__
        __INC_IDENT__ __flow_loop_count_at_depth__

        __FLOW_LOG__ "do"
        __flow_loop_ident__ {"do_while"} := *
.endmacro

.define REPEAT DO

.macro CONTINUE_IF expr, reg
  _FLOW_STATEMENT "CONTINUE_IF"
  _FLOW_PARSE_EXPR {expr}, reg

  .if __flow_expr_type__ = ::__flow_expr_type_comparison__
     .ifblank reg
        __flow_compareOp__ __flow_comparison_operand__
     .else
        __flow_compareOp__ __flow_comparison_operand__, reg
     .endif
  .endif

        __flow_branchOp1__ __flow_loop_ident__ {"do_while"}

  _FLOW_PARSE_CLEANUP
  _FLOW_END_STATEMENT
.endmacro

.macro BREAK_IF expr, reg
  _FLOW_STATEMENT "BREAK_IF"
  _FLOW_PARSE_EXPR {expr}, reg

  .if __flow_expr_type__ = ::__flow_expr_type_comparison__
     .ifblank reg
        __flow_compareOp__ __flow_comparison_operand__
     .else
        __flow_compareOp__ __flow_comparison_operand__, reg
     .endif
  .endif

        __flow_branchOp1__ __flow_loop_ident__ {"break"}

  _FLOW_PARSE_CLEANUP
  _FLOW_END_STATEMENT
.endmacro

.macro _WHILE_BOP_ branchOp
        __FLOW_LOG__ "while"
        branchOp __flow_loop_ident__ {"do_while"}

        __flow_loop_ident__ {"break"} := *
        .refto __flow_loop_ident__ {"break"}

        __DEC_IDENT__ __flow_loop_depth__
.endmacro

.macro _WHILE_COP_BOP_ compareOp, branchOp, arg, reg
        __FLOW_LOG__ "while"
      .ifblank reg
        compareOp arg
      .else
        compareOp arg,reg
      .endif
        branchOp __flow_loop_ident__ {"do_while"}

        __flow_loop_ident__ {"break"} := *
        .refto __flow_loop_ident__ {"break"}

        __DEC_IDENT__ __flow_loop_depth__
.endmacro

.macro WHILE expr, reg
  _FLOW_STATEMENT "WHILE"
  _FLOW_PARSE_EXPR {expr}, reg

  .if __flow_expr_type__ = ::__flow_expr_type_comparison__
     .ifblank reg
        __flow_compareOp__ __flow_comparison_operand__
     .else
        __flow_compareOp__ __flow_comparison_operand__, reg
     .endif
  .endif

        __flow_branchOp1__ __flow_loop_ident__ {"do_while"}

        __flow_loop_ident__ {"break"} := *
        .refto __flow_loop_ident__ {"break"}

        __DEC_IDENT__ __flow_loop_depth__

  _FLOW_PARSE_CLEANUP
  _FLOW_END_STATEMENT
.endmacro

.macro UNTIL expr, reg
  _FLOW_STATEMENT "UNTIL"
  _FLOW_PARSE_EXPR {expr}, reg

  .if __flow_expr_type__ = ::__flow_expr_type_comparison__
     .ifblank reg
        __flow_compareOp__ __flow_comparison_operand__
     .else
        __flow_compareOp__ __flow_comparison_operand__, reg
     .endif
  .endif

        __flow_branchOp2__ __flow_loop_ident__ {"do_while"}

        __flow_loop_ident__ {"break"} := *
        .refto __flow_loop_ident__ {"break"}

        __DEC_IDENT__ __flow_loop_depth__

  _FLOW_PARSE_CLEANUP
  _FLOW_END_STATEMENT
.endmacro

;;; ============================================================
;;; RTS_IF
;;; ============================================================

;;; Macros:
;;;     RTS_IF

.macro RTS_IF expr, reg
  _FLOW_STATEMENT "RTS_IF"
  _FLOW_PARSE_EXPR {expr}, reg

  .if __flow_expr_type__ = ::__flow_expr_type_comparison__
     .ifblank reg
        __flow_compareOp__ __flow_comparison_operand__
     .else
        __flow_compareOp__ __flow_comparison_operand__, reg
     .endif
  .endif

        .local skip
        __flow_branchOp2__ skip
        rts
skip:

  _FLOW_PARSE_CLEANUP
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
