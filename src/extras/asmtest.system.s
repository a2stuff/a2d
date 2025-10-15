
;;; Not included in the package - just used as a reference for
;;; testing that edge cases build and generate the expected code.

        .include "../config.inc"

        .include "../inc/macros.inc"

;;; ============================================================
;;; Flow Control Macros
;;; ============================================================

;;; --------------------------------------------------
;;; Register Comparisons
;;; --------------------------------------------------

;;; IF
    IF A >= $1234
        nop
    END_IF

;;; ELSE_IF
    IF CS
        nop
    ELSE_IF A < $1234
        nop
    END_IF

;;; WHILE
    DO
        nop
    WHILE A < $1234

;;; UNTIL
    REPEAT
        nop
    UNTIL A < $1234

;;; BREAK
    DO
        nop
        BREAK_IF A < $1234
        nop
    WHILE CS

;;; CONTINUE
    DO
        nop
        CONTINUE_IF A < $1234
        nop
    WHILE CS

;;; RTS
        RTS_IF A < $1234

;;; --------------------------------------------------
;;; Index Registers
;;; --------------------------------------------------

;;; IF
    IF A >= $1234,x
        nop
    END_IF

;;; ELSE_IF
    IF CS
        nop
    ELSE_IF A < $1234,y
        nop
    END_IF

;;; WHILE
    DO
        nop
    WHILE A < $1234,y

;;; UNTIL
    REPEAT
        nop
    UNTIL A < $1234,y

;;; BREAK
    DO
        nop
        BREAK_IF A < $1234,y
        nop
    WHILE CS

;;; CONTINUE
    DO
        nop
        CONTINUE_IF A < $1234,y
        nop
    WHILE CS

;;; RTS
        RTS_IF A < $1234,y

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


;;; WHILE ... IN / NOT_IN
    DO
        nop
    WHILE A IN #1, #2, #3

    DO
        nop
    WHILE A NOT_IN #1, #2, #3


;;; UNTIL ... IN / NOT_IN
    REPEAT
        nop
    UNTIL A IN #1, #2, #3

    REPEAT
        nop
    UNTIL A NOT_IN #1, #2, #3


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

;;; RTS_IF ... IN / NOT_IN
        nop
        RTS_IF X IN #1, #2, #3
        nop

        nop
        RTS_IF X NOT_IN #1, #2, #3
        nop

;;; --------------------------------------------------
;;; BETWEEN
;;; --------------------------------------------------

        ;; IF ... BETWEEN / NOT_BETWEEN
    IF A BETWEEN #'0', #'9'
        nop
    END_IF

    IF A NOT_BETWEEN #'0', #'9'
        nop
    END_IF

        ;; ELSE_IF ... BETWEEN / NOT_BETWEEN
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

        ;; WHILE ... BETWEEN / NOT_BETWEEN
    DO
        nop
    WHILE A BETWEEN #'A', #'Z'

    DO
        nop
    WHILE A NOT_BETWEEN #'A', #'Z'

        ;; UNTIL ... BETWEEN / NOT_BETWEEN
    REPEAT
        nop
    UNTIL A BETWEEN #'A', #'Z'

    REPEAT
        nop
    UNTIL A NOT_BETWEEN #'A', #'Z'

        ;; BREAK_IF ... BETWEEN / NOT_BETWEEN
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

        ;; CONTINUE_IF ... BETWEEN / NOT_BETWEEN
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

        ;; RTS_IF ... BETWEEN / NOT_BETWEEN
        RTS_IF A BETWEEN #'0', #'9'

        RTS_IF A NOT_BETWEEN #'0', #'9'
