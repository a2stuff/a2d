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
        lda     clean_flag
    IF NC
        ;; Update total count of entries (used for menu item states)
        lda     selector_list + kSelectorListNumPrimaryRunListOffset
        clc
        adc     selector_list + kSelectorListNumSecondaryRunListOffset
        sta     num_selector_list_items

        ;; Write out file
        jsr     WriteFile
      IF NC
        ;; ... and if successful, see if we need to update system disk
        jsr     main::GetCopiedToRAMCardFlag
       IF NS
        jsr     WriteFileToOriginalPrefix
       END_IF
      END_IF
    END_IF

        pla                     ; A = result
        rts
.endproc ; Exit

;;; ============================================================

DoAdd:  ldx     #kRunListPrimary
        lda     selector_menu
    IF A >= #kSelectorMenuFixedItems + 8
        inx
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
        CALL    main::RestoreDynamicRoutine, A=#kDynamicRoutineRestoreFD
        jsr     main::ClearUpdates ; File Dialog close (safe after restoration)
        pla
        tay
        pla
        tax
        pla
        bne     Exit

        stx     which_run_list
        sty     copy_when

        lda     #$00
:       dey
        beq     :+
        sec
        ror     a
        jmp     :-
:
        sta     copy_when
        jsr     ReadFile
    IF NS
        jmp     Exit
    END_IF

        copy16  selector_list, num_primary_run_list_entries
        lda     which_run_list
    IF A = #kRunListPrimary
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
        jsr     AssignSecondaryRunListEntryData
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
        ;; NOTE: Can't `ClearUpdates` here as File Picker overlay has
        ;; not been restored and `PROC_USED_CLEARING_UPDATES` doesn't
        ;; cover that.

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
        inx                     ; #kRunListSecondary
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
        CALL    main::RestoreDynamicRoutine, A=#kDynamicRoutineRestoreFD
        jsr     main::ClearUpdates ; File Dialog close (safe after restoration)
        pla
        tay
        pla
        tax
        pla
        RTS_IF NOT_ZERO

        stx     which_run_list

        ;; Map to `kCopyOnBoot` to `kSelectorEntryCopyOnBoot` etc
        lda     copy_when_conversion_table-1,y
        sta     copy_when
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

        ;; Index is kCopyXXX-1, value is kSelectorEntryCopyXXX
copy_when_conversion_table:
        .byte   kSelectorEntryCopyOnBoot
        .byte   kSelectorEntryCopyOnUse
        .byte   kSelectorEntryCopyNever

.endproc ; DoEdit

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
        lda     selector_action
    IF A = #SelectorAction::edit
        CALL    main::RestoreDynamicRoutine, A=#kDynamicRoutineRestoreFD
    END_IF

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
        bit     shortcut_picker_record::selected_index
    IF NS
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
        dex
    WHILE POS

        ldx     #0
    DO
        BREAK_IF X = num_primary_run_list_entries
        txa
        sta     entries_flag_table,x
        inx
    WHILE NOT_ZERO

        ldx     #0
    DO
        BREAK_IF X = num_secondary_run_list_entries
        txa
        clc
        adc     #kSelectorListNumPrimaryRunListEntries
        sta     entries_flag_table+8,x
        inx
    WHILE NOT_ZERO

        rts
.endproc ; PopulateEntriesFlagTable

;;; Table for 24 entries; index (0...23) if in use, $FF if empty
entries_flag_table:
        .res    ::kSelectorListNumEntries, 0

;;; ============================================================
;;; Assigns name, flags, and path to an entry in the file buffer
;;; and (if it's in the primary run list) also updates the
;;; resource data (used for menus, etc).
;;; Inputs: A=entry index, Y=new flags
;;;         `main::stashed_name` is name, `path_buf0` is path

.proc AssignEntryData
        cmp     #kSelectorListNumPrimaryRunListEntries
        bcs     AssignSecondaryRunListEntryData

        sta     index
        tya                     ; flags
        pha

        ptr_file = $06          ; pointer into file buffer

        ;; Assign name in `main::stashed_name` to file
        CALL    GetFileEntryAddr, A=index
        stax    ptr_file
        ldy     main::stashed_name
    DO
        copy8   main::stashed_name,y, (ptr_file),y
        dey
    WHILE POS

        ;; Assign flags to file
        ldy     #kSelectorEntryFlagsOffset
        pla
        sta     (ptr_file),y

        ;; Assign path in `path_buf0` to file
        CALL    GetFilePathAddr, A=index
        stax    ptr_file
        ldy     path_buf0
    DO
        copy8   path_buf0,y, (ptr_file),y
        dey
    WHILE POS

        jsr     UpdateMenuResources

        rts

index:  .byte   0
.endproc ; AssignEntryData

;;; ============================================================
;;; Assigns name, flags, and path to an entry in the file buffer.
;;; Inputs: A=entry index, Y=new flags
;;;         `main::stashed_name` is name, `path_buf0` is path

.proc AssignSecondaryRunListEntryData
        ptr := $06

        sta     index
        tya                     ; Y = entry flags
        pha

        ;; Compute entry address
        CALL    GetFileEntryAddr, A=index
        stax    ptr

        ;; Assign name
        ldy     main::stashed_name
    DO
        copy8   main::stashed_name,y, (ptr),y
        dey
    WHILE POS

        ;; Assign flags
        ldy     #kSelectorEntryFlagsOffset
        pla
        sta     (ptr),y

        ;; Assign path
        CALL    GetFilePathAddr, A=index
        stax    ptr
        ldy     path_buf0
    DO
        copy8   path_buf0,y, (ptr),y
        dey
    WHILE POS
        rts

index:  .byte   0
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
        dey
    WHILE POS

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
        dey
    WHILE POS

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
        dey
    WHILE POS

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
;;; Write out SELECTOR.LIST file, using original prefix.
;;; Used if DeskTop was copied to RAMCard.

filename_buffer := $1C00

        DEFINE_CREATE_PARAMS create_origpfx_params, filename_buffer, ACCESS_DEFAULT, $F1
        DEFINE_OPEN_PARAMS open_origpfx_params, filename_buffer, io_buf

        DEFINE_CREATE_PARAMS create_curpfx_params, filename, ACCESS_DEFAULT, $F1
        DEFINE_OPEN_PARAMS open_curpfx_params, filename, io_buf

filename:
        PASCAL_STRING kPathnameSelectorList

        DEFINE_READWRITE_PARAMS read_params, selector_list, kSelectorListBufSize
        DEFINE_READWRITE_PARAMS write_params, selector_list, kSelectorListBufSize
        DEFINE_CLOSE_PARAMS close_params

.proc WriteFileToOriginalPrefix
        jsr     main::SetCursorWatch ; before writing
        jsr     rest
        jmp     main::SetCursorPointer ; after writing
rest:
        ;; --------------------------------------------------


        CALL    main::CopyDeskTopOriginalPrefix, AX=#filename_buffer

        ldx     filename_buffer ; Append '/' separator
        inx
        lda     #'/'
        sta     filename_buffer,x

        ldy     #0              ; Append filename
    DO
        inx
        iny
        copy8   filename,y, filename_buffer,x
    WHILE Y <> filename
        stx     filename_buffer

        copy8   #0, second_try_flag

retry_create_and_open:
        MLI_CALL CREATE, create_origpfx_params
        MLI_CALL OPEN, open_origpfx_params
    IF CS
        ;; First time - ask if we should even try.
        lda     second_try_flag
      IF ZERO
        inc     second_try_flag
        CALL    ShowAlert, A=#kErrSaveChanges
        cmp     #kAlertResultOK
        beq     retry_create_and_open
        bne     cancel          ; always
      END_IF

        ;; Second time - prompt to insert.
        CALL    ShowAlert, A=#kErrInsertSystemDisk
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        beq     retry_create_and_open

cancel: rts
    END_IF

        lda     open_origpfx_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num

retry_write:
        MLI_CALL WRITE, write_params
    IF CS
        jsr     ShowAlert       ; arbitrary ProDOS error
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        beq     retry_write     ; `kAlertResultTryAgain` = 0
    END_IF

        MLI_CALL CLOSE, close_params
        rts

second_try_flag:                ; 0 or 1, updated with INC
        .byte   0
.endproc ; WriteFileToOriginalPrefix

;;; ============================================================
;;; Read SELECTOR.LIST file (using current prefix)

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
        dey
      WHILE NOT_ZERO
        inc     ptr+1
        dex
    WHILE NOT_ZERO
        RETURN  A=#0
.endproc ; ReadFile

;;; ============================================================
;;; Write SELECTOR.LIST file (using current prefix)

.proc WriteFile
        jsr     main::SetCursorWatch ; before writing
        jsr     rest
        jmp     main::SetCursorPointer ; after writing
rest:
        ;; --------------------------------------------------

retry_create_and_open:
        MLI_CALL CREATE, create_curpfx_params
        MLI_CALL OPEN, open_curpfx_params
    IF CS
        CALL    ShowAlert, A=#kErrInsertSystemDisk
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        beq     retry_create_and_open
        RETURN  A=#$FF
    END_IF

        lda     open_curpfx_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num

retry_write:
        MLI_CALL WRITE, write_params
    IF CS
        jsr     ShowAlert       ; arbitrary ProDOS error
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        beq     retry_write     ; `kAlertResultTryAgain` = 0
    END_IF

        MLI_CALL CLOSE, close_params
        rts
.endproc ; WriteFile

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
