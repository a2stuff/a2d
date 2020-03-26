        lda     LCBANK2
        lda     LCBANK2
        ldy     #$00
L2008:  lda     $2027,y
        sta     $D100,y
        lda     $2127,y
        sta     $D200,y
        dey
        bne     L2008
        lda     ROMIN2
        MLI_CALL QUIT, $2020
        .byte   $04
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
