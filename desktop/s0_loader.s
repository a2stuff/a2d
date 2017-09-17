.org $2000
; da65 V2.16 - Git f5e9b401
; Created:    2017-09-17 11:30:59
; Input file: orig/DESKTOP2_s0_loader
; Page:       1


        .setcpu "65C02"

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
L0A8D           := $0A8D
L1031           := $1031
L1039           := $1039
L103B           := $103B
L1044           := $1044
L10F4           := $10F4
L1129           := $1129
L118B           := $118B
L148D           := $148D
L3000           := $3000
A2D             := $4000
L616F           := $616F
L6544           := $6544
L6552           := $6552
L6964           := $6964
L6E61           := $6E61
L7808           := $7808
L7ECA           := $7ECA
L8D44           := $8D44
UNKNOWN_CALL    := $8E00
MLI             := $BF00
RAMRDOFF        := $C002
RAMRDON         := $C003
RAMWRTOFF       := $C004
RAMWRTON        := $C005
ALTZPOFF        := $C008
ALTZPON         := $C009
LCBANK1         := $C08B
LC100           := $C100
LC300           := $C300
AUXMOVE         := $C311
XFER            := $C314
FSUB            := $E7A7
FADD            := $E7BE
FMULT           := $E97F
FDIV            := $EA66
ROUND           := $EB2B
FLOAT           := $EB93
FIN             := $EC4A
FOUT            := $ED34
LFC22           := $FC22
LFC58           := $FC58
COUT            := $FDED
LFE89           := $FE89
LFE93           := $FE93
LFF69           := $FF69
L2000:  lda     $C083
L2003:  lda     $C083
        ldy     #$00
L2008:  .byte   $B9
L2009:  rmb2    $20
L200B:  .byte   $99
L200C:  brk
L200D:  .byte   $D1
L200E:  lda     L2127,y
L2011:  .byte   $99
        brk
L2013:  cmp     ($88)
        bne     L2008
        lda     $C082
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

        brk
        eor     $756F
L202E:  .byte   $73
        adc     $20
        .byte   $44
        adc     $73
        .byte   $6B
        brk
        clc
        .byte   $4C
        .byte   $6F
L2039:  .byte   $61
L203A:  stz     $69
        ror     L2067
        eor     ($70,x)
        bvs     L20AF
        adc     $20
L2045:  eor     #$49
        jsr     L6544
        .byte   $73
L204B:  .byte   $6B
L204C:  .byte   $54
        bbr6    $70,L2058
        .byte   $44
        adc     $73
        .byte   $6B
        .byte   $54
        bbr6    $70,L208A
L2058:  tsb     $00
        brk
        asl     $0400,x
        brk
        brk
        ora     ($00,x)
        ora     ($90,x)
        ora     ($03),y
        plp
L2067:  bpl     L2069
L2069:  inc     a
        brk
        lda     $C082
        jsr     LFE93
        jsr     LFE89
        sta     $C00C
        sta     $C00F
        sta     $C000
        jsr     LC300
L2080:  jsr     LFC58
        lda     #$00
L2085:  sta     $C035
        lda     #$40
L208A:  sta     RAMWRTON
        sta     $0100
        sta     $0101
        sta     RAMWRTOFF
        lda     #$0C
        sta     $25
        jsr     LFC22
        lda     #$50
        sec
        sbc     $100F
        lsr     a
        sta     $24
        ldy     #$00
        lda     $1010,y
        ora     #$80
        .byte   $20
        .byte   $ED
L20AF:  sbc     $CCC8,x
        bbr0    $10,L2085
        sbc     ($20)
        brk
        bbs3    $CC,L20F4
        .byte   $10
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
        .byte   $AD
        .byte   $83
L20F4:  cpy     #$AD
        .byte   $83
        cpy     #$A0
        brk
L20FA:  lda     $1000,y
        sta     $D100,y
        lda     $1100,y
        sta     $D200,y
        dey
        bne     L20FA
        lda     $C082
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

        jsr     LC300
        jsr     LFC58
        lda     #$0C
        sta     $25
        jsr     LFC22
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
L2176:  sta     $C010
L2179:  lda     $C000
        bpl     L2179
        and     #$7F
        cmp     #$0D
        bne     L2176
        jmp     L1044

        plp
        eor     #$6E
        .byte   $73
        adc     $72
        stz     $20,x
        stz     $68,x
        adc     $20
        .byte   $73
        adc     $7473,y
        adc     $6D
        jsr     L6964
        .byte   $73
        .byte   $6B
        jsr     L6E61
        stz     $20
        bvc     L2217
        adc     $73
        .byte   $73
        jsr     L6552
        stz     $75,x
        adc     ($6E)
        rol     a:$00
        sta     $06
        jmp     LFF69

        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        jmp     L204C

        .byte   $03
        clc
        jsr     L3000
        brk
        tsb     $00
        brk
        brk
        brk
        brk
        brk
        brk
        ora     ($00,x)
        .byte   $02
        brk
        bra     L221C
L2217:  brk
        php
        .byte   $44
        adc     $73
L221C:  .byte   $6B
        .byte   $54
        bbr6    $70,L2253
        brk
        bbr3    $00,L2265
        brk
        rti

        brk
        rti

        brk
        php
        bcc     L222F
        brk
        rti

L222F:  brk
        bne     L2232
L2232:  .byte   $FB
        brk
        rti

        brk
        php
        bcc     L223B
        brk
        .byte   $80
L223B:  brk
        ora     $0500,x
        brk
        bbr7    $00,L224B
        rts

        ora     ($01,x)
        .byte   $02
        .byte   $02
        brk
        brk
        brk
L224B:  asl     $A2
        rmb1    $A9
        brk
L2250:  sta     $BF59,x
L2253:  dex
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
L2264:  .byte   $AD
L2265:  php
        jsr     L148D
        jsr     L0A8D
        jsr     L7808
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
        lda     $C082
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

        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        pha
        lda     $C061
        and     $C062
        bpl     L2410
        lda     $C000
        cmp     #$D0
        beq     L2414
L2410:  pla
        jmp     L7ECA

L2414:  sta     $C010
        sta     $C001
        sta     $C00D
        sta     $C05E
        lda     $C050
        lda     $C057
        sta     ALTZPOFF
        sta     $C082
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
        sta     $C054
        bcs     L2499
        sta     $C055
L2499:  lda     ($06),y
        and     $03C9
        cmp     #$01
        ror     $03CA
        inc     $03C8
        dec     $03CB
        bne     L2486
        lda     $03CA
        eor     #$FF
        sta     $C054
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
L24DB:  sta     $C054
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

        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $1B
        adc     $1B
        .byte   $54
        and     ($36),y
        ora     #$4C
        jsr     L8D44
        ora     #$5A
        sta     $1B00
        lsr     $541B
        and     ($34)
        brk
        jmp     LC100

        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
