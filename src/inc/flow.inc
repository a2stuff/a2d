;;; ============================================================
;;; Flow Control
;;; ============================================================

;;; Macros that provide higher level flow control without resorting to
;;; throw-away labels.

;;; * IF_* / ELSE_IF_* / ELSE / END_IF
;;; * DO / BREAK_IF_* / WHILE_*
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

;;; A numeric variable for the current nesting depth of flow control
;;; structures. Incremented when entering a structure, decremented
;;; when leaving.
.define __flow_depth__ ::__depth__

;;; A numeric variable for the "Nth" flow control structure (if,
;;; do/while, etc) at depth D. Used to mint various identifiers unique
;;; to each, without using scopes. Incremented when entering a
;;; structure.
.define __flow_count_at_depth__ ::.ident(.sprintf("__flow_cad_%d__", __flow_depth__))

;;; Produce a unique identifier within this flow control structure.
;;; Usage: `__flow_ident__ {"else"}`
.define __flow_ident__(prefix) ::.ident(.sprintf("__flow_id_%s_%d_%d__", prefix, __flow_depth__, __flow_count_at_depth__))

;;; Produce unique identifierers for the end of each block
.define __flow_ident_counter__ __flow_ident__ {"counter"}
.define __flow_ident_block__ __flow_ident__ {.sprintf("eob%d", __flow_ident_counter__)}

;;; If debugging enabled, log a message with block details
.macro __FLOW_LOG__ msg
    .if __flow_debug__
        .out .sprintf("%s, depth: %d, bcad: %d", msg, __flow_depth__, __flow_count_at_depth__)
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

.macro _IF_BOP_ branchOp
        __INC_IDENT__ __flow_depth__
        __INC_IDENT__ __flow_count_at_depth__
        __INC_IDENT__ __flow_ident_counter__
        __FLOW_LOG__ "if"
        branchOp __flow_ident_block__
.endmacro

.macro _IF_COP_BOP_ compareOp, branchOp, arg, reg
        __INC_IDENT__ __flow_depth__
        __INC_IDENT__ __flow_count_at_depth__
        __INC_IDENT__ __flow_ident_counter__
        __FLOW_LOG__ "if"
    .ifblank reg
        compareOp arg
        branchOp __flow_ident_block__
    .else
        compareOp arg,reg
        branchOp __flow_ident_block__
    .endif
.endmacro

.macro _ELSE_IF_BOP_ branchOp
        __FLOW_LOG__ "else_if"
        jmp     __flow_ident__ {"endif"}
        __flow_ident_block__ := *
        __INC_IDENT__ __flow_ident_counter__
        branchOp __flow_ident_block__
.endmacro

.macro _ELSE_IF_COP_BOP_ compareOp, branchOp, arg, reg
        __FLOW_LOG__ "else_if"
        jmp     __flow_ident__ {"endif"}
        __flow_ident_block__ := *
        __INC_IDENT__ __flow_ident_counter__
    .ifblank reg
        compareOp arg
        branchOp __flow_ident_block__
    .else
        compareOp arg,reg
        branchOp __flow_ident_block__
    .endif
.endmacro

.macro ELSE
        __FLOW_LOG__ "else"
        jmp     __flow_ident__ {"endif"}
        __flow_ident_block__ := *
        __INC_IDENT__ __flow_ident_counter__
.endmacro

.macro END_IF
    .ifndef __flow_ident_block__
        __FLOW_LOG__ "no else"
        __flow_ident_block__ := *
    .endif

        __FLOW_LOG__ "endif"

        __flow_ident__ {"endif"} := *
        .refto __flow_ident__ {"endif"}

        __DEC_IDENT__ __flow_depth__
.endmacro

.macro ENDIF
        .error "Do you mean END_IF ?"
.endmacro

;;; --------------------------------------------------
;;; User-friendly IF/ELSE_IF macros

.define IF_ZS _IF_BOP_ bne
.define IF_ZC _IF_BOP_ beq
.define IF_CC _IF_BOP_ bcs
.define IF_CS _IF_BOP_ bcc
.define IF_NC _IF_BOP_ bmi
.define IF_NS _IF_BOP_ bpl
.define IF_VC _IF_BOP_ bvs
.define IF_VS _IF_BOP_ bvc

.define IF_ZERO     IF_ZS
.define IF_NOT_ZERO IF_ZC
.define IF_EQ       IF_ZS
.define IF_NE       IF_ZC
.define IF_GE       IF_CS
.define IF_LT       IF_CC
.define IF_PLUS     IF_NC
.define IF_MINUS    IF_NS
.define IF_POS      IF_NC
.define IF_NEG      IF_NS

.define IF_A_EQ _IF_COP_BOP_ cmp,bne,
.define IF_A_NE _IF_COP_BOP_ cmp,beq,
.define IF_A_LT _IF_COP_BOP_ cmp,bcs,
.define IF_A_GE _IF_COP_BOP_ cmp,bcc,

.define IF_X_EQ _IF_COP_BOP_ cpx,bne,
.define IF_X_NE _IF_COP_BOP_ cpx,beq,
.define IF_X_LT _IF_COP_BOP_ cpx,bcs,
.define IF_X_GE _IF_COP_BOP_ cpx,bcc,

.define IF_Y_EQ _IF_COP_BOP_ cpy,bne,
.define IF_Y_NE _IF_COP_BOP_ cpy,beq,
.define IF_Y_LT _IF_COP_BOP_ cpy,bcs,
.define IF_Y_GE _IF_COP_BOP_ cpy,bcc,

.define ELSE_IF_ZS _ELSE_IF_BOP_ bne
.define ELSE_IF_ZC _ELSE_IF_BOP_ beq
.define ELSE_IF_CC _ELSE_IF_BOP_ bcs
.define ELSE_IF_CS _ELSE_IF_BOP_ bcc
.define ELSE_IF_NC _ELSE_IF_BOP_ bmi
.define ELSE_IF_NS _ELSE_IF_BOP_ bpl
.define ELSE_IF_VC _ELSE_IF_BOP_ bvs
.define ELSE_IF_VS _ELSE_IF_BOP_ bvc

.define ELSE_IF_ZERO     ELSE_IF_ZS
.define ELSE_IF_NOT_ZERO ELSE_IF_ZC
.define ELSE_IF_EQ       ELSE_IF_ZS
.define ELSE_IF_NE       ELSE_IF_ZC
.define ELSE_IF_GE       ELSE_IF_CS
.define ELSE_IF_LT       ELSE_IF_CC
.define ELSE_IF_PLUS     ELSE_IF_NC
.define ELSE_IF_MINUS    ELSE_IF_NS
.define ELSE_IF_POS      ELSE_IF_NC
.define ELSE_IF_NEG      ELSE_IF_NS

.define ELSE_IF_A_EQ _ELSE_IF_COP_BOP cmp,bne,
.define ELSE_IF_A_NE _ELSE_IF_COP_BOP cmp,beq,
.define ELSE_IF_A_LT _ELSE_IF_COP_BOP cmp,bcs,
.define ELSE_IF_A_GE _ELSE_IF_COP_BOP cmp,bcc,

.define ELSE_IF_X_EQ _ELSE_IF_COP_BOP cpx,bne,
.define ELSE_IF_X_NE _ELSE_IF_COP_BOP cpx,beq,
.define ELSE_IF_X_LT _ELSE_IF_COP_BOP cpx,bcs,
.define ELSE_IF_X_GE _ELSE_IF_COP_BOP cpx,bcc,

.define ELSE_IF_Y_EQ _ELSE_IF_COP_BOP cpy,bne,
.define ELSE_IF_Y_NE _ELSE_IF_COP_BOP cpy,beq,
.define ELSE_IF_Y_LT _ELSE_IF_COP_BOP cpy,bcs,
.define ELSE_IF_Y_GE _ELSE_IF_COP_BOP cpy,bcc,

;;; ============================================================
;;; DO / BREAK_IF_* / WHILE_*
;;; ============================================================

;;; Usage:
;;;     ldx #17
;;;     DO
;;;     ...
;;;     BREAK_IF_A_EQ #89
;;;     ...
;;;     BREAK_IF_VS
;;;     ...
;;;     dex
;;;     WHILE_POS
;;;
;;;     DO
;;;     ...
;;;     WHILE_A_NE #'/'
;;;
;;; Macros:
;;;     WHILE_ZS           aliases: WHILE_EQ, WHILE_ZERO
;;;     WHILE_ZC           aliases: WHILE_NE, WHILE_NOT_ZERO
;;;     WHILE_CC           aliases: WHILE_LT
;;;     WHILE_CS           aliases: WHILE_GE
;;;     WHILE_VC
;;;     WHILE_VS
;;;     WHILE_NC           aliases: WHILE_POS, WHILE_PLUS
;;;     WHILE_NS           aliases: WHILE_NEG, WHILE_MINUS
;;;
;;;     WHILE_A_EQ
;;;     WHILE_A_NE
;;;     WHILE_A_LT
;;;     WHILE_A_GE
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

.macro DO
        __INC_IDENT__ __flow_depth__
        __INC_IDENT__ __flow_count_at_depth__

        __FLOW_LOG__ "do"
        __flow_ident__ {"do_while"} := *
.endmacro

.macro _BREAK_IF_BOP_ branchOp
        __FLOW_LOG__ "else_if"
        branchOp __flow_ident__ {"break"}
.endmacro

.macro _BREAK_IF_COP_BOP_ compareOp, branchOp, arg, reg
        __FLOW_LOG__ "else_if"
      .ifblank reg
        compareOp arg
      .else
        compareOp arg,reg
      .endif
        branchOp __flow_ident__ {"break"}
.endmacro

.macro _WHILE_BOP_ branchOp
        __FLOW_LOG__ "while"
        branchOp __flow_ident__ {"do_while"}

        __flow_ident__ {"break"} := *
        .refto __flow_ident__ {"break"}

        __DEC_IDENT__ __flow_depth__
.endmacro

.macro _WHILE_COP_BOP_ compareOp, branchOp, arg, reg
        __FLOW_LOG__ "while"
      .ifblank reg
        compareOp arg
      .else
        compareOp arg,reg
      .endif
        branchOp __flow_ident__ {"do_while"}

        __flow_ident__ {"break"} := *
        .refto __flow_ident__ {"break"}

        __DEC_IDENT__ __flow_depth__
.endmacro

.define WHILE_ZC _WHILE_BOP_ bne
.define WHILE_ZS _WHILE_BOP_ beq
.define WHILE_CC _WHILE_BOP_ bcc
.define WHILE_CS _WHILE_BOP_ bcs
.define WHILE_VC _WHILE_BOP_ bvc
.define WHILE_VS _WHILE_BOP_ bvs
.define WHILE_NC _WHILE_BOP_ bpl
.define WHILE_NS _WHILE_BOP_ bmi

.define WHILE_EQ WHILE_ZS
.define WHILE_NE WHILE_ZC
.define WHILE_ZERO WHILE_EQ
.define WHILE_NOT_ZERO WHILE_NE
.define WHILE_GE WHILE_CS
.define WHILE_LT WHILE_CC
.define WHILE_PLUS WHILE_NC
.define WHILE_MINUS WHILE_NS
.define WHILE_POS WHILE_NC
.define WHILE_NEG WHILE_NS

.define WHILE_A_EQ _WHILE_COP_BOP_ cmp,beq,
.define WHILE_A_NE _WHILE_COP_BOP_ cmp,bne,
.define WHILE_A_LT _WHILE_COP_BOP_ cmp,bcc,
.define WHILE_A_GE _WHILE_COP_BOP_ cmp,bcs,

.define WHILE_X_EQ _WHILE_COP_BOP_ cpx,beq,
.define WHILE_X_NE _WHILE_COP_BOP_ cpx,bne,
.define WHILE_X_LT _WHILE_COP_BOP_ cpx,bcc,
.define WHILE_X_GE _WHILE_COP_BOP_ cpx,bcs,

.define WHILE_Y_EQ _WHILE_COP_BOP_ cpy,beq,
.define WHILE_Y_NE _WHILE_COP_BOP_ cpy,bne,
.define WHILE_Y_LT _WHILE_COP_BOP_ cpy,bcc,
.define WHILE_Y_GE _WHILE_COP_BOP_ cpy,bcs,

.define BREAK_IF_ZS _BREAK_IF_BOP_ beq
.define BREAK_IF_ZC _BREAK_IF_BOP_ bne
.define BREAK_IF_CS _BREAK_IF_BOP_ bcs
.define BREAK_IF_CC _BREAK_IF_BOP_ bcc
.define BREAK_IF_VS _BREAK_IF_BOP_ bvs
.define BREAK_IF_VC _BREAK_IF_BOP_ bvc
.define BREAK_IF_NS _BREAK_IF_BOP_ bmi
.define BREAK_IF_NC _BREAK_IF_BOP_ bpl

.define BREAK_IF_EQ BREAK_IF_ZS
.define BREAK_IF_NE BREAK_IF_ZC
.define BREAK_IF_ZERO BREAK_IF_EQ
.define BREAK_IF_NOT_ZERO BREAK_IF_NE
.define BREAK_IF_GE BREAK_IF_CS
.define BREAK_IF_LT BREAK_IF_CC
.define BREAK_IF_PLUS BREAK_IF_NC
.define BREAK_IF_MINUS BREAK_IF_NS
.define BREAK_IF_POS BREAK_IF_NC
.define BREAK_IF_NEG BREAK_IF_NS

.define BREAK_IF_A_EQ _BREAK_IF_COP_BOP_ cmp,beq,
.define BREAK_IF_A_NE _BREAK_IF_COP_BOP_ cmp,bne,
.define BREAK_IF_A_LT _BREAK_IF_COP_BOP_ cmp,bcc,
.define BREAK_IF_A_GE _BREAK_IF_COP_BOP_ cmp,bcs,

.define BREAK_IF_X_EQ _BREAK_IF_COP_BOP_ cpx,beq,
.define BREAK_IF_X_NE _BREAK_IF_COP_BOP_ cpx,bne,
.define BREAK_IF_X_LT _BREAK_IF_COP_BOP_ cpx,bcc,
.define BREAK_IF_X_GE _BREAK_IF_COP_BOP_ cpx,bcs,

.define BREAK_IF_Y_EQ _BREAK_IF_COP_BOP_ cpy,beq,
.define BREAK_IF_Y_NE _BREAK_IF_COP_BOP_ cpy,bne,
.define BREAK_IF_Y_LT _BREAK_IF_COP_BOP_ cpy,bcc,
.define BREAK_IF_Y_GE _BREAK_IF_COP_BOP_ cpy,bcs,


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

.macro _RTS_IF_BOP_ bop
        .local  skip
        bop     skip
        rts
skip:
.endmacro

.define RTS_IF_ZS _RTS_IF_BOP_ bne
.define RTS_IF_ZC _RTS_IF_BOP_ beq
.define RTS_IF_CS _RTS_IF_BOP_ bcc
.define RTS_IF_CC _RTS_IF_BOP_ bcs
.define RTS_IF_VS _RTS_IF_BOP_ bvc
.define RTS_IF_VC _RTS_IF_BOP_ bvs
.define RTS_IF_NS _RTS_IF_BOP_ bpl
.define RTS_IF_NC _RTS_IF_BOP_ bmi

.define RTS_IF_EQ RTS_IF_ZS
.define RTS_IF_NE RTS_IF_ZC
.define RTS_IF_ZERO RTS_IF_EQ
.define RTS_IF_NOT_ZERO RTS_IF_NE
.define RTS_IF_GE RTS_IF_CS
.define RTS_IF_LT RTS_IF_CC
.define RTS_IF_PLUS RTS_IF_NC
.define RTS_IF_MINUS RTS_IF_NS
.define RTS_IF_POS RTS_IF_NC
.define RTS_IF_NEG RTS_IF_NS

