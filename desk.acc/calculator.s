        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../desktop.inc"

;;; ============================================================

        .org $800

;;; ============================================================
;;; Start of the code

start:  jmp     copy2aux

save_stack:  .byte   0

;;; ============================================================
;;; Duplicate the DA (code and data) to AUX memory,
;;; then invoke the code in AUX.

.proc copy2aux
        tsx
        stx     save_stack

        ;; Copy the DA to AUX memory.
        lda     ROMIN2
        copy16  #start, STARTLO
        copy16  #da_end, ENDLO
        copy16  #start, DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE

        ;; Fall through
.endproc

;;; ============================================================

.proc init_da
        ;; TODO: Should be unnecessary:
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        ;; Run DA from Aux
        sta     RAMRDON
        sta     RAMWRTON

        jmp     init
.endproc


.proc exit_da
        ;; Return to DeskTop running in Main
        sta     RAMRDOFF
        sta     RAMWRTOFF

        ;; TODO: Should be unnecessary:
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        ldx     save_stack
        txs
        rts
.endproc

;;; ============================================================
;;; Used after a event_kind_drag is completed; redraws the window.

.proc redraw_screen_and_window

        ;; Redraw DeskTop's windows.
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_REDRAW_ALL
        sta     RAMRDON
        sta     RAMWRTON

        ;; Redraw DeskTop's icons.
        ITK_CALL IconTK::RedrawIcons

        ;;  Redraw window after event_kind_drag
        jsr     draw_content
        rts

.endproc

;;; ============================================================
;;; Call Params (and other data)

        ;; The following params blocks overlap for data re-use

.params screentowindow_params
window_id      := *
screen  := * + 1
screenx := * + 1 ; aligns with event_params::xcoord
screeny := * + 3 ; aligns with event_params::ycoord
window  := * + 5
windowx := * + 5
windowy := * + 7
.endparams

.params dragwindow_params
window_id      := *
xcoord  := * + 1 ; aligns with event_params::xcoord
ycoord  := * + 3 ; aligns with event_params::ycoord
moved   := * + 5 ; ignored
.endparams

.params event_params
kind:  .byte   0
xcoord    := *                  ; if state is 0,1,2,4
ycoord    := * + 2              ; "
key       := *                  ; if state is 3
modifiers := * + 1              ; "
.endparams

.params findwindow_params
mousex:         .word   0       ; aligns with event_params::xcoord
mousey:         .word   0       ; aligns with event_params::ycoord
which_area:     .byte   0
window_id:      .byte   0
.endparams

        .byte 0, 0              ; fills out space for screentowindow_params
        .byte 0, 0              ; ???

.params trackgoaway_params
goaway:  .byte   0
.endparams

.params getwinport_params
window_id:     .byte   kDAWindowId
        .addr   grafport
.endparams
        getwinport_params_window_id := getwinport_params::window_id

.params preserve_zp_params
flag:   .byte   MGTK::zp_preserve
.endparams

.params overwrite_zp_params
flag:   .byte   MGTK::zp_overwrite
.endparams

;;; ============================================================
;;; Button Definitions

        kButtonWidth = 17
        kButtonHeight = 9

        kCol1Left = 13
        kCol1Right = kCol1Left+kButtonWidth ; 30
        kCol2Left = 42
        kCol2Right = kCol2Left+kButtonWidth ; 59
        kCol3Left = 70
        kCol3Right = kCol3Left+kButtonWidth ; 87
        kCol4Left = 98
        kCol4Right = kCol4Left+kButtonWidth ; 115

        kRow1Top = 22
        kRow1Bot = kRow1Top+kButtonHeight ; 31
        kRow2Top = 38
        kRow2Bot = kRow2Top+kButtonHeight ; 47
        kRow3Top = 53
        kRow3Bot = kRow3Top+kButtonHeight ; 62
        kRow4Top = 68
        kRow4Bot = kRow4Top+kButtonHeight ; 77
        kRow5Top = 83
        kRow5Bot = kRow5Top+kButtonHeight ; 92

        kBorderLeftTop = 1          ; border width pixels (left/top)
        kBorderBottomRight = 2          ; (bottom/right)

.params btn_c
viewloc:        DEFINE_POINT kCol1Left - kBorderLeftTop, kRow1Top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kButtonWidth + kBorderLeftTop + kBorderBottomRight, kButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          .byte   'c'
pos:            .word   kCol1Left + 6, kRow1Bot
port:           .word   kCol1Left,kRow1Top,kCol1Right,kRow1Bot
.endparams

.params btn_e
viewloc:        DEFINE_POINT kCol2Left - kBorderLeftTop, kRow1Top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kButtonWidth + kBorderLeftTop + kBorderBottomRight, kButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          .byte   'e'
pos:            .word   kCol2Left + 6, kRow1Bot
port:           .word   kCol2Left,kRow1Top,kCol2Right,kRow1Bot
.endparams

.params btn_eq
viewloc:        DEFINE_POINT kCol3Left - kBorderLeftTop, kRow1Top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kButtonWidth + kBorderLeftTop + kBorderBottomRight, kButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          .byte   '='
pos:            .word   kCol3Left + 6, kRow1Bot
port:           .word   kCol3Left,kRow1Top,kCol3Right,kRow1Bot
.endparams

.params btn_mul
viewloc:        DEFINE_POINT kCol4Left - kBorderLeftTop, kRow1Top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kButtonWidth + kBorderLeftTop + kBorderBottomRight, kButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          .byte   '*'
pos:            .word   kCol4Left + 6, kRow1Bot
port:           .word   kCol4Left,kRow1Top,kCol4Right,kRow1Bot
.endparams

.params btn_7
viewloc:        DEFINE_POINT kCol1Left - kBorderLeftTop, kRow2Top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kButtonWidth + kBorderLeftTop + kBorderBottomRight, kButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          .byte   '7'
pos:            .word   kCol1Left + 6, kRow2Bot
port:           .word   kCol1Left,kRow2Top,kCol1Right,kRow2Bot
.endparams

.params btn_8
viewloc:        DEFINE_POINT kCol2Left - kBorderLeftTop, kRow2Top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kButtonWidth + kBorderLeftTop + kBorderBottomRight, kButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          .byte   '8'
pos:            .word   kCol2Left + 6, kRow2Bot
port:           .word   kCol2Left,kRow2Top,kCol2Right,kRow2Bot
.endparams

.params btn_9
viewloc:        DEFINE_POINT kCol3Left - kBorderLeftTop, kRow2Top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kButtonWidth + kBorderLeftTop + kBorderBottomRight, kButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          .byte   '9'
pos:            .word   kCol3Left + 6, kRow2Bot
port:           .word   kCol3Left,kRow2Top,kCol3Right,kRow2Bot
.endparams

.params btn_div
viewloc:        DEFINE_POINT kCol4Left - kBorderLeftTop, kRow2Top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kButtonWidth + kBorderLeftTop + kBorderBottomRight, kButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          .byte   '/'
pos:            .word   kCol4Left + 6, kRow2Bot
port:           .word   kCol4Left,kRow2Top,kCol4Right,kRow2Bot
.endparams

.params btn_4
viewloc:        DEFINE_POINT kCol1Left - kBorderLeftTop, kRow3Top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kButtonWidth + kBorderLeftTop + kBorderBottomRight, kButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          .byte   '4'
pos:            .word   kCol1Left + 6, kRow3Bot
port:           .word   kCol1Left,kRow3Top,kCol1Right,kRow3Bot
.endparams

.params btn_5
viewloc:        DEFINE_POINT kCol2Left - kBorderLeftTop, kRow3Top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kButtonWidth + kBorderLeftTop + kBorderBottomRight, kButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          .byte   '5'
pos:            .word   kCol2Left + 6, kRow3Bot
port:           .word   kCol2Left,kRow3Top,kCol2Right,kRow3Bot
.endparams

.params btn_6
viewloc:        DEFINE_POINT kCol3Left - kBorderLeftTop, kRow3Top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kButtonWidth + kBorderLeftTop + kBorderBottomRight, kButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          .byte   '6'
pos:            .word   kCol3Left + 6, kRow3Bot
port:           .word   kCol3Left,kRow3Top,kCol3Right,kRow3Bot
.endparams

.params btn_sub
viewloc:        DEFINE_POINT kCol4Left - kBorderLeftTop, kRow3Top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kButtonWidth + kBorderLeftTop + kBorderBottomRight, kButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          .byte   '-'
pos:            .word   kCol4Left + 6, kRow3Bot
port:           .word   kCol4Left,kRow3Top,kCol4Right,kRow3Bot
.endparams

.params btn_1
viewloc:        DEFINE_POINT kCol1Left - kBorderLeftTop, kRow4Top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kButtonWidth + kBorderLeftTop + kBorderBottomRight, kButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          .byte   '1'
pos:            .word   kCol1Left + 6, kRow4Bot
port:           .word   kCol1Left,kRow4Top,kCol1Right,kRow4Bot
.endparams

.params btn_2
viewloc:        DEFINE_POINT kCol2Left - kBorderLeftTop, kRow4Top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kButtonWidth + kBorderLeftTop + kBorderBottomRight, kButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          .byte   '2'
pos:            .word   kCol2Left + 6, kRow4Bot
port:           .word   kCol2Left,kRow4Top,kCol2Right,kRow4Bot
.endparams

.params btn_3
viewloc:        DEFINE_POINT kCol3Left - kBorderLeftTop, kRow4Top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kButtonWidth + kBorderLeftTop + kBorderBottomRight, kButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          .byte   '3'
pos:            .word   kCol3Left + 6, kRow4Bot
port:           .word   kCol3Left,kRow4Top,kCol3Right,kRow4Bot
.endparams

.params btn_0
viewloc:        DEFINE_POINT kCol1Left - kBorderLeftTop, kRow5Top - kBorderLeftTop
mapbits:        .addr   wide_button_bitmap
mapwidth:       .byte   8       ; kBitmapStride (bytes)
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, 49, kButtonHeight + kBorderLeftTop + kBorderBottomRight ; 0 is extra wide
label:          .byte   '0'
pos:            .word   kCol1Left + 6, kRow5Bot
port:           .word   kCol1Left,kRow5Top,kCol2Right,kRow5Bot
.endparams

.params btn_dec
viewloc:        DEFINE_POINT kCol3Left - kBorderLeftTop, kRow5Top - kBorderLeftTop
mapbits:        .addr   button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kButtonWidth + kBorderLeftTop + kBorderBottomRight, kButtonHeight + kBorderLeftTop + kBorderBottomRight
label:          .byte   '.'
pos:            .word   kCol3Left + 6 + 2, kRow5Bot ; + 2 to center the label
port:           .word   kCol3Left,kRow5Top,kCol3Right,kRow5Bot
.endparams

.params btn_add
viewloc:        DEFINE_POINT kCol4Left - kBorderLeftTop, kRow4Top - kBorderLeftTop
mapbits:        .addr   tall_button_bitmap
mapwidth:       .byte   kBitmapStride
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kButtonWidth + kBorderLeftTop + kBorderBottomRight, 27 ; + is extra tall
label:          .byte   '+'
pos:            .word   kCol4Left + 6, kRow5Bot
port:           .word   kCol4Left,kRow4Top,kCol4Right,kRow5Bot
.endparams
        .byte   0               ; sentinel

        ;; Button bitmaps. These are used as bitmaps for
        ;; drawing the shadowed buttons.

        ;; bitmaps are low 7 bits, 0=black 1=white
        kBitmapStride   = 3    ; bytes
button_bitmap:                  ; bitmap for normal buttons
        .byte   px(%0000000),px(%0000000),px(%0000001)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%1000000),px(%0000000),px(%0000000)

        kWideBitmapStride = 8
wide_button_bitmap:             ; bitmap for '0' button
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%1111111)
        .byte   px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111110),px(%0111111)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0111111)
        .byte   px(%1000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0111111)

tall_button_bitmap:             ; bitmap for '+' button
        .byte   px(%0000000),px(%0000000),px(%0000001)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0111111),px(%1111111),px(%1111100)
        .byte   px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%1000000),px(%0000000),px(%0000000)


;;; ============================================================
;;; Calculation state

saved_stack:
        .byte   $00             ; restored after error
calc_p: .byte   $00             ; high bit set if pending op?
calc_op:.byte   $00
calc_d: .byte   $00             ; '.' if decimal present, 0 otherwise
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
        .byte   $00

black_pattern:
        .res    8, $00
        .byte   $00

white_pattern:
        .res    8, $FF
        .byte   $00

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
        DEFINE_STRING "          "
error_string:
        DEFINE_STRING "Error "

        ;; used when clearing display; params to a $18 call
.params textwidth_params
textptr:        .addr   text_buffer1
textlen:        .byte   15      ; ???
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
left:   .word   15
base:   .word   16
.endparams

.params error_pos
left:   .word   69
base:   .word   16
.endparams

farg:   .byte   $00,$00,$00,$00,$00,$00

.params title_bar_bitmap      ; Params for MGTK::PaintBits
viewloc:        DEFINE_POINT 115, AS_WORD -9, viewloc
mapbits:        .addr   pixels
mapwidth:       .byte   1
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, 6, 5
        ;;  (not part of struct, but not referenced outside)
pixels: .byte   px(%1000001)
        .byte   px(%1010110)
        .byte   px(%1110001)
        .byte   px(%1110110)
        .byte   px(%0110110)
        .byte   px(%1001001)
.endparams

.params grafport
viewloc:        DEFINE_POINT 0, 0
mapbits:        .word   0
mapwidth:       .byte   0
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, 0, 0
pattern:        .res    8, 0
colormasks:     .byte   0, 0
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   0
penheight:      .byte   0
penmode:        .byte   0
textback:       .byte   0
textfont:       .addr   0
.endparams
        .assert * - grafport = 36, error

        .byte   0               ; ???

        kMenuBarHeight = 13

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

.params penmode_normal
penmode:   .byte   MGTK::pencopy
.endparams

        .byte   $01,$02         ; ??

.params penmode_xor
penmode:   .byte   MGTK::notpenXOR
.endparams

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
mincontlength:  .word   kWindowHeight
maxcontwidth:   .word   kWindowWidth
maxcontlength:  .word   kWindowHeight
left:           .word   kDefaultLeft
top:            .word   kDefaultTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
cliprect:       DEFINE_RECT 0, 0, kWindowWidth, kWindowHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   $7f
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams
openwindow_params_top := winfo::top

window_title:
        PASCAL_STRING "Calc"

;;; ==================================================
;;; DA Init

init:   MGTK_CALL MGTK::OpenWindow, winfo
        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::FlushEvents

        jsr     reset_buffer2

        jsr     draw_content
        jsr     reset_buffers_and_display

        lda     #'='            ; last kOperation
        sta     calc_op

        lda     #0              ; clear registers
        sta     calc_p
        sta     calc_d
        sta     calc_e
        sta     calc_n
        sta     calc_g
        sta     calc_l

.proc copy_to_b1
        ldx     #sizeof_chrget_routine + 4 ; should be just + 1 ?
loop:   lda     chrget_routine-1,x
        sta     CHRGET-1,x
        dex
        bne     loop
.endproc

        lda     #0
        sta     ERRFLG          ; Turn off errors
        sta     SHIFT_SIGN_EXT  ; Zero before using FP ops

        copy16  #error_hook, COUT_HOOK ; set up FP error handler

        lda     #1
        jsr     CALL_FLOAT
        ldxy    #farg
        jsr     CALL_ROUND
        lda     #0              ; set FAC to 0
        jsr     CALL_FLOAT
        jsr     CALL_FADD
        jsr     CALL_FOUT
        lda     #$07
        jsr     CALL_FMULT
        lda     #$00
        jsr     CALL_FLOAT
        ldxy    #farg
        jsr     CALL_ROUND

        tsx
        stx     saved_stack

        lda     #'='
        jsr     process_key
        lda     #'C'
        jsr     process_key


;;; ============================================================
;;; Input Loop

input_loop:
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jsr     on_click
        jmp     input_loop

:       cmp     #MGTK::EventKind::key_down
        bne     input_loop
        jsr     on_key_press
        jmp     input_loop

;;; ============================================================
;;; On Click

on_click:
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        bcc     ignore_click
        lda     findwindow_params::window_id
        cmp     #kDAWindowId      ; This window?
        beq     :+

ignore_click:
        rts

:       lda     findwindow_params::which_area
        cmp     #MGTK::Area::content ; Content area?
        bne     :+

        jsr     map_click_to_button ; try to translate click into key
        bcc     ignore_click
        jmp     process_key

:       cmp     #MGTK::Area::close_box ; Close box?
        bne     :+
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway
        beq     ignore_click

exit:   MGTK_CALL MGTK::CloseWindow, closewindow_params
        ITK_CALL IconTK::RedrawIcons
        jmp     exit_da

:       cmp     #MGTK::Area::dragbar ; Title bar?
        bne     ignore_click
        lda     #kDAWindowId
        sta     dragwindow_params::window_id
        MGTK_CALL MGTK::DragWindow, dragwindow_params
        jsr     redraw_screen_and_window
        rts

;;; ============================================================
;;; On Key Press

.proc on_key_press
        lda     event_params::modifiers
        bne     bail
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        bne     trydel
        lda     calc_p
        bne     clear           ; empty state?
        lda     calc_l
        beq     exit            ; if so, exit DA
clear:  lda     #'C'            ; otherwise turn Escape into Clear

trydel: cmp     #CHAR_DELETE    ; Delete?
        beq     :+
        cmp     #'`'            ; lowercase range?
        bcc     :+
        and     #$5F            ; convert to uppercase
:       jmp     process_key
bail:
.endproc

rts1:  rts                     ; used by next proc

;;; ============================================================
;;; Try to map a click to a button

;;; If a button was clicked, carry is set and accum has key char

.proc map_click_to_button
        lda     #kDAWindowId
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     screentowindow_params::windowx+1        ; ensure high bits of coords are 0
        ora     screentowindow_params::windowy+1
        bne     rts1
        lda     screentowindow_params::windowy
        ldx     screentowindow_params::windowx

.proc find_button_row
        cmp     #kRow1Top+kBorderLeftTop - 1 ; row 1 ? (- 1 is bug in original?)
        bcc     miss
        cmp     #kRow1Bot+kBorderBottomRight + 1 ; (+ 1 is bug in original?)
        bcs     :+
        jsr     find_button_col
        bcc     miss
        lda     row1_lookup,x
        rts

:       cmp     #kRow2Top-kBorderLeftTop             ; row 2?
        bcc     miss
        cmp     #kRow2Bot+kBorderBottomRight
        bcs     :+
        jsr     find_button_col
        bcc     miss
        lda     row2_lookup,x
        rts

:       cmp     #kRow3Top-kBorderLeftTop             ; row 3?
        bcc     miss
        cmp     #kRow3Bot+kBorderBottomRight
        bcs     :+
        jsr     find_button_col
        bcc     miss
        lda     row3_lookup,x
        rts

:       cmp     #kRow4Top-kBorderLeftTop             ; row 4?
        bcc     miss
        cmp     #kRow4Bot+kBorderBottomRight
        bcs     :+
        jsr     find_button_col
        bcc     miss
        sec
        lda     row4_lookup,x
        rts

:       cmp     #kRow5Top-kBorderLeftTop             ; special case for tall + button
        bcs     :+
        lda     screentowindow_params::windowx
        cmp     #kCol4Left-kBorderLeftTop
        bcc     miss
        cmp     #kCol4Right+kBorderBottomRight-1         ; is -1 bug in original?
        bcs     miss
        lda     #'+'
        sec
        rts

:       cmp     #kRow5Bot+kBorderBottomRight             ; row 5?
        bcs     miss
        jsr     find_button_col
        bcc     :+
        lda     row5_lookup,x
        rts

:       lda     screentowindow_params::windowx ; special case for wide 0 button
        cmp     #kCol1Left-kBorderLeftTop
        bcc     miss
        cmp     #kCol2Right+kBorderBottomRight
        bcs     miss
        lda     #'0'
        sec
        rts

miss:   clc
        rts
.endproc

        row1_lookup := *-1
        .byte   'C', 'E', '=', '*'
        row2_lookup := *-1
        .byte   '7', '8', '9', '/'
        row3_lookup := *-1
        .byte   '4', '5', '6', '-'
        row4_lookup := *-1
        .byte   '1', '2', '3', '+'
        row5_lookup := *-1
        .byte   '0', '0', '.', '+'

.proc find_button_col
        cpx     #kCol1Left-kBorderLeftTop             ; col 1?
        bcc     miss
        cpx     #kCol1Right+kBorderBottomRight
        bcs     :+
        ldx     #1
        sec
        rts

:       cpx     #kCol2Left-kBorderLeftTop             ; col 2?
        bcc     miss
        cpx     #kCol2Right+kBorderBottomRight
        bcs     :+
        ldx     #2
        sec
        rts

:       cpx     #kCol3Left-kBorderLeftTop             ; col 3?
        bcc     miss
        cpx     #kCol3Right+kBorderBottomRight
        bcs     :+
        ldx     #3
        sec
        rts

:       cpx     #kCol4Left-kBorderLeftTop            ; col 4?
        bcc     miss
        cpx     #kCol4Right+kBorderBottomRight - 1       ; bug in original?
        bcs     miss
        ldx     #4
        sec
        rts

miss:   clc
        rts
.endproc
.endproc

;;; ============================================================
;;; Handle Key

;;; Accumulator is set to key char. Also used by
;;; click handlers (button is mapped to key char)
;;; and during initialization (by sending 'C', etc)

.proc process_key
        cmp     #'C'            ; Clear?
        bne     :+
        ldxy    #btn_c::port
        lda     #'c'
        jsr     depress_button
        lda     #0
        jsr     CALL_FLOAT
        ldxy    #farg
        jsr     CALL_ROUND
        lda     #'='
        sta     calc_op
        lda     #0
        sta     calc_p
        sta     calc_l
        sta     calc_d
        sta     calc_e
        sta     calc_n
        jmp     reset_buffers_and_display

:       cmp     #'E'            ; Exponential?
        bne     try_eq
        ldxy    #btn_e::port
        lda     #'e'
        jsr     depress_button
        ldy     calc_e
        bne     rts1
        ldy     calc_l
        bne     :+
        inc     calc_l
        lda     #'1'
        sta     text_buffer1 + kTextBufferSize
        sta     text_buffer2 + kTextBufferSize
:       lda     #'E'
        sta     calc_e
        jmp     update

rts1:   rts

try_eq: cmp     #'='            ; Equals?
        bne     :+
        pha
        ldxy    #btn_eq::port
        jmp     do_op_click

:       cmp     #'*'            ; Multiply?
        bne     :+
        pha
        ldxy    #btn_mul::port
        jmp     do_op_click

:       cmp     #'.'            ; Decimal?
        bne     try_add
        ldxy    #btn_dec::port
        jsr     depress_button
        lda     calc_d
        ora     calc_e
        bne     rts2
        lda     calc_l
        bne     :+
        inc     calc_l
:       lda     #'.'
        sta     calc_d
        jmp     update

rts2:   rts

try_add:cmp     #'+'            ; Add?
        bne     :+
        pha
        ldxy    #btn_add::port
        jmp     do_op_click

:       cmp     #'-'            ; Subtract?
        bne     trydiv
        pha
        ldxy    #btn_sub::port
        lda     calc_e          ; negate vs. subtract
        beq     :+
        lda     calc_n
        bne     :+
        sec
        ror     calc_n
        pla
        pha
        jmp     do_digit_click

:       pla
        pha
        jmp     do_op_click

trydiv: cmp     #'/'            ; Divide?
        bne     :+
        pha
        ldxy    #btn_div::port
        jmp     do_op_click

:       cmp     #'0'            ; Digit 0?
        bne     :+
        pha
        ldxy    #btn_0::port
        jmp     do_digit_click

:       cmp     #'1'            ; Digit 1?
        bne     :+
        pha
        ldxy    #btn_1::port
        jmp     do_digit_click

:       cmp     #'2'            ; Digit 2?
        bne     :+
        pha
        ldxy    #btn_2::port
        jmp     do_digit_click

:       cmp     #'3'            ; Digit 3?
        bne     :+
        pha
        ldxy    #btn_3::port
        jmp     do_digit_click

:       cmp     #'4'            ; Digit 4?
        bne     :+
        pha
        ldxy    #btn_4::port
        jmp     do_digit_click

:       cmp     #'5'            ; Digit 5?
        bne     :+
        pha
        ldxy    #btn_5::port
        jmp     do_digit_click

:       cmp     #'6'            ; Digit 6?
        bne     :+
        pha
        ldxy    #btn_6::port
        jmp     do_digit_click

:       cmp     #'7'            ; Digit 7?
        bne     :+
        pha
        ldxy    #btn_7::port
        jmp     do_digit_click

:       cmp     #'8'            ; Digit 8?
        bne     :+
        pha
        ldxy    #btn_8::port
        jmp     do_digit_click

:       cmp     #'9'            ; Digit 9?
        bne     :+
        pha
        ldxy    #btn_9::port
        jmp     do_digit_click

:       cmp     #CHAR_DELETE    ; Delete?
        bne     end
        ldy     calc_l
        beq     end
        cpy     #1
        bne     :+
        jsr     reset_buffer1_and_state
        jmp     display_buffer1

:       dec     calc_l
        ldx     #0
        lda     text_buffer1 + kTextBufferSize
        cmp     #'.'
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
        jmp     display_buffer1

end:    rts
.endproc

do_digit_click:
        jsr     depress_button
        bne     :+
        pla
        rts

:       pla
update: sec
        ror     calc_g
        ldy     calc_l
        bne     :+
        pha
        jsr     reset_buffer2
        pla
        cmp     #'0'
        bne     :+
        jmp     display_buffer1

:       sec
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
        jmp     display_buffer1

rts3:   rts

.proc do_op_click
        jsr     depress_button
        bne     :+
        pla
        rts

:       lda     calc_op
        cmp     #'='
        bne     :+
        lda     calc_g
        bne     reparse
        lda     #0
        jsr     CALL_FLOAT
        jmp     do_op

:       lda     calc_g
        bne     reparse
        pla
        sta     calc_op
        jmp     reset_buffer1_and_state

reparse:copy16  #text_buffer1, TXTPTR
        jsr     CHRGET
        jsr     CALL_FIN

do_op:  pla
        ldx     calc_op
        sta     calc_op
        lda     #<farg
        ldy     #>farg

        cpx     #'+'
        bne     :+
        jsr     CALL_FADD
        jmp     post_op

:       cpx     #'-'
        bne     :+
        jsr     CALL_FSUB
        jmp     post_op

:       cpx     #'*'
        bne     :+
        jsr     CALL_FMULT
        jmp     post_op

:       cpx     #'/'
        bne     :+
        jsr     CALL_FDIV
        jmp     post_op

:       cpx     #'='
        bne     post_op
        ldy     calc_g
        bne     post_op
        jmp     reset_buffer1_and_state
.endproc

.proc post_op
        ldxy    #farg          ; after the FP kOperation is done
        jsr     CALL_ROUND
        jsr     CALL_FOUT            ; output as null-terminated string to FBUFFR

        ldy     #0              ; count the eize
sloop:  lda     FBUFFR,y
        beq     :+
        iny
        bne     sloop

:       ldx     #kTextBufferSize ; copy to text buffers
cloop:  lda     FBUFFR-1,y
        sta     text_buffer1,x
        sta     text_buffer2,x
        dex
        dey
        bne     cloop

        cpx     #0              ; pad out with spaces if needed
        bmi     end
pad:    lda     #' '
        sta     text_buffer1,x
        sta     text_buffer2,x
        dex
        bpl     pad
end:    jsr     display_buffer1
        ; fall through
.endproc
.proc reset_buffer1_and_state
        jsr     reset_buffer1
        lda     #0
        sta     calc_l
        sta     calc_d
        sta     calc_e
        sta     calc_n
        sta     calc_g
        rts
.endproc

.proc depress_button
        stxy    invert_addr
        stxy    inrect_params
        stxy    restore_addr

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

invert:  MGTK_CALL MGTK::PaintRect, 0, invert_addr ; Inverts port

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
        beq     :+
        MGTK_CALL MGTK::PaintRect, 0, restore_addr ; Inverts back to normal
:       MGTK_CALL MGTK::SetPenMode, penmode_normal ; Normal draw mode??
        lda     button_state
        rts
.endproc

;;; ============================================================
;;; Value Display

.proc reset_buffer1
        ldy     #kTextBufferSize
loop:   lda     #' '
        sta     text_buffer1-1,y
        dey
        bne     loop
        lda     #'0'
        sta     text_buffer1 + kTextBufferSize
        rts
.endproc

.proc reset_buffer2
        ldy     #kTextBufferSize
loop:   lda     #' '
        sta     text_buffer2-1,y
        dey
        bne     loop
        lda     #'0'
        sta     text_buffer2 + kTextBufferSize
        rts
.endproc

.proc reset_buffers_and_display
        jsr     reset_buffer1
        jsr     reset_buffer2
        ; fall through
.endproc
.proc display_buffer1
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        cmp     #MGTK::Error::window_obscured
        beq     end
        MGTK_CALL MGTK::SetPort, grafport
        ldxy    #text_buffer1
        jsr     pre_display_buffer
        MGTK_CALL MGTK::DrawText, drawtext_params1
end:    rts
.endproc

.proc display_buffer2
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        cmp     #MGTK::Error::window_obscured
        beq     end
        MGTK_CALL MGTK::SetPort, grafport
        ldxy    #text_buffer2
        jsr     pre_display_buffer
        MGTK_CALL MGTK::DrawText, drawtext_params2
end:    rts
.endproc

.proc pre_display_buffer
        stx     textwidth_params::textptr ; text buffer address in x,y
        sty     textwidth_params::textptr+1
        MGTK_CALL MGTK::TextWidth, textwidth_params
        lda     #kDisplayWidth-15 ; ???
        sec
        sbc     textwidth_params::result
        sta     text_pos_params3::left
        MGTK_CALL MGTK::MoveTo, text_pos_params2 ; clear with spaces
        MGTK_CALL MGTK::DrawText, spaces_string
        MGTK_CALL MGTK::MoveTo, text_pos_params3 ; set up for display
        rts
.endproc

;;; ============================================================
;;; Draw the window contents (background, buttons)

.proc draw_content
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

        copy16  #btn_c, ptr
loop:   ldy     #0
        lda     (ptr),y
        beq     draw_title_bar  ; done!

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
        lda     (ptr),y
        sta     label

        MGTK_CALL MGTK::PaintBits, 0, bitmap_addr ; draw shadowed rect
        MGTK_CALL MGTK::MoveTo, 0, text_addr         ; button label pos
        MGTK_CALL MGTK::DrawText, drawtext_params_label  ; button label text

        lda     ptr             ; advance to next record
        clc
        adc     #.sizeof(btn_c)
        sta     ptr
        bcc     loop
        inc     ptr+1
        jmp     loop
.endproc

;;; ============================================================
;;; Draw the title bar decoration

draw_title_bar:
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
        MGTK_CALL MGTK::PaintBits, title_bar_bitmap     ; Draws decoration in title bar
        MGTK_CALL MGTK::ShowCursor
        jsr     display_buffer2
        rts

        ;; Traps FP error via call to $36 from MON.COUT, resets stack
        ;; and returns to the input loop.
.proc error_hook
        lda     LCBANK1
        lda     LCBANK1
        jsr     reset_buffers_and_display

        MGTK_CALL MGTK::GetWinPort, getwinport_params
        cmp     #MGTK::Error::window_obscured
        beq     :+
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::MoveTo, error_pos
        MGTK_CALL MGTK::DrawText, error_string

:       jsr     reset_buffer1_and_state
        lda     #'='
        sta     calc_op
        ldx     saved_stack
        txs
        jmp     input_loop
.endproc

PROC_AT chrget_routine, $B1  ; CHRGET ("Constant expression expected" error if label used)
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

.macro CALL_FP proc
        pha
        lda     ROMIN2
        pla
        jsr     proc
        pha
        lda     LCBANK1
        lda     LCBANK1
        pla
        rts
.endmacro


CALL_FLOAT:
        CALL_FP FLOAT

CALL_FADD:
        CALL_FP FADD

CALL_FSUB:
        CALL_FP FSUB

CALL_FMULT:
        CALL_FP FMULT

CALL_FDIV:
        CALL_FP FDIV

CALL_FIN:
        CALL_FP FIN

CALL_FOUT:
        CALL_FP FOUT

CALL_ROUND:
        CALL_FP ROUND

da_end := *
