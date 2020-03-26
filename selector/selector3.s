; da65 V2.17 - Git 5ac11b5e
; Created:    2020-03-25 19:03:17
; Input file: orig/selector3
; Page:       1


        .setcpu "6502"

WNDLFT          := $0020                        ; Text window left
WNDWDTH         := $0021                        ; Text window width
WNDTOP          := $0022                        ; Text window top
WNDBTM          := $0023                        ; Text window bottom+1
CH              := $0024                        ; Cursor horizontal position
CV              := $0025                        ; Cursor vertical position
BASL            := $0028                        ; Text base address low
BASH            := $0029                        ; Text base address high
INVFLG          := $0032                        ; Normal/inverse(/flash)
PROMPT          := $0033                        ; Used by GETLN
RNDL            := $004E                        ; Random counter low
RNDH            := $004F                        ; Random counter high
HIMEM           := $0073                        ; Highest available memory address+1
FBUFFR          := $0100
IN              := $0200
MOUSE_X_LO      := $03B8
DOSWARM         := $03D0                        ; DOS warmstart vector
XFERSTARTLO     := $03ED
XFERSTARTHI     := $03EE
BRKVec          := $03F0                        ; Break vector
SOFTEV          := $03F2                        ; Vector for warm start
PWREDUP         := $03F4                        ; This must be = EOR #$A5 of SOFTEV+1
IRQ_VECTOR      := $03FE
MOUSE_Y_LO      := $0438
CLAMP_MIN_LO    := $0478
MOUSE_X_HI      := $04B8
CLAMP_MAX_LO    := $04F8
MOUSE_Y_HI      := $0538
CLAMP_MIN_HI    := $0578
CLAMP_MAX_HI    := $05F8
MOUSE_STATUS    := $06B8
MOUSE_MODE      := $0738
L103A           := $103A
L10F2           := $10F2
L1127           := $1127
L118B           := $118B
L223B           := $223B
L3000           := $3000
MGTK            := $4000
L523C           := $523C
L6874           := $6874
L6964           := $6964
L6E61           := $6E61
L7270           := $7270
FONT            := $8800
START           := $8E00
LA75E           := $A75E
LA839           := $A839
LA88F           := $A88F
LA8CB           := $A8CB
LA9B6           := $A9B6
LAA3A           := $AA3A
LAA5C           := $AA5C
LAAAE           := $AAAE
LAB37           := $AB37
LBCAB           := $BCAB
LBE70           := $BE70
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
        asl     $07C9
        bne     L1E3B
        lda     $BE54
        and     #$08
        bne     L1E36
        return  #$06

L1E36:  jmp     (LBCAB)

        lda     #$10
L1E3B:  sec
        rts

        lda     $BE61
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        pha
        lda     $BE62
        eor     #$01
        lsr     a
        pla
        ror     a
        sta     $BEC7
        copy16  #$0201, $BEC8
        lda     #$C5
        jsr     LBE70
        bcs     L1E3B
        lda     $BE62
        sta     $BE3D
        lda     $BE61
        sta     $BE3C
        lda     $BCBD
        eor     #$2F
        beq     L1EE6
        lda     $0201
        and     #$0F
        adc     #$02
        sta     $0201
        adc     $BCBC
        cmp     #$40
        tax
        lda     #$10
        bcs     L1EE7
        ldy     $BCBC
        stx     $BCBC
        dex
        dey
        bmi     L1E9C
        lda     $BCBD,y
        sta     $BCBD,x
        jmp     LA88F

L1E9C:  lda     #$2F
        sta     $BCBD
L1EA1:  sta     $BCBD,x
        lda     IN,x
        dex
        bne     L1EA1
        lda     $BE53
        cmp     #$0B
        beq     L1EE6
        cmp     #$16
        beq     L1EE6
        cmp     #$08
        beq     L1EE6
        lda     $0280
        tay
        clc
        adc     $0201
        cmp     #$40
        tax
        lda     #$10
        bcs     L1EE7
        stx     $0280
        dex
        dey
        bmi     L1ED8
        lda     $0281,y
        sta     $0281,x
        jmp     LA8CB

L1ED8:  lda     #$2F
        sta     $0281
L1EDD:  sta     $0281,x
        lda     IN,x
        dex
        bne     L1EDD
L1EE6:  clc
L1EE7:  rts

        jsr     LAB37
        ldy     #$09
L1EED:  cmp     $B96B,y
        beq     L1F27
        dey
        bpl     L1EED
        cmp     #$54
        beq     L1EFC
L1EF9:  jmp     LA839

L1EFC:  lda     #$04
        and     $BE54
        beq     L1F23
        ora     $BE56
        sta     $BE56
        copy16  #$1200, $BCAD
        jsr     LAA3A
        beq     L1EF9
        cmp     #$24
        beq     L1F76
        cmp     #$41
        bcc     L1F60
        jmp     LA9B6

L1F23:  sec
        return  #$0B

L1F27:  lda     $B975,y
        beq     L1F47
        and     $BE55
        beq     L1F23
        cmp     #$04
        bne     L1F41
        and     $BE57
        bne     L1F47
        lda     #$01
        sta     $BE62
        lda     #$04
L1F41:  ora     $BE57
        sta     $BE57
L1F47:  lda     $B97F,y
        and     #$03
        sta     $BCAD
        lda     $B97F,y
        lsr     a
        lsr     a
        sta     $BCAE
        jsr     LAA3A
        beq     L1FB0
        cmp     #$24
        beq     L1F76
L1F60:  stx     $BE4B
        jsr     LAA5C
        bcc     L1F6C
        bmi     L1FB3
        bcs     L1FB0
L1F6C:  ldx     $BE4B
        jsr     LAA3A
        bne     L1F60
        beq     L1F8F
L1F76:  jsr     LAA3A
        beq     L1FB0
L1F7B:  stx     $BE4B
        jsr     LAAAE
        bcc     L1F87
        bmi     L1FB3
        bcs     L1FB0
L1F87:  ldx     $BE4B
        jsr     LAA3A
        bne     L1F7B
L1F8F:  ldx     #$02
L1F91:  cpx     $BCAD
        beq     L1F9E
        lda     $BCAF,x
        bne     L1FB3
        dex
        bne     L1F91
L1F9E:  ldy     $BCAE
L1FA1:  lda     $BCAF,x
        sta     $BE58,y
        dey
        dex
        bpl     L1FA1
        ldx     $BE4B
        clc
        rts

L1FB0:  jmp     LA839

L1FB3:  jmp     LA75E

        ldy     #$00
L1FB8:  sta     $BCAF,y
        iny
        cpy     #$03
        beq     L1FC7
        jsr     LAA3A
        bne     L1FB8
        beq     L1FB0
L1FC7:  stx     $BE4B
L1FCA:  ldx     #$00
        lda     $BCAD
        cmp     #$0E
        beq     L1FB0
        asl     a
        adc     $BCAD
        tay
L1FD8:  lda     $BCAF,x
        eor     $B997,y
        asl     a
        bne     L1FE9
        iny
        inx
        cpx     #$03
        bne     L1FD8
        beq     L1FEE
L1FE9:  inc     $BCAD
        bne     L1FCA
L1FEE:  lda     #$0D
        sec
        sbc     $BCAD
        tay
        lda     $B989,y
        sta     $BE6A
        ldx     $BE4B
        clc
        rts

L2000:  jmp     L2031

        .byte   $03
        plp
        jsr     L3000
L2008:  .byte   0
        .byte   $04
L200A:  .byte   0
        bcc     L200F
        rts

L200F           := * + 1
        ora     ($00,x)
        .byte   0
        .byte   $04
L2012:  .byte   0
        .byte   0
        rti

        .byte   0
        rts

        .byte   0
        .byte   0
        .byte   $04
L201A:  .byte   0
        .byte   0
        .byte   $34
        .byte   0
        php
        .byte   0
        .byte   0
        .byte   $02
L2022:  .byte   0
        .byte   0
        asl     $00
        ora     ($00,x)
        php
        .byte   $53
        adc     $6C
        adc     $63
        .byte   $74
        .byte   $6F
        .byte   $72
L2031:  ldax    #$1700
L2035:  sta     $BF59,x
        dex
        bpl     L2035
        php
        sei
        MLI_CALL OPEN, $2003
        plp
        and     #$FF
        beq     L2049
        .byte   0
L2049:  lda     L2008
        sta     L2022
        sta     L200A
        sta     L2012
        sta     L201A
        php
        sei
        MLI_CALL SET_MARK, $2021
        plp
        and     #$FF
        beq     L2066
        .byte   0
L2066:  php
        sei
        MLI_CALL READ, $2009
        plp
        and     #$FF
        beq     L2074
        .byte   0
L2074:  php
        sei
        MLI_CALL READ, $2011
        plp
        and     #$FF
        beq     L2082
        .byte   0
L2082:  php
        sei
        MLI_CALL READ, $2019
        plp
        and     #$FF
        beq     L2090
        .byte   0
L2090:
L2092           := * + 2
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        ldx     #$00
L209B:  lda     $3400,x
        sta     $D000,x
        lda     $3500,x
        sta     $D100,x
        lda     $3600,x
        sta     $D200,x
        lda     $3700,x
        sta     $D300,x
        lda     $3800,x
        sta     $D400,x
        lda     $3900,x
        sta     $D500,x
        lda     $3A00,x
        sta     $D600,x
        lda     $3B00,x
        sta     $D700,x
        inx
        bne     L209B
        sta     ALTZPOFF
        sta     ROMIN2
        php
        sei
        MLI_CALL CLOSE, $2026
        plp
        and     #$FF
        jmp     START

        .byte   $03
        bpl     L2092
        inc     $8D03,x
        .byte   $89
        ora     ($AD),y
        .byte   $FF
        .byte   $03
        sta     $118A
        lda     LCBANK2
        lda     LCBANK2
        ldy     #$00
L20F8:  lda     $1000,y
        sta     $D100,y
        lda     $1100,y
        sta     $D200,y
        dey
        bne     L20F8
        lda     ROMIN2
        jmp     L10F2

        lda     $1189
        sta     IRQ_VECTOR
        lda     $118A
        sta     $03FF
        MLI_CALL SET_PREFIX, $1031
        beq     L2124
        jmp     L1127

L2124:  MLI_CALL OPEN, $1034
        beq     L212F
        jmp     L118B

L212F:  lda     $1039
        sta     $1028
        MLI_CALL READ, $1027
        beq     L2140
        jmp     L118B

L2140:  MLI_CALL CLOSE, $102F
        beq     L214B
        jmp     L118B

L214B:  jmp     L2000

        jsr     SLOT3ENTRY
        jsr     HOME
        lda     #$0C
        sta     CV
        jsr     VTAB
        lda     #$50
        sec
        sbc     $115E
        lsr     a
        sta     CH
        ldy     #$00
L2166:  lda     $115F,y
        ora     #$80
        jsr     COUT
        iny
        cpy     $115E
        bne     L2166
L2174:  sta     KBDSTRB
L2177:  lda     CLR80COL
        bpl     L2177
        and     #$7F
        cmp     #$0D
        bne     L2174
        jmp     L103A

        rol     a
        eor     #$6E
        .byte   $73
        adc     $72
        .byte   $74
        jsr     L6874
        adc     WNDLFT
        .byte   $73
        adc     $7473,y
        adc     $6D
        jsr     L6964
        .byte   $73
        .byte   $6B
        jsr     L6E61
        .byte   $64
        jsr     L7270
        adc     HIMEM
        .byte   $73
        jsr     L523C
        adc     $74
        adc     $72,x
        ror     $2E3E
        .byte   0
        .byte   0
        sta     $06
        jmp     MONZ

        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        ldx     $3D20,y
        tay
        bcs     L223B
        lda     $BE53
