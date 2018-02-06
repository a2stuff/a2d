;;; ==================================================
;;; Generic Macros
;;; ==================================================

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

;;; Load A,X (immediate or absolute)
;;;    ldax $1234
;;;    ldax #$1234
.macro ldax arg
    .if (.match (.mid (0, 1, {arg}), #))
        lda     #<(.right (.tcount ({arg})-1, {arg}))
        ldx     #>(.right (.tcount ({arg})-1, {arg}))
    .else
        lda     arg
        ldx     arg+1
    .endif
.endmacro

;;; Store A,X (absolute)
;;;    stax $1234
.macro stax arg
        sta     arg
        stx     arg+1
.endmacro

;;; Add arg1 (absolute) to arg2 (immediate or absolute), store to arg3
;;;    add16 $1111, $2222, $3333
;;;    add16 $1111, #$2222, $3333
.macro add16 aa, bb, rr
    .if (.match (.mid (0, 1, {bb}), #))
        lda     aa
        clc
        adc     #<(.right (.tcount ({bb})-1, {bb}))
        sta     rr
        lda     aa+1
        adc     #>(.right (.tcount ({bb})-1, {bb}))
        sta     rr+1
    .else
        lda     aa
        clc
        adc     bb
        sta     rr
        lda     aa+1
        adc     bb+1
        sta     rr+1
    .endif
.endmacro

;;; Add arg1 (absolute) to arg2 (8-bit absolute), store to arg3
;;;    add16_8 $1111, $22, $3333
;;;    add16_8 $1111, #$22, $3333
.macro add16_8 aa, bb, rr
        lda     aa
        clc
        adc     bb
        sta     rr
        lda     aa+1
        adc     #0
        sta     rr+1
.endmacro

;;; Subtract arg2 (immediate or absolute) from arg1, store to arg3
;;;    sub16 $1111, $2222, $3333
;;;    sub16 $1111, #$2222, $3333
.macro sub16 aa, bb, rr
    .if (.match (.mid (0, 1, {bb}), #))
        lda     aa
        sec
        sbc     #<(.right (.tcount ({bb})-1, {bb}))
        sta     rr
        lda     aa+1
        sbc     #>(.right (.tcount ({bb})-1, {bb}))
        sta     rr+1
    .else
        lda     aa
        sec
        sbc     bb
        sta     rr
        lda     aa+1
        sbc     bb+1
        sta     rr+1
    .endif
.endmacro

;;; Copy 16-bit value
;;;    copy16 #$1111, $2222     ; immediate
;;;    copy16 $1111, $2222      ; absolute
;;;    copy16 $1111,x, $2222    ; indirect load
;;;    copy16 $1111,y, $2222    ; indirect load
;;;    copy16 $1111, $2222,x    ; indirect store
;;;    copy16 $1111, $2222,y    ; indirect store
.macro copy16 arg1, arg2, arg3
    .if (.match ({arg2}, x) .or .match ({arg2}, y))
        ;; indexed load variant (arg2 is x or y)
        lda     arg1,arg2
        sta     arg3
        lda     arg1+1,arg2
        sta     arg3+1
    .elseif (.match ({arg3}, x) .or .match ({arg3}, y))
        ;; indexed store variant (arg3 is x or y)
        lda     arg1
        sta     arg2,arg3
        lda     arg1+1
        sta     arg2+1,arg3
    .elseif (.match (.mid (0, 1, {arg1}), #))
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

.macro cmp16 arg1, arg2, arg3
    .if (.match ({arg2}, x) .or .match ({arg2}, y))
        ;; indexed variant (arg2 is x or y)
        lda     arg1,arg2
        cmp     arg3
        lda     arg1+1,arg2
        sbc     arg3+1
    .elseif (.match ({arg3}, x) .or .match ({arg3}, y))
        ;; indexed variant (arg3 is x or y)
        lda     arg1
        cmp     arg2,arg3
        lda     arg1+1
        sbc     arg2+1,arg3
    .elseif (.match (.mid (0, 1, {arg1}), #))
        ;; immediate variant (arg1 is #nnnn)
        lda     #<(.right (.tcount ({arg1})-1, {arg1}))
        cmp     arg2
        lda     #>(.right (.tcount ({arg1})-1, {arg1}))
        sbc     arg2+1
    .elseif (.match (.mid (0, 1, {arg2}), #))
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
