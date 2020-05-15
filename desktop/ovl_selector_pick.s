;;; ============================================================
;;; Overlay for Selector Picker
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

;;; See docs/Selector_List_Format.md for file format

.proc selector_overlay2
        .org $9000

io_buf := $0800

selector_list   := $0C00

exec:
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

L9017:  lda     selector_list + kSelectorListNumRunListOffset
        clc
        adc     selector_list + kSelectorListNumOtherListOffset
        sta     num_selector_list_items
        lda     #$00
        sta     LD344
        jsr     get_copied_to_ramcard_flag
        cmp     #$80
        bne     L9015
        jsr     JUMP_TABLE_REDRAW_WINDOWS
        lda     #$06
        jsr     L9C09
        bne     L9015
        jsr     L9C26
        pla
        rts

L903C:  ldx     #$01
        copy16  selector_menu_addr, @load
        @load := *+1
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
        jsr     JUMP_TABLE_REDRAW_WINDOWS
        pla
        tay
        pla
        tax
        pla
        bne     L900F
        inc     L938F
        stx     which_run_list
        sty     copy_when
        lda     #$00
L9080:  dey
        beq     L9088
        sec
        ror     a
        jmp     L9080

L9088:  sta     copy_when
        jsr     L9CBA
        bpl     L9093
        jmp     L9016

L9093:  copy16  selector_list, L938B
        lda     which_run_list
        cmp     #$01
        bne     L90D3
        lda     L938B
        cmp     #$08
        beq     L90F4
        ldy     copy_when
        lda     L938B
        jsr     L9A0A
        inc     selector_list + kSelectorListNumRunListOffset
        copy16  selector_menu_addr, @addr
        @addr := *+1
        inc     dummy1234
        jsr     L9CEA
        bpl     L90D0
        jmp     L9016

L90D0:  jmp     L900F

L90D3:  lda     L938C
        cmp     #$10
        beq     L90FF
        ldy     copy_when
        lda     L938C
        clc
        adc     #$08
        jsr     L9A61
        inc     selector_list + kSelectorListNumOtherListOffset
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


which_run_list:  .byte   0
copy_when:  .byte   0


L9105:  lda     #$00
        sta     L938B
        sta     L938C
        copy    #$FF, selected_index
        jsr     L9390
        jsr     L9D22
        bpl     L911D
        jmp     L936E

L911D:  jsr     L99B3
L9120:  jsr     L9646
        bmi     L9120
        beq     L912A
        jmp     L933F

L912A:  lda     selected_index
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

L9146:  lda     selected_index
        jsr     maybe_toggle_entry_hilite
        jsr     main::set_cursor_watch
        lda     selected_index
        jsr     L9A97
        beq     L915D
        jsr     main::set_cursor_pointer
        jmp     L933F

L915D:  jsr     main::set_cursor_pointer
        copy    #$FF, selected_index
        jsr     L99F5
        jsr     L9D28
        jsr     L99B3
        inc     L938F
        jmp     L9120

L9174:  lda     selected_index
        jsr     maybe_toggle_entry_hilite
        jsr     L936E
        lda     selected_index
        jsr     get_file_entry_addr
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L918C:  lda     ($06),y
        sta     path_buf1,y
        dey
        bpl     L918C
        ldy     #kSelectorEntryFlagsOffset
        lda     ($06),y
        sta     L9281
        lda     selected_index
        jsr     get_file_path_addr
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L91AA:  lda     ($06),y
        sta     path_buf0,y
        dey
        bpl     L91AA
        ldx     #$01
        lda     selected_index
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
        jsr     JUMP_TABLE_REDRAW_WINDOWS
        pla
        tay
        pla
        tax
        pla
        beq     L91DF
        rts

L91DF:  inc     L938F
        stx     which_run_list
        sty     copy_when
        lda     #$00
L91EA:  dey                     ; map 0/1/2 to $00/$80/$C0
        beq     L91F2
        sec
        ror     a
        jmp     L91EA

L91F2:  sta     copy_when
        jsr     L9CBA
        bpl     L91FD
        jmp     L936E

L91FD:  lda     selected_index
        cmp     #$09
        bcc     L923C
        lda     which_run_list
        cmp     #$02
        beq     L926A
        lda     L938B
        cmp     #$08
        bne     L9215
        jmp     L90F4

L9215:  lda     selected_index
        jsr     L9A97
        beq     L9220
        jmp     L936E

L9220:  ldx     L938B
        inc     L938B
        inc     selector_list + kSelectorListNumRunListOffset
        copy16  selector_menu_addr, @addr
        @addr := *+1
        inc     dummy1234
        txa
        jmp     L926D

L923C:  lda     which_run_list
        cmp     #$01
        beq     L926A
        lda     L938C
        cmp     #$10
        bne     L924D
        jmp     L9105

L924D:  lda     selected_index
        jsr     L9A97
        beq     L9258
        jmp     L936E

L9258:  ldx     L938C
        inc     L938C
        inc     selector_list + kSelectorListNumOtherListOffset
        lda     L938C
        clc
        adc     #$07
        jmp     L926D

L926A:  lda     selected_index
L926D:  ldy     copy_when
        jsr     L9A0A
        jsr     L9CEA
        beq     L927B
        jmp     L936E

L927B:  jsr     main::set_cursor_pointer
        jmp     L900F

L9281:  .byte   0
L9282:  lda     selected_index
        jsr     maybe_toggle_entry_hilite
        jsr     main::set_cursor_watch
        lda     selected_index
        jsr     get_file_entry_addr
        stax    $06
        ldy     #kSelectorEntryFlagsOffset
        lda     ($06),y
        cmp     #kSelectorEntryCopyNever
        beq     L92F0
        sta     L938A
        jsr     get_copied_to_ramcard_flag
        beq     L92F0
        lda     L938A
        beq     L92CE
        lda     selected_index
        jsr     L9E61
        beq     L92D6
        lda     selected_index
        jsr     get_file_path_addr
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

L92CE:  lda     selected_index
        jsr     L9E61
        bne     L92F0
L92D6:  lda     selected_index
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

L92F0:  lda     selected_index
        jsr     get_file_path_addr
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
        jsr     main::set_cursor_pointer
        copy    #$FF, selected_index
        jmp     L936E

L933F:  pha
        lda     L938E
        cmp     #$02
        bne     L934F
        lda     #$07
        jsr     JUMP_TABLE_RESTORE_OVL
        jsr     JUMP_TABLE_REDRAW_WINDOWS
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

selected_index:
        .byte   0

L938E:  .byte   0
L938F:  .byte   0


L9390:  MGTK_RELAY_CALL MGTK::OpenWindow, winfo_entry_picker
        lda     winfo_entry_picker
        jsr     main::set_port_from_window_id
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, entry_picker_outer_rect
        MGTK_RELAY_CALL MGTK::FrameRect, entry_picker_inner_rect
        MGTK_RELAY_CALL MGTK::MoveTo, entry_picker_line1_start
        MGTK_RELAY_CALL MGTK::LineTo, entry_picker_line1_end
        MGTK_RELAY_CALL MGTK::MoveTo, entry_picker_line2_start
        MGTK_RELAY_CALL MGTK::LineTo, entry_picker_line2_end
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, entry_picker_ok_rect
        MGTK_RELAY_CALL MGTK::FrameRect, entry_picker_cancel_rect
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
        lda     dialog_label_pos::xcoord
        sta     L94A8
        tya
        pha
        cmp     #16             ; 3rd column (16-24)
        bcc     L9441
        sec
        sbc     #16
        jmp     L9448

        ;; 8 rows
L9441:  cmp     #8              ; 2nd column (8-15)
        bcc     L9448
        sec
        sbc     #8

        ;; A has row
L9448:  ldx     #0
        ldy     #kEntryPickerItemHeight
        jsr     Multiply_16_8_16 ; A,X = A,X * Y
        clc
        adc     #32
        sta     dialog_label_pos::ycoord
        txa
        adc     #0
        sta     dialog_label_pos::ycoord+1
        pla

        cmp     #8
        bcs     :+
        lda     #0              ; col 1
        tax
        beq     L947F           ; always

:       cmp     #16
        bcs     :+
        ldx     #0
        lda     #115            ; col 2
        bne     L947F           ; always

:       ldax    #220            ; col 3

L947F:  clc
        adc     #10
        sta     dialog_label_pos::xcoord
        txa
        adc     #0
        sta     dialog_label_pos::xcoord+1
        MGTK_RELAY_CALL MGTK::MoveTo, dialog_label_pos
        ldax    $06
        jsr     L94CB
        lda     L94A8
        sta     dialog_label_pos::xcoord
        lda     #0
        sta     dialog_label_pos::xcoord+1
        rts

L94A8:  .byte   0

L94A9:  MGTK_RELAY_CALL MGTK::MoveTo, entry_picker_ok_pos
        addr_call main::draw_text1, aux::str_ok_label
        rts

L94BA:  MGTK_RELAY_CALL MGTK::MoveTo, entry_picker_cancel_pos
        addr_call main::draw_text1, aux::str_cancel_label
        rts

L94CB:  stax    $06
        ldy     #$00
        lda     ($06),y
        tay
L94D4:  lda     ($06),y
        sta     path_buf2+2,y
        dey
        bpl     L94D4
        copy16  #path_buf2+3, path_buf2
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

;;; ============================================================

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
        jsr     main::set_port_from_window_id
        lda     winfo_entry_picker
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL MGTK::InRect, entry_picker_ok_rect
        cmp     #MGTK::inrect_inside
        bne     L96C8
        yax_call ButtonEventLoopRelay, kEntryDialogWindowID, entry_picker_ok_rect
        bmi     L96C7
        lda     #$00
L96C7:  rts

L96C8:  MGTK_RELAY_CALL MGTK::InRect, entry_picker_cancel_rect
        cmp     #MGTK::inrect_inside
        bne     L96EF
        yax_call ButtonEventLoopRelay, kEntryDialogWindowID, entry_picker_cancel_rect
        bmi     L96EE
        lda     #$01
L96EE:  rts

L96EF:  sub16   screentowindow_windowx, #10, screentowindow_windowx
        sub16   screentowindow_windowy, #25, screentowindow_windowy
        bpl     L9716
        return  #$FF

        ;; Determine column
L9716:  cmp16   screentowindow_windowx, #110
        bmi     L9736
        cmp16   screentowindow_windowx, #220
        bmi     L9732
        lda     #2
        bne     L9738
L9732:  lda     #1
        bne     L9738
L9736:  lda     #0

        ;; Determine row
L9738:  pha
        ldax    screentowindow_windowy
        ldy     #kEntryPickerItemHeight
        jsr     Divide_16_8_16
        stax    screentowindow_windowy
        cmp     #8
        bcc     :+
        pla
        return  #$FF

:       pla
        asl     a
        asl     a
        asl     a
        clc
        adc     screentowindow_windowy
        sta     new_selection
        cmp     #8
        bcs     L9782
        cmp     L938B
        bcs     L9790

L976A:  cmp     selected_index           ; same as previous selection?
        beq     :+
        lda     selected_index
        jsr     maybe_toggle_entry_hilite
        lda     new_selection
        sta     selected_index
        jsr     maybe_toggle_entry_hilite
:       jsr     main::detect_double_click
        rts

L9782:  sec
        sbc     #8
        cmp     L938C
        bcs     L9790
        clc
        adc     #8
        jmp     L976A

L9790:  lda     selected_index
        jsr     maybe_toggle_entry_hilite
        copy    #$FF, selected_index
        rts

new_selection:
        .byte   0

;;; ============================================================

maybe_toggle_entry_hilite:
        bpl     L97A0
        rts

L97A0:  pha
        lsr     a
        lsr     a
        lsr     a
        tax
        beq     L97B6
        cmp     #1
        bne     L97B2
        addr_jump L97B6, $0069

L97B2:  ldax    #210
L97B6:  clc
        adc     #9
        sta     entry_picker_item_rect::x1
        txa
        adc     #0
        sta     entry_picker_item_rect::x1+1
        pla
        cmp     #8
        bcc     L97D4
        cmp     #16
        bcs     L97D1
        sec
        sbc     #8
        jmp     L97D4

L97D1:  sec
        sbc     #16
L97D4:  ldx     #0
        ldy     #kEntryPickerItemHeight
        jsr     Multiply_16_8_16
        clc
        adc     #24
        sta     entry_picker_item_rect::y1
        txa
        adc     #0
        sta     entry_picker_item_rect::y1+1
        add16   entry_picker_item_rect::x1, #106, entry_picker_item_rect::x2
        add16   entry_picker_item_rect::y1, #kEntryPickerItemHeight-1, entry_picker_item_rect::y2
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, entry_picker_item_rect
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
        MGTK_RELAY_CALL MGTK::PaintRect, entry_picker_ok_rect
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, entry_picker_ok_rect
        return  #0

L9885:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, entry_picker_cancel_rect
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, entry_picker_cancel_rect
        return  #1

L98AC:  lda     L938B
        ora     L938C
        beq     L98F5
        lda     selected_index
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
L98CE:  lda     selected_index
        jsr     maybe_toggle_entry_hilite
        lda     selected_index
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
        sta     selected_index
        jsr     maybe_toggle_entry_hilite
L98F5:  return  #$FF

L98F8:  lda     L938B
        ora     L938C
        beq     L993C
        lda     selected_index
        bpl     L9917
        ldx     #$10
        lda     L99ED
        bpl     L9935
        ldx     #$08
        lda     L99E5
        bpl     L9935
        lda     #$00
        beq     L9936
L9917:  lda     selected_index
        jsr     maybe_toggle_entry_hilite
        lda     selected_index
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
L9936:  sta     selected_index
        jsr     maybe_toggle_entry_hilite
L993C:  return  #$FF

L993F:  lda     L938B
        ora     L938C
        beq     L9975
        lda     selected_index
        bpl     L9956
        ldx     #$17
L994E:  lda     L99DD,x
        bpl     L996F
        dex
        bpl     L994E
L9956:  lda     selected_index
        jsr     maybe_toggle_entry_hilite
        ldx     selected_index
L995F:  dex
        bmi     L996A
        lda     L99DD,x
        bpl     L996F
        jmp     L995F

L996A:  ldx     #$18
        jmp     L995F

L996F:  sta     selected_index
        jsr     maybe_toggle_entry_hilite
L9975:  return  #$FF

L9978:  lda     L938B
        ora     L938C
        beq     L99B0
        lda     selected_index
        bpl     L998F
        ldx     #$00
L9987:  lda     L99DD,x
        bpl     L99AA
        inx
        bne     L9987
L998F:  lda     selected_index
        jsr     maybe_toggle_entry_hilite
        ldx     selected_index
L9998:  inx
        cpx     #$18
        bcs     L99A5
        lda     L99DD,x
        bpl     L99AA
        jmp     L9998

L99A5:  ldx     #$FF
        jmp     L9998

L99AA:  sta     selected_index
        jsr     maybe_toggle_entry_hilite
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
        MGTK_RELAY_CALL MGTK::PaintRect, entry_picker_all_items_rect
        rts

        rts

        rts

;;; Input: A = index, Y = copy_when (1=boot, 2=use, 3=never)

L9A0A:  cmp     #8
        bcc     L9A11
        jmp     L9A61

L9A11:  sta     L9A60
        tya
        pha
        lda     L9A60
        jsr     get_file_entry_addr
        stax    $06
        lda     L9A60
        jsr     get_resource_entry_addr
        stax    $08
        ldy     path_buf1
L9A2D:  lda     path_buf1,y
        sta     ($06),y
        sta     ($08),y
        dey
        bpl     L9A2D
        ldy     #kSelectorEntryFlagsOffset
        pla
        sta     ($06),y
        sta     ($08),y
        lda     L9A60
        jsr     get_file_path_addr
        stax    $06
        lda     L9A60
        jsr     get_resource_path_addr
        stax    $08
        ldy     path_buf0
L9A55:  lda     path_buf0,y
        sta     ($06),y
        sta     ($08),y
        dey
        bpl     L9A55
        rts

L9A60:  .byte   0

;;; ============================================================

L9A61:  sta     L9A96
        tya
        pha
        lda     L9A96
        jsr     get_file_entry_addr
        stax    $06
        ldy     path_buf1
L9A73:  lda     path_buf1,y
        sta     ($06),y
        dey
        bpl     L9A73
        ldy     #kSelectorEntryFlagsOffset
        pla
        sta     ($06),y
        lda     L9A96
        jsr     get_file_path_addr
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
L9AA8:  dec     selector_list + kSelectorListNumRunListOffset
        dec     L938B
        copy16  selector_menu_addr, @addr
        @addr := *+1
        dec     dummy1234
        jmp     L9CEA

L9AC0:  lda     L9BD4
        cmp     L938B
        beq     L9AA8
        jsr     get_file_entry_addr
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
        ldy     #kSelectorEntryFlagsOffset
        lda     ($08),y
        sta     ($06),y
        lda     L9BD4
        jsr     get_resource_entry_addr
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
        ldy     #kSelectorEntryFlagsOffset
        lda     ($08),y
        sta     ($06),y
        lda     L9BD4
        jsr     get_file_path_addr
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
        jsr     get_resource_path_addr
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
        dec     selector_list + kSelectorListNumOtherListOffset
        dec     L938C
        jmp     L9CEA

L9B70:  lda     L9BD4
        sec
        sbc     #$08
        cmp     L938C
        bne     L9B84
        dec     selector_list + kSelectorListNumOtherListOffset
        dec     L938C
        jmp     L9CEA

L9B84:  lda     L9BD4
        jsr     get_file_entry_addr
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
        jsr     get_file_path_addr
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
        ldy     #kSelectorEntryFlagsOffset
        lda     ($08),y
        sta     ($06),y
        inc     L9BD4
        jmp     L9B70

L9BD4:  .byte   0

;;; ============================================================
;;; Entry name address in the file buffer
;;; Input: A = Entry
;;; Output: A,X = Address

.proc get_file_entry_addr
        addr := selector_list + kSelectorListEntriesOffset
        jsr     times16
        clc
        adc     #<addr
        tay
        txa
        adc     #>addr
        tax
        tya
        rts
.endproc

;;; ============================================================
;;; Path address in the file buffer
;;; Input: A = Entry
;;; Output: A,X = Address

.proc get_file_path_addr
        addr := selector_list + kSelectorListPathsOffset

        jsr     times64
        clc
        adc     #<addr
        tay
        txa
        adc     #>addr
        tax
        tya
        rts
.endproc

;;; ============================================================
;;; Entry name address in the resource block (used for menu items)
;;; Input: A = Entry
;;; Output: A,X = Address

.proc get_resource_entry_addr
        jsr     times16
        clc
        adc     #<run_list_entries
        tay
        txa
        adc     #>run_list_entries
        tax
        tya
        rts
.endproc

;;; ============================================================
;;; Path address in the resource block (used for invoking)
;;; Input: A = Entry
;;; Output: A,X = Address

.proc get_resource_path_addr
        jsr     times64
        clc
        adc     #<run_list_paths
        tay
        txa
        adc     #>run_list_paths
        tax
        tya
        rts
.endproc

;;; ============================================================

L9C09:  sta     warning_dialog_num
        yax_call main::invoke_dialog_proc, $0C, warning_dialog_num
        rts

filename_buffer := $1C00

        DEFINE_OPEN_PARAMS open_params, filename_buffer, io_buf
        DEFINE_WRITE_PARAMS write_params, selector_list, kSelectorListBufSize
        DEFINE_CLOSE_PARAMS flush_close_params

L9C26:  addr_call copy_desktop_orig_prefix, filename_buffer
        inc     filename_buffer ; Append '/' separator
        ldx     filename_buffer
        lda     #'/'
        sta     filename_buffer,x

        ldx     #$00            ; Append filename
        ldy     filename_buffer
:       inx
        iny
        lda     filename,x
        sta     filename_buffer,y
        cpx     filename
        bne     :-
        sty     filename_buffer

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
        jsr     JUMP_TABLE_REDRAW_WINDOWS
        pla
        jsr     JUMP_TABLE_ALERT_0
        beq     L9C69
        jmp     L9C5F

L9C81:  yax_call MLI_RELAY, FLUSH, flush_close_params
        yax_call MLI_RELAY, CLOSE, flush_close_params
        rts

        DEFINE_OPEN_PARAMS open_params2, filename, io_buf

filename:
        PASCAL_STRING "Selector.List"

        DEFINE_READ_PARAMS read_params2, selector_list, kSelectorListBufSize
        DEFINE_WRITE_PARAMS write_params2, selector_list, kSelectorListBufSize
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

L9D28:  lda     selector_list + kSelectorListNumRunListOffset
        sta     L938B
        beq     L9D55
        lda     #$00
        sta     L9D8C
L9D35:  lda     L9D8C
        cmp     L938B
        beq     L9D55
        jsr     times16
        clc
        adc     #kSelectorListEntriesOffset
        pha
        txa
        adc     #$0C
        tax
        pla
        ldy     L9D8C
        jsr     L942B
        inc     L9D8C
        jmp     L9D35

L9D55:  lda     selector_list + kSelectorListNumOtherListOffset
        sta     L938C
        beq     L9D89
        lda     #$00
        sta     L9D8C
L9D62:  lda     L9D8C
        cmp     L938C
        beq     L9D89
        clc
        adc     #$08
        jsr     times16
        clc
        adc     #kSelectorListEntriesOffset
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

;;; ============================================================
;;; Times 16 - for computing entry list offsets
;;; Input: A = number
;;; Output: A,X = result

.proc times16
        ldx     #0
        stx     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        ldx     hi
        rts

hi:     .byte   0
.endproc

;;; ============================================================
;;; Times 64 - for computing path list offsets
;;; Input: A = number
;;; Output: A,X = result

.proc times64
        ldx     #0
        stx     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        ldx     hi
        rts

hi:     .byte   0
.endproc

;;; ============================================================

.proc MLI_RELAY
        sty     call
        stax    params
        sta     ALTZPOFF
        sta     ROMIN2
        jsr     MLI
call:   .byte   0
params: .addr   0
        sta     ALTZPON
        tax
        lda     LCBANK1
        lda     LCBANK1
        txa
        rts
.endproc

;;; ============================================================

.proc get_copied_to_ramcard_flag
        sta     ALTZPOFF
        lda     LCBANK2
        lda     LCBANK2
        lda     COPIED_TO_RAMCARD_FLAG
        tax
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        txa
        rts
.endproc

.proc copy_ramcard_prefix
        stax    @addr
        sta     ALTZPOFF
        lda     LCBANK2
        lda     LCBANK2

        ldx     RAMCARD_PREFIX
:       lda     RAMCARD_PREFIX,x
        @addr := *+1
        sta     dummy1234,x
        dex
        bpl     :-

        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts
.endproc

.proc copy_desktop_orig_prefix
        stax    @addr
        sta     ALTZPOFF
        lda     LCBANK2
        lda     LCBANK2

        ldx     DESKTOP_ORIG_PREFIX
:       lda     DESKTOP_ORIG_PREFIX,x
        @addr := *+1
        sta     dummy1234,x
        dex
        bpl     :-

        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts
.endproc

;;; ============================================================

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, 0

L9E61:  jsr     L9E74
        stax    get_file_info_params::pathname
        yax_call MLI_RELAY, GET_FILE_INFO, get_file_info_params
        rts

L9E74:  sta     L9EBF
        addr_call copy_ramcard_prefix, L9EC1
        lda     L9EBF
        jsr     get_file_path_addr
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
        ldax    #L9EC1
        rts

L9EBF:  .byte   0
L9EC0:  .byte   0
L9EC1:  .byte   0

;;; ============================================================
;;; Double Click Detection
;;; Returns with A=0 if double click, A=$FF otherwise.

.proc detect_double_click
        ;; Stash initial coords
        ldx     #.sizeof(MGTK::Point)-1
:       copy    event_coords,x, coords,x

        dex
        bpl     :-

        copy16  SETTINGS + DeskTopSettings::dblclick_speed, counter

        ;; Decrement counter, bail if time delta exceeded
loop:   dec16   counter
        lda     counter
        ora     counter+1
        beq     exit

        MGTK_CALL MGTK::PeekEvent, event_params

        ;; Check coords, bail if pixel delta exceeded
        jsr     check_delta
        bmi     exit            ; moved past delta; no double-click

        lda     event_kind
        cmp     #MGTK::EventKind::no_event
        beq     loop
        cmp     #MGTK::EventKind::drag
        beq     loop
        cmp     #MGTK::EventKind::button_up
        bne     :+

        MGTK_CALL MGTK::GetEvent, event_params
        jmp     loop

:       cmp     #MGTK::EventKind::button_down
        beq     :+
        cmp     #MGTK::EventKind::apple_key ; modified-click
        bne     exit

:       MGTK_CALL MGTK::GetEvent, event_params
        return  #0              ; double-click

exit:   return  #$FF            ; not double-click

        ;; Is the new coord within range of the old coord?
.proc check_delta
        ;; compute x delta
        lda     event_xcoord
        sec
        sbc     xcoord
        sta     delta
        lda     event_xcoord+1
        sbc     xcoord+1
        bpl     :+

        ;; is -delta < x < 0 ?
        lda     delta
        cmp     #AS_BYTE(-kDoubleClickDeltaX)
        bcs     check_y
fail:   return  #$FF

        ;; is 0 < x < delta ?
:       lda     delta
        cmp     #kDoubleClickDeltaX
        bcs     fail

        ;; compute y delta
check_y:
        lda     event_ycoord
        sec
        sbc     ycoord
        sta     delta
        lda     event_ycoord+1
        sbc     ycoord+1
        bpl     :+

        ;; is -delta < y < 0 ?
        lda     delta
        cmp     #AS_BYTE(-kDoubleClickDeltaY)
        bcs     ok

        ;; is 0 < y < delta ?
:       lda     delta
        cmp     #kDoubleClickDeltaY
        bcs     fail
ok:     return  #0
.endproc

counter:
        .word   0
coords:
xcoord: .word   0
ycoord: .word   0
delta:  .byte   0
.endproc

;;; ============================================================

        PAD_TO $A000

.endproc ; selector_overlay2

selector_picker_exec    := selector_overlay2::exec
