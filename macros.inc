;;; ==================================================
;;; Generic Macros
;;; ==================================================

.define is_immediate(arg)       (.match (.mid (0, 1, {arg}), #))
.define is_register(arg)        (.match ({arg}, x) .or .match ({arg}, y))

;;; ==================================================
;;; Pad with zeros to the given address

.macro PAD_TO addr
        .res    addr - *, 0
.endmacro

;;; ==================================================
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

;;; ==================================================
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

;;; ==================================================
;;; 16-bit pseudo-ops

;;; Load A,X
;;;    ldax #$1234      ; immediate
;;;    ldax $1234       ; absolute
.macro ldax arg
    .if is_immediate {arg}
        lda     #<(.right (.tcount ({arg})-1, {arg}))
        ldx     #>(.right (.tcount ({arg})-1, {arg}))
    .else
        lda     arg
        ldx     arg+1
    .endif
.endmacro

;;; Load X,Y
;;;    ldxy #$1234      ; immediate
;;;    ldxy $1234       ; absolute
.macro ldxy arg
    .if is_immediate {arg}
        ldx     #<(.right (.tcount ({arg})-1, {arg}))
        ldy     #>(.right (.tcount ({arg})-1, {arg}))
    .else
        ldx     arg
        ldy     arg+1
    .endif
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
.macro add16 aa, arg2, arg3
    .if is_immediate {arg2}
        lda     aa
        clc
        adc     #<(.right (.tcount ({arg2})-1, {arg2}))
        sta     arg3
        lda     aa+1
        adc     #>(.right (.tcount ({arg2})-1, {arg2}))
        sta     arg3+1
    .else
        lda     aa
        clc
        adc     arg2
        sta     arg3
        lda     aa+1
        adc     arg2+1
        sta     arg3+1
    .endif
.endmacro

;;; Add arg1 (absolute) to arg2 (8-bit absolute), store to arg3
;;;    add16_8 $1111, #$22, $3333       ; absolute, immediate, absolute
;;;    add16_8 $1111, $22, $3333        ; absolute, absolute, absolute
.macro add16_8 aa, arg2, arg3
        lda     aa
        clc
        adc     arg2
        sta     arg3
        lda     aa+1
        adc     #0
        sta     arg3+1
.endmacro

;;; Subtract arg2 from arg1, store to arg3
;;;    sub16 $1111, #$2222, $3333       ; absolute, immediate, absolute
;;;    sub16 $1111, $2222, $3333        ; absolute, absolute, absolute
;;;    sub16 $1111, $2222,x $3333       ; absolute, indexed, absolute
;;;    sub16 $1111, $2222,y $3333       ; absolute, indexed, absolute
.macro sub16 arg1, arg2, arg3, arg4
    .if is_register {arg3}
        lda     arg1
        sec
        sbc     arg2,arg3
        sta     arg4
        lda     arg1+1
        sbc     arg2+1,arg3
        sta     arg4+1
    .elseif is_immediate {arg2}
        lda     arg1
        sec
        sbc     #<(.right (.tcount ({arg2})-1, {arg2}))
        sta     arg3
        lda     arg1+1
        sbc     #>(.right (.tcount ({arg2})-1, {arg2}))
        sta     arg3+1
    .else
        lda     arg1
        sec
        sbc     arg2
        sta     arg3
        lda     arg1+1
        sbc     arg2+1
        sta     arg3+1
    .endif
.endmacro

;;; Subtract arg2 from arg1, store to arg3
;;;    sub16_8 $1111, #$22, $3333       ; absolute, immediate, absolute
;;;    sub16_8 $1111, $22, $3333        ; absolute, absolute, absolute
.macro sub16_8 arg1, arg2, arg3
        lda     arg1
        sec
        sbc     arg2
        sta     arg3
        lda     arg1+1
        sbc     #0
        sta     arg3+1
.endmacro

;;; Copy 16-bit value
;;;    copy16 #$1111, $2222     ; immediate, absolute
;;;    copy16 $1111, $2222      ; absolute, absolute
;;;    copy16 $1111,x, $2222    ; indirect load, absolute store
;;;    copy16 $1111,y, $2222    ; indirect load, absolute store
;;;    copy16 $1111, $2222,x    ; absolute load, indirect store
;;;    copy16 $1111, $2222,y    ; absolute load, indirect store
.macro copy16 arg1, arg2, arg3
    .if is_register {arg2}
        ;; indexed load variant (arg2 is x or y)
        lda     arg1,arg2
        sta     arg3
        lda     arg1+1,arg2
        sta     arg3+1
    .elseif is_register {arg3}
        ;; indexed store variant (arg3 is x or y)
        lda     arg1
        sta     arg2,arg3
        lda     arg1+1
        sta     arg2+1,arg3
    .elseif is_immediate {arg1}
        ;; immediate load variant (arg1 is #nnnn)
        lda     #<(.right (.tcount ({arg1})-1, {arg1}))
        sta     arg2
        lda     #>(.right (.tcount ({arg1})-1, {arg1}))
        sta     arg2+1
    .else
        lda     arg1
        sta     arg2
        lda     arg1+1
        sta     arg2+1
    .endif
.endmacro

;;; Compare 16-bit values
;;;    cmp16 #$1111, $2222     ; immediate, absolute
;;;    cmp16 $1111, #$2222     ; absolute, immediate
;;;    cmp16 $1111, $2222      ; absolute, absolute
;;;    cmp16 $1111,x, $2222    ; indirect, absolute
;;;    cmp16 $1111,y, $2222    ; indirect, absolute
;;;    cmp16 $1111, $2222,x    ; absolute, indirect
;;;    cmp16 $1111, $2222,y    ; absolute indirect
.macro cmp16 arg1, arg2, arg3
    .if is_register {arg2}
        ;; indexed variant (arg2 is x or y)
        lda     arg1,arg2
        cmp     arg3
        lda     arg1+1,arg2
        sbc     arg3+1
    .elseif is_register {arg3}
        ;; indexed variant (arg3 is x or y)
        lda     arg1
        cmp     arg2,arg3
        lda     arg1+1
        sbc     arg2+1,arg3
    .elseif is_immediate {arg1}
        ;; immediate variant (arg1 is #nnnn)
        lda     #<(.right (.tcount ({arg1})-1, {arg1}))
        cmp     arg2
        lda     #>(.right (.tcount ({arg1})-1, {arg1}))
        sbc     arg2+1
    .elseif is_immediate {arg2}
        ;; immediate variant (arg2 is #nnnn)
        lda     arg1
        cmp     #<(.right (.tcount ({arg2})-1, {arg2}))
        lda     arg1+1
        sbc     #>(.right (.tcount ({arg2})-1, {arg2}))
    .else
        lda     arg1
        cmp     arg2
        lda     arg1+1
        sbc     arg2+1
    .endif
.endmacro

;;; Shift 16-bit values
;;;    lsr16 $1111      ; absolute
.macro lsr16 arg1
        lsr     arg1+1
        ror     arg1
.endmacro
