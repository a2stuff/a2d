;;; ============================================================
;;; Multibyte
;;; ============================================================

;;; Macros for common operations (copy, add, subtract) for 16-bit and
;;; other sized operands.

;;; ============================================================

.define _is_immediate(arg)       .xmatch (.mid (0, 1, {arg}), #)
.define _is_register(arg)        .xmatch ({arg}, x) .or .xmatch ({arg}, y)
.define _is_y_register(arg)      .xmatch ({arg}, y)
.define _immediate_value(arg)    .right (.tcount ({arg}) - 1, {arg})

;;; Helpers for multi-byte operations

;;; Emit specified opcode accessing the Nth byte, either immediate or absolute
.macro _op_b0 op, arg
    .if _is_immediate {arg}
        op #.lobyte(_immediate_value {arg})
    .else
        op arg
    .endif
.endmacro

.macro _op_b1 op, arg
    .if _is_immediate {arg}
        op #.hibyte(_immediate_value {arg})
    .else
        op arg+1
    .endif
.endmacro

.macro _op_b2 op, arg
    .if _is_immediate {arg}
        op #.bankbyte(_immediate_value {arg})
    .else
        op arg+2
    .endif
.endmacro

.macro _op_b3 op, arg
    .if _is_immediate {arg}
        op #.hibyte(.hiword(_immediate_value {arg}))
    .else
        op arg+3
    .endif
.endmacro

;;; Like `_op_b*` but emit nothing if immediate and lower byte was the
;;; same, assuming previous byte was already loaded into the register.
.macro _op_x1 op, arg
    .if _is_immediate {arg}
      .define _iv_ _immediate_value {arg}
      .if .const(_iv_) && .lobyte(_iv_) = .hibyte(_iv_)
        ;; already loaded into relevant register
      .else
        op #.hibyte(_iv_)
      .endif
      .undefine _iv_
    .else
        op arg+1
    .endif
.endmacro

.macro _op_x2 op, arg
    .if _is_immediate {arg}
      .define _iv_ _immediate_value {arg}
      .if .const(_iv_) && .hibyte(_iv_) = .bankbyte(_iv_)
        ;; already loaded into relevant register
      .else
        op #.bankbyte(_iv_)
      .endif
      .undefine _iv_
    .else
        op arg+2
    .endif
.endmacro

.macro _op_x3 op, arg
    .if _is_immediate {arg}
      .define _iv_ _immediate_value {arg}
      .if .const(_iv_) && .bankbyte(_iv_) = .hibyte(.hiword(_iv_))
        ;; already loaded into relevant register
      .else
        op #.hibyte(.hiword(_iv_))
      .endif
      .undefine _iv_
    .else
        op arg+3
    .endif
.endmacro

;;; Aliases for 16-bit helpers
.define _op_lo _op_b0
.define _op_hi _op_b1
.define _op_hx _op_x1

;;; ============================================================
;;; 8-bit pseudo-ops

.macro copy8 arg1, arg2, arg3, arg4
    .if (_is_register {arg2}) && (_is_register {arg4})
        ;; indexed load/indexed store
        lda     arg1,arg2
        sta     arg3,arg4
    .elseif _is_register {arg2}
        ;; indexed load variant (arg2 is x or y)
        lda     arg1,arg2
        sta     arg3
    .elseif _is_register {arg3}
        ;; indexed store variant (arg3 is x or y)
        lda     arg1
        sta     arg2,arg3
    .else
        lda     arg1
        sta     arg2
    .endif
.endmacro

.macro swap8 arg1, arg2, arg3, arg4
    .if (_is_register {arg2}) && (_is_register {arg4})
        ;; indexed load/indexed store
        lda     arg1,arg2
        pha
        lda     arg3,arg4
        sta     arg1,arg2
        pla
        sta     arg3,arg4
    .elseif _is_register {arg2}
        ;; indexed load variant (arg2 is x or y)
        lda     arg1,arg2
        pha
        lda     arg3
        sta     arg1,arg2
        pla
        sta     arg3
    .elseif _is_register {arg3}
        ;; indexed store variant (arg3 is x or y)
        lda     arg1
        pha
        lda     arg2,arg3
        sta     arg1
        pla
        sta     arg2,arg3
    .else
        lda     arg1
        pha
        lda     arg2
        sta     arg1
        pla
        sta     arg2
    .endif
.endmacro

;;; ============================================================
;;; 16-bit pseudo-ops

;;; Load A,X
;;;    ldax #$1234      ; immediate (optimized if lo=hi)
;;;    ldax $1234       ; absolute
;;;    ldax $1234,y     ; absolute,y
.macro ldax arg, reg
    .ifnblank reg
        lda    arg, reg
        ldx    arg+1, reg
    .elseif !_is_immediate {arg}
        lda   arg
        ldx   arg+1
    .else
        lda   #.lobyte(_immediate_value {arg})
      .if .const(_immediate_value {arg})
       .if .lobyte(_immediate_value {arg}) = .hibyte(_immediate_value {arg})
        tax                     ; lo=hi
       .else
        ldx   #.hibyte(_immediate_value {arg})
       .endif
      .else
        ldx   #.hibyte(_immediate_value {arg})
      .endif
    .endif
.endmacro

;;; Load A,Y
;;;    lday #$1234      ; immediate (optimized if lo=hi)
;;;    lday $1234       ; absolute
.macro lday arg
    .if !_is_immediate {arg}
        lda     arg
        ldx     arg+1
    .else
        lda     #.lobyte(_immediate_value {arg})
      .if .const(_immediate_value {arg})
       .if .lobyte(_immediate_value {arg}) = .hibyte(_immediate_value {arg})
        tay                     ; lo=hi
       .else
        ldy     #.hibyte(_immediate_value {arg})
       .endif
      .else
        ldy     #.hibyte(_immediate_value {arg})
      .endif
    .endif
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

;;; Store Y,X
;;;    styx $1234       ; absolute
.macro styx arg
        sty     arg
        stx     arg+1
.endmacro

;;; Store X,Y
;;;    stxy $1234       ; absolute
.macro stxy arg
        stx     arg
        sty     arg+1
.endmacro

;;; Increment X,Y as a 16-bit number (x lo, y hi)
.macro inxy
        .local skip
        inx
        bne     skip
        iny
skip:
.endmacro

;;; Core for add16/sub16
.macro _addsub16 op, carryOp, arg1, arg2, arg3, arg4, arg5, arg6
    .if (_is_register {arg2}) && (_is_register {arg4}) && (_is_register {arg6})
        ;; xxx16 $1111,x, $2222,x, $3333,x
        lda     arg1,arg2
        carryOp
        op      arg3,arg4
        sta     arg5,arg6
        lda     arg1+1,arg2
        op      arg3+1,arg4
        sta     arg5+1,arg6
    .elseif (_is_register {arg2}) && (_is_register {arg4})
        ;; xxx16 $1111,x, $2222,x, $3333
        lda     arg1,arg2
        carryOp
        op      arg3,arg4
        sta     arg5
        lda     arg1+1,arg2
        op      arg3+1,arg4
        sta     arg5+1
    .elseif (_is_register {arg2}) && (_is_register {arg5})
        ;; xxx16 $1111,x, $2222, $3333,x
        ;; xxx16 $1111,x, #$2222, $3333,x
        lda     arg1,arg2
        carryOp
        _op_lo  op, {arg3}
        sta     arg4,arg5
        lda     arg1+1,arg2
        _op_hi  op, {arg3}
        sta     arg4+1,arg5
    .elseif (_is_register {arg3}) && (_is_register {arg5})
        ;; xxx16 $1111, $2222,x, $3333,x
        ;; xxx16 #$1111, $2222,x, $3333,x
        _op_lo  lda, {arg1}
        carryOp
        op      arg2,arg3
        sta     arg4,arg5
        _op_hi  lda, {arg1}
        op      arg2+1,arg3
        sta     arg4+1,arg5
    .elseif _is_register {arg2}
        ;; xxx16 $1111,x, $2222, $3333
        ;; xxx16 $1111,x, #$2222, $3333
        lda     arg1,arg2
        carryOp
        _op_lo  op, {arg3}
        sta     arg4
        lda     arg1+1,arg2
        _op_hi  op, {arg3}
        sta     arg4+1
    .elseif _is_register {arg3}
        ;; xxx16 $1111, $2222,x $3333
        ;; xxx16 #$1111, $2222,x $3333
        _op_lo  lda, {arg1}
        carryOp
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
        carryOp
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
        carryOp
        _op_lo op, {arg2}
        sta     arg3
        _op_hi lda, {arg1}
        _op_hi op, {arg2}
        sta     arg3+1
    .endif
.endmacro


;;; Core for add16in/sub16in
.macro _addsub16in op, carryOp, arg1, arg2, arg3, arg4, arg5, arg6
    .if _is_y_register {arg2} && _is_y_register {arg4} && _is_y_register {arg6}
        ;; xxx16in ($1111),y, ($2222),y, ($3333),y
        lda     (arg1),y
        carryOp
        op      (arg3),y
        sta     (arg5),y
        iny
        lda     (arg1),y
        op      (arg3),y
        sta     (arg5),y
    .elseif _is_y_register {arg2} && _is_y_register {arg4}
        ;; xxx16in ($1111),y, ($2222),y, $3333
        ;; xxx16in ($1111),y, ($2222),y, #$3333
        lda     (arg1),y
        carryOp
        op      (arg3),y
        sta     arg5
        iny
        lda     (arg1),y
        op      (arg3),y
        sta     arg5+1
    .elseif _is_y_register {arg2} && _is_y_register {arg5}
        ;; xxx16in ($1111),y, $2222, ($3333),y
        ;; xxx16in ($1111),y, #$2222, ($3333),y
        lda     (arg1),y
        carryOp
        _op_lo  op, {arg3}
        sta     (arg4),y
        iny
        lda     (arg1),y
        _op_hi  op, {arg3}
        sta     (arg4),y
    .elseif _is_y_register {arg3} && _is_y_register {arg5}
        ;; xxx16in $1111, ($2222),y, ($3333),y
        ;; xxx16in #$1111, ($2222),y, ($3333),y
        _op_lo  lda, {arg1}
        carryOp
        op      (arg2),y
        sta     (arg4),y
        iny
        _op_hi  lda, {arg1}
        op      (arg2),y
        sta     (arg4),y
    .elseif _is_y_register {arg2}
        ;; xxx16in ($1111),y, $2222, $3333
        ;; xxx16in ($1111),y, #$2222, $3333
        ;; xxx16in ($1111),y, $2222, #$3333
        ;; xxx16in ($1111),y, #$2222, #$3333
        lda     (arg1),y
        carryOp
        _op_lo  op, {arg3}
        sta     arg4
        iny
        lda     (arg1),y
        _op_hi  op, {arg3}
        sta     arg4+1
    .elseif _is_y_register {arg3}
        ;; xxx16in $1111, ($2222),y $3333
        ;; xxx16in #$1111, ($2222),y $3333
        ;; xxx16in $1111, ($2222),y #$3333
        ;; xxx16in #$1111, ($2222),y #$3333
        _op_lo  lda, {arg1}
        carryOp
        op      (arg2),y
        sta     arg4
        iny
        _op_hi  lda, {arg1}
        op      (arg2),y
        sta     arg4+1
    .elseif _is_y_register {arg4}
        ;; xxx16in $1111, $2222, $3333,y
        ;; xxx16in #$1111, $2222, $3333,y
        ;; xxx16in $1111, #$2222, $3333,y
        ;; xxx16in #$1111, #$2222, $3333,y
        _op_lo  lda, {arg1}
        carryOp
        _op_lo  op, {arg2}
        sta     (arg3),y
        iny
        _op_hi  lda, {arg1}
        _op_hi  op, {arg2}
        sta     (arg3),y
    .else
        .error "Indirect indexed required at least one use of y reg"
    .endif
.endmacro

;;; Add arg1 to arg2, store to arg3
;;;    add16 $1111, $2222, $3333        ; absolute, absolute, absolute
;;;    add16 $1111, #$2222, $3333       ; absolute, immediate, absolute
;;;    add16 $1111,x, $2222, $3333      ; indexed, absolute, absolute
;;;    add16 $1111, $2222,x, $3333      ; absolute, indexed, absolute
;;;    add16 $1111, $2222, $3333,x      ; absolute, absolute, indexed
;;;    add16 $1111,x, $2222, $3333,x    ; indexed, absolute, indexed
;;;    add16 $1111, $2222,x, $3333,x    ; absolute, indexed, indexed
;;;    add16 $1111,x, $2222,x, $3333,x  ; indexed, indexed, indexed
.macro add16 arg1, arg2, arg3, arg4, arg5, arg6
    _addsub16 adc, clc, arg1, arg2, arg3, arg4, arg5, arg6
.endmacro
;;; (as above, but indirect indexed, y register is incremented)
.macro add16in arg1, arg2, arg3, arg4, arg5, arg6
    _addsub16in adc, clc, arg1, arg2, arg3, arg4, arg5, arg6
.endmacro

;;; Add arg1 (absolute) to arg2 (8-bit absolute/immediate), store to arg3
;;;    add16_8 $1111, #$22, $3333       ; absolute, immediate, absolute
;;;    add16_8 $1111, $22, $3333        ; absolute, absolute, absolute
;;; Add arg1 (absolute) to arg2 (8-bit absolute/immediate), store to arg1
;;;    add16_8 $1111, #$22              ; absolute, immediate
;;;    add16_8 $1111, $22               ; absolute, absolute
.macro add16_8 arg1, arg2, arg3
    .ifblank arg3
        .local skip
        _op_lo  lda, {arg1}
        clc
        adc     arg2
        sta     arg1
        bcc     skip
        _op_hi  inc, {arg1}
skip:
    .else
        _op_lo  lda, {arg1}
        clc
        adc     arg2
        sta     arg3
        _op_hi  lda, {arg1}
        adc     #0
        sta     arg3+1
    .endif
.endmacro

;;; Add A,X to arg1 (immediate or absolute), store to arg2
;;;    addax #$1111, $3333       ; immediate, absolute
;;;    addax $1111, $3333        ; absolute, absolute
;;;    addax $1111               ; absolute
.macro addax arg1, arg2
    .ifblank arg2
        clc
        adc     arg1
        sta     arg1
        txa
        adc     arg1+1
        sta     arg1+1
    .else
        clc
        _op_lo adc, {arg1}
        sta     arg2
        txa
        _op_hi adc, {arg1}
        sta     arg2+1
    .endif
.endmacro

;;; Add arg1 (8 bit value) into A,X, optionally store to arg2
;;;    addax8 #$11       ; immediate
;;;    addax8 $11        ; absolute
;;;    addax8 #$11,$2222 ; immediate, absolute
;;;    addax8 $11,$2222  ; absolute, absolute
.macro addax8  arg1, arg2
.local skip
        clc
        adc     arg1
    .ifnblank arg2
        sta     arg2
    .endif
        bcc     skip
        inx
skip:
    .ifnblank arg2
        stx     arg2+1
    .endif
.endmacro

;;; Subtract arg1 (8 bit value) from A,X, optionally store to arg2
;;;    subax8 #$11       ; immediate
;;;    subax8 $11        ; absolute
;;;    subax8 #$11,$2222 ; immediate, absolute
;;;    subax8 $11,$2222  ; absolute, absolute
.macro subax8  arg1, arg2
.local skip
        sec
        sbc     arg1
    .ifnblank arg2
        sta     arg2
    .endif
        bcs     skip
        dex
skip:
    .ifnblank arg2
        stx     arg2+1
    .endif
.endmacro

;;; Add X,Y into arg1 (X,Y remain unchanged)
;;;    addxy #$1111, $3333       ; immediate, absolute
;;;    addxy $1111, $3333        ; absolute, absolute
;;;    addxy $1111               ; absolute
.macro addxy arg1, arg2
    .ifblank arg2
        clc
        txa
        adc     arg1
        sta     arg1
        tya
        adc     arg1+1
        sta     arg1+1
    .else
        clc
        txa
        _op_lo adc, {arg1}
        sta     arg2
        tya
        _op_hi adc, {arg1}
        sta     arg2+1
    .endif
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
;;;    sub16 $1111, $2222,x, $3333,x    ; absolute, indexed, indexed
;;;    sub16 $1111,x, $2222,x $3333,x   ; indexed, indexed, indexed
.macro sub16 arg1, arg2, arg3, arg4, arg5, arg6
    _addsub16 sbc, sec, arg1, arg2, arg3, arg4, arg5, arg6
.endmacro
;;; (as above, but indirect indexed, y register incremented)
.macro sub16in arg1, arg2, arg3, arg4, arg5, arg6
    _addsub16in sbc, sec, arg1, arg2, arg3, arg4, arg5, arg6
.endmacro


;;; Subtract arg2 from arg1, store to arg3
;;;    sub16_8 #$1111, #$22, $3333      ; immediate, immediate, absolute
;;;    sub16_8 #$1111, $22, $3333       ; immediate, absolute, absolute
;;;    sub16_8 $1111, #$22, $3333       ; absolute, immediate, absolute
;;;    sub16_8 $1111, $22, $3333        ; absolute, absolute, absolute
;;; Subtract arg2 (absolute) from arg1 (8-bit absolute/immediate), store to arg1
;;;    add16_8 $1111, #$22              ; absolute, immediate
;;;    add16_8 $1111, $22               ; absolute, absolute
.macro sub16_8 arg1, arg2, arg3
    .ifblank arg3
        .local skip
        _op_lo  lda, {arg1}
        sec
        sbc     arg2
        sta     arg1
        bcs     skip
        _op_hi  dec, {arg1}
skip:
    .else
        _op_lo  lda, {arg1}
        sec
        sbc     arg2
        sta     arg3
        _op_hi  lda, {arg1}
        sbc     #0
        sta     arg3+1
    .endif
.endmacro

;;; Copy 16-bit value
;;;    copy16 #$1111, $2222     ; immediate, absolute
;;;    copy16 $1111, $2222      ; absolute, absolute
;;;    copy16 $1111,x, $2222    ; indirect load, absolute store
;;;    copy16 $1111, $2222,x    ; absolute load, indirect store
;;;    copy16 $1111,x $2222,x   ; indirect load, indirect store
;;;    copy16 #$1111, $2222,x   ; immediate load, indirect store
.macro copy16 arg1, arg2, arg3, arg4
    .if (_is_register {arg2}) && (_is_register {arg4})
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
        _op_hx  lda, {arg1}     ; optimized
        sta     arg2+1,arg3
    .else
        _op_lo  lda, {arg1}
        sta     arg2
        _op_hx  lda, {arg1}     ; optimized
        sta     arg2+1
    .endif
.endmacro

;;; Copy 16-bit value, indexed indirect, y register incremented
;;;    copy16in #$1111, ($2222),y   ; immediate load, indexed indirect store
;;;    copy16in $1111, ($2222),y    ; absolute load, indexed indirect store
;;;    copy16in ($1111),y, $2222    ; indexed indirect load, absolute store
;;;    copy16in ($1111),y ($2222),y ; indexed indirect load, indexed indirect store
.macro copy16in arg1, arg2, arg3, arg4
    .if _is_y_register {arg2} && _is_y_register {arg4}
        ;; copy16in ($1111),y, ($2222),y
        lda     (arg1),y
        sta     (arg3),y
        iny
        lda     (arg1),y
        sta     (arg3),y
    .elseif _is_y_register {arg2}
        ;; copy16in ($1111),y, $2222
        lda     (arg1),y
        sta     arg3
        iny
        lda     (arg1),y
        sta     arg3+1
    .elseif _is_y_register {arg3}
        ;; copy16in #$1111, ($2222),y
        ;; copy16in $1111, ($2222),y
        _op_lo  lda, {arg1}
        sta     (arg2),y
        iny
        _op_hx  lda, {arg1}
        sta     (arg2),y
    .else
        .error "Indirect indexed required at least one use of y reg"
    .endif
.endmacro

;;; Copy low/high 16-bit value
;;; 8 bits from $1111[,x] to $3333
;;; 8 bits from $2222[,x] to $3333+1
;;; 8 bits from $1111 to $2222
;;; 8 bits from $1111+1 to $3333
;;;    copylohi $1111, $2222, $3333        ; absolute, absolute
;;;    copylohi $1111,x, $2222,x, $3333    ; indirect load, absolute store
;;;    copylohi $1111, $2222,x, $3333,x    ; absolute load, indirect store
.macro copylohi arg1, arg2, arg3, arg4, arg5
    .if (_is_register {arg2}) && (_is_register {arg4})
        ;; indexed load
        lda     arg1,arg2
        sta     arg5
        lda     arg3,arg4
        sta     arg5+1
    .elseif _is_register {arg3}
        ;; indexed store
        lda     arg1
        sta     arg2,arg3
        lda     arg1+1
        sta     arg4,arg5
    .else
        lda     arg1
        sta     arg3
        lda     arg2
        sta     arg3+1
    .endif
.endmacro



;;; Unsigned compare 16-bit values - test C (BCC/BCS) for ordering
;;; WARNING: Z (for equality) is NOT set per CMP; use ecmp16 if needed.
;;;    cmp16 #$1111, #$2222    ; immediate, immediate (silly, but supported)
;;;    cmp16 #$1111, $2222     ; immediate, absolute
;;;    cmp16 $1111, #$2222     ; absolute, immediate
;;;    cmp16 $1111, $2222      ; absolute, absolute
;;;    cmp16 $1111,x, $2222    ; indexed, absolute
;;;    cmp16 $1111, $2222,x    ; absolute, indexed
;;;    cmp16 $1111,x, #$2222   ; indexed, immediate
;;;    cmp16 #$1111, $2222,x   ; immediate, indexed
;;;    cmp16 $1111,x, $2222,x  ; indexed, indexed
.macro cmp16 arg1, arg2, arg3, arg4
    .if (_is_register {arg2}) && (_is_register {arg4})
        ;; indexed, indexed
        lda     arg1,arg2
        cmp     arg3,arg4
        lda     arg1+1,arg2
        sbc     arg3+1,arg4
    .elseif _is_register {arg2}
        ;; indexed, absolute/immediate
        lda     arg1,arg2
        _op_lo  cmp, {arg3}
        lda     arg1+1,arg2
        _op_hi  sbc, {arg3}
    .elseif _is_register {arg3}
        ;; absolute/immediate, indexed
        _op_lo  lda, {arg1}
        cmp     arg2,arg3
        _op_hi  lda, {arg1}
        sbc     arg2+1,arg3
    .else
        ;; absolute/immediate, absolute/immediate
        _op_lo  lda, {arg1}
        _op_lo  cmp, {arg2}
        _op_hi  lda, {arg1}
        _op_hi  sbc, {arg2}
    .endif
.endmacro

;;; Signed compare 16-bit values - test N (BPL/BMI) for ordering
;;; (http://6502.org/tutorials/compare_beyond.html#6)
;;; WARNING: C (for ordering) and Z (for equality) are NOT set per CMP.
;;;    scmp16 #$1111, #$2222    ; immediate, immediate (silly, but supported)
;;;    scmp16 #$1111, $2222     ; immediate, absolute
;;;    scmp16 $1111, #$2222     ; absolute, immediate
;;;    scmp16 $1111, $2222      ; absolute, absolute
;;;    scmp16 $1111,x, $2222    ; indexed, absolute
;;;    scmp16 $1111, $2222,x    ; absolute, indexed
;;;    scmp16 $1111,x, $2222,x  ; indexed, indexed
.macro scmp16 arg1, arg2, arg3, arg4
        cmp16 arg1,arg2,arg3,arg4
    .local skip
        bvc     skip
        eor     #$80
skip:
.endmacro

;;; Equality compare 16-bit values - test Z (BEQ/BNE) for equality, or C (BCC/BCS) for ordering.
;;; NOTE: Use cmp16 (smaller code) if Z is not needed.
;;;    ecmp16 #$1111, #$2222   ; immediate, immediate (silly, but supported)
;;;    ecmp16 #$1111, $2222    ; immediate, absolute
;;;    ecmp16 $1111, #$2222    ; absolute, immediate
;;;    ecmp16 $1111, $2222     ; absolute, absolute
;;;    ecmp16 $1111,x, $2222   ; indexed, absolute
;;;    ecmp16 $1111, $2222,x   ; absolute, indexed
;;;    ecmp16 $1111,x, #$2222  ; indexed, immediate
;;;    ecmp16 #$1111, $2222,x  ; immediate, indexed
;;;    ecmp16 $1111,x, $2222,x ; indexed, indexed
.macro ecmp16 arg1, arg2, arg3, arg4
    .local skip
        ;; Note that high bytes are compared before low bytes because
        ;; of the early exit when not equal - we want the high byte to
        ;; domimate the ordering.
    .if (_is_register {arg2}) && (_is_register {arg4})
        ;; indexed, indexed
        lda     arg1+1,arg2
        cmp     arg3+1,arg4
        bne     skip
        lda     arg1,arg2
        cmp     arg3,arg4
    .elseif _is_register {arg2}
        ;; indexed, absolute/immediate
        lda     arg1+1,arg2
        _op_hi  cmp, {arg3}
        bne     skip
        lda     arg1,arg2
        _op_lo  cmp, {arg3}
    .elseif _is_register {arg3}
        ;; absolute/immediate, indexed
        _op_hi  lda, {arg1}
        cmp     arg2+1,arg3
        bne     skip
        _op_lo  lda, {arg1}
        cmp     arg2,arg3
    .else
        ;; absolute/immediate, absolute/immediate
        _op_hi  lda, {arg1}
        _op_hi  cmp, {arg2}
        bne     skip
        _op_lo  lda, {arg1}
        _op_lo  cmp, {arg2}
    .endif
skip:
.endmacro



;;; Shift 16-bit values
;;;    lsr16 $1111      ; absolute
.macro lsr16 arg1
        lsr     arg1+1
        ror     arg1
.endmacro

;;;    asl16 $1111      ; absolute
.macro asl16 arg1
        asl     arg1
        rol     arg1+1
.endmacro

;;; "Arithmetic Shift Right" i.e. signed division by 2
;;;    asr16 $1111      ; absolute
.macro asr16 arg1
        lda     arg1+1
        rol
        ror     arg1+1
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

;;; Decrement 16-bit value
.macro dec16    arg
        .local skip
        lda     arg
        bne     skip
        dec     arg+1
skip:   dec     arg
.endmacro

;;; Push 16-bit value in A,X
.macro phax
        pha
        txa
        pha
.endmacro

;;; Pull 16-bit value to A,X
.macro plax
        pla
        tax
        pla
.endmacro

;;; Push a 16-bit value
.macro push16 arg
        _op_lo  lda, {arg}
        pha
        _op_hi  lda, {arg}
        pha
.endmacro

;;; ============================================================
;;; 24-bit pseudo-ops

;;; Copy 24-bit value
;;;    copy24 #$111111, $2222 ; immediate, absolute
;;;    copy24 $1111, $2222    ; absolute, absolute
.macro copy24 arg1, arg2
        _op_b0  lda, {arg1}
        sta     arg2
        _op_x1  lda, {arg1}     ; optimized
        sta     arg2+1
        _op_x2  lda, {arg1}     ; optimized
        sta     arg2+2
.endmacro


;;; Increment 24-bit value
.macro inc24    arg
        .local skip
        inc     arg
        bne     skip
        inc     arg+1
        bne     skip
        inc     arg+2
skip:
.endmacro

;;;    ucmp24 #$111111, $2222 ; immediate, absolute
;;;    ucmp24 $1111, $2222    ; absolute, absolute
.macro ucmp24   arg1, arg2
        _op_b0  lda, {arg1}
        _op_b0  cmp, {arg2}
        _op_b1  lda, {arg1}
        _op_b1  sbc, {arg2}
        _op_b2  lda, {arg1}
        _op_b2  sbc, {arg2}
.endmacro

;;;    ecmp24 #$111111, $2222 ; immediate, absolute
;;;    ecmp24 $1111, $2222    ; absolute, absolute
.macro ecmp24   arg1, arg2
        .local skip
        _op_b0  lda, {arg1}
        _op_b0  cmp, {arg2}
        bne     skip
        _op_b1  lda, {arg1}
        _op_b1  cmp, {arg2}
        bne     skip
        _op_b2  lda, {arg1}
        _op_b2  cmp, {arg2}
skip:
.endmacro

;;; ============================================================
;;; 32-bit pseudo-ops

;;; Core for add32/sub32
.macro _addsub32 op, carryOp, arg1, arg2, arg3
        carryOp
        _op_b0 lda, {arg1}
        _op_b0 op, {arg2}
        sta     arg3
        _op_b1 lda, {arg1}
        _op_b1 op, {arg2}
        sta     arg3+1
        _op_b2 lda, {arg1}
        _op_b2 op, {arg2}
        sta     arg3+2
        _op_b3 lda, {arg1}
        _op_b3 op, {arg2}
        sta     arg3+3
.endmacro

;;; absolute  + absolute  => absolute
;;; immediate + absolute  => absolute
;;; absolute  + immediate => absolute
.macro add32 arg1, arg2, arg3
    _addsub32 adc, clc, arg1, arg2, arg3
.endmacro

;;; absolute  - absolute  => absolute
;;; immediate - absolute  => absolute
;;; absolute  - immediate => absolute
.macro sub32 arg1, arg2, arg3
    _addsub32 sbc, sec, arg1, arg2, arg3
.endmacro

;;; Copy 32-bit value
;;;    copy32 #$11111111, $2222 ; immediate, absolute
;;;    copy32 $1111, $2222      ; absolute, absolute
.macro copy32 arg1, arg2
        _op_b0  lda, {arg1}
        sta     arg2
        _op_x1  lda, {arg1}     ; optimized
        sta     arg2+1
        _op_x2  lda, {arg1}     ; optimized
        sta     arg2+2
        _op_x3  lda, {arg1}     ; optimized
        sta     arg2+3
.endmacro

;;; Shift 32-bit values
;;;    asl32 $1111      ; absolute
.macro asl32 arg1
        asl     arg1
        rol     arg1+1
        rol     arg1+2
        rol     arg1+3
.endmacro

;;;    lsr32 $1111      ; absolute
.macro lsr32 arg1
        lsr     arg1+3
        ror     arg1+2
        ror     arg1+1
        ror     arg1
.endmacro



