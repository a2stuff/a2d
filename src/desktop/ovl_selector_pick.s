;;; ============================================================
;;; Overlay for Selector Picker
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

;;; See docs/Selector_List_Format.md for file format

        BEGINSEG OverlayShortcutPick

.scope SelectorPickOverlay

        MLIEntry := main::MLIRelayImpl
        MGTKEntry := MGTKRelayImpl
        BTKEntry := BTKRelayImpl
        OPTKEntry := OPTKRelayImpl

io_buf := $0800

selector_list := SELECTOR_FILE_BUF

        .assert SELECTOR_FILE_BUF + kSelectorListBufSize = $1400, error, "constants"
PARAM_BLOCK, $1400
orig_prefix     .res    ::kSelectorListBufSize
current_prefix  .res    ::kPathBufferSize

;;; Table for 24 entries; index (0...23) if in use, $FF if empty
entries_flag_table .res ::kSelectorListNumEntries
END_PARAM_BLOCK

Exec:
        sta     selector_action
        ldx     #$FF            ; `INC` to clear high bit
        stx     clean_flag      ; set "clean"
        cmp     #SelectorAction::add
        beq     DoAdd
        jmp     Init

;;; ============================================================

.proc Exit
        pha                     ; A = result
    IF lda clean_flag : NC
        ;; Update total count of entries (used for menu item states)
        lda     selector_list + kSelectorListNumPrimaryRunListOffset
        clc
        adc     selector_list + kSelectorListNumSecondaryRunListOffset
        sta     num_selector_list_items

        ;; First time - ask if we should even try.
        CLEAR_BIT7_FLAG retry_flag

        ;; Write to desktop current prefix
        jsr     _DoWrite
        bcs     done

        ;; Write to the original file location, if necessary.
        jsr     main::GetCopiedToRAMCardFlag
      IF ZC
        CALL    main::CopyDeskTopOriginalPrefix, AX=#orig_prefix
        MLI_CALL GET_PREFIX, current_prefix_params
retry:
        MLI_CALL SET_PREFIX, orig_prefix_params
       IF CS
        jsr     _CheckRetry
        beq     retry
        bne     done            ; always
       END_IF
        jsr     _DoWrite
        MLI_CALL SET_PREFIX
        JUMP_TABLE_MLI_CALL SET_PREFIX, current_prefix_params
        ;; Assert: Succeeded (otherwise RAMCard was deleted out from under us)
      END_IF
    END_IF

done:
        pla                     ; A = result
        rts
.endproc ; Exit

;;; ============================================================

DoAdd:  ldx     #kRunListPrimary
        lda     selector_menu
    IF A >= #kSelectorMenuFixedItems + 8
        inx                     ; `kRunListSecondary`
    END_IF

        lda     #$00
        sta     text_input_buf  ; clear name, but leave path alone
        ldy     #kCopyNever | $80 ; high bit set = Add

        ;; A = (obsolete, was dialog type)
        ;; Y = is_add_flag | copy_when
        ;; X = which_run_list
        jsr     ::SelectorEditOverlay::Run
        pha
        txa
        pha
        tya
        pha
        COPY_STRING text_input_buf, main::stashed_name
        jsr     main::ClearUpdates ; File Dialog close
        pla
        tay
        pla
        tax
        pla
        bne     Exit

        stx     which_run_list
        ;; Map to `kCopyOnBoot` to `kSelectorEntryCopyOnBoot` etc
        copy8   copy_when_conversion_table-1,y, copy_when

        jsr     ReadFile
    IF NS
        jmp     Exit
    END_IF

        copy16  selector_list, num_primary_run_list_entries

    IF lda which_run_list : A = #kRunListPrimary
        lda     num_primary_run_list_entries
        cmp     #kSelectorListNumPrimaryRunListEntries
        beq     ShowFullAlert
        ldy     copy_when       ; Flags
        lda     num_primary_run_list_entries
        inc     selector_list + kSelectorListNumPrimaryRunListOffset
        jsr     AssignEntryData
        inc     clean_flag      ; mark as "dirty"
        jmp     Exit
    END_IF

        lda     num_secondary_run_list_entries
    IF A <> #kSelectorListNumSecondaryRunListEntries
        ldy     copy_when       ; Flags
        lda     num_secondary_run_list_entries
        clc
        adc     #kSelectorListNumPrimaryRunListEntries
        jsr     AssignEntryData
        inc     selector_list + kSelectorListNumSecondaryRunListOffset
        inc     clean_flag      ; mark as "dirty"
        jmp     Exit
    END_IF

ShowFullAlert:
        CALL    ShowAlertParams, Y=#AlertButtonOptions::OK, AX=#aux::str_warning_selector_list_full
        jmp     Exit

which_run_list:
        .byte   0
copy_when:
        .byte   0

;;; ============================================================

.proc Init
        lda     #$00
        sta     num_primary_run_list_entries
        sta     num_secondary_run_list_entries
        copy8   #$FF, shortcut_picker_record::selected_index
        copy8   #BTK::kButtonStateDisabled, entry_picker_ok_button::state

        jsr     OpenWindow
        jsr     ReadFile
    IF NS
        jmp     DoCancel
    END_IF

        copy8   selector_list + kSelectorListNumPrimaryRunListOffset, num_primary_run_list_entries
        copy8   selector_list + kSelectorListNumSecondaryRunListOffset, num_secondary_run_list_entries
        jsr     PopulateEntriesFlagTable

        OPTK_CALL OPTK::Draw, shortcut_picker_params

        FALL_THROUGH_TO dialog_loop
.endproc ; Init

dialog_loop:
        jsr     EventLoop
        bmi     dialog_loop     ; N set = nothing selected, re-enter loop

        jne     DoCancel        ; Z set = OK selected

        ;; Which action are we?
        lda     shortcut_picker_record::selected_index
        bmi     dialog_loop
        lda     selector_action
        cmp     #SelectorAction::edit
        beq     DoEdit

        cmp     #SelectorAction::delete
        beq     DoDelete

        cmp     #SelectorAction::run
        bne     dialog_loop
        jmp     DoRun

;;; ============================================================

.proc DoDelete
        jsr     CloseWindow
        jsr     main::ClearUpdates ; Shortcut Picker dialog close

        CALL    RemoveEntry, A=shortcut_picker_record::selected_index
        inc     clean_flag      ; mark as "dirty"
        jmp     Exit
.endproc ; DoDelete

;;; ============================================================

.proc DoEdit
        jsr     CloseWindow
        ;; Could do `ClearUpdates` here, but not worth it since file
        ;; dialog is larger than the shortcut picker dialog.

        CALL    GetFileEntryAddr, A=shortcut_picker_record::selected_index
        stax    $06
        CALL    main::CopyPtr1ToBuf, AX=#text_input_buf

        ldy     #kSelectorEntryFlagsOffset
        lda     ($06),y
        sta     flags

        CALL    GetFilePathAddr, A=shortcut_picker_record::selected_index
        jsr     main::CopyToBuf0

        ldx     #kRunListPrimary
        lda     shortcut_picker_record::selected_index
        cmp     #kSelectorListNumPrimaryRunListEntries
    IF GE
        inx                     ; `kRunListSecondary`
    END_IF

        ;; Map to `kSelectorEntryCopyOnBoot` to `kCopyOnBoot` etc
        .define swizzle(n) (n >> 7) + 1 + (n > 127)
        .assert swizzle kSelectorEntryCopyOnBoot = kCopyOnBoot, error, "const mismatch"
        .assert swizzle kSelectorEntryCopyOnUse  = kCopyOnUse,  error, "const mismatch"
        .assert swizzle kSelectorEntryCopyNever  = kCopyNever,  error, "const mismatch"
        clc
        lda     flags
        rol     a
        rol     a
        adc     #1
        tay

        ;; A = (obsolete, was dialog type)
        ;; Y = is_add_flag | copy_when
        ;; X = which_run_list
        jsr     ::SelectorEditOverlay::Run
        pha
        txa
        pha
        tya
        pha
        COPY_STRING text_input_buf, main::stashed_name
        jsr     main::ClearUpdates ; File Dialog close
        pla
        tay
        pla
        tax
        pla
        RTS_IF NOT_ZERO

        stx     which_run_list
        ;; Map to `kCopyOnBoot` to `kSelectorEntryCopyOnBoot` etc
        copy8   copy_when_conversion_table-1,y, copy_when

        jsr     ReadFile
    IF NS
        jmp     Exit
    END_IF

        lda     shortcut_picker_record::selected_index
    IF A >= #kSelectorListNumPrimaryRunListEntries
        ;; Was on secondary run list - is it still?
        lda     which_run_list
        cmp     #kRunListSecondary
        beq     reuse_same_index

        lda     num_primary_run_list_entries
      IF A = #kSelectorListNumPrimaryRunListEntries
        jmp     ShowFullAlert
      END_IF

        CALL    RemoveEntry, A=shortcut_picker_record::selected_index

        ;; Compute new index
        ldx     num_primary_run_list_entries
        inc     num_primary_run_list_entries
        inc     selector_list + kSelectorListNumPrimaryRunListOffset
        txa
    ELSE
        ;; Was on primary run list - is it still?
        lda     which_run_list
        cmp     #kRunListPrimary
        beq     reuse_same_index

        lda     num_secondary_run_list_entries
      IF A = #kSelectorListNumSecondaryRunListEntries
        jmp     ShowFullAlert
      END_IF

        CALL    RemoveEntry, A=shortcut_picker_record::selected_index

        ;; Compute new index
        ldx     num_secondary_run_list_entries
        inc     num_secondary_run_list_entries
        inc     selector_list + kSelectorListNumSecondaryRunListOffset
        lda     num_secondary_run_list_entries
        clc
        adc     #$07
        jmp     :+

reuse_same_index:
        lda     shortcut_picker_record::selected_index
:
    END_IF

        CALL    AssignEntryData, Y=copy_when
        inc     clean_flag      ; mark as "dirty"
        jmp     Exit

flags:  .byte   0

.endproc ; DoEdit

;;; ============================================================

        ;; Index is `kCopyXXX-1`, value is `kSelectorEntryCopyXXX`
copy_when_conversion_table:
        .byte   kSelectorEntryCopyOnBoot
        .byte   kSelectorEntryCopyOnUse
        .byte   kSelectorEntryCopyNever

;;; ============================================================

.proc DoRun
        jsr     CloseWindow
        jsr     main::ClearUpdates ; Shortcut Picker dialog close

        RETURN  A=shortcut_picker_record::selected_index
.endproc ; DoRun

;;; ============================================================
;;; Cancel from Edit, Delete, or Run
;;; Also OK from Delete (since that closes immediately)

.proc DoCancel
        jsr     CloseWindow
        jsr     main::ClearUpdates ; Shortcut Picker dialog close

        TAIL_CALL Exit, A=#$FF
.endproc ; DoCancel

;;; ============================================================

.proc CloseWindow
        MGTK_CALL MGTK::CloseWindow, winfo_entry_picker

        rts
.endproc ; CloseWindow

;;; ============================================================

num_primary_run_list_entries:
        .byte   0
num_secondary_run_list_entries:
        .byte   0

selector_action:
        .byte   0

clean_flag:                     ; high bit set if "clean", cleared if "dirty"
        .byte   0               ; and should write out file

;;; ============================================================

.proc OpenWindow
        MGTK_CALL MGTK::OpenWindow, winfo_entry_picker
        CALL    main::SafeSetPortFromWindowId, A=#winfo_entry_picker::kWindowId
        jsr     main::SetPenModeNotCopy
        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, entry_picker_frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        MGTK_CALL MGTK::MoveTo, entry_picker_line1_start
        MGTK_CALL MGTK::LineTo, entry_picker_line1_end
        MGTK_CALL MGTK::MoveTo, entry_picker_line2_start
        MGTK_CALL MGTK::LineTo, entry_picker_line2_end

        BTK_CALL BTK::Draw, entry_picker_ok_button
        BTK_CALL BTK::Draw, entry_picker_cancel_button

        lda     selector_action
    IF A = #SelectorAction::edit
        TAIL_CALL DrawTitleCentered, AX=#label_edit
    END_IF

    IF A = #SelectorAction::delete
        TAIL_CALL DrawTitleCentered, AX=#label_del
    END_IF

        TAIL_CALL DrawTitleCentered, AX=#label_run
.endproc ; OpenWindow

;;; ============================================================

.proc DrawTitleCentered
        params := $06
        str := params
        width := params+2

        stax    str
        stax    @addr
        MGTK_CALL MGTK::StringWidth, params

        sub16   #winfo_entry_picker::kWidth, width, pos_dialog_title::xcoord
        lsr16   pos_dialog_title::xcoord ; /= 2
        MGTK_CALL MGTK::MoveTo, pos_dialog_title
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        rts
.endproc ; DrawTitleCentered

;;; ============================================================
;;; When returning from event loop:
;;; N = nothing selected, re-enter loop
;;; Z = OK selected
;;; Otherwise: Cancel selected

.proc EventLoop
        jsr     ::main::SystemTask
        jsr     main::GetEvent

        cmp     #MGTK::EventKind::button_down
        beq     handle_button

        cmp     #MGTK::EventKind::key_down
        bne     EventLoop
        jmp     HandleKey

handle_button:
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
    IF ZERO
        RETURN  A=#$FF
    END_IF

    IF A <> #MGTK::Area::content
        RETURN  A=#$FF
    END_IF

        lda     findwindow_params::window_id
    IF A <> winfo_entry_picker
        RETURN  A=#$FF
    END_IF

        lda     #winfo_entry_picker::kWindowId
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        MGTK_CALL MGTK::InRect, entry_picker_ok_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, entry_picker_ok_button
      IF NC
        lda     #$00            ; OK selected
      END_IF
        rts
    END_IF

        MGTK_CALL MGTK::InRect, entry_picker_cancel_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, entry_picker_cancel_button
      IF NC
        lda     #$01            ; cancel selected
      END_IF
        rts
    END_IF

        COPY_STRUCT screentowindow_params::window, shortcut_picker_params::coords
        OPTK_CALL OPTK::Click, shortcut_picker_params
    IF NC
        jsr     DetectDoubleClick
      IF NC
        pha
        BTK_CALL BTK::Flash, entry_picker_ok_button
        pla
      END_IF
    END_IF

        rts
.endproc ; EventLoop

;;; ============================================================
;;; Key down handler

.proc HandleKey
        lda     event_params::modifiers
    IF A = #MGTK::event_modifier_solid_apple
        RETURN  A=#$FF
    END_IF

        lda     event_params::key

        cmp     #CHAR_RETURN
        beq     HandleKeyReturn

        cmp     #CHAR_ESCAPE
        beq     HandleKeyEscape

        lda     num_primary_run_list_entries
        ora     num_secondary_run_list_entries
    IF NOT_ZERO
        lda     event_params::key
      IF A IN #CHAR_UP, #CHAR_DOWN, #CHAR_LEFT, #CHAR_RIGHT
        sta     shortcut_picker_params::key
        OPTK_CALL OPTK::Key, shortcut_picker_params
      END_IF
    END_IF

        RETURN  A=#$FF
.endproc ; HandleKey

;;; ============================================================

.proc HandleKeyReturn
        BTK_CALL BTK::Flash, entry_picker_ok_button
    IF NS
        RETURN  A=#$FF          ; ignore
    END_IF
        RETURN  A=#0
.endproc ; HandleKeyReturn

;;; ============================================================

.proc HandleKeyEscape
        BTK_CALL BTK::Flash, entry_picker_cancel_button
        RETURN  A=#1
.endproc ; HandleKeyEscape

;;; ============================================================

.proc UpdateOKButton
        lda     #BTK::kButtonStateNormal
    IF bit shortcut_picker_record::selected_index : NS
        lda     #BTK::kButtonStateDisabled
    END_IF

    IF A <> entry_picker_ok_button::state
        sta     entry_picker_ok_button::state
        BTK_CALL BTK::Hilite, entry_picker_ok_button
    END_IF
        rts
.endproc ; UpdateOKButton

;;; ============================================================

.proc PopulateEntriesFlagTable
        ldx     #kSelectorListNumEntries - 1
        lda     #$FF
    DO
        sta     entries_flag_table,x
    WHILE dex : POS

        ldx     #0
    DO
        BREAK_IF X = num_primary_run_list_entries
        txa
        sta     entries_flag_table,x
    WHILE inx : NOT_ZERO

        ldx     #0
    DO
        BREAK_IF X = num_secondary_run_list_entries
        txa
        clc
        adc     #kSelectorListNumPrimaryRunListEntries
        sta     entries_flag_table+8,x
    WHILE inx : NOT_ZERO

        rts
.endproc ; PopulateEntriesFlagTable

;;; ============================================================
;;; Assigns name, flags, and path to an entry in the file buffer
;;; and (if it's in the primary run list) also updates the
;;; resource data (used for menus, etc).
;;; Inputs: A=entry index, Y=new flags
;;;         `main::stashed_name` is name, `path_buf0` is path

.proc AssignEntryData
        ptr_file = $06          ; pointer into file buffer

        sta     index
        sty     flags

        ;; Assign name in `main::stashed_name` to file
        CALL    GetFileEntryAddr, A=index
        stax    ptr_file
        ldy     main::stashed_name
    DO
        copy8   main::stashed_name,y, (ptr_file),y
    WHILE dey : POS

        ;; Assign flags to file
        ldy     #kSelectorEntryFlagsOffset
        copy8   flags, (ptr_file),y

        ;; Assign path in `path_buf0` to file
        CALL    GetFilePathAddr, A=index
        stax    ptr_file
        ldy     path_buf0
    DO
        copy8   path_buf0,y, (ptr_file),y
    WHILE dey : POS

        ;; If primary run list, update the menu as well
    IF lda index : A < #kSelectorListNumPrimaryRunListEntries
        jsr     UpdateMenuResources
    END_IF

        rts

index:  .byte   0
flags:  .byte   0
.endproc ; AssignSecondaryRunListEntryData

;;; ============================================================
;;; Removes the specified entry, shifting later entries down as
;;; needed. Handles both the file buffer and resource data (used for
;;; menus, etc.)
;;; Inputs: Entry in A

.proc RemoveEntry
        ptr1 := $06
        ptr2 := $08

        sta     index
        cmp     #kSelectorListNumPrimaryRunListEntries
        bcs     secondary_run_list

        ;; Primary run list
.scope
        tax
        inx
        cpx     num_primary_run_list_entries
        bne     loop

finish:
        dec     selector_list + kSelectorListNumPrimaryRunListOffset
        dec     num_primary_run_list_entries
        TAIL_CALL UpdateMenuResources

loop:   lda     index
        cmp     num_primary_run_list_entries
        beq     finish

        jsr     MoveEntryDown

        inc     index
        jmp     loop
.endscope

        ;; --------------------------------------------------

secondary_run_list:
.scope
        sec
        sbc     #kSelectorListNumPrimaryRunListEntries - 1
    IF A = num_secondary_run_list_entries
        dec     selector_list + kSelectorListNumSecondaryRunListOffset
        dec     num_secondary_run_list_entries
        rts
    END_IF

    REPEAT
        lda     index
        sec
        sbc     #kSelectorListNumPrimaryRunListEntries
      IF A = num_secondary_run_list_entries
        dec     selector_list + kSelectorListNumSecondaryRunListOffset
        dec     num_secondary_run_list_entries
        rts
      END_IF

        CALL    MoveEntryDown, A=index

        inc     index
    FOREVER
.endscope

index:  .byte   0

;;; Move an entry (in the file buffer) down by one.
;;; A=entry index
.proc MoveEntryDown
        ;; Copy entry (in file buffer) down by one
        jsr     GetFileEntryAddr
        stax    ptr1
        add16   ptr1, #kSelectorListNameLength, ptr2

        ldy     #0
        lda     (ptr2),y
        tay
    DO
        copy8   (ptr2),y, (ptr1),y
    WHILE dey : POS

        ;; And flags
        ldy     #kSelectorEntryFlagsOffset
        lda     (ptr2),y
        sta     (ptr1),y

        ;; Copy path (in file buffer) down by one
        CALL    GetFilePathAddr, A=index
        stax    ptr1
        add16   ptr1, #kSelectorListPathLength, ptr2

        ldy     #0
        lda     (ptr2),y
        tay
    DO
        copy8   (ptr2),y, (ptr1),y
    WHILE dey : POS

        rts
.endproc ; MoveEntryDown

.endproc ; RemoveEntry

;;; ============================================================
;;; Update menu from the file data, following an add/edit/remove.

.proc UpdateMenuResources

        ptr_file = $06          ; pointer into file buffer
        ptr_res = $08           ; pointer into resource data

        lda     selector_list + kSelectorListNumPrimaryRunListOffset
        sta     index

    REPEAT
        dec     index
        bmi     finish

        ;; Name
        CALL    GetFileEntryAddr, A=index
        stax    ptr_file
        CALL    GetResourceEntryAddr, A=index
        stax    ptr_res
        jsr     _CopyString

        ;; Flags
        ldy     #kSelectorEntryFlagsOffset
        lda     (ptr_file),y
        sta     (ptr_res),y

        ;; Path
        CALL    GetFilePathAddr, A=index
        stax    ptr_file
        CALL    GetResourcePathAddr, A=index
        stax    ptr_res
        jsr     _CopyString
    FOREVER

finish:
        ;; Menu size
        lda     selector_list + kSelectorListNumPrimaryRunListOffset
        clc
        adc     #kSelectorMenuFixedItems
        sta     selector_menu
        ;; No separator if it is last
    IF A = #kSelectorMenuFixedItems
        dec     selector_menu
    END_IF

        ;; Re-initialize the menu so that new widths can be pre-computed.
        ;; That will un-hilite the Selector menu, so re-hilite it so
        ;; it un-hilites correctly when finally dismissed.

        MGTK_CALL MGTK::SetMenu, aux::desktop_menu
        jsr     main::ToggleMenuHilite
        jsr     main::ShowClockForceUpdate

        rts

;;; Copy the string at `ptr_file` to `ptr_res`.
.proc _CopyString
        ldy     #0
        lda     (ptr_file),y
        tay
    DO
        copy8   (ptr_file),y, (ptr_res),y
    WHILE dey : POS

        rts
.endproc ; _CopyString

index:  .byte   0
.endproc ; UpdateMenuResources


;;; ============================================================
;;; Entry name address in the file buffer
;;; Input: A = Entry
;;; Output: A,X = Address

.proc GetFileEntryAddr
        addr := selector_list + kSelectorListEntriesOffset
        jsr     main::ATimes16
        clc
        adc     #<addr
        tay
        txa
        adc     #>addr
        tax
        tya
        rts
.endproc ; GetFileEntryAddr

;;; ============================================================
;;; Path address in the file buffer
;;; Input: A = Entry
;;; Output: A,X = Address

.proc GetFilePathAddr
        addr := selector_list + kSelectorListPathsOffset

        jsr     main::ATimes64
        clc
        adc     #<addr
        tay
        txa
        adc     #>addr
        tax
        tya
        rts
.endproc ; GetFilePathAddr

;;; ============================================================
;;; Entry name address in the resource block (used for menu items)
;;; Input: A = Entry
;;; Output: A,X = Address

.proc GetResourceEntryAddr
        jsr     main::ATimes16
        clc
        adc     #<run_list_entries
        tay
        txa
        adc     #>run_list_entries
        tax
        tya
        rts
.endproc ; GetResourceEntryAddr

;;; ============================================================
;;; Path address in the resource block (used for invoking)
;;; Input: A = Entry
;;; Output: A,X = Address

.proc GetResourcePathAddr
        jsr     main::ATimes64
        clc
        adc     #<main::run_list_paths
        tay
        txa
        adc     #>main::run_list_paths
        tax
        tya
        rts
.endproc ; GetResourcePathAddr

;;; ============================================================

        DEFINE_DESTROY_PARAMS destroy_params, filename
        DEFINE_CREATE_PARAMS create_params, filename, ACCESS_DEFAULT, $F1
        DEFINE_OPEN_PARAMS open_params, filename, io_buf
        DEFINE_READWRITE_PARAMS write_params, selector_list, kSelectorListBufSize
        DEFINE_CLOSE_PARAMS close_params

filename:
        PASCAL_STRING kPathnameSelectorList

        DEFINE_GET_PREFIX_PARAMS current_prefix_params, current_prefix
        DEFINE_GET_PREFIX_PARAMS orig_prefix_params, orig_prefix

local_dir:      PASCAL_STRING kFilenameLocalDir
        DEFINE_CREATE_PARAMS create_localdir_params, local_dir, ACCESS_DEFAULT, FT_DIRECTORY,, ST_LINKED_DIRECTORY

;;; ============================================================
;;; Read SELECTOR.LIST file (using current prefix)

        DEFINE_OPEN_PARAMS open_curpfx_params, filename, io_buf
        DEFINE_READWRITE_PARAMS read_params, selector_list, kSelectorListBufSize

.proc ReadFile
        jsr     main::SetCursorWatch ; before reading
        jsr     rest
        jmp     main::SetCursorPointer ; after reading
rest:
        ;; --------------------------------------------------

retry:  MLI_CALL OPEN, open_curpfx_params
        bcc     read
        cmp     #ERR_FILE_NOT_FOUND
        beq     not_found
        cmp     #ERR_PATH_NOT_FOUND
        beq     not_found
        CALL    ShowAlert, A=#kErrInsertSystemDisk
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        beq     retry
        RETURN  A=#$FF          ; failure

read:   lda     open_curpfx_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        MLI_CALL READ, read_params
        php
        pha
        MLI_CALL CLOSE, close_params
        pla
        plp
        rts

not_found:
        ;; Clear buffer
        ptr := $06
        copy16  #selector_list, ptr
        ldx     #>kSelectorListBufSize ; number of pages
        lda     #0
    DO
        ldy     #0
      DO
        sta     (ptr),y
      WHILE dey : NOT_ZERO
        inc     ptr+1
    WHILE dex: NOT_ZERO
        RETURN  A=#0
.endproc ; ReadFile

;;; ============================================================
;;; Write out SELECTOR.LIST file.

.proc _DoWrite
        jsr     main::SetCursorWatch ; before writing
        jsr     rest
        jmp     main::SetCursorPointer ; after writing
rest:
        ;; --------------------------------------------------

        ldax    DATELO
        stax    create_params::create_date
        stax    create_localdir_params::create_date
        ldax    TIMELO
        stax    create_params::create_time
        stax    create_localdir_params::create_time

        ;; Create local dir if necessary
retry1:
        JUMP_TABLE_MLI_CALL CREATE, create_localdir_params
    IF CS AND A <> #ERR_DUPLICATE_FILENAME
        jsr     _CheckRetry
        beq     retry1
        bne     failed          ; always
    END_IF

        ;; Destroy existing settings file if necessary
        ;; This is to catch write failures before the file `OPEN`, as
        ;; failure to `WRITE`/`FLUSH` will make the `CLOSE` fail,
        ;; leaving the `io_buffer` in use.
retry2:
        JUMP_TABLE_MLI_CALL DESTROY, destroy_params
    IF CS AND A <> #ERR_FILE_NOT_FOUND
        jsr     _CheckRetry
        beq     retry2
        bne     failed          ; always
    END_IF

        ;; Create/write settings file if necessary
retry3:
        JUMP_TABLE_MLI_CALL CREATE, create_params
        JUMP_TABLE_MLI_CALL OPEN, open_params
    IF CC
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        JUMP_TABLE_MLI_CALL WRITE, write_params
        JUMP_TABLE_MLI_CALL CLOSE, close_params
    END_IF
    IF CS
        jsr     _CheckRetry
        beq     retry3
        bne     failed          ; always
    END_IF
        rts                     ; C=0

failed:
        sec
        rts                     ; C=1
.endproc ; _DoWrite

;;; Before calling: ensure `retry_flag` was cleared at some point.
;;; Input: A = ProDOS error code
;;; Output: Z = 1 if retry was selected
.proc _CheckRetry
    IF bit retry_flag : NC
        ;; First time - prompt see if we want to try saving.
        SET_BIT7_FLAG retry_flag
        CALL    JUMP_TABLE_SHOW_ALERT, A=#kErrSaveChanges ; OK/Cancel
        cmp     #kAlertResultOK
        rts                     ; Z=1 if OK selected (i.e. retry)
    END_IF

        ;; Special case
    IF A = #ERR_VOL_NOT_FOUND
        lda     #kErrInsertSystemDisk ; Try Again/Cancel
    END_IF
        jsr     JUMP_TABLE_SHOW_ALERT ; arbitrary ProDOS error
        ;; Responses are either OK or Try Again/Cancel
        cmp     #kAlertResultTryAgain
        rts
.endproc

retry_flag:        .byte   0 ; bit7

;;; ============================================================

.proc IsEntryCallback
        tay
        ldx     entries_flag_table,y ; set N appropriately
        rts
.endproc ; IsEntryCallback

.proc DrawEntryCallback
        addr := selector_list + kSelectorListEntriesOffset

        jsr     main::ATimes16
        clc
        adc     #<addr
        pha
        txa
        adc     #>addr
        tax
        pla

        ptr1 := $06
        stax    ptr1
        CALL    main::CopyPtr1ToBuf, AX=#text_buffer2
        MGTK_CALL MGTK::DrawString, text_buffer2
        rts
.endproc ; DrawEntryCallback

.proc SelChangeCallback
        jmp     UpdateOKButton
.endproc ; SelChangeCallback


;;; ============================================================

.endscope ; SelectorPickOverlay

        ENDSEG OverlayShortcutPick
