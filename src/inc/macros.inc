.feature leading_dot_in_identifiers

;;; ============================================================
;;; Generic Macros
;;; ============================================================

.define _is_immediate(arg)       (.match (.mid (0, 1, {arg}), #))
.define _is_register(arg)        (.match ({arg}, x) .or .match ({arg}, y))
.define _is_y_register(arg)      (.match ({arg}, y))
.define _immediate_value(arg)    (.right (.tcount ({arg})-1, {arg}))

;;; 16-bit helpers
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

;;; 32-bit helpers
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

;;; ============================================================
;;; Strings

;;; Length-prefixed string
;;;
;;; Can include control chars by using:
;;;
;;; PASCAL_STRING {"abc",$0D,"def"}

.macro PASCAL_STRING str,res
        .local  data
        .local  end
        .byte   end - data
data:   .byte   str
end:
.if     .paramcount > 1
        .res    res - (end - data), 0
.endif
.endmacro

.define TO_LOWER(char) (char | %00100000)

;;; ============================================================
;;; Pad with zeros to the given address

.macro PAD_TO addr
    .if ((addr) - *) = 0
        ;; no-op
    .elseif (addr - *) > 0
        ;; .out .sprintf("  Padding: $%04X bytes ($%04X - $%04X)", ((addr) - *), *, (addr))
        .res    addr - *
    .else
        .error .sprintf("Padding offset %d", addr - *)
    .endif
.endmacro

;;; ============================================================
;;; Pad if necessary to avoid a page boundary

.macro PAD_IF_NEEDED_TO_AVOID_PAGE_BOUNDARY
    .if .lobyte(*) = $FF
        .out .sprintf("Padding 1 byte to avoid page boundary at $%04X", *)
        .res    1
    .endif
.endmacro

;;; ============================================================
;;; Common patterns

.define AS_BYTE(arg)        (arg) & $FF
.define AS_WORD(arg)        (arg) & $FFFF

;;; Return a value in A - immediate or absolute
.macro return arg
        lda     arg
        rts
.endmacro

;;; Return a value in A,X - immediate or absolute
.macro return16 arg
        _op_lo  lda, {arg}
        _op_hi  ldx, {arg}
        rts
.endmacro

.macro copy8 arg1, arg2, arg3, arg4
    .if _is_register {arg2} && _is_register {arg4}
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

;;; This uses BIT to treat the next 2-byte instruction as data.
;;; Note that it has side effects on flags. If the high byte
;;; is potentially $C0 then it must not be used.
.macro SKIP_NEXT_2_BYTE_INSTRUCTION
        .byte   $2C             ; OPC_BIT_abs
.endmacro

;;; ============================================================
;;; Calls with one parameter (address in A,X) or two (Y, plus A,X)
;;; Usage: param_call target, ax_arg
;;;        param_call target, y_arg, ax_arg

.macro param_call target, param1, param2
.if     .paramcount = 2
        lda     #<(param1)
        ldx     #>(param1)
.elseif .paramcount = 3
        ldy     #param1
        lda     #<(param2)
        ldx     #>(param2)
.else
        .error "incorrect macro usage"
.endif
        jsr     target
.endmacro

.macro param_call_indirect target, param1, param2
.if     .paramcount = 2
        lda     param1
        ldx     param1+1
.elseif .paramcount = 3
        ldy     #param1
        lda     param2
        ldx     param2+1
.else
        .error "incorrect macro usage"
.endif
        jsr     target
.endmacro

.macro param_jump target, param1, param2
.if     .paramcount = 2
        lda     #<(param1)
        ldx     #>(param1)
.elseif .paramcount = 3
        ldy     #param1
        lda     #<(param2)
        ldx     #>(param2)
.else
        .error "incorrect macro usage"
.endif
        jmp     target
.endmacro

.macro param_jump_indirect target, param1, param2
.if     .paramcount = 2
        lda     param1
        ldx     param1+1
.elseif .paramcount = 3
        ldy     #param1
        lda     param2
        ldx     param2+1
.else
        .error "incorrect macro usage"
.endif
        jmp     target
.endmacro


;;; ============================================================
;;; Long branch pseudo-ops

.macpack longbranch

;;; ============================================================
;;; 16-bit pseudo-ops

;;; Load A,X
;;;    ldax #$1234      ; immediate
;;;    ldax $1234       ; absolute
;;;    ldax $1234,y     ; absolute,y
.macro ldax arg, reg
    .if .paramcount > 1
        lda    arg, reg
        ldx    arg+1, reg
    .else
        _op_lo lda, {arg}
        _op_hi ldx, {arg}
    .endif
.endmacro

;;; Load A,Y
;;;    lday #$1234      ; immediate
;;;    lday $1234       ; absolute
.macro lday arg
        _op_lo lda, {arg}
        _op_hi ldy, {arg}
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
    .elseif _is_register {arg3} && _is_register {arg5}
        ;; xxx16 $1111, $2222,x, $3333,x
        ;; xxx16 #$1111, $2222,x, $3333,x
        _op_lo  lda, {arg1}
        opc
        op      arg2,arg3
        sta     arg4,arg5
        _op_hi  lda, {arg1}
        op      arg2+1,arg3
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


;;; Core for add16in/sub16in
.macro _addsub16in op, opc, arg1, arg2, arg3, arg4, arg5, arg6
    .if _is_y_register {arg2} && _is_y_register {arg4} && _is_y_register {arg6}
        ;; xxx16in ($1111),y, ($2222),y, ($3333),y
        lda     (arg1),y
        opc
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
        opc
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
        opc
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
        opc
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
        opc
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
        opc
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
        opc
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
      .if .xmatch ({arg1}, #0)
        ;; Common special case
        lda     #0
        sta     arg2,arg3
        sta     arg2+1,arg3
      .else
        _op_lo  lda, {arg1}
        sta     arg2,arg3
        _op_hi  lda, {arg1}
        sta     arg2+1,arg3
      .endif
    .else
      .if .xmatch ({arg1}, #0)
        ;; Common special case
        lda     #0
        sta     arg2
        sta     arg2+1
      .else
        _op_lo  lda, {arg1}
        sta     arg2
        _op_hi  lda, {arg1}
        sta     arg2+1
      .endif
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
        _op_hi  lda, {arg1}
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
    .if _is_register {arg2}
        ;; indexed load
        ;; arg4 is also a register
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
    .if _is_register {arg2} && _is_register {arg4}
        ;; indexed variant (arg2+arg4 is x or y)
        lda     arg1,arg2
        cmp     arg3,arg4
        lda     arg1+1,arg2
        sbc     arg3+1,arg4
    .elseif _is_register {arg2}
        ;; indexed variant (arg2 is x or y)
        lda     arg1,arg2
        _op_lo  cmp, {arg3}
        lda     arg1+1,arg2
        _op_hi  sbc, {arg3}
    .elseif _is_register {arg3}
        ;; indexed variant (arg3 is x or y)
        _op_lo  lda, {arg1}
        cmp     arg2,arg3
        _op_hi  lda, {arg1}
        sbc     arg2+1,arg3
    .else
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
    .if _is_register {arg2} && _is_register {arg4}
        ;; indexed variant (arg2+arg4 is x or y)
        lda     arg1,arg2
        cmp     arg3,arg4
        bne     skip
        lda     arg1+1,arg2
        cmp     arg3+1,arg4
    .elseif _is_register {arg2}
        ;; indexed variant (arg2 is x or y)
        lda     arg1,arg2
        _op_lo  cmp, {arg3}
        bne     skip
        lda     arg1+1,arg2
        _op_hi  cmp, {arg3}
    .elseif _is_register {arg3}
        ;; indexed variant (arg3 is x or y)
        _op_lo  lda, {arg1}
        cmp     arg2,arg3
        bne     skip
        _op_hi  lda, {arg1}
        cmp     arg2+1,arg3
    .else
        _op_lo  lda, {arg1}
        _op_lo  cmp, {arg2}
        bne     skip
        _op_hi  lda, {arg1}
        _op_hi  cmp, {arg2}
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

;;; ============================================================
;;; 32-bit pseudo-ops

;;; Core for add32/sub32
.macro _addsub32 op, opc, arg1, arg2, arg3
        opc
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
      .if .xmatch ({arg1}, #0)
        ;; Common special case
        lda     #0
        sta     arg2
        sta     arg2+1
        sta     arg2+2
        sta     arg2+3
      .else
        _op_b0  lda, {arg1}
        sta     arg2
        _op_b1  lda, {arg1}
        sta     arg2+1
        _op_b2  lda, {arg1}
        sta     arg2+2
        _op_b3  lda, {arg1}
        sta     arg2+3
      .endif
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



;;; ============================================================
;;; Placed Param Blocks
;;; ============================================================

;;; Helper macros to set up a scoped block of parameters at a pre-determined
;;; address. Like .struct/.org, but also defines a label at the target
;;; address. Nested .struct can be used.
;;;
;;; Example:
;;;    .proc my_function
;;;            PARAM_BLOCK params, $82
;;;    arg1    .byte
;;;    arg2    .word
;;;    arg3    .res    7
;;;            END_PARAM_BLOCK
;;;
;;;            lda     params::arg1         ; equiv. to lda $82
;;;            lda     params::arg2         ; equiv. to lda $83
;;;            lda     params::arg3         ; equiv. to lda $85
;;;            lda     #params              ; equiv. to lda #$82
;;;            lda     #.sizeof(params)     ; equiv. to lda #10
;;;
;;; The `name` argument can be empty, in which case an anonymous block
;;; is used, with the parameters defined in the current scope.

.macro PARAM_BLOCK name, addr
    .ifnblank name
        WARN_IF_SHADOWING name
        name := addr
        .refto name
    .endif
        .struct name
        .org addr
.endmacro

.macro END_PARAM_BLOCK
        .endstruct
.endmacro


;;; ============================================================
;;; Structure Helpers
;;; ============================================================

.macro COPY_BYTES size, src, dst
.local loop
        ldx     #size - 1
loop:   lda     src,x
        sta     dst,x
        dex
        bpl     loop
.endmacro

.macro COPY_STRUCT type, src, dst
        COPY_BYTES .sizeof(type), src, dst
.endmacro

.macro COPY_BLOCK block, dst
        COPY_BYTES .sizeof(block), block, dst
.endmacro

.macro COPY_STRING src, dst
.local loop
        ldx     src
loop:   lda     src,x
        sta     dst,x
        dex
        cpx     #$FF
        bne     loop
.endmacro


;;; ============================================================
;;; Placed Procedures
;;; ============================================================
;;; Usage:
;;;    PROC_AT relocated_proc, $300
;;;       .assert * = $300, ...
;;;       ...
;;;    END_PROC_AT
;;;       .assert * = back to normal

.macro PROC_AT name, addr
        WARN_IF_SHADOWING name
.proc name
        .pushorg addr
.endmacro

.macro END_PROC_AT
        .poporg
.endproc ; name
.endmacro


;;; ============================================================
;;; Temporary org change, for relocated routines
;;; ============================================================
;;; Example:
;;; .pushorg $380
;;;     lda #$12
;;;     rts
;;; .poporg

__pushorg_depth__ .set 0

.macro .pushorg addr
        ::__pushorg_depth__ .set ::__pushorg_depth__ + 1
        .ident(.sprintf("__pushorg_saved__%d", ::__pushorg_depth__)) := *
        .org addr
        .ident(.sprintf("__pushorg_start__%d", ::__pushorg_depth__)) := *
.endmacro

.macro .poporg
        .org .ident(.sprintf("__pushorg_saved__%d", ::__pushorg_depth__)) + (* - .ident(.sprintf("__pushorg_start__%d", ::__pushorg_depth__)))
        ::__pushorg_depth__ .set ::__pushorg_depth__ - 1
.endmacro

;;; ============================================================
;;; Scope Helpers
;;; ============================================================

.macro PREDEFINE_SCOPE scope_name
    scope_name::__predefine_scope__ = 0
.endmacro

__shadow_warning_suppress_count__ .set 0

;;; TODO: More careful scoping throughout the project to eliminate these
.macro SUPPRESS_SHADOW_WARNING
::__shadow_warning_suppress_count__ .set ::__shadow_warning_suppress_count__ + 1
.endmacro

.macro UNSUPPRESS_SHADOW_WARNING
::__shadow_warning_suppress_count__ .set ::__shadow_warning_suppress_count__ - 1
.endmacro

.macro WARN_IF_SHADOWING ident
  .if !::__shadow_warning_suppress_count__
    .ifdef ident
        .warning .sprintf("Declaration of '%s' shadows existing '%s'", .string(ident), .string(ident))
    .endif
  .endif
.endmacro

;;; ============================================================
;;; Parameter Blocks - named scopes that indicate data
;;; ============================================================
;;; Example:
;;; .params label
;;; p1: .byte 0
;;; p2: .word 1234
;;; .endparams

.macro .params label
        WARN_IF_SHADOWING label
        .proc label
.endmacro

.macro .endparams
.endproc ; label
.endmacro


;;; ============================================================
;;; Assertions
;;; ============================================================

.macro ASSERT_EQUALS actual, expected, message
    .if .paramcount = 3
        .assert (actual) = (expected), error, .sprintf("expected %d actual %d: %s", (expected), (actual), message)
    .else
        .assert (actual) = (expected), error, .sprintf("expected %d actual %d", (expected), (actual))
    .endif
.endmacro

.macro ASSERT_NOT_EQUALS actual, expected, message
    .if .paramcount = 3
        .assert (actual) <> (expected), error, .sprintf("unexpected %d: %s", (expected), message)
    .else
        .assert (actual) <> (expected), error, .sprintf("unexpected %d", (expected))
    .endif
.endmacro

.macro ASSERT_ADDRESS addr, opt_message
    .if .paramcount = 2
        .assert * = (addr), error, .sprintf("%s mismatch, expected $%X actual $%X", opt_message, (addr), *)
    .else
        .assert * = (addr), error, .sprintf("Address mismatch, expected $%X actual $%X", (addr), *)
    .endif
.endmacro

.macro ASSERT_TABLE_SIZE name, size
        .assert * - name = size, error, .sprintf("Table size mismatch: %s (expected: %d, actual: %d)", .string(name), size, * - name)
.endmacro

.macro ASSERT_ADDRESS_TABLE_SIZE name, size
        .assert (* - name) = (size) * 2, error, .sprintf("Table size mismatch: %s (expected: %d, actual: %d)", .string(name), (size) * 2, * - name)
.endmacro

.macro ASSERT_RECORD_TABLE_SIZE name, size, record_length
        .assert (* - name) = (size) * (record_length), error, .sprintf("Table size mismatch: %s (expected: %d, actual: %d)", .string(name), (size) * (record_length), * - name)
.endmacro

.macro FALL_THROUGH_TO label
        .assert * = (label), error, .sprintf("Fall through expectation failed: %s", .string(label))
.endmacro

;;; ============================================================
;;; Flow Control
;;; ============================================================
;;; Usage:
;;;     bit foo
;;;     IF_NS
;;;     ...
;;;     ELSE_IF_VS ; optional
;;;     ...
;;;     ELSE ; optional
;;;     ...
;;;     END_IF
;;;
;;;     lda     foo
;;;     IF_A_EQ bar
;;;     ...
;;;     END_IF
;;;
;;; Macros:
;;;     IF_ZS           aliases: IF_ZERO, IF_EQ
;;;     IF_ZC           aliases: IF_NOT_ZERO, IF_NE
;;;     IF_CC           aliases: IF_LT
;;;     IF_CS           aliases: IF_GE
;;;     IF_VC
;;;     IF_VS
;;;     IF_NC           aliases: IF_POS, IF_PLUS
;;;     IF_NS           aliases: IF_NEG, IF_MINUS
;;; ... and ditto for ELSE_IF_*
;;;
;;;     IF_A_EQ / ELSE_IF_A_EQ
;;;     IF_A_NE / ELSE_IF_A_NE
;;;     IF_A_LT / ELSE_IF_A_LT
;;;     IF_A_GE / ELSE_IF_A_GE

;;; --------------------------------------------------
;;; Flow control infrastructure

;;; Increment a numeric variable; if not initialized, treated as 0
.macro __INC_IDENT__ ident
    .if .not(.defined(ident))
        ident .set 0
    .endif
    ident .set ident + 1
.endmacro

;;; Decrement a numeric variable
.macro __DEC_IDENT__ ident
        ident .set ident - 1
.endmacro

;;; Change to 1 to enable logging
.define __flow_debug__ 0

;;; A numeric variable for the current nesting depth of flow control
;;; structures. Incremented when entering a structure, decremented
;;; when leaving.
.define __flow_depth__ ::__depth__

;;; A numeric variable for the "Nth" flow control structure (if,
;;; do/while, etc) at depth D. Used to mint various identifiers unique
;;; to each, without using scopes. Incremented when entering a
;;; structure.
.define __flow_count_at_depth__ ::.ident(.sprintf("__flow_cad_%d__", __flow_depth__))

;;; Produce a unique identifier within this flow control structure.
;;; Usage: `__flow_ident__ {"else"}`
.define __flow_ident__(prefix) ::.ident(.sprintf("__flow_id_%s_%d_%d__", prefix, __flow_depth__, __flow_count_at_depth__))

;;; Produce unique identifierers for the end of each block
.define __flow_ident_counter__ __flow_ident__ {"counter"}
.define __flow_ident_block__ __flow_ident__ {.sprintf("eob%d", __flow_ident_counter__)}

;;; If debugging enabled, log a message with block details
.macro __FLOW_LOG__ msg
    .if __flow_debug__
        .out .sprintf("%s, depth: %d, bcad: %d", msg, __flow_depth__, __flow_count_at_depth__)
    .endif
.endmacro

;;; --------------------------------------------------
;;; IF/ELSE_IF/ELSE/END_IF

.macro _IF_BOP_ branchOp
        __INC_IDENT__ __flow_depth__
        __INC_IDENT__ __flow_count_at_depth__
        __INC_IDENT__ __flow_ident_counter__
        __FLOW_LOG__ "if"
        branchOp __flow_ident_block__
.endmacro

.macro _IF_COP_BOP_ compareOp, branchOp, arg1, arg2
        __INC_IDENT__ __flow_depth__
        __INC_IDENT__ __flow_count_at_depth__
        __INC_IDENT__ __flow_ident_counter__
        __FLOW_LOG__ "if"
.ifblank arg2
        compareOp arg1
        branchOp __flow_ident_block__
.else
        compareOp arg1,arg2
        branchOp __flow_ident_block__
.endif
.endmacro

.macro _ELSE_IF_BOP_ branchOp
        __FLOW_LOG__ "else_if"
        jmp     __flow_ident__ {"endif"}
        __flow_ident_block__ := *
        __INC_IDENT__ __flow_ident_counter__
        branchOp __flow_ident_block__
.endmacro

.macro _ELSE_IF_COP_BOP_ compareOp, branchOp, arg1, arg2
        __FLOW_LOG__ "else_if"
        jmp     __flow_ident__ {"endif"}
        __flow_ident_block__ := *
        __INC_IDENT__ __flow_ident_counter__
.ifblank arg2
        compareOp arg1
        branchOp __flow_ident_block__
.else
        compareOp arg1,arg2
        branchOp __flow_ident_block__
.endif
.endmacro

.macro ELSE
        __FLOW_LOG__ "else"
        jmp     __flow_ident__ {"endif"}
        __flow_ident_block__ := *
        __INC_IDENT__ __flow_ident_counter__
.endmacro

.macro END_IF
        .ifndef __flow_ident_block__
        __FLOW_LOG__ "no else"
        __flow_ident_block__ := *
        .endif

        __FLOW_LOG__ "endif"
        __flow_ident__ {"endif"} := *

        .refto __flow_ident__ {"endif"}
        __DEC_IDENT__ __flow_depth__
.endmacro

.macro ENDIF
        .error "Do you mean END_IF ?"
.endmacro

;;; --------------------------------------------------
;;; User-friendly IF/ELSE_IF macros

.define IF_ZS _IF_BOP_ bne
.define IF_ZC _IF_BOP_ beq
.define IF_CC _IF_BOP_ bcs
.define IF_CS _IF_BOP_ bcc
.define IF_NC _IF_BOP_ bmi
.define IF_NS _IF_BOP_ bpl
.define IF_VC _IF_BOP_ bvs
.define IF_VS _IF_BOP_ bvc

.define IF_ZERO     IF_ZS
.define IF_NOT_ZERO IF_ZC
.define IF_EQ       IF_ZS
.define IF_NE       IF_ZC
.define IF_GE       IF_CS
.define IF_LT       IF_CC
.define IF_PLUS     IF_NC
.define IF_MINUS    IF_NS
.define IF_POS      IF_NC
.define IF_NEG      IF_NS

.define IF_A_EQ _IF_COP_BOP_ cmp,bne,
.define IF_A_NE _IF_COP_BOP_ cmp,beq,
.define IF_A_LT _IF_COP_BOP_ cmp,bcs,
.define IF_A_GE _IF_COP_BOP_ cmp,bcc,

.define IF_X_EQ _IF_COP_BOP_ cpx,bne,
.define IF_X_NE _IF_COP_BOP_ cpx,beq,
.define IF_X_LT _IF_COP_BOP_ cpx,bcs,
.define IF_X_GE _IF_COP_BOP_ cpx,bcc,

.define IF_Y_EQ _IF_COP_BOP_ cpy,bne,
.define IF_Y_NE _IF_COP_BOP_ cpy,beq,
.define IF_Y_LT _IF_COP_BOP_ cpy,bcs,
.define IF_Y_GE _IF_COP_BOP_ cpy,bcc,

.define ELSE_IF_ZS _ELSE_IF_BOP_ bne
.define ELSE_IF_ZC _ELSE_IF_BOP_ beq
.define ELSE_IF_CC _ELSE_IF_BOP_ bcs
.define ELSE_IF_CS _ELSE_IF_BOP_ bcc
.define ELSE_IF_NC _ELSE_IF_BOP_ bmi
.define ELSE_IF_NS _ELSE_IF_BOP_ bpl
.define ELSE_IF_VC _ELSE_IF_BOP_ bvs
.define ELSE_IF_VS _ELSE_IF_BOP_ bvc

.define ELSE_IF_ZERO     ELSE_IF_ZS
.define ELSE_IF_NOT_ZERO ELSE_IF_ZC
.define ELSE_IF_EQ       ELSE_IF_ZS
.define ELSE_IF_NE       ELSE_IF_ZC
.define ELSE_IF_GE       ELSE_IF_CS
.define ELSE_IF_LT       ELSE_IF_CC
.define ELSE_IF_PLUS     ELSE_IF_NC
.define ELSE_IF_MINUS    ELSE_IF_NS
.define ELSE_IF_POS      ELSE_IF_NC
.define ELSE_IF_NEG      ELSE_IF_NS

.define ELSE_IF_A_EQ _ELSE_IF_COP_BOP cmp,bne,
.define ELSE_IF_A_NE _ELSE_IF_COP_BOP cmp,beq,
.define ELSE_IF_A_LT _ELSE_IF_COP_BOP cmp,bcs,
.define ELSE_IF_A_GE _ELSE_IF_COP_BOP cmp,bcc,

.define ELSE_IF_X_EQ _ELSE_IF_COP_BOP cpx,bne,
.define ELSE_IF_X_NE _ELSE_IF_COP_BOP cpx,beq,
.define ELSE_IF_X_LT _ELSE_IF_COP_BOP cpx,bcs,
.define ELSE_IF_X_GE _ELSE_IF_COP_BOP cpx,bcc,

.define ELSE_IF_Y_EQ _ELSE_IF_COP_BOP cpy,bne,
.define ELSE_IF_Y_NE _ELSE_IF_COP_BOP cpy,beq,
.define ELSE_IF_Y_LT _ELSE_IF_COP_BOP cpy,bcs,
.define ELSE_IF_Y_GE _ELSE_IF_COP_BOP cpy,bcc,

;;; --------------------------------------------------

;;; Usage:
;;;     ldx #17
;;;     DO
;;;     ...
;;;     dex
;;;     WHILE_POS
;;;
;;; Macros:
;;;     WHILE_ZS           aliases: WHILE_EQ, WHILE_ZERO
;;;     WHILE_ZC           aliases: WHILE_NE, WHILE_NOT_ZERO
;;;     WHILE_CC           aliases: WHILE_LT
;;;     WHILE_CS           aliases: WHILE_GE
;;;     WHILE_VC
;;;     WHILE_VS
;;;     WHILE_NC           aliases: WHILE_POS, WHILE_PLUS
;;;     WHILE_NS           aliases: WHILE_NEG, WHILE_MINUS

.macro DO
        __INC_IDENT__ __flow_depth__
        __INC_IDENT__ __flow_count_at_depth__

        __FLOW_LOG__ "do"
        __flow_ident__ {"do_while"} := *
.endmacro

.macro _WHILE_BOP_ branchOp
        __FLOW_LOG__ "while"
        branchOp __flow_ident__ {"do_while"}
        __DEC_IDENT__ __flow_depth__
.endmacro

.define WHILE_ZC _WHILE_BOP_ bne
.define WHILE_ZS _WHILE_BOP_ beq
.define WHILE_CC _WHILE_BOP_ bcc
.define WHILE_CS _WHILE_BOP_ bcs
.define WHILE_VC _WHILE_BOP_ bvc
.define WHILE_VS _WHILE_BOP_ bvs
.define WHILE_NC _WHILE_BOP_ bpl
.define WHILE_NS _WHILE_BOP_ bmi

.define WHILE_EQ WHILE_ZS
.define WHILE_NE WHILE_ZC
.define WHILE_ZERO WHILE_EQ
.define WHILE_NOT_ZERO WHILE_NE
.define WHILE_GE WHILE_CS
.define WHILE_LT WHILE_CC
.define WHILE_PLUS WHILE_NC
.define WHILE_MINUS WHILE_NS
.define WHILE_POS WHILE_NC
.define WHILE_NEG WHILE_NS

;;; --------------------------------------------------

;;; Macros:
;;;     RTS_IF_ZS           aliases: RTS_IF_EQ, RTS_IF_ZERO
;;;     RTS_IF_ZC           aliases: RTS_IF_NE, RTS_IF_NOT_ZERO
;;;     RTS_IF_CC           aliases: RTS_IF_LT
;;;     RTS_IF_CS           aliases: RTS_IF_GE
;;;     RTS_IF_VC
;;;     RTS_IF_VS
;;;     RTS_IF_NC           aliases: RTS_IF_POS, RTS_IF_PLUS
;;;     RTS_IF_NS           aliases: RTS_IF_NEG, RTS_IF_MINUS

.macro RTS_IF_ZS
        .local  skip
        bne     skip
        rts
skip:
.endmacro

.macro RTS_IF_ZC
        .local  skip
        beq     skip
        rts
skip:
.endmacro

.macro RTS_IF_CS
        .local  skip
        bcc     skip
        rts
skip:
.endmacro

.macro RTS_IF_CC
        .local  skip
        bcs     skip
        rts
skip:
.endmacro

.macro RTS_IF_VC
        .local  skip
        bvs     skip
        rts
skip:
.endmacro

.macro RTS_IF_VS
        .local  skip
        bvc     skip
        rts
skip:
.endmacro

.macro RTS_IF_NC
        .local  skip
        bmi     skip
        rts
skip:
.endmacro

.macro RTS_IF_NS
        .local  skip
        bpl     skip
        rts
skip:
.endmacro

        .define RTS_IF_EQ RTS_IF_ZS
        .define RTS_IF_NE RTS_IF_ZC
        .define RTS_IF_ZERO RTS_IF_EQ
        .define RTS_IF_NOT_ZERO RTS_IF_NE
        .define RTS_IF_GE RTS_IF_CS
        .define RTS_IF_LT RTS_IF_CC
        .define RTS_IF_PLUS RTS_IF_NC
        .define RTS_IF_MINUS RTS_IF_NS
        .define RTS_IF_POS RTS_IF_NC
        .define RTS_IF_NEG RTS_IF_NS


;;; ============================================================
;;; Lambda Invocation
;;; ============================================================

;;; Like `param_call` but the target is passed a "lambda"
;;; that is defined inline. And RTS (or tail call) is required!

.macro INVOKE_WITH_LAMBDA target
.scope
        lda     #<(lambda)
        ldx     #>(lambda)
        jsr     target
        jmp     __end_of_lambda__
.proc lambda
.endmacro

.macro END_OF_LAMBDA
.endproc ; lambda
        __end_of_lambda__ := *
.endscope
.endmacro


;;; ============================================================
;;; Jump Table Definitions
;;; ============================================================

.macro JT_INIT addr
        __jt_addr__ .set addr
.endmacro

.macro JT_ENTRY name
        name := __jt_addr__
        .refto name
        __jt_addr__ .set __jt_addr__ + 3
.endmacro

;;; ============================================================
;;; File Segments
;;; ============================================================

.macro INITSEG offset
        .assert (offset .mod BLOCK_SIZE) = 0, error, "Offset must be block aligned"

        __segoffset__ .set offset
        __nextsegpad__ .set 0
.endmacro

.macro DEFSEG name, addr, len
        .assert (__segoffset__ .mod BLOCK_SIZE) = 0, error, "Offset must be block aligned"

        .ident(.sprintf("k%sAddress", .string(name))) = addr
        .ident(.sprintf("k%sLength", .string(name))) = len
        .ident(.sprintf("k%sOffset", .string(name))) = __segoffset__
        .ident(.sprintf("k%sAlignmentPadding", .string(name))) = __nextsegpad__

        ;; Align file segments to block boundaries
        __curoffset__ .set __segoffset__ + len
        .if __curoffset__ .mod BLOCK_SIZE
            __nextsegpad__ .set BLOCK_SIZE - (__curoffset__ .mod BLOCK_SIZE)
        .else
            __nextsegpad__ .set 0
        .endif
        __segoffset__ .set __curoffset__ + __nextsegpad__
.endmacro

.macro BEGINSEG name
        ;; Padding to block-align this segment in the file
        .res .ident(.sprintf("k%sAlignmentPadding", .string(name)))

        .org .ident(.sprintf("k%sAddress", .string(name)))
.endmacro

.macro ENDSEG name
        .out .sprintf("Segment: %20s  addr: $%04X  len: $%04X  offset: $%06X  padding: $%04X", \
          .string(name), \
          .ident(.sprintf("k%sAddress", .string(name))),\
          .ident(.sprintf("k%sLength", .string(name))),\
          .ident(.sprintf("k%sOffset", .string(name))),\
          .ident(.sprintf("k%sAddress", .string(name))) + .ident(.sprintf("k%sLength", .string(name))) - *\
        )

        PAD_TO .ident(.sprintf("k%sAddress", .string(name))) + .ident(.sprintf("k%sLength", .string(name)))
.endmacro
