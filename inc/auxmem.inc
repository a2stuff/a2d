;;; ------------------------------
;;; Aux Memory
;;; ------------------------------

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

STARTLO         := $3C
STARTHI         := $3D
ENDLO           := $3E
ENDHI           := $3F
DESTINATIONLO   := $42
DESTINATIONHI   := $43

XFERSTARTLO     := $03ED
XFERSTARTHI     := $03EE
