;;; ============================================================
;;; Flow Control
;;; ============================================================

;;; Macros that provide higher level flow control without resorting to
;;; throw-away labels.

;;; * IF_* / ELSE_IF_* / ELSE / END_IF
;;;   * and IF_A_EQ_ONE_OF as a common case
;;; * DO / CONTINUE_IF_* / BREAK_IF_* / WHILE_*
;;;   * or REPEAT / UNTIL_* if you prefer
;;; * RTS_IF_*
;;;
;;; Conditions (the "*" above) take the form of flag tests or
;;; register comparisons (with an argument):
;;;
;;; Flag tests: ZS ZC CS CC VS VC NS NC
;;; (Aliases: EQ, NE, ZERO, NOT_ZERO, LT, GE, POS, NEG, PLUS, MINUS)
;;;
;;; Comparisons: A_EQ, A_NE, A_LT, A_GE; ditto for X and Y

;;; ============================================================
;;; Flow control infrastructure
;;; ============================================================

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
;;; IF_* / ELSE_IF_* / ELSE / END_IF
;;; ============================================================
;;;
;;; Usage:
;;;     bit foo
;;;     IF_NS
;;;     ...
;;;     ELSE_IF_VS ; optional
;;;     ...
;;;     ELSE ; optional
;;;     ...
;;;     END_IF
;;;
;;;     lda     foo
;;;     IF_A_EQ bar
;;;     ...
;;;     END_IF
;;;
;;;     IF_A_EQ_ONE_OF #CHAR_UP, #CHAR_DOWN
;;;     ...
;;;     END_IF
;;;
;;; Macros:
;;;     IF_ZS           aliases: IF_ZERO, IF_EQ
;;;     IF_ZC           aliases: IF_NOT_ZERO, IF_NE
;;;     IF_CC           aliases: IF_LT
;;;     IF_CS           aliases: IF_GE
;;;     IF_VC
;;;     IF_VS
;;;     IF_NC           aliases: IF_POS, IF_PLUS
;;;     IF_NS           aliases: IF_NEG, IF_MINUS
;;; ... and ditto for ELSE_IF_*
;;;
;;;     IF_A_EQ / ELSE_IF_A_EQ
;;;     IF_A_NE / ELSE_IF_A_NE
;;;     IF_A_LT / ELSE_IF_A_LT
;;;     IF_A_GE / ELSE_IF_A_GE
;;; ... and ditto for *_X_* and *_Y_*
;;;
;;;     IF_A_EQ_ONE_OF

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

.macro _IF_BOP_ branchOp
        __INC_IDENT__ __flow_branch_depth__
        __INC_IDENT__ __flow_branch_count_at_depth__
        __INC_IDENT__ __flow_branch_ident_counter__
        __FLOW_LOG__ "if"
        branchOp __flow_branch_ident_block__
.endmacro

.macro _IF_COP_BOP_ compareOp, branchOp, arg, reg
        __INC_IDENT__ __flow_branch_depth__
        __INC_IDENT__ __flow_branch_count_at_depth__
        __INC_IDENT__ __flow_branch_ident_counter__
        __FLOW_LOG__ "if"
    .ifblank reg
        compareOp arg
        branchOp __flow_branch_ident_block__
    .else
        compareOp arg,reg
        branchOp __flow_branch_ident_block__
    .endif
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

.macro _ELSE_IF_BOP_ branchOp
        __FLOW_LOG__ "else_if"
        jmp     __flow_branch_ident__ {"endif"}
        __flow_branch_ident_block__ := *
        __INC_IDENT__ __flow_branch_ident_counter__
        branchOp __flow_branch_ident_block__
.endmacro

.macro _ELSE_IF_COP_BOP_ compareOp, branchOp, arg, reg
        __FLOW_LOG__ "else_if"
        jmp     __flow_branch_ident__ {"endif"}
        __flow_branch_ident_block__ := *
        __INC_IDENT__ __flow_branch_ident_counter__
    .ifblank reg
        compareOp arg
        branchOp __flow_branch_ident_block__
    .else
        compareOp arg,reg
        branchOp __flow_branch_ident_block__
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
;;; DO / CONTINUE_IF_* / BREAK_IF_* / WHILE_* or REPEAT / UNTIL_*
;;; ============================================================

;;; Usage:
;;;     ldx #17
;;;     DO
;;;     ...
;;;     BREAK_IF_A_EQ #89
;;;     ...
;;;     CONTINUE_IF_VS
;;;     ...
;;;     dex
;;;     WHILE_POS
;;;
;;;     REPEAT
;;;     ...
;;;     BREAK_IF_Y_EQ #0
;;;     ...
;;;     UNTIL_A_EQ #'/'
;;;
;;; Macros:
;;;     DO                 aliases: REPEAT
;;;
;;;     WHILE_ZS           aliases: WHILE_EQ, WHILE_ZERO
;;;     WHILE_ZC           aliases: WHILE_NE, WHILE_NOT_ZERO
;;;     WHILE_CC           aliases: WHILE_LT
;;;     WHILE_CS           aliases: WHILE_GE
;;;     WHILE_VC
;;;     WHILE_VS
;;;     WHILE_NC           aliases: WHILE_POS, WHILE_PLUS
;;;     WHILE_NS           aliases: WHILE_NEG, WHILE_MINUS
;;; ... and ditto for UNTIL_*
;;;
;;;     WHILE_A_EQ
;;;     WHILE_A_NE
;;;     WHILE_A_LT
;;;     WHILE_A_GE
;;; ... and ditto for *_X_* and *_Y_*
;;; ... and ditto for UNTIL_*
;;;
;;;     CONTINUE_IF_ZS     aliases: CONTINUE_IF_EQ, CONTINUE_IF_ZERO
;;;     CONTINUE_IF_ZC     aliases: CONTINUE_IF_NE, CONTINUE_IF_NOT_ZERO
;;;     CONTINUE_IF_CC     aliases: CONTINUE_IF_LT
;;;     CONTINUE_IF_CS     aliases: CONTINUE_IF_GE
;;;     CONTINUE_IF_VC
;;;     CONTINUE_IF_VS
;;;     CONTINUE_IF_NC     aliases: CONTINUE_IF_POS, CONTINUE_IF_PLUS
;;;     CONTINUE_IF_NS     aliases: CONTINUE_IF_NEG, CONTINUE_IF_MINUS
;;;
;;;     CONTINUE_IF_A_EQ
;;;     CONTINUE_IF_A_NE
;;;     CONTINUE_IF_A_LT
;;;     CONTINUE_IF_A_GE
;;; ... and ditto for *_X_* and *_Y_*
;;;
;;;     BREAK_IF_ZS        aliases: BREAK_IF_EQ, BREAK_IF_ZERO
;;;     BREAK_IF_ZC        aliases: BREAK_IF_NE, BREAK_IF_NOT_ZERO
;;;     BREAK_IF_CC        aliases: BREAK_IF_LT
;;;     BREAK_IF_CS        aliases: BREAK_IF_GE
;;;     BREAK_IF_VC
;;;     BREAK_IF_VS
;;;     BREAK_IF_NC        aliases: BREAK_IF_POS, BREAK_IF_PLUS
;;;     BREAK_IF_NS        aliases: BREAK_IF_NEG, BREAK_IF_MINUS
;;;
;;;     BREAK_IF_A_EQ
;;;     BREAK_IF_A_NE
;;;     BREAK_IF_A_LT
;;;     BREAK_IF_A_GE
;;; ... and ditto for *_X_* and *_Y_*

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

.macro _CONTINUE_IF_BOP_ branchOp
        __FLOW_LOG__ "continue_if"
        branchOp __flow_loop_ident__ {"do_while"}
.endmacro

.macro _CONTINUE_IF_COP_BOP_ compareOp, branchOp, arg, reg
        __FLOW_LOG__ "continue_if"
      .ifblank reg
        compareOp arg
      .else
        compareOp arg,reg
      .endif
        branchOp __flow_loop_ident__ {"do_while"}
.endmacro

.macro _BREAK_IF_BOP_ branchOp
        __FLOW_LOG__ "break_if"
        branchOp __flow_loop_ident__ {"break"}
.endmacro

.macro _BREAK_IF_COP_BOP_ compareOp, branchOp, arg, reg
        __FLOW_LOG__ "break_if"
      .ifblank reg
        compareOp arg
      .else
        compareOp arg,reg
      .endif
        branchOp __flow_loop_ident__ {"break"}
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


;;; ============================================================
;;; RTS_IF_*
;;; ============================================================

;;; Macros:
;;;     RTS_IF_ZS           aliases: RTS_IF_EQ, RTS_IF_ZERO
;;;     RTS_IF_ZC           aliases: RTS_IF_NE, RTS_IF_NOT_ZERO
;;;     RTS_IF_CC           aliases: RTS_IF_LT
;;;     RTS_IF_CS           aliases: RTS_IF_GE
;;;     RTS_IF_VC
;;;     RTS_IF_VS
;;;     RTS_IF_NC           aliases: RTS_IF_POS, RTS_IF_PLUS
;;;     RTS_IF_NS           aliases: RTS_IF_NEG, RTS_IF_MINUS
;;;
;;;     RTS_IF_A_EQ
;;;     RTS_IF_A_NE
;;;     RTS_IF_A_LT
;;;     RTS_IF_A_GE
;;; ... and ditto for *_X_* and *_Y_*

.macro _RTS_IF_BOP_ branchOp
        .local  skip
        branchOp skip
        rts
skip:
.endmacro

.macro _RTS_IF_COP_BOP_ compareOp, branchOp, arg, reg
    .ifblank reg
        compareOp arg
    .else
        compareOp arg,reg
    .endif
        .local  skip
        branchOp skip
        rts
skip:
.endmacro


;;; ============================================================
;;; Produce the actual user-friendly macros
;;; ============================================================

.macro _FLOW_DEFINE_FLAG_MACROS_ cond, branchOp1, branchOp2
        .define .ident(.sprintf("IF_%s", .string(cond))) _IF_BOP_ branchOp2
        .define .ident(.sprintf("ELSE_IF_%s", .string(cond))) _ELSE_IF_BOP_ branchOp2
        .define .ident(.sprintf("WHILE_%s", .string(cond))) _WHILE_BOP_ branchOp1
        .define .ident(.sprintf("UNTIL_%s", .string(cond))) _WHILE_BOP_ branchOp2
        .define .ident(.sprintf("CONTINUE_IF_%s", .string(cond))) _CONTINUE_IF_BOP_ branchOp1
        .define .ident(.sprintf("BREAK_IF_%s", .string(cond))) _BREAK_IF_BOP_ branchOp1
        .define .ident(.sprintf("RTS_IF_%s", .string(cond))) _RTS_IF_BOP_ branchOp2
.endmacro
.macro _FLOW_DEFINE_COMPARE_MACROS_ reg, cond, compareOp, branchOp1, branchOp2
        .define .ident(.sprintf("IF_%s_%s", reg, .string(cond))) _IF_COP_BOP_ compareOp, branchOp2,
        .define .ident(.sprintf("ELSE_IF_%s_%s", reg, .string(cond))) _ELSE_IF_COP_BOP_ compareOp, branchOp2,
        .define .ident(.sprintf("WHILE_%s_%s", reg, .string(cond))) _WHILE_COP_BOP_ compareOp, branchOp1,
        .define .ident(.sprintf("UNTIL_%s_%s", reg, .string(cond))) _WHILE_COP_BOP_ compareOp, branchOp2,
        .define .ident(.sprintf("CONTINUE_IF_%s_%s", reg, .string(cond))) _CONTINUE_IF_COP_BOP_ compareOp, branchOp1,
        .define .ident(.sprintf("BREAK_IF_%s_%s", reg, .string(cond))) _BREAK_IF_COP_BOP_ compareOp, branchOp1,
        .define .ident(.sprintf("RTS_IF_%s_%s", reg, .string(cond))) _RTS_IF_COP_BOP_ compareOp, branchOp2,
.endmacro

_FLOW_DEFINE_FLAG_MACROS_ ZS, beq, bne
_FLOW_DEFINE_FLAG_MACROS_ ZC, bne, beq
_FLOW_DEFINE_FLAG_MACROS_ CS, bcs, bcc
_FLOW_DEFINE_FLAG_MACROS_ CC, bcc, bcs
_FLOW_DEFINE_FLAG_MACROS_ VS, bvs, bvc
_FLOW_DEFINE_FLAG_MACROS_ VC, bvc, bvs
_FLOW_DEFINE_FLAG_MACROS_ NS, bmi, bpl
_FLOW_DEFINE_FLAG_MACROS_ NC, bpl, bmi

_FLOW_DEFINE_FLAG_MACROS_ EQ,       beq, bne
_FLOW_DEFINE_FLAG_MACROS_ ZERO,     beq, bne
_FLOW_DEFINE_FLAG_MACROS_ NE,       bne, beq
_FLOW_DEFINE_FLAG_MACROS_ NOT_ZERO, bne, beq
_FLOW_DEFINE_FLAG_MACROS_ GE,       bcs, bcc
_FLOW_DEFINE_FLAG_MACROS_ LT,       bcc, bcs
_FLOW_DEFINE_FLAG_MACROS_ MINUS,    bmi, bpl
_FLOW_DEFINE_FLAG_MACROS_ NEG,      bmi, bpl
_FLOW_DEFINE_FLAG_MACROS_ PLUS,     bpl, bmi
_FLOW_DEFINE_FLAG_MACROS_ POS,      bpl, bmi

_FLOW_DEFINE_COMPARE_MACROS_ "A", EQ, cmp, beq, bne
_FLOW_DEFINE_COMPARE_MACROS_ "A", NE, cmp, bne, beq
_FLOW_DEFINE_COMPARE_MACROS_ "A", LT, cmp, bcc, bcs
_FLOW_DEFINE_COMPARE_MACROS_ "A", GE, cmp, bcs, bcc

_FLOW_DEFINE_COMPARE_MACROS_ "X", EQ, cpx, beq, bne
_FLOW_DEFINE_COMPARE_MACROS_ "X", NE, cpx, bne, beq
_FLOW_DEFINE_COMPARE_MACROS_ "X", LT, cpx, bcc, bcs
_FLOW_DEFINE_COMPARE_MACROS_ "X", GE, cpx, bcs, bcc

_FLOW_DEFINE_COMPARE_MACROS_ "Y", EQ, cpy, beq, bne
_FLOW_DEFINE_COMPARE_MACROS_ "Y", NE, cpy, bne, beq
_FLOW_DEFINE_COMPARE_MACROS_ "Y", LT, cpy, bcc, bcs
_FLOW_DEFINE_COMPARE_MACROS_ "Y", GE, cpy, bcs, bcc
