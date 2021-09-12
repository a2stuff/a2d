;;; ============================================================
;;; DeskTop - Initialization
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

        RESOURCE_FILE "init.res"

;;; ============================================================
;;; Segment loaded into MAIN $800-$FFF
;;; ============================================================

;;;            Main                  Aux
;;;       :.............:       :.............:
;;;       |.............|       |.............|
;;;       |.............|       |.............|
;;;       |.Graphics....|       |.Graphics....|
;;; $2000 +-------------+       +-------------+
;;;       | I/O Buffer  |       | Win/Icn Map | <- initialized
;;; $1C00 +-------------+       |             |
;;; $1B00 |             |       +-------------+
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


;;; NOTE: if DeskTop2 file is extended in length, there is room for
;;; this segment to grow by moving buffers up by a few pages.

;;; Init sequence - machine identification, etc
;;;
;;; * Hook reset vector
;;; * Clear hires screen
;;; * Detect machine type
;;; * Preserve DEVLST, remove /RAM
;;; * Initialize MGTK, with saved settings
;;; * Initialize icon entry map in LC and window/icon maps in Aux
;;; * Load selector list, populate Selector menu
;;; * Enumerate desk accessories, populate Apple menu
;;; * Compute label widths
;;; * Create desktop icons, populate device name table
;;; * Populate startup menu
;;; * Identify removable disks, for later polling
;;; * Configure MGTK
;;; * Restore saved windows

.proc init

        .org ::kSegmentInitializerAddress

        MLIRelayImpl := main::MLIRelayImpl

        data_buf := $1200
        kDataBufferSize = $400

start:

;;; ============================================================
;;; Set the reset vector to cold start
.scope hook_reset_vector

        ;; Main hook
        lda     #<main::reset_handler
        sta     SOFTEV
        lda     #>main::reset_handler
        sta     SOFTEV+1
        eor     #$A5
        sta     SOFTEV+2

.endscope

;;; ============================================================
;;; Clear DHR screen to black before it is shown

.scope clear_screen
        ptr := $6
        HIRES_ADDR = $2000
        kHiresSize = $2000

        sta     PAGE2ON         ; Clear aux
        jsr     clear
        sta     PAGE2OFF        ; Clear main
        jsr     clear
        jmp     done

clear:  copy16  #HIRES_ADDR, ptr
        lda     #0              ; clear to black
        ldx     #>kHiresSize    ; number of pages
        ldy     #0              ; pointer within page
:       sta     (ptr),y
        iny
        bne     :-
        inc     ptr+1
        dex
        bne     :-
        rts

done:
.endscope

;;; ============================================================
;;; Snapshot state of PB2 (shift key mod)

.scope pb2_state
        copy    BUTN2, main::pb2_initial_state
.endscope

;;; ============================================================
;;; Detect Le Chat Mauve Eve RGB card

.scope lcm
        jsr     DetectLeChatMauveEve
        bne     :+
        copy    #$80, main::lcm_eve_flag
:
.endscope

;;; ============================================================
;;; Detect Machine Type - set flags and periodic task delay

;;; NOTE: Starts with ROM paged in, exits with LCBANK1 paged in.

.scope machine_type
        ;; See Apple II Miscellaneous #7: Apple II Family Identification

        ;; First, detect IIgs
        sec                     ; Follow detection protocol
        jsr     IDROUTINE       ; RTS on pre-IIgs
        bcs     :+              ; carry clear = IIgs
        copy    #$80, is_iigs_flag
:
        ;; Now stash the bytes we need
        copy    VERSION, id_version ; $06 = IIe or later
        copy    ZIDBYTE, id_idbyte ; $00 = IIc or later
        copy    ZIDBYTE2, id_idbyte2 ; IIc ROM version (IIc+ = $05)
        copy    IDBYTELASER128, id_idlaser ; $AC = Laser 128

        ;; ... and page in LCBANK1
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        ;; Ensure we're on a IIe or later
        lda     id_version
        cmp     #$06            ; Ensure a IIe or later
        beq     :+
        brk                     ; Otherwise (][, ][+, ///), just crash

        ;; State needed by MGTK
:       copy    id_version, startdesktop_params::machine
        copy    id_idbyte, startdesktop_params::subid

        ;; Identify machine type (periodic delays and other flags)
        lda     id_idbyte
        beq     is_iic          ; $FBC0 = $00 -> is IIc or IIc+
        bit     is_iigs_flag
        bmi     is_iigs

        ;; Laser 128?
        lda     id_idlaser           ; Is it a Laser 128?
        cmp     #$AC
        bne     is_iie

        copy    #$80, is_laser128_flag
        lda     #kPeriodicTaskDelayIIgs ; Assume accelerated???
        bne     end                     ; always

        ;; IIe (or IIe Option Card)
is_iie: lda     #kPeriodicTaskDelayIIe
        bne     end             ; always

        ;; IIgs
is_iigs:
        lda     #kPeriodicTaskDelayIIgs
        bne     end             ; always

        ;; IIc or IIc+
is_iic: lda     id_idbyte2            ; ROM version
        cmp     #$05                  ; IIc Plus = $05
        bne     :+
        copy    #$80, is_iic_plus_flag
:       lda     #kPeriodicTaskDelayIIc

end:
        sta     periodic_task_delay

        ;; Fall through
.endscope

;;; ============================================================
;;; Back up DEVLST

.scope
        ;; Make a copy of the original device list
        ldx     DEVCNT          ; number of devices
        inx                     ; include DEVCNT itself
:       lda     DEVLST-1,x      ; DEVCNT is at DEVLST-1
        sta     devlst_backup,x
        dex
        bpl     :-
        ;; fall through
.endscope

;;; ============================================================
;;; Detach aux-memory RAM Disk

.scope
        ;; Look for /RAM
        ldx     DEVCNT
:       lda     DEVLST,x
        and     #%11110000      ; DSSSnnnn
        cmp     #$B0            ; Slot 3, Drive 2 = /RAM
        beq     found_ram
        dex
        bpl     :-
        bmi     end

found_ram:
        jsr     remove_device
        ;; fall through

end:
.endscope

;;; ============================================================
;;; Initialize MGTK

.scope
        MGTK_RELAY_CALL MGTK::SetDeskPat, SETTINGS + DeskTopSettings::pattern
        MGTK_RELAY_CALL MGTK::StartDeskTop, startdesktop_params
        MGTK_RELAY_CALL MGTK::InitMenu, initmenu_params
        jsr     main::SetRGBMode
        MGTK_RELAY_CALL MGTK::SetMenu, splash_menu

        ;; --------------------------------------------------
        ;; Cursor tracking

        ;; Doubled if option selected
        lda     SETTINGS + DeskTopSettings::mouse_tracking
        IF_NOT_ZERO
        inc     scalemouse_params::x_exponent
        inc     scalemouse_params::y_exponent
        END_IF
        ;; Also doubled if a IIc
        lda     id_idbyte       ; ZIDBYTE=0 for IIc / IIc+
        IF_ZERO
        inc     scalemouse_params::x_exponent
        inc     scalemouse_params::y_exponent
        END_IF
        MGTK_RELAY_CALL MGTK::ScaleMouse, scalemouse_params

        ;; --------------------------------------------------

        MGTK_RELAY_CALL MGTK::SetCursor, watch_cursor
        MGTK_RELAY_CALL MGTK::ShowCursor

        ;; fall through
.endscope

;;; ============================================================
;;; Populate icon_entries table

.scope
        ptr := $6

        jsr     main::push_pointers
        copy16  #icon_entries, ptr
        ldx     #1
loop:   cpx     #kMaxIconCount+1 ; allow up to the maximum
        bne     :+
        jsr     main::pop_pointers
        jmp     end
:       txa
        pha
        asl     a
        tax
        copy16  ptr, icon_entry_address_table,x
        pla
        pha
        ldy     #0
        sta     (ptr),y
        iny
        copy    #0, (ptr),y
        lda     ptr
        clc
        adc     #.sizeof(IconEntry)
        sta     ptr
        bcc     :+
        inc     ptr+1
:       pla
        tax
        inx
        jmp     loop
end:
.endscope

;;; ============================================================
;;; Zero the window icon tables

.scope
        sta     RAMWRTON
        lda     #$00
        tax
loop:   sta     WINDOW_ENTRY_TABLES + $400,x         ; window 8, icon use map
        sta     WINDOW_ENTRY_TABLES + $300,x         ; window 6, 7
        sta     WINDOW_ENTRY_TABLES + $200,x         ; window 4, 5
        sta     WINDOW_ENTRY_TABLES + $100,x         ; window 2, 3
        sta     WINDOW_ENTRY_TABLES + $000,x         ; window 0, 1 (0=desktop)
        inx
        bne     loop
        sta     RAMWRTOFF
        jmp     create_trash_icon
.endscope

;;; ============================================================

trash_name:  PASCAL_STRING res_string_trash_icon_name

.proc create_trash_icon
        ptr := $6

        copy    #0, cached_window_id
        lda     #1
        sta     cached_window_entry_count
        sta     icon_count
        jsr     AllocateIcon
        sta     trash_icon_num
        sta     cached_window_entry_list
        jsr     main::icon_entry_lookup
        stax    ptr
        ldy     #IconEntry::win_type
        copy    #kIconEntryTypeTrash, (ptr),y

        ldy     #IconEntry::iconx
        copy16in #kTrashIconX, (ptr),y
        ldy     #IconEntry::icony
        copy16in #kTrashIconY, (ptr),y
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
        ;; fall through
.endproc

;;; ============================================================


;;; See docs/Selector_List_Format.md for file format

.proc load_selector_list
        ptr1 := $6
        ptr2 := $8

        selector_list_io_buf := IO_BUFFER
        selector_list_data_buf := data_buf
        kSelectorListShortSize = $400
        .assert kSelectorListShortSize <= kDataBufferSize, error, "Buffer size error"

        MGTK_RELAY_CALL MGTK::CheckEvents

        copy    #0, L0A92
        jsr     read_selector_list
        bne     done

        lda     selector_list_data_buf
        clc
        adc     selector_list_data_buf+1
        sta     num_selector_list_items

        copy    #0, selector_menu_items_updated_flag

        lda     selector_list_data_buf
        sta     L0A93
L0A3B:  lda     L0A92
        cmp     L0A93
        beq     done
        jsr     calc_data_addr
        stax    ptr1
        lda     L0A92
        jsr     calc_entry_addr
        stax    ptr2
        ldy     #0
        lda     (ptr1),y
        tay
L0A59:  lda     (ptr1),y
        sta     (ptr2),y
        dey
        bpl     L0A59
        ldy     #15
        lda     (ptr1),y
        sta     (ptr2),y
        lda     L0A92
        jsr     calc_data_str
        stax    ptr1
        lda     L0A92
        jsr     calc_entry_str
        stax    ptr2
        ldy     #0
        lda     (ptr1),y
        tay
L0A7F:  lda     (ptr1),y
        sta     (ptr2),y
        dey
        bpl     L0A7F
        inc     L0A92
        inc     selector_menu
        jmp     L0A3B

done:   jmp     calc_header_item_widths

L0A92:  .byte   0
L0A93:  .byte   0
        .byte   0

;;; --------------------------------------------------

calc_data_addr:
        jsr     main::a_times_16
        clc
        adc     #<(selector_list_data_buf+2)
        tay
        txa
        adc     #>(selector_list_data_buf+2)
        tax
        tya
        rts

calc_entry_addr:
        jsr     main::a_times_16
        clc
        adc     #<run_list_entries
        tay
        txa
        adc     #>run_list_entries
        tax
        tya
        rts

calc_entry_str:
        jsr     main::a_times_64
        clc
        adc     #<run_list_paths
        tay
        txa
        adc     #>run_list_paths
        tax
        tya
        rts

calc_data_str:
        jsr     main::a_times_64
        clc
        adc     #<(selector_list_data_buf+2 + $180)
        tay
        txa
        adc     #>(selector_list_data_buf+2 + $180)
        tax
        tya
        rts

;;; --------------------------------------------------

        DEFINE_OPEN_PARAMS open_params, str_selector_list, selector_list_io_buf

str_selector_list:
        PASCAL_STRING kFilenameSelectorList

        DEFINE_READ_PARAMS read_params, selector_list_data_buf, kSelectorListShortSize
        DEFINE_CLOSE_PARAMS close_params

.proc read_selector_list
        MLI_RELAY_CALL OPEN, open_params
        ;;         bne     done
        bne     write_selector_list

        lda     open_params::ref_num
        sta     read_params::ref_num
        MLI_RELAY_CALL READ, read_params
        MLI_RELAY_CALL CLOSE, close_params
done:   rts
.endproc

        DEFINE_CREATE_PARAMS create_params, str_selector_list, ACCESS_DEFAULT, $F1
        DEFINE_WRITE_PARAMS write_params, selector_list_data_buf, kSelectorListShortSize

.proc write_selector_list
        ptr := $06

        ;; Clear buffer
        copy16  #selector_list_data_buf, ptr
        ldx     #>kSelectorListShortSize ; number of pages
        lda     #0
ploop:  ldy     #0
:       sta     (ptr),y
        dey
        bne     :-
        dex
        bne     ploop

        ;; Write out file
        MLI_RELAY_CALL CREATE, create_params
        bne     done
        MLI_RELAY_CALL OPEN, open_params
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        MLI_RELAY_CALL WRITE, write_params ; two blocks of $400
        MLI_RELAY_CALL WRITE, write_params
        MLI_RELAY_CALL CLOSE, close_params

done:   rts
.endproc

.endproc

;;; ============================================================

.proc calc_header_item_widths
        ;; Enough space for "123,456"
        param_call main::measure_text1, str_from_int
        stax    dx

        ;; Width of "123,456 Items"
        param_call main::measure_text1, str_items_suffix
        addax   dx, width_items_label

        ;; Width of "123,456K in disk"
        param_call main::measure_text1, str_k_in_disk
        addax   dx, width_k_in_disk_label

        ;; Width of "123,456K available"
        param_call main::measure_text1, str_k_available
        addax   dx, width_k_available_label

        add16   width_k_in_disk_label, width_k_available_label, width_right_labels
        add16   width_items_label, #5, width_items_label_padded
        add16   width_items_label_padded, width_k_in_disk_label, width_left_labels
        add16   width_left_labels, #3, width_left_labels
        jmp     end

dx:     .word   0

end:
.endproc

;;; ============================================================
;;; Enumerate Desk Accessories

.scope
        MGTK_RELAY_CALL MGTK::CheckEvents

        read_dir_buffer := data_buf

        ;; Does the directory exist?
        MLI_RELAY_CALL GET_FILE_INFO, get_file_info_params
        beq     :+
        jmp     end

:       lda     get_file_info_type
        cmp     #FT_DIRECTORY
        beq     open_dir
        jmp     end

open_dir:
        MLI_RELAY_CALL OPEN, open_params
        lda     open_ref_num
        sta     read_ref_num
        sta     close_ref_num
        MLI_RELAY_CALL READ, read_params

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
        MLI_RELAY_CALL READ, read_params
        copy16  #read_dir_buffer + 4, dir_ptr

        lda     #0
        sta     entry_in_block
        jmp     process_block

:       add16_8 dir_ptr, entry_length, dir_ptr
        jmp     process_block

close_dir:
        MLI_RELAY_CALL CLOSE, close_params
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

        kNumAppleMenuTypes = 7
apple_menu_type_table:
        .byte   FT_SYSTEM, FT_S16, FT_BINARY, FT_BASIC ; Executable
        .byte   FT_TEXT, FT_GRAPHICS, FT_FONT          ; Previewable
        ASSERT_TABLE_SIZE apple_menu_type_table, kNumAppleMenuTypes

end:
.endscope

;;; ============================================================
;;; Populate volume icons and device names

;;; TODO: Dedupe with cmd_check_drives

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
        jsr     main::create_volume_icon ; A = unit number, Y = device index
        sta     cvi_result
        MGTK_RELAY_CALL MGTK::CheckEvents

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

        ;; TODO: Figure out if this block makes any sense.
        ldy     device_index
        lda     DEVLST,y
        and     #$0F            ; BUG: Do not trust low nibble of unit_num
        beq     select_template ; "0 = Disk II" originally
        ldx     device_index
        jsr     remove_device
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

        jsr     main::get_device_type
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
        bmi     populate_startup_menu
:       jmp     process_volume  ; next!

device_type:
        .byte   0
device_index:
        .byte   0
cvi_result:
        .byte   0
.endscope

;;; ============================================================

        ;; Remove device num in X from devices list
.proc remove_device
        dex
:       inx
        copy    DEVLST+1,x, DEVLST,x
        copy    device_to_icon_map+1,x, device_to_icon_map,x
        cpx     DEVCNT
        bne     :-
        dec     DEVCNT
        rts
.endproc

;;; ============================================================

.proc populate_startup_menu
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
        sta     startup_slot_table,x

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
        jmp     initialize_disks_in_devices_tables

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
.endproc

;;; ============================================================
;;; Enumerate DEVLST and find removable devices; build a list of
;;; these, and check to see which have disks in them. The list
;;; will be polled periodically to detect changes and refresh.
;;; List is built in DEVLST order since processing is in
;;; `check_disks_in_devices` (etc) is done in reverse order.
;;;
;;; Some hardware (machine/slot) combinations are filtered out
;;; due to known-buggy firmware.

.proc initialize_disks_in_devices_tables
        slot_ptr := $0A

        lda     #0
        sta     count
        sta     index

loop:   ldy     index
        lda     DEVLST,y
        jsr     main::DeviceDriverAddress
        bne     next            ; if RAM-based driver (not $CnXX), skip
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
        jsr     main::check_disks_in_devices

        ;; Make copy of table
        ldx     main::disk_in_device_table
        beq     done
:       copy    main::disk_in_device_table,x, main::last_disk_in_devices_table,x
        dex
        bpl     :-

done:   jmp     final_setup

        ;; Maybe add device to the removable device table
append: ldy     index
        lda     DEVLST,y

        ;; Don't issue STATUS calls to IIc Plus Slot 5 firmware, as it causes
        ;; the motor to spin. https://github.com/a2stuff/a2d/issues/25
        bit     is_iic_plus_flag
        bpl     :+
        and     #%01110000      ; mask off slot
        cmp     #$50            ; is it slot 5?
        beq     next            ; if so, ignore

        ;; Don't issue STATUS calls to Laser 128 Slot 7 firmware, as it causes
        ;; hangs in some cases. https://github.com/a2stuff/a2d/issues/138
:       bit     is_laser128_flag
        bpl     :+
        and     #%01110000      ; mask off slot
        cmp     #$70            ; is it slot 7?
        beq     next            ; if so, ignore

:       lda     DEVLST,y

        inc     count
        ldx     count
        sta     main::removable_device_table,x
        bne     next            ; always

index:  .byte   0
count:  .byte   0
.endproc

;;; ============================================================

.proc final_setup
        ;; Final MGTK configuration
        MGTK_RELAY_CALL MGTK::CheckEvents
        MGTK_RELAY_CALL MGTK::SetMenu, aux::desktop_menu
        MGTK_RELAY_CALL MGTK::SetCursor, pointer_cursor
        lda     #0
        sta     active_window_id
        jsr     main::update_window_menu_items
        jsr     main::disable_menu_items_requiring_volume_selection
        jsr     main::disable_menu_items_requiring_file_selection
        jsr     main::disable_menu_items_requiring_selection

        ;; Add desktop icons
        ldx     #0
iloop:  cpx     cached_window_entry_count
        beq     :+
        txa
        pha
        lda     cached_window_entry_list,x
        sta     icon_param
        jsr     main::icon_entry_lookup
        stax    @addr
        ITK_RELAY_CALL IconTK::AddIcon, 0, @addr
        ITK_RELAY_CALL IconTK::RedrawIcon, icon_param ; CHECKED (desktop)
        pla
        tax
        inx
        jmp     iloop
:
        ;; Desktop icons are cached now
        copy    #0, cached_window_id
        jsr     StoreWindowEntryTable

        ;; Restore state from previous session
        jsr     restore_windows

        ;; Display any pending error messages
        lda     main::pending_alert
        beq     :+
        tay
        jsr     ShowAlert
:

        ;; And start pumping events
        jmp     main::main_loop
.endproc

;;; ============================================================

.proc restore_windows
        data_ptr := $06

        jsr     main::save_restore_windows::open
        bcs     exit
        lda     main::save_restore_windows::open_params::ref_num
        sta     main::save_restore_windows::read_params::ref_num
        sta     main::save_restore_windows::close_params::ref_num
        MLI_RELAY_CALL READ, main::save_restore_windows::read_params
        jsr     main::save_restore_windows::close

        ;; Validate version bytes
        lda     main::save_restore_windows::desktop_file_data_buf
        cmp     #kDeskTopFileVersion
        bne     exit
        copy16  #main::save_restore_windows::desktop_file_data_buf+1, data_ptr

loop:   ldy     #0
        lda     (data_ptr),y
        beq     exit

        ;; Copy path to `open_dir_path_buf`
        tay
:       lda     (data_ptr),y
        sta     open_dir_path_buf,y
        dey
        bpl     :-

        ;; Copy bounds to `tmp_rect`
        ldy     #DeskTopFileItem::rect+.sizeof(MGTK::Rect)-1
        ldx     #.sizeof(MGTK::Rect)-1
:       lda     (data_ptr),y
        sta     tmp_rect,x
        dey
        dex
        bpl     :-

        jsr     main::push_pointers

        lda     #$80
        sta     main::copy_new_window_bounds_flag
        sta     main::open_directory::suppress_error_on_open_flag
        jsr     maybe_open_window
        lda     #0
        sta     main::copy_new_window_bounds_flag
        sta     main::open_directory::suppress_error_on_open_flag

        jsr     main::pop_pointers

        add16_8 data_ptr, #.sizeof(DeskTopFileItem), data_ptr
        jmp     loop

exit:   jsr     LoadDesktopEntryTable
        rts

.proc maybe_open_window
        ;; Save stack for restore on error. If the call
        ;; fails, the routine will restore the stack then
        ;; rts, returning to our caller.
        tsx
        stx     saved_stack
        jmp     main::open_window_for_path
.endproc

.endproc

;;; ============================================================

;;; ID bytes, copied from ROM
id_idlaser:     .byte   0
id_version:     .byte   0
id_idbyte:      .byte   0
id_idbyte2:     .byte   0

;;; High bits set if specific machine type detected.
is_iigs_flag:
        .byte   0
is_iic_plus_flag:
        .byte   0
is_laser128_flag:
        .byte   0

;;; ============================================================

kDeviceTemplateSlotOffset = res_const_sd_prefix_pattern_offset1
kDeviceTemplateDriveOffset = res_const_sd_prefix_pattern_offset2

kSDPrefixLength = .strlen(res_string_sd_prefix_pattern)
str_sdname_buffer:
        PASCAL_STRING res_string_sd_prefix_pattern ; "S#,D#: " prefix
        .res    16, 0              ; space for actual name

str_volume_type_unknown:
        PASCAL_STRING res_string_volume_type_unknown

;;; ============================================================

        .include "../lib/detect_lcmeve.s"

;;; ============================================================


        PAD_TO ::kSegmentInitializerAddress + ::kSegmentInitializerLength

.endproc ; init
