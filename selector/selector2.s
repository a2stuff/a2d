;;; ============================================================
;;; Quit Handler
;;; ============================================================

        .org    $1000

;;; This gets invoked via ProDOS QUIT, which relocated it to
;;; $1000 Main.

.scope

L1000:  jmp     L103A

L1003:  .byte   0, "Selector", 0

L100D:
L100E           := * + 1
        PASCAL_STRING "Loading Selector"
        PASCAL_STRING "Selector"

        ;; ProDOS MLI call param blocks
        .byte   4
L1028:  .byte   0
        .byte   0
        .byte   $1C
        .byte   0
        asl     $00
        .byte   0
        ora     ($00,x)
        ora     ($90,x)
        ora     ($03),y
        asl     a:$10,x
        clc
L1039:  .byte   0
L103A:  lda     ROMIN2
        jsr     SETVID
        jsr     SETKBD
        sta     CLR80VID
        sta     SETALTCHAR
        sta     CLR80COL
        jsr     SLOT3ENTRY
        jsr     HOME
        lda     #$00
        sta     SHADOW
        lda     #$80
L105B           := * + 2
        sta     ALTZPON
        sta     FBUFFR
        sta     $0101
        sta     ALTZPOFF
        lda     NEWVIDEO
        ora     #$20
        sta     NEWVIDEO
        lda     #$0C
        sta     CV
        jsr     VTAB
        lda     #$50
        sec
        sbc     L100D
        lsr     a
        sta     CH
        ldy     #$00
L107F:  lda     L100E,y
        ora     #$80
        jsr     COUT
        iny
        cpy     L100D
        bne     L107F
        MLI_CALL CLOSE, $102F
        ldx     #$17
        lda     #$01
        sta     $BF58,x
        dex
        lda     #$00
L109D:  sta     $BF58,x
        dex
        bpl     L109D
        lda     #$CF
        sta     $BF58
        lda     L1003
        bne     L10E6
        MLI_CALL GET_PREFIX, $1031
        beq     L10B8
        jmp     L118B

L10B8:  lda     #$FF
        sta     L1003
        lda     IRQ_VECTOR
        sta     L1189
        lda     $03FF
        sta     L118A
        lda     LCBANK2
        lda     LCBANK2
        ldy     #$00
L10D1:  lda     L1000,y
        sta     $D100,y
        lda     L1000+$100,y
        sta     $D200,y
        dey
        bne     L10D1
        lda     ROMIN2
        jmp     L10F2

L10E6:  lda     L1189
        sta     IRQ_VECTOR
        lda     L118A
        sta     $03FF
L10F2:  MLI_CALL SET_PREFIX, $1031
        beq     L10FD
        jmp     L1127

L10FD:  MLI_CALL OPEN, $1034
        beq     L1108
        jmp     L118B

L1108:  lda     L1039
        sta     L1028
        MLI_CALL READ, $1027
        beq     L1119
        jmp     L118B

L1119:  MLI_CALL CLOSE, $102F
        beq     L1124
        jmp     L118B

L1124:  jmp     LOADER

L1127:  jsr     SLOT3ENTRY
        jsr     HOME
        lda     #$0C
        sta     CV
        jsr     VTAB
        lda     #$50
        sec
        sbc     L115E
        lsr     a
        sta     CH
        ldy     #$00
L113F:  lda     L115F,y
        ora     #$80
        jsr     COUT
        iny
        cpy     L115E
        bne     L113F
L114D:  sta     KBDSTRB
L1150:  lda     CLR80COL
        bpl     L1150
        and     #$7F
        cmp     #$0D
        bne     L114D
        jmp     L103A

L115E:
L115F:= *+1
        PASCAL_STRING "Insert the system disk and press <Return>."

L1189:  .byte   0
L118A:  .byte   0
L118B:  sta     $06
        jmp     MONZ

        PAD_TO  $11D0

.endscope