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
;;; ============================================================

        jmp     start

;;; ============================================================
;;; Resources and library code are here since they aren't needed by
;;; `RestoreWindows` which trashes $800... $DFF

str_volume_type_unknown:
        PASCAL_STRING res_string_volume_type_unknown

trash_name:
        PASCAL_STRING res_string_trash_icon_name

        .include "../lib/clear_dhr.s"
        saved_ram_unitnum := main::saved_ram_unitnum
        saved_ram_drvec   := main::saved_ram_drvec
        saved_ram_buffer  := IO_BUFFER
        .include "../lib/disconnect_ram.s"

;;; ============================================================

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
        CALL    ReadSetting, X=#DeskTopSettings::system_capabilities

        tax                     ; A = X = kSysCapXYZ bitmap
        ora     #DeskTopSettings::kSysCapIsIIgs | DeskTopSettings::kSysCapIsLaser128
    IF NOT_ZERO
        lda     #kPeriodicTaskDelayIIgs
        bne     end             ; always
    END_IF

        txa                     ; A = X = kSysCapXYZ bitmap
        ora     #DeskTopSettings::kSysCapIsIIc
    IF NOT_ZERO
        lda     #kPeriodicTaskDelayIIc
        bne     end             ; always
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
    WHILE POS
        ;; fall through
.endscope

;;; ============================================================
;;; Make startup volume first in list

.scope
        ;; Find the startup volume's unit number
        copy8   DEVNUM, target
        jsr     main::GetCopiedToRAMCardFlag
    IF NS
        CALL    main::CopyDeskTopOriginalPrefix, AX=#INVOKER_PREFIX
        MLI_CALL GET_FILE_INFO, main::src_file_info_params
      IF CC
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
    WHILE X < DEVCNT
        bcs     done            ; last one or not found

        ;; Save it
found:  ldy     DEVLST,x

        ;; Move everything up
    DO
        copy8   DEVLST+1,x, DEVLST,x
        inx
    WHILE X <> DEVCNT

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
    WHILE X <> #AS_BYTE(DeskTopSettings::pattern-1)

        MGTK_CALL MGTK::SetZP1, setzp_params_nopreserve
        MGTK_CALL MGTK::SetDeskPat, tmp_pattern
        MGTK_CALL MGTK::StartDeskTop, startdesktop_params
        MGTK_CALL MGTK::InitMenu, initmenu_params
        jsr     main::SetRGBMode
        MGTK_CALL MGTK::SetMenu, aux::desktop_menu
        jsr     main::ShowClock

        lda     startdesktop_params::slot_num
    IF ZERO
        CALL    ReadSetting, X=#DeskTopSettings::options
        ora     #DeskTopSettings::kOptionsShowShortcuts
        jsr     WriteSetting
    END_IF

        SET_BIT7_FLAG main::mli_relay_checkevents_flag

        ;; --------------------------------------------------
        ;; Cursor tracking

        ;; Doubled if option selected
        CALL    ReadSetting, X=#DeskTopSettings::mouse_tracking
    IF NOT_ZERO
        inc     scalemouse_params::x_exponent
        inc     scalemouse_params::y_exponent
    END_IF

        ;; Also doubled if a IIc
        CALL    ReadSetting, X=#DeskTopSettings::system_capabilities
        and     #DeskTopSettings::kSysCapIsIIc
    IF NOT_ZERO
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
        sta     icon_param
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
    WHILE X <> trash_name
        copy8   trash_name,x, (ptr),y

        ITK_CALL IconTK::DrawIcon, icon_param

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
        bne     done

        lda     selector_list_data_buf + kSelectorListNumPrimaryRunListOffset
        clc
        adc     selector_list_data_buf + kSelectorListNumSecondaryRunListOffset
        sta     num_selector_list_items

        copy8   selector_list_data_buf, count
loop:   lda     index
        cmp     count
        beq     done

        ;; Copy entry name into place
        jsr     main::ATimes16
        addax   #selector_list_data_buf + kSelectorListEntriesOffset, ptr1
        CALL    main::ATimes16, A=index
        addax   #run_list_entries, ptr2
        jsr     _CopyPtr1ToPtr2

        ;; Copy entry flags into place
        ldy     #15
        copy8   (ptr1),y, (ptr2),y

        ;; Copy entry path into place
        CALL    main::ATimes64, A=index
        addax   #selector_list_data_buf + kSelectorListPathsOffset, ptr1
        CALL    main::ATimes64, A=index
        addax   #main::run_list_paths, ptr2
        jsr     _CopyPtr1ToPtr2

        inc     index
        inc     selector_menu
        jmp     loop

done:
        ;; No separator if it is last
        lda     selector_menu
    IF A = #kSelectorMenuFixedItems
        dec     selector_menu
    END_IF
        jmp     end_of_scope

index:  .byte   0
count:  .byte   0

;;; --------------------------------------------------

.proc _CopyPtr1ToPtr2
        ptr1 := $06
        ptr2 := $08

        ldy     #0
        lda     (ptr1),y
        tay
    DO
        copy8   (ptr1),y, (ptr2),y
        dey
    WHILE POS
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
        bcs     not_found

        lda     open_params::ref_num
        sta     read_params::ref_num
        MLI_CALL READ, read_params
        MLI_CALL CLOSE, close_params
        rts

not_found:
        ;; Clear buffer
        ptr := $06
        copy16  #selector_list_data_buf, ptr
        ldx     #>kSelectorListShortSize ; number of pages
        lda     #0
    DO
        ldy     #0
      DO
        sta     (ptr),y
        dey
      WHILE NOT_ZERO
        inc     ptr+1
        dex
    WHILE NOT_ZERO
        rts
.endproc ; _ReadSelectorList

        end_of_scope := *

.endproc ; LoadSelectorList

;;; ============================================================
;;; Enumerate Desk Accessories

.scope
        MGTK_CALL MGTK::CheckEvents

        read_dir_buffer := data_buf

        ;; Does the directory exist?
        MLI_CALL GET_FILE_INFO, get_file_info_params
        jcs     end

        lda     get_file_info_params::file_type
        cmp     #FT_DIRECTORY
        beq     open_dir
        jmp     end

open_dir:
        MLI_CALL OPEN, open_params
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
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
        CALL    AdjustFileEntryCase, AX=dir_ptr

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
    IF A = #kDAFileType         ; DA? (must match type/auxtype)
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
        CALL    Multiply_16_8_16, Y=desk_acc_num, AX=#kDAMenuItemSize
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
    WHILE NOT_ZERO

        ;; If a directory, prepend name with folder glyphs
        ldy     #FileEntry::file_type
        lda     (dir_ptr),y
    IF A = #FT_DIRECTORY        ; Directory?
        ldy     name_buf
      DO
        copy8   name_buf,y, name_buf+3,y
        dey
      WHILE NOT_ZERO

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
      IF A = #'.'
        lda     #' '
      END_IF
        sta     (da_ptr),y
        dey
    WHILE NOT_ZERO

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
    IF A = entries_per_block
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
        .assert BLOCK_SIZE <= kDataBufferSize, error, "Buffer size error"
        DEFINE_READWRITE_PARAMS read_params, read_dir_buffer, BLOCK_SIZE
        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, str_desk_acc
        DEFINE_CLOSE_PARAMS close_params

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
    IF A = #kAppleMenuFixedItems
        dec     apple_menu
    END_IF

.endscope

;;; ============================================================
;;; Populate volume icons

.scope
        copy8   #0, main::pending_alert

        ;; Enumerate DEVLST in reverse order (most important volumes first)
        copy8   DEVCNT, device_index
    DO
        device_index := *+1
        ldy     #SELF_MODIFIED_BYTE
        lda     DEVLST,y
        pha                     ; A = unmasked unit number

        jsr     main::CreateVolumeIcon ; A = unmasked unit number, Y = device index
      IF A = #ERR_DEVICE_NOT_CONNECTED
        ;; If device is not connected, remove it from DEVLST
        ;; unless it's a Disk II.
        pla                     ; A = unmasked unit number
        pha                     ; A = unmasked unit number
        ;; NOTE: Not masked with `UNIT_NUM_MASK`, `IsDiskII` handles it.
        jsr     main::IsDiskII
        beq     done_create     ; skip
        CALL    _RemoveDevice, X=device_index
        jmp     next
      END_IF

      IF A = #ERR_DUPLICATE_VOLUME
        copy8   #kErrDuplicateVolName, main::pending_alert
      END_IF

done_create:
        ldx     cached_window_entry_count
        copy8   cached_window_entry_list-1,x, icon_param
        ITK_CALL IconTK::DrawIcon, icon_param

next:
        pla
        dec     device_index
    WHILE POS

        copy8   #0, cached_window_id
        jsr     main::StoreWindowEntryTable

        jmp     end_of_scope

;;; Remove device num in X from devices list
.proc _RemoveDevice
        dex
    DO
        inx
        copy8   DEVLST+1,x, DEVLST,x
        copy8   main::device_to_icon_map+1,x, main::device_to_icon_map,x
        cpx     DEVCNT
    WHILE NOT_ZERO
        dec     DEVCNT

        ;; ProDOS requires an ON_LINE call after a device is
        ;; disconnected in order to clean up the VCB entry. However,
        ;; we only remove devices here if the device already failed an
        ;; ON_LINE call with `ERR_DEVICE_NOT_CONNECTED` so it should
        ;; not be necessary.

        rts
.endproc ; _RemoveDevice

        end_of_scope := *
        FALL_THROUGH_TO PopulateDeviceNames
.endscope

;;; ============================================================
;;; This section populates `device_name_table` - it determines which
;;; device type string to use, and fills in slot and drive as
;;; appropriate. Used in the Format/Erase disk dialog.

.proc PopulateDeviceNames
        ;; Enumerate DEVLST in reverse order (most important volumes first)
        ldy     DEVCNT
    DO
        tya                     ; Y = index
        pha                     ; A = index

        lda     DEVLST,y
        pha                     ; A = unmasked unit number

        devname_ptr := $06

        jsr     main::GetDeviceType ; A = unmasked unit number
        stax    devname_ptr         ; A,X = device name (may be empty)
        ;; Empty?
        ldy     #0
        lda     (devname_ptr),y
      IF ZERO
        copy16  #str_volume_type_unknown, devname_ptr
      END_IF

        ;; arg0 = slot
        pla                     ; A = unmasked unit number
        tay
        and     #%01110000      ; A = 0SSS0000
        lsr                     ; A = 00SSS000
        lsr                     ; A = 000SSS00
        lsr                     ; A = 0000SSS0
        lsr                     ; A = 00000SSS
        pha                     ; arg0 lo
        lda     #0
        pha                     ; arg0 hi

        ;; arg1 = drive
        tya
        asl                     ; drive bit into C
        lda     #0
        adc     #1              ; arg1 lo
        pha
        lda     #0
        pha                     ; arg1 hi

        ;; arg2 = name
        push16  devname_ptr     ; arg2

        FORMAT_MESSAGE 3, aux::str_sd_name_format

        ;; Copy name into table
        pla                     ; A = index
        pha

        asl     a
        tax
        copy16  device_name_table,x, devname_ptr

        ldy     text_input_buf
      DO
        copy8   text_input_buf,y, (devname_ptr),y
        dey
      WHILE POS

        pla                     ; A = index
        tay                     ; Y = index
        dey
    WHILE POS

        FALL_THROUGH_TO PopulateStartupMenu

.endproc ; PopulateDeviceNames

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

        ldy     #$01            ; $Cn01 == $20 ?
        lda     (slot_ptr),y
        cmp     #$20
        bne     next

        ldy     #$03            ; $Cn03 == $00 ?
        lda     (slot_ptr),y
        cmp     #$00
        bne     next

        ldy     #$05            ; $Cn05 == $03 ?
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
    WHILE NOT_ZERO

        ;; Set number of menu items.
        stx     startup_menu
        jmp     end_of_scope

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

        end_of_scope := *
        FALL_THROUGH_TO InitializeDisksInDevicesTables
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
    WHILE A >= index

        lda     count
        sta     main::removable_device_table
        sta     main::disk_in_device_table
        jsr     main::CheckDisksInDevices

        ;; Make copy of table
        ldx     main::disk_in_device_table
    IF NOT_ZERO
      DO
        copy8   main::disk_in_device_table,x, main::last_disk_in_devices_table,x
        dex
      WHILE POS
    END_IF

        jmp     end_of_scope

        DEFINE_SP_STATUS_PARAMS status_params, SELF_MODIFIED_BYTE, dib_buffer, 3 ; Return Device Information Block (DIB)

dib_buffer := ::IO_BUFFER

        ;; Maybe add device to the removable device table
append:
        ;; Do SmartPort STATUS call to filter out 5.25 devices
        CALL    main::FindSmartportDispatchAddress, A=unit_num
        bcs     next            ; can't determine address - skip it!
        stax    dispatch
        sty     status_params::unit_num

        ;; Don't issue STATUS calls to IIc Plus Slot 5 firmware, as it causes
        ;; the motor to spin. https://github.com/a2stuff/a2d/issues/25
        CALL    ReadSetting, X=#DeskTopSettings::system_capabilities
        and     #DeskTopSettings::kSysCapIsIIcPlus
    IF NOT_ZERO
        lda     dispatch+1
        and     #%00001111      ; mask off slot
        cmp     #$05            ; is it slot 5?
        beq     next            ; if so, ignore
    END_IF

        ;; Don't issue STATUS calls to Laser 128 Slot 7 firmware, as it causes
        ;; hangs in some cases. https://github.com/a2stuff/a2d/issues/138
        CALL    ReadSetting, X=#DeskTopSettings::system_capabilities
        and     #DeskTopSettings::kSysCapIsLaser128
    IF NOT_ZERO
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

        end_of_scope := *
        FALL_THROUGH_TO FinalSetup
.endproc ; InitializeDisksInDevicesTables

;;; ============================================================

.proc FinalSetup
        ;; Final MGTK configuration
        MGTK_CALL MGTK::CheckEvents
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        copy8   #0, active_window_id

        ;; Restore state from previous session
        jsr     RestoreWindows

        ;; Window restoration can safely trash anything before this
        ;; point, but needs to be able to return here to finish up.
        .assert * >= (DIR_READ_DATA_BUFFER + kDirReadDataBufferSize), error, "data/code clash"

        ;; Display any pending error messages
        lda     main::pending_alert
    IF NOT_ZERO
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
    WHILE POS

        jsr     PushPointers

        ;; Is there a matching volume icon? (If not, skip)
        ldx     #1              ; past leading '/'
    DO
        lda     INVOKER_PREFIX+1,x
        BREAK_IF A = #'/'       ; look for next '/'
        inx
    WHILE X <> INVOKER_PREFIX

        dex
        stx     INVOKER_PREFIX+1 ; overwrite leading '/' with length
        CALL    main::FindIconByName, Y=#0, AX=#INVOKER_PREFIX+1 ; 0=desktop
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
    WHILE POS

        ;; Copy bounds to `new_window_maprect`
        ldy     #DeskTopFileItem::maprect+.sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
    DO
        copy8   (data_ptr),y, new_window_maprect,x
        dey
        dex
    WHILE POS

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
        stx     main::saved_stack
        jmp     main::OpenWindowForPath
.endproc ; _MaybeOpenWindow

.endproc ; RestoreWindows

;;; ============================================================

        .assert * <= data_buf, error, "data/code clash"

;;; ============================================================

.endscope ; init

        ENDSEG SegmentInitializer
