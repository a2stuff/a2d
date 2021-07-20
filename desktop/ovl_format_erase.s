;;; ============================================================
;;; Overlay for Format/Erase
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.proc format_erase_overlay
        .org $800

        block_buffer := $1A00

        ovl_string_buf := path_buf0

exec:

L0800:  pha
        jsr     main::set_cursor_pointer
        pla
        cmp     #$04
        beq     L080C
        jmp     L09D9

;;; ============================================================
;;; Format Disk

L080C:  copy    #$00, has_input_field_flag
        jsr     main::open_prompt_window
        lda     winfo_prompt_dialog::window_id
        jsr     main::set_port_from_window_id
        param_call main::draw_dialog_title, aux::label_format_disk
        param_call main::draw_dialog_label, 1, aux::str_select_format
        jsr     draw_volume_labels
        copy    #$FF, selected_device_index
L0832:  copy16  #L0B48, main::jump_relay+1
        copy    #$80, format_erase_overlay_flag
L0841:  jsr     main::prompt_input_loop
        bmi     L0841
        pha
        copy16  #main::noop, main::jump_relay+1
        lda     #$00
        sta     LD8F3
        sta     format_erase_overlay_flag
        pla
        beq     L085F
        jmp     L09C2

L085F:  bit     selected_device_index
        bmi     L0832
        lda     winfo_prompt_dialog::window_id
        jsr     main::set_port_from_window_id
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, name_input_rect
        jsr     main::clear_path_buf1
        copy    #$80, has_input_field_flag
        copy    #$00, format_erase_overlay_flag
        jsr     main::clear_path_buf2
        param_call main::draw_dialog_label, 3, aux::str_new_volume
L08A7:  jsr     main::prompt_input_loop
        bmi     L08A7
        beq     L08B7
        jmp     L09C2

L08B1:  jsr     Bell
        jmp     L08A7

L08B7:  lda     path_buf1
        beq     L08B1
        cmp     #$10
        bcs     L08B1
        jsr     main::set_cursor_pointer
        lda     winfo_prompt_dialog::window_id
        jsr     main::set_port_from_window_id
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect

        ;; Reverse order, so boot volume is first
        lda     DEVCNT
        sec
        sbc     selected_device_index
        tax
        lda     DEVLST,x

        sta     L09D8
        sta     L09D7
        lda     #$00
        sta     has_input_field_flag
        param_call main::draw_dialog_label, 3, aux::str_confirm_format
        lda     L09D7
        jsr     L1A2D
        param_call main::DrawString, ovl_string_buf
L0902:  jsr     main::prompt_input_loop
        bmi     L0902
        beq     L090C
        jmp     L09C2

L090C:  lda     winfo_prompt_dialog::window_id
        jsr     main::set_port_from_window_id
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        param_call main::draw_dialog_label, 1, aux::str_formatting
        lda     L09D7
        jsr     L12C1
        and     #$FF
        bne     L0942
        jsr     main::set_cursor_watch
        lda     L09D7
        jsr     L126F
        bcs     L099B
L0942:  lda     winfo_prompt_dialog::window_id
        jsr     main::set_port_from_window_id
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        param_call main::draw_dialog_label, 1, aux::str_erasing
        param_call upcase_string, path_buf1
        ldxy    #path_buf1
        lda     L09D7
        jsr     L1307
        pha
        jsr     main::set_cursor_pointer
        pla
        bne     L0980
        lda     #$00
        jmp     L09C2

L0980:  cmp     #ERR_WRITE_PROTECTED
        bne     L098C
        jsr     JUMP_TABLE_SHOW_ALERT
        bne     L09C2
        jmp     L090C

L098C:  jsr     Bell
        param_call main::draw_dialog_label, 6, aux::str_erasing_error
        jmp     L09B8

L099B:  pha
        jsr     main::set_cursor_pointer
        pla
        cmp     #ERR_WRITE_PROTECTED
        bne     L09AC
        jsr     JUMP_TABLE_SHOW_ALERT
        bne     L09C2
        jmp     L090C

L09AC:  jsr     Bell
        param_call main::draw_dialog_label, 6, aux::str_formatting_error
L09B8:  jsr     main::prompt_input_loop
        bmi     L09B8
        bne     L09C2
        jmp     L090C

L09C2:  pha
        jsr     main::set_cursor_pointer
        jsr     main::reset_main_grafport
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_prompt_dialog
        ldx     L09D8
        pla
        rts

L09D7:  .byte   0
L09D8:  .byte   0

;;; ============================================================
;;; Erase Disk

L09D9:  lda     #$00
        sta     has_input_field_flag
        jsr     main::open_prompt_window
        lda     winfo_prompt_dialog::window_id
        jsr     main::set_port_from_window_id
        param_call main::draw_dialog_title, aux::label_erase_disk
        param_call main::draw_dialog_label, 1, aux::str_select_erase
        jsr     draw_volume_labels
        copy    #$FF, selected_device_index
        copy16  #L0B48, main::jump_relay+1
        copy    #$80, format_erase_overlay_flag
L0A0E:  jsr     main::prompt_input_loop
        bmi     L0A0E
        beq     L0A18
        jmp     L0B31

L0A18:  bit     selected_device_index
        bmi     L0A0E
        copy16  #main::rts1, main::jump_relay+1
        lda     winfo_prompt_dialog::window_id
        jsr     main::set_port_from_window_id
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, name_input_rect
        jsr     main::clear_path_buf1
        copy    #$80, has_input_field_flag
        copy    #$00, format_erase_overlay_flag
        jsr     main::clear_path_buf2
        param_call main::draw_dialog_label, 3, aux::str_new_volume
L0A6A:  jsr     main::prompt_input_loop
        bmi     L0A6A
        beq     L0A7A
        jmp     L0B31

L0A74:  jsr     Bell
        jmp     L0A6A

L0A7A:  lda     path_buf1
        beq     L0A74
        cmp     #$10
        bcs     L0A74
        jsr     main::set_cursor_pointer
        lda     winfo_prompt_dialog::window_id
        jsr     main::set_port_from_window_id
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        copy    #$00, has_input_field_flag

        ;; Reverse order, so boot volume is first
        lda     DEVCNT
        sec
        sbc     selected_device_index
        tax
        lda     DEVLST,x

        sta     L0B47
        sta     L0B46
        param_call main::draw_dialog_label, 3, aux::str_confirm_erase
        lda     L0B46
        and     #$F0
        jsr     L1A2D
        param_call main::DrawString, ovl_string_buf
L0AC7:  jsr     main::prompt_input_loop
        bmi     L0AC7
        beq     L0AD1
        jmp     L0B31

L0AD1:  lda     winfo_prompt_dialog::window_id
        jsr     main::set_port_from_window_id
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        param_call main::draw_dialog_label, 1, aux::str_erasing
        param_call upcase_string, path_buf1
        jsr     main::set_cursor_watch
        ldxy    #path_buf1
        lda     L0B46
        jsr     L1307
        pha
        jsr     main::set_cursor_pointer
        pla
        bne     L0B12
        lda     #$00
        jmp     L0B31

L0B12:  cmp     #ERR_WRITE_PROTECTED
        bne     L0B1E
        jsr     JUMP_TABLE_SHOW_ALERT
        bne     L0B31
        jmp     L0AD1

L0B1E:  jsr     Bell
        param_call main::draw_dialog_label, 6, aux::str_erasing_error
L0B2A:  jsr     main::prompt_input_loop
        bmi     L0B2A
        beq     L0AD1
L0B31:  pha
        jsr     main::set_cursor_pointer
        jsr     main::reset_main_grafport
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_prompt_dialog
        ldx     L0B47
        pla
        rts

L0B46:  .byte   0
L0B47:  .byte   0

;;; ============================================================

        kLabelsVOffset = 49

L0B48:  cmp16   screentowindow_windowx, #40
        bpl     :+
        return  #$FF
:       cmp16   screentowindow_windowx, #360
        bcc     :+
        return  #$FF
:       lda     screentowindow_windowy
        sec
        sbc     #kLabelsVOffset
        sta     screentowindow_windowy
        lda     screentowindow_windowy+1
        sbc     #0
        bpl     :+
        return  #$FF
:       sta     screentowindow_windowy+1

        ;; Divide by aux::kDialogLabelHeight
        ldax    screentowindow_windowy
        ldy     #aux::kDialogLabelHeight
        jsr     Divide_16_8_16
        stax    screentowindow_windowy

        cmp     #4
        bcc     L0B98
        return  #$FF

L0B98:  copy    #$02, L0C1F
        cmp16   screentowindow_windowx, #280
        bcs     L0BBB
        dec     L0C1F
        cmp16   screentowindow_windowx, #160
        bcs     L0BBB
        dec     L0C1F
L0BBB:  lda     L0C1F
        asl     a
        asl     a
        clc
        adc     screentowindow_windowy
        cmp     num_volumes
        bcc     L0BDC
        lda     selected_device_index
        bmi     L0BD9
        lda     selected_device_index
        jsr     highlight_volume_label
        lda     #$FF
        sta     selected_device_index
L0BD9:  return  #$FF

L0BDC:  cmp     selected_device_index
        bne     L0C04
        jsr     main::detect_double_click
        bmi     L0C03
L0BE6:  MGTK_RELAY_CALL MGTK::SetPenMode, penXOR ; flash the button
        MGTK_RELAY_CALL MGTK::PaintRect, aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::ok_button_rect
        lda     #$00
L0C03:  rts

L0C04:  sta     L0C1E
        lda     selected_device_index
        bmi     L0C0F
        jsr     highlight_volume_label
L0C0F:  lda     L0C1E
        sta     selected_device_index
        jsr     highlight_volume_label
        jsr     main::detect_double_click
        beq     L0BE6
        rts

L0C1E:  .byte   0
L0C1F:  .byte   0

;;; ============================================================
;;; Hilight volume label
;;; Input: A = volume index

        kLabelWidth = 110

.proc highlight_volume_label
        ldy     #39
        sty     select_volume_rect::x1
        ldy     #0
        sty     select_volume_rect::x1+1
        tax
        lsr     a               ; / 4
        lsr     a
        sta     L0CA9           ; column (0, 1, or 2)
        beq     :+
        add16   select_volume_rect::x1, #kLabelWidth, select_volume_rect::x1
        lda     L0CA9
        cmp     #1
        beq     :+
        add16   select_volume_rect::x1, #kLabelWidth, select_volume_rect::x1
:       asl     L0CA9           ; * 4
        asl     L0CA9
        txa
        sec
        sbc     L0CA9           ; entry % 4
        ldx     #0

        ldy     #aux::kDialogLabelHeight
        jsr     Multiply_16_8_16
        stax    select_volume_rect::y1
        add16_8 select_volume_rect::y1, #kLabelsVOffset, select_volume_rect::y1

        add16   select_volume_rect::x1, #kLabelWidth-1, select_volume_rect::x2
        add16   select_volume_rect::y1, #aux::kDialogLabelHeight-1, select_volume_rect::y2
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::PaintRect, select_volume_rect
        rts

L0CA9:  .byte   0
.endproc

;;; ============================================================

.proc maybe_highlight_selected_index
        lda     selected_device_index
        bmi     :+
        jsr     highlight_volume_label
        copy    #$FF, selected_device_index
:       rts
.endproc

;;; ============================================================

        ;; Called from main
.proc prompt_handle_key_right
        lda     selected_device_index
        bpl     :+              ; has selection

        lda     #0              ; no selection - select first
        beq     set             ; always

        ;; Change selection
:       clc                     ; to the right is +4
        adc     #4
        cmp     num_volumes     ; unless we went too far?
        bcc     :+
        clc                     ; if we went too far, wrap to next row (+1)
        adc     #1
        and     #3              ; and clamp to first column
        cmp     num_volumes
        bcc     :+
        lda     #0              ; wrap to 0 if needed

:       pha
        jsr     maybe_highlight_selected_index
        pla
set:    sta     selected_device_index
        jsr     highlight_volume_label
done:   return  #$FF
.endproc

;;; ============================================================

        ;; Called from main
.proc prompt_handle_key_left
        lda     selected_device_index
        bpl     loop            ; has selection

        ;; No selection - pick bottom-right one...
        lda     num_volumes
        cmp     #11             ; last in 3rd column?
        bcc     :+
        lda     #11
        bne     set             ; always
:       cmp     #7              ; last in 2nd column?
        bcc     :+
        lda     #7
        bne     set             ; always
:       tax
        dex
        txa
        bpl     set             ; always

        ;; Change selection
loop:   sec
        sbc     #4
        bpl     :+
        clc
        adc     #15             ; (4 * num columns) - 1

:       cmp     num_volumes
        bcs     loop

        pha
        jsr     maybe_highlight_selected_index
        pla

set:    sta     selected_device_index
        jsr     highlight_volume_label
done:   return  #$FF
.endproc

;;; ============================================================

        ;; Called from main
.proc prompt_handle_key_down
        lda     selected_device_index ; $FF if none, would inc to #0
        clc
        adc     #1
        cmp     num_volumes
        bcc     :+
        lda     #0              ; wrap to first
:       pha
        jsr     maybe_highlight_selected_index
        pla
        sta     selected_device_index
        jsr     highlight_volume_label
        return  #$FF
.endproc

;;; ============================================================

        ;; Called from main
.proc prompt_handle_key_up
        lda     selected_device_index
        bmi     wrap            ; if no selection, wrap
        sec
        sbc     #1              ; to to previous
        bpl     :+              ; unless wrapping needed

wrap:   ldx     num_volumes     ; go to last (num - 1)
        dex
        txa

:       pha
        jsr     maybe_highlight_selected_index
        pla
        sta     selected_device_index
        jsr     highlight_volume_label
        return  #$FF
.endproc

;;; ============================================================
;;; Draw volume labels

.proc draw_volume_labels
        ldx     DEVCNT
        inx
        stx     num_volumes

        lda     #0
        sta     vol
loop:   lda     vol
        cmp     num_volumes
        bne     :+
        copy16  #kDialogLabelDefaultX, dialog_label_pos::xcoord
        rts

:       cmp     #8              ; third column?
        bcc     :+
        ldax    #kDialogLabelDefaultX + kLabelWidth*2
        jmp     setpos

:       cmp     #4              ; second column?
        bcc     skip
        ldax    #kDialogLabelDefaultX + kLabelWidth
        ;; fall through

setpos: stax    dialog_label_pos::xcoord
skip:

        ;; Reverse order, so boot volume is first
        lda     DEVCNT
        sec
        sbc     vol
        asl     a
        tay

        lda     device_name_table+1,y
        tax
        lda     device_name_table,y ; now A,X has pointer
        pha                         ; save A

        ;; Compute label line into Y
        lda     vol
        lsr     a
        lsr     a
        asl     a
        asl     a
        sta     tmp
        lda     vol
        sec
        sbc     tmp
        tay
        iny
        iny
        iny

        pla                     ; A,X has pointer again
        jsr     main::draw_dialog_label
        inc     vol
        jmp     loop

vol:    .byte   0               ; volume being drawn
tmp:    .byte   0
.endproc

        PAD_TO $E00

;;; ============================================================

        .include "../lib/formatdiskii.s"

;;; ============================================================

        read_buffer := $1C00

        DEFINE_ON_LINE_PARAMS on_line_params,, $1C00
        DEFINE_READ_BLOCK_PARAMS read_block_params, read_buffer, 0
        DEFINE_WRITE_BLOCK_PARAMS write_block_params, prodos_loader_blocks, 0

L124A:  .byte   $00

;;; ============================================================

.proc MLI_RELAY
        sty     call
        stax    params
        sta     ALTZPOFF
        lda     ROMIN2
        jsr     MLI
call:   .byte   0
params: .addr   0
        tax
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        txa
        rts
.endproc

;;; ============================================================

L126F:  sta     L12C0
        and     #$0F
        beq     L12A6
        ldx     #$11
        lda     L12C0
        and     #$80
        beq     L1281
        ldx     #$21
L1281:  stx     @lsb
        lda     L12C0
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     @lsb
        sta     @lsb
        @lsb := *+1
        lda     MLI
        sta     $07
        lda     #$00
        sta     $06
        ldy     #$FF
        lda     ($06),y
        beq     L12A6
        cmp     #$FF
        bne     L12AD
L12A6:  lda     L12C0
        jsr     FormatDiskII
        rts

L12AD:  ldy     #$FF            ; offset to low byte of driver address
        lda     ($06),y
        sta     $06
        lda     #DRIVER_COMMAND_FORMAT
        sta     DRIVER_COMMAND
        lda     L12C0
        and     #$F0
        sta     DRIVER_UNIT_NUMBER
        jmp     ($06)

        rts

L12C0:  .byte   0
L12C1:  sta     L1306
        and     #$0F
        beq     L1303
        ldx     #$11
        lda     L1306
        and     #$80
        beq     L12D3
        ldx     #$21
L12D3:  stx     @lsb
        lda     L1306
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     @lsb
        sta     @lsb
        @lsb := *+1
        lda     MLI
        sta     $07
        lda     #$00
        sta     $06
        ldy     #$FF
        lda     ($06),y
        beq     L1303
        cmp     #$FF
        beq     L1303
        ldy     #$FE
        lda     ($06),y
        and     #$08
        bne     L1303
        return  #$FF

L1303:  return  #$00

;;; ============================================================

L1306:  .byte   0
L1307:  sta     L124A
        and     #$F0
        sta     write_block_params::unit_num
        stx     $06
        sty     $06+1
        ldy     #$01
        lda     ($06),y
        and     #CHAR_MASK
        cmp     #'/'
        bne     L132C
        dey
        lda     ($06),y
        sec
        sbc     #1
        iny
        sta     ($06),y
        inc16   $06
L132C:  ldy     #0
        lda     ($06),y
        tay
:       lda     ($06),y
        and     #CHAR_MASK
        sta     L14E5,y
        dey
        bpl     :-

        lda     L124A
        and     #$0F
        beq     L1394
        ldx     #$11
        lda     L124A
        and     #$80
        beq     L134D
        ldx     #$21
L134D:  stx     @lsb
        lda     L124A
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     @lsb
        sta     @lsb
        @lsb := *+1
        lda     MLI
        sta     $06+1
        lda     #$00
        sta     $06
        ldy     #$FF
        lda     ($06),y
        beq     L1394
        cmp     #$FF
        beq     L1394

        ldy     #$FF            ; offset to low byte of driver address
        lda     ($06),y
        sta     $06
        lda     #DRIVER_COMMAND_STATUS
        sta     DRIVER_COMMAND
        lda     L124A
        and     #$F0
        sta     DRIVER_UNIT_NUMBER
        lda     #$00
        sta     DRIVER_BLOCK_NUMBER
        sta     DRIVER_BLOCK_NUMBER+1
        jsr     L1391
        bcc     L1398
        jmp     L1483

L1391:  jmp     ($06)

L1394:  ldx     #$18
        ldy     #$01
L1398:  stx     L14E3
        sty     L14E4

        ;; Write first block of loader
        copy16  #prodos_loader_blocks, write_block_params::data_buffer
        lda     #0
        sta     write_block_params::block_num
        sta     write_block_params::block_num+1
        MLI_RELAY_CALL WRITE_BLOCK, write_block_params
        beq     :+
        jmp     fail2

        ;; Write second block of loader
:       inc     write_block_params::block_num     ; next block needs...
        inc     write_block_params::data_buffer+1 ; next $200 of data
        inc     write_block_params::data_buffer+1
        jsr     write_block_and_zero

        ;; Subsequent blocks...
        copy16  #block_buffer, write_block_params::data_buffer
        lda     #$03
        sta     block_buffer+$02
        ldy     L14E5
        tya
        ora     #$F0
        sta     block_buffer+$04
L13E2:  lda     L14E5,y
        sta     block_buffer+$04,y
        dey
        bne     L13E2
        ldy     #8
L13ED:  lda     L14DC,y
        sta     block_buffer+$22,y
        dey
        bpl     L13ED
        jsr     write_block_and_zero

        copy    #$02, block_buffer
        copy    #$04, block_buffer+$02
        jsr     write_block_and_zero

        copy    #$03, block_buffer
        copy    #$05, block_buffer+$02
        jsr     write_block_and_zero

        copy    #$04, block_buffer
        jsr     write_block_and_zero

        lsr16   L14E3           ; / 8
        lsr16   L14E3
        lsr16   L14E3
        lda     L14E3
        bne     :+
        dec     L14E4
:       dec     L14E3
L1438:  jsr     L1485
        lda     write_block_params::block_num+1
        bne     L146A
        lda     write_block_params::block_num
        cmp     #$06
        bne     L146A
        copy    #$01, block_buffer
        lda     L14E4
        cmp     #$02
        bcc     L146A
        copy    #$00, block_buffer
        lda     L14E4
        lsr     a
        tax
        lda     #$FF
        dex
        beq     L1467
L1462:  clc
        rol     a
        dex
        bne     L1462
L1467:  sta     block_buffer+$01
L146A:  jsr     write_block_and_zero
        dec     L14E4
        dec     L14E4
        lda     L14E4
        beq     L147D
        bmi     L147D
        jmp     L1438

L147D:  lda     #$00
        sta     $08
        clc
        rts

L1483:  sec
        rts

L1485:  ldy     L14E4
        beq     L148E
        ldy     #$FF
        bne     L1491
L148E:  ldy     L14E3
L1491:  lda     #$FF
L1493:  sta     block_buffer,y
        dey
        bne     L1493
        sta     block_buffer
        ldy     L14E4
        beq     L14B5
        cpy     #$02
        bcc     L14A9
        ldy     #$FF
        bne     L14AC
L14A9:  ldy     L14E3
L14AC:  sta     block_buffer+$100,y
        dey
        bne     L14AC
        sta     block_buffer+$100
L14B5:  rts

;;; ============================================================

fail:   pla
        pla
fail2:  sec
        rts

;;; ============================================================

.proc write_block_and_zero
        MLI_RELAY_CALL WRITE_BLOCK, write_block_params
        bne     fail
        jsr     zero_buffers
        inc     write_block_params::block_num
        rts

zero_buffers:
        ldy     #0
        tya
:       sta     block_buffer,y
        dey
        bne     :-
:       sta     block_buffer+$100,y
        dey
        bne     :-
        rts
.endproc

;;; ============================================================

L14DC:  .byte   $C3,$27,$0D,$00,$00,$06,$00
L14E3:  .byte   $18
L14E4:  .byte   $01
L14E5:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00

;;; ============================================================
;;; ProDOS Loader
;;; ============================================================

.proc prodos_loader_blocks
        .incbin "../inc/pdload.dat"
.endproc
        .assert .sizeof(prodos_loader_blocks) = $400, error, "Bad data"

;;; ============================================================

.proc upcase_string
        ptr := $06
        stx     ptr+1
        sta     ptr
        ldy     #0
        lda     (ptr),y
        tay
loop:   lda     (ptr),y
        cmp     #'a'
        bcc     :+
        cmp     #'z'+1
        bcs     :+
        and     #CASE_MASK
        sta     (ptr),y
:       dey
        bpl     loop
        rts
.endproc

L192E:  sta     read_block_params::unit_num
        lda     #0
        sta     read_block_params::block_num
        sta     read_block_params::block_num+1
        MLI_RELAY_CALL READ_BLOCK, read_block_params
        bne     L1959
        lda     read_buffer + 1
        cmp     #$E0
        beq     L194E
        jmp     L1986

L194E:  lda     read_buffer + 2
        cmp     #$70
        beq     L197E
        cmp     #$60
        beq     L197E
L1959:  lda     read_block_params::unit_num
        jsr     L19B7
        sta     the_disk_in_slot_label + kTheDiskInSlotSlotCharOffset
        lda     read_block_params::unit_num
        jsr     L19C1
        sta     the_disk_in_slot_label + kTheDiskInSlotDriveCharOffset
        ldx     the_disk_in_slot_label
L1974:  lda     the_disk_in_slot_label,x
        sta     ovl_string_buf,x
        dex
        bpl     L1974
        rts

L197E:  param_call L19C8, ovl_string_buf
        rts

L1986:  cmp     #$A5
        bne     L1959
        lda     read_buffer + 2
        cmp     #$27
        bne     L1959
        lda     read_block_params::unit_num
        jsr     L19B7
        sta     the_dos_33_disk_label + kTheDos33DiskSlotCharOffset
        lda     read_block_params::unit_num
        jsr     L19C1
        sta     the_dos_33_disk_label + kTheDos33DiskDriveCharOffset
        ldx     the_dos_33_disk_label
L19AC:  lda     the_dos_33_disk_label,x
        sta     ovl_string_buf,x
        dex
        bpl     L19AC
        rts

        .byte   0
L19B7:  and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #$30
        rts

L19C1:  and     #$80
        asl     a
        rol     a
        adc     #$31
        rts

L19C8:  copy16  #$0002, read_block_params::block_num
        MLI_RELAY_CALL READ_BLOCK, read_block_params
        beq     L19F7
        copy    #4, ovl_string_buf
        copy    #' ', ovl_string_buf+1
        copy    #':', ovl_string_buf+2
        copy    #' ', ovl_string_buf+3 ; Overwritten ???
        copy    #'?', ovl_string_buf+3
        rts

        ;; This straddles $1A00 which is the block buffer ($1A00-$1BFF) ???

L19F7:  lda     read_buffer + 6
        tax
L19FB:  lda     read_buffer + 6,x
        sta     ovl_string_buf,x
        dex
        bpl     L19FB
        inc     ovl_string_buf
        ldx     ovl_string_buf
        lda     #':'
        sta     ovl_string_buf,x
        inc     ovl_string_buf
        ldx     ovl_string_buf
        lda     #' '
        sta     ovl_string_buf,x
        inc     ovl_string_buf
        ldx     ovl_string_buf
        lda     #'?'
L1A22:  sta     ovl_string_buf,x
        rts

;;; ============================================================

.proc L1A2D
        sta     on_line_params::unit_num
        MLI_RELAY_CALL ON_LINE, on_line_params
        bne     L1A6D
        lda     read_buffer
        and     #NAME_LENGTH_MASK
        beq     L1A6D
        sta     read_buffer
        tax
:       lda     read_buffer,x
        sta     ovl_string_buf,x
        dex
        bpl     :-

        inc     ovl_string_buf
        ldx     ovl_string_buf
        lda     #' '
        sta     ovl_string_buf,x
        inc     ovl_string_buf
        ldx     ovl_string_buf
        lda     #$3F
        sta     ovl_string_buf,x
        rts

L1A6D:  lda     on_line_params::unit_num
        jsr     L192E
        rts
.endproc

;;; ============================================================

        PAD_TO $1C00

.endproc ; format_erase_overlay

format_erase_overlay_prompt_handle_key_left     := format_erase_overlay::prompt_handle_key_left
format_erase_overlay_prompt_handle_key_right    := format_erase_overlay::prompt_handle_key_right
format_erase_overlay_prompt_handle_key_down     := format_erase_overlay::prompt_handle_key_down
format_erase_overlay_prompt_handle_key_up       := format_erase_overlay::prompt_handle_key_up

format_erase_overlay_exec := format_erase_overlay::exec