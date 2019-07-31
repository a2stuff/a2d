;;; ============================================================
;;;
;;; More Apple II Symbols
;;;
;;; ============================================================

;;; Zero Page

COUT_HOOK       := $36

;;; Other Pages

IN              := $200


;;; Soft Switches

SPKR            := $C030
ROMIN2          := $C082

NEWVIDEO        := $C029        ; IIgs - new video modes
        ;; Bit 7 = 1 = Enable Super-Hi-Res
        ;; Bit 6 = 1 = Linearize SHR
        ;; Bit 5 = 0 = Color DHR, 1 = B/W DHR
        ;; Bits 4-0 must be 0

SHADOW          := $C035        ; IIgs - inhibit shadowing

AN3_ON          := $C05F        ; AppleColor Adapter Card / Le Chat Mauve
AN3_OFF         := $C05E

BUTN2           := $C063

RAMWORKS_BANK   := $C071        ; RAMWorks bank selection ???

HR1_ON          := $C0B3
HR1_OFF         := $C0B2
HR2_ON          := $C0B5
HR2_OFF         := $C0B4
HR3_ON          := $C0B7
HR3_OFF         := $C0B6


;;; ============================================================
;;; Monitor ROM
;;; ============================================================

;;; Monitor
INIT            := $FB2F
SETPWRC         := $FB6F
VERSION         := $FBB3
BELL1           := $FBDD
VTAB            := $FC22
VTABZ           := $FC24
HOME            := $FC58
PRBYTE          := $FDDA
COUT            := $FDED
MOVE            := $FE2C
SETKBD          := $FE89
SETVID          := $FE93
MONZ            := $FF69

F8VERSION       := $06

;;; Miscellaneous
IRQ_VECTOR      := $3FE

ID_BYTE_FB1E    := $FB1E        ; $AC = Laser 128
ID_BYTE_FBB3    := $FBB3        ; $06 = IIe or later
ID_BYTE_FBC0    := $FBC0        ; $EA = IIe, $E0 = IIe enh/IIgs, $00 = IIc/IIc+
ID_BYTE_FBBF    := $FBBF        ; IIc ROM version ($05 = IIc+)
ID_BYTE_FE1F    := $FE1F        ; RTS ($60) on pre-IIgs, clears carry on IIgs


;;; ============================================================
;;; Applesoft Basic ROM
;;; ============================================================

;;; Zero Page

LINNUM          := $50          ; Line number, unsigned word
ERRFLG          := $D8
CHRGET          := $B1          ; Routine called by ROM
TXTPTR          := $B8
FAC             := $9D
SHIFT_SIGN_EXT  := $A4          ; Zero before using FP ops

;;; Entry Points
GIVAYF          := $E2F2        ; FAC from signed integer in (Y,A)
CONINT          := $E6FB        ; FAC = X as unsigned byte
GETADR          := $E752        ; FAC to unsigned integer in LINNUM
FADDH           := $E7A0        ; Add 0.5 to FAC
FSUB            := $E7A7        ; FAC = (Y,A) - FAC
FSUBT           := $E7AA        ; FAC = ARG - FAC
FADD            := $E7BE        ; FAC = (Y,A) + FAC
FADDT           := $E7C1        ; FAC = ARG + FAC
ZERO_FAC        := $E84E        ; FAC = 0
LOG             := $E941        ; FAC = LOG(FAC)
FMULT           := $E97F        ; FAC = (Y,A) * FAC
FMULTT          := $E982        ; FAC = ARG * FAC
DIV10           := $EA55        ; FAC = FAC / 10
FDIV            := $EA66        ; FAC = (Y,A) / FAC
FDIVT           := $EA69        ; FAC = ARG / FAC
LOAD_ARG        := $EAE3        ; ARG = (Y,A)
MOVFM           := $EAF9        ; FAC = (Y,A)
LOAD_FAC        := $EAF9        ; FAC = (Y,A)
MOVMF           := $EB2B        ; (Y,X) = FAC
ROUND           := $EB2B        ; Round FAC, store at (Y,X)
ARG_TO_FAC      := $EB53        ; ARG = FAC
FAC_TO_ARG_R    := $EB63        ; FAC = ARG, rounded
SGN             := $EB90        ; FAC = SGN(FAC)
FLOAT           := $EB93        ; FAC = A as signed byte
FLOAT1          := $EB9B        ; FAC from unsigned integer in FAC+1,2 eX
FLOAT2          := $EBA0        ; FAC from unsigned integer in FAC+1,2 eX, carry set = positive
ABS             := $EBAF        ; FAC = ABS(FAC)
FCOMP           := $EBB2        ; FAC <=> (Y,A), result in A
QINT            := $EBF2        ; FAC to signed integer in FAC+1...FAC+4 (e < 32)
INT             := $EC23        ; FAC = INT(FAC)
FIN             := $EC4A        ; Parse TEXTPTR to FAC (first char in A, C set if digit)
FOUT            := $ED34        ; FAC as string to FBUFFR (trashes FAC)
SQR             := $EE8D        ; FAC = SQR(FAC)
NEGOP           := $EED0        ; FAC = -FAC
EXP             := $EF09        ; FAC = EXP(FAC)
RND             := $EFAE        ; FAC = RND(FAC)
COS             := $EFEA        ; FAC = COS(FAC)
SIN             := $EFF1        ; FAC = SIN(FAC)
TAN             := $F03A        ; FAC = SIN(FAC)
ATN             := $F09E        ; FAC = ATN(FAC)

;;; Constants
CON_ONE         := $E913        ; 1
CON_SQR_HALF    := $E92D        ; SQR(1/2)
CON_SQR_TWO     := $E932        ; SQR(2)
CON_NEG_HALF    := $E937        ; -1/2
CON_LOG_TWO     := $E93C        ; LOG(2)
CON_TEN         := $E950        ; 10
CON_BILLION     := $ED14        ; 1E9
CON_HALF        := $EE64        ; 1/2
CON_LOG2_E      := $EEDB        ; Log(E) base 2 ????
CON_HALF_PI     := $F063        ; pi/2
CON_TWO_PI      := $F06B        ; pi/*2
CON_QUARTER     := $F070        ; 1/4

;;; Other
FBUFFR          := $100


;;; ============================================================
;;; Aux Memory / Extended 80 Column Card
;;; ============================================================

;;; Softswitches
RAMRDOFF        := $C002
RAMRDON         := $C003
RAMWRTOFF       := $C004
RAMWRTON        := $C005
ALTZPOFF        := $C008
ALTZPON         := $C009

CLR80VID        := $C00C
SET80VID        := $C00D
RDALTZP         := $C016
RD80STORE       := $C018
RDPAGE2         := $C01C

PAGE2OFF        := $C054
PAGE2ON         := $C055
HIRESON         := $C056
HIRESOFF        := $C057
DHIRESON        := $C05E
DHIRESOFF       := $C05F

PADDL0          := $C064
PTRIG           := $C070

;;; Routines
SLOT3ENTRY      := $C300
AUXMOVE         := $C311        ; carry set main>aux, carry clear aux>main
XFER            := $C314

;;; Zero Page Locations
STARTLO         := $3C
STARTHI         := $3D
ENDLO           := $3E
ENDHI           := $3F
DESTINATIONLO   := $42
DESTINATIONHI   := $43

;;; Other Locations
XFERSTARTLO     := $03ED
XFERSTARTHI     := $03EE
RESETVEC        := $03F2


;;; ============================================================
;;; Disk II / IWM I/O locations
;;; ============================================================

;;; $C0nX, n = slot + 8 -- c/o http://archive.li/ewHUL
PHASE0  := $C080                ; Stepper motor phase 0
PHASE1  := $C082                ; Stepper motor phase 1
PHASE2  := $C084                ; Stepper motor phase 2
PHASE3  := $C086                ; Stepper motor phase 3
DISABLE := $C088                ; Turn disk drive off
ENABLE  := $C089                ; Turn disk drive on
SELECT  := $C08A                ; Select drive 1 or 2
SELECT1 := $C08A                ; Select drive 1
SELECT2 := $C08B                ; Select drive 2
XMIT    := $C08C                ; Get/set bits to/from disk
TESTWP  := $C08D                ; Test WP mode (then WPRES has result)
DATA    := $C08D                ; Write data to buffer (then XMIT to send)
WPRES   := $C08E                ; WP mode test result
RDMODE  := $C08E                ; Turn off write mode
WRMODE  := $C08F                ; Turn on write mode


;;; ============================================================
;;; Mouse Peripheral Card
;;; ============================================================

;;; Firmware Routines

SETMOUSE        = $12
SERVEMOUSE      = $13
READMOUSE       = $14
CLEARMOUSE      = $15
POSMOUSE        = $16
CLAMPMOUSE      = $17
HOMEMOUSE       = $18
INITMOUSE       = $19

;;; Constants

CLAMP_X         = 0
CLAMP_Y         = 1

MOUSE_MODE_OFF  = $00
MOUSE_MODE_TRANS= $01
MOUSE_MODE_INT  = $03
MOUSE_MODE_BTN  = $05

;;; RAM Locations

CLAMP_MIN_LO    := $478
CLAMP_MIN_HI    := $578
CLAMP_MAX_LO    := $4F8
CLAMP_MAX_HI    := $5F8

;;; RAM Locations
;;; (Add $Cn where n is slot to these)

MOUSE_X_LO      := $03B8
MOUSE_X_HI      := $04B8
MOUSE_Y_LO      := $0438
MOUSE_Y_HI      := $0538
MOUSE_STATUS    := $06B8
MOUSE_MODE      := $0738


;;; ============================================================
;;; Character Constants (Screen/Key Codes)
;;; ============================================================

CHAR_MASK       = $7F
CASE_MASK       = $DF

CHAR_CTRL_C     = $03
CHAR_LEFT       = $08
CHAR_TAB        = $09
CHAR_DOWN       = $0A
CHAR_UP         = $0B
CHAR_RETURN     = $0D
CHAR_CTRL_O     = $0F
CHAR_RIGHT      = $15
CHAR_ESCAPE     = $1B
CHAR_DELETE     = $7F
