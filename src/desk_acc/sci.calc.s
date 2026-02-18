;;; ============================================================
;;; SCI.CALC - Desk Accessory
;;;
;;; A scientific calculator.
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "calculator.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

.proc InitDA
        ;; Mostly use ZP preservation mode, since we use ROM FP routines.
        MGTK_CALL MGTK::SetZP1, setzp_params_preserve
        jmp     init
.endproc ; InitDA


.proc ExitDA
        MGTK_CALL MGTK::CloseWindow, closewindow_params
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        MGTK_CALL MGTK::SetZP1, setzp_params_nopreserve
        rts
.endproc ; ExitDA

;;; ============================================================
;;; Call Params (and other data)

.include "../lib/event_params.s"

.params trackgoaway_params
goaway:  .byte   0
.endparams

.params getwinport_params
window_id:     .byte   kDAWindowId
        .addr   grafport
.endparams

setzp_params_nopreserve:        ; performance over convenience
        .byte   MGTK::zp_overwrite

setzp_params_preserve:          ; convenience over performance
        .byte   MGTK::zp_preserve

;;; ============================================================
;;; Button Definitions

        kBasicOffset = 92

        kCalcButtonWidth = 17
        kCalcButtonHeight = 9
        kCalcButtonHSpacing = kCalcButtonWidth + 12
        kCalcButtonVSpacing = kCalcButtonHeight + 6

        kColALeft = 13
        kColBLeft = 58

        kCol1Left = 13 + kBasicOffset
        kCol1Right = kCol1Left+kCalcButtonWidth
        kCol2Left = kCol1Left + kCalcButtonHSpacing
        kCol2Right = kCol2Left+kCalcButtonWidth
        kCol3Left = kCol2Left + kCalcButtonHSpacing
        kCol3Right = kCol3Left+kCalcButtonWidth
        kCol4Left = kCol3Left + kCalcButtonHSpacing
        kCol4Right = kCol4Left+kCalcButtonWidth

        kRow0Top = 22 - 16

        kRow1Top = 22
        kRow1Bot = kRow1Top+kCalcButtonHeight
        kRow2Top = kRow1Top + kCalcButtonVSpacing
        kRow2Bot = kRow2Top+kCalcButtonHeight
        kRow3Top = kRow2Top + kCalcButtonVSpacing
        kRow3Bot = kRow3Top+kCalcButtonHeight
        kRow4Top = kRow3Top + kCalcButtonVSpacing
        kRow4Bot = kRow4Top+kCalcButtonHeight
        kRow5Top = kRow4Top + kCalcButtonVSpacing
        kRow5Bot = kRow5Top+kCalcButtonHeight

        kBorderLeftTop = 1          ; border width pixels (left/top)
        kBorderBottomRight = 2          ; (bottom/right)

kLabelStrSize = 4               ; for padding, so button structs are consistent size

.macro CALC_BUTTON identifier, func, labelstr, left, top, key_char
.params identifier
function:       .byte   func
key:            .byte   key_char
        .refto function
        .refto key
        DEFINE_POINT viewloc, left - kBorderLeftTop, top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kCalcButtonWidth + kBorderLeftTop + kBorderBottomRight, kCalcButtonHeight + kBorderLeftTop + kBorderBottomRight
        REF_MAPINFO_MEMBERS

label:          PASCAL_STRING labelstr, aux::kLabelStrSize
pos:            .word   left + 6, top+kCalcButtonHeight
port:           .word   left, top, left+kCalcButtonWidth, top+kCalcButtonHeight
        .refto label
        .refto pos
        .refto port
.endparams
.endmacro


kSciButtonWidth = 35
.macro CALC_BUTTON_S identifier, func, labelstr, left, top, opt_key
.params identifier
function:       .byte   func
key:
.if .paramcount >= 6
        .byte   opt_key
.elseif .strlen(labelstr) = 1
        .byte   labelstr
.else
        .byte   0
.endif
        .refto function
        .refto key
        ;; Cheap centering
        kLabelOff = (kSciButtonWidth - (6 * .strlen(labelstr))) / 2
        DEFINE_POINT viewloc, left - kBorderLeftTop, top - kBorderLeftTop
mapbits:        .addr   sci_button_bitmap
mapwidth:       .byte   kSciBitmapStride
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kSciButtonWidth, kCalcButtonHeight + kBorderLeftTop + kBorderBottomRight
        REF_MAPINFO_MEMBERS

label:          PASCAL_STRING labelstr, aux::kLabelStrSize
pos:            .word   left + kLabelOff, top+kCalcButtonHeight
port:           .word   left, top, left+kSciButtonWidth-3, top+kCalcButtonHeight
        .refto label
        .refto pos
        .refto port
.endparams
.endmacro

.enum Function
        ;; Reserve 0 for no match

        ;; Commands
        clear   = 1
        equals

        ;; Entry
        exp
        digit0 = '0'
        digit1 = '1'
        digit2 = '2'
        digit3 = '3'
        digit4 = '4'
        digit5 = '5'
        digit6 = '6'
        digit7 = '7'
        digit8 = '8'
        digit9 = '9'
        decimal = '.'

        ;; Operations
        op_multiply = '*'
        op_divide   = '/'
        op_add      = '+'
        op_subtract = '-'
        op_power    = $40

        ;; Functions
        fn_sin
        fn_cos
        fn_tan
        fn_asin
        fn_acos
        fn_atan
        fn_sqrt
        fn_neg
        fn_ln
        fn_exp
        fn_inv

.endenum

        first_button := *
        CALC_BUTTON btn_c,   Function::clear,       "c", kCol1Left, kRow1Top, 'C'
        CALC_BUTTON btn_e,   Function::exp,         "e", kCol2Left, kRow1Top, 'E'
        CALC_BUTTON btn_eq,  Function::equals,      "=", kCol3Left, kRow1Top, '='
        CALC_BUTTON btn_mul, Function::op_multiply, "*", kCol4Left, kRow1Top, '*'

        CALC_BUTTON btn_7,   Function::digit7,      "7", kCol1Left, kRow2Top, '7'
        CALC_BUTTON btn_8,   Function::digit8,      "8", kCol2Left, kRow2Top, '8'
        CALC_BUTTON btn_9,   Function::digit9,      "9", kCol3Left, kRow2Top, '9'
        CALC_BUTTON btn_div, Function::op_divide,   "/", kCol4Left, kRow2Top, '/'

        CALC_BUTTON btn_4,   Function::digit4,      "4", kCol1Left, kRow3Top, '4'
        CALC_BUTTON btn_5,   Function::digit5,      "5", kCol2Left, kRow3Top, '5'
        CALC_BUTTON btn_6,   Function::digit6,      "6", kCol3Left, kRow3Top, '6'
        CALC_BUTTON btn_sub, Function::op_subtract, "-", kCol4Left, kRow3Top, '-'

        CALC_BUTTON btn_1,   Function::digit1,      "1", kCol1Left, kRow4Top, '1'
        CALC_BUTTON btn_2,   Function::digit2,      "2", kCol2Left, kRow4Top, '2'
        CALC_BUTTON btn_3,   Function::digit3,      "3", kCol3Left, kRow4Top, '3'

.params btn_0
        left = kCol1Left
        top = kRow5Top
        kWideButtonWidth = 49
function:       .byte   Function::digit0
key:            .byte   "0"
        DEFINE_POINT viewloc, left - kBorderLeftTop, top - kBorderLeftTop
mapbits:        .addr   wide_button_bitmap
mapwidth:       .byte   kWideBitmapStride
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kWideButtonWidth, kCalcButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          PASCAL_STRING "0", aux::kLabelStrSize
pos:            .word   left + 6, top+kCalcButtonHeight
port:           .word   left, top, left+kWideButtonWidth-3, top+kCalcButtonHeight
.endparams

        CALC_BUTTON_S btn_sin,  Function::fn_sin,    "sin",  kColALeft, kRow0Top
        CALC_BUTTON_S btn_cos,  Function::fn_cos,    "cos",  kColALeft, kRow1Top
        CALC_BUTTON_S btn_tan,  Function::fn_tan,    "tan",  kColALeft, kRow2Top
        CALC_BUTTON_S btn_xy,   Function::op_power,  "x^y",  kColALeft, kRow3Top, '^'
        CALC_BUTTON_S btn_sqrt, Function::fn_sqrt,   "sqrt", kColALeft, kRow4Top
        CALC_BUTTON_S btn_pm,   Function::fn_neg,    "+/-",  kColALeft, kRow5Top

        CALC_BUTTON_S btn_asin, Function::fn_asin,   "asin", kColBLeft, kRow0Top
        CALC_BUTTON_S btn_acos, Function::fn_acos,   "acos", kColBLeft, kRow1Top
        CALC_BUTTON_S btn_atan, Function::fn_atan,   "atan", kColBLeft, kRow2Top
        CALC_BUTTON_S btn_ln,   Function::fn_ln,     "ln",   kColBLeft, kRow3Top
        CALC_BUTTON_S btn_ex,   Function::fn_exp,    "e^x",  kColBLeft, kRow4Top
        CALC_BUTTON_S btn_1x,   Function::fn_inv,    "1/x",  kColBLeft, kRow5Top

.params btn_dec
function:       .byte   Function::decimal
key:            .byte   SELF_MODIFIED_BYTE
        DEFINE_POINT viewloc, kCol3Left - kBorderLeftTop, kRow5Top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kCalcButtonWidth + kBorderLeftTop + kBorderBottomRight, kCalcButtonHeight + kBorderLeftTop + kBorderBottomRight
        REF_MAPINFO_MEMBERS
label:          PASCAL_STRING ".", aux::kLabelStrSize
pos:            .word   kCol3Left + 6 + 2, kRow5Bot ; + 2 to center the label
port:           .word   kCol3Left,kRow5Top,kCol3Right,kRow5Bot
        .refto label
        .refto pos
        .refto port
.endparams

.params btn_add
function:       .byte   Function::op_add
key:            .byte   '+'
        DEFINE_POINT viewloc, kCol4Left - kBorderLeftTop, kRow4Top - kBorderLeftTop
mapbits:        .addr   tall_button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kCalcButtonWidth + kBorderLeftTop + kBorderBottomRight, 27 ; + is extra tall
        REF_MAPINFO_MEMBERS

label:          PASCAL_STRING '+', aux::kLabelStrSize
pos:            .word   kCol4Left + 6, kRow5Bot
port:           .word   kCol4Left,kRow4Top,kCol4Right,kRow5Bot
        .refto label
        .refto pos
        .refto port
.endparams
        .byte   0               ; sentinel


        ASSERT_EQUALS .sizeof(btn_c), .sizeof(btn_0)
        ASSERT_EQUALS .sizeof(btn_c), .sizeof(btn_sin)
        ASSERT_EQUALS .sizeof(btn_c), .sizeof(btn_dec)
        ASSERT_EQUALS .sizeof(btn_c), .sizeof(btn_add)

        ;; Button bitmaps. These are used as bitmaps for
        ;; drawing the shadowed buttons.

        ;; bitmaps are low 7 bits, 0=black 1=white
        kBitmapStride   = 3    ; bytes
button_bitmap:                  ; bitmap for normal buttons
        PIXELS  "....................#"
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  "....................."
        PIXELS  "#...................."

        kWideBitmapStride = 8
wide_button_bitmap:             ; bitmap for '0' button
        PIXELS  ".................................................#######"
        PIXELS  ".###############################################..######"
        PIXELS  ".###############################################..######"
        PIXELS  ".###############################################..######"
        PIXELS  ".###############################################..######"
        PIXELS  ".###############################################..######"
        PIXELS  ".###############################################..######"
        PIXELS  ".###############################################..######"
        PIXELS  ".###############################################..######"
        PIXELS  ".###############################################..######"
        PIXELS  ".###############################################..######"
        PIXELS  "..................................................######"
        PIXELS  "#.................................................######"

        kSciBitmapStride = 6
sci_button_bitmap:              ; bitmap for scientific calc button
        PIXELS  "...................................#######"
        PIXELS  ".#################################..######"
        PIXELS  ".#################################..######"
        PIXELS  ".#################################..######"
        PIXELS  ".#################################..######"
        PIXELS  ".#################################..######"
        PIXELS  ".#################################..######"
        PIXELS  ".#################################..######"
        PIXELS  ".#################################..######"
        PIXELS  ".#################################..######"
        PIXELS  ".#################################..######"
        PIXELS  "....................................######"
        PIXELS  "#...................................######"

tall_button_bitmap:             ; bitmap for '+' button
        PIXELS  "....................#"
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  ".##################.."
        PIXELS  "....................."
        PIXELS  "#...................."


;;; ============================================================
;;; Calculation state

saved_stack:
        .byte   $00             ; restored after error
calc_p: .byte   $00             ; input since last clear?
calc_op:.byte   $00
calc_d: .byte   $00             ; decimal separator if present, 0 otherwise
calc_e: .byte   $00             ; exponent?
calc_n: .byte   $00             ; negative?
calc_g: .byte   $00             ; high bit set if last input digit
calc_f: .byte   $00             ; high bit set if last was function
calc_l: .byte   $00             ; input length

kMaxEntryLength = 10

;;; ============================================================
;;; Miscellaneous param blocks

.params background_box_params
left:   .word   1
top:    .word   0
right:  .word   259
bottom: .word   96
.endparams

background_pattern:
        .byte   $77,$DD,$77,$DD,$77,$DD,$77,$DD

black_pattern:
        .res    8, $00

white_pattern:
        .res    8, $FF

.params settextbg_params
backcolor:  .byte   $7F
.endparams

        kDisplayLeft    = 10 + kBasicOffset
        kDisplayTop     = 5
        kDisplayRight   = 120 + kBasicOffset
        kDisplayBottom  = 17

.params frame_display_params
left:   .word   kDisplayLeft
top:    .word   kDisplayTop
width:  .word   kDisplayRight
height: .word   kDisplayBottom
.endparams

.params clear_display_params
left:   .word   kDisplayLeft+1
top:    .word   kDisplayTop+1
width:  .word   kDisplayRight-1
height: .word   kDisplayBottom-1
.endparams

        ;; For drawing 1-character strings (button labels)
.params drawtext_params_label
        .addr   label
        .byte   1
.endparams
label:  .byte   0               ; modified with char to draw

.params drawtext_params1
textptr:        .addr   text_buffer1
textlen:        .byte   15
.endparams

kTextBufferSize = 14

text_buffer1:
        .res    kTextBufferSize+2, 0

.params drawtext_params2
textptr:        .addr   text_buffer2
textlen:        .byte   15
.endparams

text_buffer2:
        .res    kTextBufferSize+2, 0

spaces_string:
        PASCAL_STRING "          "
error_string:
        PASCAL_STRING res_string_error_string

.params textwidth_params
textptr:        .addr   text_buffer1
textlen:        .byte   15
result:         .word   0
.endparams

        kDAWindowId = $80

.params closewindow_params
window_id:     .byte   kDAWindowId
.endparams

.params text_pos_params3
left:   .word   0
base:   .word   16
.endparams

.params text_pos_params2
left:   .word   15 + kBasicOffset
base:   .word   16
.endparams

.params error_pos
left:   .word   69 + kBasicOffset
base:   .word   16
.endparams

farg:   .byte   $00,$00,$00,$00,$00,$00

grafport:       .tag    MGTK::GrafPort

penmode_normal: .byte   MGTK::pencopy
penmode_xor:    .byte   MGTK::notpenXOR

        kDAWidth = 130 + kBasicOffset
        kDAHeight = 96
        kDALeft         = (kScreenWidth - kDAWidth)/2
        kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

.params winfo
window_id:      .byte   kDAWindowId
options:        .byte   MGTK::Option::go_away_box
title:          .addr   window_title
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   0
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   kDAWidth
mincontheight:  .word   kDAHeight
maxcontwidth:   .word   kDAWidth
maxcontheight:  .word   kDAHeight
port:
        DEFINE_POINT viewloc, kDALeft, kDATop
        top := viewloc::ycoord
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDAWidth, kDAHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams
openwindow_params_top := winfo::top

window_title:
        PASCAL_STRING res_string_window_title

;;; ==================================================

.macro ROM_CALL addr
        jsr     ROMCall
        .addr   addr
.endmacro

;;; ==================================================
;;; Cached settings

intl_deci_sep:  .byte   0

;;; ==================================================
;;; DA Init

init:
        ;; Cache settings
        CALL    ReadSetting, X=#DeskTopSettings::intl_deci_sep
        sta     intl_deci_sep
        sta     btn_dec::key
        sta     btn_dec::label+1

        MGTK_CALL MGTK::OpenWindow, winfo
        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::FlushEvents

        jsr     ResetBuffer2

        jsr     DrawContent
        jsr     ResetBuffersAndDisplay

        copy8   #Function::equals, calc_op ; last kOperation

        lda     #0              ; clear registers
        sta     calc_p
        sta     calc_d
        sta     calc_e
        sta     calc_n
        sta     calc_g
        sta     calc_f
        sta     calc_l

.proc CopyToB1
        ldx     #sizeof_chrget_routine + 4 ; should be just + 1 ?
    DO
        copy8   chrget_routine-1,x, CHRGET-1,x
        dex
    WHILE NOT_ZERO
.endproc ; CopyToB1

        lda     #0
        sta     ERRFLG          ; Turn off errors
        sta     SHIFT_SIGN_EXT  ; Zero before using FP ops

        copy16  #ErrorHook, COUT_HOOK ; set up FP error handler

        ROM_CALL ZERO_FAC       ; FAC = 0
        ldxy    #farg
        ROM_CALL ROUND          ; `farg` = FAC

        tsx
        stx     saved_stack

        CALL    ProcessFunction, A=#Function::equals
        CALL    ProcessFunction, A=#Function::clear

;;; ============================================================
;;; Input Loop

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        MGTK_CALL MGTK::GetEvent, event_params

        lda     event_params::kind
    IF A = #MGTK::EventKind::button_down
        jsr     OnClick
        jmp     InputLoop
    END_IF

        cmp     #MGTK::EventKind::key_down
        bne     InputLoop

        jsr     OnKeyPress
        jmp     InputLoop
.endproc ; InputLoop

;;; ============================================================
;;; On Click

.proc OnClick
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        bcc     ret
        lda     findwindow_params::window_id
        cmp     #kDAWindowId      ; This window?
        bne     ret

        lda     findwindow_params::which_area
    IF A = #MGTK::Area::content ; Content area?
        jsr     MapClickToFunction
        beq     ret
        jmp     ProcessFunction
    END_IF

    IF A = #MGTK::Area::close_box ; Close box?
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway
        beq     ret
        pla                     ; pop OnClick
        pla
        jmp     ExitDA
    END_IF

    IF A = #MGTK::Area::dragbar ; Title bar?
        copy8   #kDAWindowId, dragwindow_params::window_id
        MGTK_CALL MGTK::DragWindow, dragwindow_params
        bit     dragwindow_params::moved
        bpl     ret

        ;; Redraw DeskTop's windows and icons
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES

        jsr     DrawContent
    END_IF

ret:    rts
.endproc ; OnClick

;;; ============================================================
;;; On Key Press

.proc OnKeyPress
        CALL    ToUpperCase, A=event_params::key

        ldx     event_params::modifiers
    IF NOT_ZERO
      IF A = #kShortcutCloseWindow
        pla                     ; pop OnKeyPress
        pla
        jmp     ExitDA
      END_IF
        rts
    END_IF

    IF A = #'.'                 ; allow either
        lda     intl_deci_sep
    END_IF

    IF A = #CHAR_ESCAPE
        lda     calc_p
      IF ZERO                   ; empty state?
        lda     calc_l
       IF ZERO
        pla                     ; pop OnKeyPress
        pla
        jmp     ExitDA
       END_IF
      END_IF
        TAIL_CALL ProcessFunction, A=#Function::clear
    END_IF

    IF A = #CHAR_DELETE
        ldy     calc_l
        beq     ret
      IF Y = #1
        jsr     ResetBuffer1AndState
        jmp     DisplayBuffer1
      END_IF

        dec     calc_l
        ldx     #0
        lda     text_buffer1 + kTextBufferSize
      IF A = intl_deci_sep
        stx     calc_d
      END_IF
      IF A = #'E'
        stx     calc_e
      END_IF
      IF A = #'-'
        stx     calc_n
      END_IF

        ldx     #kTextBufferSize-1
      DO
        lda     text_buffer1,x
        sta     text_buffer1+1,x
        sta     text_buffer2+1,x
        dex
        dey
      WHILE NOT_ZERO

        lda     #' '
        sta     text_buffer1+1,x
        sta     text_buffer2+1,x
        jmp     DisplayBuffer1
    END_IF

    IF A = #CHAR_CLEAR
        TAIL_CALL ProcessFunction, A=#Function::clear
    END_IF

    IF A = #CHAR_RETURN
        TAIL_CALL ProcessFunction, A=#Function::equals
    END_IF

        jsr     MapKeyToFunction
        jne     ProcessFunction

ret:    rts
.endproc ; OnKeyPress

;;; ============================================================
;;; Try to map a click to a button

;;; If a button was clicked, carry is set and accum has key char

.proc MapClickToFunction
        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        copy8   #MGTK::EventKind::button_down, event_params::kind ; Needed in `DepressButton`

        ptr := $06
        rect_ptr := $08

        copy16  #first_button, ptr
    REPEAT
        ldy     #0
        lda     (ptr),y
      IF NOT ZERO
        ;; Button's "port" is the inner inversion rect; test against
        ;; 1px beyond that, to match BTK. Make a copy and inflate it.
        add16_8 ptr, #(btn_c::port - btn_c), rect_ptr
        ldy     #.sizeof(MGTK::Rect)-1
       DO
        copy8   (rect_ptr),y, inrect_rect,y
        dey
       WHILE POS
        MGTK_CALL MGTK::InflateRect, grow_rect
        MGTK_CALL MGTK::InRect, inrect_rect
        beq     next

        ;; Return the function...
        ldy     #(btn_c::function - btn_c)
        lda     (ptr),y
        pha
        ;; ...but first flash the button
        CALL    DepressButton, AX=rect_ptr
        beq     ignore
        pla
      END_IF
        rts

ignore: pla
        RETURN  A=#0

next:   add16_8 ptr, #.sizeof(btn_c)
    FOREVER

        DEFINE_RECT inrect_rect, 0,0,0,0
.params grow_rect
        .addr   inrect_rect
        .word   1, 1
.endparams
.endproc ; MapClickToFunction

;;; ============================================================

.proc MapKeyToFunction
        sta     key

        ;; Buttons
        ptr := $06

        copy16  #first_button, ptr
    REPEAT
        ldy     #0
        lda     (ptr),y
      IF NOT ZERO
        ldy     #(btn_c::key - btn_c)
        lda     (ptr),y
        key := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     next

        ;; Return the function...
        ldy     #(btn_c::function - btn_c)
        lda     (ptr),y
        pha
        ;; ...but first flash the button
        add16_8 ptr, #btn_c::port - btn_c
        CALL    DepressButton, AX=ptr
        pla
      END_IF
        rts

next:   add16_8 ptr, #.sizeof(btn_c)
    FOREVER
.endproc ; MapKeyToFunction

;;; ============================================================
;;; Inputs: A = Function enum member

.proc ProcessFunction
    IF A = #Function::clear
        ROM_CALL ZERO_FAC       ; FAC = 0
        ldxy    #farg
        ROM_CALL ROUND          ; `farg` = FAC
        copy8   #Function::equals, calc_op
        lda     #0
        sta     calc_p
        sta     calc_l
        sta     calc_d
        sta     calc_e
        sta     calc_n
        jmp     ResetBuffersAndDisplay
    END_IF

    IF A = #Function::exp
        ldy     calc_e          ; already exponent?
      IF ZERO
        ldy     calc_l
       IF ZERO                  ; if no entry, make it "1E"
        inc     calc_l
        lda     #'1'
        sta     text_buffer1 + kTextBufferSize
        sta     text_buffer2 + kTextBufferSize
       END_IF
        copy8   #'E', calc_e
        jmp     _Insert
      END_IF
        rts
    END_IF

    IF A = #Function::op_subtract
        lda     calc_e          ; negate vs. subtract
      IF NOT_ZERO
        lda     calc_n
       IF ZERO
        SET_BIT7_FLAG calc_n
        pla
        pha
        jmp     _Insert
       END_IF
      END_IF

        TAIL_CALL DoOp, A=#Function::op_subtract
    END_IF

    IF A = #Function::decimal
        lda     calc_d          ; already a decimal?
        ora     calc_e          ; or exponent?
      IF ZERO
        lda     calc_l
       IF ZERO
        inc     calc_l
       END_IF
        copy8   intl_deci_sep, calc_d
        jmp     _Insert
      END_IF
        rts
    END_IF

        cmp     #Function::digit0
        bcc     DoOp
        cmp     #Function::digit9+1
        bcs     DoOp
        FALL_THROUGH_TO _Insert

        .assert Function::digit0 = '0', error, "Enum values"

.proc _Insert
        SET_BIT7_FLAG calc_g
        ldy     calc_l
    IF ZERO
        pha
        jsr     ResetBuffer2
        pla
      IF A = #'0'
        jmp     DisplayBuffer1
      END_IF
    END_IF

        SET_BIT7_FLAG calc_p
        cpy     #kMaxEntryLength
        bcs     ret
        pha
        ldy     calc_l
        beq     empty
        lda     #15
        sec
        sbc     calc_l
        tax
    DO
        lda     text_buffer1,x
        sta     text_buffer1-1,x
        sta     text_buffer2-1,x
        inx
        dey
    WHILE NOT_ZERO

empty:  inc     calc_l
        pla
        sta     text_buffer1 + kTextBufferSize
        sta     text_buffer2 + kTextBufferSize
        jmp     DisplayBuffer1

ret:   rts
.endproc ; _Insert

.endproc ; ProcessFunction

;;; ============================================================

;;; Inputs: A = operation invoked
.proc DoOp
        ;; Pending input we need to parse?
        pha
        lda     calc_g
    IF NOT_ZERO
        ;; Parse `text_buffer1` into FAC.
        ;; Copy string to `FBUFFR`, mapping decimal char.
        ldx     #kTextBufferSize
      DO
        lda     text_buffer1,x
       IF A = intl_deci_sep
        lda     #'.'
       END_IF
        sta     FBUFFR,x
        dex
      WHILE POS
        copy16  #FBUFFR, TXTPTR
        jsr     CHRGET
        ROM_CALL FIN
    END_IF
        pla

        ;; --------------------------------------------------
        ;; Function? These modify the FAC in place
    IF A = #Function::fn_sin
        jsr     DegToRad
        ROM_CALL SIN
        jmp     PostFunc
    END_IF

    IF A = #Function::fn_cos
        jsr     DegToRad
        ROM_CALL COS
        jmp     PostFunc
    END_IF

    IF A = #Function::fn_tan
        jsr     DegToRad
        ROM_CALL TAN
        jmp     PostFunc
    END_IF

    IF A = #Function::fn_asin
        ;; ASIN(x) = ATN(X/SQR(-X*X+1))
        ROM_CALL FAC_TO_ARG_R   ; ARG = X
        jsr     PushARG
        jsr     FixSGNCPR
        ROM_CALL FMULTT         ; FAC = X * X
        ROM_CALL NEGOP          ; FAC = -X*X
        lday    #CON_ONE
        ROM_CALL FADD           ; FAC = -X*X+1
        ROM_CALL SQR            ; FAC = SQR(-X*X+1)
        jsr     PopARG          ; ARG = X
        jsr     FixSGNCPR
        ROM_CALL FDIVT          ; FAC = X/SQR(-X*X+1)
        ROM_CALL ATN            ; FAC = ATN(X/SQR(-X*X+1))
        jsr     RadToDeg
        jmp     PostFunc
    END_IF

    IF A = #Function::fn_acos
        ;; ACOS(x) = -ATN(X/SQR(-X*X+l))+1.5708
        ROM_CALL FAC_TO_ARG_R   ; ARG = X
        jsr     PushARG
        jsr     FixSGNCPR
        ROM_CALL FMULTT         ; FAC = X * X
        ROM_CALL NEGOP          ; FAC = -X*X
        lday    #CON_ONE
        ROM_CALL FADD           ; FAC = -X*X+1
        ROM_CALL SQR            ; FAC = SQR(-X*X+1)
        jsr     PopARG          ; ARG = X
        jsr     FixSGNCPR
        ROM_CALL FDIVT          ; FAC = X/SQR(-X*X+1)
        ROM_CALL ATN            ; FAC = ATN(X/SQR(-X*X+1))
        ROM_CALL NEGOP          ; FAC = -ATN(X/SQR(-X*X+1))
        lday    #CON_HALF_PI    ;
        ROM_CALL FADD           ; FAC = -ATN(X/SQR(-X*X+1))+1.5708
        jsr     RadToDeg
        jmp     PostFunc
    END_IF

    IF A = #Function::fn_atan
        ROM_CALL ATN
        jsr     RadToDeg
        jmp     PostFunc
    END_IF

    IF A = #Function::fn_sqrt
        ROM_CALL SQR
        jmp     PostFunc
    END_IF

    IF A = #Function::fn_neg
        ROM_CALL NEGOP
        jmp     PostFunc
    END_IF

    IF A = #Function::fn_ln
        ROM_CALL LOG
        jmp     PostFunc
    END_IF

    IF A = #Function::fn_exp
        ROM_CALL EXP
        ;; TODO: This should be `PostFunc`
        jmp     PostOp
    END_IF

    IF A = #Function::fn_inv
        lday    #CON_ONE
        ROM_CALL FDIV
        jmp     PostFunc
    END_IF

        ;; --------------------------------------------------

        pha

        ;; Look at last operation
        lda     calc_op

    IF A = #Function::equals
        lda     calc_g          ; last input was a digit insertion or func?
        ora     calc_f
        bne     do_op           ; reparsed above, proceed

        lda     #0              ; otherwise, reset to 0
        ROM_CALL FLOAT
        jmp     do_op
    END_IF

        ;; Was last an input or function?
        lda     calc_g
        ora     calc_f
    IF ZERO
        ;; No, so last was an op, we're overriding it.
        ;; e.g.: 2 * +
        pla
        sta     calc_op
        jmp     ResetBuffer1AndState
    END_IF

        ;; --------------------------------------------------
        ;; Operators

do_op:
        pla                     ; A = current op
        ldx     calc_op         ; X = previous op
        sta     calc_op         ; save for later
        lday    #farg           ; A,Y = previous intermediate result

    IF X = #Function::op_add
        ROM_CALL FADD           ; FAC = (Y,A) + FAC
    ELSE_IF X = #Function::op_subtract
        ROM_CALL FSUB           ; FAC = (Y,A) - FAC
    ELSE_IF X = #Function::op_multiply
        ROM_CALL FMULT          ; FAC = (Y,A) * FAC
    ELSE_IF X = #Function::op_divide
        ROM_CALL FDIV           ; FAC = (Y,A) / FAC
    ELSE_IF X = #Function::op_power
        ROM_CALL LOAD_ARG       ; ARG = (Y,A)
        ROM_CALL FPWRT          ; FAC = ARG ^ FAC
    ELSE_IF X = #Function::equals
        ldy     calc_f
      IF ZERO
        ldy     calc_g
       IF ZERO
        jmp     ResetBuffer1AndState
       END_IF
      END_IF
    END_IF

        FALL_THROUGH_TO PostOp
.endproc ; DoOp

;;; ============================================================

.proc PostOp
        copy8   #0, calc_f

        ldxy    #farg           ; save intermediate result
        ROM_CALL ROUND          ; (Y,A) = ROUND(FAC)

ep2:    jsr     PushFAC
        ROM_CALL FOUT       ; output as null-terminated string to FBUFFR
        jsr     PopFAC

        ldy     #0              ; count the size
    DO
        lda     FBUFFR,y
        BREAK_IF ZERO
        iny
    WHILE NOT_ZERO

        ldx     #kTextBufferSize ; copy to text buffers
    DO
        lda     FBUFFR-1,y
      IF A = #'.'               ; map decimal character
        lda     intl_deci_sep
      END_IF
        sta     text_buffer1,x
        sta     text_buffer2,x
        dex
        dey
    WHILE NOT_ZERO

        ;; Add leading zero if starting with decimal
    IF A = #'-'
        ;; skip leading '-' temporarily
        inx
        jsr     MaybeAddLeadingZero
        lda     #'-'
        sta     text_buffer1,x
        sta     text_buffer2,x
        dex
    ELSE
        jsr     MaybeAddLeadingZero
    END_IF

        cpx     #0              ; pad out with spaces if needed
    IF POS
      DO
        lda     #' '
        sta     text_buffer1,x
        sta     text_buffer2,x
        dex
      WHILE POS
    END_IF

        jsr     DisplayBuffer1

        FALL_THROUGH_TO ResetBuffer1AndState
.endproc ; PostOp

.proc ResetBuffer1AndState
        jsr     ResetBuffer1
        lda     #0
        sta     calc_l
        sta     calc_d
        sta     calc_e
        sta     calc_n
        sta     calc_g
        sta     calc_f
        rts
.endproc ; ResetBuffer1AndState

.proc MaybeAddLeadingZero
        lda     text_buffer1+1,x
    IF A = intl_deci_sep
        lda     #'0'
        sta     text_buffer1,x
        sta     text_buffer2,x
        dex
    END_IF
        rts
.endproc ; MaybeAddLeadingZero

;;; After a function (e.g. SIN, COS, etc) is done, we must leave
;;; the FAC alone but we do need to update the display and set
;;; a flag indicating we shouldn't override the pending op.
.proc PostFunc
        jsr     PostOp::ep2
        SET_BIT7_FLAG calc_f
        rts
.endproc ; PostFunc

;;; ============================================================

kRegSize = 6

.proc PushFAC
        pla
        sta     lo
        pla
        sta     hi

        PUSH_BYTES kRegSize, FAC

        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha

        rts
.endproc ; PushFAC

.proc PopFAC
        pla
        sta     lo
        pla
        sta     hi

        POP_BYTES kRegSize, FAC

        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha

        rts
.endproc ; PopFAC

.proc PushARG
        pla
        sta     lo
        pla
        sta     hi

        PUSH_BYTES kRegSize, ARG

        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha

        rts
.endproc ; PushARG

.proc PopARG
        pla
        sta     lo
        pla
        sta     hi

        POP_BYTES kRegSize, ARG

        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha

        rts
.endproc ; PopARG

;;; ============================================================

;;; Convert FAC from degrees to radians
.proc DegToRad
        ;; R = D / 90 * (PI/2)
        ROM_CALL FAC_TO_ARG_R   ; ARG = D
        lda     #90
        ROM_CALL FLOAT          ; FAC = 90
        jsr     FixSGNCPR
        ROM_CALL FDIVT          ; FAC = D / 90
        lday    #CON_HALF_PI
        ROM_CALL FMULT          ; FAC = (D / 90) * (PI/2)
        rts
.endproc ; DegToRad

;;; Convert FAC from radians to degrees
.proc RadToDeg
        ;; D = R * 90 / (PI/2)
        ROM_CALL FAC_TO_ARG_R   ; ARG = R
        lda     #90
        ROM_CALL FLOAT          ; FAC = 90
        jsr     FixSGNCPR
        ROM_CALL FMULTT         ; FAC = R * 90
        ROM_CALL FAC_TO_ARG_R   ; ARG = R * 90
        lday    #CON_HALF_PI
        ROM_CALL LOAD_FAC       ; FAC = PI/2
        jsr     FixSGNCPR
        ROM_CALL FDIVT          ; FAC = (R * 90) / (PI/2)
        rts
.endproc ; RadToDeg

;;; Needed before FMULTT / FDIVT
.proc FixSGNCPR
        lda     FAC_SIGN
        eor     ARG_SIGN
        sta     SGNCPR          ; compared sign for mul/div

        ;; Like `LOAD.ARG.FROM.YA`
        lda     FAC             ; set status bits on FAC exponent

        rts
.endproc ; FixSGNCPR

;;; ============================================================

;;; Input: A,X = button rectangle; `event_params` must be valid
.proc DepressButton
        stax    invert_addr

        ;; The passed rect is the inner inversion rect; test against
        ;; 1px beyond that, to match BTK. Make a copy and inflate it.
        ptr := $06
        stax    ptr
        ldy     #.sizeof(MGTK::Rect)-1
    DO
        copy8   (ptr),y, inrect_rect,y
        dey
    WHILE POS
        MGTK_CALL MGTK::InflateRect, grow_rect

        ;; --------------------------------------------------
        ;; Keyboard?
        lda     event_params::kind
    IF A = #MGTK::EventKind::key_down

        ;; Match delay in BTK::Flash
        jsr     invert_rect
        ldx     #5
      DO
        txa
        pha
        MGTK_CALL MGTK::WaitVBL
        pla
        tax
        dex
      WHILE NOT ZERO
        jmp     invert_rect

    END_IF

        ;; --------------------------------------------------
        ;; Mouse

        button_state := $10
        SET_BIT7_FLAG button_state

invert: jsr     invert_rect

check_button:
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::drag ; Button down?
        bne     done            ; Nope, done immediately

        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, inrect_rect
        bne     inside

        lda     button_state    ; outside, not down
        beq     check_button    ; so keep looping

        lda     #0              ; outside, was down
        sta     button_state    ; so set up
        beq     invert          ; and show it

inside: lda     button_state    ; inside, and down
        bne     check_button    ; so keep looking

        SET_BIT7_FLAG button_state ; inside, was not down so set down
        jmp     invert          ; and show it

done:   lda     button_state    ; high bit set if button down
        pha
    IF NOT_ZERO
        jsr     invert_rect     ; Back to normal
    END_IF
        pla
        rts

invert_rect:
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        RTS_IF  A = #MGTK::Error::window_obscured
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::SetPattern, black_pattern
        MGTK_CALL MGTK::SetPenMode, penmode_xor
        MGTK_CALL MGTK::PaintRect, SELF_MODIFIED, invert_addr
        rts

        DEFINE_RECT inrect_rect, 0,0,0,0
.params grow_rect
        .addr   inrect_rect
        .word   1, 1
.endparams
.endproc ; DepressButton

;;; ============================================================
;;; Value Display

.proc ResetBuffer1
        ldy     #kTextBufferSize
    DO
        copy8   #' ', text_buffer1-1,y
        dey
    WHILE NOT_ZERO
        copy8   #'0', text_buffer1 + kTextBufferSize
        rts
.endproc ; ResetBuffer1

.proc ResetBuffer2
        ldy     #kTextBufferSize
    DO
        copy8   #' ', text_buffer2-1,y
        dey
    WHILE NOT_ZERO
        copy8   #'0', text_buffer2 + kTextBufferSize
        rts
.endproc ; ResetBuffer2

.proc ResetBuffersAndDisplay
        jsr     ResetBuffer1
        jsr     ResetBuffer2
        FALL_THROUGH_TO DisplayBuffer1
.endproc ; ResetBuffersAndDisplay

.proc DisplayBuffer1
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        cmp     #MGTK::Error::window_obscured
        beq     end
        MGTK_CALL MGTK::SetPort, grafport
        CALL    PreDisplayBuffer, XY=#text_buffer1
        MGTK_CALL MGTK::DrawText, drawtext_params1
end:    rts
.endproc ; DisplayBuffer1

.proc DisplayBuffer2
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        cmp     #MGTK::Error::window_obscured
        beq     end
        MGTK_CALL MGTK::SetPort, grafport
        CALL    PreDisplayBuffer, XY=#text_buffer2
        MGTK_CALL MGTK::DrawText, drawtext_params2
end:    rts
.endproc ; DisplayBuffer2

.proc PreDisplayBuffer
        stx     textwidth_params::textptr ; text buffer address in x,y
        sty     textwidth_params::textptr+1
        MGTK_CALL MGTK::TextWidth, textwidth_params
        lda     #kDisplayRight-15 ; ???
        sec
        sbc     textwidth_params::result
        sta     text_pos_params3::left
        MGTK_CALL MGTK::MoveTo, text_pos_params2 ; clear with spaces
        MGTK_CALL MGTK::DrawString, spaces_string
        MGTK_CALL MGTK::MoveTo, text_pos_params3 ; set up for display
        rts
.endproc ; PreDisplayBuffer

;;; ============================================================
;;; Draw the window contents (background, buttons)

.proc DrawContent
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        RTS_IF A = #MGTK::Error::window_obscured

        MGTK_CALL MGTK::SetPort, grafport

        ;; Frame
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::SetPattern, background_pattern
        MGTK_CALL MGTK::PaintRect, background_box_params
        MGTK_CALL MGTK::SetPattern, black_pattern
        MGTK_CALL MGTK::FrameRect, frame_display_params
        MGTK_CALL MGTK::SetPattern, white_pattern
        MGTK_CALL MGTK::PaintRect, clear_display_params
        MGTK_CALL MGTK::SetTextBG, settextbg_params

        ;; Buttons
        ptr := $06

        copy16  #first_button, ptr
    REPEAT
        ldy     #0
        lda     (ptr),y
        BREAK_IF ZERO

        add16_8 ptr, #(btn_c::viewloc - btn_c), bitmap_addr
        add16_8 ptr, #(btn_c::pos - btn_c), text_addr
        add16_8 ptr, #(btn_c::label - btn_c), label

        MGTK_CALL MGTK::PaintBits, 0, bitmap_addr ; draw shadowed rect
        MGTK_CALL MGTK::MoveTo, 0, text_addr         ; button label pos
        MGTK_CALL MGTK::DrawString, 0, label

        add16_8 ptr, #.sizeof(btn_c)
    FOREVER

        jsr     DisplayBuffer2

        MGTK_CALL MGTK::ShowCursor

        rts

.endproc ; DrawContent

;;; ============================================================

        ;; Traps FP error via call to $36 from MON.COUT, resets stack
        ;; and returns to the input loop.
.proc ErrorHook
        bit     LCBANK1
        bit     LCBANK1
        jsr     ResetBuffersAndDisplay

        MGTK_CALL MGTK::GetWinPort, getwinport_params
    IF A <> #MGTK::Error::window_obscured
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::MoveTo, error_pos
        MGTK_CALL MGTK::DrawString, error_string
    END_IF

        jsr     ResetBuffer1AndState
        copy8   #Function::equals, calc_op
        ldx     saved_stack
        txs
        jmp     InputLoop
.endproc ; ErrorHook

PROC_AT chrget_routine, ::CHRGET
        dummy_addr := $EA60

    DO
        inc16   TXTPTR

        .assert * + 1 = TXTPTR, error, "misaligned routine"
        lda     dummy_addr      ; this ends up being aligned on TXTPTR

        cmp     #'9'+1          ; after digits?
        bcs     end
    WHILE A = #' '              ; space? keep going

        sec
        sbc     #'0'            ; convert to digit...
        sec
        sbc     #$D0            ; carry set if successful
end:    rts
END_PROC_AT
        sizeof_chrget_routine = .sizeof(chrget_routine)

;;; ============================================================

        .include "../lib/uppercase.s"
        .include "../lib/rom_call.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT

        JSR_TO_AUX aux::InitDA
        rts

        DA_END_MAIN_SEGMENT

;;; ============================================================
