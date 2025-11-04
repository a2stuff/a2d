;;; Floating Point macros

.macro  DEFINE_FLOAT ident
        WARN_IF_SHADOWING ident
        ident := *
        .res    5, 0
.endmacro


;;; FAC = int
.macro  FAC_LOAD_INT arg
        CALL    GIVAYF, YA=arg
.endmacro

;;; int = FAC
.macro FAC_STORE_INT int
        jsr     QINT
        lda     FAC+4
        sta     int
        lda     FAC+3
        sta     int+1
.endmacro

;;; FAC = float
.macro  FAC_LOAD float
        CALL    MOVFM, AY=#float
.endmacro

;;; float = FAC
.macro  FAC_STORE float
        CALL    MOVMF, XY=#float
.endmacro

;;; FAC = float / FAC
.macro  FAC_DIV float
        CALL    FDIV, AY=#float
.endmacro

;;; FAC = float * FAC
.macro  FAC_MUL float
        CALL    FMULT, AY=#float
.endmacro

;;; FAC = float - FAC
.macro  FAC_SUB float
        CALL    FSUB, AY=#float
.endmacro

;;; FAC = float + FAC
.macro  FAC_ADD float
        CALL    FADD, AY=#float
.endmacro

;;; A = float <=> FAC
.macro  FAC_COMP float
        CALL    FCOMP, AY=#float
.endmacro
