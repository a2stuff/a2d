;;; ============================================================
;;; This chunk of code is wedged in between MGTK and the font,
;;; $851F - $87FF. No references to it have yet been identified.

        .byte   $03
        .addr    $85E9

L8522:  php
        lda     winfo7+MGTK::Winfo::port+5,x
        sta     $08+1
        ldy     #$14
        ldx     #$00
L852C:  lda     ($08),y
        sta     L8590,x
        iny
        inx
        cpx     #$04
        bne     L852C
        ldy     #$1C
        ldx     #$00
L853B:  lda     ($08),y
        sta     L8594,x
        iny
        inx
        cpx     #$04
        bne     L853B
        ldy     #$03
        sub16in ($06),y, L8590, ($06),y
        iny
        sub16in ($06),y, L8592, ($06),y
        ldy     #$03
        add16in ($06),y, L8594, ($06),y
        iny
        add16in ($06),y, L8596, ($06),y
        jsr     $83A5
        rts

L8590:  .byte   $24
L8591:  .byte   $00
L8592:  .byte   $23
L8593:  .byte   $00
L8594:  .byte   $00
L8595:  .byte   $00
L8596:  .byte   $00
L8597:  .byte   $00

        ldax    #0
:       sta     $D409,x
        sta     $D401,x
        sta     $D40D
        inx
        cpx     #$04
        bne     :-
        lda     #$0A
        sta     $D40D
        sta     $D40F

        MGTK_RELAY_CALL MGTK::SetPort, $D401
        rts

        addr_call $6B17, $1A39
        ldx     $D5CA
        txs
        rts

        addr_call $6B17, $1A56
        ldx     $D5CA
        txs
        rts

        addr_call $6B17, $1A71
        ldx     $D5CA
        txs
        rts

L85E0:  cmp     #$27
        bne     :+
        addr_call $6B17, $1B22
        ldx     $D5CA
        txs
        jmp     L8625

:       cmp     #$45
        bne     :+
        addr_call $6B17, $1B3B
        ldx     $D5CA
        txs
        jmp     L8625

:       cmp     #$52
        bne     :+
        addr_call $6B17, $1B5B
        ldx     $D5CA
        txs
        jmp     L8625

:       cmp     #$57
        bne     L8625
        addr_call $6B17, $1B7C
        ldx     $D5CA
        txs
L8625:  MGTK_RELAY_CALL MGTK::HiliteMenu, $D63F ; ???
        rts

        addr_call $6B17, $1B9C
        ldx     $D5CA
        txs
        MGTK_RELAY_CALL MGTK::HiliteMenu, $D63F ; ???
        rts

        addr_call $6B17, $1BBF
        ldx     $D5CA
        txs
        MGTK_RELAY_CALL MGTK::HiliteMenu, $D63F ; ???
        rts

        sta     L8737
        sty     L8738
        and     #$F0
        sta     on_line_unit_num
        sta     ALTZPOFF
        MLI_CALL ON_LINE, on_line_params
        sta     ALTZPON
        beq     L867B
L8672:  pha
        dec     $EF8A           ; ???
        dec     $EF88           ; ???
        pla
        rts

L867B:  lda     on_line_buffer
        beq     L8672
        jsr     $8388      ; into dynamically loaded code???
        jsr     DESKTOP_ALLOC_ICON ; AUX > MAIN call???
        ldy     L8738
        sta     $D464,y
        asl     a
        tax
        copy16  $F13A,x, $06
        ldx     #$00
        ldy     #$09
        lda     #' '
L869E:  sta     ($06),y
        iny
        inx
        cpx     #$12
        bne     L869E
        ldy     #$09
        lda     on_line_buffer
        and     #$0F
        sta     on_line_buffer
        sta     ($06),y
        ldx     #$00
        ldy     #$0B
L86B6:  lda     on_line_buffer+1,x
        cmp     #$41            ; convert to lowercase ???
        bcc     L86C4
        cmp     #$5F
        bcs     L86C4
        clc
        adc     #$20
L86C4:  sta     ($06),y
        iny
        inx
        cpx     on_line_buffer
        bne     L86B6
        ldy     #9
        lda     ($06),y
        clc
        adc     #2              ; increase length by 2 (spaces) ???
        sta     ($06),y
        lda     L8737           ; type?
        and     #$0F

        cmp     #$04
        bne     L86ED
        ldy     #IconEntry::iconbits
        lda     #<$14B4            ; $14B4 ???
        sta     ($06),y
        iny
        lda     #>$14B4
        sta     ($06),y
        jmp     L870A

L86ED:  cmp     #$0B
        bne     L86FF
        ldy     #IconEntry::iconbits
        lda     #<$1470            ; $1470 ???
        sta     ($06),y
        iny
        lda     #>$1470
        sta     ($06),y
        jmp     L870A

L86FF:  ldy     #IconEntry::iconbits
        lda     #<$1440            ; $1440 ???
        sta     ($06),y
        iny
        lda     #>$1440
        sta     ($06),y

L870A:  ldy     #IconEntry::win_type
        lda     #0
        sta     ($06),y
        inc     L8738
        lda     L8738
        asl     a
        asl     a
        tax
        ldy     #IconEntry::iconx
:       lda     L8739,x
        sta     ($06),y
        inx
        iny
        cpy     #7
        bne     :-
        ldx     $EF8A
        dex
        ldy     #0
        lda     ($06),y
        sta     $EF8B,x
        jsr     $83A5
        return  #0

L8737:  .byte   $60             ; file type ???
L8738:  .byte   $04
L8739:  .byte   $00,$00,$00,$00

L873D:  DEFINE_POINT 500, 16
        DEFINE_POINT 500, 41
        DEFINE_POINT 500, 66
        DEFINE_POINT 500, 91
        DEFINE_POINT 500, 116

        DEFINE_POINT 440, 16
        DEFINE_POINT 440, 41
        DEFINE_POINT 440, 66
        DEFINE_POINT 440, 91
        DEFINE_POINT 440, 116
        DEFINE_POINT 440, 141

        DEFINE_POINT 400, 16
        DEFINE_POINT 400, 41
        DEFINE_POINT 400, 66

        DEFINE_ON_LINE_PARAMS on_line_params, $60, on_line_buffer ; Slot 6 Drive 1
        on_line_unit_num := on_line_params::unit_num

        ;; Per ProDOS TRM this should be 256 bytes!
on_line_buffer:
        .byte   $0B
        .byte   "GRAPHICS.TK",$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$C8
