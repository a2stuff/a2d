        .setcpu "6502"

;;; NB: Compiled as part of ovl34567.s

;;; ==================================================
;;; Overlay for Selector (part of it, anyway)
;;; ==================================================

        .org $7000
.proc selector_overlay

L7000:  stx     L73A9
        sty     L73AA
        jsr     common_overlay::L5CF7
        jsr     L7101
        jsr     L70AD
        jsr     common_overlay::L5E87
        lda     path_buf0
        beq     L7056
        addr_call common_overlay::L6129, path_buf0
        ldy     path_buf0
L7021:  lda     path_buf0,y
        sta     $5028,y
        dey
        bpl     L7021
        jsr     common_overlay::L5F49
        ldy     path_buf0
L7030:  lda     path_buf0,y
        cmp     #$2F
        beq     L7044
        dey
        cpy     #$01
        bne     L7030
        lda     #$00
        sta     path_buf0
        jmp     L7056

L7044:  ldx     #$00
L7046:  iny
        inx
        lda     path_buf0,y
        sta     L709D,x
        cpy     path_buf0
        bne     L7046
        stx     L709D
L7056:  jsr     common_overlay::L5F5B
        lda     #$00
        bcs     L706A
        addr_call common_overlay::L6516, $709D
        sta     $D920
        jsr     common_overlay::L6586
L706A:  jsr     common_overlay::L6163
        jsr     common_overlay::L61B1
        jsr     common_overlay::L606D
        lda     path_buf0
        bne     L707B
        jsr     common_overlay::L6D30
L707B:  copy16  #$2001, $D484
        jsr     common_overlay::L6D27
        jsr     common_overlay::L6693
        copy16  #$2001, $D484
        lda     #$FF
        sta     $D8EC
        jmp     common_overlay::L5106

;;; ==================================================

L709D:  .res 16, 0

;;; ==================================================


L70AD:  ldx     L7207
L70B0:  lda     L7207+1,x
        sta     $6D1E,x
        dex
        lda     L7207+1,x
        sta     $6D1E,x
        dex
        dex
        bpl     L70B0
        lda     #$00
        sta     $51AE
        lda     #$80
        sta     $5104
        copy16  #$0601, $D484
        lda     winfo12
        jsr     common_overlay::L62C8
        lda     L73A9
        jsr     L7467
        lda     L73AA
        jsr     L747B
        lda     #$80
        sta     $5103
        lda     #$AB
        sta     $531C
        lda     #$73
        sta     $531D
        lda     #$F4
        sta     $5B24
        lda     #$74
        sta     $5B25
        rts

L7101:  lda     winfo12
        jsr     common_overlay::L62C8
        lda     path_buf0
        beq     L7116
        addr_call common_overlay::L5E0A, $D729
        jmp     L711D

L7116:  addr_call common_overlay::L5E0A, $D718
L711D:  addr_call common_overlay::L5E6F, $D849
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR ; penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, dialog_rect1
        MGTK_RELAY_CALL MGTK::FrameRect, dialog_rect2
        addr_call common_overlay::L5E57, $D769
        addr_call common_overlay::L5E6F, $D797
        MGTK_RELAY_CALL MGTK::MoveTo, $D922
        addr_call common_overlay::L5DED, $D7DE
        MGTK_RELAY_CALL MGTK::MoveTo, $D926
        addr_call common_overlay::L5DED, $D7F6
        MGTK_RELAY_CALL MGTK::MoveTo, $D92A
        addr_call common_overlay::L5DED, $D802
        MGTK_RELAY_CALL MGTK::MoveTo, $D92E
        addr_call common_overlay::L5DED, $D814
        MGTK_RELAY_CALL MGTK::MoveTo, $D932
        addr_call common_overlay::L5DED, $D81F
        MGTK_RELAY_CALL MGTK::MoveTo, $D936
        addr_call common_overlay::L5DED, $D830
        MGTK_RELAY_CALL MGTK::MoveTo, $D93A
        addr_call common_overlay::L5DED, $D840
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, $D93E
        MGTK_RELAY_CALL MGTK::FrameRect, $D946
        MGTK_RELAY_CALL MGTK::FrameRect, $D94E
        MGTK_RELAY_CALL MGTK::FrameRect, $D956
        MGTK_RELAY_CALL MGTK::FrameRect, $D95E
        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        rts

;;; ==================================================

        .byte   $00

L7207:  .byte   $29
        entry   0, $725D
        entry   0, $732F
        entry   0, $6593
        entry   0, $664E
        entry   0, $6DC2
        entry   0, $6DD0
        entry   0, $6E1D
        entry   0, $69C6
        entry   0, $6A18
        entry   0, $6A53
        entry   0, $6AAC
        entry   0, $6B01
        entry   0, $6B44
        entry   0, $66D8

L7232:  .byte   $29
        entry   0, $72CD
        entry   0, $736C
        entry   0, $65F0
        entry   0, $6693
        entry   0, $6DC9
        entry   0, $6DD4
        entry   0, $6E31
        entry   0, $6B72
        entry   0, $6BC4
        entry   0, $6BFF
        entry   0, $6C58
        entry   0, $6CAD
        entry   0, $6CF0
        entry   0, $684F

;;; ==================================================

        copy16  #$2001, $D484
        jsr     common_overlay::L6D27
        ldx     L7232
L726D:  lda     L7232+1,x
        sta     $6D1E,x
        dex
        lda     L7232+1,x
        sta     $6D1E,x
        dex
        dex
        bpl     L726D
        lda     #$80
        sta     $51AE
        sta     $5105
        lda     $D8F0
        sta     $D8F1
        lda     #$00
        sta     $D8F0
        lda     $D443
        bne     L72BF
        lda     #$00
        sta     $D443
        ldx     path_buf0
        beq     L72BF
L72A0:  lda     path_buf0,x
        cmp     #$2F
        beq     L72AD
        dex
        bne     L72A0
        jmp     L72BF

L72AD:  ldy     #$00
L72AF:  iny
        inx
        lda     path_buf0,x
        sta     $D443,y
        cpx     path_buf0
        bne     L72AF
        sty     $D443
L72BF:  copy16  #$0601, $D484
        jsr     common_overlay::L6D27
        rts

        addr_call common_overlay::L647C, path_buf0
        bne     L72E2
        lda     $D443
        beq     L72E7
        cmp     #$0F
        bcs     L72E8
        jmp     L72EE

L72E2:  lda     #$40
        jsr     JUMP_TABLE_ALERT_0
L72E7:  rts

L72E8:  lda     #$FB
        jsr     JUMP_TABLE_ALERT_0
        rts

L72EE:  MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo15
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo12
        sta     $D8EC
        jsr     common_overlay::L55BA
        copy16  #$59B8, $5B24
        ldx     $50AA
        txs
        ldx     L73A9
        ldy     L73AA
        return  #$00

        MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo15
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo12
        lda     #$00
        sta     $D8EC
        jsr     common_overlay::L55BA
        copy16  #$59B8, $5B24
        ldx     $50AA
        txs
        return  #$FF

        copy16  #$2001, $D484
        jsr     common_overlay::L6D27
        ldx     L7207
L737C:  lda     L7207+1,x
        sta     $6D1E,x
        dex
        lda     L7207+1,x
        sta     $6D1E,x
        dex
        dex
        bpl     L737C
        copy16  #$0601, $D484
        jsr     common_overlay::L6D27
        lda     #$00
        sta     $5105
        sta     $51AE
        lda     $D8F1
        sta     $D8F0
        rts

L73A9:  .byte   0
L73AA:  .byte   0

        MGTK_RELAY_CALL MGTK::InRect, $D966
        cmp     #MGTK::inrect_inside
        bne     L73BB
        jmp     L73FE

L73BB:  MGTK_RELAY_CALL MGTK::InRect, $D96E
        cmp     #MGTK::inrect_inside
        bne     L73CB
        jmp     L7413

L73CB:  MGTK_RELAY_CALL MGTK::InRect, $D976
        cmp     #MGTK::inrect_inside
        bne     L73DB
        jmp     L7428

L73DB:  MGTK_RELAY_CALL MGTK::InRect, $D97E
        cmp     #MGTK::inrect_inside
        bne     L73EB
        jmp     L743D

L73EB:  MGTK_RELAY_CALL MGTK::InRect, $D986
        cmp     #MGTK::inrect_inside
        bne     L73FB
        jmp     L7452

L73FB:  return  #$00

L73FE:  lda     L73A9
        cmp     #1
        beq     L7410
        jsr     L7467
        lda     #1
        sta     L73A9
        jsr     L7467
L7410:  return  #$FF

L7413:  lda     L73A9
        cmp     #2
        beq     L7425
        jsr     L7467
        lda     #2
        sta     L73A9
        jsr     L7467
L7425:  return  #$FF

L7428:  lda     L73AA
        cmp     #1
        beq     L743A
        jsr     L747B
        lda     #1
        sta     L73AA
        jsr     L747B
L743A:  return  #$FF

L743D:  lda     L73AA
        cmp     #2
        beq     L744F
        jsr     L747B
        lda     #2
        sta     L73AA
        jsr     L747B
L744F:  return  #$FF

L7452:  lda     L73AA
        cmp     #3
        beq     L7464
        jsr     L747B
        lda     #3
        sta     L73AA
        jsr     L747B
L7464:  return  #$FF

L7467:  cmp     #1
        bne     L7473
        addr_call L749B, $D93E
        rts

L7473:  addr_call L749B, $D946
        rts

L747B:  cmp     #1
        bne     L7487
        addr_call L749B, $D94E
        rts

L7487:  cmp     #2
        bne     L7493
        addr_call L749B, $D956
        rts

L7493:  addr_call L749B, $D95E
        rts

L749B:  stax    $06
        ldy     #7
L74A1:  lda     ($06),y
        sta     $D98E,y
        dey
        bpl     L74A1
        lda     $D98E
        clc
        adc     #2
        sta     $D98E
        bcc     L74B7
        inc     $D98F
L74B7:  lda     $D990
        clc
        adc     #2
        sta     $D990
        bcc     L74C5
        inc     $D991
L74C5:  lda     $D992
        sec
        sbc     #2
        sta     $D992
        bcs     L74D3
        dec     $D993
L74D3:  lda     $D994
        sec
        sbc     #2
        sta     $D994
        bcs     L74E1
        dec     $D995
L74E1:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, $D98E
        rts

        lda     winfo12
        jsr     common_overlay::L62C8
        lda     $D20A
        bne     L7500
        rts

L7500:  lda     $D209
        and     #$7F
        cmp     #'1'
        bne     L750C
        jmp     L73FE

L750C:  cmp     #'2'
        bne     L7513
        jmp     L7413

L7513:  cmp     #'3'
        bne     L751A
        jmp     L7428

L751A:  cmp     #'4'
        bne     L7521
        jmp     L743D

L7521:  cmp     #'5'
        bne     L7528
        jmp     L7452

L7528:  rts

;;; ==================================================

        PAD_TO $7800
.endproc ; selector_overlay
