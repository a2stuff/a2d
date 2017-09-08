        .setcpu "65C02"
        .org $800

        .include "apple2.inc"
        .include "../inc/prodos.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/applesoft.inc"

        .include "a2d.inc"

L0020           := $0020

adjust_txtptr := $B1

ROMIN2          := $C082


start:  jmp     copy2aux

save_stack:  .byte   0

.proc copy2aux
        tsx
        stx     save_stack

        start   := call_init
        end     := da_end
        dest    := start

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

.proc L084C

        zp_stash := $20

        lda     LCBANK1
        lda     LCBANK1
        ldx     #(routine_end - routine)
L0854:  lda     routine,x
        sta     zp_stash,x
        dex
        bpl     L0854
        jsr     zp_stash
        lda     ROMIN2
        lda     #window_id
        jsr     L089E
        lda     LCBANK1
        lda     LCBANK1
        bit     L089D
        bmi     L0878
        jsr     UNKNOWN_CALL
        .byte   $0C
        .addr   0

L0878:  lda     #0
        sta     L089D
        lda     ROMIN2
        A2D_CALL $3C, L08D1
        A2D_CALL A2D_TEXT_BOX1, L0C6E
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
L089E:  sta     L08D1
        lda     L0CBD
        cmp     #$BF
        bcc     :+
        lda     #$80
        sta     L089D
        rts

:       A2D_CALL $3C, L08D1     ; After drag, maybe?
        A2D_CALL A2D_TEXT_BOX1, L0C6E
        lda     L08D1
        cmp     #window_id
        bne     L08C4
        jmp     draw_window

L08C4:  rts

;;; ==================================================
;;; Call Params (and other data)

.proc button_state_params
state:  .byte   0
.endproc
        ;;  falls through?

keychar:                        ; this params block is getting reused "creatively"
keydown := * + 1
tpp     := * + 4
clickx  := * + 4
clicky  := * + 6
.proc get_mouse_params
xcoord: .word   0
ycoord: .word   0
elem:   .byte   0
id:     .byte   0
        .word   0               ; ???
.endproc

        .byte $00,$00

.proc button_click_params
state:  .byte   0
.endproc

L08D1:  .byte   $00
        .addr   $0C6E

L08D4:  .byte   $80

        ;; button definitions

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

L08D5:  .byte   $00

.proc btn_c
        .word   col1_left - border_lt
        .word   row1_top - border_lt
        .addr   L0AE1
        .byte   $03,$00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   'c'
pos:    .word   col1_left + 6, row1_bot
box:    .word   col1_left,row1_top,col1_right,row1_bot
.endproc

.proc btn_e
        .word   col2_left - border_lt
        .word   row1_top - border_lt
        .addr   L0AE1
        .byte   $03,$00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   'e'
        .word   col2_left + 6, row1_bot
box:    .word   col2_left,row1_top,col2_right,row1_bot
.endproc

.proc btn_eq
        .word   col3_left - border_lt
        .word   row1_top - border_lt
        .addr   L0AE1
        .byte   $03,$00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '='
        .word   col3_left + 6, row1_bot
box:    .word   col3_left,row1_top,col3_right,row1_bot
.endproc

.proc btn_mul
        .word   col4_left - border_lt
        .word   row1_top - border_lt
        .addr   L0AE1
        .byte   $03,$00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '*'
        .word   col4_left + 6, row1_bot
box:    .word   col4_left,row1_top,col4_right,row1_bot
.endproc

.proc btn_7
        .word   col1_left - border_lt
        .word   row2_top - border_lt
        .addr   L0AE1
        .byte   $03,$00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '7'
        .word   col1_left + 6, row2_bot
box:    .word   col1_left,row2_top,col1_right,row2_bot
.endproc

.proc btn_8
        .word   col2_left - border_lt
        .word   row2_top - border_lt
        .addr   L0AE1
        .byte   $03,$00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '8'
        .word   col2_left + 6, row2_bot
box:    .word   col2_left,row2_top,col2_right,row2_bot
.endproc

.proc btn_9
        .word   col3_left - border_lt
        .word   row2_top - border_lt
        .addr   L0AE1
        .byte   $03,$00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '9'
        .word   col3_left + 6, row2_bot
box:    .word   col3_left,row2_top,col3_right,row2_bot
.endproc

.proc btn_div
        .word   col4_left - border_lt
        .word   row2_top - border_lt
        .addr   L0AE1
        .byte   $03,$00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '/'
        .word   col4_left + 6, row2_bot
box:    .word   col4_left,row2_top,col4_right,row2_bot
.endproc

.proc btn_4
        .word   col1_left - border_lt
        .word   row3_top - border_lt
        .addr   L0AE1
        .byte   $03,$00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '4'
        .word   col1_left + 6, row3_bot
box:    .word   col1_left,row3_top,col1_right,row3_bot
.endproc

.proc btn_5
        .word   col2_left - border_lt
        .word   row3_top - border_lt
        .addr   L0AE1
        .byte   $03,$00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '5'
        .word   col2_left + 6, row3_bot
box:    .word   col2_left,row3_top,col2_right,row3_bot
.endproc

.proc btn_6
        .word   col3_left - border_lt
        .word   row3_top - border_lt
        .addr   L0AE1
        .byte   $03,$00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '6'
        .word   col3_left + 6, row3_bot
box:    .word   col3_left,row3_top,col3_right,row3_bot
.endproc

.proc btn_sub
        .word   col4_left - border_lt
        .word   row3_top - border_lt
        .addr   L0AE1
        .byte   $03,$00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '-'
        .word   col4_left + 6, row3_bot
box:    .word   col4_left,row3_top,col4_right,row3_bot
.endproc

.proc btn_1
        .word   col1_left - border_lt
        .word   row4_top - border_lt
        .addr   L0AE1
        .byte   $03,$00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '1'
        .word   col1_left + 6, row4_bot
box:    .word   col1_left,row4_top,col1_right,row4_bot
.endproc

.proc btn_2
        .word   col2_left - border_lt
        .word   row4_top - border_lt
        .addr   L0AE1
        .byte   $03,$00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '2'
        .word   col2_left + 6, row4_bot
box:    .word   col2_left,row4_top,col2_right,row4_bot
.endproc

.proc btn_3
        .word   col3_left - border_lt
        .word   row4_top - border_lt
        .addr   L0AE1
        .byte   $03,$00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
label:  .byte   '3'
        .word   col3_left + 6, row4_bot
box:    .word   col3_left,row4_top,col3_right,row4_bot
.endproc

.proc btn_0
        .word   col1_left - border_lt
        .word   row5_top - border_lt
        .addr   L0B08           ; Why different ???
        .byte   $08,$00,$00,$00,$00,$00 ; ???
        .word   49                      ; 0 is extra wide
        .word   button_height + border_lt + border_br
        .byte   '0'
        .word   col1_left + 6, row5_bot
box:    .word   col1_left,row5_top,col2_right,row5_bot
.endproc

.proc btn_dec
        .word   col3_left - border_lt
        .word   row5_top - border_lt
        .addr   L0AE1
        .byte   $03,$00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   button_height + border_lt + border_br
        .byte   '.'
        .word   col3_left + 6 + 2, row5_bot ; + 2 to center the label
box:    .word   col3_left,row5_top,col3_right,row5_bot
.endproc

.proc btn_add
        .word   col4_left - border_lt
        .word   row4_top - border_lt
        .addr   L0B70
        .byte   $03,$00,$00,$00,$00,$00
        .word   button_width + border_lt + border_br
        .word   27              ; + is extra tall
        .byte   '+'
        .word   col4_left + 6, row5_bot
box:    .word   col4_left,row4_top,col4_right,row5_bot
.endproc
        .byte   0               ; sentinel

L0AE1:                          ; pattern for normal buttons
        .byte   $00,$00,$40,$7E
        .byte   $7F,$1F,$7E,$7F,$1F,$7E,$7F,$1F
        .byte   $7E,$7F,$1F,$7E,$7F,$1F,$7E,$7F
        .byte   $1F,$7E,$7F,$1F,$7E,$7F,$1F,$7E
        .byte   $7F,$1F,$7E,$7F,$1F,$00,$00,$00
        .byte   $01,$00,$00

L0B08:                          ; pattern for '0' button
        .byte   $00,$00,$00,$00,$00
        .byte   $00,$00,$7F,$7E,$7F,$7F,$7F,$7F
        .byte   $7F,$3F,$7E,$7E,$7F,$7F,$7F,$7F
        .byte   $7F,$3F,$7E,$7E,$7F,$7F,$7F,$7F
        .byte   $7F,$3F,$7E,$7E,$7F,$7F,$7F,$7F
        .byte   $7F,$3F,$7E,$7E,$7F,$7F,$7F,$7F
        .byte   $7F,$3F,$7E,$7E,$7F,$7F,$7F,$7F
        .byte   $7F,$3F,$7E,$7E,$7F,$7F,$7F,$7F
        .byte   $7F,$3F,$7E,$7E,$7F,$7F,$7F,$7F
        .byte   $7F,$3F,$7E,$7E,$7F,$7F,$7F,$7F
        .byte   $7F,$3F,$7E,$7E,$7F,$7F,$7F,$7F
        .byte   $7F,$3F,$7E,$00,$00,$00,$00,$00
        .byte   $00,$00,$7E,$01,$00,$00,$00,$00
        .byte   $00,$00,$7E

L0B70:                          ; pattern for '+' button
        .byte   $00,$00,$40,$7E,$7F
        .byte   $1F,$7E,$7F,$1F,$7E,$7F,$1F,$7E
        .byte   $7F,$1F,$7E,$7F,$1F,$7E,$7F,$1F
        .byte   $7E,$7F,$1F,$7E,$7F,$1F,$7E,$7F
        .byte   $1F,$7E,$7F,$1F,$7E,$7F,$1F,$7E
        .byte   $7F,$1F,$7E,$7F,$1F,$7E,$7F,$1F
        .byte   $7E,$7F,$1F,$7E,$7F,$1F,$7E,$7F
        .byte   $1F,$7E,$7F,$1F,$7E,$7F,$1F,$7E
        .byte   $7F,$1F,$7E,$7F,$1F,$7E,$7F,$1F
        .byte   $7E,$7F,$1F,$7E,$7F,$1F,$7E,$7F
        .byte   $1F,$00,$00,$00,$01,$00,$00

        ;; Calculation state
L0BC4:  .byte   $00
L0BC5:  .byte   $00
calc_op:.byte   $00
L0BC7:  .byte   $00
L0BC8:  .byte   $00
L0BC9:  .byte   $00
L0BCA:  .byte   $00
L0BCB:  .byte   $00

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
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00

white_pattern:
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00

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
        .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


.proc draw_text_params2
addr:   .addr   text_buffer2
length: .byte   15
.endproc

text_buffer2:
        .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

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

L0C4E:  .byte   $45,$00,$10,$00

farg:
        .byte   $00,$00,$00,$00,$00,$00

        ;; Title bar decoration?
L0C58:  .byte   $73
L0C59:  .byte   $00
L0C5A:  .byte   $F7
L0C5B:  .byte   $FF,$68,$0C,$01,$00,$00,$00,$00
        .byte   $00,$06,$00,$05,$00,$41,$35,$47
        .byte   $37,$36,$49
L0C6E:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00

L0C93:  .byte   $00,$00,$0D,$00,$00,$20,$80,$00
        .byte   $00,$00,$00,$00,$2F,$02,$B1,$00

L0CA3:  .byte   $00             ; arg for fill mode?
        .byte   $01,$02
L0CA6:  .byte   $06             ; arg for fill mode?

create_window_params:
        .byte   window_id       ; id
        .byte   $02             ; flags
        .addr   title
        .byte   $00,$00,$00,$00
        .byte   $00,$00,$00,$00,$82,$00,$60,$00
        .byte   $82,$00,$60,$00
L0CBB:  .byte   $D2
L0CBC:  .byte   $00
L0CBD:  .byte   $3C
L0CBE:  .byte   $00,$00,$20,$80,$00,$00,$00,$00
        .byte   $00,$82,$00,$60,$00,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$00,$00
        .byte   $00,$00,$00,$01,$01,$00,$7F,$00
        .byte   $88,$00,$00

title:  PASCAL_STRING "Calc"
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
        A2D_CALL $03, L0C6E
        A2D_CALL A2D_TEXT_BOX1, L0C6E
        A2D_CALL $2B, 0
        lda     #$01
        sta     button_state_params::state
        A2D_CALL $2D, button_state_params
        A2D_CALL A2D_GET_BUTTON, button_state_params
        lda     ROMIN2
        jsr     reset_buffer2
        lda     #window_id
        jsr     L089E
        jsr     reset_buffers_and_display

        lda     #'='            ; last operation
        sta     calc_op

        lda     #0              ; clear registers
        sta     L0BC5
        sta     L0BC7
        sta     L0BC8
        sta     L0BC9
        sta     L0BCA
        sta     L0BCB

.proc copy_to_b1
        ldx     #(end_adjust_txtptr_copied - adjust_txtptr_copied + 4) ; should be just + 1 ?
loop:   lda     adjust_txtptr_copied-1,x
        sta     adjust_txtptr-1,x
        dex
        bne     loop
.endproc

        lda     #0              ; Turn off errors
        sta     ERRFLG

        lda     #<hook_36
        sta     $36
        lda     #>hook_36
        sta     $36+1

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
        stx     L0BC4
        lda     #'='
        jsr     process_key
        lda     #'C'
        jsr     process_key
        A2D_CALL $24, L0CE6
        ;; fall through

;;; ==================================================
;;; Input Loop

input_loop:
        A2D_CALL $2A, button_state_params
        lda     button_state_params::state
        cmp     #$01
        bne     L0DDC
        jsr     on_click
        jmp     input_loop

L0DDC:  cmp     #$03
        bne     input_loop
        jsr     L0E6F           ; key
        jmp     input_loop

;;; ==================================================
;;; On Click

on_click:
        lda     LCBANK1
        lda     LCBANK1
        A2D_CALL A2D_GET_MOUSE, get_mouse_params
        lda     ROMIN2
        lda     get_mouse_params::elem
        cmp     #A2D_ELEM_CLIENT ; Less than CLIENT is MENU or DESKTOP
        bcc     ignore_click
        lda     get_mouse_params::id
        cmp     #window_id      ; This window?
        beq     :+

ignore_click:
        rts

:       lda     get_mouse_params::elem
        cmp     #A2D_ELEM_CLIENT ; Client area?
        bne     :+
        jsr     map_click_to_button ; try to translate click into key
        bcc     ignore_click
        jmp     process_key

:       cmp     #A2D_ELEM_CLOSE ; Close box?
        bne     :+
        A2D_CALL A2D_BTN_CLICK, button_click_params
        lda     button_click_params::state
        beq     ignore_click
exit:   lda     LCBANK1
        lda     LCBANK1
        A2D_CALL A2D_DESTROY_WINDOW, destroy_window_params
        jsr     UNKNOWN_CALL
        .byte   $0C
        .addr   0
        lda     ROMIN2
        A2D_CALL $1A, L08D5

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
        sta     button_state_params::state
        lda     LCBANK1
        lda     LCBANK1
        A2D_CALL $44, button_state_params
        lda     ROMIN2
        jsr     L084C
        rts

;;; ==================================================
;;; On Key Press

.proc L0E6F
        lda     keydown
        bne     bail
        lda     keychar         ; check key
        cmp     #$1B            ; Escape?
        bne     trydel
        lda     L0BC5
        bne     clear           ; empty state?
        lda     L0BCB
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
        sta     button_state_params::state
        A2D_CALL $46, button_state_params
        lda     clickx+1        ; ensure high bits of coords are 0
        ora     clicky+1
        bne     L0E94
        lda     clicky ; click y
        ldx     clickx ; click x

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
        lda     clickx
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

:       lda     clickx ; special case for wide 0 button
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
        lda     #$63
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
        sta     L0BCB
        sta     L0BC7
        sta     L0BC8
        sta     L0BC9
        jmp     reset_buffers_and_display

:       cmp     #'E'            ; Exponential?
        bne     L0FC7
        ldx     #<btn_e::box
        ldy     #>btn_e::box
        lda     #$65
        jsr     depress_button
        ldy     L0BC8
        bne     L0FC6
        ldy     L0BCB
        bne     :+
        inc     L0BCB
        lda     #'1'
        sta     text_buffer1 + text_buffer_size
        sta     text_buffer2 + text_buffer_size
:       lda     #'E'
        sta     L0BC8
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
        lda     L0BC7
        ora     L0BC8
        bne     L1002
        lda     L0BCB
        bne     :+
        inc     L0BCB
:       lda     #'.'
        sta     L0BC7
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
        lda     L0BC8
        beq     :+
        lda     L0BC9
        bne     :+
        sec
        ror     L0BC9
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
        ldy     L0BCB
        beq     end
        cpy     #1
        bne     :+
        jsr     reset_buffer1_and_state
        jmp     display_buffer1

:       dec     L0BCB
        ldx     #0
        lda     text_buffer1 + text_buffer_size
        cmp     #'.'
        bne     :+
        stx     L0BC7
:       cmp     #'E'
        bne     :+
        stx     L0BC8
:       cmp     #'-'
        bne     :+
        stx     L0BC9
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
        ldy     L0BCB
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
        ldy     L0BCB
        beq     L113E
        lda     #$0F
        sec
        sbc     L0BCB
        tax
L1131:  lda     text_buffer1,x
        sta     text_buffer1-1,x
        sta     text_buffer2-1,x
        inx
        dey
        bne     L1131
L113E:  inc     L0BCB
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
        sta     L0BCB
        sta     L0BC7
        sta     L0BC8
        sta     L0BC9
        sta     L0BCA
        rts
.endproc

.proc depress_button
        stx     invert_addr
        stx     c13_addr
        stx     restore_addr
        sty     invert_addr+1
        sty     c13_addr+1
        sty     restore_addr+1
        A2D_CALL A2D_SET_PATTERN, black_pattern
        A2D_CALL $07, L0CA6     ; set mode XOR ?
        sec
        ror     $FC
clear:  A2D_CALL A2D_FILL_RECT, 0, invert_addr ; Inverts box
check_button:
        A2D_CALL A2D_GET_BUTTON, button_state_params
        lda     button_state_params::state
        cmp     #$04            ; Button down?
        bne     done            ; Nope, done immediately
        lda     #window_id
        sta     button_state_params::state
        A2D_CALL $46, button_state_params
        A2D_CALL A2D_SET_TEXT_POS, tpp
        A2D_CALL $13, 0, c13_addr
        bne     :+
        lda     $FC
        beq     check_button
        lda     #$00
        sta     $FC
        beq     clear
:       lda     $FC
        bne     check_button
        sec
        ror     $FC
        jmp     clear

done:   lda     $FC             ; high bit set if button down
        beq     :+
        A2D_CALL A2D_FILL_RECT, 0, restore_addr ; Inverts back to normal
:       A2D_CALL $07, L0CA3                     ; Normal draw mode??
        lda     $FC
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
        A2D_CALL A2D_SET_TEXT_POS, text_pos_params2 ; clear with spaces
        A2D_CALL A2D_DRAW_TEXT, spaces_string
        A2D_CALL A2D_SET_TEXT_POS, text_pos_params3 ; set up for display
        rts
.endproc

;;; ==================================================
;;; Draw the window contents (background, buttons)

.proc draw_window
        ;; Frame
        A2D_CALL A2D_HIDE_CURSOR
        A2D_CALL A2D_SET_PATTERN, background_pattern
        A2D_CALL A2D_FILL_RECT, background_box_params
        A2D_CALL A2D_SET_PATTERN, black_pattern
        A2D_CALL A2D_DRAW_RECT, frame_display_params
        A2D_CALL A2D_SET_PATTERN, white_pattern
        A2D_CALL A2D_FILL_RECT, clear_display_params
        A2D_CALL $0C, L0BEF     ; ???

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
        sta     c14_addr
        ldy     ptr+1
        sty     c14_addr+1

        clc                     ; address for label pos
        adc     #(btn_c::pos - btn_c)
        sta     text_addr
        bcc     :+
        iny
:       sty     text_addr+1

        ldy     #(btn_c::label - btn_c) ; label
        lda     (ptr),y
        sta     label

        A2D_CALL $14, 0, c14_addr                       ; draw shadowed rect
        A2D_CALL A2D_SET_TEXT_POS, 0, text_addr         ; button label pos
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
;;; Draw the title bar - with extra doodad (???)

draw_title_bar:
        ldx     L0CBC
        lda     L0CBB
        clc
        adc     #$73
        sta     L0C58
        bcc     :+
        inx
:       stx     L0C59
        ldx     L0CBE
        lda     L0CBD
        sec
        sbc     #$16
        sta     L0C5A
        bcs     :+
        dex
:       stx     L0C5B
        A2D_CALL A2D_TEXT_BOX2, L0C93
        A2D_CALL $14, L0C58     ; Draws decoration in title bar
        lda     #window_id
        sta     L08D1
        A2D_CALL $3C, L08D1
        A2D_CALL A2D_TEXT_BOX1, L0C6E
        A2D_CALL A2D_SHOW_CURSOR
        jsr     display_buffer2
        rts

.proc hook_36
        jsr     reset_buffers_and_display
        A2D_CALL A2D_SET_TEXT_POS, L0C4E
        A2D_CALL A2D_DRAW_TEXT, error_string
        jsr     reset_buffer1_and_state
        lda     #'='
        sta     calc_op
        ldx     L0BC4
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
