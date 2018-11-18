        .setcpu "6502"

;;; NB: Compiled as part of ovl34567.s

;;; ============================================================
;;; Overlay for Selector (part of it, anyway)
;;; ============================================================

        .org $9000
.proc selector_overlay2

;;; Entry points in desktop_main
launch_dialog           := $A500
set_cursor_watch        := $B3E7
set_cursor_pointer      := $B403
LB445                   := $B445 ; ???
draw_text1              := $B708
set_port_from_window_id := $B7B9

        sta     L938E
        ldx     #$FF
        stx     L938F
        cmp     #$01
        beq     L903C
        jmp     L9105

L900F:  pha
        lda     L938F
        bpl     L9017
L9015:  pla
L9016:  rts

L9017:  lda     $0C00
        clc
        adc     $0C01
        sta     LD343
        lda     #$00
        sta     LD343+1
        jsr     L9DED
        cmp     #$80
        bne     L9015
        jsr     JUMP_TABLE_REDRAW_ALL
        lda     #$06
        jsr     L9C09
        bne     L9015
        jsr     L9C26
        pla
        rts

L903C:  ldx     #$01
        copy16  $DB1C, load
        load := *+1
        lda     dummy1234
        cmp     #$0D
        bcc     L9052
        inx
L9052:  lda     #$00
        sta     path_buf0
        sta     path_buf1
        ldy     #$03
        lda     #$02
        jsr     common_overlay_L5000
        pha
        txa
        pha
        tya
        pha
        lda     #$07
        jsr     JUMP_TABLE_RESTORE_OVL
        jsr     JUMP_TABLE_REDRAW_ALL
        pla
        tay
        pla
        tax
        pla
        bne     L900F
        inc     L938F
        stx     L9103
        sty     L9104
        lda     #$00
L9080:  dey
        beq     L9088
        sec
        ror     a
        jmp     L9080

L9088:  sta     L9104
        jsr     L9CBA
        bpl     L9093
        jmp     L9016

L9093:  copy16  $0C00, L938B
        lda     L9103
        cmp     #$01
        bne     L90D3
        lda     L938B
        cmp     #$08
        beq     L90F4
        ldy     L9104
        lda     L938B
        jsr     L9A0A
        inc     $0C00
        copy16  $DB1C, @addr
        @addr := *+1
        inc     dummy1234
        jsr     L9CEA
        bpl     L90D0
        jmp     L9016

L90D0:  jmp     L900F

L90D3:  lda     L938C
        cmp     #$10
        beq     L90FF
        ldy     L9104
        lda     L938C
        clc
        adc     #$08
        jsr     L9A61
        inc     $0C01
        jsr     L9CEA
        bpl     L90F1
        jmp     L9016

L90F1:  jmp     L900F

L90F4:  lda     #$01
L90F6:  jsr     L9C09
        dec     L938F
        jmp     L9016

L90FF:  lda     #$02
        bne     L90F6
L9103:  .byte   0
L9104:  .byte   0
L9105:  lda     #$00
        sta     L938B
        sta     L938C
        lda     #$FF
        sta     L938D
        jsr     L9390
        jsr     L9D22
        bpl     L911D
        jmp     L936E

L911D:  jsr     L99B3
L9120:  jsr     L9646
        bmi     L9120
        beq     L912A
        jmp     L933F

L912A:  lda     L938D
        bmi     L9120
        lda     L938E
        cmp     #$02
        bne     L9139
        jmp     L9174

L9139:  cmp     #$03
        bne     L913F
        beq     L9146
L913F:  cmp     #$04
        bne     L9120
        jmp     L9282

L9146:  lda     L938D
        jsr     L979D
        jsr     set_cursor_watch
        lda     L938D
        jsr     L9A97
        beq     L915D
        jsr     set_cursor_pointer
        jmp     L933F

L915D:  jsr     set_cursor_pointer
        lda     #$FF
        sta     L938D
        jsr     L99F5
        jsr     L9D28
        jsr     L99B3
        inc     L938F
        jmp     L9120

L9174:  lda     L938D
        jsr     L979D
        jsr     L936E
        lda     L938D
        jsr     L9BD5
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L918C:  lda     ($06),y
        sta     path_buf1,y
        dey
        bpl     L918C
        ldy     #$0F
        lda     ($06),y
        sta     L9281
        lda     L938D
        jsr     L9BE2
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L91AA:  lda     ($06),y
        sta     path_buf0,y
        dey
        bpl     L91AA
        ldx     #$01
        lda     L938D
        cmp     #$09
        bcc     L91BC
        inx
L91BC:  clc
        lda     L9281
        rol     a
        rol     a
        adc     #$01
        tay
        lda     #$02
        jsr     common_overlay_L5000
        pha
        txa
        pha
        tya
        pha
        lda     #$07
        jsr     JUMP_TABLE_RESTORE_OVL
        jsr     JUMP_TABLE_REDRAW_ALL
        pla
        tay
        pla
        tax
        pla
        beq     L91DF
        rts

L91DF:  inc     L938F
        stx     L9103
        sty     L9104
        lda     #$00
L91EA:  dey
        beq     L91F2
        sec
        ror     a
        jmp     L91EA

L91F2:  sta     L9104
        jsr     L9CBA
        bpl     L91FD
        jmp     L936E

L91FD:  lda     L938D
        cmp     #$09
        bcc     L923C
        lda     L9103
        cmp     #$02
        beq     L926A
        lda     L938B
        cmp     #$08
        bne     L9215
        jmp     L90F4

L9215:  lda     L938D
        jsr     L9A97
        beq     L9220
        jmp     L936E

L9220:  ldx     L938B
        inc     L938B
        inc     $0C00
        copy16  $DB1C, @addr
        @addr := *+1
        inc     dummy1234
        txa
        jmp     L926D

L923C:  lda     L9103
        cmp     #$01
        beq     L926A
        lda     L938C
        cmp     #$10
        bne     L924D
        jmp     L9105

L924D:  lda     L938D
        jsr     L9A97
        beq     L9258
        jmp     L936E

L9258:  ldx     L938C
        inc     L938C
        inc     $0C01
        lda     L938C
        clc
        adc     #$07
        jmp     L926D

L926A:  lda     L938D
L926D:  ldy     L9104
        jsr     L9A0A
        jsr     L9CEA
        beq     L927B
        jmp     L936E

L927B:  jsr     set_cursor_pointer
        jmp     L900F

L9281:  .byte   0
L9282:  lda     L938D
        jsr     L979D
        jsr     set_cursor_watch
        lda     L938D
        jsr     L9BD5
        stax    $06
        ldy     #$0F
        lda     ($06),y
        cmp     #$C0
        beq     L92F0
        sta     L938A
        jsr     L9DED
        beq     L92F0
        lda     L938A
        beq     L92CE
        lda     L938D
        jsr     L9E61
        beq     L92D6
        lda     L938D
        jsr     L9BE2
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L92C1:  lda     ($06),y
        sta     buf_win_path,y
        dey
        bpl     L92C1
        lda     #$FF
        jmp     L933F

L92CE:  lda     L938D
        jsr     L9E61
        bne     L92F0
L92D6:  lda     L938D
        jsr     L9E74
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L92E5:  lda     ($06),y
        sta     buf_win_path,y
        dey
        bpl     L92E5
        jmp     L9307

L92F0:  lda     L938D
        jsr     L9BE2
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L92FF:  lda     ($06),y
        sta     buf_win_path,y
        dey
        bpl     L92FF
L9307:  ldy     buf_win_path
L930A:  lda     buf_win_path,y
        cmp     #$2F
        beq     L9314
        dey
        bne     L930A
L9314:  dey
        sty     L938A
        iny
        ldx     #$00
L931B:  iny
        inx
        lda     buf_win_path,y
        sta     buf_filename2,x
        cpy     buf_win_path
        bne     L931B
        stx     buf_filename2
        lda     L938A
        sta     buf_win_path
        jsr     JUMP_TABLE_LAUNCH_FILE
        jsr     set_cursor_pointer
        lda     #$FF
        sta     L938D
        jmp     L936E

L933F:  pha
        lda     L938E
        cmp     #$02
        bne     L934F
        lda     #$07
        jsr     JUMP_TABLE_RESTORE_OVL
        jsr     JUMP_TABLE_REDRAW_ALL
L934F:  MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entry_picker
        pla
        jmp     L900F

L936E:  MGTK_RELAY_CALL MGTK::InitPort, grafport3
        MGTK_RELAY_CALL MGTK::SetPort, grafport3
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entry_picker
        rts

L938A:  .byte   0
L938B:  .byte   0
L938C:  .byte   0
L938D:  .byte   0
L938E:  .byte   0
L938F:  .byte   0


L9390:  MGTK_RELAY_CALL MGTK::OpenWindow, winfo_entry_picker
        lda     winfo_entry_picker
        jsr     set_port_from_window_id
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, rect_D6D8
        MGTK_RELAY_CALL MGTK::FrameRect, rect_D6E0
        MGTK_RELAY_CALL MGTK::MoveTo, pos_D6E8
        MGTK_RELAY_CALL MGTK::LineTo, pos_D6EC
        MGTK_RELAY_CALL MGTK::MoveTo, pos_D6F0
        MGTK_RELAY_CALL MGTK::LineTo, pos_D6F4
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, rect_D6F8
        MGTK_RELAY_CALL MGTK::FrameRect, rect_D700
        jsr     L94A9
        jsr     L94BA
        lda     L938E
        cmp     #$02
        bne     L9417
        addr_call L94F0, edit_an_entry_label
        rts

L9417:  cmp     #$03
        bne     L9423
        addr_call L94F0, delete_an_entry_label
        rts

L9423:  addr_call L94F0, run_an_entry_label
        rts

L942B:  stx     $07
        sta     $06
        lda     dialog_label_pos
        sta     L94A8
        tya
        pha
        cmp     #$10
        bcc     L9441
        sec
        sbc     #$10
        jmp     L9448

L9441:  cmp     #$08
        bcc     L9448
        sec
        sbc     #$08
L9448:  ldx     #$00
        stx     L94A7
        asl     a
        rol     L94A7
        asl     a
        rol     L94A7
        asl     a
        rol     L94A7
        clc
        adc     #$20
        sta     dialog_label_pos+2
        lda     L94A7
        adc     #0
        sta     dialog_label_pos+3
        pla
        cmp     #$08
        bcs     L9471
        lda     #$00
        tax
        beq     L947F
L9471:  cmp     #$10
        bcs     L947B
        ldx     #$00
        lda     #$73
        bne     L947F
L947B:  ldax    #$00DC
L947F:  clc
        adc     #$0A
        sta     dialog_label_pos
        txa
        adc     #$00
        sta     dialog_label_pos+1
        MGTK_RELAY_CALL MGTK::MoveTo, dialog_label_pos
        lda     $06
        ldx     $07
        jsr     L94CB
        lda     L94A8
        sta     dialog_label_pos
        lda     #0
        sta     dialog_label_pos+1
        rts

L94A7:  .byte   0
L94A8:  .byte   0

L94A9:  MGTK_RELAY_CALL MGTK::MoveTo, pos_D708
        addr_call draw_text1, $AE40
        rts

L94BA:  MGTK_RELAY_CALL MGTK::MoveTo, pos_D70C
        addr_call draw_text1, $AE96
        rts

L94CB:  stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L94D4:  lda     ($06),y
        sta     path_buf2+2,y
        dey
        bpl     L94D4
        copy16  #$D487, path_buf2
        MGTK_RELAY_CALL MGTK::DrawText, path_buf2
        rts

L94F0:  stax    $06
        ldy     #$00
        lda     ($06),y
        sta     $08
        inc16   $06
        MGTK_RELAY_CALL MGTK::TextWidth, $06
        lsr16    $09
        lda     #$01
        sta     L9539
        lda     #$5E
        lsr     L9539
        ror     a
        sec
        sbc     $09
        sta     pos_dialog_title
        lda     L9539
        sbc     $0A
        sta     pos_dialog_title+1
        MGTK_RELAY_CALL MGTK::MoveTo, pos_dialog_title
        MGTK_RELAY_CALL MGTK::DrawText, $06
        rts

L9539:  .byte   0
L953A:  lda     #$00
        sta     L95BF
L953F:  MGTK_RELAY_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     L95A2
        lda     winfo_entry_picker
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL MGTK::InRect, rect_D6F8
        cmp     #MGTK::inrect_inside
        beq     L957C
        lda     L95BF
        beq     L9584
        jmp     L953F

L957C:  lda     L95BF
        bne     L9584
        jmp     L953F

L9584:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, rect_D6F8
        lda     L95BF
        clc
        adc     #$80
        sta     L95BF
        jmp     L953F

L95A2:  lda     L95BF
        beq     L95AA
        return  #$FF

L95AA:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, rect_D6F8
        return  #$00

L95BF:  .byte   0
L95C0:  lda     #$00
        sta     L9645
L95C5:  MGTK_RELAY_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     L9628
        lda     winfo_entry_picker
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL MGTK::InRect, rect_D700
        cmp     #MGTK::inrect_inside
        beq     L9602
        lda     L9645
        beq     L960A
        jmp     L95C5

L9602:  lda     L9645
        bne     L960A
        jmp     L95C5

L960A:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, rect_D700
        lda     L9645
        clc
        adc     #$80
        sta     L9645
        jmp     L95C5

L9628:  lda     L9645
        beq     L9630
        return  #$FF

L9630:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, rect_D700
        return  #$01

L9645:  .byte   0
L9646:  MGTK_RELAY_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        bne     L9659
        jmp     L9660

L9659:  cmp     #MGTK::EventKind::key_down
        bne     L9646
        jmp     L9822

L9660:  MGTK_RELAY_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_which_area
        bne     L9671
        return  #$FF

L9671:  cmp     #MGTK::Area::content
        beq     L9678
        return  #$FF

L9678:  lda     findwindow_window_id
        cmp     winfo_entry_picker
        beq     L9683
        return  #$FF

L9683:  lda     winfo_entry_picker
        jsr     set_port_from_window_id
        lda     winfo_entry_picker
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL MGTK::InRect, rect_D6F8
        cmp     #MGTK::inrect_inside
        bne     L96C8
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, rect_D6F8
        jsr     L953A
        bmi     L96C7
        lda     #$00
L96C7:  rts

L96C8:  MGTK_RELAY_CALL MGTK::InRect, rect_D700
        cmp     #MGTK::inrect_inside
        bne     L96EF
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, rect_D700
        jsr     L95C0
        bmi     L96EE
        lda     #$01
L96EE:  rts

L96EF:  sub16   screentowindow_windowx, #10, screentowindow_windowx
        sub16   screentowindow_windowy, #25, screentowindow_windowy
        bpl     L9716
        return  #$FF

L9716:  cmp16   screentowindow_windowx, #110
        bmi     L9736
        cmp16   screentowindow_windowx, #220
        bmi     L9732
        lda     #$02
        bne     L9738
L9732:  lda     #$01
        bne     L9738
L9736:  lda     #$00
L9738:  pha
        lsr16   screentowindow_windowy
        lsr16   screentowindow_windowy
        lsr16   screentowindow_windowy
        lda     screentowindow_windowy
        cmp     #8
        bcc     L9756
        pla
        return  #$FF

L9756:  pla
        asl     a
        asl     a
        asl     a
        clc
        adc     screentowindow_windowy
        sta     L979C
        cmp     #$08
        bcs     L9782
        cmp     L938B
        bcs     L9790
L976A:  cmp     L938D
        beq     L977E
        lda     L938D
        jsr     L979D
        lda     L979C
        sta     L938D
        jsr     L979D
L977E:  jsr     LB445
        rts

L9782:  sec
        sbc     #$08
        cmp     L938C
        bcs     L9790
        clc
        adc     #$08
        jmp     L976A

L9790:  lda     L938D
        jsr     L979D
        lda     #$FF
        sta     L938D
        rts

L979C:  .byte   0
L979D:  bpl     L97A0
        rts

L97A0:  pha
        lsr     a
        lsr     a
        lsr     a
        tax
        beq     L97B6
        cmp     #$01
        bne     L97B2
        addr_jump L97B6, $0069

L97B2:  ldax    #$00D2
L97B6:  clc
        adc     #$09
        sta     rect_D877
        txa
        adc     #$00
        sta     rect_D877+1
        pla
        cmp     #$08
        bcc     L97D4
        cmp     #$10
        bcs     L97D1
        sec
        sbc     #$08
        jmp     L97D4

L97D1:  sec
        sbc     #$10
L97D4:  asl     a
        asl     a
        asl     a
        clc
        adc     #$18
        sta     rect_D877+2
        lda     #$00
        adc     #$00
        sta     rect_D877+3
        add16   rect_D877, #106, rect_D877+4
        add16   rect_D877+2, #7, rect_D877+6
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, rect_D877
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        rts

        ;; key down handler
L9822:  lda     event_modifiers
        cmp     #MGTK::event_modifier_solid_apple
        bne     :+
        return  #$FF
:       lda     event_key
        and     #CHAR_MASK

        cmp     #CHAR_LEFT
        bne     :+
        jmp     L98F8

:       cmp     #CHAR_RIGHT
        bne     :+
        jmp     L98AC

:       cmp     #CHAR_RETURN
        bne     :+
        jmp     L985E

:       cmp     #CHAR_ESCAPE
        bne     :+
        jmp     L9885

:       cmp     #CHAR_DOWN
        bne     :+
        jmp     L9978

:       cmp     #CHAR_UP
        bne     :+
        jmp     L993F

:       return  #$FF

L985E:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, rect_D6F8
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, rect_D6F8
        return  #$00

L9885:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, rect_D700
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, rect_D700
        return  #$01

L98AC:  lda     L938B
        ora     L938C
        beq     L98F5
        lda     L938D
        bpl     L98CE
        ldx     #$00
        lda     L99DD
        bpl     L98EE
        ldx     #$08
        lda     L99E5
        bpl     L98EE
        ldx     #$10
        lda     L99ED
        bpl     L98EE
L98CE:  lda     L938D
        jsr     L979D
        lda     L938D
L98D7:  clc
        adc     #$08
        cmp     #$18
        bcc     L98E4
        sec
        sbc     #$20
        jmp     L98D7

L98E4:  tax
        lda     L99DD,x
        bpl     L98EE
        txa
        jmp     L98D7

L98EE:  txa
        sta     L938D
        jsr     L979D
L98F5:  return  #$FF

L98F8:  lda     L938B
        ora     L938C
        beq     L993C
        lda     L938D
        bpl     L9917
        ldx     #$10
        lda     L99ED
        bpl     L9935
        ldx     #$08
        lda     L99E5
        bpl     L9935
        lda     #$00
        beq     L9936
L9917:  lda     L938D
        jsr     L979D
        lda     L938D
L9920:  sec
        sbc     #$08
        bpl     L992B
        clc
        adc     #$20
        jmp     L9920

L992B:  tax
        lda     L99DD,x
        bpl     L9935
        txa
        jmp     L9920

L9935:  txa
L9936:  sta     L938D
        jsr     L979D
L993C:  return  #$FF

L993F:  lda     L938B
        ora     L938C
        beq     L9975
        lda     L938D
        bpl     L9956
        ldx     #$17
L994E:  lda     L99DD,x
        bpl     L996F
        dex
        bpl     L994E
L9956:  lda     L938D
        jsr     L979D
        ldx     L938D
L995F:  dex
        bmi     L996A
        lda     L99DD,x
        bpl     L996F
        jmp     L995F

L996A:  ldx     #$18
        jmp     L995F

L996F:  sta     L938D
        jsr     L979D
L9975:  return  #$FF

L9978:  lda     L938B
        ora     L938C
        beq     L99B0
        lda     L938D
        bpl     L998F
        ldx     #$00
L9987:  lda     L99DD,x
        bpl     L99AA
        inx
        bne     L9987
L998F:  lda     L938D
        jsr     L979D
        ldx     L938D
L9998:  inx
        cpx     #$18
        bcs     L99A5
        lda     L99DD,x
        bpl     L99AA
        jmp     L9998

L99A5:  ldx     #$FF
        jmp     L9998

L99AA:  sta     L938D
        jsr     L979D
L99B0:  return  #$FF

L99B3:  ldx     #$17
        lda     #$FF
L99B7:  sta     L99DD,x
        dex
        bpl     L99B7
        ldx     #$00
L99BF:  cpx     L938B
        beq     L99CB
        txa
        sta     L99DD,x
        inx
        bne     L99BF
L99CB:  ldx     #$00
L99CD:  cpx     L938C
        beq     L99DC
        txa
        clc
        adc     #$08
        sta     L99E5,x
        inx
        bne     L99CD
L99DC:  rts

L99DD:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L99E5:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L99ED:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
L99F5:  MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, rect_D87F
        rts

        rts

        rts

L9A0A:  cmp     #$08
        bcc     L9A11
        jmp     L9A61

L9A11:  sta     L9A60
        tya
        pha
        lda     L9A60
        jsr     L9BD5
        stax    $06
        lda     L9A60
        jsr     L9BEF
        stax    $08
        ldy     path_buf1
L9A2D:  lda     path_buf1,y
        sta     ($06),y
        sta     ($08),y
        dey
        bpl     L9A2D
        ldy     #$0F
        pla
        sta     ($06),y
        sta     ($08),y
        lda     L9A60
        jsr     L9BE2
        stax    $06
        lda     L9A60
        jsr     L9BFC
        stax    $08
        ldy     path_buf0
L9A55:  lda     path_buf0,y
        sta     ($06),y
        sta     ($08),y
        dey
        bpl     L9A55
        rts

L9A60:  .byte   0
L9A61:  sta     L9A96
        tya
        pha
        lda     L9A96
        jsr     L9BD5
        stax    $06
        ldy     path_buf1
L9A73:  lda     path_buf1,y
        sta     ($06),y
        dey
        bpl     L9A73
        ldy     #$0F
        pla
        sta     ($06),y
        lda     L9A96
        jsr     L9BE2
        stax    $06
        ldy     path_buf0
L9A8D:  lda     path_buf0,y
        sta     ($06),y
        dey
        bpl     L9A8D
        rts

L9A96:  .byte   0
L9A97:  sta     L9BD4
        cmp     #$08
        bcc     L9AA1
        jmp     L9B5F

L9AA1:  tax
        inx
        cpx     L938B
        bne     L9AC0
L9AA8:  dec     $0C00
        dec     L938B
        copy16  $DB1C, @addr
        @addr := *+1
        dec     dummy1234
        jmp     L9CEA

L9AC0:  lda     L9BD4
        cmp     L938B
        beq     L9AA8
        jsr     L9BD5
        stax    $06
        lda     $06
        adc     #$10
        sta     $08
        lda     $07
        adc     #$00
        sta     $09
        ldy     #$00
        lda     ($08),y
        tay
L9AE0:  lda     ($08),y
        sta     ($06),y
        dey
        bpl     L9AE0
        ldy     #$0F
        lda     ($08),y
        sta     ($06),y
        lda     L9BD4
        jsr     L9BEF
        stax    $06
        lda     $06
        adc     #$10
        sta     $08
        lda     $07
        adc     #$00
        sta     $09
        ldy     #$00
        lda     ($08),y
        tay
L9B08:  lda     ($08),y
        sta     ($06),y
        dey
        bpl     L9B08
        ldy     #$0F
        lda     ($08),y
        sta     ($06),y
        lda     L9BD4
        jsr     L9BE2
        stax    $06
        lda     $06
        adc     #$40
        sta     $08
        lda     $07
        adc     #$00
        sta     $09
        ldy     #$00
        lda     ($08),y
        tay
L9B30:  lda     ($08),y
        sta     ($06),y
        dey
        bpl     L9B30
        lda     L9BD4
        jsr     L9BFC
        stax    $06
        lda     $06
        adc     #$40
        sta     $08
        lda     $07
        adc     #$00
        sta     $09
        ldy     #$00
        lda     ($08),y
        tay
L9B52:  lda     ($08),y
        sta     ($06),y
        dey
        bpl     L9B52
        inc     L9BD4
        jmp     L9AC0

L9B5F:  sec
        sbc     #$07
        cmp     L938C
        bne     L9B70
        dec     $0C01
        dec     L938C
        jmp     L9CEA

L9B70:  lda     L9BD4
        sec
        sbc     #$08
        cmp     L938C
        bne     L9B84
        dec     $0C01
        dec     L938C
        jmp     L9CEA

L9B84:  lda     L9BD4
        jsr     L9BD5
        stax    $06
        lda     $06
        adc     #$10
        sta     $08
        lda     $07
        adc     #$00
        sta     $09
        ldy     #$00
        lda     ($08),y
        tay
L9B9F:  lda     ($08),y
        sta     ($06),y
        dey
        bpl     L9B9F
        lda     L9BD4
        jsr     L9BE2
        stax    $06
        lda     $06
        adc     #$40
        sta     $08
        lda     $07
        adc     #$00
        sta     $09
        ldy     #$00
        lda     ($08),y
        tay
L9BC1:  lda     ($08),y
        sta     ($06),y
        dey
        bpl     L9BC1
        ldy     #$0F
        lda     ($08),y
        sta     ($06),y
        inc     L9BD4
        jmp     L9B70

L9BD4:  .byte   0
L9BD5:  jsr     L9D8D
        clc
        adc     #$02
        tay
        txa
        adc     #$0C
        tax
        tya
        rts

L9BE2:  jsr     L9DA7
        clc
        adc     #$82
        tay
        txa
        adc     #$0D
        tax
        tya
        rts

L9BEF:  jsr     L9D8D
        clc
        adc     #$1E
        tay
        txa
        adc     #$DB
        tax
        tya
        rts

L9BFC:  jsr     L9DA7
        clc
        adc     #$9E
        tay
        txa
        adc     #$DB
        tax
        tya
        rts

L9C09:  sta     warning_dialog_num
        yax_call launch_dialog, $0C, warning_dialog_num
        rts

        DEFINE_OPEN_PARAMS open_params, $1C00, $800
        DEFINE_WRITE_PARAMS write_params, $C00, $800
        DEFINE_CLOSE_PARAMS flush_close_params

L9C26:  addr_call L9E2A, $1C00
        inc     $1C00
        ldx     $1C00
        lda     #$2F
        sta     $1C00,x
        ldx     #$00
        ldy     $1C00
L9C3D:  inx
        iny
        lda     L9C9A,x
        sta     $1C00,y
        cpx     L9C9A
        bne     L9C3D
        sty     $1C00
L9C4D:  yax_call MLI_RELAY, OPEN, open_params
        beq     L9C60
        lda     #$00
        jsr     L9C09
        beq     L9C4D
L9C5F:  rts

L9C60:  lda     open_params::ref_num
        sta     write_params::ref_num
        sta     flush_close_params::ref_num
L9C69:  yax_call MLI_RELAY, WRITE, write_params
        beq     L9C81
        pha
        jsr     JUMP_TABLE_REDRAW_ALL
        pla
        jsr     JUMP_TABLE_ALERT_0
        beq     L9C69
        jmp     L9C5F

L9C81:  yax_call MLI_RELAY, FLUSH, flush_close_params
        yax_call MLI_RELAY, CLOSE, flush_close_params
        rts

        DEFINE_OPEN_PARAMS open_params2, $9C9A, $800

L9C9A:  PASCAL_STRING "Selector.List"

        DEFINE_READ_PARAMS read_params2, $C00, $800
        DEFINE_WRITE_PARAMS write_params2, $C00, $800
        DEFINE_CLOSE_PARAMS close_params2

L9CBA:  yax_call MLI_RELAY, OPEN, open_params2
        beq     L9CCF
        lda     #$00
        jsr     L9C09
        beq     L9CBA
        return  #$FF

L9CCF:  lda     open_params2::ref_num
        sta     read_params2::ref_num
        yax_call MLI_RELAY, READ, read_params2
        bne     L9CE9
        yax_call MLI_RELAY, CLOSE, close_params2
L9CE9:  rts

L9CEA:  yax_call MLI_RELAY, OPEN, open_params2
        beq     L9CFF
        lda     #0
        jsr     L9C09
        beq     L9CBA
        return  #$FF

L9CFF:  lda     open_params2::ref_num
        sta     write_params2::ref_num
L9D05:  yax_call MLI_RELAY, WRITE, write_params2
        beq     L9D18
        jsr     JUMP_TABLE_ALERT_0
        beq     L9D05
        jmp     L9D21

L9D18:  yax_call MLI_RELAY, CLOSE, close_params2
L9D21:  rts

L9D22:  jsr     L9CBA
        bpl     L9D28
        rts

L9D28:  lda     $0C00
        sta     L938B
        beq     L9D55
        lda     #$00
        sta     L9D8C
L9D35:  lda     L9D8C
        cmp     L938B
        beq     L9D55
        jsr     L9D8D
        clc
        adc     #$02
        pha
        txa
        adc     #$0C
        tax
        pla
        ldy     L9D8C
        jsr     L942B
        inc     L9D8C
        jmp     L9D35

L9D55:  lda     $0C01
        sta     L938C
        beq     L9D89
        lda     #$00
        sta     L9D8C
L9D62:  lda     L9D8C
        cmp     L938C
        beq     L9D89
        clc
        adc     #$08
        jsr     L9D8D
        clc
        adc     #$02
        pha
        txa
        adc     #$0C
        tax
        lda     L9D8C
        clc
        adc     #$08
        tay
        pla
        jsr     L942B
        inc     L9D8C
        jmp     L9D62

L9D89:  return  #$00

L9D8C:  .byte   0
L9D8D:  ldx     #$00
        stx     L9DA6
        asl     a
        rol     L9DA6
        asl     a
        rol     L9DA6
        asl     a
        rol     L9DA6
        asl     a
        rol     L9DA6
        ldx     L9DA6
        rts

L9DA6:  .byte   0
L9DA7:  ldx     #$00
        stx     L9DC8
        asl     a
        rol     L9DC8
        asl     a
        rol     L9DC8
        asl     a
        rol     L9DC8
        asl     a
        rol     L9DC8
        asl     a
        rol     L9DC8
        asl     a
        rol     L9DC8
        ldx     L9DC8
        rts

L9DC8:  .byte   0

;;; ============================================================

.proc MLI_RELAY
        sty     call
        stax    params
        php
        sei
        sta     ALTZPOFF
        sta     ROMIN2
        jsr     MLI
call:   .byte   0
params: .addr   0
        sta     ALTZPON
        tax
        lda     LCBANK1
        lda     LCBANK1
        plp
        txa
        rts
.endproc

;;; ============================================================

L9DED:  sta     ALTZPOFF
        lda     LCBANK2
        lda     LCBANK2
        lda     LD3FF
        tax
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        txa
        rts

L9E05:  stax    L9E1B
        sta     ALTZPOFF
        lda     LCBANK2
        lda     LCBANK2
        ldx     LD3EE
L9E17:  lda     LD3EE,x
        .byte   $9D
L9E1B:  .addr   $1234
        dex
        bpl     L9E17
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts

L9E2A:  stax    L9E40
        sta     ALTZPOFF
        lda     LCBANK2
        lda     LCBANK2
        ldx     LD3AD
L9E3C:  lda     LD3AD,x
        .byte   $9D
L9E40:  .addr   $1234
        dex
        bpl     L9E3C
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, 0

L9E61:  jsr     L9E74
        stax    get_file_info_params::pathname
        yax_call MLI_RELAY, GET_FILE_INFO, get_file_info_params
        rts

L9E74:  sta     L9EBF
        addr_call L9E05, $9EC1
        lda     L9EBF
        jsr     L9BE2
        stax    $06
        ldy     #$00
        lda     ($06),y
        sta     L9EC0
        tay
L9E90:  lda     ($06),y
        and     #CHAR_MASK
        cmp     #'/'
        beq     L9E9B
        dey
        bne     L9E90
L9E9B:  dey
L9E9C:  lda     ($06),y
        and     #CHAR_MASK
        cmp     #'/'
        beq     L9EA7
        dey
        bne     L9E9C
L9EA7:  dey
        ldx     L9EC1
L9EAB:  inx
        iny
        lda     ($06),y
        sta     L9EC1,x
        cpy     L9EC0
        bne     L9EAB
        stx     L9EC1
        ldax    #$9EC1
        rts

L9EBF:  .byte   0
L9EC0:  .byte   0
L9EC1:  .byte   0
        ;; how much is buffer, how much is padding?

;;; ============================================================

        PAD_TO $A000
.endproc ; selector_overlay2
