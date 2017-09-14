;;; ==================================================
;;; A2Desktop
;;; ==================================================

;;; ==================================================
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
JUMP_TABLE_MLI  := $4021        ; ProDOS MLI call (Y=call, X,A=params addr)
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

;;; ==================================================
;;; A2D Calls

;;; $40E5,(call*2) is the jump table used for processing these calls
;;; $4184,(call*2) defines param blocks input length
;;;   if >=0, is length of param block
;;;   if <0, and with $7E to get length
;;;   if $4185,(call*2) is non-zero, param block is copied.


A2D_QUERY_SCREEN        := $03  ; Get screen info
        ;; (input length 0 bytes)
        ;; (input length 35 bytes)
        ;; -- first part is like SET_BOX/QUERY_BOX params
        ;; .word left
        ;; .word top
        ;; .addr addr           A2D_SCREEN_ADDR
        ;; .word stride         A2D_SCREEN_STRIDE
        ;; .word hoffset
        ;; .word voffset
        ;; .word width          560-1
        ;; .word height         192-1
        ;; -- next part is ???
        ;; .byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ???
        ;; .byte 0,0,0,0        ???
        ;; .byte 1,1,0,$7F,0,$88

A2D_SET_BOX1   := $04           ; Not sure what BOX1 vs. BOX2 is for
        ;; (input length 36 bytes)
A2D_SET_BOX2   := $06           ; set vs. intersect? (not quite)
        ;; (input length 16 bytes)
        ;; .word left           pixels from screen edge
        ;; .word top
        ;; .addr addr           A2D_SCREEN_ADDR ($2000)
        ;; .word stride         A2D_SCREEN_STRIDE ($80)
        ;; .word hoffset        pixels scrolled
        ;; .word voffset
        ;; .word width          pixels
        ;; .word height

A2D_SET_FILL_MODE := $07
        ;; (input length 1 byte)
        ;; .byte mode           0 = normal, 6 = xor     (<4, >=4)

A2D_SET_PATTERN := $08
        ;; (input length 8 bytes)
        ;; .byte r0...r7        8x8 pixel pattern for A2D_FILL_RECT calls

        ;; $0A used in Date
        ;; (input length 2 bytes)

A2D_UNK_0C      := $0C          ; Unknown - used in calculator
        ;; (input length 1 byte)

A2D_SET_POS     := $0E
        ;; (input length 4 bytes)
        ;; .word x
        ;; .word y

        ;; $0F used in puzzle
        ;; (input length 4 bytes)

A2D_FILL_RECT   := $11          ; With selected simple pattern (SET_PATTERN)
        ;; (input length 8 bytes)
        ;; .word left           (includes scroll pos)
        ;; .word top
        ;; .word right          pixels
        ;; .word bottom

A2D_DRAW_RECT   := $12          ; With selected pattern
        ;; (input length 8 bytes)
        ;; .word left           (includes scroll pos)
        ;; .word top
        ;; .word right          pixels
        ;; .word bottom

A2D_TEST_BOX    := $13          ; Is pos (via SET_POS) in bounds? Returns true/false in A
        ;; (input length 8 bytes)
        ;; .word left
        ;; .word top
        ;; .word right
        ;; .word bottom

A2D_DRAW_PATTERN := $14         ; Draw pattern
        ;; (input length 16 bytes)
        ;; .word left
        ;; .word top
        ;; .addr pattern        pattern is 7 bits per byte, 0 = black, 1 = white
        ;; .byte stride         pattern width in bytes
        ;; .byte 0,0,0,0,0      ???
        ;; .word width          pixels
        ;; .word height         pixels

A2D_MEASURE_TEXT := $18
        ;; (input length 3 bytes)
        ;; .addr data
        ;; .byte length
        ;; .word width          pixels

A2D_DRAW_TEXT   := $19          ; Drawn at last SET_POS as left, baseline
        ;; (input length 3 bytes)
        ;; .addr data
        ;; .byte length

A2D_UNK_1A      := $1A          ; Unknown - used in calculator before window creation,
                                ; and after destruction
        ;; (input length 1 byte)

A2D_UNK_24      := $24          ; Unknown - used in calculator
        ;; (no parameters; pass $0000 as address)

A2D_SHOW_CURSOR := $25
        ;; (no parameters; pass $0000 as address)

A2D_HIDE_CURSOR := $26
        ;; (no parameters; pass $0000 as address)

A2D_GET_INPUT   := $2A
        ;; (input length 0 bytes)
        ;; (output length 5 bytes)
        ;; .byte state     (0=up, 1=press, 2=release, 3=key, 4=held)
        ;; if state is not 3:
        ;;   .byte key       (ASCII code; high bit clear)
        ;;   .byte modifiers (0=none, 1=open-apple, 2=closed-apple, 3=both)
        ;; if state is 3:
        ;;   .word xcoord
        ;;   .word ycoord

A2D_UNK_2B      := $2B          ; Unknown - possibly "reset drawing state"
        ;; (no parameters; pass $0000 as address)

A2D_UNK_2D      := $2D          ; Unknown - used in calculator
        ;; (input length 5 bytes)

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
        ;; .word width_a        ??? possibly size of scroll area within window of scroll area?
        ;; .word height_a       ???
        ;; .word width_b        (of scroll area?)
        ;; .word height_b       (of scroll area?)
        ;;  - next section is identical to that for A2D_SET_BOX
        ;; .word left           pixels from screen edge
        ;; .word top
        ;; .word screen_addr
        ;; .word screen_stride
        ;; .word hoffset        pixels scrolled
        ;; .word voffset
        ;; .word width          pixels
        ;; .word height

A2D_DESTROY_WINDOW := $39
        ;; (input length 1 byte)
        ;; .byte id

A2D_QUERY_BOX      := $3C       ; get client "box" of window
        ;; (input length 3 bytes)
        ;; .byte id             window
        ;; .addr box            box definition to populate, like A2D_SET_BOX1 (or 2 ???)

A2D_QUERY_TARGET   := $40
        ;; (input length 4 bytes)
        ;; .word queryx         (relative to screen)
        ;; .word queryy
        ;; .byte element        (A2D_ELEM_*)
        ;;      0 = desktop
        ;;      1 = menu
        ;;      2 = client area (including scroll bars/resize box)
        ;;      3 = title bar
        ;;      4 = resize box
        ;;      5 = close box
        ;; .byte id of window

A2D_CLOSE_CLICK := $43
        ;; (input length 0 bytes)
        ;; .byte clicked (0 = cancelled, 1 = clicked)
        ;; .byte ??
        ;; .byte ??

A2D_DRAG_WINDOW := $44
        ;; (input length 5 bytes)
        ;; .byte window_id
        ;; .word xcoord         screen coordinates
        ;; .word ycoord

A2D_DRAG_RESIZE := $45
        ;; (input length 5 bytes)
        ;; .byte id of window
        ;; .word xcoord of mouse
        ;; .word ycoord of mouse
        ;; .byte ??     (likely: moved? 0 = no change, 1 = moved)

A2D_MAP_COORDS  := $46           ; Map screen coords to client coords
        ;; (input length 5 bytes)
        ;; .byte window_id
        ;; .word screenx
        ;; .word screeny
        ;; .word clientx
        ;; .word clienty

A2D_QUERY_CLIENT:= $48
        ;; (input length 4 bytes)
        ;; .word xcoord of query
        ;; .word ycoord of query
        ;; .byte part (0 = client, 1 = vscroll, 2 = hscroll)
        ;; .byte scroll (1 = up/left, 2 = down/right, 3 = above/before, 4 = below/after, 5 = thumb)

A2D_RESIZE_WINDOW := $49
        ;; (input length 3 bytes)
        ;; .byte ??
        ;; .byte ??

A2D_DRAG_SCROLL := $4A
        ;; (input length 5 bytes)
        ;; .byte type (1 = vscroll, 2 = hscroll)
        ;; .word xcoord of mouse
        ;; .word ycoord of mouse
        ;; .byte position (0...255)
        ;; .byte moved (0 = no change, 1 = moved)

A2D_UPDATE_SCROLL:= $4B
        ;; (input length 3 bytes)
        ;; .byte type (1 = vertical, 2 = horizontal)
        ;; .byte pos (new position 0...250)
        ;; .byte ???

;;; $4E looks like last call

;;; ==================================================
;;; Constants

;;; Used in A2D_QUERY_BOX / A2D_SET_BOX
A2D_SCREEN_ADDR     := $2000    ; Screen address
A2D_SCREEN_STRIDE   := $80      ; Stride in bytes (???)

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

;;; Used in A2D_SET_FILL_MODE
A2D_SFM_NORMAL          := 0
A2D_SFM_XOR             := 6

;;; Used in A2D_CREATE_WINDOW
A2D_CWF_NOTITLE  := 1 << 0
A2D_CWF_ADDCLOSE := 1 << 1
A2D_CWF_ADDRESIZE:= 1 << 2

A2D_CWS_NOSCROLL := 0
A2D_CWS_SCROLL_ENABLED := 1 << 7
A2D_CWS_SCROLL_THUMB   := 1 << 6
A2D_CWS_SCROLL_TRACK   := 1 << 0
A2D_CWS_SCROLL_NORMAL  := A2D_CWS_SCROLL_ENABLED | A2D_CWS_SCROLL_THUMB | A2D_CWS_SCROLL_TRACK


;;; ==================================================
;;; Macros

;;; Call an A2D entry point:
;;;     A2D_CALL n                      - params is $0000
;;;     A2D_CALL n, params_addr
;;;     A2D_CALL m, params_addr, label  - params_addr is labeled for modifying

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

.macro A2D_DEFSTRING str, label ; String definition, for use with A2D_TEXT
        .local  data            ; Call as A2D_DEFSTRING "abc"
        .local  end             ; Can include control chars by using:
        .addr   data            ; A2D_DEFSTRING {"abc",$0D,"def"}
        .byte   end - data
data:   .byte   str
end:
.endmacro

.macro PASCAL_STRING str        ; Length-prefixed string
        .byte   .strlen(str)
        .byte   str
.endmacro

;;; Define pattern for A2D_DRAW_PATTERN - low 7 bits are reversed
;;; e.g. .byte px(%1000000)
.define px(bits) (((bits&$40)>>6)|((bits&$20)>>4)|((bits&$10)>>2)|(bits&$8)|((bits&$4)<<2)|((bits&$2)<<4)|((bits&$1)<<6))

;;; ==================================================
;;; DeskTop Internals

        ;; These are DeskTop internals, but it appears there is no
        ;; API for getting the selected file.
        file_selected := $DF21  ; 0 if no selection, 1 otherwise
        path_index := $DF20     ; index of selected window (used to get prefix)
        path_table := $DFB3     ; window address table
        ;; each entry is 65 bytes long
        ;;      length-prefixed path string (no trailing /)
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
