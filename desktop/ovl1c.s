; da65 V2.16 - Git f5e9b401
; Created:    2018-02-22 08:22:52
; Input file: orig/ovl1c
; Page:       1


        .setcpu "6502"

L0006           := $0006
MGTK            := $4000
UNKNOWN_CALL    := $8E00
MLI             := $BF00
RAMRDOFF        := $C002
RAMRDON         := $C003
RAMWRTOFF       := $C004
RAMWRTON        := $C005
ALTZPOFF        := $C008
ALTZPON         := $C009
LCBANK1         := $C08B
AUXMOVE         := $C311
XFER            := $C314
MGTK_RELAY      := $D000
DESKTOP_RELAY   := $D040
LDAEE           := $DAEE
LDB55           := $DB55
LDBE0           := $DBE0
LDE9F           := $DE9F
LDF94           := $DF94
LE0FE           := $E0FE
LE137           := $E137
LE6AB           := $E6AB
LE6FD           := $E6FD
LE766           := $E766
FSUB            := $E7A7
LE7A8           := $E7A8
FADD            := $E7BE
FMULT           := $E97F
FDIV            := $EA66
ROUND           := $EB2B
FLOAT           := $EB93
FIN             := $EC4A
FOUT            := $ED34
INIT            := $FB2F
BELL1           := $FBDD
HOME            := $FC58
COUT            := $FDED
SETKBD          := $FE89
SETVID          := $FE93
L0800:  php
        sei
        jsr     L083A
        plp
        cmp     #$00
        bne     L080C
        clc
        rts

L080C:  cmp     #$02
        bne     L0815
        lda     #$2B
        jmp     L0821

L0815:  cmp     #$01
        bne     L081E
        lda     #$27
        jmp     L0821

L081E:  clc
        adc     #$30
L0821:  sec
        rts

L0823:  asl     a
        asl     L0C24
        sta     L0C36
        txa
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tay
        lda     L0C36
        jsr     L09C6
        lsr     L0C24
        rts

L083A:  tax
        and     #$70
        sta     L0C23
        txa
        ldx     L0C23
        rol     a
        lda     #$00
        rol     a
        bne     L0850
        lda     $C08A,x
        jmp     L0853

L0850:  lda     LCBANK1,x
L0853:  lda     $C089,x
        lda     #$D7
        sta     $DA
        lda     #$50
        sta     L0C24
        lda     #$00
        jsr     L0823
L0864:  lda     $DA
        beq     L086E
        jsr     L0B3A
        jmp     L0864

L086E:  lda     #$01
        sta     $D3
        lda     #$AA
        sta     $D0
        lda     L0C20
        clc
        adc     #$02
        sta     $D4
        lda     #$00
        sta     $D1
L0882:  lda     $D1
        ldx     L0C23
        jsr     L0823
        ldx     L0C23
        lda     $C08D,x
        lda     $C08E,x
        tay
        lda     $C08E,x
        lda     $C08C,x
        tya
        bpl     L08A2
        lda     #$02
        jmp     L08F9

L08A2:  jsr     L0B63
        bcc     L08B5
        lda     #$01
        ldy     $D4
        cpy     L0C1F
        bcs     L08B2
        lda     #$04
L08B2:  jmp     L08F9

L08B5:  ldy     $D4
        cpy     L0C1F
        bcs     L08C1
        lda     #$04
        jmp     L08F9

L08C1:  cpy     L0C20
        bcc     L08CB
        lda     #$03
        jmp     L08F9

L08CB:  lda     L0C22
        sta     L0C25
L08D1:  dec     L0C25
        bne     L08DB
        lda     #$01
        jmp     L08F9

L08DB:  ldx     L0C23
        jsr     L096A
        bcs     L08D1
        lda     $D8
        bne     L08D1
        ldx     L0C23
        jsr     L0907
        bcs     L08D1
        inc     $D1
        lda     $D1
        cmp     #$23
        bcc     L0882
        lda     #$00
L08F9:  pha
        ldx     L0C23
        lda     $C088,x
        lda     #$00
        jsr     L0823
        pla
        rts

L0907:  ldy     #$20
L0909:  dey
        beq     L0968
L090C:  lda     $C08C,x
        bpl     L090C
L0911:  eor     #$D5
        bne     L0909
        nop
L0916:  lda     $C08C,x
        bpl     L0916
        cmp     #$AA
        bne     L0911
        ldy     #$56
L0921:  lda     $C08C,x
        bpl     L0921
        cmp     #$AD
        bne     L0911
        lda     #$00
L092C:  dey
        sty     $D5
L092F:  lda     $C08C,x
        bpl     L092F
        cmp     #$96
        bne     L0968
        ldy     $D5
        bne     L092C
L093C:  sty     $D5
L093E:  lda     $C08C,x
        bpl     L093E
        cmp     #$96
        bne     L0968
        ldy     $D5
        iny
        bne     L093C
L094C:  lda     $C08C,x
        bpl     L094C
        cmp     #$96
        bne     L0968
L0955:  lda     $C08C,x
        bpl     L0955
        cmp     #$DE
        bne     L0968
        nop
L095F:  lda     $C08C,x
        bpl     L095F
        cmp     #$AA
        beq     L09C4
L0968:  sec
        rts

L096A:  ldy     #$FC
        sty     $DC
L096E:  iny
        bne     L0975
        inc     $DC
        beq     L0968
L0975:  lda     $C08C,x
        bpl     L0975
L097A:  cmp     #$D5
        bne     L096E
        nop
L097F:  lda     $C08C,x
        bpl     L097F
        cmp     #$AA
        bne     L097A
        ldy     #$03
L098A:  lda     $C08C,x
        bpl     L098A
        cmp     #$96
        bne     L097A
        lda     #$00
L0995:  sta     $DB
L0997:  lda     $C08C,x
        bpl     L0997
        rol     a
        sta     $DD
L099F:  lda     $C08C,x
        bpl     L099F
        and     $DD
        sta     $D7,y
        eor     $DB
        dey
        bpl     L0995
        tay
        bne     L0968
L09B1:  lda     $C08C,x
        bpl     L09B1
        cmp     #$DE
        bne     L0968
        nop
L09BB:  lda     $C08C,x
        bpl     L09BB
        cmp     #$AA
        bne     L0968
L09C4:  clc
        rts

L09C6:  stx     L0C37
        sta     L0C36
        cmp     L0C24
        beq     L0A2D
        lda     #$00
        sta     L0C38
L09D6:  lda     L0C24
        sta     L0C39
        sec
        sbc     L0C36
        beq     L0A19
        bcs     L09EB
        eor     #$FF
        inc     L0C24
        bcc     L09F0
L09EB:  adc     #$FE
        dec     L0C24
L09F0:  cmp     L0C38
        bcc     L09F8
        lda     L0C38
L09F8:  cmp     #$0C
        bcs     L09FD
        tay
L09FD:  sec
        jsr     L0A1D
        lda     L0B4B,y
        jsr     L0B3A
        lda     L0C39
        clc
        .byte   $20
L0A0C:  jsr     $B90A
        .byte   $57
        .byte   $0B
        jsr     L0B3A
        inc     L0C38
        bne     L09D6
L0A19:  jsr     L0B3A
        clc
L0A1D:  lda     L0C24
L0A20:  and     #$03
        rol     a
        ora     L0C37
        tax
        lda     $C080,x
        ldx     L0C37
L0A2D:  rts

L0A2E:  jsr     L0C0E
        lda     $C08D,x
        lda     $C08E,x
        lda     #$FF
        sta     $C08F,x
        cmp     $C08C,x
        pha
        pla
        nop
        ldy     #$04
L0A44:  pha
        pla
        jsr     L0AA5
        dey
        bne     L0A44
        lda     #$D5
        jsr     L0AA4
        lda     #$AA
        jsr     L0AA4
        lda     #$AD
        jsr     L0AA4
        ldy     #$56
        nop
        nop
        nop
        bne     L0A65
L0A62:  jsr     L0C0E
L0A65:  nop
        nop
        lda     #$96
        sta     $C08D,x
        cmp     $C08C,x
        dey
        bne     L0A62
        bit     $00
        nop
L0A75:  jsr     L0C0E
        lda     #$96
        sta     $C08D,x
        cmp     $C08C,x
        lda     #$96
        nop
        iny
        bne     L0A75
        jsr     L0AA4
        lda     #$DE
        jsr     L0AA4
        lda     #$AA
        jsr     L0AA4
        lda     #$EB
        jsr     L0AA4
        lda     #$FF
        jsr     L0AA4
        lda     $C08E,x
        lda     $C08C,x
        rts

L0AA4:  nop
L0AA5:  pha
        pla
        sta     $C08D,x
        cmp     $C08C,x
        rts

L0AAE:  sec
        lda     $C08D,x
        lda     $C08E,x
        bmi     L0B15
        lda     #$FF
        sta     $C08F,x
        cmp     $C08C,x
        pha
        pla
L0AC1:  jsr     L0B1B
        jsr     L0B1B
        sta     $C08D,x
        cmp     $C08C,x
        nop
        dey
        bne     L0AC1
        lda     #$D5
        jsr     L0B2D
        lda     #$AA
        jsr     L0B2D
        lda     #$96
        jsr     L0B2D
        lda     $D3
        jsr     L0B1C
        lda     $D1
        jsr     L0B1C
        lda     $D2
        jsr     L0B1C
        lda     $D3
        eor     $D1
        eor     $D2
        pha
        lsr     a
        ora     $D0
        sta     $C08D,x
        lda     $C08C,x
        pla
        ora     #$AA
        jsr     L0B2C
        lda     #$DE
        jsr     L0B2D
        lda     #$AA
        jsr     L0B2D
        lda     #$EB
        jsr     L0B2D
        clc
L0B15:  lda     $C08E,x
        lda     $C08C,x
L0B1B:  rts

L0B1C:  pha
        lsr     a
        ora     $D0
        sta     $C08D,x
        cmp     $C08C,x
        pla
        nop
        nop
        nop
        ora     #$AA
L0B2C:  nop
L0B2D:  nop
        pha
        pla
        sta     $C08D,x
        cmp     $C08C,x
        rts

        brk
        brk
        brk
L0B3A:  ldx     #$11
L0B3C:  dex
        bne     L0B3C
        inc     $D9
        bne     L0B45
        inc     $DA
L0B45:  sec
        sbc     #$01
        bne     L0B3A
        rts

L0B4B:  ora     ($30,x)
        plp
        bit     $20
        asl     $1C1D,x
        .byte   $1C
        .byte   $1C
        .byte   $1C
        .byte   $1C
L0B57:  bvs     L0B85
        rol     $22
        .byte   $1F
        asl     $1C1D,x
        .byte   $1C
        .byte   $1C
        .byte   $1C
        .byte   $1C
L0B63:  lda     L0C21
        sta     $D6
L0B68:  ldy     #$80
        lda     #$00
        sta     $D2
        jmp     L0B73

L0B71:  ldy     $D4
L0B73:  ldx     L0C23
        jsr     L0AAE
        bcc     L0B7E
        jmp     L0C0E

L0B7E:  ldx     L0C23
        jsr     L0A2E
        .byte   $E6
L0B85:  .byte   $D2
        lda     $D2
        cmp     #$10
        bcc     L0B71
        ldy     #$0F
        sty     $D2
        lda     L0C22
        sta     L0C25
L0B96:  sta     L0C26,y
        dey
        bpl     L0B96
        lda     $D4
        sec
        sbc     #$05
        tay
L0BA2:  jsr     L0C0E
        jsr     L0C0E
        pha
        pla
        nop
        nop
        dey
        bne     L0BA2
        ldx     L0C23
        jsr     L096A
        bcs     L0BF3
        lda     $D8
        beq     L0BCE
        dec     $D4
        lda     $D4
        cmp     L0C1F
        bcs     L0BF3
        sec
        rts

L0BC6:  ldx     L0C23
        jsr     L096A
        bcs     L0BE8
L0BCE:  ldx     L0C23
        jsr     L0907
        bcs     L0BE8
        ldy     $D8
        lda     L0C26,y
        bmi     L0BE8
        lda     #$FF
        sta     L0C26,y
        dec     $D2
        bpl     L0BC6
        clc
        rts

L0BE8:  dec     L0C25
        bne     L0BC6
        dec     $D6
        bne     L0BF3
        sec
        rts

L0BF3:  lda     L0C22
        asl     a
        sta     L0C25
L0BFA:  ldx     L0C23
        jsr     L096A
        bcs     L0C08
        lda     $D8
        cmp     #$0F
        beq     L0C0F
L0C08:  dec     L0C25
        bne     L0BFA
        sec
L0C0E:  rts

L0C0F:  ldx     #$D6
L0C11:  jsr     L0C0E
        jsr     L0C0E
        bit     $00
        dex
        bne     L0C11
        jmp     L0B68

L0C1F:  .byte   $0E
L0C20:  .byte   $1B
L0C21:  .byte   $03
L0C22:  .byte   $10
L0C23:  brk
L0C24:  brk
L0C25:  brk
L0C26:  brk
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
L0C36:  brk
L0C37:  brk
L0C38:  brk
L0C39:  brk
        .byte   $04
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $02
        brk
        brk
        .byte   $13
        .byte   $02
        brk
        eor     #$0C
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
        .byte   $03
L0C5A:  brk
L0C5B:  brk
L0C5C:  .byte   $1C
L0C5D:  brk
L0C5E:  brk
L0C5F:  sty     L0C73
        sta     L0C74
        stx     L0C75
        php
        sei
        sta     ALTZPOFF
        lda     $C082
        jsr     MLI
L0C73:  brk
L0C74:  brk
L0C75:  brk
        tax
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        plp
        txa
        rts

        rts

        jsr     LDF94
        sta     ALTZPOFF
        lda     $C082
        sta     $C05F
        sta     $C050
        sta     $C00C
        sta     $C00F
        sta     $C000
        jsr     SETVID
        jsr     SETKBD
        jsr     INIT
        jsr     HOME
        jsr     MLI
        adc     $3A
        .byte   $0C
        rts

        ldx     $D418
        lda     $D3F7,x
        sta     L0CEC
        and     #$0F
        beq     L0CCC
        lda     $D3F7,x
        jsr     L0D26
        ldy     #$FF
        lda     (L0006),y
        beq     L0CCC
        cmp     #$FF
        bne     L0CD3
L0CCC:  lda     L0CEC
        jsr     L0800
        rts

L0CD3:  lda     L0CEC
        jsr     L0D26
        ldy     #$FF
        lda     (L0006),y
        sta     L0006
        lda     #$03
        sta     $42
        lda     L0CEC
        sta     $43
        jmp     (L0006)

        rts

L0CEC:  brk
        sta     L0D24
        jsr     L0D26
        ldy     #$07
        lda     (L0006),y
        bne     L0D19
        ldy     #$FB
        lda     (L0006),y
        and     #$7F
        bne     L0D19
        ldy     #$FF
        lda     (L0006),y
        clc
        adc     #$03
        sta     L0006
        lda     L0D24
        jsr     L0D51
        sta     L0D1E
        jsr     L0D1A
        .byte   $04
        .byte   $1D
        .byte   $0D
L0D19:  rts

L0D1A:  jmp     (L0006)

        .byte   $03
L0D1E:  brk
        .byte   $22
        ora     a:$04
        brk
L0D24:  brk
        brk
L0D26:  sta     L0D50
        ldx     #$11
        lda     L0D50
        and     #$80
        beq     L0D34
        ldx     #$21
L0D34:  stx     L0D47
        lda     L0D50
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     L0D47
        sta     L0D47
        .byte   $AD
L0D47:  brk
        .byte   $BF
        sta     $07
        lda     #$00
        sta     L0006
        rts

L0D50:  brk
L0D51:  pha
        rol     a
        pla
        php
        and     #$20
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        plp
        adc     #$01
        rts

        ldx     $D417
        lda     $D3F7,x
        sta     L0C5A
        lda     #$00
        sta     L0C5D
        sta     L0C5E
        jsr     L12AF
        bne     L0D8A
        lda     $1C01
        cmp     #$E0
        beq     L0D7F
        jmp     L0DA4

L0D7F:  lda     $1C02
        cmp     #$70
        beq     L0D90
        cmp     #$60
        beq     L0D90
L0D8A:  lda     #$81
        sta     $D44D
        rts

L0D90:  lda     #$00
        ldx     #$13
        jsr     LDE9F
        lda     #$00
        ldx     #$13
        jsr     LE0FE
        lda     #$C0
        sta     $D44D
        rts

L0DA4:  cmp     #$A5
        bne     L0D8A
        lda     $1C02
        cmp     #$27
        bne     L0D8A
        lda     #$80
        sta     $D44D
        rts

        lda     #$14
        jsr     L1133
        lda     $D417
        asl     a
        tax
        lda     $D407,x
        sta     L0EB0
        lda     $D408,x
        sta     L0EB1
        lsr     L0EB1
        ror     L0EB0
        lsr     L0EB1
        ror     L0EB0
        lsr     L0EB1
        ror     L0EB0
        lda     L0EB0
        sta     $D427
        lda     L0EB1
        sta     $D428
        bit     $D44D
        bmi     L0DF6
        lda     $D451
        bne     L0DF6
        jmp     L0E4D

L0DF6:  lda     #$FF
        clc
        adc     $D427
        sta     L0006
        lda     #$13
        adc     $D428
        sta     $07
        ldy     #$00
L0E07:  lda     #$00
        sta     (L0006),y
        dec     L0006
        lda     L0006
        cmp     #$FF
        bne     L0E15
        dec     $07
L0E15:  lda     $07
        cmp     #$14
        bne     L0E07
        lda     L0006
        cmp     #$00
        bne     L0E07
        lda     #$00
        sta     (L0006),y
        lda     $D428
        cmp     #$02
        bcs     L0E2D
        rts

L0E2D:  lda     #$14
        sta     L0006
        lda     $D428
        pha
L0E35:  inc     L0006
        inc     L0006
        pla
        sec
        sbc     #$02
        pha
        bmi     L0E46
        jsr     L0E47
        jmp     L0E35

L0E46:  pla
L0E47:  lda     L0006
        jsr     L1133
        rts

L0E4D:  lda     #$06
        sta     L0C5D
        lda     #$00
        sta     L0C5E
        ldx     $D417
        lda     $D3F7,x
        sta     L0C5A
        lda     #$00
        sta     L0C5B
        lda     #$14
        sta     L0C5C
        jsr     L12AF
        beq     L0E70
        brk
L0E70:  lda     L0EB0
        sec
        sbc     #$00
        sta     L0EB0
        lda     L0EB1
        sbc     #$02
        sta     L0EB1
        lda     L0EB1
        bpl     L0E87
        rts

L0E87:  lda     L0EB0
        bne     L0E8D
        rts

L0E8D:  lda     L0C5B
        clc
        adc     #$00
        sta     L0C5B
        lda     L0C5C
        adc     #$02
        sta     L0C5C
        inc     L0C5D
        lda     L0C5C
        jsr     L1133
        jsr     L12AF
        beq     L0EAD
        brk
L0EAD:  jmp     L0E70

L0EB0:  brk
L0EB1:  brk
        and     #$F0
        sta     L0ED6
        ldx     $BF31
L0EBA:  lda     $BF32,x
        and     #$F0
        cmp     L0ED6
        beq     L0ECA
        dex
        bpl     L0EBA
L0EC7:  lda     #$00
        rts

L0ECA:  lda     $BF32,x
        and     #$0F
        cmp     #$0B
        bne     L0EC7
        lda     #$80
        rts

L0ED6:  brk
        bit     $C010
        sta     L0FE6
        and     #$FF
        bpl     L0EFF
        lda     $D424
        sta     $D421
        lda     $D425
        sta     $D422
        lda     $D426
        sta     $D423
        ldx     $D418
        lda     $D3F7,x
        sta     L0C5A
        jmp     L0F1A

L0EFF:  lda     $D421
        sta     $D424
        lda     $D422
        sta     $D425
        lda     $D423
        sta     $D426
        ldx     $D417
        lda     $D3F7,x
        sta     L0C5A
L0F1A:  lda     #$07
        sta     $D420
        lda     #$00
        sta     $D41F
        sta     L0FE4
        sta     L0FE5
L0F2A:  lda     $C000
        cmp     #$9B
        bne     L0F37
        jsr     LE6AB
        jmp     L0F6F

L0F37:  bit     L0FE4
        bmi     L0F6C
        bit     L0FE5
        bmi     L0F69
        jsr     L107F
        bcc     L0F51
        bne     L0F4C
        cpx     #$00
        beq     L0F6C
L0F4C:  ldy     #$80
        sty     L0FE4
L0F51:  sta     L0FE7
        stx     L0FE8
        jsr     L0FE9
        bcc     L0F72
        bne     L0F62
        cpx     #$00
        beq     L0F69
L0F62:  ldy     #$80
        sty     L0FE5
        bne     L0F72
L0F69:  lda     #$80
        rts

L0F6C:  lda     #$00
        rts

L0F6F:  lda     #$01
        rts

L0F72:  sta     L0C5D
        stx     L0C5E
        ldx     L0FE8
        lda     L0FE7
        ldy     $D41F
        cpy     #$10
        bcs     L0F9A
        bit     L0FE6
        bmi     L0F92
        jsr     L1160
        bmi     L0F6F
        jmp     L0F2A

L0F92:  jsr     L11F7
        bmi     L0F6F
        jmp     L0F2A

L0F9A:  cpy     #$1D
        bcc     L0FB7
        cpy     #$20
        bcs     L0FCC
        bit     L0FE6
        bmi     L0FAF
        jsr     L1175
        bmi     L0F6F
        jmp     L0F2A

L0FAF:  jsr     L120C
        bmi     L0F6F
        jmp     L0F2A

L0FB7:  bit     L0FE6
        bmi     L0FC4
        jsr     LE766
        bmi     L0F6F
        jmp     L0F2A

L0FC4:  jsr     LE7A8
        bmi     L0F6F
        jmp     L0F2A

L0FCC:  bit     L0FE6
        bmi     L0FD9
        jsr     L11AD
        bmi     L0F6F
        jmp     L0F2A

L0FD9:  jsr     L123F
        bmi     L0FE1
        jmp     L0F2A

L0FE1:  jmp     L0F6F

L0FE4:  brk
L0FE5:  brk
L0FE6:  brk
L0FE7:  brk
L0FE8:  brk
L0FE9:  jsr     L102A
        cpy     #$00
        bne     L0FF6
        pha
        jsr     L0FFF
        pla
        rts

L0FF6:  jsr     L0FFF
        bcc     L0FE9
        lda     #$00
        tax
        rts

L0FFF:  dec     $D423
        lda     $D423
        cmp     #$FF
        beq     L100B
L1009:  clc
        rts

L100B:  lda     #$07
        sta     $D423
        inc     $D421
        bne     L1018
        inc     $D422
L1018:  lda     $D422
        cmp     $D428
        bne     L1009
        lda     $D421
        cmp     $D427
        bne     L1009
        sec
        rts

L102A:  lda     #$00
        clc
        adc     $D421
        sta     L0006
        lda     #$14
        adc     $D422
        sta     $07
        ldy     #$00
        lda     (L0006),y
        ldx     $D423
        cpx     #$00
        beq     L1048
L1044:  lsr     a
        dex
        bne     L1044
L1048:  and     #$01
        bne     L104F
        tay
        beq     L1051
L104F:  ldy     #$FF
L1051:  lda     $D422
        sta     L1076
        lda     $D421
        asl     a
        rol     L1076
        asl     a
        rol     L1076
        asl     a
        rol     L1076
        ldx     $D423
        clc
        adc     L1077,x
        pha
        lda     L1076
        adc     #$00
        tax
        pla
        rts

L1076:  brk
L1077:  .byte   $07
        asl     $05
        .byte   $04
        .byte   $03
        .byte   $02
        ora     ($00,x)
L107F:  jsr     L10B2
        cpy     #$00
        beq     L108C
        pha
        jsr     L1095
        pla
        rts

L108C:  jsr     L1095
        bcc     L107F
        lda     #$00
        tax
        rts

L1095:  dec     $D420
        lda     $D420
        cmp     #$FF
        beq     L10A1
L109F:  clc
        rts

L10A1:  lda     #$07
        sta     $D420
        inc     $D41F
        lda     $D41F
        cmp     #$21
        bcc     L109F
        sec
        rts

L10B2:  ldx     $D41F
        lda     L12B9,x
        ldx     $D420
        cpx     #$00
        beq     L10C3
L10BF:  lsr     a
        dex
        bne     L10BF
L10C3:  and     #$01
        bne     L10CB
        ldy     #$00
        beq     L10CD
L10CB:  ldy     #$FF
L10CD:  lda     $D41F
        cmp     #$10
        bcs     L10E3
L10D4:  asl     a
        asl     a
        asl     a
        asl     a
        ldx     $D420
        clc
        adc     L10F3,x
        tax
        lda     #$00
        rts

L10E3:  cmp     #$20
        bcs     L10ED
        sec
        sbc     #$10
        jmp     L10D4

L10ED:  sec
        sbc     #$13
        jmp     L10D4

L10F3:  asl     L0A0C
        php
        asl     $04
        .byte   $02
        brk
        lda     #$14
        sta     L0006
        lda     #$00
        sta     L111E
L1104:  lda     L0006
        jsr     L111F
        inc     L0006
        inc     L0006
        inc     L111E
        inc     L111E
        lda     L111E
        cmp     $D428
        beq     L1104
        bcc     L1104
        rts

L111E:  brk
L111F:  jsr     L1149
        tay
        sec
        cpx     #$00
        beq     L112C
L1128:  asl     a
        dex
        bne     L1128
L112C:  ora     L12B9,y
        sta     L12B9,y
        rts

L1133:  jsr     L1149
        tay
        sec
        cpx     #$00
        beq     L1140
L113C:  asl     a
        dex
        bne     L113C
L1140:  eor     #$FF
        and     L12B9,y
        sta     L12B9,y
        rts

L1149:  pha
        and     #$0F
        lsr     a
        tax
        lda     L1158,x
        tax
        pla
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        rts

L1158:  .byte   $07
        asl     $05
        .byte   $04
        .byte   $03
        .byte   $02
        ora     ($00,x)
L1160:  sta     L0C5B
        stx     L0C5C
L1166:  jsr     L12AF
        beq     L1174
        ldx     #$00
        jsr     LE6FD
        bmi     L1174
        bne     L1166
L1174:  rts

L1175:  sta     L0006
        sta     $08
        stx     $07
        stx     $09
        inc     $09
        lda     #$00
        sta     L0C5B
        lda     #$1C
        sta     L0C5C
L1189:  jsr     L12AF
        beq     L119A
        ldx     #$00
        jsr     LE6FD
        beq     L119A
        bpl     L1189
        lda     #$80
        rts

L119A:  ldy     #$FF
        iny
L119D:  lda     $1C00,y
        sta     (L0006),y
        lda     $1D00,y
        sta     ($08),y
        iny
        bne     L119D
        lda     #$00
        rts

L11AD:  sta     L0006
        sta     $08
        stx     $07
        stx     $09
        inc     $09
        lda     #$00
        sta     L0C5B
        lda     #$1C
        sta     L0C5C
L11C1:  jsr     L12AF
        beq     L11D8
        ldx     #$00
        jsr     LE6FD
        beq     L11D8
        bpl     L11C1
        lda     LCBANK1
        lda     LCBANK1
        lda     #$80
        rts

L11D8:  lda     $C083
        lda     $C083
        ldy     #$FF
        iny
L11E1:  lda     $1C00,y
        sta     (L0006),y
        lda     $1D00,y
        sta     ($08),y
        iny
        bne     L11E1
        lda     LCBANK1
        lda     LCBANK1
        lda     #$00
        rts

L11F7:  sta     L0C5B
        stx     L0C5C
L11FD:  jsr     L12A5
        beq     L120B
        ldx     #$80
        jsr     LE6FD
        beq     L120B
        bpl     L11FD
L120B:  rts

L120C:  sta     L0006
        sta     $08
        stx     $07
        stx     $09
        inc     $09
        lda     #$00
        sta     L0C5B
        lda     #$1C
        sta     L0C5C
        ldy     #$FF
        iny
L1223:  lda     (L0006),y
        sta     $1C00,y
        lda     ($08),y
        sta     $1D00,y
        iny
        bne     L1223
L1230:  jsr     L12A5
        beq     L123E
        ldx     #$80
        jsr     LE6FD
        beq     L123E
        bpl     L1230
L123E:  rts

L123F:  bit     $C083
        bit     $C083
        sta     L0006
        sta     $08
        stx     $07
        stx     $09
        inc     $09
        lda     #$00
        sta     L0C5B
        lda     #$1C
        sta     L0C5C
        ldy     #$FF
        iny
L125C:  lda     (L0006),y
        sta     $1C00,y
        lda     ($08),y
        sta     $1D00,y
        iny
        bne     L125C
        lda     LCBANK1
        lda     LCBANK1
L126F:  jsr     L12A5
        beq     L127D
        ldx     #$80
        jsr     LE6FD
        beq     L127D
        bpl     L126F
L127D:  rts

        sta     ALTZPOFF
        sta     $C082
        jsr     BELL1
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts

        ldy     #$C5
        lda     #$41
        ldx     #$0C
        jsr     L0C5F
        rts

        ldy     #$C5
        lda     #$45
        ldx     #$0C
        jsr     L0C5F
        rts

L12A5:  ldy     #$81
        lda     #$59
        ldx     #$0C
        jsr     L0C5F
        rts

L12AF:  ldy     #$80
        lda     #$59
        ldx     #$0C
        jsr     L0C5F
        rts

L12B9:  brk
        .byte   $3C
        brk
        brk
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        inc     a:$00,x
        brk
        brk
        .byte   $0F
        .byte   $FF
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $FF
        .byte   $FF
        .byte   $FF
        brk
        brk
        brk
        .byte   $7F
        .byte   $FF
        lda     $D133
        cmp     $D18D
        bne     L12E5
        jmp     LDAEE

L12E5:  cmp     $D1C7
        bne     L12ED
        jmp     LDB55

L12ED:  rts

        lda     $D18D
        sta     $D12D
        jsr     LE137
        ldy     #$46
        lda     #$2D
        ldx     #$D1
        jsr     LDBE0
