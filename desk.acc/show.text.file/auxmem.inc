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
LCBANK1         := $C08B

;;; Routines
AUXMOVE         := $C311        ; carry set main>aux, carry clear aux>main

STARTLO         := $3C
STARTHI         := $3D
ENDLO           := $3E
ENDHI           := $3F
DESTINATIONLO   := $42
DESTINATIONHI   := $43
