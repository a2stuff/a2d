;;; ------------------------------
;;; ProDOS MLI
;;; ------------------------------

;;; Entry point
MLI             := $BF00

;;; Housekeeping Calls
CREATE          := $C0
DESTROY         := $C1
RENAME          := $C2
SET_FILE_INFO   := $C3
GET_FILE_INFO   := $C4
ON_LINE         := $C5
SET_PREFIX      := $C6
GET_PREFIX      := $C7
;;; Filing Calls
OPEN            := $C8
NEWLINE         := $C9
READ            := $CA
WRITE           := $CB
CLOSE           := $CC
FLUSH           := $CD
SET_MARK        := $CE
GET_MARK        := $CF
SET_EOF         := $D0
GET_EOF         := $D1
SET_BUF         := $D2
GET_BUF         := $D3
;;; System Calls
GET_TIME        := $82
ALLOC_INTERRUPT := $40
DEALLOC_INTERRUPT       := $41
;;; Direct Disk Access Commands
READ_BLOCK      := $80
WRITE_BLOCK     := $71

;;; Macros
.macro  MLI_CALL    op, addr
        jsr MLI
        .byte op
        .addr addr
.endmacro
