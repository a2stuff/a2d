        .org $800
        .setcpu "65C02"

        .include "apple2.inc"
        .include "../inc/prodos.inc"
        .include "../inc/auxmem.inc"

        .include "a2d.inc"


L0000           := $0000
L0020           := $0020
L4015           := $4015

        jmp     L0828

        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00

stash_stack:  .byte   $00
L0828:  tsx
        stx     stash_stack
        sta     ALTZPOFF
        lda     $C082
        lda     #$70
        sta     STARTLO
        lda     #$08
        sta     STARTHI
        lda     #$F6
        sta     ENDLO
        lda     #$12
        sta     ENDHI
        lda     #$70
        sta     DESTINATIONLO
        lda     #$08
        sta     DESTINATIONHI
        sec
        jsr     AUXMOVE
        lda     #$70
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

L0862:  sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        ldx     stash_stack
        txs
        rts

        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        lda     #$00
        sta     $08
        jmp     L0E53

L0880:  ldx     #$10
L0882:  lda     L08A3,x
        sta     L0020,x
        dex
        bpl     L0882
        jsr     L0020
        lda     #$33
        jsr     L08B4
        bit     L08B3
        bmi     L089D
        jsr     UNKNOWN_CALL
        .byte   $0C
        .addr   L0000
L089D:  lda     #$00
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
        cmp     #$33
        bne     L08DA
        jmp     L1072

L08DA:  rts

L08DB:  .byte   $00
L08DC:  .byte   $00
L08DD:  .byte   $00,$00,$00
L08E0:  .byte   $00
L08E1:  .byte   $00
L08E2:  .byte   $00
L08E3:  .byte   $00,$00,$00
L08E6:  .byte   $00
L08E7:  .byte   $00,$B3,$0D
L08EA:  .byte   $05
L08EB:  .byte   $00
L08EC:  .byte   $03
L08ED:  .byte   $00,$21,$00,$03,$00,$3D,$00,$03
        .byte   $00,$59,$00,$03,$00,$05,$00,$13
        .byte   $00,$21,$00,$13,$00,$3D,$00,$13
        .byte   $00,$59,$00,$13,$00,$05,$00,$23
        .byte   $00,$21,$00,$23,$00,$3D,$00,$23
        .byte   $00,$59,$00,$23,$00,$05,$00,$33
        .byte   $00,$21,$00,$33,$00,$3D,$00,$33
        .byte   $00,$59,$00,$33,$00
L092A:  .byte   $6A
L092B:  .byte   $09,$AA,$09,$EA,$09,$2A,$0A,$6A
        .byte   $0A,$AA,$0A,$EA,$0A,$2A,$0B,$6A
        .byte   $0B,$AA,$0B,$EA,$0B,$2A,$0C,$6A
        .byte   $0C,$AA,$0C
L0946:  .byte   $EA,$0C,$2A
L0949:  .byte   $0D
L094A:  .byte   $00
L094B:  .byte   $00,$00,$00
L094E:  .byte   $00
L094F:  .byte   $00
L0950:  .byte   $00
L0951:  .byte   $00
L0952:  .byte   $00
L0953:  .byte   $00
L0954:  .byte   $00
L0955:  .byte   $00
L0956:  .byte   $00,$00,$00
L0959:  .byte   $00
L095A:  .byte   $00
L095B:  .byte   $00
L095C:  .byte   $00
L095D:  .byte   $00
L095E:  .byte   $00
L095F:  .byte   $00,$04,$00,$00,$00,$00,$00,$1B
        .byte   $00,$0F,$00,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$00
        .byte   $00,$00,$00,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $00,$7C,$3F,$0E,$55,$42,$3F,$00
        .byte   $00,$00,$00,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$47,$3F,$7E
        .byte   $7F,$54,$3E,$7E,$5F,$2A,$3D,$7E
        .byte   $27,$55,$3E,$7E,$53,$2A,$3E,$7E
        .byte   $28,$15,$3F,$3E,$55,$4A,$3F,$5E
        .byte   $2A,$71,$3F,$2E,$55,$7C,$3F,$56
        .byte   $0A,$7E,$3F,$26,$65,$7F,$3F,$56
        .byte   $78,$1F,$00,$06,$7F,$21,$15,$00
        .byte   $00,$00,$00,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$70
        .byte   $7F,$7F,$3F,$0A,$7E,$7F,$3F,$00
        .byte   $00,$00,$00,$7E,$7F,$7F,$1F,$7E
        .byte   $7F,$7F,$1F,$7E,$7F,$7F,$17,$7E
        .byte   $7F,$7F,$2B,$7E,$7F,$7F,$3D,$7E
        .byte   $7F,$7F,$3E,$7E,$7F,$3F,$3F,$7E
        .byte   $7F,$5F,$3F,$7E,$7F,$5F,$3F,$7E
        .byte   $7F,$6F,$3F,$7E,$7F,$77,$3F,$7E
        .byte   $7F,$77,$3F,$7E,$7F,$37,$1B,$7E
        .byte   $7F,$5B,$2D,$7E,$7F,$6B,$36,$00
        .byte   $00,$00,$00,$2A,$55,$2A,$15,$54
        .byte   $2A,$55,$2A,$2A,$55,$2A,$15,$54
        .byte   $2A,$55,$2A,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$6C,$36,$5B,$2D,$36
        .byte   $5B,$6D,$36,$5A,$6D,$36,$1B,$00
        .byte   $00,$00,$00,$2A,$55,$2A,$15,$54
        .byte   $2A,$55,$2A,$2A,$55,$2A,$15,$54
        .byte   $2A,$55,$2A,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$36,$5B,$6D,$36,$5A
        .byte   $6D,$36,$1B,$6C,$36,$5B,$2D,$00
        .byte   $00,$00,$00,$2A,$45,$7F,$3F,$54
        .byte   $2A,$7E,$3F,$2A,$55,$78,$3F,$54
        .byte   $2A,$71,$3F,$7E,$7F,$7C,$3F,$7E
        .byte   $3F,$7F,$3F,$7E,$5F,$7F,$3F,$7E
        .byte   $6F,$7F,$3F,$7E,$77,$7F,$3F,$7E
        .byte   $77,$7F,$3F,$7E,$7B,$7F,$3F,$7E
        .byte   $7B,$7F,$3F,$5A,$79,$7F,$3F,$6C
        .byte   $7C,$7F,$3F,$36,$7D,$7F,$3F,$00
        .byte   $00,$00,$00,$7E,$7F,$67,$36,$7E
        .byte   $7F,$37,$1B,$7E,$7F,$57,$2D,$7E
        .byte   $7F,$67,$36,$7E,$7F,$2F,$15,$7E
        .byte   $7F,$2F,$15,$7E,$7F,$1F,$15,$7E
        .byte   $7F,$3F,$15,$7E,$7F,$3F,$15,$7E
        .byte   $7F,$3F,$15,$7E,$7F,$7F,$14,$7E
        .byte   $7F,$7F,$19,$7E,$7F,$7F,$33,$7E
        .byte   $7F,$7F,$17,$7E,$7F,$7F,$2F,$00
        .byte   $00,$00,$00,$5A,$6D,$36,$1B,$6C
        .byte   $36,$5B,$2D,$36,$5B,$6D,$36,$5A
        .byte   $6D,$36,$1B,$2A,$55,$2A,$15,$2A
        .byte   $55,$2A,$15,$2A,$55,$2A,$15,$2A
        .byte   $55,$2A,$15,$2A,$55,$2A,$15,$2A
        .byte   $55,$2A,$15,$2A,$55,$2A,$15,$32
        .byte   $66,$4C,$19,$66,$4C,$19,$33,$32
        .byte   $66,$4C,$19,$66,$4C,$19,$33,$00
        .byte   $00,$00,$00,$6C,$36,$5B,$2D,$36
        .byte   $5B,$6D,$36,$5A,$6D,$36,$1B,$6C
        .byte   $36,$5B,$2D,$2A,$55,$2A,$15,$2A
        .byte   $55,$2A,$15,$2A,$55,$2A,$15,$2A
        .byte   $55,$2A,$15,$2A,$55,$2A,$15,$2A
        .byte   $55,$2A,$15,$2A,$55,$2A,$15,$32
        .byte   $66,$4C,$19,$66,$4C,$19,$33,$32
        .byte   $66,$4C,$19,$66,$4C,$19,$33,$00
        .byte   $00,$00,$00,$36,$7D,$7F,$3F,$5A
        .byte   $7D,$7F,$3F,$6C,$7A,$7F,$3F,$36
        .byte   $7B,$7F,$3F,$2A,$75,$7F,$3F,$2A
        .byte   $65,$7F,$3F,$2A,$65,$7F,$3F,$2A
        .byte   $55,$7F,$3F,$2A,$15,$7F,$3F,$2A
        .byte   $55,$7C,$3F,$2A,$55,$72,$3F,$32
        .byte   $66,$74,$3F,$66,$4C,$79,$3F,$32
        .byte   $66,$78,$3F,$66,$4C,$7D,$3F,$00
        .byte   $00,$00,$00,$7E,$7F,$7F,$3F,$6E
        .byte   $5D,$3B,$37,$7E,$7F,$7F,$3F,$3A
        .byte   $77,$6E,$1D,$7E,$7F,$7F,$3F,$6E
        .byte   $5D,$3B,$37,$7E,$7F,$7F,$3F,$3A
        .byte   $77,$6E,$1D,$7E,$7F,$7F,$3F,$6E
        .byte   $5D,$3B,$37,$7E,$7F,$7F,$3F,$3A
        .byte   $77,$6E,$1D,$7E,$7F,$7F,$3F,$6E
        .byte   $5D,$3B,$37,$7E,$7F,$7F,$3F,$00
        .byte   $00,$00,$00,$18,$33,$66,$0C,$32
        .byte   $66,$4C,$19,$66,$4C,$19,$33,$6C
        .byte   $36,$5B,$2D,$52,$6D,$36,$1B,$26
        .byte   $5B,$6D,$36,$4E,$36,$5B,$2D,$3E
        .byte   $6E,$36,$1B,$7E,$51,$0D,$00,$7E
        .byte   $0F,$40,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$00
        .byte   $00,$00,$00,$18,$33,$66,$0C,$32
        .byte   $66,$4C,$19,$66,$4C,$19,$33,$36
        .byte   $5B,$6D,$36,$6C,$36,$5B,$2D,$5A
        .byte   $6D,$36,$1B,$36,$5B,$6D,$36,$6C
        .byte   $36,$5B,$2D,$00,$00,$30,$1B,$7E
        .byte   $7F,$03,$20,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$00
        .byte   $00,$00,$00,$18,$33,$7C,$3F,$32
        .byte   $66,$7E,$3F,$66,$0C,$7F,$3F,$5A
        .byte   $4D,$7F,$3F,$36,$73,$7F,$3F,$6C
        .byte   $7C,$7F,$3F,$3A,$7E,$7F,$3F,$72
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$7E
        .byte   $7F,$7F,$3F,$7E,$7F,$7F,$3F,$00
        .byte   $00,$00,$00
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
L0E53:  jsr     L10A5
        A2D_CALL A2D_CREATE_WINDOW, L0DEC
        ldy     #$0F
L0E5E:  tya
        sta     L094A,y
        dey
        bpl     L0E5E
        lda     #$33
        jsr     L08B4
        A2D_CALL $2B
L0E70:  ldy     #$03
L0E72:  tya
        pha
        ldx     L094A
        ldy     #$00
L0E79:  lda     L094B,y
        sta     L094A,y
        iny
        cpy     #$0F
        bcc     L0E79
        stx     L0959
        pla
        tay
        dey
        bne     L0E72
        ldx     L094A
        lda     L094B
        sta     L094A
        stx     L094B
        A2D_CALL A2D_GET_INPUT, L08DB
        lda     L08DB
        beq     L0E70
        jsr     L1262
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
        cmp     #$33
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
        .addr   L0000

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
        lda     #$33
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

L0F3D:  lda     #$33
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
L0FF4:  lda     L0949,y
        sta     L094A,y
        dey
        dex
        bne     L0FF4
        beq     L1055
L1000:  lda     L0D97
        sec
        sbc     L0D95
        tax
L1008:  lda     L094B,y
        sta     L094A,y
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
L1026:  lda     L0946,y
        sta     L094A,y
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
L103D:  lda     L094E,y
        sta     L094A,y
        iny
        iny
        iny
        iny
        dex
        bne     L103D
L104A:  lda     #$0C
        sta     L094A,y
        jsr     L11D9
        jmp     L105D

L1055:  lda     #$0C
        sta     L094A,y
        jsr     L11C8
L105D:  jsr     L1262
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
        lda     #$33
        sta     L08E7
        A2D_CALL A2D_QUERY_BOX, L08E7
        A2D_CALL A2D_SET_BOX1, L0DB3
        rts

L10A5:  ldx     #$00
L10A7:  lda     L0000,x
        sta     L10BB,x
        dex
        bne     L10A7
        rts

        ldx     #$00
L10B2:  lda     L10BB,x
        sta     L0000,x
        dex
        bne     L10B2
        rts

L10BB:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
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
        lda     #$33
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
        sta     L095A
        lda     L08EB,x
        sta     L095B
        lda     L08EC,x
        sta     L095C
        lda     L08ED,x
        sta     L095D
        lda     L094A,y
        asl     a
        tax
        lda     L092A,x
        sta     L095E
        lda     L092B,x
        sta     L095F
        A2D_CALL A2D_DRAW_PATTERN, L095A
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

L1262:  lda     L094A
        beq     L126B
        cmp     #$0C
        bne     L12D0
L126B:  ldy     #$01
L126D:  tya
        cmp     L094A,y
        bne     L12D0
        iny
        cpy     #$05
        bcc     L126D
        lda     L094F
        cmp     #$05
        beq     L1283
        cmp     #$06
        bne     L12D0
L1283:  lda     L0950
        cmp     #$05
        beq     L128E
        cmp     #$06
        bne     L12D0
L128E:  lda     L0951
        cmp     #$07
        bne     L12D0
        lda     L0952
        cmp     #$08
        bne     L12D0
        lda     L0953
        cmp     #$09
        beq     L12A7
        cmp     #$0A
        bne     L12D0
L12A7:  lda     L0954
        cmp     #$09
        beq     L12B2
        cmp     #$0A
        bne     L12D0
L12B2:  lda     L0955
        cmp     #$0B
        bne     L12D0
        lda     L0956
        beq     L12C2
        cmp     #$0C
        bne     L12D0
L12C2:  ldy     #$0D
L12C4:  tya
        cmp     L094A,y
        bne     L12D0
        iny
        cpy     #$10
        bcc     L12C4
        rts

L12D0:  clc
        rts

L12D2:  ldy     #$0F
L12D4:  lda     L094A,y
        cmp     #$0C
        beq     L12DE
        dey
        bpl     L12D4
L12DE:  lda     #$00
        sta     L0D95
        sta     L0D96
        tya
L12E7:  cmp     #$04
        bcc     L12F2
        sbc     #$04
        inc     L0D96
        bne     L12E7
L12F2:  sta     L0D95
        rts
