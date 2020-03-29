;;; ============================================================
;;; Loader
;;; ============================================================

        .org $2000

;;; Loads the Invoker (page 2/3), Selector App (at $4000...$9FFF),
;;; and Resources (Aux LC), then invokes the app.

.scope

        jmp     start

        resources_load_addr := $3400
        resources_final_addr := $D000

        ;; ProDOS parameter blocks

        DEFINE_OPEN_PARAMS open_params, str_selector, $3000
        DEFINE_READ_PARAMS read_params1, INVOKER, $160
        DEFINE_READ_PARAMS read_params2, MGTK, $6000
        DEFINE_READ_PARAMS read_params3, resources_load_addr, $800

        DEFINE_SET_MARK_PARAMS set_mark_params, $600
        DEFINE_CLOSE_PARAMS close_params

str_selector:
        PASCAL_STRING "Selector"

.macro  WRAPPED_MLI_CALL op, params
        php
        sei
        MLI_CALL op, params
        plp
        and     #$FF            ; restore Z flag
.endmacro

start:
        ;; Clear ProDOS memory bitmap
        lda     #0
        ldx     #$17
:       sta     $BF59,x
        dex
        bpl     :-

        WRAPPED_MLI_CALL OPEN, open_params
        beq     L2049
        brk

L2049:  lda     open_params::ref_num
        sta     set_mark_params::ref_num
        sta     read_params1::ref_num
        sta     read_params2::ref_num
        sta     read_params3::ref_num

        WRAPPED_MLI_CALL SET_MARK, set_mark_params
        beq     :+
        brk

:       WRAPPED_MLI_CALL READ, read_params1
        beq     :+
        brk

:       WRAPPED_MLI_CALL READ, read_params2
        beq     :+
        brk

:       WRAPPED_MLI_CALL READ, read_params3
        beq     :+
        brk

:
L2092           := * + 2

        ;; Copy last Resources segment to Aux LC1
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        ldx     #0
:       .repeat 8, i
        lda     resources_load_addr + ($100 * i),x
        sta     resources_final_addr + ($100 * i),x
        .endrepeat
        inx
        bne     :-

        sta     ALTZPOFF
        sta     ROMIN2

        WRAPPED_MLI_CALL CLOSE, close_params

        jmp     START

;;; ============================================================
;;; Duplicated from selector2.s - unused?

.scope

L103A           := $103A
L10F2           := $10F2
L1127           := $1127
L118B           := $118B
L223B           := $223B

        .byte   $03
        bpl     L2092
        inc     $8D03,x
        .byte   $89
        ora     ($AD),y
        .byte   $FF
        .byte   $03
        sta     $118A
        lda     LCBANK2
        lda     LCBANK2
        ldy     #$00
L20F8:  lda     $1000,y
        sta     $D100,y
        lda     $1100,y
        sta     $D200,y
        dey
        bne     L20F8
        lda     ROMIN2
        jmp     L10F2

        lda     $1189
        sta     IRQ_VECTOR
        lda     $118A
        sta     $03FF
        MLI_CALL SET_PREFIX, $1031
        beq     L2124
        jmp     L1127

L2124:  MLI_CALL OPEN, $1034
        beq     L212F
        jmp     L118B

L212F:  lda     $1039
        sta     $1028
        MLI_CALL READ, $1027
        beq     L2140
        jmp     L118B

L2140:  MLI_CALL CLOSE, $102F
        beq     L214B
        jmp     L118B

L214B:  jmp     $2000

        jsr     SLOT3ENTRY
        jsr     HOME
        lda     #$0C
        sta     CV
        jsr     VTAB
        lda     #$50
        sec
        sbc     $115E
        lsr     a
        sta     CH
        ldy     #$00
L2166:  lda     $115F,y
        ora     #$80
        jsr     COUT
        iny
        cpy     $115E
        bne     L2166
L2174:  sta     KBDSTRB
L2177:  lda     CLR80COL
        bpl     L2177
        and     #$7F
        cmp     #$0D
        bne     L2174
        jmp     L103A

        PASCAL_STRING "Insert the system disk and press <Return>."

        .byte   0
        .byte   0
        sta     $06
        jmp     MONZ

        PAD_TO $21F7

        ;; Probably part of BASIC.SYSTEM ???

        ldx     $3D20,y
        tay
        bcs     L223B
        lda     $BE53

.endscope

.endscope
