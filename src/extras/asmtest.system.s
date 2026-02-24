
;;; Not included in the package - just used as a reference for
;;; testing that edge cases build and generate the expected code.

;;; The suggested approach is to extending these tests is as follows:
;;;
;;; (1) Write out the test case using macros, e.g.:
;;;
;;;   IF X < #5
;;;   nop
;;;   END_IF
;;;
;;; (2) Comment out the macros, and write the expected output, e.g.:
;;;
;;;   ;; IF X < #5
;;;   cpx #5
;;;   bcs end_if
;;;
;;;   nop
;;;
;;;   ;; END_IF
;;;   end_if := *
;;;
;;; (3) Build, and capture an MD5 of `out/asmtest.system.SYS`
;;;
;;; (4) Switch the code back to the macros:
;;;
;;;   IF X < #5
;;;   nop
;;;   END_IF
;;;
;;; (5) Build, and compare the MD5 of `out/asmtest.system.SYS` with
;;; that from (3). If these don't match, then either the macros aren't
;;; working as expected, or you made a mistake in the transcription in
;;; (2).
;;;
;;; (6) Once they match, commit final code here. There is no need to
;;; capture intermediate states as long as the output is verified
;;; whenever changing the macro definitions.

        .include "../config.inc"

        .include "../inc/macros.inc"

;;; ============================================================
;;; Flow Control Macros - Branch & Loop
;;; ============================================================

;;; --------------------------------------------------
;;; Structure
;;; --------------------------------------------------

;;; IF
    IF NS
        nop
    END_IF

;;; IF / ELSE
    IF NS
        nop
    ELSE
        nop
    END_IF

;;; IF / ELSE_IF
    IF NS
        nop
    ELSE_IF CS
        nop
    END_IF

;;; IF / multiple ELSE_IF
    IF NS
        nop
    ELSE_IF CS
        nop
    ELSE_IF VS
        nop
    END_IF

;;; IF / ELSE_IF / ELSE
    IF NS
        nop
    ELSE_IF CS
        nop
    ELSE
        nop
    END_IF

;;; --------------------------------------------------
;;; Flag Tests
;;; --------------------------------------------------

;;; IF
    IF NC
        nop
    END_IF

    IF NOT NC
        nop
    END_IF

;;; ELSE_IF
    IF CS
        nop
    ELSE_IF NC
        nop
    END_IF

    IF CS
        nop
    ELSE_IF NOT NC
        nop
    END_IF

;;; WHILE
    DO
        nop
    WHILE NC

    DO
        nop
    WHILE NOT NC

;;; UNTIL
    REPEAT
        nop
    UNTIL NC

    REPEAT
        nop
    UNTIL NOT NC

;;; FOREVER
    DO
        nop
    FOREVER

    REPEAT
        nop
    FOREVER

;;; BREAK_IF
    DO
        nop
        BREAK_IF NC
        BREAK_IF NOT NC
        nop
    WHILE CS

    DO
        nop
        BREAK_IF NC
        BREAK_IF NOT NC
        nop
    FOREVER

;;; CONTINUE_IF
    DO
        nop
        CONTINUE_IF NC
        CONTINUE_IF NOT NC
        nop
    WHILE CS

    DO
        ;; NOTE: With `FOREVER`, `CONTINUE_IF` is branches to the
        ;; start of the loop body not the end of the loop body, to
        ;; save a few cycles.
        nop
        CONTINUE_IF NC
        CONTINUE_IF NOT NC
        nop
    FOREVER

;;; REDO_IF
    DO
        nop
        REDO_IF NC
        REDO_IF NOT NC
        nop
    WHILE CS

    DO
        nop
        REDO_IF NC
        REDO_IF NOT NC
        nop
    FOREVER

;;; RTS_IF
        RTS_IF NC
        RTS_IF NOT NC

;;; --------------------------------------------------
;;; Register Comparisons
;;; --------------------------------------------------

;;; IF
    IF A >= #$12
        nop
    END_IF

    IF NOT A >= #$12
        nop
    END_IF

;;; ELSE_IF
    IF CS
        nop
    ELSE_IF A < #$12
        nop
    END_IF

    IF CS
        nop
    ELSE_IF NOT A < #$12
        nop
    END_IF

;;; WHILE
    DO
        nop
    WHILE A < #$12

    DO
        nop
    WHILE NOT A < #$12

;;; UNTIL
    REPEAT
        nop
    UNTIL A < #$12

    REPEAT
        nop
    UNTIL NOT A < #$12

;;; BREAK_IF
    DO
        nop
        BREAK_IF A < #$12
        BREAK_IF NOT A < #$12
        nop
    WHILE CS

;;; REDO_IF
    DO
        nop
        REDO_IF A < #$12
        REDO_IF NOT A < #$12
        nop
    WHILE CS

;;; CONTINUE_IF
    DO
        nop
        CONTINUE_IF A < #$12
        CONTINUE_IF NOT A < #$12
        nop
    WHILE CS

;;; RTS_IF
        RTS_IF A < #$12
        RTS_IF NOT A < #$12

;;; --------------------------------------------------
;;; Index Registers
;;; --------------------------------------------------

table := *

;;; IF
    IF A >= table,x
        nop
    END_IF

;;; ELSE_IF
    IF CS
        nop
    ELSE_IF A < table,y
        nop
    END_IF

;;; WHILE
    DO
        nop
    WHILE A < table,y

;;; UNTIL
    REPEAT
        nop
    UNTIL A < table,y

;;; BREAK_IF
    DO
        nop
        BREAK_IF A < table,y
        nop
    WHILE CS

;;; REDO_IF
    DO
        nop
        REDO_IF A < table,y
        nop
    WHILE CS

;;; CONTINUE_IF
    DO
        nop
        CONTINUE_IF A < table,y
        nop
    WHILE CS

;;; RTS_IF
        RTS_IF A < table,y

;;; --------------------------------------------------
;;; IN / NOT_IN operators
;;; --------------------------------------------------

;;; IF ... IN / NOT_IN
    IF A IN #1, #2, #3
        nop
    END_IF

    IF A NOT_IN #1, #2, #3
        nop
    END_IF

    IF NOT A IN #1, #2, #3
        nop
    END_IF

    IF NOT A NOT_IN #1, #2, #3
        nop
    END_IF

;;; ELSE_IF ... IN / NOT_IN
    IF CS
        nop
    ELSE_IF A IN #1, #2, #3
        nop
    END_IF

    IF CS
        nop
    ELSE_IF A NOT_IN #1, #2, #3
        nop
    END_IF

    IF CS
        nop
    ELSE_IF NOT A IN #1, #2, #3
        nop
    END_IF

    IF CS
        nop
    ELSE_IF NOT A NOT_IN #1, #2, #3
        nop
    END_IF

;;; WHILE ... IN / NOT_IN
    DO
        nop
    WHILE A IN #1, #2, #3

    DO
        nop
    WHILE A NOT_IN #1, #2, #3

    DO
        nop
    WHILE NOT A IN #1, #2, #3

    DO
        nop
    WHILE NOT A NOT_IN #1, #2, #3

;;; UNTIL ... IN / NOT_IN
    REPEAT
        nop
    UNTIL A IN #1, #2, #3

    REPEAT
        nop
    UNTIL A NOT_IN #1, #2, #3

    REPEAT
        nop
    UNTIL NOT A IN #1, #2, #3

    REPEAT
        nop
    UNTIL NOT A NOT_IN #1, #2, #3

;;; BREAK_IF ... IN / NOT_IN
    DO
        nop
        BREAK_IF X IN #1, #2, #3
        nop
    WHILE CC

    DO
        nop
        BREAK_IF X NOT_IN #1, #2, #3
        nop
    WHILE CC

    DO
        nop
        BREAK_IF NOT X IN #1, #2, #3
        nop
    WHILE CC

    DO
        nop
        BREAK_IF NOT X NOT_IN #1, #2, #3
        nop
    WHILE CC

;;; REDO_IF ... IN / NOT_IN
    DO
        nop
        REDO_IF X IN #1, #2, #3
        nop
    WHILE CC

    DO
        nop
        REDO_IF X NOT_IN #1, #2, #3
        nop
    WHILE CC

    DO
        nop
        REDO_IF NOT X IN #1, #2, #3
        nop
    WHILE CC

    DO
        nop
        REDO_IF NOT X NOT_IN #1, #2, #3
        nop
    WHILE CC

;;; CONTINUE_IF ... IN / NOT_IN
    DO
        nop
        CONTINUE_IF X IN #1, #2, #3
        nop
    WHILE CC

    DO
        nop
        CONTINUE_IF X NOT_IN #1, #2, #3
        nop
    WHILE CC

    DO
        nop
        CONTINUE_IF NOT X IN #1, #2, #3
        nop
    WHILE CC

    DO
        nop
        CONTINUE_IF NOT X NOT_IN #1, #2, #3
        nop
    WHILE CC

;;; RTS_IF ... IN / NOT_IN
        nop
        RTS_IF X IN #1, #2, #3
        nop

        nop
        RTS_IF X NOT_IN #1, #2, #3
        nop

        nop
        RTS_IF NOT X IN #1, #2, #3
        nop

        nop
        RTS_IF NOT X NOT_IN #1, #2, #3
        nop

;;; --------------------------------------------------
;;; BETWEEN / NOT_BETWEEN operators
;;; --------------------------------------------------

;;; IF ... BETWEEN / NOT_BETWEEN
    IF A BETWEEN #'0', #'9'
        nop
    END_IF

    IF A NOT_BETWEEN #'0', #'9'
        nop
    END_IF

    IF NOT A BETWEEN #'0', #'9'
        nop
    END_IF

    IF NOT A NOT_BETWEEN #'0', #'9'
        nop
    END_IF

;;; ELSE_IF ... BETWEEN / NOT_BETWEEN
    IF CS
        nop
    ELSE_IF A BETWEEN #'0', #'9'
        nop
    END_IF

    IF CS
        nop
    ELSE_IF A NOT_BETWEEN #'0', #'9'
        nop
    END_IF

    IF CS
        nop
    ELSE_IF NOT A BETWEEN #'0', #'9'
        nop
    END_IF

    IF CS
        nop
    ELSE_IF NOT A NOT_BETWEEN #'0', #'9'
        nop
    END_IF

;;; WHILE ... BETWEEN / NOT_BETWEEN
    DO
        nop
    WHILE A BETWEEN #'A', #'Z'

    DO
        nop
    WHILE A NOT_BETWEEN #'A', #'Z'

    DO
        nop
    WHILE NOT A BETWEEN #'A', #'Z'

    DO
        nop
    WHILE NOT A NOT_BETWEEN #'A', #'Z'

;;; UNTIL ... BETWEEN / NOT_BETWEEN
    REPEAT
        nop
    UNTIL A BETWEEN #'A', #'Z'

    REPEAT
        nop
    UNTIL A NOT_BETWEEN #'A', #'Z'

    REPEAT
        nop
    UNTIL NOT A BETWEEN #'A', #'Z'

    REPEAT
        nop
    UNTIL NOT A NOT_BETWEEN #'A', #'Z'

;;; BREAK_IF ... BETWEEN / NOT_BETWEEN
    DO
        nop
        BREAK_IF A BETWEEN #'A', #'Z'
        nop
    WHILE CS

    DO
        nop
        BREAK_IF A NOT_BETWEEN #'A', #'Z'
        nop
    WHILE CS

    DO
        nop
        BREAK_IF NOT A BETWEEN #'A', #'Z'
        nop
    WHILE CS

    DO
        nop
        BREAK_IF NOT A NOT_BETWEEN #'A', #'Z'
        nop
    WHILE CS

;;; REDO_IF ... BETWEEN / NOT_BETWEEN
    DO
        nop
        REDO_IF A BETWEEN #'A', #'Z'
        nop
    WHILE CS

    DO
        nop
        REDO_IF A NOT_BETWEEN #'A', #'Z'
        nop
    WHILE CS

    DO
        nop
        REDO_IF NOT A BETWEEN #'A', #'Z'
        nop
    WHILE CS

    DO
        nop
        REDO_IF NOT A NOT_BETWEEN #'A', #'Z'
        nop
    WHILE CS

;;; CONTINUE_IF ... BETWEEN / NOT_BETWEEN
    DO
        nop
        CONTINUE_IF A BETWEEN #'A', #'Z'
        nop
    WHILE CS

    DO
        nop
        CONTINUE_IF A NOT_BETWEEN #'A', #'Z'
        nop
    WHILE CS

    DO
        nop
        CONTINUE_IF NOT A BETWEEN #'A', #'Z'
        nop
    WHILE CS

    DO
        nop
        CONTINUE_IF NOT A NOT_BETWEEN #'A', #'Z'
        nop
    WHILE CS

;;; RTS_IF ... BETWEEN / NOT_BETWEEN
        RTS_IF A BETWEEN #'0', #'9'

        RTS_IF A NOT_BETWEEN #'0', #'9'

        RTS_IF NOT A BETWEEN #'0', #'9'

        RTS_IF NOT A NOT_BETWEEN #'0', #'9'


;;; --------------------------------------------------
;;; Cheap Local Label Compatibility
;;; --------------------------------------------------

    DO
@cheap:
        BREAK_IF CS
        REDO_IF CS
        CONTINUE_IF CS
        beq     @cheap
    WHILE A < #123

;;; --------------------------------------------------
;;; Nesting
;;; --------------------------------------------------

    DO
        nop
      IF A >= #5
        nop
      END_IF
        nop
    WHILE A < #33

;;; --------------------------------------------------
;;; Conjunctions
;;; --------------------------------------------------

    IF CS AND A = #5
        nop
    END_IF

    IF NOT CS AND A = #5
        nop
    END_IF

    IF CS AND NOT A = #5
        nop
    END_IF

    IF NOT CS AND NOT A = #5
        nop
    END_IF

    DO
        nop
    WHILE CS AND A = #5

    DO
        nop
    WHILE NOT CS AND A = #5

    DO
        nop
    WHILE CS AND NOT A = #5

    DO
        nop
    WHILE NOT CS AND NOT A = #5

;;; --------------------------------------------------
;;; Conjunction and IN operator
;;; --------------------------------------------------

    IF A IN #1, #2, #3 AND CS
        nop
    END_IF

    DO
        nop
    WHILE A IN #1, #2, #3 AND CS

    IF NOT A IN #1, #2, #3 AND CS
        nop
    END_IF

    DO
        nop
    WHILE NOT A IN #1, #2, #3 AND CS

;;; --------------------------------------------------
;;; Conjunction and BETWEEN operator
;;; --------------------------------------------------

    IF A BETWEEN #1, #9 AND CS
        nop
    END_IF

    DO
        nop
    WHILE A BETWEEN #1, #9 AND CS

    IF NOT A BETWEEN #1, #9 AND CS
        nop
    END_IF

    DO
        nop
    WHILE NOT A BETWEEN #1, #9 AND CS

;;; --------------------------------------------------
;;; Disjunctions
;;; --------------------------------------------------

    IF CS OR A = #5
        nop
    END_IF

    IF NOT CS OR A = #5
        nop
    END_IF

    IF CS OR  NOT A = #5
        nop
    END_IF

    IF NOT CS OR NOT A = #5
        nop
    END_IF

    DO
        nop
    WHILE CS OR A = #5

    DO
        nop
    WHILE NOT CS OR A = #5

    DO
        nop
    WHILE CS OR  NOT A = #5

    DO
        nop
    WHILE NOT CS OR NOT A = #5

;;; --------------------------------------------------
;;; Disjunction and IN operator
;;; --------------------------------------------------

    IF A IN #1, #2, #3 OR CS
        nop
    END_IF

    DO
        nop
    WHILE A IN #1, #2, #3 OR CS

    IF NOT A IN #1, #2, #3 OR CS
        nop
    END_IF

    DO
        nop
    WHILE NOT A IN #1, #2, #3 OR CS

;;; --------------------------------------------------
;;; Disjunction and BETWEEN operator
;;; --------------------------------------------------

    IF A BETWEEN #1, #9 OR CS
        nop
    END_IF

    DO
        nop
    WHILE A BETWEEN #1, #9 OR CS

    IF NOT A BETWEEN #1, #9 OR CS
        nop
    END_IF

    DO
        nop
    WHILE NOT A BETWEEN #1, #9 OR CS

;;; --------------------------------------------------
;;; Statements within conditions
;;; --------------------------------------------------

        ;; BIT
    IF bit var : NS
        nop
    END_IF
    IF BIT var : NS
        nop
    END_IF

        ;; LDA
    IF lda var : NS
        nop
    END_IF
    IF LDA var : NS
        nop
    END_IF

        ;; LDX
    IF ldx var : NS
        nop
    END_IF
    IF LDX var : NS
        nop
    END_IF

        ;; LDY
    IF ldy var : NS
        nop
    END_IF
    IF LDY var : NS
        nop
    END_IF

        ;; INC
    DO
        nop
    WHILE inc var : X < #10
    DO
        nop
    WHILE INC var : X < #10

        ;; INX
    DO
        nop
    WHILE inx : X < #10
    DO
        nop
    WHILE INX : X < #10

        ;; INY
    DO
        nop
    WHILE iny : X < #10
    DO
        nop
    WHILE INY : X < #10

        ;; DEC
    DO
        nop
    WHILE dec var : X < #10
    DO
        nop
    WHILE DEC var : X < #10

        ;; DEX
    DO
        nop
    WHILE dex : X < #10
    DO
        nop
    WHILE DEX : X < #10

        ;; DEY
    DO
        nop
    WHILE dey : X < #10
    DO
        nop
    WHILE DEY : X < #10

        ;; Multiple statements
    DO
        nop
    WHILE dex : dex : POS

        ;; Staments in "gotos"
    DO
        nop
        REDO_IF bit var : NS
        nop
        CONTINUE_IF bit var : NS
        nop
        BREAK_IF bit var : NS
        nop
    WHILE POS

;;; ============================================================
;;; Flow Control Macros - Functions
;;; ============================================================

var:
target:
kConstant = 12
kClear = 0
kSet = 1

;;; CALL
        CALL    target

        CALL    target, A=#0
        CALL    target, A=#kConstant
        CALL    target, A=var
        CALL    target, A=table,x

        CALL    target, A=#0
        CALL    target, X=#0
        CALL    target, Y=#0
        CALL    target, AX=#0
        CALL    target, AY=#0
        CALL    target, XY=#0

        CALL    target, C=0
        CALL    target, C=1
        CALL    target, C=kClear
        CALL    target, C=kSet

        CALL    target, C=1
        CALL    target, D=1

        CALL    target, C=0, D=1, A=#0, X=#1, Y=#2
        CALL    target, Y=#kConstant, AX=var
        CALL    target, C=1, A=table,x, X=table,y

;;; TAIL_CALL
        TAIL_CALL target

        TAIL_CALL target, A=#0
        TAIL_CALL target, A=#kConstant
        TAIL_CALL target, A=var
        TAIL_CALL target, A=table,x

        TAIL_CALL target, A=#0
        TAIL_CALL target, X=#0
        TAIL_CALL target, Y=#0
        TAIL_CALL target, AX=#0
        TAIL_CALL target, AY=#0
        TAIL_CALL target, XY=#0

        TAIL_CALL target, C=0
        TAIL_CALL target, C=1
        TAIL_CALL target, C=kClear
        TAIL_CALL target, C=kSet

        TAIL_CALL target, C=1
        TAIL_CALL target, D=1

        TAIL_CALL target, C=0, D=1, A=#0, X=#1, Y=#2
        TAIL_CALL target, Y=#kConstant, AX=var
        TAIL_CALL target, C=1, A=table,x, X=table,y

;;; RETURN
        RETURN

        RETURN  A=#0
        RETURN  A=#kConstant
        RETURN  A=var
        RETURN  A=table,x

        RETURN  A=#0
        RETURN  X=#0
        RETURN  Y=#0
        RETURN  AX=#0
        RETURN  AY=#0
        RETURN  XY=#0

        RETURN  C=0
        RETURN  C=1
        RETURN  C=kClear
        RETURN  C=kSet

        RETURN  C=1
        RETURN  D=1

        RETURN  C=0, D=1, A=#0, X=#1, Y=#2
        RETURN  Y=#kConstant, AX=var
        RETURN  C=1, A=table,x, X=table,y

;;; --------------------------------------------------
;;; Cheap Local Label Compatibility
;;; --------------------------------------------------

@cheap:
        CALL    target, A=#1
        TAIL_CALL target, A=#2
        RETURN  A=#3
        beq     @cheap


;;; --------------------------------------------------
;;; Long (backwards) branches
;;; --------------------------------------------------

    DO
.repeat 120
        nop
.endrepeat
        ;; Should be `BMI`
        REDO_IF NS

        ;; Should be `BCS`
    WHILE CS

    DO
.repeat 130
        nop
.endrepeat
        ;; Should be `BPL` / `JMP`
        REDO_IF NS

        ;; Should be `BCC` / `JMP`
    WHILE CS

;;; ============================================================
;;; Errors
;;; ============================================================

.if 0
        RTS_IF                     ; RTS_IF: Empty expression
        RTS_IF CS X                ; RTS_IF: Unexpected token: 'X'
        RTS_IF CS,CC               ; RTS_IF: Unexpected token: ','
        RTS_IF A > #123            ; RTS_IF: Greater-than operator ('>') not supported
        RTS_IF A <= #123           ; RTS_IF: Less-than-or-equal operator ('<=') not supported
        RTS_IF A = 1               ; RTS_IF: Numeric literal in '=' comparison; did you mean '#1'?
        RTS_IF A >= table,A        ; RTS_IF: Unexpected non-index register after comparison '>='
        RTS_IF A >= table,X,Y      ; RTS_IF: Unexpected arguments after comparison '>='
        RTS_IF A BETWEEN           ; RTS_IF: Expected argument(s) after 'BETWEEN'
        RTS_IF A BETWEEN 0         ; RTS_IF: Numeric literal in 'BETWEEN' comparison; did you mean '#0'
        RTS_IF A BETWEEN a         ; RTS_IF: Expected two arguments for 'BETWEEN'
        RTS_IF A BETWEEN a,b,c     ; RTS_IF: Expected two arguments for 'BETWEEN'
        RTS_IF A BETWEEN '0', #'9' ; RTS_IF: Expected immediate 1st argument for 'BETWEEN'
        RTS_IF A BETWEEN #'0', '9' ; RTS_IF: Expected immediate 2nd argument for 'BETWEEN'
        RTS_IF A IN                ; RTS_IF: Expected argument(s) after 'IN'
        RTS_IF aa >= #1            ; RTS_IF: Expected boolean expression, saw identifier ('aa')
        RTS_IF A IN #0 #1          ; Expected 'end-of-line' but found '#'
        RTS_IF BIT var             ; RTS_IF: Expected end-of-statement (':')

        CALL    target, FOO=        ; CALL: Expected 'reg=...'
        CALL    target, A           ; CALL: Expected 'A=...'
        CALL    target, A=0         ; CALL: Numeric literal in 'A=expr' assignment; did you mean '#0'?
        CALL    target, A=kConstant ; CALL: Constant in 'A=expr' assignment; did you mean '#kConstant'?
        CALL    target, C=1 bad     ; CALL: Unexpected tokens after 'C=...'
        CALL    target, C=var       ; CALL: Expected constant expression after 'C='


.endif
