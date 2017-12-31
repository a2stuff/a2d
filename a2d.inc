;;; ==================================================
;;; A2Desktop - GUI Library
;;; ==================================================

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

A2D_CFG_DISPLAY         := $02  ; Configure display switches
        ;; (input length 1 byte)
        ;; Turns on 80 col/DHR, and then:
        ;;   bit 0: LoRes if clear, HiRes if set
        ;;   bit 1: Page 1 if clear, Page 2 if set
        ;;   bit 2: Full screen if clear, split screen if set
        ;;   bit 3: Graphics if clear, text if set

A2D_QUERY_SCREEN        := $03  ; Get screen state
        ;; (input length 0 bytes)
        ;; (output length 36 bytes)
        ;; .word left
        ;; .word top
        ;; .addr addr           A2D_SCREEN_ADDR
        ;; .word stride         A2D_SCREEN_STRIDE
        ;; .word hoff
        ;; .word voff
        ;; .word width          560-1
        ;; .word height         192-1
        ;; .res 8 pattern
        ;; .byte mskand         AND mask, default $FF
        ;; .byte mskor          ORA mask, default $00
        ;; .word xpos
        ;; .word ypos
        ;; .byte hthick         horizontal pen thickness
        ;; .byte vthick         vertical pen thickness
        ;; .byte 0              ??? fill mode?
        ;; .byte tmask          AND mask for text, default $7F
        ;; .addr font           A2D_DEFAULT_FONT

A2D_SET_STATE   := $04          ; Set full drawing state
        ;; (input length 36 bytes)
        ;; .word left           pixels from screen edge
        ;; .word top
        ;; .addr addr           A2D_SCREEN_ADDR
        ;; .word stride         A2D_SCREEN_STRIDE
        ;; .word hoff           pixels scrolled
        ;; .word voff
        ;; .word width          pixels
        ;; .word height
        ;; .res 8 pattern
        ;; .byte mskand         AND mask, default $FF
        ;; .byte mskor          ORA mask, default $00
        ;; .word xpos
        ;; .word ypos
        ;; .byte hthick         horizontal pen thickness
        ;; .byte vthick         vertical pen thickness
        ;; .byte 0              ??? fill mode?
        ;; .byte tmask          AND mask for text, default $7F
        ;; .addr font           A2D_DEFAULT_FONT

A2D_GET_STATE   := $05          ; Get pointer to active drawing state
        ;; (input length 0 bytes)
        ;; (output length 2 bytes)
        ;; .addr state          (out)

A2D_SET_BOX   := $06            ; Set just the drawing box, subset of full state
        ;; (input length 16 bytes)
        ;; .word left           pixels from screen edge
        ;; .word top
        ;; .addr addr           A2D_SCREEN_ADDR ($2000)
        ;; .word stride         A2D_SCREEN_STRIDE ($80)
        ;; .word hoff           pixels scrolled
        ;; .word voff
        ;; .word width          pixels
        ;; .word height

A2D_SET_FILL_MODE := $07
        ;; (input length 1 byte)
        ;; .byte mode           (>=4 also sets eor mask to $7f)

A2D_SET_PATTERN := $08
        ;; (input length 8 bytes)
        ;; .res 8 pattern       8x8 pixel pattern for A2D_FILL_RECT calls

A2D_SET_MSK := $09
        ;; (input length 2 bytes)
        ;; .byte mskand
        ;; .byte mskor

A2D_SET_THICKNESS := $0A
        ;; (input length 2 bytes)
        ;; .byte hthick         horizontal pen thickness
        ;; .byte vthick         vertical pen thickness

A2D_SET_FONT    := $0B
        ;; (input length 2 bytes)
        ;; .addr font           font definition (see below)

A2D_SET_TEXT_MASK := $0C        ; Stored to background before XORing glyph
        ;; (input length 1 byte)
        ;; .byte mask

A2D_OFFSET_POS    := $0D        ; Adjust start of subsequent DRAW_TEXT, DRAW_LINE
        ;; (input length 4 bytes)
        ;; .word xdelta
        ;; .word ydelta

A2D_SET_POS     := $0E          ; Start of subsequent DRAW_TEXT, DRAW_LINE
        ;; (input length 4 bytes)
        ;; .word xcoord
        ;; .word ycoord

A2D_DRAW_LINE   := $0F          ; Draw line (from SET_POS)
        ;; (input length 4 bytes)
        ;; .word xdelta         signed, delta in pixels
        ;; .word ydelta

A2D_DRAW_LINE_ABS := $10        ; Draw line (from SET_POS)
        ;; (input length 4 bytes)
        ;; .word xcoord         end coords in pixels
        ;; .word ycoord

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
        ;; .word hoff           offset within bitmap definition
        ;; .word voff
        ;; .word width          pixels
        ;; .word height         pixels

        ;; $15 used in DeskTop but not DAs - icon redraw
        ;; (input length 0 bytes)

A2D_DRAW_POLYGONS := $16       ; Draw multiple closed polygons
        ;; (input length 0 bytes)
        ;; Address points at struct:
        ;; .byte points         count
        ;; .byte flag           high bit clear if this is last polygon, set if not
        ;; .word x1, y1
        ;; .word x2, y2
        ;; ...

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

A2D_INIT_SCREEN_AND_MOUSE := $1D; Inits state, registers interrupt handler, draws desktop
        ;; (input length 12 byte)
        ;; ???

A2D_DISABLE_MOUSE  := $1E       ; Deallocates interrupt, hides cursor
        ;; (no parameters; pass $0000 as address)

A2D_HOOK_MOUSE := $20           ; Install mouse hook; A=0 on success, $95 if mouse disabled
        ;; NOTE: Doesn't set the internal flag - buggy ???
        ;; (input length 2 bytes)
        ;; (output length 2 bytes)
        ;; .addr hook           Mouse hook routine to install
        ;; .addr mouse_state    (out) Address of mouse state (.word x, y; .byte status)

A2D_GET_INT_HANDLER     := $23  ; Get address of interrupt handler
        ;; (input length 0)
        ;; (output length 2 bytes)
        ;; .addr handler        (out) Address of interrupt handler (after cld)

A2D_SET_CURSOR  := $24          ; Set cursor definition
        ;; (input not copied)
        ;; .res 24 bitmap       2x12 byte bitmap
        ;; .res 24 mask         2x12 byte mask
        ;; .byte hotx           hotspot coords
        ;; .byte hoty

A2D_SHOW_CURSOR := $25          ; Return cursor to visibility
        ;; (no parameters; pass $0000 as address)

A2D_HIDE_CURSOR := $26          ; Cursor hidden until A2D_SHOW_CURSOR call
        ;; (no parameters; pass $0000 as address)

A2D_ERASE_CURSOR := $27         ; Cursor hidden until moved or other A2D call
        ;; (no parameters; pass $0000 as address)

A2D_GET_CURSOR := $28           ; Get cursor definition
        ;; (input length 0 bytes)
        ;; (output length 2 bytes)
        ;; .addr definition     See A2D_SET_CURSOR

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

A2D_SET_KBD_FLAG   := $2E       ; When set, keyboard is ignored in $29 calls
        ;; (input length 1 byte)
        ;; .byte flag           high bit set = ignore keyboard, otherwise check

A2D_SET_MENU := $30             ; Configure (and draw) menu
        ;; (input not copied)
        ;; .word count          Number of top-level menus
        ;;
        ;; .word menu_id        Menu identifier
        ;; .addr label          Address of pascal (length-prefixed) string
        ;; .addr menu_defn      Address of menu definition
        ;; .word 0,0,0          (overwritten with ???, left edge, right edge)
        ;; ...
        ;;
        ;; Menu definitions are:
        ;; .word count          Number of items in menu

        ;; Menu items are:
        ;; .word 0,0            ???
        ;; .word has_shortcut   1 if has keyboard shortcuts, 0 otherwise
        ;; .byte shortcut1      ASCII code of shortcut #1 (e.g. uppercase B); or 0
        ;; .byte shortcut2      ASCII code of shortcut #2 (e.g. uppercase b, or same); or 0
        ;; .addr label          Address of pascal (length-prefixed) string
        ;; or for a separator:
        ;; .word $40, $13, $0

A2D_MENU_CLICK := $31           ; Enter modal loop for handling mouse-down on menu bar
        ;; (input not copied)
        ;; (output 2 bytes)
        ;; .byte menu_id        Top level menu identifier, or 0 if none
        ;; .byte item_num       Index (1-based) of item in menu, or 0 if none

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
        ;; .word hoff          pixels scrolled
        ;; .word voff
        ;; .word width          pixels
        ;; .word height
        ;; .res 8 pattern
        ;; .byte mskand         AND mask, default $FF
        ;; .byte mskor          ORA mask, default $00
        ;; .word xpos
        ;; .word ypos
        ;; .byte hthick
        ;; .byte vthick
        ;; .byte 0              ??? fill mode?
        ;; .byte tmask          AND mask for text, default $7F
        ;; .addr font           A2D_DEFAULT_FONT
        ;; .addr next           address of next lower window in stack (filled in by call)

A2D_DESTROY_WINDOW := $39
        ;; (input length 1 byte)
        ;; .byte id

A2D_QUERY_WINDOW := $3B         ; Get pointer to window params by id; A=0 on success
        ;; (input length 1 byte)
        ;; (output length 3 bytes)
        ;; .byte id             of window
        ;; .addr window         (out) window params

A2D_QUERY_STATE      := $3C     ; get drawing state of window
        ;; (input length 3 bytes)
        ;; .byte id             window
        ;; .addr state          state definition to populate, like A2D_SET_STATE

A2D_UPDATE_STATE     := $3D     ; Update drawing state by passed window id
        ;; ** Implementation appears buggy - or maybe just really cryptic ??? **
        ;; (input length 2 bytes)
        ;; .byte id             window
        ;; .byte ???


A2D_REDRAW_WINDOW := $3E        ; Draws window border, background, title bar, scroll bars
        ;; (input length 1 byte)
        ;; .byte id

A2D_QUERY_TARGET   := $40
        ;; (input length 4 bytes)
        ;; .word queryx         relative to screen
        ;; .word queryy
        ;; .byte element        (out) A2D_ELEM_*
        ;; .byte id             (out) of window

A2D_QUERY_TOP := $41            ; Get id of top window
        ;; (input length 0 bytes)
        ;; (output length 1 byte)
        ;; .byte id             (out) window, or 0 if none

A2D_RAISE_WINDOW   := $42       ; Make window topmost
        ;; (input length 1 byte)
        ;; .byte id             window

A2D_CLOSE_CLICK := $43
        ;; (input length 0 bytes)
        ;; .byte clicked        (out) 0 = cancelled, 1 = clicked
        ;; .byte ??             (out)
        ;; .byte ??             (out)

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
A2D_SCREEN_STRIDE   := $80      ; Stride in bytes

;;; Used in A2D_GET_INPUT
A2D_INPUT_NONE          := 0    ; No mouse or keypress
A2D_INPUT_DOWN          := 1    ; Mouse button was depressed
A2D_INPUT_UP            := 2    ; Mouse button was released
A2D_INPUT_KEY           := 3    ; Key was pressed
A2D_INPUT_HELD          := 4    ; Mouse button still down
A2D_INPUT_DOWN_MOD      := 5    ; Mouse button was depressed, modifier key down

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
A2D_DEFAULT_TMASK       := $7F

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
;;; Internals

        A2D_DEFAULT_FONT := $8800

        font_flag       := $8800 ; = $00 - if high bit set, glyphs are 2 bytes wide (???)
        font_size_count := $8801 ; = $7F - max glyph number (count is this + 1)
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
        A2D_GLYPH_CAPPLE := $1E

        ;; Relay for main>aux A2D call (Y=call, X,A=params addr)
.macro A2D_RELAY_CALL call, addr
        ldy     #(call)
        lda     #<(addr)
        ldx     #>(addr)
        jsr     desktop_A2D_RELAY
.endmacro
