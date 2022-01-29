.feature leading_dot_in_identifiers

;;; ============================================================
;;; Generic Macros
;;; ============================================================

.define _is_immediate(arg)       (.match (.mid (0, 1, {arg}), #))
.define _is_register(arg)        (.match ({arg}, x) .or .match ({arg}, y))
.define _is_y_register(arg)      (.match ({arg}, y))
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
    .if (addr - *) >= 0
        .res    addr - *
    .else
        .error .sprintf("Padding offset %d", addr - *)
    .endif
.endmacro

;;; ============================================================
;;; Common patterns

.define AS_BYTE(arg)        arg & $FF
.define AS_WORD(arg)        arg & $FFFF

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

.macro copy arg1, arg2, arg3, arg4
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

;;; ============================================================
;;; Calls with one parameter (address in A,X) or two (Y, plus A,X)
;;; Usage: param_call target, ax_arg
;;;        param_call target, y_arg, ax_arg

.macro param_call target, param1, param2
.if     .paramcount = 2
        lda     #<param1
        ldx     #>param1
.elseif .paramcount = 3
        ldy     #param1
        lda     #<param2
        ldx     #>param2
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
        lda     #<param1
        ldx     #>param1
.elseif .paramcount = 3
        ldy     #param1
        lda     #<param2
        ldx     #>param2
.else
        .error "incorrect macro usage"
.endif
        jmp     target
.endmacro


;;; ============================================================
;;; Long branch pseudo-ops

.macro jcc addr
        .local end
        bcs     end
        jmp     addr
end:
.endmacro

.macro jcs addr
        .local end
        bcc     end
        jmp     addr
end:
.endmacro

.macro jeq addr
        .local end
        bne     end
        jmp     addr
end:
.endmacro

.macro jmi addr
        .local end
        bpl     end
        jmp     addr
end:
.endmacro

.macro jne addr
        .local end
        beq     end
        jmp     addr
end:
.endmacro

.macro jpl addr
        .local end
        bmi     end
        jmp     addr
end:
.endmacro

.macro jvc addr
        .local end
        bvs     end
        jmp     addr
end:
.endmacro

.macro jvs addr
        .local end
        bvc     end
        jmp     addr
end:
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
        ;; xxx16in $1111,y, $2222,y, $3333,y
        lda     (arg1),y
        opc
        op      (arg3),y
        sta     (arg5),y
        iny
        lda     (arg1),y
        op      (arg3),y
        sta     (arg5),y
    .elseif _is_y_register {arg2} && _is_y_register {arg4}
        ;; xxx16in $1111,y, $2222,y, $3333
        lda     (arg1),y
        opc
        op      (arg3),y
        sta     arg5
        iny
        lda     (arg1),y
        op      (arg3),y
        sta     arg5+1
    .elseif _is_y_register {arg2} && _is_y_register {arg5}
        ;; xxx16in $1111,y, $2222, $3333,y
        ;; xxx16in $1111,y, #$2222, $3333,y
        lda     (arg1),y
        opc
        _op_lo  op, {arg3}
        sta     (arg4),y
        iny
        lda     (arg1),y
        _op_hi  op, {arg3}
        sta     (arg4),y
    .elseif _is_y_register {arg2}
        ;; xxx16in $1111,x, $2222, $3333
        ;; xxx16in $1111,x, #$2222, $3333
        lda     (arg1),y
        opc
        _op_lo  op, {arg3}
        sta     arg4
        iny
        lda     (arg1),y
        _op_hi  op, {arg3}
        sta     arg4+1
    .elseif _is_y_register {arg3}
        ;; xxx16in $1111, $2222,y $3333
        ;; xxx16in #$1111, $2222,y $3333
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
;;; (absolute, absolute, absolute, but requiring carry clear already)
.macro add16nc arg1, arg2, arg3, arg4, arg5, arg6
    lda arg1
    adc arg2
    sta arg3
    lda arg1 + 1
    adc arg2 + 1
    sta arg3 + 1
.endmacro
;;; (absolute, absolute, absolute, but requiring carry set already)
.macro sub16nc arg1, arg2, arg3, arg4, arg5, arg6
    lda arg1
    sbc arg2
    sta arg3
    lda arg1 + 1
    sbc arg2 + 1
    sta arg3 + 1
.endmacro


;;; Add arg1 (absolute) to arg2 (8-bit absolute), store to arg3
;;;    add16_8 $1111, #$22, $3333       ; absolute, immediate, absolute
;;;    add16_8 $1111, $22, $3333        ; absolute, absolute, absolute
.macro add16_8 arg1, arg2, arg3
    .ifblank arg3
        _op_lo  lda, {arg1}
        clc
        adc     arg2
        sta     arg1
        bcc     :+
        _op_hi  inc, {arg1}
:
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
;;;    copylohi $1111, $2222, $3333        ; absolute, absolute
;;;    copylohi $1111,x, $2222,x, $3333    ; indirect load, absolute store
.macro copylohi arg1, arg2, arg3, arg4, arg5
    .if _is_register {arg2}
        ;; indexed load
        ;; arg4 is also a register
        lda     arg1,arg2
        sta     arg5
        lda     arg3,arg4
        sta     arg5+1
    .else
        lda     arg1
        sta     arg3
        lda     arg2
        sta     arg3+1
    .endif
.endmacro



;;; Compare 16-bit values
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

;;; Signed compare 16-bit values - test N (BPL/BMI) for result
;;; (http://6502.org/tutorials/compare_beyond.html#6)
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
.macro PARAM_BLOCK name, addr
        name := addr
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
.scope
        ldx     #size - 1
loop:   lda     src,x
        sta     dst,x
        dex
        bpl     loop
.endscope
.endmacro

.macro COPY_STRUCT type, src, dst
        COPY_BYTES .sizeof(type), src, dst
.endmacro

.macro COPY_BLOCK block, dst
        COPY_BYTES .sizeof(block), block, dst
.endmacro

.macro COPY_STRING src, dst
.scope
        ldx     src
loop:   lda     src,x
        sta     dst,x
        dex
        cpx     #$FF
        bne     loop
.endscope
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
.proc name
        .pushorg addr
.endmacro

.macro END_PROC_AT
        .poporg
.endproc
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
;;; Parameter Blocks - named scopes that indicate data
;;; ============================================================
;;; Example:
;;; .params label
;;; p1: .byte 0
;;; p2: .word 1234
;;; .endparams

.macro .params label
        .proc label
.endmacro

.macro .endparams
        .endproc
.endmacro


;;; ============================================================
;;; Assertions
;;; ============================================================

.macro ASSERT_EQUALS actual, expected
    .assert (actual) = (expected), error, .sprintf("expected %d actual %d", (actual), (expected))
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


;;; ============================================================
;;; Flow Control
;;; ============================================================
;;; Usage:
;;;     lda foo
;;;     cmp bar
;;;     IF_EQ
;;;     ...
;;;     ELSE ; optional
;;;     ...
;;;     END_IF
;;;
;;; Macros:
;;;     IF_EQ           aliases: IF_ZERO
;;;     IF_NE           aliases: IF_NOT_ZERO
;;;     IF_CC           aliases: IF_LT
;;;     IF_CS           aliases: IF_GE
;;;     IF_VC
;;;     IF_VS
;;;     IF_NC           aliases: IF_POS, IF_PLUS
;;;     IF_NS           aliases: IF_NEG, IF_MINUS

__depth__ .set 0

.macro IF_EQ
        ::__depth__ .set ::__depth__ + 1
        .scope
        bne     .ident(.sprintf("__else__%d", ::__depth__))
.endmacro

.macro IF_NE
        ::__depth__ .set ::__depth__ + 1
        .scope
        beq     .ident(.sprintf("__else__%d", ::__depth__))
.endmacro

.macro IF_CC
        ::__depth__ .set ::__depth__ + 1
        .scope
        bcs     .ident(.sprintf("__else__%d", ::__depth__))
.endmacro

.macro IF_CS
        ::__depth__ .set ::__depth__ + 1
        .scope
        bcc     .ident(.sprintf("__else__%d", ::__depth__))
.endmacro

.macro IF_NC
        ::__depth__ .set ::__depth__ + 1
        .scope
        bmi     .ident(.sprintf("__else__%d", ::__depth__))
.endmacro

.macro IF_NS
        ::__depth__ .set ::__depth__ + 1
        .scope
        bpl     .ident(.sprintf("__else__%d", ::__depth__))
.endmacro

.macro IF_VC
        ::__depth__ .set ::__depth__ + 1
        .scope
        bvs     .ident(.sprintf("__else__%d", ::__depth__))
.endmacro

.macro IF_VS
        ::__depth__ .set ::__depth__ + 1
        .scope
        bvc     .ident(.sprintf("__else__%d", ::__depth__))
.endmacro

        .define IF_ZERO IF_EQ
        .define IF_NOT_ZERO IF_NE
        .define IF_GE IF_CS
        .define IF_LT IF_CC
        .define IF_PLUS IF_NC
        .define IF_MINUS IF_NS
        .define IF_POS IF_NC
        .define IF_NEG IF_NS

;;; --------------------------------------------------

.macro ELSE
        jmp     .ident(.sprintf("__endif__%d", ::__depth__))
        .ident(.sprintf("__else__%d", ::__depth__)) := *
.endmacro

.macro ELSE_IF
        .error "ELSE_IF not supported"
.endmacro

.macro ELSEIF
        .error "ELSEIF not supported"
.endmacro

;;; --------------------------------------------------

.macro END_IF
    .if .not(.defined(.ident(.sprintf("__else__%d", ::__depth__))))
        .ident(.sprintf("__else__%d", ::__depth__)) := *
    .endif
        .ident(.sprintf("__endif__%d", ::__depth__)) := *
.endscope
        ::__depth__ .set ::__depth__ - 1
.endmacro

.macro ENDIF
        .error "Do you mean END_IF ?"
.endmacro
