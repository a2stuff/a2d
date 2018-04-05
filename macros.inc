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


.macro return arg
        lda     arg
        rts
.endmacro


.macro copy arg1, arg2
        lda     arg1
        sta     arg2
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

;;; Core for add16/sub16
.macro _addsub16 op, opc, arg1, arg2, arg3, arg4, arg5, arg6
    .if _is_register {arg2} && _is_register {arg4} && _is_register {arg6}
        ;; xxx16 $1111,x, $2222,x, $3333,x
        lda     arg1,arg2
        opc
        op      arg3,arg4
        sta     arg5,arg6
        lda     arg1+1,arg2
        op      arg3+1,arg4
        sta     arg5+1,arg6
    .elseif _is_register {arg2} && _is_register {arg4}
        ;; xxx16 $1111,x, $2222,x, $3333
        lda     arg1,arg2
        opc
        op      arg3,arg4
        sta     arg5
        lda     arg1+1,arg2
        op      arg3+1,arg4
        sta     arg5+1
    .elseif _is_register {arg2} && _is_register {arg5}
        ;; xxx16 $1111,x, $2222, $3333,x
        ;; xxx16 $1111,x, #$2222, $3333,x
        lda     arg1,arg2
        opc
        _op_lo  op, {arg3}
        sta     arg4,arg5
        lda     arg1+1,arg2
        _op_hi  op, {arg3}
        sta     arg4+1,arg5
    .elseif _is_register {arg2}
        ;; xxx16 $1111,x, $2222, $3333
        ;; xxx16 $1111,x, #$2222, $3333
        lda     arg1,arg2
        opc
        _op_lo  op, {arg3}
        sta     arg4
        lda     arg1+1,arg2
        _op_hi  op, {arg3}
        sta     arg4+1
    .elseif _is_register {arg3}
        ;; xxx16 $1111, $2222,x $3333
        ;; xxx16 #$1111, $2222,x $3333
        _op_lo  lda, {arg1}
        opc
        op      arg2,arg3
        sta     arg4
        _op_hi  lda, {arg1}
        op      arg2+1,arg3
        sta     arg4+1
    .elseif _is_register {arg4}
        ;; xxx16 $1111, $2222, $3333,x
        ;; xxx16 #$1111, $2222, $3333,x
        ;; xxx16 $1111, #$2222, $3333,x
        ;; xxx16 #$1111, #$2222, $3333,x
        _op_lo  lda, {arg1}
        opc
        _op_lo  op, {arg2}
        sta     arg3,arg4
        _op_hi  lda, {arg1}
        _op_hi  op, {arg2}
        sta     arg3+1,arg4
    .else
        ;; xxx16 $1111, $2222, $3333
        ;; xxx16 #$1111, $2222, $3333
        ;; xxx16 $1111, #$2222, $3333
        ;; xxx16 #$1111, #$2222, $3333
        _op_lo lda, {arg1}
        opc
        _op_lo op, {arg2}
        sta     arg3
        _op_hi lda, {arg1}
        _op_hi op, {arg2}
        sta     arg3+1
    .endif
.endmacro

;;; Core for add16/sub16, with leading carry operation
.macro _addsub16lc op, opc, arg1, arg2, arg3, arg4, arg5, arg6
        opc
    .if _is_register {arg2} && _is_register {arg4} && _is_register {arg6}
        ;; xxx16 $1111,x, $2222,x, $3333,x
        lda     arg1,arg2
        op      arg3,arg4
        sta     arg5,arg6
        lda     arg1+1,arg2
        op      arg3+1,arg4
        sta     arg5+1,arg6
    .elseif _is_register {arg2} && _is_register {arg4}
        ;; xxx16 $1111,x, $2222,x, $3333
        lda     arg1,arg2
        op      arg3,arg4
        sta     arg5
        lda     arg1+1,arg2
        op      arg3+1,arg4
        sta     arg5+1
    .elseif _is_register {arg2} && _is_register {arg5}
        ;; xxx16 $1111,x, $2222, $3333,x
        ;; xxx16 $1111,x, #$2222, $3333,x
        lda     arg1,arg2
        _op_lo  op, {arg3}
        sta     arg4,arg5
        lda     arg1+1,arg2
        _op_hi  op, {arg3}
        sta     arg4+1,arg5
    .elseif _is_register {arg2}
        ;; xxx16 $1111,x, $2222, $3333
        ;; xxx16 $1111,x, #$2222, $3333
        lda     arg1,arg2
        _op_lo  op, {arg3}
        sta     arg4
        lda     arg1+1,arg2
        _op_hi  op, {arg3}
        sta     arg4+1
    .elseif _is_register {arg3}
        ;; xxx16 $1111, $2222,x $3333
        ;; xxx16 #$1111, $2222,x $3333
        _op_lo  lda, {arg1}
        op      arg2,arg3
        sta     arg4
        _op_hi  lda, {arg1}
        op      arg2+1,arg3
        sta     arg4+1
    .elseif _is_register {arg4}
        ;; xxx16 $1111, $2222, $3333,x
        ;; xxx16 #$1111, $2222, $3333,x
        ;; xxx16 $1111, #$2222, $3333,x
        ;; xxx16 #$1111, #$2222, $3333,x
        _op_lo  lda, {arg1}
        _op_lo  op, {arg2}
        sta     arg3,arg4
        _op_hi  lda, {arg1}
        _op_hi  op, {arg2}
        sta     arg3+1,arg4
    .else
        ;; xxx16 $1111, $2222, $3333
        ;; xxx16 #$1111, $2222, $3333
        ;; xxx16 $1111, #$2222, $3333
        ;; xxx16 #$1111, #$2222, $3333
        _op_lo lda, {arg1}
        _op_lo op, {arg2}
        sta     arg3
        _op_hi lda, {arg1}
        _op_hi op, {arg2}
        sta     arg3+1
    .endif
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
    _addsub16 adc, clc, arg1, arg2, arg3, arg4, arg5, arg6
.endmacro
;;; (as above, but clc precedes first lda)
.macro add16lc arg1, arg2, arg3, arg4, arg5, arg6
    _addsub16lc adc, clc, arg1, arg2, arg3, arg4, arg5, arg6
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
    _addsub16 sbc, sec, arg1, arg2, arg3, arg4, arg5, arg6
.endmacro
;;; (as above, but sec precedes first lda)
.macro sub16lc arg1, arg2, arg3, arg4, arg5, arg6
    _addsub16lc sbc, sec, arg1, arg2, arg3, arg4, arg5, arg6
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

;;; Helper macros to set up a scoped block of parameters at a pre-determined
;;; address.
;;;
;;; Note: to use this macro, your cfg must have a BSS segment:
;;;     (BSS: load = BSS, type = bss)
;;;
;;; Example:
;;;    .proc my_function
;;;            PARAM_BLOCK params, $82
;;;    arg1:   .res    1
;;;    arg2:   .res    2
;;;    arg3:   .res    2
;;;            END_PARAM_BLOCK
;;;
;;;            lda     params::arg1         ; equiv. to lda $82
;;;            lda     params::arg2         ; equiv. to lda $83
;;;            lda     params::arg3         ; equiv. to lda $85
;;;
.macro PARAM_BLOCK name, addr
        name := addr
        .scope  name
        .pushseg
        .bss
        .feature org_per_seg
        .org    addr
start:
.endmacro

.macro END_PARAM_BLOCK
        size := * - start
        .popseg
        .endscope
.endmacro
