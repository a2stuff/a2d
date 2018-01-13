;;; ------------------------------
;;; More Apple II Symbols
;;; ------------------------------

;;; Zero Page

COUT_HOOK       := $36

;;; Soft Switches

SPKR            := $C030
ROMIN2          := $C082

NEWVIDEO        := $C029        ; IIgs - new video modes
SHADOW          := $C035        ; IIgs - inhibit shadowing

;;; Key Codes

KEY_RETURN      := $0D
KEY_ESCAPE      := $1B
KEY_LEFT        := $08
KEY_DOWN        := $0A
KEY_UP          := $0B
KEY_RIGHT       := $15
KEY_DELETE      := $7F

;;; Monitor
INIT            := $FB2F
BELL1           := $FBDD
VTAB            := $FC22
HOME            := $FC58
COUT            := $FDED
SETKBD          := $FE89
SETVID          := $FE93
MONZ            := $FF69

;;; Miscellaneous
IRQ_VECTOR      := $3FE

ID_BYTE_FBB3    := $FBB3        ; $06 = IIe or later
ID_BYTE_FBC0    := $FBC0        ; $EA = IIe, $E0 = IIe enh/IIgs, $00 = IIc/IIc+
ID_BYTE_FE1F    := $FE1F        ; RTS ($60) on pre-IIgs
