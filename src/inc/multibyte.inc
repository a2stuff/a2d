;;; ============================================================
;;; Multibyte
;;; ============================================================

;;; Macros for common operations (copy, add, subtract) for 16-bit and
;;; other sized operands.

;;; ============================================================

.define _is_immediate(arg)       .xmatch({.mid (0, 1, {arg})}, #)
.define _is_register(arg)        .xmatch({arg}, x) || .xmatch({arg}, y)
.define _immediate_value(arg)    .right(.tcount({arg}) - 1, {arg})

.define _is_indexed(arg)         .match({.right(2, {arg})}, {,X}) || .match({.right(2, {arg})}, {,Y})
.define _indexed_prefix(arg)     .left(.tcount({arg}) - 2, {arg})
.define _indexed_suffix(arg)     .right(1, {arg})
.define _is_indirect_indexed(arg) .xmatch({.left(1, {arg})}, {(}) && .xmatch({.right(3, {arg})}, {),Y})

;;; Helpers for multi-byte operations

;;; Emit specified opcode accessing the Nth byte, either immediate or absolute
;;; For indirect indexed (i.e. `(zp),y`) the caller is responsible for `INY`
.macro _op_b0 op, arg
    .if _is_immediate {arg}
        op #.lobyte(_immediate_value {arg})
    .elseif _is_indirect_indexed {arg}
        op arg
    .elseif _is_indexed {arg}
        op _indexed_prefix {arg} , _indexed_suffix {arg}
    .else
        op arg
    .endif
.endmacro

.macro _op_b1 op, arg
    .if _is_immediate {arg}
        op #.hibyte(_immediate_value {arg})
    .elseif _is_indirect_indexed {arg}
        op arg
    .elseif _is_indexed {arg}
        op _indexed_prefix {arg} + 1, _indexed_suffix {arg}
    .else
        op arg+1
    .endif
.endmacro

.macro _op_b2 op, arg
    .if _is_immediate {arg}
        op #.bankbyte(_immediate_value {arg})
    .elseif _is_indirect_indexed {arg}
        op arg
    .elseif _is_indexed {arg}
        op _indexed_prefix {arg} + 2, _indexed_suffix {arg}
    .else
        op arg+2
    .endif
.endmacro

.macro _op_b3 op, arg
    .if _is_immediate {arg}
        op #.hibyte(.hiword(_immediate_value {arg}))
    .elseif _is_indirect_indexed {arg}
        op arg
    .elseif _is_indexed {arg}
        op _indexed_prefix {arg} + 3, _indexed_suffix {arg}
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
    .elseif _is_indirect_indexed {arg}
        op arg
    .elseif _is_indexed {arg}
        op _indexed_prefix {arg} + 1, _indexed_suffix {arg}
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
    .elseif _is_indirect_indexed {arg}
        op arg
    .elseif _is_indexed {arg}
        op _indexed_prefix {arg} + 2, _indexed_suffix {arg}
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
    .elseif _is_indirect_indexed {arg}
        op arg
    .elseif _is_indexed {arg}
        op _indexed_prefix {arg} + 3, _indexed_suffix {arg}
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

;;; Copy 8 bit value from src to dst
;;;    copy8 src, dst
;;; Supports all addressing modes.
.macro copy8 arg1, arg2, arg3, arg4
    .if _is_register {arg2}
        copy8 {arg1,arg2}, {arg3}, {arg4}
        .exitmacro
    .elseif _is_register {arg3}
        copy8 {arg1}, {arg2,arg3}, {arg4}
        .exitmacro
    .endif
        .assert .blank({arg3}) && .blank({arg4}), error, "extra parameters"

        _op_b0 lda, {arg1}
        _op_b0 sta, {arg2}
.endmacro

;;; Swap arg1 and arg2
;;;    swap8 src, dst
;;; Supports all addressing modes.
.macro swap8 arg1, arg2, arg3, arg4
    .if _is_register {arg2}
        swap8 {arg1,arg2}, {arg3}, {arg4}
        .exitmacro
    .elseif _is_register {arg3}
        swap8 {arg1}, {arg2,arg3}, {arg4}
        .exitmacro
    .endif
        .assert .blank({arg3}) && .blank({arg4}), error, "extra parameters"

        _op_b0  lda, {arg1}
        pha
        _op_b0  lda, {arg2}
        _op_b0  sta, {arg1}
        pla
        _op_b0  sta, {arg2}
.endmacro

;;; Unsigned compare 8-bit values - C and Z valid
;;;    ucmp8 arg1, arg2
;;; Supports all addressing modes.
.macro ucmp8 arg1, arg2, arg3, arg4
    .if _is_register {arg2}
        ucmp8 {arg1,arg2}, {arg3}, {arg4}
        .exitmacro
    .elseif _is_register {arg3}
        ucmp8 {arg1}, {arg2,arg3}, {arg4}
        .exitmacro
    .endif
        .assert .blank({arg3}) && .blank({arg4}), error, "extra parameters"

        _op_b0  lda, {arg1}
        _op_b0  cmp, {arg2}
.endmacro

;;; Core for add8/sub8
.macro _addsub8 op, carryOp, arg1, arg2, arg3, arg4, arg5, arg6
    .if _is_register {arg2}
        _addsub8 op, carryOp, {arg1,arg2}, {arg3}, {arg4}, {arg5}, {arg6}
        .exitmacro
    .elseif _is_register {arg3}
        _addsub8 op, carryOp, {arg1}, {arg2,arg3}, {arg4}, {arg5}, {arg6}
        .exitmacro
    .elseif _is_register {arg4}
        _addsub8 op, carryOp, {arg1}, {arg2}, {arg3,arg4}, {arg5}, {arg6}
        .exitmacro
    .endif
        .assert .blank({arg4}) && .blank({arg5}) && .blank({arg6}), error, "extra parameters"

        _op_b0 lda, {arg1}
        carryOp
        _op_b0 op,  {arg2}
        _op_b0 sta, {arg3}
.endmacro

;;; Add arg1 to arg2, store to arg3
;;;    add8 arg1, arg2, arg3
;;; Supports all addressing modes.
.macro add8 arg1, arg2, arg3, arg4, arg5, arg6
    _addsub8 adc, clc, {arg1}, {arg2}, {arg3}, {arg4}, {arg5}, {arg6}
.endmacro

;;; Subtract arg2 from arg1, store to arg3
;;;    add8 arg1, arg2, arg3
;;; Supports all addressing modes.
.macro sub8 arg1, arg2, arg3, arg4, arg5, arg6
    _addsub8 sbc, sec, {arg1}, {arg2}, {arg3}, {arg4}, {arg5}, {arg6}
.endmacro


;;; ============================================================
;;; 16-bit pseudo-ops

;;; Load two registers (e.g. A, X), optimizing same immediate (e.g. w/ TAX)
.macro _ld_reg_reg ld1, ld2, t12, arg, reg
    .if _is_register {reg}
        _ld_reg_reg {ld1}, {ld2}, {t12}, {arg,reg}
        .exitmacro
    .endif

    .if _is_immediate {arg}
      .if .const(_immediate_value {arg}) && .lobyte(_immediate_value {arg}) = .hibyte(_immediate_value {arg})
        _op_lo  ld1, {arg}
        t12
        .exitmacro
      .endif
    .endif

        _op_lo  ld1, {arg}
        _op_hi  ld2, {arg}
.endmacro

;;; Load A,X
;;;    ldax #$1234      ; immediate (optimized if lo=hi)
;;;    ldax $1234       ; absolute
;;;    ldax $1234,y     ; absolute,y
.macro ldax arg, reg
        _ld_reg_reg lda, ldx, tax, arg, reg
.endmacro

;;; Load A,Y
;;;    lday #$1234      ; immediate (optimized if lo=hi)
;;;    lday $1234       ; absolute
.macro lday arg, reg
        _ld_reg_reg lda, ldy, tay, arg, reg
.endmacro

;;; Load Y, A
;;;    ldya #$1234      ; immediate (optimized if lo=hi)
;;;    ldya $1234       ; absolute
.macro ldya arg, reg
        _ld_reg_reg ldy, lda, tya, arg, reg
.endmacro

;;; Load X,Y
;;;    ldxy #$1234      ; immediate (no optimization)
;;;    ldxy $1234       ; absolute
.macro ldxy arg
        _op_lo ldx, {arg}
        _op_hi ldy, {arg}
.endmacro

;;; Store A,X
;;;    stax $1234       ; absolute
.macro stax arg
        _op_lo  sta, {arg}
        _op_hi  stx, {arg}
.endmacro

;;; Store Y,X
;;;    styx $1234       ; absolute
.macro styx arg
        _op_lo  sty, {arg}
        _op_hi  stx, {arg}
.endmacro

;;; Store X,Y
;;;    stxy $1234       ; absolute
.macro stxy arg
        _op_lo  stx, {arg}
        _op_hi  sty, {arg}
.endmacro

;;; Increment X,Y as a 16-bit number (x lo, y hi)
.macro inxy
        .local @skip
        inx
        bne     @skip
        iny
@skip:
.endmacro

;;; Core for add16/sub16
.macro _addsub16 op, carryOp, arg1, arg2, arg3, arg4, arg5, arg6
    .if _is_register {arg2}
        _addsub16 op, carryOp, {arg1,arg2}, {arg3}, {arg4}, {arg5}, {arg6}
        .exitmacro
    .elseif _is_register {arg3}
        _addsub16 op, carryOp, {arg1}, {arg2,arg3}, {arg4}, {arg5}, {arg6}
        .exitmacro
    .elseif _is_register {arg4}
        _addsub16 op, carryOp, {arg1}, {arg2}, {arg3,arg4}, {arg5}, {arg6}
        .exitmacro
    .endif
        .assert .blank({arg4}) && .blank({arg5}) && .blank({arg6}), error, "extra parameters"

        _op_lo lda, {arg1}
        carryOp
        _op_lo op, {arg2}
        _op_lo sta, {arg3}
        _op_hi lda, {arg1}
        _op_hi op, {arg2}
        _op_hi sta, {arg3}
.endmacro

;;; Core for add16in/sub16in
.macro _addsub16in op, carryOp, arg1, arg2, arg3, arg4, arg5, arg6
    .if _is_register {arg2}
        _addsub16in op, carryOp, {arg1,arg2}, {arg3}, {arg4}, {arg5}, {arg6}
        .exitmacro
    .elseif _is_register {arg3}
        _addsub16in op, carryOp, {arg1}, {arg2,arg3}, {arg4}, {arg5}, {arg6}
        .exitmacro
    .elseif _is_register {arg4}
        _addsub16in op, carryOp, {arg1}, {arg2}, {arg3,arg4}, {arg5}, {arg6}
        .exitmacro
    .endif
        .assert .blank({arg4}) && .blank({arg5}) && .blank({arg6}), error, "extra parameters"

        _op_lo  lda, {arg1}
        carryOp
        _op_lo  op,  {arg2}
        _op_lo  sta, {arg3}
        iny
        _op_hi  lda, {arg1}
        _op_hi  op,  {arg2}
        _op_hi  sta, {arg3}
.endmacro

;;; Core for add16_8/sub16_8
.macro _addsub16_8 op, carryOp, brOp, incOp, arg1, arg2, arg3, arg4, arg5, arg6
    .if _is_register {arg2}
        _addsub16_8 op, carryOp, brOp, incOp, {arg1,arg2}, {arg3}, {arg4}, {arg5}, {arg6}
        .exitmacro
    .elseif _is_register {arg3}
        _addsub16_8 op, carryOp, brOp, incOp, {arg1}, {arg2,arg3}, {arg4}, {arg5}, {arg6}
        .exitmacro
    .elseif _is_register {arg4}
        _addsub16_8 op, carryOp, brOp, incOp, {arg1}, {arg2}, {arg3,arg4}, {arg5}, {arg6}
        .exitmacro
    .endif
        .assert .blank({arg4}) && .blank({arg5}) && .blank({arg6}), error, "extra parameters"

    .ifblank arg3
        .local @skip
        _op_lo  lda, {arg1}
        carryOp
        _op_lo  op,  {arg2}
        _op_lo  sta, {arg1}
        brOp    @skip
        _op_hi  incOp, {arg1}
@skip:
    .else
      .if _is_immediate {arg2}
          .warning "Unnecessary use of add/sub16_8 macro with immediate arg"
      .endif

        _op_lo  lda, {arg1}
        carryOp
        _op_lo  op,  {arg2}
        _op_lo  sta, {arg3}
        _op_hi  lda, {arg1}
        op      #0
        _op_hi  sta, {arg3}
    .endif
.endmacro

;;; Add arg1 to arg2, store to arg3
;;;    add16 arg1, arg2, arg3
;;; Supports all non-indirect addressing modes.
.macro add16 arg1, arg2, arg3, arg4, arg5, arg6
    _addsub16 adc, clc, {arg1}, {arg2}, {arg3}, {arg4}, {arg5}, {arg6}
.endmacro
;;; (as above, but indirect indexed, y register is incremented)
.macro add16in arg1, arg2, arg3, arg4, arg5, arg6
    _addsub16in adc, clc, {arg1}, {arg2}, {arg3}, {arg4}, {arg5}, {arg6}
.endmacro

;;; Add arg1 (16-bit) to arg2 (8-bit), store to arg3
;;;    add16_8 arg1, arg2, arg3
;;; Add arg1 (16-bit) to arg2 (8-bit), store to arg1
;;;    add16_8 arg1, arg2
;;; Does not support indirect addressing modes.
.macro add16_8 arg1, arg2, arg3, arg4, arg5, arg6
    _addsub16_8 adc, clc, bcc, inc, {arg1}, {arg2}, {arg3}, {arg4}, {arg5}, {arg6}
.endmacro

;;; Add A,X to arg1 (immediate or absolute), store to arg2
;;;    addax #$1111, $3333       ; immediate, absolute
;;;    addax $1111, $3333        ; absolute, absolute
;;;    addax $1111               ; absolute
;;; Does not support indexed addressing modes.
.macro addax arg1, arg2
    .ifblank arg2
        clc
        _op_lo  adc, {arg1}
        _op_lo  sta, {arg1}
        txa
        _op_hi  adc, {arg1}
        _op_hi  sta, {arg1}
    .else
        clc
        _op_lo adc, {arg1}
        _op_lo sta, {arg2}
        txa
        _op_hi adc, {arg1}
        _op_hi sta, {arg2}
    .endif
.endmacro

;;; Subtract A,X from arg1 (immediate or absolute), store to arg2 (or arg1 if not given)
;;;    subax #$1111, $3333       ; immediate, absolute
;;;    subax $1111, $3333        ; absolute, absolute
;;;    subax $1111               ; absolute
;;; Does not support indexed addressing modes.
.macro subax arg1, arg2
    .ifblank arg2
        sec
        eor     #$FF
        _op_lo  adc, {arg1}
        _op_lo  sta, {arg1}
        txa
        eor     #$FF
        _op_hi  adc, {arg1}
        _op_hi  sta, {arg1}
    .else
        sec
        eor     #$FF
        _op_lo adc, {arg1}
        _op_lo sta, {arg2}
        txa
        eor     #$FF
        _op_hi adc, {arg1}
        _op_hi sta, {arg2}
    .endif
.endmacro

;;; Add arg1 (8 bit value) into A,X, optionally store to arg2
;;;    addax8 #$11       ; immediate
;;;    addax8 $11        ; absolute
;;;    addax8 #$11,$2222 ; immediate, absolute
;;;    addax8 $11,$2222  ; absolute, absolute
;;; Does not support indexed addressing modes.
.macro addax8  arg1, arg2
.local @skip
        clc
        _op_lo  adc, {arg1}
    .ifnblank arg2
        _op_lo  sta, {arg2}
    .endif
        bcc     @skip
        inx
@skip:
    .ifnblank arg2
        _op_hi  stx, {arg2}
    .endif
.endmacro

;;; Subtract arg1 (8 bit value) from A,X, optionally store to arg2
;;;    subax8 #$11       ; immediate
;;;    subax8 $11        ; absolute
;;;    subax8 #$11,$2222 ; immediate, absolute
;;;    subax8 $11,$2222  ; absolute, absolute
;;; Does not support indexed addressing modes.
.macro subax8  arg1, arg2
.local @skip
        sec
        _op_lo  sbc, {arg1}
    .ifnblank arg2
        _op_lo  sta, {arg2}
    .endif
        bcs     @skip
        dex
@skip:
    .ifnblank arg2
        _op_hi  stx, {arg2}
    .endif
.endmacro

;;; Add X,Y into arg1 (X,Y remain unchanged)
;;;    addxy #$1111, $3333       ; immediate, absolute
;;;    addxy $1111, $3333        ; absolute, absolute
;;;    addxy $1111               ; absolute
;;; Does not support indexed addressing modes.
.macro addxy arg1, arg2
    .ifblank arg2
        clc
        txa
        _op_lo  adc, {arg1}
        _op_lo  sta, {arg1}
        tya
        _op_hi  adc, {arg1}
        _op_hi  sta, {arg1}
    .else
        clc
        txa
        _op_lo adc, {arg1}
        _op_lo sta, {arg2}
        tya
        _op_hi adc, {arg1}
        _op_hi sta, {arg2}
    .endif
.endmacro

;;; Subtract arg2 from arg1, store to arg3
;;;    sub16 arg1, arg2, arg3
;;; Supports all non-indirect addressing modes.
.macro sub16 arg1, arg2, arg3, arg4, arg5, arg6
    _addsub16 sbc, sec, {arg1}, {arg2}, {arg3}, {arg4}, {arg5}, {arg6}
.endmacro
;;; (as above, but indirect indexed, y register incremented)
.macro sub16in arg1, arg2, arg3, arg4, arg5, arg6
    _addsub16in sbc, sec, {arg1}, {arg2}, {arg3}, {arg4}, {arg5}, {arg6}
.endmacro

;;; Subtract arg2 (8-bit) from arg1 (16-bit), store to arg3
;;;    sub16_8 arg1, arg2, arg3
;;; Subtract arg2 (8-bit) from arg1 (16-bit), store to arg1
;;;    sub16_8 arg1, arg2
;;; Does not support indirect addressing modes.
.macro sub16_8 arg1, arg2, arg3, arg4, arg5, arg6
        _addsub16_8 sbc, sec, bcs, dec, {arg1}, {arg2}, {arg3}, {arg4}, {arg5}, {arg6}
.endmacro

;;; Copy 16-bit value
;;;    copy16 src, dst
;;; Supports all non-indirect addressing modes. Immediate mode optimized.
.macro copy16 arg1, arg2, arg3, arg4
    .if _is_register {arg2}
        copy16 {arg1,arg2}, {arg3}, {arg4}
        .exitmacro
    .elseif _is_register {arg3}
        copy16 {arg1}, {arg2,arg3}, {arg4}
        .exitmacro
    .endif
        .assert .blank({arg3}) && .blank({arg4}), error, "extra parameters"

        _op_lo  lda, {arg1}
        _op_lo  sta, {arg2}
        _op_hx  lda, {arg1}     ; optimized
        _op_hi  sta, {arg2}
.endmacro

;;; Copy 16-bit value, indexed indirect, y register incremented
;;;    copy16in #$1111, ($2222),y   ; immediate load, indexed indirect store
;;;    copy16in $1111, ($2222),y    ; absolute load, indexed indirect store
;;;    copy16in ($1111),y, $2222    ; indexed indirect load, absolute store
;;;    copy16in ($1111),y ($2222),y ; indexed indirect load, indexed indirect store
.macro copy16in arg1, arg2, arg3, arg4
    .if _is_register {arg2}
        copy16in {arg1,arg2}, {arg3}, {arg4}
        .exitmacro
    .elseif _is_register {arg3}
        copy16in {arg1}, {arg2,arg3}, {arg4}
        .exitmacro
    .endif
        .assert .blank({arg3}) && .blank({arg4}), error, "extra parameters"

        _op_lo  lda, {arg1}
        _op_lo  sta, {arg2}
        iny
        _op_hx  lda, {arg1}
        _op_hi  sta, {arg2}
.endmacro

;;; Copy low/high 16-bit value
;;;    copylohi src_lo, src_hi, dst
;;; Supports all non-indirect addressing modes.
.macro copylohi arg1, arg2, arg3, arg4, arg5, arg6
    .if _is_register {arg2}
        copylohi {arg1,arg2}, {arg3}, {arg4}, {arg5}, {arg6}
        .exitmacro
    .elseif _is_register {arg3}
        copylohi {arg1}, {arg2,arg3}, {arg4}, {arg5}, {arg6}
        .exitmacro
    .elseif _is_register {arg4}
        copylohi {arg1}, {arg2}, {arg3,arg4}, {arg5}, {arg6}
        .exitmacro
    .endif
        .assert .blank({arg4}) && .blank({arg5}) && .blank({arg6}), error, "extra parameters"

        _op_lo lda, {arg1}
        _op_lo sta, {arg3}
        _op_lo lda, {arg2}
        _op_hi sta, {arg3}
.endmacro


;;; Unsigned compare 16-bit values - test C (BCC/BCS) for ordering
;;; WARNING: Z (for equality) is NOT set per CMP; use ecmp16 if needed.
;;;    ucmp16 arg1, arg2
;;; Supports all non-indirect addressing modes.
.macro ucmp16 arg1, arg2, arg3, arg4
    .if _is_register {arg2}
        ucmp16 {arg1,arg2}, {arg3}, {arg4}
        .exitmacro
    .elseif _is_register {arg3}
        ucmp16 {arg1}, {arg2,arg3}, {arg4}
        .exitmacro
    .endif
        .assert .blank({arg3}) && .blank({arg4}), error, "extra parameters"

        _op_lo  lda, {arg1}
        _op_lo  cmp, {arg2}
        _op_hi  lda, {arg1}
        _op_hi  sbc, {arg2}
.endmacro

;;; Signed compare 16-bit values - test N (BPL/BMI) for ordering
;;; (http://6502.org/tutorials/compare_beyond.html#6)
;;; WARNING: C (for ordering) and Z (for equality) are NOT set per CMP.
;;;    scmp16 arg1, arg2
;;; Supports all non-indirect addressing modes.
;;; NOTE: Some callers rely on A's bit7 implicitly matching result in N.
.macro scmp16 arg1, arg2, arg3, arg4
        .local @skip
        ucmp16 arg1,arg2,arg3,arg4
        bvc     @skip
        eor     #$80
@skip:
.endmacro

;;; Equality compare 16-bit values - test Z (BEQ/BNE) for equality, or C (BCC/BCS) for ordering.
;;; NOTE: Use ucmp16 (smaller code) if Z is not needed.
;;;    ecmp16 arg1, arg2
;;; Supports all non-indirect addressing modes.
.macro ecmp16 arg1, arg2, arg3, arg4
    .if _is_register {arg2}
        ecmp16 {arg1,arg2}, {arg3}, {arg4}
        .exitmacro
    .elseif _is_register {arg3}
        ecmp16 {arg1}, {arg2,arg3}, {arg4}
        .exitmacro
    .endif
        .assert .blank({arg3}) && .blank({arg4}), error, "extra parameters"

        ;; Note that high bytes are compared before low bytes because
        ;; of the early exit when not equal - we want the high byte to
        ;; domimate the ordering.
        _op_hi  lda, {arg1}
        _op_hi  cmp, {arg2}
        bne     @skip
        _op_lo  lda, {arg1}
        _op_lo  cmp, {arg2}
@skip:
.endmacro


;;; Shift 16-bit values
;;;    lsr16 arg
;;; Supports absolute, zero-page, and x-indexed addressing modes.
.macro lsr16 arg1, arg2
    .if _is_register {arg2}
        lsr16 {arg1,arg2}
        .exitmacro
    .endif
        .assert .blank({arg2}), error, "extra parameters"

        _op_hi  lsr, {arg1}
        _op_lo  ror, {arg1}
.endmacro

;;;    asl16 arg
;;; Supports absolute, zero-page, and x-indexed addressing modes.
.macro asl16 arg1, arg2
    .if _is_register {arg2}
        asl16 {arg1,arg2}
        .exitmacro
    .endif
        .assert .blank({arg2}), error, "extra parameters"

        _op_lo  asl, {arg1}
        _op_hi  rol, {arg1}
.endmacro

;;; "Arithmetic Shift Right" i.e. signed division by 2
;;;    asr16 arg
;;; Supports absolute, zero-page, and x-indexed addressing modes.
.macro asr16 arg1, arg2
    .if _is_register {arg2}
        asr16 {arg1,arg2}
        .exitmacro
    .endif
        .assert .blank({arg2}), error, "extra parameters"

        _op_hi  lda, {arg1}
        rol
        _op_hi  ror, {arg1}
        _op_lo  ror, {arg1}
.endmacro

;;; Increment 16-bit value
;;;    inc16 arg
;;; Supports absolute, zero-page, and x-indexed addressing modes.
.macro inc16 arg1, arg2
    .if _is_register {arg2}
        inc16 {arg1,arg2}
        .exitmacro
    .endif
        .assert .blank({arg2}), error, "extra parameters"

        .local @skip
        _op_lo  inc, {arg1}
        bne     @skip
        _op_hi  inc, {arg1}
@skip:
.endmacro

;;; Decrement 16-bit value
;;;    dec16 arg
;;; Supports absolute, zero-page, and x-indexed addressing modes.
.macro dec16 arg1, arg2
    .if _is_register {arg2}
        dec16 {arg1,arg2}
        .exitmacro
    .endif
        .assert .blank({arg2}), error, "extra parameters"

        .local @skip
        _op_lo  lda, {arg1}
        bne     @skip
        _op_hi  dec, {arg1}
@skip:  _op_lo  dec, {arg1}
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
;;;    push16 arg
;;; Supports all non-indirect addressing modes.
.macro push16 arg1, arg2
    .if _is_register {arg2}
        push16 {arg1,arg2}
        .exitmacro
    .endif
        .assert .blank({arg2}), error, "extra parameters"

        _op_lo  lda, {arg1}
        pha
        _op_hi  lda, {arg1}
        pha
.endmacro

;;; ============================================================
;;; 24-bit pseudo-ops

;;; Copy 24-bit value
;;;    copy24 arg1, arg2
;;; Supports all non-indirect addressing modes. Immediate mode optimized.
.macro copy24 arg1, arg2, arg3, arg4
    .if _is_register {arg2}
        copy24 {arg1,arg2}, {arg3}, {arg4}
        .exitmacro
    .elseif _is_register {arg3}
        copy24 {arg1}, {arg2,arg3}, {arg4}
        .exitmacro
    .endif
        .assert .blank({arg3}) && .blank({arg4}), error, "extra parameters"

        _op_b0  lda, {arg1}
        _op_b0  sta, {arg2}
        _op_x1  lda, {arg1}     ; optimized
        _op_b1  sta, {arg2}
        _op_x2  lda, {arg1}     ; optimized
        _op_b2  sta, {arg2}
.endmacro

;;; Increment 24-bit value
;;;    inc24 arg
;;; Supports all non-indirect addressing modes.
.macro inc24 arg1, arg2
    .if _is_register {arg2}
        inc24 {arg1,arg2}
        .exitmacro
    .endif
        .assert .blank({arg2}), error, "extra parameters"

        .local @skip
        _op_b0  inc, {arg1}
        bne     @skip
        _op_b1  inc, {arg1}
        bne     @skip
        _op_b2  inc, {arg1}
@skip:
.endmacro

;;; Unsigned compare 24-bit values
;;;    ucmp24 arg1, arg2
;;; Supports all non-indirect addressing modes.
.macro ucmp24 arg1, arg2, arg3, arg4
    .if _is_register {arg2}
        ucmp24 {arg1,arg2}, {arg3}, {arg4}
        .exitmacro
    .elseif _is_register {arg3}
        ucmp24 {arg1}, {arg2,arg3}, {arg4}
        .exitmacro
    .endif
        .assert .blank({arg3}) && .blank({arg4}), error, "extra parameters"

        _op_b0  lda, {arg1}
        _op_b0  cmp, {arg2}
        _op_b1  lda, {arg1}
        _op_b1  sbc, {arg2}
        _op_b2  lda, {arg1}
        _op_b2  sbc, {arg2}
.endmacro

;;; Equality compare 24-bit values
;;;    ecmp24 arg1, arg2
;;; Supports all non-indirect addressing modes.
.macro ecmp24 arg1, arg2, arg3, arg4
    .if _is_register {arg2}
        ecmp24 {arg1,arg2}, {arg3}, {arg4}
        .exitmacro
    .elseif _is_register {arg3}
        ecmp24 {arg1}, {arg2,arg3}, {arg4}
        .exitmacro
    .endif
        .assert .blank({arg3}) && .blank({arg4}), error, "extra parameters"

        .local @skip
        _op_b0  lda, {arg1}
        _op_b0  cmp, {arg2}
        bne     @skip
        _op_b1  lda, {arg1}
        _op_b1  cmp, {arg2}
        bne     @skip
        _op_b2  lda, {arg1}
        _op_b2  cmp, {arg2}
@skip:
.endmacro

;;; ============================================================
;;; 32-bit pseudo-ops

;;; Core for add32/sub32
.macro _addsub32 op, carryOp, arg1, arg2, arg3, arg4, arg5, arg6
    .if _is_register {arg2}
        _addsub32 op, carryOp, {arg1,arg2}, {arg3}, {arg4}, {arg5}, {arg6}
        .exitmacro
    .elseif _is_register {arg3}
        _addsub32 op, carryOp, {arg1}, {arg2,arg3}, {arg4}, {arg5}, {arg6}
        .exitmacro
    .elseif _is_register {arg4}
        _addsub32 op, carryOp, {arg1}, {arg2}, {arg3,arg4}, {arg5}, {arg6}
        .exitmacro
    .endif
        .assert .blank({arg4}) && .blank({arg5}) && .blank({arg6}), error, "extra parameters"

        carryOp
        _op_b0 lda, {arg1}
        _op_b0 op,  {arg2}
        _op_b0 sta, {arg3}
        _op_b1 lda, {arg1}
        _op_b1 op,  {arg2}
        _op_b1 sta, {arg3}
        _op_b2 lda, {arg1}
        _op_b2 op,  {arg2}
        _op_b2 sta, {arg3}
        _op_b3 lda, {arg1}
        _op_b3 op,  {arg2}
        _op_b3 sta, {arg3}
.endmacro

;;; Add arg1 to arg2, store to arg3
;;;    add32 arg1, arg2, arg3
;;; Supports all non-indirect addressing modes.
.macro add32 arg1, arg2, arg3, arg4, arg5, arg6
    _addsub32 adc, clc, {arg1}, {arg2}, {arg3}, {arg4}, {arg5}, {arg6}
.endmacro

;;; Subtract arg2 from arg1, store to arg3
;;;    sub32 arg1, arg2, arg3
;;; Supports all non-indirect addressing modes.
.macro sub32 arg1, arg2, arg3, arg4, arg5, arg6
    _addsub32 sbc, sec, {arg1}, {arg2}, {arg3}, {arg4}, {arg5}, {arg6}
.endmacro

;;; Copy 32-bit value
;;;    copy32 src, dst
;;; Supports all non-indirect addressing modes. Immediate mode optimized.
.macro copy32 arg1, arg2, arg3, arg4
    .if _is_register {arg2}
        copy32 {arg1,arg2}, {arg3}, {arg4}
        .exitmacro
    .elseif _is_register {arg3}
        copy32 {arg1}, {arg2,arg3}, {arg4}
        .exitmacro
    .endif
        .assert .blank({arg3}) && .blank({arg4}), error, "extra parameters"

        _op_b0  lda, {arg1}
        _op_b0  sta, {arg2}
        _op_x1  lda, {arg1}     ; optimized
        _op_b1  sta, {arg2}
        _op_x2  lda, {arg1}     ; optimized
        _op_b2  sta, {arg2}
        _op_x3  lda, {arg1}     ; optimized
        _op_b3  sta, {arg2}
.endmacro

;;; Shift 32-bit values
;;;    asl32 arg
;;; Supports absolute, zero-page, and x-indexed addressing modes.
.macro asl32 arg1, arg2
    .if _is_register {arg2}
        asl32 {arg1,arg2}
        .exitmacro
    .endif
        .assert .blank({arg2}), error, "extra parameters"

        _op_b0  asl, {arg1}
        _op_b1  rol, {arg1}
        _op_b2  rol, {arg1}
        _op_b3  rol, {arg1}
.endmacro

;;;    lsr32 arg
;;; Supports absolute, zero-page, and x-indexed addressing modes.
.macro lsr32 arg1, arg2
    .if _is_register {arg2}
        lsr32 {arg1,arg2}
        .exitmacro
    .endif
        .assert .blank({arg2}), error, "extra parameters"

        _op_b3  lsr, {arg1}
        _op_b2  ror, {arg1}
        _op_b1  ror, {arg1}
        _op_b0  ror, {arg1}
.endmacro



