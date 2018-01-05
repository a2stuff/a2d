.org $800
; da65 V2.16 - Git f5e9b401
; Created:    2018-01-05 09:39:35
; Input file: orig/DESKTOP2_s5
; Page:       1


        .setcpu "6502"

L0006           := $0006
A2D             := $4000
L46BA           := $46BA
L4AFD           := $4AFD
L4B3A           := $4B3A
L6365           := $6365
L66A2           := $66A2
L670C           := $670C
L678A           := $678A
L7254           := $7254
L86A7           := $86A7
L86C1           := $86C1
L86E3           := $86E3
L879C           := $879C
L87BA           := $87BA
L87F6           := $87F6
L8813           := $8813
L89B6           := $89B6
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
A2D_RELAY       := $D000
DESKTOP_RELAY   := $D040
LD05E           := $D05E
FSUB            := $E7A7
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
LFE1F           := $FE1F
SETKBD          := $FE89
SETVID          := $FE93
        lda     #$00
        sta     L0853
        lda     $FBC0
        beq     L0815
        sec
        jsr     LFE1F
        bcs     L0815
        lda     #$80
        sta     L0853
L0815:  ldx     $FBB3
        ldy     $FBC0
        cpx     #$06
        beq     L0820
        brk
L0820:  sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        sta     $C001
        stx     $D29C
        sty     $D29D
        cpy     #$00
        beq     L084B
        bit     L0853
        bpl     L0843
        lda     #$FD
        sta     $D2AB
        jmp     L0854

L0843:  lda     #$96
        sta     $D2AB
        jmp     L0854

L084B:  lda     #$FA
        sta     $D2AB
        jmp     L0854

L0853:  brk
L0854:  sta     $C00C
        sta     $C05E
        sta     $C05F
        sta     $C05E
        sta     $C05F
        sta     $C00D
        sta     $C05E
        sta     $C0B5
        sta     $C0B7
        bit     L0853
        bpl     L087C
        lda     $C029
        ora     #$20
        sta     $C029
L087C:  ldx     $BF31
        inx
L0880:  lda     $BF31,x
        sta     $E196,x
        dex
        bpl     L0880
        ldx     $BF31
L088C:  lda     $BF32,x
        cmp     #$BF
        beq     L0898
        dex
        bpl     L088C
        bmi     L089B
L0898:  jsr     L0E35
L089B:  ldy     #$1D
        lda     #$9C
        ldx     #$D2
        jsr     A2D_RELAY
        ldy     #$30
        lda     #$72
        ldx     #$E6
        jsr     A2D_RELAY
        ldy     #$1A
        lda     #$A7
        ldx     #$D2
        jsr     A2D_RELAY
        ldy     #$24
        lda     #$11
        ldx     #$D3
        jsr     A2D_RELAY
        ldy     #$25
        lda     #$00
        ldx     #$00
        jsr     A2D_RELAY
        jsr     L87F6
        lda     #$63
        sta     L0006
        lda     #$EC
        sta     $07
        ldx     #$01
L08D5:  cpx     #$7F
        bne     L08DF
        jsr     L8813
        jmp     L0909

L08DF:  txa
        pha
        asl     a
        tax
        lda     L0006
        sta     $DD9F,x
        lda     $07
        sta     $DDA0,x
        pla
        pha
        ldy     #$00
        sta     (L0006),y
        iny
        lda     #$00
        sta     (L0006),y
        lda     L0006
        clc
        adc     #$1B
        sta     L0006
        bcc     L0903
        inc     $07
L0903:  pla
        tax
        inx
        jmp     L08D5

L0909:  sta     RAMWRTON
        lda     #$00
        tax
L090F:  sta     $1F00,x
        sta     $1E00,x
        sta     $1D00,x
        sta     $1C00,x
        sta     $1B00,x
        inx
        bne     L090F
        sta     RAMWRTOFF
        jmp     L092F

L0927:  .byte   $07
        jsr     L7254
        adc     ($73,x)
        pla
        .byte   $20
L092F:  lda     #$00
        sta     $DE9F
        lda     #$01
        sta     $DEA0
        sta     $DD9E
        jsr     LD05E
        sta     $EBFB
        sta     $DEA1
        jsr     L86E3
        sta     L0006
        stx     $07
        ldy     #$02
        lda     #$70
        sta     (L0006),y
        ldy     #$07
        lda     #$AC
        sta     (L0006),y
        iny
        lda     #$AA
        sta     (L0006),y
        iny
        ldx     #$00
L0960:  lda     L0927,x
        sta     (L0006),y
        iny
        inx
        cpx     L0927
        bne     L0960
        lda     L0927,x
        sta     (L0006),y
        lda     $BF31
        sta     L0A01
        inc     L0A01
        ldx     #$00
L097C:  lda     $BF32,x
        and     #$8F
        cmp     #$8B
        beq     L098E
        inx
        cpx     L0A01
        bne     L097C
        jmp     L09F5

L098E:  lda     $BF32,x
        stx     L09F8
        sta     L0A02
        ldx     #$11
        lda     L0A02
        and     #$80
        beq     L09A2
        ldx     #$21
L09A2:  stx     L09B5
        lda     L0A02
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     L09B5
        sta     L09B5
        .byte   $AD
L09B5:  brk
        .byte   $BF
        sta     $07
        lda     #$00
        sta     L0006
        ldy     #$07
        lda     (L0006),y
        bne     L09F5
        ldy     #$FB
        lda     (L0006),y
        and     #$7F
        bne     L09F5
        ldy     #$FF
        lda     (L0006),y
        clc
        adc     #$03
        sta     L0006
        jsr     L09F9
        brk
        .byte   $FC
        ora     #$B0
        ora     $AD,y
        .byte   $1F
        cmp     #$02
        bcs     L09F5
        ldx     L09F8
L09E6:  lda     $BF33,x
        sta     $BF32,x
        inx
        cpx     L0A01
        bne     L09E6
        dec     $BF31
L09F5:  jmp     L0A03

L09F8:  brk
L09F9:  jmp     (L0006)

        .byte   $03
        brk
        brk
        .byte   $1F
        brk
L0A01:  brk
L0A02:  brk
L0A03:  ldy     #$29
        lda     #$00
        ldx     #$00
        jsr     A2D_RELAY
        ldy     #$C7
        lda     #$F1
        ldx     #$8A
        jsr     L46BA
        ldy     #$29
        lda     #$00
        ldx     #$00
        jsr     A2D_RELAY
        lda     #$00
        sta     L0A92
        jsr     L0AE7
        lda     $1400
        clc
        adc     $1401
        sta     $D343
        lda     #$00
        sta     $D344
        lda     $1400
        sta     L0A93
L0A3B:  lda     L0A92
        cmp     L0A93
        beq     L0A8F
        jsr     L0A95
        sta     L0006
        stx     $07
        lda     L0A92
        jsr     L0AA2
        sta     $08
        stx     $09
        ldy     #$00
        lda     (L0006),y
        tay
L0A59:  lda     (L0006),y
        sta     ($08),y
        dey
        bpl     L0A59
        ldy     #$0F
        lda     (L0006),y
        sta     ($08),y
        lda     L0A92
        jsr     L0ABC
        sta     L0006
        stx     $07
        lda     L0A92
        jsr     L0AAF
        sta     $08
        stx     $09
        ldy     #$00
        lda     (L0006),y
        tay
L0A7F:  lda     (L0006),y
        sta     ($08),y
        dey
        bpl     L0A7F
        inc     L0A92
        inc     $E4F2
        jmp     L0A3B

L0A8F:  jmp     L0B09

L0A92:  brk
L0A93:  brk
        brk
L0A95:  jsr     L86A7
        clc
        adc     #$02
        tay
        txa
        adc     #$14
        tax
        tya
        rts

L0AA2:  jsr     L86A7
        clc
        adc     #$1E
        tay
        txa
        adc     #$DB
        tax
        tya
        rts

L0AAF:  jsr     L86C1
        clc
        adc     #$9E
        tay
        txa
        adc     #$DB
        tax
        tya
        rts

L0ABC:  jsr     L86C1
        clc
        adc     #$82
        tay
        txa
        adc     #$15
        tax
        tya
        rts

        .byte   $03
        .byte   $CF
        asl     a
        brk
        .byte   $10
L0ACE:  brk
L0ACF:  ora     $6553
        jmp     (L6365)

        .byte   $74
        .byte   $6F
        .byte   $72
        rol     $694C
        .byte   $73
        .byte   $74
        .byte   $04
L0ADE:  brk
        brk
        .byte   $14
        brk
        .byte   $04
        brk
        brk
        ora     ($00,x)
L0AE7:  ldy     #$C8
        lda     #$C9
        ldx     #$0A
        jsr     L46BA
        lda     L0ACE
        sta     L0ADE
        ldy     #$CA
        lda     #$DD
        ldx     #$0A
        jsr     L46BA
        ldy     #$CC
        lda     #$E5
        ldx     #$0A
        jsr     L46BA
        rts

L0B09:  lda     #$DC
        ldx     #$EB
        jsr     L879C
        sta     L0BA0
        stx     L0BA1
        lda     #$B3
        ldx     #$EB
        jsr     L879C
        clc
        adc     L0BA0
        sta     $EBF3
        txa
        adc     L0BA1
        sta     $EBF4
        lda     #$C6
        ldx     #$EB
        jsr     L879C
        clc
        adc     L0BA0
        sta     $EBF5
        txa
        adc     L0BA1
        sta     $EBF6
        lda     #$D0
        ldx     #$EB
        jsr     L879C
        clc
        adc     L0BA0
        sta     $EBF7
        txa
        adc     L0BA1
        sta     $EBF8
        lda     $EBF5
        clc
        adc     $EBF7
        sta     $EBF9
        lda     $EBF6
        adc     $EBF8
        sta     $EBFA
        lda     $EBF3
        clc
        adc     #$05
        sta     $EBE3
        lda     $EBF4
        adc     #$00
        sta     $EBE4
        lda     $EBE3
        clc
        adc     $EBF5
        sta     $EBE7
        lda     $EBE4
        adc     $EBF6
        sta     $EBE8
        lda     $EBE7
        clc
        adc     #$03
        sta     $EBE7
        lda     $EBE8
        adc     #$00
        sta     $EBE8
        jmp     L0BA2

L0BA0:  brk
L0BA1:  brk
L0BA2:  ldy     #$29
        lda     #$00
        ldx     #$00
        jsr     A2D_RELAY
        ldy     #$C4
        lda     #$E5
        ldx     #$0C
        jsr     L46BA
        beq     L0BB9
        jmp     L0D0A

L0BB9:  lda     L0CE9
        cmp     #$0F
        beq     L0BC3
        jmp     L0D0A

L0BC3:  ldy     #$C8
        lda     #$D7
        ldx     #$0C
        jsr     L46BA
        lda     L0CDC
        sta     L0CDE
        sta     L0CF9
        ldy     #$CA
        lda     #$DD
        ldx     #$0C
        jsr     L46BA
        lda     #$00
        sta     L0D04
        sta     L0D05
        lda     #$01
        sta     L0D08
        lda     $1425
        and     #$7F
        sta     L0D03
        lda     #$02
        sta     $E594
        lda     $1424
        sta     L0D07
        lda     $1423
        sta     L0D06
        lda     #$2B
        sta     L0006
        lda     #$14
        sta     $07
L0C0C:  ldy     #$00
        lda     (L0006),y
        and     #$0F
        bne     L0C17
        jmp     L0C81

L0C17:  inc     L0D04
        ldy     #$10
        lda     (L0006),y
        cmp     #$F1
        beq     L0C25
        jmp     L0C81

L0C25:  inc     L0D05
        lda     #$F2
        sta     $08
        lda     #$E5
        sta     $09
        lda     #$00
        sta     L0D09
        lda     $E594
        sec
        sbc     #$02
        asl     a
        rol     L0D09
        asl     a
        rol     L0D09
        asl     a
        rol     L0D09
        asl     a
        rol     L0D09
        clc
        adc     $08
        sta     $08
        lda     L0D09
        adc     $09
        sta     $09
        ldy     #$00
        lda     (L0006),y
        and     #$0F
        sta     ($08),y
        tay
L0C60:  lda     (L0006),y
        sta     ($08),y
        dey
        bne     L0C60
        lda     $08
        ldx     $09
        jsr     L87BA
        lda     ($08),y
        tay
L0C71:  lda     ($08),y
        cmp     #$2E
        bne     L0C7B
        lda     #$20
        sta     ($08),y
L0C7B:  dey
        bne     L0C71
        inc     $E594
L0C81:  lda     L0D05
        cmp     #$08
        bcc     L0C8B
        jmp     L0CCB

L0C8B:  lda     L0D04
        cmp     L0D03
        bne     L0C96
        jmp     L0CCB

L0C96:  inc     L0D08
        lda     L0D08
        cmp     L0D07
        bne     L0CBA
        ldy     #$CA
        lda     #$DD
        ldx     #$0C
        jsr     L46BA
        lda     #$04
        sta     L0006
        lda     #$14
        sta     $07
        lda     #$00
        sta     L0D08
        jmp     L0C0C

L0CBA:  lda     L0006
        clc
        adc     L0D06
        sta     L0006
        lda     $07
        adc     #$00
        sta     $07
        jmp     L0C0C

L0CCB:  ldy     #$CC
        lda     #$F8
        ldx     #$0C
        jsr     L46BA
        jmp     L0D0A

        .byte   $03
        .byte   $FA
        .byte   $0C
        brk
        .byte   $10
L0CDC:  brk
        .byte   $04
L0CDE:  brk
        brk
        .byte   $14
        brk
        .byte   $02
        brk
        brk
        asl     a
        .byte   $FA
        .byte   $0C
        brk
L0CE9:  brk
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
        .byte   $01
L0CF9:  brk
        php
        .byte   $44
        adc     $73
        .byte   $6B
        rol     $6361
        .byte   $63
L0D03:  brk
L0D04:  brk
L0D05:  brk
L0D06:  brk
L0D07:  brk
L0D08:  brk
L0D09:  brk
L0D0A:  ldy     #$00
        sty     $599F
        sty     L0E33
L0D12:  lda     L0E33
        asl     a
        tay
        lda     $DB00,y
        sta     $08
        lda     $DB01,y
        sta     $09
        ldy     L0E33
        lda     $BF32,y
        pha
        txa
        pha
        tya
        pha
        inc     $DEA0
        inc     $DD9E
        lda     $BF32,y
        jsr     L89B6
        sta     L0E34
        ldy     #$29
        lda     #$00
        ldx     #$00
        jsr     A2D_RELAY
        pla
        tay
        pla
        tax
        pla
        pha
        lda     L0E34
        cmp     #$28
        bne     L0D64
        ldy     L0E33
        lda     $BF32,y
        and     #$0F
        beq     L0D6D
        ldx     L0E33
        jsr     L0E35
        jmp     L0E25

L0D64:  cmp     #$57
        bne     L0D6D
        lda     #$F9
        sta     $599F
L0D6D:  pla
        pha
        and     #$0F
        sta     L0E32
        cmp     #$00
        bne     L0D7F
        lda     #$DD
        ldx     #$E4
        jmp     L0DAD

L0D7F:  cmp     #$0B
        beq     L0DA9
        cmp     #$04
        bne     L0DC2
        pla
        pha
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #$C0
        sta     L0D96
        .byte   $AD
        .byte   $FB
L0D96:  .byte   $C7
        and     #$01
        bne     L0DA2
        lda     #$A0
        ldx     #$E4
        jmp     L0DAD

L0DA2:  lda     #$C8
        ldx     #$E4
        jmp     L0DAD

L0DA9:  lda     #$B4
        ldx     #$E4
L0DAD:  sta     L0006
        stx     $07
        ldy     #$00
        lda     (L0006),y
        sta     L0DBE
L0DB8:  iny
        lda     (L0006),y
        sta     ($08),y
        .byte   $C0
L0DBE:  brk
        bne     L0DB8
        tay
L0DC2:  pla
        pha
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #$30
        tax
        lda     L0E32
        cmp     #$04
        bne     L0DF0
        pla
        pha
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #$C0
        sta     L0DE3
        .byte   $AD
        .byte   $FB
L0DE3:  .byte   $C7
        and     #$01
        bne     L0DEC
        ldy     #$0E
        bne     L0DFA
L0DEC:  ldy     #$0E
        bne     L0DFA
L0DF0:  cmp     #$0B
        bne     L0DF8
        ldy     #$0F
        bne     L0DFA
L0DF8:  ldy     #$06
L0DFA:  txa
        sta     ($08),y
        lda     L0E32
        and     #$0F
        cmp     #$04
        beq     L0E21
        pla
        pha
        rol     a
        lda     #$00
        adc     #$01
        ora     #$30
        pha
        lda     L0E32
        and     #$0F
        bne     L0E1C
        ldy     #$10
        pla
        bne     L0E1F
L0E1C:  ldy     #$11
        pla
L0E1F:  sta     ($08),y
L0E21:  pla
        inc     L0E33
L0E25:  lda     L0E33
        cmp     $BF31
        beq     L0E2F
        bcs     L0E4C
L0E2F:  jmp     L0D12

L0E32:  brk
L0E33:  brk
L0E34:  brk
L0E35:  dex
L0E36:  inx
        lda     $BF33,x
        sta     $BF32,x
        lda     $E1A1,x
        sta     $E1A0,x
        cpx     $BF31
        bne     L0E36
        dec     $BF31
        rts

L0E4C:  lda     $BF31
        clc
        adc     #$03
        sta     $E270
        lda     #$00
        sta     L0EAF
        tay
        tax
L0E5C:  lda     $BF32,y
        and     #$70
        beq     L0EA8
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        cmp     L0EAF
        beq     L0E70
        cmp     #$02
        bne     L0E79
L0E70:  cpy     $BF31
        beq     L0EA8
        iny
        jmp     L0E5C

L0E79:  sta     L0EAF
        clc
        adc     #$30
        sta     L0EAE
        txa
        pha
        asl     a
        tax
        lda     L0EB0,x
        sta     L0E9A
        lda     L0EB1,x
        sta     L0E9B
        ldx     $E44C
        dex
        lda     L0EAE
        .byte   $9D
L0E9A:  .byte   $34
L0E9B:  .byte   $12
        pla
        tax
        inx
        cpy     $BF31
        beq     L0EA8
        iny
        jmp     L0E5C

L0EA8:  stx     $E2D6
        jmp     L0EE1

L0EAE:  brk
L0EAF:  brk
L0EB0:  .byte   $4C
L0EB1:  cpx     $54
        cpx     $5C
        cpx     $64
        cpx     $6C
        cpx     $74
        cpx     $7C
        cpx     $0A
        .byte   $62
        pha
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
        ora     ($62,x)
        pha
L0ED4:  .byte   $0C
        .byte   $53
        adc     $7473,y
        adc     $6D
        .byte   $2F
        .byte   $53
        .byte   $74
        adc     ($72,x)
        .byte   $74
L0EE1:  lda     #$00
        sta     $4861
        jsr     L4AFD
        cmp     #$80
        beq     L0EFE
        ldy     #$C7
        lda     #$D1
        ldx     #$0E
        jsr     L46BA
        bne     L0F34
        dec     $4862
        jmp     L0F05

L0EFE:  lda     #$62
        ldx     #$48
        jsr     L4B3A
L0F05:  ldx     $4862
L0F08:  lda     $4862,x
        cmp     #$2F
        beq     L0F12
        dex
        bne     L0F08
L0F12:  ldy     #$00
L0F14:  inx
        iny
        lda     L0ED4,y
        sta     $4862,x
        cpy     L0ED4
        bne     L0F14
        stx     $4862
        ldy     #$C4
        lda     #$BE
        ldx     #$0E
        jsr     L46BA
        bne     L0F34
        lda     #$80
        sta     $4861
L0F34:  ldy     #$29
        lda     #$00
        ldx     #$00
        jsr     A2D_RELAY
        ldy     #$30
        lda     #$44
        ldx     #$AC
        jsr     A2D_RELAY
        ldy     #$24
        lda     #$AD
        ldx     #$D2
        jsr     A2D_RELAY
        lda     #$00
        sta     $EC25
        jsr     L66A2
        jsr     L678A
        jsr     L670C
        jmp     A2D

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
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
