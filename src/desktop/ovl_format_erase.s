;;; ============================================================
;;; Overlay for Format/Erase
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

        BEGINSEG OverlayFormatErase

.scope FormatEraseOverlay

;;; Memory Map
;;; ...
;;; $1E00 - $1FFF - unused/preserved
;;; $1C00 - $1DFF - `read_buffer` (for checking target format)
;;; $1A00 - $1BFF - `block_buffer` (for writing)
;;; $1700 - $19FF - unused/preserved
;;; $0800 - $16FF - overlay code
;;; ...

        MLIEntry := main::MLIRelayImpl
        MGTKEntry := MGTKRelayImpl
        LETKEntry := LETKRelayImpl
        BTKEntry := BTKRelayImpl
        OPTKEntry := OPTKRelayImpl

        block_buffer := $1A00
        read_buffer := $1C00

        ovl_string_buf := path_buf0

        kDefaultFloppyBlocks = 280

;;; ============================================================

        ;; This must be page-aligned.
        .include "../lib/formatdiskii.s"

;;; ============================================================

;;; A = operation (Format/Erase); X = unit num (or 0)
Exec:
        cmp     #FormatEraseAction::format
        jeq     FormatDisk
        jmp     EraseDisk

;;; ============================================================
;;; Show the device prompt, name prompt, and confirmation.
;;; Input: C=operation flag, 1=erase, 0=format
;;;        X=unit num, or 0 to prompt for device
;;; Output: C=0, A=unit_num on success, C=1 if canceled.

.proc PromptForDeviceAndName
        ror     erase_flag      ; C into bit7
        stx     unit_num

        ;; --------------------------------------------------
        ;; Prompt for device
.scope
        CLEAR_BIT7_FLAG has_input_field_flag
        lda     #kPromptButtonsOKCancel
        jsr     main::OpenPromptWindow ; A = `prompt_button_flags`
        jsr     main::SetPortForDialogWindow

        ldax    #aux::label_format_disk
        bit     erase_flag
    IF NS
        ldax    #aux::label_erase_disk
    END_IF
        jsr     main::DrawDialogTitle

        lda     unit_num
        bne     skip_select

        MGTK_CALL MGTK::MoveTo, vol_picker_select_pos
        ldax    #aux::str_select_format
        bit     erase_flag
    IF NS
        ldax    #aux::str_select_erase
    END_IF
        jsr     main::DrawString

        jsr     main::SetPenModeNotCopy
        MGTK_CALL MGTK::MoveTo, vol_picker_line1_start
        MGTK_CALL MGTK::LineTo, vol_picker_line1_end
        MGTK_CALL MGTK::MoveTo, vol_picker_line2_start
        MGTK_CALL MGTK::LineTo, vol_picker_line2_end

        copy8   #$FF, vol_picker_record::selected_index
        copy16  #HandleClick, main::PromptDialogClickHandlerHook
        copy16  #HandleKey, main::PromptDialogKeyHandlerHook
        SET_BIT7_FLAG has_device_picker_flag

        OPTK_CALL OPTK::Draw, vol_picker_params
        jsr     main::UpdateOKButton

    DO
        jsr     main::PromptInputLoop
    WHILE NS                    ; not done
        jne     cancel          ; cancel

        jsr     GetSelectedUnitNum
        sta     unit_num
.endscope

skip_select:

        ;; --------------------------------------------------
        ;; Prompt for name
.scope
        ldax    #main::NoOp
        stax    main::PromptDialogClickHandlerHook
        stax    main::PromptDialogKeyHandlerHook

        jsr     SetPortAndClear
        jsr     main::SetPenModeNotCopy
        MGTK_CALL MGTK::FrameRect, name_input_rect
        SET_BIT7_FLAG has_input_field_flag
        copy8   #0, text_input_buf
        CLEAR_BIT7_FLAG has_device_picker_flag

        param_call main::DrawDialogLabel, 2, aux::str_location

        ;; Find `DEVLST` index of selected/specified device
        ldx     #AS_BYTE(-1)
    DO
        inx
        lda     DEVLST,x
        and     #UNIT_NUM_MASK
    WHILE A <> unit_num
        ;; NOTE: Assertion violation if not found

        txa
        jsr     GetDeviceNameForIndex
        jsr     main::DrawString

        param_call main::DrawDialogLabel, 4, aux::str_new_volume

        LETK_CALL LETK::Init, prompt_le_params
        LETK_CALL LETK::Activate, prompt_le_params
        jsr     main::UpdateOKButton

loop2:
        jsr     main::PromptInputLoop
        bmi     loop2           ; not done
        bne     cancel          ; cancel

        jsr     main::SetCursorPointerWithFlag

        ;; Check for conflicting name
        ldxy    #text_input_buf
        lda     unit_num
        jsr     CheckConflictingVolumeName
        bcc     :+
        lda     #ERR_DUPLICATE_FILENAME
        jsr     ShowAlert
        jmp     loop2
:
.endscope

        ;; --------------------------------------------------
        ;; Confirm operation
.scope
        COPY_STRING text_input_buf, main::filename_buf

        CLEAR_BIT7_FLAG has_input_field_flag
        jsr     SetPortAndClear
        MGTK_CALL MGTK::PaintRect, ok_button::rect
        MGTK_CALL MGTK::PaintRect, cancel_button::rect

        lda     unit_num
        jsr     GetVolName      ; populates `ovl_string_buf`

        push16  #ovl_string_buf
        FORMAT_MESSAGE 1, aux::str_confirm_erase_format
        param_call ShowAlertParams, AlertButtonOptions::OKCancel, text_input_buf
        cmp     #kAlertResultOK
        jne     cancel
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
.endproc ; PromptForDeviceAndName

;;; ============================================================
;;; Format Disk

.proc FormatDisk
        clc                     ; C=0 = format
        jsr     PromptForDeviceAndName
        bcs     finish
        sta     unit_num

        ;; --------------------------------------------------
        ;; Proceed with format
retry:
        jsr     SetPortAndClear
        param_call main::DrawDialogLabel, 1, aux::str_formatting
        param_call main::DrawDialogLabel, 7, aux::str_tip_prodos
        jsr     main::SetCursorWatch

        unit_num := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     CheckSupportsFormat
        and     #$FF
        bne     l9
        lda     unit_num
        jsr     FormatUnit
        bcs     l12
l9:
        lda     unit_num
        jmp     ::FormatEraseOverlay::EraseDisk::EP2

l12:    pha
        jsr     main::SetCursorPointer
        pla
    IF A = #ERR_WRITE_PROTECTED

        jsr     ShowAlert
        ASSERT_NOT_EQUALS ::kAlertResultCancel, 0
        bne     finish          ; `kAlertResultCancel` = 1
        beq     retry           ; `kAlertResultTryAgain` = 0
    END_IF

        param_call ShowAlertParams, AlertButtonOptions::TryAgainCancel, aux::str_formatting_error
        cmp     #kAlertResultCancel
        bne     retry

finish:
        pha
        jsr     main::SetCursorPointer
        MGTK_CALL MGTK::CloseWindow, winfo_prompt_dialog
        jsr     main::ClearUpdates

        ldx     unit_num
        pla
        rts
.endproc ; FormatDisk

;;; ============================================================
;;; Erase Disk

.proc EraseDisk
        sec                     ; C=1 = erase
        jsr     PromptForDeviceAndName
        bcs     finish

;;; Entry point used after `FormatDisk`
EP2:
        sta     unit_num

        ;; --------------------------------------------------
        ;; Proceed with erase
retry:
        jsr     SetPortAndClear
        param_call main::DrawDialogLabel, 1, aux::str_erasing
        param_call main::DrawDialogLabel, 7, aux::str_tip_prodos
        jsr     main::SetCursorWatch

        ldxy    #main::filename_buf
        unit_num := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     WriteHeaderBlocks
        pha
        jsr     main::SetCursorPointer
        pla
    IF ZERO
        lda     #$00
        beq     finish          ; always
    END_IF

    IF A = #ERR_WRITE_PROTECTED

        jsr     ShowAlert
        ASSERT_NOT_EQUALS ::kAlertResultCancel, 0
        bne     finish          ; `kAlertResultCancel` = 1
        beq     retry           ; `kAlertResultTryAgain` = 0
    END_IF

        param_call ShowAlertParams, AlertButtonOptions::TryAgainCancel, aux::str_erasing_error
        cmp     #kAlertResultCancel
        bne     retry

finish:
        pha
        jsr     main::SetCursorPointer
        MGTK_CALL MGTK::CloseWindow, winfo_prompt_dialog
        jsr     main::ClearUpdates

        ldx     unit_num
        pla
        rts
.endproc ; EraseDisk

;;; ============================================================

.proc SetPortAndClear
        jsr     main::SetPortForDialogWindow
        MGTK_CALL MGTK::PaintRect, aux::clear_dialog_labels_rect
        rts
.endproc ; SetPortAndClear

;;; ============================================================

;;; Output: N=0 if there is a valid selection, N=1 if no selection
;;; A,X,Y unmodified
.proc ValidSelection
        bit     vol_picker_record::selected_index
        rts
.endproc ; ValidSelection

;;; ============================================================

.proc HandleClick
        COPY_STRUCT screentowindow_params::window, vol_picker_params::coords
        OPTK_CALL OPTK::Click, vol_picker_params
    IF NC
        jsr     DetectDoubleClick
      IF NC
        pha
        BTK_CALL BTK::Flash, ok_button
        pla
      END_IF
    END_IF
        rts
.endproc ; HandleClick

;;; ============================================================

.proc HandleKey
    IF A IN #CHAR_UP, #CHAR_DOWN, #CHAR_LEFT, #CHAR_RIGHT
        sta     vol_picker_params::key
        OPTK_CALL OPTK::Key, vol_picker_params
    END_IF

        return8 #$FF
.endproc ; HandleKey

;;; ============================================================

;;; Input: A = index
;;; Output: N=0 if valid entry
.proc IsEntryCallback
        cmp     DEVCNT          ; num volumes - 1
        beq     yes             ; TODO: `BGT` ?
        bcs     no
yes:    lda     #$00
        rts
no:     lda     #$80
        rts
.endproc ; IsEntryCallback

.proc DrawEntryCallback
        ;; Reverse order, so boot volume is first
        sta     index
        lda     DEVCNT
        sec
        index := *+1
        sbc     #SELF_MODIFIED_BYTE

        jsr     GetDeviceNameForIndex
        jmp     main::DrawString
.endproc ; DrawEntryCallback

.proc SelChangeCallback
        jmp     main::UpdateOKButton
.endproc ; SelChangeCallback

;;; ============================================================

;;; Input: A = index in `DEVLST`
;;; Output: A,X = device name
.proc GetDeviceNameForIndex
        asl     a
        tay
        ldax    device_name_table,y ; now A,X has pointer
        rts
.endproc ; GetDeviceNameForIndex

;;; ============================================================
;;; Gets the selected unit number from `DEVLST`
;;; Output: A = unit number (with low nibble intact)
;;; Assert: `vol_picker_record::selected_index` is valid (i.e. not $FF)

.proc GetSelectedUnitNum
        ;; Reverse order, so boot volume is first
        lda     DEVCNT
        sec
        sbc     vol_picker_record::selected_index
        tax
        lda     DEVLST,x
        and     #UNIT_NUM_MASK
        rts
.endproc ; GetSelectedUnitNum

;;; ============================================================
;;; Inputs: A = unit number (no need to mask off low nibble), X,Y = name
;;; Outputs: C=1 if there's a duplicate, C=0 otherwise

.proc CheckConflictingVolumeName
        ptr := $06
        stxy    ptr
        sta     unit_num

        ;; Copy name, prepending '/'
        ldy     #0
        lda     (ptr),y
        tay
    DO
        copy8   (ptr),y, path+1,y
        dey
    WHILE POS
        clc
        adc     #1
        sta     path
        copy8   #'/', path+1

        MLI_CALL GET_FILE_INFO, get_file_info_params
    IF CC
        ;; A volume with that name exists... but is it the one
        ;; we're about to format/erase?
        lda     DEVNUM
        unit_num := *+1
        cmp     #SELF_MODIFIED_BYTE
      IF NE
        ;; Not the same device, so a match. Return C=1
        sec
        rts
      END_IF
    END_IF

        ;; No match we care about, so return C=0.
        clc
        rts
.endproc ; CheckConflictingVolumeName

;;; ============================================================

        ;; Used to get current volume name (if a ProDOS volume)
        DEFINE_ON_LINE_PARAMS on_line_params,, on_line_buffer

        DEFINE_READWRITE_BLOCK_PARAMS read_block_params, read_buffer, 0
        DEFINE_READWRITE_BLOCK_PARAMS write_block_params, prodos_loader_blocks, 0

        ;; Used to check for existing volume with same name
        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, path

on_line_buffer:
path:
        .res    17,0            ; length + '/' + 15-char name

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
.endproc ; GetDriverAddress

;;; ============================================================
;;; Format disk
;;; Input: A = unit number

.proc FormatUnit
        sta     unit_num

        jsr     main::IsDiskII
    IF EQ
        ;; Format as Disk II
        lda     unit_num
        jmp     FormatDiskII
    END_IF

        ;; Format using driver
        lda     unit_num
        jsr     GetDriverAddress
        stax    driver_addr

        sta     ALTZPOFF        ; Main ZP/LCBANKs

        copy8   #DRIVER_COMMAND_FORMAT, DRIVER_COMMAND
        unit_num := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     DRIVER_UNIT_NUMBER

        driver_addr := *+1
        jsr     SELF_MODIFIED

        sta     ALTZPON         ; Aux ZP/LCBANKs

        rts
.endproc ; FormatUnit

;;; ============================================================
;;; Check if the device supports formatting
;;; Input: A = unit number (with low nibble intact)
;;; Output: A=0/Z=1/N=0 if yes, A=$FF/Z=0/N=1 if no

.proc CheckSupportsFormat
        sta     unit_num

        jsr     main::IsDiskII
    IF NE
        ;; Check if the driver is firmware ($CnXX).
        lda     unit_num
        jsr     GetDriverAddress
        stx     addr+1          ; self-modify address below
        txa                     ; high byte
        and     #$F0            ; look at high nibble
        cmp     #$C0            ; firmware? ($Cn)
      IF EQ                     ; TODO: Should we guess yes or no here???
        ;; Check the firmware status byte
        addr := *+1
        lda     $C0FE           ; $CnFE, high byte is self-modified above
        and     #%00001000      ; Bit 3 = Supports format
       IF ZERO

        return8 #$FF            ; no, does not support format
       END_IF
      END_IF
    END_IF

        return8 #$00            ; yes, supports format

unit_num:
        .byte   0
.endproc ; CheckSupportsFormat

;;; ============================================================
;;; Write the loader, volume directory, and volume bitmap
;;; Inputs: A = unit number, X,Y = volume name

.proc WriteHeaderBlocks
        sta     unit_num
        sta     write_block_params::unit_num
        stxy    $06

        ;; Copy name into volume directory key block data
        param_call main::CopyPtr1ToBuf, vol_name_buf

        ldx     #DeskTopSettings::options
        jsr     ReadSetting
        and     #DeskTopSettings::kOptionsSetCaseBits
    IF ZERO
        ldax    #0
    ELSE
        param_call_indirect main::CalculateCaseBits, $06
    END_IF
        stax    case_bits

        param_call main::UpcaseString, vol_name_buf

        ;; --------------------------------------------------
        ;; Get the block count for the device

        ;; Check if it's a Disk II
        lda     unit_num
        jsr     main::IsDiskII
    IF NE
        ;; Not Disk II - use the driver.
        lda     unit_num
        jsr     GetDriverAddress
        stax    @driver

        sta     ALTZPOFF        ; Main ZP/LCBANKs

        copy8   #DRIVER_COMMAND_STATUS, DRIVER_COMMAND
        copy8   unit_num, DRIVER_UNIT_NUMBER
        copy16  #0, DRIVER_BLOCK_NUMBER

        @driver := *+1
        jsr     SELF_MODIFIED

        sta     ALTZPON         ; Aux ZP/LCBANKs

        bcc     got_blocks      ; success
        jmp     fail            ; failure
    END_IF

        ldxy    #kDefaultFloppyBlocks
got_blocks:
        stxy    total_blocks

        ;; --------------------------------------------------
        ;; Loader blocks

        ;; Write first block of loader
        copy16  #prodos_loader_blocks, write_block_params::data_buffer
        copy16  #0, write_block_params::block_num
        MLI_CALL WRITE_BLOCK, write_block_params
        jcs     fail2

        ;; Write second block of loader
        inc     write_block_params::block_num     ; next block needs...
        inc     write_block_params::data_buffer+1 ; next $200 of data
        inc     write_block_params::data_buffer+1
        jsr     WriteBlockAndZero

        ;; --------------------------------------------------
        ;; Volume directory key block

        copy16  #block_buffer, write_block_params::data_buffer
        copy8   #3, block_buffer+2 ; block 2, points at 3

        ldy     vol_name_buf    ; volume name
        tya
        ora     #ST_VOLUME_DIRECTORY << 4
        sta     block_buffer + VolumeDirectoryHeader::storage_type_name_length
    DO
        copy8   vol_name_buf,y, block_buffer + VolumeDirectoryHeader::file_name - 1,y
        dey
    WHILE NOT_ZERO

        ldy     #kNumKeyBlockHeaderBytes-1 ; other header bytes
    DO
        copy8   key_block_header_bytes,y, block_buffer+kKeyBlockHeaderOffset,y
        dey
    WHILE POS

        MLI_CALL GET_TIME       ; Apply timestamp
        ldy     #3
    DO
        copy8   DATELO,y, block_buffer + VolumeDirectoryHeader::creation_date,y
        dey
    WHILE POS

        copy16  case_bits, block_buffer + VolumeDirectoryHeader::case_bits

        jsr     WriteBlockAndZero

        ;; Subsequent volume directory blocks (4 total)
        copy8   #2, block_buffer ; block 3, points at 2 and 4
        copy8   #4, block_buffer+2
        jsr     WriteBlockAndZero

        copy8   #3, block_buffer ; block 4, points at 3 and 5
        copy8   #5, block_buffer+2
        jsr     WriteBlockAndZero

        copy8   #4, block_buffer ; block 4, points back at 4
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
    DO

        jsr     _BuildBlock     ; Build a bitmap for the current block

        lda     write_block_params::block_num+1 ; Are we at a block >255?
        bne     fail            ; Then something's gone horribly wrong and we need to stop
        lda     write_block_params::block_num
        cmp     #6              ; Are we anywhere other than block 6?
        bne     gowrite         ; Then go ahead and write the bitmap block as-is

        ;; Block 6 - Set up the volume bitmap to protect the blocks at the beginning of the volume
        copy8   #$01, block_buffer ; Mark blocks 0-6 in use
        lda     lastblock       ; What's the last block we need to protect?
        cmp     #7
        bcc     gowrite         ; If it's less than 7, default to always protecting 0-6

        copy8   #$00, block_buffer ; Otherwise (>=7) mark blocks 0-7 as "in use"
        lda     lastblock       ; and check again
      IF A < #15                ; Is it 15 or more? Skip ahead.
        and     #$07            ; Otherwise (7-14) take the low three bits
        tax
        lda     freemask,x      ; convert them to the correct VBM value using a lookup table
        sta     block_buffer+1  ; put it in the bitmap
        bcc     gowrite         ; and write the block
      END_IF

        copy8   #$00, block_buffer+1 ; (>=15) Mark blocks 8-15 as "in use"
        lda     lastblock       ; Then finally
        and     #$07            ; take the low three bits
        tax
        lda     freemask,x      ; convert them to the correct VBM value using a lookup table
        sta     block_buffer+2  ; put it in the bitmap, and fall through to the write

        ;; Call the write/increment/zero routine, and loop back if we're not done
gowrite:
        jsr     WriteBlockAndZero
        lda     lastblock
    WHILE A >= write_block_params::block_num

        ;; Success
        lda     #$00
        sta     $08
        clc
        rts

fail:   sec
        rts

unit_num:
        .byte   0

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

.proc _BuildBlock
        ldy     #$00
        lda     #$FF
    DO
        sta     block_buffer,y  ; Fill this entire block
        sta     block_buffer+$100,y ; with $FF bytes
        iny
    WHILE NOT_ZERO

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
.endproc ; _BuildBlock

.endproc ; WriteHeaderBlocks

;;; ============================================================

pop_and_fail:
        pla
        pla
fail2:
        sec
        rts

;;; ============================================================

.proc WriteBlockAndZero
        MLI_CALL WRITE_BLOCK, write_block_params
        bcs     pop_and_fail
        jsr     zero_buffers
        inc     write_block_params::block_num
        rts

zero_buffers:
        ldy     #0
        tya
    DO
        sta     block_buffer,y
        sta     block_buffer+$100,y
        dey
    WHILE NOT_ZERO
        rts
.endproc ; WriteBlockAndZero

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
        .res    16,0

case_bits:
        .word   0

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

.proc GetNonProDOSVolName
        kPascalSig1  = $E0
        kPascalSig2a = $70
        kPascalSig2b = $60
        kDOS33Sig1   = $A5
        kDOS33Sig2   = $27

        ;; Read block 0
        sta     read_block_params::unit_num
        copy16  #0, read_block_params::block_num
        MLI_CALL READ_BLOCK, read_block_params
    IF CC
        lda     read_buffer + 1
      IF A <> #kPascalSig1      ; DOS 3.3?
        jmp     maybe_dos       ; Maybe...
      END_IF

        lda     read_buffer + 2
        cmp     #kPascalSig2a
        beq     pascal
        cmp     #kPascalSig2b
        beq     pascal
        FALL_THROUGH_TO unknown
    END_IF

        ;; Unknown, just use slot and drive
unknown:
        lda     read_block_params::unit_num
        jsr     _GetSlotNum
        phax

        lda     read_block_params::unit_num
        jsr     _GetDriveNum
        phax

        FORMAT_MESSAGE 2, the_disk_in_slot_format
        COPY_STRING text_input_buf, ovl_string_buf
        rts

        ;; Pascal
pascal: param_call pascal_disk, ovl_string_buf
        jmp     EnquoteStringBuf

        ;; Maybe DOS 3.3, not sure yet...
maybe_dos:
        cmp     #kDOS33Sig1
        bne     unknown
        lda     read_buffer + 2
        cmp     #kDOS33Sig2
        bne     unknown

        ;; DOS 3.3, use slot and drive
        lda     read_block_params::unit_num
        jsr     _GetSlotNum
        phax

        lda     read_block_params::unit_num
        jsr     _GetDriveNum
        phax

        FORMAT_MESSAGE 2, the_dos_33_disk_format
        COPY_STRING text_input_buf, ovl_string_buf
        rts

;;; Returns slot number in A,X
.proc _GetSlotNum
        ldx     #0              ; hi
        and     #$70
        lsr     a
        lsr     a
        lsr     a
        lsr     a               ; lo
        rts
.endproc ; _GetSlotNum

;;; Returns the drive number in A,X
.proc _GetDriveNum
        ldx     #0              ; hi
        asl     a               ; drive bit into C
        txa
        adc     #1              ; lo
        rts
.endproc ; _GetDriveNum

;;; Handle Pascal disk - name suffixed with ':'
pascal_disk:
        copy16  #kVolumeDirKeyBlock, read_block_params::block_num
        MLI_CALL READ_BLOCK, read_block_params
    IF CS
        ;; Pascal disk, empty name - use " :" (weird, but okay?)
        copy8   #2, ovl_string_buf
        copy8   #' ', ovl_string_buf+1
        copy8   #':', ovl_string_buf+2
        rts
    END_IF

        ;; Pascal disk, use name
        lda     read_buffer + 6
        tax
    DO
        copy8   read_buffer + 6,x, ovl_string_buf,x
        dex
    WHILE POS
        inc     ovl_string_buf
        ldx     ovl_string_buf
        copy8   #':', ovl_string_buf,x
        rts
.endproc ; GetNonProDOSVolName

;;; ============================================================
;;; Get a volume name, for ProDOS or non-ProDOS disk.
;;; Input: A = unit number
;;; Output: `ovl_string_buf` is populated

.proc GetVolName
        sta     on_line_params::unit_num
        MLI_CALL ON_LINE, on_line_params
        bcs     non_pro
        lda     on_line_buffer
        and     #NAME_LENGTH_MASK
        beq     non_pro

        param_call AdjustOnLineEntryCase, on_line_buffer

        ldx     on_line_buffer
    DO
        copy8   on_line_buffer,x, ovl_string_buf,x
        dex
    WHILE POS

        jmp     EnquoteStringBuf

non_pro:
        lda     on_line_params::unit_num
        jmp     GetNonProDOSVolName
.endproc ; GetVolName

;;; ============================================================

.proc EnquoteStringBuf
        ldx     ovl_string_buf
    DO
        copy8   ovl_string_buf,x, ovl_string_buf+1,x
        dex
    WHILE NOT_ZERO

        ldx     ovl_string_buf
        inx
        inx
        lda     #'"'            ; " (balance quotes for some text editors)
        sta     ovl_string_buf,x
        sta     ovl_string_buf+1
        stx     ovl_string_buf
        rts
.endproc ; EnquoteStringBuf

;;; ============================================================

.endscope ; FormatEraseOverlay

        ENDSEG OverlayFormatErase
