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
        sta     selector_action
        ldx     #$FF
        stx     L938F
        cmp     #SelectorAction::add
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
        jsr     JUMP_TABLE_CLEAR_UPDATES
        lda     #$06
        jsr     show_warning_dialog
        bne     L9015
        jsr     write_file_to_original_prefix
        pla
        rts

L903C:  ldx     #$01
        copy16  selector_menu_addr, @load
        @load := *+1
        lda     SELF_MODIFIED
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
        jsr     JUMP_TABLE_CLEAR_UPDATES
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
        jsr     read_file
        bpl     L9093
        jmp     L9016

L9093:  copy16  selector_list, num_run_list_entries
        lda     which_run_list
        cmp     #$01
        bne     L90D3
        lda     num_run_list_entries
        cmp     #$08
        beq     L90F4
        ldy     copy_when       ; Flags
        lda     num_run_list_entries
        jsr     L9A0A
        inc     selector_list + kSelectorListNumRunListOffset
        copy16  selector_menu_addr, @addr
        @addr := *+1
        inc     SELF_MODIFIED
        jsr     write_file
        bpl     L90D0
        jmp     L9016

L90D0:  jmp     L900F

L90D3:  lda     num_other_run_list_entries
        cmp     #$10
        beq     L90FF
        ldy     copy_when       ; Flags
        lda     num_other_run_list_entries
        clc
        adc     #8
        jsr     assign_entry_data
        inc     selector_list + kSelectorListNumOtherListOffset
        jsr     write_file
        bpl     L90F1
        jmp     L9016

L90F1:  jmp     L900F

L90F4:  lda     #$01
L90F6:  jsr     show_warning_dialog
        dec     L938F
        jmp     L9016

L90FF:  lda     #$02
        bne     L90F6


which_run_list:  .byte   0
copy_when:  .byte   0

;;; ============================================================

L9105:  lda     #$00
        sta     num_run_list_entries
        sta     num_other_run_list_entries
        copy    #$FF, selected_index
        jsr     L9390
        jsr     read_file_and_draw_entries
        bpl     L911D
        jmp     close_window

L911D:  jsr     populate_entries_flag_table

dialog_loop:
        jsr     event_loop
        bmi     dialog_loop     ; N set = nothing selected, re-enter loop

        beq     :+              ; Z set = OK selected
        jmp     do_cancel

        ;; Which action are we?
:       lda     selected_index
        bmi     dialog_loop
        lda     selector_action
        cmp     #SelectorAction::edit
        bne     :+
        jmp     do_edit

:       cmp     #SelectorAction::delete
        bne     :+
        beq     do_delete       ; always

:       cmp     #SelectorAction::run
        bne     dialog_loop
        jmp     do_run

;;; ============================================================

do_delete:
        lda     selected_index
        jsr     maybe_toggle_entry_hilite
        jsr     main::set_cursor_watch
        lda     selected_index
        jsr     remove_entry
        beq     :+
        jsr     main::set_cursor_pointer
        jmp     do_cancel

:       jsr     main::set_cursor_pointer
        copy    #$FF, selected_index
        jsr     draw_items_rect
        jsr     draw_all_entries
        jsr     populate_entries_flag_table
        inc     L938F

        jmp     dialog_loop

;;; ============================================================

do_edit:
        lda     selected_index
        jsr     maybe_toggle_entry_hilite
        jsr     close_window
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
        ldy     #0
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
        jsr     JUMP_TABLE_CLEAR_UPDATES
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
        jsr     read_file
        bpl     L91FD
        jmp     close_window

L91FD:  lda     selected_index
        cmp     #$09
        bcc     L923C
        lda     which_run_list
        cmp     #$02
        beq     L926A
        lda     num_run_list_entries
        cmp     #$08
        bne     L9215
        jmp     L90F4

L9215:  lda     selected_index
        jsr     remove_entry
        beq     L9220
        jmp     close_window

L9220:  ldx     num_run_list_entries
        inc     num_run_list_entries
        inc     selector_list + kSelectorListNumRunListOffset
        copy16  selector_menu_addr, @addr
        @addr := *+1
        inc     SELF_MODIFIED
        txa
        jmp     L926D

L923C:  lda     which_run_list
        cmp     #$01
        beq     L926A
        lda     num_other_run_list_entries
        cmp     #$10
        bne     L924D
        jmp     L9105

L924D:  lda     selected_index
        jsr     remove_entry
        beq     L9258
        jmp     close_window

L9258:  ldx     num_other_run_list_entries
        inc     num_other_run_list_entries
        inc     selector_list + kSelectorListNumOtherListOffset
        lda     num_other_run_list_entries
        clc
        adc     #$07
        jmp     L926D

L926A:  lda     selected_index
L926D:  ldy     copy_when
        jsr     L9A0A
        jsr     write_file
        beq     L927B
        jmp     close_window

L927B:  jsr     main::set_cursor_pointer
        jmp     L900F

L9281:  .byte   0

;;; ============================================================

do_run:
        lda     selected_index
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
        jsr     get_entry_ramcard_file_info
        beq     L92D6
        lda     selected_index
        jsr     get_file_path_addr
        stax    $06
        ldy     #0
        lda     ($06),y
        tay
L92C1:  lda     ($06),y
        sta     buf_win_path,y
        dey
        bpl     L92C1
        lda     #$FF
        jmp     do_cancel

L92CE:  lda     selected_index
        jsr     get_entry_ramcard_file_info
        bne     L92F0
L92D6:  lda     selected_index
        jsr     get_entry_ramcard_path
        stax    $06
        ldy     #0
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
        ldy     #0
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
        jsr     close_window
        jsr     JUMP_TABLE_CLEAR_UPDATES_REDRAW_ICONS
        jsr     JUMP_TABLE_LAUNCH_FILE
        jsr     main::set_cursor_pointer
        copy    #$FF, selected_index
        return  #0


do_cancel:
        pha
        lda     selector_action
        cmp     #SelectorAction::edit
        bne     :+
        lda     #$07
        jsr     JUMP_TABLE_RESTORE_OVL
        jsr     JUMP_TABLE_CLEAR_UPDATES
:       jsr     close_window
        pla
        jmp     L900F

;;; ============================================================

.proc close_window
        MGTK_RELAY_CALL MGTK::InitPort, main_grafport
        MGTK_RELAY_CALL MGTK::SetPort, main_grafport
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_entry_picker
        rts
.endproc

;;; ============================================================

L938A:  .byte   0
num_run_list_entries:
        .byte   0
num_other_run_list_entries:
        .byte   0

selected_index:
        .byte   0

selector_action:
        .byte   0
L938F:  .byte   0

;;; ============================================================

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
        lda     selector_action
        cmp     #SelectorAction::edit
        bne     L9417
        param_call draw_title_centered, label_edit
        rts

L9417:  cmp     #$03
        bne     L9423
        param_call draw_title_centered, label_del
        rts

L9423:  param_call draw_title_centered, label_run
        rts

;;; ============================================================

.proc draw_entry
        stx     $07
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
        jsr     draw_string
        lda     L94A8
        sta     dialog_label_pos::xcoord
        lda     #0
        sta     dialog_label_pos::xcoord+1
        rts

L94A8:  .byte   0
.endproc

;;; ============================================================

L94A9:  MGTK_RELAY_CALL MGTK::MoveTo, entry_picker_ok_pos
        param_call main::DrawString, aux::ok_button_label
        rts

L94BA:  MGTK_RELAY_CALL MGTK::MoveTo, entry_picker_cancel_pos
        param_call main::DrawString, aux::cancel_button_label
        rts

;;; ============================================================

.proc draw_string
        stax    $06
        ldy     #0
        lda     ($06),y
        tay
L94D4:  lda     ($06),y
        sta     path_buf2+2,y
        dey
        bpl     L94D4
        copy16  #path_buf2+3, path_buf2
        MGTK_RELAY_CALL MGTK::DrawText, path_buf2
        rts
.endproc

;;; ============================================================

.proc draw_title_centered
        text_params     := $6
        text_addr       := text_params + 0
        text_length     := text_params + 2
        text_width      := text_params + 3

        stax    text_addr       ; input is length-prefixed string
        ldy     #0
        lda     (text_addr),y
        sta     text_length
        inc16   text_addr ; point past length byte
        MGTK_RELAY_CALL MGTK::TextWidth, text_params

        kWidth = 350

        sub16   #kWidth, text_width, pos_dialog_title::xcoord
        lsr16   pos_dialog_title::xcoord ; /= 2
        MGTK_RELAY_CALL MGTK::MoveTo, pos_dialog_title
        MGTK_RELAY_CALL MGTK::DrawText, text_params
        rts
.endproc

;;; ============================================================
;;; When returning from event loop:
;;; N = nothing selected, re-enter loop
;;; Z = OK selected
;;; Otherwise: Cancel selected

event_loop:
        MGTK_RELAY_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jmp     handle_button
:       cmp     #MGTK::EventKind::key_down
        bne     event_loop
        jmp     handle_key

handle_button:
        MGTK_RELAY_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_which_area
        bne     :+
        return  #$FF

:       cmp     #MGTK::Area::content
        beq     :+
        return  #$FF

:       lda     findwindow_window_id
        cmp     winfo_entry_picker
        beq     :+
        return  #$FF

:       lda     winfo_entry_picker
        jsr     main::set_port_from_window_id
        lda     winfo_entry_picker
        sta     screentowindow_window_id
        MGTK_RELAY_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_RELAY_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_RELAY_CALL MGTK::InRect, entry_picker_ok_rect
        cmp     #MGTK::inrect_inside
        bne     not_ok
        param_call ButtonEventLoopRelay, kEntryDialogWindowID, entry_picker_ok_rect
        bmi     :+              ; nothing selected, re-enter loop
        lda     #$00            ; OK selected
:       rts

not_ok: MGTK_RELAY_CALL MGTK::InRect, entry_picker_cancel_rect
        cmp     #MGTK::inrect_inside
        bne     not_cancel
        param_call ButtonEventLoopRelay, kEntryDialogWindowID, entry_picker_cancel_rect
        bmi     :+              ; nothing selected, re-enter loop
        lda     #$01            ; Cancel selected
:       rts

not_cancel:
        sub16   screentowindow_windowx, #10, screentowindow_windowx
        sub16   screentowindow_windowy, #25, screentowindow_windowy
        bpl     :+
        return  #$FF            ; nothing selected, re-enter loop

        ;; Determine column
:       cmp16   screentowindow_windowx, #110
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
        return  #$FF            ; nothing selected, re-enter loop

:       pla
        asl     a
        asl     a
        asl     a
        clc
        adc     screentowindow_windowy
        sta     new_selection
        cmp     #8
        bcs     L9782
        cmp     num_run_list_entries
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
        cmp     num_other_run_list_entries
        bcs     L9790
        clc
        adc     #8
        jmp     L976A

L9790:  lda     selected_index
        jsr     maybe_toggle_entry_hilite
        copy    #$FF, selected_index ; nothing selected, re-enter loop
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
        param_jump L97B6, $0069

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

;;; ============================================================
;;; Key down handler

.proc handle_key
        lda     event_modifiers
        cmp     #MGTK::event_modifier_solid_apple
        bne     :+
        return  #$FF
:       lda     event_key

        cmp     #CHAR_LEFT
        bne     :+
        jmp     handle_key_left

:       cmp     #CHAR_RIGHT
        bne     :+
        jmp     handle_key_right

:       cmp     #CHAR_RETURN
        bne     :+
        jmp     handle_key_return

:       cmp     #CHAR_ESCAPE
        bne     :+
        jmp     handle_key_escape

:       cmp     #CHAR_DOWN
        bne     :+
        jmp     handle_key_down

:       cmp     #CHAR_UP
        bne     :+
        jmp     handle_key_up

:       return  #$FF
.endproc

;;; ============================================================

.proc handle_key_return
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, entry_picker_ok_rect
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, entry_picker_ok_rect
        return  #0
.endproc

;;; ============================================================

.proc handle_key_escape
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, entry_picker_cancel_rect
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, entry_picker_cancel_rect
        return  #1
.endproc

;;; ============================================================

.proc handle_key_right
        lda     num_run_list_entries
        ora     num_other_run_list_entries
        beq     done

        lda     selected_index
        bpl     move           ; have a selection

        ;; No selection; find a valid one in top row
        ldx     #0
        lda     entries_flag_table
        bpl     set

        ldx     #8
        lda     entries_flag_table+8
        bpl     set

        ldx     #16
        lda     entries_flag_table+16
        bpl     set

        ;; Change selection
move:   lda     selected_index  ; unselect current
        jsr     maybe_toggle_entry_hilite

        lda     selected_index
loop:   clc
        adc     #8
        cmp     #kSelectorListNumEntries
        bcc     :+
        clc
        adc     #1
        and     #7

:       tax
        lda     entries_flag_table,x
        bpl     set
        txa
        jmp     loop

set:    txa
        sta     selected_index
        jsr     maybe_toggle_entry_hilite

done:   return  #$FF
.endproc

;;; ============================================================

.proc handle_key_left
        lda     num_run_list_entries
        ora     num_other_run_list_entries
        beq     done

        lda     selected_index
        bpl     move            ; have a selection

        ;; No selection - re-use logic to find last item
        jmp     handle_key_up

        ;; Change selection
move:   lda     selected_index  ; unselect current
        jsr     maybe_toggle_entry_hilite

        lda     selected_index
loop:   sec
        sbc     #8
        bpl     :+
        sec
        sbc     #1
        and     #7
        ora     #16

:       tax
        lda     entries_flag_table,x
        bpl     set
        txa
        jmp     loop

set:    txa
        sta     selected_index
        jsr     maybe_toggle_entry_hilite

done:   return  #$FF
.endproc

;;; ============================================================

.proc handle_key_up
        lda     num_run_list_entries
        ora     num_other_run_list_entries
        beq     done

        lda     selected_index
        bpl     move            ; have a selection

        ;; No selection; find last valid one
        ldx     #kSelectorListNumEntries - 1
:       lda     entries_flag_table,x
        bpl     set
        dex
        bpl     :-

        ;; Change selection
move:   lda     selected_index  ; unselect current
        jsr     maybe_toggle_entry_hilite

        ldx     selected_index
loop:   dex                     ; to previous
        bmi     wrap
        lda     entries_flag_table,x
        bpl     set
        jmp     loop

wrap:   ldx     #kSelectorListNumEntries
        jmp     loop

set:    sta     selected_index
        jsr     maybe_toggle_entry_hilite

done:   return  #$FF
.endproc

;;; ============================================================

.proc handle_key_down
        lda     num_run_list_entries
        ora     num_other_run_list_entries
        beq     done

        lda     selected_index
        bpl     move           ; have a selection

        ;; No selection; find first valid one
        ldx     #0
:       lda     entries_flag_table,x
        bpl     set
        inx
        bne     :-

        ;; Change selection
move:   lda     selected_index  ; unselect current
        jsr     maybe_toggle_entry_hilite

        ldx     selected_index
loop:   inx                     ; to next
        cpx     #kSelectorListNumEntries
        bcs     wrap
        lda     entries_flag_table,x
        bpl     set             ; valid!
        jmp     loop

wrap:   ldx     #AS_BYTE(-1)
        jmp     loop

        ;; Set the selection
set:    sta     selected_index
        jsr     maybe_toggle_entry_hilite

done:   return  #$FF
.endproc

;;; ============================================================

.proc populate_entries_flag_table
        ldx     #kSelectorListNumEntries - 1
        lda     #$FF
:       sta     entries_flag_table,x
        dex
        bpl     :-

        ldx     #0
:       cpx     num_run_list_entries
        beq     :+
        txa
        sta     entries_flag_table,x
        inx
        bne     :-

:       ldx     #0
:       cpx     num_other_run_list_entries
        beq     :+
        txa
        clc
        adc     #8
        sta     entries_flag_table+8,x
        inx
        bne     :-
:       rts
.endproc

;;; Table for 24 entries; index (0...23) if in use, $FF if empty
entries_flag_table:
        .res    ::kSelectorListNumEntries, 0

;;; ============================================================

.proc draw_items_rect
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, entry_picker_all_items_rect
        rts
.endproc

;;; ============================================================

        rts                     ; ???

        rts                     ; ???

;;; ============================================================

;;; Input: A = index, Y = copy_when (1=boot, 2=use, 3=never)

.proc L9A0A
        cmp     #8
        bcc     L9A11
        jmp     assign_entry_data

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
.endproc

;;; ============================================================
;;; Assigns name, flags, and path to an entry.
;;; Inputs: A=entry index, Y=new flags
;;;         `path_buf1` is name, `path_buf0` is path

.proc assign_entry_data
        ptr := $06

        sta     index
        tya                     ; Y = entry flags
        pha

        ;; Compute entry address
        lda     index
        jsr     get_file_entry_addr
        stax    ptr

        ;; Assign name
        ldy     path_buf1
:       lda     path_buf1,y
        sta     (ptr),y
        dey
        bpl     :-

        ;; Assign flags
        ldy     #kSelectorEntryFlagsOffset
        pla
        sta     (ptr),y

        ;; Assign path
        lda     index
        jsr     get_file_path_addr
        stax    ptr
        ldy     path_buf0
:       lda     path_buf0,y
        sta     (ptr),y
        dey
        bpl     :-
        rts

index:  .byte   0
.endproc

;;; ============================================================
;;; Removes the specified entry, shifting later entries down as
;;; needed. Writes the file when done. Handles both the file
;;; buffer and resource data (used for menus, etc.
;;; Inputs: Entry in A

.proc remove_entry
        ptr1 := $06
        ptr2 := $08


        sta     index
        cmp     #8
        bcc     run_list
        jmp     other_run_list

        ;; Primary run list
run_list:
.scope
        tax
        inx
        cpx     num_run_list_entries
        bne     loop

finish:
        dec     selector_list + kSelectorListNumRunListOffset
        dec     num_run_list_entries
        copy16  selector_menu_addr, @addr
        @addr := *+1
        dec     SELF_MODIFIED
        jmp     write_file

loop:   lda     index
        cmp     num_run_list_entries
        beq     finish

        ;; Copy entry (in file buffer) down by one
        jsr     get_file_entry_addr
        stax    ptr1
        lda     ptr1             ; BUG: Missing clc???
        adc     #<kSelectorListNameLength
        sta     ptr2
        lda     ptr1+1
        adc     #>kSelectorListNameLength
        sta     ptr2+1

        ldy     #0
        lda     (ptr2),y
        tay
:       lda     (ptr2),y
        sta     (ptr1),y
        dey
        bpl     :-

        ;; And flags
        ldy     #kSelectorEntryFlagsOffset
        lda     (ptr2),y
        sta     (ptr1),y

        ;; Copy entry (in resource data) down by one
        lda     index
        jsr     get_resource_entry_addr
        stax    ptr1
        lda     ptr1             ; BUG: Missing clc???
        adc     #<kSelectorListNameLength
        sta     ptr2
        lda     ptr1+1
        adc     #>kSelectorListNameLength
        sta     ptr2+1

        ldy     #0
        lda     (ptr2),y
        tay
:       lda     (ptr2),y
        sta     (ptr1),y
        dey
        bpl     :-

        ;; And flags
        ldy     #kSelectorEntryFlagsOffset
        lda     (ptr2),y
        sta     (ptr1),y

        ;; Copy path (in file buffer) down by one
        lda     index
        jsr     get_file_path_addr
        stax    ptr1
        lda     ptr1             ; BUG: Missing clc???
        adc     #<kSelectorListPathLength
        sta     ptr2
        lda     ptr1+1
        adc     #>kSelectorListPathLength
        sta     ptr2+1

        ldy     #0
        lda     (ptr2),y
        tay
:       lda     (ptr2),y
        sta     (ptr1),y
        dey
        bpl     :-

        ;; Copy path (in resource data) down by one
        lda     index
        jsr     get_resource_path_addr
        stax    ptr1
        lda     ptr1             ; BUG: Missing clc???
        adc     #<kSelectorListPathLength
        sta     ptr2
        lda     ptr1+1
        adc     #>kSelectorListPathLength
        sta     ptr2+1

        ldy     #0
        lda     (ptr2),y
        tay
:       lda     (ptr2),y
        sta     (ptr1),y
        dey
        bpl     :-

        ;; Next
        inc     index
        jmp     loop
.endscope

        ;; --------------------------------------------------

other_run_list:
.scope
        sec
        sbc     #ptr1+1
        cmp     num_other_run_list_entries
        bne     loop
        dec     selector_list + kSelectorListNumOtherListOffset
        dec     num_other_run_list_entries
        jmp     write_file

loop:   lda     index
        sec
        sbc     #ptr2
        cmp     num_other_run_list_entries
        bne     L9B84
        dec     selector_list + kSelectorListNumOtherListOffset
        dec     num_other_run_list_entries
        jmp     write_file

L9B84:  lda     index

        ;; Copy entry (in file buffer) down by one
        jsr     get_file_entry_addr
        stax    ptr1
        lda     ptr1             ; BUG: Missing clc???
        adc     #<kSelectorListNameLength
        sta     ptr2
        lda     ptr1+1
        adc     #>kSelectorListNameLength
        sta     ptr2+1

        ldy     #0
        lda     (ptr2),y
        tay
:       lda     (ptr2),y
        sta     (ptr1),y
        dey
        bpl     :-

        ;; Copy path (in file buffer) down by one
        lda     index
        jsr     get_file_path_addr
        stax    ptr1
        lda     ptr1             ; BUG: Missing clc???
        adc     #<kSelectorListPathLength
        sta     ptr2
        lda     ptr1+1
        adc     #>kSelectorListPathLength
        sta     ptr2+1

        ldy     #0
        lda     (ptr2),y
        tay
:       lda     (ptr2),y
        sta     (ptr1),y
        dey
        bpl     :-

        ;; And flags
        ldy     #kSelectorEntryFlagsOffset
        lda     (ptr2),y
        sta     (ptr1),y

        ;; Next
        inc     index
        jmp     loop
.endscope

index:  .byte   0
.endproc

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

.proc show_warning_dialog
        sta     warning_dialog_num
        param_call main::invoke_dialog_proc, $0C, warning_dialog_num
        rts
.endproc

;;; ============================================================
;;; Write out SELECTOR.LIST file, using original prefix.
;;; Used if DeskTop was copied to RAMCard.

filename_buffer := $1C00

        DEFINE_OPEN_PARAMS open_params, filename_buffer, io_buf
        DEFINE_WRITE_PARAMS write_params, selector_list, kSelectorListBufSize
        DEFINE_CLOSE_PARAMS flush_close_params

.proc write_file_to_original_prefix
        param_call copy_desktop_orig_prefix, filename_buffer
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

retry_open:
        MLI_RELAY_CALL OPEN, open_params
        beq     write
        lda     #0
        jsr     show_warning_dialog
        beq     retry_open

L9C5F:  rts

write:  lda     open_params::ref_num
        sta     write_params::ref_num
        sta     flush_close_params::ref_num

retry_write:
        MLI_RELAY_CALL WRITE, write_params
        beq     close
        pha
        jsr     JUMP_TABLE_CLEAR_UPDATES
        pla
        jsr     JUMP_TABLE_SHOW_ALERT
        beq     retry_write
        jmp     L9C5F

close:  MLI_RELAY_CALL FLUSH, flush_close_params ; TODO: is FLUSH necessary?
        MLI_RELAY_CALL CLOSE, flush_close_params
        rts
.endproc

;;; ============================================================
;;; Read SELECTOR.LIST file (using current prefix)

        DEFINE_OPEN_PARAMS open_params2, filename, io_buf

filename:
        PASCAL_STRING kFilenameSelectorList

        DEFINE_READ_PARAMS read_params2, selector_list, kSelectorListBufSize
        DEFINE_WRITE_PARAMS write_params2, selector_list, kSelectorListBufSize
        DEFINE_CLOSE_PARAMS close_params2

.proc read_file
retry:  MLI_RELAY_CALL OPEN, open_params2
        beq     read
        lda     #$00
        jsr     show_warning_dialog
        beq     retry
        return  #$FF

read:   lda     open_params2::ref_num
        sta     read_params2::ref_num
        MLI_RELAY_CALL READ, read_params2
        bne     :+              ; TODO: Close even if read fails?
        MLI_RELAY_CALL CLOSE, close_params2
:       rts
.endproc

;;; ============================================================
;;; Write SELECTOR.LIST file (using current prefix)

.proc write_file
        MLI_RELAY_CALL OPEN, open_params2
        beq     write
        lda     #0
        jsr     show_warning_dialog
        beq     read_file       ; BUG: Should be `write_file`
        return  #$FF

write:  lda     open_params2::ref_num
        sta     write_params2::ref_num
:       MLI_RELAY_CALL WRITE, write_params2
        beq     close
        jsr     JUMP_TABLE_SHOW_ALERT
        beq     :-
        jmp     done            ; TODO: Close even if no retry?

close:  MLI_RELAY_CALL CLOSE, close_params2
done:   rts
.endproc

;;; ============================================================

.proc read_file_and_draw_entries
        jsr     read_file
        bpl     draw_all_entries
        rts
.endproc

;;; ============================================================

.proc draw_all_entries
        lda     selector_list + kSelectorListNumRunListOffset
        sta     num_run_list_entries
        beq     other_run_list

        ;; Draw "run list" entries
        lda     #0
        sta     index
loop1:  lda     index
        cmp     num_run_list_entries
        beq     other_run_list
        jsr     times16
        clc
        adc     #kSelectorListEntriesOffset
        pha
        txa
        adc     #>selector_list
        tax
        pla
        ldy     index
        jsr     draw_entry
        inc     index
        jmp     loop1

        ;; Draw "other run list" entries
other_run_list:
        lda     selector_list + kSelectorListNumOtherListOffset
        sta     num_other_run_list_entries
        beq     done
        lda     #0
        sta     index
loop2:  lda     index
        cmp     num_other_run_list_entries
        beq     done
        clc
        adc     #8
        jsr     times16
        clc
        adc     #kSelectorListEntriesOffset
        pha
        txa
        adc     #>selector_list
        tax
        lda     index
        clc
        adc     #8
        tay
        pla
        jsr     draw_entry
        inc     index
        jmp     loop2

done:   return  #0

index:  .byte   0
.endproc

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
        sta     SELF_MODIFIED,x
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
        sta     SELF_MODIFIED,x
        dex
        bpl     :-

        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts
.endproc

;;; ============================================================
;;; Populate `get_file_info_params` with the info for the entry
;;; as copied to RAMCard.
;;; Input: A=entry number
;;; Output: `get_file_info_params` populated.

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, 0

.proc get_entry_ramcard_file_info
        jsr     get_entry_ramcard_path
        stax    get_file_info_params::pathname
        MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params
        rts
.endproc

;;; ============================================================
;;; Get the path for an entry as it would be on a RAMCard.
;;; e.g. if the path was "/APPS/MOUSEPAINT/MP.SYSTEM" this would
;;; return the address of a buffer with "/RAM/MOUSEPAINT/MP.SYSTEM"
;;; Input: A=entry number
;;; Output: A,X=path buffer

.proc get_entry_ramcard_path
        ptr := $06

        sta     index
        param_call copy_ramcard_prefix, buf
        lda     index
        jsr     get_file_path_addr
        stax    ptr

        ;; Find last / in entry's path
        ldy     #0
        lda     (ptr),y
        sta     len
        tay
:       lda     (ptr),y
        and     #CHAR_MASK      ; TODO: Is this needed?
        cmp     #'/'
        beq     :+
        dey
        bne     :-

        ;; And find preceeding /
:       dey
:       lda     (ptr),y
        and     #CHAR_MASK
        cmp     #'/'
        beq     :+
        dey
        bne     :-

        ;; Append everything after this to the buffer
:       dey
        ldx     buf
:       inx
        iny
        lda     (ptr),y
        sta     buf,x
        cpy     len
        bne     :-
        stx     buf

        ;; Return the buffer's address
        ldax    #buf
        rts

index:  .byte   0
len:    .byte   0
buf:    .res    ::kPathBufferSize
.endproc

;;; ============================================================

        PAD_TO $A000

.endproc ; selector_overlay2

selector_picker_exec    := selector_overlay2::exec
