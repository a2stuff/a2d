;;; ============================================================
;;; Overlay for Format/Erase
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.scope format_erase_overlay
        .org ::kOverlayFormatEraseAddress

        MLIEntry := main::MLIRelayImpl
        MGTKEntry := MGTKRelayImpl
        BTKEntry := BTKRelayImpl

        block_buffer := $1A00
        read_buffer := $1C00

        ovl_string_buf := path_buf0

        kDefaultFloppyBlocks = 280

        kMaxVolumesInPicker = 12 ; 3 cols * 4 rows

;;; ============================================================

        ;; This must be page-aligned.
        .include "../lib/formatdiskii.s"

;;; ============================================================

Exec:
        pha
        jsr     main::SetCursorPointer
        pla
        cmp     #$04
        jeq     FormatDisk
        jmp     EraseDisk

;;; ============================================================

;;; The selected index (0-based), or $FF if no drive is selected
selected_device_index:
        .byte   0

;;; Number of volumes; min(DEVCNT+1, kMaxVolumesInPicker)
num_volumes:
        .byte   0

;;; ============================================================
;;; Show the device prompt, name prompt, and confirmation.
;;; Input: A=operation flag, high bit set=erase, clear=format
;;; Output: C=0, A=unit_num on success, C=1 if canceled.

.proc PromptForDeviceAndName
        sta     erase_flag

        ;; --------------------------------------------------
        ;; Prompt for device
.scope
        copy    #$00, has_input_field_flag
        jsr     main::OpenPromptWindow
        jsr     main::SetPortForDialogWindow
        bit     erase_flag
    IF_NC
        param_call main::DrawDialogTitle, aux::label_format_disk
        param_call main::DrawDialogLabel, 1, aux::str_select_format
    ELSE
        param_call main::DrawDialogTitle, aux::label_erase_disk
        param_call main::DrawDialogLabel, 1, aux::str_select_erase
    END_IF

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::MoveTo, vol_picker_line1_start
        MGTK_CALL MGTK::LineTo, vol_picker_line1_end
        MGTK_CALL MGTK::MoveTo, vol_picker_line2_start
        MGTK_CALL MGTK::LineTo, vol_picker_line2_end

        jsr     DrawVolumeLabels
        copy    #$FF, selected_device_index
        copy16  #HandleClick, main::jump_relay+1
        copy    #$80, format_erase_overlay_flag

loop1:
        jsr     main::PromptInputLoop
        bmi     loop1           ; not done
        beq     :+              ; ok
        jmp     cancel          ; cancel
:
        bit     selected_device_index
        bmi     loop1

        jsr     GetSelectedUnitNum
        sta     unit_num
.endscope

        ;; --------------------------------------------------
        ;; Prompt for name
.scope
        copy16  #main::NoOp, main::jump_relay+1

        jsr     main::SetPortForDialogWindow
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, name_input_rect
        jsr     main::ClearPathBuf1
        copy    #$80, has_input_field_flag
        copy    #$00, format_erase_overlay_flag
        jsr     main::InitNameInput
        jsr     main::SetPortForDialogWindow
        param_call main::DrawDialogLabel, 3, aux::str_new_volume

loop2:
        jsr     main::PromptInputLoop
        bmi     loop2           ; not done
        beq     ok2             ; ok
        jmp     cancel          ; cancel

err2:   jsr     Bell
        jmp     loop2

ok2:    lda     path_buf1
        beq     err2            ; name is empty
        cmp     #kMaxFilenameLength+1
        bcs     err2            ; name > 15 characters
        jsr     main::SetCursorPointerWithFlag

        ;; Check for conflicting name
        ldxy    #path_buf1
        lda     unit_num
        jsr     CheckConflictingVolumeName
        bcc     :+
        lda     #ERR_DUPLICATE_FILENAME
        jsr     JUMP_TABLE_SHOW_ALERT
        jmp     loop2
:
.endscope

        ;; --------------------------------------------------
        ;; Confirm operation
.scope
        jsr     main::SetPortForDialogWindow
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect

        copy    #0, has_input_field_flag
        bit     erase_flag
    IF_NC
        param_call main::DrawDialogLabel, 3, aux::str_confirm_format_prefix
    ELSE
        param_call main::DrawDialogLabel, 3, aux::str_confirm_erase_prefix
    END_IF
        lda     unit_num
        jsr     GetVolName
        param_call main::DrawString, ovl_string_buf
        bit     erase_flag
    IF_NC
        param_call main::DrawString, aux::str_confirm_format_suffix
    ELSE
        param_call main::DrawString, aux::str_confirm_erase_suffix
    END_IF
:       jsr     main::PromptInputLoop
        bmi     :-              ; not done
        beq     :+              ; ok
        jmp     cancel          ; cancel
:
.endscope

        ;; Confirmed!
        unit_num := *+1
        lda     #SELF_MODIFIED_BYTE
        clc
        rts

cancel:
        sec
        rts

;;; High bit set if erase, otherwise format.
erase_flag:
        .byte   0
.endproc

;;; ============================================================
;;; Format Disk

.proc FormatDisk
        lda     #$00
        jsr     PromptForDeviceAndName
        jcs     cancel
        sta     d2
        sta     unit_num

        ;; --------------------------------------------------
        ;; Proceed with format
l8:
        jsr     main::SetPortForDialogWindow
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        param_call main::DrawDialogLabel, 1, aux::str_formatting

        unit_num := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     CheckSupportsFormat
        and     #$FF
        bne     l9
        jsr     main::SetCursorWatch
        lda     unit_num
        jsr     FormatUnit
        bcs     l12
l9:     jsr     main::SetPortForDialogWindow
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        param_call main::DrawDialogLabel, 1, aux::str_erasing
        param_call UpcaseString, path_buf1

        ldxy    #path_buf1
        lda     unit_num
        jsr     WriteHeaderBlocks
        pha
        jsr     main::SetCursorPointer
        pla
        bne     l10
        lda     #$00
        jmp     cancel

l10:    cmp     #ERR_WRITE_PROTECTED
        bne     l11
        jsr     JUMP_TABLE_SHOW_ALERT
        .assert kAlertResultCancel <> 0, error, "Branch assumes enum value"
        bne     cancel          ; `kAlertResultCancel` = 1
        jmp     l8              ; `kAlertResultTryAgain` = 0

l11:    jsr     Bell
        jsr     main::SetPortForDialogWindow
        param_call main::DrawDialogLabel, 6, aux::str_erasing_error
        jmp     l14

l12:    pha
        jsr     main::SetCursorPointer
        pla
        cmp     #ERR_WRITE_PROTECTED
        bne     l13
        jsr     JUMP_TABLE_SHOW_ALERT
        .assert kAlertResultCancel <> 0, error, "Branch assumes enum value"
        bne     cancel          ; `kAlertResultCancel` = 1
        jmp     l8              ; `kAlertResultTryAgain` = 0

l13:    jsr     Bell
        jsr     main::SetPortForDialogWindow
        param_call main::DrawDialogLabel, 6, aux::str_formatting_error
l14:    jsr     main::PromptInputLoop
        bmi     l14             ; not done
        bne     cancel          ; ok
        jmp     l8              ; cancel

cancel:
        pha
        jsr     main::SetCursorPointer
        MGTK_CALL MGTK::CloseWindow, winfo_prompt_dialog

        d2 := *+1               ; ???
        ldx     #SELF_MODIFIED_BYTE
        pla
        rts
.endproc

;;; ============================================================
;;; Erase Disk

.proc EraseDisk
        lda     #$80
        jsr     PromptForDeviceAndName
        bcs     cancel
        sta     d2
        sta     unit_num

        ;; --------------------------------------------------
        ;; Proceed with erase
l7:
        jsr     main::SetPortForDialogWindow
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        param_call main::DrawDialogLabel, 1, aux::str_erasing
        param_call UpcaseString, path_buf1
        jsr     main::SetCursorWatch

        ldxy    #path_buf1
        unit_num := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     WriteHeaderBlocks
        pha
        jsr     main::SetCursorPointer
        pla
        bne     l8
        lda     #$00
        jmp     cancel

l8:     cmp     #ERR_WRITE_PROTECTED
        bne     l9
        jsr     JUMP_TABLE_SHOW_ALERT
        .assert kAlertResultCancel <> 0, error, "Branch assumes enum value"
        bne     cancel          ; `kAlertResultCancel` = 1
        jmp     l7              ; `kAlertResultTryAgain` = 0

l9:     jsr     Bell
        jsr     main::SetPortForDialogWindow
        param_call main::DrawDialogLabel, 6, aux::str_erasing_error
l10:    jsr     main::PromptInputLoop
        bmi     l10             ; not done
        beq     l7              ; ok

cancel:
        pha                     ; cancel
        jsr     main::SetCursorPointer
        MGTK_CALL MGTK::CloseWindow, winfo_prompt_dialog

        d2 := *+1               ; ???
        ldx     #SELF_MODIFIED_BYTE
        pla
        rts
.endproc

;;; ============================================================

.proc HandleClick
        jsr     GetOptionIndexFromCoords
        bmi     done

        ;; Is it valid?
        cmp     num_volumes
        bcc     valid
        lda     selected_device_index ; nope - clear selection if needed
        bmi     done
        lda     selected_device_index
        jsr     HighlightVolumeLabel
        lda     #$FF
        sta     selected_device_index
done:   return  #$FF

        ;; Valid selection - has it changed?
valid:  cmp     selected_device_index
        bne     update

        jsr     main::StashCoordsAndDetectDoubleClick
        bmi     l6

        ;; Activated by double-click
l5:     BTK_CALL BTK::Flash, aux::ok_button_params
        lda     #$00
l6:     rts

        ;; Update selection
update: pha                     ; A = new selection
        lda     selected_device_index
        bmi     :+
        jsr     HighlightVolumeLabel ; unhighlight old
:
        pla                     ; A = new selection
        sta     selected_device_index
        jsr     HighlightVolumeLabel ; highlight new
        jsr     main::StashCoordsAndDetectDoubleClick
        beq     l5
        rts
.endproc

;;; ============================================================
;;; Get the coordinates of an option by index.
;;; Input: A = volume index
;;; Output: A,X = x coordinate, Y = y coordinate
.proc GetOptionPos
        sta     index
        .repeat ::kVolPickerRowShift
        lsr                     ; lo
        .endrepeat
        ldx     #0              ; hi
        ldy     #kVolPickerItemWidth
        jsr     Multiply_16_8_16
        clc
        adc     #<kVolPickerLeft
        pha                     ; lo
        txa
        adc     #>kVolPickerLeft
        pha                     ; hi

        ;; Y coordinate
        index := *+1
        lda     #SELF_MODIFIED_BYTE
        and     #kVolPickerRows-1
        ldx     #0              ; hi
        ldy     #kVolPickerItemHeight
        jsr     Multiply_16_8_16
        clc
        adc     #kVolPickerTop

        tay                     ; Y coord
        pla
        tax                     ; X coord hi
        pla                     ; X coord lo

        rts
.endproc

;;; ============================================================

;;; Inputs: `screentowindow_params` has `windowx` and `windowy` mapped
;;; Outputs: A=index, N=1 if no match
.proc GetOptionIndexFromCoords
        ;; Row
        sub16   screentowindow_params::windowy, #kVolPickerTop, screentowindow_params::windowy
        bmi     done

        ldax    screentowindow_params::windowy
        ldy     #kVolPickerItemHeight
        jsr     Divide_16_8_16  ; A = row

        cmp     #kVolPickerRows
        bcs     done
        sta     row

        ;; Column
        sub16   screentowindow_params::windowx, #kVolPickerLeft, screentowindow_params::windowx
        bmi     done

        ldax    screentowindow_params::windowx
        ldy     #kVolPickerItemWidth
        jsr     Divide_16_8_16  ; A = col

        cmp     #kVolPickerCols
        bcs     done

        ;; Index
        .repeat ::kVolPickerRowShift
        asl
        .endrepeat
        row := *+1
        ora     #SELF_MODIFIED_BYTE
        rts

done:   return  #$FF
.endproc

;;; ============================================================
;;; Hilight volume label
;;; Input: A = volume index

.proc HighlightVolumeLabel
        jsr     GetOptionPos
        stax    vol_picker_item_rect::x1
        addax   #kVolPickerItemWidth-1, vol_picker_item_rect::x2

        tya
        ldx     #0
        stax    vol_picker_item_rect::y1
        addax   #kListItemHeight-1, vol_picker_item_rect::y2

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, vol_picker_item_rect
        rts
.endproc

;;; ============================================================

.proc MaybeHighlightSelectedIndex
        lda     selected_device_index
        bmi     :+
        jsr     HighlightVolumeLabel
        copy    #$FF, selected_device_index
:       rts
.endproc

;;; ============================================================

        ;; Called from main
.proc PromptHandleKeyRight
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
        jsr     MaybeHighlightSelectedIndex
        pla
set:    sta     selected_device_index
        jsr     HighlightVolumeLabel
done:   return  #$FF
.endproc

;;; ============================================================

        ;; Called from main
.proc PromptHandleKeyLeft
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
        jsr     MaybeHighlightSelectedIndex
        pla

set:    sta     selected_device_index
        jsr     HighlightVolumeLabel
done:   return  #$FF
.endproc

;;; ============================================================

        ;; Called from main
.proc PromptHandleKeyDown
        lda     selected_device_index ; $FF if none, would inc to #0
        clc
        adc     #1
        cmp     num_volumes
        bcc     :+
        lda     #0              ; wrap to first
:       pha
        jsr     MaybeHighlightSelectedIndex
        pla
        sta     selected_device_index
        jsr     HighlightVolumeLabel
        return  #$FF
.endproc

;;; ============================================================

        ;; Called from main
.proc PromptHandleKeyUp
        lda     selected_device_index
        bmi     wrap            ; if no selection, wrap
        sec
        sbc     #1              ; to to previous
        bpl     :+              ; unless wrapping needed

wrap:   ldx     num_volumes     ; go to last (num - 1)
        dex
        txa

:       pha
        jsr     MaybeHighlightSelectedIndex
        pla
        sta     selected_device_index
        jsr     HighlightVolumeLabel
        return  #$FF
.endproc

;;; ============================================================
;;; Draw volume labels

.proc DrawVolumeLabels
        ldx     DEVCNT          ; number of volumes - 1
        inx
        cpx     #kMaxVolumesInPicker
        bcc     :+
        ldx     #kMaxVolumesInPicker
:       stx     num_volumes

        lda     #0
        sta     vol

        vol := *+1
loop:   lda     #SELF_MODIFIED_BYTE
        cmp     num_volumes
        bne     :+
        rts
:
        jsr     GetOptionPos
        addax   #kVolPickerTextHOffset, vol_picker_item_rect::x1
        tya
        ldx     #0
        addax   #kVolPickerTextVOffset, vol_picker_item_rect::y1
        MGTK_CALL MGTK::MoveTo, vol_picker_item_rect::topleft

        ;; Reverse order, so boot volume is first
        lda     num_volumes
        sec
        sbc     #1
        sbc     vol
        asl     a
        tay
        lda     device_name_table+1,y
        tax
        lda     device_name_table,y ; now A,X has pointer
        jsr     main::DrawString

        inc     vol
        jmp     loop
.endproc

;;; ============================================================
;;; Gets the selected unit number from `DEVLST`
;;; Output: A = unit number (with low nibble intact)
;;; Assert: `selected_device_index` is valid (i.e. not $FF)

.proc GetSelectedUnitNum
        ;; Reverse order, so boot volume is first
        lda     num_volumes
        sec
        sbc     #1
        sbc     selected_device_index
        tax
        lda     DEVLST,x
        rts
.endproc

;;; ============================================================
;;; A,X = string

.proc UpcaseString
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

;;; ============================================================
;;; Inputs: A = unit number (no need to mask off low nibble), X,Y = name
;;; Outputs: C=1 if there's a duplicate, C=0 otherwise

.proc CheckConflictingVolumeName
        ptr := $06
        stxy    ptr
        and     #UNIT_NUM_MASK
        sta     unit_num

        ;; Copy name, prepending '/'
        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     path+1,y
        dey
        bpl     :-
        clc
        adc     #1
        sta     path
        copy    #'/', path+1

        MLI_CALL GET_FILE_INFO, get_file_info_params
        bne     no_match

        ;; A volume with that name exists... but is it the one
        ;; we're about to format/erase?
        lda     DEVNUM

        unit_num := *+1
        cmp     #SELF_MODIFIED_BYTE
        beq     no_match

        ;; Not the same device, so a match. Return C=1
        sec
        rts

        ;; No match we care about, so return C=0.
no_match:
        clc
        rts
.endproc

;;; ============================================================

        DEFINE_ON_LINE_PARAMS on_line_params,, $1C00
        DEFINE_READ_BLOCK_PARAMS read_block_params, read_buffer, 0
        DEFINE_WRITE_BLOCK_PARAMS write_block_params, prodos_loader_blocks, 0

unit_num:
        .byte   $00

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, path
path:
        .res    17,0              ; length + '/' + 15-char name

;;; ============================================================
;;; Get driver address
;;; Input: A = unit number (no need to mask off low nibble)
;;; Output: A,X = driver address

.proc GetDriverAddress
        and     #UNIT_NUM_MASK  ; DSSS0000 after masking
        lsr                     ; 0DSSS000
        lsr                     ; 00DSSS00
        lsr                     ; 000DSSS0
        tax
        lda     DEVADR,x        ; low byte of driver address
        pha
        inx
        lda     DEVADR,x        ; high byte of driver address
        tax
        pla
        rts
.endproc

;;; ============================================================
;;; Format disk
;;; Input: A = unit number (with low nibble intact)

.proc FormatUnit
        sta     unit_num

        jsr     main::IsDiskII
        bne     driver

        ;; Format as Disk II
        lda     unit_num
        jmp     FormatDiskII

        ;; Format using driver
driver: lda     unit_num
        jsr     GetDriverAddress
        stax    @driver

        sta     ALTZPOFF        ; Main ZP/LCBANKs

        copy    #DRIVER_COMMAND_FORMAT, DRIVER_COMMAND
        lda     unit_num
        and     #UNIT_NUM_MASK
        sta     DRIVER_UNIT_NUMBER

        @driver := *+1
        jsr     SELF_MODIFIED

        sta     ALTZPON         ; Aux ZP/LCBANKs

        rts

unit_num:
        .byte   0
.endproc

;;; ============================================================
;;; Check if the device supports formatting
;;; Input: A = unit number (with low nibble intact)
;;; Output: A=0/Z=1/N=0 if yes, A=$FF/Z=0/N=1 if no

.proc CheckSupportsFormat
        sta     unit_num

        jsr     main::IsDiskII
        beq     supported

        ;; Check if the driver is firmware ($CnXX).
        lda     unit_num
        jsr     GetDriverAddress
        stx     addr+1          ; self-modify address below
        txa                     ; high byte
        and     #$F0            ; look at high nibble
        cmp     #$C0            ; firmware? ($Cn)
        bne     supported       ; TODO: Should we guess yes or no here???

        ;; Check the firmware status byte
        addr := *+1
        lda     $C0FE           ; $CnFE, high byte is self-modified above
        and     #%00001000      ; Bit 3 = Supports format
        bne     supported

        return  #$FF            ; no, does not support format

supported:
        return  #$00            ; yes, supports format

unit_num:
        .byte   0
.endproc

;;; ============================================================
;;; Write the loader, volume directory, and volume bitmap
;;; Inputs: A = unit number (with low nibble intact), X,Y = volume name

.proc WriteHeaderBlocks
        sta     unit_num
        and     #UNIT_NUM_MASK
        sta     write_block_params::unit_num
        stxy    $06

        ;; Remove leading '/' from name, if necessary
        ldy     #$01
        lda     ($06),y
        cmp     #'/'
        bne     L132C           ; nope
        dey
        lda     ($06),y         ; shrink string, adjust pointer
        sec
        sbc     #1
        iny
        sta     ($06),y
        inc16   $06

        ;; Copy name into volume directory key block data
L132C:  ldy     #0
        lda     ($06),y
        tay
:       lda     ($06),y
        sta     vol_name_buf,y
        dey
        bpl     :-

        ;; --------------------------------------------------
        ;; Get the block count for the device

        ;; Check if it's a Disk II
        lda     unit_num
        jsr     main::IsDiskII
        beq     disk_ii

        ;; Not Disk II - use the driver.
        lda     unit_num
        jsr     GetDriverAddress
        stax    @driver

        sta     ALTZPOFF        ; Main ZP/LCBANKs

        copy    #DRIVER_COMMAND_STATUS, DRIVER_COMMAND
        lda     unit_num
        and     #UNIT_NUM_MASK
        sta     DRIVER_UNIT_NUMBER
        lda     #$00
        sta     DRIVER_BLOCK_NUMBER
        sta     DRIVER_BLOCK_NUMBER+1

        @driver := *+1
        jsr     SELF_MODIFIED

        sta     ALTZPON         ; Aux ZP/LCBANKs

        bcc     L1398           ; success
        jmp     L1483           ; failure

disk_ii:
        ldxy    #kDefaultFloppyBlocks
L1398:  stxy    total_blocks

        ;; --------------------------------------------------
        ;; Loader blocks

        ;; Write first block of loader
        copy16  #prodos_loader_blocks, write_block_params::data_buffer
        copy16  #0, write_block_params::block_num
        MLI_CALL WRITE_BLOCK, write_block_params
        beq     :+
        jmp     fail2

        ;; Write second block of loader
:       inc     write_block_params::block_num     ; next block needs...
        inc     write_block_params::data_buffer+1 ; next $200 of data
        inc     write_block_params::data_buffer+1
        jsr     WriteBlockAndZero

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

        MLI_CALL GET_TIME ; Apply timestamp
        ldy     #3
:       lda     DATELO,y
        sta     block_buffer + VolumeDirectoryHeader::creation_date,y
        dey
        bpl     :-

        jsr     WriteBlockAndZero

        ;; Subsequent volume directory blocks (4 total)
        copy    #2, block_buffer ; block 3, points at 2 and 4
        copy    #4, block_buffer+2
        jsr     WriteBlockAndZero

        copy    #3, block_buffer ; block 4, points at 3 and 5
        copy    #5, block_buffer+2
        jsr     WriteBlockAndZero

        copy    #4, block_buffer ; block 4, points back at 4
        jsr     WriteBlockAndZero

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
        jsr     BuildBlock      ; Build a bitmap for the current block

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
        bcc     gowrite         ; and write the block

:       copy    #$00, block_buffer+1 ; (>=15) Mark blocks 8-15 as "in use"
        lda     lastblock       ; Then finally
        and     #$07            ; take the low three bits
        tax
        lda     freemask,x      ; convert them to the correct VBM value using a lookup table
        sta     block_buffer+2  ; put it in the bitmap, and fall through to the write

        ;; Call the write/increment/zero routine, and loop back if we're not done
gowrite:
        jsr     WriteBlockAndZero
        lda     lastblock
        cmp     write_block_params::block_num
        bcs     bitmaploop

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

.proc BuildBlock
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

.proc WriteBlockAndZero
        MLI_CALL WRITE_BLOCK, write_block_params
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

prodos_loader_blocks:
        .incbin "../inc/pdload.dat"
        .assert * - prodos_loader_blocks = $400, error, "Bad data"

;;; ============================================================

;;; Note that code from around this point is overwritten when
;;; `block_buffer` is used, so only place routines not used after
;;; writing starts are placed here. The overlay will be reloaded
;;; for subsequent format/erase operations.

;;; ============================================================
;;; Get a volume name for a non-ProDOS disk given a unit number.
;;; Input: A = unit number
;;; Output: `ovl_string_buf` is populated.

.proc GetNonprodosVolName
        ;; Read block 0
        sta     read_block_params::unit_num
        copy16  #0, read_block_params::block_num
        MLI_CALL READ_BLOCK, read_block_params
        bne     unknown         ; failure
        lda     read_buffer + 1
        cmp     #$E0            ; DOS 3.3?
        beq     :+              ; Maybe...
        jmp     maybe_dos
:       lda     read_buffer + 2
        cmp     #$70
        beq     pascal
        cmp     #$60
        beq     pascal
        FALL_THROUGH_TO unknown

        ;; Unknown, just use slot and drive
unknown:
        lda     read_block_params::unit_num
        jsr     GetSlotChar
        sta     the_disk_in_slot_label + kTheDiskInSlotSlotCharOffset
        lda     read_block_params::unit_num
        jsr     GetDriveChar
        sta     the_disk_in_slot_label + kTheDiskInSlotDriveCharOffset
        ldx     the_disk_in_slot_label
L1974:  lda     the_disk_in_slot_label,x
        sta     ovl_string_buf,x
        dex
        bpl     L1974
        rts

        ;; Pascal
pascal: param_call pascal_disk, ovl_string_buf
        rts

        ;; Maybe DOS 3.3, not sure yet...
maybe_dos:
        cmp     #$A5
        bne     unknown
        lda     read_buffer + 2
        cmp     #$27
        bne     unknown

        ;; DOS 3.3, use slot and drive
        lda     read_block_params::unit_num
        jsr     GetSlotChar
        sta     the_dos_33_disk_label + kTheDos33DiskSlotCharOffset
        lda     read_block_params::unit_num
        jsr     GetDriveChar
        sta     the_dos_33_disk_label + kTheDos33DiskDriveCharOffset
        COPY_STRING the_dos_33_disk_label, ovl_string_buf
        rts

.proc GetSlotChar
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #'0'
        rts
.endproc

.proc GetDriveChar
        and     #$80
        asl     a
        rol     a
        adc     #'1'
        rts
.endproc

;;; Handle Pascal disk - name suffixed with ':'
pascal_disk:
        copy16  #$0002, read_block_params::block_num
        MLI_CALL READ_BLOCK, read_block_params
        beq     :+
        ;; Pascal disk, empty name - use " :" (weird, but okay?)
        copy    #2, ovl_string_buf
        copy    #' ', ovl_string_buf+1
        copy    #':', ovl_string_buf+2
        rts

        ;; Pascal disk, use name
:       lda     read_buffer + 6
        tax
:       lda     read_buffer + 6,x
        sta     ovl_string_buf,x
        dex
        bpl     :-
        inc     ovl_string_buf
        ldx     ovl_string_buf
        lda     #':'
        sta     ovl_string_buf,x
        rts
.endproc

;;; ============================================================
;;; Get a volume name, for ProDOS or non-ProDOS disk.
;;; Input: A = unit number (no need to mask off low nibble)
;;; Output: `ovl_string_buf` is populated

.proc GetVolName
        and     #UNIT_NUM_MASK
        sta     on_line_params::unit_num
        MLI_CALL ON_LINE, on_line_params
        bne     non_pro
        lda     read_buffer
        and     #NAME_LENGTH_MASK
        beq     non_pro
        sta     read_buffer
        tax
:       lda     read_buffer,x
        sta     ovl_string_buf,x
        dex
        bpl     :-

        rts

non_pro:
        lda     on_line_params::unit_num
        jmp     GetNonprodosVolName
.endproc

;;; ============================================================

        PAD_TO ::kOverlayFormatEraseAddress + ::kOverlayFormatEraseLength

.endscope ; format_erase_overlay

format_erase_overlay__PromptHandleKeyLeft     := format_erase_overlay::PromptHandleKeyLeft
format_erase_overlay__PromptHandleKeyRight    := format_erase_overlay::PromptHandleKeyRight
format_erase_overlay__PromptHandleKeyDown     := format_erase_overlay::PromptHandleKeyDown
format_erase_overlay__PromptHandleKeyUp       := format_erase_overlay::PromptHandleKeyUp

format_erase_overlay__Exec := format_erase_overlay::Exec
