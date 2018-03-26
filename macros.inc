;;; ============================================================
;;; Generic Macros
;;; ============================================================

.define _is_immediate(arg)       (.match (.mid (0, 1, {arg}), #))
.define _is_register(arg)        (.match ({arg}, x) .or .match ({arg}, y))
.define _immediate_value(arg)    (.right (.tcount ({arg})-1, {arg}))

.macro _op_lo op, arg
    .if _is_immediate {arg}
        op #<_immediate_value {arg}
    .else
        op arg
    .endif
.endmacro

.macro _op_hi op, arg
    .if _is_immediate {arg}
        op #>_immediate_value {arg}
    .else
        op arg+1
    .endif
.endmacro

;;; ============================================================
;;; Pad with zeros to the given address

.macro PAD_TO addr
        .res    addr - *, 0
.endmacro

;;; ============================================================
;;; Common patterns

.define AS_WORD(arg)        arg & $FFFF


.macro  return arg
        lda     arg
        rts
.endmacro

;;; ============================================================
;;; Calls with one parameter (address in A,X)

.macro addr_call target, addr
        lda     #<addr
        ldx     #>addr
        jsr     target
.endmacro

.macro addr_call_indirect target, addr
        lda     addr
        ldx     addr+1
        jsr     target
.endmacro

.macro addr_jump target, addr
        lda     #<addr
        ldx     #>addr
        jmp     target
.endmacro

;;; ============================================================
;;; Calls with two paramters (call # in y, address in A,X)
;;; (various output orders to match original binary)

.macro axy_call target, yparam, addr
        lda     #<addr
        ldx     #>addr
        ldy     #yparam
        jsr     target
.endmacro

.macro yax_call target, yparam, addr
        ldy     #yparam
        lda     #<addr
        ldx     #>addr
        jsr     target
.endmacro

.macro yxa_call target, yparam, addr
        ldy     #yparam
        ldx     #>addr
        lda     #<addr
        jsr     target
.endmacro

.macro yxa_jump target, yparam, addr
        ldy     #yparam
        ldx     #>addr
        lda     #<addr
        jmp     target
.endmacro


;;; ============================================================
;;; 16-bit pseudo-ops

;;; Load A,X
;;;    ldax #$1234      ; immediate
;;;    ldax $1234       ; absolute
.macro ldax arg
        _op_lo lda, {arg}
        _op_hi ldx, {arg}
.endmacro

;;; Load X,Y
;;;    ldxy #$1234      ; immediate
;;;    ldxy $1234       ; absolute
.macro ldxy arg
        _op_lo ldx, {arg}
        _op_hi ldy, {arg}
.endmacro

;;; Store A,X
;;;    stax $1234       ; absolute
.macro stax arg
        sta     arg
        stx     arg+1
.endmacro


;;; Add arg1 to arg2, store to arg3
;;;    add16 $1111, $2222, $3333        ; absolute, absolute, absolute
;;;    add16 $1111, #$2222, $3333       ; absolute, immediate, absolute
;;;    add16 $1111,x, $2222, $3333      ; indexed, absolute, absolute
;;;    add16 $1111, $2222,x, $3333      ; absolute, indexed, absolute
;;;    add16 $1111, $2222, $3333,x      ; absolute, absolute, indexed
;;;    add16 $1111,x, $2222, $3333,x    ; indexed, absolute, indexed
;;;    add16 $1111,x, $2222,x, $3333,x  ; indexed, indexed, indexed
.macro add16 arg1, arg2, arg3, arg4, arg5, arg6
    .if _is_register {arg2} && _is_register {arg4} && _is_register {arg6}
        lda     arg1,arg2
        clc
        adc     arg3,arg4
        sta     arg5,arg6
        lda     arg1+1,arg2
        adc     arg3+1,arg4
        sta     arg5+1,arg6
    .elseif _is_register {arg2} && _is_register {arg5}
        lda     arg1,arg2
        clc
        _op_lo  adc, {arg3}
        sta     arg4,arg5
        lda     arg1+1,arg2
        _op_hi  adc, {arg3}
        sta     arg4+1,arg5
    .elseif _is_register {arg2}
        lda     arg1,arg2
        clc
        _op_lo  adc, {arg3}
        sta     arg4
        lda     arg1+1,arg2
        _op_hi  adc, {arg3}
        sta     arg4+1
    .elseif _is_register {arg3}
        _op_lo  lda, {arg1}
        clc
        adc     arg2,arg3
        sta     arg4
        _op_hi  lda, {arg1}
        adc     arg2+1,arg3
        sta     arg4+1
    .elseif _is_register {arg4}
        _op_lo  lda, {arg1}
        clc
        _op_lo  adc, {arg2}
        sta     arg3,arg4
        _op_hi  lda, {arg1}
        _op_hi  adc, {arg2}
        sta     arg3+1,arg4
    .else
        _op_lo lda, {arg1}
        clc
        _op_lo adc, {arg2}
        sta     arg3
        _op_hi lda, {arg1}
        _op_hi adc, {arg2}
        sta     arg3+1
    .endif
.endmacro


;;; Add arg1 (absolute) to arg2 (8-bit absolute), store to arg3
;;;    add16_8 $1111, #$22, $3333       ; absolute, immediate, absolute
;;;    add16_8 $1111, $22, $3333        ; absolute, absolute, absolute
.macro add16_8 arg1, arg2, arg3
        _op_lo  lda, {arg1}
        clc
        adc     arg2
        sta     arg3
        _op_hi  lda, {arg1}
        adc     #0
        sta     arg3+1
.endmacro

;;; Add A,Z to arg1 (immediate or absolute), store to arg2
;;;    addax #$1111, $3333       ; immediate, absolute
;;;    addax $1111, $3333        ; absolute, absolute
.macro addax arg1, arg2
        clc
        _op_lo adc, {arg1}
        sta     arg2
        txa
        _op_hi adc, {arg1}
        sta     arg2+1
.endmacro

;;; Subtract arg2 from arg1, store to arg3
;;;    sub16 #$1111, #$2222, $3333      ; immediate, immediate, absolute
;;;    sub16 #$1111, $2222, $3333       ; immediate, absolute, absolute
;;;    sub16 $1111, #$2222, $3333       ; absolute, immediate, absolute
;;;    sub16 $1111, $2222, $3333        ; absolute, absolute, absolute
;;;    sub16 $1111, $2222,x, $3333      ; absolute, indexed, absolute
;;;    sub16 $1111, $2222, $3333,x      ; absolute, absolute, indexed
;;;    sub16 $1111,x, $2222,x, $3333    ; indexed, indexed, absolute
;;;    sub16 $1111,x, $2222, $3333,x    ; indexed, absolute, indexed
;;;    sub16 $1111,x, $2222,x $3333,x   ; indexed, indexed, indexed
.macro sub16 arg1, arg2, arg3, arg4, arg5, arg6
    .if _is_register {arg2} && _is_register {arg4} && _is_register {arg6}
        lda     arg1,arg2
        sec
        sbc     arg3,arg4
        sta     arg5,arg6
        lda     arg1+1,arg2
        sbc     arg3+1,arg4
        sta     arg5+1,arg6
    .elseif _is_register {arg2} && _is_register {arg4}
        lda     arg1,arg2
        sec
        sbc     arg3,arg4
        sta     arg5
        lda     arg1+1,arg2
        sbc     arg3+1,arg4
        sta     arg5+1
    .elseif _is_register {arg2} && _is_register {arg5}
        lda     arg1,arg2
        sec
        _op_lo  sbc, {arg3}
        sta     arg4,arg5
        lda     arg1+1,arg2
        _op_hi  sbc, {arg3}
        sta     arg4+1,arg5
    .elseif _is_register {arg3}
        _op_lo  lda, {arg1}
        sec
        sbc     arg2,arg3
        sta     arg4
        _op_hi  lda, {arg1}
        sbc     arg2+1,arg3
        sta     arg4+1
    .elseif _is_register {arg4}
        _op_lo  lda, {arg1}
        sec
        _op_lo  sbc, {arg2}
        sta     arg3,arg4
        _op_hi  lda, {arg1}
        _op_hi  sbc, {arg2}
        sta     arg3+1,arg4
    .else
        _op_lo lda, {arg1}
        sec
        _op_lo sbc, {arg2}
        sta     arg3
        _op_hi lda, {arg1}
        _op_hi sbc, {arg2}
        sta     arg3+1
    .endif
.endmacro

;;; Subtract arg2 from arg1, store to arg3
;;;    sub16_8 #$1111, #$22, $3333      ; immediate, immediate, absolute
;;;    sub16_8 #$1111, $22, $3333       ; immediate, absolute, absolute
;;;    sub16_8 $1111, #$22, $3333       ; absolute, immediate, absolute
;;;    sub16_8 $1111, $22, $3333        ; absolute, absolute, absolute
.macro sub16_8 arg1, arg2, arg3
        _op_lo  lda, {arg1}
        sec
        sbc     arg2
        sta     arg3
        _op_hi  lda, {arg1}
        sbc     #0
        sta     arg3+1
.endmacro

;;; Copy 16-bit value
;;;    copy16 #$1111, $2222     ; immediate, absolute
;;;    copy16 $1111, $2222      ; absolute, absolute
;;;    copy16 $1111,x, $2222    ; indirect load, absolute store
;;;    copy16 $1111, $2222,x    ; absolute load, indirect store
;;;    copy16 $1111,x $2222,x   ; indirect load, indirect store
;;;    copy16 #$1111, $2222,x   ; immediate load, indirect store
.macro copy16 arg1, arg2, arg3, arg4
    .if _is_register {arg2} && _is_register {arg4}
        ;; indexed load/indexed store
        lda     arg1,arg2
        sta     arg3,arg4
        lda     arg1+1,arg2
        sta     arg3+1,arg4
    .elseif _is_register {arg2}
        ;; indexed load variant (arg2 is x or y)
        lda     arg1,arg2
        sta     arg3
        lda     arg1+1,arg2
        sta     arg3+1
    .elseif _is_register {arg3}
        ;; indexed store variant (arg3 is x or y)
        _op_lo  lda, {arg1}
        sta     arg2,arg3
        _op_hi  lda, {arg1}
        sta     arg2+1,arg3
    .else
        _op_lo  lda, {arg1}
        sta     arg2
        _op_hi  lda, {arg1}
        sta     arg2+1
    .endif
.endmacro

;;; Compare 16-bit values
;;;    cmp16 #$1111, #$2222    ; immediate, immediate (silly, but supported)
;;;    cmp16 #$1111, $2222     ; immediate, absolute
;;;    cmp16 $1111, #$2222     ; absolute, immediate
;;;    cmp16 $1111, $2222      ; absolute, absolute
;;;    cmp16 $1111,x, $2222    ; indirect, absolute
;;;    cmp16 $1111, $2222,x    ; absolute, indirect
.macro cmp16 arg1, arg2, arg3
    .if _is_register {arg2}
        ;; indexed variant (arg2 is x or y)
        lda     arg1,arg2
        cmp     arg3
        lda     arg1+1,arg2
        sbc     arg3+1
    .elseif _is_register {arg3}
        ;; indexed variant (arg3 is x or y)
        lda     arg1
        cmp     arg2,arg3
        lda     arg1+1
        sbc     arg2+1,arg3
    .else
        _op_lo  lda, {arg1}
        _op_lo  cmp, {arg2}
        _op_hi  lda, {arg1}
        _op_hi  sbc, {arg2}
    .endif
.endmacro

;;; Shift 16-bit values
;;;    lsr16 $1111      ; absolute
.macro lsr16 arg1
        lsr     arg1+1
        ror     arg1
.endmacro

;;; Increment 16-bit value
.macro inc16    arg
        .local skip
        inc     arg
        bne     skip
        inc     arg+1
skip:
.endmacro
