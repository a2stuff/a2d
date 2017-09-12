        .org $800
        .setcpu "65C02"

        .include "apple2.inc"
        .include "../inc/prodos.inc"
        .include "../inc/auxmem.inc"

        .include "a2d.inc"

SPKR := $C030
L0020           := $0020
L4015           := $4015

        jmp     copy2aux

        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0

;;; ==================================================
;;; Copy the DA to AUX and invoke it

stash_stack:  .byte   0
.proc copy2aux
        tsx
        stx     stash_stack

        start := enter_da
        end := last

        sta     ALTZPOFF
        lda     $C082
        lda     #<start
        sta     STARTLO
        lda     #>start
        sta     STARTHI
        lda     #<end
        sta     ENDLO
        lda     #>end
        sta     ENDHI
        lda     #<start
        sta     DESTINATIONLO
        lda     #>start
        sta     DESTINATIONHI
        sec                     ; main>aux
        jsr     AUXMOVE

        lda     #<enter_da
        sta     XFERSTARTLO
        lda     #>enter_da
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
;;; Set up / tear down

.proc exit_da
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        ldx     stash_stack
        txs
        rts
.endproc

.proc enter_da
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        lda     #0
        sta     $08
        jmp     create_window
.endproc

        window_id = $33

;;; ==================================================

.proc call_4015_main

        dest := $20

        ;; copy following routine to $20 and call it
        ldx     #sizeof_routine
loop:   lda     routine,x
        sta     dest,x
        dex
        bpl     loop
        jsr     dest

        lda     #window_id
        jsr     L08B4
        bit     L08B3
        bmi     L089D

        jsr     UNKNOWN_CALL
        .byte   $0C
        .addr   0

L089D:  lda     #0
        sta     L08B3
        rts

.proc routine
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     L4015
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc
        sizeof_routine := * - routine
.endproc

;;; ==================================================
;;; ???

        screen_height := 192

L08B3:  .byte   0               ; ???
L08B4:  sta     query_box_params_id
        lda     create_window_params_L0E02
        cmp     #screen_height-1
        bcc     :+
        lda     #$80
        sta     L08B3
        rts

:       A2D_CALL A2D_QUERY_BOX, query_box_params
        A2D_CALL A2D_SET_BOX1, L0DB3
        lda     query_box_params_id
        cmp     #window_id
        bne     :+
        jmp     L1072

:       rts

;;; ==================================================
;;; Param Blocks

        ;; following memory space is re-used
.proc drag_window_params
id := * + 0
.endproc

.proc map_coords_params
id      := * + 0
screenx := * + 1
screeny := * + 3
clientx := * + 5
clienty := * + 7
.endproc

        query_target_params := *+1
        query_target_params_queryx := *+1
        query_target_params_queryy := *+3
        query_target_params_element := *+5
        query_target_params_id := *+6

.proc get_input_params
state:  .byte   0
key       := *
modifiers := *+1

xcoord    := *
ycoord    := *+2
        .byte   0,0,0,0         ; storage for above
.endproc



L08E0:  .byte   0
L08E1:  .byte   0
L08E2:  .byte   0
L08E3:  .byte   0,0,0

.proc close_click_params
clicked:.byte   0
.endproc

.proc query_box_params
id:     .byte   0
addr:   .addr   $0DB3
.endproc
query_box_params_id := query_box_params::id

        cw := 28
        c1 := 5
        c2 := c1 + cw
        c3 := c2 + cw
        c4 := c3 + cw
        rh := 16
        r1 := 3
        r2 := r1 + rh
        r3 := r2 + rh
        r4 := r3 + rh

space_positions:                 ; left, top for all 16 holes
        .word   c1,r1
        .word   c2,r1
        .word   c3,r1
        .word   c4,r1
        .word   c1,r2
        .word   c2,r2
        .word   c3,r2
        .word   c4,r2
        .word   c1,r3
        .word   c2,r3
        .word   c3,r3
        .word   c4,r3
        .word   c1,r4
        .word   c2,r4
        .word   c3,r4
        .word   c4,r4

.proc pattern_table
        .addr   piece1, piece2, piece3, piece4, piece5, piece6, piece7
        .addr   piece8, piece9, piece10, piece11, piece12, piece13, piece14
p15:    .addr   piece15
p16:    .addr   piece16
.endproc

        ;; Current position table
position_table := *
        .byte   0,0,0,0
        .byte   0,0,0,0
        .byte   0,0,0,0
        .byte   0,0,0,0

.proc draw_pattern_params
left:   .word   0
top:    .word   0
addr:   .addr   0
stride: .byte   4
        .byte   0,0,0,0,0
width:  .word   27
height: .word   15
.endproc

piece1:
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece2:
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%0000000),px(%0011111),px(%1111110)
        .byte px(%0111000),px(%1010101),px(%0100001),px(%1111110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece3:
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1110001),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%0010101),px(%0111110)
        .byte px(%0111111),px(%1111101),px(%0101010),px(%1011110)
        .byte px(%0111111),px(%1110010),px(%1010101),px(%0111110)
        .byte px(%0111111),px(%1100101),px(%0101010),px(%0111110)
        .byte px(%0111111),px(%0001010),px(%1010100),px(%1111110)
        .byte px(%0111110),px(%1010101),px(%0101001),px(%1111110)
        .byte px(%0111101),px(%0101010),px(%1000111),px(%1111110)
        .byte px(%0111010),px(%1010101),px(%0011111),px(%1111110)
        .byte px(%0110101),px(%0101000),px(%0111111),px(%1111110)
        .byte px(%0110010),px(%1010011),px(%1111111),px(%1111110)
        .byte px(%0110101),px(%0001111),px(%1111100),px(%0000000)
        .byte px(%0110000),px(%1111111),px(%1000010),px(%1010100)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece4:
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0000111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0101000),px(%0111111),px(%1111111),px(%1111110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece5:
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1110100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1101010)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1011110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%0111110)
        .byte px(%0111111),px(%1111111),px(%1111110),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111101),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111101),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111011),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1110111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1110111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1110110),px(%1101100)
        .byte px(%0111111),px(%1111111),px(%1101101),px(%1011010)
        .byte px(%0111111),px(%1111111),px(%1101011),px(%0110110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece6:
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0010101),px(%0101010),px(%1010101),px(%0101010)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0010101),px(%0101010),px(%1010101),px(%0101010)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0011011),px(%0110110),px(%1101101),px(%1011010)
        .byte px(%0110110),px(%1101101),px(%1011011),px(%0110110)
        .byte px(%0101101),px(%1011011),px(%0110110),px(%1101100)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece7:
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0010101),px(%0101010),px(%1010101),px(%0101010)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0010101),px(%0101010),px(%1010101),px(%0101010)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0110110),px(%1101101),px(%1011011),px(%0110110)
        .byte px(%0101101),px(%1011011),px(%0110110),px(%1101100)
        .byte px(%0011011),px(%0110110),px(%1101101),px(%1011010)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece8:
        .byte px(%0101010),px(%1010001),px(%1111111),px(%1111110)
        .byte px(%0010101),px(%0101010),px(%0111111),px(%1111110)
        .byte px(%0101010),px(%1010101),px(%0001111),px(%1111110)
        .byte px(%0010101),px(%0101010),px(%1000111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%0011111),px(%1111110)
        .byte px(%0111111),px(%1111110),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111101),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111011),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1110111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1110111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1101111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1101111),px(%1111111),px(%1111110)
        .byte px(%0101101),px(%1001111),px(%1111111),px(%1111110)
        .byte px(%0011011),px(%0011111),px(%1111111),px(%1111110)
        .byte px(%0110110),px(%1011111),px(%1111111),px(%1111110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece9:
        .byte px(%0111111),px(%1111111),px(%1110011),px(%0110110)
        .byte px(%0111111),px(%1111111),px(%1110110),px(%1101100)
        .byte px(%0111111),px(%1111111),px(%1110101),px(%1011010)
        .byte px(%0111111),px(%1111111),px(%1110011),px(%0110110)
        .byte px(%0111111),px(%1111111),px(%1111010),px(%1010100)
        .byte px(%0111111),px(%1111111),px(%1111010),px(%1010100)
        .byte px(%0111111),px(%1111111),px(%1111100),px(%1010100)
        .byte px(%0111111),px(%1111111),px(%1111110),px(%1010100)
        .byte px(%0111111),px(%1111111),px(%1111110),px(%1010100)
        .byte px(%0111111),px(%1111111),px(%1111110),px(%1010100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%0010100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1001100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1100110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1110100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111010)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece10:
        .byte px(%0101101),px(%1011011),px(%0110110),px(%1101100)
        .byte px(%0011011),px(%0110110),px(%1101101),px(%1011010)
        .byte px(%0110110),px(%1101101),px(%1011011),px(%0110110)
        .byte px(%0101101),px(%1011011),px(%0110110),px(%1101100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0100110),px(%0110011),px(%0011001),px(%1001100)
        .byte px(%0110011),px(%0011001),px(%1001100),px(%1100110)
        .byte px(%0100110),px(%0110011),px(%0011001),px(%1001100)
        .byte px(%0110011),px(%0011001),px(%1001100),px(%1100110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece11:
        .byte px(%0011011),px(%0110110),px(%1101101),px(%1011010)
        .byte px(%0110110),px(%1101101),px(%1011011),px(%0110110)
        .byte px(%0101101),px(%1011011),px(%0110110),px(%1101100)
        .byte px(%0011011),px(%0110110),px(%1101101),px(%1011010)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0101010),px(%1010101),px(%0101010),px(%1010100)
        .byte px(%0100110),px(%0110011),px(%0011001),px(%1001100)
        .byte px(%0110011),px(%0011001),px(%1001100),px(%1100110)
        .byte px(%0100110),px(%0110011),px(%0011001),px(%1001100)
        .byte px(%0110011),px(%0011001),px(%1001100),px(%1100110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece12:
        .byte px(%0110110),px(%1011111),px(%1111111),px(%1111110)
        .byte px(%0101101),px(%1011111),px(%1111111),px(%1111110)
        .byte px(%0011011),px(%0101111),px(%1111111),px(%1111110)
        .byte px(%0110110),px(%1101111),px(%1111111),px(%1111110)
        .byte px(%0101010),px(%1010111),px(%1111111),px(%1111110)
        .byte px(%0101010),px(%1010011),px(%1111111),px(%1111110)
        .byte px(%0101010),px(%1010011),px(%1111111),px(%1111110)
        .byte px(%0101010),px(%1010101),px(%1111111),px(%1111110)
        .byte px(%0101010),px(%1010100),px(%1111111),px(%1111110)
        .byte px(%0101010),px(%1010101),px(%0011111),px(%1111110)
        .byte px(%0101010),px(%1010101),px(%0100111),px(%1111110)
        .byte px(%0100110),px(%0110011),px(%0010111),px(%1111110)
        .byte px(%0110011),px(%0011001),px(%1001111),px(%1111110)
        .byte px(%0100110),px(%0110011),px(%0001111),px(%1111110)
        .byte px(%0110011),px(%0011001),px(%1011111),px(%1111110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece13:                       ; the hole
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111011),px(%1011101),px(%1101110),px(%1110110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0101110),px(%1110111),px(%0111011),px(%1011100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111011),px(%1011101),px(%1101110),px(%1110110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0101110),px(%1110111),px(%0111011),px(%1011100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111011),px(%1011101),px(%1101110),px(%1110110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0101110),px(%1110111),px(%0111011),px(%1011100)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111011),px(%1011101),px(%1101110),px(%1110110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece14:
        .byte px(%0001100),px(%1100110),px(%0110011),px(%0011000)
        .byte px(%0100110),px(%0110011),px(%0011001),px(%1001100)
        .byte px(%0110011),px(%0011001),px(%1001100),px(%1100110)
        .byte px(%0011011),px(%0110110),px(%1101101),px(%1011010)
        .byte px(%0100101),px(%1011011),px(%0110110),px(%1101100)
        .byte px(%0110010),px(%1101101),px(%1011011),px(%0110110)
        .byte px(%0111001),px(%0110110),px(%1101101),px(%1011010)
        .byte px(%0111110),px(%0111011),px(%0110110),px(%1101100)
        .byte px(%0111111),px(%1000101),px(%1011000),px(%0000000)
        .byte px(%0111111),px(%1111000),px(%0000001),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece15:
        .byte px(%0001100),px(%1100110),px(%0110011),px(%0011000)
        .byte px(%0100110),px(%0110011),px(%0011001),px(%1001100)
        .byte px(%0110011),px(%0011001),px(%1001100),px(%1100110)
        .byte px(%0110110),px(%1101101),px(%1011011),px(%0110110)
        .byte px(%0011011),px(%0110110),px(%1101101),px(%1011010)
        .byte px(%0101101),px(%1011011),px(%0110110),px(%1101100)
        .byte px(%0110110),px(%1101101),px(%1011011),px(%0110110)
        .byte px(%0011011),px(%0110110),px(%1101101),px(%1011010)
        .byte px(%0000000),px(%0000000),px(%0000110),px(%1101100)
        .byte px(%0111111),px(%1111111),px(%1100000),px(%0000010)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)
piece16:
        .byte px(%0001100),px(%1100110),px(%0011111),px(%1111110)
        .byte px(%0100110),px(%0110011),px(%0111111),px(%1111110)
        .byte px(%0110011),px(%0011000),px(%1111111),px(%1111110)
        .byte px(%0101101),px(%1011001),px(%1111111),px(%1111110)
        .byte px(%0110110),px(%1100111),px(%1111111),px(%1111110)
        .byte px(%0011011),px(%0011111),px(%1111111),px(%1111110)
        .byte px(%0101110),px(%0111111),px(%1111111),px(%1111110)
        .byte px(%0100111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0111111),px(%1111111),px(%1111111),px(%1111110)
        .byte px(%0000000),px(%0000000),px(%0000000),px(%0000000)


.proc fill_rect_params
        .word   1, 0, $79, $44
.endproc

.proc pattern_speckles
        .byte   $77,$DD,$77,$DD,$77,$DD,$77,$DD
.endproc

        .byte   $00             ; ???

.proc pattern_black
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
.endproc

        .byte   $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$00

.proc set_pos_params            ; for what ??? (board is at 5,3)
        .word   5, 2
.endproc

        ;; Param block for $0F call (4 bytes)
L0D91:  .byte   $70,$00,$00,$00 ; ???

        ;; hole position (0..3, 0..3)
hole_x: .byte   0
hole_y: .byte   0

        ;; click location (0..3, 0..3)
click_y:  .byte   $00
click_x:  .byte   $00

        ;; param for draw_row/draw_col
draw_rc:  .byte   $00

        ;; params for draw_selected
draw_end:  .byte   $00
draw_inc:  .byte   $00

destroy_window_params:
L0D9C:  .byte   $33,$73,$00,$F7,$FF,$AD,$0D,$01
        .byte   $00,$00,$00,$00,$00,$06,$00,$05
        .byte   $00,$41,$35,$47,$37,$36,$49

        ;; SET_BOX1 params (filled in by QUERY_BOX)
L0DB3:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$0D
        .byte   $00,$00,$20,$80,$00,$00,$00,$00
        .byte   $00,$2F,$02,$B1,$00,$00,$01,$02
        .byte   $06

        default_width := $79
        default_height := $44

.proc create_window_params
id:     .byte   $33
flags:  .byte   A2D_CWF_ADDCLOSE
title:  .addr   name
hscroll:.byte   0
vscroll:.byte   0
hsmax:  .byte   0
hspos:  .byte   0
vsmax:  .byte   0
vspos:  .byte   0
        .byte   $00,$00         ; ???
w_a:    .word   default_width
h_a:    .word   default_height
w_b:    .word   default_width
h_b:    .word   default_height

left:   .word   $DC
top:    .word   $50
saddr:  .addr   A2D_SCREEN_ADDR
stride: .word   A2D_SCREEN_STRIDE
hoffset:.word   0
voffset:.word   0
width:  .word   default_width
height: .word   default_height

        ;; This is QUERY_BOX/SET_BOX cruft
        .byte   $FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $00,$00,$00,$00,$01,$01,$00,$7F
        .byte   $00,$88

        .byte   $00,$00,$DC,$00,$50,$00
        .byte   $00,$20,$80,$00,$00,$00,$00,$00
        .byte   $79,$00,$44,$00,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$00,$00,$00
        .byte   $00,$00,$01,$01,$00,$7F,$00,$88
        .byte   $00,$00

.endproc
name:   PASCAL_STRING "Puzzle"

        create_window_params_L0E02 := create_window_params::top

;;; ==================================================
;;; Create the window

.proc create_window
        jsr     save_zp
        A2D_CALL A2D_CREATE_WINDOW, create_window_params

        ;; init pieces
        ldy     #15
loop:   tya
        sta     position_table,y
        dey
        bpl     loop

        lda     #window_id
        jsr     L08B4
        A2D_CALL $2B
L0E70:  ldy     #3
L0E72:  tya
        pha
        ldx     position_table
        ldy     #0
ploop:  lda     position_table+1,y
        sta     position_table,y
        iny
        cpy     #15
        bcc     ploop

        stx     position_table+15
        pla
        tay
        dey
        bne     L0E72
        ldx     position_table
        lda     position_table+1
        sta     position_table
        stx     position_table+1

        A2D_CALL A2D_GET_INPUT, get_input_params
        lda     get_input_params::state
        beq     L0E70
        jsr     check_victory
        bcs     L0E70
        jsr     draw_all
        jsr     find_hole
        ; fall through
.endproc

;;; ==================================================
;;; Input loop and processing

.proc input_loop
        A2D_CALL A2D_GET_INPUT, get_input_params
        lda     get_input_params::state
        cmp     #A2D_INPUT_DOWN
        bne     :+
        jsr     on_click
        jmp     input_loop

        ;; key?
:       cmp     #A2D_INPUT_KEY
        bne     input_loop
        jsr     check_key
        jmp     input_loop

        ;; click - where?
on_click:
        A2D_CALL A2D_QUERY_TARGET, query_target_params
        lda     query_target_params_id
        cmp     #window_id
        bne     bail
        lda     query_target_params_element
        bne     :+
bail:   rts

        ;; client area?
:       cmp     #A2D_ELEM_CLIENT
        bne     :+
        jsr     find_click_piece
        bcc     bail
        jmp     L0FBC

        ;; close box?
:       cmp     #A2D_ELEM_CLOSE
        bne     check_title
        A2D_CALL A2D_CLOSE_CLICK, close_click_params
        lda     close_click_params::clicked
        beq     bail
destroy:
        A2D_CALL A2D_DESTROY_WINDOW, destroy_window_params

        jsr     UNKNOWN_CALL    ; ???
        .byte   $0C
        .addr   0

        target = $20            ; copy following to ZP and run it
        ldx     #sizeof_routine
loop:   lda     routine,x
        sta     target,x
        dex
        bpl     loop
        jmp     target

.proc routine
L0F12:  sta     RAMRDOFF
        sta     RAMWRTOFF
        jmp     exit_da
.endproc
        sizeof_routine := * - routine

        ;; title bar?
check_title:
        cmp     #A2D_ELEM_TITLE
        bne     bail
        lda     #window_id
        sta     drag_window_params::id
        A2D_CALL A2D_DRAG_WINDOW, drag_window_params
        ldx     #$23
        jsr     call_4015_main
        rts

        ;; on key press - exit if Escape
check_key:
        lda     get_input_params::modifiers
        bne     :+
        lda     get_input_params::key
        cmp     #$1B            ; Escape
        beq     destroy
:       rts
.endproc

;;; ==================================================
;;; Map click to piece x/y

.proc find_click_piece
L0F3D:  lda     #window_id
        sta     map_coords_params::id
        A2D_CALL A2D_MAP_COORDS, map_coords_params
        lda     map_coords_params::clientx+1
        ora     map_coords_params::clienty+1
        bne     nope            ; ensure high bytes are 0

        lda     map_coords_params::clienty
        ldx     map_coords_params::clientx

        cmp     #r1
        bcc     nope
        cmp     #r2+1
        bcs     :+
        jsr     find_click_y
        bcc     nope
        lda     #0
        beq     yep
:       cmp     #r3+1
        bcs     :+
        jsr     find_click_y
        bcc     nope
        lda     #1
        bne     yep
:       cmp     #r4+1
        bcs     :+
        jsr     find_click_y
        bcc     nope
        lda     #2
        bne     yep
:       cmp     #r4+rh+1
        bcs     nope
        jsr     find_click_y
        bcc     nope
        lda     #3

yep:    sta     click_x
        sec
        rts

nope:   clc
        rts
.endproc

.proc find_click_y
        cpx     #c1
        bcc     nope
        cpx     #c2
        bcs     :+
        lda     #0
        beq     yep
:       cpx     #c3+1
        bcs     :+
        lda     #1
        bne     yep
:       cpx     #c4+1
        bcs     :+
        lda     #2
        bne     yep
:       cpx     #c4+cw
        bcs     nope
        lda     #3

yep:    sta     click_y
        sec
        rts

nope:   clc
        rts
.endproc

;;; ==================================================
;;; Process piece click

        hole_piece := 12

L0FBC:  lda     #$00
        ldy     hole_y
        beq     L0FC9
L0FC3:  clc
        adc     #$04
        dey
        bne     L0FC3
L0FC9:  sta     draw_rc
        clc
        adc     hole_x
        tay
        lda     click_y
        cmp     hole_x
        beq     L1014
        lda     click_x
        cmp     hole_y
        beq     L0FE2
L0FE1:  rts

L0FE2:  lda     click_y
        cmp     hole_x
        beq     L0FE1
        bcs     L1000
        lda     hole_x
        sec
        sbc     click_y
        tax
L0FF4:  lda     position_table-1,y
        sta     position_table,y
        dey
        dex
        bne     L0FF4
        beq     L1055
L1000:  lda     click_y
        sec
        sbc     hole_x
        tax
L1008:  lda     position_table+1,y
        sta     position_table,y
        iny
        dex
        bne     L1008
        beq     L1055
L1014:  lda     click_x
        cmp     hole_y
        beq     L0FE1
        bcs     L1035
        lda     hole_y
        sec
        sbc     click_x
        tax
L1026:  lda     position_table-4,y
        sta     position_table,y
        dey
        dey
        dey
        dey
        dex
        bne     L1026
        beq     L104A
L1035:  lda     click_x
        sec
        sbc     hole_y
        tax
L103D:  lda     position_table+4,y
        sta     position_table,y
        iny
        iny
        iny
        iny
        dex
        bne     L103D
L104A:  lda     #hole_piece
        sta     position_table,y
        jsr     draw_col
        jmp     L105D

L1055:  lda     #hole_piece
        sta     position_table,y
        jsr     draw_row
L105D:  jsr     check_victory
        bcc     L106E
        ldx     #4
L1064:  txa
        pha
        jsr     play_sound
        pla
        tax
        dex
        bne     L1064
L106E:  jmp     find_hole

        rts

;;; ==================================================
;;; Clear the background

L1072:  A2D_CALL A2D_SET_PATTERN, pattern_speckles
        A2D_CALL A2D_FILL_RECT, fill_rect_params
        A2D_CALL A2D_SET_PATTERN, pattern_black
        A2D_CALL A2D_SET_POS, set_pos_params
        A2D_CALL $0F, L0D91     ; ???
        jsr     draw_all

        lda     #window_id
        sta     query_box_params::id
        A2D_CALL A2D_QUERY_BOX, query_box_params
        A2D_CALL A2D_SET_BOX1, L0DB3
        rts

;;; ==================================================

.proc save_zp
        ldx     #$00
loop:   lda     $00,x
        sta     saved_zp,x
        dex
        bne     loop
        rts
.endproc

.proc restore_zp
        ldx     #$00
loop:   lda     saved_zp,x
        sta     $00,x
        dex
        bne     loop
        rts
.endproc

saved_zp:
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0

;;; ==================================================
;;; Draw pieces

.proc draw_all
        ldy     #1
        sty     draw_inc
        dey
        lda     #16
        sta     draw_end
        bne     draw_selected
.endproc

.proc draw_row                  ; row specified in draw_rc
        lda     #1
        sta     draw_inc
        lda     draw_rc
        tay
        clc
        adc     #4
        sta     draw_end
        bne     draw_selected
.endproc

.proc draw_col                  ; col specified in draw_rc
        lda     #4
        sta     draw_inc
        ldy     hole_x
        lda     #16
        sta     draw_end
        ;; fall through
.endproc

        ;; Draw pieces from A to draw_end, step draw_inc
.proc draw_selected
        tya
        pha
        A2D_CALL A2D_HIDE_CURSOR
        lda     #window_id
        sta     query_box_params::id
        A2D_CALL A2D_QUERY_BOX, query_box_params
        A2D_CALL A2D_SET_BOX1, L0DB3
        pla
        tay

loop:   tya
        pha
        asl     a
        asl     a
        tax
        lda     space_positions,x
        sta     draw_pattern_params::left
        lda     space_positions+1,x
        sta     draw_pattern_params::left+1
        lda     space_positions+2,x
        sta     draw_pattern_params::top
        lda     space_positions+3,x
        sta     draw_pattern_params::top+1
        lda     position_table,y
        asl     a
        tax
        lda     pattern_table,x
        sta     draw_pattern_params::addr
        lda     pattern_table+1,x
        sta     draw_pattern_params::addr+1
        A2D_CALL A2D_DRAW_PATTERN, draw_pattern_params
        pla
        clc
        adc     draw_inc
        tay
        cpy     draw_end
        bcc     loop
        A2D_CALL A2D_SHOW_CURSOR
        rts
.endproc

;;; ==================================================
;;; Play sound

.proc play_sound
        ldx     #$80
loop1:  lda     #$58
loop2:  ldy     #$1B
delay1: dey
        bne     delay1
        bit     SPKR
        tay
delay2: dey
        bne     delay2
        sbc     #1
        beq     loop1
        bit     SPKR
        dex
        bne     loop2
        rts
.endproc

;;; ==================================================
;;; Puzzle complete?

        ;; Returns with carry set if puzzle complete
.proc check_victory             ; Allows for swapped indistinct pieces, etc.
        ;; 0/12 can be swapped
        lda     position_table
        beq     :+
        cmp     #12
        bne     nope

:       ldy     #1
c1234:  tya
        cmp     position_table,y
        bne     nope
        iny
        cpy     #5
        bcc     c1234

        ;; 5/6 are identical
        lda     position_table+5
        cmp     #5
        beq     :+
        cmp     #6
        bne     nope
:       lda     position_table+6
        cmp     #5
        beq     :+
        cmp     #6
        bne     nope
:       lda     position_table+7
        cmp     #7
        bne     nope
        lda     position_table+8
        cmp     #8
        bne     nope

        ;; 9/10 are identical
        lda     position_table+9
        cmp     #9
        beq     :+
        cmp     #10
        bne     nope
:       lda     position_table+10
        cmp     #9
        beq     :+
        cmp     #10
        bne     nope

:       lda     position_table+11
        cmp     #11
        bne     nope

        ;; 0/12 can be swapped
        lda     position_table+12
        beq     :+
        cmp     #12
        bne     nope

:       ldy     #13
c131415:tya
        cmp     position_table,y
        bne     nope
        iny
        cpy     #16
        bcc     c131415
        rts

nope:   clc
        rts
.endproc

;;; ==================================================
;;; Find hole piece

.proc find_hole
        ldy     #15
loop:   lda     position_table,y
        cmp     #hole_piece
        beq     :+
        dey
        bpl     loop

:       lda     #0
        sta     hole_x
        sta     hole_y

        tya
again:  cmp     #4
        bcc     done
        sbc     #4
        inc     hole_y
        bne     again

done:   sta     hole_x
        rts
.endproc

last := *
