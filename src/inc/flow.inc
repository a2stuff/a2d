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
;;; * DO / REDO_IF cond / CONTINUE_IF cond / BREAK_IF cond / WHILE cond
;;;   * or REPEAT / UNTIL cond if you prefer
;;;   * DO / FOREVER (or REPEAT / FOREVER) for unconditional JMP
;;; * RTS_IF cond
;;;
;;; Conditions take the form of flag tests or register comparisons.
;;;
;;; Flag tests: ZS ZC CS CC VS VC NS NC
;;; (Aliases: EQ, NE, ZERO, NOT_ZERO, LT, GE, POS, NEG, PLUS, MINUS)
;;;
;;; Register comparisons: <register> <operator> <argument>
;;; e.g. "IF A = #25"
;;; Operators: =, <>, <, >=
;;;
;;; Also: IN, BETWEEN (and NOT_IN, NOT_BETWEEN)
;;; e.g. "IF A IN #1, #2, #3"
;;; e.g. "IF A BETWEEN #'A', #'Z'"
;;;
;;; Conditions can be prepended with NOT to invert meaning.
;;; e.g. "IF NOT A = #25"
;;;
;;; Conditions can be joined with AND and OR.
;;; e.g. "IF CS AND A = #25"
;;; e.g. "IF A = #1 OR X = #2"
;;;
;;; ("NOT" has highest precedence, then "AND", then "OR")
;;;
;;; Conditions can optionally be preceded by one or more statements
;;; that start with BIT, LDA, LDX, LDY, INC, INX, INY, DEC, DEX, or
;;; DEY (upper or lowercase), terminated by a ':'.
;;; e.g. "IF BIT flag : NS"
;;; e.g. "WHILE INX : X < #10"
;;; e.g. "WHILE DEX : DEX : POS"

;;; ============================================================
;;; Infrastructure
;;; ============================================================

;;; Set context
.macro _FLOW_STATEMENT name
    .define __flow_statement__ name
    __FLOW_LOG__ name
.endmacro

.macro _FLOW_END_STATEMENT
  .undef __flow_statement__
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
;;; Expression Parsing and Code Generation
;;; ============================================================
;;;
;;; Condition Grammar:
;;;
;;;   cond  = bexpr ( ( "AND" | "OR" ) bexpr )*
;;;   bexpr = "NOT" bexpr | comp | test
;;;   comp  = reg binop rhs | reg "BETWEEN" lo "," hi | reg "IN" arg ( "," arg )*
;;;   reg   = "A" | "X" | "Y"
;;;   binop = "=" | "<>" | "<" | ">="
;;;   rhs   = /* any non-zero sequence of tokens excluding "AND" and "OR" */
;;;   test  = "CC" | "CS" | "NC" | "NS" | "VC" | "VS" | "ZC" | "ZS"

;;; '@' is used for numeric variables so they do not interfere with
;;; cheap local labels in user code.

;;; NB: 'F2' is used as a prefix here as this represents the second
;;; from-scratch implementation, to handle AND/OR

::F2_SENSE_BIT = 0            ; "branch if true"  (like WHILE)
::F2_SENSE_BIF = 1            ; "branch if false" (like IF, UNTIL)

;;; --------------------------------------------------
;;; Logging
;;; --------------------------------------------------

.macro F2_LOG_CODEGEN_BRANCH bop, target
        ;;.out .sprintf("] emitting %s to %s", .string(bop), target)
.endmacro
.macro F2_LOG_CODEGEN_COMPARE cop, args
        ;;.out .sprintf("] emitting %s (args %d tokens)", .string(cop), .tcount({args}))
.endmacro
.macro F2_LOG_SAW str
        ;;.out .sprintf("> saw %s", str)
.endmacro
.macro F2_LOG_PEEKED str
        ;;.out .sprintf("> peeked %s", str)
.endmacro
.macro F2_LOG_FUNC name
        ;;.out .sprintf("( %s", name)
.endmacro
.macro F2_LOG_END_FUNC name
        ;;.out .sprintf(") %s", name)
.endmacro
.macro F2_LOG_TCOUNT
        ;;.out .sprintf("  token list size = %d", .tcount({f2_token_list}))
.endmacro

;;; --------------------------------------------------
;;; Error Reporting
;;; --------------------------------------------------

.macro F2_ERR message
        .error .sprintf("%s: %s", __flow_statement__, message)
        .fatal "Terminating parse after error"
        .exitmacro
.endmacro

.macro F2_ERR_UNREACHED
        F2_ERR "Unreachable code reached"
.endmacro

.macro F2_ERR_UNEXPECTED_TOKEN
        .define f2_tok .left(1, {f2_token_list})

        .if .match({f2_tok}, A)
          F2_ERR "Unexpected token: 'A'"
        .elseif .match({f2_tok}, X)
          F2_ERR "Unexpected token: 'X'"
        .elseif .match({f2_tok}, Y)
          F2_ERR "Unexpected token: 'Y'"
        .elseif .match({f2_tok}, {,})
          F2_ERR "Unexpected token: ','"
        .elseif .match({f2_tok}, some_ident)
          F2_ERR .sprintf("Unexpected token: identifier ('%s')", .string(f2_tok))
        .elseif .match({f2_tok}, 1234)
          F2_ERR .sprintf("Unexpected token: number (%d)", f2_tok)
        .else
          F2_ERR "Unexpected token"
        .endif

        .undef f2_tok
.endmacro

.macro F2_ERR_EXPECTED what
        .if .tcount({f2_token_list}) = 0
          F2_ERR .sprintf("Expected %s", what)
        .endif

        .define f2_tok .left(1, {f2_token_list})

        .if .match({f2_tok}, A)
          F2_ERR "Unexpected token: 'A'"
        .elseif .match({f2_tok}, X)
          F2_ERR "Unexpected token: 'X'"
        .elseif .match({f2_tok}, Y)
          F2_ERR "Unexpected token: 'Y'"
        .elseif .match({f2_tok}, {,})
          F2_ERR "Unexpected token: ','"
        .elseif .match({f2_tok}, some_ident)
          F2_ERR .sprintf("Expected %s, saw identifier ('%s')", what, .string(f2_tok))
        .elseif .match({f2_tok}, 1234)
          F2_ERR .sprintf("Expected %s, saw number (%d)", what, f2_tok)
        .else
          F2_ERR .sprintf("Expected %s", what)
        .endif

        .undef f2_tok
.endmacro

;;; --------------------------------------------------
;;; Code Generation
;;; --------------------------------------------------

;;; ----------------------------------------
;;; Low Level
;;; ----------------------------------------

;;; Emit a branch (`bop`) to a target (`target`); `kind` provides a name to log (e.g. "stay")
.macro F2_CODEGEN_BRANCH bop, target, kind
        F2_LOG_FUNC "CODEGEN_BRANCH"
        F2_LOG_CODEGEN_BRANCH bop, kind

        .if .def(target) .and .const((*-2)-(target)) .and ((*+2)-(target)>127)

         .if .xmatch(bop, BCC)
           BCS *+5
         .elseif .xmatch(bop, BCS)
           BCC *+5
         .elseif .xmatch(bop, BVC)
           BVS *+5
         .elseif .xmatch(bop, BVCS)
           BVC *+5
         .elseif .xmatch(bop, BPL)
           BMI *+5
         .elseif .xmatch(bop, BMI)
           BPL *+5
         .elseif .xmatch(bop, BEQ)
           BNE *+5
         .elseif .xmatch(bop, BNE)
           BEQ *+5
         .else
           F2_ERR_UNREACHED
         .endif
         JMP target

        .else

          bop target

        .endif
.endmacro

;;;Emit a comparison
.macro F2_CODEGEN_COMPARE cop, args
        F2_LOG_FUNC "CODEGEN_COMPARE"
        F2_LOG_CODEGEN_COMPARE cop, {args}

        cop args
.endmacro
.macro F2_VALIDATE_COMPARE_RHS op_str,arg1,arg2,arg3
        .if .paramcount > 3
            F2_ERR .sprintf("Unexpected arguments after comparison '%s'", op_str)
        .endif
        .ifnblank arg2
        .if .not(.xmatch({arg2},X) .or .xmatch({arg2},Y))
        F2_ERR .sprintf("Unexpected non-index-register after comparison '%s'", op_str)
        .endif
        .endif
.endmacro


;;; ----------------------------------------
;;; Comparison Ops (e.g. binary ops, flags)
;;; ----------------------------------------

;;; if expr followed by an OR
;;; > if BIF then BIT `stay`
;;; > if BIT then BIT `branch`
;;; if expr followed by an AND
;;; > if BIF then BIF `branch`
;;; > if BIT then BIF `stay`
;;; otherwise
;;; > if BIF then BIF `branch`
;;; > if BIT then BIT `branch`

;;; Given two a pair of branch ops (e.g. BCC, BCS), emit a branch depending on `@f2_sense_flag` and `@f2_negate_flag`
.macro F2_CODEGEN_BRANCH_WITH_FLAGS bop1, bop2
        F2_LOG_FUNC "CODEGEN_BRANCH_WITH_FLAGS"
        .if @f2_negate_flag
          F2_CODEGEN_BRANCH_WITH_FLAGS2 bop2, bop1
        .else
          F2_CODEGEN_BRANCH_WITH_FLAGS2 bop1, bop2
        .endif
.endmacro
.macro F2_CODEGEN_BRANCH_WITH_FLAGS2 bop1, bop2
        F2_LOG_FUNC "CODEGEN_BRANCH_WITH_FLAGS2"
        F2_LOG_TCOUNT

        ;; Look at negate flag, sense flag, and next token (and, or, none), generate code
        .if .tcount({f2_token_list}) = 0
          F2_LOG_PEEKED "EOF"
          .if @f2_sense_flag
            F2_CODEGEN_BRANCH bop2, f2_branch_target, "branch_target"
          .else
            F2_CODEGEN_BRANCH bop1, f2_branch_target, "branch_target"
          .endif
        .elseif .xmatch(.left(1, {f2_token_list}), OR)
          F2_LOG_PEEKED "OR"
          .if @f2_sense_flag
            F2_CODEGEN_BRANCH bop1, f2_stay_target, "stay_target"
          .else
            F2_CODEGEN_BRANCH bop1, f2_branch_target, "branch_target"
          .endif
        .elseif .xmatch(.left(1, {f2_token_list}), AND)
          F2_LOG_PEEKED "AND"
          .if @f2_sense_flag
            F2_CODEGEN_BRANCH bop2, f2_branch_target, "branch_target"
          .else
            F2_CODEGEN_BRANCH bop2, f2_stay_target, "stay_target"
          .endif
        .else
          F2_ERR_UNEXPECTED_TOKEN
        .endif
        F2_LOG_END_FUNC "CODEGEN_BRANCH_WITH_FLAGS2"
.endmacro

;;; ----------------------------------------
;;; "IN" operator
;;; ----------------------------------------

.macro F2_CODEGEN_IN_LIST cop, list
        F2_LOG_FUNC "CODEGEN_IN_LIST"
        .local @skip

        ;; TODO: Look for symmetries to exploit to simplify this

        .if .not(@f2_negate_flag)
          .if .tcount({f2_token_list}) = 0
            F2_LOG_PEEKED "EOF"
            .if @f2_sense_flag
              ;; e.g. IF A IN #1, #2, #3
              F2_CODEGEN_IN_LIST2 cop, BEQ, @skip, "skip", BNE, f2_branch_target, "branch_target", list
            .else
              ;; e.g. WHILE A IN #1, #2, #3
              F2_CODEGEN_IN_LIST2 cop, BEQ, f2_branch_target, "branch_target", BEQ, f2_branch_target, "branch_target", list
            .endif
          .elseif .xmatch(.left(1, {f2_token_list}), AND)
            F2_LOG_PEEKED "AND"
            .if @f2_sense_flag
              ;; e.g. IF A IN #1, #2, #3 AND CS
              F2_CODEGEN_IN_LIST2 cop, BEQ, @skip, "skip", BNE, f2_branch_target, "branch_target", list
            .else
              ;; e.g. WHILE A IN #1, #2, #3 AND CS
              F2_CODEGEN_IN_LIST2 cop, BEQ, @skip, "skip", BNE, f2_stay_target, "stay_target", list
            .endif
          .elseif .xmatch(.left(1, {f2_token_list}), OR)
            F2_LOG_PEEKED "OR"
            .if @f2_sense_flag
              ;; e.g. IF A IN #1, #2, #3 OR CS
              F2_CODEGEN_IN_LIST2 cop, BEQ, f2_stay_target, "stay_target", BEQ, f2_stay_target, "stay_target", list
            .else
              ;; e.g. WHILE A IN #1, #2, #3 OR CS
              F2_CODEGEN_IN_LIST2 cop, BEQ, f2_branch_target, "branch_target", BEQ, f2_branch_target, "branch_target", list
            .endif
          .else
            F2_ERR_UNEXPECTED_TOKEN
          .endif
        .else
          .if .tcount({f2_token_list}) = 0
            F2_LOG_PEEKED "EOF"
            .if @f2_sense_flag
              ;; e.g. IF NOT A IN #1, #2, #3
              F2_CODEGEN_IN_LIST2 cop, BEQ, f2_branch_target, "branch_target", BEQ, f2_branch_target, "branch_target", list
            .else
              ;; e.g. WHILE NOT A IN #1, #2, #3
              F2_CODEGEN_IN_LIST2 cop, BEQ, f2_stay_target, "stay_target", BNE, f2_branch_target, "branch_target", list
            .endif
          .elseif .xmatch(.left(1, {f2_token_list}), AND)
            F2_LOG_PEEKED "AND"
            .if @f2_sense_flag
              ;; e.g. IF NOT A IN #1, #2, #3 AND CS
              F2_CODEGEN_IN_LIST2 cop, BEQ, f2_branch_target, "branch_target", BEQ, f2_branch_target, "branch_target", list
            .else
              ;; e.g. WHILE NOT A IN #1, #2, #3 AND CS
              F2_CODEGEN_IN_LIST2 cop, BEQ, f2_stay_target, "stay_target", BEQ, f2_stay_target, "stay_target", list
            .endif
          .elseif .xmatch(.left(1, {f2_token_list}), OR)
            F2_LOG_PEEKED "OR"
            .if @f2_sense_flag
              ;; e.g. IF NOT A IN #1, #2, #3 OR CS
              F2_CODEGEN_IN_LIST2 cop, BEQ, @skip, "skip", BNE, f2_stay_target, "stay_target", list
            .else
              ;; e.g. WHILE NOT A IN #1, #2, #3 OR CS
              F2_CODEGEN_IN_LIST2 cop, BEQ, @skip, "skip", BNE, f2_branch_target, "branch_target", list
            .endif
          .endif
        .endif

        @skip := *
        F2_LOG_END_FUNC "CODEGEN_IN_LIST"
.endmacro
.macro F2_CODEGEN_IN_LIST2 cop, bop1, target1, target1_name, bop2, target2, target2_name, p1, p2, p3, p4, p5, p6, p7, p8, p9
        F2_LOG_FUNC "CODEGEN_IN_LIST2"
        .ifnblank p2
          F2_CODEGEN_COMPARE cop, p1
          F2_CODEGEN_BRANCH bop1, target1, target1_name
          F2_CODEGEN_IN_LIST2 cop, bop1, target1, target1_name, bop2, target2, target2_name, p2, p3, p4, p5, p6, p7, p8, p9
        .else
          F2_CODEGEN_COMPARE cop, p1
          F2_CODEGEN_BRANCH bop2, target2, target2_name
        .endif
        F2_LOG_END_FUNC "CODEGEN_IN_LIST2"
.endmacro

;;; ----------------------------------------
;;; "BETWEEN" operator
;;; ----------------------------------------

.macro F2_CODEGEN_BETWEEN cop, lo, hi, op_str
        F2_LOG_FUNC "F2_CODEGEN_BETWEEN"
        .local @skip

        .if .not(.xmatch(.left(1, {lo}), {#}))
          F2_ERR .sprintf("Expected immediate 1st argument for '%s'", op_str)
        .elseif .not(.xmatch(.left(1, {hi}), {#}))
          F2_ERR .sprintf("Expected immediate 2nd argument for '%s'", op_str)
        .endif

        ;; TODO: Look for symmetries to exploit to simplify this

        .if .not(@f2_negate_flag)
          .if .tcount({f2_token_list}) = 0
            F2_LOG_PEEKED "EOF"
            .if @f2_sense_flag
              ;; e.g. IF A BETWEEN #1, #9
              F2_CODEGEN_COMPARE cop, {lo}
              F2_CODEGEN_BRANCH BCC, f2_branch_target, "branch_target"
              F2_CODEGEN_COMPARE cop, {hi+1}
              F2_CODEGEN_BRANCH BCS, f2_branch_target, "branch_target"
            .else
              ;; e.g. WHILE A BETWEEN #1, #9
              F2_CODEGEN_COMPARE cop, {lo}
              F2_CODEGEN_BRANCH BCC, f2_stay_target, "stay_target"
              F2_CODEGEN_COMPARE cop, {hi+1}
              F2_CODEGEN_BRANCH BCC, f2_branch_target, "branch_target"
            .endif
          .elseif .xmatch(.left(1, {f2_token_list}), AND)
            F2_LOG_PEEKED "AND"
            .if @f2_sense_flag
              ;; e.g. IF A BETWEEN #1, #9 AND CS
              F2_CODEGEN_COMPARE cop, {lo}
              F2_CODEGEN_BRANCH BCC, f2_branch_target, "branch_target"
              F2_CODEGEN_COMPARE cop, {hi+1}
              F2_CODEGEN_BRANCH BCS, f2_branch_target, "branch_target"
            .else
              ;; e.g. WHILE A BETWEEN #1, #9 AND CS
              F2_CODEGEN_COMPARE cop, {lo}
              F2_CODEGEN_BRANCH BCC, f2_stay_target, "stay_target"
              F2_CODEGEN_COMPARE cop, {hi+1}
              F2_CODEGEN_BRANCH BCC, f2_branch_target, "branch_target"
            .endif
          .elseif .xmatch(.left(1, {f2_token_list}), OR)
            F2_LOG_PEEKED "OR"
            .if @f2_sense_flag
              ;; e.g. IF A BETWEEN #1, #9 OR CS
              F2_CODEGEN_COMPARE cop, {lo}
              F2_CODEGEN_BRANCH BCC, @skip, "skip"
              F2_CODEGEN_COMPARE cop, {hi+1}
              F2_CODEGEN_BRANCH BCC, f2_stay_target, "stay_target"
            .else
              ;; e.g. WHILE A BETWEEN #1, #9 OR CS
              F2_CODEGEN_COMPARE cop, {lo}
              F2_CODEGEN_BRANCH BCC, @skip, "skip"
              F2_CODEGEN_COMPARE cop, {hi+1}
              F2_CODEGEN_BRANCH BCC, f2_branch_target, "branch_target"
            .endif
          .else
            F2_ERR_UNEXPECTED_TOKEN
          .endif
        .else
          .if .tcount({f2_token_list}) = 0
            F2_LOG_PEEKED "EOF"
            .if @f2_sense_flag
              ;; e.g. IF NOT A BETWEEN #1, #9
              F2_CODEGEN_COMPARE cop, {lo}
              F2_CODEGEN_BRANCH BCC, f2_stay_target, "stay_target"
              F2_CODEGEN_COMPARE cop, {hi+1}
              F2_CODEGEN_BRANCH BCC, f2_branch_target, "branch_target"
            .else
              ;; e.g. WHILE NOT A BETWEEN #1, #9
              F2_CODEGEN_COMPARE cop, {lo}
              F2_CODEGEN_BRANCH BCC, f2_branch_target, "branch_target"
              F2_CODEGEN_COMPARE cop, {hi+1}
              F2_CODEGEN_BRANCH BCS, f2_branch_target, "branch_target"
            .endif
          .elseif .xmatch(.left(1, {f2_token_list}), AND)
            F2_LOG_PEEKED "AND"
            .if @f2_sense_flag
              ;; e.g. IF NOT A BETWEEN #1, #9 AND CS
              F2_CODEGEN_COMPARE cop, {lo}
              F2_CODEGEN_BRANCH BCC, @skip, "skip"
              F2_CODEGEN_COMPARE cop, {hi+1}
              F2_CODEGEN_BRANCH BCC, f2_branch_target, "branch_target"
            .else
              ;; e.g. WHILE NOT A BETWEEN #1, #9 AND CS
              F2_CODEGEN_COMPARE cop, {lo}
              F2_CODEGEN_BRANCH BCC, @skip, "skip"
              F2_CODEGEN_COMPARE cop, {hi+1}
              F2_CODEGEN_BRANCH BCC, f2_stay_target, "stay_target"
            .endif
          .elseif .xmatch(.left(1, {f2_token_list}), OR)
            F2_LOG_PEEKED "OR"
            .if @f2_sense_flag
              ;; e.g. IF NOT A BETWEEN #1, #9 OR CS
              F2_CODEGEN_COMPARE cop, {lo}
              F2_CODEGEN_BRANCH BCC, f2_stay_target, "stay_target"
              F2_CODEGEN_COMPARE cop, {hi+1}
              F2_CODEGEN_BRANCH BCC, f2_branch_target, "branch_target"
            .else
              ;; e.g. WHILE NOT A BETWEEN #1, #9 OR CS
              F2_CODEGEN_COMPARE cop, {lo}
              F2_CODEGEN_BRANCH BCC, f2_branch_target, "branch_target"
              F2_CODEGEN_COMPARE cop, {hi+1}
              F2_CODEGEN_BRANCH BCS, f2_branch_target, "branch_target"
            .endif
          .endif
        .endif

        @skip := *
        F2_LOG_END_FUNC "F2_CODEGEN_BETWEEN"
.endmacro

;;; --------------------------------------------------
;;; Parsing
;;; --------------------------------------------------

;;; Consume a single token from `f2_token_list`
.macro F2_PARSE_CONSUME
        F2_LOG_FUNC "PARSE_CONSUME"
        .define f2_tmp .mid(1, 9999, {f2_token_list})
        .undef f2_token_list
        .define f2_token_list f2_tmp
        .undef f2_tmp
        F2_LOG_END_FUNC "PARSE_CONSUME"
.endmacro

;;; Parse `f2_token_list` up to an "AND" or an "OR"; defines `f2_rhs` (caller must .undef it)
.macro F2_PARSE_RHS
        F2_LOG_FUNC "PARSE_RHS"
        .define f2_rhs .left(1, {f2_token_list})
        F2_PARSE_CONSUME
        F2_PARSE_RHS2
        F2_LOG_END_FUNC "PARSE_RHS"
.endmacro
.macro F2_PARSE_RHS2
        F2_LOG_FUNC "PARSE_RHS2"
        .if .tcount({f2_token_list}) > 0
          .if .not(.xmatch(.left(1, {f2_token_list}), AND) .or .xmatch(.left(1, {f2_token_list}), OR))
            .define f2_tmp f2_rhs
            .undef f2_rhs
            .define f2_rhs f2_tmp .left(1, {f2_token_list})
            .undef f2_tmp
            F2_PARSE_CONSUME
            F2_PARSE_RHS2
          .endif
        .endif
        F2_LOG_END_FUNC "PARSE_RHS2"
.endmacro

;;; Parse `f2_rhs` up to a ","; defines `f2_first` and `f2_second` (caller must .undef them)
.macro F2_PARSE_PAIR op_str, param1,param2,p3,p4,p5,p6,p7,p8,p9
        F2_LOG_FUNC "PARSE_PAIR"
        .if .paramcount <> 3
          F2_ERR_EXPECTED .sprintf("two arguments for '%s'", op_str)
        .endif
        .define f2_first param1
        .define f2_second param2
        F2_LOG_END_FUNC "PARSE_PAIR"
.endmacro

;;; Parse a relational expression / binary operation (e.g. `A = #7`)
.macro F2_PARSE_COMP
        F2_LOG_FUNC "PARSE_COMP"
        F2_LOG_TCOUNT

        .define f2_lhs .left(1, {f2_token_list})
        .if .xmatch(f2_lhs, A)
          F2_LOG_SAW "A"
        .elseif .xmatch(f2_lhs, X)
          F2_LOG_SAW "X"
        .elseif .xmatch(f2_lhs, Y)
          F2_LOG_SAW "Y"
        .else
          F2_ERR_EXPECTED "register (A,X,Y)"
        .endif
        F2_PARSE_CONSUME

        .if .tcount({f2_token_list}) = 0
          F2_ERR_EXPECTED "operator (=, <>, <, >=, IN, BETWEEN)"
        .endif
        .define f2_op .left(1, {f2_token_list})
        .if .xmatch(f2_op, =)
          .define f2_op_str "="
        .elseif .xmatch(f2_op, <>)
          .define f2_op_str "<>"
        .elseif .xmatch(f2_op, <)
          .define f2_op_str "<"
        .elseif .xmatch(f2_op, >=)
          .define f2_op_str ">="
        .elseif .xmatch(f2_op, IN)
          .define f2_op_str "IN"
        .elseif .xmatch(f2_op, NOT_IN)
          .define f2_op_str "NOT_IN"
        .elseif .xmatch(f2_op, BETWEEN)
          .define f2_op_str "BETWEEN"
        .elseif .xmatch(f2_op, NOT_BETWEEN)
          .define f2_op_str "NOT_BETWEEN"
        .elseif .xmatch(f2_op, >)
          F2_ERR "Greater-than operator ('>') not supported"
        .elseif .xmatch(f2_op, <=)
          F2_ERR "Less-than-or-equal operator ('<=') not supported"
        .else
          F2_ERR_EXPECTED "operator (=, <>, <, >=, IN, BETWEEN)"
        .endif
         F2_LOG_SAW f2_op_str
        F2_PARSE_CONSUME

        .if .tcount({f2_token_list}) = 0
          F2_ERR_EXPECTED .sprintf("argument(s) after '%s'", f2_op_str)
        .endif
        F2_PARSE_RHS
        F2_LOG_SAW .sprintf("RHS (%d tokens)", .tcount({f2_rhs}))

        .if .match({f2_rhs}, 1234)
          F2_ERR .sprintf("Numeric literal in '%s' comparison; did you mean '#%d'?", f2_op_str, f2_rhs)
        .endif

        .if .xmatch(f2_op, IN)
          .if .xmatch(f2_lhs, A)
            F2_CODEGEN_IN_LIST CMP, {f2_rhs}
          .elseif .xmatch(f2_lhs, X)
            F2_CODEGEN_IN_LIST CPX, {f2_rhs}
          .elseif .xmatch(f2_lhs, Y)
            F2_CODEGEN_IN_LIST CPY, {f2_rhs}
          .else
            F2_ERR_UNREACHED
          .endif

        .elseif .xmatch(f2_op, NOT_IN)
          @f2_negate_flag .set .not(@f2_negate_flag)
          .if .xmatch(f2_lhs, A)
            F2_CODEGEN_IN_LIST CMP, {f2_rhs}
          .elseif .xmatch(f2_lhs, X)
            F2_CODEGEN_IN_LIST CPX, {f2_rhs}
          .elseif .xmatch(f2_lhs, Y)
            F2_CODEGEN_IN_LIST CPY, {f2_rhs}
          .else
            F2_ERR_UNREACHED
          .endif
          @f2_negate_flag .set .not(@f2_negate_flag)

        .elseif .xmatch(f2_op, BETWEEN)
          F2_PARSE_PAIR f2_op_str, f2_rhs

          .if .xmatch(f2_lhs, A)
            F2_CODEGEN_BETWEEN CMP, {f2_first}, {f2_second}, f2_op_str
          .elseif .xmatch(f2_lhs, X)
            F2_CODEGEN_BETWEEN CPX, {f2_first}, {f2_second}, f2_op_str
          .elseif .xmatch(f2_lhs, Y)
            F2_CODEGEN_BETWEEN CPY, {f2_first}, {f2_second}, f2_op_str
          .else
            F2_ERR_UNREACHED
          .endif

          .undef f2_first
          .undef f2_second

        .elseif .xmatch(f2_op, NOT_BETWEEN)
          F2_PARSE_PAIR f2_op_str, f2_rhs

          @f2_negate_flag .set .not(@f2_negate_flag)
          .if .xmatch(f2_lhs, A)
            F2_CODEGEN_BETWEEN CMP, {f2_first}, {f2_second}, f2_op_str
          .elseif .xmatch(f2_lhs, X)
            F2_CODEGEN_BETWEEN CPX, {f2_first}, {f2_second}, f2_op_str
          .elseif .xmatch(f2_lhs, Y)
            F2_CODEGEN_BETWEEN CPY, {f2_first}, {f2_second}, f2_op_str
          .else
            F2_ERR_UNREACHED
          .endif
          @f2_negate_flag .set .not(@f2_negate_flag)

          .undef f2_first
          .undef f2_second

        .else
          ;; binary operator

          F2_VALIDATE_COMPARE_RHS f2_op_str, f2_rhs

          ;; Code generation
          .if .xmatch(f2_lhs, A)
            F2_CODEGEN_COMPARE CMP, {f2_rhs}
          .elseif .xmatch(f2_lhs, X)
            F2_CODEGEN_COMPARE CPX, {f2_rhs}
          .elseif .xmatch(f2_lhs, Y)
            F2_CODEGEN_COMPARE CPY, {f2_rhs}
          .else
            F2_ERR_UNREACHED
          .endif

          ;; Code generation - branches
          .if .xmatch(f2_op, =)
            F2_CODEGEN_BRANCH_WITH_FLAGS BEQ, BNE
          .elseif .xmatch(f2_op, <>)
            F2_CODEGEN_BRANCH_WITH_FLAGS BNE, BEQ
          .elseif .xmatch(f2_op, <)
            F2_CODEGEN_BRANCH_WITH_FLAGS BCC, BCS
          .elseif .xmatch(f2_op, >=)
            F2_CODEGEN_BRANCH_WITH_FLAGS BCS, BCC
          .else
            F2_ERR_UNREACHED
          .endif
        .endif

        .undef f2_lhs
        .undef f2_op
        .undef f2_op_str
        .undef f2_rhs

        F2_LOG_TCOUNT
        F2_LOG_END_FUNC "PARSE_COMP"
.endmacro

;;; Parse a unary test (e.g. CS, NC, ...)
.macro F2_PARSE_FLAG_TEST
        F2_LOG_FUNC "PARSE_FLAG_TEST"
        F2_LOG_TCOUNT

        .define f2_flag_test .left(1, {f2_token_list})
        F2_PARSE_CONSUME
        F2_LOG_SAW .string(f2_flag_test)

        .if .xmatch(f2_flag_test, ZS)
          F2_CODEGEN_BRANCH_WITH_FLAGS BEQ, BNE
        .elseif .xmatch(f2_flag_test, ZC)
          F2_CODEGEN_BRANCH_WITH_FLAGS BNE, BEQ
        .elseif .xmatch(f2_flag_test, NS)
          F2_CODEGEN_BRANCH_WITH_FLAGS BMI, BPL
        .elseif .xmatch(f2_flag_test, NC)
          F2_CODEGEN_BRANCH_WITH_FLAGS BPL, BMI
        .elseif .xmatch(f2_flag_test, CS)
          F2_CODEGEN_BRANCH_WITH_FLAGS BCS, BCC
        .elseif .xmatch(f2_flag_test, CC)
          F2_CODEGEN_BRANCH_WITH_FLAGS BCC, BCS
        .elseif .xmatch(f2_flag_test, VS)
          F2_CODEGEN_BRANCH_WITH_FLAGS BVS, BVC
        .elseif .xmatch(f2_flag_test, VC)
          F2_CODEGEN_BRANCH_WITH_FLAGS BVC, BVS
        .else
          F2_ERR_UNREACHED
        .endif

        .undef f2_flag_test

        F2_LOG_TCOUNT
        F2_LOG_END_FUNC "PARSE_FLAG_TEST"
.endmacro

;;; Parse a boolean expression
.macro F2_PARSE_BEXPR
        F2_LOG_FUNC "PARSE_BEXPR"
        F2_LOG_TCOUNT

        .define f2_tok .left(1, {f2_token_list})
        .if .xmatch({f2_tok}, NOT)
          .undef f2_tok

          ;; NOT - toggle the invert flag, recurse
          F2_PARSE_CONSUME
          F2_LOG_SAW "NOT"
          @f2_negate_flag .set .not(@f2_negate_flag)
          F2_PARSE_BEXPR

        .elseif .xmatch({f2_tok}, A) .or .xmatch({f2_tok}, X) .or .xmatch({f2_tok}, Y)
          .undef f2_tok

          ;; register - start of a relational expression (comparison)
          F2_PARSE_COMP

        .elseif .xmatch({f2_tok}, CC) .or .xmatch({f2_tok}, CS) .or .xmatch({f2_tok}, NC) .or .xmatch({f2_tok}, NS) .or .xmatch({f2_tok}, ZC) .or .xmatch({f2_tok}, ZS) .or .xmatch({f2_tok}, VC) .or .xmatch({f2_tok}, VS)
          .undef f2_tok

          ;; flag test
          F2_PARSE_FLAG_TEST

        .else
          .undef f2_tok
          F2_ERR_EXPECTED "boolean expression"
        .endif

        F2_LOG_END_FUNC "PARSE_BEXPR"
.endmacro

;;; Parse a compound boolean expression (joined by AND/OR)
.macro F2_PARSE_BEXPR_LOOP
        F2_LOG_FUNC "PARSE_BEXPR_LOOP"
        F2_LOG_TCOUNT

        @f2_negate_flag .set 0
        F2_PARSE_BEXPR

        F2_LOG_TCOUNT

        .if .tcount({f2_token_list}) > 0
          .if .xmatch(.left(1, {f2_token_list}), AND)
            F2_LOG_SAW "AND"
            F2_PARSE_CONSUME
            F2_PARSE_BEXPR_LOOP
          .elseif .xmatch(.left(1, {f2_token_list}), OR)
            F2_LOG_SAW "OR"
            F2_PARSE_CONSUME
            F2_PARSE_BEXPR_LOOP
          .else
            F2_ERR_UNEXPECTED_TOKEN
          .endif
        .endif

        F2_LOG_TCOUNT
        F2_LOG_END_FUNC "PARSE_BEXPR_LOOP"
.endmacro

;;; Parse (and emit) a statement - everything up to next ':'
.macro F2_PARSE_STATEMENT
        F2_LOG_FUNC "PARSE_STATEMENT"

        .define f2_stmt .left(1, {f2_token_list})

        F2_PARSE_CONSUME
        F2_PARSE_STATEMENT2

        f2_stmt

        .undef f2_stmt

        F2_LOG_END_FUNC "PARSE_STATEMENT"
.endmacro
.macro F2_PARSE_STATEMENT2
        F2_LOG_FUNC "PARSE_STATEMENT2"
        .if .tcount({f2_token_list}) = 0
          F2_ERR_EXPECTED "end-of-statement (':')"
        .endif

        .if .xmatch(.left(1, {f2_token_list}), :)
          F2_PARSE_CONSUME
        .else
          .define f2_tmp f2_stmt
          .undef f2_stmt
          .define f2_stmt f2_tmp .left(1, {f2_token_list})
          .undef f2_tmp
          F2_PARSE_CONSUME
          F2_PARSE_STATEMENT2
        .endif
        F2_LOG_END_FUNC "PARSE_STATEMENT2"
.endmacro

.macro F2_PARSE_STATEMENTS
        F2_LOG_FUNC "PARSE_STATEMENTS"

        ;; Match any of BIT, LDA, LDX, LDY, INC, INX, INY, DEC, DEX, DEY, upper or lowercase
        .if .xmatch(.left(1, {f2_token_list}), bit) .or .xmatch(.left(1, {f2_token_list}), BIT) .or .xmatch(.left(1, {f2_token_list}), lda) .or .xmatch(.left(1, {f2_token_list}), LDA) .or .xmatch(.left(1, {f2_token_list}), ldx) .or .xmatch(.left(1, {f2_token_list}), LDX) .or .xmatch(.left(1, {f2_token_list}), ldy) .or .xmatch(.left(1, {f2_token_list}), LDY) .or .xmatch(.left(1, {f2_token_list}), inc) .or .xmatch(.left(1, {f2_token_list}), INC) .or .xmatch(.left(1, {f2_token_list}), inx) .or .xmatch(.left(1, {f2_token_list}), INX) .or .xmatch(.left(1, {f2_token_list}), iny) .or .xmatch(.left(1, {f2_token_list}), INY) .or .xmatch(.left(1, {f2_token_list}), dec) .or .xmatch(.left(1, {f2_token_list}), DEC) .or .xmatch(.left(1, {f2_token_list}), dex) .or .xmatch(.left(1, {f2_token_list}), DEX) .or .xmatch(.left(1, {f2_token_list}), dey) .or .xmatch(.left(1, {f2_token_list}), DEY)
          F2_PARSE_STATEMENT

          .ifnblank token_list
            F2_PARSE_STATEMENTS
          .endif

        .endif

        F2_LOG_END_FUNC "PARSE_STATEMENTS"
.endmacro

;;; Parse a condition
.macro F2_PARSE_COND sense, stay_target, branch_target, token_list
        F2_LOG_FUNC "PARSE_COND"
        .ifblank token_list
          F2_ERR "Empty expression"
        .endif

        .define f2_token_list token_list
        @f2_sense_flag .set sense
        .define f2_stay_target stay_target
        .define f2_branch_target branch_target
        F2_LOG_TCOUNT

        ;; Condition may be preceded by statements
        F2_PARSE_STATEMENTS

        F2_PARSE_BEXPR_LOOP
        .undef f2_token_list
        .undef f2_stay_target
        .undef f2_branch_target
        F2_LOG_END_FUNC "PARSE_COND"
.endmacro

;;; Squash comma-delimited macro parameters into a single parameter containing commas
;;; Defines `f2_params`; caller must .undef it
.macro F2_PARSE_SQUASH_PARAMS p1,p2,p3,p4,p5,p6,p7,p8,p9
        .if     !.blank({p9})
          .define f2_params p1,p2,p3,p4,p5,p6,p7,p8,p9
        .elseif !.blank({p8})
          .define f2_params p1,p2,p3,p4,p5,p6,p7,p8
        .elseif !.blank({p7})
          .define f2_params p1,p2,p3,p4,p5,p6,p7
        .elseif !.blank({p6})
          .define f2_params p1,p2,p3,p4,p5,p6
        .elseif !.blank({p5})
          .define f2_params p1,p2,p3,p4,p5
        .elseif !.blank({p4})
          .define f2_params p1,p2,p3,p4
        .elseif !.blank({p3})
          .define f2_params p1,p2,p3
        .elseif !.blank({p2})
          .define f2_params p1,p2
        .elseif !.blank({p1})
          .define f2_params p1
        .else
          .define f2_params
        .endif
.endmacro

;;; ============================================================
;;; Code Generation
;;; ============================================================

;;; NB: This glues together statement logic (below) with expression
;;; parsing and code generation (above).

;;; Parse expression and generate code with "branch if true" semantics
.macro _FLOW_PARSE_AND_GEN_BIT target,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
        .local @stay

        F2_PARSE_SQUASH_PARAMS arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
        F2_PARSE_COND ::F2_SENSE_BIT, @stay, target, {f2_params}
        .undef f2_params

        @stay := *
.endmacro

;;; Parse expression and generate code with "branch if false" semantics
.macro _FLOW_PARSE_AND_GEN_BIF target,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
        .local @stay

        F2_PARSE_SQUASH_PARAMS arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8
        F2_PARSE_COND ::F2_SENSE_BIF, @stay, target, {f2_params}
        .undef f2_params

        @stay := *
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
;;; DO / REDO_IF / CONTINUE_IF / BREAK_IF / WHILE or REPEAT / UNTIL
;;; ============================================================

;;; Usage:
;;;     DO
;;;     ...
;;;     BREAK_IF <condition> ; optional
;;;     ...
;;;     REDO_IF <condition> ; optional
;;;     ...
;;;     CONTINUE_IF <condition> ; optional
;;;     ...
;;;     WHILE <condition>
;;;
;;;     REPEAT
;;;     ...
;;;     BREAK_IF <condition> ; optional
;;;     ...
;;;     REDO_IF <condition> ; optional
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
;;;     REDO_IF         - branches to start of loop body
;;;     CONTINUE_IF     - branches to end of loop body
;;;     BREAK_IF        - branches to after end of loop
;;;
;;; Example:
;;;     DO
;;;   eg_redo:
;;;       nop
;;;       REDO_IF Y = #1       ; conditionally branches to `eg_redo`
;;;       nop
;;;       CONTINUE_IF Y = #2   ; conditionally branches to `eg_continue`
;;;       nop
;;;       BREAK_IF Y = #3      ; conditionally branches to `eg_break`
;;;       nop
;;;   eg_continue:
;;;     WHILE inx : X < #30    ; 0+ statements, conditional branch to `eg_redo`
;;;   eg_break:

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

.macro REDO_IF expr,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  _FLOW_STATEMENT "REDO_IF"

        .local @redo
        @redo := __flow_loop_ident__ {"do_while"}

        _FLOW_PARSE_AND_GEN_BIT @redo,{expr},arg2,arg3,arg4,arg5,arg6,arg7,arg8

  _FLOW_END_STATEMENT
.endmacro

.macro CONTINUE_IF expr,arg2,arg3,arg4,arg5,arg6,arg7,arg8
  _FLOW_STATEMENT "CONTINUE_IF"

        .local @continue
        @continue := __flow_loop_ident__ {"continue"}

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

        .local redo
        redo := __flow_loop_ident__ {"do_while"}

        __flow_loop_ident__ {"continue"} := *
        .refto __flow_loop_ident__ {"continue"}

        _FLOW_PARSE_AND_GEN_BIT redo,{expr},arg2,arg3,arg4,arg5,arg6,arg7,arg8

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

        .local redo
        redo := __flow_loop_ident__ {"do_while"}

        __flow_loop_ident__ {"continue"} := *
        .refto __flow_loop_ident__ {"continue"}

        _FLOW_PARSE_AND_GEN_BIF redo,{expr},arg2,arg3,arg4,arg5,arg6,arg7,arg8

        __flow_loop_ident__ {"break"} := *
        .refto __flow_loop_ident__ {"break"}

        __DEC_IDENT__ __flow_loop_depth__

  _FLOW_END_STATEMENT
.endmacro

.macro FOREVER
  _FLOW_STATEMENT "FOREVER"

        ;; Note that "do_while" is still used for minting identifiers
        ;; so that DO and REPEAT remain synonyms and helpers can be
        ;; shared between WHILE and UNTIL.

        .local redo
        redo := __flow_loop_ident__ {"do_while"}

        ;; NOTE: The `continue` label here points at start of the
        ;; block (i.e. `redo` label) not the end of the block (i.e.
        ;; the `JMP` statement) to save cycles.
        __flow_loop_ident__ {"continue"} := redo
        .refto __flow_loop_ident__ {"continue"}

        jmp     redo

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
        .define .ident(.sprintf("REDO_IF_%s", cond)) REDO_IF .ident(cond)
        .define .ident(.sprintf("BREAK_IF_%s", cond)) BREAK_IF .ident(cond)
        .define .ident(.sprintf("RTS_IF_%s", cond)) RTS_IF .ident(cond)
.endmacro
.macro _FLOW_DEFINE_COMPARE_MACROS_ cond
        .define .ident(.sprintf("IF_A_%s", cond)) IF A .ident(cond)
        .define .ident(.sprintf("ELSE_IF_A_%s", cond)) ELSE_IF A .ident(cond)
        .define .ident(.sprintf("WHILE_A_%s", cond)) WHILE A .ident(cond)
        .define .ident(.sprintf("UNTIL_A_%s", cond)) UNTIL A .ident(cond)
        .define .ident(.sprintf("REDO_IF_A_%s", cond)) REDO_IF A .ident(cond)
        .define .ident(.sprintf("BREAK_IF_A_%s", cond)) BREAK_IF A .ident(cond)
        .define .ident(.sprintf("RTS_IF_A_%s", cond)) RTS_IF A .ident(cond)

        .define .ident(.sprintf("IF_X_%s", cond)) IF X.ident(cond)
        .define .ident(.sprintf("ELSE_IF_X_%s", cond)) ELSE_IF X.ident(cond)
        .define .ident(.sprintf("WHILE_X_%s", cond)) WHILE X.ident(cond)
        .define .ident(.sprintf("UNTIL_X_%s", cond)) UNTIL X.ident(cond)
        .define .ident(.sprintf("REDO_IF_X_%s", cond)) REDO_IF X.ident(cond)
        .define .ident(.sprintf("BREAK_IF_X_%s", cond)) BREAK_IF X.ident(cond)
        .define .ident(.sprintf("RTS_IF_X_%s", cond)) RTS_IF X.ident(cond)

        .define .ident(.sprintf("IF_Y_%s", cond)) IF Y .ident(cond)
        .define .ident(.sprintf("ELSE_IF_Y_%s", cond)) ELSE_IF Y .ident(cond)
        .define .ident(.sprintf("WHILE_Y_%s", cond)) WHILE Y .ident(cond)
        .define .ident(.sprintf("UNTIL_Y_%s", cond)) UNTIL Y .ident(cond)
        .define .ident(.sprintf("REDO_IF_Y_%s", cond)) REDO_IF Y .ident(cond)
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
