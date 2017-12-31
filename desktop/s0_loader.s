.org $2000
; da65 V2.16 - Git f5e9b401
; Created:    2017-09-27 19:43:21
; Input file: orig/DESKTOP2_s0_loader
; Page:       1


        .setcpu "65C02"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/prodos.inc"

L02B4           := $02B4
L02B6           := $02B6
L02C3           := $02C3
L02C5           := $02C5
L02E6           := $02E6
L035F           := $035F
L0393           := $0393
L03B3           := $03B3
L03C1           := $03C1
L03E5           := $03E5
L0800           := $0800
L1031           := $1031
L1039           := $1039
L103B           := $103B
L1044           := $1044
L10F4           := $10F4
L1129           := $1129
L118B           := $118B
A2D             := $4000
L7ECA           := $7ECA
UNKNOWN_CALL    := $8E00

L2000:  lda     LCBANK2
L2003:  lda     LCBANK2
        ldy     #$00
L2008:
L2009           := * + 1
L200A           := * + 2
        lda     L2027,y
L200B:
L200C           := * + 1
L200D           := * + 2
        sta     $D100,y
L200E:  lda     L2127,y
L2011:
L2013           := * + 2
        sta     $D200,y
L2014:  dey
        bne     L2008
        lda     ROMIN2
        jsr     MLI
        .byte   $65
        .addr   L2020
L2020:  .byte   $04
L2021:  brk
L2022:  brk
        brk
        brk
        brk
        brk
L2027:  jmp     L1044

        .byte   $00,$4D,$6F,$75
L202E:  .byte   $73,$65,$20,$44,$65,$73,$6B,$00
        .byte   $18,$4C,$6F
L2039:  .byte   $61
L203A:  .byte   $64,$69,$6E,$67,$20,$41,$70,$70
        .byte   $6C,$65,$20
L2045:  .byte   $49,$49,$20,$44,$65,$73
L204B:  .byte   $6B,$54,$6F,$70,$08,$44,$65,$73
        .byte   $6B,$54,$6F,$70,$32,$04,$00,$00
        .byte   $1E,$00,$04,$00,$00,$01,$00,$01
        .byte   $90,$11,$03,$28,$10,$00,$1A,$00
        lda     ROMIN2
        jsr     SETVID
        jsr     SETKBD
        sta     CLR80VID
        sta     SETALTCHAR
        sta     CLR80COL
        jsr     SLOT3ENTRY
L2080:  jsr     HOME
        lda     #$00
        sta     SHADOW          ; ??? IIgs specific?
        lda     #$40
        sta     RAMWRTON
        sta     $0100
        sta     $0101
        sta     RAMWRTOFF
        lda     #$0C
        sta     $25
        jsr     VTAB
        lda     #$50
        sec
        sbc     $100F
        lsr     a
        sta     $24
        ldy     #$00
L20A8:  lda     $1010,y
        ora     #$80
        jsr     COUT
        iny
        cpy     $100F
        bne     L20A8
        jsr     MLI
        .byte   $CC
        .addr   L1039
        ldx     #$17
        lda     #$01
        sta     $BF58,x
        dex
        lda     #$00
L20C6:  sta     $BF58,x
        dex
        bpl     L20C6
        lda     #$CF
        sta     $BF58
        lda     $1003
        bne     L210F
L20D6:  jsr     MLI
        .byte   $C7
        .addr   L103B
L20DC:  .byte   $F0
L20DD:  .byte   $03
        jmp     L118B

L20E1:  lda     #$FF
        sta     $1003
        lda     $03FE
        sta     $1189
        lda     $03FF
        sta     $118A
        lda     LCBANK2
        lda     LCBANK2
        ldy     #$00
L20FA:  lda     $1000,y
        sta     $D100,y
        lda     $1100,y
        sta     $D200,y
        dey
        bne     L20FA
        lda     ROMIN2
        jmp     L10F4

L210F:  lda     $1189
        sta     $03FE
        lda     $118A
        sta     $03FF
        jsr     MLI
        .byte   $C6
        .addr   L103B
        beq     L2126
        jmp     L1129

L2126:  .byte   $20
L2127:  brk
        bbs3    $C8,L2169
        .byte   $10
        .byte   $F0
L212D:  .byte   $03
L212E:  jmp     L118B

L2131:  lda     $1043
        sta     $1032
        jsr     MLI
        .byte   $CA
        .addr   L1031
        beq     L2142
        jmp     L118B

L2142:  jsr     MLI
        .byte   $CC
        .addr   L1039
        beq     L214D
        jmp     L118B

L214D:  jmp     L2000

        jsr     SLOT3ENTRY
        jsr     HOME
        lda     #$0C
        sta     $25
        jsr     VTAB
        lda     #$50
        sec
        sbc     $1160
        lsr     a
        sta     $24
        ldy     #$00
L2168:  .byte   $B9
L2169:  adc     ($11,x)
        ora     #$80
        jsr     COUT
        iny
        cpy     $1160
        bne     L2168
L2176:  sta     KBDSTRB
L2179:  lda     CLR80COL
        bpl     L2179
        and     #$7F
        cmp     #$0D
        bne     L2176
        jmp     L1044

        .byte   $28,$49,$6E,$73,$65,$72,$74,$20
        .byte   $74,$68,$65,$20,$73,$79,$73,$74
        .byte   $65,$6D,$20,$64,$69,$73,$6B,$20
        .byte   $61,$6E,$64,$20,$50,$72,$65,$73
        .byte   $73,$20,$52,$65,$74,$75,$72,$6E
        .byte   $2E,$00,$00,$85,$06,$4C,$69,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$4C,$4C,$20,$03,$18,$20,$00
        .byte   $30,$00,$04,$00,$00,$00,$00,$00
        .byte   $00,$00,$01,$00,$02,$00,$80,$05
        .byte   $00,$08,$44,$65,$73,$6B,$54,$6F
        .byte   $70,$32,$00,$3F,$00,$40,$00,$40
        .byte   $00,$40,$00,$08,$90,$02,$00,$40
        .byte   $00,$D0,$00,$FB,$00,$40,$00,$08
        .byte   $90,$02,$00,$80,$00,$1D,$00,$05
        .byte   $00,$7F,$00,$08,$60,$01,$01,$02
        .byte   $02,$00,$00,$00,$06,$A2,$17,$A9
        .byte   $00
L2250:  sta     $BF59,x
        dex
        bpl     L2250
        php
        sei
        jsr     MLI
        .byte   $C8
        .addr   L2003
        plp
        and     #$FF
        beq     L2264
        brk
L2264:  lda     L2008
        sta     L2014
        sta     L200A
        php
        sei
        jsr     MLI
        .byte   $CE
        .addr   L2013
        plp
        and     #$FF
        beq     L227B
        brk
L227B:  lda     #$00
        sta     L20DC
        lda     L20DC
        cmp     L204B
        bne     L2299
        php
        sei
        jsr     MLI
        .byte   $CC
        .addr   L2011
        plp
        and     #$FF
        beq     L2296
        brk
L2296:  jmp     L0800

L2299:  asl     a
        tax
        lda     L2021,x
        sta     L200B
        lda     L2022,x
        sta     L200C
        lda     L2039,x
        sta     L200D
        lda     L203A,x
        sta     L200E
        php
        sei
        jsr     MLI
        .byte   $CA
        .addr   L2009
        plp
        and     #$FF
        beq     L22C1
        brk
L22C1:  ldx     L20DC
        lda     L2045,x
        beq     L22D6
        cmp     #$02
        beq     L22D3
        jsr     L212E
        jmp     L20D6

L22D3:  jsr     L20DD
L22D6:  inc     L20DC
        jmp     L2080

        brk
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        lda     #$80
        sta     $0100
        sta     $0101
        lda     #$00
        sta     $06
        sta     $08
        lda     L20DC
        asl     a
        tax
        lda     L202E,x
        sta     $09
        lda     L200C
        sta     $07
        clc
        adc     L203A,x
        sta     L212D
        lda     L2039,x
        beq     L2312
        inc     L212D
L2312:  ldy     #$00
L2314:  lda     ($06),y
        sta     ($08),y
        iny
        bne     L2314
        inc     $07
        inc     $09
        lda     $07
        cmp     L212D
        bne     L2314
        sta     ALTZPOFF
        lda     ROMIN2
        rts

        brk
        lda     #$00
        sta     $06
        sta     $08
        lda     L20DC
        asl     a
        tax
        lda     L202E,x
        sta     $09
        lda     L200C
        sta     $07
        clc
        adc     L203A,x
        sta     L2168
        sta     RAMRDOFF
        sta     RAMWRTON
        ldy     #$00
L2352:  lda     ($06),y
        sta     ($08),y
        iny
        bne     L2352
        inc     $07
        inc     $09
        lda     $07
        cmp     L2168
        bne     L2352
        sta     RAMWRTOFF
        rts

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
        pha
        lda     BUTN0
        and     BUTN1
        bpl     L2410
        lda     KBD
        cmp     #$D0
        beq     L2414
L2410:  pla
        jmp     L7ECA

L2414:  sta     KBDSTRB
        sta     SET80COL
        sta     SET80VID
        sta     DHIRESON
        lda     TXTCLR
        lda     HIRES
        sta     ALTZPOFF
        sta     ROMIN2
        lda     #$00
        sta     $03C5
        jmp     L035F

        ldy     #$00
        lda     $03CF,y
        beq     L2442
        jsr     L03C1
        iny
        jmp     L02B6

L2442:  rts

        ldy     #$00
        lda     $03DE,y
        beq     L2451
        jsr     L03C1
        iny
        jmp     L02C5

L2451:  rts

        ldx     #$00
L2454:  lda     $02E0,x
        jsr     L03C1
        inx
        cpx     #$06
        bne     L2454
        rts

        .byte   $1B
        rmb4    $30
        and     $36,x
        bmi     L2487
        cmp     ($02)
        ldy     #$00
        sty     $03CC
        lda     #$01
        sta     $03C9
        lda     #$00
        sta     $03C6
        sta     $03C7
L247B:  lda     #$08
        sta     $03CB
        lda     $03C5
        sta     $03C8
L2486:  .byte   $AD
L2487:  iny
        .byte   $03
        jsr     L0393
        lda     $03CC
        lsr     a
        tay
        sta     LOWSCR
        bcs     L2499
        sta     HISCR
L2499:  lda     ($06),y
        and     $03C9
        cmp     #$01
        ror     $03CA
        inc     $03C8
        dec     $03CB
        bne     L2486
        lda     $03CA
        eor     #$FF
        sta     LOWSCR
        jsr     L03C1
        lda     $03C6
        cmp     #$2F
        bne     L24C4
        lda     $03C7
        cmp     #$02
        beq     L24DB
L24C4:  asl     $03C9
        bpl     L24D1
        lda     #$01
        sta     $03C9
        inc     $03CC
L24D1:  inc     $03C6
        bne     L247B
        inc     $03C7
        bne     L247B
L24DB:  sta     LOWSCR
        rts

        jsr     L03B3
        jsr     L02B4
L24E5:  jsr     L02E6
        lda     #$0D
        jsr     L03C1
        lda     #$0A
        jsr     L03C1
        lda     $03C8
        sta     $03C5
        cmp     #$C0
        bcc     L24E5
        lda     #$0D
        jsr     L03C1
        lda     #$0D
        jsr     L03C1
        jsr     L02C3
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts

        pha
        and     #$C7
        eor     #$08
        sta     $07
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        sta     $06
        pla
        and     #$38
        asl     a
        asl     a
        eor     $06
        asl     a
        rol     $07
        asl     a
        rol     $07
        eor     $06
        sta     $06
        rts

        lda     #$C1
        sta     $37
        lda     #$00
        sta     $36
        lda     #$8D
        jsr     L03E5
        rts

        jsr     COUT
        rts

        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$1B,$65,$1B,$54,$31,$36
        .byte   $09,$4C,$20,$44,$8D,$09,$5A,$8D
        .byte   $00,$1B,$4E,$1B,$54,$32,$34,$00
        .byte   $4C,$00,$C1,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00
