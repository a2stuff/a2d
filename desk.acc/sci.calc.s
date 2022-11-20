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

        MGTKEntry := MGTKAuxEntry

;;; ============================================================

        .org DA_LOAD_ADDRESS

;;; ============================================================
;;; Start of the code

start:  jmp     Copy2Aux

save_stack:  .byte   0

;;; ============================================================
;;; Duplicate the DA (code and data) to AUX memory,
;;; then invoke the code in AUX.

.proc Copy2Aux
        lda     SETTINGS + DeskTopSettings::intl_deci_sep
        sta     btn_dec_key
        sta     btn_dec_label

        tsx
        stx     save_stack

        ;; Copy the DA to AUX memory.
        copy16  #start, STARTLO
        copy16  #da_end, ENDLO
        copy16  #start, DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE

        FALL_THROUGH_TO InitDA
.endproc

;;; ============================================================

.proc InitDA
        ;; Run DA from Aux
        sta     RAMRDON
        sta     RAMWRTON

        ;; Mostly use ZP preservation mode, since we use ROM FP routines.
        MGTK_CALL MGTK::SetZP1, setzp_params_preserve

        jmp     init
.endproc


.proc ExitDA
        MGTK_CALL MGTK::SetZP1, setzp_params_nopreserve

        ;; Return to DeskTop running in Main
        sta     RAMRDOFF
        sta     RAMWRTOFF

        ldx     save_stack
        txs
        rts
.endproc

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
        getwinport_params_window_id := getwinport_params::window_id

setzp_params_nopreserve:        ; performance over convenience
        .byte   MGTK::zp_overwrite

setzp_params_preserve:          ; convenience over performance
        .byte   MGTK::zp_preserve

;;; ============================================================
;;; Button Definitions

        kBasicOffset = 92

        kCalcButtonWidth = 17
        kCalcButtonHeight = 9

        kColALeft = 13
        kColBLeft = 58

        kCol1Left = 13 + kBasicOffset
        kCol1Right = kCol1Left+kCalcButtonWidth ; 30
        kCol2Left = 42 + kBasicOffset
        kCol2Right = kCol2Left+kCalcButtonWidth ; 59
        kCol3Left = 70 + kBasicOffset
        kCol3Right = kCol3Left+kCalcButtonWidth ; 87
        kCol4Left = 98 + kBasicOffset
        kCol4Right = kCol4Left+kCalcButtonWidth ; 115

        kRow0Top = 22 - 16

        kRow1Top = 22
        kRow1Bot = kRow1Top+kCalcButtonHeight ; 31
        kRow2Top = 38
        kRow2Bot = kRow2Top+kCalcButtonHeight ; 47
        kRow3Top = 53
        kRow3Bot = kRow3Top+kCalcButtonHeight ; 62
        kRow4Top = 68
        kRow4Bot = kRow4Top+kCalcButtonHeight ; 77
        kRow5Top = 83
        kRow5Bot = kRow5Top+kCalcButtonHeight ; 92

        kBorderLeftTop = 1          ; border width pixels (left/top)
        kBorderBottomRight = 2          ; (bottom/right)

kLabelStrSize = 4               ; for padding, so button structs are consistent size

.macro CALC_BUTTON identifier, func, labelstr, left, top
.params identifier
function:       .byte   func
key:
.if .strlen(labelstr) = 1
                .byte   labelstr
.else
                .byte   0
.endif
        DEFINE_POINT viewloc, left - kBorderLeftTop, top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kCalcButtonWidth + kBorderLeftTop + kBorderBottomRight, kCalcButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          PASCAL_STRING labelstr, ::kLabelStrSize
pos:            .word   left + 6, top+kCalcButtonHeight
port:           .word   left, top, left+kCalcButtonWidth, top+kCalcButtonHeight
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
        ;; Cheap centering
        kLabelOff = (kSciButtonWidth - (6 * .strlen(labelstr))) / 2
        DEFINE_POINT viewloc, left - kBorderLeftTop, top - kBorderLeftTop
mapbits:        .addr   sci_button_bitmap
mapwidth:       .byte   kSciBitmapStride
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kSciButtonWidth, kCalcButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          PASCAL_STRING labelstr, ::kLabelStrSize
pos:            .word   left + kLabelOff, top+kCalcButtonHeight
port:           .word   left, top, left+kSciButtonWidth-3, top+kCalcButtonHeight
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
        CALC_BUTTON btn_c,   Function::clear,    "c", kCol1Left, kRow1Top
        CALC_BUTTON btn_e,   Function::exp,      "e", kCol2Left, kRow1Top
        CALC_BUTTON btn_eq,  Function::equals,   "=", kCol3Left, kRow1Top
        CALC_BUTTON btn_mul, Function::op_multiply, "*", kCol4Left, kRow1Top

        CALC_BUTTON btn_7,   Function::digit7, "7", kCol1Left, kRow2Top
        CALC_BUTTON btn_8,   Function::digit8, "8", kCol2Left, kRow2Top
        CALC_BUTTON btn_9,   Function::digit9, "9", kCol3Left, kRow2Top
        CALC_BUTTON btn_div, Function::op_divide, "/", kCol4Left, kRow2Top

        CALC_BUTTON btn_4,   Function::digit4, "4", kCol1Left, kRow3Top
        CALC_BUTTON btn_5,   Function::digit5, "5", kCol2Left, kRow3Top
        CALC_BUTTON btn_6,   Function::digit6, "6", kCol3Left, kRow3Top
        CALC_BUTTON btn_sub, Function::op_subtract, "-", kCol4Left, kRow3Top

        CALC_BUTTON btn_1,   Function::digit1, "1", kCol1Left, kRow4Top
        CALC_BUTTON btn_2,   Function::digit2, "2", kCol2Left, kRow4Top
        CALC_BUTTON btn_3,   Function::digit3, "3", kCol3Left, kRow4Top

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
label:          PASCAL_STRING "0", ::kLabelStrSize
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
        CALC_BUTTON_S btn_ln,   Function::fn_ln,     "ln",  kColBLeft, kRow3Top
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
label:          PASCAL_STRING ".", ::kLabelStrSize
pos:            .word   kCol3Left + 6 + 2, kRow5Bot ; + 2 to center the label
port:           .word   kCol3Left,kRow5Top,kCol3Right,kRow5Bot
.endparams
btn_dec_key   := btn_dec::key
btn_dec_label := btn_dec::label+1


.params btn_add
function:       .byte   Function::op_add
key:            .byte   '+'
        DEFINE_POINT viewloc, kCol4Left - kBorderLeftTop, kRow4Top - kBorderLeftTop
mapbits:        .addr   tall_button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kCalcButtonWidth + kBorderLeftTop + kBorderBottomRight, 27 ; + is extra tall
label:          PASCAL_STRING '+', ::kLabelStrSize
pos:            .word   kCol4Left + 6, kRow5Bot
port:           .word   kCol4Left,kRow4Top,kCol4Right,kRow5Bot
.endparams
        .byte   0               ; sentinel


        .assert .sizeof(btn_c) = .sizeof(btn_0),   error, "Size mismatch"
        .assert .sizeof(btn_c) = .sizeof(btn_sin), error, "Size mismatch"
        .assert .sizeof(btn_c) = .sizeof(btn_dec), error, "Size mismatch"
        .assert .sizeof(btn_c) = .sizeof(btn_add), error, "Size mismatch"

        ;; Button bitmaps. These are used as bitmaps for
        ;; drawing the shadowed buttons.

        ;; bitmaps are low 7 bits, 0=black 1=white
        kBitmapStride   = 3    ; bytes
button_bitmap:                  ; bitmap for normal buttons
        .byte   PX(%0000000),PX(%0000000),PX(%0000001)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%1000000),PX(%0000000),PX(%0000000)

        kWideBitmapStride = 8
wide_button_bitmap:             ; bitmap for '0' button
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111)
        .byte   PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111)

        kSciBitmapStride = 6
sci_button_bitmap:              ; bitmap for scientific calc button
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111)
        .byte   PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111)

tall_button_bitmap:             ; bitmap for '+' button
        .byte   PX(%0000000),PX(%0000000),PX(%0000001)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%1000000),PX(%0000000),PX(%0000000)


;;; ============================================================
;;; Calculation state

saved_stack:
        .byte   $00             ; restored after error
calc_p: .byte   $00             ; high bit set if pending op?
calc_op:.byte   $00
calc_d: .byte   $00             ; decimal separator if present, 0 otherwise
calc_e: .byte   $00             ; exponential?
calc_n: .byte   $00             ; negative?
calc_g: .byte   $00             ; high bit set if last input digit
calc_f: .byte   $00             ; high bit set if last was function
calc_l: .byte   $00             ; input length

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

        kDAWindowId = 52

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

.params penmode_normal
penmode:   .byte   MGTK::pencopy
.endparams

.params penmode_xor
penmode:   .byte   MGTK::notpenXOR
.endparams

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
mincontlength:  .word   kDAHeight
maxcontwidth:   .word   kDAWidth
maxcontlength:  .word   kDAHeight
left:           .word   kDALeft
top:            .word   kDATop
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
textback:       .byte   $7f
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
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
;;; DA Init

init:   MGTK_CALL MGTK::OpenWindow, winfo
        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::FlushEvents

        jsr     ResetBuffer2

        jsr     DrawContent
        jsr     ResetBuffersAndDisplay

        lda     #Function::equals ; last kOperation
        sta     calc_op

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
loop:   lda     chrget_routine-1,x
        sta     CHRGET-1,x
        dex
        bne     loop
.endproc

        lda     #0
        sta     ERRFLG          ; Turn off errors
        sta     SHIFT_SIGN_EXT  ; Zero before using FP ops

        copy16  #ErrorHook, COUT_HOOK ; set up FP error handler

        lda     #1
        ROM_CALL FLOAT
        ldxy    #farg
        ROM_CALL ROUND
        lda     #0              ; set FAC to 0
        ROM_CALL FLOAT
        ROM_CALL FADD
        ROM_CALL FOUT
        lda     #$07
        ROM_CALL FMULT
        lda     #$00
        ROM_CALL FLOAT
        ldxy    #farg
        ROM_CALL ROUND

        tsx
        stx     saved_stack

        lda     #Function::equals
        jsr     ProcessFunction
        lda     #Function::clear
        jsr     ProcessFunction


;;; ============================================================
;;; Input Loop

.proc InputLoop
        param_call JTRelay, JUMP_TABLE_YIELD_LOOP
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jsr     OnClick
        jmp     InputLoop

:       cmp     #MGTK::EventKind::key_down
        bne     InputLoop
        jsr     OnKeyPress
        jmp     InputLoop
.endproc

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
        cmp     #MGTK::Area::content ; Content area?
    IF_EQ
        jsr     MapClickToFunction
        beq     ret
        jmp     ProcessFunction
    END_IF

        cmp     #MGTK::Area::close_box ; Close box?
    IF_EQ
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway
        beq     ret
        MGTK_CALL MGTK::CloseWindow, closewindow_params
        param_call JTRelay, JUMP_TABLE_CLEAR_UPDATES
        jmp     ExitDA
    END_IF

        cmp     #MGTK::Area::dragbar ; Title bar?
    IF_EQ
        copy    #kDAWindowId, dragwindow_params::window_id
        MGTK_CALL MGTK::DragWindow, dragwindow_params

        ;; Redraw DeskTop's windows and icons
        param_call JTRelay, JUMP_TABLE_CLEAR_UPDATES

        jsr     DrawContent
    END_IF

ret:    rts
.endproc

;;; ============================================================
;;; On Key Press

.proc OnKeyPress
        lda     event_params::modifiers
        beq     :+
        rts
:

        lda     event_params::key
        ;; To lowercase
        cmp     #'A'
        bcc     :+
        cmp     #'Z'+1
        bcs     :+
        ora     #AS_BYTE(~CASE_MASK)
:
        cmp     #'.'            ; allow either
        bne     :+
        lda     SETTINGS + DeskTopSettings::intl_deci_sep
:
        cmp     #CHAR_ESCAPE
    IF_EQ
        lda     calc_p
        bne     :+           ; empty state?
        lda     calc_l
      IF_ZERO
        MGTK_CALL MGTK::CloseWindow, closewindow_params
        jmp     ExitDA
      END_IF
:       lda     #Function::clear
        jmp     ProcessFunction
    END_IF

        cmp     #CHAR_DELETE
    IF_EQ
        ldy     calc_l
        beq     ret
        cpy     #1
        bne     :+
        jsr     ResetBuffer1AndState
        jmp     DisplayBuffer1

:       dec     calc_l
        ldx     #0
        lda     text_buffer1 + kTextBufferSize
        cmp     SETTINGS + DeskTopSettings::intl_deci_sep
        bne     :+
        stx     calc_d
:       cmp     #'E'
        bne     :+
        stx     calc_e
:       cmp     #'-'
        bne     :+
        stx     calc_n
:       ldx     #kTextBufferSize-1
loop:   lda     text_buffer1,x
        sta     text_buffer1+1,x
        sta     text_buffer2+1,x
        dex
        dey
        bne     loop
        lda     #' '
        sta     text_buffer1+1,x
        sta     text_buffer2+1,x
        jmp     DisplayBuffer1
    END_IF

        cmp     #CHAR_CLEAR
    IF_EQ
        lda     #Function::clear
        jmp     ProcessFunction
    END_IF

        cmp     #CHAR_RETURN
    IF_EQ
        lda     #Function::equals
        jmp     ProcessFunction
    END_IF

        jsr     MapKeyToFunction
        jne     ProcessFunction

ret:    rts
.endproc

;;; ============================================================
;;; Try to map a click to a button

;;; If a button was clicked, carry is set and accum has key char

.proc MapClickToFunction
        lda     #kDAWindowId
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        ptr := $FA

        copy16  #first_button, ptr
loop:   ldy     #0
        lda     (ptr),y
        beq     ret

        add16_8 ptr, #(btn_c::port - btn_c), rect
        MGTK_CALL MGTK::InRect, 0, rect
        beq     next

        ;; Return the function...
        ldy     #(btn_c::function - btn_c)
        lda     (ptr),y
        pha
        ;; ...but first flash the button
        ldax    rect
        jsr     DepressButton
        beq     ignore
        pla
ret:    rts

ignore: pla
        lda     #0
        rts

next:   add16_8 ptr, #.sizeof(btn_c)
        jmp     loop
.endproc

;;; ============================================================

.proc MapKeyToFunction
        sta     key

        ;; Buttons
        ptr := $FA

        copy16  #first_button, ptr
loop:   ldy     #0
        lda     (ptr),y
        beq     ret

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
        ldax    ptr
        jsr     DepressButton
        pla

ret:    rts

next:   add16_8 ptr, #.sizeof(btn_c)
        jmp     loop
.endproc


;;; ============================================================
;;; Inputs: A = Function enum member

.proc ProcessFunction
        cmp     #Function::clear
    IF_EQ
        lda     #0
        ROM_CALL FLOAT
        ldxy    #farg
        ROM_CALL ROUND
        lda     #Function::equals
        sta     calc_op
        lda     #0
        sta     calc_p
        sta     calc_l
        sta     calc_d
        sta     calc_e
        sta     calc_n
        jmp     ResetBuffersAndDisplay
    END_IF

        cmp     #Function::exp
    IF_EQ
        ldy     calc_e
        bne     ret
        ldy     calc_l
        bne     :+
        inc     calc_l
        lda     #'1'
        sta     text_buffer1 + kTextBufferSize
        sta     text_buffer2 + kTextBufferSize
:       lda     #'E'
        sta     calc_e
        jmp     Insert
ret:    rts
    END_IF

        cmp     #Function::op_subtract
    IF_EQ
        lda     calc_e          ; negate vs. subtract
        beq     :+
        lda     calc_n
        bne     :+
        sec
        ror     calc_n
        pla
        pha
        jmp     Insert
:       lda     #Function::op_subtract
        jmp     DoOp
    END_IF

        cmp     #Function::decimal
    IF_EQ
        lda     calc_d
        ora     calc_e
        bne     ret
        lda     calc_l
        bne     :+
        inc     calc_l
:       lda     SETTINGS + DeskTopSettings::intl_deci_sep
        sta     calc_d
        jmp     Insert

ret:    rts
    END_IF

        cmp     #Function::digit0
        bcc     DoOp
        cmp     #Function::digit9+1
        bcs     DoOp

        .assert Function::digit0 = '0', error, "Enum values"

Insert: sec
        ror     calc_g
        ldy     calc_l
        bne     :+
        pha
        jsr     ResetBuffer2
        pla
        cmp     #'0'
        bne     :+
        jmp     DisplayBuffer1

:       sec
        ror     calc_p
        cpy     #10
        bcs     ret
        pha
        ldy     calc_l
        beq     empty
        lda     #15
        sec
        sbc     calc_l
        tax
:       lda     text_buffer1,x
        sta     text_buffer1-1,x
        sta     text_buffer2-1,x
        inx
        dey
        bne     :-
empty:  inc     calc_l
        pla
        sta     text_buffer1 + kTextBufferSize
        sta     text_buffer2 + kTextBufferSize
        jmp     DisplayBuffer1

ret:   rts
.endproc

;;; ============================================================

;;; Inputs: A = operation invoked
.proc DoOp
        ;; Pending input we need to parse?
        pha
        lda     calc_g
    IF_NOT_ZERO
        ;; Parse `text_buffer1` into FAC.
        ;; Copy string to `FBUFFR`, mapping decimal char.
        ldx     #kTextBufferSize
cloop:  lda     text_buffer1,x
        cmp     SETTINGS + DeskTopSettings::intl_deci_sep
        bne     :+
        lda     #'.'
:       sta     FBUFFR,x
        dex
        bpl     cloop
        copy16  #FBUFFR, TXTPTR
        jsr     CHRGET
        ROM_CALL FIN
    END_IF
        pla

        ;; --------------------------------------------------
        ;; Function? These modify the FAC in place
        cmp     #Function::fn_sin
    IF_EQ
        ROM_CALL SIN
        jmp     PostFunc
    END_IF
        cmp     #Function::fn_cos
    IF_EQ
        ROM_CALL COS
        jmp     PostFunc
    END_IF
        cmp     #Function::fn_tan
    IF_EQ
        ROM_CALL TAN
        jmp     PostFunc
    END_IF
        cmp     #Function::fn_asin
    IF_EQ
        ;; ASIN(x) = ATN(X/SQR(-X*X+1))
        ROM_CALL FAC_TO_ARG_R   ; ARG = X
        jsr     PushARG
        ROM_CALL FMULTT         ; FAC = X * X
        ROM_CALL NEGOP          ; FAC = -X*X
        lday    #CON_ONE
        ROM_CALL FADD           ; FAC = -X*X+1
        ROM_CALL ABS
        ROM_CALL SQR            ; FAC = SQR(-X*X+1)
        jsr     PopARG          ; ARG = X
        ROM_CALL FDIVT          ; FAC = X/SQR(-X*X+1)
        ROM_CALL ATN            ; FAC = ATN(X/SQR(-X*X+1))
        jmp     PostFunc
    END_IF
        cmp     #Function::fn_acos
    IF_EQ
        ;; ACOS(x) = -ATN(X/SQR(-X*X+l))+1.5708
        ROM_CALL FAC_TO_ARG_R   ; ARG = X
        jsr     PushARG
        ROM_CALL FMULTT         ; FAC = X * X
        ROM_CALL NEGOP          ; FAC = -X*X
        lday    #CON_ONE
        ROM_CALL FADD           ; FAC = -X*X+1
        ROM_CALL ABS
        ROM_CALL SQR            ; FAC = SQR(-X*X+1)
        jsr     PopARG          ; ARG = X
        ROM_CALL FDIVT          ; FAC = X/SQR(-X*X+1)
        ROM_CALL ATN            ; FAC = ATN(X/SQR(-X*X+1))
        ROM_CALL NEGOP          ; FAC = -ATN(X/SQR(-X*X+1))
        lday    #CON_HALF_PI    ;
        ROM_CALL FADD           ; FAC = -ATN(X/SQR(-X*X+1))+1
        jmp     PostFunc
    END_IF
        cmp     #Function::fn_atan
    IF_EQ
        ROM_CALL ATN
        jmp     PostFunc
    END_IF
        cmp     #Function::fn_sqrt
    IF_EQ
        ROM_CALL SQR
        jmp     PostFunc
    END_IF
        cmp     #Function::fn_neg
    IF_EQ
        ROM_CALL NEGOP
        jmp     PostFunc
    END_IF
        cmp     #Function::fn_ln
    IF_EQ
        ROM_CALL LOG
        jmp     PostFunc
    END_IF
        cmp     #Function::fn_exp
    IF_EQ
        ROM_CALL EXP
        jmp     PostOp
    END_IF
        cmp     #Function::fn_inv
    IF_EQ
        lday    #CON_ONE
        ROM_CALL FDIV
        jmp     PostFunc
    END_IF

        ;; --------------------------------------------------

        pha

        ;; Look at last operation
        lda     calc_op

        cmp     #Function::equals
    IF_EQ
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
    IF_ZERO
        ;; No, so last was an op, we're overriding it.
        ;; e.g.: 2 * +
        pla
        sta     calc_op
        jmp     ResetBuffer1AndState
    END_IF

        ;; --------------------------------------------------
        ;; Operators

do_op:
        copy    #0, calc_f

        pla                     ; A = current op
        ldx     calc_op         ; X = previous op
        sta     calc_op         ; save for later
        lday    #farg           ; A,Y = previous intermediate result

        cpx     #Function::op_add
        bne     :+
        ROM_CALL FADD           ; FAC = (Y,A) + FAC
        jmp     PostOp

:       cpx     #Function::op_subtract
        bne     :+
        ROM_CALL FSUB           ; FAC = (Y,A) - FAC
        jmp     PostOp

:       cpx     #Function::op_multiply
        bne     :+
        ROM_CALL FMULT          ; FAC = (Y,A) * FAC
        jmp     PostOp

:       cpx     #Function::op_divide
        bne     :+
        ROM_CALL FDIV           ; FAC = (Y,A) / FAC
        jmp     PostOp

:       cpx     #Function::op_power
        bne     :+
        ROM_CALL LOAD_ARG       ; ARG = (A,Y)
        ROM_CALL FPWRT          ; FAC = ARG ^ FAC
        jmp     PostOp

:       cpx     #Function::equals
        bne     :+
        ldy     calc_g
        bne     PostOp
        jmp     ResetBuffer1AndState
:
        FALL_THROUGH_TO PostOp
.endproc

;;; ============================================================

.proc PostOp
        ldxy    #farg           ; save intermediate result
        ROM_CALL ROUND

ep2:    jsr     PushFAC
        ROM_CALL FOUT       ; output as null-terminated string to FBUFFR
        jsr     PopFAC

        ldy     #0              ; count the size
sloop:  lda     FBUFFR,y
        beq     :+
        iny
        bne     sloop

:       ldx     #kTextBufferSize ; copy to text buffers
cloop:  lda     FBUFFR-1,y
        cmp     #'.'            ; map decimal character
        bne     :+
        lda     SETTINGS + DeskTopSettings::intl_deci_sep
:       sta     text_buffer1,x
        sta     text_buffer2,x
        dex
        dey
        bne     cloop

        ;; Add leading zero if starting with decimal
        cmp     #'-'
    IF_EQ
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
        bmi     end
pad:    lda     #' '
        sta     text_buffer1,x
        sta     text_buffer2,x
        dex
        bpl     pad
end:    jsr     DisplayBuffer1
        FALL_THROUGH_TO ResetBuffer1AndState
.endproc

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
.endproc

.proc MaybeAddLeadingZero
        lda     text_buffer1+1,x
        cmp     SETTINGS + DeskTopSettings::intl_deci_sep
        bne     :+
        lda     #'0'
        sta     text_buffer1,x
        sta     text_buffer2,x
        dex
:
        rts
.endproc

;;; After a function (e.g. SIN, COS, etc) is done, we must leave
;;; the FAC alone but we do need to update the display and set
;;; a flag indicating we shouldn't override the pending op.
.proc PostFunc
        jsr     PostOp::ep2
        sec
        ror     calc_f
        rts
.endproc

;;; ============================================================

kRegSize = 6

.proc PushFAC
        pla
        sta     lo
        pla
        sta     hi

        ldx     #AS_BYTE(-kRegSize)
:       lda     FAC + kRegSize,x
        pha
        inx
        bne     :-

        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha

        rts
.endproc

.proc PopFAC
        pla
        sta     lo
        pla
        sta     hi

        ldx     #kRegSize-1
:       pla
        sta     FAC,x
        dex
        bpl     :-

        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha

        rts
.endproc

.proc PushARG
        pla
        sta     lo
        pla
        sta     hi

        ldx     #AS_BYTE(-kRegSize)
:       lda     ARG + kRegSize,x
        pha
        inx
        bne     :-

        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha

        rts
.endproc

.proc PopARG
        pla
        sta     lo
        pla
        sta     hi

        ldx     #kRegSize-1
:       pla
        sta     ARG,x
        dex
        bpl     :-

        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        pha
        lo := *+1
        lda     #SELF_MODIFIED_BYTE
        pha

        rts
.endproc

;;; ============================================================

.proc DepressButton
        stax    invert_addr
        stax    inrect_params

        MGTK_CALL MGTK::GetWinPort, getwinport_params
        cmp     #MGTK::Error::window_obscured
        bne     :+
        rts
:       MGTK_CALL MGTK::SetPort, grafport

        button_state := $FC

        MGTK_CALL MGTK::SetPattern, black_pattern
        MGTK_CALL MGTK::SetPenMode, penmode_xor
        sec
        ror     button_state

invert: jsr     invert_rect

check_button:
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::drag ; Button down?
        bne     done            ; Nope, done immediately
        lda     #kDAWindowId
        sta     screentowindow_params::window_id

        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, 0, inrect_params
        bne     inside

        lda     button_state    ; outside, not down
        beq     check_button    ; so keep looping

        lda     #0              ; outside, was down
        sta     button_state    ; so set up
        beq     invert          ; and show it

inside: lda     button_state    ; inside, and down
        bne     check_button    ; so keep looking

        sec                     ; inside, was not down
        ror     button_state    ; so set down
        jmp     invert          ; and show it

done:   lda     button_state                    ; high bit set if button down
        pha
        beq     :+
        jsr     invert_rect                        ; Back to normal
:       MGTK_CALL MGTK::SetPenMode, penmode_normal ; Normal draw mode??
        pla
        rts

invert_rect:
        MGTK_CALL MGTK::PaintRect, 0, invert_addr
        rts
.endproc

;;; ============================================================
;;; Value Display

.proc ResetBuffer1
        ldy     #kTextBufferSize
loop:   lda     #' '
        sta     text_buffer1-1,y
        dey
        bne     loop
        lda     #'0'
        sta     text_buffer1 + kTextBufferSize
        rts
.endproc

.proc ResetBuffer2
        ldy     #kTextBufferSize
loop:   lda     #' '
        sta     text_buffer2-1,y
        dey
        bne     loop
        lda     #'0'
        sta     text_buffer2 + kTextBufferSize
        rts
.endproc

.proc ResetBuffersAndDisplay
        jsr     ResetBuffer1
        jsr     ResetBuffer2
        FALL_THROUGH_TO DisplayBuffer1
.endproc

.proc DisplayBuffer1
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        cmp     #MGTK::Error::window_obscured
        beq     end
        MGTK_CALL MGTK::SetPort, grafport
        ldxy    #text_buffer1
        jsr     PreDisplayBuffer
        MGTK_CALL MGTK::DrawText, drawtext_params1
end:    rts
.endproc

.proc DisplayBuffer2
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        cmp     #MGTK::Error::window_obscured
        beq     end
        MGTK_CALL MGTK::SetPort, grafport
        ldxy    #text_buffer2
        jsr     PreDisplayBuffer
        MGTK_CALL MGTK::DrawText, drawtext_params2
end:    rts
.endproc

.proc PreDisplayBuffer
        stx     textwidth_params::textptr ; text buffer address in x,y
        sty     textwidth_params::textptr+1
        MGTK_CALL MGTK::TextWidth, textwidth_params
        lda     #kDisplayRight-15 ; ???
        sec
        sbc     textwidth_params::result
        sta     text_pos_params3::left
        MGTK_CALL MGTK::MoveTo, text_pos_params2 ; clear with spaces
        param_call DrawString, spaces_string
        MGTK_CALL MGTK::MoveTo, text_pos_params3 ; set up for display
        rts
.endproc

;;; ============================================================
;;; Draw the window contents (background, buttons)

.proc DrawContent
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        cmp     #MGTK::Error::window_obscured
        bne     :+
        rts
:       MGTK_CALL MGTK::SetPort, grafport

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
        ptr := $FA

        copy16  #first_button, ptr
loop:   ldy     #0
        lda     (ptr),y
        beq     finish

        add16_8 ptr, #(btn_c::viewloc - btn_c), bitmap_addr
        add16_8 ptr, #(btn_c::pos - btn_c), text_addr
        add16_8 ptr, #(btn_c::label - btn_c), label

        MGTK_CALL MGTK::PaintBits, 0, bitmap_addr ; draw shadowed rect
        MGTK_CALL MGTK::MoveTo, 0, text_addr         ; button label pos
        param_call_indirect DrawString, label

        add16_8 ptr, #.sizeof(btn_c)
        jmp     loop

finish: jsr     DisplayBuffer2

        MGTK_CALL MGTK::ShowCursor

        rts

label:  .addr   0

.endproc

;;; ============================================================

        ;; Traps FP error via call to $36 from MON.COUT, resets stack
        ;; and returns to the input loop.
.proc ErrorHook
        bit     LCBANK1
        bit     LCBANK1
        jsr     ResetBuffersAndDisplay

        MGTK_CALL MGTK::GetWinPort, getwinport_params
        cmp     #MGTK::Error::window_obscured
        beq     :+
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::MoveTo, error_pos
        param_call DrawString, error_string

:       jsr     ResetBuffer1AndState
        lda     #Function::equals
        sta     calc_op
        ldx     saved_stack
        txs
        jmp     InputLoop
.endproc

PROC_AT chrget_routine, ::CHRGET
        dummy_addr := $EA60

loop:   inc16   TXTPTR

        .assert * + 1 = TXTPTR, error, "misaligned routine"
        lda     dummy_addr      ; this ends up being aligned on TXTPTR

        cmp     #'9'+1          ; after digits?
        bcs     end
        cmp     #' '            ; space? keep going
        beq     loop
        sec
        sbc     #'0'            ; convert to digit...
        sec
        sbc     #$D0            ; carry set if successful
end:    rts
END_PROC_AT
        sizeof_chrget_routine = .sizeof(chrget_routine)

;;; ============================================================
;;; Make call into Main from Aux (for JUMP_TABLE calls)
;;; Inputs: A,X = address

.proc JTRelay
        sta     RAMRDOFF
        sta     RAMWRTOFF
        stax    @addr
        @addr := *+1
        jsr     SELF_MODIFIED
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

;;; ============================================================

        .include "../lib/drawstring.s"
        .include "../lib/rom_call.s"

;;; ============================================================

da_end  := *
.assert * < DA_IO_BUFFER, error, .sprintf("DA too big (at $%X)", *)

;;; ============================================================
