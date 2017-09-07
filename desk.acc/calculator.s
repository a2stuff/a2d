        .setcpu "65C02"
        .org $800

        .include "apple2.inc"
        .include "../inc/prodos.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/applesoft.inc"

        .include "a2d.inc"

L0020           := $0020
L00B1           := $00B1

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

.proc  exit_da
        lda     LCBANK1
        lda     LCBANK1
        ldx     save_stack
        txs
        rts
.endproc

call_init:
        lda     ROMIN2
        jmp     L0D18

L084C:  lda     LCBANK1
        lda     LCBANK1
        ldx     #$10
L0854:  lda     L088D,x
        sta     L0020,x
        dex
        bpl     L0854
        jsr     L0020
        lda     ROMIN2
        lda     #$34
        jsr     L089E
        lda     LCBANK1
        lda     LCBANK1
        bit     L089D
        bmi     L0878
        jsr     UNKNOWN_CALL
        .byte   $0C
        .addr   0

L0878:  lda     #$00
        sta     L089D
        lda     ROMIN2
        A2D_CALL $3C, L08D1
        A2D_CALL A2D_TEXT_BOX1, L0C6E
        rts

L088D:  sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_15
        sta     RAMRDON
        sta     RAMWRTON
        rts

L089D:  brk
L089E:  sta     L08D1
        lda     L0CBD
        cmp     #$BF
        bcc     L08AE
        lda     #$80
        sta     L089D
        rts

L08AE:  A2D_CALL $3C, L08D1
        A2D_CALL A2D_TEXT_BOX1, L0C6E
        lda     L08D1
        cmp     #$34
        bne     L08C4
        jmp     draw_window

L08C4:  rts

.proc button_state_params
state:  .byte   $00
.endproc

L08C6:  .byte   $00
L08C7:  .byte   $00,$00,$00

.proc text_pos_params1
left:   .word   0
base:   .word   0
.endproc

        .byte $00,$00

.proc button_click_params
state:  .byte   $00
.endproc

L08D1:  .byte   $00,$6E,$0C
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


L08D5:  .byte   $00
L08D6:  .byte   $0C,$00,$15,$00,$E1,$0A,$03
        .byte   $00,$00,$00,$00,$00,$14,$00,$0C
        .byte   $00,$63,$13,$00
        .word   row1_bot

btnc_box:
        .word   col1_left,row1_top,col1_right,row1_bot

        .byte   $29,$00
        .byte   $15,$00,$E1,$0A,$03,$00,$00,$00
        .byte   $00,$00,$14,$00,$0C,$00,$65,$30
        .byte   $00
        .word   row1_bot

btne_box:
        .word   col2_left,row1_top,col2_right,row1_bot

        .byte   $45,$00,$15,$00,$E1
        .byte   $0A,$03,$00,$00,$00,$00,$00,$14
        .byte   $00,$0C,$00,$3D,$4C,$00
        .word   row1_bot

btneq_box:
        .word   col3_left,row1_top,col3_right,row1_bot

        .byte   $61,$00,$15,$00,$E1,$0A,$03,$00
        .byte   $00,$00,$00,$00,$14,$00,$0C,$00
        .byte   $2A,$68,$00
        .word   row1_bot

btnmul_box:
        .word   col4_left,row1_top,col4_right,row1_bot

        .byte   $0C,$00,$25
        .byte   $00,$E1,$0A,$03,$00,$00,$00,$00
        .byte   $00,$14,$00,$0C,$00,$37,$13,$00
        .word   row2_bot

btn7_box:
        .word   col1_left,row2_top,col1_right,row2_bot

        .word   $29
        .byte   $25,$00,$E1,$0A
        .byte   $03,$00,$00,$00,$00,$00,$14,$00
        .byte   $0C,$00,$38,$30,$00
        .word   row2_bot

btn8_box:
        .word   col2_left,row2_top,col2_right,row2_bot

        .byte   $45
        .byte   $00,$25,$00,$E1,$0A,$03,$00,$00
        .byte   $00,$00,$00,$14,$00,$0C,$00,$39
        .byte   $4C,$00
        .word   row2_bot

btn9_box:
        .word   col3_left,row2_top,col3_right,row2_bot

        .byte   $61,$00,$25,$00
        .byte   $E1,$0A,$03,$00,$00,$00,$00,$00
        .byte   $14,$00,$0C,$00,$2F,$68,$00
        .word   row2_bot

btndiv_box:
        .word   col4_left,row2_top,col4_right,row2_bot

        .byte   $0C,$00,$34,$00,$E1,$0A,$03
        .byte   $00,$00,$00,$00,$00,$14,$00,$0C
        .byte   $00,$34,$13,$00
        .word   row3_bot

btn4_box:
        .word   col1_left,row3_top,col1_right,row3_bot

        .byte   $29,$00
        .byte   $34,$00,$E1,$0A,$03,$00,$00,$00
        .byte   $00,$00,$14,$00,$0C,$00,$35,$30
        .byte   $00
        .word   row3_bot

btn5_box:
        .word   col2_left,row3_top,col2_right,row3_bot

        .byte   $45,$00,$34,$00,$E1
        .byte   $0A,$03,$00,$00,$00,$00,$00,$14
        .byte   $00,$0C,$00,$36,$4C,$00
        .word   row3_bot


btn6_box:
        .word   col3_left,row3_top,col3_right,row3_bot

        .byte   $61,$00,$34,$00,$E1,$0A,$03,$00
        .byte   $00,$00,$00,$00,$14,$00,$0C,$00
        .byte   $2D,$68,$00
        .word   row3_bot

btnsub_box:
        .word   col4_left,row3_top,col4_right,row3_bot

        .byte   $0C,$00,$43
        .byte   $00,$E1,$0A,$03,$00,$00,$00,$00
        .byte   $00,$14,$00,$0C,$00,$31,$13,$00
        .word   row4_bot

btn1_box:
        .word   col1_left,row4_top,col1_right,row4_bot

        .byte   $29,$00,$43,$00,$E1,$0A
        .byte   $03,$00,$00,$00,$00,$00,$14,$00
        .byte   $0C,$00,$32,$30,$00
        .word   row4_bot

btn2_box:
        .word   col2_left,row4_top,col2_right,row4_bot

        .byte   $45
        .byte   $00,$43,$00,$E1,$0A,$03,$00,$00
        .byte   $00,$00,$00,$14,$00,$0C,$00,$33
        .byte   $4C,$00
        .word   row4_bot

btn3_box:
        .word   col3_left,row4_top,col3_right,row4_bot

        .byte   $0C,$00,$52,$00
        .byte   $08,$0B,$08,$00,$00,$00,$00,$00
        .byte   $31,$00,$0C,$00,$30,$13,$00
        .word   row5_bot

btn0_box:
        .word   col1_left,row5_top,col2_right,row5_bot

        .byte   $45,$00,$52,$00,$E1,$0A,$03
        .byte   $00,$00,$00,$00,$00,$14,$00,$0C
        .byte   $00,$2E,$4E,$00
        .word   row5_bot

btndec_box:
        .word   col3_left,row5_top,col3_right,row5_bot

        .byte   $61,$00
        .byte   $43,$00,$70,$0B,$03,$00,$00,$00
        .byte   $00,$00,$14,$00,$1B,$00,$2B,$68
        .byte   $00
        .word   row5_bot

btnadd_box:
        .word   col4_left,row4_top,col4_right,row5_bot

        .byte   $00,$00,$00,$40,$7E
        .byte   $7F,$1F,$7E,$7F,$1F,$7E,$7F,$1F
        .byte   $7E,$7F,$1F,$7E,$7F,$1F,$7E,$7F
        .byte   $1F,$7E,$7F,$1F,$7E,$7F,$1F,$7E
        .byte   $7F,$1F,$7E,$7F,$1F,$00,$00,$00
        .byte   $01,$00,$00,$00,$00,$00,$00,$00
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
        .byte   $00,$00,$7E,$00,$00,$40,$7E,$7F
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

L0BC4:  .byte   $00
L0BC5:  .byte   $00
L0BC6:  .byte   $00
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

.proc frame_display_params
left:   .word   10
top:    .word   5
right:  .word   120
bottom: .word   17
.endproc

.proc clear_display_params
left:   .word   11
top:    .word   6
right:  .word   119
bottom: .word   16
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

L0C40:  .byte   $07
L0C41:  .byte   $0C,$0F
L0C43:  .byte   $00,$00

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
        jsr     L128E
        lda     #window_id
        jsr     L089E
        jsr     L129E
        lda     #$3D
        sta     L0BC6
        lda     #$00
        sta     L0BC5
        sta     L0BC7
        sta     L0BC8
        sta     L0BC9
        sta     L0BCA
        sta     L0BCB
        ldx     #$1C
L0D79:  lda     L13CB,x
        sta     $B0,x
        dex
        bne     L0D79
        lda     #$00
        sta     $D8
        lda     #$AE
        sta     $36
        lda     #$13
        sta     $37
        lda     #$01
        jsr     FLOAT
        ldx     #<farg
        ldy     #>farg
        jsr     ROUND
        lda     #$00
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
L0DC9:  A2D_CALL $2A, button_state_params
        lda     button_state_params::state
        cmp     #$01
        bne     L0DDC
        jsr     L0DE6
        jmp     L0DC9

L0DDC:  cmp     #$03
        bne     L0DC9
        jsr     L0E6F
        jmp     L0DC9

L0DE6:  lda     LCBANK1
        lda     LCBANK1
        A2D_CALL A2D_GET_MOUSE, L08C6
        lda     ROMIN2
        lda     text_pos_params1::left
        cmp     #$02
        bcc     L0E03
        lda     text_pos_params1::left+1
        cmp     #window_id
        beq     L0E04
L0E03:  rts

L0E04:  lda     text_pos_params1::left
        cmp     #$02
        bne     L0E13
        jsr     L0E95
        bcc     L0E03
        jmp     process_key

L0E13:  cmp     #$05
        bne     L0E53
        A2D_CALL A2D_BTN_CLICK, button_click_params
        lda     button_click_params::state
        beq     L0E03
exit:   lda     LCBANK1
        lda     LCBANK1
        A2D_CALL A2D_DESTROY_WINDOW, destroy_window_params
        jsr     UNKNOWN_CALL
        .byte   $0C
        .addr   0
        lda     ROMIN2
        A2D_CALL $1A, L08D5
        ldx     #$09
L0E3F:  lda     L0E4A,x
        sta     L0020,x
        dex
        bpl     L0E3F
        jmp     L0020

L0E4A:  sta     RAMRDOFF
        sta     RAMWRTOFF
        jmp     exit_da

L0E53:  cmp     #$03
        bne     L0E03
        lda     #window_id
        sta     button_state_params::state
        lda     LCBANK1
        lda     LCBANK1
        A2D_CALL $44, button_state_params
        lda     ROMIN2
        jsr     L084C
        rts

.proc L0E6F
        lda     L08C7
        bne     bail
        lda     L08C6           ; check key
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

L0E95:  lda     #window_id
        sta     button_state_params::state
        A2D_CALL $46, button_state_params
        lda     text_pos_params1::left+1 ; must have alternate meaning here
        ora     text_pos_params1::base+1
        bne     L0E94
        lda     text_pos_params1::base ; click y
        ldx     text_pos_params1::left ; click x

        border_lt := 1          ; border width pixels (left/top)
        border_br := 2          ; (bottom/right)

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

:       cmp     #82             ; special case for tall + button
        bcs     :+
        lda     text_pos_params1::left
        cmp     #97
        bcc     miss
        cmp     #116
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

:       lda     text_pos_params1::left ; special case for wide 0 button
        cmp     #12
        bcc     miss
        cmp     #'='
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

.proc process_key
        cmp     #'C'            ; Clear?
        bne     :+
        ldx     #<btnc_box
        ldy     #>btnc_box
        lda     #$63
        jsr     depress_button
        lda     #$00
        jsr     FLOAT
        ldx     #<farg
        ldy     #>farg
        jsr     ROUND
        lda     #'='
        sta     L0BC6
        lda     #0
        sta     L0BC5
        sta     L0BCB
        sta     L0BC7
        sta     L0BC8
        sta     L0BC9
        jmp     L129E

:       cmp     #'E'            ; Exponential?
        bne     L0FC7
        ldx     #<btne_box
        ldy     #>btne_box
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
        ldx     #<btneq_box
        ldy     #>btneq_box
        jmp     L114C

:       cmp     #'*'            ; Multiply?
        bne     :+
        pha
        ldx     #<btnmul_box
        ldy     #>btnmul_box
        jmp     L114C

:       cmp     #'.'            ; Decimal?
        bne     L1003
        ldx     #<btndec_box
        ldy     #>btndec_box
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
        ldx     #<btnadd_box
        ldy     #>btnadd_box
        jmp     L114C

:       cmp     #'-'            ; Subtract?
        bne     trydiv
        pha
        ldx     #<btnsub_box
        ldy     #>btnsub_box
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
        ldx     #<btndiv_box
        ldy     #>btndiv_box
        jmp     L114C

:       cmp     #'0'            ; Digit 0?
        bne     :+
        pha
        ldx     #<btn0_box
        ldy     #>btn0_box
        jmp     L10FF

:       cmp     #'1'            ; Digit 1?
        bne     :+
        pha
        ldx     #<btn1_box
        ldy     #>btn1_box
        jmp     L10FF

:       cmp     #'2'            ; Digit 2?
        bne     :+
        pha
        ldx     #<btn2_box
        ldy     #>btn2_box
        jmp     L10FF

:       cmp     #'3'            ; Digit 3?
        bne     :+
        pha
        ldx     #<btn3_box
        ldy     #>btn3_box
        jmp     L10FF

:       cmp     #'4'            ; Digit 4?
        bne     :+
        pha
        ldx     #<btn4_box
        ldy     #>btn4_box
        jmp     L10FF

:       cmp     #'5'            ; Digit 5?
        bne     :+
        pha
        ldx     #<btn5_box
        ldy     #>btn5_box
        jmp     L10FF

:       cmp     #'6'            ; Digit 6?
        bne     :+
        pha
        ldx     #<btn6_box
        ldy     #>btn6_box
        jmp     L10FF

:       cmp     #'7'            ; Digit 7?
        bne     :+
        pha
        ldx     #<btn7_box
        ldy     #>btn7_box
        jmp     L10FF

:       cmp     #'8'            ; Digit 8?
        bne     :+
        pha
        ldx     #<btn8_box
        ldy     #>btn8_box
        jmp     L10FF

:       cmp     #'9'            ; Digit 9?
        bne     :+
        pha
        ldx     #<btn9_box
        ldy     #>btn9_box
        jmp     L10FF

:       cmp     #$7F            ; Delete?
        bne     end
        ldy     L0BCB
        beq     end
        cpy     #1
        bne     :+
        jsr     L11F5
        jmp     L12A4

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
        jmp     L12A4

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
        jsr     L128E
        pla
        cmp     #$30
        bne     L111C
        jmp     L12A4

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
        jmp     L12A4

L114B:  rts

L114C:  jsr     depress_button
        bne     L1153
        pla
        rts

L1153:  lda     L0BC6
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
        sta     L0BC6
        jmp     L11F5

L1173:  lda     #$07
        sta     $B8
        lda     #$0C
        sta     $B9
        jsr     L00B1
        jsr     FIN
L1181:  pla
        ldx     L0BC6
        sta     L0BC6           ; Operation
        lda     #<farg
        ldy     #>farg

        cpx     #'+'
        bne     :+
        jsr     FADD
        jmp     post

:       cpx     #'-'
        bne     :+
        jsr     FSUB
        jmp     post

:       cpx     #'*'
        bne     :+
        jsr     FMULT
        jmp     post

:       cpx     #'/'
        bne     :+
        jsr     FDIV
        jmp     post

:       cpx     #'='
        bne     post
        ldy     L0BCA
        bne     post
        jmp     L11F5

post:   ldx     #<farg          ; after the FP operation is done
        ldy     #>farg
        jsr     ROUND
        jsr     FOUT
        ldy     #0
L11CC:  lda     $0100,y         ; stack ?
        beq     L11D4
        iny
        bne     L11CC
L11D4:  ldx     #text_buffer_size
L11D6:  lda     $FF,y           ; stack-1 ?
        sta     text_buffer1,x
        sta     text_buffer2,x
        dex
        dey
        bne     L11D6
        cpx     #0
        bmi     L11F2
loop:   lda     #' '
        sta     text_buffer1,x
        sta     text_buffer2,x
        dex
        bpl     loop
L11F2:  jsr     L12A4
L11F5:  jsr     L127E
        lda     #0
        sta     L0BCB
        sta     L0BC7
        sta     L0BC8
        sta     L0BC9
        sta     L0BCA
        rts

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
        A2D_CALL A2D_SET_TEXT_POS, text_pos_params1
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

L127E:  ldy     #text_buffer_size
L1280:  lda     #' '
        sta     text_buffer1-1,y
        dey
        bne     L1280
        lda     #$30
        sta     text_buffer1 + text_buffer_size
        rts

L128E:  ldy     #text_buffer_size
L1290:  lda     #' '
        sta     text_buffer2-1,y
        dey
        bne     L1290
        lda     #'0'
        sta     text_buffer2 + text_buffer_size
        rts

L129E:  jsr     L127E
        jsr     L128E
L12A4:  ldx     #$07
        ldy     #$0C
        jsr     L12C0
        A2D_CALL A2D_DRAW_TEXT, draw_text_params1
        rts

L12B2:  ldx     #$1A
        ldy     #$0C
        jsr     L12C0
        A2D_CALL A2D_DRAW_TEXT, draw_text_params2
        rts

L12C0:  stx     L0C40
        sty     L0C41
        A2D_CALL $18, L0C40
        lda     #$69
        sec
        sbc     L0C43
        sta     text_pos_params3::left
        A2D_CALL A2D_SET_TEXT_POS, text_pos_params2
        A2D_CALL A2D_DRAW_TEXT, spaces_string
        A2D_CALL A2D_SET_TEXT_POS, text_pos_params3
        rts

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
        lda     #<L08D6
        sta     ptr
        lda     #>L08D6
        sta     ptr+1
loop:   ldy     #0
        lda     (ptr),y
        beq     L1363           ; done!
        lda     ptr
        sta     c14_addr
        ldy     ptr+1
        sty     c14_addr+1
        clc
        adc     #$11            ; byte offset
        sta     text_addr
        bcc     :+
        iny
:       sty     text_addr+1
        ldy     #$10
        lda     ($FA),y
        sta     label
        A2D_CALL $14, 0, c14_addr                       ; draw shadowed rect
        A2D_CALL A2D_SET_TEXT_POS, 0, text_addr         ; button label pos
        A2D_CALL A2D_DRAW_TEXT, draw_text_params_label  ; button label text
        lda     $FA
        clc
        adc     #$1D
        sta     $FA
        bcc     loop
        inc     $FB
        jmp     loop
.endproc

L1363:  ldx     L0CBC
        lda     L0CBB
        clc
        adc     #$73
        sta     L0C58
        bcc     L1372
        inx
L1372:  stx     L0C59
        ldx     L0CBE
        lda     L0CBD
        sec
        sbc     #$16
        sta     L0C5A
        bcs     L1384
        dex
L1384:  stx     L0C5B
        A2D_CALL A2D_TEXT_BOX2, L0C93
        A2D_CALL $14, L0C58     ; Draws decoration in title bar
        lda     #window_id
        sta     L08D1
        A2D_CALL $3C, L08D1
        A2D_CALL A2D_TEXT_BOX1, L0C6E
        A2D_CALL A2D_SHOW_CURSOR
        jsr     L12B2
        rts

        jsr     L129E
        A2D_CALL A2D_SET_TEXT_POS, L0C4E
        A2D_CALL A2D_DRAW_TEXT, error_string
        jsr     L11F5
        lda     #$3D
        sta     L0BC6
        ldx     L0BC4
        txs
L13CB           := * + 2
        jmp     L0DC9

L13CC:  inc     $B8
        bne     L13D2
        inc     $B9
L13D2:  lda     $EA60
        cmp     #$3A
        bcs     L13E3
        cmp     #' '
        beq     L13CC
        sec
        sbc     #'0'
        sec
        sbc     #$D0
L13E3:  rts

da_end := *
