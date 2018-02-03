        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/applesoft.inc"
        .include "../inc/prodos.inc"

        .include "../mgtk.inc"
        .include "../desktop.inc" ; redraw icons after window move; font

        .org $800

adjust_txtptr := $B1

;;; ==================================================
;;; Start of the code

start:  jmp     copy2aux

save_stack:  .byte   0

;;; ==================================================
;;; Duplicate the DA (code and data) to AUX memory,
;;; then invoke the code in AUX.

.proc copy2aux
        tsx
        stx     save_stack

        start   := call_init
        end     := da_end
        dest    := start

        ;; Copy the DA to AUX memory.
        lda     ROMIN2
        lda     #<start
        sta     STARTLO
        lda     #>start
        sta     STARTHI
        lda     #<end
        sta     ENDLO
        lda     #>end
        sta     ENDHI
        lda     #<dest
        sta     DESTINATIONLO
        lda     #>dest
        sta     DESTINATIONHI
        sec                     ; main>aux
        jsr     AUXMOVE

        ;; Invoke it.
        lda     #<start
        sta     XFERSTARTLO
        lda     #>start
        sta     XFERSTARTHI
        php
        pla
        ora     #$40            ; set overflow: use aux zp/stack
        pha
        plp
        sec                     ; control main>aux
        jmp     XFER
.endproc

;;; ==================================================

.proc exit_da
        lda     LCBANK1
        lda     LCBANK1
        ldx     save_stack
        txs
        rts
.endproc

;;; ==================================================

call_init:
        jmp     init

        ;; Used after a event_kind_drag-and-drop is completed;
        ;; redraws the window.
.proc redraw_screen_and_window

        ;; Redraw the desktop (by copying trampoline to ZP)
        zp_stash := $20
        lda     LCBANK1
        lda     LCBANK1
        ldx     #sizeof_routine
:       lda     routine,x
        sta     zp_stash,x
        dex
        bpl     :-
        jsr     zp_stash

        lda     LCBANK1
        lda     LCBANK1

        bit     offscreen_flag ; if was offscreen, don't bother redrawing
        bmi     :+
        DESKTOP_CALL DESKTOP_REDRAW_ICONS

        ;;  Redraw window after event_kind_drag
        lda     #da_window_id
        jsr     check_visibility_and_draw_window

        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, port_params
        rts

.proc routine
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_REDRAW_ALL
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc
        sizeof_routine := * - routine
.endproc

;;; ==================================================

        ;; Set when the client area is offscreen and
        ;; should not be painted.
offscreen_flag:
        .byte   0

        ;; Called after window event_kind_drag is complete
        ;; (called with window_id in A)
.proc check_visibility_and_draw_window
        sta     getwinport_params_window_id
        lda     openwindow_params_top
        cmp     #screen_height - 1
        bcc     :+
        lda     #$80
        sta     offscreen_flag
        rts

:       lda     #0
        sta     offscreen_flag

        ;; Is skipping this responsible for display redraw bug?
        ;; https://github.com/inexorabletash/a2d/issues/34
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, port_params
        lda     getwinport_params_window_id
        cmp     #da_window_id
        bne     :+
        jmp     draw_background
:       rts
.endproc

;;; ==================================================
;;; Call Params (and other data)

        ;; The following params blocks overlap for data re-use

.proc screentowindow_params
window_id      := *
screen  := * + 1
screenx := * + 1 ; aligns with event_params::xcoord
screeny := * + 3 ; aligns with event_params::ycoord
window  := * + 5
windowx := * + 5
windowy := * + 7
.endproc

.proc dragwindow_params
window_id      := *
xcoord  := * + 1 ; aligns with event_params::xcoord
ycoord  := * + 3 ; aligns with event_params::ycoord
moved   := * + 5 ; ignored
.endproc

.proc event_params
kind:  .byte   0
xcoord    := *                  ; if state is 0,1,2,4
ycoord    := * + 2              ; "
key       := *                  ; if state is 3
modifiers := * + 1              ; "
.endproc

.proc findwindow_params
mousex: .word   0               ; aligns with event_params::xcoord
mousey: .word   0               ; aligns with event_params::ycoord
area:   .byte   0
window_id:     .byte   0
.endproc

        .byte 0, 0              ; fills out space for screentowindow_params
        .byte 0, 0              ; ???

.proc trackgoaway_params
goaway:  .byte   0
.endproc

.proc getwinport_params
window_id:     .byte   0
        .addr   port_params
.endproc
        getwinport_params_window_id := getwinport_params::window_id

.proc preserve_zp_params
flag:  .byte   MGTK::zp_preserve
.endproc

.proc overwrite_zp_params
flag:  .byte   MGTK::zp_overwrite
.endproc

;;; ==================================================
;;; Button Definitions

        button_width := 17
        button_height := 9

        col1_left := 13
        col1_right := col1_left+button_width ; 30
        col2_left := 42
        col2_right := col2_left+button_width ; 59
        col3_left := 70
        col3_right := col3_left+button_width ; 87
        col4_left := 98
        col4_right := col4_left+button_width ; 115

        row1_top := 22
        row1_bot := row1_top+button_height ; 31
        row2_top := 38
        row2_bot := row2_top+button_height ; 47
        row3_top := 53
        row3_bot := row3_top+button_height ; 62
        row4_top := 68
        row4_bot := row4_top+button_height ; 77
        row5_top := 83
        row5_bot := row5_top+button_height ; 92

        border_lt := 1          ; border width pixels (left/top)
        border_br := 2          ; (bottom/right)

.proc btn_c
viewloc:        DEFINE_POINT col1_left - border_lt, row1_top - border_lt
mapbits: .addr   button_bitmap
mapwidth: .byte   bitmap_stride
reserved: .byte 0
maprect:         DEFINE_RECT 0, 0, button_width + border_lt + border_br, button_height + border_lt + border_br
label:  .byte   'c'
pos:    .word   col1_left + 6, row1_bot
port:    .word   col1_left,row1_top,col1_right,row1_bot
.endproc

.proc btn_e
viewloc:        DEFINE_POINT col2_left - border_lt, row1_top - border_lt
mapbits: .addr   button_bitmap
mapwidth: .byte   bitmap_stride
reserved: .byte 0
maprect:         DEFINE_RECT 0, 0, button_width + border_lt + border_br, button_height + border_lt + border_br
label:  .byte   'e'
pos:    .word   col2_left + 6, row1_bot
port:    .word   col2_left,row1_top,col2_right,row1_bot
.endproc

.proc btn_eq
viewloc:        DEFINE_POINT col3_left - border_lt, row1_top - border_lt
mapbits: .addr   button_bitmap
mapwidth: .byte   bitmap_stride
reserved: .byte 0
maprect:         DEFINE_RECT 0, 0, button_width + border_lt + border_br, button_height + border_lt + border_br
label:  .byte   '='
pos:    .word   col3_left + 6, row1_bot
port:    .word   col3_left,row1_top,col3_right,row1_bot
.endproc

.proc btn_mul
viewloc:        DEFINE_POINT col4_left - border_lt, row1_top - border_lt
mapbits: .addr   button_bitmap
mapwidth: .byte   bitmap_stride
reserved: .byte 0
maprect:         DEFINE_RECT 0, 0, button_width + border_lt + border_br, button_height + border_lt + border_br
label:  .byte   '*'
pos:    .word   col4_left + 6, row1_bot
port:    .word   col4_left,row1_top,col4_right,row1_bot
.endproc

.proc btn_7
viewloc:        DEFINE_POINT col1_left - border_lt, row2_top - border_lt
mapbits: .addr   button_bitmap
mapwidth: .byte   bitmap_stride
reserved: .byte 0
maprect:         DEFINE_RECT 0, 0, button_width + border_lt + border_br, button_height + border_lt + border_br
label:  .byte   '7'
pos:    .word   col1_left + 6, row2_bot
port:    .word   col1_left,row2_top,col1_right,row2_bot
.endproc

.proc btn_8
viewloc:        DEFINE_POINT col2_left - border_lt, row2_top - border_lt
mapbits: .addr   button_bitmap
mapwidth: .byte   bitmap_stride
reserved: .byte 0
maprect:         DEFINE_RECT 0, 0, button_width + border_lt + border_br, button_height + border_lt + border_br
label:  .byte   '8'
pos:    .word   col2_left + 6, row2_bot
port:    .word   col2_left,row2_top,col2_right,row2_bot
.endproc

.proc btn_9
viewloc:        DEFINE_POINT col3_left - border_lt, row2_top - border_lt
mapbits: .addr   button_bitmap
mapwidth: .byte   bitmap_stride
reserved: .byte 0
maprect:         DEFINE_RECT 0, 0, button_width + border_lt + border_br, button_height + border_lt + border_br
label:  .byte   '9'
pos:    .word   col3_left + 6, row2_bot
port:    .word   col3_left,row2_top,col3_right,row2_bot
.endproc

.proc btn_div
viewloc:        DEFINE_POINT col4_left - border_lt, row2_top - border_lt
mapbits: .addr   button_bitmap
mapwidth: .byte   bitmap_stride
reserved: .byte 0
maprect:         DEFINE_RECT 0, 0, button_width + border_lt + border_br, button_height + border_lt + border_br
label:  .byte   '/'
pos:    .word   col4_left + 6, row2_bot
port:    .word   col4_left,row2_top,col4_right,row2_bot
.endproc

.proc btn_4
viewloc:        DEFINE_POINT col1_left - border_lt, row3_top - border_lt
mapbits: .addr   button_bitmap
mapwidth: .byte   bitmap_stride
reserved: .byte 0
maprect:         DEFINE_RECT 0, 0, button_width + border_lt + border_br, button_height + border_lt + border_br
label:  .byte   '4'
pos:    .word   col1_left + 6, row3_bot
port:    .word   col1_left,row3_top,col1_right,row3_bot
.endproc

.proc btn_5
viewloc:        DEFINE_POINT col2_left - border_lt, row3_top - border_lt
mapbits: .addr   button_bitmap
mapwidth: .byte   bitmap_stride
reserved: .byte 0
maprect:         DEFINE_RECT 0, 0, button_width + border_lt + border_br, button_height + border_lt + border_br
label:  .byte   '5'
pos:    .word   col2_left + 6, row3_bot
port:    .word   col2_left,row3_top,col2_right,row3_bot
.endproc

.proc btn_6
viewloc:        DEFINE_POINT col3_left - border_lt, row3_top - border_lt
mapbits: .addr   button_bitmap
mapwidth: .byte   bitmap_stride
reserved: .byte 0
maprect:         DEFINE_RECT 0, 0, button_width + border_lt + border_br, button_height + border_lt + border_br
label:  .byte   '6'
pos:    .word   col3_left + 6, row3_bot
port:    .word   col3_left,row3_top,col3_right,row3_bot
.endproc

.proc btn_sub
viewloc:        DEFINE_POINT col4_left - border_lt, row3_top - border_lt
mapbits: .addr   button_bitmap
mapwidth: .byte   bitmap_stride
reserved: .byte 0
maprect:         DEFINE_RECT 0, 0, button_width + border_lt + border_br, button_height + border_lt + border_br
label:  .byte   '-'
pos:    .word   col4_left + 6, row3_bot
port:    .word   col4_left,row3_top,col4_right,row3_bot
.endproc

.proc btn_1
viewloc:        DEFINE_POINT col1_left - border_lt, row4_top - border_lt
mapbits: .addr   button_bitmap
mapwidth: .byte   bitmap_stride
reserved: .byte 0
maprect:         DEFINE_RECT 0, 0, button_width + border_lt + border_br, button_height + border_lt + border_br
label:  .byte   '1'
pos:    .word   col1_left + 6, row4_bot
port:    .word   col1_left,row4_top,col1_right,row4_bot
.endproc

.proc btn_2
viewloc:        DEFINE_POINT col2_left - border_lt, row4_top - border_lt
mapbits: .addr   button_bitmap
mapwidth: .byte   bitmap_stride
reserved: .byte 0
maprect:         DEFINE_RECT 0, 0, button_width + border_lt + border_br, button_height + border_lt + border_br
label:  .byte   '2'
pos:    .word   col2_left + 6, row4_bot
port:    .word   col2_left,row4_top,col2_right,row4_bot
.endproc

.proc btn_3
viewloc:        DEFINE_POINT col3_left - border_lt, row4_top - border_lt
mapbits: .addr   button_bitmap
mapwidth: .byte   bitmap_stride
reserved: .byte 0
maprect:         DEFINE_RECT 0, 0, button_width + border_lt + border_br, button_height + border_lt + border_br
label:  .byte   '3'
pos:    .word   col3_left + 6, row4_bot
port:    .word   col3_left,row4_top,col3_right,row4_bot
.endproc

.proc btn_0
viewloc:        DEFINE_POINT col1_left - border_lt, row5_top - border_lt
mapbits: .addr   wide_button_bitmap
mapwidth: .byte   8                   ; bitmap_stride (bytes)
reserved: .byte 0
maprect:         DEFINE_RECT 0, 0, 49, button_height + border_lt + border_br ; 0 is extra wide
label:  .byte   '0'
pos:    .word   col1_left + 6, row5_bot
port:    .word   col1_left,row5_top,col2_right,row5_bot
.endproc

.proc btn_dec
viewloc:        DEFINE_POINT col3_left - border_lt, row5_top - border_lt
mapbits: .addr   button_bitmap
mapwidth: .byte   bitmap_stride
reserved: .byte 0
maprect:         DEFINE_RECT 0, 0, button_width + border_lt + border_br, button_height + border_lt + border_br
label:  .byte   '.'
pos:    .word   col3_left + 6 + 2, row5_bot ; + 2 to center the label
port:    .word   col3_left,row5_top,col3_right,row5_bot
.endproc

.proc btn_add
viewloc:        DEFINE_POINT col4_left - border_lt, row4_top - border_lt
mapbits: .addr   tall_button_bitmap
mapwidth: .byte   bitmap_stride
reserved: .byte 0
maprect:         DEFINE_RECT 0, 0, button_width + border_lt + border_br, 27 ; + is extra tall
label:  .byte   '+'
pos:    .word   col4_left + 6, row5_bot
port:    .word   col4_left,row4_top,col4_right,row5_bot
.endproc
        .byte   0               ; sentinel

        ;; Button bitmaps. These are used as bitmaps for
        ;; drawing the shadowed buttons.

        ;; bitmaps are low 7 bits, 0=black 1=white
        bitmap_stride   := 3    ; bytes
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

        wide_bitmap_stride := 8
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


;;; ==================================================
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

;;; ==================================================
;;; Miscellaneous param blocks

.proc background_box_params
left:   .word   1
top:    .word   0
right:  .word   129
bottom: .word   96
.endproc

background_pattern:
        .byte   $77,$DD,$77,$DD,$77,$DD,$77,$DD
        .byte   $00

black_pattern:
        .res    8, $00
        .byte   $00

white_pattern:
        .res    8, $FF
        .byte   $00

.proc settextbg_params
backcolor:  .byte   $7F
.endproc

        display_left    := 10
        display_top     := 5
        display_width   := 120
        display_height  := 17

.proc frame_display_params
left:   .word   display_left
top:    .word   display_top
width:  .word   display_width
height: .word   display_height
.endproc

.proc clear_display_params
left:   .word   display_left+1
top:    .word   display_top+1
width:  .word   display_width-1
height: .word   display_height-1
.endproc

        ;; For drawing 1-character strings (button labels)
.proc drawtext_params_label
        .addr   label
        .byte   1
.endproc
label:  .byte   0               ; modified with char to draw

.proc drawtext_params1
textptr:   .addr   text_buffer1
textlen: .byte   15
.endproc

text_buffer_size := 14

text_buffer1:
        .res    text_buffer_size+2, 0

.proc drawtext_params2
textptr:   .addr   text_buffer2
textlen: .byte   15
.endproc

text_buffer2:
        .res    text_buffer_size+2, 0

spaces_string:
        DEFINE_STRING "          "
error_string:
        DEFINE_STRING "Error "

        ;;  used when clearing display; params to a $18 call
.proc textwidth_params
textptr:   .addr   text_buffer1
textlen:    .byte   15              ; ???
result:  .word   0
.endproc

        da_window_id = 52

.proc closewindow_params
window_id:     .byte   da_window_id
.endproc

.proc text_pos_params3
left:   .word   0
base:   .word   16
.endproc

.proc text_pos_params2
left:   .word   15
base:   .word   16
.endproc

.proc error_pos
left:   .word   69
base:   .word   16
.endproc

farg:   .byte   $00,$00,$00,$00,$00,$00

.proc title_bar_decoration      ; Params for MGTK::PaintBits
left:   .word   115             ; overwritten
top:    .word   $FFF7           ; overwritten
mapbits:.addr   pixels
mapwidth: .byte   1
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, 6, 5
        ;;  (not part of struct, but not referenced outside)
pixels: .byte   px(%1000001)
        .byte   px(%1010110)
        .byte   px(%1110001)
        .byte   px(%1110110)
        .byte   px(%0110110)
        .byte   px(%1001001)
.endproc

.proc port_params
viewloc:        DEFINE_POINT 0, 0
mapbits:   .word   0
mapwidth: .word   0
cliprect:       DEFINE_RECT 0, 0, 0, 0
pattern:.res    8, 0
colormasks:     .byte   0, 0
penloc: DEFINE_POINT 0, 0
penwidth: .byte   0
penheight: .byte   0
penmode:   .byte   0
textback:  .byte   0
textfont:   .addr   0
.endproc

        .byte   0,0             ; ???

        menu_bar_height := 13
        screen_width    := 560
        screen_height   := 192

        ;; params for MGTK::SetPortBits when decorating title bar
.proc screen_port
        .word   0
        .word   menu_bar_height
        .word   MGTK::screen_mapbits
        .word   MGTK::screen_mapwidth
        .word   0, 0            ; hoff/voff
        .word   screen_width - 1
        .word   screen_height - menu_bar_height - 2
.endproc

.proc penmode_normal
penmode:   .byte   MGTK::pencopy
.endproc

        .byte   $01,$02         ; ??

.proc penmode_xor
penmode:   .byte   MGTK::notpenXOR
.endproc

        window_width := 130
        window_height := 96
        default_left := 210
        default_top := 60

.proc winfo
window_id:     .byte   da_window_id
options:  .byte   MGTK::option_go_away_box
title:  .addr   window_title
hscroll:.byte   MGTK::scroll_option_none
vscroll:.byte   MGTK::scroll_option_none
hthumbmax: .byte   0
hthumbpos: .byte   0
vthumbmax: .byte   0
vthumbpos: .byte   0
status: .byte   0
reserved:       .byte 0
mincontwidth:     .word   window_width
mincontlength:     .word   window_height
maxcontwidth:     .word   window_width
maxcontlength:     .word   window_height
left:   .word   default_left
top:    .word   default_top
mapbits:   .addr   MGTK::screen_mapbits
mapwidth: .word   MGTK::screen_mapwidth
cliprect:       DEFINE_RECT 0, 0, window_width, window_height
pattern:.res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc: DEFINE_POINT 0, 0
penwidth: .byte   1
penheight: .byte   1
penmode:   .byte   0
textback:  .byte   0
textfont:   .addr   DEFAULT_FONT
nextwinfo:   .addr   0
.endproc
openwindow_params_top := winfo::top

window_title:
        PASCAL_STRING "Calc"

;;; ==================================================
;;; DA Init

init:   sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        MGTK_CALL MGTK::SetZP1, preserve_zp_params
        MGTK_CALL MGTK::OpenWindow, winfo
        MGTK_CALL MGTK::InitPort, port_params
        MGTK_CALL MGTK::SetPort, port_params
        MGTK_CALL MGTK::FlushEvents

        jsr     reset_buffer2

        lda     #da_window_id
        jsr     check_visibility_and_draw_window
        jsr     reset_buffers_and_display

        lda     #'='            ; last operation
        sta     calc_op

        lda     #0              ; clear registers
        sta     calc_p
        sta     calc_d
        sta     calc_e
        sta     calc_n
        sta     calc_g
        sta     calc_l

.proc copy_to_b1
        ldx     #sizeof_adjust_txtptr_copied + 4 ; should be just + 1 ?
loop:   lda     adjust_txtptr_copied-1,x
        sta     adjust_txtptr-1,x
        dex
        bne     loop
.endproc

        lda     #0              ; Turn off errors
        sta     ERRFLG

        lda     #<error_hook    ; set up FP error handler
        sta     COUT_HOOK
        lda     #>error_hook
        sta     COUT_HOOK+1

        lda     #1
        jsr     CALL_FLOAT
        ldx     #<farg
        ldy     #>farg
        jsr     CALL_ROUND
        lda     #0              ; set FAC to 0
        jsr     CALL_FLOAT
        jsr     CALL_FADD
        jsr     CALL_FOUT
        lda     #$07
        jsr     CALL_FMULT
        lda     #$00
        jsr     CALL_FLOAT
        ldx     #<farg
        ldy     #>farg
        jsr     CALL_ROUND

        tsx
        stx     saved_stack

        lda     #'='
        jsr     process_key
        lda     #'C'
        jsr     process_key

;;; ==================================================
;;; Input Loop

input_loop:
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::event_kind_button_down
        bne     :+
        jsr     on_click
        jmp     input_loop

:       cmp     #MGTK::event_kind_key_down
        bne     input_loop
        jsr     on_key_press
        jmp     input_loop

;;; ==================================================
;;; On Click

on_click:
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::area
        cmp     #MGTK::area_content ; Less than CLIENT is MENU or DESKTOP
        bcc     ignore_click
        lda     findwindow_params::window_id
        cmp     #da_window_id      ; This window?
        beq     :+

ignore_click:
        rts

:       lda     findwindow_params::area
        cmp     #MGTK::area_content ; Client area?
        bne     :+
        jsr     map_click_to_button ; try to translate click into key
        bcc     ignore_click
        jmp     process_key

:       cmp     #MGTK::area_close_box ; Close box?
        bne     :+
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway
        beq     ignore_click
exit:   MGTK_CALL MGTK::CloseWindow, closewindow_params
        DESKTOP_CALL DESKTOP_REDRAW_ICONS
        lda     ROMIN2
        MGTK_CALL MGTK::SetZP1, overwrite_zp_params

.proc do_close
        ;; Copy following routine to ZP and invoke it
        zp_stash := $20

        ldx     #sizeof_routine
loop:   lda     routine,x
        sta     zp_stash,x
        dex
        bpl     loop
        jmp     zp_stash

.proc routine
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jmp     exit_da
.endproc
        sizeof_routine := * - routine       ; Can't use .sizeof before the .proc definition
.endproc

:       cmp     #MGTK::area_dragbar ; Title bar?
        bne     ignore_click
        lda     #da_window_id
        sta     dragwindow_params::window_id
        MGTK_CALL MGTK::DragWindow, dragwindow_params
        jsr     redraw_screen_and_window
        rts

;;; ==================================================
;;; On Key Press

.proc on_key_press
        lda     event_params::modifiers
        bne     bail
        lda     event_params::key
        cmp     #KEY_ESCAPE
        bne     trydel
        lda     calc_p
        bne     clear           ; empty state?
        lda     calc_l
        beq     exit            ; if so, exit DA
clear:  lda     #'C'            ; otherwise turn Escape into Clear

trydel: cmp     #$7F            ; Delete?
        beq     :+
        cmp     #$60            ; lowercase range?
        bcc     :+
        and     #$5F            ; convert to uppercase
:       jmp     process_key
bail:
.endproc

rts1:  rts                     ; used by next proc

;;; ==================================================
;;; Try to map a click to a button

;;; If a button was clicked, carry is set and accum has key char

.proc map_click_to_button
        lda     #da_window_id
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        lda     screentowindow_params::windowx+1        ; ensure high bits of coords are 0
        ora     screentowindow_params::windowy+1
        bne     rts1
        lda     screentowindow_params::windowy
        ldx     screentowindow_params::windowx

.proc find_button_row
        cmp     #row1_top+border_lt - 1 ; row 1 ? (- 1 is bug in original?)
        bcc     miss
        cmp     #row1_bot+border_br + 1 ; (+ 1 is bug in original?)
        bcs     :+
        jsr     find_button_col
        bcc     miss
        lda     row1_lookup,x
        rts

:       cmp     #row2_top-border_lt             ; row 2?
        bcc     miss
        cmp     #row2_bot+border_br
        bcs     :+
        jsr     find_button_col
        bcc     miss
        lda     row2_lookup,x
        rts

:       cmp     #row3_top-border_lt             ; row 3?
        bcc     miss
        cmp     #row3_bot+border_br
        bcs     :+
        jsr     find_button_col
        bcc     miss
        lda     row3_lookup,x
        rts

:       cmp     #row4_top-border_lt             ; row 4?
        bcc     miss
        cmp     #row4_bot+border_br
        bcs     :+
        jsr     find_button_col
        bcc     miss
        sec
        lda     row4_lookup,x
        rts

:       cmp     #row5_top-border_lt             ; special case for tall + button
        bcs     :+
        lda     screentowindow_params::windowx
        cmp     #col4_left-border_lt
        bcc     miss
        cmp     #col4_right+border_br-1         ; is -1 bug in original?
        bcs     miss
        lda     #'+'
        sec
        rts

:       cmp     #row5_bot+border_br             ; row 5?
        bcs     miss
        jsr     find_button_col
        bcc     :+
        lda     row5_lookup,x
        rts

:       lda     screentowindow_params::windowx ; special case for wide 0 button
        cmp     #col1_left-border_lt
        bcc     miss
        cmp     #col2_right+border_br
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
        cpx     #col1_left-border_lt             ; col 1?
        bcc     miss
        cpx     #col1_right+border_br
        bcs     :+
        ldx     #1
        sec
        rts

:       cpx     #col2_left-border_lt             ; col 2?
        bcc     miss
        cpx     #col2_right+border_br
        bcs     :+
        ldx     #2
        sec
        rts

:       cpx     #col3_left-border_lt             ; col 3?
        bcc     miss
        cpx     #col3_right+border_br
        bcs     :+
        ldx     #3
        sec
        rts

:       cpx     #col4_left-border_lt            ; col 4?
        bcc     miss
        cpx     #col4_right+border_br - 1       ; bug in original?
        bcs     miss
        ldx     #4
        sec
        rts

miss:   clc
        rts
.endproc
.endproc

;;; ==================================================
;;; Handle Key

;;; Accumulator is set to key char. Also used by
;;; click handlers (button is mapped to key char)
;;; and during initialization (by sending 'C', etc)

.proc process_key
        cmp     #'C'            ; Clear?
        bne     :+
        ldx     #<btn_c::port
        ldy     #>btn_c::port
        lda     #'c'
        jsr     depress_button
        lda     #$00
        jsr     CALL_FLOAT
        ldx     #<farg
        ldy     #>farg
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
        ldx     #<btn_e::port
        ldy     #>btn_e::port
        lda     #'e'
        jsr     depress_button
        ldy     calc_e
        bne     rts1
        ldy     calc_l
        bne     :+
        inc     calc_l
        lda     #'1'
        sta     text_buffer1 + text_buffer_size
        sta     text_buffer2 + text_buffer_size
:       lda     #'E'
        sta     calc_e
        jmp     update

rts1:   rts

try_eq: cmp     #'='            ; Equals?
        bne     :+
        pha
        ldx     #<btn_eq::port
        ldy     #>btn_eq::port
        jmp     do_op_click

:       cmp     #'*'            ; Multiply?
        bne     :+
        pha
        ldx     #<btn_mul::port
        ldy     #>btn_mul::port
        jmp     do_op_click

:       cmp     #'.'            ; Decimal?
        bne     try_add
        ldx     #<btn_dec::port
        ldy     #>btn_dec::port
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
        ldx     #<btn_add::port
        ldy     #>btn_add::port
        jmp     do_op_click

:       cmp     #'-'            ; Subtract?
        bne     trydiv
        pha
        ldx     #<btn_sub::port
        ldy     #>btn_sub::port
        lda     calc_e           ; negate vs. subtract
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
        ldx     #<btn_div::port
        ldy     #>btn_div::port
        jmp     do_op_click

:       cmp     #'0'            ; Digit 0?
        bne     :+
        pha
        ldx     #<btn_0::port
        ldy     #>btn_0::port
        jmp     do_digit_click

:       cmp     #'1'            ; Digit 1?
        bne     :+
        pha
        ldx     #<btn_1::port
        ldy     #>btn_1::port
        jmp     do_digit_click

:       cmp     #'2'            ; Digit 2?
        bne     :+
        pha
        ldx     #<btn_2::port
        ldy     #>btn_2::port
        jmp     do_digit_click

:       cmp     #'3'            ; Digit 3?
        bne     :+
        pha
        ldx     #<btn_3::port
        ldy     #>btn_3::port
        jmp     do_digit_click

:       cmp     #'4'            ; Digit 4?
        bne     :+
        pha
        ldx     #<btn_4::port
        ldy     #>btn_4::port
        jmp     do_digit_click

:       cmp     #'5'            ; Digit 5?
        bne     :+
        pha
        ldx     #<btn_5::port
        ldy     #>btn_5::port
        jmp     do_digit_click

:       cmp     #'6'            ; Digit 6?
        bne     :+
        pha
        ldx     #<btn_6::port
        ldy     #>btn_6::port
        jmp     do_digit_click

:       cmp     #'7'            ; Digit 7?
        bne     :+
        pha
        ldx     #<btn_7::port
        ldy     #>btn_7::port
        jmp     do_digit_click

:       cmp     #'8'            ; Digit 8?
        bne     :+
        pha
        ldx     #<btn_8::port
        ldy     #>btn_8::port
        jmp     do_digit_click

:       cmp     #'9'            ; Digit 9?
        bne     :+
        pha
        ldx     #<btn_9::port
        ldy     #>btn_9::port
        jmp     do_digit_click

:       cmp     #$7F            ; Delete?
        bne     end
        ldy     calc_l
        beq     end
        cpy     #1
        bne     :+
        jsr     reset_buffer1_and_state
        jmp     display_buffer1

:       dec     calc_l
        ldx     #0
        lda     text_buffer1 + text_buffer_size
        cmp     #'.'
        bne     :+
        stx     calc_d
:       cmp     #'E'
        bne     :+
        stx     calc_e
:       cmp     #'-'
        bne     :+
        stx     calc_n
:       ldx     #text_buffer_size-1
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
        cpy     #$0A
        bcs     rts3
        pha
        ldy     calc_l
        beq     empty
        lda     #$0F
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
        sta     text_buffer1 + text_buffer_size
        sta     text_buffer2 + text_buffer_size
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
        lda     #$00
        jsr     CALL_FLOAT
        jmp     do_op

:       lda     calc_g
        bne     reparse
        pla
        sta     calc_op
        jmp     reset_buffer1_and_state

reparse:lda     #<text_buffer1
        sta     TXTPTR
        lda     #>text_buffer1
        sta     TXTPTR+1
        jsr     adjust_txtptr
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
        ldx     #<farg          ; after the FP operation is done
        ldy     #>farg
        jsr     CALL_ROUND
        jsr     CALL_FOUT            ; output as null-terminated string to FBUFFR

        ldy     #0              ; count the eize
sloop:  lda     FBUFFR,y
        beq     :+
        iny
        bne     sloop

:       ldx     #text_buffer_size ; copy to text buffers
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
        button_state := $FC

        stx     invert_addr
        stx     inrect_params
        stx     restore_addr
        sty     invert_addr+1
        sty     inrect_params+1
        sty     restore_addr+1
        MGTK_CALL MGTK::SetPattern, black_pattern
        MGTK_CALL MGTK::SetPenMode, penmode_xor
        sec
        ror     button_state

invert:  MGTK_CALL MGTK::PaintRect, 0, invert_addr ; Inverts port

check_button:
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::event_kind_drag ; Button down?
        bne     done            ; Nope, done immediately
        lda     #da_window_id
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

;;; ==================================================
;;; Value Display

.proc reset_buffer1
        ldy     #text_buffer_size
loop:   lda     #' '
        sta     text_buffer1-1,y
        dey
        bne     loop
        lda     #'0'
        sta     text_buffer1 + text_buffer_size
        rts
.endproc

.proc reset_buffer2
        ldy     #text_buffer_size
loop:   lda     #' '
        sta     text_buffer2-1,y
        dey
        bne     loop
        lda     #'0'
        sta     text_buffer2 + text_buffer_size
        rts
.endproc

.proc reset_buffers_and_display
        jsr     reset_buffer1
        jsr     reset_buffer2
        ; fall through
.endproc
.proc display_buffer1
        bit     offscreen_flag
        bmi     end
        ldx     #<text_buffer1
        ldy     #>text_buffer1
        jsr     pre_display_buffer
        MGTK_CALL MGTK::DrawText, drawtext_params1
end:    rts
.endproc

.proc display_buffer2
        bit     offscreen_flag
        bmi     end
        ldx     #<text_buffer2
        ldy     #>text_buffer2
        jsr     pre_display_buffer
        MGTK_CALL MGTK::DrawText, drawtext_params2
end:    rts
.endproc

.proc pre_display_buffer
        stx     textwidth_params::textptr ; text buffer address in x,y
        sty     textwidth_params::textptr+1
        MGTK_CALL MGTK::TextWidth, textwidth_params
        lda     #display_width-15 ; ???
        sec
        sbc     textwidth_params::result
        sta     text_pos_params3::left
        MGTK_CALL MGTK::MoveTo, text_pos_params2 ; clear with spaces
        MGTK_CALL MGTK::DrawText, spaces_string
        MGTK_CALL MGTK::MoveTo, text_pos_params3 ; set up for display
        rts
.endproc

;;; ==================================================
;;; Draw the window contents (background, buttons)

.proc draw_background
        ;; Frame
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::SetPattern, background_pattern
        MGTK_CALL MGTK::PaintRect, background_box_params
        MGTK_CALL MGTK::SetPattern, black_pattern
        MGTK_CALL MGTK::FrameRect, frame_display_params
        MGTK_CALL MGTK::SetPattern, white_pattern
        MGTK_CALL MGTK::PaintRect, clear_display_params
        MGTK_CALL MGTK::SetTextBG, settextbg_params
        ;; fall through
.endproc

.proc draw_buttons
        ;; Buttons
        ptr := $FA

        lda     #<btn_c
        sta     ptr
        lda     #>btn_c
        sta     ptr+1
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

;;; ==================================================
;;; Draw the title bar decoration

draw_title_bar:
        offset_left     := 115  ; pixels from left of client area
        offset_top      := 22   ; pixels from top of client area (up!)
        ldx     winfo::left+1
        lda     winfo::left
        clc
        adc     #offset_left
        sta     title_bar_decoration::left
        bcc     :+
        inx
:       stx     title_bar_decoration::left+1
        ldx     winfo::top+1
        lda     winfo::top
        sec
        sbc     #offset_top
        sta     title_bar_decoration::top
        bcs     :+
        dex
:       stx     title_bar_decoration::top+1
        MGTK_CALL MGTK::SetPortBits, screen_port ; set clipping rect to whole screen
        MGTK_CALL MGTK::PaintBits, title_bar_decoration     ; Draws decoration in title bar
        lda     #da_window_id
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, port_params
        MGTK_CALL MGTK::ShowCursor
        jsr     display_buffer2
        rts

        ;; Traps FP error via call to $36 from MON.COUT, resets stack
        ;; and returns to the input loop.
.proc error_hook
        lda     LCBANK1
        lda     LCBANK1
        jsr     reset_buffers_and_display
        bit     offscreen_flag
        bmi     :+
        MGTK_CALL MGTK::MoveTo, error_pos
        MGTK_CALL MGTK::DrawText, error_string
:       jsr     reset_buffer1_and_state
        lda     #'='
        sta     calc_op
        ldx     saved_stack
        txs
        jmp     input_loop
.endproc

        ;; Following proc is copied to $B1
.proc adjust_txtptr_copied
loop:   inc     TXTPTR
        bne     :+
        inc     TXTPTR+1
:       lda     $EA60           ; this ends up being aligned on TXTPTR
        cmp     #'9'+1          ; after digits?
        bcs     end
        cmp     #' '            ; space? keep going
        beq     loop
        sec
        sbc     #'0'            ; convert to digit...
        sec
        sbc     #$D0            ; carry set if successful
end:    rts
.endproc
        sizeof_adjust_txtptr_copied := * - adjust_txtptr_copied


CALL_FLOAT:
        pha
        lda     ROMIN2
        pla
        jsr     FLOAT
        pha
        lda     LCBANK1
        lda     LCBANK1
        pla
        rts

CALL_FADD:
        pha
        lda     ROMIN2
        pla
        jsr     FADD
        pha
        lda     LCBANK1
        lda     LCBANK1
        pla
        rts

CALL_FSUB:
        pha
        lda     ROMIN2
        jsr     FSUB
        pha
        lda     LCBANK1
        lda     LCBANK1
        pla
        rts

CALL_FMULT:
        pha
        lda     ROMIN2
        pla
        jsr     FMULT
        pha
        lda     LCBANK1
        lda     LCBANK1
        pla
        rts

CALL_FDIV:
        pha
        lda     ROMIN2
        pla
        jsr     FDIV
        pha
        lda     LCBANK1
        lda     LCBANK1
        pla
        rts

CALL_FIN:
        pha
        lda     ROMIN2
        pla
        jsr     FIN
        pha
        lda     LCBANK1
        lda     LCBANK1
        pla
        rts

CALL_FOUT:
        pha
        lda     ROMIN2
        pla
        jsr     FOUT
        pha
        lda     LCBANK1
        lda     LCBANK1
        pla
        rts

CALL_ROUND:
        pha
        lda     ROMIN2
        pla
        jsr     ROUND
        pha
        lda     LCBANK1
        lda     LCBANK1
        pla
        rts

da_end := *
