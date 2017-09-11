        .org $800
        .setcpu "65C02"

        .include "apple2.inc"
        .include "../inc/prodos.inc"
        .include "../inc/auxmem.inc"

        .include "a2d.inc"

L0000           := $0000
L0020           := $0020
L1000           := $1000
L4021           := $4021

        jmp     L0825

L0803:  .byte   $00,$09,$4D,$44,$2E,$53,$59,$53
        .byte   $54,$45,$4D,$03,$04,$08,$00,$09
L0813:  .byte   $00,$02
L0815:  .byte   $00,$03,$00,$00,$04
L081A:  .byte   $00,$23,$08,$02,$00,$00,$00,$01
L0822:  .byte   $00
L0823:  .byte   $00

stash_stack:  .byte   $00
L0825:  tsx
        stx     L0803
        sta     ALTZPOFF
        lda     $C082
        lda     $BF90
        sta     L090F
        lda     $BF91
        sta     L0910
        lda     #$B8
        sta     STARTLO
        lda     #$08
        sta     STARTHI
        lda     #$2D
        sta     ENDLO
        lda     #$0F
        sta     ENDHI
        lda     #$B8
        sta     DESTINATIONLO
        lda     #$08
        sta     DESTINATIONHI
        sec
        jsr     AUXMOVE
        lda     #$B8
        sta     $03ED
        lda     #$08
        sta     $03EE
        php
        pla
        ora     #$40
        pha
        plp
        sec
        jmp     XFER

L086B:  sta     ALTZPON
        sta     L0823
        stx     stash_stack
        lda     LCBANK1
        lda     LCBANK1
        lda     L0823
        beq     L08B3
        ldy     #$C8
        lda     #$0E
        ldx     #$08
        jsr     L4021
        bne     L08B3
        lda     L0813
        sta     L0815
        sta     L081A
        sta     L0822
        ldy     #$CE
        lda     #$14
        ldx     #$08
        jsr     L4021
        bne     L08AA
        ldy     #$CB
        lda     #$19
        ldx     #$08
        jsr     L4021
L08AA:  ldy     #$CC
        lda     #$21
        ldx     #$08
        jsr     L4021
L08B3:  ldx     L0803
        txs
        rts

        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        jmp     L0986

L08C4:  .byte   $6A,$00,$2E,$00,$B5,$00,$39,$00
L08CC:  .byte   $10,$00,$2E,$00,$5A,$00,$39,$00
L08D4:  .byte   $AA,$00,$0A,$00,$B4,$00,$14,$00
L08DC:  .byte   $AA,$00,$1E,$00,$B4,$00,$28,$00
L08E4:  .byte   $25,$00,$14,$00,$3B,$00,$1E,$00
L08EC:  .byte   $51,$00,$14,$00,$6F,$00,$1E,$00
L08F4:  .byte   $7F,$00,$14,$00,$95,$00,$1E,$00
L08FC:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF
L0905:  .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF
L090E:  .byte   $00
L090F:  .byte   $00
L0910:  .byte   $00
L0911:  .byte   $1A
L0912:  .byte   $02
L0913:  .byte   $55
L0914:  .byte   $17,$09,$04,$20,$20,$20,$20
L091B:  .byte   $2B,$00,$1E,$00
L091F:  .byte   $22,$09,$02
L0922:  .byte   $20
L0923:  .byte   $20
L0924:  .byte   $57,$00,$1E,$00
L0928:  .byte   $2B,$09,$03,$20,$20,$20
L092E:  .byte   $85,$00,$1E,$00
L0932:  .byte   $35,$09,$02
L0935:  .byte   $20
L0936:  .byte   $20
L0937:  .byte   $00
L0938:  .byte   $00
L0939:  .byte   $00
L093A:  .byte   $00
L093B:  .byte   $00
L093C:  .byte   $00
L093D:  .byte   $00
L093E:  .byte   $64
L093F:  .byte   $00
L0940:  .byte   $00
L0941:  .byte   $00
L0942:  .byte   $00
L0943:  .byte   $00,$00,$00,$00
L0947:  .byte   $64,$00,$01
L094A:  .byte   $02,$06
L094C:  .byte   $64,$01,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$64,$00,$64,$00
        .byte   $F4,$01,$F4,$01
L0960:  .byte   $B4,$00,$32,$00,$00,$20,$80,$00
        .byte   $00,$00,$00,$00,$C7,$00,$40,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF,$00,$00,$00,$00,$00,$04,$02
        .byte   $00,$7F,$00,$88,$00,$00

L0986:  jsr     L0E00
        lda     L0910
        lsr     a
        sta     L0913
        lda     L090F
        and     #$1F
        sta     L0911
        lda     L0910
        ror     a
        lda     L090F
        ror     a
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     L0912
        A2D_CALL A2D_CREATE_WINDOW, L094C
        lda     #$00
        sta     L090E
        jsr     L0CF0
        A2D_CALL $2B
L09BB:  A2D_CALL A2D_GET_INPUT, L0937
        lda     L0937
        cmp     #$01
        bne     L09CE
        jsr     L0A45
        jmp     L09BB

L09CE:  cmp     #$03
        bne     L09BB
        lda     L0939
        bne     L09BB
        lda     L0938
        cmp     #$0D
        bne     L09E1
        jmp     L0A92

L09E1:  cmp     #$1B
        bne     L09E8
        jmp     L0ABB

L09E8:  cmp     #$08
        beq     L0A26
        cmp     #$15
        beq     L0A33
        cmp     #$0A
        beq     L0A0F
        cmp     #$0B
        bne     L09BB
        A2D_CALL A2D_FILL_RECT, L08D4
        lda     #$03
        sta     L0B50
        jsr     L0B17
        A2D_CALL A2D_FILL_RECT, L08D4
        jmp     L09BB

L0A0F:  A2D_CALL A2D_FILL_RECT, L08DC
        lda     #$04
        sta     L0B50
        jsr     L0B17
        A2D_CALL A2D_FILL_RECT, L08DC
        jmp     L09BB

L0A26:  sec
        lda     L090E
        sbc     #$01
        bne     L0A3F
        lda     #$03
        jmp     L0A3F

L0A33:  clc
        lda     L090E
        adc     #$01
        cmp     #$04
        bne     L0A3F
        lda     #$01
L0A3F:  jsr     L0DB4
        jmp     L09BB

L0A45:  A2D_CALL A2D_QUERY_TARGET, L0938
        A2D_CALL A2D_SET_FILL_MODE, L094A
        A2D_CALL A2D_SET_PATTERN, L0905
        lda     L093D
        cmp     #$64
        bne     L0A63
        lda     L093C
        bne     L0A64
L0A63:  rts

L0A64:  cmp     #$02
        bne     L0A63
        jsr     L0C54
        cpx     #$00
        beq     L0A63
        txa
        sec
        sbc     #$01
        asl     a
        tay
        lda     L0A84,y
        sta     L0A82
        lda     L0A85,y
        sta     L0A83
L0A82           := * + 1
L0A83           := * + 2
        jmp     L1000

L0A84:  .byte   $92
L0A85:  .byte   $0A,$BB,$0A,$C9,$0A,$D7,$0A,$E5
        .byte   $0A,$E5,$0A,$E5,$0A
L0A92:  A2D_CALL A2D_FILL_RECT, L08C4
        sta     RAMWRTOFF
        lda     L0912
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        ora     L0911
        sta     $BF90
        lda     L0913
        rol     a
        sta     $BF91
        sta     RAMWRTON
        lda     #$01
        sta     L0C1A
        jmp     L0C1B

L0ABB:  A2D_CALL A2D_FILL_RECT, L08CC
        lda     #$00
        sta     L0C1A
        jmp     L0C1B

        txa
        pha
        A2D_CALL A2D_FILL_RECT, L08D4
        pla
        tax
        jsr     L0AEC
        rts

        txa
        pha
        A2D_CALL A2D_FILL_RECT, L08DC
        pla
        tax
        jsr     L0AEC
        rts

        txa
        sec
        sbc     #$04
        jmp     L0DB4

L0AEC:  stx     L0B50
L0AEF:  A2D_CALL A2D_GET_INPUT, L0937
        lda     L0937
        cmp     #$02
        beq     L0B02
        jsr     L0B17
        jmp     L0AEF

L0B02:  lda     L0B50
        cmp     #$03
        beq     L0B10
        A2D_CALL A2D_FILL_RECT, L08DC
        rts

L0B10:  A2D_CALL A2D_FILL_RECT, L08D4
        rts

L0B17:  jsr     L0DF2
        lda     L0B50
        cmp     #$03
        beq     L0B2C
        lda     #$59
        sta     $07
        lda     #$0B
        sta     $08
        jmp     L0B34

L0B2C:  lda     #$51
        sta     $07
        lda     #$0B
        sta     $08
L0B34:  lda     L090E
        asl     a
        tay
        lda     ($07),y
        sta     L0B45
        iny
        lda     ($07),y
        sta     L0B46
L0B45           := * + 1
L0B46           := * + 2
        jsr     L1000
        A2D_CALL $0C, L08FC
        jmp     L0D73

L0B50:  .byte   $00,$00,$00,$61,$0B,$73,$0B,$85
        .byte   $0B,$00,$00,$97,$0B,$A4,$0B,$B1
        .byte   $0B
        clc
        lda     L0911
        adc     #$01
        cmp     #$20
        bne     L0B6D
        lda     #$01
L0B6D:  sta     L0911
        jmp     L0BBE

        clc
        lda     L0912
        adc     #$01
        cmp     #$0D
        bne     L0B7F
        lda     #$01
L0B7F:  sta     L0912
        jmp     L0BCB

        clc
        lda     L0913
        adc     #$01
        cmp     #$64
        bne     L0B91
        lda     #$00
L0B91:  sta     L0913
        jmp     L0C0D

        dec     L0911
        bne     L0BA1
        lda     #$1F
        sta     L0911
L0BA1:  jmp     L0BBE

        dec     L0912
        bne     L0BAE
        lda     #$0C
        sta     L0912
L0BAE:  jmp     L0BCB

        dec     L0913
        bpl     L0BBB
        lda     #$63
        sta     L0913
L0BBB:  jmp     L0C0D

L0BBE:  lda     L0911
        jsr     L0F16
        sta     L0922
        stx     L0923
        rts

L0BCB:  lda     L0912
        asl     a
        clc
        adc     L0912
        tax
        dex
        lda     #$2B
        sta     $07
        lda     #$09
        sta     $08
        ldy     #$02
L0BDF:  lda     L0BE9,x
        sta     ($07),y
        dex
        dey
        bpl     L0BDF
        rts

L0BE9:  .byte   $4A,$61,$6E,$46,$65,$62,$4D,$61
        .byte   $72,$41,$70,$72,$4D,$61,$79,$4A
        .byte   $75,$6E,$4A,$75,$6C,$41,$75,$67
        .byte   $53,$65,$70,$4F,$63,$74,$4E,$6F
        .byte   $76,$44,$65,$63
L0C0D:  lda     L0913
        jsr     L0F16
        sta     L0935
        stx     L0936
        rts

L0C1A:  brk
L0C1B:  A2D_CALL A2D_DESTROY_WINDOW, L0947
        jsr     UNKNOWN_CALL
        .byte   $0C
        .addr   L0000
        ldx     #$09
L0C29:  lda     L0C4B,x
        sta     L0020,x
        dex
        bpl     L0C29
        lda     L0C1A
        beq     L0C48
        lda     L0912
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        ora     L0911
        tay
        lda     L0913
        rol     a
        tax
        tya
L0C48:  jmp     L0020

L0C4B:  sta     RAMRDOFF
        sta     RAMWRTOFF
        jmp     L086B

L0C54:  lda     L0938
        sta     L093F
        lda     L0939
        sta     L0940
        lda     L093A
        sta     L0941
        lda     L093B
        sta     L0942
        A2D_CALL A2D_MAP_COORDS, L093E
        A2D_CALL A2D_SET_POS, L0943
        ldx     #$01
        lda     #$C4
        sta     L0C8A
        lda     #$08
        sta     L0C8A+1
L0C84:  txa
        pha
        A2D_CALL A2D_TEST_BOX, $1000, L0C8A
        bne     L0CA6
        clc
        lda     L0C8A
        adc     #$08
        sta     L0C8A
        bcc     L0C9C
        inc     L0C8A+1
L0C9C:  pla
        tax
        inx
        cpx     #$08
        bne     L0C84
        ldx     #$00
        rts

L0CA6:  pla
        tax
        rts

L0CA9:  .byte   $04,$00,$02,$00,$C0,$00,$3D,$00
L0CB1:  .byte   $20,$00,$0F,$00,$9A,$00,$23,$00
L0CB9:  .byte   $BC,$0C,$0C,$4F,$4B,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$0D
L0CC8:  .byte   $CB,$0C,$0B,$43,$61,$6E,$63,$65
        .byte   $6C,$20,$20,$45,$53,$43
L0CD6:  .byte   $D9,$0C,$01,$0B
L0CDA:  .byte   $DD,$0C,$01,$0A
L0CDE:  .byte   $15,$00,$38,$00
L0CE2:  .byte   $6E,$00,$38,$00
L0CE6:  .byte   $AC,$00,$13,$00
L0CEA:  .byte   $AC,$00,$27,$00
L0CEE:  .byte   $01,$01
L0CF0:  A2D_CALL A2D_SET_BOX1, L0960
        A2D_CALL A2D_DRAW_RECT, L0CA9
        A2D_CALL $0A, L0CEE
        A2D_CALL A2D_DRAW_RECT, L0CB1
        A2D_CALL A2D_DRAW_RECT, L08C4
        A2D_CALL A2D_DRAW_RECT, L08CC
        A2D_CALL A2D_SET_POS, L0CE2
        A2D_CALL A2D_DRAW_TEXT, L0CB9
        A2D_CALL A2D_SET_POS, L0CDE
        A2D_CALL A2D_DRAW_TEXT, L0CC8
        A2D_CALL A2D_SET_POS, L0CE6
        A2D_CALL A2D_DRAW_TEXT, L0CD6
        A2D_CALL A2D_DRAW_RECT, L08D4
        A2D_CALL A2D_SET_POS, L0CEA
        A2D_CALL A2D_DRAW_TEXT, L0CDA
        A2D_CALL A2D_DRAW_RECT, L08DC
        jsr     L0BBE
        jsr     L0BCB
        jsr     L0C0D
        jsr     L0D81
        jsr     L0D8E
        jsr     L0DA7
        A2D_CALL A2D_SET_FILL_MODE, L094A
        A2D_CALL A2D_SET_PATTERN, L0905
        lda     #$01
        jmp     L0DB4

L0D73:  lda     L090E
        cmp     #$01
        beq     L0D81
        cmp     #$02
        beq     L0D8E
        jmp     L0DA7

L0D81:  A2D_CALL A2D_SET_POS, L091B
        A2D_CALL A2D_DRAW_TEXT, L091F
        rts

L0D8E:  A2D_CALL A2D_SET_POS, L0924
        A2D_CALL A2D_DRAW_TEXT, L0914
        A2D_CALL A2D_SET_POS, L0924
        A2D_CALL A2D_DRAW_TEXT, L0928
        rts

L0DA7:  A2D_CALL A2D_SET_POS, L092E
        A2D_CALL A2D_DRAW_TEXT, L0932
        rts

L0DB4:  pha
        lda     L090E
        beq     L0DD1
        cmp     #$01
        bne     L0DC4
        jsr     L0DE4
        jmp     L0DD1

L0DC4:  cmp     #$02
        bne     L0DCE
        jsr     L0DEB
        jmp     L0DD1

L0DCE:  jsr     L0DDD
L0DD1:  pla
        sta     L090E
        cmp     #$01
        beq     L0DE4
        cmp     #$02
        beq     L0DEB
L0DDD:  A2D_CALL A2D_FILL_RECT, L08F4
        rts

L0DE4:  A2D_CALL A2D_FILL_RECT, L08E4
        rts

L0DEB:  A2D_CALL A2D_FILL_RECT, L08EC
        rts

L0DF2:  lda     #$FF
        sec
L0DF5:  pha
L0DF6:  sbc     #$01
        bne     L0DF6
        pla
        sbc     #$01
        bne     L0DF5
        rts

L0E00:  ldx     #$00
L0E02:  lda     L0000,x
        sta     L0E16,x
        dex
        bne     L0E02
        rts

        ldx     #$00
L0E0D:  lda     L0E16,x
        sta     L0000,x
        dex
        bne     L0E0D
        rts

L0E16:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00

L0F16:  ldy     #$00
L0F18:  cmp     #$0A
        bcc     L0F23
        sec
        sbc     #$0A
        iny
        jmp     L0F18

L0F23:  clc
        adc     #$30
        tax
        tya
        clc
        adc     #$30
        rts

        rts
