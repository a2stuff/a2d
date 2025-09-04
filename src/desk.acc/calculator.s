;;; ============================================================
;;; CALCULATOR - Desk Accessory
;;;
;;; A basic four-function calculator.
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
        jmp     Init
.endproc ; InitDA


.proc ExitDA
        MGTK_CALL MGTK::SetZP1, setzp_params_nopreserve
        rts
.endproc ; ExitDA

;;; ============================================================
;;; Call Params (and other data)

        .include "../lib/event_params.s"
        .res    1               ; unused

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

        kCalcButtonWidth = 17
        kCalcButtonHeight = 9

        kCol1Left = 13
        kCol1Right = kCol1Left+kCalcButtonWidth ; 30
        kCol2Left = 42
        kCol2Right = kCol2Left+kCalcButtonWidth ; 59
        kCol3Left = 70
        kCol3Right = kCol3Left+kCalcButtonWidth ; 87
        kCol4Left = 98
        kCol4Right = kCol4Left+kCalcButtonWidth ; 115

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

.macro CALC_BUTTON identifier, labelchar, left, top
.params identifier
        DEFINE_POINT viewloc, left - kBorderLeftTop, top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kCalcButtonWidth + kBorderLeftTop + kBorderBottomRight, kCalcButtonHeight + kBorderLeftTop + kBorderBottomRight
        REF_MAPINFO_MEMBERS
label:          .byte   labelchar
pos:            .word   left + 6, top+kCalcButtonHeight
port:           .word   left, top, left+kCalcButtonWidth, top+kCalcButtonHeight
        .refto label
        .refto pos
        .refto port
.endparams
.endmacro

        CALC_BUTTON btn_c,   'c', kCol1Left, kRow1Top
        CALC_BUTTON btn_e,   'e', kCol2Left, kRow1Top
        CALC_BUTTON btn_eq,  '=', kCol3Left, kRow1Top
        CALC_BUTTON btn_mul, '*', kCol4Left, kRow1Top

        CALC_BUTTON btn_7,   '7', kCol1Left, kRow2Top
        CALC_BUTTON btn_8,   '8', kCol2Left, kRow2Top
        CALC_BUTTON btn_9,   '9', kCol3Left, kRow2Top
        CALC_BUTTON btn_div, '/', kCol4Left, kRow2Top

        CALC_BUTTON btn_4,   '4', kCol1Left, kRow3Top
        CALC_BUTTON btn_5,   '5', kCol2Left, kRow3Top
        CALC_BUTTON btn_6,   '6', kCol3Left, kRow3Top
        CALC_BUTTON btn_sub, '-', kCol4Left, kRow3Top

        CALC_BUTTON btn_1,   '1', kCol1Left, kRow4Top
        CALC_BUTTON btn_2,   '2', kCol2Left, kRow4Top
        CALC_BUTTON btn_3,   '3', kCol3Left, kRow4Top


.params btn_0
        DEFINE_POINT viewloc, kCol1Left - kBorderLeftTop, kRow5Top - kBorderLeftTop
mapbits:        .addr   wide_button_bitmap
mapwidth:       .byte   8       ; kBitmapStride (bytes)
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 49, kCalcButtonHeight + kBorderLeftTop + kBorderBottomRight ; 0 is extra wide
        REF_MAPINFO_MEMBERS

label:          .byte   '0'
pos:            .word   kCol1Left + 6, kRow5Bot
port:           .word   kCol1Left,kRow5Top,kCol2Right,kRow5Bot
        .refto label
        .refto pos
        .refto port
.endparams

.params btn_dec
        DEFINE_POINT viewloc, kCol3Left - kBorderLeftTop, kRow5Top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kCalcButtonWidth + kBorderLeftTop + kBorderBottomRight, kCalcButtonHeight + kBorderLeftTop + kBorderBottomRight
        REF_MAPINFO_MEMBERS

label:          .byte   SELF_MODIFIED_BYTE          ; populated at runtime
pos:            .word   kCol3Left + 6 + 2, kRow5Bot ; + 2 to center the label
port:           .word   kCol3Left,kRow5Top,kCol3Right,kRow5Bot
        .refto label
        .refto pos
        .refto port
.endparams
decimal_label := btn_dec::label

.params btn_add
        DEFINE_POINT viewloc, kCol4Left - kBorderLeftTop, kRow4Top - kBorderLeftTop
mapbits:        .addr   tall_button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kCalcButtonWidth + kBorderLeftTop + kBorderBottomRight, 27 ; + is extra tall
        REF_MAPINFO_MEMBERS

label:          .byte   '+'
pos:            .word   kCol4Left + 6, kRow5Bot
port:           .word   kCol4Left,kRow4Top,kCol4Right,kRow5Bot
        .refto label
        .refto pos
        .refto port
.endparams
        .byte   0               ; sentinel

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
calc_p: .byte   $00             ; high bit set if pending op?
calc_op:.byte   $00
calc_d: .byte   $00             ; decimal separator if present, 0 otherwise
calc_e: .byte   $00             ; exponential?
calc_n: .byte   $00             ; negative?
calc_g: .byte   $00             ; high bit set if last input digit
calc_l: .byte   $00             ; input length

;;; ============================================================
;;; Miscellaneous param blocks

.params background_box_params
left:   .word   1
top:    .word   0
right:  .word   129
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

        kDisplayLeft    = 10
        kDisplayTop     = 5
        kDisplayWidth   = 120
        kDisplayHeight  = 17

.params frame_display_params
left:   .word   kDisplayLeft
top:    .word   kDisplayTop
width:  .word   kDisplayWidth
height: .word   kDisplayHeight
.endparams

.params clear_display_params
left:   .word   kDisplayLeft+1
top:    .word   kDisplayTop+1
width:  .word   kDisplayWidth-1
height: .word   kDisplayHeight-1
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
left:   .word   15
base:   .word   16
.endparams

.params error_pos
left:   .word   69
base:   .word   16
.endparams

farg:   .byte   $00,$00,$00,$00,$00,$00

.params title_bar_bitmap      ; Params for MGTK::PaintBits
        DEFINE_POINT viewloc, 115, AS_WORD -9
mapbits:        .addr   pixels
mapwidth:       .byte   1
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 6, 5
        REF_MAPINFO_MEMBERS

        ;;  (not part of struct, but not referenced outside)
pixels: PIXELS  "#.....#"
        PIXELS  "#.#.##."
        PIXELS  "###...#"
        PIXELS  "###.##."
        PIXELS  ".##.##."
        PIXELS  "#..#..#"
.endparams

grafport:       .tag    MGTK::GrafPort

        ;; params for MGTK::SetPortBits when decorating title bar
.params screen_port
left:           .word   0
top:            .word   kMenuBarHeight
mapbits:        .word   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
hoff:           .word   0
voff:           .word   0
width:          .word   kScreenWidth - 1
height:         .word   kScreenHeight - kMenuBarHeight - 2
.endparams

penmode_normal: .byte   MGTK::pencopy
penmode_xor:    .byte   MGTK::notpenXOR

        kWindowWidth = 130
        kWindowHeight = 96
        kDefaultLeft = 210
        kDefaultTop = 60

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
mincontwidth:   .word   kWindowWidth
mincontheight:  .word   kWindowHeight
maxcontwidth:   .word   kWindowWidth
maxcontheight:  .word   kWindowHeight
port:
        DEFINE_POINT viewloc, kDefaultLeft, kDefaultTop
        left := viewloc::xcoord
        top  := viewloc::ycoord
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kWindowWidth, kWindowHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
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

.proc Init
        ;; Cache settings
        ldx     #DeskTopSettings::intl_deci_sep
        jsr     ReadSetting
        sta     intl_deci_sep
        sta     decimal_label
        sta     decimal_lookup

        MGTK_CALL MGTK::OpenWindow, winfo
        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::FlushEvents

        jsr     ResetBuffer2

        jsr     DrawContent
        jsr     ResetBuffersAndDisplay

        lda     #'='            ; last kOperation
        sta     calc_op

        lda     #0              ; clear registers
        sta     calc_p
        sta     calc_d
        sta     calc_e
        sta     calc_n
        sta     calc_g
        sta     calc_l

.scope
        ldx     #sizeof_chrget_routine + 4 ; should be just + 1 ?
loop:   copy8   chrget_routine-1,x, CHRGET-1,x
        dex
        bne     loop
.endscope

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

        lda     #'='
        jsr     ProcessKey
        lda     #'C'
        jsr     ProcessKey

        FALL_THROUGH_TO InputLoop
.endproc ; Init

;;; ============================================================
;;; Input Loop

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        MGTK_CALL MGTK::GetEvent, event_params

        lda     event_params::kind
    IF_A_EQ     #MGTK::EventKind::button_down
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
        bcc     ignore_click

        lda     findwindow_params::window_id
    IF_A_NE     #kDAWindowId      ; This window?
ignore_click:
        rts
    END_IF

        lda     findwindow_params::which_area
    IF_A_EQ     #MGTK::Area::content ; Content area?
        jsr     MapClickToButton ; try to translate click into key
        bcc     ignore_click
        jmp     ProcessKey
    END_IF

    IF_A_EQ     #MGTK::Area::close_box ; Close box?
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway
        beq     ignore_click

exit:   pla                     ; pop OnClick / OnKeyPress
        pla
        MGTK_CALL MGTK::CloseWindow, closewindow_params
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        jmp     ExitDA
    END_IF

        cmp     #MGTK::Area::dragbar ; Title bar?
        bne     ignore_click

        copy8   #kDAWindowId, dragwindow_params::window_id
        MGTK_CALL MGTK::DragWindow, dragwindow_params
        bit     dragwindow_params::moved
    IF_NS
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        jmp     DrawContent
    END_IF
ret:    rts
.endproc ; OnClick
exit := OnClick::exit

;;; ============================================================
;;; On Key Press

.proc OnKeyPress
        lda     event_params::key
        jsr     ToUpperCase

        ldx     event_params::modifiers
    IF_NOT_ZERO
        cmp     #kShortcutCloseWindow
        beq     exit
        bne     bail            ; always
    END_IF

    IF_A_EQ     #CHAR_RETURN    ; Treat Return as Equals
        lda     #'='
        bne     process         ; always
    END_IF

    IF_A_EQ     #CHAR_CLEAR     ; Treat Control+X as Clear
        lda     #'C'
        bne     process         ; always
    END_IF

    IF_A_EQ     #CHAR_ESCAPE    ; Treat Escape as Clear *or* Close
        lda     calc_p
        bne     clear           ; empty state?
        lda     calc_l
        beq     exit            ; if so, exit DA
clear:  lda     #'C'            ; otherwise turn Escape into Clear
    END_IF

process:
        jmp     ProcessKey
bail:
        FALL_THROUGH_TO rts1
.endproc ; OnKeyPress

rts1:  rts                     ; used by next proc

;;; ============================================================
;;; Try to map a click to a button

;;; If a button was clicked, carry is set and accum has key char

.proc MapClickToButton
        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     screentowindow_params::windowx+1        ; ensure high bits of coords are 0
        ora     screentowindow_params::windowy+1
        bne     rts1
        lda     screentowindow_params::windowy
        ldx     screentowindow_params::windowx
        FALL_THROUGH_TO FindButtonRow

.proc FindButtonRow
        cmp     #kRow1Top+kBorderLeftTop - 1 ; row 1 ? (- 1 is bug in original?)
        bcc     miss
    IF_A_LT     #kRow1Bot+kBorderBottomRight + 1 ; (+ 1 is bug in original?)
        jsr     FindButtonCol
        bcc     miss
        lda     row1_lookup,x
        rts
    END_IF

        cmp     #kRow2Top-kBorderLeftTop             ; row 2?
        bcc     miss
    IF_A_LT     #kRow2Bot+kBorderBottomRight
        jsr     FindButtonCol
        bcc     miss
        lda     row2_lookup,x
        rts
    END_IF

        cmp     #kRow3Top-kBorderLeftTop             ; row 3?
        bcc     miss
    IF_A_LT     #kRow3Bot+kBorderBottomRight
        jsr     FindButtonCol
        bcc     miss
        lda     row3_lookup,x
        rts
    END_IF

        cmp     #kRow4Top-kBorderLeftTop             ; row 4?
        bcc     miss
    IF_A_LT     #kRow4Bot+kBorderBottomRight
        jsr     FindButtonCol
        bcc     miss
        sec
        lda     row4_lookup,x
        rts
    END_IF

    IF_A_LT     #kRow5Top-kBorderLeftTop             ; special case for tall + button
        lda     screentowindow_params::windowx
        cmp     #kCol4Left-kBorderLeftTop
        bcc     miss
        cmp     #kCol4Right+kBorderBottomRight-1         ; is -1 bug in original?
        bcs     miss
        lda     #'+'
        sec
        rts
    END_IF

        cmp     #kRow5Bot+kBorderBottomRight             ; row 5?
        bcs     miss

        jsr     FindButtonCol
    IF_CS
        lda     row5_lookup,x
        rts
    END_IF

        lda     screentowindow_params::windowx ; special case for wide 0 button
    IF_A_GE     #kCol1Left-kBorderLeftTop
      IF_A_LT   #kCol2Right+kBorderBottomRight
        lda     #'0'
        sec
        rts
      END_IF
    END_IF

miss:   clc
        rts
.endproc ; FindButtonRow

        row1_lookup := *-1
        .byte   'C', 'E', '=', '*'
        row2_lookup := *-1
        .byte   '7', '8', '9', '/'
        row3_lookup := *-1
        .byte   '4', '5', '6', '-'
        row4_lookup := *-1
        .byte   '1', '2', '3', '+'
        row5_lookup := *-1
        .byte   '0', '0', SELF_MODIFIED_BYTE, '+'
        ::decimal_lookup := *-2

.proc FindButtonCol
        cpx     #kCol1Left-kBorderLeftTop             ; col 1?
        bcc     miss
    IF_X_LT     #kCol1Right+kBorderBottomRight
        ldx     #1
        sec
        rts
    END_IF

        cpx     #kCol2Left-kBorderLeftTop             ; col 2?
        bcc     miss
    IF_X_LT     #kCol2Right+kBorderBottomRight
        ldx     #2
        sec
        rts
    END_IF

        cpx     #kCol3Left-kBorderLeftTop             ; col 3?
        bcc     miss
    IF_X_LT     #kCol3Right+kBorderBottomRight
        ldx     #3
        sec
        rts
    END_IF

        cpx     #kCol4Left-kBorderLeftTop            ; col 4?
        bcc     miss
    IF_X_LT     #kCol4Right+kBorderBottomRight - 1       ; bug in original?
        ldx     #4
        sec
        rts
    END_IF

miss:   clc
        rts
.endproc ; FindButtonCol
.endproc ; MapClickToButton

;;; ============================================================
;;; Handle Key

;;; Accumulator is set to key char. Also used by
;;; click handlers (button is mapped to key char)
;;; and during initialization (by sending 'C', etc)

.proc ProcessKey
    IF_A_EQ     #'C'            ; Clear?
        ldxy    #btn_c::port
        lda     #'c'
        jsr     DepressButton
        lda     #0
        ROM_CALL FLOAT
        ldxy    #farg
        ROM_CALL ROUND
        copy8   #'=', calc_op
        lda     #0
        sta     calc_p
        sta     calc_l
        sta     calc_d
        sta     calc_e
        sta     calc_n
        jmp     ResetBuffersAndDisplay
    END_IF

    IF_A_EQ     #'E'            ; Exponential?
        ldxy    #btn_e::port
        lda     #'e'
        jsr     DepressButton
        ldy     calc_e
        bne     rts1
        ldy     calc_l
      IF_ZERO
        inc     calc_l
        lda     #'1'
        sta     text_buffer1 + kTextBufferSize
        sta     text_buffer2 + kTextBufferSize
      END_IF
        copy8   #'E', calc_e
        jmp     update

rts1:   rts
    END_IF

    IF_A_EQ     #'='            ; Equals?
        pha
        ldxy    #btn_eq::port
        jmp     DoOpClick
    END_IF

    IF_A_EQ     #'*'            ; Multiply?
        pha
        ldxy    #btn_mul::port
        jmp     DoOpClick
    END_IF

        cmp     intl_deci_sep   ; Decimal?
        beq     dsep

    IF_A_EQ     #'.'            ; allow either
dsep:   ldxy    #btn_dec::port
        jsr     DepressButton
        lda     calc_d
        ora     calc_e
        bne     rts2
        lda     calc_l
      IF_ZERO
        inc     calc_l
      END_IF
        copy8   intl_deci_sep, calc_d
        jmp     update

rts2:   rts
    END_IF

    IF_A_EQ     #'+'            ; Add?
        pha
        ldxy    #btn_add::port
        jmp     DoOpClick
    END_IF

    IF_A_EQ     #'-'            ; Subtract?
        pha
        ldxy    #btn_sub::port
        lda     calc_e          ; negate vs. subtract
      IF_NOT_ZERO
        lda     calc_n
       IF_ZERO
        sec
        ror     calc_n
        pla
        pha
        jmp     do_digit_click
       END_IF
      END_IF

        pla
        pha
        jmp     DoOpClick
    END_IF

    IF_A_EQ     #'/'            ; Divide?
        pha
        ldxy    #btn_div::port
        jmp     DoOpClick
    END_IF

    IF_A_EQ     #'0'            ; Digit 0?
        pha
        ldxy    #btn_0::port
        jmp     do_digit_click
    END_IF

    IF_A_EQ     #'1'            ; Digit 1?
        pha
        ldxy    #btn_1::port
        jmp     do_digit_click
    END_IF

    IF_A_EQ     #'2'            ; Digit 2?
        pha
        ldxy    #btn_2::port
        jmp     do_digit_click
    END_IF

    IF_A_EQ     #'3'            ; Digit 3?
        pha
        ldxy    #btn_3::port
        jmp     do_digit_click
    END_IF

    IF_A_EQ     #'4'            ; Digit 4?
        pha
        ldxy    #btn_4::port
        jmp     do_digit_click
    END_IF

    IF_A_EQ     #'5'            ; Digit 5?
        pha
        ldxy    #btn_5::port
        jmp     do_digit_click
    END_IF

    IF_A_EQ     #'6'            ; Digit 6?
        pha
        ldxy    #btn_6::port
        jmp     do_digit_click
    END_IF

    IF_A_EQ     #'7'            ; Digit 7?
        pha
        ldxy    #btn_7::port
        jmp     do_digit_click
    END_IF

    IF_A_EQ     #'8'            ; Digit 8?
        pha
        ldxy    #btn_8::port
        jmp     do_digit_click
    END_IF

    IF_A_EQ     #'9'            ; Digit 9?
        pha
        ldxy    #btn_9::port
        jmp     do_digit_click
    END_IF

    IF_A_EQ     #CHAR_DELETE    ; Delete?
        ldy     calc_l
        beq     end
      IF_Y_EQ   #1
        jsr     ResetBuffer1AndState
        jmp     DisplayBuffer1
      END_IF

        dec     calc_l

        ldx     #0
        lda     text_buffer1 + kTextBufferSize
      IF_A_EQ   intl_deci_sep
        stx     calc_d
      END_IF
      IF_A_EQ   #'E'
        stx     calc_e
      END_IF
      IF_A_EQ   #'-'
        stx     calc_n
      END_IF

        ldx     #kTextBufferSize-1
      DO
        lda     text_buffer1,x
        sta     text_buffer1+1,x
        sta     text_buffer2+1,x
        dex
        dey
      WHILE_NOT_ZERO
        lda     #' '

        sta     text_buffer1+1,x
        sta     text_buffer2+1,x
        jmp     DisplayBuffer1
    END_IF

end:    rts
.endproc ; ProcessKey

do_digit_click:
        jsr     DepressButton
    IF_ZERO
        pla
        rts
    END_IF

        pla
update: sec
        ror     calc_g
        ldy     calc_l
    IF_ZERO
        pha
        jsr     ResetBuffer2
        pla
      IF_A_EQ   #'0'
        jmp     DisplayBuffer1
      END_IF
    END_IF

        sec
        ror     calc_p
        cpy     #10
        bcs     rts3
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
    WHILE_NOT_ZERO

empty:  inc     calc_l
        pla
        sta     text_buffer1 + kTextBufferSize
        sta     text_buffer2 + kTextBufferSize
        jmp     DisplayBuffer1

rts3:   rts

.proc DoOpClick
        jsr     DepressButton
    IF_ZERO
        pla
        rts
    END_IF

        lda     calc_op
    IF_A_EQ     #'='
        lda     calc_g
        bne     reparse
        lda     #0
        ROM_CALL FLOAT
        jmp     do_op
    END_IF

        lda     calc_g
        bne     reparse
        pla
        sta     calc_op
        jmp     ResetBuffer1AndState

reparse:
        ;; Copy string to `FBUFFR`, mapping decimal char.
        ldx     #kTextBufferSize
cloop:  lda     text_buffer1,x
    IF_A_EQ     intl_deci_sep
        lda     #'.'
    END_IF
        sta     FBUFFR,x
        dex
        bpl     cloop
        copy16  #FBUFFR, TXTPTR
        jsr     CHRGET
        ROM_CALL FIN

do_op:  pla
        ldx     calc_op
        sta     calc_op
        lda     #<farg
        ldy     #>farg

    IF_X_EQ     #'+'
        ROM_CALL FADD
        jmp     PostOp
    END_IF

    IF_X_EQ     #'-'
        ROM_CALL FSUB
        jmp     PostOp
    END_IF

    IF_X_EQ     #'*'
        ROM_CALL FMULT
        jmp     PostOp
    END_IF

    IF_X_EQ     #'/'
        ROM_CALL FDIV
        jmp     PostOp
    END_IF

    IF_X_EQ     #'='
        ldy     calc_g
      IF_ZERO
        jmp     ResetBuffer1AndState
      END_IF
    END_IF

        FALL_THROUGH_TO PostOp
.endproc ; DoOpClick

.proc PostOp
        ldxy    #farg           ; after the FP kOperation is done
        ROM_CALL ROUND
        ROM_CALL FOUT           ; output as null-terminated string to FBUFFR

        ldy     #0              ; count the size
    DO
        lda     FBUFFR,y
        BREAK_IF_ZERO
        iny
    WHILE_NOT_ZERO              ; always

        ldx     #kTextBufferSize ; copy to text buffers
    DO
        lda     FBUFFR-1,y
      IF_A_EQ   #'.'            ; map decimal character
        lda     intl_deci_sep
      END_IF
        sta     text_buffer1,x
        sta     text_buffer2,x
        dex
        dey
    WHILE_NOT_ZERO

        ;; Add leading zero if starting with decimal
    IF_A_EQ     #'-'
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
.endproc ; PostOp

.proc ResetBuffer1AndState
        jsr     ResetBuffer1
        lda     #0
        sta     calc_l
        sta     calc_d
        sta     calc_e
        sta     calc_n
        sta     calc_g
        rts
.endproc ; ResetBuffer1AndState

.proc MaybeAddLeadingZero
        lda     text_buffer1+1,x
    IF_A_EQ     intl_deci_sep
        lda     #'0'
        sta     text_buffer1,x
        sta     text_buffer2,x
        dex
    END_IF
        rts
.endproc ; MaybeAddLeadingZero

.proc DepressButton
        stxy    invert_addr
        stxy    inrect_params
        stxy    restore_addr

        MGTK_CALL MGTK::GetWinPort, getwinport_params
    IF_A_EQ     #MGTK::Error::window_obscured
        lda     #$80            ; key was pressed
        rts
    END_IF
        MGTK_CALL MGTK::SetPort, grafport

        button_state := $FC

        MGTK_CALL MGTK::SetPattern, black_pattern
        MGTK_CALL MGTK::SetPenMode, penmode_xor
        sec
        ror     button_state

invert:  MGTK_CALL MGTK::PaintRect, 0, invert_addr ; Inverts port

check_button:
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::drag ; Button down?
        bne     done            ; Nope, done immediately

        copy8   #kDAWindowId, screentowindow_params::window_id
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
    IF_NOT_ZERO
        MGTK_CALL MGTK::PaintRect, 0, restore_addr ; Inverts back to normal
    END_IF
        MGTK_CALL MGTK::SetPenMode, penmode_normal ; Normal draw mode??
        lda     button_state
        rts
.endproc ; DepressButton

;;; ============================================================
;;; Value Display

.proc ResetBuffer1
        ldy     #kTextBufferSize
loop:   copy8   #' ', text_buffer1-1,y
        dey
        bne     loop
        copy8   #'0', text_buffer1 + kTextBufferSize
        rts
.endproc ; ResetBuffer1

.proc ResetBuffer2
        ldy     #kTextBufferSize
loop:   copy8   #' ', text_buffer2-1,y
        dey
        bne     loop
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
        ldxy    #text_buffer1
        jsr     PreDisplayBuffer
        MGTK_CALL MGTK::DrawText, drawtext_params1
end:    rts
.endproc ; DisplayBuffer1

.proc DisplayBuffer2
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        cmp     #MGTK::Error::window_obscured
        beq     end
        MGTK_CALL MGTK::SetPort, grafport
        ldxy    #text_buffer2
        jsr     PreDisplayBuffer
        MGTK_CALL MGTK::DrawText, drawtext_params2
end:    rts
.endproc ; DisplayBuffer2

.proc PreDisplayBuffer
        stx     textwidth_params::textptr ; text buffer address in x,y
        sty     textwidth_params::textptr+1
        MGTK_CALL MGTK::TextWidth, textwidth_params
        lda     #kDisplayWidth-15 ; ???
        sec
        sbc     textwidth_params::result
        sta     text_pos_params3::left
        MGTK_CALL MGTK::MoveTo, text_pos_params2 ; clear with spaces
        param_call DrawString, spaces_string
        MGTK_CALL MGTK::MoveTo, text_pos_params3 ; set up for display
        rts
.endproc ; PreDisplayBuffer

;;; ============================================================
;;; Draw the window contents (background, buttons)

.proc DrawContent
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        cmp     #MGTK::Error::window_obscured
        RTS_IF_EQ

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
        ptr := $FA

        copy16  #btn_c, ptr
loop:   ldy     #0
        lda     (ptr),y
        beq     DrawTitleBar    ; done!

        lda     ptr             ; address for shadowed rect params
        sta     bitmap_addr
        ldy     ptr+1
        sty     bitmap_addr+1

        clc                     ; address for label pos
        adc     #(btn_c::pos - btn_c)
        sta     text_addr
        bcc     :+
        iny
:       sty     text_addr+1

        ldy     #(btn_c::label - btn_c) ; label
        copy8   (ptr),y, label

        MGTK_CALL MGTK::PaintBitsHC, 0, bitmap_addr ; draw shadowed rect
        MGTK_CALL MGTK::MoveTo, 0, text_addr         ; button label pos
        MGTK_CALL MGTK::DrawText, drawtext_params_label  ; button label text

        lda     ptr             ; advance to next record
        clc
        adc     #.sizeof(btn_c)
        sta     ptr
        bcc     loop
        inc     ptr+1
        jmp     loop
.endproc ; DrawContent

;;; ============================================================
;;; Draw the title bar decoration

.proc DrawTitleBar
        kOffsetLeft     = 115  ; pixels from left of client area
        kOffsetTop      = 22   ; pixels from top of client area (up!)
        ldx     winfo::left+1
        lda     winfo::left
        clc
        adc     #kOffsetLeft
        sta     title_bar_bitmap::viewloc::xcoord
        bcc     :+
        inx
:       stx     title_bar_bitmap::viewloc::xcoord+1
        ldx     winfo::top+1
        lda     winfo::top
        sec
        sbc     #kOffsetTop
        sta     title_bar_bitmap::viewloc::ycoord
        bcs     :+
        dex
:       stx     title_bar_bitmap::viewloc::ycoord+1
        MGTK_CALL MGTK::SetPortBits, screen_port ; set clipping rect to whole screen
        MGTK_CALL MGTK::PaintBitsHC, title_bar_bitmap     ; Draws decoration in title bar
        MGTK_CALL MGTK::ShowCursor
        jmp     DisplayBuffer2
.endproc ; DrawTitleBar

;;; ============================================================
;;; Traps FP error via call to $36 from MON.COUT, resets stack
;;; and returns to the input loop.

.proc ErrorHook
        bit     LCBANK1
        bit     LCBANK1
        jsr     ResetBuffersAndDisplay

        MGTK_CALL MGTK::GetWinPort, getwinport_params
    IF_A_NE     #MGTK::Error::window_obscured
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::MoveTo, error_pos
        param_call DrawString, error_string
    END_IF

        jsr     ResetBuffer1AndState
        copy8   #'=', calc_op
        ldx     saved_stack
        txs
        jmp     InputLoop
.endproc ; ErrorHook

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


        .include "../lib/uppercase.s"
        .include "../lib/drawstring.s"
        .include "../lib/rom_call.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT

        JSR_TO_AUX aux::InitDA
        rts

        DA_END_MAIN_SEGMENT

;;; ============================================================
