.feature leading_dot_in_identifiers

;;; ============================================================
;;; Common patterns
;;; ============================================================

.define AS_BYTE(arg)        (arg) & $FF
.define AS_WORD(arg)        (arg) & $FFFF

;;; This uses BIT to treat the next 2-byte instruction as data.
;;; Note that it has side effects on flags. If the high byte
;;; is potentially $C0 then it must not be used.
.macro SKIP_NEXT_2_BYTE_INSTRUCTION
        .byte   $2C             ; OPC_BIT_abs
.endmacro

.macro SET_BIT7_FLAG ident
    .ifblank ident
        .error "CLEAR_BIT7_FLAG without identifier!"
    .endif
        sec
        ror     ident
.endmacro

.macro CLEAR_BIT7_FLAG ident
    .ifblank ident
        .error "CLEAR_BIT7_FLAG without identifier!"
    .endif
        lsr     ident
.endmacro

.macro ENTRY_POINTS_FOR_BIT7_FLAG ep_set, ep_clear, flag_name
ep_set:
        sec
        .byte   $90             ; OPC_BCC
ep_clear:
        clc
        ror     flag_name       ; C into bit7
.endmacro

.macro ENTRY_POINTS_FOR_A ep_1, value_1, ep_2, value_2, arg4, arg5, arg6, arg7, arg8, arg9
ep_1:
        lda     #value_1
        SKIP_NEXT_2_BYTE_INSTRUCTION
        ASSERT_NOT_EQUALS (value_2 & $F0), $C0, "Bad BIT skip"
    .ifblank arg4
ep_2:
        lda     #value_2
    .else
        ENTRY_POINTS_FOR_A ep_2, value_2, arg4, arg5, arg6, arg7, arg8, arg9
    .endif
.endmacro

;;; Inject a return address to the stack.
.macro PUSH_RETURN_ADDRESS addr
        lda     #>(addr-1)
        pha
        lda     #<(addr-1)
        pha
.endmacro

;;; ============================================================
;;; Strings
;;; ============================================================

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
    .ifnblank res
        .res    res - (end - data), 0
    .endif
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

.if kBuildSupportsLowercase
.define TO_LOWER(char) (char | %00100000)
.endif


;;; ============================================================
;;; Padding
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

;;; --------------------------------------------------
;;; Pad if necessary to avoid a page boundary
;;;
;;; `opt_count` is the number of entries (words) in a jump table

.macro PAD_IF_NEEDED_TO_AVOID_PAGE_BOUNDARY opt_count
  .ifblank opt_count
    .if .lobyte(*) = $FF
        .out .sprintf("Padding 1 byte to avoid page boundary at $%04X", *)
        .res    1
    .endif
  .else
    .if (* & 1) .and .hibyte(*) <> .hibyte(* + (2 * opt_count))
        .out .sprintf("Padding 1 byte to avoid page boundary at $%04X", *)
        .res    1
    .endif
  .endif
.endmacro


;;; ============================================================
;;; Lambda Invocation
;;; ============================================================

;;; Call a proc and pass a "lambda" (anonymous locally defined
;;; function) in A,X. An RTS (or tail call) is required!

;;; Example:
;;;   INVOKE_WITH_LAMBDA ForEachThing
;;;     sta last_thing_seen
;;;     inc thing_count
;;;     rts
;;;   END_OF_LAMBDA

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
;;; Parameter Blocks
;;; ============================================================

;;; Basic parameter blocks - named scopes that indicate data
;;;
;;; Example:
;;;   .params label
;;;     p1: .byte 0
;;;     p2: .word 1234
;;;   .endparams

.macro .params label
        WARN_IF_SHADOWING label
        .proc label
.endmacro

.macro .endparams
.endproc ; label
.endmacro

;;; --------------------------------------------------
;;; Placed Parameter Blocks
;;;
;;; Helper macros to set up a scoped block of parameters at a
;;; pre-determined address (e.g. the zero page). Like .struct/.org,
;;; but also defines a label at the target address. Nested .struct can
;;; be used.
;;;
;;; Example:
;;;   .proc my_function
;;;     PARAM_BLOCK params, $82
;;;       arg1    .byte
;;;       arg2    .word
;;;       arg3    .res    7
;;;     END_PARAM_BLOCK
;;;
;;;           lda     params::arg1         ; equiv. to lda $82
;;;           lda     params::arg2         ; equiv. to lda $83
;;;           lda     params::arg3         ; equiv. to lda $85
;;;           lda     #params              ; equiv. to lda #$82
;;;           lda     #.sizeof(params)     ; equiv. to lda #10
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

;;; Either:
;;;    COPY_STRUCT src, dst        ; if .sizeof(src) works
;;;    COPY_STRUCT type, src, dst  ; if .sizeof(type) is needed
.macro COPY_STRUCT arg1, arg2, arg3
    .ifblank arg3
        COPY_BYTES .sizeof(arg1), arg1, arg2
    .else
        COPY_BYTES .sizeof(arg1), arg2, arg3
    .endif
.endmacro

.macro COPY_BLOCK block, dst
        COPY_BYTES .sizeof(block), block, dst
.endmacro

.macro PUSH_BYTES size, src
        ldx     #AS_BYTE(-size)
.local loop
loop:
        lda     src + size,x
        pha
        inx
        bne     loop
.endmacro

.macro POP_BYTES size, dst
        ldx     #(size)-1
.local loop
loop:   pla
        sta     dst,x
        dex
        bpl     loop
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
;;;   .pushorg $380
;;;     lda #$12
;;;     rts
;;;   .poporg

::__pushorg_depth__ .set 0

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

::__shadow_warning_suppress_count__ .set 0

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
;;; Assertions
;;; ============================================================

.macro ASSERT_EQUALS actual, expected, message
    .ifnblank message
        .assert (actual) = (expected), error, .sprintf("expected %d actual %d: %s", (expected), (actual), message)
    .else
        .assert (actual) = (expected), error, .sprintf("expected %d actual %d", (expected), (actual))
    .endif
.endmacro

.macro ASSERT_NOT_EQUALS actual, expected, message
    .ifnblank message
        .assert (actual) <> (expected), error, .sprintf("unexpected %d: %s", (expected), message)
    .else
        .assert (actual) <> (expected), error, .sprintf("unexpected %d", (expected))
    .endif
.endmacro

.macro ASSERT_ADDRESS addr, opt_message
    .ifnblank opt_message
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
;;; Jump Table Definitions (very DeskTop-specific)
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
;;; File Segments (very DeskTop-specific)
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

;;; ============================================================
;;; Other Macro Libraries
;;; ============================================================

        .include "multibyte.inc"
        .include "flow.inc"
        .macpack longbranch
