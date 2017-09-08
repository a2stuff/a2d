;;; ------------------------------
;;; Applesoft Basic
;;; ------------------------------

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
