;;; Floating Point macros

.macro  DEFINE_FLOAT ident
        WARN_IF_SHADOWING ident
        ident := *
        .res    5, 0
.endmacro


;;; FAC = int
.macro  FAC_LOAD_INT arg
        _op_lo ldy, {arg}
        _op_hi lda, {arg}
        jsr     GIVAYF
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
        lday    #float
        jsr     MOVFM
.endmacro

;;; float = FAC
.macro  FAC_STORE float
        ldxy    #float
        jsr     MOVMF
.endmacro

;;; FAC = float / FAC
.macro  FAC_DIV float
        lday    #float
        jsr     FDIV
.endmacro

;;; FAC = float * FAC
.macro  FAC_MUL float
        lday    #float
        jsr     FMULT
.endmacro

;;; FAC = float - FAC
.macro  FAC_SUB float
        lday    #float
        jsr     FSUB
.endmacro

;;; FAC = float + FAC
.macro  FAC_ADD float
        lday    #float
        jsr     FADD
.endmacro

;;; A = float <=> FAC
.macro  FAC_COMP float
        lday    #float
        jsr     FCOMP
.endmacro
