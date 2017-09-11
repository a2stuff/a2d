        .org $800
        .setcpu "65C02"

        .include "apple2.inc"
        .include "../inc/prodos.inc"
        .include "../inc/auxmem.inc"

        .include "a2d.inc"


L0020           := $0020
L4015           := $4015

        jmp     L0828

        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0,0,0,0,0
        .byte   0,0,0,0

stash_stack:  .byte   0
L0828:  tsx
        stx     stash_stack
        sta     ALTZPOFF
        lda     $C082
        lda     #<L0870
        sta     STARTLO
        lda     #>L0870
        sta     STARTHI
        lda     #$F6
        sta     ENDLO
        lda     #$12
        sta     ENDHI
        lda     #<L0870
        sta     DESTINATIONLO
        lda     #>L0870
        sta     DESTINATIONHI
        sec
        jsr     AUXMOVE
        lda     #<L0870
        sta     $03ED
        lda     #>L0870
        sta     $03EE
        php
        pla
        ora     #$40
        pha
        plp
        sec
        jmp     XFER

L0862:  sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        ldx     stash_stack
        txs
        rts

L0870:  sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        lda     #0
        sta     $08
        jmp     L0E53

        window_id = $33

L0880:  ldx     #$10
L0882:  lda     L08A3,x
        sta     L0020,x
        dex
        bpl     L0882
        jsr     L0020
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

L08A3:  sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     L4015
        sta     RAMRDON
        sta     RAMWRTON
        rts

L08B3:  brk
L08B4:  sta     L08E7
        lda     L0E02
        cmp     #$BF
        bcc     L08C4
        lda     #$80
        sta     L08B3
        rts

L08C4:  A2D_CALL A2D_QUERY_BOX, L08E7
        A2D_CALL A2D_SET_BOX1, L0DB3
        lda     L08E7
        cmp     #window_id
        bne     L08DA
        jmp     L1072

L08DA:  rts

L08DB:  .byte   0
L08DC:  .byte   0
L08DD:  .byte   0,0,0
L08E0:  .byte   0
L08E1:  .byte   0
L08E2:  .byte   0
L08E3:  .byte   0,0,0
L08E6:  .byte   0
L08E7:  .byte   0,$B3,$0D
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



L0D6A:  .byte   $01,$00,$00,$00,$79,$00,$44,$00
L0D72:  .byte   $77,$DD,$77,$DD,$77,$DD,$77,$DD
        .byte   $00
L0D7B:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$00
L0D8D:  .byte   $05,$00,$02,$00
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
        A2D_CALL A2D_GET_INPUT, L08DB
        lda     L08DB
        beq     L0E70
        jsr     check_victory
        bcs     L0E70
        jsr     L11BB
        jsr     L12D2
L0EAE:  A2D_CALL A2D_GET_INPUT, L08DB
        lda     L08DB
        cmp     #$01
        bne     L0EC1
        jsr     L0ECB
        jmp     L0EAE

L0EC1:  cmp     #$03
        bne     L0EAE
        jsr     L0F30
        jmp     L0EAE

L0ECB:  A2D_CALL A2D_QUERY_TARGET, L08DC
        lda     L08E1
        cmp     #window_id
        bne     L0EDD
        lda     L08E0
        bne     L0EDE
L0EDD:  rts

L0EDE:  cmp     #$02
        bne     L0EEA
        jsr     L0F3D
        bcc     L0EDD
        jmp     L0FBC

L0EEA:  cmp     #$05
        bne     L0F1B
        A2D_CALL A2D_CLOSE_CLICK, L08E6
        lda     L08E6
        beq     L0EDD
L0EF9:  A2D_CALL A2D_DESTROY_WINDOW, L0D9C

        jsr     UNKNOWN_CALL
        .byte   $0C
        .addr   0

        ldx     #$09
L0F07:  lda     L0F12,x
        sta     L0020,x
        dex
        bpl     L0F07
        jmp     L0020

L0F12:  sta     RAMRDOFF
        sta     RAMWRTOFF
        jmp     L0862

L0F1B:  cmp     #$03
        bne     L0EDD
        lda     #window_id
        sta     L08DB
        A2D_CALL A2D_DRAG_WINDOW, L08DB
        ldx     #$23
        jsr     L0880
        rts

L0F30:  lda     L08DD
        bne     L0F3C
        lda     L08DC
        cmp     #$1B
        beq     L0EF9
L0F3C:  rts

L0F3D:  lda     #window_id
        sta     L08DB
        A2D_CALL A2D_MAP_COORDS, L08DB
        lda     L08E1
        ora     L08E3
        bne     L0F91
        lda     L08E2
        ldx     L08E0
        cmp     #$03
        bcc     L0F91
        cmp     #$14
        bcs     L0F67
        jsr     L0F93
        bcc     L0F91
        lda     #$00
        beq     L0F8C
L0F67:  cmp     #$24
        bcs     L0F74
        jsr     L0F93
        bcc     L0F91
        lda     #$01
        bne     L0F8C
L0F74:  cmp     #$34
        bcs     L0F81
        jsr     L0F93
        bcc     L0F91
        lda     #$02
        bne     L0F8C
L0F81:  cmp     #$44
        bcs     L0F91
        jsr     L0F93
        bcc     L0F91
        lda     #$03
L0F8C:  sta     L0D98
        sec
        rts

L0F91:  clc
        rts

L0F93:  cpx     #$05
        bcc     L0FBA
        cpx     #$21
        bcs     L0F9F
        lda     #$00
        beq     L0FB5
L0F9F:  cpx     #$3E
        bcs     L0FA7
        lda     #$01
        bne     L0FB5
L0FA7:  cpx     #$5A
        bcs     L0FAF
        lda     #$02
        bne     L0FB5
L0FAF:  cpx     #$75
        bcs     L0FBA
        lda     #$03
L0FB5:  sta     L0D97
        sec
        rts

L0FBA:  clc
        rts

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
        jsr     L1247
        pla
        tax
        dex
        bne     L1064
L106E:  jmp     L12D2

        rts

L1072:  A2D_CALL A2D_SET_PATTERN, L0D72
        A2D_CALL A2D_FILL_RECT, L0D6A
        A2D_CALL A2D_SET_PATTERN, L0D7B
        A2D_CALL A2D_SET_POS, L0D8D
        A2D_CALL $0F, L0D91
        jsr     L11BB
        lda     #window_id
        sta     L08E7
        A2D_CALL A2D_QUERY_BOX, L08E7
        A2D_CALL A2D_SET_BOX1, L0DB3
        rts

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
        sta     L08E7
        A2D_CALL A2D_QUERY_BOX, L08E7
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

L1247:  ldx     #$80
L1249:  lda     #$58
L124B:  ldy     #$1B
L124D:  dey
        bne     L124D
        bit     $C030
        tay
L1254:  dey
        bne     L1254
        sbc     #$01
        beq     L1249
        bit     $C030
        dex
        bne     L124B
        rts

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
