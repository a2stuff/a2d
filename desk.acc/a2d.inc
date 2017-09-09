;;; ------------------------------
;;; A2Desktop
;;; ------------------------------

;;; Entry Points
A2D             := $4000

UNKNOWN_CALL    := $8E00

        ;; These must be called from main memory (RAMRDON/RAMWRTON)
JUMP_TABLE_03   := $4003        ; ???
JUMP_TABLE_06   := $4006        ; ???
JUMP_TABLE_09   := $4009        ; ???
JUMP_TABLE_0C   := $400C        ; ??? (made "items/in disk/..." redraw oddly)
JUMP_TABLE_0F   := $400F        ; ???
JUMP_TABLE_12   := $4012        ; ???
JUMP_TABLE_15   := $4015        ; ???
JUMP_TABLE_18   := $4018        ; ???
JUMP_TABLE_CLEAR_SEL   := $401E ; Clear DeskTop selection
JUMP_TABLE_21   := $4021        ; ???
JUMP_TABLE_24   := $4024        ; ???
JUMP_TABLE_27   := $4027        ; ???
JUMP_TABLE_2A   := $402A        ; ???
JUMP_TABLE_2D   := $402D        ; ???
JUMP_TABLE_30   := $4030        ; ???
JUMP_TABLE_33   := $4033        ; Shows "The syntax of the pathname is invalid.", hangs
JUMP_TABLE_36   := $4036        ; ditto
JUMP_TABLE_CUR_POINTER  := $4039 ; Changes mouse cursor to pointer
JUMP_TABLE_CUR_WATCH    := $403C ; Changes mouse cursor to watch
JUMP_TABLE_3F   := $403F        ; ???

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

A2D_UNK_07      := $07          ; Unknown - used in calculator

A2D_SET_PATTERN := $08
        ;; .byte r0...r7        8x8 pixel pattern for A2D_CLEAR_BOX calls

A2D_UNK_0C      := $0C          ; Unknown - used in calculator

A2D_SET_TEXT_POS:= $0E
        ;; .word left
        ;; .word base

A2D_FILL_RECT   := $11          ; With selected pattern
        ;; .word left           (includes scroll pos)
        ;; .word top
        ;; .word right          pixels
        ;; .word bottom

A2D_DRAW_RECT   := $12          ; With selected pattern
        ;; .word left           (includes scroll pos)
        ;; .word top
        ;; .word right          pixels
        ;; .word bottom

A2D_UNK_14      := $14          ; Unknown - draws push button (calculator)

A2D_MEASURE_TEXT := $18
        ;; .addr data
        ;; .byte length         ???
        ;; .word width          pixels

A2D_DRAW_TEXT   := $19
        ;; .addr data
        ;; .byte length

A2D_UNK_1A      := $1A          ; Unknown - used in calculator before window creation

A2D_UNK_24      := $24          ; Unknown - used in calculator

A2D_SHOW_CURSOR := $25
        ;; no parameters (pass $0000 as address)

A2D_HIDE_CURSOR := $26
        ;; no parameters (pass $0000 as address)

A2D_GET_INPUT  := $2A
        ;; .byte state     (0=up, 1=press, 2=release, 3=key, 4=held)
        ;; .byte key       (ASCII code; high bit clear)
        ;; .byte modifiers (0=none, 1=open-apple, 2=closed-apple, 3=both)

A2D_UNK_2B      := $2B          ; Unknown
        ;; no parameters (pass $0000 as address)

A2D_UNK_2D      := $2D          ; Unknown - used in calculator

A2D_CREATE_WINDOW := $38
        ;; .byte id
        ;;      0 = desktop
        ;;      1, 2, ... = file windows
        ;;      100 = DA (for example)
        ;; .byte flags          (A2D_CWF_*)
        ;;      bit 0: remove title bar
        ;;      bit 1: add close box
        ;;      bit 2: add resize box
        ;; .addr title
        ;; .byte hscroll        bits: 7 = enable, 6 = show thumb, 0 = show track
        ;; .byte vscroll
        ;; .byte hscroll_max
        ;; .byte hscroll_pos
        ;; .byte vscroll_max
        ;; .byte vscroll_pos
        ;; .byte ???
        ;; .byte ???
        ;; .word width_a        ???
        ;; .word height_a       ???
        ;; .word width_b        (of scroll area?)
        ;; .word height_b       (of scroll area?)
        ;;  - next section is identical to that for TEXT_BOX
        ;; .word left           pixels from screen edge
        ;; .word top
        ;; .word $2000          ???
        ;; .word $80            ???
        ;; .word hoffset        pixels scrolled
        ;; .word voffset
        ;; .word width          pixels
        ;; .word height



A2D_DESTROY_WINDOW := $39
        ;; .byte id

A2D_UNK_3C      := $3C          ; Unknown, used in calculator

A2D_GET_MOUSE   := $40
        ;; .word x              (relative to screen)
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

A2D_UNK_44      := $44          ; Unknown - used in calculator

A2D_MAP_COORDS := $46           ; Map screen coords to client coords
        ;; .byte window_id
        ;; .word screenx
        ;; .word screeny
        ;; .word clientx
        ;; .word clienty

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

;;; Used in A2D_GET_INPUT
A2D_INPUT_NONE  := 0            ; No mouse or keypress
A2D_INPUT_DOWN  := 1            ; Mouse button was depressed
A2D_INPUT_UP    := 2            ; Mouse button was released
A2D_INPUT_KEY   := 3            ; Key was pressed
A2D_INPUT_HELD  := 4            ; Mouse button still down

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
A2D_CWF_NOTITLE  := 1 << 0
A2D_CWF_ADDCLOSE := 1 << 1
A2D_CWF_ADDRESIZE:= 1 << 2

A2D_CWS_NOSCROLL := 0
A2D_CWS_SCROLL_ENABLED := 1 << 7
A2D_CWS_SCROLL_THUMB   := 1 << 6
A2D_CWS_SCROLL_TRACK   := 1 << 0
A2D_CWS_SCROLL_NORMAL  := A2D_CWS_SCROLL_ENABLED | A2D_CWS_SCROLL_THUMB | A2D_CWS_SCROLL_TRACK


;;; Macros
.macro  A2D_CALL    op, addr, label
        jsr A2D
        .byte op

.if .paramcount > 2
        label := *
.endif

.if .paramcount > 1
        .addr addr
.else
        .addr 0
.endif
.endmacro

.macro A2D_DEFSTRING str        ; String definition, for use with A2D_TEXT
        .local  data
        .addr   data
        .byte   .strlen(str)
data:   .byte   str
.endmacro

.macro PASCAL_STRING str        ; Length-prefixed string
        .byte   .strlen(str)
        .byte   str
.endmacro


;;; DeskTop Internals

        ;; These are DeskTop internals, but it appears there is no
        ;; API for getting the selected file.
        file_selected := $DF21  ; 0 if no selection, 1 otherwise
        path_index := $DF20     ; index of selected window (used to get prefix)
        path_table := $DFB3     ; window address table
        ;; each entry is 65 bytes long
        ;; each entry is length-prefixed path string (no trailing /)
        file_index := $DF22     ; index of selected file (global, not w/in window)
        file_table := $DD9F     ; file address table
        ;; each entry is 27 bytes long
        ;;      .byte ??
        ;;      .byte ??
        ;;      .byte type/icon (bits 4,5,6 clear = directory)
        ;;      .word iconx     (pixels)
        ;;      .word icony     (pixels)
        ;;      .byte ??
        ;;      .byte ??
        ;;      .byte len, name (length-prefixed, spaces before/after; 17 byte buffer)
