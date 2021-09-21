;;; ============================================================
;;; Overlay for Format/Erase
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.proc format_erase_overlay
        .org $800

        MLIRelayImpl := main::MLIRelayImpl

        block_buffer := $1A00

        ovl_string_buf := path_buf0

        kLabelsVOffset = 49

        kLabelWidth   = 127
        kLabelsCol1    = 11
        kLabelsCol2    = kLabelsCol1 + kLabelWidth
        kLabelsCol3    = kLabelsCol1 + kLabelWidth*2

        kDefaultFloppyBlocks = 280
exec:

L0800:  pha
        jsr     main::set_cursor_pointer
        pla
        cmp     #$04
        beq     format_disk
        jmp     erase_disk

;;; ============================================================
;;; Format Disk

.proc format_disk
        copy    #$00, has_input_field_flag
        jsr     main::open_prompt_window
        lda     winfo_prompt_dialog::window_id
        jsr     main::safe_set_port_from_window_id
        param_call main::draw_dialog_title, aux::label_format_disk
        param_call main::draw_dialog_label, 1, aux::str_select_format
        jsr     draw_volume_labels
        copy    #$FF, selected_device_index
l1:     copy16  #handle_click, main::jump_relay+1
        copy    #$80, format_erase_overlay_flag
l2:     jsr     main::prompt_input_loop
        bmi     l2
        pha
        copy16  #main::noop, main::jump_relay+1
        lda     #$00
        sta     LD8F3
        sta     format_erase_overlay_flag
        pla
        beq     l3
        jmp     l15

l3:     bit     selected_device_index
        bmi     l1
        lda     winfo_prompt_dialog::window_id
        jsr     main::safe_set_port_from_window_id
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, name_input_rect
        jsr     main::clear_path_buf1
        copy    #$80, has_input_field_flag
        copy    #$00, format_erase_overlay_flag
        jsr     main::clear_path_buf2
        param_call main::draw_dialog_label, 3, aux::str_new_volume
l4:     jsr     main::prompt_input_loop
        bmi     l4
        beq     l6
        jmp     l15

l5:     jsr     Bell
        jmp     l4

l6:     lda     path_buf1
        beq     l5
        cmp     #$10
        bcs     l5
        jsr     main::set_cursor_pointer
        lda     winfo_prompt_dialog::window_id
        jsr     main::safe_set_port_from_window_id
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect

        ;; Reverse order, so boot volume is first
        lda     DEVCNT
        sec
        sbc     selected_device_index
        tax
        lda     DEVLST,x

        sta     d2
        sta     unit_num
        lda     #$00
        sta     has_input_field_flag
        param_call main::draw_dialog_label, 3, aux::str_confirm_format
        lda     unit_num
        jsr     append_vol_name_question
        param_call main::DrawString, ovl_string_buf
l7:     jsr     main::prompt_input_loop
        bmi     l7
        beq     l8
        jmp     l15

l8:     lda     winfo_prompt_dialog::window_id
        jsr     main::safe_set_port_from_window_id
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        param_call main::draw_dialog_label, 1, aux::str_formatting
        lda     unit_num
        jsr     check_supports_format
        and     #$FF
        bne     l9
        jsr     main::set_cursor_watch
        lda     unit_num
        jsr     format_unit
        bcs     l12
l9:     lda     winfo_prompt_dialog::window_id
        jsr     main::safe_set_port_from_window_id
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        param_call main::draw_dialog_label, 1, aux::str_erasing
        param_call upcase_string, path_buf1
        ldxy    #path_buf1
        lda     unit_num
        jsr     L1307
        pha
        jsr     main::set_cursor_pointer
        pla
        bne     l10
        lda     #$00
        jmp     l15

l10:    cmp     #ERR_WRITE_PROTECTED
        bne     l11
        jsr     JUMP_TABLE_SHOW_ALERT
        bne     l15             ; `kAlertResultCancel` = 1
        jmp     l8              ; `kAlertResultTryAgain` = 0

l11:    jsr     Bell
        param_call main::draw_dialog_label, 6, aux::str_erasing_error
        jmp     l14

l12:    pha
        jsr     main::set_cursor_pointer
        pla
        cmp     #ERR_WRITE_PROTECTED
        bne     l13
        jsr     JUMP_TABLE_SHOW_ALERT
        bne     l15             ; `kAlertResultCancel` = 1
        jmp     l8              ; `kAlertResultTryAgain` = 0

l13:    jsr     Bell
        param_call main::draw_dialog_label, 6, aux::str_formatting_error
l14:    jsr     main::prompt_input_loop
        bmi     l14
        bne     l15
        jmp     l8

l15:    pha
        jsr     main::set_cursor_pointer
        jsr     main::reset_main_grafport
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_prompt_dialog
        ldx     d2
        pla
        rts

unit_num:
        .byte   0
d2:     .byte   0
.endproc

;;; ============================================================
;;; Erase Disk

.proc erase_disk
        lda     #$00
        sta     has_input_field_flag
        jsr     main::open_prompt_window
        lda     winfo_prompt_dialog::window_id
        jsr     main::safe_set_port_from_window_id
        param_call main::draw_dialog_title, aux::label_erase_disk
        param_call main::draw_dialog_label, 1, aux::str_select_erase
        jsr     draw_volume_labels
        copy    #$FF, selected_device_index
        copy16  #handle_click, main::jump_relay+1
        copy    #$80, format_erase_overlay_flag
l1:     jsr     main::prompt_input_loop
        bmi     l1
        beq     l2
        jmp     l11

l2:     bit     selected_device_index
        bmi     l1
        copy16  #main::rts1, main::jump_relay+1
        lda     winfo_prompt_dialog::window_id
        jsr     main::safe_set_port_from_window_id
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        MGTK_RELAY_CALL MGTK::SetPenMode, penXOR
        MGTK_RELAY_CALL MGTK::FrameRect, name_input_rect
        jsr     main::clear_path_buf1
        copy    #$80, has_input_field_flag
        copy    #$00, format_erase_overlay_flag
        jsr     main::clear_path_buf2
        param_call main::draw_dialog_label, 3, aux::str_new_volume
l3:     jsr     main::prompt_input_loop
        bmi     l3
        beq     l5
        jmp     l11

l4:     jsr     Bell
        jmp     l3

l5:     lda     path_buf1
        beq     l4
        cmp     #$10
        bcs     l4
        jsr     main::set_cursor_pointer
        lda     winfo_prompt_dialog::window_id
        jsr     main::safe_set_port_from_window_id
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        copy    #$00, has_input_field_flag

        ;; Reverse order, so boot volume is first
        lda     DEVCNT
        sec
        sbc     selected_device_index
        tax
        lda     DEVLST,x

        sta     d2
        sta     unit_num
        param_call main::draw_dialog_label, 3, aux::str_confirm_erase
        lda     unit_num
        and     #$F0
        jsr     append_vol_name_question
        param_call main::DrawString, ovl_string_buf
l6:     jsr     main::prompt_input_loop
        bmi     l6
        beq     l7
        jmp     l11

l7:     lda     winfo_prompt_dialog::window_id
        jsr     main::safe_set_port_from_window_id
        MGTK_RELAY_CALL MGTK::SetPenMode, pencopy
        MGTK_RELAY_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        param_call main::draw_dialog_label, 1, aux::str_erasing
        param_call upcase_string, path_buf1
        jsr     main::set_cursor_watch
        ldxy    #path_buf1
        lda     unit_num
        jsr     L1307
        pha
        jsr     main::set_cursor_pointer
        pla
        bne     l8
        lda     #$00
        jmp     l11

l8:     cmp     #ERR_WRITE_PROTECTED
        bne     l9
        jsr     JUMP_TABLE_SHOW_ALERT
        bne     l11             ; `kAlertResultCancel` = 1
        jmp     l7              ; `kAlertResultTryAgain` = 0

l9:     jsr     Bell
        param_call main::draw_dialog_label, 6, aux::str_erasing_error
l10:    jsr     main::prompt_input_loop
        bmi     l10
        beq     l7
l11:    pha
        jsr     main::set_cursor_pointer
        jsr     main::reset_main_grafport
        MGTK_RELAY_CALL MGTK::CloseWindow, winfo_prompt_dialog
        ldx     d2
        pla
        rts

unit_num:
        .byte   0
d2:     .byte   0
.endproc

;;; ============================================================


.proc handle_click
        cmp16   screentowindow_windowx, #kLabelsCol1
        bpl     :+
        return  #$FF
:       cmp16   screentowindow_windowx, #kLabelsCol3 + kLabelWidth
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
        bcc     l1
        return  #$FF

l1:     copy    #2, col
        cmp16   screentowindow_windowx, #kLabelsCol3
        bcs     l2
        dec     col
        cmp16   screentowindow_windowx, #kLabelsCol2
        bcs     l2
        dec     col
l2:     lda     col
        asl     a
        asl     a
        clc
        adc     screentowindow_windowy
        cmp     num_volumes
        bcc     l4
        lda     selected_device_index
        bmi     l3
        lda     selected_device_index
        jsr     highlight_volume_label
        lda     #$FF
        sta     selected_device_index
l3:     return  #$FF

l4:     cmp     selected_device_index
        bne     l7
        jsr     main::detect_double_click
        bmi     l6
l5:     MGTK_RELAY_CALL MGTK::SetPenMode, penXOR ; flash the button
        MGTK_RELAY_CALL MGTK::PaintRect, aux::ok_button_rect
        MGTK_RELAY_CALL MGTK::PaintRect, aux::ok_button_rect
        lda     #$00
l6:     rts

l7:     sta     d1
        lda     selected_device_index
        bmi     l8
        jsr     highlight_volume_label
l8:     lda     d1
        sta     selected_device_index
        jsr     highlight_volume_label
        jsr     main::detect_double_click
        beq     l5
        rts

d1:     .byte   0
col:    .byte   0
.endproc

;;; ============================================================
;;; Hilight volume label
;;; Input: A = volume index

.proc highlight_volume_label
        ldy     #<(kLabelsCol1-1)
        sty     select_volume_rect::x1
        ldy     #>(kLabelsCol1-1)
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
        ldax    #kLabelsCol3
        jmp     setpos

:       cmp     #4              ; second column?
        bcc     :+
        ldax    #kLabelsCol2
        jmp     setpos

:       ldax    #kLabelsCol1
        ;; fall through

setpos: stax    dialog_label_pos::xcoord

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

unit_num:
        .byte   $00

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
;;; Format disk
;;; Input: A = unit number

.proc format_unit
        ;; Check low nibble of unit number; if 0, it's a 16-sector Disk II
        ;; BUG: That's not valid per ProDOS TN21
        sta     unit_num
        and     #$0F
        beq     l2

        ;; This code is grabbing the high byte of the unit's address in
        ;; DEVADR, to test if $CnFF is $FF (a 13-sector disk).
        ;; BUG: The code doesn't verify that the high byte is $Cn so it
        ;; will fail (badly) for RAM-based drivers, including remapped
        ;; drives.
        ldx     #$11  ; TODO: Just do ((unit_num & $F0) >> 3) + DEVADR
        lda     unit_num
        and     #$80
        beq     l1
        ldx     #$21
l1:     stx     @lsb
        lda     unit_num
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     @lsb
        sta     @lsb
        @lsb := *+1
        lda     DEVADR & $FF00
        sta     $07
        lda     #$00
        sta     $06             ; point $06 at $Cn00
        ldy     #$FF
        lda     ($06),y         ; load $CnFF
        beq     l2              ; $00 = Disk II 16-sector
        cmp     #$FF            ; $FF = Disk II 13-sector
        bne     l3
l2:     lda     unit_num
        jsr     FormatDiskII
        rts

l3:     ldy     #$FF            ; offset to low byte of driver address
        lda     ($06),y
        sta     $06
        copy    #DRIVER_COMMAND_FORMAT, DRIVER_COMMAND
        lda     unit_num
        and     #$F0
        sta     DRIVER_UNIT_NUMBER
        jmp     ($06)

        rts

unit_num:
        .byte   0
.endproc

;;; ============================================================
;;; Check if the device supports formatting
;;; Input: A = unit number
;;; Output: A=0/Z=1/N=0 if yes, A=$FF/Z=0/N=1 if no

.proc check_supports_format
        ;; Check low nibble of unit number; if 0, it's a 16-sector Disk II
        ;; BUG: That's not valid per ProDOS TN21
        sta     unit_num
        and     #$0F
        beq     l2

        ldx     #$11  ; TODO: Just do ((unit_num & $F0) >> 3) + DEVADR
        lda     unit_num
        and     #$80
        beq     l1
        ldx     #$21
l1:     stx     @lsb
        lda     unit_num
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     @lsb
        sta     @lsb
        @lsb := *+1
        lda     DEVADR & $FF00
        sta     $07
        lda     #$00
        sta     $06             ; point $06 at $Cn00
        ldy     #$FF
        lda     ($06),y         ; load $CnFF
        beq     l2              ; $00 = Disk II 16-sector
        cmp     #$FF            ; $FF = Disk II 13-sector
        beq     l2
        ldy     #$FE            ; $CnFE
        lda     ($06),y
        and     #%00001000      ; Bit 3 = Supports format
        bne     l2

        return  #$FF            ; no, does not support format

l2:     return  #$00            ; yes, supports format

unit_num:
        .byte   0
.endproc

;;; ============================================================

.proc L1307
        sta     unit_num
        and     #$F0
        sta     write_block_params::unit_num
        stxy    $06

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
        sta     vol_name_buf,y
        dey
        bpl     :-

        lda     unit_num
        and     #$0F
        beq     L1394
        ldx     #$11  ; TODO: Just do ((unit_num & $F0) >> 3) + DEVADR
        lda     unit_num
        and     #$80
        beq     L134D
        ldx     #$21
L134D:  stx     @lsb
        lda     unit_num
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     @lsb
        sta     @lsb
        @lsb := *+1
        lda     DEVADR & $FF00
        sta     $06+1
        lda     #$00
        sta     $06
        ldy     #$FF
        lda     ($06),y         ; load $CnFF
        beq     L1394           ; $00 = Disk II 16-sector
        cmp     #$FF            ; $FF = Disk II 13-sector
        beq     L1394

        ldy     #$FF            ; offset to low byte of driver address
        lda     ($06),y
        sta     $06
        copy    #DRIVER_COMMAND_STATUS, DRIVER_COMMAND
        lda     unit_num
        and     #$F0
        sta     DRIVER_UNIT_NUMBER
        lda     #$00
        sta     DRIVER_BLOCK_NUMBER
        sta     DRIVER_BLOCK_NUMBER+1
        jsr     L1391
        bcc     L1398
        jmp     L1483

L1391:  jmp     ($06)

L1394:  ldxy    #kDefaultFloppyBlocks
L1398:  stxy    total_blocks

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

        ;; --------------------------------------------------
        ;; Volume directory key block

        copy16  #block_buffer, write_block_params::data_buffer
        lda     #3              ; block 2, points at 3
        sta     block_buffer+2

        ldy     vol_name_buf    ; volume name
        tya
        ora     #$F0
        sta     block_buffer + VolumeDirectoryHeader::storage_type_name_length
:       lda     vol_name_buf,y
        sta     block_buffer + VolumeDirectoryHeader::file_name - 1,y
        dey
        bne     :-

        ldy     #kNumKeyBlockHeaderBytes-1 ; other header bytes
:       lda     key_block_header_bytes,y
        sta     block_buffer+kKeyBlockHeaderOffset,y
        dey
        bpl     :-

        MLI_RELAY_CALL GET_TIME ; Apply timestamp
        ldy     #3
:       lda     DATELO,y
        sta     block_buffer + VolumeDirectoryHeader::creation_date,y
        dey
        bpl     :-

        jsr     write_block_and_zero

        ;; Subsequent volume directory blocks (4 total)
        copy    #2, block_buffer ; block 3, points at 2 and 4
        copy    #4, block_buffer+2
        jsr     write_block_and_zero

        copy    #3, block_buffer ; block 4, points at 3 and 5
        copy    #5, block_buffer+2
        jsr     write_block_and_zero

        copy    #4, block_buffer ; block 4, points back at 4
        jsr     write_block_and_zero

        ;; --------------------------------------------------
        ;; Bitmap blocks

        ;; Do a bunch of preliminary math to make building the volume bitmap easier

        lda     total_blocks    ; A lot of the math is affected by off-by-one problems that
        bne     :+              ; vanish if you decrease the blocks by one (go from "how many"
        dec     total_blocks+1  ; to "last block number")
:       dec     total_blocks

        lda     total_blocks    ; Take the remainder of the last block number modulo 8
        and     #$07
        tax                     ; Convert that remainder to a bitmask of "n+1" set high-endian bits
        lda     bitmask,x       ; using a lookup table and store it for later
        sta     last_byte       ; This value will go at the end of the bitmap

        lsr16   total_blocks    ; Divide the last block number by 8 in-place
        lsr16   total_blocks    ; This will become the in-block offset to the last
        lsr16   total_blocks    ; byte shortly

        lda     total_blocks+1  ; Divide the last block number again by 512 (high byte/2) in-register to get
        lsr     a               ; the base number of bitmap blocks needed minus 1
        clc                     ; Finally, add 6 to account for the 6 blocks used by the boot blocks (2)
        adc     #6              ; and volume directory (4) to get the block number of the last VBM block
        sta     lastblock       ; This final result should ONLY fall in the range of 6-21

        lda     total_blocks+1  ; Mask off the last block's "partial" byte count - this is now the offset to the
        and     #$01            ; last byte in the last VBM block. All other blocks get filled with 512 $FF's
        sta     total_blocks+1

        ;; Main loop to build the volume bitmap
bitmaploop:
        jsr     buildblock      ; Build a bitmap for the current block

        lda     write_block_params::block_num+1 ; Are we at a block >255?
        bne     L1483           ; Then something's gone horribly wrong and we need to stop
        lda     write_block_params::block_num
        cmp     #6              ; Are we anywhere other than block 6?
        bne     gowrite         ; Then go ahead and write the bitmap block as-is

        ;; Block 6 - Set up the volume bitmap to protect the blocks at the beginning of the volume
        copy    #$01, block_buffer ; Mark blocks 0-6 in use
        lda     lastblock       ; What's the last block we need to protect?
        cmp     #7
        bcc     gowrite         ; If it's less than 7, default to always protecting 0-6

        copy    #$00, block_buffer ; Otherwise (>=7) mark blocks 0-7 as "in use"
        lda     lastblock       ; and check again
        cmp     #15
        bcs     :+              ; Is it 15 or more? Skip ahead.
        and     #$07            ; Otherwise (7-14) take the low three bits
        tax
        lda     freemask,x      ; convert them to the correct VBM value using a lookup table
        sta     block_buffer+1  ; put it in the bitmap
        jmp     gowrite         ; and write the block

:       copy    #$00, block_buffer+1 ; (>=15) Mark blocks 8-15 as "in use"
        lda     lastblock       ; Then finally
        and     #$07            ; take the low three bits
        tax
        lda     freemask,x      ; convert them to the correct VBM value using a lookup table
        sta     block_buffer+2  ; put it in the bitmap, and fall through to the write

        ;; Call the write/increment/zero routine, and loop back if we're not done
gowrite:
        jsr     write_block_and_zero
        lda     write_block_params::block_num
        cmp     lastblock
        bcc     bitmaploop
        beq     bitmaploop

success:
        lda     #$00
        sta     $08
        clc
        rts

L1483:  sec
        rts

;;; Values with "n+1" (1-8) high-endian bits set
bitmask:
        .byte   $80,$C0,$E0,$F0,$F8,$FC,$FE,$FF

;;; Special mask values for setting up block 6 /NOTE OFF-BY-ONE/
freemask:
        .byte   $7F,$3F,$1F,$0F,$07,$03,$01,$FF

;;; Contents of the last byte of the VBM
last_byte:
        .byte   $00

;;; Block number of the last VBM block
lastblock:
        .byte   6

;;; ============================================================
;;; Build a single block of the VBM. These blocks are all filled with
;;; 512 $FF values, except for the last block in the entire VBM, which
;;; gets cleared to $00's following the final byte position.

.proc buildblock
        ldy     #$00
        lda     #$FF
ffloop: sta     block_buffer,y  ; Fill this entire block
        sta     block_buffer+$100,y ; with $FF bytes
        iny
        bne     ffloop

        lda     write_block_params::block_num
        cmp     lastblock       ; Is this the last block?
        bne     builddone       ; No, then just use the full block of $FF's

        ldy     total_blocks    ; Get the offset to the last byte that needs to be updated
        lda     total_blocks+1
        bne     secondhalf      ; Is it in the first $100 or the second $100?

        lda     last_byte       ; Updating the first half
        sta     block_buffer,y  ; Put the last byte in the right location
        lda     #$00
        iny
        beq     zerosecond      ; Was that the end of the first half?

zerofirst:
        sta     block_buffer,y  ; Clear the remainder of the first half
        iny
        bne     zerofirst
        beq     zerosecond      ; Then go clear ALL of the second half

secondhalf:
        lda     last_byte       ; Updating the second half
        sta     block_buffer+$100,y ; Put the last byte in the right location
        lda     #$00
        iny
        beq     builddone       ; Was that the end of the second half?

zerosecond:
        sta     block_buffer+$100,y ; Clear the remainder of the second half
        iny
        bne     zerosecond

builddone:
        rts                     ; And we're done
.endproc

.endproc

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

;;; Part of volume directory block at offset $22
;;; $22 = access $C3
;;; $23 = entry_length $27
;;; $24 = entries_per_block $0D
;;; $25 = file_count 0
;;; $27 = bit_map_pointer 6
;;; $29 = total_blocks
kNumKeyBlockHeaderBytes = .sizeof(VolumeDirectoryHeader) - VolumeDirectoryHeader::access
kKeyBlockHeaderOffset = VolumeDirectoryHeader::access
key_block_header_bytes:
        .byte   $C3,$27,$0D
        .word   0
        .word   6
total_blocks:
        .word   kDefaultFloppyBlocks
        ASSERT_TABLE_SIZE key_block_header_bytes, kNumKeyBlockHeaderBytes

vol_name_buf:
        .res    27,0

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
        jsr     get_slot_char
        sta     the_disk_in_slot_label + kTheDiskInSlotSlotCharOffset
        lda     read_block_params::unit_num
        jsr     get_drive_char
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
        jsr     get_slot_char
        sta     the_dos_33_disk_label + kTheDos33DiskSlotCharOffset
        lda     read_block_params::unit_num
        jsr     get_drive_char
        sta     the_dos_33_disk_label + kTheDos33DiskDriveCharOffset
        COPY_STRING the_dos_33_disk_label, ovl_string_buf
        rts

        .byte   0

.proc get_slot_char
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #'0'
        rts
.endproc

.proc get_drive_char
        and     #$80
        asl     a
        rol     a
        adc     #'1'
        rts
.endproc

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
;;; Inputs: A=unit number

.proc append_vol_name_question
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
        lda     #'?'
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
