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
SHADOW          := $C035        ; IIgs - inhibit shadowing

AN3_ON          := $C05F        ; AppleColor Adapter Card / Le Chat Mauve
AN3_OFF         := $C05E

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
BELL1           := $FBDD
VTAB            := $FC22
VTABZ           := $FC24
HOME            := $FC58
PRBYTE          := $FDDA
COUT            := $FDED
SETKBD          := $FE89
SETVID          := $FE93
MONZ            := $FF69

;;; Miscellaneous
IRQ_VECTOR      := $3FE

ID_BYTE_FBB3    := $FBB3        ; $06 = IIe or later
ID_BYTE_FBC0    := $FBC0        ; $EA = IIe, $E0 = IIe enh/IIgs, $00 = IIc/IIc+
ID_BYTE_FE1F    := $FE1F        ; RTS ($60) on pre-IIgs


;;; ============================================================
;;; Applesoft Basic ROM
;;; ============================================================

;;; Zero Page

ERRFLG          := $D8
TXTPTR          := $B8

;;; Entry Points
FSUB            := $E7A7
FADD            := $E7BE
FMULT           := $E97F
FDIV            := $EA66
ROUND           := $EB2B        ; Round FAC, store at (y,x)
FLOAT           := $EB93        ; A as signed byte into FAC
FIN             := $EC4A        ; Parse TEXTPTR to FAC (first char in A, C set if digit)
FOUT            := $ED34        ; FAC as string to FBUFFR


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
RD80STORE       := $C018
RDPAGE2         := $C01C

PAGE2OFF        := $C054
PAGE2ON         := $C055
HIRESON         := $C056
HIRESOFF        := $C057
DHIRESON        := $C05E
DHIRESOFF       := $C05F

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


;;; ============================================================
;;; Mouse Peripheral Card
;;; ============================================================

;;; Firmware Routines

SETMOUSE        := $12
SERVEMOUSE      := $13
READMOUSE       := $14
CLEARMOUSE      := $15
POSMOUSE        := $16
CLAMPMOUSE      := $17
HOMEMOUSE       := $18
INITMOUSE       := $19

;;; Constants

CLAMP_X         := 0
CLAMP_Y         := 1

MOUSE_MODE_OFF  := $00
MOUSE_MODE_TRANS:= $01
MOUSE_MODE_INT  := $03
MOUSE_MODE_BTN  := $05

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

CHAR_LEFT       := $08
CHAR_TAB        := $09
CHAR_DOWN       := $0A
CHAR_UP         := $0B
CHAR_RETURN     := $0D
CHAR_RIGHT      := $15
CHAR_ESCAPE     := $1B
CHAR_DELETE     := $7F
