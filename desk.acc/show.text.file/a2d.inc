;;; ------------------------------
;;; A2Desktop
;;; ------------------------------

;;; Entry Points
A2D             := $4000
UNKNOWN_CALL    := $8E00

A2D_TEXT        := $19

;;; Macros
.macro  A2D_CALL    op, addr
        jsr A2D
        .byte op
        .addr addr
.endmacro

.macro A2D_DEFSTRING str        ; String definition, for use with A2D_TEXT
        .local  data
        .addr   data
        .byte   .strlen(str)
data:   .byte   str
.endmacro
