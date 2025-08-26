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
        ldx     #$FF
        stx     clean_flag      ; set "clean"
        cmp     #SelectorAction::add
        beq     DoAdd
        jmp     Init

L900F:  pha
        lda     clean_flag
        bpl     L9017           ; dirty, check about saving
L9015:  pla
L9016:  rts

L9017:  lda     selector_list + kSelectorListNumPrimaryRunListOffset
        clc
        adc     selector_list + kSelectorListNumSecondaryRunListOffset
        sta     num_selector_list_items
        jsr     main::GetCopiedToRAMCardFlag
        cmp     #$80
        bne     L9015
        jsr     WriteFileToOriginalPrefix
        pla
        rts

;;; ============================================================

DoAdd:  ldx     #kRunListPrimary
        lda     selector_menu
        cmp     #kSelectorMenuFixedItems + 8
        bcc     L9052
        inx
L9052:  lda     #$00
        sta     text_input_buf    ; clear name, but leave path alone
        ldy     #kCopyNever | $80 ; high bit set = Add
        ;; A = (obsolete, was dialog type)
        ;; Y = is_add_flag | copy_when
        ;; X = which_run_list
        jsr     SelectorEditOverlay__Run
        pha
        txa
        pha
        tya
        pha
        lda     #kDynamicRoutineRestoreFD
        jsr     main::RestoreDynamicRoutine
        jsr     main::ClearUpdates ; Add File Dialog close
        pla
        tay
        pla
        tax
        pla
        bne     L900F
        inc     clean_flag      ; mark as "dirty"
        stx     which_run_list
        sty     copy_when
        lda     #$00
L9080:  dey
        beq     L9088
        sec
        ror     a
        jmp     L9080

L9088:  sta     copy_when
        jsr     ReadFile
        bpl     L9093
        jmp     L9016

L9093:  copy16  selector_list, num_primary_run_list_entries
        lda     which_run_list
        cmp     #kRunListPrimary
        bne     L90D3
        lda     num_primary_run_list_entries
        cmp     #kSelectorListNumPrimaryRunListEntries
        beq     L90F4
        ldy     copy_when       ; Flags
        lda     num_primary_run_list_entries
        inc     selector_list + kSelectorListNumPrimaryRunListOffset
        jsr     AssignEntryData
        jsr     WriteFile
        bpl     L90D0
        jmp     L9016

L90D0:  jmp     L900F

L90D3:  lda     num_secondary_run_list_entries
        cmp     #kSelectorListNumSecondaryRunListEntries
        beq     L90F4
        ldy     copy_when       ; Flags
        lda     num_secondary_run_list_entries
        clc
        adc     #kSelectorListNumPrimaryRunListEntries
        jsr     AssignSecondaryRunListEntryData
        inc     selector_list + kSelectorListNumSecondaryRunListOffset
        jsr     WriteFile
        bpl     L90F1
        jmp     L9016

L90F1:  jmp     L900F

L90F4:  param_call ShowAlertParams, AlertButtonOptions::OK, aux::str_warning_selector_list_full
        dec     clean_flag      ; reset to "clean"
        jmp     L9016

which_run_list:
        .byte   0
copy_when:  .byte   0

;;; ============================================================

.proc Init
        lda     #$00
        sta     num_primary_run_list_entries
        sta     num_secondary_run_list_entries
        copy8   #$FF, shortcut_picker_record::selected_index
        copy8   #BTK::kButtonStateDisabled, entry_picker_ok_button::state

        jsr     OpenWindow
        jsr     ReadFile
    IF_NS
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

        beq     :+              ; Z set = OK selected
        jmp     DoCancel

        ;; Which action are we?
:       lda     shortcut_picker_record::selected_index
        bmi     dialog_loop
        lda     selector_action
        cmp     #SelectorAction::edit
        jeq     DoEdit

        cmp     #SelectorAction::delete
        bne     :+
        beq     DoDelete       ; always

:       cmp     #SelectorAction::run
        bne     dialog_loop
        jmp     DoRun

;;; ============================================================

.proc DoDelete
        jsr     main::SetCursorWatch
        lda     shortcut_picker_record::selected_index
        jsr     RemoveEntry
        bne     :+              ; Z set on success

        inc     clean_flag      ; mark as "dirty"

:       jsr     main::SetCursorPointer
        jmp     DoCancel
.endproc ; DoDelete

;;; ============================================================

.proc DoEdit
        jsr     CloseWindow

        lda     shortcut_picker_record::selected_index
        jsr     GetFileEntryAddr
        stax    $06
        param_call main::CopyPtr1ToBuf, text_input_buf

        ldy     #kSelectorEntryFlagsOffset
        lda     ($06),y
        sta     flags

        lda     shortcut_picker_record::selected_index
        jsr     GetFilePathAddr
        jsr     main::CopyToBuf0

        ldx     #kRunListPrimary
        lda     shortcut_picker_record::selected_index
        cmp     #kSelectorListNumPrimaryRunListEntries
        bcc     :+
        inx
:
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
        jsr     SelectorEditOverlay__Run
        pha
        txa
        pha
        tya
        pha
        lda     #kDynamicRoutineRestoreFD
        jsr     main::RestoreDynamicRoutine
        jsr     main::ClearUpdates ; Edit File Dialog close
        pla
        tay
        pla
        tax
        pla
        RTS_IF_NOT_ZERO

        inc     clean_flag      ; mark as "dirty"
        stx     which_run_list

        ;; Map to `kCopyOnBoot` to `kSelectorEntryCopyOnBoot` etc
        lda     copy_when_conversion_table-1,y
        sta     copy_when
        jsr     ReadFile
        bpl     l7
        jmp     CloseWindow

l7:     lda     shortcut_picker_record::selected_index
        cmp     #kSelectorListNumPrimaryRunListEntries
        bcc     l10
        lda     which_run_list
        cmp     #kRunListSecondary
        beq     l13
        lda     num_primary_run_list_entries
        cmp     #kSelectorListNumPrimaryRunListEntries
        bne     l8
        jmp     L90F4

l8:     lda     shortcut_picker_record::selected_index
        jsr     RemoveEntry
        beq     l9
        jmp     CloseWindow

l9:     ldx     num_primary_run_list_entries
        inc     num_primary_run_list_entries
        inc     selector_list + kSelectorListNumPrimaryRunListOffset
        txa
        jmp     l14

l10:    lda     which_run_list
        cmp     #kRunListPrimary
        beq     l13
        lda     num_secondary_run_list_entries
        cmp     #kSelectorListNumSecondaryRunListEntries
        bne     l11
        jmp     Init

l11:    lda     shortcut_picker_record::selected_index
        jsr     RemoveEntry
        beq     l12
        jmp     CloseWindow

l12:    ldx     num_secondary_run_list_entries
        inc     num_secondary_run_list_entries
        inc     selector_list + kSelectorListNumSecondaryRunListOffset
        lda     num_secondary_run_list_entries
        clc
        adc     #$07
        jmp     l14

l13:    lda     shortcut_picker_record::selected_index
l14:    ldy     copy_when
        jsr     AssignEntryData
        jsr     WriteFile
        beq     l15
        jmp     CloseWindow

l15:    jsr     main::SetCursorPointer
        jmp     L900F

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
        jsr     main::ClearUpdates       ; Run dialog OK
        lda     shortcut_picker_record::selected_index
        rts
.endproc ; DoRun

;;; ============================================================
;;; Cancel from Edit, Delete, or Run
;;; Also OK from Delete (since that closes immediately)

.proc DoCancel
        lda     selector_action
        cmp     #SelectorAction::edit
        bne     :+

        lda     #kDynamicRoutineRestoreFD
        jsr     main::RestoreDynamicRoutine

:       jsr     CloseWindow
        jsr     main::ClearUpdates

        lda     #$FF
        jmp     L900F
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
        .byte   0               ; and should save to original prefix

;;; ============================================================

.proc OpenWindow
        MGTK_CALL MGTK::OpenWindow, winfo_entry_picker
        lda     #winfo_entry_picker::kWindowId
        jsr     main::SafeSetPortFromWindowId
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
        cmp     #SelectorAction::edit
    IF_EQ
        param_jump DrawTitleCentered, label_edit
    END_IF

        cmp     #SelectorAction::delete
    IF_EQ
        param_jump DrawTitleCentered, label_del
    END_IF

        param_jump DrawTitleCentered, label_run
.endproc ; OpenWindow

;;; ============================================================

.proc DrawTitleCentered
        text_params     := $6
        text_addr       := text_params + 0
        text_length     := text_params + 2
        text_width      := text_params + 3

        stax    text_addr       ; input is length-prefixed string
        ldy     #0
        lda     (text_addr),y
        sta     text_length
        inc16   text_addr ; point past length byte
        MGTK_CALL MGTK::TextWidth, text_params

        sub16   #winfo_entry_picker::kWidth, text_width, pos_dialog_title::xcoord
        lsr16   pos_dialog_title::xcoord ; /= 2
        MGTK_CALL MGTK::MoveTo, pos_dialog_title
        MGTK_CALL MGTK::DrawText, text_params
        rts
.endproc ; DrawTitleCentered

;;; ============================================================
;;; When returning from event loop:
;;; N = nothing selected, re-enter loop
;;; Z = OK selected
;;; Otherwise: Cancel selected

.proc EventLoop
        jsr     SystemTask
        jsr     main::GetEvent

        cmp     #MGTK::EventKind::button_down
        jeq     handle_button

        cmp     #MGTK::EventKind::key_down
        bne     EventLoop
        jmp     HandleKey

handle_button:
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        bne     :+
        return  #$FF

:       cmp     #MGTK::Area::content
        beq     :+
        return  #$FF

:       lda     findwindow_params::window_id
        cmp     winfo_entry_picker
        beq     :+
        return  #$FF

:       lda     #winfo_entry_picker::kWindowId
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        MGTK_CALL MGTK::InRect, entry_picker_ok_button::rect
    IF_NOT_ZERO
        BTK_CALL BTK::Track, entry_picker_ok_button
        bmi     :+
        lda     #$00            ; OK selected
:       rts
    END_IF

        MGTK_CALL MGTK::InRect, entry_picker_cancel_button::rect
    IF_NOT_ZERO
        BTK_CALL BTK::Track, entry_picker_cancel_button
        bmi     :+
        lda     #$01            ; cancel selected
:       rts
    END_IF

        COPY_STRUCT MGTK::Point, screentowindow_params::window, shortcut_picker_params::coords
        OPTK_CALL OPTK::Click, shortcut_picker_params
        bmi     ret
        jsr     DetectDoubleClick
    IF_NC
        pha
        BTK_CALL BTK::Flash, entry_picker_ok_button
        pla
    END_IF
ret:    rts
.endproc ; EventLoop

;;; ============================================================
;;; Key down handler

.proc HandleKey
        lda     event_params::modifiers
        cmp     #MGTK::event_modifier_solid_apple
        bne     :+
        return  #$FF
:       lda     event_params::key

        cmp     #CHAR_RETURN
        jeq     HandleKeyReturn

        cmp     #CHAR_ESCAPE
        jeq     HandleKeyEscape

        lda     num_primary_run_list_entries
        ora     num_secondary_run_list_entries
    IF_NE
        lda     event_params::key
        cmp     #CHAR_UP
        beq     :+
        cmp     #CHAR_DOWN
        beq     :+
        cmp     #CHAR_LEFT
        beq     :+
        cmp     #CHAR_RIGHT
:     IF_EQ
        sta     shortcut_picker_params::key
        OPTK_CALL OPTK::Key, shortcut_picker_params
      END_IF
    END_IF

        return  #$FF
.endproc ; HandleKey

;;; ============================================================

.proc HandleKeyReturn
        BTK_CALL BTK::Flash, entry_picker_ok_button
    IF_NS
        return #$FF             ; ignore
    END_IF
        return  #0
.endproc ; HandleKeyReturn

;;; ============================================================

.proc HandleKeyEscape
        BTK_CALL BTK::Flash, entry_picker_cancel_button
        return  #1
.endproc ; HandleKeyEscape

;;; ============================================================

.proc UpdateOKButton
        lda     #BTK::kButtonStateNormal
        bit     shortcut_picker_record::selected_index
        bpl     :+
        lda     #BTK::kButtonStateDisabled
:       cmp     entry_picker_ok_button::state
        beq     :+
        sta     entry_picker_ok_button::state
        BTK_CALL BTK::Hilite, entry_picker_ok_button
:       rts

.endproc ; UpdateOKButton

;;; ============================================================

.proc PopulateEntriesFlagTable
        ldx     #kSelectorListNumEntries - 1
        lda     #$FF
:       sta     entries_flag_table,x
        dex
        bpl     :-

        ldx     #0
:       cpx     num_primary_run_list_entries
        beq     :+
        txa
        sta     entries_flag_table,x
        inx
        bne     :-

:       ldx     #0
:       cpx     num_secondary_run_list_entries
        beq     :+
        txa
        clc
        adc     #8
        sta     entries_flag_table+8,x
        inx
        bne     :-
:       rts
.endproc ; PopulateEntriesFlagTable

;;; Table for 24 entries; index (0...23) if in use, $FF if empty
entries_flag_table:
        .res    ::kSelectorListNumEntries, 0

;;; ============================================================
;;; Assigns name, flags, and path to an entry in the file buffer
;;; and (if it's in the primary run list) also updates the
;;; resource data (used for menus, etc).
;;; Inputs: A=entry index, Y=new flags
;;;         `text_input_buf` is name, `path_buf0` is path

.proc AssignEntryData
        cmp     #8
        bcc     :+
        jmp     AssignSecondaryRunListEntryData

:       sta     index
        tya                     ; flags
        pha

        ptr_file = $06          ; pointer into file buffer

        ;; Assign name in `text_input_buf` to file
        lda     index
        jsr     GetFileEntryAddr
        stax    ptr_file
        ldy     text_input_buf
:       lda     text_input_buf,y
        sta     (ptr_file),y
        dey
        bpl     :-

        ;; Assign flags to file
        ldy     #kSelectorEntryFlagsOffset
        pla
        sta     (ptr_file),y

        ;; Assign path in `path_buf0` to file
        lda     index
        jsr     GetFilePathAddr
        stax    ptr_file
        ldy     path_buf0
:       lda     path_buf0,y
        sta     (ptr_file),y
        dey
        bpl     :-

        jsr     UpdateMenuResources

        rts

index:  .byte   0
.endproc ; AssignEntryData

;;; ============================================================
;;; Assigns name, flags, and path to an entry in the file buffer.
;;; Inputs: A=entry index, Y=new flags
;;;         `text_input_buf` is name, `path_buf0` is path

.proc AssignSecondaryRunListEntryData
        ptr := $06

        sta     index
        tya                     ; Y = entry flags
        pha

        ;; Compute entry address
        lda     index
        jsr     GetFileEntryAddr
        stax    ptr

        ;; Assign name
        ldy     text_input_buf
:       lda     text_input_buf,y
        sta     (ptr),y
        dey
        bpl     :-

        ;; Assign flags
        ldy     #kSelectorEntryFlagsOffset
        pla
        sta     (ptr),y

        ;; Assign path
        lda     index
        jsr     GetFilePathAddr
        stax    ptr
        ldy     path_buf0
:       lda     path_buf0,y
        sta     (ptr),y
        dey
        bpl     :-
        rts

index:  .byte   0
.endproc ; AssignSecondaryRunListEntryData

;;; ============================================================
;;; Removes the specified entry, shifting later entries down as
;;; needed. Writes the file when done. Handles both the file
;;; buffer and resource data (used for menus, etc.)
;;; Inputs: Entry in A

.proc RemoveEntry
        ptr1 := $06
        ptr2 := $08

        sta     index
        cmp     #8
        bcc     run_list
        jmp     secondary_run_list

        ;; Primary run list
run_list:
.scope
        tax
        inx
        cpx     num_primary_run_list_entries
        bne     loop

finish:
        dec     selector_list + kSelectorListNumPrimaryRunListOffset
        dec     num_primary_run_list_entries
        jsr     UpdateMenuResources
        jmp     WriteFile

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
        sbc     #ptr1+1
        cmp     num_secondary_run_list_entries
        bne     loop
        dec     selector_list + kSelectorListNumSecondaryRunListOffset
        dec     num_secondary_run_list_entries
        jmp     WriteFile

loop:   lda     index
        sec
        sbc     #ptr2
        cmp     num_secondary_run_list_entries
        bne     :+

        dec     selector_list + kSelectorListNumSecondaryRunListOffset
        dec     num_secondary_run_list_entries
        jmp     WriteFile

:       lda     index
        jsr     MoveEntryDown

        inc     index
        jmp     loop
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
:       lda     (ptr2),y
        sta     (ptr1),y
        dey
        bpl     :-

        ;; And flags
        ldy     #kSelectorEntryFlagsOffset
        lda     (ptr2),y
        sta     (ptr1),y

        ;; Copy path (in file buffer) down by one
        lda     index
        jsr     GetFilePathAddr
        stax    ptr1
        add16   ptr1, #kSelectorListPathLength, ptr2

        ldy     #0
        lda     (ptr2),y
        tay
:       lda     (ptr2),y
        sta     (ptr1),y
        dey
        bpl     :-

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

loop:   dec     index
        bmi     finish

        ;; Name
        lda     index
        jsr     GetFileEntryAddr
        stax    ptr_file
        lda     index
        jsr     GetResourceEntryAddr
        stax    ptr_res
        jsr     _CopyString

        ;; Flags
        ldy     #kSelectorEntryFlagsOffset
        lda     (ptr_file),y
        sta     (ptr_res),y

        ;; Path
        lda     index
        jsr     GetFilePathAddr
        stax    ptr_file
        lda     index
        jsr     GetResourcePathAddr
        stax    ptr_res
        jsr     _CopyString

        jmp     loop

finish:
        ;; Menu size
        lda     selector_list + kSelectorListNumPrimaryRunListOffset
        clc
        adc     #kSelectorMenuFixedItems
        sta     selector_menu
        ;; No separator if it is last
        cmp     #kSelectorMenuFixedItems
    IF_EQ
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
:       lda     (ptr_file),y
        sta     (ptr_res),y
        dey
        bpl     :-

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

        DEFINE_CREATE_PARAMS create_params, filename_buffer, ACCESS_DEFAULT, $F1
        DEFINE_OPEN_PARAMS open_origpfx_params, filename_buffer, io_buf

        DEFINE_OPEN_PARAMS open_curpfx_params, filename, io_buf

filename:
        PASCAL_STRING kPathnameSelectorList

        DEFINE_READWRITE_PARAMS read_params, selector_list, kSelectorListBufSize
        DEFINE_READWRITE_PARAMS write_params, selector_list, kSelectorListBufSize
        DEFINE_CLOSE_PARAMS close_params

.proc WriteFileToOriginalPrefix
        param_call main::CopyDeskTopOriginalPrefix, filename_buffer
        inc     filename_buffer ; Append '/' separator
        ldx     filename_buffer
        lda     #'/'
        sta     filename_buffer,x

        ldx     #$00            ; Append filename
        ldy     filename_buffer
:       inx
        iny
        lda     filename,x
        sta     filename_buffer,y
        cpx     filename
        bne     :-
        sty     filename_buffer

        copy8   #0, second_try_flag

@retry: MLI_CALL CREATE, create_params
        MLI_CALL OPEN, open_origpfx_params
        bcc     write

        ;; First time - ask if we should even try.
        lda     second_try_flag
        bne     :+
        inc     second_try_flag
        lda     #kErrSaveChanges
        jsr     ShowAlert
        cmp     #kAlertResultOK
        beq     @retry
        bne     cancel          ; always

        ;; Second time - prompt to insert.
:       lda     #kErrInsertSystemDisk
        jsr     ShowAlert
        cmp     #kAlertResultOK
        beq     @retry

cancel: rts

write:  lda     open_origpfx_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num

@retry: MLI_CALL WRITE, write_params
        bcc     close
        jsr     ShowAlert
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        beq     @retry          ; `kAlertResultTryAgain` = 0

close:  MLI_CALL CLOSE, close_params
        rts

second_try_flag:
        .byte   0
.endproc ; WriteFileToOriginalPrefix

;;; ============================================================
;;; Read SELECTOR.LIST file (using current prefix)

.proc ReadFile
@retry: MLI_CALL OPEN, open_curpfx_params
        bcc     read
        lda     #kErrInsertSystemDisk
        jsr     ShowAlert
        cmp     #kAlertResultOK
        beq     @retry
        return  #$FF

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
.endproc ; ReadFile

;;; ============================================================
;;; Write SELECTOR.LIST file (using current prefix)

.proc WriteFile
@retry: MLI_CALL OPEN, open_curpfx_params
        bcc     write
        lda     #kErrInsertSystemDisk
        jsr     ShowAlert
        cmp     #kAlertResultOK
        beq     @retry
        return  #$FF

write:  lda     open_curpfx_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
@retry: MLI_CALL WRITE, write_params
        bcc     close
        jsr     ShowAlert
        ASSERT_EQUALS ::kAlertResultTryAgain, 0
        beq     @retry          ; `kAlertResultTryAgain` = 0

close:  MLI_CALL CLOSE, close_params
        rts
.endproc ; WriteFile

;;; ============================================================

.proc IsEntryCallback
        tay
        ldx     entries_flag_table,y
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
        param_call main::CopyPtr1ToBuf, text_buffer2
        param_jump main::DrawString, text_buffer2
.endproc ; DrawEntryCallback

.proc SelChangeCallback
        jmp     UpdateOKButton
.endproc ; SelChangeCallback


;;; ============================================================

.endscope ; SelectorPickOverlay

selector_picker__Exec    := SelectorPickOverlay::Exec

SelectorPickOverlay__IsEntryCallback   := SelectorPickOverlay::IsEntryCallback
SelectorPickOverlay__DrawEntryCallback := SelectorPickOverlay::DrawEntryCallback
SelectorPickOverlay__SelChangeCallback := SelectorPickOverlay::SelChangeCallback

        ENDSEG OverlayShortcutPick
