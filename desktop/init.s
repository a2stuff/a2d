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

        ;; First, detect IIgs
        sec                     ; Follow detection protocol
        jsr     IDROUTINE       ; RTS on pre-IIgs
        bcs     :+              ; carry clear = IIgs
        copy    #$80, tmp_iigs_flag
:
        ;; Now stash the bytes we need
        copy    VERSION, tmp_version  ; $06 = IIe or later
        copy    ZIDBYTE, tmp_idbyte   ; $00 = IIc or later
        copy    ZIDBYTE2, tmp_idbyte2 ; IIc ROM version (IIc+ = $05)
        copy    IDBYTEMACIIE, tmp_idmaciie ; $02 = Mac IIe Option Card
        copy    IDBYTELASER128, tmp_idlaser ; $AC = Laser 128

        ;; ... and page in LCBANK1
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        ;; Place the version bytes somewhere useful later
        tmp_version := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     machine_config::id_version
        tmp_idbyte := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     machine_config::id_idbyte
        tmp_idbyte2 := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     machine_config::id_idbyte2
        tmp_idmaciie := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     machine_config::id_idmaciie
        tmp_idlaser := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     machine_config::id_idlaser
        tmp_iigs_flag := *+1
        lda     #SELF_MODIFIED_BYTE
        sta     machine_config::iigs_flag

        ;; Ensure we're on a IIe or later
        lda     machine_config::id_version
        cmp     #$06            ; Ensure a IIe or later
        beq     :+
        brk                     ; Otherwise (][, ][+, ///), just crash

        ;; State needed by MGTK
:       copy    machine_config::id_version, startdesktop_params::machine
        copy    machine_config::id_idbyte, startdesktop_params::subid

        ;; Identify machine type (periodic delays and other flags)
        lda     machine_config::id_idbyte
        beq     is_iic          ; $FBC0 = $00 -> is IIc or IIc+
        bit     machine_config::iigs_flag
        bmi     is_iigs

        ;; Laser 128?
        lda     machine_config::id_idlaser ; Is it a Laser 128?
        cmp     #$AC
        bne     is_iie

        copy    #$80, machine_config::laser128_flag
        lda     #kPeriodicTaskDelayIIgs ; Assume accelerated???
        bne     end                     ; always

        ;; IIe (or Mac IIe Option Card)
is_iie: lda     machine_config::id_idbyte
        cmp     #$E0            ; Is Enhanced IIe?
        bne     :+
        lda     machine_config::id_idmaciie
        cmp     #$02            ; Mac IIe Option Card signature
        bne     :+
        copy    #$80, machine_config::iiecard_flag
:
        lda     #kPeriodicTaskDelayIIe
        bne     end             ; always

        ;; IIgs
is_iigs:
        lda     #kPeriodicTaskDelayIIgs
        bne     end             ; always

        ;; IIc or IIc+
is_iic: lda     machine_config::id_idbyte2 ; ROM version
        cmp     #$05                  ; IIc Plus = $05
        bne     :+
        copy    #$80, machine_config::iic_plus_flag
:       lda     #kPeriodicTaskDelayIIc

end:
        sta     periodic_task_delay

        ;; Fall through
.endscope ; machine_type

;;; ============================================================
;;; Snapshot state of PB2 (shift key mod)

.scope pb2_state
        copy    BUTN2, machine_config::pb2_initial_state
.endscope ; pb2_state

;;; ============================================================
;;; Detect Le Chat Mauve Eve RGB card

.scope lcm
        bit     ROMIN2
        jsr     DetectLeChatMauveEve
        pha
        bit     LCBANK1
        bit     LCBANK1
        pla
        beq     :+              ; Z=1 means no LCMEve
        copy    #$80, machine_config::lcm_eve_flag
:
.endscope ; lcm

;;; ============================================================
;;; Back up DEVLST

.scope
        ;; Make a copy of the original device list
        .assert DEVLST = DEVCNT+1, error, "DEVCNT must precede DEVLST"
        ldx     DEVCNT          ; number of devices
        inx                     ; include DEVCNT itself
:       copy    DEVLST-1,x, main::devlst_backup,x ; DEVCNT is at DEVLST-1
        dex
        bpl     :-
        ;; fall through
.endscope

;;; ============================================================
;;; Make startup volume first in list

.scope
        ;; Find the startup volume's unit number
        copy    DEVNUM, target
        jsr     main::GetCopiedToRAMCardFlag
    IF_MINUS
        param_call main::CopyDeskTopOriginalPrefix, INVOKER_PREFIX
        MLI_CALL GET_FILE_INFO, main::src_file_info_params
        bcs     :+
        copy    DEVNUM, target
:
    END_IF

        ;; Find the device's index in the list
        ldx     #0
:       lda     DEVLST,x
        and     #UNIT_NUM_MASK  ; to compare against DEVNUM
        target := *+1
        cmp     #SELF_MODIFIED_BYTE
        beq     found
        inx
        cpx     DEVCNT
        bcc     :-
        bcs     done            ; last one or not found

        ;; Save it
found:  ldy     DEVLST,x

        ;; Move everything up
:       lda     DEVLST+1,x
        sta     DEVLST,x
        inx
        cpx     DEVCNT
        bne     :-

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
:       jsr     main::ReadSetting
        sta     tmp_pattern - DeskTopSettings::pattern,x
        dex
        cpx     #AS_BYTE(DeskTopSettings::pattern-1)
        bne     :-

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
        jsr     main::ReadSetting
        ora     #DeskTopSettings::kOptionsShowShortcuts
        jsr     main::WriteSetting
    END_IF

        copy    #$80, main::mli_relay_checkevents_flag

        ;; --------------------------------------------------
        ;; Cursor tracking

        ;; Doubled if option selected
        ldx     #DeskTopSettings::mouse_tracking
        jsr     main::ReadSetting
    IF_NOT_ZERO
        inc     scalemouse_params::x_exponent
        inc     scalemouse_params::y_exponent
    END_IF
        ;; Also doubled if a IIc
        lda     machine_config::id_idbyte ; ZIDBYTE=0 for IIc / IIc+
    IF_ZERO
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
;;; Populate icon_entries table

.scope
        ptr := $6

        jsr     PushPointers
        copy16  #icon_entries, ptr

        ldx     #1
loop:
        ;; Populate table entry
        txa                     ; A = icon id
        asl     a
        tay
        copy16  ptr, icon_entry_address_table,y

        ;; Initialize IconEntry
        txa                     ; A = icon id
        ldy     #IconEntry::id
        sta     (ptr),y
        iny                     ; Y = IconEntry::state
        copy    #0, (ptr),y     ; mark not allocated

        ;; Next entry
        add16_8 ptr, #.sizeof(IconEntry)
        inx
        cpx     #kMaxIconCount+1 ; allow up to the maximum
        bne     loop
        jsr     PopPointers

        ITK_CALL IconTK::InitToolKit, itkinit_params

        FALL_THROUGH_TO CreateTrashIcon
.endscope

;;; ============================================================

.proc CreateTrashIcon
        ptr := $6

        copy    #0, cached_window_id
        lda     #1
        sta     cached_window_entry_count
        sta     icon_count
        jsr     main::AllocateIcon
        sta     main::trash_icon_num
        sta     cached_window_entry_list
        jsr     main::GetIconEntry
        stax    ptr

        ;; Trash is a drop target
        ldy     #IconEntry::win_flags
        copy    #kIconEntryFlagsDropTarget|kIconEntryFlagsNotDropSource, (ptr),y

        ldy     #IconEntry::iconx
        copy16in #main::kTrashIconX, (ptr),y
        ldy     #IconEntry::icony
        copy16in #main::kTrashIconY, (ptr),y
        ldy     #IconEntry::iconbits
        copy16in #trash_icon, (ptr),y

        iny
        ldx     #0
:       lda     trash_name,x
        sta     (ptr),y
        iny
        inx
        cpx     trash_name
        bne     :-
        lda     trash_name,x
        sta     (ptr),y

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

        copy    #0, index
        jsr     ReadSelectorList
        jne     done

        lda     selector_list_data_buf + kSelectorListNumPrimaryRunListOffset
        clc
        adc     selector_list_data_buf + kSelectorListNumSecondaryRunListOffset
        sta     num_selector_list_items

        copy    #0, selector_menu_items_updated_flag

        lda     selector_list_data_buf
        sta     count
L0A3B:  lda     index
        cmp     count
        beq     done

        ;; Copy entry name into place
        jsr     main::ATimes16
        addax   #selector_list_data_buf + kSelectorListEntriesOffset, ptr1
        lda     index
        jsr     main::ATimes16
        addax   #run_list_entries, ptr2
        jsr     CopyPtr1ToPtr2

        ;; Copy entry flags into place
        ldy     #15
        lda     (ptr1),y
        sta     (ptr2),y

        ;; Copy entry path into place
        lda     index
        jsr     main::ATimes64
        addax   #selector_list_data_buf + kSelectorListPathsOffset, ptr1
        lda     index
        jsr     main::ATimes64
        addax   #main::run_list_paths, ptr2
        jsr     CopyPtr1ToPtr2

        inc     index
        inc     selector_menu
        jmp     L0A3B

done:   jmp     end

index:  .byte   0
count:  .byte   0

.proc CopyPtr1ToPtr2
        ptr1 := $06
        ptr2 := $08

        ldy     #0
        lda     (ptr1),y
        tay
:       lda     (ptr1),y
        sta     (ptr2),y
        dey
        bpl     :-
        rts
.endproc ; CopyPtr1ToPtr2

;;; --------------------------------------------------

        DEFINE_OPEN_PARAMS open_params, str_selector_list, selector_list_io_buf

str_selector_list:
        PASCAL_STRING kPathnameSelectorList

        DEFINE_READ_PARAMS read_params, selector_list_data_buf, kSelectorListShortSize
        DEFINE_CLOSE_PARAMS close_params

.proc ReadSelectorList
        MLI_CALL OPEN, open_params
        bne     WriteSelectorList

        lda     open_params::ref_num
        sta     read_params::ref_num
        MLI_CALL READ, read_params
        MLI_CALL CLOSE, close_params
        rts
.endproc ; ReadSelectorList

        DEFINE_CREATE_PARAMS create_params, str_selector_list, ACCESS_DEFAULT, $F1
        DEFINE_WRITE_PARAMS write_params, selector_list_data_buf, kSelectorListShortSize

.proc WriteSelectorList
        ptr := $06

        ;; Clear buffer
        copy16  #selector_list_data_buf, ptr
        ldx     #>kSelectorListShortSize ; number of pages
        lda     #0
ploop:  ldy     #0
:       sta     (ptr),y
        dey
        bne     :-
        inc     ptr+1
        dex
        bne     ploop

        ;; Write out file
        MLI_CALL CREATE, create_params
        bne     done
        MLI_CALL OPEN, open_params
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        MLI_CALL WRITE, write_params ; two blocks of $400
        MLI_CALL WRITE, write_params
        MLI_CALL CLOSE, close_params

done:   rts
.endproc ; WriteSelectorList

end:
.endproc ; LoadSelectorList

;;; ============================================================
;;; Enumerate Desk Accessories

.scope
        MGTK_CALL MGTK::CheckEvents

        read_dir_buffer := data_buf

        ;; Does the directory exist?
        MLI_CALL GET_FILE_INFO, get_file_info_params
        beq     :+
        jmp     end

:       lda     get_file_info_type
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

        lda     #1              ; First block has header instead of entry
        sta     entry_in_block

        lda     read_dir_buffer + SubdirectoryHeader::file_count
        and     #$7F
        sta     file_count

        lda     #2
        sta     apple_menu      ; "About..." and separator

        lda     read_dir_buffer + SubdirectoryHeader::entries_per_block
        sta     entries_per_block
        lda     read_dir_buffer + SubdirectoryHeader::entry_length
        sta     entry_length

        dir_ptr := $06
        da_ptr := $08

        copy16  #read_dir_buffer + .sizeof(SubdirectoryHeader), dir_ptr

process_block:
        param_call_indirect main::AdjustFileEntryCase, dir_ptr

        ldy     #FileEntry::storage_type_name_length
        lda     (dir_ptr),y
        and     #NAME_LENGTH_MASK
        bne     :+
        jmp     next_entry

:       inc     entry_num
        ldy     #FileEntry::file_type
        lda     (dir_ptr),y

        cmp     #FT_DIRECTORY   ; Directory?
        beq     include

        cmp     #kDAFileType    ; DA? (must match type/auxtype)
        bne     :+
        ldy     #FileEntry::aux_type
        lda     (dir_ptr),y
        cmp     #<kDAFileAuxType
        jne     next_entry
        iny
        lda     (dir_ptr),y
        cmp     #>kDAFileAuxType
        jne     next_entry

:       ldx     #kNumAppleMenuTypes-1
:       cmp     apple_menu_type_table,x
        beq     include
        dex
        bpl     :-
        jne     next_entry

include:
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
:       lda     (dir_ptr),y
        sta     name_buf,y
        dey
        bne     :-

        ;; If a directory, prepend name with folder glyphs
        ldy     #FileEntry::file_type
        lda     (dir_ptr),y
        cmp     #FT_DIRECTORY   ; Directory?
    IF_EQ
        ldy     name_buf
:       lda     name_buf,y
        sta     name_buf+3,y
        dey
        bne     :-

        copy    #kGlyphFolderLeft, name_buf+1
        copy    #kGlyphFolderRight, name_buf+2
        copy    #kGlyphSpacer, name_buf+3
        inc     name_buf
        inc     name_buf
        inc     name_buf
    END_IF

        ;; Convert periods to spaces, copy into menu
        ldy     #0
        lda     name_buf,y
        sta     (da_ptr),y
        tay
loop:   lda     name_buf,y
        cmp     #'.'
        bne     :+
        lda     #' '
:       sta     (da_ptr),y
        dey
        bne     loop

        inc     desk_acc_num
        inc     apple_menu      ; number of menu items

next_entry:
        ;; Room for more DAs?
        lda     desk_acc_num
        cmp     #kMaxDeskAccCount
        bcc     :+
        jmp     close_dir

        ;; Any more entries in dir?
:       lda     entry_num
        cmp     file_count
        bne     :+
        jmp     close_dir

        ;; Any more entries in block?
:       inc     entry_in_block
        lda     entry_in_block
        cmp     entries_per_block
        bne     :+
        MLI_CALL READ, read_params
        copy16  #read_dir_buffer + 4, dir_ptr

        lda     #0
        sta     entry_in_block
        jmp     process_block

:       add16_8 dir_ptr, entry_length
        jmp     process_block

close_dir:
        MLI_CALL CLOSE, close_params
        jmp     end

        DEFINE_OPEN_PARAMS open_params, str_desk_acc, IO_BUFFER
        open_ref_num := open_params::ref_num

        .assert BLOCK_SIZE <= kDataBufferSize, error, "Buffer size error"
        DEFINE_READ_PARAMS read_params, read_dir_buffer, BLOCK_SIZE
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

        kNumAppleMenuTypes = 8
apple_menu_type_table:
        .byte   FT_SYSTEM, FT_S16, FT_BINARY, FT_BASIC ; Executable
        .byte   FT_TEXT, FT_GRAPHICS, FT_FONT, FT_MUSIC ; Previewable
        ASSERT_TABLE_SIZE apple_menu_type_table, kNumAppleMenuTypes

end:
.endscope

;;; ============================================================
;;; Populate volume icons and device names

;;; TODO: Dedupe with CmdCheckDrives

.scope
        devname_ptr := $08

        ldy     #0
        sty     main::pending_alert

        ;; Enumerate DEVLST in reverse order (most important volumes first)
        lda     DEVCNT
        sta     device_index

process_volume:
        lda     device_index
        asl     a
        tay
        copy16  device_name_table,y, devname_ptr
        ldy     device_index
        lda     DEVLST,y

        pha                     ; save all registers
        txa
        pha
        tya
        pha

        inc     cached_window_entry_count
        inc     icon_count
        lda     DEVLST,y
        jsr     main::CreateVolumeIcon ; A = unit number, Y = device index
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
        cmp     #ERR_DEVICE_NOT_CONNECTED
        bne     :+

        ;; If device is not connected, remove it from DEVLST
        ;; unless it's a Disk II.

        ldy     device_index
        lda     DEVLST,y
        jsr     main::IsDiskII
        beq     select_template ; skip
        ldx     device_index
        jsr     RemoveDevice
        jmp     next

:       cmp     #ERR_DUPLICATE_VOLUME
        bne     select_template
        lda     #kErrDuplicateVolName
        sta     main::pending_alert

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
        bne     :+
        copy16  #str_volume_type_unknown, src
:

        ;; Set final length
        lda     (src),y         ; Y = 0
        clc
        adc     #kSDPrefixLength
        sta     str_sdname_buffer

        ;; Copy string into template, after prefix
        lda     (src),y         ; Y = 0
        tay                     ; Y = length
:       lda     (src),y
        sta     str_sdname_buffer + kSDPrefixLength,y
        dey
        bne     :-              ; leave length alone

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
:       lda     str_sdname_buffer,y
        sta     (devname_ptr),y
        dey
        bpl     :-

next:   pla
        dec     device_index
        lda     device_index

        bpl     :+
        bmi     PopulateStartupMenu
:       jmp     process_volume  ; next!

device_index:
        .byte   0
cvi_result:
        .byte   0
.endscope

;;; ============================================================

        ;; Remove device num in X from devices list
.proc RemoveDevice
        dex
:       inx
        copy    DEVLST+1,x, DEVLST,x
        copy    main::device_to_icon_map+1,x, main::device_to_icon_map,x
        cpx     DEVCNT
        bne     :-
        dec     DEVCNT
        rts
.endproc ; RemoveDevice

;;; ============================================================

.proc PopulateStartupMenu
        slot_ptr := $06         ; pointed at $Cn00
        table_ptr := $08        ; points into slot_string_table

        lda     #7
        sta     slot
        lda     #0
        sta     slot_ptr
        tax                     ; X = menu entry

        ;; Identify ProDOS device in slot by ID bytes
loop:   lda     slot
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
        lda     slot
        sta     main::startup_slot_table,x

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
        bne     loop

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

loop:   ldy     index
        lda     DEVLST,y
        sta     unit_num
        jsr     main::DeviceDriverAddress
        bvs     append          ; remapped SmartPort, it's usable
        bne     next            ; if RAM-based driver (not $CnXX), skip
        stx     slot_ptr+1      ; just need high byte ($Cn)
        copy    #0, slot_ptr    ; make $Cn00
        ldy     #$FF            ; Firmware ID byte
        lda     (slot_ptr),y    ; $CnFF: $00=Disk II, $FF=13-sector, else=block
        beq     next
        dey
        lda     (slot_ptr),y    ; $CnFE: Status Byte
        bmi     append          ; bit 7 - Medium is removable

next:   inc     index
        lda     DEVCNT          ; continue while index <= DEVCNT
        cmp     index
        bcs     loop

        lda     count
        sta     main::removable_device_table
        sta     main::disk_in_device_table
        jsr     main::CheckDisksInDevices

        ;; Make copy of table
        ldx     main::disk_in_device_table
        beq     done
:       copy    main::disk_in_device_table,x, main::last_disk_in_devices_table,x
        dex
        bpl     :-

done:   jmp     FinalSetup

        DEFINE_SP_STATUS_PARAMS status_params, SELF_MODIFIED_BYTE, dib_buffer, 3 ; Return Device Information Block (DIB)

dib_buffer := ::IO_BUFFER

        ;; Maybe add device to the removable device table
append: lda     unit_num

        ;; Don't issue STATUS calls to IIc Plus Slot 5 firmware, as it causes
        ;; the motor to spin. https://github.com/a2stuff/a2d/issues/25
        bit     machine_config::iic_plus_flag
        bpl     :+
        and     #%01110000      ; mask off slot
        cmp     #$50            ; is it slot 5?
        beq     next            ; if so, ignore
:
        ;; Do SmartPort STATUS call to filter out 5.25 devices
        lda     unit_num
        jsr     main::FindSmartportDispatchAddress
        bcs     next            ; can't determine address - skip it!
        stax    dispatch
        sty     status_params::unit_num

        ;; Don't issue STATUS calls to Laser 128 Slot 7 firmware, as it causes
        ;; hangs in some cases. https://github.com/a2stuff/a2d/issues/138
        bit     machine_config::laser128_flag
    IF_NS
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
        lda     unit_num
        sta     main::removable_device_table,x
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
        lda     #0
        sta     active_window_id
        jsr     main::UpdateWindowMenuItems
        jsr     main::DisableMenuItemsRequiringVolumeSelection
        jsr     main::DisableMenuItemsRequiringFileSelection
        jsr     main::DisableMenuItemsRequiringSelection

        ;; Add desktop icons
        ldx     #0
iloop:  cpx     cached_window_entry_count
        beq     :+
        txa
        pha
        lda     cached_window_entry_list,x
        sta     icon_param
        jsr     main::GetIconEntry
        stax    @addr
        ITK_CALL IconTK::AddIcon, 0, @addr
        ITK_CALL IconTK::DrawIcon, icon_param ; CHECKED (desktop)
        pla
        tax
        inx
        jmp     iloop
:
        ;; Desktop icons are cached now
        copy    #0, cached_window_id
        jsr     main::StoreWindowEntryTable

        ;; Restore state from previous session
        jsr     RestoreWindows

        ;; Display any pending error messages
        lda     main::pending_alert
        beq     :+
        tay
        jsr     ShowAlert
:

        ;; And start pumping events
        jmp     main::MainLoop
.endproc ; FinalSetup

;;; ============================================================

.proc RestoreWindows
        data_ptr := $06

        jsr     main::save_restore_windows::Open
        jcs     exit
        lda     main::save_restore_windows::open_params::ref_num
        sta     main::save_restore_windows::read_params::ref_num
        sta     main::save_restore_windows::close_params::ref_num
        MLI_CALL READ, main::save_restore_windows::read_params
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
:       lda     (data_ptr),y
        sta     INVOKER_PREFIX,y
        dey
        bpl     :-

        jsr     PushPointers

        ;; Is there a matching volume icon? (If not, skip)
        ldx     #1              ; past leading '/'
:       lda     INVOKER_PREFIX+1,x
        cmp     #'/'            ; look for next '/'
        beq     :+
        inx
        cpx     INVOKER_PREFIX
        bne     :-
:       dex
        stx     INVOKER_PREFIX+1 ; overwrite leading '/' with length
        param_call main::FindIconByName, 0, INVOKER_PREFIX+1 ; 0=desktop
        beq     next
        copy    #'/', INVOKER_PREFIX+1 ; restore leading '/'

        ;; Copy view type to `new_window_view_by`
        ldy     #DeskTopFileItem::view_by
        lda     (data_ptr),y
        sta     new_window_view_by

        ;; Copy loc to `new_window_viewloc`
        ldy     #DeskTopFileItem::viewloc+.sizeof(MGTK::Point)-1
        ldx     #.sizeof(MGTK::Point)-1
:       lda     (data_ptr),y
        sta     new_window_viewloc,x
        dey
        dex
        bpl     :-

        ;; Copy bounds to `new_window_maprect`
        ldy     #DeskTopFileItem::maprect+.sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
:       lda     (data_ptr),y
        sta     new_window_maprect,x
        dey
        dex
        bpl     :-

        lda     #$80
        sta     main::copy_new_window_bounds_flag
        sta     main::OpenDirectory::suppress_error_on_open_flag
        jsr     MaybeOpenWindow
        lda     #0
        sta     main::copy_new_window_bounds_flag
        sta     main::OpenDirectory::suppress_error_on_open_flag

next:   jsr     PopPointers

        add16_8 data_ptr, #.sizeof(DeskTopFileItem)
        jmp     loop

exit:   jmp     main::LoadDesktopEntryTable

.proc MaybeOpenWindow
        ;; Save stack for restore on error. If the call
        ;; fails, the routine will restore the stack then
        ;; rts, returning to our caller.
        tsx
        stx     saved_stack
        jmp     main::OpenWindowForPath
.endproc ; MaybeOpenWindow

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

        .include "../lib/detect_lcmeve.s"
        .include "../lib/clear_dhr.s"
        saved_ram_unitnum := main::saved_ram_unitnum
        saved_ram_drvec   := main::saved_ram_drvec
        .include "../lib/disconnect_ram.s"

;;; ============================================================


.endscope ; init

        ENDSEG SegmentInitializer
