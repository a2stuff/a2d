;;; ============================================================
;;; Loader
;;; ============================================================

        .org $2000

;;; Loads the Invoker (page 2/3), Selector App (at $4000...$9FFF),
;;; and Resources (Aux LC), then invokes the app.

.scope

        jmp     start

        ;; ProDOS parameter blocks

        .byte   $03
        plp
        jsr     $3000
L2008:  .byte   0
        .byte   $04
L200A:  .byte   0
        bcc     L200F
        rts

L200F           := * + 1
        ora     ($00,x)
        .byte   0
        .byte   $04
L2012:  .byte   0
        .byte   0
        rti

        .byte   0
        rts

        .byte   0
        .byte   0
        .byte   $04
L201A:  .byte   0
        .byte   0
        .byte   $34
        .byte   0
        php
        .byte   0
        .byte   0
        .byte   $02
L2022:  .byte   0
        .byte   0
        asl     $00
        ora     ($00,x)
        php
        .byte   $53
        adc     $6C
        adc     $63
        .byte   $74
        .byte   $6F
        .byte   $72

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

        WRAPPED_MLI_CALL OPEN, $2003
        beq     L2049
        brk

L2049:  lda     L2008
        sta     L2022
        sta     L200A
        sta     L2012
        sta     L201A

        WRAPPED_MLI_CALL SET_MARK, $2021
        beq     :+
        brk

:       WRAPPED_MLI_CALL READ, $2009
        beq     :+
        brk

:       WRAPPED_MLI_CALL READ, $2011
        beq     :+
        brk

:       WRAPPED_MLI_CALL READ, $2019
        beq     :+
        brk

:
L2092           := * + 2

        ;; Copy last Resources segment to Aux LC1
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        ldx     #$00
:       lda     $3400,x
        sta     $D000,x
        lda     $3500,x
        sta     $D100,x
        lda     $3600,x
        sta     $D200,x
        lda     $3700,x
        sta     $D300,x
        lda     $3800,x
        sta     $D400,x
        lda     $3900,x
        sta     $D500,x
        lda     $3A00,x
        sta     $D600,x
        lda     $3B00,x
        sta     $D700,x
        inx
        bne     :-

        sta     ALTZPOFF
        sta     ROMIN2

        WRAPPED_MLI_CALL CLOSE, $2026

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
