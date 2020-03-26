; da65 V2.17 - Git 5ac11b5e
; Created:    2020-03-25 19:03:17
; Input file: orig/selector5
; Page:       1


        .setcpu "6502"

L0000           := $0000
L0002           := $0002
L000C           := $000C
WNDLFT          := $0020                        ; Text window left
WNDWDTH         := $0021                        ; Text window width
WNDTOP          := $0022                        ; Text window top
WNDBTM          := $0023                        ; Text window bottom+1
CH              := $0024                        ; Cursor horizontal position
CV              := $0025                        ; Cursor vertical position
BASL            := $0028                        ; Text base address low
BASH            := $0029                        ; Text base address high
L0030           := $0030
INVFLG          := $0032                        ; Normal/inverse(/flash)
PROMPT          := $0033                        ; Used by GETLN
RNDL            := $004E                        ; Random counter low
RNDH            := $004F                        ; Random counter high
HIMEM           := $0073                        ; Highest available memory address+1
L0080           := $0080
L0088           := $0088
FBUFFR          := $0100
IN              := $0200
L0290           := $0290
MOUSE_X_LO      := $03B8
DOSWARM         := $03D0                        ; DOS warmstart vector
XFERSTARTLO     := $03ED
XFERSTARTHI     := $03EE
BRKVec          := $03F0                        ; Break vector
SOFTEV          := $03F2                        ; Vector for warm start
PWREDUP         := $03F4                        ; This must be = EOR #$A5 of SOFTEV+1
IRQ_VECTOR      := $03FE
L0400           := $0400
MOUSE_Y_LO      := $0438
CLAMP_MIN_LO    := $0478
MOUSE_X_HI      := $04B8
CLAMP_MAX_LO    := $04F8
MOUSE_Y_HI      := $0538
CLAMP_MIN_HI    := $0578
L05A3           := $05A3
CLAMP_MAX_HI    := $05F8
MOUSE_STATUS    := $06B8
MOUSE_MODE      := $0738
L0765           := $0765
L0D20           := $0D20
L1234           := $1234
L17D5           := $17D5
L2000           := $2000
L2020           := $2020
L202D           := $202D
L2061           := $2061
L2078           := $2078
L2120           := $2120
L2121           := $2121
L2824           := $2824
L2E2E           := $2E2E
L3028           := $3028
LA000           := $A000
LA003           := $A003
MLI             := $BF00
CLR80COL        := $C000                        ; Disable 80 column store
SET80COL        := $C001                        ; Enable 80 column store
RAMRDOFF        := $C002
RAMRDON         := $C003
RAMWRTOFF       := $C004
RAMWRTON        := $C005
ALTZPOFF        := $C008
ALTZPON         := $C009
CLR80VID        := $C00C
SET80VID        := $C00D
CLRALTCHAR      := $C00E                        ; Normal Apple II char set
SETALTCHAR      := $C00F                        ; Norm/inv LC, no flash
KBDSTRB         := $C010                        ; Clear keyboard strobe
RDLCBNK2        := $C011                        ; >127 if LC bank 2 in use
RDLCRAM         := $C012                        ; >127 if LC is read enabled
RDALTZP         := $C016
RD80COL         := $C018                        ; >127 if 80 column store enabled
RDPAGE2         := $C01C
ALTCHARSET      := $C01E                        ; >127 if alt charset switched in
RD80VID         := $C01F                        ; >127 if 80 column video enabled
NEWVIDEO        := $C029                        ; IIgs - new video modes
SPKR            := $C030
SHADOW          := $C035                        ; IIgs - inhibit shadowing
TXTCLR          := $C050                        ; Display graphics
TXTSET          := $C051                        ; Display text
MIXCLR          := $C052                        ; Disable 4 lines of text
MIXSET          := $C053                        ; Enable 4 lines of text
LOWSCR          := $C054                        ; Page 1
HISCR           := $C055                        ; Page 2
LORES           := $C056                        ; Lores graphics
HIRES           := $C057                        ; Hires graphics
DHIRESON        := $C05E
DHIRESOFF       := $C05F
BUTN0           := $C061                        ; Open-Apple Key
BUTN1           := $C062                        ; Closed-Apple Key
RAMWORKS_BANK   := $C071                        ; RAMWorks bank selection ???
ROMIN           := $C081                        ; Swap in D000-FFFF ROM
ROMIN2          := $C082
LCBANK2         := $C083                        ; Swap in LC bank 2
LCBANK1         := $C08B                        ; Swap in LC bank 1
HR1_OFF         := $C0B2
HR1_ON          := $C0B3
HR2_OFF         := $C0B4
HR2_ON          := $C0B5
HR3_OFF         := $C0B6
HR3_ON          := $C0B7
SLOT3ENTRY      := $C300
AUXMOVE         := $C311                        ; carry set main>aux, carry clear aux>main
XFER            := $C314
LD23E           := $D23E
GIVAYF          := $E2F2                        ; FAC from signed integer in (Y,A)
CONINT          := $E6FB                        ; FAC = X as unsigned byte
GETADR          := $E752                        ; FAC to unsigned integer in LINNUM
FADDH           := $E7A0                        ; Add 0.5 to FAC
FSUB            := $E7A7                        ; FAC = (Y,A) - FAC
FSUBT           := $E7AA                        ; FAC = ARG - FAC
FADD            := $E7BE                        ; FAC = (Y,A) + FAC
FADDT           := $E7C1                        ; FAC = ARG + FAC
ZERO_FAC        := $E84E                        ; FAC = 0
CON_ONE         := $E913                        ; 1
CON_SQR_HALF    := $E92D                        ; SQR(1/2)
CON_SQR_TWO     := $E932                        ; SQR(2)
CON_NEG_HALF    := $E937                        ; -1/2
CON_LOG_TWO     := $E93C                        ; LOG(2)
LOG             := $E941                        ; FAC = LOG(FAC)
CON_TEN         := $E950                        ; 10
FMULT           := $E97F                        ; FAC = (Y,A) * FAC
FMULTT          := $E982                        ; FAC = ARG * FAC
DIV10           := $EA55                        ; FAC = FAC / 10
FDIV            := $EA66                        ; FAC = (Y,A) / FAC
FDIVT           := $EA69                        ; FAC = ARG / FAC
LOAD_ARG        := $EAE3                        ; ARG = (Y,A)
LOAD_FAC        := $EAF9                        ; FAC = (Y,A)
ROUND           := $EB2B                        ; Round FAC, store at (Y,X)
ARG_TO_FAC      := $EB53                        ; ARG = FAC
FAC_TO_ARG_R    := $EB63                        ; FAC = ARG, rounded
SGN             := $EB90                        ; FAC = SGN(FAC)
FLOAT           := $EB93                        ; FAC = A as signed byte
FLOAT1          := $EB9B                        ; FAC from unsigned integer in FAC+1,2 eX
FLOAT2          := $EBA0                        ; FAC from unsigned integer in FAC+1,2 eX, carry set = positive
ABS             := $EBAF                        ; FAC = ABS(FAC)
FCOMP           := $EBB2                        ; FAC <=> (Y,A), result in A
QINT            := $EBF2                        ; FAC to signed integer in FAC+1...FAC+4 (e < 32)
INT             := $EC23                        ; FAC = INT(FAC)
FIN             := $EC4A                        ; Parse TEXTPTR to FAC (first char in A, C set if digit)
CON_BILLION     := $ED14                        ; 1E9
FOUT            := $ED34                        ; FAC as string to FBUFFR (trashes FAC)
CON_HALF        := $EE64                        ; 1/2
SQR             := $EE8D                        ; FAC = SQR(FAC)
NEGOP           := $EED0                        ; FAC = -FAC
CON_LOG2_E      := $EEDB                        ; Log(E) base 2 ????
EXP             := $EF09                        ; FAC = EXP(FAC)
RND             := $EFAE                        ; FAC = RND(FAC)
COS             := $EFEA                        ; FAC = COS(FAC)
SIN             := $EFF1                        ; FAC = SIN(FAC)
TAN             := $F03A                        ; FAC = SIN(FAC)
CON_HALF_PI     := $F063                        ; pi/2
CON_TWO_PI      := $F06B                        ; pi/*2
CON_QUARTER     := $F070                        ; 1/4
ATN             := $F09E                        ; FAC = ATN(FAC)
LF0A5           := $F0A5
INIT            := $FB2F
VERSION         := $FBB3
ID_BYTE_FBC0    := $FBC0                        ; $EA = IIe, $E0 = IIe enh/IIgs, $00 = IIc/IIc+
BELL1           := $FBDD
VTAB            := $FC22
VTABZ           := $FC24
HOME            := $FC58
PRBYTE          := $FDDA
COUT            := $FDED
ID_BYTE_FE1F    := $FE1F                        ; RTS ($60) on pre-IIgs, clears carry on IIgs
SETKBD          := $FE89
SETVID          := $FE93
MONZ            := $FF69
LFFFF           := $FFFF
MGTK:   bit     L5F0D
        bpl     L401C
        ldx     #$7F
L4007:  lda     L0080,x
        sta     L5F64,x
        dex
        bpl     L4007
        ldx     #$0B
L4011:  lda     L5F58,x
        sta     $F4,x
        dex
        bpl     L4011
        jsr     L40B7
L401C:  pla
        sta     L0080
        clc
        adc     #$03
        tax
        pla
        sta     $81
        adc     #$00
        pha
        txa
        pha
        tsx
        stx     L5F0F
        ldy     #$01
        lda     (L0080),y
        asl     a
        tax
        lda     L40DF,x
        sta     L4082
        lda     L40E0,x
L403F           := * + 1
L4040           := * + 2
        sta     L4083
        iny
        lda     (L0080),y
        pha
        iny
        lda     (L0080),y
        sta     $81
        pla
        sta     L0080
        ldy     L417A,x
        bpl     L4070
        txa
        pha
        tya
        pha
        lda     L0080
        pha
        lda     $81
        pha
        bit     L6330
        bpl     L4064
L4062           := * + 1
        jsr     L40CE
L4064:  pla
        sta     $81
        pla
        sta     L0080
        pla
        and     #$7F
        tay
        pla
        tax
L4070:  lda     L4179,x
        beq     L4081
        sta     L407C
        dey
L4079:  lda     (L0080),y
L407C           := * + 1
        sta     $FF,y
        dey
        bpl     L4079
L4081:
L4082           := * + 1
L4083           := * + 2
        jsr     LFFFF
L4084:  bit     L6330
        bpl     L408C
        jsr     L40D4
L408C:  bit     L5F0D
        bpl     L40A8
        jsr     L40C2
        ldx     #$0B
L4096:  lda     $F4,x
        sta     L5F58,x
        dex
        bpl     L4096
        ldx     #$7F
L40A0:  lda     L5F64,x
        sta     L0080,x
        dex
        bpl     L40A0
L40A8:  return  #$00

L40AB:  pha
        jsr     L4084
        pla
        ldx     L5F0F
        txs
        ldy     #$FF
L40B6:  rts

L40B7:  ldy     #$23
L40B9:  lda     ($F4),y
        sta     $D0,y
        dey
        bpl     L40B9
        rts

L40C2:  ldy     #$23
L40C4:  lda     $D0,y
        sta     ($F4),y
        dey
        bpl     L40C4
        rts

L40CD:  .byte   0
L40CE:  dec     L40CD
        jmp     L624C

L40D4:  bit     L40CD
        bpl     L40B6
        inc     L40CD
        jmp     L6225

L40DF:  tax
L40E0:  rti

        rti

        lsr     L5E6A,x
        ldx     $5E,y
        stx     $A65E
        lsr     L507E,x
        lda     ($4D,x)
        .byte   $7F
        .byte   $4F
        tax
        rti

        tax
        rti

        eor     $AA58,y
        rti

        and     ($57),y
        tax
        rti

        .byte   $52
        .byte   $57
        adc     $57
        bmi     L4153
        cmp     RNDH,x
        eor     ($50,x)
        .byte   $5A
        eor     ($6D),y
        .byte   $53
        cmp     $56
        adc     #$53
        .byte   $CB
        cli
        .byte   $27
        eor     L5EC1,y
        bne     L4175
        .byte   $FC
        lsr     L6332,x
        adc     $64,x
        ldx     #$64
        .byte   $83
        adc     $E2
        .byte   $82
        .byte   $27
        .byte   $7C
        adc     $2560
        .byte   $62
        jmp     L4062

        .byte   $62
        .byte   $FC
        .byte   $62
        .byte   $33
        ror     $A7
        adc     HIMEM
        .byte   $67
        ldy     $65
        .byte   $DF
        adc     $AF
        .byte   $67
        .byte   $04
        ror     L68BF
        .byte   $12
        .byte   $6B
        .byte   $97
        ror     a
        .byte   $54
        ror     a
        .byte   $02
        .byte   $6B
        cpx     #$6A
        cpx     L6C6A
        ror     L7341
        .byte   $DB
        ror     $FC,x
L4153           := * + 1
        ror     $C6,x
        .byte   $73
        .byte   $62
        .byte   $74
        sbc     $74
        sed
        .byte   $73
L415B:  .byte   $52
        .byte   $74
        .byte   $BF
        .byte   $72
        .byte   $FF
        .byte   $74
        .byte   $72
        .byte   $73
        bpl     L41DA
        .byte   $72
        adc     $6E,x
        adc     $BF,x
        .byte   $77
        .byte   $A7
        .byte   $77
        .byte   $87
        adc     L7A3B,y
        bvs     L41ED
        nop
        .byte   $7B
L4175:  .byte   $2B
        sei
        .byte   $A3
L4179           := * + 1
        eor     (L0000),y
L417A:  .byte   0
        .byte   0
        .byte   0
        .byte   $82
        ora     (L0000,x)
        .byte   0
        bne     L41A7
        .byte   0
        .byte   0
        bne     L4197
        beq     L418A
L418A           := * + 1
        cpx     #$08
        inx
        .byte   $02
        inc     a:L0002
        .byte   0
        sbc     ($01),y
        lda     ($04,x)
        nop
        .byte   $04
L4197:  lda     ($84,x)
        .byte   $92
        sty     $92
        dey
        .byte   $9F
        dey
        .byte   $92
        php
        txa
        bpl     L41A4
L41A4:  .byte   $80
        .byte   0
        .byte   $80
L41A7:  .byte   0
        .byte   0
        lda     ($03,x)
        lda     ($83,x)
        .byte   $82
        ora     ($82,x)
        ora     (L0000,x)
        .byte   0
        .byte   $82
        .byte   $0C
        .byte   0
        .byte   0
        .byte   $82
        .byte   $03
        .byte   $82
        .byte   $02
        .byte   $82
        .byte   $02
        .byte   $82
        ora     (L0000,x)
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $82
        ora     $82
        ora     ($82,x)
        .byte   $04
        .byte   0
        .byte   0
        .byte   0
L41DA:  .byte   0
        .byte   $C7
        .byte   $04
        .byte   $C7
        ora     ($C7,x)
        .byte   $02
        .byte   $C7
        .byte   $03
        .byte   $C7
        .byte   $03
        .byte   $C7
        .byte   $04
        .byte   0
        .byte   0
        .byte   $82
        ora     (L0000,x)
        .byte   0
L41ED:  .byte   $82
        ora     ($82,x)
        .byte   $03
        .byte   $82
        .byte   $02
        .byte   $82
        ora     ($82,x)
        ora     ($EA,x)
        .byte   $04
        .byte   0
        .byte   0
        .byte   $82
        ora     (L0000,x)
        .byte   0
        .byte   $82
        ora     $82
        ora     $82
        ora     $82
        ora     $EA
        .byte   $04
        .byte   $82
        .byte   $03
        .byte   $82
        ora     $8C
        .byte   $03
        sty     L8A02
L4213           := * + 1
        bpl     L4214
L4214:  .byte   $02
        .byte   $04
        asl     $08
        asl     a
        .byte   $0C
        asl     $1210
        .byte   $14
        asl     $18,x
        .byte   $1A
        .byte   $1C
        asl     $2220,x
        bit     $26
        plp
        rol     a
        bit     $302E
        .byte   $32
        .byte   $34
        rol     $38,x
        .byte   $3A
        .byte   $3C
        rol     L4240,x
        .byte   $44
        lsr     $48
        lsr     a
        jmp     L504E

        .byte   $52
        .byte   $54
        lsr     $58,x
L4240:  .byte   $5A
        .byte   $5C
        lsr     L6260,x
        .byte   $64
        ror     $68
        ror     a
        jmp     (L706E)

        .byte   $72
        .byte   $74
        ror     $78,x
        .byte   $7A
        .byte   $7C
        ror     IN,x
        .byte   $04
        asl     $08
        asl     a
        .byte   $0C
        asl     $1210
        .byte   $14
        asl     $18,x
        .byte   $1A
        .byte   $1C
        asl     $2220,x
        bit     $26
        plp
        rol     a
        bit     $302E
        .byte   $32
        .byte   $34
        rol     $38,x
        .byte   $3A
        .byte   $3C
        rol     L4240,x
        .byte   $44
        lsr     $48
        lsr     a
        jmp     L504E

        .byte   $52
        .byte   $54
        lsr     $58,x
        .byte   $5A
        .byte   $5C
        lsr     L6260,x
        .byte   $64
        ror     $68
        ror     a
        jmp     (L706E)

        .byte   $72
        .byte   $74
        ror     $78,x
        .byte   $7A
        .byte   $7C
L4293           := * + 1
        ror     a:L0000,x
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        .byte   0
        .byte   $04
        php
        .byte   $0C
        bpl     L432D
        clc
        .byte   $1C
        jsr     L2824
        bit     $3430
        sec
        .byte   $3C
        rti

L4324:  .byte   $44
        pha
        jmp     L5450

        cli
        .byte   $5C
        rts

        .byte   $64
L432D:  pla
        jmp     (L7470)

        sei
        .byte   $7C
        .byte   0
        .byte   $04
        php
        .byte   $0C
        bpl     L434D
        clc
        .byte   $1C
        jsr     L2824
        bit     $3430
        sec
        .byte   $3C
        rti

        .byte   $44
        pha
        jmp     L5450

        cli
        .byte   $5C
        rts

        .byte   $64
L434D:  pla
        jmp     (L7470)

        sei
        .byte   $7C
        .byte   0
        .byte   $04
        php
        .byte   $0C
        bpl     L436D
        clc
        .byte   $1C
        jsr     L2824
        bit     $3430
        sec
        .byte   $3C
        rti

        .byte   $44
        pha
        jmp     L5450

        cli
        .byte   $5C
        rts

        .byte   $64
L436D:  pla
        jmp     (L7470)

        sei
        .byte   $7C
        .byte   0
        .byte   $04
        php
        .byte   $0C
        bpl     L438D
        clc
        .byte   $1C
        jsr     L2824
        bit     $3430
        sec
        .byte   $3C
        rti

        .byte   $44
        pha
        jmp     L5450

        cli
        .byte   $5C
        rts

        .byte   $64
L438D:  pla
        jmp     (L7470)

        sei
        .byte   $7C
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   0
        php
        bpl     L442F
        jsr     L3028
        sec
        rti

        pha
        bvc     L4477
        rts

        pla
        bvs     L449B
        .byte   0
        php
        bpl     L443F
        jsr     L3028
        sec
        rti

        pha
        bvc     L4487
L442F:  rts

        pla
        bvs     L44AB
        .byte   0
        php
        bpl     L444F
        jsr     L3028
        sec
        rti

        pha
        bvc     L4497
L443F:  rts

        pla
        bvs     L44BB
        .byte   0
        php
        bpl     L445F
        jsr     L3028
        sec
        rti

        pha
        bvc     L44A7
L444F:  rts

        pla
        bvs     L44CB
        .byte   0
        php
        bpl     L446F
        jsr     L3028
        sec
        rti

        pha
        bvc     L44B7
L445F:  rts

        pla
        bvs     L44DB
        .byte   0
        php
        bpl     L447F
        jsr     L3028
        sec
        rti

        pha
        bvc     L44C7
L446F:  rts

        pla
        bvs     L44EB
        .byte   0
        php
        bpl     L448F
L4477:  jsr     L3028
        sec
        rti

        pha
        bvc     L44D7
L447F:  rts

        pla
        bvs     L44FB
        .byte   0
        php
        bpl     L449F
L4487:  jsr     L3028
        sec
        rti

        pha
        bvc     L44E7
L448F:  rts

        pla
        bvs     L450B
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L4497:  .byte   0
        .byte   0
        .byte   0
        .byte   0
L449B:  .byte   0
        .byte   0
        .byte   0
        .byte   0
L449F:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        ora     ($01,x)
        ora     ($01,x)
L44A7:  ora     ($01,x)
        ora     ($01,x)
L44AB:  ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
L44B7:  .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
L44BB:  .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
L44C7:  .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
L44CB:  .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
L44D7:  .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
L44DB:  .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
        ora     $05
        ora     $05
L44E7:  ora     $05
        ora     $05
L44EB:  ora     $05
        ora     $05
        ora     $05
        ora     $05
        asl     $06
        asl     $06
        asl     $06
        asl     $06
L44FB:  asl     $06
        asl     $06
        asl     $06
        asl     $06
        .byte   $07
        .byte   $07
        .byte   $07
        .byte   $07
        .byte   $07
        .byte   $07
        .byte   $07
        .byte   $07
L450B:  .byte   $07
        .byte   $07
        .byte   $07
        .byte   $07
        .byte   $07
        .byte   $07
        .byte   $07
        .byte   $07
        .byte   0
        bpl     L4536
        bmi     L4558
        bvc     L457A
        bvs     L451C
L451C:  bpl     L453E
        bmi     L4560
        bvc     L4582
        bvs     L4524
L4524:  bpl     L4546
        bmi     L4568
        bvc     L458A
        bvs     L452C
L452C:  bpl     L454E
        bmi     L4570
        bvc     L4592
        bvs     L4534
L4534:  bpl     L4556
L4536:  bmi     L4578
        bvc     L459A
        bvs     L453C
L453C:  bpl     L455E
L453E:  bmi     L4580
        bvc     L45A2
        bvs     L4544
L4544:  bpl     L4566
L4546:  bmi     L4588
        bvc     L45AA
        bvs     L454C
L454C:  bpl     L456E
L454E:  bmi     L4590
        bvc     L45B2
        bvs     L4554
L4554:  bpl     L4576
L4556:  bmi     L4598
L4558:  bvc     L45BA
        bvs     L455C
L455C:  bpl     L457E
L455E:  bmi     L45A0
L4560:  bvc     L45C2
        bvs     L4564
L4564:  bpl     L4586
L4566:  bmi     L45A8
L4568:  bvc     L45CA
        bvs     L456C
L456C:  bpl     L458E
L456E:  bmi     L45B0
L4570:  bvc     L45D2
        bvs     L4574
L4574:  bpl     L4596
L4576:  bmi     L45B8
L4578:  bvc     L45DA
L457A:  bvs     L457C
L457C:  bpl     L459E
L457E:  bmi     L45C0
L4580:  bvc     L45E2
L4582:  bvs     L4584
L4584:  bpl     L45A6
L4586:  bmi     L45C8
L4588:  bvc     L45EA
L458A:  bvs     L458C
L458C:  bpl     L45AE
L458E:  bmi     L45D0
L4590:  bvc     L45F2
L4592:  bvs     L4594
L4594:  .byte   0
        .byte   0
L4596:  .byte   0
        .byte   0
L4598:  .byte   0
        .byte   0
L459A:  .byte   0
        ora     ($01,x)
L459E           := * + 1
        ora     ($01,x)
L45A0           := * + 1
        ora     ($01,x)
L45A2           := * + 1
        ora     ($01,x)
        .byte   $02
        .byte   $02
        .byte   $02
L45A6:  .byte   $02
        .byte   $02
L45A8:  .byte   $02
        .byte   $02
L45AA:  .byte   $02
        .byte   $03
        .byte   $03
        .byte   $03
L45AE:  .byte   $03
        .byte   $03
L45B0:  .byte   $03
        .byte   $03
L45B2:  .byte   $03
        .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
L45B8:  .byte   $04
        .byte   $04
L45BA:  .byte   $04
        ora     $05
        ora     $05
L45C0           := * + 1
        ora     $05
L45C2           := * + 1
        ora     $05
        asl     $06
        asl     $06
L45C8           := * + 1
        asl     $06
L45CA           := * + 1
        asl     $06
        .byte   $07
        .byte   $07
        .byte   $07
        .byte   $07
        .byte   $07
L45D0:  .byte   $07
        .byte   $07
L45D2:  .byte   $07
        php
        php
        php
        php
        php
        php
        php
L45DA:  php
        ora     #$09
        ora     #$09
        ora     #$09
L45E2           := * + 1
        ora     #$09
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
L45EA:  asl     a
        .byte   $0B
        .byte   $0B
        .byte   $0B
        .byte   $0B
        .byte   $0B
        .byte   $0B
        .byte   $0B
L45F2:  .byte   $0B
        .byte   $0C
        .byte   $0C
        .byte   $0C
        .byte   $0C
        .byte   $0C
        .byte   $0C
        .byte   $0C
        .byte   $0C
        ora     $0D0D
        ora     $0D0D
        ora     $0E0D
        asl     $0E0E
        asl     $0E0E
        asl     $0F0F
        .byte   $0F
        .byte   $0F
        .byte   $0F
        .byte   $0F
        .byte   $0F
        .byte   $0F
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        jsr     L6040
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        ora     ($01,x)
        ora     ($01,x)
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $02
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
        ora     $05
        ora     $05
        asl     $06
        asl     $06
        .byte   $07
        .byte   $07
        .byte   $07
        .byte   $07
        php
        php
        php
        php
        ora     #$09
        ora     #$09
        asl     a
        asl     a
        asl     a
        asl     a
        .byte   $0B
        .byte   $0B
        .byte   $0B
        .byte   $0B
        .byte   $0C
        .byte   $0C
        .byte   $0C
        .byte   $0C
        ora     $0D0D
        ora     $0E0E
        asl     $0F0E
        .byte   $0F
        .byte   $0F
        .byte   $0F
        bpl     L46E5
        bpl     L46E7
        ora     ($11),y
        ora     ($11),y
        .byte   $12
        .byte   $12
        .byte   $12
        .byte   $12
        .byte   $13
        .byte   $13
        .byte   $13
        .byte   $13
        .byte   $14
        .byte   $14
L46E5:  .byte   $14
        .byte   $14
L46E7:  ora     $15,x
        ora     $15,x
        asl     $16,x
        asl     $16,x
        .byte   $17
        .byte   $17
        .byte   $17
        .byte   $17
        clc
        clc
        clc
        clc
        ora     $1919,y
        ora     $1A1A,y
        .byte   $1A
        .byte   $1A
        .byte   $1B
        .byte   $1B
        .byte   $1B
        .byte   $1B
        .byte   $1C
        .byte   $1C
        .byte   $1C
        .byte   $1C
        ora     $1D1D,x
        ora     $1E1E,x
        asl     $1F1E,x
        .byte   $1F
        .byte   $1F
        .byte   $1F
        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        rti

        .byte   0
        .byte   0
        ora     ($01,x)
        .byte   $02
        .byte   $02
        .byte   $03
        .byte   $03
        .byte   $04
        .byte   $04
        ora     $05
        asl     $06
        .byte   $07
        .byte   $07
        php
        php
        ora     #$09
        asl     a
        asl     a
        .byte   $0B
        .byte   $0B
        .byte   $0C
        .byte   $0C
        ora     $0E0D
        asl     $0F0F
        bpl     L47C5
        ora     ($11),y
        .byte   $12
        .byte   $12
        .byte   $13
        .byte   $13
        .byte   $14
        .byte   $14
        ora     $15,x
        asl     $16,x
        .byte   $17
        .byte   $17
        clc
        clc
L47C5:  ora     $1A19,y
        .byte   $1A
        .byte   $1B
        .byte   $1B
        .byte   $1C
        .byte   $1C
        ora     $1E1D,x
        asl     $1F1F,x
        jsr     L2120
        and     (WNDTOP,x)
        .byte   $22
        .byte   $23
        .byte   $23
        bit     CH
        and     CV
        rol     $26
        .byte   $27
        .byte   $27
        plp
        plp
        and     #$29
        rol     a
        rol     a
        .byte   $2B
        .byte   $2B
        bit     $2D2C
        and     L2E2E
        .byte   $2F
        .byte   $2F
        bmi     L4825
        and     ($31),y
        .byte   $32
        .byte   $32
        .byte   $33
        .byte   $33
        .byte   $34
        .byte   $34
        and     $35,x
        rol     $36,x
        .byte   $37
        .byte   $37
        sec
        sec
        and     $3A39,y
        .byte   $3A
        .byte   $3B
        .byte   $3B
        .byte   $3C
        .byte   $3C
        and     $3E3D,x
        rol     $3F3F,x
L4813:  .byte   0
        .byte   0
        .byte   0
        .byte   0
L4817:  .byte   0
        .byte   0
        .byte   0
L481A:  ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        ora     (L0002,x)
        .byte   $02
        .byte   $02
        .byte   $02
L4825:  .byte   $02
        .byte   $02
        .byte   $02
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $03
        .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
        ora     $05
        ora     $05
        ora     $05
        ora     $06
        asl     $06
        asl     $06
        asl     $06
        .byte   $07
        .byte   $07
        .byte   $07
        .byte   $07
        .byte   $07
        .byte   $07
        .byte   $07
        php
        php
        php
        php
        php
        php
        php
        ora     #$09
        ora     #$09
        ora     #$09
        ora     #$0A
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        .byte   $0B
        .byte   $0B
        .byte   $0B
        .byte   $0B
        .byte   $0B
        .byte   $0B
        .byte   $0B
        .byte   $0C
        .byte   $0C
        .byte   $0C
        .byte   $0C
        .byte   $0C
        .byte   $0C
        .byte   $0C
        ora     $0D0D
        ora     $0D0D
        ora     $0E0E
        asl     $0E0E
        asl     $0F0E
        .byte   $0F
        .byte   $0F
        .byte   $0F
        .byte   $0F
        .byte   $0F
        .byte   $0F
        bpl     L4895
        bpl     L4897
        bpl     L4899
        bpl     L489C
        ora     ($11),y
        ora     ($11),y
        ora     ($11),y
        .byte   $12
        .byte   $12
        .byte   $12
        .byte   $12
L4895:  .byte   $12
        .byte   $12
L4897:  .byte   $12
        .byte   $13
L4899:  .byte   $13
        .byte   $13
        .byte   $13
L489C:  .byte   $13
        .byte   $13
        .byte   $13
        .byte   $14
        .byte   $14
        .byte   $14
        .byte   $14
        .byte   $14
        .byte   $14
        .byte   $14
        ora     $15,x
        ora     $15,x
        ora     $15,x
        ora     $16,x
        asl     $16,x
        asl     $16,x
        asl     $16,x
        .byte   $17
        .byte   $17
        .byte   $17
        .byte   $17
        .byte   $17
        .byte   $17
        .byte   $17
        clc
        clc
        clc
        clc
        clc
        clc
        clc
        ora     $1919,y
        ora     $1919,y
        ora     $1A1A,y
        .byte   $1A
        .byte   $1A
        .byte   $1A
        .byte   $1A
        .byte   $1A
        .byte   $1B
        .byte   $1B
        .byte   $1B
        .byte   $1B
        .byte   $1B
        .byte   $1B
        .byte   $1B
        .byte   $1C
        .byte   $1C
        .byte   $1C
        .byte   $1C
        .byte   $1C
        .byte   $1C
        .byte   $1C
        ora     $1D1D,x
        ora     $1D1D,x
        ora     $1E1E,x
        asl     $1E1E,x
        asl     $1F1E,x
        .byte   $1F
        .byte   $1F
        .byte   $1F
        .byte   $1F
        .byte   $1F
        .byte   $1F
        jsr     L2020
        jsr     L2020
        jsr     L2121
        and     (WNDWDTH,x)
        and     (WNDWDTH,x)
        and     (WNDTOP,x)
        .byte   $22
        .byte   $22
        .byte   $22
        .byte   $22
        .byte   $22
        .byte   $22
        .byte   $23
        .byte   $23
        .byte   $23
        .byte   $23
        .byte   $23
        .byte   $23
        .byte   $23
        bit     CH
        bit     CH
L4913:  .byte   0
        ora     (L0002,x)
        .byte   $03
L4917:  .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
L498F:  ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   0
        ora     (L0002,x)
        .byte   $03
L4A13:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        .byte   $80
        plp
        plp
        plp
        plp
        plp
        plp
        plp
        plp
        tay
        tay
        tay
        tay
        tay
        tay
        tay
        tay
        plp
        plp
        plp
        plp
        plp
        plp
        plp
        plp
        tay
        tay
L4A6D:  tay
        tay
L4A6F:  tay
        tay
L4A71:  tay
        tay
L4A73:  plp
        plp
        plp
        plp
        plp
        plp
        plp
        plp
        tay
        tay
L4A7D:  tay
        tay
L4A7F:  tay
        tay
L4A81:  tay
        tay
L4A83:  plp
        plp
        plp
        plp
        plp
        plp
        plp
        plp
        tay
        tay
L4A8D:  tay
        tay
L4A8F:  tay
        tay
L4A91:  tay
        tay
L4A93:  bvc     L4AE5
        bvc     L4AE7
        bvc     L4AE9
        bvc     L4AEB
        bne     L4A6D
L4A9D:  bne     L4A6F
L4A9F:  bne     L4A71
L4AA1:  bne     L4A73
L4AA3:  bvc     L4AF5
        bvc     L4AF7
        bvc     L4AF9
        bvc     L4AFB
        bne     L4A7D
        bne     L4A7F
        bne     L4A81
        bne     L4A83
        bvc     L4B05
        bvc     L4B07
        bvc     L4B09
        bvc     L4B0B
        bne     L4A8D
        bne     L4A8F
        bne     L4A91
        bne     L4A93
        bvc     L4B15
        bvc     L4B17
        bvc     L4B19
        bvc     L4B1B
        bne     L4A9D
        bne     L4A9F
        bne     L4AA1
        bne     L4AA3
L4AD3:  .byte   0
        .byte   $04
        php
        .byte   $0C
        bpl     L4AED
        clc
        .byte   $1C
        .byte   0
        .byte   $04
        php
        .byte   $0C
        bpl     L4AF5
        clc
        .byte   $1C
        ora     ($05,x)
L4AE5:  ora     #$0D
L4AE7:  ora     ($15),y
L4AE9:
L4AEB           := * + 2
        ora     $011D,y
L4AED           := * + 1
        ora     $09
        ora     $1511
        ora     $021D,y
L4AF5           := * + 1
        asl     $0A
L4AF7           := * + 1
        asl     $1612
L4AF9:  .byte   $1A
L4AFB           := * + 1
        asl     $0602,x
        asl     a
        asl     $1612
        .byte   $1A
        asl     $0703,x
L4B05:  .byte   $0B
        .byte   $0F
L4B07:  .byte   $13
        .byte   $17
L4B09:  .byte   $1B
        .byte   $1F
L4B0B:  .byte   $03
        .byte   $07
        .byte   $0B
        .byte   $0F
        .byte   $13
        .byte   $17
        .byte   $1B
        .byte   $1F
        .byte   0
        .byte   $04
L4B15:  php
        .byte   $0C
L4B17:  bpl     L4B2D
L4B19:  clc
        .byte   $1C
L4B1B:  .byte   0
        .byte   $04
        php
        .byte   $0C
        bpl     L4B35
        clc
        .byte   $1C
        ora     ($05,x)
        ora     #$0D
        ora     ($15),y
        ora     $011D,y
L4B2D           := * + 1
        ora     $09
        ora     $1511
        ora     $021D,y
L4B35           := * + 1
        asl     $0A
        asl     $1612
        .byte   $1A
        asl     $0602,x
        asl     a
        asl     $1612
        .byte   $1A
        asl     $0703,x
        .byte   $0B
        .byte   $0F
        .byte   $13
        .byte   $17
        .byte   $1B
        .byte   $1F
        .byte   $03
        .byte   $07
        .byte   $0B
        .byte   $0F
L4B4F:  .byte   $13
        .byte   $17
        .byte   $1B
        .byte   $1F
        .byte   0
        .byte   $04
        php
        .byte   $0C
        bpl     L4B6D
        clc
        .byte   $1C
        .byte   0
        .byte   $04
        php
        .byte   $0C
        bpl     L4B75
        clc
        .byte   $1C
        ora     ($05,x)
        ora     #$0D
        ora     ($15),y
        ora     $011D,y
L4B6D           := * + 1
        ora     $09
        ora     $1511
        ora     $021D,y
L4B75           := * + 1
        asl     $0A
        asl     $1612
        .byte   $1A
        asl     $0602,x
        asl     a
        asl     $1612
        .byte   $1A
        asl     $0703,x
        .byte   $0B
        .byte   $0F
        .byte   $13
        .byte   $17
        .byte   $1B
        .byte   $1F
        .byte   $03
        .byte   $07
        .byte   $0B
        .byte   $0F
        .byte   $13
        .byte   $17
        .byte   $1B
        .byte   $1F
L4B93:  lda     ($84),y
        eor     ($8E),y
        eor     $F6
        and     $89
        eor     ($84),y
        bcc     L4BA3
L4B9F:  lda     ($8E),y
        eor     $F6
L4BA3:  and     $E8
        ora     $E9
        sta     ($84),y
        dey
        bne     L4B9F
L4BAC:  lda     ($84),y
        eor     ($8E),y
        eor     $F6
        and     L0088
        eor     ($84),y
        and     $E8
        ora     $E9
        sta     ($84),y
        rts

        lda     ($8E),y
        eor     $F6
        and     $89
        bcc     L4BC9
L4BC5:  lda     ($8E),y
        eor     $F6
L4BC9:  ora     ($84),y
        and     $E8
        ora     $E9
        sta     ($84),y
        dey
        bne     L4BC5
        lda     ($8E),y
        eor     $F6
        and     L0088
        ora     ($84),y
        and     $E8
        ora     $E9
        sta     ($84),y
        rts

        lda     ($8E),y
        eor     $F6
        and     $89
        bcc     L4BEF
L4BEB:  lda     ($8E),y
        eor     $F6
L4BEF:  eor     ($84),y
        and     $E8
        ora     $E9
        sta     ($84),y
        dey
        bne     L4BEB
        lda     ($8E),y
        eor     $F6
        and     L0088
        eor     ($84),y
        and     $E8
        ora     $E9
        sta     ($84),y
        rts

        lda     ($8E),y
        eor     $F6
        and     $89
        bcc     L4C15
L4C11:  lda     ($8E),y
        eor     $F6
L4C15:  eor     #$FF
        and     ($84),y
        and     $E8
        ora     $E9
        sta     ($84),y
        dey
        bne     L4C11
        lda     ($8E),y
        eor     $F6
        and     L0088
        eor     #$FF
        and     ($84),y
        and     $E8
        ora     $E9
L4C30:  sta     ($84),y
        rts

L4C33:  cpx     $98
        beq     L4C3B
        inx
L4C38:
L4C39           := * + 1
L4C3A           := * + 2
        jmp     L4CED

L4C3B:  rts

        lda     L4C4D
L4C3F:  adc     $90
        sta     L4C4D
        bcc     L4C49
        inc     L4C4E
L4C49:  ldy     L5158
L4C4C:
L4C4D           := * + 1
L4C4E           := * + 2
        lda     LFFFF,y
        and     #$7F
        sta     $0601,y
        dey
        bpl     L4C4C
        bmi     L4C91
L4C59:  ldy     $8C
        inc     $8C
        lda     L4AD3,y
        ora     L0080
        sta     $83
        lda     L4A13,y
        adc     $8A
        sta     $82
L4C6B:  stx     $81
        ldy     #$00
        ldx     #$00
L4C71:  sta     HISCR
        lda     ($82),y
        and     #$7F
        sta     LOWSCR
L4C7C           := * + 1
        sta     $0601,x
        lda     ($82),y
        and     #$7F
L4C83           := * + 1
        sta     $0602,x
        iny
        inx
        inx
        cpx     L5158
        bcc     L4C71
        beq     L4C71
        ldx     $81
L4C91:  clc
L4C93           := * + 1
L4C94           := * + 2
        jmp     L4CB0

        stx     $82
        ldy     L5158
        lda     #$00
L4C9C:  ldx     $0601,y
L4CA0           := * + 1
L4CA1           := * + 2
        ora     L4293,x
L4CA3           := * + 1
        sta     $0602,y
L4CA6           := * + 1
L4CA7           := * + 2
        lda     L4213,x
        dey
        bpl     L4C9C
L4CAC           := * + 1
        sta     $0601
        ldx     $82
L4CB0:
L4CB1           := * + 1
L4CB2           := * + 2
        jmp     L4D2A

        stx     $82
        ldx     #$00
        ldy     #$00
L4CB9:
L4CBA           := * + 1
        lda     $0601,x
        sta     HISCR
        sta     $0601,y
        sta     LOWSCR
L4CC6           := * + 1
        lda     $0602,x
        sta     $0601,y
        inx
        inx
        iny
        cpy     $91
        bcc     L4CB9
        beq     L4CB9
        ldx     $82
        jmp     L4D2A

L4CD9:  ldx     $94
        clc
        jmp     L4C38

L4CDF:  ldx     L4D5C
        stx     L4C39
        ldx     L4D5D
        stx     L4C3A
        ldx     $94
L4CED:
L4CEE           := * + 1
L4CEF           := * + 2
        jmp     L4D03

        txa
        ror     a
        ror     a
        ror     a
        and     #$C0
        ora     $86
        sta     $82
        lda     #$04
        adc     #$00
        sta     $83
        jmp     L4C6B

L4D03:  txa
        ror     a
        ror     a
        ror     a
        and     #$C0
        ora     $86
        sta     $8E
        lda     #$04
        adc     #$00
        sta     $8F
L4D14           := * + 1
L4D15           := * + 2
        jmp     L4D2A

L4D16:  lda     $84
        clc
        adc     $D6
        sta     $84
        bcc     L4D22
        inc     $85
        clc
L4D22:  ldy     $91
        jsr     L4D59
        jmp     L4C33

L4D2A:  lda     L4AD3,x
        ora     $D5
        sta     $85
        lda     L4A13,x
        clc
        adc     $86
        sta     $84
        ldy     #$01
        jsr     L4D46
        ldy     #$00
        jsr     L4D46
        jmp     L4C33

L4D46:  sta     LOWSCR,y
        lda     $92,y
        ora     #$80
        sta     L0088
        lda     $96,y
        ora     #$80
        sta     $89
        ldy     $91
L4D59:
L4D5A           := * + 1
L4D5B           := * + 2
        jmp     L4B93

L4D5C:
L4D5D           := * + 1
L4D5E           := * + 2
        sbc     a:$4C
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L4D65:  ora     ($03,x)
        .byte   $07
        .byte   $0F
        .byte   $1F
        .byte   $3F
        .byte   $7F
L4D6C:  .byte   $7F
        .byte   $7F
        .byte   $7F
        .byte   $7F
        .byte   $7F
        .byte   $7F
        .byte   $7F
L4D73:  .byte   $7F
        ror     L787C,x
        bvs     L4DD9
        rti

        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L4D81:  .byte   $93
L4D82:  .byte   $4B
        lda     $E34B,x
        .byte   $4B
        ora     #$4C
        .byte   $93
        .byte   $4B
        lda     $E34B,x
        .byte   $4B
        ora     #$4C
L4D91:
L4D92           := * + 1
        ldy     $D44B
        .byte   $4B
        .byte   $FA
        .byte   $4B
        .byte   $22
        jmp     L4BAC

        .byte   $D4
        .byte   $4B
        .byte   $FA
        .byte   $4B
        .byte   $22
L4DA1           := * + 1
        jmp     LF0A5

        ldx     #$00
        cmp     #$04
        bcc     L4DAB
        ldx     #$7F
L4DAB:  stx     $F6
        rts

L4DAE:  add16   $F7, $96, $96
        add16   $F9, $98, $98
        add16   $F7, $92, $92
        lda     $F9
        clc
L4DD9           := * + 1
        adc     $94
        sta     $94
        lda     $FA
        adc     $95
        sta     $95
        lsr     $97
        beq     L4DE9
        jmp     L4E6B

L4DE9:  lda     $96
        ror     a
        tax
        lda     L4813,x
        ldy     L4913,x
L4DF3:  sta     $82
        tya
        rol     a
        tay
        lda     L4D65,y
        sta     $97
        lda     L4D5E,y
        sta     $96
        lsr     $93
        bne     L4E5A
        lda     $92
        ror     a
        tax
        lda     L4813,x
        ldy     L4913,x
L4E10:  sta     $86
        tya
        rol     a
        tay
        sty     $87
        lda     L4D73,y
        sta     $93
        lda     L4D6C,y
        sta     $92
        lda     $82
        sec
        sbc     $86
L4E26:  sta     $91
        pha
        lda     $F0
        asl     a
        tax
        pla
        bne     L4E4D
        lda     $93
        and     $97
        sta     $93
        sta     $97
        lda     $92
        and     $96
        sta     $92
        sta     $96
        lda     L4D91,x
        sta     L4D5A
        lda     L4D92,x
        sta     L4D5B
        rts

L4E4D:  lda     L4D81,x
        sta     L4D5A
        lda     L4D82,x
        sta     L4D5B
        rts

L4E5A:  lda     $92
        ror     a
        tax
        php
        lda     L4817,x
        clc
        adc     #$24
        plp
        ldy     L4917,x
        bpl     L4E10
L4E6B:  lda     $96
        ror     a
        tax
        php
        lda     L4817,x
        clc
        adc     #$24
        plp
        ldy     L4917,x
        bmi     L4E7F
        jmp     L4DF3

L4E7F:  lsr     a
        bne     L4E8C
        txa
        ror     a
        tax
        lda     L4813,x
        ldy     L4913,x
        rts

L4E8C:  txa
        ror     a
        tax
        php
        lda     L4817,x
        clc
        adc     #$24
        plp
        ldy     L4917,x
        rts

L4E9B:  lda     $86
        ldx     $94
        ldy     $D6
        jsr     L4F5D
        clc
        adc     $D4
        sta     $84
        tya
        adc     $D5
        sta     $85
        lda     #$02
        tax
        tay
        bit     $D6
        bmi     L4EDB
        copy16  #$0601, $8E
        jsr     L4F03
        txa
        inx
        stx     L5158
        jsr     L4E26
        copy16  L4F23, L4C93
        ldax    #$0000
        ldy     #$00
L4EDB:  pha
        lda     L4F29,x
        sta     L4D14
        lda     L4F2A,x
        sta     L4D15
        pla
        tax
        lda     L4F25,x
        sta     L4CEE
        lda     L4F26,x
        sta     L4CEF
        lda     L4F2D,y
        sta     L4CB1
        lda     L4F2E,y
        sta     L4CB2
        rts

L4F03:  lda     $91
        asl     a
        tax
        inx
        lda     $93
        bne     L4F17
        dex
        inc     $8E
        inc16   $84
L4F15:  lda     $92
L4F17:  sta     L0088
        lda     $96
        bne     L4F20
        dex
        lda     $97
L4F20:  sta     $89
        rts

L4F23:
L4F24           := * + 1
        bcs     L4F71
L4F25:
L4F26           := * + 1
        beq     L4F73
        .byte   $03
L4F29           := * + 1
L4F2A           := * + 2
        eor     L4D16
        rol     a
L4F2D           := * + 1
L4F2E           := * + 2
        eor     L4D16
        .byte   $B3
L4F31           := * + 1
        jmp     L8CA6

        ldy     $90
        jsr     L4F5D
        clc
        adc     $8E
        sta     L4C4D
        tya
        adc     $8F
        sta     L4C4E
        ldx     #$02
        bit     $90
        bmi     L4F4C
        ldx     #$00
L4F4C:  lda     L4F59,x
        sta     L4C39
        lda     L4F5A,x
        sta     L4C3A
        rts

L4F59:  .byte   $3C
L4F5A:  jmp     L4C59

L4F5D:  bmi     L4F7E
        stx     $82
        sty     $83
        nop
        ldx     #$08
L4F66:  lsr     $83
        bcc     L4F6D
        clc
        adc     $82
L4F6D:  ror     a
        ror     $84
L4F70:  dex
L4F71:  bne     L4F66
L4F73:  sty     $82
        tay
        lda     $84
        sec
        sbc     $82
        bcs     L4F7E
        dey
L4F7E:  rts

L4F7F:  lda     #$00
        sta     $8E
        lda     $F9
        and     #$07
        lsr     a
        ror     $8E
        lsr     a
        ror     $8E
        adc     #$04
        sta     $8F
        ldx     #$07
L4F93:  lda     $F7
        and     #$07
        tay
        lda     $E0,x
L4F9A:  dey
        bmi     L4FA2
        cmp     #$80
        rol     a
        bne     L4F9A
L4FA2:  ldy     #$27
L4FA4:  pha
        lsr     a
        sta     LOWSCR
        sta     ($8E),y
        pla
        ror     a
        pha
        lsr     a
        sta     HISCR
        sta     ($8E),y
        pla
        ror     a
        dey
        bpl     L4FA4
        lda     $8E
        sec
        sbc     #$40
        sta     $8E
        bcs     L4FCD
        ldy     $8F
        dey
        cpy     #$04
        bcs     L4FCB
        ldy     #$05
L4FCB:  sty     $8F
L4FCD:  dex
        bpl     L4F93
        sta     LOWSCR
        rts

L4FD4:  .byte   0
        ldy     #$03
L4FD7:  ldx     #$07
L4FD9:  lda     $9F,x
        sta     $92,x
        dex
        bpl     L4FD9
        ldx     L5006,y
        lda     $9F,x
        pha
        lda     $A0,x
        ldx     L500A,y
        sta     $93,x
        pla
        sta     $92,x
        sty     L4FD4
        jsr     L500E
        ldy     L4FD4
        dey
        bpl     L4FD7
        ldx     #$03
L4FFE:  lda     $9F,x
        sta     $EA,x
        dex
        bpl     L4FFE
L5005:  rts

L5006:  .byte   0
        .byte   $02
        .byte   $04
L500A           := * + 1
        asl     $04
        asl     L0000
        .byte   $02
L500E:  lda     $EE
        sec
        sbc     #$01
        cmp     #$FF
        beq     L5005
        adc     $96
        sta     $96
        bcc     L501F
        inc     $97
L501F:  lda     $EF
        sec
        sbc     #$01
        cmp     #$FF
        beq     L5005
        adc     $98
        sta     $98
        bcc     L5030
        inc     $99
L5030:  jsr     L513C
L5033:  jsr     L5099
        bcc     L5005
        jsr     L4DAE
        jsr     L4E9B
        jmp     L4CDF

L5041:  jsr     L513C
        lda     $EA
        ldx     $EB
        cpx     $93
        bmi     L507D
        bne     L5052
L504E:  cmp     $92
        bcc     L507D
L5052:  cpx     $97
        bmi     L505E
        bne     L507D
        cmp     $96
        bcc     L505E
        bne     L507D
L505E:  lda     $EC
        ldx     $ED
        cpx     $95
        bmi     L507D
        bne     L506C
        cmp     $94
        bcc     L507D
L506C:  cpx     $99
        bmi     L5078
        bne     L507D
        cmp     $98
        bcc     L5078
        bne     L507D
L5078:  lda     #$80
        jmp     L40AB

L507D:  rts

L507E:  sub16   $D0, $D8, $F7
        sub16   $D2, $DA, $F9
        rts

L5099:  lda     $DD
        cmp     $93
        bmi     L50A7
        bne     L50A9
        lda     $DC
        cmp     $92
        bcs     L50A9
L50A7:  clc
L50A8:  rts

L50A9:  lda     $97
        cmp     $D9
        bmi     L50A7
        bne     L50B7
        lda     $96
        cmp     $D8
        bcc     L50A8
L50B7:  lda     $DF
        cmp     $95
        bmi     L50A7
        bne     L50C5
        lda     $DE
        cmp     $94
        bcc     L50A8
L50C5:  lda     $99
        cmp     $DB
        bmi     L50A7
        bne     L50D3
        lda     $98
        cmp     $DA
        bcc     L50A8
L50D3:  ldy     #$00
        lda     $92
        sec
        sbc     $D8
        tax
        lda     $93
        sbc     $D9
        bpl     L50EE
        stx     $9B
        sta     $9C
        copy16  $D8, $92
        iny
L50EE:  lda     $DC
        sec
        sbc     $96
        tax
        lda     $DD
        sbc     $97
        bpl     L5106
        copy16  $DC, $96
        tya
        ora     #$04
        tay
L5106:  lda     $94
        sec
        sbc     $DA
        tax
        lda     $95
        sbc     $DB
        bpl     L5120
        stx     $9D
        sta     $9E
        copy16  $DA, $94
        iny
        iny
L5120:  lda     $DE
        sec
        sbc     $98
        tax
        lda     $DF
        sbc     $99
        bpl     L5138
        copy16  $DE, $98
        tya
        ora     #$08
        tay
L5138:  sty     $9A
        sec
        rts

L513C:  sec
        lda     $96
        sbc     $92
        lda     $97
        sbc     $93
        bmi     L5153
        sec
        lda     $98
        sbc     $94
        lda     $99
        sbc     $95
        bmi     L5153
        rts

L5153:  lda     #$83
        jmp     L40AB

L5158:  .byte   0
L5159:  .byte   0
        ldx     #$03
L515C:  lda     $8A,x
        sta     $9B,x
        lda     $92,x
        sta     $8A,x
        dex
        bpl     L515C
        sub16   $96, $92, $82
        lda     $9B
        sta     $92
        clc
        adc     $82
        sta     $96
        lda     $9C
        sta     $93
        adc     $83
        sta     $97
        sub16   $98, $94, $82
        lda     $9D
        sta     $94
        clc
        adc     $82
        sta     $98
        lda     $9E
        sta     $95
        adc     $83
        sta     $99
L51A3:  lda     #$00
        sta     $9B
        sta     $9C
        sta     $9D
        lda     $8F
        sta     L0080
        jsr     L5099
        bcs     L51B5
        rts

L51B5:  jsr     L4DAE
        lda     $91
        asl     a
        ldx     $93
        beq     L51C1
        adc     #$01
L51C1:  ldx     $96
        beq     L51C7
        adc     #$01
L51C7:  sta     L5159
        sta     L5158
        lda     #$02
        sta     $81
        lda     #$00
        sec
        sbc     $9D
        clc
        adc     $8C
        sta     $8C
        lda     #$00
        sec
        sbc     $9B
        tax
        lda     #$00
        sbc     $9C
        tay
        txa
        clc
        adc     $8A
        tax
        tya
        adc     $8B
        jsr     L4E7F
        sta     $8A
        tya
        rol     a
        cmp     #$07
        ldx     #$01
        bcc     L51FE
        dex
        sbc     #$07
L51FE:  stx     L4C7C
        inx
        stx     L4C83
        sta     $9B
        lda     $8A
        rol     a
        jsr     L4F31
        jsr     L4E9B
L5211           := * + 1
        copy16  #$0601, $8E
        ldx     #$01
        lda     $87
        sec
        sbc     #$07
L5220           := * + 1
        bcc     L5224
        sta     $87
        dex
L5224:  stx     L4CBA
        inx
        stx     L4CC6
        lda     $87
        sec
        sbc     $9B
        bcs     L5239
        adc     #$07
        inc     L5158
        dec     $81
L5239:  tay
        bne     L5240
        ldx     #$00
        beq     L5266
L5240:  tya
        asl     a
        tay
        lda     L5283,y
        sta     L4CA0
        lda     L5284,y
        sta     L4CA1
        lda     L5277,y
        sta     L4CA6
        lda     L5278,y
        sta     L4CA7
        ldy     $81
        sty     L4CA3
        dey
        sty     L4CAC
        ldx     #$02
L5266:  lda     L5275,x
        sta     L4C93
        lda     L5276,x
        sta     L4C94
        jmp     L4CD9

L5275:
L5276           := * + 1
        bcs     L52C3
L5277:
L5278           := * + 1
        sta     $4C,x
        .byte   $13
        .byte   $42
        .byte   $13
        .byte   $43
        .byte   $13
        .byte   $44
        .byte   $13
        eor     $13
L5283           := * + 1
        lsr     $13
L5284:  .byte   $47
        .byte   $93
        .byte   $42
        .byte   $93
        .byte   $43
        .byte   $93
        .byte   $44
        .byte   $93
        eor     $93
        lsr     $93
        .byte   $47
L5291:  stx     $B0
        asl     a
        asl     a
        sta     $B3
        ldy     #$03
L5299:  lda     (L0080),y
        sta     $92,y
        sta     $96,y
        dey
        bpl     L5299
        copy16  $94, $A7
        ldy     #$00
        stx     $AE
L52B0:  stx     $82
        lda     (L0080),y
        sta     $0700,x
        pha
        iny
        lda     (L0080),y
        sta     $073C,x
        tax
        pla
        iny
        cpx     $93
L52C3:  bmi     L52CB
        bne     L52D1
        cmp     $92
        bcs     L52D1
L52CB:  stax    $92
        bcc     L52DF
L52D1:  cpx     $97
        bmi     L52DF
        bne     L52DB
        cmp     $96
        bcc     L52DF
L52DB:  stax    $96
L52DF:  ldx     $82
        lda     (L0080),y
        sta     $0780,x
        pha
        iny
        lda     (L0080),y
        sta     $07BC,x
        tax
        pla
        iny
        cpx     $95
        bmi     L52FA
        bne     L5300
        cmp     $94
        bcs     L5300
L52FA:  stax    $94
        bcc     L530E
L5300:  cpx     $99
        bmi     L530E
        bne     L530A
L5307           := * + 1
        cmp     $98
        bcc     L530E
L530A:  stax    $98
L530E:  cpx     $A8
        stx     $A8
        bmi     L5320
        bne     L531C
        cmp     $A7
        bcc     L5320
        beq     L5320
L531C:  ldx     $82
        stx     $AE
L5320:  sta     $A7
        ldx     $82
        inx
        cpx     #$3C
        beq     L5387
        cpy     $B3
        bcc     L52B0
        lda     $94
        cmp     $98
        bne     L5339
        lda     $95
        cmp     $99
        beq     L5387
L5339:  stx     $B3
        bit     $BA
        bpl     L5340
        nop
L5340:  jmp     L5099

L5343:  lda     $B4
        bpl     L5368
        asl     a
        asl     a
        adc     L0080
        sta     L0080
        bcc     L5351
        inc     $81
L5351:  ldy     #$00
        lda     (L0080),y
        iny
        ora     (L0080),y
        sta     $B4
        inc16   L0080
L5360:  inc16   L0080
L5366:  ldy     #$80
L5368:  rts

        lda     #$80
        bne     L536F
L536D:  lda     #$00
L536F:  sta     $BA
        ldx     #$00
        stx     $AD
        jsr     L5351
L5378:  jsr     L5291
        bcs     L538C
        ldx     $B0
L537F:  jsr     L5343
        bmi     L5378
        jmp     L545E

L5387:  lda     #$81
        jmp     L40AB

L538C:  ldy     #$01
        sty     $AF
        ldy     $AE
        cpy     $B0
        bne     L5398
        ldy     $B3
L5398:  dey
        sty     $AB
        php
L539C:  sty     $AC
        iny
        cpy     $B3
        bne     L53A5
        ldy     $B0
L53A5:  sty     $AA
        cpy     $AE
        bne     L53AD
        dec     $AF
L53AD:  lda     $0780,y
        ldx     $07BC,y
        stx     $83
L53B5:  sty     $A9
        iny
        cpy     $B3
        bne     L53BE
        ldy     $B0
L53BE:  cmp     $0780,y
        bne     L53CA
        ldx     $07BC,y
        cpx     $83
        beq     L53B5
L53CA:  ldx     $AB
        sec
        sbc     $0780,x
        lda     $83
        sbc     $07BC,x
        bmi     L5437
        lda     $A9
        plp
        bmi     L53E7
        tay
        sta     $0680,x
        lda     $AA
        sta     $06BC,x
        bpl     L544C
L53E7:  ldx     $AD
        cpx     #$10
        bcs     L5387
        sta     $0468,x
        lda     $AA
        sta     $04A8,x
        ldy     $AB
        lda     $0680,y
        sta     $0469,x
        lda     $06BC,y
L5400:  sta     $04A9,x
        lda     $0780,y
        sta     $05E8,x
        sta     $05E9,x
        lda     $07BC,y
        sta     L5DF0,x
        sta     L5DF1,x
        lda     $0700,y
        sta     L5E21,x
        lda     $073C,y
        sta     L5E31,x
        ldy     $AC
        lda     $0700,y
        sta     L5E20,x
        lda     $073C,y
        sta     L5E30,x
        inx
        inx
        stx     $AD
        ldy     $A9
        bpl     L544C
L5437:  plp
        bmi     L543F
        lda     #$80
        sta     $0680,x
L543F:  ldy     $AA
        txa
        sta     $0680,y
        lda     $AC
        sta     $06BC,y
        lda     #$80
L544C:  php
        sty     $AB
L5450           := * + 1
        ldy     $A9
        bit     $AF
        bmi     L5458
        jmp     L539C

L5458:  plp
        ldx     $B3
        jmp     L537F

L545E:  ldx     #$00
        stx     $B1
        lda     #$80
        sta     $0428
        sta     $B2
L5469:  inx
        cpx     $AD
        bcc     L5471
        beq     L54A1
        rts

L5471:  lda     $B1
L5473:  tay
        lda     $05E8,x
        cmp     $05E8,y
        bcs     L5491
        tya
        sta     $0428,x
        cpy     $B1
        beq     L548D
        ldy     $82
        txa
        sta     $0428,y
        jmp     L5469

L548D:  stx     $B1
        bcs     L5469
L5491:  sty     $82
        lda     $0428,y
        bpl     L5473
        sta     $0428,x
        txa
        sta     $0428,y
        bpl     L5469
L54A1:  ldx     $B1
        lda     $05E8,x
        sta     $A9
        sta     $94
        lda     L5DF0,x
        sta     $AA
        sta     $95
L54B1:  ldx     $B1
        bmi     L5523
L54B5:  lda     $05E8,x
        cmp     $A9
        bne     L5521
        lda     L5DF0,x
        cmp     $AA
        bne     L5521
        lda     $0428,x
        sta     $82
        jsr     L55F5
        lda     $B2
        bmi     L5506
L54CF:  tay
        lda     L5E30,x
        cmp     L5E30,y
        bmi     L550F
        bne     L54F6
        lda     L5E20,x
        cmp     L5E20,y
        bcc     L550F
        bne     L54F6
        lda     L5E00,x
        cmp     L5E00,y
        bcc     L550F
        bne     L54F6
        lda     L5E10,x
        cmp     L5E10,y
        bcc     L550F
L54F6:  sty     $83
        lda     $0428,y
        bpl     L54CF
        sta     $0428,x
        txa
        sta     $0428,y
        bpl     L551D
L5506:  sta     $0428,x
        stx     $B2
        jmp     L551D

L550E:  rts

L550F:  tya
        cpy     $B2
        beq     L5506
        sta     $0428,x
        txa
        ldy     $83
        sta     $0428,y
L551D:  ldx     $82
        bpl     L54B5
L5521:  stx     $B1
L5523:  lda     #$00
        sta     $AB
        lda     $B2
        sta     $83
        bmi     L550E
L552D:  tax
        lda     $A9
        cmp     $05E8,x
        bne     L5573
        lda     $AA
        cmp     L5DF0,x
        bne     L5573
        ldy     $0468,x
        lda     $0680,y
        bpl     L555B
        cpx     $B2
        beq     L5553
        ldy     $83
        lda     $0428,x
        sta     $0428,y
        jmp     L55E7

L5553:  lda     $0428,x
        sta     $B2
        jmp     L55E7

L555B:  sta     $0468,x
        lda     $0700,y
        sta     L5E20,x
        lda     $073C,y
        sta     L5E30,x
        lda     $06BC,y
        sta     $04A8,x
        jsr     L55F5
L5573:  stx     $AC
        ldy     L5E30,x
        lda     L5E20,x
        tax
        lda     $AB
        eor     #$FF
        sta     $AB
        bpl     L558A
        stx     $92
        sty     $93
        bmi     L55BD
L558A:  stx     $96
        sty     $97
        cpy     $93
        bmi     L5598
        bne     L55A4
        cpx     $92
        bcs     L55A4
L5598:  lda     $92
        stx     $92
        sta     $96
        lda     $93
        sty     $93
        sta     $97
L55A4:  lda     $A9
        sta     $94
        sta     $98
        lda     $AA
        sta     $95
        sta     $99
        bit     $BA
        bpl     L55BA
        jsr     L5041
        jmp     L55BD

L55BA:  jsr     L5033
L55BD:  ldx     $AC
        lda     L5E10,x
        clc
        adc     $0528,x
        sta     L5E10,x
        lda     L5E00,x
        adc     $04E8,x
        sta     L5E00,x
        lda     L5E20,x
        adc     $0568,x
        sta     L5E20,x
        lda     L5E30,x
        adc     $05A8,x
        sta     L5E30,x
        lda     $0428,x
L55E7:  bmi     L55EC
        jmp     L552D

L55EC:  inc16   $A9
L55F2:  jmp     L54B1

L55F5:  ldy     $04A8,x
        lda     $0780,y
        sta     $05E8,x
        sec
        sbc     $A9
        sta     $A3
        lda     $07BC,y
        sta     L5DF0,x
        sbc     $AA
        sta     $A4
        lda     $0700,y
        sec
        sbc     L5E20,x
        sta     $A1
        lda     $073C,y
        sbc     L5E30,x
        sta     $A2
        php
        bpl     L562E
        lda     #$00
        sec
        sbc     $A1
        sta     $A1
        lda     #$00
        sbc     $A2
        sta     $A2
L562E:  stx     $84
        jsr     L5689
        ldx     $84
        plp
        bpl     L5651
        lda     #$00
        sec
        sbc     $9F
        sta     $9F
        lda     #$00
        sbc     $A0
        sta     $A0
        lda     #$00
        sbc     $A1
        sta     $A1
        lda     #$00
        sbc     $A2
        sta     $A2
L5651:  lda     $A2
        sta     $05A8,x
        cmp     #$80
        ror     a
        pha
        lda     $A1
        sta     $0568,x
        ror     a
        pha
        lda     $A0
        sta     $04E8,x
        ror     a
        pha
        lda     $9F
        sta     $0528,x
        ror     a
        sta     L5E10,x
        pla
        clc
        adc     #$80
        sta     L5E00,x
        pla
        adc     L5E20,x
        sta     L5E20,x
        pla
        adc     L5E30,x
        sta     L5E30,x
        rts

L5687:  lda     $A2
L5689:  ora     $A1
        bne     L5697
        sta     $9F
        sta     $A0
        sta     $A1
        sta     $A2
        beq     L56C4
L5697:  ldy     #$20
        lda     #$00
        sta     $9F
        sta     $A0
        sta     $A5
        sta     $A6
L56A3:  asl     $9F
        rol     $A0
        rol     $A1
        rol     $A2
        rol     $A5
        rol     $A6
        lda     $A5
        sec
        sbc     $A3
        tax
        lda     $A6
        sbc     $A4
        bcc     L56C1
        stx     $A5
        sta     $A6
        inc     $9F
L56C1:  dey
        bne     L56A3
L56C4:  rts

        lda     #$00
        sta     $BA
        jsr     L5351
L56CC:  copy16  L0080, $B7
        lda     $B4
        sta     $B6
        ldx     #$00
        jsr     L5291
        bcc     L571E
        lda     $B3
        sta     $B5
        ldy     #$00
L56E5:  dec     $B5
        beq     L5702
        sty     $B9
        ldx     #$00
L56ED:  lda     ($B7),y
        sta     $92,x
        iny
        inx
        cpx     #$08
        bne     L56ED
        jsr     L5772
        lda     $B9
        clc
        adc     #$04
        tay
        bne     L56E5
L5702:  ldx     #$00
L5704:  lda     ($B7),y
        sta     $92,x
        iny
        inx
        cpx     #$04
        bne     L5704
        ldy     #$03
L5710:  lda     ($B7),y
        sta     $96,y
        sta     $EA,y
        dey
        bpl     L5710
        jsr     L5772
L571E:  ldx     #$01
L5720:  lda     $B7,x
        sta     L0080,x
        lda     $B5,x
        sta     $B3,x
        dex
        bpl     L5720
        jsr     L5343
        bmi     L56CC
        rts

        lda     $A1
        ldx     $A2
        jsr     L5747
        lda     $A3
        ldx     $A4
        clc
        adc     $EC
        sta     $EC
        txa
        adc     $ED
        sta     $ED
        rts

L5747:  clc
        adc     $EA
        sta     $EA
        txa
        adc     $EB
        sta     $EB
        rts

        ldx     #$02
L5754:  lda     $A1,x
        clc
        adc     $EA,x
        sta     $92,x
        lda     $A2,x
        adc     $EB,x
        sta     $93,x
        dex
        dex
        bpl     L5754
        ldx     #$03
L5767:  lda     $EA,x
        sta     $96,x
        lda     $92,x
        sta     $EA,x
        dex
        bpl     L5767
L5772:  lda     $99
        cmp     $95
        bmi     L579F
        bne     L57AE
        lda     $98
        cmp     $94
        bcc     L579F
        bne     L57AE
        lda     $92
        ldx     $93
        cpx     $97
        bmi     L579C
        bne     L5790
        cmp     $96
        bcc     L579C
L5790:  ldy     $96
        sta     $96
        sty     $92
        ldy     $97
        stx     $97
        sty     $93
L579C:  jmp     L500E

L579F:  ldx     #$03
L57A1:  lda     $92,x
        tay
        lda     $96,x
        sta     $92,x
        tya
        sta     $96,x
        dex
        bpl     L57A1
L57AE:  ldx     $EE
        dex
        stx     $A2
        lda     $EF
        sta     $A4
        lda     #$00
        sta     $A1
        sta     $A3
        lda     $92
        ldx     $93
        cpx     $97
        bmi     L57D8
        bne     L57D0
        cmp     $96
        bcc     L57D8
        bne     L57D0
        jmp     L500E

L57D0:  lda     $A1
        ldx     $A2
        sta     $A2
        stx     $A1
L57D8:  ldy     #$05
L57DA:  sty     $82
        ldx     L582D,y
        ldy     #$03
L57E1:  lda     $92,x
        sta     $83,y
        dex
        dey
        bpl     L57E1
        ldy     $82
        ldx     L5833,y
        lda     $A1,x
        clc
        adc     $83
        sta     $83
        bcc     L57FA
        inc     $84
L57FA:  ldx     L5839,y
        lda     $A3,x
        clc
        adc     $85
        sta     $85
        bcc     L5808
        inc     $86
L5808:  tya
        asl     a
        asl     a
        tay
        ldx     #$00
L580E:  lda     $83,x
        sta     L5841,y
        iny
        inx
        cpx     #$04
        bne     L580E
        ldy     $82
        dey
        bpl     L57DA
        copy16  L582B, L0080
        jmp     L536D

L582B:  .byte   $3F
L582C:  cli
L582D:  .byte   $03
        .byte   $03
        .byte   $07
        .byte   $07
        .byte   $07
        .byte   $03
L5833:  .byte   0
        .byte   0
        .byte   0
        ora     ($01,x)
L5839           := * + 1
        ora     (L0000,x)
        ora     ($01,x)
        ora     (L0000,x)
        .byte   0
        asl     L0000
L5841:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        copy16  L0080, $F2
L5861:  ldy     #$00
L5863:  lda     ($F2),y
        sta     $FD,y
        iny
        cpy     #$03
        bne     L5863
        cmp     #$11
        bcs     L58A6
        lda     $F2
        ldx     $F3
        clc
        adc     #$03
        bcc     L587B
        inx
L587B:  stax    $FB
        sec
        adc     $FE
        bcc     L5885
        inx
L5885:  ldy     #$00
L5887:  sta     L58AB,y
        pha
        txa
        sta     L58BB,y
        pla
        sec
        adc     $FE
        bcc     L5896
        inx
L5896:  bit     $FD
        bpl     L58A0
        sec
        adc     $FE
        bcc     L58A0
        inx
L58A0:  iny
        cpy     $FF
        bne     L5887
        rts

L58A6:  lda     #$82
        jmp     L40AB

L58AB:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L58BB:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        jsr     L58D7
        ldy     #$03
        sta     (L0080),y
        txa
        iny
        sta     (L0080),y
        rts

L58D7:  ldx     #$00
        ldy     #$00
        sty     $82
L58DD:  sty     $83
        lda     ($A1),y
        tay
        txa
        clc
        adc     ($FB),y
        bcc     L58EA
        inc     $82
L58EA:  tax
        ldy     $83
        iny
        cpy     $A3
        bne     L58DD
        txa
        ldx     $82
        rts

L58F6:  sec
        sbc     #$01
        bcs     L58FC
        dex
L58FC:  clc
        adc     $EA
        sta     $96
        txa
        adc     $EB
        sta     $97
        copy16  $EA, $92
        lda     $EC
        sta     $98
        ldx     $ED
        stx     $99
        clc
        adc     #$01
        bcc     L591C
        inx
L591C:  sec
        sbc     $FF
        bcs     L5922
        dex
L5922:  stax    $94
        rts

L5927:  jsr     L5EEC
        jsr     L58D7
        stax    $A4
        ldy     #$00
        sty     $9F
        sty     $A0
        sty     $9B
        sty     $9D
        jsr     L58F6
        jsr     L5099
        bcc     L59A8
        tya
        ror     a
        bcc     L5961
        ldy     #$00
        ldx     $9C
L594B:  sty     $9F
        lda     ($A1),y
        tay
        lda     ($FB),y
        clc
        adc     $9B
        bcc     L595A
        inx
        beq     L5961
L595A:  sta     $9B
        ldy     $9F
        iny
        bne     L594B
L5961:  jsr     L4DAE
        jsr     L4E9B
        lda     $87
        clc
        adc     $9B
        bpl     L5974
        inc     $91
        dec     $A0
        adc     #$0E
L5974:  sta     $87
        lda     $91
        inc     $91
        ldy     $D6
        bpl     L598E
        asl     a
        tax
        lda     $87
        cmp     #$07
        bcs     L5987
        inx
L5987:  lda     $96
        beq     L598C
        inx
L598C:  stx     $91
L598E:  lda     $87
        sec
        sbc     #$07
        bcc     L5997
        sta     $87
L5997:  lda     #$00
        rol     a
        eor     #$01
        sta     $9C
        tax
        sta     LOWSCR,x
        jsr     L59B2
        sta     LOWSCR
L59A8:  jsr     L5EDC
        lda     $A4
        ldx     $A5
        jmp     L5747

L59B2:  lda     $98
        sec
        sbc     $94
        asl     a
        tax
        lda     L5D70,x
        sta     L5AF1
        lda     L5D71,x
        sta     L5AF2
        lda     L5D90,x
        sta     L5A84
        lda     L5D91,x
        sta     L5A85
        lda     L5DB0,x
        sta     L5C11
        lda     L5DB1,x
        sta     L5C12
        lda     L5DD0,x
        sta     L5CAD
        lda     L5DD1,x
        sta     L5CAE
        txa
        lsr     a
        tax
        sec
        stx     L0080
        stx     $81
        lda     #$00
        sbc     $9D
        sta     $9D
        tay
        ldx     #$C3
        sec
L59FB:  lda     L58AB,y
        sta     L5AF4,x
        lda     L58BB,y
        sta     L5AF5,x
        txa
        sbc     #$0D
        tax
        iny
        dec     L0080
        bpl     L59FB
        ldy     $9D
        ldx     #$4B
        sec
L5A15:  lda     L58AB,y
        sta     L5A87,x
        lda     L58BB,y
        sta     L5A88,x
        txa
        sbc     #$05
        tax
        iny
        dec     $81
        bpl     L5A15
        ldy     $94
        ldx     #$00
L5A2E:  bit     $D6
        bmi     L5A45
        lda     $84
        clc
        adc     $D6
        sta     $84
        sta     WNDLFT,x
        lda     $85
        adc     #$00
        sta     $85
        sta     WNDWDTH,x
        bne     L5A54
L5A45:  lda     L4A13,y
        clc
        adc     $86
        sta     WNDLFT,x
        lda     L4AD3,y
        ora     $D5
        sta     WNDWDTH,x
L5A54:  cpy     $98
        beq     L5A5D
        iny
        inx
        inx
        bne     L5A2E
L5A5D:  ldx     #$0F
        lda     #$00
L5A61:  sta     L0000,x
        dex
        bpl     L5A61
        sta     $81
        sta     $40
        lda     #$80
        sta     $42
        ldy     $9F
L5A70:  lda     ($A1),y
        tay
        bit     $81
        bpl     L5A7A
        sec
        adc     $FE
L5A7A:  tax
        lda     ($FB),y
        beq     L5AD6
        ldy     $87
        bne     L5AD9
L5A84           := * + 1
L5A85           := * + 2
        jmp     L5A86

L5A86:
L5A87           := * + 1
L5A88           := * + 2
        lda     LFFFF,x
        sta     $0F
        lda     LFFFF,x
        sta     $0E
        lda     LFFFF,x
        sta     $0D
        lda     LFFFF,x
        sta     L000C
        lda     LFFFF,x
        sta     $0B
        lda     LFFFF,x
        sta     $0A
        lda     LFFFF,x
        sta     $09
        lda     LFFFF,x
        sta     $08
        lda     LFFFF,x
        sta     $07
        lda     LFFFF,x
        sta     $06
        lda     LFFFF,x
        sta     $05
        lda     LFFFF,x
        sta     $04
        lda     LFFFF,x
        sta     $03
        lda     LFFFF,x
        sta     L0002
        lda     LFFFF,x
        sta     $01
        lda     LFFFF,x
        sta     L0000
L5AD6:  jmp     L5BC3

L5AD9:  tya
        asl     a
        tay
        lda     L5277,y
        sta     $40
        lda     L5278,y
        sta     $41
        lda     L5283,y
        sta     $42
        lda     L5284,y
        sta     $43
L5AF1           := * + 1
L5AF2           := * + 2
        jmp     L5AF3

L5AF3:
L5AF4           := * + 1
L5AF5           := * + 2
        ldy     LFFFF,x
        lda     ($42),y
        sta     $1F
        lda     ($40),y
        ora     $0F
        sta     $0F
        ldy     LFFFF,x
        lda     ($42),y
        sta     $1E
        lda     ($40),y
        ora     $0E
        sta     $0E
        ldy     LFFFF,x
        lda     ($42),y
        sta     $1D
        lda     ($40),y
        ora     $0D
        sta     $0D
        ldy     LFFFF,x
        lda     ($42),y
        sta     $1C
        lda     ($40),y
        ora     L000C
        sta     L000C
        ldy     LFFFF,x
        lda     ($42),y
        sta     $1B
        lda     ($40),y
        ora     $0B
        sta     $0B
        ldy     LFFFF,x
        lda     ($42),y
        sta     $1A
        lda     ($40),y
        ora     $0A
        sta     $0A
        ldy     LFFFF,x
        lda     ($42),y
        sta     $19
        lda     ($40),y
        ora     $09
        sta     $09
        ldy     LFFFF,x
        lda     ($42),y
        sta     $18
        lda     ($40),y
        ora     $08
L5B5A           := * + 1
        sta     $08
        ldy     LFFFF,x
        lda     ($42),y
        sta     $17
        lda     ($40),y
        ora     $07
        sta     $07
        ldy     LFFFF,x
        lda     ($42),y
        sta     $16
        lda     ($40),y
        ora     $06
        sta     $06
        ldy     LFFFF,x
        lda     ($42),y
        sta     $15
        lda     ($40),y
        ora     $05
        sta     $05
        ldy     LFFFF,x
        lda     ($42),y
        sta     $14
        lda     ($40),y
        ora     $04
        sta     $04
        ldy     LFFFF,x
        lda     ($42),y
        sta     $13
        lda     ($40),y
        ora     $03
        sta     $03
        ldy     LFFFF,x
        lda     ($42),y
        sta     $12
        lda     ($40),y
        ora     L0002
        sta     L0002
        ldy     LFFFF,x
        lda     ($42),y
        sta     $11
        lda     ($40),y
        ora     $01
        sta     $01
        ldy     LFFFF,x
        lda     ($42),y
        sta     $10
        lda     ($40),y
        ora     L0000
        sta     L0000
L5BC3:  bit     $81
        bpl     L5BD1
        inc     $9F
        lda     #$00
        sta     $81
        lda     $9A
        bne     L5BE5
L5BD1:  txa
        tay
        lda     ($FB),y
        cmp     #$08
        bcs     L5BDD
        inc     $9F
        bcc     L5BE5
L5BDD:  sbc     #$07
        sta     $9A
        ror     $81
        lda     #$07
L5BE5:  clc
        adc     $87
        cmp     #$07
        bcs     L5BFC
        sta     $87
L5BEE:  ldy     $9F
        cpy     $A3
        beq     L5BF7
        jmp     L5A70

L5BF7:  ldy     $A0
        jmp     L5CA4

L5BFC:  sbc     #$07
        sta     $87
        ldy     $A0
        bne     L5C07
        jmp     L5C91

L5C07:  bmi     L5C73
        dec     $91
        bne     L5C10
        jmp     L5CA4

L5C10:
L5C11           := * + 1
L5C12           := * + 2
        jmp     L5C13

L5C13:  lda     $0F
        eor     $F1
        sta     ($3E),y
        lda     $0E
        eor     $F1
        sta     ($3C),y
        lda     $0D
        eor     $F1
        sta     ($3A),y
        lda     L000C
        eor     $F1
        sta     ($38),y
        lda     $0B
        eor     $F1
        sta     ($36),y
        lda     $0A
        eor     $F1
        sta     ($34),y
        lda     $09
        eor     $F1
        sta     (INVFLG),y
        lda     $08
        eor     $F1
        sta     (L0030),y
        lda     $07
        eor     $F1
        sta     ($2E),y
        lda     $06
        eor     $F1
        sta     ($2C),y
        lda     $05
        eor     $F1
        sta     ($2A),y
        lda     $04
        eor     $F1
        sta     (BASL),y
        lda     $03
        eor     $F1
        sta     ($26),y
        lda     L0002
        eor     $F1
        sta     (CH),y
        lda     $01
        eor     $F1
        sta     (WNDTOP),y
        lda     L0000
        eor     $F1
        sta     (WNDLFT),y
L5C73:  bit     $D6
        bpl     L5C83
        lda     $9C
        eor     #$01
        tax
        sta     $9C
        sta     LOWSCR,x
        beq     L5C85
L5C83:  inc     $A0
L5C85:  ldx     #$0F
L5C87:  lda     $10,x
        sta     L0000,x
        dex
        bpl     L5C87
        jmp     L5BEE

L5C91:  ldx     $9C
        lda     $92,x
        dec     $91
        beq     L5C9F
        jsr     L5CA8
        jmp     L5C73

L5C9F:  and     $96,x
        bne     L5CA8
        rts

L5CA4:  ldx     $9C
        lda     $96,x
L5CA8:  ora     #$80
        sta     L0080
L5CAD           := * + 1
L5CAE           := * + 2
        jmp     L5CAF

L5CAF:  lda     $0F
        eor     $F1
        eor     ($3E),y
        and     L0080
        eor     ($3E),y
        sta     ($3E),y
        lda     $0E
        eor     $F1
        eor     ($3C),y
        and     L0080
        eor     ($3C),y
        sta     ($3C),y
        lda     $0D
        eor     $F1
        eor     ($3A),y
        and     L0080
        eor     ($3A),y
        sta     ($3A),y
        lda     L000C
        eor     $F1
        eor     ($38),y
        and     L0080
        eor     ($38),y
        sta     ($38),y
        lda     $0B
        eor     $F1
        eor     ($36),y
        and     L0080
        eor     ($36),y
        sta     ($36),y
        lda     $0A
        eor     $F1
        eor     ($34),y
        and     L0080
        eor     ($34),y
        sta     ($34),y
L5CF7:  lda     $09
        eor     $F1
        eor     (INVFLG),y
        and     L0080
        eor     (INVFLG),y
        sta     (INVFLG),y
        lda     $08
        eor     $F1
        eor     (L0030),y
        and     L0080
        eor     (L0030),y
        sta     (L0030),y
L5D0F:  lda     $07
        eor     $F1
        eor     ($2E),y
        and     L0080
        eor     ($2E),y
        sta     ($2E),y
        lda     $06
        eor     $F1
        eor     ($2C),y
        and     L0080
        eor     ($2C),y
        sta     ($2C),y
L5D27:  lda     $05
        eor     $F1
        eor     ($2A),y
        and     L0080
        eor     ($2A),y
        sta     ($2A),y
        lda     $04
        eor     $F1
        eor     (BASL),y
        and     L0080
        eor     (BASL),y
        sta     (BASL),y
L5D3F:  lda     $03
        eor     $F1
        eor     ($26),y
        and     L0080
        eor     ($26),y
        sta     ($26),y
        lda     L0002
        eor     $F1
        eor     (CH),y
        and     L0080
        eor     (CH),y
        sta     (CH),y
L5D57:  lda     $01
        eor     $F1
        eor     (WNDTOP),y
        and     L0080
        eor     (WNDTOP),y
        sta     (WNDTOP),y
        lda     L0000
        eor     $F1
        eor     (WNDLFT),y
        and     L0080
        eor     (WNDLFT),y
        sta     (WNDLFT),y
        rts

L5D70:
L5D71           := * + 1
        ldx     $5B,y
        lda     #$5B
        .byte   $9C
        .byte   $5B
        .byte   $8F
        .byte   $5B
        .byte   $82
        .byte   $5B
        adc     $5B,x
        pla
        .byte   $5B
        .byte   $5B
        .byte   $5B
        lsr     L415B
        .byte   $5B
        .byte   $34
        .byte   $5B
        .byte   $27
        .byte   $5B
        .byte   $1A
        .byte   $5B
        ora     a:$5B
        .byte   $5B
        .byte   $F3
        .byte   $5A
L5D90:
L5D91           := * + 1
        cmp     ($5A),y
        cpy     $C75A
        .byte   $5A
        .byte   $C2
        .byte   $5A
        lda     $B85A,x
        .byte   $5A
        .byte   $B3
        .byte   $5A
        ldx     $A95A
        .byte   $5A
        ldy     $5A
        .byte   $9F
        .byte   $5A
        txs
        .byte   $5A
        sta     $5A,x
        bcc     L5E06
        .byte   $8B
        .byte   $5A
        stx     $5A
L5DB0:
L5DB1           := * + 1
        adc     L675C
        .byte   $5C
        adc     ($5C,x)
        .byte   $5B
        .byte   $5C
        eor     $5C,x
        .byte   $4F
        .byte   $5C
        eor     #$5C
        .byte   $43
        .byte   $5C
        and     $375C,x
        .byte   $5C
        and     ($5C),y
        .byte   $2B
        .byte   $5C
        and     $5C
        .byte   $1F
        .byte   $5C
        ora     $135C,y
        .byte   $5C
L5DD0:  .byte   $63
L5DD1:  eor     L5D57,x
        .byte   $4B
        eor     L5D3F,x
        .byte   $33
        eor     L5D27,x
        .byte   $1B
        eor     L5D0F,x
        .byte   $03
        eor     L5CF7,x
        .byte   $EB
        .byte   $5C
        .byte   $DF
        .byte   $5C
        .byte   $D3
        .byte   $5C
        .byte   $C7
        .byte   $5C
        .byte   $BB
        .byte   $5C
        .byte   $AF
        .byte   $5C
L5DF0:  .byte   0
L5DF1:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L5E00:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L5E06:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L5E10:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L5E20:  .byte   0
L5E21:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L5E30:  .byte   0
L5E31:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L5E40:  lda     #$41
        sta     $82
        jsr     L5E6A
        ldx     #$23
L5E49:  lda     L5F10,x
        sta     $8A,x
        sta     $D0,x
        dex
        bpl     L5E49
        lda     L5E68
        ldx     L5E69
        jsr     L5E92
        lda     #$7F
        sta     $F6
        jsr     L5030
        lda     #$00
        sta     $F6
        rts

L5E68:  .byte   $34
L5E69:  .byte   $5F
L5E6A:  lda     DHIRESON
        sta     SET80VID
        ldx     #$06
L5E72:  lsr     $82
        lda     L5E87,x
        rol     a
        tay
        bcs     L5E80
        lda     CLR80COL,y
        bcc     L5E83
L5E80:  sta     CLR80COL,y
L5E83:  dex
        bpl     L5E72
        rts

L5E87:  .byte   $80
        sta     ($82,x)
        plp
        and     #$2A
        .byte   $2B
        lda     L0080
        ldx     $81
L5E92:  stax    $F4
L5E96:  lda     $F3
        beq     L5E9D
        jsr     L5861
L5E9D:  jsr     L507E
        jsr     L4F7F
        jmp     L4DA1

        jsr     L40C2
        lda     $F4
        ldx     $F5
L5EAD:  ldy     #$00
L5EAF:  sta     (L0080),y
        txa
        iny
        sta     (L0080),y
        rts

        ldy     #$23
L5EB8:  lda     L5F10,y
        sta     (L0080),y
        dey
        bpl     L5EB8
L5EC0:  rts

L5EC1:  lda     $82
        cmp     L5F0D
        beq     L5EC0
        sta     L5F0D
        bcc     L5EC0
        jmp     L4084

        lda     $82
        cmp     L5F0E
        beq     L5EC0
        sta     L5F0E
        bcc     L5EF1
L5EDC:  bit     L5F0E
        bpl     L5EEB
        ldx     #$43
L5EE3:  lda     L5DF0,x
        sta     L0000,x
        dex
        bpl     L5EE3
L5EEB:  rts

L5EEC:  bit     L5F0E
        bpl     L5EEB
L5EF1:  ldx     #$43
L5EF3:  lda     L0000,x
        sta     L5DF0,x
        dex
        bpl     L5EF3
        rts

        ldy     #$05
L5EFE:  lda     L5F07,y
        sta     (L0080),y
        dey
        bpl     L5EFE
        rts

L5F07:  ora     (L0000,x)
        .byte   0
        .byte   $42
        .byte   $04
        .byte   0
L5F0D:  .byte   $80
L5F0E:  .byte   $80
L5F0F:  .byte   0
L5F10:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        jsr     L0080
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $2F
        .byte   $02
        .byte   $BF
        .byte   0
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        ora     ($01,x)
        .byte   0
L5F31:  .byte   0
L5F32:  .byte   0
L5F33:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        jsr     L0080
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $2F
        .byte   $02
        .byte   $BF
        .byte   0
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        ora     ($01,x)
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L5F58:  .byte   $34
        .byte   $5F
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L5F5E:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L5F64:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L5F8E:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L5FE4:  .byte   0
L5FE5:  .byte   $FF
L5FE6:  .byte   0
L5FE7:  .byte   0
L5FE8:  .byte   0
        .byte   0
L5FEA:  .byte   0
L5FEB:  .byte   0
L5FEC:  .byte   0
L5FED:  .byte   0
L5FEE:  .byte   0
L5FEF:  .byte   0
L5FF0:  .byte   0
L5FF1:  .byte   0
L5FF2:  .byte   0
L5FF3:  .byte   0
L5FF4:  .byte   0
L5FF5:  .byte   0
L5FF6:  .byte   0
L5FF7:  .byte   0
L5FF8:  .byte   0
L5FF9:  .byte   0
L5FFA:  .byte   0
L5FFB:  .byte   0
L5FFC:  .byte   0
L5FFD:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L6021:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $02
        .byte   0
        asl     L0000
        asl     $1E00
        .byte   0
        rol     L7E00,x
        .byte   0
        .byte   $1A
        .byte   0
        bmi     L6037
L6037:  bmi     L6039
L6039:  rts

        .byte   0
        .byte   0
        .byte   0
        .byte   $03
        .byte   0
        .byte   $07
L6040:  .byte   0
        .byte   $0F
        .byte   0
        .byte   $1F
        .byte   0
        .byte   $3F
        .byte   0
        .byte   $7F
        .byte   0
        .byte   $7F
        ora     ($7F,x)
        .byte   0
        sei
        .byte   0
        sei
        .byte   0
        bvs     L6054
L6054           := * + 1
        bvs     L6056
L6056           := * + 1
        ora     ($01,x)
L6057:
L6058           := * + 1
        and     $60
L6059:  lda     #$FF
        sta     L5FE5
        lda     #$00
        sta     L5FE4
        copy16  L6057, L0080
L606D:  php
        sei
        lda     L0080
        ldx     $81
        stax    L6134
        clc
        adc     #$18
        bcc     L607F
        inx
L607F:  stax    L613A
        ldy     #$30
        lda     (L0080),y
        sta     L5FF4
        iny
        lda     (L0080),y
        sta     L5FF5
        jsr     L61B8
        jsr     L609A
        plp
L6099:  rts

L609A:  lda     L5FE5
        bne     L6099
        bit     L5FE4
        bmi     L6099
L60A4:  lda     #$00
        sta     L5FE5
        sta     L5FE4
        lda     L5FE8
        clc
        sbc     L5FF5
        sta     $84
        clc
        adc     #$0C
        sta     $85
        lda     L5FE6
        sec
        sbc     L5FF4
        tax
        lda     L5FE7
        sbc     #$00
        bpl     L60D3
        txa
        ror     a
        tax
        ldy     L498F,x
        lda     #$FF
        bmi     L60D6
L60D3:  jsr     L4E7F
L60D6:  sta     $82
        tya
        rol     a
        cmp     #$07
        bcc     L60E0
        sbc     #$07
L60E0:  tay
        lda     #$2A
        rol     a
        eor     #$01
        sta     $83
        sty     L5FF6
        tya
        asl     a
        tay
        lda     L5283,y
        sta     L6156
        lda     L5284,y
        sta     L6157
        lda     L5277,y
        sta     L615C
        lda     L5278,y
        sta     L615D
        ldx     #$03
L6108:  lda     $82,x
        sta     L6021,x
        dex
        bpl     L6108
        ldx     #$17
        stx     $86
        ldx     #$23
        ldy     $85
L6118:  cpy     #$C0
        bcc     L611F
        jmp     L61AB

L611F:  lda     L4A13,y
        sta     L0088
        lda     L4AD3,y
        ora     #$20
        sta     $89
        sty     $85
        stx     $87
        ldy     $86
        ldx     #$01
L6133:
L6134           := * + 1
L6135           := * + 2
        lda     LFFFF,y
        sta     L5FF7,x
L613A           := * + 1
L613B           := * + 2
        lda     LFFFF,y
        sta     L5FFA,x
        dey
        dex
        bpl     L6133
        lda     #$00
        sta     L5FF9
        sta     L5FFC
        ldy     L5FF6
        beq     L6164
        ldy     #$05
L6152:  ldx     L5FF6,y
L6156           := * + 1
L6157           := * + 2
        ora     $FF80,x
        sta     L5FF7,y
L615C           := * + 1
L615D           := * + 2
        lda     $FF00,x
        dey
        bne     L6152
        sta     L5FF7
L6164:  ldx     $87
        ldy     $82
        lda     $83
        jsr     L621C
        bcs     L617F
        lda     (L0088),y
        sta     L5FFD,x
        lda     L5FFA
        ora     (L0088),y
        eor     L5FF7
        sta     (L0088),y
        dex
L617F:  jsr     L6212
        bcs     L6194
        lda     (L0088),y
        sta     L5FFD,x
        lda     L5FFB
        ora     (L0088),y
        eor     L5FF8
        sta     (L0088),y
        dex
L6194:  jsr     L6212
        bcs     L61A9
        lda     (L0088),y
        sta     L5FFD,x
        lda     L5FFC
        ora     (L0088),y
        eor     L5FF9
        sta     (L0088),y
        dex
L61A9:  ldy     $85
L61AB:  dec     $86
        dec     $86
        dey
        cpy     $84
        beq     L620E
        jmp     L6118

L61B7:  rts

L61B8:  lda     L5FE5
        bne     L61B7
        bit     L5FE4
        bmi     L61B7
        ldx     #$03
L61C4:  lda     L6021,x
        sta     $82,x
        dex
        bpl     L61C4
        ldx     #$23
        ldy     $85
L61D0:  cpy     #$C0
        bcs     L6209
        lda     L4A13,y
        sta     L0088
        lda     L4AD3,y
        ora     #$20
        sta     $89
        sty     $85
        ldy     $82
        lda     $83
        jsr     L621C
        bcs     L61F1
        lda     L5FFD,x
        sta     (L0088),y
        dex
L61F1:  jsr     L6212
        bcs     L61FC
        lda     L5FFD,x
        sta     (L0088),y
        dex
L61FC:  jsr     L6212
        bcs     L6207
        lda     L5FFD,x
        sta     (L0088),y
        dex
L6207:  ldy     $85
L6209:  dey
        cpy     $84
        bne     L61D0
L620E:  sta     LOWSCR
        rts

L6212:  lda     L6220
        eor     #$01
        cmp     #$54
        beq     L621C
        iny
L621C:  sta     L6220
L6220           := * + 1
        sta     $C0FF
        cpy     #$28
        rts

L6225:  php
        sei
        lda     L5FE5
        beq     L623E
        inc     L5FE5
        bmi     L623E
        beq     L6236
        dec     L5FE5
L6236:  bit     L5FE4
        bmi     L623E
        jsr     L60A4
L623E:  plp
        rts

        php
        sei
        jsr     L61B8
        lda     #$80
        sta     L5FE4
        plp
        rts

L624C:  php
        sei
        jsr     L61B8
        dec     L5FE5
        plp
L6255:  rts

L6256:  .byte   0
L6257:  bit     L632B
        bpl     L626E
        lda     L7C2F
L6260           := * + 1
        bne     L626E
        dec     L6256
        lda     L6256
        bpl     L6255
        lda     #$02
        sta     L6256
L626E:  ldx     #$02
L6270:  lda     L5FEA,x
        cmp     L5FE6,x
        bne     L627D
        dex
        bpl     L6270
        bmi     L6291
L627D:  jsr     L61B8
        ldx     #$02
        stx     L5FE4
L6285:  lda     L5FEA,x
        sta     L5FE6,x
        dex
        bpl     L6285
        jsr     L609A
L6291:  bit     L83D7
        bmi     L6299
        jsr     L62AC
L6299:  bit     L83D7
        bpl     L62A3
        lda     #$00
        sta     L5FEE
L62A3:  lda     L7C2F
        beq     L62AB
        jsr     L7DB0
L62AB:  rts

L62AC:  ldy     #$14
        jsr     L6305
        bit     L5FF1
        bmi     L62CB
        ldx     L83D8
        lda     MOUSE_X_LO,x
        sta     L5FEA
        lda     MOUSE_X_HI,x
        sta     L5FEB
        lda     MOUSE_Y_LO,x
        sta     L5FEC
L62CB:  ldy     L5FEF
        beq     L62E1
L62D0:  lda     L5FEA
        asl     a
        sta     L5FEA
        lda     L5FEB
        rol     a
        sta     L5FEB
        dey
        bne     L62D0
L62E1:  ldy     L5FF0
        beq     L62F0
        lda     L5FEC
L62E9:  asl     a
        dey
        bne     L62E9
        sta     L5FEC
L62F0:  bit     L5FF1
        bmi     L62FB
        lda     MOUSE_STATUS,x
        sta     L5FEE
L62FB:  rts

        lda     L6134
        ldx     L6135
        jmp     L5EAD

L6305:  bit     L83D7
        bmi     L62AB
        bit     L5FF1
        bmi     L6324
        pha
        ldx     L83D8
        stx     $89
        lda     #$00
        sta     L0088
        lda     (L0088),y
        sta     L0088
        pla
        ldy     L83D9
        jmp     (L0088)

L6324:  jmp     (L5FF2)

L6327:  .byte   0
L6328:  .byte   0
L6329:  .byte   0
L632A:  .byte   0
L632B:  .byte   0
L632C:  .byte   0
L632D:  .byte   0
        .byte   0
        .byte   0
L6330:  .byte   0
L6331:  .byte   0
L6332:  php
        pla
        sta     L6331
        ldx     #$04
L6339:  lda     $82,x
        sta     L6327,x
        dex
        bpl     L6339
        lda     #$7F
        sta     L5F31
        copy16  $87, L5F32
        copy16  $89, L67D0
        copy16  $8B, L632C
L6365           := * + 1
        jsr     L644D
        jsr     L6461
        ldy     #$02
        lda     ($87),y
        tax
        stx     L67BD
        dex
        stx     L7791
        inx
        inx
        inx
        stx     L67CE
        inx
        stx     L7793
        stx     L67C6
        stx     L67D4
        stx     L67DC
        inx
        stx     L7799
        stx     L7795
        stx     L6564
        stx     L656C
        copy16  #$0001, L5FEF
        bit     L6328
        bvs     L63AF
        copy16  #$0102, L5FEF
L63AF:  ldx     L632A
        jsr     L8378
        bit     L632A
        bpl     L63D4
        cpx     #$00
        bne     L63C3
        lda     #$92
        jmp     L40AB

L63C3:  lda     L632A
        and     #$7F
        beq     L63D4
        cpx     L632A
        beq     L63D4
        lda     #$91
        jmp     L40AB

L63D4:  stx     L632A
        lda     #$80
        sta     L6330
        lda     L632A
        bne     L63EB
        bit     L632B
        bpl     L63EB
        lda     #$00
        sta     L632B
L63EB:  ldy     #$03
        lda     L632A
        sta     (L0080),y
        iny
        lda     L632B
        sta     (L0080),y
        bit     L632B
        bpl     L6408
        bit     L6329
        bpl     L6408
        MLI_CALL ALLOC_INTERRUPT, $6447
L6408:  lda     VERSION
        pha
        lda     #$06
        sta     VERSION
        ldy     #$12
        lda     #$01
        bit     L632B
        bpl     L641D
        cli
        ora     #$08
L641D:  jsr     L6305
        pla
        sta     VERSION
        jsr     L5E40
        jsr     L6059
        jsr     L6773
        lda     #$00
        sta     L6F5C
L6432:  jsr     L650F
        jsr     L6558
        MGTK_CALL MGTK::SetPattern, $657A
        MGTK_CALL MGTK::PaintRect, $656A
        jmp     L6526

        .byte   $02
L6448:  .byte   0
        cmp     ($66,x)
L644C           := * + 1
        ora     (L0000,x)
L644D:  lda     L632B
        beq     L645B
        cmp     #$01
        bne     L645C
        lda     #$80
        sta     L632B
L645B:  rts

L645C:  lda     #$93
        jmp     L40AB

L6461:  lda     L6329
        beq     L646F
        cmp     #$01
        beq     L6474
        lda     #$90
        jmp     L40AB

L646F:  lda     #$80
        sta     L6329
L6474:  rts

        ldy     #$12
        lda     #$00
        jsr     L6305
        ldy     #$13
        jsr     L6305
        bit     L632B
        bpl     L6497
        bit     L6329
        bpl     L6497
        lda     L6448
        sta     L644C
        MLI_CALL DEALLOC_INTERRUPT, $644B
L6497:  lda     L6331
        pha
        plp
        lda     #$00
        sta     L6330
        rts

        lda     $82
        cmp     #$01
        bne     L64B5
        lda     $84
        bne     L64C6
        sta     L64F2
        lda     $83
        sta     L64F1
        rts

L64B5:  cmp     #$02
        bne     L64D8
        lda     $84
        bne     L64CF
        sta     L6508
        lda     $83
        sta     L6507
        rts

L64C6:  lda     #$00
        sta     L64F1
        sta     L64F2
        rts

L64CF:  lda     #$00
        sta     L6507
        sta     L6508
        rts

L64D8:  lda     #$94
        jmp     L40AB

L64DD:  lda     L64F2
        beq     L64ED
        jsr     L650F
        jsr     L64EE
        php
        jsr     L6526
        plp
L64ED:  rts

L64EE:  jmp     (L64F1)

L64F1:  .byte   0
L64F2:  .byte   0
L64F3:  lda     L6508
        beq     L6503
        jsr     L650F
        jsr     L6504
        php
        jsr     L6526
        plp
L6503:  rts

L6504:  jmp     (L6507)

L6507:  .byte   0
L6508:  .byte   0
L6509:  .byte   0
L650A:  .byte   0
L650B:  .byte   0
L650C:  jsr     L624C
L650F:  copy16  L0080, L6509
        lda     L5F0F
        sta     L650B
        lsr     L5F0D
        rts

L6523:  jsr     L6225
L6526:  asl     L5F0D
        copy16  L6509, L0080
        lda     $F4
        ldx     $F5
L6537:  stax    $82
        lda     L650B
        sta     L5F0F
        ldy     #$23
L6543:
L6544           := * + 1
        lda     ($82),y
        sta     $D0,y
        dey
        bpl     L6543
        jmp     L5E96

L654E:  lda     L6556
L6553           := * + 2
        ldx     L6557
        bne     L6537
L6556:
L6557           := * + 1
        bpl     L65B7
L6558:  jsr     L654E
        MGTK_CALL MGTK::SetPortBits, $6562
        rts

        .byte   0
        .byte   0
L6564:  ora     a:L0000
        jsr     L0080
L656A:  .byte   0
        .byte   0
L656C:  .byte   0
        .byte   0
        .byte   $2F
        .byte   $02
        .byte   $BF
        .byte   0
L6572:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        eor     $AA,x
        eor     $AA,x
        eor     $AA,x
        eor     $AA,x
        .byte   0
        bit     L6330
        bmi     L659D
        copy16  $82, L5FF2
        lda     L65A2
        ldx     L65A3
        ldy     #$02
        jmp     L5EAF

L659D:  lda     #$95
        jmp     L40AB

L65A2:  nop
L65A3:  .byte   $5F
        clc
        bcc     L65A8
        sec
L65A8:  php
        bit     L632B
        bpl     L65B1
        sei
        bmi     L65B4
L65B1:  jsr     L6633
L65B4:  jsr     L6799
L65B7:  bcs     L65D4
        plp
        php
        bcc     L65C0
        sta     L66ED
L65C0:  tax
        ldy     #$00
L65C3:  lda     L66EF,x
        sta     (L0080),y
        inx
        iny
        cpy     #$04
        bne     L65C3
        lda     #$00
        sta     (L0080),y
        beq     L65D7
L65D4:  jsr     L6615
L65D7:  plp
        bit     L632B
        bpl     L65DE
        cli
L65DE:  rts

        php
        sei
        lda     $82
        bmi     L65F6
        cmp     #$06
        bcs     L660B
        cmp     #$03
        beq     L65F6
        ldx     $83
        ldy     $84
        lda     $85
        jsr     L7CD4
L65F6:  jsr     L677F
        bcs     L660F
        tax
        ldy     #$00
L65FE:  lda     (L0080),y
        sta     L66EF,x
        inx
        iny
        cpy     #$04
        bne     L65FE
        plp
        rts

L660B:  lda     #$98
        bmi     L6611
L660F:  lda     #$99
L6611:  plp
        jmp     L40AB

L6615:  lda     #$00
        bit     L5FEE
        bpl     L661E
        lda     #$04
L661E:  ldy     #$00
        sta     (L0080),y
        iny
L6623:  lda     L5FE5,y
        sta     (L0080),y
        iny
        cpy     #$05
        bne     L6623
        rts

L662E:  .byte   0
L662F:  .byte   0
L6630:  .byte   0
        .byte   0
L6632:  .byte   0
L6633:  bit     L632B
        bpl     L663D
        lda     #$97
        jmp     L40AB

L663D:  sec
        jsr     L64DD
        bcc     L66B5
        lda     BUTN1
        asl     a
        lda     BUTN0
        and     #$80
        rol     a
        rol     a
        sta     L6632
        jsr     L7E21
        jsr     L6257
        lda     L5FEE
        asl     a
        eor     L5FEE
        bmi     L6684
        bit     L5FEE
        bmi     L66B5
        bit     L67AE
        bpl     L6684
        lda     CLR80COL
        bpl     L66B5
        and     #$7F
        sta     L662F
        bit     KBDSTRB
        lda     L6632
        sta     L6630
        lda     #$03
        sta     L662E
        bne     L66A3
L6684:  bcc     L6693
        lda     L6632
        beq     L668F
        lda     #$05
        bne     L6695
L668F:  lda     #$01
        bne     L6695
L6693:  lda     #$02
L6695:  sta     L662E
        ldx     #$02
L669A:  lda     L5FE6,x
        sta     L662F,x
        dex
        bpl     L669A
L66A3:  jsr     L677F
        tax
        ldy     #$00
L66A9:  lda     L662E,y
        sta     L66EF,x
        inx
        iny
        cpy     #$04
        bne     L66A9
L66B5:  jmp     L64F3

L66B8:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        cld
        ldx     #$08
L66C4:  lda     $82,x
        sta     L66B8,x
        dex
        bpl     L66C4
        ldy     #$13
        jsr     L6305
        bcs     L66D7
        jsr     L663D
        clc
L66D7:  ldx     #$08
L66D9:  lda     L66B8,x
        sta     $82,x
        dex
        bpl     L66D9
        rts

        .byte   $C2
        ror     $AD
        .byte   $E2
        ror     $AE
        .byte   $E3
        ror     $4C
L66ED           := * + 2
        lda     a:$5E
L66EE:  .byte   0
L66EF:  .byte   0
L66F0:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L675C:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L6773:  php
        sei
        lda     #$00
        sta     L66ED
        sta     L66EE
        plp
        rts

L677F:  lda     L66EE
        cmp     #$80
        bne     L678A
        lda     #$00
        bcs     L678D
L678A:  clc
L678B:  adc     #$04
L678D:  cmp     L66ED
        beq     L6797
        sta     L66EE
        clc
        rts

L6797:  sec
        rts

L6799:  lda     L66ED
        cmp     L66EE
        beq     L6797
        cmp     #$80
        bne     L67A9
        lda     #$00
        bcs     L67AC
L67A9:  clc
        adc     #$04
L67AC:  clc
        rts

L67AE:  .byte   $80
        asl     L67AE
        ror     $82
        ror     L67AE
        rts

L67B8:  .byte   $02
L67B9:
L67BA           := * + 1
        ora     #$10
L67BB:
L67BC           := * + 1
        ora     #$1E
L67BD:
L67BE           := * + 1
        cmp     L0000
L67BF:  .byte   0
L67C0:  .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        bmi     L67C8
L67C6:  .byte   $0C
        .byte   0
L67C8:  .byte   0
        .byte   0
        .byte   0
        .byte   0
L67CC:  .byte   0
        .byte   0
L67CE:  .byte   $0B
        .byte   0
L67D0:  .byte   0
L67D1:  .byte   0
L67D2:  .byte   0
        .byte   0
L67D4:  .byte   $0C
        .byte   0
L67D6:  .byte   0
        .byte   0
L67D8:  .byte   0
        .byte   0
L67DA:  .byte   0
L67DB:  .byte   0
L67DC:  .byte   $0C
        .byte   0
L67DE:  .byte   0
L67DF:  .byte   0
L67E0:  .byte   0
L67E1:  .byte   0
L67E2:  .byte   $0C
L67E3:  clc
        bit     L0030
        .byte   $3C
        pha
        .byte   $54
        rts

        jmp     (L8478)

        bcc     L678B
        tay
L67F1           := * + 1
        ldy     $1E,x
L67F2:  .byte   $1F
L67F3:
L67F4           := * + 1
        ora     $0201,x
L67F6:
L67F7           := * + 1
        asl     $01FF,x
L67F9:
L67FA           := * + 1
L67FB           := * + 2
        ora     L67C0,x
L67FC:  .byte   $D2
L67FD:  .byte   $67
L67FE:  sed
L67FF:  .byte   $67
L6800:
L6801           := * + 1
        sbc     $67,x
L6802:  copy16  L67BE, $82
        ldy     #$00
        lda     ($82),y
        sta     $A8
        rts

L6813:  stx     $A7
        lda     #$02
        clc
L6818:  dex
        bmi     L681F
        adc     #$0C
        bne     L6818
L681F:  adc     L67BE
        sta     $AB
        lda     L67BF
        adc     #$00
        sta     $AC
        ldy     #$0B
L682D:  lda     ($AB),y
        sta     $AF,y
        dey
        bpl     L682D
        ldy     #$05
L6837:  lda     ($B3),y
        sta     $BA,y
        dey
        bne     L6837
        lda     ($B3),y
        sta     $AA
        rts

L6844:  ldy     #$0B
L6846:  lda     $AF,y
        sta     ($AB),y
        dey
        bpl     L6846
        ldy     #$05
L6850:  lda     $BA,y
        sta     ($B3),y
        dey
        bne     L6850
        rts

L6859:  stx     $A9
        lda     #$06
        clc
L685E:  dex
        bmi     L6865
        adc     #$06
        bne     L685E
L6865:  adc     $B3
        sta     $AD
        lda     $B4
        adc     #$00
        sta     $AE
        ldy     #$05
L6871:  lda     ($AD),y
        sta     $BF,y
        dey
        bpl     L6871
        rts

L687A:  ldy     #$05
L687C:  lda     $BF,y
        sta     ($AD),y
        dey
        bpl     L687C
        rts

L6885:  sty     $EC
        ldy     #$00
        sty     $ED
L688B:  stax    $EA
        rts

L6890:  sta     $F0
        jmp     L4DA1

L6895:  jsr     L68A1
        jmp     L58D7

L689B:  jsr     L68A1
        jmp     L5927

L68A1:  stax    $82
        clc
        adc     #$01
        bcc     L68AB
        inx
L68AB:  stax    $A1
        ldy     #$00
        lda     ($82),y
        sta     $A3
        rts

L68B6:  MGTK_CALL MGTK::CheckEvents, $0082
        return  $82

L68BF:  copy16  L0080, L67BE
        jsr     L6802
        jsr     L650C
        jsr     L654E
        lda     L67FA
        ldx     L67FB
        jsr     L699D
        ldax    #$000C
        ldy     L67BD
        iny
        jsr     L6885
        ldx     #$00
L68E8:  jsr     L6813
        lda     $EA
        ldx     $EB
        stax    $B5
        sec
        sbc     #$08
        bcs     L68F9
        dex
L68F9:  stax    $B7
        stax    $BB
        ldx     #$00
        stx     $C5
        stx     $C6
L6907:  jsr     L6859
        bit     $BF
        bvs     L6945
        lda     $C3
        ldx     $C4
        jsr     L6895
        stax    $82
        lda     $BF
        and     #$03
        bne     L6928
        lda     $C1
        bne     L6928
        lda     L67BB
        bne     L692B
L6928:  lda     L67BC
L692B:  clc
        adc     $82
        sta     $82
        bcc     L6934
        inc     $83
L6934:  sec
        sbc     $C5
        lda     $83
        sbc     $C6
        bmi     L6945
        copy16  $82, $C5
L6945:  ldx     $A9
        inx
        cpx     $AA
        bne     L6907
L694C:  lda     $BB
        clc
        adc     $C5
        sta     $BD
        lda     $BC
        adc     #$00
        sta     $BE
        jsr     L6844
        lda     $B1
        ldx     $B2
        jsr     L689B
        jsr     L6993
        lda     $EA
        ldx     $EB
        clc
        adc     #$08
        bcc     L6970
        inx
L6970:  stax    $B9
        jsr     L6844
        addr_call L5747, $000C
        ldx     $A7
        inx
        cpx     $A8
        beq     L6988
        jmp     L68E8

L6988:  lda     #$00
        sta     L6B10
        sta     L6B11
        jmp     L6523

L6993:  ldx     $A7
        jsr     L6813
        ldx     $A9
        jmp     L6859

L699D:  stax    $69B2
        stax    $69BD
        lda     #$00
        jsr     L6890
        MGTK_CALL MGTK::PaintRect, $0000
        lda     #$04
        jsr     L6890
        MGTK_CALL MGTK::FrameRect, $0000
        rts

L69C0:  jsr     L69CB
        bne     L69CA
        lda     #$9A
        jmp     L40AB

L69CA:  rts

L69CB:  lda     #$00
L69CD:  sta     $C6
        jsr     L6802
        ldx     #$00
L69D4:  jsr     L6813
        bit     $C6
        bvs     L6A01
        bmi     L69E5
        lda     $AF
        cmp     $C7
        bne     L6A06
        beq     L6A10
L69E5:  lda     L5FE6
        ldx     L5FE7
        cpx     $B8
        bcc     L6A06
        bne     L69F5
        cmp     $B7
        bcc     L6A06
L69F5:  cpx     $BA
        bcc     L6A10
        bne     L6A06
        cmp     $B9
        bcc     L6A10
        bcs     L6A06
L6A01:  jsr     L6A13
        bne     L6A10
L6A06:  ldx     $A7
        inx
        cpx     $A8
        bne     L69D4
        return  #$00

L6A10:  return  $AF

L6A13:  ldx     #$00
L6A15:  jsr     L6859
        ldx     $A9
        inx
        bit     $C6
        bvs     L6A31
        bmi     L6A27
        cpx     $C8
        bne     L6A4D
        beq     L6A53
L6A27:  lda     L67E2,x
        cmp     L5FE8
        bcs     L6A53
        bcc     L6A4D
L6A31:  lda     $C9
        and     #$7F
        cmp     $C1
        beq     L6A3D
        cmp     $C2
        bne     L6A4D
L6A3D:  cmp     #$20
        bcc     L6A53
        lda     $BF
        and     #$C0
        bne     L6A4D
        lda     $BF
        and     $CA
        bne     L6A53
L6A4D:  cpx     $AA
        bne     L6A15
        ldx     #$00
L6A53:  rts

L6A54:  lda     $C7
        bne     L6A5D
        lda     L6B10
        sta     $C7
L6A5D:  jsr     L69C0
L6A60:  jsr     L650C
        jsr     L654E
        jsr     L6A6C
        jmp     L6523

L6A6C:  ldx     #$01
L6A6E:  lda     $B7,x
        sta     L67C8,x
        lda     $B9,x
        sta     L67CC,x
        lda     $BB,x
        sta     L67D2,x
        sta     L67DA,x
        lda     $BD,x
        sta     L67D6,x
        sta     L67DE,x
        dex
        bpl     L6A6E
        lda     #$02
        jsr     L6890
        MGTK_CALL MGTK::PaintRect, $67C8
        rts

        lda     $C9
        cmp     #$1B
        bne     L6AA7
        lda     $CA
        bne     L6AA7
        jsr     L7C27
        jmp     L6B12

L6AA7:  lda     #$C0
        jsr     L69CD
        beq     L6ABF
        lda     $B0
        bmi     L6ABF
        lda     $BF
        and     #$C0
        bne     L6ABF
        lda     $AF
        sta     L6B10
        bne     L6AC2
L6ABF:  lda     #$00
        tax
L6AC2:  ldy     #$00
        sta     (L0080),y
        iny
        txa
        sta     (L0080),y
        bne     L6A60
        rts

L6ACD:  jsr     L69C0
        jsr     L6A13
        cpx     #$00
L6AD5:  rts

L6AD6:  jsr     L6ACD
        bne     L6AD5
        lda     #$9B
        jmp     L40AB

        jsr     L6AD6
        asl     $BF
        ror     $C9
        ror     $BF
        jmp     L687A

        jsr     L6AD6
        lda     $C9
        beq     L6AF9
        lda     #$20
        ora     $BF
        bne     L6AFD
L6AF9:  lda     #$DF
        and     $BF
L6AFD:  sta     $BF
        jmp     L687A

        jsr     L69C0
        asl     $B0
        ror     $C8
        ror     $B0
        ldx     $A7
        jmp     L6844

L6B10:  .byte   0
L6B11:  .byte   0
L6B12:  jsr     L7D88
        jsr     L6802
        jsr     L650F
        jsr     L654E
        bit     L7C2F
        bpl     L6B29
        jsr     L7E9C
        jmp     L6B5A

L6B29:  lda     #$00
        sta     L6B10
        sta     L6B11
        jsr     L68B6
L6B34:  bit     L7C3C
        bpl     L6B3C
        jmp     L8004

L6B3C:  MGTK_CALL MGTK::MoveTo, $0083
        MGTK_CALL MGTK::InRect, $67C0
        bne     L6B8F
        lda     L6B10
        beq     L6B5A
        MGTK_CALL MGTK::InRect, $67D2
        bne     L6BAA
        jsr     L6DD8
L6B5A:  jsr     L68B6
        beq     L6B63
        cmp     #$02
        bne     L6B34
L6B63:  lda     L6B11
        bne     L6B6E
        jsr     L6C5A
        jmp     L6B77

L6B6E:  jsr     L624C
        jsr     L654E
        jsr     L6C2B
L6B77:  jsr     L6526
        lda     #$00
        ldx     L6B11
        beq     L6B8C
        lda     L6B10
        ldy     $A7
        sty     L7C35
        stx     L7C36
L6B8C:  jmp     L5EAD

L6B8F:  jsr     L6DD8
        lda     #$80
        jsr     L69CD
        cmp     L6B10
        beq     L6B5A
        pha
        jsr     L6C5A
        pla
        sta     L6B10
        jsr     L6C5D
        jmp     L6B5A

L6BAA:  lda     #$80
        sta     $C6
        jsr     L6A13
        cpx     L6B11
        beq     L6B5A
        lda     $B0
        ora     $BF
        and     #$C0
        beq     L6BC0
        ldx     #$00
L6BC0:  txa
        pha
        jsr     L6DE1
        pla
        sta     L6B11
        jsr     L6DE1
        jmp     L6B5A

L6BCF:  lda     $BC
        lsr     a
        lda     $BB
        ror     a
        tax
        lda     L4813,x
        sta     $82
        lda     $BE
        lsr     a
        lda     $BD
        ror     a
        tax
        lda     L4813,x
        sec
        sbc     $82
        sta     $90
        copy16  L67D0, $8E
        ldy     $AA
        ldx     L67E2,y
        inx
        stx     $83
        stx     L67E0
        stx     L67D8
        ldx     L67BD
        inx
        inx
        inx
        stx     L67DC
        stx     L67D4
        rts

L6C0F:  lda     L4A13,x
        clc
        adc     $82
        sta     $84
        lda     L4AD3,x
        ora     #$20
        sta     $85
        rts

L6C1F:  lda     $8E
        sec
        adc     $90
        sta     $8E
        bcc     L6C2A
        inc     $8F
L6C2A:  rts

L6C2B:  jsr     L6BCF
L6C2E:  jsr     L6C0F
        sta     HISCR
        ldy     $90
L6C36:  lda     ($8E),y
        sta     ($84),y
        dey
        bpl     L6C36
        jsr     L6C1F
        sta     LOWSCR
        ldy     $90
L6C45:  lda     ($8E),y
        sta     ($84),y
        dey
        bpl     L6C45
        jsr     L6C1F
        inx
        cpx     $83
        bcc     L6C2E
        beq     L6C2E
        jmp     L6225

L6C59:  rts

L6C5A:  clc
        bcc     L6C5E
L6C5D:  sec
L6C5E:  lda     L6B10
        beq     L6C59
        php
        sta     $C7
        jsr     L69CB
L6C6A           := * + 1
        jsr     L624C
        jsr     L6A6C
        plp
        bcc     L6C2B
        jsr     L6BCF
L6C75:  jsr     L6C0F
        sta     HISCR
        ldy     $90
L6C7D:  lda     ($84),y
        sta     ($8E),y
        dey
        bpl     L6C7D
        jsr     L6C1F
        sta     LOWSCR
        ldy     $90
L6C8C:  lda     ($84),y
        sta     ($8E),y
        dey
        bpl     L6C8C
        jsr     L6C1F
        inx
        cpx     $83
        bcc     L6C75
        beq     L6C75
        jsr     L654E
        lda     L67FC
        ldx     L67FD
        jsr     L699D
        inc16   L67DA
L6CB1:  lda     L67DE
        bne     L6CB9
        dec     L67DF
L6CB9:  dec     L67DE
        jsr     L6993
        ldx     #$00
L6CC1:  jsr     L6859
        bit     $BF
        bvc     L6CCB
        jmp     L6D4F

L6CCB:  lda     $BF
        and     #$20
        beq     L6CF4
        lda     L67B8
        jsr     L6D5C
        lda     L67F3
        sta     L67F9
        lda     $BF
        and     #$04
        beq     L6CE8
        lda     $C0
        sta     L67F9
L6CE8:  lda     L67FE
        ldx     L67FF
        jsr     L689B
        jsr     L6993
L6CF4:  lda     L67B9
        jsr     L6D5C
        lda     $C3
        ldx     $C4
        jsr     L689B
        jsr     L6993
        lda     $BF
        and     #$03
        bne     L6D17
        lda     $C1
        beq     L6D41
        lda     L67F4
        sta     L67F6
        jmp     L6D41

L6D17:  cmp     #$01
        bne     L6D24
        lda     L67F2
        sta     L67F6
        jmp     L6D2A

L6D24:  lda     L67F1
        sta     L67F6
L6D2A:  lda     $C1
        sta     L67F7
        lda     L67BA
        jsr     L6DC9
        lda     L6800
        ldx     L6801
        jsr     L689B
        jsr     L6993
L6D41:  bit     $B0
        bmi     L6D49
        bit     $BF
        bpl     L6D4F
L6D49:  jsr     L6D6D
        jmp     L6D4F

L6D4F:  ldx     $A9
        inx
        cpx     $AA
        beq     L6D59
        jmp     L6CC1

L6D59:  jmp     L6225

L6D5C:  ldx     $A9
        ldy     L67E3,x
        dey
        ldx     $BC
        clc
        adc     $BB
        bcc     L6D6A
        inx
L6D6A:  jmp     L6885

L6D6D:  ldx     $A9
        lda     L67E2,x
        sta     L6DC3
        inc     L6DC3
        lda     L67E3,x
        sta     L6DC7
        clc
        lda     $BB
        adc     #$05
        sta     L6DC1
        lda     $BC
        adc     #$00
        sta     L6DC2
        sec
        lda     $BD
        sbc     #$05
        sta     L6DC5
        lda     $BE
        sbc     #$00
        sta     L6DC6
        MGTK_CALL MGTK::SetPattern, $6DB9
        lda     #$01
        jsr     L6890
        MGTK_CALL MGTK::PaintRect, $6DC1
        MGTK_CALL MGTK::SetPattern, $5F20
        lda     #$02
        jsr     L6890
        rts

        dey
        eor     L0088,x
        eor     L0088,x
        eor     L0088,x
L6DC1           := * + 1
        eor     L0000,x
L6DC2:  .byte   0
L6DC3:  .byte   0
        .byte   0
L6DC5:  .byte   0
L6DC6:  .byte   0
L6DC7:  .byte   0
        .byte   0
L6DC9:  sta     $82
        lda     $BD
        ldx     $BE
        sec
        sbc     $82
        bcs     L6DD5
        dex
L6DD5:  jmp     L688B

L6DD8:  jsr     L6DE1
        lda     #$00
        sta     L6B11
L6DE0:  rts

L6DE1:  ldx     L6B11
        beq     L6DE0
        ldy     L67E1,x
        iny
        sty     L67DC
        ldy     L67E2,x
        sty     L67E0
        jsr     L624C
        lda     #$02
        jsr     L6890
        MGTK_CALL MGTK::PaintRect, $67DA
        jmp     L6225

        ldx     #$03
L6E06:  lda     $82,x
        sta     L67F1,x
        dex
        bpl     L6E06
        copy16  L5F32, $82
        ldy     #$00
        lda     ($82),y
        bmi     L6E39
        copy16  #$0902, L67B8
        copy16  #$0910, L67BA
        lda     #$1E
        sta     L67BC
        bne     L6E52
L6E39:  copy16  #$1002, L67B8
        lda     #$1E
        sta     L67BA
L6E49           := * + 1
        copy16  #$3310, L67BB
L6E52:  ldy     #$02
        lda     ($82),y
        cmp     #$0B
        nop
        tay
        iny
        iny
        iny
        ldx     #$00
L6E5F:  tya
        adc     L67E2,x
        inx
        sta     L67E2,x
        cpx     #$0E
        bcc     L6E5F
        rts

L6E6D           := * + 1
        jsr     L6AD6
        lda     $C9
        beq     L6E80
        lda     #$04
        ora     $BF
        sta     $BF
        lda     $CA
        sta     $C0
        jmp     L687A

L6E80:  lda     #$FB
        and     $BF
        sta     $BF
        jmp     L687A

L6E89:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $13
        asl     a
        lda     ($6E),y
L6E91:  .byte   0
        .byte   0
L6E93:  .byte   0
L6E94:  .byte   0
        .byte   $13
        asl     a
        .byte   $D2
L6E99           := * + 1
        ror     a:L0000
        .byte   0
        .byte   0
        .byte   $14
        ora     #$F3
L6EA1           := * + 1
L6EA2           := * + 2
        ror     a:L0000
        .byte   0
        .byte   0
        .byte   $12
        ora     #$11
        .byte   $6F
L6EA9:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $14
        asl     a
        bmi     L6F20
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        clc
        .byte   0
        .byte   0
        ror     L0000
        rti

        ora     ($03,x)
        bmi     L6EBF
L6EBF:  .byte   $0C
        .byte   $7C
        ora     ($3F,x)
        rti

        ora     ($03,x)
        rti

        ora     ($03,x)
        rti

        .byte   $7F
        .byte   $03
        .byte   0
        .byte   0
        .byte   0
        ror     L7F7F,x
        ror     L7F7F,x
        .byte   0
        .byte   0
        .byte   0
        rti

        .byte   $7F
        .byte   $03
        rti

        ora     ($03,x)
        rti

        ora     ($03,x)
        .byte   $7C
        ora     ($3F,x)
        bmi     L6EE6
L6EE6:  .byte   $0C
        rti

        ora     ($03,x)
        .byte   0
        ror     L0000
        .byte   0
        clc
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        clc
        rti

        .byte   0
        asl     L4040,x
        adc     $304F,y
        .byte   0
        jmp     L000C

        jmp     L0030

        jmp     L7940

        .byte   $4F
        .byte   0
        asl     a:$40,x
        clc
        rti

        .byte   0
        .byte   0
        .byte   0
        ora     (L000C,x)
        .byte   0
        ora     ($3C,x)
        .byte   0
        adc     $014F,y
        ora     $0600,y
L6F20:  ora     $1800,y
        ora     $0600,y
        adc     $014F,y
        ora     ($3C,x)
        .byte   0
        ora     (L000C,x)
        .byte   0
        .byte   0
        .byte   $7F
        .byte   $7F
        .byte   $7F
        ora     (L0000,x)
        rti

        adc     L403F,y
        ora     L4F70,y
        ora     L4C30,y
        ora     L4C30,y
        adc     L4C3F,y
        adc     (L0000,x)
        jmp     L7F61

        .byte   $4F
        ora     (L0000,x)
        rti

        .byte   $7F
        .byte   $7F
        .byte   $7F
L6F51:  .byte   $89
L6F52:
L6F53           := * + 1
L6F54           := * + 2
        ror     L6E91
L6F55:
L6F56           := * + 1
L6F57           := * + 2
        sta     $A16E,y
L6F58:
L6F59           := * + 1
L6F5A           := * + 2
        ror     L6EA9
L6F5B:  .byte   0
L6F5C:  .byte   0
L6F5D:  .byte   0
L6F5E:  .byte   0
L6F5F:  .byte   0
L6F60:  .byte   0
L6F61:  .byte   $23
L6F62:  .byte   $6F
L6F63:  copy16  L6F61, $A7
        lda     L6F5B
        ldx     L6F5C
        bne     L6F88
L6F75:  rts

L6F76:  copy16  $A9, $A7
        ldy     #$39
        lda     ($A9),y
        beq     L6F75
        tax
        dey
        lda     ($A9),y
L6F88:  stax    L6F5E
L6F8E:  lda     L6F5E
        ldx     L6F5F
L6F94:  stax    $A9
        ldy     #$0B
L6F9A:  lda     ($A9),y
        sta     $AB,y
        dey
        bpl     L6F9A
        ldy     #$23
L6FA4:  lda     ($A9),y
        sta     $A3,y
        dey
        cpy     #$13
        bne     L6FA4
L6FAE:  lda     $A9
        ldx     $AA
        rts

L6FB3:  jsr     L6F63
        beq     L6FC3
L6FB8:  lda     $AB
        cmp     $82
        beq     L6FAE
        jsr     L6F76
        bne     L6FB8
L6FC3:  rts

L6FC4:  jsr     L6FB3
        beq     L6FCA
        rts

L6FCA:  lda     #$9E
        jmp     L40AB

L6FCF:  MGTK_CALL MGTK::FrameRect, $00C7
        rts

L6FD6:  MGTK_CALL MGTK::InRect, $00C7
        rts

L6FDD:  ldx     #$03
L6FDF:  lda     $B7,x
        sta     $C7,x
        dex
        bpl     L6FDF
        ldx     #$02
L6FE8:  lda     $C3,x
        sec
        sbc     $BF,x
        tay
        lda     $C4,x
        sbc     $C0,x
        pha
        tya
        clc
        adc     $C7,x
        sta     $CB,x
        pla
        adc     $C8,x
        sta     $CC,x
        dex
        dex
        bpl     L6FE8
L7002:  ldax    #$00C7
        rts

L7007:  jsr     L6FDD
        lda     $C7
        bne     L7010
        dec     $C8
L7010:  dec     $C7
        bit     $B0
        bmi     L7020
        lda     $AC
        and     #$04
        bne     L7020
        lda     #$01
        bne     L7022
L7020:  lda     #$15
L7022:  clc
        adc     $CB
        sta     $CB
        bcc     L702B
        inc     $CC
L702B:  lda     #$01
        bit     $AF
        bpl     L7033
        lda     #$0B
L7033:  clc
        adc     $CD
        sta     $CD
        bcc     L703C
        inc     $CE
L703C:  lda     #$01
        and     $AC
L7041           := * + 1
        bne     L7045
        lda     L7795
L7045:  sta     $82
        lda     $C9
        sec
        sbc     $82
        sta     $C9
        bcs     L7002
        dec     $CA
        bcc     L7002
L7054:  jsr     L7007
        lda     $CB
        ldx     $CC
        sec
        sbc     #$14
        bcs     L7061
        dex
L7061:  stax    $C7
        lda     $AC
        and     #$01
        bne     L7002
        lda     $C9
        clc
L706E:  adc     L7793
        sta     $C9
        bcc     L7002
        inc     $CA
        bcs     L7002
L7079:  jsr     L7007
L707C:  lda     $CD
        ldx     $CE
        sec
        sbc     #$0A
        bcs     L7086
        dex
L7086:  stax    $C9
        jmp     L7002

L708D:  jsr     L7054
        jmp     L707C

L7093:  jsr     L7007
        lda     $C9
        clc
        adc     L7793
        sta     $CD
        lda     $CA
        adc     #$00
        sta     $CE
        jmp     L7002

L70A7:  jsr     L7093
        lda     $C7
        ldx     $C8
        clc
        adc     #$02
        bcc     L70B4
        inx
L70B4:  stax    $C7
        clc
        adc     #$0E
        bcc     L70BE
        inx
L70BE:  stax    $CB
        lda     $C9
        ldx     $CA
        clc
        adc     #$02
        bcc     L70CC
        inx
L70CC:  stax    $C9
        clc
        adc     L7791
        bcc     L70D7
        inx
L70D7:  stax    $CD
        jmp     L7002

L70DE:  jsr     L7007
        jsr     L699D
        lda     $AC
        and     #$01
        bne     L70FA
        jsr     L7093
        jsr     L699D
        jsr     L7285
        lda     $AD
        ldx     $AE
        jsr     L689B
L70FA:  jsr     L6F8E
        bit     $B0
        bpl     L7107
        jsr     L7054
        jsr     L6FCF
L7107:  bit     $AF
        bpl     L7111
        jsr     L7079
        jsr     L6FCF
L7111:  lda     $AC
        and     #$04
        beq     L7123
        jsr     L708D
        jsr     L6FCF
        jsr     L7054
        jsr     L6FCF
L7123:  jsr     L6F8E
        lda     $AB
        cmp     L6F5D
        bne     L7133
        jsr     L6558
        jmp     L713B

L7133:  rts

L7134:
L7135           := * + 1
        ora     ($A9,x)
        ora     ($A2,x)
        .byte   0
        beq     L713F
L713B:  ldax    #$0103
L713F:  stx     L7134
        jsr     L6890
        lda     $AC
        and     #$02
        beq     L7157
        lda     $AC
        and     #$01
        bne     L7157
        jsr     L70A7
        jsr     L6FCF
L7157:  lda     #$02
        jsr     L6890
        lda     $AC
        and     #$01
        bne     L7192
        jsr     L7093
        jsr     L7285
        jsr     L58F6
        lda     $92
        sec
        sbc     #$0A
        sta     $92
        bcs     L7176
        dec     $93
L7176:  lda     $96
        clc
        adc     #$0A
        sta     $96
        bcc     L7181
        inc     $97
L7181:  lda     $94
        bne     L7187
        dec     $95
L7187:  dec     $94
        inc16   $98
L718F:  jsr     L5030
L7192:  jsr     L6F8E
        bit     $B0
        bpl     L71DF
        jsr     L7054
        ldx     #$03
L719E:  lda     $C7,x
        sta     L6E89,x
        sta     L6E91,x
        dex
        bpl     L719E
        lda     $CD
        ldx     $CE
        sec
        sbc     #$0A
        bcs     L71B3
        dex
L71B3:  pha
        lda     $AC
        and     #$04
        bne     L71BE
        bit     $AF
        bpl     L71C6
L71BE:  pla
        sec
        sbc     #$0B
        bcs     L71C5
        dex
L71C5:  pha
L71C6:  pla
        stax    L6E93
        lda     L6F53
        ldx     L6F54
        jsr     L77E2
        lda     L6F51
        ldx     L6F52
        jsr     L77E2
L71DF:  bit     $AF
        bpl     L7229
        jsr     L7079
        ldx     #$03
L71E8:  lda     $C7,x
        sta     L6E99,x
        sta     L6EA1,x
        dex
        bpl     L71E8
        lda     $CB
        ldx     $CC
        sec
        sbc     #$14
        bcs     L71FD
        dex
L71FD:  pha
        lda     $AC
        and     #$04
        bne     L7208
        bit     $B0
        bpl     L7210
L7208:  pla
        sec
        sbc     #$15
        bcs     L720F
        dex
L720F:  pha
L7210:  pla
        stax    L6EA1
        lda     L6F57
        ldx     L6F58
        jsr     L77E2
        lda     L6F55
        ldx     L6F56
        jsr     L77E2
L7229:  lda     #$00
        jsr     L6890
        lda     $B0
        and     #$01
        beq     L7241
        lda     #$80
        sta     $8C
        lda     L7134
        jsr     L7866
        jsr     L6F8E
L7241:  lda     $AF
        and     #$01
        beq     L7254
        lda     #$00
        sta     $8C
        lda     L7134
        jsr     L7866
        jsr     L6F8E
L7254:  lda     $AC
        and     #$04
        beq     L7284
        jsr     L708D
        lda     L7134
        bne     L726C
        addr_call L699D, $00C7
        jmp     L7284

L726C:  ldx     #$03
L726E:  lda     $C7,x
        sta     L6EA9,x
        dex
        bpl     L726E
        lda     #$04
        jsr     L6890
        lda     L6F59
        ldx     L6F5A
        jsr     L77E2
L7284:  rts

L7285:  lda     $AD
        ldx     $AE
        jsr     L6895
        stax    $82
        lda     $C7
        clc
        adc     $CB
        tay
        lda     $C8
        adc     $CC
        tax
        tya
        sec
        sbc     $82
        tay
        txa
        sbc     $83
        cmp     #$80
        ror     a
        sta     $EB
        tya
        ror     a
        sta     $EA
        lda     $CD
        ldx     $CE
        sec
        sbc     #$02
        bcs     L72B6
        dex
L72B6:  stax    $EC
        lda     $82
        ldx     $83
        rts

        jsr     L650F
        MGTK_CALL MGTK::InRect, $67C0
        beq     L72DC
        lda     #$01
L72CC:  ldx     #$00
L72CE:  pha
        txa
        pha
        jsr     L6526
        pla
        tax
        pla
        ldy     #$04
        jmp     L5EAF

L72DC:  lda     #$00
        sta     L7340
        jsr     L6F63
        beq     L72F6
L72E6:  jsr     L7007
        jsr     L6FD6
        bne     L72FA
        jsr     L6F76
        stx     L7340
        bne     L72E6
L72F6:  lda     #$00
        beq     L72CC
L72FA:  lda     $AC
        and     #$01
        bne     L7323
        jsr     L7093
        jsr     L6FD6
        beq     L7323
        lda     L7340
        bne     L731F
        lda     $AC
        and     #$02
        beq     L731F
        jsr     L70A7
        jsr     L6FD6
        beq     L731F
        lda     #$05
        bne     L7338
L731F:  lda     #$03
        bne     L7338
L7323:  lda     L7340
        bne     L733C
        lda     $AC
        and     #$04
        beq     L733C
        jsr     L708D
        jsr     L6FD6
        beq     L733C
        lda     #$04
L7338:  ldx     $AB
        bne     L72CE
L733C:  lda     #$02
        bne     L7338
L7340:  .byte   0
L7341:  copy16  L0080, $A9
        ldy     #$00
        lda     ($A9),y
        bne     L7354
        lda     #$9D
        jmp     L40AB

L7354:  sta     $82
        jsr     L6FB3
        beq     L7360
        lda     #$9C
        jmp     L40AB

L7360:  copy16  L0080, $A9
        ldy     #$0A
        lda     ($A9),y
        ora     #$80
        sta     ($A9),y
        bmi     L7383
        jsr     L6FC4
        cmp     L6F5B
        bne     L7380
        cpx     L6F5C
        bne     L7380
        rts

L7380:  jsr     L73BA
L7383:  ldy     #$38
        lda     L6F5B
        sta     ($A9),y
        iny
        lda     L6F5C
        sta     ($A9),y
        lda     $A9
        pha
        lda     $AA
        pha
        jsr     L650C
        jsr     L6558
        jsr     L6F63
        beq     L73A4
        jsr     L7135
L73A4:  pla
        sta     L6F5C
        pla
        sta     L6F5B
        jsr     L6F63
        lda     $AB
        sta     L6F5D
        jsr     L70DE
        jmp     L6523

L73BA:  ldy     #$38
        lda     ($A9),y
        sta     ($A7),y
        iny
        lda     ($A9),y
        sta     ($A7),y
        rts

        jsr     L6FC4
        lda     $A9
        ldx     $AA
        ldy     #$01
        jmp     L5EAF

L73D2:  .byte   0
L73D3:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        jsr     L6FC4
        lda     $AB
        cmp     L6F60
        bne     L7405
        inc     L7737
L7405:  jsr     L650C
        jsr     L6558
        lda     L7737
        bne     L7416
        MGTK_CALL MGTK::SetPortBits, $7797
L7416:  jsr     L70DE
        jsr     L6558
        lda     L7737
        bne     L7427
        MGTK_CALL MGTK::SetPortBits, $7797
L7427:  jsr     L6F8E
        copy16  $F4, L73D2
        jsr     L748C
        php
        lda     L7450
        ldx     L7451
        jsr     L5E92
        asl     L5F0D
        plp
        bcc     L7448
        rts

L7448:  jsr     L7452
L744B:  lda     #$A2
        jmp     L40AB

L7450:  .byte   $D4
L7451:  .byte   $73
L7452:  jsr     L6225
        lda     L73D2
        ldx     L73D3
        stax    $F4
        jmp     L6537

        jsr     L40C2
        jsr     L6FC4
        lda     $83
        sta     L0080
        lda     $84
L746F           := * + 1
        sta     $81
L7470:  ldx     #$07
L7472:  lda     L656A,x
        sta     $D8,x
        dex
        bpl     L7472
        jsr     L748C
        bcc     L744B
        ldy     #$23
L7481:  lda     $D0,y
        sta     (L0080),y
        dey
        bpl     L7481
        jmp     L40B7

L748C:  jsr     L6FDD
        ldx     #$07
L7491:  lda     #$00
        sta     $9B,x
        lda     $C7,x
        sta     $92,x
        dex
        bpl     L7491
        jsr     L5099
        bcs     L74A2
        rts

L74A2:  ldy     #$14
L74A4:  lda     ($A9),y
        sta     $BC,y
        iny
        cpy     #$38
        bne     L74A4
        ldx     #$02
L74B0:  lda     $92,x
        sta     $D0,x
        lda     $93,x
        sta     $D1,x
        lda     $96,x
        sec
        sbc     $92,x
        sta     $82,x
        lda     $97,x
        sbc     $93,x
        sta     $83,x
        lda     $D8,x
        sec
        sbc     $9B,x
        sta     $D8,x
        lda     $D9,x
        sbc     $9C,x
        sta     $D9,x
        lda     $D8,x
        clc
        adc     $82,x
        sta     $DC,x
        lda     $D9,x
        adc     $83,x
        sta     $DD,x
        dex
        dex
        bpl     L74B0
        sec
        rts

        jsr     L6FC4
        lda     $A9
        clc
        adc     #$14
        sta     $A9
        bcc     L74F3
        inc     $AA
L74F3:  ldy     #$23
L74F5:  lda     ($82),y
        sta     ($A9),y
        dey
        cpy     #$10
        bcs     L74F5
        rts

        jsr     L6F63
        beq     L7508
        lda     $AB
        bne     L750A
L7508:  lda     #$00
L750A:  ldy     #$00
        sta     (L0080),y
        rts

L750F:  .byte   0
        jsr     L6F63
        beq     L755D
        jsr     L70A7
        jsr     L650F
        jsr     L6558
        lda     #$80
L7520:  sta     L750F
        lda     #$02
        jsr     L6890
        jsr     L624C
        MGTK_CALL MGTK::PaintRect, $00C7
        jsr     L6225
L7534:  jsr     L68B6
        cmp     #$02
        beq     L7551
        MGTK_CALL MGTK::MoveTo, $5FE6
        jsr     L6FD6
        eor     L750F
        bpl     L7534
        lda     L750F
        eor     #$80
        jmp     L7520

L7551:  jsr     L6526
        ldy     #$00
        lda     L750F
        beq     L755D
        lda     #$01
L755D:  sta     (L0080),y
        rts

        .byte   0
L7561:  .byte   0
L7562:  .byte   0
L7563:  .byte   0
L7564:  .byte   0
L7565:  .byte   0
L7566:  .byte   0
        .byte   0
        .byte   0
L7569:  .byte   0
L756A:  .byte   0
        .byte   0
        .byte   0
L756D:  .byte   0
        lda     #$80
L7570:  bmi     L7574
        lda     #$00
L7574:  sta     L756D
        jsr     L7D88
        ldx     #$03
L757C:  lda     $83,x
        sta     L7561,x
        sta     L7565,x
        lda     #$00
        sta     L7569,x
        dex
        bpl     L757C
        jsr     L6FC4
        bit     L7C2F
        bpl     L7597
        jsr     L8037
L7597:  jsr     L650C
        jsr     L7712
        lda     #$02
        jsr     L6890
        MGTK_CALL MGTK::SetPattern, $657A
L75A8:  jsr     L6F8E
        jsr     L760F
        jsr     L7007
        jsr     L6FCF
        jsr     L6225
L75B7:  jsr     L68B6
        cmp     #$02
        bne     L7601
        jsr     L6FCF
        bit     L7C3C
        bmi     L75D0
        ldx     #$03
L75C8:  lda     L7569,x
        bne     L75DA
        dex
        bpl     L75C8
L75D0:  jsr     L6523
        lda     #$00
L75D5:  ldy     #$05
        sta     (L0080),y
        rts

L75DA:  ldy     #$14
L75DC:  lda     $A3,y
        sta     ($A9),y
        iny
        cpy     #$24
        bne     L75DC
        jsr     L624C
        lda     $AB
        jsr     L7738
        jsr     L650C
        bit     L7C3C
        bvc     L75F9
        jsr     L8202
L75F9:  jsr     L6523
        lda     #$80
        jmp     L75D5

L7601:  jsr     L76A6
        beq     L75B7
        jsr     L624C
        jsr     L6FCF
        jmp     L75A8

L760F:  ldy     #$13
L7611:  lda     ($A9),y
        sta     $BB,y
        dey
        cpy     #$0B
        bne     L7611
        ldx     #$00
        stx     L820C
        bit     L756D
        bmi     L7643
L7625:  lda     $B7,x
        clc
        adc     L7569,x
        sta     $B7,x
        lda     $B8,x
        adc     L756A,x
        sta     $B8,x
        inx
        inx
        cpx     #$04
        bne     L7625
        lda     #$12
        cmp     $B9
        bcc     L7642
        sta     $B9
L7642:  rts

L7643:  lda     #$00
        sta     L82B0
L7648:  clc
        lda     $C3,x
        adc     L7569,x
        sta     $C3,x
        lda     $C4,x
        adc     L756A,x
        sta     $C4,x
        sec
        lda     $C3,x
        sbc     $BF,x
        sta     $82
        lda     $C4,x
        sbc     $C0,x
        sta     $83
        sec
        lda     $82
        sbc     $C7,x
        lda     $83
        sbc     $C8,x
        bpl     L7682
        clc
        lda     $C7,x
        adc     $BF,x
        sta     $C3,x
        lda     $C8,x
        adc     $C0,x
        sta     $C4,x
        jsr     L82B1
        jmp     L769D

L7682:  sec
        lda     $CB,x
        sbc     $82
        lda     $CC,x
        sbc     $83
        bpl     L769D
        clc
        lda     $CB,x
        adc     $BF,x
        sta     $C3,x
        lda     $CC,x
        adc     $C0,x
        sta     $C4,x
        jsr     L82B1
L769D:  inx
        inx
        cpx     #$04
        bne     L7648
        jmp     L82B7

L76A6:  ldx     #$02
        ldy     #$00
L76AA:  lda     $84,x
        cmp     L7566,x
        bne     L76B2
        iny
L76B2:  lda     $83,x
        cmp     L7565,x
        bne     L76BA
        iny
L76BA:  sta     L7565,x
        sec
        sbc     L7561,x
        sta     L7569,x
        lda     $84,x
        sta     L7566,x
        sbc     L7562,x
        sta     L756A,x
        dex
        dex
        bpl     L76AA
        cpy     #$04
        bne     L76DA
        lda     L820C
L76DA:  rts

        jsr     L6FC4
        jsr     L650C
        jsr     L7712
        jsr     L73BA
        ldy     #$0A
        lda     ($A9),y
        and     #$7F
        sta     ($A9),y
        jsr     L6F63
        lda     $AB
        sta     L6F5D
        lda     #$00
        jmp     L7738

L76FC:  jsr     L6F63
        beq     L770F
        ldy     #$0A
        lda     ($A9),y
        and     #$7F
        sta     ($A9),y
        jsr     L73BA
        jmp     L76FC

L770F:  jmp     L6432

L7712:  jsr     L6558
        jsr     L7007
        ldx     #$07
L771A:  lda     $C7,x
        sta     $92,x
        dex
        bpl     L771A
        jsr     L5099
        ldx     #$03
L7726:  lda     $92,x
        sta     L779F,x
        sta     L7797,x
        lda     $96,x
        sta     L77A3,x
        dex
        bpl     L7726
        rts

L7737:  .byte   0
L7738:  sta     L6F60
        lda     #$00
        sta     L7737
        MGTK_CALL MGTK::SetPortBits, $7797
        lda     #$00
        jsr     L6890
        MGTK_CALL MGTK::SetPattern, $657A
        MGTK_CALL MGTK::PaintRect, $779F
        jsr     L6523
        jsr     L6F63
        beq     L7790
        php
        sei
        jsr     L6773
L7764:  jsr     L6F76
        bne     L7764
L7769:  jsr     L677F
        bcs     L778F
        tax
        lda     #$06
        sta     L66EF,x
        lda     $AB
        sta     L66F0,x
        lda     $AB
        cmp     L6F5D
        beq     L778F
        sta     $82
        jsr     L6FB3
        lda     $A7
        ldx     $A8
        jsr     L6F94
        jmp     L7769

L778F:  plp
L7790:  rts

L7791:  php
        .byte   0
L7793:  .byte   $0C
        .byte   0
L7795:
L7797           := * + 2
        ora     a:L0000
        .byte   0
L7799:  ora     a:L0000
        jsr     L0080
L779F:  .byte   0
        .byte   0
        .byte   0
        .byte   0
L77A3:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        jsr     L6FC4
        ldx     #$02
L77AC:  lda     $83,x
        clc
        adc     $B7,x
        sta     $83,x
        lda     $84,x
        adc     $B8,x
        sta     $84,x
        dex
        dex
        bpl     L77AC
        bmi     L77D5
        jsr     L6FC4
        ldx     #$02
L77C4:  lda     $83,x
        sec
        sbc     $B7,x
        sta     $83,x
        lda     $84,x
        sbc     $B8,x
        sta     $84,x
        dex
        dex
        bpl     L77C4
L77D5:  ldy     #$05
L77D7:  lda     $7E,y
        sta     (L0080),y
        iny
        cpy     #$09
        bne     L77D7
        rts

L77E2:  stax    $82
        ldy     #$03
L77E8:  lda     #$00
        sta     $8A,y
        lda     ($82),y
        sta     $92,y
        dey
        bpl     L77E8
        iny
        sty     $91
        ldy     #$04
        lda     ($82),y
        tax
        lda     L481A,x
        sta     $90
        txa
        ldx     $93
        clc
        adc     $92
        bcc     L780B
        inx
L780B:  stax    $96
        iny
        lda     ($82),y
        ldx     $95
        clc
        adc     $94
        bcc     L781A
        inx
L781A:  stax    $98
        iny
        lda     ($82),y
        sta     $8E
        iny
        lda     ($82),y
        sta     $8F
        jmp     L51A3

        lda     $8C
        cmp     #$01
        bne     L7837
        lda     #$80
        sta     $8C
        bne     L7842
L7837:  cmp     #$02
        bne     L7841
        lda     #$00
        sta     $8C
        beq     L7842
L7841:  rts

L7842:  jsr     L650C
        jsr     L6F63
        bit     $8C
        bpl     L7852
        lda     $B0
        ldy     #$05
        bne     L7856
L7852:  lda     $AF
        ldy     #$04
L7856:  eor     $8D
        and     #$01
        eor     ($A9),y
        sta     ($A9),y
        lda     $8D
        jsr     L7866
        jmp     L6523

L7866:  bne     L7875
        jsr     L78B7
        jsr     L654E
        MGTK_CALL MGTK::PaintRect, $00C7
        rts

L7875:  bit     $8C
        bmi     L787E
        bit     $AF
L787C           := * + 1
        bmi     L7882
L787D:  rts

L787E:  bit     $B0
        bpl     L787D
L7882:  jsr     L654E
        jsr     L78B7
        MGTK_CALL MGTK::SetPattern, $78AD
        MGTK_CALL MGTK::PaintRect, $00C7
        MGTK_CALL MGTK::SetPattern, $5F20
        bit     $8C
        bmi     L78A3
        bit     $AF
        bvs     L78A7
L78A2:  rts

L78A3:  bit     $B0
        bvc     L78A2
L78A7:  jsr     L7939
        jmp     L699D

        cmp     $DD77,x
        .byte   $77
        cmp     $DD77,x
        .byte   $77
        .byte   0
        .byte   0
L78B7:  bit     $8C
        bpl     L78FA
        jsr     L7054
        lda     $C9
        clc
        adc     #$0B
        sta     $C9
        bcc     L78C9
        inc     $CA
L78C9:  lda     $CD
        sec
        sbc     #$0B
        sta     $CD
        bcs     L78D4
        dec     $CE
L78D4:  lda     $AC
        and     #$04
        bne     L78DE
        bit     $AF
        bpl     L78E9
L78DE:  lda     $CD
        sec
        sbc     #$0B
        sta     $CD
        bcs     L78E9
        dec     $CE
L78E9:  inc16   $C7
L78EF:  lda     $CB
        bne     L78F5
        dec     $CC
L78F5:  dec     $CB
        jmp     L7936

L78FA:  jsr     L7079
        lda     $C7
        clc
        adc     #$15
        sta     $C7
        bcc     L7908
        inc     $C8
L7908:  lda     $CB
        sec
        sbc     #$15
        sta     $CB
        bcs     L7913
        dec     $CC
L7913:  lda     $AC
        and     #$04
        bne     L791D
        bit     $B0
        bpl     L7928
L791D:  lda     $CB
        sec
        sbc     #$15
        sta     $CB
        bcs     L7928
        dec     $CC
L7928:  inc16   $C9
L792E:  lda     $CD
        bne     L7934
        dec     $CE
L7934:  dec     $CD
L7936:  jmp     L7002

L7939:  jsr     L78B7
        jsr     L7BA9
L7940           := * + 1
        jsr     L5687
        lda     $A1
        pha
        jsr     L7BC1
        jsr     L7B80
        pla
        tax
        lda     $A3
        ldy     $A4
        cpx     #$01
        beq     L795A
        ldx     $A0
        jsr     L7B59
L795A:  sta     $82
        sty     $83
        ldx     #$00
        lda     #$14
        bit     $8C
        bpl     L796A
        ldx     #$02
        lda     #$0C
L796A:  pha
        lda     $C7,x
        clc
        adc     $82
        sta     $C7,x
L7973           := * + 1
        lda     $C8,x
        adc     $83
        sta     $C8,x
        pla
        clc
        adc     $C7,x
        sta     $CB,x
        lda     $C8,x
        adc     #$00
        sta     $CC,x
        jmp     L7002

        jsr     L650F
        jsr     L6F63
        bne     L7994
        lda     #$9F
        jmp     L40AB

L7994:  bit     $B0
        bpl     L79DB
        jsr     L7054
        jsr     L6FD6
        beq     L79DB
        ldx     #$00
        lda     $B0
        and     #$01
        beq     L79D7
        lda     #$80
        sta     $8C
        jsr     L78B7
        jsr     L6FD6
        beq     L79C4
        bit     $B0
        bcs     L7A36
        jsr     L7939
        jsr     L6FD6
        beq     L79C8
        ldx     #$05
        bne     L79D7
L79C4:  lda     #$01
        bne     L79CA
L79C8:  lda     #$03
L79CA:  pha
        jsr     L7939
        pla
        tax
        lda     $EC
        cmp     $C9
        bcc     L79D7
        inx
L79D7:  lda     #$01
        bne     L7A38
L79DB:  bit     $AF
        bpl     L7A2A
        jsr     L7079
        jsr     L6FD6
        beq     L7A2A
        ldx     #$00
        lda     $AF
        and     #$01
        beq     L7A26
        lda     #$00
        sta     $8C
        jsr     L78B7
        jsr     L6FD6
        beq     L7A0B
        bit     $AF
        bvc     L7A36
        jsr     L7939
        jsr     L6FD6
        beq     L7A0F
        ldx     #$05
        bne     L7A26
L7A0B:  lda     #$01
        bne     L7A11
L7A0F:  lda     #$03
L7A11:  pha
        jsr     L7939
        pla
        tax
        lda     $EB
        cmp     $C8
        bcc     L7A26
        bne     L7A25
        lda     $EA
        cmp     $C7
        bcc     L7A26
L7A25:  inx
L7A26:  lda     #$02
        bne     L7A38
L7A2A:  jsr     L6FDD
        jsr     L6FD6
        beq     L7A36
        lda     #$00
        beq     L7A38
L7A36:  lda     #$03
L7A38:  jmp     L72CE

L7A3B:  lda     $82
        cmp     #$01
        bne     L7A47
        lda     #$80
        sta     $82
        bne     L7A56
L7A47:  cmp     #$02
        bne     L7A51
        lda     #$00
        sta     $82
        beq     L7A56
L7A51:  lda     #$A3
        jmp     L40AB

L7A56:  jsr     L6F63
        bne     L7A60
        lda     #$9F
        jmp     L40AB

L7A60:  ldy     #$06
        bit     $82
        bpl     L7A68
        ldy     #$08
L7A68:  lda     $83
        sta     ($A9),y
        sta     $AB,y
        rts

        lda     $82
        cmp     #$01
        bne     L7A7C
        lda     #$80
        sta     $82
        bne     L7A8B
L7A7C:  cmp     #$02
        bne     L7A86
        lda     #$00
        sta     $82
        beq     L7A8B
L7A86:  lda     #$A3
        jmp     L40AB

L7A8B:  lda     $82
        sta     $8C
        ldx     #$03
L7A91:  lda     $83,x
        sta     L7561,x
        sta     L7565,x
        dex
        bpl     L7A91
        jsr     L6F63
        bne     L7AA6
        lda     #$9F
        jmp     L40AB

L7AA6:  jsr     L7939
        jsr     L650F
        jsr     L6558
        lda     #$02
        jsr     L6890
        MGTK_CALL MGTK::SetPattern, $78AD
        jsr     L624C
L7ABD:  jsr     L6FCF
        jsr     L6225
L7AC3:  jsr     L68B6
        cmp     #$02
        beq     L7B2C
        jsr     L76A6
        beq     L7AC3
        jsr     L624C
        jsr     L6FCF
        jsr     L6F63
        jsr     L7939
        ldx     #$00
        lda     #$14
        bit     $8C
        bpl     L7AE7
        ldx     #$02
        lda     #$0C
L7AE7:  sta     $82
        lda     $C7,x
        clc
        adc     L7569,x
        tay
        lda     $C8,x
        adc     L756A,x
        cmp     L7B7F
        bcc     L7B01
        bne     L7B07
        cpy     L7B7E
        bcs     L7B07
L7B01:  lda     L7B7F
        ldy     L7B7E
L7B07:  cmp     L7B7D
        bcc     L7B19
        bne     L7B13
        cpy     L7B7C
        bcc     L7B19
L7B13:  lda     L7B7D
        ldy     L7B7C
L7B19:  sta     $C8,x
        tya
        sta     $C7,x
        clc
        adc     $82
        sta     $CB,x
        lda     $C8,x
        adc     #$00
        sta     $CC,x
        jmp     L7ABD

L7B2C:  jsr     L624C
        jsr     L6FCF
        jsr     L6523
        jsr     L7B80
        jsr     L5687
        ldx     $A1
        jsr     L7BA9
        lda     $A3
        ldy     #$00
        cpx     #$01
        bcs     L7B4D
        ldx     $A0
        jsr     L7B59
L7B4D:  ldx     #$01
        cmp     $A1
        bne     L7B54
        dex
L7B54:  ldy     #$05
        jmp     L5EAF

L7B59:  sta     $82
        sty     $83
        lda     #$80
        sta     $84
        ldy     #$00
        sty     $85
        txa
        beq     L7B7B
L7B68:  add16   $82, $84, $84
        bcc     L7B78
        iny
L7B78:  dex
L7B7A           := * + 1
        bne     L7B68
L7B7B:  rts

L7B7C:  .byte   0
L7B7D:  .byte   0
L7B7E:  .byte   0
L7B7F:  .byte   0
L7B80:  sub16   L7B7C, L7B7E, $A3
        ldx     #$00
        bit     $8C
        bpl     L7B99
        ldx     #$02
L7B99:  lda     $C7,x
        sec
        sbc     L7B7E
        sta     $A1
        lda     $C8,x
        sbc     L7B7F
        sta     $A2
        rts

L7BA9:  ldy     #$06
        bit     $8C
        bpl     L7BB1
        ldy     #$08
L7BB1:  lda     ($A9),y
        sta     $A3
        iny
        lda     ($A9),y
        sta     $A1
        lda     #$00
        sta     $A2
        sta     $A4
        rts

L7BC1:  ldx     #$00
        lda     #$14
        bit     $8C
        bpl     L7BCD
        ldx     #$02
        lda     #$0C
L7BCD:  sta     $82
        lda     $C7,x
        ldy     $C8,x
        sta     L7B7E
        sty     L7B7F
        lda     $CB,x
        ldy     $CC,x
        sec
        sbc     $82
        bcs     L7BE3
        dey
L7BE3:  sta     L7B7C
        sty     L7B7D
        rts

        lda     $8C
        cmp     #$01
        bne     L7BF6
        lda     #$80
        sta     $8C
        bne     L7C05
L7BF6:  cmp     #$02
        bne     L7C00
        lda     #$00
        sta     $8C
        beq     L7C05
L7C00:  lda     #$A3
        jmp     L40AB

L7C05:  jsr     L6F63
        bne     L7C0F
        lda     #$9F
        jmp     L40AB

L7C0F:  ldy     #$07
        bit     $8C
        bpl     L7C17
        ldy     #$09
L7C17:  lda     $8D
        sta     ($A9),y
        jsr     L650C
        jsr     L654E
        jsr     L7866
        jmp     L6523

L7C27:  lda     #$80
        sta     L7C2F
        jmp     L6773

L7C2F:  .byte   0
L7C30:  .byte   0
L7C31:  .byte   0
L7C32:  .byte   0
        .byte   0
L7C34:  .byte   0
L7C35:  .byte   0
L7C36:  .byte   0
L7C37:  .byte   0
L7C38:  .byte   0
L7C39:  .byte   0
L7C3A:  .byte   0
L7C3B:  .byte   0
L7C3C:  .byte   0
L7C3D:  .byte   0
L7C3E:  ldx     #$7F
L7C40:  lda     L0080,x
        sta     L7C54,x
        dex
        bpl     L7C40
        rts

L7C49:  ldx     #$7F
L7C4B:  lda     L7C54,x
        sta     L0080,x
        dex
        bpl     L7C4B
        rts

L7C54:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L7CD4:  bit     L5FF1
        bmi     L7D04
        bit     L83D7
        bmi     L7D04
        pha
        txa
        sec
        jsr     L7D30
        ldx     L83D8
        sta     MOUSE_X_LO,x
        tya
        sta     MOUSE_X_HI,x
        pla
        ldy     #$00
        clc
        jsr     L7D30
        ldx     L83D8
        sta     MOUSE_Y_LO,x
        tya
        sta     MOUSE_Y_HI,x
        ldy     #$16
        jmp     L6305

L7D04:  stx     L5FEA
        sty     L5FEB
        sta     L5FEC
        bit     L5FF1
        bpl     L7D17
        ldy     #$16
        jmp     L6305

L7D17:  rts

L7D18:  ldx     L7C37
        ldy     L7C38
        lda     L7C39
        jmp     L7CD4

L7D24:  ldx     L7C30
        ldy     L7C31
        lda     L7C32
        jmp     L7CD4

L7D30:  bcc     L7D38
        ldx     L5FEF
        bne     L7D3D
L7D37:  rts

L7D38:  ldx     L5FF0
        beq     L7D37
L7D3D:  pha
        tya
        lsr     a
        tay
        pla
        ror     a
        dex
        bne     L7D3D
        rts

L7D47:  ldx     #$02
L7D49:  lda     L7C30,x
        sta     L5FEA,x
        dex
        bpl     L7D49
        rts

L7D53:  jsr     L7D47
        jmp     L7D24

L7D59:  jsr     L62AC
        ldx     #$02
L7D5E:  lda     L5FEA,x
        sta     L7C37,x
        dex
        bpl     L7D5E
        rts

L7D68:  jsr     L7DEB
        copy16  L7DE9, L0080
        jsr     L606D
        jsr     L7DF6
        lda     #$00
        sta     L7C2F
        lda     #$40
        sta     L5FEE
        jmp     L7D18

L7D88:  lda     #$00
        sta     L7C3C
        sta     L820C
        rts

L7D91:  lda     BUTN1
        asl     a
        lda     BUTN0
        and     #$80
        rol     a
        rol     a
        rts

L7D9D:  jsr     L7D91
        sta     L820B
L7DA3:  clc
        lda     CLR80COL
        bpl     L7DAF
        stx     KBDSTRB
        and     #$7F
        sec
L7DAF:  rts

L7DB0:  lda     L7C2F
        bne     L7DB6
        rts

L7DB6:  cmp     #$04
        beq     L7E03
        jsr     L7E6F
        lda     L7C2F
        cmp     #$01
        bne     L7DC7
        jmp     L7F08

L7DC7:  jmp     L811A

L7DCA:  jsr     L7DEB
        copy16  L6134, L7DE9
        copy16  L6057, L0080
        jsr     L606D
        jmp     L7DF6

L7DE9:  .byte   0
L7DEA:  .byte   0
L7DEB:  copy16  L0080, L7E01
        rts

L7DF6:  copy16  L7E01, L0080
L7E00:  rts

L7E01:  .byte   0
L7E02:  .byte   0
L7E03:  jsr     L7D91
        ror     a
L7E07:  ror     a
        ror     L7C3D
        lda     L7C3D
        sta     L5FEE
        lda     #$00
        sta     L6632
        jsr     L7DA3
        bcc     L7E1E
        jmp     L814D

L7E1E:  jmp     L7D53

L7E21:  pha
        lda     L7C2F
        bne     L7E5E
        pla
        cmp     #$03
        bne     L7E5D
        bit     L5FEE
        bmi     L7E5D
        lda     #$04
        sta     L7C2F
        ldx     #$0A
L7E38:  lda     SPKR
        ldy     #$00
L7E3D:  dey
        bne     L7E3D
        dex
        bpl     L7E38
L7E43:  jsr     L7D91
        cmp     #$03
        beq     L7E43
        sta     L6632
        lda     #$00
        sta     L7C3D
        ldx     #$02
L7E54:  lda     L5FE6,x
        sta     L7C30,x
        dex
        bpl     L7E54
L7E5D:  rts

L7E5E:  cmp     #$04
        bne     L7E6D
        pla
        and     #$01
        bne     L7E6C
        lda     #$00
        sta     L7C2F
L7E6C:  rts

L7E6D:  pla
        rts

L7E6F:  bit     L5FEE
        bpl     L7E7C
        lda     #$00
        sta     L7C2F
        jmp     L7D24

L7E7C:  lda     L5FEE
        pha
        lda     #$C0
        sta     L5FEE
        pla
        and     #$20
        beq     L7E99
        ldx     #$02
L7E8C:  lda     L5FEA,x
        sta     L7C30,x
        dex
        bpl     L7E8C
        stx     L7C34
        rts

L7E99:  jmp     L7D47

L7E9C:  php
        sei
        jsr     L7D59
        lda     #$01
        sta     L7C2F
        jsr     L7ECA
        lda     #$80
        sta     L5FEE
        jsr     L7DCA
        ldx     L7C35
        jsr     L6813
        lda     $AF
        sta     L6B10
        jsr     L6C5D
        lda     L7C36
        sta     L6B11
        jsr     L6DE1
        plp
        rts

L7ECA:  ldx     L7C35
        jsr     L6813
        clc
        lda     $B7
        adc     #$05
        sta     L7C30
        lda     $B8
        adc     #$00
        sta     L7C31
        ldy     L7C36
        lda     L67E2,y
        sta     L7C32
        lda     #$C0
        sta     L5FEE
        jmp     L7D53

L7EF0:  bit     L7C34
        bpl     L7F07
        lda     L6B11
        sta     L7C36
        ldx     L6B10
        dex
        stx     L7C35
        lda     #$00
        sta     L7C34
L7F07:  rts

L7F08:  jsr     L7C3E
        jsr     L7F11
        jmp     L7C49

L7F11:  jsr     L7D9D
        bcs     L7F17
        rts

L7F17:  pha
        jsr     L7EF0
        pla
        cmp     #$1B
        bne     L7F2E
        lda     #$00
        sta     L7C3B
        sta     L7C3A
        lda     #$80
        sta     L7C3C
        rts

L7F2E:  cmp     #$0D
        bne     L7F38
        jsr     L7D47
        jmp     L7D68

L7F38:  cmp     #$0B
        bne     L7F5E
L7F3C:  dec     L7C36
        bpl     L7F4C
        ldx     L7C35
        jsr     L6813
        ldx     $AA
        stx     L7C36
L7F4C:  ldx     L7C36
        beq     L7F5B
        dex
        jsr     L6859
        lda     $BF
        and     #$C0
        bne     L7F3C
L7F5B:  jmp     L7ECA

L7F5E:  cmp     #$0A
L7F61           := * + 1
        bne     L7F8B
L7F62:  inc     L7C36
        ldx     L7C35
        jsr     L6813
        lda     L7C36
        cmp     $AA
        bcc     L7F79
        beq     L7F79
        lda     #$00
        sta     L7C36
L7F79:  ldx     L7C36
        beq     L7F88
L7F7E:  dex
L7F7F:  jsr     L6859
        lda     $BF
        and     #$C0
        bne     L7F62
L7F88:  jmp     L7ECA

L7F8B:  cmp     #$15
        bne     L7FA6
        lda     #$00
        sta     L7C36
        inc     L7C35
        lda     L7C35
        cmp     $A8
        bcc     L7FA3
        lda     #$00
        sta     L7C35
L7FA3:  jmp     L7ECA

L7FA6:  cmp     #$08
        bne     L7FC0
        lda     #$00
        sta     L7C36
        dec     L7C35
        bmi     L7FB7
        jmp     L7ECA

L7FB7:  ldx     $A8
        dex
        stx     L7C35
        jmp     L7ECA

L7FC0:  jsr     L7FCB
        bcc     L7FCA
        lda     #$80
        sta     L7C3C
L7FCA:  rts

L7FCB:  sta     $C9
        lda     L820B
        and     #$03
        sta     $CA
        lda     L6B10
        pha
        lda     L6B11
        pha
        lda     #$C0
        jsr     L69CD
        beq     L7FF8
        stx     L7C3B
        lda     $B0
        bmi     L7FF8
        lda     $BF
        and     #$C0
        bne     L7FF8
        lda     $AF
        sta     L7C3A
        sec
        bcs     L7FF9
L7FF8:  clc
L7FF9:  pla
        sta     L6B11
        pla
        sta     L6B10
        sta     $C7
        rts

L8004:  plp
        sei
        jsr     L6C5A
        jsr     L7D68
        lda     L7C3A
        sta     $C7
        sta     L6B10
        lda     L7C3B
        sta     $C8
        sta     L6B11
        jsr     L6526
        lda     L7C3A
        beq     L802A
        jsr     L6A54
        lda     L7C3A
L802A:  sta     L6B10
        ldx     L7C3B
        stx     L6B11
        plp
        jmp     L5EAD

L8037:  php
        sei
        jsr     L7D59
        lda     #$80
        sta     L5FEE
        jsr     L7007
        bit     L756D
        bpl     L809F
        lda     $AC
        and     #$04
        beq     L8094
        ldx     #$00
L8051:  sec
        lda     $CB,x
        sbc     #$04
        sta     L7C30,x
        sta     L7561,x
        sta     L7565,x
        lda     $CC,x
        sbc     #$00
        sta     L7C31,x
        sta     L7562,x
        sta     L7566,x
        inx
        inx
        cpx     #$04
        bcc     L8051
        sec
        lda     #$2F
        sbc     L7561
        lda     #$02
        sbc     L7562
        bmi     L8094
        sec
        lda     #$BF
        sbc     L7563
        lda     #$00
        sbc     L7564
        bmi     L8094
        jsr     L7D53
        jsr     L7DCA
        plp
        rts

L8094:  lda     #$00
        sta     L7C2F
        lda     #$A1
        plp
        jmp     L40AB

L809F:  lda     $AC
        and     #$01
        beq     L80AF
        lda     #$00
        sta     L7C2F
        lda     #$A0
        jmp     L40AB

L80AF:  ldx     #$00
L80B1:  clc
        lda     $C7,x
        cpx     #$02
        beq     L80BD
        adc     #$14
        jmp     L80BF

L80BD:  adc     #$05
L80BF:  sta     L7C30,x
        sta     L7561,x
        sta     L7565,x
        lda     $C8,x
        adc     #$00
        sta     L7C31,x
        sta     L7562,x
        sta     L7566,x
        inx
        inx
        cpx     #$04
        bcc     L80B1
        bit     L7C31
        bpl     L80F0
        ldx     #$01
        lda     #$00
L80E4:  sta     L7C30,x
        sta     L7561,x
        sta     L7565,x
        dex
        bpl     L80E4
L80F0:  jsr     L7D53
        jsr     L7DCA
        plp
        rts

L80F8:  php
        clc
        adc     L7C32
        sta     L7C32
        plp
        bpl     L810F
        cmp     #$C0
        bcc     L810C
        lda     #$00
        sta     L7C32
L810C:  jmp     L7D53

L810F:  cmp     #$C0
        bcc     L810C
        lda     #$BF
        sta     L7C32
        bne     L810C
L811A:  jsr     L7C3E
        jsr     L8123
        jmp     L7C49

L8123:  jsr     L7D9D
        bcs     L8129
        rts

L8129:  cmp     #$1B
        bne     L8135
        lda     #$80
        sta     L7C3C
        jmp     L7D68

L8135:  cmp     #$0D
        bne     L813C
        jmp     L7D68

L813C:  pha
        lda     L820B
        beq     L8147
        ora     #$80
        sta     L820B
L8147:  pla
        ldx     #$C0
        stx     L5FEE
L814D:  cmp     #$0B
        bne     L815D
        lda     #$F8
        bit     L820B
        bpl     L815A
        lda     #$D0
L815A:  jmp     L80F8

L815D:  cmp     #$0A
        bne     L816D
        lda     #$08
        bit     L820B
        bpl     L816A
        lda     #$30
L816A:  jmp     L80F8

L816D:  cmp     #$15
        bne     L81A8
        jsr     L8255
        bcc     L81A5
        clc
        lda     #$08
        bit     L820B
        bpl     L8180
        lda     #$40
L8180:  adc     L7C30
        sta     L7C30
        lda     L7C31
        adc     #$00
        sta     L7C31
        sec
        lda     L7C30
        sbc     #$2F
        lda     L7C31
        sbc     #$02
        bmi     L81A5
        lda     #$02
        sta     L7C31
        lda     #$2F
        sta     L7C30
L81A5:  jmp     L7D53

L81A8:  cmp     #$08
        bne     L81D8
        jsr     L820D
        bcc     L81D5
        lda     L7C30
        bit     L820B
        bpl     L81BE
        sbc     #$40
        jmp     L81C0

L81BE:  sbc     #$08
L81C0:  sta     L7C30
        lda     L7C31
        sbc     #$00
        sta     L7C31
        bpl     L81D5
        lda     #$00
        sta     L7C30
        sta     L7C31
L81D5:  jmp     L7D53

L81D8:  sta     L820A
        ldx     #$23
L81DD:  lda     $A7,x
        sta     $0600,x
        dex
        bpl     L81DD
        lda     L820A
        jsr     L7FCB
        php
        ldx     #$23
L81EE:  lda     $0600,x
        sta     $A7,x
        dex
        bpl     L81EE
        plp
        bcc     L8201
        lda     #$40
        sta     L7C3C
        jmp     L7D68

L8201:  rts

L8202:  MGTK_CALL MGTK::PeekEvent, $8209
        rts

        .byte   $03
L820A:  .byte   0
L820B:  .byte   0
L820C:  .byte   0
L820D:  lda     L7C2F
        cmp     #$04
        beq     L8223
        lda     L7C30
        bne     L8223
        lda     L7C31
        bne     L8223
        bit     L756D
        bpl     L8225
L8223:  sec
        rts

L8225:  jsr     L7007
        lda     $CC
        bne     L823B
        lda     #$09
        bit     L820B
        bpl     L8235
        lda     #$41
L8235:  cmp     $CB
        bcc     L823B
        clc
        rts

L823B:  inc     L820C
        clc
        lda     #$08
        bit     L820B
        bpl     L8248
        lda     #$40
L8248:  adc     L7561
        sta     L7561
        bcc     L8253
        inc     L7562
L8253:  clc
        rts

L8255:  lda     L7C2F
        cmp     #$04
        beq     L826E
        bit     L756D
        bmi     L826E
        lda     L7C30
        sbc     #$2F
        lda     L7C31
        sbc     #$02
        beq     L8270
        sec
L826E:  sec
        rts

L8270:  jsr     L7007
        sec
        lda     #$2F
        sbc     $C7
        tax
        lda     #$02
        sbc     $C8
        beq     L8281
        ldx     #$FF
L8281:  bit     L820B
        bpl     L828C
        cpx     #$55
        bcc     L8292
        bcs     L8294
L828C:  cpx     #$1D
        bcc     L8292
        bcs     L829D
L8292:  clc
        rts

L8294:  sec
        lda     L7561
        sbc     #$40
        jmp     L82A3

L829D:  sec
        lda     L7561
        sbc     #$08
L82A3:  sta     L7561
        bcs     L82AB
        dec     L7562
L82AB:  inc     L820C
        clc
        rts

L82B0:  .byte   0
L82B1:  lda     #$80
        sta     L82B0
L82B6:  rts

L82B7:  bit     L7C2F
        bpl     L82B6
        bit     L82B0
        bpl     L82B6
        jsr     L7007
        php
        sei
        ldx     #$00
L82C8:  sec
        lda     $CB,x
        sbc     #$04
        sta     L7C30,x
        lda     $CC,x
        sbc     #$00
        sta     L7C31,x
        inx
        inx
        cpx     #$04
        bcc     L82C8
        jsr     L7D53
        plp
        rts

        copy16  $82, L5FEF
L82EC:  bit     L83D7
        bmi     L8367
        lda     L5FEF
        asl     a
        tay
        lda     #$00
        sta     L5FEA
        sta     L5FEB
        bit     L5FF1
        bmi     L8309
        sta     CLAMP_MIN_LO
        sta     CLAMP_MIN_HI
L8309:  lda     L8368,y
        sta     L5FEC
        bit     L5FF1
        bmi     L8317
        sta     CLAMP_MAX_LO
L8317:  lda     L8369,y
        sta     L5FED
        bit     L5FF1
        bmi     L8325
        sta     CLAMP_MAX_HI
L8325:  lda     #$00
        ldy     #$17
        jsr     L6305
        lda     L5FF0
        asl     a
        tay
        lda     #$00
        sta     L5FEA
        sta     L5FEB
        bit     L5FF1
        bmi     L8344
        sta     CLAMP_MIN_LO
        sta     CLAMP_MIN_HI
L8344:  lda     L8370,y
        sta     L5FEC
        bit     L5FF1
        bmi     L8352
        sta     CLAMP_MAX_LO
L8352:  lda     L8371,y
        sta     L5FED
        bit     L5FF1
        bmi     L8360
        sta     CLAMP_MAX_HI
L8360:  lda     #$01
        ldy     #$17
        jsr     L6305
L8367:  rts

L8368:  .byte   $2F
L8369:  .byte   $02
        .byte   $17
        ora     ($8B,x)
        .byte   0
        eor     L0000
L8370:  .byte   $BF
L8371:  .byte   0
        .byte   $5F
        .byte   0
        .byte   $2F
        .byte   0
        .byte   $17
        .byte   0
L8378:  txa
        and     #$7F
        beq     L8388
        jsr     L83AD
        sta     L83D7
        beq     L8399
        ldx     #$00
        rts

L8388:  ldx     #$07
L838A:  txa
        jsr     L83AD
        sta     L83D7
        beq     L8399
        dex
        bpl     L838A
        ldx     #$00
        rts

L8399:  ldy     #$19
        jsr     L6305
        jsr     L82EC
        ldy     #$18
        jsr     L6305
        lda     L83D8
        and     #$0F
        tax
        rts

L83AD:  ora     #$C0
        sta     $89
        lda     #$00
        sta     L0088
        ldy     #$0C
        lda     (L0088),y
        cmp     #$20
        bne     L83D4
        ldy     #$FB
        lda     (L0088),y
        cmp     #$D6
        bne     L83D4
        lda     $89
        sta     L83D8
        asl     a
        asl     a
        asl     a
        asl     a
L83D0           := * + 2
        sta     L83D9
        return  #$00

L83D4:  return  #$80

L83D7:  .byte   0
L83D8:  .byte   0
L83D9:  .byte   0
        .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
        .byte   $04
        ora     $05
        ora     $05
        ora     $05
        ora     $05
        ora     $05
        ora     $05
        ora     $05
        ora     $05
        asl     $06
        asl     $06
        asl     $06
        asl     $06
        asl     $06
        asl     $06
        .byte   0
        .byte   $52
        .byte   $54
        eor     $56,x
        .byte   $57
        cli
        eor     L5B5A,y
        .byte   $5C
        eor     L5F5E,x
        rts

        adc     ($62,x)
        .byte   $63
        .byte   $64
        adc     $66
        .byte   $67
        pla
        adc     #$6A
        .byte   $6B
        jmp     (L6E6D)

        .byte   $6F
        bvs     L8490
        .byte   $72
        .byte   $73
        .byte   $74
        adc     $76,x
        .byte   $77
        sei
        adc     L7B7A,y
        .byte   $7C
        adc     L7F7E,x
        .byte   $80
        sta     ($82,x)
        .byte   $83
        sty     $85
        stx     $87
        dey
        .byte   $89
        txa
        .byte   $8B
        sty     L8E8D
        .byte   $8F
        bcc     L83D0
        .byte   $92
        .byte   $93
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L8478:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L8490:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        jmp     (L0400)

        .byte   0
        tay
        .byte   0
        sbc     (L0000,x)
        .byte   0
        .byte   0
        .byte   $02
        .byte   0
        ldx     $E100,y
        .byte   0
        .byte   0
        .byte   0
        .byte   $02
        .byte   0
        inc     a:$03,x
L8617:  .byte   0
        .byte   0
        .byte   0
        tay
        .byte   $02
        .byte   0
        sta     L0000,x
        .byte   0
        .byte   0
        bpl     L867A
        .byte   $27
        tay
        .byte   $97
        .byte   0
        .byte   0
        .byte   0
        clc
        bpl     L862C
L862C:  inc     a:$9A
        .byte   0
        .byte   0
        rti

        bpl     L8634
L8634:  .byte   $62
        bne     L8617
        .byte   0
        .byte   0
        rti

        eor     (L0000,x)
L863C:  ror     $D0,x
        cpx     #$00
        .byte   0
        jsr     L17D5
        .byte   0
        inx
        ora     (L0000,x)
        .byte   0
        .byte   0
        .byte   $F3
        ora     (L0000,x)
        .byte   $D4
        .byte   0
        .byte   0
        .byte   0
        .byte   $80
L8652:  adc     a:$3C,x
        jsr     L0000
        .byte   0
        .byte   0
        .byte   0
        clc
        .byte   0
        bne     L8660
        .byte   0
L8660:  .byte   0
        .byte   0
        .byte   0
        bpl     L8665
L8665:  bne     L8668
        .byte   0
L8668:  .byte   0
        .byte   $80
        .byte   0
        .byte   0
        .byte   $5C
        .byte   $17
        sta     L0000,x
        ora     (L0000,x)
        .byte   0
        sta     $AF,x
        pla
        cpy     #$00
L8678:  pha
        .byte   $AF
L867A:  .byte   $83
        cpy     #$00
        .byte   $AF
        .byte   $83
        cpy     #$00
        .byte   $22
        .byte   $7F
        .byte   $FB
        ora     ($68,x)
        .byte   $8F
        pla
        cpy     #$00
        rti

        php
        sei
        clc
        .byte   $FB
        php
        .byte   $E2
        bmi     L863C
        .byte   0
        bcc     L8698
        lda     #$80
L8698:  .byte   $8F
        sbc     $95,x
        .byte   0
        .byte   $22
        .byte   $64
        .byte   0
        sbc     ($C2,x)
        bmi     L8652
        ldx     $E100,y
        bmi     L86DC
        ora     #$00
        .byte   $80
        .byte   $8F
        ldx     $E100,y
        pla
        pha
        .byte   $EB
        .byte   $E2
L86B4           := * + 1
        bmi     L86FD
        plp
        .byte   $E2
        bmi     L8668
        pla
        cpy     #$00
        .byte   $8F
        inc     $95,x
L86BF:  .byte   0
        and     #$04
        bne     L86CE
        .byte   $AF
        .byte   $8B
        cpy     #$00
        .byte   $AF
        .byte   $8B
        cpy     #$00
        .byte   $80
        php
L86CE:  .byte   $AF
        .byte   $83
        cpy     #$00
        .byte   $AF
        .byte   $83
        cpy     #$00
        .byte   $0B
        .byte   $8B
L86D8:  .byte   $5C
        .byte   0
        inx
L86DC           := * + 1
        ora     ($AF,x)
        inc     a:$95
        .byte   $8F
L86E2           := * + 1
        beq     L8678
        .byte   0
        lda     #$07
        .byte   0
        .byte   $8F
        inc     a:$95
        clc
        .byte   $A3
L86ED:  .byte   $03
        adc     #$06
        .byte   0
        .byte   $83
        .byte   $03
        bcc     L86FE
        .byte   $E2
        jsr     L05A3
        adc     #$00
        .byte   0
        .byte   $83
L86FD:
L86FE           := * + 1
        ora     L0080
        ora     $2BAB,y
        .byte   $C2
        bmi     L86B4
        inc     a:$95
        and     #$FF
        .byte   0
        bne     L8719
        .byte   $A3
        .byte   $02
        and     #$FE
        .byte   $FF
        ora     #$02
        .byte   0
        .byte   $83
        .byte   $02
        .byte   $80
        .byte   $0C
L8719:  .byte   $C2
        bmi     L86BF
        .byte   $02
        and     #$FD
        .byte   $FF
        ora     #$01
        .byte   0
        .byte   $83
        .byte   $02
        sei
        .byte   $E2
        bmi     L86D8
        inc     $95,x
        .byte   0
        .byte   $8F
        pla
        cpy     #$00
        .byte   $C2
        bmi     L86E2
        inc     a:$95
        and     #$FF
        .byte   0
        cmp     #$07
        .byte   0
        beq     L8749
        .byte   $AF
        ldx     $E100,y
        and     #$FF
        .byte   $7F
        .byte   $8F
        ldx     $E100,y
L8749:  .byte   $22
        pla
        .byte   0
        sbc     ($AF,x)
        inc     a:$95
        and     #$FF
        .byte   0
        pha
        .byte   $AF
        beq     L86ED
        .byte   0
        .byte   $8F
        inc     a:$95
        pla
        plp
        .byte   $FB
        plp
        .byte   $6B
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        sec
        .byte   $FB
        MLI_CALL CREATE, $9709
        php
        clc
        .byte   $FB
        plp
        .byte   $6B
        sec
        .byte   $FB
        MLI_CALL DESTROY, $9715
        php
        clc
        .byte   $FB
        plp
        .byte   $6B
        sec
        .byte   $FB
        MLI_CALL RENAME, $9718
        php
        clc
        .byte   $FB
        plp
        .byte   $6B
        sec
        .byte   $FB
        MLI_CALL SET_FILE_INFO, $971D
        php
        clc
        .byte   $FB
        plp
        .byte   $6B
        sec
        .byte   $FB
        MLI_CALL GET_FILE_INFO, $972B
        php
        clc
        .byte   $FB
        plp
        .byte   $6B
        sec
        .byte   $FB
        MLI_CALL ON_LINE, $973D
        php
        clc
        .byte   $FB
        plp
        .byte   $6B
        sec
        .byte   $FB
        MLI_CALL SET_PREFIX, $9741
        php
        clc
        .byte   $FB
        plp
        .byte   $6B
        sec
        .byte   $FB
        MLI_CALL OPEN, $9744
        php
        clc
        .byte   $FB
        plp
        .byte   $6B
        sec
        .byte   $FB
        MLI_CALL NEWLINE, $974A
        php
        clc
        .byte   $FB
        plp
        .byte   $6B
        sec
        .byte   $FB
        MLI_CALL READ, $974E
        php
        clc
        .byte   $FB
        plp
        .byte   $6B
        sec
        .byte   $FB
        MLI_CALL WRITE, $9756
        php
        clc
        .byte   $FB
        plp
        .byte   $6B
        sec
        .byte   $FB
        MLI_CALL $00, $097F
        .byte   $01,$07,$07,$07,$07,$07,$01,$07
        .byte   $07,$07,$07,$07,$07,$07,$07,$07
        .byte   $07,$03,$07,$06,$07,$07,$07,$07
        .byte   $07,$07,$07,$07,$07,$07,$07,$07
        .byte   $05,$03,$04,$07,$06,$06,$06,$02
        .byte   $03,$03,$06,$06,$04,$06,$03,$07
        .byte   $06,$06,$06,$06,$06,$06,$06,$06
        .byte   $06,$06,$03,$03,$05,$06,$05,$06
        .byte   $07,$07,$07,$07,$07,$07,$07,$07
        .byte   $07,$07,$07,$07,$07,$07,$07,$07
        .byte   $07,$07,$07,$07,$07,$07,$06,$07
        .byte   $07,$07,$07,$05,$06,$06,$04,$06
        .byte   $05,$07,$07,$06,$07,$06,$06,$06
        .byte   $06,$03,$05,$06,$03,$07,$06,$06
        .byte   $06,$06,$06,$06,$06,$06,$06,$07
        .byte   $06,$06,$06,$04,$02,$04,$05,$07
        .byte   $00,$00,$00,$3F,$77,$01,$01,$00
        .byte   $00,$7F,$00,$00,$7F,$30,$3E,$3E
        .byte   $00,$00,$3C,$00,$00,$00,$00,$00
        .byte   $14,$55,$2A,$00,$7F,$00,$10,$10
        .byte   $00,$03,$05,$12,$04,$03,$02,$01
        .byte   $02,$01,$00,$00,$00,$00,$00,$00
        .byte   $0E,$0C,$0E,$0E,$1B,$1F,$0E,$1F
        .byte   $0E,$0E,$00,$00,$00,$00,$00,$0E
        .byte   $00,$1E,$1F,$1E,$1F,$3F,$3F,$1E
        .byte   $33,$3F,$3E,$33,$03,$33,$33,$1E
        .byte   $1F,$1E,$1F,$1E,$3F,$33,$1B,$33
        .byte   $33,$33,$3F,$0F,$00,$0F,$02,$00
        .byte   $03,$00,$03,$00,$30,$00,$1C,$00
        .byte   $03,$03,$0C,$03,$03,$00,$00,$00
        .byte   $00,$00,$00,$00,$06,$00,$00,$00
        .byte   $00,$00,$00,$04,$01,$01,$05,$00
        .byte   $00,$3E,$00,$21,$1C,$03,$01,$00
        .byte   $00,$01,$08,$08,$40,$30,$41,$41
        .byte   $00,$00,$42,$00,$00,$00,$08,$00
        .byte   $14,$2A,$55,$00,$3F,$40,$08,$08
        .byte   $00,$03,$05,$12,$1E,$13,$05,$01
        .byte   $01,$02,$04,$04,$00,$00,$00,$30
        .byte   $1B,$0F,$1B,$1B,$1B,$03,$1B,$18
        .byte   $1B,$1B,$00,$00,$0C,$00,$03,$1B
        .byte   $1E,$33,$33,$33,$33,$03,$03,$33
        .byte   $33,$0C,$18,$1B,$03,$3F,$33,$33
        .byte   $33,$33,$33,$33,$0C,$33,$1B,$33
        .byte   $33,$33,$30,$03,$00,$0C,$05,$00
        .byte   $06,$00,$03,$00,$30,$00,$06,$00
        .byte   $03,$00,$00,$03,$03,$00,$00,$00
        .byte   $00,$00,$00,$00,$06,$00,$00,$00
        .byte   $00,$00,$00,$02,$01,$02,$0A,$00
        .byte   $00,$43,$01,$12,$08,$07,$01,$00
        .byte   $0C,$01,$08,$1C,$40,$30,$5D,$5D
        .byte   $77,$03,$04,$1F,$0C,$18,$1C,$0C
        .byte   $14,$55,$2A,$0C,$1F,$60,$36,$36
        .byte   $00,$03,$00,$3F,$05,$08,$05,$00
        .byte   $01,$02,$15,$04,$00,$00,$00,$18
        .byte   $1B,$0C,$18,$18,$1B,$0F,$03,$0C
        .byte   $1B,$1B,$03,$03,$06,$0F,$06,$18
        .byte   $21,$33,$33,$03,$33,$03,$03,$03
        .byte   $33,$0C,$18,$0F,$03,$3F,$37,$33
        .byte   $33,$33,$33,$03,$0C,$33,$1B,$33
        .byte   $1E,$33,$18,$03,$01,$0C,$00,$00
        .byte   $0C,$1E,$1F,$1E,$3E,$0E,$06,$0E
        .byte   $0F,$03,$0C,$1B,$03,$1F,$0F,$0E
        .byte   $0F,$1E,$0F,$1E,$1F,$1B,$1B,$23
        .byte   $1B,$1B,$1F,$02,$01,$02,$00
L8A02:  .byte   $00,$00,$43,$3F,$0C,$08,$0F,$01
        .byte   $00,$06,$01,$08,$3E,$40,$34,$45
        .byte   $55,$52,$02,$08,$0A,$00,$30,$36
        .byte   $12,$77,$2A,$55,$1E,$4E,$31,$7F
        .byte   $49,$00,$03,$00,$12,$0E,$04,$02
        .byte   $00,$01,$02,$0E,$1F,$00,$1F,$00
        .byte   $0C,$1B,$0C,$0C,$0C,$1F,$18,$0F
        .byte   $06,$0E,$1E,$00,$00,$03,$00,$0C
        .byte   $0C,$2D,$3F,$1F,$03,$33,$0F,$0F
        .byte   $3B,$3F,$0C,$18,$0F,$03,$33,$3B
        .byte   $33,$1F,$33,$1F,$1E,$0C,$33,$1B
        .byte   $33,$0C,$1E,$0C,$03,$02,$0C,$00
        .byte   $00,$00,$30,$33,$03,$33,$1B,$0F
        .byte   $1B,$1B,$03,$0C,$0F,$03,$2B,$1B
        .byte   $1B,$1B,$1B,$1B,$03,$06,$1B,$1B
        .byte   $2B,$0E,$1B,$18,$01,$01,$04,$00
        .byte   $2A,$00,$03,$30,$0C,$08,$1F,$01
        .byte   $7F,$7F,$01,$6B,$6B,$40,$36,$45
        .byte   $4D,$12,$02,$3E,$0A,$3F,$7F,$63
        .byte   $21,$00,$55,$2A,$3F,$64,$1B,$3F
        .byte   $21,$00,$03,$00,$12,$14,$02,$15
        .byte   $00,$01,$02,$15,$04,$00,$00,$00
        .byte   $06,$1B,$0C,$06,$18,$18,$18,$1B
        .byte   $03,$1B,$10,$00,$00,$06,$0F,$06
        .byte   $06,$3D,$33,$33,$03,$33,$03,$03
        .byte   $33,$33,$0C,$18,$0F,$03,$33,$33
        .byte   $33,$03,$33,$33,$30,$0C,$33,$1B
        .byte   $3F,$1E,$0C,$06,$03,$04,$0C,$00
        .byte   $00,$00,$3E,$33,$03,$33,$1F,$06
        .byte   $1B,$1B,$03,$0C,$07,$03,$2B,$1B
        .byte   $1B,$1B,$1B,$03,$0E,$06,$1B,$1B
        .byte   $2B,$04,$1B,$0C,$02,$01,$02,$00
        .byte   $14,$00,$03,$30,$12,$08,$3F,$01
        .byte   $00,$06,$01,$3E,$08,$40,$3F,$5D
        .byte   $55,$12,$02,$10,$0A,$00,$30,$7F
        .byte   $12,$77,$2A,$55,$1E,$71,$0E,$3F
        .byte   $21,$00,$00,$00,$3F,$0F,$19,$09
        .byte   $00,$01,$02,$04,$04,$00,$00,$00
        .byte   $03,$1B,$0C,$03,$1B,$18,$1B,$1B
        .byte   $03,$1B,$1B,$03,$03,$0C,$00,$03
        .byte   $00,$1D,$33,$33,$33,$33,$03,$03
        .byte   $33,$33,$0C,$1B,$1B,$03,$33,$33
        .byte   $33,$03,$33,$33,$33,$0C,$33,$0E
        .byte   $3F,$33,$0C,$03,$03,$08,$0C,$00
        .byte   $00,$00,$33,$33,$03,$33,$03,$06
        .byte   $1B,$1B,$03,$0C,$0F,$03,$2B,$1B
        .byte   $1B,$1B,$1B,$03,$18,$06,$1B,$0E
        .byte   $2B,$0E,$1B,$06,$02,$01,$02,$00
        .byte   $2A,$00,$03,$30,$2D,$08,$0D,$01
        .byte   $00,$0C,$01,$1C,$08,$40,$06,$41
        .byte   $41,$00,$00,$1A,$0A,$0C,$18,$00
        .byte   $0C,$14,$55,$2A,$0C,$7B,$04,$7E
        .byte   $6A,$00,$03,$00,$12,$04,$18,$16
        .byte   $00,$02,$01,$00,$00,$06,$00,$01
        .byte   $00,$0E,$1F,$1F,$0E,$18,$0E,$0E
        .byte   $03,$0E,$0E,$00,$03,$00,$00,$00
        .byte   $06,$01,$33,$1F,$1E,$1F,$3F,$03
        .byte   $1E,$33,$3F,$0E,$33,$3F,$33,$33
        .byte   $1E,$03,$1E,$33,$1E,$0C,$1E,$04
        .byte   $33,$33,$0C,$3F,$03,$10,$0C,$00
        .byte   $00,$00,$3F,$1F,$1E,$3E,$1E,$06
        .byte   $1E,$1B,$03,$0C,$1B,$03,$2B,$1B
        .byte   $0E,$0F,$1E,$03,$0F,$06,$1E,$04
        .byte   $1F,$1B,$1E,$1F,$04,$01,$01,$00
        .byte   $14,$00,$7F,$3F,$3F,$1C,$18,$01
        .byte   $00,$00,$01,$08,$08,$40,$04,$3E
        .byte   $3E,$00,$00,$4F,$00,$00,$00,$00
        .byte   $00,$14,$2A,$55,$00,$7F,$00,$36
        .byte   $36,$00,$00,$00,$12,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$06,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$01,$00,$00,$00
        .byte   $00,$3E,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$30,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$0F,$00,$0F,$00
        .byte   $1F,$00,$00,$00,$00,$00,$00,$00
        .byte   $18,$00,$00,$0C,$00,$00,$00,$00
        .byte   $00,$03,$18,$00,$00,$00,$00,$00
        .byte   $00,$00,$18,$00,$00,$00,$00,$00
        .byte   $2A,$00,$00,$00,$00,$77,$30,$01
        .byte   $00,$00,$7F,$00,$00,$7F,$00,$00
        .byte   $00,$00,$00,$7A,$00,$00,$00,$00
        .byte   $00,$14,$55,$2A,$00,$7F,$00,$00
        .byte   $00,$00,$00,$00
L8CA6:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$03,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$0E,$00,$00,$07
        .byte   $00,$00,$00,$00,$00,$03,$18,$00
        .byte   $00,$00,$00,$00,$00,$00,$0E,$00
        .byte   $00,$00,$00,$00,$00,$8D,$3F,$07
        .byte   $07,$07,$07,$07,$07,$07,$07,$07
        .byte   $07,$07,$07,$07,$07,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$10,$20
        .byte   $30,$40,$50,$60,$70,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$03,$03,$03
        .byte   $03,$03,$03,$03,$03,$04,$04,$04
        .byte   $04,$04,$04,$04,$04,$05,$05,$05
        .byte   $05,$05,$05,$05,$05,$06,$06,$06
        .byte   $06,$06,$06,$06,$06,$07,$07,$07
        .byte   $07,$07,$07,$07,$07,$08,$08,$08
        .byte   $08,$08,$08,$08,$08,$09,$09,$09
        .byte   $09,$09,$09,$09,$09,$0A,$0A,$0A
        .byte   $0A,$0A,$0A,$0A,$0A,$0B,$0B,$0B
        .byte   $0B,$0B,$0B,$0B,$0B,$0C,$0C,$0C
        .byte   $0C,$0C,$0C,$0C,$0C,$0D,$0D,$0D
        .byte   $0D,$0D
START:  jmp     L912A

        .byte   0
        ora     (L0002,x)
        .byte   $03
        .byte   $04
        ora     $06
        .byte   $07
L8E0B:  .byte   0
L8E0C:  .byte   0
L8E0D:  .byte   0
L8E0E:  .byte   0
L8E0F:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $03
        .byte   0
        ora     (L0000,x)
        .byte   $9B
        stx     L8E3B
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $02
        .byte   0
        sta     L5F8E,x
        stx     a:L0000
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $03
        .byte   0
        ldx     #$8E
        .byte   $6B
        stx     a:L0000
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L8E3B:  ora     L0000
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        tax
        stx     a:L0000
        .byte   0
        .byte   0
        .byte   $C7
        stx     a:L0000
        .byte   0
        .byte   0
        cmp     #$8E
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        inc     a:$8E
        .byte   0
        .byte   0
        .byte   0
        .byte   $12
        .byte   $8F
        ora     (L0000,x)
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        ora     (L0000,x)
        .byte   $52
        .byte   $72
        .byte   $27
        .byte   $8F
L8E6B:  ora     (L0000,x)
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        ora     (L0000,x)
L8E73:
L8E74           := * + 1
        bmi     L8EA5
        and     $018F,y
        .byte   0
L8E79:
L8E7A           := * + 1
        bmi     L8EAB
        eor     ($8F,x)
        ora     (L0000,x)
L8E7F:
L8E80           := * + 1
        bmi     L8EB1
        eor     #$8F
        ora     (L0000,x)
L8E85:
L8E86           := * + 1
        bmi     L8EB7
        eor     ($8F),y
        ora     (L0000,x)
L8E8B:
L8E8C           := * + 1
        bmi     L8EBD
L8E8D:  eor     $018F,y
        .byte   0
L8E91:
L8E92           := * + 1
        bmi     L8EC3
        adc     ($8F,x)
        ora     (L0000,x)
L8E97:
L8E98           := * + 1
        bmi     L8EC9
        adc     #$8F
        ora     ($1E,x)
        .byte   $04
        lsr     $69
        jmp     (L0765)

        .byte   $53
        .byte   $74
L8EA5:  adc     ($72,x)
        .byte   $74
        adc     $70,x
        .byte   $1C
L8EAB:  eor     ($70,x)
        bvs     L8F1B
        adc     WNDLFT
L8EB1:  eor     #$49
        jsr     L6544
        .byte   $73
L8EB7:  .byte   $6B
        .byte   $54
        .byte   $6F
        bvs     L8EDC
L8EBD           := * + 1
        lsr     $65,x
        .byte   $72
        .byte   $73
        adc     #$6F
L8EC3           := * + 1
        ror     $3120
        rol     $0131
L8EC9           := * + 1
        jsr     L4324
        .byte   $6F
        bvs     L8F47
        .byte   $72
        adc     #$67
        pla
        .byte   $74
        jsr     L7041
        bvs     L8F44
        adc     WNDLFT
        .byte   $43
        .byte   $6F
L8EDC:  adc     L7570
        .byte   $74
        adc     $72
        jsr     L6E49
        .byte   $63
        rol     $202C
        and     ($39),y
        sec
        rol     WNDLFT,x
        .byte   $23
        .byte   $43
        .byte   $6F
        bvs     L8F6C
        .byte   $72
        adc     #$67
        pla
        .byte   $74
        jsr     L6556
        .byte   $72
        .byte   $73
        adc     #$6F
        ror     L5320
        .byte   $6F
        ror     $74
        bit     $3120
        and     $3538,y
        jsr     L202D
        and     ($39),y
        sec
        rol     $14,x
        eor     ($6C,x)
        jmp     (L5220)

        adc     #$67
        pla
L8F1B:  .byte   $74
        .byte   $73
        jsr     L6572
        .byte   $73
        adc     $72
        ror     $65,x
        .byte   $64
        jsr     L5211
        adc     $6E,x
        jsr     L2061
        bvc     L8FA2
        .byte   $6F
        .byte   $67
        .byte   $72
        adc     ($6D,x)
        jsr     L2E2E
        rol     L5307
        jmp     (L746F)

L8F3F           := * + 1
        jsr     L2078
        .byte   $07
        .byte   $53
L8F44           := * + 1
        jmp     (L746F)

L8F47           := * + 1
        jsr     L2078
        .byte   $07
        .byte   $53
        jmp     (L746F)

L8F4F           := * + 1
        jsr     L2078
        .byte   $07
        .byte   $53
        jmp     (L746F)

L8F57           := * + 1
        jsr     L2078
        .byte   $07
        .byte   $53
        jmp     (L746F)

L8F5F           := * + 1
        jsr     L2078
        .byte   $07
        .byte   $53
        jmp     (L746F)

L8F67           := * + 1
        jsr     L2078
        .byte   $07
        .byte   $53
L8F6C           := * + 1
        jmp     (L746F)

L8F6F           := * + 1
        jsr     L2078
L8F71:  .byte   0
L8F72:  .byte   0
L8F73:  .byte   0
L8F74:  .byte   0
L8F75:  .byte   0
L8F76:  .byte   0
L8F77:  .byte   0
L8F78:  .byte   0
L8F79:  .byte   0
L8F7A:  .byte   0
L8F7B:  .byte   0
        .byte   0
        .byte   0
L8F7E:  .byte   0
L8F7F:  .byte   0
L8F80:  .byte   0
L8F81:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L8FA2:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L8FA7:  .byte   0
        tax
        .byte   $8F
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        asl     $EA
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        dey
        .byte   0
        php
        .byte   0
        php
L8FD9:  ora     ($01,x)
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        stx     L0000,y
        .byte   $32
        .byte   0
        .byte   $F4
        ora     ($8C,x)
        .byte   0
        ora     $2800,y
        .byte   0
        .byte   0
        jsr     L0080
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $F4
        ora     ($6E,x)
        .byte   0
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        ora     ($01,x)
        .byte   0
        .byte   $7F
        .byte   0
        dey
        .byte   0
        .byte   0
        .byte   $04
        .byte   0
        .byte   $02
        .byte   0
        beq     L901A
L901A           := * + 1
        jmp     (L5400)

        ora     ($5E,x)
        .byte   0
        clv
        ora     ($69,x)
        .byte   0
        .byte   $3C
        .byte   0
        lsr     LA000,x
        .byte   0
        adc     #$00
        cli
        ora     ($68,x)
        .byte   0
        .byte   $0F
        jsr     L4B4F
        jsr     L2020
        jsr     L2020
        jsr     L2020
        jsr     L0D20
        rti

        .byte   0
        pla
        .byte   0
        ora     (WNDLFT),y
        .byte   $44
        adc     HIMEM
        .byte   $6B
        .byte   $54
        .byte   $6F
        bvs     L906D
        jsr     L2020
        jsr     L2020
        eor     (WNDLFT),y
        .byte   $02
L9057           := * + 1
        ora     (L0000,x)
L9058:  .byte   0
        .byte   $0F
        .byte   0
        php
        .byte   $53
        adc     $6C
        adc     $63
        .byte   $74
        .byte   $6F
        .byte   $72
        ora     L0000
L9066:
L9067           := * + 1
        asl     L0000,x
        ora     L0000
        .byte   $14
        .byte   0
        .byte   $EF
L906D:  ora     ($14,x)
        .byte   0
        ora     L0000
        .byte   $5A
        .byte   0
        .byte   $EF
        ora     ($5A,x)
        .byte   0
L9078:  asl     a
L9079:  .byte   0
L907A:
L907B           := * + 1
L907C           := * + 2
        asl     a:L0000,x
L907D:  .byte   0
L907E:  .byte   0
L907F:  .byte   0
L9080:
L9081           := * + 1
        ora     L0000
L9082:
L9083           := * + 1
        ora     L0000,x
L9084:
L9085           := * + 1
        sty     L0000
L9086:
L9087           := * + 1
L9088           := * + 2
        ora     a:L0000,x
L9089:  .byte   0
L908A:  .byte   0
L908B:  .byte   0
L908C:  .byte   0
L908D:  .byte   0
L908E:  .byte   0
L908F:  .byte   0
        .byte   0
        .byte   $7F
        .byte   $03
        ldx     a:$90
        .byte   $BB
L9097:  .byte   0
        .byte   $04
L9099:  .byte   0
        .byte   0
        .byte   $B3
        .byte   0
        php
        .byte   0
        .byte   0
        .byte   $03
        ldy     a:$90,x
        .byte   $1C
L90A5:  .byte   0
        .byte   $04
L90A7:  .byte   0
        .byte   0
        jsr     L0400
        .byte   0
        .byte   0
        ora     L6553
        jmp     (L6365)

        .byte   $74
        .byte   $6F
        .byte   $72
        rol     L694C
        .byte   $73
        .byte   $74
        php
        .byte   $44
        adc     HIMEM
        .byte   $6B
        .byte   $54
        .byte   $6F
        bvs     L90F7
        ora     (L0000,x)
        .byte   $03
        cmp     a:$90
        php
L90CC:  .byte   0
        php
        .byte   $73
        adc     $6C
        adc     $63
        .byte   $74
        .byte   $6F
        .byte   $72
        .byte   $02
L90D7:  .byte   0
        rts

        .byte   $6F
        .byte   0
        .byte   $02
L90DC:  .byte   0
        rts

        stx     L0400
L90E1:  .byte   0
        .byte   0
        ldy     #$00
        .byte   $1F
        .byte   0
        .byte   0
        .byte   $04
L90E9:  .byte   0
        .byte   0
        ldy     #$00
        ora     a:L0000
        ora     (L0000,x)
        asl     a
        .byte   $04
        sta     (L0000),y
        .byte   0
L90F7:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        php
        .byte   $44
        adc     HIMEM
        .byte   $6B
        .byte   $54
        .byte   $6F
        bvs     L913F
L910D:  .byte   0
L910E:  .byte   0
        .byte   0
L9110:  .byte   0
L9111:  .byte   0
L9112:  .byte   0
L9113:  .byte   0
L9114:  .byte   0
L9115:  .byte   0
L9116:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L9127:  .byte   0
L9128:  .byte   0
L9129:  .byte   0
L912A:  cli
        lda     #$FF
        sta     L910E
        jsr     L97F7
        lda     #$01
        sta     L9129
        lda     L9128
        ora     L9127
L913F           := * + 1
        bne     L9151
L9140:  yax_call L95A0, $C4, $90F2
        beq     L914E
        jmp     L91B2

L914E:  jmp     L95B6

L9151:  lda     #$00
        sta     L92C1
        lda     CLR80COL
        bpl     L91B2
        sta     KBDSTRB
        and     #$7F
        bit     BUTN0
        bmi     L916A
        bit     BUTN1
        bpl     L917B
L916A:  cmp     #$31
        bcc     L917B
        cmp     #$38
        bcs     L917B
        sec
        sbc     #$30
        sta     L92C1
        jmp     L91B2

L917B:  cmp     #$51
        beq     L9140
        cmp     #$71
        beq     L9140
        sec
        sbc     #$31
        bmi     L91B2
        cmp     L9127
        bcs     L91B2
        sta     L910E
        jsr     L9A25
        stax    $06
        ldy     #$0F
        lda     ($06),y
        cmp     #$C0
        beq     L91AC
        jsr     L9EFC
        beq     L91B2
        jsr     L9DFF
        beq     L91AC
        jmp     L91B2

L91AC:  lda     L910E
        jsr     L9C07
L91B2:  sta     KBDSTRB
        lda     #$00
        sta     L9129
        jsr     L98E7
        ldx     #$01
L91BF:  cpx     #$03
        beq     L91DE
        cpx     #$02
        beq     L91DE
        ldy     $BF31
L91CA:  lda     $BF32,y
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     L91E5
        cpx     L91E5
        beq     L91E6
        dey
        bpl     L91CA
L91DE:  cpx     #$07
        beq     L91F2
        inx
        bne     L91BF
L91E5:  .byte   0
L91E6:  inc     L8F71
        ldy     L8F71
        sta     L8F71,y
        jmp     L91DE

L91F2:  lda     L92C1
        beq     L920D
        ldy     L8F71
L91FA:  cmp     L8F71,y
        beq     L9205
        dey
        bne     L91FA
        jmp     L920D

L9205:  ora     #$C0
        sta     L920C
L920C           := * + 2
        jmp     CLR80COL

L920D:  lda     L8F71
        sta     L8E6B
        lda     L8F72
        ora     #$30
        sta     L8F3F
        sta     L8E73
        sta     L8E74
        lda     L8F73
        ora     #$30
        sta     L8F47
        sta     L8E79
        sta     L8E7A
        lda     L8F74
        ora     #$30
        sta     L8F4F
        sta     L8E7F
        sta     L8E80
        lda     L8F75
        ora     #$30
        sta     L8F57
        sta     L8E85
        sta     L8E86
        lda     L8F76
        ora     #$30
        sta     L8F5F
        sta     L8E8B
        sta     L8E8C
        lda     L8F77
        ora     #$30
        sta     L8F67
        sta     L8E91
        sta     L8E92
        lda     L8F78
        ora     #$30
        sta     L8E97
        sta     L8E98
        sta     L8F6F
        MGTK_CALL MGTK::StartDeskTop, $8FCE
        MGTK_CALL MGTK::InitMenu, $8E15
        MGTK_CALL MGTK::SetCursor, $0000
        MGTK_CALL MGTK::GetEvent, $0000
        yax_call L95A0, $C4, $90F2
        beq     L929A
        lda     #$80
L929A:  sta     L910D
        MGTK_CALL MGTK::SetMark, $8FD9
        jsr     L9914
        lda     #$00
        sta     L9112
        sta     L9110
        lda     #$01
        sta     L9111
        lda     #$FF
        sta     L910E
        jsr     L97F7
        jsr     L97C6
        jmp     L92C2

L92C1:  .byte   0
L92C2:  bit     L9112
        bpl     L92D6
        dec     L9110
        bne     L92D6
        dec     L9111
        bne     L92D6
        lda     #$00
        sta     L9112
L92D6:  MGTK_CALL MGTK::CheckEvents, $8F79
        lda     L8F79
        cmp     #$01
        bne     L92E9
        jsr     L9451
        jmp     L92C2

L92E9:  cmp     #$03
        bne     L931C
        bit     L910D
        bmi     L9316
        lda     L8F7A
        and     #$7F
        cmp     #$51
        beq     L92FF
        cmp     #$71
        bne     L9316
L92FF:  yax_call L95A0, $C4, $90F2
        beq     L9313
        lda     #$FE
        jsr     L9F74
        bne     L9316
        beq     L92FF
L9313:  jmp     L95B6

L9316:  jsr     L937B
        jmp     L92C2

L931C:  cmp     #$06
        bne     L9323
        jsr     L9339
L9323:  jmp     L92C2

L9326:  MGTK_CALL MGTK::FlushEvents, $8F79
        lda     L8F79
        cmp     #$06
        bne     L9351
        MGTK_CALL MGTK::CheckEvents, $8F79
L9339:  jsr     L933F
        jmp     L9326

L933F:  MGTK_CALL MGTK::SetWinPort, $8F7A
        bne     L9351
        jsr     L9352
        MGTK_CALL MGTK::BeginUpdate, $0000
        rts

L9351:  rts

L9352:  jsr     L991A
        jsr     L97C6
        rts

L9359:
L935A           := * + 1
        lda     $95,x
        lda     $95,x
        lda     $95,x
        lda     $95,x
        lda     $95,x
        lda     $95,x
        lda     $95,x
        .byte   $F2
        .byte   $93
        lda     $BD9B,x
        .byte   $9B
        lda     $BD9B,x
        .byte   $9B
        lda     $BD9B,x
        .byte   $9B
L9377           := * + 2
        lda     a:$9B,x
        asl     $1E10
L937B:  lda     L8F7B
        bne     L938C
        lda     L8F7A
        and     #$7F
        cmp     #$1B
        beq     L93A5
L9389:  jmp     L95F5

L938C:  lda     L8F7A
        and     #$7F
        cmp     #$1B
        beq     L93A5
        cmp     #$52
        beq     L93A5
        cmp     #$72
        beq     L93A5
        cmp     #$3A
        bcs     L9389
        cmp     #$31
        bcc     L9389
L93A5:  sta     L8E0E
        lda     L8F7B
        sta     L8E0F
        MGTK_CALL MGTK::MenuSelect, $8E0C
L93B4:  ldx     L8E0D
        beq     L93BE
        ldx     L8E0C
        bne     L93C1
L93BE:  jmp     L92C2

L93C1:  dex
        lda     L9377,x
        tax
        ldy     L8E0D
        dey
        tya
        asl     a
        sta     L93F0
        txa
        clc
        adc     L93F0
        tax
        lda     L9359,x
        sta     L93F0
        lda     L935A,x
        sta     L93F1
        jsr     L93EB
        MGTK_CALL MGTK::MenuKey, $8E0C
        rts

L93EB:  tsx
        stx     L8E0B
L93F0           := * + 1
L93F1           := * + 2
        jmp     L1234

        lda     L910E
        bmi     L93FF
        jsr     L9B42
        lda     #$FF
        sta     L910E
L93FF:  jsr     L98C1
        yax_call L95A0, $C8, $90C7
        bne     L9443
        lda     L90CC
        sta     L90D7
        sta     L90E1
        yax_call L95A0, $CE, $90D6
        yax_call L95A0, $CA, $90E0
        yax_call L95A0, $CC, $90F0
        jsr     LA000
        bne     L943F
L9436:  tya
        jsr     L9C1A
        jsr     LA003
        beq     L9436
L943F:  jsr     L97F7
        rts

L9443:  lda     #$FE
        jsr     L9F74
        bne     L9450
        jsr     L98C1
        jmp     L93FF

L9450:  rts

L9451:  MGTK_CALL MGTK::EndUpdate, $8F7A
        lda     L8F7E
        bne     L945D
        rts

L945D:  cmp     #$01
        bne     L946A
        MGTK_CALL MGTK::SetMenu, $8E0C
        jmp     L93B4

L946A:  cmp     #$02
        bne     L9472
        jmp     L9473

        rts

L9472:  rts

L9473:  lda     L8F7F
        cmp     L8FD9
        beq     L947C
        rts

L947C:  lda     L8FD9
        jsr     L9A15
        lda     L8FD9
        sta     L8F79
        MGTK_CALL MGTK::GrowWindow, $8F79
        MGTK_CALL MGTK::MoveTo, $8F7E
        MGTK_CALL MGTK::InRect, $901B
        cmp     #$80
        beq     L94A1
        jmp     L94B6

L94A1:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $901B
        jsr     L9E20
        bmi     L94B5
        jsr     L97BD
L94B5:  rts

L94B6:  bit     L910D
        bmi     L94F0
        MGTK_CALL MGTK::InRect, $9023
        cmp     #$80
        beq     L94C8
        jmp     L94F0

L94C8:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $9023
        jsr     L9E8E
        bmi     L94B5
L94D9:  yax_call L95A0, $C4, $90F2
        beq     L94ED
        lda     #$FE
        jsr     L9F74
        bne     L94B5
        beq     L94D9
L94ED:  jmp     L95B6

L94F0:  sub16   L8F7E, L9078, L8F7E
        sub16   L8F80, L9066, L8F80
        lda     L8F81
        bpl     L9527
        lda     L910E
        jsr     L9B42
        lda     #$FF
        sta     L910E
        rts

L9527:  lsr16   L8F80
        lsr16   L8F80
        lsr16   L8F80
        lda     L8F80
        cmp     #$08
        bcc     L954C
        lda     L910E
        jsr     L9B42
        lda     #$FF
        sta     L910E
        rts

L954C:  sta     L959D
        lda     #$00
        sta     L959F
        asl     L8F7E
        rol     L8F7F
        rol     L959F
        lda     L8F7F
        asl     a
        asl     a
        asl     a
        clc
        adc     L959D
        sta     L959E
        cmp     #$08
        bcc     L9571
        jmp     L9582

L9571:  cmp     L9127
        bcc     L9596
        lda     L910E
        jsr     L9B42
        lda     #$FF
        sta     L910E
        rts

L9582:  sec
        sbc     #$08
        cmp     L9128
        bcc     L9596
        lda     L910E
        jsr     L9B42
        lda     #$FF
        sta     L910E
        rts

L9596:  lda     L959E
        jsr     L9AFD
        rts

L959D:  .byte   0
L959E:  .byte   0
L959F:  .byte   0
L95A0:  sty     $95AE
        stax    $95AF
        php
        sei
        MLI_CALL $00, $0000
        plp
        and     #$FF
        rts

        rts

L95B6:  yax_call L95A0, $C8, $90A0
        lda     L90A5
        sta     L90A7
        sta     DHIRESOFF
        sta     TXTCLR
        sta     CLR80VID
        sta     SETALTCHAR
        sta     CLR80COL
        jsr     SETVID
        jsr     SETKBD
        jsr     INIT
        jsr     HOME
        yax_call L95A0, $CA, $90A6
        yax_call L95A0, $CC, $90C5
        jmp     L2000

L95F5:  lda     L8FD9
        jsr     L9A15
        lda     L8F7A
        and     #$7F
        cmp     #$1C
        bcs     L9607
        jmp     L9638

L9607:  cmp     #$31
        bcs     L960C
        rts

L960C:  cmp     #$39
        bcc     L9611
        rts

L9611:  sec
        sbc     #$31
        sta     L97BC
        cmp     L9127
        bcc     L961D
        rts

L961D:  lda     L910E
        bmi     L962E
        cmp     L97BC
        bne     L9628
        rts

L9628:  lda     L910E
        jsr     L9B42
L962E:  lda     L97BC
        sta     L910E
        jsr     L9B42
        rts

L9638:  cmp     #$0D
        bne     L9658
        lda     L8FD9
        jsr     L9A15
        MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $901B
        MGTK_CALL MGTK::PaintRect, $901B
        jsr     L97BD
        rts

L9658:  cmp     #$15
        beq     L965F
        jmp     L96B5

L965F:  lda     L9127
        bne     L966A
        lda     L9128
        bne     L966A
        rts

L966A:  lda     L910E
        bpl     L9678
        lda     #$00
        sta     L910E
        jsr     L9B42
        rts

L9678:  lda     L910E
        cmp     #$08
        bcc     L9682
        jmp     L969A

L9682:  cmp     L9128
        bcc     L9688
        rts

L9688:  clc
        adc     #$08
        pha
        lda     L910E
        jsr     L9B42
        pla
        sta     L910E
        jsr     L9B42
        rts

L969A:  cmp     L9128
        bcc     L96A0
        rts

L96A0:  lda     L910E
        clc
        adc     #$08
        pha
        lda     L910E
        jsr     L9B42
        pla
        sta     L910E
        jsr     L9B42
        rts

L96B5:  cmp     #$08
        beq     L96BC
        jmp     L96EA

L96BC:  lda     L910E
        bpl     L96C2
        rts

L96C2:  cmp     #$08
        bcs     L96C7
        rts

L96C7:  lda     L910E
        sec
        sbc     #$08
        cmp     #$08
        bcs     L96D7
        cmp     L9127
        bcc     L96D7
        rts

L96D7:  lda     L910E
        jsr     L9B42
        lda     L910E
        sec
        sbc     #$08
        sta     L910E
        jsr     L9B42
        rts

L96EA:  cmp     #$0B
        beq     L96F1
        jmp     L976B

L96F1:  lda     L910E
        bpl     L96F7
        rts

L96F7:  lda     L910E
        jsr     L9B42
        jsr     L9728
        lda     L910E
        cmp     #$08
        bcc     L970E
        sec
        sbc     #$08
        clc
        adc     L9127
L970E:  sec
        sbc     #$01
        bpl     L971D
        lda     L9127
        clc
        adc     L9128
        sec
        sbc     #$01
L971D:  tax
        lda     L974B,x
        sta     L910E
        jsr     L9B42
        rts

L9728:  ldx     #$00
L972A:  cpx     L9127
        beq     L9737
        txa
        sta     L974B,x
        inx
        jmp     L972A

L9737:  ldy     #$00
L9739:  cpy     L9128
        bne     L973F
        rts

L973F:  tya
        clc
        adc     #$08
        sta     L974B,x
        inx
        iny
        jmp     L9739

L974B:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L976B:  cmp     #$0A
        beq     L9770
        rts

L9770:  lda     L9127
        bne     L977B
        lda     L9128
        bne     L977B
        rts

L977B:  lda     L910E
        bpl     L9789
        lda     #$00
        sta     L910E
        jsr     L9B42
        rts

L9789:  lda     L910E
        jsr     L9B42
        jsr     L9728
        lda     L9127
        clc
        adc     L9128
        sta     L97BC
        ldx     #$00
L979E:  lda     L974B,x
        cmp     L910E
        beq     L97AA
        inx
        jmp     L979E

L97AA:  inx
        cpx     L97BC
        bne     L97B2
        ldx     #$00
L97B2:  lda     L974B,x
        sta     L910E
        jsr     L9B42
        rts

L97BC:  .byte   0
L97BD:  lda     L910E
        bmi     L97C5
        jsr     L9C07
L97C5:  rts

L97C6:  lda     #$00
        sta     L97F6
L97CB:  lda     L97F6
        cmp     L9127
        beq     L97DC
        jsr     L9AA2
        inc     L97F6
        jmp     L97CB

L97DC:  lda     #$00
        sta     L97F6
L97E1:  lda     L97F6
        cmp     L9128
        beq     L97F5
        clc
        adc     #$08
        jsr     L9AA2
        inc     L97F6
        jmp     L97E1

L97F5:  rts

L97F6:  .byte   0
L97F7:  yax_call L95A0, $C8, $9092
        lda     L9097
        sta     L9099
        yax_call L95A0, $CA, $9098
        yax_call L95A0, $CC, $90C5
        copy16  $B300, L9127
        rts

L9825:  yax_call L95A0, $C8, $90C7
        bne     L9855
        lda     L90CC
        sta     L90DC
        sta     L90E9
        yax_call L95A0, $CE, $90DB
        yax_call L95A0, $CA, $90E8
        yax_call L95A0, $CC, $90F0
        rts

L9855:  lda     #$FE
        jsr     L9F74
        beq     L9825
        rts

        .byte   0
        .byte   0
        .byte   $02
        .byte   0
        asl     L0000
        asl     $1E00
        .byte   0
        rol     L7E00,x
        .byte   0
        .byte   $1A
        .byte   0
        bmi     L986F
L986F:  bmi     L9871
L9871:  rts

        .byte   0
        .byte   0
        .byte   0
        .byte   $03
        .byte   0
        .byte   $07
        .byte   0
        .byte   $0F
        .byte   0
        .byte   $1F
        .byte   0
        .byte   $3F
        .byte   0
        .byte   $7F
        .byte   0
        .byte   $7F
        ora     ($7F,x)
        .byte   0
        sei
        .byte   0
        sei
        .byte   0
        bvs     L988C
L988C           := * + 1
        bvs     L988E
L988E           := * + 1
        ora     ($01,x)
        .byte   0
        .byte   0
        .byte   $7C
        .byte   $03
        .byte   $7C
        .byte   $03
        .byte   $02
        .byte   $04
        .byte   $42
        .byte   $04
        .byte   $32
        .byte   $0C
        .byte   $02
        .byte   $04
        .byte   $02
        .byte   $04
        .byte   $7C
        .byte   $03
        .byte   $7C
        .byte   $03
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   $7C
        .byte   $03
        ror     L7E07,x
        .byte   $07
        .byte   $7F
        .byte   $0F
        .byte   $7F
        .byte   $0F
        .byte   $7F
        .byte   $1F
        .byte   $7F
        .byte   $0F
        .byte   $7F
        .byte   $0F
        ror     L7E07,x
        .byte   $07
        .byte   $7C
        .byte   $03
        .byte   0
        .byte   0
        ora     $05
L98C1:  MGTK_CALL MGTK::ShowCursor, $0000
        MGTK_CALL MGTK::GetIntHandler, $988F
        MGTK_CALL MGTK::SetCursor, $0000
        rts

L98D4:  MGTK_CALL MGTK::ShowCursor, $0000
        MGTK_CALL MGTK::GetIntHandler, $985D
        MGTK_CALL MGTK::SetCursor, $0000
        rts

L98E7:  ldx     $BF31
L98EA:  lda     $BF32,x
        cmp     #$BF
        beq     L98F5
        dex
        bpl     L98EA
        rts

L98F5:  lda     $BF33,x
        sta     $BF32,x
        cpx     $BF31
        beq     L9904
        inx
        jmp     L98F5

L9904:  dec     $BF31
        rts

L9908:  inc     $BF31
        ldx     $BF31
        lda     #$BF
        sta     $BF32,x
        rts

L9914:  lda     L8FD9
        jsr     L9A15
L991A:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::SetPenSize, $9055
        MGTK_CALL MGTK::FrameRect, $9013
        MGTK_CALL MGTK::FrameRect, $901B
        bit     L910D
        bmi     L993D
        MGTK_CALL MGTK::FrameRect, $9023
L993D:  addr_call L999B, $905B
        jsr     L9968
        bit     L910D
        bmi     L994F
        jsr     L9976
L994F:  MGTK_CALL MGTK::MoveTo, $9068
        MGTK_CALL MGTK::LineTo, $906C
        MGTK_CALL MGTK::MoveTo, $9070
        MGTK_CALL MGTK::LineTo, $9074
        rts

L9968:  MGTK_CALL MGTK::MoveTo, $902B
        addr_call L9984, $902F
        rts

L9976:  MGTK_CALL MGTK::MoveTo, $903F
        addr_call L9984, $9043
        rts

L9984:  stax    $06
        ldy     #$00
        lda     ($06),y
        sta     $08
        inc16   $06
L9994:  MGTK_CALL MGTK::DrawText, $0006
        rts

L999B:  stax    $06
        ldy     #$00
        lda     ($06),y
        sta     $08
        inc16   $06
L99AB:  MGTK_CALL MGTK::TextWidth, $0006
        lsr16   $09
        lda     #$01
        sta     L99DB
        lda     #$F4
        lsr     L99DB
        ror     a
        sec
        sbc     $09
        sta     L9057
        lda     L99DB
        sbc     $0A
        sta     L9058
        MGTK_CALL MGTK::MoveTo, $9057
        MGTK_CALL MGTK::DrawText, $0006
        rts

L99DB:  .byte   0
        stx     $0B
        sta     $0A
        ldy     #$00
        lda     ($0A),y
        tay
        bne     L99E8
        rts

L99E8:  dey
        beq     L99ED
        bpl     L99EE
L99ED:  rts

L99EE:  lda     ($0A),y
        and     #$7F
        cmp     #$2F
        beq     L99FA
        cmp     #$2E
        bne     L99FE
L99FA:  dey
        jmp     L99E8

L99FE:  iny
        lda     ($0A),y
        and     #$7F
        cmp     #$41
        bcc     L9A10
        cmp     #$5B
        bcs     L9A10
        clc
        adc     #$20
        sta     ($0A),y
L9A10:  dey
        jmp     L99E8

        .byte   0
L9A15:  sta     L8FA7
        MGTK_CALL MGTK::GetWinPtr, $8FA7
        MGTK_CALL MGTK::SetPort, $8FAA
        rts

L9A25:  ldx     #$00
        stx     L9A46
        asl     a
        rol     L9A46
        asl     a
        rol     L9A46
        asl     a
        rol     L9A46
        asl     a
        rol     L9A46
        clc
        adc     #$02
        tay
        lda     L9A46
        adc     #$B3
        tax
        tya
        rts

L9A46:  .byte   0
L9A47:  ldx     #$00
        stx     L9A61
        lsr     a
        ror     L9A61
        lsr     a
        ror     L9A61
        pha
        lda     L9A61
        adc     #$82
        tay
        pla
        adc     #$B4
        tax
        tya
        rts

L9A61:  .byte   0
L9A62:  pha
        lsr     a
        lsr     a
        lsr     a
        pha
        ldx     #$00
        stx     L9AA1
        lsr     a
        ror     L9AA1
        tay
        lda     L9AA1
        clc
        adc     L9078
        sta     L907C
        tya
        adc     L9079
        sta     L907D
        pla
        asl     a
        asl     a
        asl     a
        sta     L9AA1
        pla
        sec
        sbc     L9AA1
        asl     a
        asl     a
        asl     a
        clc
        adc     L907A
        sta     L907E
        lda     #$00
        adc     L907B
        sta     L907F
        rts

L9AA1:  .byte   0
L9AA2:  pha
        jsr     L9A25
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L9AAF:  lda     ($06),y
        sta     L9116,y
        dey
        bne     L9AAF
        ldy     #$00
        lda     ($06),y
        clc
        adc     #$03
        sta     L9113
        pla
        pha
        cmp     #$08
        bcc     L9AD5
        lda     #$20
        sta     L9114
        sta     L9115
        sta     L9116
        jmp     L9AE5

L9AD5:  pla
        pha
        clc
        adc     #$31
        sta     L9114
        lda     #$20
        sta     L9115
        sta     L9116
L9AE5:  lda     L8FD9
        jsr     L9A15
        pla
        jsr     L9A62
        MGTK_CALL MGTK::MoveTo, $907C
        addr_call L9984, $9113
        rts

L9AFD:  cmp     L910E
        beq     L9B05
        jmp     L9B22

L9B05:  bit     L9112
        bpl     L9B17
        jsr     L9C07
        jsr     BELL1
        jsr     BELL1
        jsr     BELL1
        rts

L9B17:  lda     #$FF
        sta     L9112
        lda     #$1E
        sta     L9110
        rts

L9B22:  pha
        lda     L910E
        bmi     L9B2E
        lda     L910E
        jsr     L9B42
L9B2E:  pla
        sta     L910E
        jsr     L9B42
        lda     #$FF
        sta     L9112
        lda     #$1E
        sta     L9110
        jmp     L9B17

L9B42:  pha
        lsr     a
        lsr     a
        lsr     a
        sta     L9BBC
        asl     a
        asl     a
        asl     a
        sta     L9BBA
        pla
        sec
        sbc     L9BBA
        sta     L9BBB
        lda     #$00
        sta     L9BBA
        lda     L9BBC
        lsr     a
        ror     L9BBA
        pha
        lda     L9BBA
        clc
        adc     L9080
        sta     L9088
        pla
        pha
        adc     L9081
        sta     L9089
        lda     L9BBA
        clc
        adc     L9084
        sta     L908C
        pla
        adc     L9085
        sta     L908D
        lda     L9BBB
        asl     a
        asl     a
        asl     a
        pha
        clc
        adc     L9082
        sta     L908A
        lda     #$00
        adc     L9083
        sta     L908B
        pla
        clc
        adc     L9086
        sta     L908E
        lda     #$00
        adc     L9087
        sta     L908F
        MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $9088
        rts

L9BBA:  .byte   0
L9BBB:  .byte   0
L9BBC:  .byte   0
        ldy     L8E0D
        lda     L8F71,y
        ora     #$C0
        sta     L9BF4
        sta     ALTZPOFF
        lda     ROMIN2
        sta     TXTSET
        sta     LOWSCR
        sta     LORES
        sta     MIXCLR
        sta     DHIRESOFF
        sta     CLRALTCHAR
        sta     CLR80VID
        sta     CLR80COL
        jsr     SETVID
        jsr     SETKBD
        jsr     INIT
        jsr     HOME
L9BF4           := * + 2
        jmp     L0000

        asl     a
        jsr     L0002
L9BF9:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L9C07:  lda     L9129
        bne     L9C17
        jsr     L98C1
        lda     L910E
        bmi     L9C17
        jsr     L9B42
L9C17:  jmp     L9C1D

L9C1A:  jmp     L9C7E

L9C1D:  lda     L9129
        bne     L9C32
        bit     BUTN0
        bpl     L9C2A
        jmp     L9C78

L9C2A:  jsr     L9EFC
        bne     L9C32
        jmp     L9C78

L9C32:  lda     L910E
        jsr     L9A25
        stax    $06
        ldy     #$0F
        lda     ($06),y
        asl     a
        bmi     L9C78
        bcc     L9C65
        lda     L9129
        bne     L9C6F
        jsr     L9DFF
        beq     L9C6F
        jsr     L9825
        lda     L910E
        jsr     LA000
        pha
        jsr     L9326
        pla
        beq     L9C6F
        jsr     L98D4
        jmp     L9D44

L9C65:  lda     L9129
        bne     L9C6F
        jsr     L9DFF
        bne     L9C78
L9C6F:  lda     L910E
        jsr     L9F27
        jmp     L9C7E

L9C78:  lda     L910E
        jsr     L9A47
L9C7E:  stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L9C87:  lda     ($06),y
        sta     $0220,y
        dey
        bpl     L9C87
        yax_call L95A0, $C4, $9BF5
        beq     L9CB7
        tax
        lda     L9129
        bne     L9CB4
        txa
        pha
        jsr     L9F74
        tax
        pla
        cmp     #$45
        bne     L9CB4
        txa
        bne     L9CB4
        jsr     L98C1
        jmp     L9C78

L9CB4:  jmp     L9D44

L9CB7:  lda     L9BF9
        cmp     #$FC
        bne     L9CC4
        jsr     L9D61
        jmp     L9CD8

L9CC4:  cmp     #$06
        beq     L9CD8
        cmp     #$FF
        beq     L9CD8
        cmp     #$B3
        beq     L9CD8
        lda     #$00
        jsr     L9F74
        jmp     L9D44

L9CD8:  ldy     $0220
L9CDB:  lda     $0220,y
        cmp     #$2F
        beq     L9CEF
        dey
        bne     L9CDB
        lda     #$45
        jsr     L9F74
        bne     L9D44
        jmp     L9C1D

L9CEF:  dey
        tya
        pha
        iny
        ldx     #$00
L9CF5:  iny
        inx
        lda     $0220,y
        sta     $0280,x
        cpy     $0220
        bne     L9CF5
        stx     $0280
        pla
        sta     $0220
        addr_call L9DE4, $0220
        addr_call L9DE4, $0280
        jsr     L9908
        jsr     SETVID
        jsr     SETKBD
        jsr     INIT
        jsr     HOME
        sta     DHIRESOFF
        sta     TXTSET
        sta     LOWSCR
        sta     LORES
        sta     MIXCLR
        sta     CLRALTCHAR
        sta     CLR80VID
        sta     CLR80COL
        jsr     L0290
        jsr     L98E7
L9D44:  lda     L9129
        bne     L9D4E
        lda     #$FF
        sta     L910E
L9D4E:  rts

        asl     a
        .byte   0
        .byte   $1C
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L9D61:  ldx     $0220
L9D64:  lda     $0220,x
        cmp     #$2F
        beq     L9D71
        dex
        bne     L9D64
        jmp     L9DBA

L9D71:  dex
        stx     L9DD6
        stx     $1C00
L9D78:  lda     $0220,x
        sta     $1C00,x
        dex
        bne     L9D78
        inc     $1C00
        ldx     $1C00
        lda     #$2F
        sta     $1C00,x
L9D8C:  ldx     $1C00
        ldy     #$00
L9D91:  inx
        iny
        lda     L9DD7,y
        sta     $1C00,x
        cpy     L9DD7
        bne     L9D91
        stx     $1C00
        yax_call L95A0, $C4, $9D4F
        bne     L9DAD
        rts

L9DAD:  ldx     L9DD6
L9DB0:  lda     $1C00,x
        cmp     #$2F
        beq     L9DC8
        dex
        bne     L9DB0
L9DBA:  lda     #$FF
        jsr     L9F74
        jsr     L9D44
        jsr     L98D4
        pla
        pla
        rts

L9DC8:  cpx     #$01
        beq     L9DBA
        stx     $1C00
        dex
        stx     L9DD6
        jmp     L9D8C

L9DD6:  .byte   0
L9DD7:  .byte   $0C
        .byte   $42
        adc     (HIMEM,x)
        adc     #$63
        rol     L7973
        .byte   $73
        .byte   $74
        adc     $6D
L9DE4:  stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L9DED:  lda     ($06),y
        cmp     #$61
        bcc     L9DFB
        cmp     #$7B
        bcs     L9DFB
        and     #$DF
        sta     ($06),y
L9DFB:  dey
        bne     L9DED
        rts

L9DFF:  lda     L910E
        jsr     L9F27
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L9E0E:  lda     ($06),y
        sta     $0220,y
        dey
        bpl     L9E0E
        yax_call L95A0, $C4, $9BF5
        rts

L9E20:  lda     #$00
        sta     L9E8D
L9E25:  MGTK_CALL MGTK::CheckEvents, $8F79
        lda     L8F79
        cmp     #$02
        beq     L9E76
        lda     L8FD9
        sta     L8F79
        MGTK_CALL MGTK::GrowWindow, $8F79
        MGTK_CALL MGTK::MoveTo, $8F7E
        MGTK_CALL MGTK::InRect, $901B
        cmp     #$80
        beq     L9E56
        lda     L9E8D
        beq     L9E5E
        jmp     L9E25

L9E56:  lda     L9E8D
        bne     L9E5E
        jmp     L9E25

L9E5E:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $901B
        lda     L9E8D
        clc
        adc     #$80
        sta     L9E8D
        jmp     L9E25

L9E76:  lda     L9E8D
        beq     L9E7E
        return  #$FF

L9E7E:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $901B
        return  #$00

L9E8D:  .byte   0
L9E8E:  lda     #$00
        sta     L9EFB
L9E93:  MGTK_CALL MGTK::CheckEvents, $8F79
        lda     L8F79
        cmp     #$02
        beq     L9EE4
        lda     L8FD9
        sta     L8F79
        MGTK_CALL MGTK::GrowWindow, $8F79
        MGTK_CALL MGTK::MoveTo, $8F7E
        MGTK_CALL MGTK::InRect, $9023
        cmp     #$80
        beq     L9EC4
        lda     L9EFB
        beq     L9ECC
        jmp     L9E93

L9EC4:  lda     L9EFB
        bne     L9ECC
        jmp     L9E93

L9ECC:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $9023
        lda     L9EFB
        clc
        adc     #$80
        sta     L9EFB
        jmp     L9E93

L9EE4:  lda     L9EFB
        beq     L9EEC
        return  #$FF

L9EEC:  MGTK_CALL MGTK::SetPenMode, $8E05
        MGTK_CALL MGTK::PaintRect, $9023
        return  #$01

L9EFB:  .byte   0
L9EFC:  lda     LCBANK2
        lda     LCBANK2
        lda     $D3FF
        tax
        lda     ROMIN2
        txa
        rts

L9F0B:  stax    L9F1E
        lda     LCBANK2
        lda     LCBANK2
        ldx     $D3EE
L9F1A:  lda     $D3EE,x
L9F1E           := * + 1
L9F1F           := * + 2
        sta     L1234,x
        dex
        bpl     L9F1A
        lda     ROMIN2
        rts

L9F27:  sta     L9F72
        addr_call L9F0B, $0800
        lda     L9F72
        jsr     L9A47
        stax    $06
        ldy     #$00
        lda     ($06),y
        sta     L9F73
        tay
L9F43:  lda     ($06),y
        and     #$7F
        cmp     #$2F
        beq     L9F4E
        dey
        bne     L9F43
L9F4E:  dey
L9F4F:  lda     ($06),y
        and     #$7F
        cmp     #$2F
        beq     L9F5A
        dey
        bne     L9F4F
L9F5A:  dey
        ldx     $0800
L9F5E:  inx
        iny
        lda     ($06),y
        sta     $0800,x
        cpy     L9F73
        bne     L9F5E
        stx     $0800
        ldax    #$0800
        rts

L9F72:  .byte   0
L9F73:  .byte   0
L9F74:  pha
        jsr     BELL1
        pla
        tax
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        txa
        jsr     LD23E
        tax
        sta     ALTZPOFF
        sta     ROMIN2
        rts

        sta     $85,x
        .byte   $83
        lda     $9D
        sta     $94
        clc
        adc     $82
        sta     $98
        lda     $9E
        sta     $95
        adc     $83
        sta     $99
        lda     #$00
        sta     $9B
        sta     $9C
        sta     $9D
        lda     $8F
        sta     L0080
        jsr     L5099
        bcs     L9FB5
        rts

L9FB5:  jsr     L4DAE
        lda     $91
        asl     a
        ldx     $93
        beq     L9FC1
        adc     #$01
L9FC1:  ldx     $96
        beq     L9FC7
        adc     #$01
L9FC7:  sta     L5159
        sta     L5158
        lda     #$02
        sta     $81
        lda     #$00
        sec
        sbc     $9D
        clc
        adc     $8C
        sta     $8C
        lda     #$00
        sec
        sbc     $9B
        tax
        lda     #$00
        sbc     $9C
        tay
        txa
        clc
        adc     $8A
        tax
        tya
        adc     $8B
        jsr     L4E7F
        sta     $8A
        tya
        rol     a
        cmp     #$07
        ldx     #$01
        bcc     L9FFE
        dex
        sbc     #$07
L9FFE:  .byte   $8E
        .byte   $7C
