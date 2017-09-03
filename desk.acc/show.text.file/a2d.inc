;;; ------------------------------
;;; A2Desktop
;;; ------------------------------

;;; Entry Points
A2D             := $4000

UNKNOWN_CALL    := $8E00

JUMP_TABLE_01   := $4015        ; ???
JUMP_TABLE_02   := $4018
JUMP_TABLE_03   := $401E
JUMP_TABLE_04   := $4021
JUMP_TABLE_05   := $4021
JUMP_TABLE_06   := $4024
JUMP_TABLE_07   := $4027
JUMP_TABLE_08   := $402A
JUMP_TABLE_09   := $402D
JUMP_TABLE_10   := $4030
JUMP_TABLE_11   := $4033
JUMP_TABLE_12   := $4036
JUMP_TABLE_13   := $4039
JUMP_TABLE_14   := $403C
JUMP_TABLE_15   := $403F

A2D_UNK_03      := $03          ; Unknown - used in calculator after frame is drawn

A2D_TEXT_BOX1   := $04          ; Not sure what BOX1 vs. BOX2 is for
A2D_TEXT_BOX2   := $06          ; Not sure what BOX1 vs. BOX2 is for
        ;; .word left           pixels from screen edge
        ;; .word top
        ;; .word $2000          ???
        ;; .word $80            ???
        ;; .word hoffset        pixels scrolled
        ;; .word voffset
        ;; .word width          pixels
        ;; .word height

A2D_SET_PATTERN := $08
        ;; .byte r0...r7        8x8 pixel pattern for A2D_CLEAR_BOX calls

A2D_UNK_0C      := $0C          ; Unknown - used in calculator

A2D_SET_TEXT_POS:= $0E
        ;; .word left
        ;; .word base

A2D_CLEAR_BOX   := $11   ; To window background pattern
        ;; .word hoffset        (includes scroll pos)
        ;; .word voffset
        ;; .word width          pixels
        ;; .word height

A2D_UNK_14      := $14          ; Unknown - draws push button (calculator)
A2D_UNK_19      := $19          ; Unknown - draws button label (calculator)

A2D_DRAW_TEXT   := $19
        ;; .addr data
        ;; .byte length

A2D_GET_BUTTON  := $2A
        ;; .byte state (0=up, 1=pressed, 2=held???)

A2D_CREATE_WINDOW := $38
        ;; .byte id
        ;;      0 = desktop
        ;;      1, 2, ... = file windows
        ;;      100 = DA (for example)
        ;; .byte flags          (A2D_CW_*)
        ;;      bit 0: remove title bar
        ;;      bit 1: add close box
        ;;      bit 2: add resize box
        ;; .addr title
        ;; .byte ???
        ;; .byte ???
        ;; .byte ???
        ;; .byte ???
        ;; .byte ???
        ;; .byte vscroll_pos
        ;; .byte ???
        ;; .byte ???
        ;; .byte ???
        ;; .byte ???
        ;; .byte ???
        ;; .byte ???
        ;; .word width
        ;; .word height

A2D_DESTROY_WINDOW := $39
        ;; .byte id
        ;; .byte ???

A2D_GET_MOUSE   := $40
        ;; .word x
        ;; .word y
        ;; .byte element        (A2D_ELEM_*)
        ;;      0 = desktop
        ;;      1 = menu
        ;;      2 = client area (including scroll bars/resize box)
        ;;      3 = title bar
        ;;      4 = resize box
        ;;      5 = close box
        ;; .byte id of window

A2D_BTN_CLICK   := $43
        ;; .byte clicked (0 = cancelled, 1 = clicked)
        ;; .byte ??
        ;; .byte ??

A2D_DRAG_RESIZE := $45
        ;; .byte id of window
        ;; .word xcoord of mouse
        ;; .word ycoord of mouse
        ;; .byte ??     (likely: moved? 0 = no change, 1 = moved)

A2D_QUERY_CLIENT:= $48
        ;; .word xcoord of query
        ;; .word ycoord of query
        ;; .byte part (0 = client, 1 = vscroll, 2 = hscroll)
        ;; .byte scroll (1 = up/left, 2 = down/right, 3 = above/before, 4 = below/after, 5 = thumb)

A2D_RESIZE_WINDOW := $49
        ;; .byte ??     (unused, so incomplete)
        ;; .byte ??

A2D_DRAG_SCROLL:= $4A
        ;; .byte type (1 = vscroll, 2 = hscroll)
        ;; .word xcoord of mouse
        ;; .word ycoord of mouse
        ;; .byte position (0...255)
        ;; .byte moved (0 = no change, 1 = moved)

A2D_UPDATE_SCROLL:= $4B
        ;; .byte type (1 = vertical, 2 = horizontal)
        ;; .byte pos (new position 0...250)


;;; Used in A2D_GET_MOUSE
A2D_ELEM_DESKTOP:= 0
A2D_ELEM_MENU   := 1
A2D_ELEM_CLIENT := 2
A2D_ELEM_TITLE  := 3
A2D_ELEM_RESIZE := 4
A2D_ELEM_CLOSE  := 5

;;; Used in A2D_QUERY_CLIENT, A2D_DRAG_SCROLL, A2D_UPDATE_SCROLL
A2D_CLIENT      := 0
A2D_VSCROLL     := 1
A2D_HSCROLL     := 2

;;; Used in A2D_QUERY_CLIENT
A2D_SCROLL_PART_UP      := 1
A2D_SCROLL_PART_LEFT    := 1
A2D_SCROLL_PART_DOWN    := 2
A2D_SCROLL_PART_RIGHT   := 2
A2D_SCROLL_PART_ABOVE   := 3
A2D_SCROLL_PART_BEFORE  := 3
A2D_SCROLL_PART_BELOW   := 4
A2D_SCROLL_PART_AFTER   := 4
A2D_SCROLL_PART_THUMB   := 5

;;; Used in A2D_CREATE_WINDOW
A2D_CW_NOTITLE  := 1 << 0
A2D_CW_ADDCLOSE := 1 << 1
A2D_CW_ADDRESIZE:= 1 << 2

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
