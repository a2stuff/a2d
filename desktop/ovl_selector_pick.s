;;; ============================================================
;;; Overlay for Selector Picker
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

;;; See docs/Selector_List_Format.md for file format

.proc SelectorPickOverlay
        .org ::kOverlayShortcutPickAddress

        MLIEntry := main::MLIRelayImpl
        MGTKEntry := MGTKRelayImpl

io_buf := $0800

selector_list   := $0C00

Exec:
        sta     selector_action
        ldx     #$FF
        stx     clean_flag      ; set "clean"
        cmp     #SelectorAction::add
        beq     L903C
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
        copy    #0, selector_menu_items_updated_flag
        jsr     main::GetCopiedToRAMCardFlag
        cmp     #$80
        bne     L9015
        jsr     WriteFileToOriginalPrefix
        pla
        rts

L903C:  ldx     #1
        lda     selector_menu
        cmp     #kSelectorMenuMinItems + 8
        bcc     L9052
        inx
L9052:  lda     #$00
        sta     path_buf0
        sta     path_buf1
        ldy     #$03
        lda     #$02
        jsr     file_dialog__Exec
        pha
        txa
        pha
        tya
        pha
        lda     #kDynamicRoutineRestore5000
        jsr     JUMP_TABLE_RESTORE_OVL
        jsr     JUMP_TABLE_CLEAR_UPDATES ; Add File Dialog close
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
        cmp     #1
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

L90F4:  lda     #kErrSelectorListFull
        jsr     ShowAlert
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
        copy    #$FF, selected_index
        jsr     OpenWindow
        jsr     ReadFileAndDrawEntries
        bpl     :+
        jmp     CloseWindow

:       jsr     PopulateEntriesFlagTable
        FALL_THROUGH_TO dialog_loop
.endproc

dialog_loop:
        jsr     EventLoop
        bmi     dialog_loop     ; N set = nothing selected, re-enter loop

        beq     :+              ; Z set = OK selected
        jmp     DoCancel

        ;; Which action are we?
:       lda     selected_index
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
        lda     selected_index
        jsr     MaybeToggleEntryHilite
        jsr     main::SetCursorWatch
        lda     selected_index
        jsr     RemoveEntry
        bne     :+              ; Z set on success

        inc     clean_flag      ; mark as "dirty"

:       jsr     main::SetCursorPointer
        jmp     DoCancel
.endproc

;;; ============================================================

.proc DoEdit
        lda     selected_index
        jsr     MaybeToggleEntryHilite
        jsr     CloseWindow
        lda     selected_index
        jsr     GetFileEntryAddr
        stax    $06
        ldy     #$00
        lda     ($06),y
        tay
l1:     lda     ($06),y
        sta     path_buf1,y
        dey
        bpl     l1
        ldy     #kSelectorEntryFlagsOffset
        lda     ($06),y
        sta     flags
        lda     selected_index
        jsr     GetFilePathAddr
        stax    $06
        ldy     #0
        lda     ($06),y
        tay
l2:     lda     ($06),y
        sta     path_buf0,y
        dey
        bpl     l2
        ldx     #$01
        lda     selected_index
        cmp     #kSelectorListNumPrimaryRunListEntries+1
        bcc     l3
        inx
l3:     clc
        lda     flags
        rol     a
        rol     a
        adc     #$01
        tay
        lda     #$02
        jsr     file_dialog__Exec
        pha
        txa
        pha
        tya
        pha
        lda     #kDynamicRoutineRestore5000
        jsr     JUMP_TABLE_RESTORE_OVL
        jsr     JUMP_TABLE_CLEAR_UPDATES ; Edit File Dialog close
        pla
        tay
        pla
        tax
        pla
        beq     l4
        rts

l4:     inc     clean_flag      ; mark as "dirty"
        stx     which_run_list
        sty     copy_when
        lda     #$00
l5:     dey                     ; map 0/1/2 to $00/$80/$C0
        beq     l6
        sec
        ror     a
        jmp     l5

l6:     sta     copy_when
        jsr     ReadFile
        bpl     l7
        jmp     CloseWindow

l7:     lda     selected_index
        cmp     #kSelectorListNumPrimaryRunListEntries+1
        bcc     l10
        lda     which_run_list
        cmp     #2
        beq     l13
        lda     num_primary_run_list_entries
        cmp     #kSelectorListNumPrimaryRunListEntries
        bne     l8
        jmp     L90F4

l8:     lda     selected_index
        jsr     RemoveEntry
        beq     l9
        jmp     CloseWindow

l9:     ldx     num_primary_run_list_entries
        inc     num_primary_run_list_entries
        inc     selector_list + kSelectorListNumPrimaryRunListOffset
        txa
        jmp     l14

l10:    lda     which_run_list
        cmp     #1
        beq     l13
        lda     num_secondary_run_list_entries
        cmp     #kSelectorListNumSecondaryRunListEntries
        bne     l11
        jmp     Init

l11:    lda     selected_index
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

l13:    lda     selected_index
l14:    ldy     copy_when
        jsr     AssignEntryData
        jsr     WriteFile
        beq     l15
        jmp     CloseWindow

l15:    jsr     main::SetCursorPointer
        jmp     L900F

flags:  .byte   0
.endproc

;;; ============================================================

.proc DoRun
        lda     selected_index
        jsr     MaybeToggleEntryHilite
        jsr     main::SetCursorWatch
        lda     selected_index
        jsr     GetFileEntryAddr
        stax    $06
        ldy     #kSelectorEntryFlagsOffset
        lda     ($06),y
        cmp     #kSelectorEntryCopyNever
        beq     l5
        sta     L938A
        jsr     main::GetCopiedToRAMCardFlag
        beq     l5
        lda     L938A
        beq     l2
        lda     selected_index
        jsr     GetEntryRamcardFileInfo
        beq     l3
        lda     selected_index
        jsr     GetFilePathAddr
        stax    $06
        ldy     #0
        lda     ($06),y
        tay
l1:     lda     ($06),y
        sta     buf_win_path,y
        dey
        bpl     l1
        lda     #$FF
        jmp     DoCancel

l2:     lda     selected_index
        jsr     GetEntryRamcardFileInfo
        bne     l5
l3:     lda     selected_index
        jsr     GetEntryRamcardPath
        stax    $06
        ldy     #0
        lda     ($06),y
        tay
l4:     lda     ($06),y
        sta     buf_win_path,y
        dey
        bpl     l4
        jmp     l7

l5:     lda     selected_index
        jsr     GetFilePathAddr
        stax    $06
        ldy     #0
        lda     ($06),y
        tay
l6:     lda     ($06),y
        sta     buf_win_path,y
        dey
        bpl     l6
l7:     ldy     buf_win_path
l8:     lda     buf_win_path,y
        cmp     #$2F
        beq     l9
        dey
        bne     l8
l9:     dey
        sty     L938A
        iny
        ldx     #$00
l10:    iny
        inx
        lda     buf_win_path,y
        sta     buf_filename2,x
        cpy     buf_win_path
        bne     l10
        stx     buf_filename2
        lda     L938A
        sta     buf_win_path
        jsr     CloseWindow
        jsr     JUMP_TABLE_CLEAR_UPDATES ; Run dialog OK
        jsr     JUMP_TABLE_LAUNCH_FILE
        jsr     main::SetCursorPointer
        copy    #$FF, selected_index
        return  #0
.endproc

;;; ============================================================
;;; Cancel from Edit, Delete, or Run
;;; Also OK from Delete (since that closes immediately)

.proc DoCancel
        pha
        lda     selector_action
        cmp     #SelectorAction::edit
        bne     :+

        lda     #kDynamicRoutineRestore5000
        jsr     JUMP_TABLE_RESTORE_OVL

:       jsr     CloseWindow
        jsr     JUMP_TABLE_CLEAR_UPDATES
        pla
        jmp     L900F
.endproc

;;; ============================================================

.proc CloseWindow
        MGTK_CALL MGTK::CloseWindow, winfo_entry_picker
        rts
.endproc

;;; ============================================================

L938A:  .byte   0               ; ???

num_primary_run_list_entries:
        .byte   0
num_secondary_run_list_entries:
        .byte   0

selected_index:
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
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, entry_picker_frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        MGTK_CALL MGTK::MoveTo, entry_picker_line1_start
        MGTK_CALL MGTK::LineTo, entry_picker_line1_end
        MGTK_CALL MGTK::MoveTo, entry_picker_line2_start
        MGTK_CALL MGTK::LineTo, entry_picker_line2_end

        MGTK_CALL MGTK::SetPenMode, penXOR

        MGTK_CALL MGTK::FrameRect, entry_picker_ok_rect
        MGTK_CALL MGTK::MoveTo, entry_picker_ok_pos
        param_call main::DrawString, aux::ok_button_label

        MGTK_CALL MGTK::FrameRect, entry_picker_cancel_rect
        MGTK_CALL MGTK::MoveTo, entry_picker_cancel_pos
        param_call main::DrawString, aux::cancel_button_label

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
.endproc

;;; ============================================================

;;; Inputs: A,X=string, Y=index
.proc DrawEntry
        stax    $06

        tya
        jsr     GetOptionPos
        addax   #kShortcutPickerTextHOffset, entry_picker_item_rect::x1
        tya
        ldx     #0
        addax   #kShortcutPickerTextYOffset, entry_picker_item_rect::y1

        MGTK_CALL MGTK::MoveTo, entry_picker_item_rect::topleft
        ldax    $06
        jmp     DrawString
.endproc

;;; ============================================================
;;; Get the coordinates of an option by index.
;;; Input: A = volume index
;;; Output: A,X = x coordinate, Y = y coordinate
.proc GetOptionPos
        sta     index
        .repeat ::kShortcutPickerRowShift
        lsr                     ; lo
        .endrepeat
        ldx     #0              ; hi
        ldy     #kShortcutPickerItemWidth
        jsr     Multiply_16_8_16
        clc
        adc     #<kShortcutPickerLeft
        pha                     ; lo
        txa
        adc     #>kShortcutPickerLeft
        pha                     ; hi

        ;; Y coordinate
        index := *+1
        lda     #SELF_MODIFIED_BYTE
        and     #kShortcutPickerRows-1
        ldx     #0              ; hi
        ldy     #kShortcutPickerItemHeight
        jsr     Multiply_16_8_16
        clc
        adc     #kShortcutPickerTop

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
        sub16   screentowindow_params::windowy, #kShortcutPickerTop, screentowindow_params::windowy
        bmi     done

        ldax    screentowindow_params::windowy
        ldy     #kShortcutPickerItemHeight
        jsr     Divide_16_8_16  ; A = row

        cmp     #kShortcutPickerRows
        bcs     done
        sta     row

        ;; Column
        sub16   screentowindow_params::windowx, #kShortcutPickerLeft, screentowindow_params::windowx
        bmi     done

        ldax    screentowindow_params::windowx
        ldy     #kShortcutPickerItemWidth
        jsr     Divide_16_8_16  ; A = col

        cmp     #kShortcutPickerCols
        bcs     done

        ;; Index
        .repeat ::kShortcutPickerRowShift
        asl
        .endrepeat
        row := *+1
        ora     #SELF_MODIFIED_BYTE
        rts

done:   return  #$FF
.endproc

;;; ============================================================

;;; Copy the string somewhere visible to MGTK in auxmem.
.proc DrawString
        ptr := $06

        stax    ptr
        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        sta     text_buffer2::length,y
        dey
        bpl     :-

        MGTK_CALL MGTK::DrawText, text_buffer2
        rts
.endproc

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
.endproc

;;; ============================================================
;;; When returning from event loop:
;;; N = nothing selected, re-enter loop
;;; Z = OK selected
;;; Otherwise: Cancel selected

.proc EventLoop
        jsr     main::YieldLoop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
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
        MGTK_CALL MGTK::InRect, entry_picker_ok_rect
        cmp     #MGTK::inrect_inside
        bne     not_ok
        param_call main::ButtonEventLoop, winfo_entry_picker::kWindowId, entry_picker_ok_rect
        bmi     :+              ; nothing selected, re-enter loop
        lda     #$00            ; OK selected
:       rts

not_ok: MGTK_CALL MGTK::InRect, entry_picker_cancel_rect
        cmp     #MGTK::inrect_inside
        bne     not_cancel
        param_call main::ButtonEventLoop, winfo_entry_picker::kWindowId, entry_picker_cancel_rect
        bmi     :+              ; nothing selected, re-enter loop
        lda     #$01            ; Cancel selected
:       rts

not_cancel:
        jsr     GetOptionIndexFromCoords
        bmi     done

        ;; Is it valid?
        sta     new_selection
        cmp     #8
        bcs     l5
        cmp     num_primary_run_list_entries
        bcs     l6

l4:     cmp     selected_index           ; same as previous selection?
        beq     :+
        lda     selected_index
        jsr     MaybeToggleEntryHilite
        lda     new_selection
        sta     selected_index
        jsr     MaybeToggleEntryHilite
:       jsr     main::StashCoordsAndDetectDoubleClick
        rts

l5:     sec
        sbc     #kSelectorListNumPrimaryRunListEntries
        cmp     num_secondary_run_list_entries
        bcs     l6
        clc
        adc     #kSelectorListNumPrimaryRunListEntries
        jmp     l4

l6:     lda     selected_index
        jsr     MaybeToggleEntryHilite
        copy    #$FF, selected_index ; nothing selected, re-enter loop

done:   return  #$FF


new_selection:
        .byte   0
.endproc

;;; ============================================================

.proc MaybeToggleEntryHilite
        bmi     ret

        jsr     GetOptionPos
        stax    entry_picker_item_rect::x1
        addax   #kShortcutPickerItemWidth-1, entry_picker_item_rect::x2
        tya                     ; y lo
        ldx     #0              ; y hi
        stax    entry_picker_item_rect::y1
        addax   #kShortcutPickerItemHeight-1, entry_picker_item_rect::y2

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, entry_picker_item_rect
        MGTK_CALL MGTK::SetPenMode, pencopy

ret:    rts
.endproc

;;; ============================================================
;;; Key down handler

.proc HandleKey
        lda     event_params::modifiers
        cmp     #MGTK::event_modifier_solid_apple
        bne     :+
        return  #$FF
:       lda     event_params::key

        cmp     #CHAR_LEFT
        jeq     HandleKeyLeft

        cmp     #CHAR_RIGHT
        jeq     HandleKeyRight

        cmp     #CHAR_RETURN
        jeq     HandleKeyReturn

        cmp     #CHAR_ESCAPE
        jeq     HandleKeyEscape

        cmp     #CHAR_DOWN
        jeq     HandleKeyDown

        cmp     #CHAR_UP
        jeq     HandleKeyUp

        return  #$FF
.endproc

;;; ============================================================

.proc HandleKeyReturn
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, entry_picker_ok_rect
        MGTK_CALL MGTK::PaintRect, entry_picker_ok_rect
        return  #0
.endproc

;;; ============================================================

.proc HandleKeyEscape
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, entry_picker_cancel_rect
        MGTK_CALL MGTK::PaintRect, entry_picker_cancel_rect
        return  #1
.endproc

;;; ============================================================

.proc HandleKeyRight
        lda     num_primary_run_list_entries
        ora     num_secondary_run_list_entries
        beq     done

        lda     selected_index
        bpl     move           ; have a selection

        ;; No selection; find a valid one in top row
        ldx     #0
        lda     entries_flag_table
        bpl     set

        ldx     #8
        lda     entries_flag_table+8
        bpl     set

        ldx     #16
        lda     entries_flag_table+16
        bpl     set

        ;; Change selection
move:   lda     selected_index  ; unselect current
        jsr     MaybeToggleEntryHilite

        lda     selected_index
loop:   clc
        adc     #8
        cmp     #kSelectorListNumEntries
        bcc     :+
        clc
        adc     #1
        and     #7

:       tax
        lda     entries_flag_table,x
        bpl     set
        txa
        jmp     loop

set:    txa
        sta     selected_index
        jsr     MaybeToggleEntryHilite

done:   return  #$FF
.endproc

;;; ============================================================

.proc HandleKeyLeft
        lda     num_primary_run_list_entries
        ora     num_secondary_run_list_entries
        beq     done

        lda     selected_index
        bpl     move            ; have a selection

        ;; No selection - re-use logic to find last item
        jmp     HandleKeyUp

        ;; Change selection
move:   lda     selected_index  ; unselect current
        jsr     MaybeToggleEntryHilite

        lda     selected_index
loop:   sec
        sbc     #8
        bpl     :+
        sec
        sbc     #1
        and     #7
        ora     #16

:       tax
        lda     entries_flag_table,x
        bpl     set
        txa
        jmp     loop

set:    txa
        sta     selected_index
        jsr     MaybeToggleEntryHilite

done:   return  #$FF
.endproc

;;; ============================================================

.proc HandleKeyUp
        lda     num_primary_run_list_entries
        ora     num_secondary_run_list_entries
        beq     done

        lda     selected_index
        bpl     move            ; have a selection

        ;; No selection; find last valid one
        ldx     #kSelectorListNumEntries - 1
:       lda     entries_flag_table,x
        bpl     set
        dex
        bpl     :-

        ;; Change selection
move:   lda     selected_index  ; unselect current
        jsr     MaybeToggleEntryHilite

        ldx     selected_index
loop:   dex                     ; to previous
        bmi     wrap
        lda     entries_flag_table,x
        bpl     set
        jmp     loop

wrap:   ldx     #kSelectorListNumEntries
        jmp     loop

set:    sta     selected_index
        jsr     MaybeToggleEntryHilite

done:   return  #$FF
.endproc

;;; ============================================================

.proc HandleKeyDown
        lda     num_primary_run_list_entries
        ora     num_secondary_run_list_entries
        beq     done

        lda     selected_index
        bpl     move           ; have a selection

        ;; No selection; find first valid one
        ldx     #0
:       lda     entries_flag_table,x
        bpl     set
        inx
        bne     :-

        ;; Change selection
move:   lda     selected_index  ; unselect current
        jsr     MaybeToggleEntryHilite

        ldx     selected_index
loop:   inx                     ; to next
        cpx     #kSelectorListNumEntries
        bcs     wrap
        lda     entries_flag_table,x
        bpl     set             ; valid!
        jmp     loop

wrap:   ldx     #AS_BYTE(-1)
        jmp     loop

        ;; Set the selection
set:    sta     selected_index
        jsr     MaybeToggleEntryHilite

done:   return  #$FF
.endproc

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
.endproc

;;; Table for 24 entries; index (0...23) if in use, $FF if empty
entries_flag_table:
        .res    ::kSelectorListNumEntries, 0

;;; ============================================================
;;; Assigns name, flags, and path to an entry in the file buffer
;;; and (if it's in the primary run list) also updates the
;;; resource data (used for menus, etc).
;;; Inputs: A=entry index, Y=new flags
;;;         `path_buf1` is name, `path_buf0` is path

.proc AssignEntryData
        cmp     #8
        bcc     :+
        jmp     AssignSecondaryRunListEntryData

:       sta     index
        tya                     ; flags
        pha

        ptr_file = $06          ; pointer into file buffer

        ;; Assign name in `path_buf1` to file
        lda     index
        jsr     GetFileEntryAddr
        stax    ptr_file
        ldy     path_buf1
:       lda     path_buf1,y
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
.endproc

;;; ============================================================
;;; Assigns name, flags, and path to an entry in the file buffer.
;;; Inputs: A=entry index, Y=new flags
;;;         `path_buf1` is name, `path_buf0` is path

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
        ldy     path_buf1
:       lda     path_buf1,y
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
.endproc

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
.endproc

.endproc

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
        jsr     CopyString

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
        jsr     CopyString

        jmp     loop

finish:
        ;; Menu size
        lda     selector_list + kSelectorListNumPrimaryRunListOffset
        clc
        adc     #kSelectorMenuMinItems
        sta     selector_menu

        ;; Re-initialize the menu so that new widths can be pre-computed.
        ;; That will un-hilite the Selector menu, so re-hilite it so
        ;; it un-hilites correctly when finally dismissed.

        MGTK_CALL MGTK::SetMenu, aux::desktop_menu
        jsr     main::ToggleMenuHilite
        jsr     main::ShowClockForceUpdate

        rts

;;; Copy the string at `ptr_file` to `ptr_res`.
.proc CopyString
        ldy     #0
        lda     (ptr_file),y
        tay
:       lda     (ptr_file),y
        sta     (ptr_res),y
        dey
        bpl     :-

        rts
.endproc

index:  .byte   0
.endproc


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
.endproc

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
.endproc

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
.endproc

;;; ============================================================
;;; Path address in the resource block (used for invoking)
;;; Input: A = Entry
;;; Output: A,X = Address

.proc GetResourcePathAddr
        jsr     main::ATimes64
        clc
        adc     #<run_list_paths
        tay
        txa
        adc     #>run_list_paths
        tax
        tya
        rts
.endproc

;;; ============================================================
;;; Write out SELECTOR.LIST file, using original prefix.
;;; Used if DeskTop was copied to RAMCard.

filename_buffer := $1C00

        DEFINE_CREATE_PARAMS create_params, filename_buffer, ACCESS_DEFAULT, $F1
        DEFINE_OPEN_PARAMS open_origpfx_params, filename_buffer, io_buf

        DEFINE_OPEN_PARAMS open_curpfx_params, filename, io_buf

filename:
        PASCAL_STRING kFilenameSelectorList

        DEFINE_READ_PARAMS read_params, selector_list, kSelectorListBufSize
        DEFINE_WRITE_PARAMS write_params, selector_list, kSelectorListBufSize
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

        copy    #0, second_try_flag

@retry: MLI_CALL CREATE, create_params
        MLI_CALL OPEN, open_origpfx_params
        beq     write

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
        beq     close
        jsr     JUMP_TABLE_SHOW_ALERT
        .assert kAlertResultTryAgain = 0, error, "Branch assumes enum value"
        beq     @retry          ; `kAlertResultTryAgain` = 0

close:  MLI_CALL CLOSE, close_params
        rts

second_try_flag:
        .byte   0
.endproc

;;; ============================================================
;;; Read SELECTOR.LIST file (using current prefix)

.proc ReadFile
@retry: MLI_CALL OPEN, open_curpfx_params
        beq     read
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
.endproc

;;; ============================================================
;;; Write SELECTOR.LIST file (using current prefix)

.proc WriteFile
@retry: MLI_CALL OPEN, open_curpfx_params
        beq     write
        lda     #kErrInsertSystemDisk
        jsr     ShowAlert
        cmp     #kAlertResultOK
        beq     @retry
        return  #$FF

write:  lda     open_curpfx_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
@retry: MLI_CALL WRITE, write_params
        beq     close
        jsr     JUMP_TABLE_SHOW_ALERT
        .assert kAlertResultTryAgain = 0, error, "Branch assumes enum value"
        beq     @retry          ; `kAlertResultTryAgain` = 0

close:  MLI_CALL CLOSE, close_params
        rts
.endproc

;;; ============================================================

.proc ReadFileAndDrawEntries
        jsr     ReadFile
        bpl     DrawAllEntries
        rts
.endproc

;;; ============================================================

.proc DrawAllEntries
        lda     selector_list + kSelectorListNumPrimaryRunListOffset
        sta     num_primary_run_list_entries
        beq     secondary_run_list

        ;; Draw "primary run list" entries
        lda     #0
        sta     index
loop1:  lda     index
        cmp     num_primary_run_list_entries
        beq     secondary_run_list
        jsr     main::ATimes16
        clc
        adc     #kSelectorListEntriesOffset
        pha
        txa
        adc     #>selector_list
        tax
        pla
        ldy     index
        jsr     DrawEntry
        inc     index
        jmp     loop1

        ;; Draw "secondary run list" entries
secondary_run_list:
        lda     selector_list + kSelectorListNumSecondaryRunListOffset
        sta     num_secondary_run_list_entries
        beq     done
        lda     #0
        sta     index
loop2:  lda     index
        cmp     num_secondary_run_list_entries
        beq     done
        clc
        adc     #8
        jsr     main::ATimes16
        clc
        adc     #kSelectorListEntriesOffset
        pha
        txa
        adc     #>selector_list
        tax
        lda     index
        clc
        adc     #8
        tay
        pla
        jsr     DrawEntry
        inc     index
        jmp     loop2

done:   return  #0

index:  .byte   0
.endproc

;;; ============================================================
;;; Populate `get_file_info_params` with the info for the entry
;;; as copied to RAMCard.
;;; Input: A=entry number
;;; Output: `get_file_info_params` populated.

        DEFINE_GET_FILE_INFO_PARAMS get_file_info_params, 0

.proc GetEntryRamcardFileInfo
        jsr     GetEntryRamcardPath
        stax    get_file_info_params::pathname
        MLI_CALL GET_FILE_INFO, get_file_info_params
        rts
.endproc

;;; ============================================================
;;; Get the path for an entry as it would be on a RAMCard.
;;; e.g. if the path was "/APPS/MOUSEPAINT/MP.SYSTEM" this would
;;; return the address of a buffer with "/RAM/MOUSEPAINT/MP.SYSTEM"
;;; Input: A=entry number
;;; Output: A,X=path buffer

.proc GetEntryRamcardPath
        ptr := $06

        sta     index
        param_call main::CopyRAMCardPrefix, buf
        lda     index
        jsr     GetFilePathAddr
        stax    ptr

        ;; Find last / in entry's path
        ldy     #0
        lda     (ptr),y
        sta     len
        tay
:       lda     (ptr),y
        cmp     #'/'
        beq     :+
        dey
        bne     :-

        ;; And find preceding /
:       dey
:       lda     (ptr),y
        cmp     #'/'
        beq     :+
        dey
        bne     :-

        ;; Append everything after this to the buffer
:       dey
        ldx     buf
:       inx
        iny
        lda     (ptr),y
        sta     buf,x
        cpy     len
        bne     :-
        stx     buf

        ;; Return the buffer's address
        ldax    #buf
        rts

index:  .byte   0
len:    .byte   0
buf:    .res    ::kPathBufferSize
.endproc

;;; ============================================================

        PAD_TO ::kOverlayShortcutPickAddress + ::kOverlayShortcutPickLength

.endproc ; SelectorPickOverlay

selector_picker__Exec    := SelectorPickOverlay::Exec
