;;; ==================================================
;;; A2Desktop
;;; ==================================================

;;; ==================================================
;;; Direct Calls

        ;; These must be called from main memory (RAMRDOFF/RAMWRTOFF)
JUMP_TABLE_03   := $4003        ; Enter DeskTop input loop
JUMP_TABLE_06   := $4006        ; ???
JUMP_TABLE_09   := $4009        ; ???
JUMP_TABLE_0C   := $400C        ; ??? (made "items/in disk/..." redraw oddly)
JUMP_TABLE_0F   := $400F        ; ???
JUMP_TABLE_12   := $4012        ; ???
JUMP_TABLE_REDRAW_ALL  := $4015 ; Redraw all windows (e.g. after a drag)
JUMP_TABLE_18   := $4018        ; ???
JUMP_TABLE_CLEAR_SEL   := $401E ; Clear DeskTop selection
JUMP_TABLE_MLI  := $4021        ; ProDOS MLI call (Y=call, X,A=params addr)
JUMP_TABLE_24   := $4024        ; ???
JUMP_TABLE_27   := $4027        ; ???
JUMP_TABLE_2A   := $402A        ; Just an RTS
JUMP_TABLE_2D   := $402D        ; Draw type/size/date in non-icon views
JUMP_TABLE_30   := $4030        ; ???
JUMP_TABLE_33   := $4033        ; Shows "The syntax of the pathname is invalid.", hangs
JUMP_TABLE_36   := $4036        ; ditto
JUMP_TABLE_CUR_POINTER  := $4039 ; Changes mouse cursor to pointer
JUMP_TABLE_CUR_WATCH    := $403C ; Changes mouse cursor to watch
JUMP_TABLE_3F   := $403F        ; ???

        ;; Relay for A2D call (Y=call, X,A=params addr)

A2D_RELAY       := $D000

;;; ==================================================
;;; A2D Calls

A2D             := $4000
        ;; MLI-style call (jsr A2D ; .byte call ; .addr params)
        ;; Call from AUX (RAMRDON/RAMWRTON)


;;; $40E5,(call*2) is the jump table used for processing these calls
;;; $4184,(call*2) defines param blocks input length
;;;   if >=0, is length of param block
;;;   if <0, and with $7E to get length
;;;   if $4185,(call*2) is non-zero, param block is copied.

A2D_QUERY_SCREEN        := $03  ; Get screen state
        ;; (input length 0 bytes)
        ;; (output length 35 bytes - NOT 36 - TODO - where is this off???)
        ;; .word left
        ;; .word top
        ;; .addr addr           A2D_SCREEN_ADDR
        ;; .word stride         A2D_SCREEN_STRIDE
        ;; .word hoffset
        ;; .word voffset
        ;; .word width          560-1
        ;; .word height         192-1
        ;; .res 8 pattern
        ;; .byte mskand         AND mask, default $FF
        ;; .byte mskor          ORA mask, default $00
        ;; .byte 0,0,0,0        ???
        ;; .byte hthick         horizontal pen thickness
        ;; .byte vthick         vertical pen thickness
        ;; .byte 0              ??? fill mode?
        ;; .byte tmsk           AND mask for text, default $7F
        ;; .addr font           A2D_DEFAULT_FONT

A2D_SET_STATE   := $04          ; Set full drawing state
        ;; (input length 36 bytes)
        ;; .word left           pixels from screen edge
        ;; .word top
        ;; .addr addr           A2D_SCREEN_ADDR
        ;; .word stride         A2D_SCREEN_STRIDE
        ;; .word hoffset        pixels scrolled
        ;; .word voffset
        ;; .word width          pixels
        ;; .word height
        ;; .res 8 pattern
        ;; .byte mskand         AND mask, default $FF
        ;; .byte mskor          ORA mask, default $00
        ;; .byte 0,0,0,0        ???
        ;; .byte hthick         horizontal pen thickness
        ;; .byte vthick         vertical pen thickness
        ;; .byte 0              ??? fill mode?
        ;; .byte tmsk           AND mask for text, default $7F
        ;; .addr font           A2D_DEFAULT_FONT

        ;; $05 used in DeskTop but not DAs - icon click
        ;; (input length 0 bytes)

A2D_SET_BOX   := $06            ; Set just the drawing box, subset of full state
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
        ;; .res 8 pattern       8x8 pixel pattern for A2D_FILL_RECT calls
        ;; (TODO: Is there an output???)

A2D_SET_THICKNESS := $0A
        ;; (input length 2 bytes)
        ;; .byte hthick         horizontal pen thickness
        ;; .byte vthick         vertical pen thickness

A2D_SET_TEXT_MASK := $0C        ; Stored to background before XORing glyph
        ;; (input length 1 byte)
        ;; .byte mask

A2D_SET_POS     := $0E          ; Start of subsequent DRAW_TEXT, DRAW_LINE
        ;; (input length 4 bytes)
        ;; .word xcoord
        ;; .word ycoord

A2D_DRAW_LINE   := $0F          ; Draw line (from SET_POS)
        ;; $0F used in puzzle
        ;; (input length 4 bytes)
        ;; .word xdelta         signed, delta in pixels
        ;; .word ydelta

A2D_FILL_RECT   := $11          ; Fill rectangle with selected simple pattern/thickness
        ;; (input length 8 bytes)
        ;; .word left           (includes scroll pos)
        ;; .word top
        ;; .word right          pixels
        ;; .word bottom

A2D_DRAW_RECT   := $12          ; Draw rectangle with selected simple pattern/thickness
        ;; (input length 8 bytes)
        ;; .word left           pixels
        ;; .word top
        ;; .word right
        ;; .word bottom

A2D_TEST_BOX    := $13          ; Is pos (via SET_POS) in bounds? Returns true/false in A
        ;; (input length 8 bytes)
        ;; .word left
        ;; .word top
        ;; .word right
        ;; .word bottom

A2D_DRAW_BITMAP := $14          ; Draw pattern
        ;; (input length 16 bytes)
        ;; .word left
        ;; .word top
        ;; .addr bitmap         bitmap is 7 bits per byte, 0 = black, 1 = white
        ;; .byte stride         bitmap width in bytes
        ;; .byte 0              ???
        ;; .word hoffset        offset within bitmap definition
        ;; .word voffset
        ;; .word width          pixels
        ;; .word height         pixels

        ;; $15 used in DeskTop but not DAs - icon redraw
        ;; (input length 0 bytes)

        ;; $16 used in DeskTop but not DAs - desktop icon drag
        ;; (input length 0 bytes)

        ;; $17 used in DeskTop but not DAs - maybe selection drag
        ;; (input length 0 bytes)

A2D_MEASURE_TEXT := $18         ; Measure the width of a string in pixels
        ;; (input length 3 bytes)
        ;; .addr data
        ;; .byte length
        ;; .word width          result in pixels

A2D_DRAW_TEXT   := $19          ; Drawn at last SET_POS as left, baseline
        ;; (input length 3 bytes)
        ;; .addr data
        ;; .byte length

A2D_CONFIGURE_ZP_USE    := $1A  ; Configure ZP usage by API (speed vs. convenience)
        ;; (input length 1 byte)
        ;; .byte flag           (AWS_CZP_*; high bit set = preserve ZP during calls)

A2D_SET_CURSOR  := $24          ; Change cursor pattern
        ;; (input not copied)
        ;; .res 24 bitmap       2x12 byte bitmap
        ;; .res 24 mask         2x12 byte mask
        ;; .byte hotx           hotspot coords
        ;; .byte hoty

A2D_SHOW_CURSOR := $25
        ;; (no parameters; pass $0000 as address)

A2D_HIDE_CURSOR := $26
        ;; (no parameters; pass $0000 as address)

A2D_GET_INPUT   := $2A
        ;; (input length 0 bytes)
        ;; (output length 5 bytes)
        ;; .byte state          (A2D_INPUT_*)
        ;; if state is A2D_INPUT_KEY:
        ;;   .byte key          (ASCII code; high bit clear)
        ;;   .byte modifiers    (0=none, 1=open-apple, 2=closed-apple, 3=both)
        ;; if state otherwise:
        ;;   .word xcoord
        ;;   .word ycoord

A2D_UNK_2B      := $2B          ; Unknown - possibly "reset drawing state"
        ;; (no parameters; pass $0000 as address)

        ;; $2C used in DeskTop but not DAs - icon drag
        ;; (input length 0 bytes)

A2D_SET_INPUT   := $2D          ; Set pending input state (mouse or keyboard)
        ;; (input length 5 bytes)
        ;; .byte state          A2D_INPUT_*
        ;; if state is A2D_INPUT_KEY:
        ;;   .byte key          ASCII code; high bit clear
        ;;   .byte modifiers    0=none, 1=open-apple, 2=closed-apple, 3=both
        ;; if state otherwise:
        ;;   .word xcoord
        ;;   .word ycoord

A2D_CREATE_WINDOW := $38
        ;; (input not copied)
        ;; .byte id             0 = desktop, 1-...n = DeskTop windows, DAs use 51, 52, 100
        ;; .byte flags          A2D_CWF_*
        ;; .addr title
        ;; .byte hscroll        A2D_CWS_*
        ;; .byte vscroll        A2D_CWS_*
        ;; .byte hsmax
        ;; .byte hspos
        ;; .byte vsmax
        ;; .byte vspos
        ;; .byte ???
        ;; .byte ???
        ;; .word width_a        ??? possibly size of scroll area within window of scroll area?
        ;; .word height_a       ???
        ;; .word width_b        (of scroll area?)
        ;; .word height_b       (of scroll area?)
        ;;  - next section is identical to that for A2D_SET_STATE
        ;; .word left           pixels from screen edge
        ;; .word top
        ;; .word screen_addr
        ;; .word screen_stride
        ;; .word hoffset        pixels scrolled
        ;; .word voffset
        ;; .word width          pixels
        ;; .word height
        ;; .res 8 pattern
        ;; .byte mskand         AND mask, default $FF
        ;; .byte mskor          ORA mask, default $00
        ;; .byte 0,0,0,0        ???
        ;; .byte hthick
        ;; .byte vthick
        ;; .byte 0              ??? fill mode?
        ;; .byte tmsk           AND mask for text, default $7F
        ;; .addr font           A2D_DEFAULT_FONT
        ;; .addr next           address of next lower window in stack (filled in by call)

A2D_DESTROY_WINDOW := $39
        ;; (input length 1 byte)
        ;; .byte id

        ;; $3B used in DeskTop but not DAs - triggered by dragging window near right edge
        ;; (input length 1 byte)

A2D_QUERY_STATE      := $3C     ; get drawing state of window
        ;; (input length 3 bytes)
        ;; .byte id             window
        ;; .addr state          state definition to populate, like A2D_SET_STATE

A2D_QUERY_TARGET   := $40
        ;; (input length 4 bytes)
        ;; .word queryx         relative to screen
        ;; .word queryy
        ;; .byte element        A2D_ELEM_*
        ;; .byte id             of window

        ;; $41 used in DeskTop but not DAs - icon in window drop
        ;; (input length 0 bytes)

A2D_CLOSE_CLICK := $43
        ;; (input length 0 bytes)
        ;; .byte clicked        0 = cancelled, 1 = clicked
        ;; .byte ??
        ;; .byte ??

A2D_DRAG_WINDOW := $44
        ;; (input length 5 bytes)
        ;; .byte id             window
        ;; .word xcoord         mouse coords
        ;; .word ycoord
        ;; .byte moved          high bit set if moved, clear if not

A2D_DRAG_RESIZE := $45
        ;; (input length 5 bytes)
        ;; .byte id             window
        ;; .word xcoord         mouse coords
        ;; .word ycoord
        ;; .byte ??             likely: moved? 0 = no change, 1 = moved

A2D_MAP_COORDS  := $46          ; Map screen coords to client coords
        ;; (input length 5 bytes)
        ;; .byte window_id
        ;; .word screenx
        ;; .word screeny
        ;; .word clientx
        ;; .word clienty

A2D_QUERY_CLIENT:= $48
        ;; (input length 4 bytes)
        ;; .word xcoord
        ;; .word ycoord
        ;; .byte part           A2D_CLIENT, A2D_HSCROLL or A2D_VSCROLL
        ;; .byte scroll         A2D_SCROLL_PART_*

A2D_RESIZE_WINDOW := $49        ; ???
        ;; (input length 3 bytes)
        ;; .byte ???            maybe part (i.e. HSCROLL or VSCROLL) ???
        ;; .byte ???            width fraction ??
        ;; .byte ???

A2D_DRAG_SCROLL := $4A
        ;; (input length 5 bytes)
        ;; .byte type           A2D_HSCROLL or A2D_VSCROLL
        ;; .word mouse xcoord
        ;; .word mouse ycoord
        ;; .byte position       0...255
        ;; .byte moved          0 = no change, 1 = moved

A2D_UPDATE_SCROLL:= $4B
        ;; (input length 3 bytes)
        ;; .byte type           A2D_HSCROLL or A2D_VSCROLL
        ;; .byte pos            new position 0...250
        ;; .byte ???

;;; $4E looks like last call

;;; ==================================================
;;; Constants

;;; Used in A2D_QUERY_STATE / A2D_SET_BOX
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
A2D_ELEM_CLIENT := 2            ; Includes scroll bars
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
A2D_CWF_NOTITLE         := 1 << 0
A2D_CWF_ADDCLOSE        := 1 << 1
A2D_CWF_ADDRESIZE       := 1 << 2

A2D_CWS_NOSCROLL        := 0
A2D_CWS_SCROLL_ENABLED  := 1 << 7
A2D_CWS_SCROLL_THUMB    := 1 << 6
A2D_CWS_SCROLL_TRACK    := 1 << 0
A2D_CWS_SCROLL_NORMAL   := A2D_CWS_SCROLL_ENABLED | A2D_CWS_SCROLL_THUMB | A2D_CWS_SCROLL_TRACK

;;; Used in A2D_CONFIGURE_ZP_USE
A2D_CZP_PRESERVE        := 1<<7
A2D_CZP_OVERWRITE       := 0

;;; Used in various state blocks
A2D_DEFAULT_MSKAND      := $FF
A2D_DEFAULT_MSKOR       := $00
A2D_DEFAULT_TMSK        := $7F

;;; ==================================================

DESKTOP    := $8E00
        ;; MLI-style call (jsr A2D ; .byte call ; .addr params)
        ;; Call from AUX (RAMRDON/RAMWRTON)

        ;; Implementation bounces to $93BC, uses jump table at $939E

;;; This is the only known call:

DESKTOP_REDRAW_ICONS := $0C     ; Repaints desktop icons

        ;; $0D used at start of drag-select, $09 at end (then another $0D)

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

;;; ------------------------------------
;;; Same as above, but for DESKTOP

.macro  DESKTOP_CALL    op, addr, label
        jsr DESKTOP
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

;;; ------------------------------------

.macro A2D_DEFSTRING str, label ; String definition, for use with A2D_TEXT
        .local  data            ; Call as A2D_DEFSTRING "abc"
        .local  end             ; Can include control chars by using:
        .addr   data            ; A2D_DEFSTRING {"abc",$0D,"def"}

.if .paramcount > 1
label:
.endif
        .byte   end - data
data:   .byte   str
end:
.endmacro

.macro PASCAL_STRING str        ; Length-prefixed string
        .local  data            ; Can include control chars by using:
        .local  end             ; A2D_DEFSTRING {"abc",$0D,"def"}
        .byte   end - data
data:   .byte   str
end:
.endmacro


;;; Define pattern for A2D_DRAW_BITMAP - low 7 bits are reversed
;;; e.g. .byte px(%1000000)
;;; px() has high bit clear, PX() has high bit set
.define px(bits) (((bits&$40)>>6)|((bits&$20)>>4)|((bits&$10)>>2)|(bits&$8)|((bits&$4)<<2)|((bits&$2)<<4)|((bits&$1)<<6))
.define PX(bits) (((bits&$40)>>6)|((bits&$20)>>4)|((bits&$10)>>2)|(bits&$8)|((bits&$4)<<2)|((bits&$2)<<4)|((bits&$1)<<6)|$80)

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

        A2D_DEFAULT_FONT := $8800

        font_unk        := $8800 ; = $00 - ???
        font_size_count := $8801 ; = $7F - max glyph number
                                 ; looks like an address ($7F00) but is used as count
        font_height     := $8802 ; 9 pixels
        font_width_table := $8803 ; width in pixels, indexed by ASCII code

        font_glyphs     := $8883 ; $80 glyphs, organized by row, 9 bytes per
        ;; So glyph for A $41
        ;;  width is at $8803 + $41 = $8844 which is 7
        ;;  row0 is at $8883 + $41 + (0 * $80) = $88C4 ~ $1E = %00011110
        ;;  row1 is at $8883 + $41 + (1 * $80) = $8944 ~ $33 = %00110011
        ;; etc
        ;;
        ;; Glyphs $00-$1F are useful symbols; some overlap with MouseText
        ;; (called out as MT:X in the table below)
        ;;
        ;; $00 = space                $10 = TM left
        ;; $01 = folder left  (MT:X)  $11 = TM right
        ;; $02 = folder right (MT:Y)  $12 = pound
        ;; $03 = hourglass    (MT:C)  $13 = pi
        ;; $04 = insertion pt         $14 = divide
        ;; $05 = pointer      (MT:B)  $15 = rarrow       (MT:U)
        ;; $06 = vbar         (MT:_)  $16 = tri
        ;; $07 = hbar         (MT:S)  $17 = open circ
        ;; $08 = larrow               $18 = close        (MT:])
        ;; $09 = left box             $19 = gray odd     (MT:W)
        ;; $0A = darrow       (MT:J)  $1A = gray even    (MT:V)
        ;; $0B = uarrow       (MT:K)  $1B = solid circ
        ;; $0C = right box            $1C = inv check    (MT:E)
        ;; $0D = return       (MT:M)  $1D = check        (MT:D)
        ;; $0E = (C)                  $1E = solid apple  (MT:@)
        ;; $0F = (R)                  $1F = open apple   (MT:A)

        A2D_GLYPH_LARROW := $09
        A2D_GLYPH_RARROW := $15
        A2D_GLYPH_UARROW := $0B
        A2D_GLYPH_DARROW := $0A
        A2D_GLYPH_RETURN := $0D
        A2D_GLYPH_OAPPLE := $1F
