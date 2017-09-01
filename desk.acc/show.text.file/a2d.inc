;;; ------------------------------
;;; A2Desktop
;;; ------------------------------

;;; Entry Points
A2D             := $4000
UNKNOWN_CALL    := $8E00

A2D_DRAW_TEXT   := $19
        ;; .addr data
        ;; .byte length

A2D_GET_BUTTON  := $2A
        ;; .byte state (0=up, 1=pressed, 2=held???)

A2D_CREATE_WINDOW := $38
        ;; .byte id
        ;; .byte ???

A2D_DESTROY_WINDOW := $39
        ;; .byte id
        ;; .byte ???

A2D_GET_MOUSE   := $40
        ;; .word x
        ;; .word y
        ;; .word element
        ;;      0 = ??
        ;;      1 = ??
        ;;      2 = client area/scroll bar
        ;;      3 = title bar
        ;;      4 = ??? (but tested for?)
        ;;      5 = close box
        ;; .word window
        ;;      $0 = outside window
        ;;      $64 = in window

A2D_BTN_CLICK   := $43
        ;; .byte clicked (0 = cancelled, 1 = clicked)
        ;; .byte ??
        ;; .byte ??

A2D_QUERY_CLIENT:= $48
        ;; .word xcoord of query
        ;; .word ycoord of query
        ;; .byte part (0 = client, 1 = vertical scroll bar, 2 = ???)
        ;; .byte scroll (1 = up, 2 = down, 3 = above, 4 = below, 5 = thumb)

A2D_UPDATE_SCROLL:= $4B
        ;; .byte type (1 = vertical, 2 = horizontal)
        ;; .byte pos (new position 0...250)

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
