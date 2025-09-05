;;; ============================================================
;;; DeskTop - Initialization
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

;;; ============================================================
;;; Segment loaded into MAIN $800-$FFF
;;; ============================================================

;;;            Main                  Aux
;;;       :.............:       :.............:
;;;       |.............|       |.............|
;;;       |.............|       |.............|
;;;       |.Graphics....|       |.Graphics....|
;;; $2000 +-------------+       +-------------+
;;;       | I/O Buffer  |       |             |
;;; $1C00 +-------------+       |             |
;;;       |             |       |             |
;;;       |             |       |             |
;;;       |             |       |             |
;;;       |             |       |             |
;;;       |             |       |             |
;;; $1600 +-------------+       |             |
;;;       | Data Buffer |       |             |
;;; $1200 +-------------+       |             |
;;;       |             |       |             |
;;;       | Code        |       |             |
;;; $0800 +-------------+       +-------------+
;;;       |.............|       |.............|
;;;       :.............:       :.............:


;;; NOTE: if DeskTop file is extended in length, there is room for
;;; this segment to grow by moving buffers up by a few pages.

;;; Init sequence - machine identification, etc
;;;
;;; * Hook reset vector
;;; * Clear hires screen
;;; * Detect machine type
;;; * Preserve DEVLST, remove /RAM
;;; * Initialize MGTK, with saved settings
;;; * Load selector list, populate Selector menu
;;; * Enumerate desk accessories, populate Apple menu
;;; * Compute label widths
;;; * Create desktop icons, populate device name table
;;; * Populate startup menu
;;; * Identify removable disks, for later polling
;;; * Configure MGTK
;;; * Restore saved windows


        BEGINSEG SegmentInitializer

.scope init

        MLIEntry  := main::MLIRelayImpl
        MGTKEntry := MGTKRelayImpl
        ITKEntry  := ITKRelayImpl

        data_buf := $1200
        kDataBufferSize = $400

start:

;;; ============================================================
;;; Set the reset vector to cold start
.scope hook_reset_vector

        ;; Main hook
        lda     #<main::ResetHandler
        sta     SOFTEV
        lda     #>main::ResetHandler
        sta     SOFTEV+1
        eor     #$A5
        sta     SOFTEV+2

.endscope ; hook_reset_vector

;;; ============================================================
;;; Clear DHR screen to black before it is shown

        jsr     ClearDHRToBlack

;;; ============================================================
;;; Detect Machine Type - set flags and periodic task delay

;;; NOTE: Starts with ROM paged in, exits with LCBANK1 paged in.

.scope machine_type
        ;; See Apple II Miscellaneous #7: Apple II Family Identification

        ;; Now stash the bytes we need
        copy8   VERSION, tmp_version  ; $06 = IIe or later
        copy8   ZIDBYTE, tmp_idbyte   ; $00 = IIc or later

        ;; ... and page in LCBANK1
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        ;; State needed by MGTK
        tmp_version := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     startdesktop_params::machine
        tmp_idbyte := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     startdesktop_params::subid

        ;; Model?
        ldx     #DeskTopSettings::system_capabilities
        jsr     ReadSetting

        tax                     ; A = X = kSysCapXYZ bitmap
        ora     #DeskTopSettings::kSysCapIsIIgs | DeskTopSettings::kSysCapIsLaser128
    IF_NOT_ZERO
        lda     #kPeriodicTaskDelayIIgs
        bne     end                     ; always
    END_IF

        txa                     ; A = X = kSysCapXYZ bitmap
        ora     #DeskTopSettings::kSysCapIsIIc
    IF_NOT_ZERO
        lda     #kPeriodicTaskDelayIIc
        bne     end                     ; always
    END_IF

        ;; Default
        lda     #kPeriodicTaskDelayIIe
end:
        sta     periodic_task_delay

        ;; Fall through
.endscope ; machine_type

;;; ============================================================
;;; Snapshot state of PB2 (shift key mod)

.scope pb2_state
        copy8   BUTN2, pb2_initial_state
        ;; fall through
.endscope ; pb2_state

;;; ============================================================
;;; Back up DEVLST

.scope
        ;; Make a copy of the original device list
        .assert DEVLST = DEVCNT+1, error, "DEVCNT must precede DEVLST"
        ldx     DEVCNT          ; number of devices
        inx                     ; include DEVCNT itself
    DO
        copy8   DEVLST-1,x, main::devlst_backup,x ; DEVCNT is at DEVLST-1
        dex
    WHILE_POS
        ;; fall through
.endscope

;;; ============================================================
;;; Make startup volume first in list

.scope
        ;; Find the startup volume's unit number
        copy8   DEVNUM, target
        jsr     main::GetCopiedToRAMCardFlag
    IF_NS
        param_call main::CopyDeskTopOriginalPrefix, INVOKER_PREFIX
        MLI_CALL GET_FILE_INFO, main::src_file_info_params
      IF_CC
        copy8   DEVNUM, target
      END_IF
    END_IF

        ;; Find the device's index in the list
        ldx     #0
    DO
        lda     DEVLST,x
        and     #UNIT_NUM_MASK  ; to compare against DEVNUM
        target := *+1
        cmp     #SELF_MODIFIED_BYTE
        beq     found
        inx
    WHILE_X_LT  DEVCNT
        bcs     done            ; last one or not found

        ;; Save it
found:  ldy     DEVLST,x

        ;; Move everything up
    DO
        copy8   DEVLST+1,x, DEVLST,x
        inx
    WHILE_X_NE  DEVCNT

        ;; Place it at the end
        tya
        sta     DEVLST,x

done:
.endscope

;;; ============================================================

        jsr     DisconnectRAM

;;; ============================================================
;;; Initialize MGTK

.scope
        ;; Copy pattern from settings to somewhere MGTK can see
        tmp_pattern := $00
        ldx     #DeskTopSettings::pattern + .sizeof(MGTK::Pattern)-1
    DO
        jsr     ReadSetting
        sta     tmp_pattern - DeskTopSettings::pattern,x
        dex
    WHILE_X_NE  #AS_BYTE(DeskTopSettings::pattern-1)

        MGTK_CALL MGTK::SetZP1, setzp_params_nopreserve
        MGTK_CALL MGTK::SetDeskPat, tmp_pattern
        MGTK_CALL MGTK::StartDeskTop, startdesktop_params
        MGTK_CALL MGTK::InitMenu, initmenu_params
        jsr     main::SetRGBMode
        MGTK_CALL MGTK::SetMenu, aux::desktop_menu
        jsr     main::ShowClock

        lda     startdesktop_params::slot_num
    IF_ZERO
        ldx     #DeskTopSettings::options
        jsr     ReadSetting
        ora     #DeskTopSettings::kOptionsShowShortcuts
        jsr     WriteSetting
    END_IF

        copy8   #$80, main::mli_relay_checkevents_flag

        ;; --------------------------------------------------
        ;; Cursor tracking

        ;; Doubled if option selected
        ldx     #DeskTopSettings::mouse_tracking
        jsr     ReadSetting
    IF_NOT_ZERO
        inc     scalemouse_params::x_exponent
        inc     scalemouse_params::y_exponent
    END_IF

        ;; Also doubled if a IIc
        ldx     #DeskTopSettings::system_capabilities
        jsr     ReadSetting
        and     #DeskTopSettings::kSysCapIsIIc
    IF_NOT_ZERO
        inc     scalemouse_params::x_exponent
        inc     scalemouse_params::y_exponent
    END_IF
        MGTK_CALL MGTK::ScaleMouse, scalemouse_params

        ;; --------------------------------------------------

        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch
        MGTK_CALL MGTK::ShowCursor

        ;; fall through
.endscope

;;; ============================================================
;;; Initialize IconTK

.scope
        ITK_CALL IconTK::InitToolKit, itkinit_params

        FALL_THROUGH_TO CreateTrashIcon
.endscope

;;; ============================================================

.proc CreateTrashIcon
        ptr := $6

        copy8   #0, cached_window_id
        lda     #1
        sta     cached_window_entry_count
        sta     icon_count
        ITK_CALL IconTK::AllocIcon, get_icon_entry_params
        lda     get_icon_entry_params::id
        sta     main::trash_icon_num
        sta     cached_window_entry_list
        ldax    get_icon_entry_params::addr
        stax    ptr

        ;; Trash is a drop target
        ldy     #IconEntry::win_flags
        copy8   #kIconEntryFlagsDropTarget|kIconEntryFlagsNotDropSource, (ptr),y

        ldy     #IconEntry::iconx
        copy16in #main::kTrashIconX, (ptr),y
        ldy     #IconEntry::icony
        copy16in #main::kTrashIconY, (ptr),y
        ldy     #IconEntry::type
        copy8   #IconType::trash, (ptr),y

        iny
        ldx     #0
    DO
        copy8   trash_name,x, (ptr),y
        iny
        inx
    WHILE_X_NE  trash_name
        copy8   trash_name,x, (ptr),y

        FALL_THROUGH_TO LoadSelectorList
.endproc ; CreateTrashIcon

;;; ============================================================


;;; See docs/Selector_List_Format.md for file format

.proc LoadSelectorList
        ptr1 := $6
        ptr2 := $8

        selector_list_io_buf := IO_BUFFER
        selector_list_data_buf := data_buf
        .assert kSelectorListShortSize <= kDataBufferSize, error, "Buffer size error"

        MGTK_CALL MGTK::CheckEvents

        copy8   #0, index
        jsr     _ReadSelectorList
        jne     done

        lda     selector_list_data_buf + kSelectorListNumPrimaryRunListOffset
        clc
        adc     selector_list_data_buf + kSelectorListNumSecondaryRunListOffset
        sta     num_selector_list_items

        copy8   selector_list_data_buf, count
L0A3B:  lda     index
        cmp     count
        beq     done

        ;; Copy entry name into place
        jsr     main::ATimes16
        addax   #selector_list_data_buf + kSelectorListEntriesOffset, ptr1
        lda     index
        jsr     main::ATimes16
        addax   #run_list_entries, ptr2
        jsr     _CopyPtr1ToPtr2

        ;; Copy entry flags into place
        ldy     #15
        copy8   (ptr1),y, (ptr2),y

        ;; Copy entry path into place
        lda     index
        jsr     main::ATimes64
        addax   #selector_list_data_buf + kSelectorListPathsOffset, ptr1
        lda     index
        jsr     main::ATimes64
        addax   #main::run_list_paths, ptr2
        jsr     _CopyPtr1ToPtr2

        inc     index
        inc     selector_menu
        jmp     L0A3B

done:   jmp     end

index:  .byte   0
count:  .byte   0

.proc _CopyPtr1ToPtr2
        ptr1 := $06
        ptr2 := $08

        ldy     #0
        lda     (ptr1),y
        tay
    DO
        copy8   (ptr1),y, (ptr2),y
        dey
    WHILE_POS
        rts
.endproc ; _CopyPtr1ToPtr2

;;; --------------------------------------------------

        DEFINE_OPEN_PARAMS open_params, str_selector_list, selector_list_io_buf

str_selector_list:
        PASCAL_STRING kPathnameSelectorList

        DEFINE_READWRITE_PARAMS read_params, selector_list_data_buf, kSelectorListShortSize
        DEFINE_CLOSE_PARAMS close_params

.proc _ReadSelectorList
        MLI_CALL OPEN, open_params
        bcs     _WriteSelectorList

        lda     open_params::ref_num
        sta     read_params::ref_num
        MLI_CALL READ, read_params
        MLI_CALL CLOSE, close_params
        rts
.endproc ; _ReadSelectorList

        DEFINE_CREATE_PARAMS create_params, str_selector_list, ACCESS_DEFAULT, $F1
        DEFINE_READWRITE_PARAMS write_params, selector_list_data_buf, kSelectorListShortSize

.proc _WriteSelectorList
        ptr := $06

        ;; Clear buffer
        copy16  #selector_list_data_buf, ptr
        ldx     #>kSelectorListShortSize ; number of pages
        lda     #0
    DO
        ldy     #0
      DO
        sta     (ptr),y
        dey
      WHILE_NOT_ZERO
        inc     ptr+1
        dex
    WHILE_NOT_ZERO

        ;; Write out file
        MLI_CALL CREATE, create_params
        bcs     done
        MLI_CALL OPEN, open_params
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        MLI_CALL WRITE, write_params ; two blocks of $400
        MLI_CALL WRITE, write_params
        MLI_CALL CLOSE, close_params

done:   rts
.endproc ; _WriteSelectorList

end:
        ;; No separator if it is last
        lda     selector_menu
    IF_A_EQ     #kSelectorMenuFixedItems
        dec     selector_menu
    END_IF

.endproc ; LoadSelectorList

;;; ============================================================
;;; Enumerate Desk Accessories

.scope
        MGTK_CALL MGTK::CheckEvents

        read_dir_buffer := data_buf

        ;; Does the directory exist?
        MLI_CALL GET_FILE_INFO, get_file_info_params
        jcs     end

        lda     get_file_info_type
        cmp     #FT_DIRECTORY
        beq     open_dir
        jmp     end

open_dir:
        MLI_CALL OPEN, open_params
        lda     open_ref_num
        sta     read_ref_num
        sta     close_ref_num
        MLI_CALL READ, read_params

        lda     #0
        sta     entry_num
        sta     desk_acc_num

        copy8   #1, entry_in_block ; First block has header instead of entry

        lda     read_dir_buffer + SubdirectoryHeader::file_count
        and     #$7F
        sta     file_count

        copy8   read_dir_buffer + SubdirectoryHeader::entries_per_block, entries_per_block
        copy8   read_dir_buffer + SubdirectoryHeader::entry_length, entry_length

        dir_ptr := $06
        da_ptr := $08

        copy16  #read_dir_buffer + .sizeof(SubdirectoryHeader), dir_ptr

process_block:
        param_call_indirect AdjustFileEntryCase, dir_ptr

        ldy     #FileEntry::storage_type_name_length
        lda     (dir_ptr),y
        and     #NAME_LENGTH_MASK
        jeq     next_entry

        inc     entry_num

        ;; Hide invisible files
        ldy     #FileEntry::access
        lda     (dir_ptr),y
        and     #ACCESS_I
        jne     next_entry

        ldy     #FileEntry::file_type
        lda     (dir_ptr),y
    IF_A_EQ     #kDAFileType    ; DA? (must match type/auxtype)
        ldy     #FileEntry::aux_type
        lda     (dir_ptr),y
        cmp     #<kDAFileAuxType
        jne     next_entry
        iny
        lda     (dir_ptr),y
        cmp     #>kDAFileAuxType
        jne     next_entry
    END_IF

        ;; Allow anything else

        ;; Compute slot in DA name table
        ldy     desk_acc_num
        ldax    #kDAMenuItemSize
        jsr     Multiply_16_8_16
        addax   #desk_acc_names, da_ptr

        ;; Copy name
        ldy     #FileEntry::storage_type_name_length
        lda     (dir_ptr),y
        and     #NAME_LENGTH_MASK
        sta     name_buf
        tay
    DO
        copy8   (dir_ptr),y, name_buf,y
        dey
    WHILE_NOT_ZERO

        ;; If a directory, prepend name with folder glyphs
        ldy     #FileEntry::file_type
        lda     (dir_ptr),y
    IF_A_EQ     #FT_DIRECTORY   ; Directory?
        ldy     name_buf
      DO
        copy8   name_buf,y, name_buf+3,y
        dey
      WHILE_NOT_ZERO

        copy8   #kGlyphFolderLeft, name_buf+1
        copy8   #kGlyphFolderRight, name_buf+2
        copy8   #kGlyphSpacer, name_buf+3
        inc     name_buf
        inc     name_buf
        inc     name_buf
    END_IF

        ;; Convert periods to spaces, copy into menu
        ldy     #0
        copy8   name_buf,y, (da_ptr),y
        tay
    DO
        lda     name_buf,y
      IF_A_EQ   #'.'
        lda     #' '
      END_IF
        sta     (da_ptr),y
        dey
    WHILE_NOT_ZERO

        inc     desk_acc_num
        inc     apple_menu      ; number of menu items

next_entry:
        ;; Room for more DAs?
        lda     desk_acc_num
        cmp     #kMaxDeskAccCount
        jcs     close_dir

        ;; Any more entries in dir?
        lda     entry_num
        cmp     file_count
        jeq     close_dir

        ;; Any more entries in block?
        inc     entry_in_block
        lda     entry_in_block
    IF_A_EQ     entries_per_block
        MLI_CALL READ, read_params
        copy16  #read_dir_buffer + 4, dir_ptr

        copy8   #0, entry_in_block
        jmp     process_block
    END_IF

        add16_8 dir_ptr, entry_length
        jmp     process_block

close_dir:
        MLI_CALL CLOSE, close_params
        jmp     end

        DEFINE_OPEN_PARAMS open_params, str_desk_acc, IO_BUFFER
        open_ref_num := open_params::ref_num

        .assert BLOCK_SIZE <= kDataBufferSize, error, "Buffer size error"
        DEFINE_READWRITE_PARAMS read_params, read_dir_buffer, BLOCK_SIZE
        read_ref_num := read_params::ref_num

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, str_desk_acc
        get_file_info_type := get_file_info_params::file_type

        DEFINE_CLOSE_PARAMS close_params
        close_ref_num := close_params::ref_num

str_desk_acc:
        PASCAL_STRING kFilenameDADir

file_count:     .byte   0
entry_num:      .byte   0
desk_acc_num:   .byte   0
entry_length:   .byte   0
entries_per_block:      .byte   0
entry_in_block: .byte   0

name_buf:       .res    ::kDAMenuItemSize, 0

end:
        ;; No separator if it is last
        lda     apple_menu
    IF_A_EQ     #kAppleMenuFixedItems
        dec     apple_menu
    END_IF

.endscope

;;; ============================================================
;;; Populate volume icons and device names

;;; TODO: Dedupe with CmdCheckDrives

.scope
        devname_ptr := $08

        ldy     #0
        sty     main::pending_alert

        ;; Enumerate DEVLST in reverse order (most important volumes first)
        copy8   DEVCNT, device_index

process_volume:
        lda     device_index
        asl     a
        tay
        copy16  device_name_table,y, devname_ptr
        ldy     device_index
        lda     DEVLST,y        ;
        ;; NOTE: Not masked with `UNIT_NUM_MASK`, for `CreateVolumeIcon`.

        pha                     ; save all registers
        txa
        pha
        tya
        pha

        inc     cached_window_entry_count
        inc     icon_count
        lda     DEVLST,y
        jsr     main::CreateVolumeIcon ; A = unmasked unit number, Y = device index
        sta     cvi_result
        MGTK_CALL MGTK::CheckEvents

        pla                     ; restore all registers
        tay
        pla
        tax
        pla

        ;; A = unit number, X = (nothing), Y = device_index

        pha                     ; save unit number on the stack

        lda     cvi_result
    IF_A_EQ     #ERR_DEVICE_NOT_CONNECTED
        ;; If device is not connected, remove it from DEVLST
        ;; unless it's a Disk II.
        ldy     device_index
        lda     DEVLST,y
        ;; NOTE: Not masked with `UNIT_NUM_MASK`, `IsDiskII` handles it.
        jsr     main::IsDiskII
        beq     select_template ; skip
        ldx     device_index
        jsr     RemoveDevice
        jmp     next
    END_IF

    IF_A_EQ     #ERR_DUPLICATE_VOLUME
        copy8   #kErrDuplicateVolName, main::pending_alert
    END_IF

        ;; This section populates device_name_table -
        ;; it determines which device type string to use, and
        ;; fills in slot and drive as appropriate. Used in the
        ;; Format/Erase disk dialog.

select_template:
        pla                     ; unit number into A
        pha

        src := $06

        jsr     main::GetDeviceType
        stax    src             ; A,X = device name (may be empty)

        ;; Empty?
        ldy     #0
        lda     (src),y
    IF_ZERO
        copy16  #str_volume_type_unknown, src
    END_IF

        ;; Set final length
        lda     (src),y         ; Y = 0
        clc
        adc     #kSDPrefixLength
        sta     str_sdname_buffer

        ;; Copy string into template, after prefix
        lda     (src),y         ; Y = 0
        tay                     ; Y = length
    DO
        copy8   (src),y, str_sdname_buffer + kSDPrefixLength,y
        dey
    WHILE_NOT_ZERO              ; leave length alone

        ;; Insert Slot #
        pla                     ; unit number into A
        pha

        and     #%01110000      ; slot (from DSSSxxxx)
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #'0'
        sta     str_sdname_buffer + kDeviceTemplateSlotOffset

        ;; Insert Drive #
        pla                     ; unit number into A
        pha

        rol     a               ; set carry to drive - 1
        lda     #0              ; 0 + carry + '1'
        adc     #'1'            ; convert to '1' or '2'
        sta     str_sdname_buffer + kDeviceTemplateDriveOffset

        ;; Copy name into table
        ldy     str_sdname_buffer
    DO
        copy8   str_sdname_buffer,y, (devname_ptr),y
        dey
    WHILE_POS

next:   pla
        dec     device_index
        lda     device_index

        bmi     PopulateStartupMenu
        jmp     process_volume  ; next!

device_index:
        .byte   0
cvi_result:
        .byte   0
.endscope

;;; ============================================================

        ;; Remove device num in X from devices list
.proc RemoveDevice
        dex
    DO
        inx
        copy8   DEVLST+1,x, DEVLST,x
        copy8   main::device_to_icon_map+1,x, main::device_to_icon_map,x
        cpx     DEVCNT
    WHILE_NOT_ZERO
        dec     DEVCNT

        ;; ProDOS requires an ON_LINE call after a device is
        ;; disconnected in order to clean up the VCB entry. However,
        ;; we only remove devices here if the device already failed an
        ;; ON_LINE call with `ERR_DEVICE_NOT_CONNECTED` so it should
        ;; not be necessary.

        rts
.endproc ; RemoveDevice

;;; ============================================================

.proc PopulateStartupMenu
        slot_ptr := $06         ; pointed at $Cn00
        table_ptr := $08        ; points into slot_string_table

        copy8   #7, slot
        copy8   #0, slot_ptr
        tax                     ; X = menu entry

        ;; Identify ProDOS device in slot by ID bytes
    DO
        lda     slot
        ora     #$C0            ; hi byte of $Cn00
        sta     slot_ptr+1

        ldy     #$01        ; $Cn01 == $20 ?
        lda     (slot_ptr),y
        cmp     #$20
        bne     next

        ldy     #$03        ; $Cn03 == $00 ?
        lda     (slot_ptr),y
        cmp     #$00
        bne     next

        ldy     #$05        ; $Cn05 == $03 ?
        lda     (slot_ptr),y
        cmp     #$03
        bne     next

        ;; It is a ProDOS device - prepare menu item.
        copy8   slot, main::startup_slot_table,x

        txa                     ; pointer to nth sNN string
        pha
        asl     a
        tax
        copy16  slot_string_table,x, table_ptr

        ldy     #kStartupMenuItemSlotOffset
        lda     slot
        ora     #'0'
        sta     (table_ptr),y

        pla
        tax
        inx

next:   dec     slot
    WHILE_NOT_ZERO

        ;; Set number of menu items.
        stx     startup_menu
        jmp     InitializeDisksInDevicesTables

slot:   .byte   0

slot_string_table:
        .addr   startup_menu_item_1
        .addr   startup_menu_item_2
        .addr   startup_menu_item_3
        .addr   startup_menu_item_4
        .addr   startup_menu_item_5
        .addr   startup_menu_item_6
        .addr   startup_menu_item_7
        ASSERT_ADDRESS_TABLE_SIZE slot_string_table, ::kMenuSizeStartup
.endproc ; PopulateStartupMenu

;;; ============================================================
;;; Enumerate DEVLST and find removable devices; build a list of
;;; these, and check to see which have disks in them. The list
;;; will be polled periodically to detect changes and refresh.
;;; List is built in DEVLST order since processing is in
;;; `CheckDisksInDevices` (etc) is done in reverse order.
;;;
;;; Some hardware (machine/slot) combinations are filtered out
;;; due to known-buggy firmware.

.proc InitializeDisksInDevicesTables
        slot_ptr := $0A

        lda     #0
        sta     count
        sta     index

    DO
        ldy     index
        lda     DEVLST,y
        ;; NOTE: Not masked with `UNIT_NUM_MASK`, `DeviceDriverAddress` handles it.
        sta     unit_num
        jsr     main::DeviceDriverAddress
        bvs     append          ; remapped SmartPort, it's usable
        bne     next            ; if RAM-based driver (not $CnXX), skip
        stx     slot_ptr+1      ; just need high byte ($Cn)
        copy8   #0, slot_ptr    ; make $Cn00
        ldy     #$FF            ; Firmware ID byte
        lda     (slot_ptr),y    ; $CnFF: $00=Disk II, $FF=13-sector, else=block
        beq     next
        dey
        lda     (slot_ptr),y    ; $CnFE: Status Byte
        bmi     append          ; bit 7 - Medium is removable

next:   inc     index
        lda     DEVCNT          ; continue while index <= DEVCNT
    WHILE_A_GE  index

        lda     count
        sta     main::removable_device_table
        sta     main::disk_in_device_table
        jsr     main::CheckDisksInDevices

        ;; Make copy of table
        ldx     main::disk_in_device_table
    IF_NOT_ZERO
      DO
        copy8   main::disk_in_device_table,x, main::last_disk_in_devices_table,x
        dex
      WHILE_POS
    END_IF

        jmp     FinalSetup

        DEFINE_SP_STATUS_PARAMS status_params, SELF_MODIFIED_BYTE, dib_buffer, 3 ; Return Device Information Block (DIB)

dib_buffer := ::IO_BUFFER

        ;; Maybe add device to the removable device table
append:
        ;; Do SmartPort STATUS call to filter out 5.25 devices
        lda     unit_num
        jsr     main::FindSmartportDispatchAddress
        bcs     next            ; can't determine address - skip it!
        stax    dispatch
        sty     status_params::unit_num

        ;; Don't issue STATUS calls to IIc Plus Slot 5 firmware, as it causes
        ;; the motor to spin. https://github.com/a2stuff/a2d/issues/25
        ldx     #DeskTopSettings::system_capabilities
        jsr     ReadSetting
        and     #DeskTopSettings::kSysCapIsIIcPlus
    IF_NOT_ZERO
        lda     dispatch+1
        and     #%00001111      ; mask off slot
        cmp     #$05            ; is it slot 5?
        beq     next            ; if so, ignore
    END_IF

        ;; Don't issue STATUS calls to Laser 128 Slot 7 firmware, as it causes
        ;; hangs in some cases. https://github.com/a2stuff/a2d/issues/138
        ldx     #DeskTopSettings::system_capabilities
        jsr     ReadSetting
        and     #DeskTopSettings::kSysCapIsLaser128
    IF_NOT_ZERO
        lda     dispatch+1      ; $Cs
        and     #%00001111      ; mask off slot
        cmp     #$07            ; is it slot 7?
        beq     next            ; if so, skip it!
    END_IF

        dispatch := *+1
        jsr     SELF_MODIFIED
        .byte   SPCall::Status
        .addr   status_params
        bcs     next            ; call failed - skip it!
        lda     dib_buffer+SPDIB::Device_Type_Code
        cmp     #SPDeviceType::Disk525
        beq     next            ; is 5.25 - skip it!

        ;; Append the device
        inc     count
        ldx     count
        copy8   unit_num, main::removable_device_table,x
        bne     next            ; always

index:  .byte   0
count:  .byte   0
unit_num:
        .byte   0
.endproc ; InitializeDisksInDevicesTables

;;; ============================================================

.proc FinalSetup
        ;; Final MGTK configuration
        MGTK_CALL MGTK::CheckEvents
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        copy8   #0, active_window_id

        ;; Add desktop icons
        ldx     #0
    DO
        BREAK_IF_X_EQ cached_window_entry_count
        txa
        pha
        copy8   cached_window_entry_list,x, icon_param
        ITK_CALL IconTK::DrawIcon, icon_param
        pla
        tax
        inx
    WHILE_NOT_ZERO              ; always

        ;; Desktop icons are cached now
        copy8   #0, cached_window_id
        jsr     main::StoreWindowEntryTable

        ;; Restore state from previous session
        jsr     RestoreWindows

        ;; Display any pending error messages
        lda     main::pending_alert
    IF_NOT_ZERO
        tay
        jsr     ShowAlert
    END_IF

        ;; And start pumping events
        jmp     main::MainLoop
.endproc ; FinalSetup

;;; ============================================================

.proc RestoreWindows
        data_ptr := $06

        jsr     main::save_restore_windows::Open
        jcs     exit
        lda     main::save_restore_windows::open_params::ref_num
        sta     main::save_restore_windows::rw_params::ref_num
        sta     main::save_restore_windows::close_params::ref_num
        MLI_CALL READ, main::save_restore_windows::rw_params
        jsr     main::save_restore_windows::Close

        ;; Validate file format version byte
        lda     main::save_restore_windows::desktop_file_data_buf
        cmp     #kDeskTopFileVersion
        jne     exit

        copy16  #main::save_restore_windows::desktop_file_data_buf+1, data_ptr

loop:   ldy     #0
        lda     (data_ptr),y
        beq     exit

        tay
    DO
        copy8   (data_ptr),y, INVOKER_PREFIX,y
        dey
    WHILE_POS

        jsr     PushPointers

        ;; Is there a matching volume icon? (If not, skip)
        ldx     #1              ; past leading '/'
    DO
        lda     INVOKER_PREFIX+1,x
        BREAK_IF_A_EQ #'/'      ; look for next '/'
        inx
    WHILE_X_NE  INVOKER_PREFIX

        dex
        stx     INVOKER_PREFIX+1 ; overwrite leading '/' with length
        param_call main::FindIconByName, 0, INVOKER_PREFIX+1 ; 0=desktop
        beq     next
        copy8   #'/', INVOKER_PREFIX+1 ; restore leading '/'

        ;; Copy view type to `new_window_view_by`
        ldy     #DeskTopFileItem::view_by
        copy8   (data_ptr),y, new_window_view_by

        ;; Copy loc to `new_window_viewloc`
        ldy     #DeskTopFileItem::viewloc+.sizeof(MGTK::Point)-1
        ldx     #.sizeof(MGTK::Point)-1
    DO
        copy8   (data_ptr),y, new_window_viewloc,x
        dey
        dex
    WHILE_POS

        ;; Copy bounds to `new_window_maprect`
        ldy     #DeskTopFileItem::maprect+.sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
    DO
        copy8   (data_ptr),y, new_window_maprect,x
        dey
        dex
    WHILE_POS

        lda     #$80
        sta     main::copy_new_window_bounds_flag
        sta     main::CreateFileRecordsForWindowImpl::suppress_error_on_open_flag
        jsr     _MaybeOpenWindow
        lda     #0
        sta     main::copy_new_window_bounds_flag
        sta     main::CreateFileRecordsForWindowImpl::suppress_error_on_open_flag

next:   jsr     PopPointers

        add16_8 data_ptr, #.sizeof(DeskTopFileItem)
        jmp     loop

exit:   jmp     main::LoadDesktopEntryTable

.proc _MaybeOpenWindow
        ;; Save stack for restore on error. If the call
        ;; fails, the routine will restore the stack then
        ;; rts, returning to our caller.
        tsx
        stx     saved_stack
        jmp     main::OpenWindowForPath
.endproc ; _MaybeOpenWindow

.endproc ; RestoreWindows

;;; ============================================================

kDeviceTemplateSlotOffset = res_const_sd_prefix_pattern_offset1
kDeviceTemplateDriveOffset = res_const_sd_prefix_pattern_offset2

kSDPrefixLength = .strlen(res_string_sd_prefix_pattern)
str_sdname_buffer:
        PASCAL_STRING res_string_sd_prefix_pattern ; "S#,D#: " prefix
        .res    16, 0              ; space for actual name

str_volume_type_unknown:
        PASCAL_STRING res_string_volume_type_unknown

trash_name:  PASCAL_STRING res_string_trash_icon_name

;;; ============================================================

        .include "../lib/clear_dhr.s"
        saved_ram_unitnum := main::saved_ram_unitnum
        saved_ram_drvec   := main::saved_ram_drvec
        saved_ram_buffer  := IO_BUFFER
        .include "../lib/disconnect_ram.s"

;;; ============================================================


.endscope ; init

        ENDSEG SegmentInitializer
