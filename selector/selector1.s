; da65 V2.17 - Git 5ac11b5e
; Created:    2020-03-25 19:03:17
; Input file: orig/selector1
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
MGTK            := $4000
FONT            := $8800
START           := $8E00
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
        lda     LCBANK2
        lda     LCBANK2
        ldy     #$00
L2008:  lda     $2027,y
        sta     $D100,y
        lda     $2127,y
        sta     $D200,y
        dey
        bne     L2008
        lda     ROMIN2
        MLI_CALL QUIT, $2020
        .byte   $04
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
