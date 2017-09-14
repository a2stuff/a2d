        .setcpu "65C02"
        .org $800

        .include "apple2.inc"
        .include "../inc/prodos.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/applesoft.inc"

        .include "a2d.inc"

adjust_txtptr := $B1

ROMIN2          := $C082
COUT_HOOK       := $36

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

.proc  exit_da
        lda     LCBANK1
        lda     LCBANK1
        ldx     save_stack
        txs
        rts
.endproc

;;; ==================================================

call_init:
        lda     ROMIN2
        jmp     L0D18

        ;; Used after a drag-and-drop is completed;
        ;; redraws the window.
.proc call_4015_main

        zp_stash := $20

        ;; Call jump table entry $4015 in main memory, by
        ;; copying a trampoline routine to the ZP.

        lda     LCBANK1
        lda     LCBANK1
        ldx     #(routine_end - routine)
:       lda     routine,x
        sta     zp_stash,x
        dex
        bpl     :-
        jsr     zp_stash

        ;;  Redraw window after drag
        lda     ROMIN2
        lda     #window_id
        jsr     draw_window

        ;; ???
        lda     LCBANK1
        lda     LCBANK1
        bit     L089D
        bmi     skip
        jsr     UNKNOWN_CALL
        .byte   $0C
        .addr   0

        ;; ???
skip:   lda     #0
        sta     L089D
        lda     ROMIN2
        A2D_CALL A2D_QUERY_STATE, query_state_params
        A2D_CALL A2D_SET_STATE, state_params
        rts

.proc routine
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_15
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc
        routine_end := *
.endproc

;;; ==================================================


L089D:  .byte   0

        ;; Called after window drag is complete
        ;; (called with window_id in A)
.proc draw_window
        sta     query_state_params_id
        lda     create_window_params_top
        cmp     #screen_height - 1
        bcc     :+
        lda     #$80
        sta     L089D
        rts

:       A2D_CALL A2D_QUERY_STATE, query_state_params
        A2D_CALL A2D_SET_STATE, state_params
        lda     query_state_params_id
        cmp     #window_id
        bne     :+
        jmp     draw_background
:       rts
.endproc

;;; ==================================================
;;; Call Params (and other data)

        ;; The following params blocks overlap for data re-use

.proc map_coords_params
id      := *
screen  := * + 1
screenx := * + 1 ; aligns with input_state::xcoord
screeny := * + 3 ; aligns with input_state::ycoord
client  := * + 5
clientx := * + 5
clienty := * + 7
.endproc

.proc drag_params
id      := *
xcoord  := * + 1 ; aligns with input_state::xcoord
ycoord  := * + 3 ; aligns with input_state::ycoord
.endproc

.proc input_state_params
state:  .byte   0
xcoord    := *                  ; if state is 0,1,2,4
ycoord    := * + 2              ; "
key       := *                  ; if state is 3
modifiers := * + 1              ; "
.endproc

.proc target_params
queryx: .word   0               ; aligns with input_state_params::xcoord
queryy: .word   0               ; aligns with input_state_params::ycoord
elem:   .byte   0
id:     .byte   0
.endproc

        .byte 0, 0              ; fills out space for map_coords_params
        .byte 0, 0              ; ???

.proc close_click_params
state:  .byte   0
.endproc

.proc query_state_params
id:     .byte   0
        .addr   state_params
.endproc
        query_state_params_id := query_state_params::id

        ;; param block for a 1A call
L08D4:  .byte   $80

        ;; param block for a 1A call
L08D5:  .byte   $00

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
        .word   col1_left - border_lt
        .word   row1_top - border_lt
        .addr   button_pattern
        .byte   pattern_stride
        .byte   $00,$00,$00,$00,$00 ; ???
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   'c'
pos:    .word   col1_left + 6, row1_bot
box:    .word   col1_left,row1_top,col1_right,row1_bot
.endproc

.proc btn_e
        .word   col2_left - border_lt
        .word   row1_top - border_lt
        .addr   button_pattern
        .byte   pattern_stride
        .byte   $00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   'e'
        .word   col2_left + 6, row1_bot
box:    .word   col2_left,row1_top,col2_right,row1_bot
.endproc

.proc btn_eq
        .word   col3_left - border_lt
        .word   row1_top - border_lt
        .addr   button_pattern
        .byte   pattern_stride
        .byte   $00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '='
        .word   col3_left + 6, row1_bot
box:    .word   col3_left,row1_top,col3_right,row1_bot
.endproc

.proc btn_mul
        .word   col4_left - border_lt
        .word   row1_top - border_lt
        .addr   button_pattern
        .byte   pattern_stride
        .byte   $00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '*'
        .word   col4_left + 6, row1_bot
box:    .word   col4_left,row1_top,col4_right,row1_bot
.endproc

.proc btn_7
        .word   col1_left - border_lt
        .word   row2_top - border_lt
        .addr   button_pattern
        .byte   pattern_stride
        .byte   $00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '7'
        .word   col1_left + 6, row2_bot
box:    .word   col1_left,row2_top,col1_right,row2_bot
.endproc

.proc btn_8
        .word   col2_left - border_lt
        .word   row2_top - border_lt
        .addr   button_pattern
        .byte   pattern_stride
        .byte   $00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '8'
        .word   col2_left + 6, row2_bot
box:    .word   col2_left,row2_top,col2_right,row2_bot
.endproc

.proc btn_9
        .word   col3_left - border_lt
        .word   row2_top - border_lt
        .addr   button_pattern
        .byte   pattern_stride
        .byte   $00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '9'
        .word   col3_left + 6, row2_bot
box:    .word   col3_left,row2_top,col3_right,row2_bot
.endproc

.proc btn_div
        .word   col4_left - border_lt
        .word   row2_top - border_lt
        .addr   button_pattern
        .byte   pattern_stride
        .byte   $00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '/'
        .word   col4_left + 6, row2_bot
box:    .word   col4_left,row2_top,col4_right,row2_bot
.endproc

.proc btn_4
        .word   col1_left - border_lt
        .word   row3_top - border_lt
        .addr   button_pattern
        .byte   pattern_stride
        .byte   $00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '4'
        .word   col1_left + 6, row3_bot
box:    .word   col1_left,row3_top,col1_right,row3_bot
.endproc

.proc btn_5
        .word   col2_left - border_lt
        .word   row3_top - border_lt
        .addr   button_pattern
        .byte   pattern_stride
        .byte   $00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '5'
        .word   col2_left + 6, row3_bot
box:    .word   col2_left,row3_top,col2_right,row3_bot
.endproc

.proc btn_6
        .word   col3_left - border_lt
        .word   row3_top - border_lt
        .addr   button_pattern
        .byte   pattern_stride
        .byte   $00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '6'
        .word   col3_left + 6, row3_bot
box:    .word   col3_left,row3_top,col3_right,row3_bot
.endproc

.proc btn_sub
        .word   col4_left - border_lt
        .word   row3_top - border_lt
        .addr   button_pattern
        .byte   pattern_stride
        .byte   $00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '-'
        .word   col4_left + 6, row3_bot
box:    .word   col4_left,row3_top,col4_right,row3_bot
.endproc

.proc btn_1
        .word   col1_left - border_lt
        .word   row4_top - border_lt
        .addr   button_pattern
        .byte   pattern_stride
        .byte   $00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '1'
        .word   col1_left + 6, row4_bot
box:    .word   col1_left,row4_top,col1_right,row4_bot
.endproc

.proc btn_2
        .word   col2_left - border_lt
        .word   row4_top - border_lt
        .addr   button_pattern
        .byte   pattern_stride
        .byte   $00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '2'
        .word   col2_left + 6, row4_bot
box:    .word   col2_left,row4_top,col2_right,row4_bot
.endproc

.proc btn_3
        .word   col3_left - border_lt
        .word   row4_top - border_lt
        .addr   button_pattern
        .byte   pattern_stride
        .byte   $00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '3'
        .word   col3_left + 6, row4_bot
box:    .word   col3_left,row4_top,col3_right,row4_bot
.endproc

.proc btn_0
        .word   col1_left - border_lt
        .word   row5_top - border_lt
        .addr   wide_button_pattern
        .byte   8                   ; pattern_stride (bytes)
        .byte   $00,$00,$00,$00,$00
        .word   49                      ; 0 is extra wide
        .word   button_height + border_lt + border_br
        .byte   '0'
        .word   col1_left + 6, row5_bot
box:    .word   col1_left,row5_top,col2_right,row5_bot
.endproc

.proc btn_dec
        .word   col3_left - border_lt
        .word   row5_top - border_lt
        .addr   button_pattern
        .byte   pattern_stride
        .byte   $00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
        .byte   '.'
        .word   col3_left + 6 + 2, row5_bot ; + 2 to center the label
box:    .word   col3_left,row5_top,col3_right,row5_bot
.endproc

.proc btn_add
        .word   col4_left - border_lt
        .word   row4_top - border_lt
        .addr   tall_button_pattern
        .byte   pattern_stride
        .byte   $00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   27              ; + is extra tall
        .byte   '+'
        .word   col4_left + 6, row5_bot
box:    .word   col4_left,row4_top,col4_right,row5_bot
.endproc
        .byte   0               ; sentinel

        ;; Button patterns. These are used as bitmaps for
        ;; drawing the shadowed buttons.

        ;; patterns are low 7 bits, 0=black 1=white
        pattern_stride   := 3    ; bytes
button_pattern:                 ; pattern for normal buttons
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

        wide_pattern_stride := 8
wide_button_pattern:            ; pattern for '0' button
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

tall_button_pattern:            ; pattern for '+' button
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
L0BC5:  .byte   $00             ; high bit set if pending op?
calc_op:.byte   $00
calc_d: .byte   $00             ; '.' if decimal present, 0 otherwise
calc_e: .byte   $00             ; exponential?
calc_n: .byte   $00             ; negative?
L0BCA:  .byte   $00             ; related to = key
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

        ;; ???
L0BEF:  .byte   $7F

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
.proc draw_text_params_label
        .addr   label
        .byte   1
.endproc
label:  .byte   0               ; modified with char to draw

.proc draw_text_params1
addr:   .addr   text_buffer1
length: .byte   15
.endproc

text_buffer_size := 14

text_buffer1:
        .res    text_buffer_size+2, 0

.proc draw_text_params2
addr:   .addr   text_buffer2
length: .byte   15
.endproc

text_buffer2:
        .res    text_buffer_size+2, 0

spaces_string:
        A2D_DEFSTRING "          "
error_string:
        A2D_DEFSTRING "Error "

        ;;  used when clearing display; params to a $18 call
.proc measure_text_params
addr:   .addr   text_buffer1
len:    .byte   15              ; ???
width:  .word   0
.endproc

        window_id = $34

.proc destroy_window_params
id:     .byte   window_id
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

.proc title_bar_decoration      ; Params for A2D_DRAW_PATTERN
left:   .word   115             ; overwritten
top:    .word   $FFF7           ; overwritten
pattern:.addr   pixels
stride: .byte   1
        .byte   0,0,0,0,0       ; ???
width:  .word   6
height: .word   5
        ;;  (not part of struct, but not referenced outside)
pixels: .byte   px(%1000001)
        .byte   px(%1010110)
        .byte   px(%1110001)
        .byte   px(%1110110)
        .byte   px(%0110110)
        .byte   px(%1001001)
.endproc

        ;; param block for a QUERY_SCREEN and SET_STATE calls, and ref'd in QUERY_STATE call
.proc state_params
left:   .word   0
top:    .word   0
addr:   .word   0
stride: .word   0
hoffset:.word   0
voffset:.word   0
width:  .word   0
height: .word   0
pattern:.res    8, 0
mskand: .byte   0
mskor:  .byte   0
        .byte   0,0,0,0       ; ???
hthick: .byte   0
vthick: .byte   0
        .byte   0,0,0,0,0       ; ???
.endproc

        menu_bar_height := 13
        screen_width    := 560
        screen_height   := 192

        ;; params for A2D_SET_BOX when decorating title bar
.proc screen_box
        .word   0
        .word   menu_bar_height
        .word   A2D_SCREEN_ADDR
        .word   A2D_SCREEN_STRIDE
        .word   0, 0            ; hoffset/voffset
        .word   screen_width - 1
        .word   screen_height - menu_bar_height - 2
.endproc

.proc fill_mode_normal
mode:   .byte   A2D_SFM_NORMAL
.endproc

        .byte   $01,$02         ; ??

.proc fill_mode_xor
mode:   .byte   A2D_SFM_XOR
.endproc

        window_width := 130
        window_height := 96
        default_left := 210
        default_top := 60

.proc create_window_params
id:     .byte   window_id
flags:  .byte   $02
        .addr   title
hscroll:.byte   0
vscroll:.byte   0
hs_max: .byte   0
hs_pos: .byte   0
vs_max: .byte   0
vs_pos: .byte   0
        .byte   0,0             ; ???
w1:     .word   window_width
h1:     .word   window_height
w2:     .word   window_width
h2:     .word   window_height
left:   .word   default_left
top:    .word   default_top
        .word   A2D_SCREEN_ADDR
        .word   A2D_SCREEN_STRIDE
hoffset:.word   0
voffset:.word   0
width:  .word   window_width
height: .word   window_height
pattern:.res    8, $FF
mskand: .byte   $FF
mskor:  .byte   $00
        .byte   0,0,0,0       ; ???
hthick: .byte   1
vthick: .byte   1
        .byte   $00,$7F,$00,$88,$00,$00 ; ???
.endproc
create_window_params_top := create_window_params::top

title:  PASCAL_STRING "Calc"

        ;; param block for $24 call (just before entering input loop)
L0CE6:  .byte   $00,$00,$02,$00,$06,$00,$0E,$00
        .byte   $1E,$00,$3E,$00,$7E,$00,$1A,$00
        .byte   $30,$00,$30,$00,$60,$00,$00,$00
        .byte   $03,$00,$07,$00,$0F,$00,$1F,$00
        .byte   $3F,$00,$7F,$00,$7F,$01,$7F,$00
        .byte   $78,$00,$78,$00,$70,$01,$70,$01
        .byte   $01,$01

;;; ==================================================
;;; DA Init

L0D18:  sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        A2D_CALL $1A, L08D4
        A2D_CALL A2D_CREATE_WINDOW, create_window_params
        A2D_CALL A2D_QUERY_SCREEN, state_params
        A2D_CALL A2D_SET_STATE, state_params     ; set clipping bounds?
        A2D_CALL $2B                          ; reset drawing state?
        lda     #$01
        sta     input_state_params::state
        A2D_CALL $2D, input_state_params
        A2D_CALL A2D_GET_INPUT, input_state_params
        lda     ROMIN2
        jsr     reset_buffer2
        lda     #window_id
        jsr     draw_window
        jsr     reset_buffers_and_display

        lda     #'='            ; last operation
        sta     calc_op

        lda     #0              ; clear registers
        sta     L0BC5
        sta     calc_d
        sta     calc_e
        sta     calc_n
        sta     L0BCA
        sta     calc_l

.proc copy_to_b1
        ldx     #(end_adjust_txtptr_copied - adjust_txtptr_copied + 4) ; should be just + 1 ?
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
        jsr     FLOAT
        ldx     #<farg
        ldy     #>farg
        jsr     ROUND
        lda     #0              ; set FAC to 0
        jsr     FLOAT
        jsr     FADD
        jsr     FOUT
        lda     #$07
        jsr     FMULT
        lda     #$00
        jsr     FLOAT
        ldx     #<farg
        ldy     #>farg
        jsr     ROUND

        tsx
        stx     saved_stack

        lda     #'='
        jsr     process_key
        lda     #'C'
        jsr     process_key

        A2D_CALL $24, L0CE6
        ;; fall through

;;; ==================================================
;;; Input Loop

input_loop:
        A2D_CALL A2D_GET_INPUT, input_state_params
        lda     input_state_params::state
        cmp     #A2D_INPUT_DOWN
        bne     :+
        jsr     on_click
        jmp     input_loop

:       cmp     #A2D_INPUT_KEY
        bne     input_loop
        jsr     on_key_press
        jmp     input_loop

;;; ==================================================
;;; On Click

on_click:
        lda     LCBANK1
        lda     LCBANK1
        A2D_CALL A2D_QUERY_TARGET, target_params
        lda     ROMIN2
        lda     target_params::elem
        cmp     #A2D_ELEM_CLIENT ; Less than CLIENT is MENU or DESKTOP
        bcc     ignore_click
        lda     target_params::id
        cmp     #window_id      ; This window?
        beq     :+

ignore_click:
        rts

:       lda     target_params::elem
        cmp     #A2D_ELEM_CLIENT ; Client area?
        bne     :+
        jsr     map_click_to_button ; try to translate click into key
        bcc     ignore_click
        jmp     process_key

:       cmp     #A2D_ELEM_CLOSE ; Close box?
        bne     :+
        A2D_CALL A2D_CLOSE_CLICK, close_click_params
        lda     close_click_params::state
        beq     ignore_click
exit:   lda     LCBANK1
        lda     LCBANK1
        A2D_CALL A2D_DESTROY_WINDOW, destroy_window_params
        jsr     UNKNOWN_CALL
        .byte   $0C
        .addr   0
        lda     ROMIN2
        A2D_CALL $1A, L08D5     ; ??? one byte input value?

.proc do_close
        ;; Copy following routine to ZP and invoke it
        zp_stash := $20

        ldx     #(routine_end - routine)
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
        routine_end := *        ; Can't use .sizeof before the .proc definition
.endproc

:       cmp     #A2D_ELEM_TITLE ; Title bar?
        bne     ignore_click
        lda     #window_id
        sta     drag_params::id
        lda     LCBANK1
        lda     LCBANK1
        A2D_CALL A2D_DRAG_WINDOW, drag_params
        lda     ROMIN2
        jsr     call_4015_main  ; redraws window
        rts

;;; ==================================================
;;; On Key Press

.proc on_key_press
        lda     input_state_params::modifiers
        bne     bail
        lda     input_state_params::key
        cmp     #$1B            ; Escape?
        bne     trydel
        lda     L0BC5
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
L0E94:  rts                     ; used by prev/next proc

;;; ==================================================
;;; Try to map a click to a button

;;; If a button was clicked, carry is set and accum has key char

.proc map_click_to_button
        lda     #window_id
        sta     map_coords_params::id
        A2D_CALL A2D_MAP_COORDS, map_coords_params
        lda     map_coords_params::clientx+1        ; ensure high bits of coords are 0
        ora     map_coords_params::clienty+1
        bne     L0E94
        lda     map_coords_params::clienty
        ldx     map_coords_params::clientx

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
        lda     map_coords_params::clientx
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

:       lda     map_coords_params::clientx ; special case for wide 0 button
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

:       cpx     #col4_left-border_lt             ; col 4?
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
        ldx     #<btn_c::box
        ldy     #>btn_c::box
        lda     #'c'
        jsr     depress_button
        lda     #$00
        jsr     FLOAT
        ldx     #<farg
        ldy     #>farg
        jsr     ROUND
        lda     #'='
        sta     calc_op
        lda     #0
        sta     L0BC5
        sta     calc_l
        sta     calc_d
        sta     calc_e
        sta     calc_n
        jmp     reset_buffers_and_display

:       cmp     #'E'            ; Exponential?
        bne     L0FC7
        ldx     #<btn_e::box
        ldy     #>btn_e::box
        lda     #'e'
        jsr     depress_button
        ldy     calc_e
        bne     L0FC6
        ldy     calc_l
        bne     :+
        inc     calc_l
        lda     #'1'
        sta     text_buffer1 + text_buffer_size
        sta     text_buffer2 + text_buffer_size
:       lda     #'E'
        sta     calc_e
        jmp     L1107

L0FC6:  rts

L0FC7:  cmp     #'='            ; Equals?
        bne     :+
        pha
        ldx     #<btn_eq::box
        ldy     #>btn_eq::box
        jmp     L114C

:       cmp     #'*'            ; Multiply?
        bne     :+
        pha
        ldx     #<btn_mul::box
        ldy     #>btn_mul::box
        jmp     L114C

:       cmp     #'.'            ; Decimal?
        bne     L1003
        ldx     #<btn_dec::box
        ldy     #>btn_dec::box
        jsr     depress_button
        lda     calc_d
        ora     calc_e
        bne     L1002
        lda     calc_l
        bne     :+
        inc     calc_l
:       lda     #'.'
        sta     calc_d
        jmp     L1107

L1002:  rts

L1003:  cmp     #'+'            ; Add?
        bne     :+
        pha
        ldx     #<btn_add::box
        ldy     #>btn_add::box
        jmp     L114C

:       cmp     #'-'            ; Subtract?
        bne     trydiv
        pha
        ldx     #<btn_sub::box
        ldy     #>btn_sub::box
        lda     calc_e           ; negate vs. subtract
        beq     :+
        lda     calc_n
        bne     :+
        sec
        ror     calc_n
        pla
        pha
        jmp     L10FF

:       pla
        pha
        jmp     L114C

trydiv: cmp     #'/'            ; Divide?
        bne     :+
        pha
        ldx     #<btn_div::box
        ldy     #>btn_div::box
        jmp     L114C

:       cmp     #'0'            ; Digit 0?
        bne     :+
        pha
        ldx     #<btn_0::box
        ldy     #>btn_0::box
        jmp     L10FF

:       cmp     #'1'            ; Digit 1?
        bne     :+
        pha
        ldx     #<btn_1::box
        ldy     #>btn_1::box
        jmp     L10FF

:       cmp     #'2'            ; Digit 2?
        bne     :+
        pha
        ldx     #<btn_2::box
        ldy     #>btn_2::box
        jmp     L10FF

:       cmp     #'3'            ; Digit 3?
        bne     :+
        pha
        ldx     #<btn_3::box
        ldy     #>btn_3::box
        jmp     L10FF

:       cmp     #'4'            ; Digit 4?
        bne     :+
        pha
        ldx     #<btn_4::box
        ldy     #>btn_4::box
        jmp     L10FF

:       cmp     #'5'            ; Digit 5?
        bne     :+
        pha
        ldx     #<btn_5::box
        ldy     #>btn_5::box
        jmp     L10FF

:       cmp     #'6'            ; Digit 6?
        bne     :+
        pha
        ldx     #<btn_6::box
        ldy     #>btn_6::box
        jmp     L10FF

:       cmp     #'7'            ; Digit 7?
        bne     :+
        pha
        ldx     #<btn_7::box
        ldy     #>btn_7::box
        jmp     L10FF

:       cmp     #'8'            ; Digit 8?
        bne     :+
        pha
        ldx     #<btn_8::box
        ldy     #>btn_8::box
        jmp     L10FF

:       cmp     #'9'            ; Digit 9?
        bne     :+
        pha
        ldx     #<btn_9::box
        ldy     #>btn_9::box
        jmp     L10FF

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

L10FF:  jsr     depress_button
        bne     L1106
        pla
        rts

L1106:  pla
L1107:  sec
        ror     L0BCA
        ldy     calc_l
        bne     L111C
        pha
        jsr     reset_buffer2
        pla
        cmp     #$30
        bne     L111C
        jmp     display_buffer1

L111C:  sec
        ror     L0BC5
        cpy     #$0A
        bcs     L114B
        pha
        ldy     calc_l
        beq     L113E
        lda     #$0F
        sec
        sbc     calc_l
        tax
L1131:  lda     text_buffer1,x
        sta     text_buffer1-1,x
        sta     text_buffer2-1,x
        inx
        dey
        bne     L1131
L113E:  inc     calc_l
        pla
        sta     text_buffer1 + text_buffer_size
        sta     text_buffer2 + text_buffer_size
        jmp     display_buffer1

L114B:  rts

L114C:  jsr     depress_button
        bne     L1153
        pla
        rts

L1153:  lda     calc_op
        cmp     #'='
        bne     :+
        lda     L0BCA
        bne     L1173
        lda     #$00
        jsr     FLOAT
        jmp     L1181

:       lda     L0BCA
        bne     L1173
        pla
        sta     calc_op
        jmp     reset_buffer1_and_state

L1173:  lda     #<text_buffer1
        sta     TXTPTR
        lda     #>text_buffer1
        sta     TXTPTR+1
        jsr     adjust_txtptr
        jsr     FIN
L1181:  pla
        ldx     calc_op
        sta     calc_op           ; Operation
        lda     #<farg
        ldy     #>farg

        cpx     #'+'
        bne     :+
        jsr     FADD
        jmp     post_op

:       cpx     #'-'
        bne     :+
        jsr     FSUB
        jmp     post_op

:       cpx     #'*'
        bne     :+
        jsr     FMULT
        jmp     post_op

:       cpx     #'/'
        bne     :+
        jsr     FDIV
        jmp     post_op

:       cpx     #'='
        bne     post_op
        ldy     L0BCA
        bne     post_op
        jmp     reset_buffer1_and_state

.proc post_op
        ldx     #<farg          ; after the FP operation is done
        ldy     #>farg
        jsr     ROUND
        jsr     FOUT            ; output as null-terminated string to FBUFFR

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
        sta     L0BCA
        rts
.endproc

.proc depress_button
        button_state := $FC

        stx     invert_addr
        stx     c13_addr
        stx     restore_addr
        sty     invert_addr+1
        sty     c13_addr+1
        sty     restore_addr+1
        A2D_CALL A2D_SET_PATTERN, black_pattern
        A2D_CALL A2D_SET_FILL_MODE, fill_mode_xor
        sec
        ror     button_state

invert:  A2D_CALL A2D_FILL_RECT, 0, invert_addr ; Inverts box

check_button:
        A2D_CALL A2D_GET_INPUT, input_state_params
        lda     input_state_params::state
        cmp     #A2D_INPUT_HELD ; Button down?
        bne     done            ; Nope, done immediately
        lda     #window_id
        sta     map_coords_params::id

        A2D_CALL A2D_MAP_COORDS, map_coords_params
        A2D_CALL A2D_SET_POS, map_coords_params::client
        A2D_CALL A2D_TEST_BOX, 0, c13_addr
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
        A2D_CALL A2D_FILL_RECT, 0, restore_addr ; Inverts back to normal
:       A2D_CALL A2D_SET_FILL_MODE, fill_mode_normal ; Normal draw mode??
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
        ldx     #<text_buffer1
        ldy     #>text_buffer1
        jsr     pre_display_buffer
        A2D_CALL A2D_DRAW_TEXT, draw_text_params1
        rts
.endproc

.proc display_buffer2
        ldx     #<text_buffer2
        ldy     #>text_buffer2
        jsr     pre_display_buffer
        A2D_CALL A2D_DRAW_TEXT, draw_text_params2
        rts
.endproc

.proc pre_display_buffer
        stx     measure_text_params::addr ; text buffer address in x,y
        sty     measure_text_params::addr+1
        A2D_CALL A2D_MEASURE_TEXT, measure_text_params
        lda     #display_width-15 ; ???
        sec
        sbc     measure_text_params::width
        sta     text_pos_params3::left
        A2D_CALL A2D_SET_POS, text_pos_params2 ; clear with spaces
        A2D_CALL A2D_DRAW_TEXT, spaces_string
        A2D_CALL A2D_SET_POS, text_pos_params3 ; set up for display
        rts
.endproc

;;; ==================================================
;;; Draw the window contents (background, buttons)

.proc draw_background
        ;; Frame
        A2D_CALL A2D_HIDE_CURSOR
        A2D_CALL A2D_SET_PATTERN, background_pattern
        A2D_CALL A2D_FILL_RECT, background_box_params
        A2D_CALL A2D_SET_PATTERN, black_pattern
        A2D_CALL A2D_DRAW_RECT, frame_display_params
        A2D_CALL A2D_SET_PATTERN, white_pattern
        A2D_CALL A2D_FILL_RECT, clear_display_params

        A2D_CALL $0C, L0BEF     ; ???
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
        sta     pattern_addr
        ldy     ptr+1
        sty     pattern_addr+1

        clc                     ; address for label pos
        adc     #(btn_c::pos - btn_c)
        sta     text_addr
        bcc     :+
        iny
:       sty     text_addr+1

        ldy     #(btn_c::label - btn_c) ; label
        lda     (ptr),y
        sta     label

        A2D_CALL A2D_DRAW_PATTERN, 0, pattern_addr ; draw shadowed rect
        A2D_CALL A2D_SET_POS, 0, text_addr         ; button label pos
        A2D_CALL A2D_DRAW_TEXT, draw_text_params_label  ; button label text

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
        ldx     create_window_params::left+1
        lda     create_window_params::left
        clc
        adc     #offset_left
        sta     title_bar_decoration::left
        bcc     :+
        inx
:       stx     title_bar_decoration::left+1
        ldx     create_window_params::top+1
        lda     create_window_params::top
        sec
        sbc     #offset_top
        sta     title_bar_decoration::top
        bcs     :+
        dex
:       stx     title_bar_decoration::top+1
        A2D_CALL A2D_SET_BOX, screen_box ; set clipping rect to whole screen
        A2D_CALL A2D_DRAW_PATTERN, title_bar_decoration     ; Draws decoration in title bar
        lda     #window_id
        sta     query_state_params::id
        A2D_CALL A2D_QUERY_STATE, query_state_params
        A2D_CALL A2D_SET_STATE, state_params
        A2D_CALL A2D_SHOW_CURSOR
        jsr     display_buffer2
        rts

        ;; Traps FP error via call to $36 from MON.COUT, resets stack
        ;; and returns to the input loop.
.proc error_hook
        jsr     reset_buffers_and_display
        A2D_CALL A2D_SET_POS, error_pos
        A2D_CALL A2D_DRAW_TEXT, error_string
        jsr     reset_buffer1_and_state
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
        end_adjust_txtptr_copied := *

da_end := *
