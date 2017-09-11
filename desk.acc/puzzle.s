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
        jmp     L0E53
.endproc

        window_id = $33

;;; ==================================================

.proc call_4015_main

        dest := $20

        ;; copy following routine to $20 and call it
        ldx     #(routine_end - routine)
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
        routine_end := *
.endproc

;;; ==================================================

L08B3:  .byte   0               ; ???
L08B4:  sta     query_box_params_id
        lda     L0E02
        cmp     #$BF
        bcc     L08C4
        lda     #$80
        sta     L08B3
        rts

;;; ==================================================

L08C4:  A2D_CALL A2D_QUERY_BOX, query_box_params
        A2D_CALL A2D_SET_BOX1, L0DB3
        lda     query_box_params_id
        cmp     #window_id
        bne     L08DA
        jmp     L1072

L08DA:  rts


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
L08E6:  .byte   0

.proc query_box_params
id:     .byte   0
addr:   .addr   $0DB3
.endproc
query_box_params_id := query_box_params::id

L08EA:  .byte   $05
L08EB:  .byte   0
L08EC:  .byte   $03
L08ED:  .byte   $00,$21,$00,$03,$00,$3D,$00,$03
        .byte   $00,$59,$00,$03,$00,$05,$00,$13
        .byte   $00,$21,$00,$13,$00,$3D,$00,$13
        .byte   $00,$59,$00,$13,$00,$05,$00,$23
        .byte   $00,$21,$00,$23,$00,$3D,$00,$23
        .byte   $00,$59,$00,$23,$00,$05,$00,$33
        .byte   $00,$21,$00,$33,$00,$3D,$00,$33
        .byte   $00,$59,$00,$33,$00

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
piece13:                       ; the gap
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

.proc set_pos_params            ; for what ???
        .word   5, 2
.endproc

L0D91:  .byte   $70,$00,$00,$00
L0D95:  .byte   $00
L0D96:  .byte   $00
L0D97:  .byte   $00
L0D98:  .byte   $00
L0D99:  .byte   $00
L0D9A:  .byte   $00
L0D9B:  .byte   $00
L0D9C:  .byte   $33,$73,$00,$F7,$FF,$AD,$0D,$01
        .byte   $00,$00,$00,$00,$00,$06,$00,$05
        .byte   $00,$41,$35,$47,$37,$36,$49

L0DB3:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$0D
        .byte   $00,$00,$20,$80,$00,$00,$00,$00
        .byte   $00,$2F,$02,$B1,$00,$00,$01,$02
        .byte   $06
L0DEC:  .byte   $33,$02,$4C,$0E,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$79,$00,$44,$00
        .byte   $79,$00,$44,$00,$DC,$00
L0E02:  .byte   $50,$00,$00,$20,$80,$00,$00,$00
        .byte   $00,$00,$79,$00,$44,$00,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $00,$00,$00,$00,$01,$01,$00,$7F
        .byte   $00,$88,$00,$00,$DC,$00,$50,$00
        .byte   $00,$20,$80,$00,$00,$00,$00,$00
        .byte   $79,$00,$44,$00,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$00,$00,$00
        .byte   $00,$00,$01,$01,$00,$7F,$00,$88
        .byte   $00,$00,$06,$50,$75,$7A,$7A,$6C
        .byte   $65

;;; ==================================================
;;; Create the window

L0E53:  jsr     save_zp
        A2D_CALL A2D_CREATE_WINDOW, L0DEC
        ldy     #$0F
L0E5E:  tya
        sta     position_table,y
        dey
        bpl     L0E5E
        lda     #window_id
        jsr     L08B4
        A2D_CALL $2B
L0E70:  ldy     #$03
L0E72:  tya
        pha
        ldx     position_table
        ldy     #$00
L0E79:  lda     position_table+1,y
        sta     position_table,y
        iny
        cpy     #$0F
        bcc     L0E79
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
        jsr     L11BB
        jsr     L12D2

;;; ==================================================
;;; Input loop and processing

input_loop:
        A2D_CALL A2D_GET_INPUT, get_input_params
        lda     get_input_params::state
        cmp     #A2D_INPUT_DOWN
        bne     :+
        jsr     L0ECB
        jmp     input_loop

        ;; key?
:       cmp     #A2D_INPUT_KEY
        bne     input_loop
        jsr     check_key
        jmp     input_loop

        ;; click - where?
L0ECB:  A2D_CALL A2D_QUERY_TARGET, query_target_params
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
        A2D_CALL A2D_CLOSE_CLICK, L08E6
        lda     L08E6
        beq     bail
L0EF9:  A2D_CALL A2D_DESTROY_WINDOW, L0D9C

        jsr     UNKNOWN_CALL    ; ???
        .byte   $0C
        .addr   0

        ldx     #$09            ; copy following to ZP and run it
L0F07:  lda     L0F12,x
        sta     L0020,x
        dex
        bpl     L0F07
        jmp     L0020

L0F12:  sta     RAMRDOFF
        sta     RAMWRTOFF
        jmp     exit_da

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
        beq     L0EF9
:       rts

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

        cmp     #$03
        bcc     nope
        cmp     #$14
        bcs     :+
        jsr     find_click_y
        bcc     nope
        lda     #0
        beq     yep
:       cmp     #$24
        bcs     :+
        jsr     find_click_y
        bcc     nope
        lda     #1
        bne     yep
:       cmp     #$34
        bcs     :+
        jsr     find_click_y
        bcc     nope
        lda     #2
        bne     yep
:       cmp     #$44
        bcs     nope
        jsr     find_click_y
        bcc     nope
        lda     #3

yep:    sta     L0D98
        sec
        rts

nope:   clc
        rts
.endproc

.proc find_click_y
        cpx     #$05
        bcc     nope
        cpx     #$21
        bcs     :+
        lda     #0
        beq     yep
:       cpx     #$3E
        bcs     :+
        lda     #1
        bne     yep
:       cpx     #$5A
        bcs     :+
        lda     #2
        bne     yep
:       cpx     #$75
        bcs     nope
        lda     #3

yep:    sta     L0D97
        sec
        rts

nope:   clc
        rts
.endproc

;;; ==================================================
;;; Process piece click

L0FBC:  lda     #$00
        ldy     L0D96
        beq     L0FC9
L0FC3:  clc
        adc     #$04
        dey
        bne     L0FC3
L0FC9:  sta     L0D99
        clc
        adc     L0D95
        tay
        lda     L0D97
        cmp     L0D95
        beq     L1014
        lda     L0D98
        cmp     L0D96
        beq     L0FE2
L0FE1:  rts

L0FE2:  lda     L0D97
        cmp     L0D95
        beq     L0FE1
        bcs     L1000
        lda     L0D95
        sec
        sbc     L0D97
        tax
L0FF4:  lda     position_table-1,y
        sta     position_table,y
        dey
        dex
        bne     L0FF4
        beq     L1055
L1000:  lda     L0D97
        sec
        sbc     L0D95
        tax
L1008:  lda     position_table+1,y
        sta     position_table,y
        iny
        dex
        bne     L1008
        beq     L1055
L1014:  lda     L0D98
        cmp     L0D96
        beq     L0FE1
        bcs     L1035
        lda     L0D96
        sec
        sbc     L0D98
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
L1035:  lda     L0D98
        sec
        sbc     L0D96
        tax
L103D:  lda     position_table+4,y
        sta     position_table,y
        iny
        iny
        iny
        iny
        dex
        bne     L103D
L104A:  lda     #$0C
        sta     position_table,y
        jsr     L11D9
        jmp     L105D

L1055:  lda     #$0C
        sta     position_table,y
        jsr     L11C8
L105D:  jsr     check_victory
        bcc     L106E
        ldx     #$04
L1064:  txa
        pha
        jsr     play_sound
        pla
        tax
        dex
        bne     L1064
L106E:  jmp     L12D2

        rts

;;; ==================================================
;;; Clear the background

L1072:  A2D_CALL A2D_SET_PATTERN, pattern_speckles
        A2D_CALL A2D_FILL_RECT, fill_rect_params
        A2D_CALL A2D_SET_PATTERN, pattern_black
        A2D_CALL A2D_SET_POS, set_pos_params
        A2D_CALL $0F, L0D91     ; ???
        jsr     L11BB

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

L11BB:  ldy     #$01
        sty     L0D9B
        dey
        lda     #$10
        sta     L0D9A
        bne     L11E6
L11C8:  lda     #$01
        sta     L0D9B
        lda     L0D99
        tay
        clc
        adc     #$04
        sta     L0D9A
        bne     L11E6
L11D9:  lda     #$04
        sta     L0D9B
        ldy     L0D95
        lda     #$10
        sta     L0D9A
L11E6:  tya
        pha
        A2D_CALL A2D_HIDE_CURSOR
        lda     #window_id
        sta     query_box_params::id
        A2D_CALL A2D_QUERY_BOX, query_box_params
        A2D_CALL A2D_SET_BOX1, L0DB3
        pla
        tay
L1201:  tya
        pha
        asl     a
        asl     a
        tax
        lda     L08EA,x
        sta     draw_pattern_params::left
        lda     L08EB,x
        sta     draw_pattern_params::left+1
        lda     L08EC,x
        sta     draw_pattern_params::top
        lda     L08ED,x
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
        adc     L0D9B
        tay
        cpy     L0D9A
        bcc     L1201
        A2D_CALL A2D_SHOW_CURSOR
        rts

;;; ==================================================
;;; Play sound

.proc play_sound
        ldx     #$80
L1249:  lda     #$58
L124B:  ldy     #$1B
L124D:  dey
        bne     L124D
        bit     SPKR
        tay
delay:  dey
        bne     delay
        sbc     #$01
        beq     L1249
        bit     SPKR
        dex
        bne     L124B
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


L12D2:  ldy     #$0F
L12D4:  lda     position_table,y
        cmp     #$0C
        beq     L12DE
        dey
        bpl     L12D4
L12DE:  lda     #0
        sta     L0D95
        sta     L0D96
        tya
L12E7:  cmp     #4
        bcc     L12F2
        sbc     #4
        inc     L0D96
        bne     L12E7
L12F2:  sta     L0D95
        rts

last := *
