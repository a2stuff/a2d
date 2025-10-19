
;;; Not included in the package - just used as a reference for
;;; testing that edge cases build and generate the expected code.

        .include "../config.inc"

        .include "../inc/macros.inc"

;;; ============================================================
;;; Flow Control Macros
;;; ============================================================

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

;;; BREAK
    DO
        nop
        BREAK_IF NC
        BREAK_IF NOT NC
        nop
    WHILE CS

;;; CONTINUE
    DO
        nop
        CONTINUE_IF NC
        CONTINUE_IF NOT NC
        nop
    WHILE CS

;;; RTS
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

;;; BREAK
    DO
        nop
        BREAK_IF A < #$12
        BREAK_IF NOT A < #$12
        nop
    WHILE CS

;;; CONTINUE
    DO
        nop
        CONTINUE_IF A < #$12
        CONTINUE_IF NOT A < #$12
        nop
    WHILE CS

;;; RTS
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

;;; BREAK
    DO
        nop
        BREAK_IF A < table,y
        nop
    WHILE CS

;;; CONTINUE
    DO
        nop
        CONTINUE_IF A < table,y
        nop
    WHILE CS

;;; RTS
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

;;; ============================================================
;;; Errors
;;; ============================================================

.if 0
        RTS_IF                     ; RTS_IF: Empty expression
        RTS_IF CS X                ; RTS_IF: Unexpected tokens after flag test 'CS'
        RTS_IF CS,CC               ; RTS_IF: Unexpected arguments after flag test 'CS'
        RTS_IF A > #123            ; RTS_IF: Greater-than operator ('>') not supported
        RTS_IF A <= #123           ; RTS_IF: Less-than-or-equal operator ('<=') not supported
        RTS_IF A = 1               ; RTS_IF: Numeric literal in '=' comparison; did you mean '#1'?
        RTS_IF A >= table,A        ; RTS_IF: Unexpected non-index register after comparison '>='
        RTS_IF A >= table,X,Y      ; RTS_IF: Unexpected arguments after comparison '>='
        RTS_IF A BETWEEN '0', #'9' ; RTS_IF: Expected immediate 1st argument for 'BETWEEN'
        RTS_IF A BETWEEN #'0'      ; RTS_IF: Expected 2nd argument for 'BETWEEN'
        RTS_IF A BETWEEN #'0', '9' ; RTS_IF: Expected immediate 2nd argument for 'BETWEEN'
.endif
