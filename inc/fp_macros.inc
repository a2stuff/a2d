;;; Floating Point macros

.macro  DEFINE_FLOAT
        .res    5, 0
.endmacro


;;; FAC = int
.macro  fac_load_int arg
        _op_lo ldy, {arg}
        _op_hi lda, {arg}
        jsr     GIVAYF
.endmacro

;;; int = FAC
.macro fac_store_int int
        jsr     QINT
        lda     FAC+4
        sta     int
        lda     FAC+3
        sta     int+1
.endmacro

;;; FAC = float
.macro  fac_load float
        lday    #float
        jsr     MOVFM
.endmacro

;;; float = FAC
.macro  fac_store float
        ldxy    #float
        jsr     MOVMF
.endmacro

;;; FAC = float / FAC
.macro  fac_div float
        lday    #float
        jsr     FDIV
.endmacro

;;; FAC = float * FAC
.macro  fac_mul float
        lday    #float
        jsr     FMULT
.endmacro

;;; FAC = float - FAC
.macro  fac_sub float
        lday    #float
        jsr     FSUB
.endmacro

;;; FAC = float + FAC
.macro  fac_add float
        lday    #float
        jsr     FADD
.endmacro

;;; A = float <=> FAC
.macro  fac_comp float
        lday    #float
        jsr     FCOMP
.endmacro
