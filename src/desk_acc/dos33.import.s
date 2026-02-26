;;; ============================================================
;;; DOS3.3.IMPORT - Desk Accessory
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "dos33.import.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../inc/dos33.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../lib/alert_dialog.inc"
        .include "../desktop/desktop.inc"
        .include "../toolkits/btk.inc"
        .include "../toolkits/lbtk.inc"

;;; ============================================================
;;; Memory map
;;;
;;;              Main           Aux
;;;          :           : :           :
;;;          |           | |           |
;;;          | DHR       | | DHR       |
;;;  $2000   +-----------+ +-----------+
;;;          | Block Buf | |           |
;;;  $1E00   +-----------+ |           |
;;;          | RWTS Buf1 | |           |
;;;  $1D00   +-----------+ |           |
;;;          | T/S List  | |           |
;;;  $1C00   +-----------+ |    ^      |
;;;          | I/O Buf   | |    |      |
;;;          |           | |    |      |
;;;  $1800   +-----------+ |  Catalog  |
;;;          |           | |  Entries  |
;;;          |           | +-----------+ ~$1200
;;;          :           : :           :
;;;          | (unused)  | | (unused)  |
;;;          |           | +-----------+ ????
;;;   ????   +-----------+ |           |
;;;          |           | | DA GUI    |
;;;          | DA Logic  | | Code &    |
;;;          | & RWTS    | | Resources |
;;;   $800   +-----------+ +-----------+
;;;          :           : :           :

;;; ============================================================

.struct ControlBlock
num_entries     .byte
dev_count       .byte
dev_list        .res 14
unit_num        .byte
volume_number   .byte
selected_index  .byte
progress_num    .word
progress_denom  .word
.endstruct

;;; ============================================================

        DA_HEADER

        DA_START_AUX_SEGMENT

.struct CatalogEntry
TypeFlags .byte
Name      .res 1 + dos33::MaxFilenameLen ; length-prefixed
Length    .word
Track     .byte
Sector    .byte
.endstruct

kMaxCatalogEntries = 105

        EntryBuffer := $2000 - kMaxCatalogEntries * .sizeof(CatalogEntry)


;;; ============================================================
;;; Resources used across windows

        .include "../lib/event_params.s"

NoOp:    rts

pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY

grafport_win:   .tag    MGTK::GrafPort

control_block:  .tag    ControlBlock

;;; ============================================================
;;; Alerts

.params AlertNoWindowsOpen
        .addr   str_alert_no_windows_open
        .byte   AlertButtonOptions::OK
        .byte   AlertOptions::Beep | AlertOptions::SaveBack
.endparams
str_alert_no_windows_open:
        PASCAL_STRING res_string_alert_no_windows_open

;;; ============================================================

.scope DevicePicker

kDAWindowId     = $80
kDAWidth        = 270
kDAHeight       = kPickerHeight + 45
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

kButtonsTop  = kDAHeight - 20
kButtonsRight = kDAWidth - 19
kButtonsGap  = 10

kPickerRows            = 6
kPickerWindowId        = kDAWindowId+1
kPickerWidth           = kDAWidth - 60
kPickerWidthSB         = kPickerWidth + 20
kPickerHeight          = kPickerRows * kListItemHeight - 1
kPickerLeft            = kDALeft + (kDAWidth - kPickerWidthSB) / 2
kPickerTop             = kDATop + 20


.params winfo_picker
window_id:      .byte   kDAWindowId
options:        .byte   MGTK::Option::dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   0
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   kDAWidth
mincontheight:  .word   kDAHeight
maxcontwidth:   .word   kDAWidth
maxcontheight:  .word   kDAHeight
port:
        DEFINE_POINT viewloc, kDALeft, kDATop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDAWidth, kDAHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::notpencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

        DEFINE_RECT_FRAME frame_rect, kDAWidth, kDAHeight

        DEFINE_BUTTON ok_button, kDAWindowId, res_string_button_ok, kGlyphReturn, kButtonsRight - kButtonWidth*2 - kButtonsGap, kButtonsTop
        DEFINE_BUTTON cancel_button, kDAWindowId, res_string_button_cancel, res_string_button_cancel_shortcut, kButtonsRight - kButtonWidth, kButtonsTop


        DEFINE_LIST_BOX_WINFO winfo_picker_listbox, \
                kPickerWindowId, \
                kPickerLeft, \
                kPickerTop, \
                kPickerWidth, \
                kPickerHeight, \
                DEFAULT_FONT
        DEFINE_LIST_BOX listbox_rec, winfo_picker_listbox, \
                kPickerRows, 0, \
                DrawListEntryProc, OnSelChange, NoOp
        DEFINE_LIST_BOX_PARAMS lb_params, listbox_rec

.params getwinport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport_win
.endparams

;;; ============================================================

.proc Init
        copy8   control_block+ControlBlock::dev_count, listbox_rec::num_items
        copy8   #BTK::kButtonStateDisabled, ok_button::state

        MGTK_CALL MGTK::OpenWindow, winfo_picker

        MGTK_CALL MGTK::HideCursor
        jsr     DrawWindow
        MGTK_CALL MGTK::OpenWindow, winfo_picker_listbox
        LBTK_CALL LBTK::Init, lb_params
        MGTK_CALL MGTK::ShowCursor

        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        jsr     GetNextEvent

        cmp     #MGTK::EventKind::button_down
        jeq     HandleDown

        cmp     #MGTK::EventKind::key_down
        beq     HandleKey

        bne     InputLoop       ; always
.endproc ; InputLoop

.proc Exit
        ldx     listbox_rec::selected_index
    IF NC
        copy8   control_block+ControlBlock::dev_list,x, control_block+ControlBlock::unit_num
    END_IF

        MGTK_CALL MGTK::CloseWindow, winfo_picker_listbox
        MGTK_CALL MGTK::CloseWindow, winfo_picker
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts
.endproc ; Exit

;;; ============================================================

.proc HandleKey
        lda     event_params::key
    IF A IN #CHAR_UP, #CHAR_DOWN
        copy8   event_params::key, lb_params::key
        copy8   event_params::modifiers, lb_params::modifiers
        LBTK_CALL LBTK::Key, lb_params
        jmp     InputLoop
    END_IF

        ldx     event_params::modifiers
    IF NOT_ZERO
        ;; Modified
        lda     event_params::key
        jsr     ToUpperCase

      IF A = #kShortcutCloseWindow
        BTK_CALL BTK::Flash, cancel_button
        jmp     Exit
      END_IF

        jmp     InputLoop
    END_IF

        ;; Not modified
    IF A = #CHAR_ESCAPE
        BTK_CALL BTK::Flash, cancel_button
        copy8   #$FF, listbox_rec::selected_index
        jmp     Exit
    END_IF

    IF A = #CHAR_RETURN
        BTK_CALL BTK::Flash, ok_button
        jmi     InputLoop
        jmp     Exit
    END_IF

        jmp     InputLoop
.endproc ; HandleKey

;;; ============================================================

.proc HandleDown
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        bne     done

        lda     findwindow_params::window_id
    IF A = #kPickerWindowId
        COPY_STRUCT event_params::coords, lb_params::coords
        LBTK_CALL LBTK::Click, lb_params
      IF NC
        jsr     DetectDoubleClick
       IF NC
        BTK_CALL BTK::Flash, ok_button
        jmp     Exit
       END_IF
      END_IF
        jmp     InputLoop
    END_IF

        cmp     #kDAWindowId
        bne     done

        ;; Click in DA content area
        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        MGTK_CALL MGTK::InRect, ok_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, ok_button
        bmi     done
        jmp     Exit
    END_IF

        MGTK_CALL MGTK::InRect, cancel_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, cancel_button
        bmi     done
        copy8   #$FF, listbox_rec::selected_index
        jmp     Exit
    END_IF

done:   jmp     InputLoop
.endproc ; HandleDown

;;; ============================================================

        DEFINE_LABEL prompt, res_string_select_disk, 20, 16

.proc DrawWindow
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        ;; ASSERT: Not obscured.
        MGTK_CALL MGTK::SetPort, grafport_win

        MGTK_CALL MGTK::HideCursor

        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        MGTK_CALL MGTK::MoveTo, prompt_label_pos
        MGTK_CALL MGTK::DrawString, prompt_label_str

        BTK_CALL BTK::Draw, ok_button
        BTK_CALL BTK::Draw, cancel_button


        MGTK_CALL MGTK::ShowCursor
        rts
.endproc ; DrawWindow


str_template:
        PASCAL_STRING res_string_slot_drive_pattern
        kSlotOffset = res_const_slot_drive_pattern_offset1
        kDriveOffset = res_const_slot_drive_pattern_offset2

;;; Called with A = index
.proc DrawListEntryProc

        tax                     ; X = index
        lda     control_block+ControlBlock::dev_list,x
        pha                     ; A = unit number

        and     #%01110000      ; A = 0sss0000
        lsr                     ; A = 00sss000
        lsr                     ; A = 000sss00
        lsr                     ; A = 0000sss0
        lsr                     ; A = 00000sss
        ora     #'0'
        sta     str_template + kSlotOffset

        pla                     ; A = unit number
        rol                     ; C = drive 1/2
        lda     #'1'
        adc     #0
        sta     str_template + kDriveOffset

        MGTK_CALL MGTK::DrawString, str_template
        rts
.endproc ; DrawListEntryProc

.proc OnSelChange
        lda     listbox_rec::selected_index
        ASSERT_EQUALS BTK::kButtonStateChecked, %10000000
        and     #BTK::kButtonStateChecked
        sta     ok_button::state
        BTK_CALL BTK::Hilite, ok_button
        rts
.endproc ; OnSelChange

.endscope ; DevicePicker

;;; ============================================================

.scope Catalog

kDAWindowId     = $80
kDAWidth        = 355
kDAHeight       = kCatalogHeight + 46
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

kButtonsTop  = 8
kButtonsRight = kDAWidth - 19
kButtonsGap  = 10

kProgressBarTop = 23
kProgressBarInset = 20
kProgressBarWidth = kDAWidth - kProgressBarInset*2
kProgressBarHeight = 7

kCatalogRows            = 11
kCatalogWindowId        = kDAWindowId+1
kCatalogWidth           = kDAWidth - 60
kCatalogWidthSB         = kCatalogWidth + 20
kCatalogHeight          = kCatalogRows * kListItemHeight - 1
kCatalogLeft            = kDALeft + (kDAWidth - kCatalogWidthSB) / 2
kCatalogTop             = kDATop + 36

.params winfo_catalog
window_id:      .byte   kDAWindowId
options:        .byte   MGTK::Option::dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   0
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   kDAWidth
mincontheight:  .word   kDAHeight
maxcontwidth:   .word   kDAWidth
maxcontheight:  .word   kDAHeight
port:
        DEFINE_POINT viewloc, kDALeft, kDATop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDAWidth, kDAHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::notpencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

        DEFINE_RECT_FRAME frame_rect, kDAWidth, kDAHeight

        DEFINE_BUTTON import_button, kDAWindowId, res_string_button_import, kGlyphReturn, kButtonsRight - kButtonWidth*2 - kButtonsGap, kButtonsTop
        DEFINE_BUTTON close_button, kDAWindowId, res_string_button_close, res_string_button_cancel_shortcut, kButtonsRight - kButtonWidth, kButtonsTop

        DEFINE_RECT_SZ progress_frame, kProgressBarInset-1, kProgressBarTop-1, kProgressBarWidth+2, kProgressBarHeight+2
        DEFINE_RECT_SZ progress_meter, kProgressBarInset, kProgressBarTop, kProgressBarWidth, kProgressBarHeight

pencopy:        .byte   MGTK::pencopy

progress_pattern:
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001

        DEFINE_LIST_BOX_WINFO winfo_catalog_listbox, \
                kCatalogWindowId, \
                kCatalogLeft, \
                kCatalogTop, \
                kCatalogWidth, \
                kCatalogHeight, \
                DEFAULT_FONT
        DEFINE_LIST_BOX listbox_rec, winfo_catalog_listbox, \
                kCatalogRows, 0, \
                DrawListEntryProc, OnSelChange, NoOp
        DEFINE_LIST_BOX_PARAMS lb_params, listbox_rec

.params getwinport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport_win
.endparams

        DEFINE_LABEL disk_vol, res_string_disk_volume_prefix, 20, 18

.params entry_muldiv_params
number:         .word   0                     ; (in) populated dynamically
numerator:      .word   .sizeof(CatalogEntry) ; (in) constant
denominator:    .word   1                     ; (in) constant
result:         .word   0                     ; (out)
remainder:      .word   0                     ; (out)
        REF_MULDIV_MEMBERS
.endparams

.params progress_muldiv_params
number:         .word   kProgressBarWidth ; (in) constant
numerator:      .word   0                 ; (in) populated dynamically
denominator:    .word   0                 ; (in) populated dynamically
result:         .word   0                 ; (out)
remainder:      .word   0                 ; (out)
        REF_MULDIV_MEMBERS
.endparams

;;; ============================================================

.proc Init
        copy8   control_block+ControlBlock::num_entries, listbox_rec::num_items
        copy8   #BTK::kButtonStateDisabled, import_button::state

        MGTK_CALL MGTK::OpenWindow, winfo_catalog

        MGTK_CALL MGTK::HideCursor
        jsr     DrawWindow
        MGTK_CALL MGTK::OpenWindow, winfo_catalog_listbox
        LBTK_CALL LBTK::Init, lb_params
        MGTK_CALL MGTK::ShowCursor

        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        jsr     GetNextEvent

        cmp     #MGTK::EventKind::button_down
        jeq     HandleDown

        cmp     #MGTK::EventKind::key_down
        beq     HandleKey

        bne     InputLoop       ; always
.endproc ; InputLoop

.proc ExitOK
        lda     #0
        FALL_THROUGH_TO Exit
.endproc ; ExitOK

.proc Exit
        pha                     ; A = error code (0 = success)
        MGTK_CALL MGTK::CloseWindow, winfo_catalog_listbox
        MGTK_CALL MGTK::CloseWindow, winfo_catalog
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        pla                     ; A = error code (0 = success)
        rts
.endproc ; Exit

;;; ============================================================

.proc HandleKey
        lda     event_params::key
    IF A IN #CHAR_UP, #CHAR_DOWN
        copy8   event_params::key, lb_params::key
        copy8   event_params::modifiers, lb_params::modifiers
        LBTK_CALL LBTK::Key, lb_params
        jmp     InputLoop
    END_IF

        ldx     event_params::modifiers
    IF NOT_ZERO
        ;; Modified
        lda     event_params::key
        jsr     ToUpperCase

      IF A = #kShortcutCloseWindow
        BTK_CALL BTK::Flash, close_button
        jmp     ExitOK
      END_IF

        jmp     InputLoop
    END_IF

        ;; Not modified
    IF A = #CHAR_ESCAPE
        BTK_CALL BTK::Flash, close_button
        jmp     ExitOK
    END_IF

    IF A = #CHAR_RETURN
        BTK_CALL BTK::Flash, import_button
        jmi     InputLoop
        jmp     Import
    END_IF

        jmp     InputLoop
.endproc ; HandleKey

;;; ============================================================

.proc HandleDown
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        bne     done

        lda     findwindow_params::window_id
    IF A = #kCatalogWindowId
        COPY_STRUCT event_params::coords, lb_params::coords
        LBTK_CALL LBTK::Click, lb_params
      IF NC
        jsr     DetectDoubleClick
       IF NC
        BTK_CALL BTK::Flash, import_button
        jmp     Import
       END_IF
      END_IF
        jmp     InputLoop
    END_IF

        cmp     #kDAWindowId
        bne     done

        ;; Click in DA content area
        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        MGTK_CALL MGTK::InRect, import_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, import_button
        bmi     done
        jmp     Import
    END_IF

        MGTK_CALL MGTK::InRect, close_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, close_button
        bmi     done
        jmp     ExitOK
    END_IF

done:   jmp     InputLoop
.endproc ; HandleDown

;;; ============================================================

.proc Import
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch
        copy8   listbox_rec::selected_index, control_block+ControlBlock::selected_index
        JSR_TO_MAIN ::main::DoImport
        pha                     ; A = error code (0 = success)
        jsr     ClearProgressMeter
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        pla                     ; A = error code (0 = success
        jne     Exit
        jmp     InputLoop
.endproc ; Import

;;; ============================================================

.proc DrawWindow
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        ;; ASSERT: Not obscured.
        MGTK_CALL MGTK::SetPort, grafport_win

        MGTK_CALL MGTK::HideCursor

        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        MGTK_CALL MGTK::FrameRect, progress_frame

        MGTK_CALL MGTK::MoveTo, disk_vol_label_pos
        MGTK_CALL MGTK::DrawString, disk_vol_label_str

        lda     control_block+ControlBlock::volume_number
        ldx     #0
        jsr     To3DigitString
        MGTK_CALL MGTK::DrawString, str_from_int

        BTK_CALL BTK::Draw, import_button
        BTK_CALL BTK::Draw, close_button

        MGTK_CALL MGTK::ShowCursor
        rts
.endproc ; DrawWindow

        DEFINE_POINT pt, 0, 0

;;; Called with A = index
.proc DrawListEntryProc
        pha
        pt_ptr := $06
        stxy    pt_ptr
        ldy     #.sizeof(MGTK::Point)-1
    DO
        copy8   (pt_ptr),y, pt,y
    WHILE dey : POS
        pla

        ;; Calculate address of `CatalogEntry`
        ptr := $04
        sta     entry_muldiv_params::number
        MGTK_CALL MGTK::MulDiv, entry_muldiv_params
        add16   entry_muldiv_params::result, #EntryBuffer, ptr

        kLockedX = 8
        kTypeX   = 20
        kSizeX   = 32
        kNameX   = 57

        ;; Locked?
        ldy     #CatalogEntry::TypeFlags
        lda     (ptr),y
    IF NS
        copy16  #kLockedX, pt::xcoord
        MGTK_CALL MGTK::MoveTo, pt
        MGTK_CALL MGTK::DrawString, str_locked
    END_IF

        ;; Type
        copy16  #kTypeX, pt::xcoord
        MGTK_CALL MGTK::MoveTo, pt
        ldy     #CatalogEntry::TypeFlags
        lda     (ptr),y
        and     #$7F
        jsr     clz
        copy8   type_table,x, str_type+1
        MGTK_CALL MGTK::DrawString, str_type

        ;; Size
        copy16  #kSizeX, pt::xcoord
        MGTK_CALL MGTK::MoveTo, pt
        ldy     #CatalogEntry::Length+1
        lda     (ptr),y
        tax
        dey
        lda     (ptr),y
        jsr     To3DigitString
        MGTK_CALL MGTK::DrawString, str_from_int

        ;; Name
        copy16  #kNameX, pt::xcoord
        MGTK_CALL MGTK::MoveTo, pt
        add16_8 ptr, #CatalogEntry::Name, @addr
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        rts
.endproc ; DrawListEntryProc

str_locked:     PASCAL_STRING "*"
str_type:       PASCAL_STRING "?"

;;; Index is count of leading zeros
type_table:
        .byte   'I', 'A', 'B', 'S', 'R', '1', '2', '?', 'T'

;;; Count leading zeros
;;; Input: A = byte
;;; Output: X = leading zeros (0...8)
.proc clz
        ldx     #0
    DO
        lsr     a
        BREAK_IF CS
    WHILE inx : X <> #8
        rts
.endproc ; clz

.proc OnSelChange
        lda     listbox_rec::selected_index
        ASSERT_EQUALS BTK::kButtonStateChecked, %10000000
        and     #BTK::kButtonStateChecked
        sta     import_button::state
        BTK_CALL BTK::Hilite, import_button
        rts
.endproc ; OnSelChange

.proc UpdateProgressMeter
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        ;; ASSERT: Not obscured.
        MGTK_CALL MGTK::SetPort, grafport_win

        copy16  control_block+ControlBlock::progress_num, progress_muldiv_params::numerator
        copy16  control_block+ControlBlock::progress_denom, progress_muldiv_params::denominator
        MGTK_CALL MGTK::MulDiv, progress_muldiv_params
        add16   progress_muldiv_params::result, progress_meter::x1, progress_meter::x2

        MGTK_CALL MGTK::SetPattern, progress_pattern
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, progress_meter
        rts
.endproc ; UpdateProgressMeter

.proc ClearProgressMeter
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        ;; ASSERT: Not obscured.
        MGTK_CALL MGTK::SetPort, grafport_win

        add16   #kProgressBarWidth, progress_meter::x1, progress_meter::x2

        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, progress_meter
        rts
.endproc ; ClearProgressMeter

.endscope ; Catalog

;;; ============================================================

.proc To3DigitString
        jsr     IntToString

        ;; TODO: Make this more elegant
        lda     str_from_int
    IF A = #1
        copy8   str_from_int+1, str_from_int+3
        lda     #'0'
        sta     str_from_int+1
        sta     str_from_int+2
        copy8   #3, str_from_int
        rts
    END_IF

    IF A = #2
        copy8   str_from_int+2, str_from_int+3
        copy8   str_from_int+1, str_from_int+2
        copy8   #'0', str_from_int+1
        copy8   #3, str_from_int
        rts
    END_IF

        rts
.endproc ; To3DigitString

str_from_int:   PASCAL_STRING "000000" ; filled in by IntToString

;;; ============================================================

        .include "../lib/uppercase.s"
        .include "../lib/get_next_event.s"
        .include "../lib/doubleclick.s"
        .include "../lib/inttostring.s"

        .assert * < EntryBuffer, error, "DA too large"
;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
.scope main

;;; ============================================================

        RWTS_BLOCK_BUF  := $1E00 ; 512 bytes
        RWTS_SECTOR_BUF := $1D00 ; 256 bytes
        TS_BUF          := $1C00 ; 256 bytes File Track/Sector List buffer
        IO_BUF          := $1800 ; 1kB ProDOS buffer

;;; ============================================================

        ;; Get active window's path
        jsr     GetWinPath
    IF NOT_ZERO
        TAIL_CALL JUMP_TABLE_SHOW_ALERT_PARAMS, AX=#aux::AlertNoWindowsOpen
    END_IF

        CLEAR_BIT7_FLAG dirty_flag

        JUMP_TABLE_MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch
        jsr     EnumerateDrives
        JUMP_TABLE_MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer

        jsr     SendControlBlock
        JSR_TO_AUX aux::DevicePicker::Init
        jsr     FetchControlBlock

        lda     control_block+ControlBlock::unit_num
        RTS_IF ZERO

        JUMP_TABLE_MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch
        jsr     LoadCatalogEntries
        JUMP_TABLE_MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        jsr     SendControlBlock
        JSR_TO_AUX aux::Catalog::Init
        pha                     ; A = error code (0 = success)
        jsr     FetchControlBlock
        pla                     ; A = error code (0 = success)
    IF NOT_ZERO
        ;; A = arbitrary ProDOS error but we don't support retries so...
        CALL    JUMP_TABLE_SHOW_ALERT, A=#ERR_IO_ERROR
    END_IF

        bit     dirty_flag
        RTS_IF NC               ; no change

        ;; Force window refresh
        window_id := $06
        JUMP_TABLE_MGTK_CALL MGTK::FrontWindow, window_id
        TAIL_CALL JUMP_TABLE_ACTIVATE_WINDOW, A=window_id

.proc EnumerateDrives
        ;; TODO: Iterate slot/drive vs. DEVLST? Order?

        copy8   DEVCNT, index
        copy8   #0, control_block+ControlBlock::dev_count

    DO
        ldx     index
        lda     DEVLST,x
        and     #UNIT_NUM_MASK
        jsr     IsDiskII
      IF ZS
        ldx     index
        lda     DEVLST,x
        and     #UNIT_NUM_MASK
        jsr     IsDOS33
       IF ZS
        ;; It is DOS 3.3 - append it to the list
        ldx     index
        lda     DEVLST,x
        and     #UNIT_NUM_MASK

        ldx     control_block+ControlBlock::dev_count
        sta     control_block+ControlBlock::dev_list,x
        inc     control_block+ControlBlock::dev_count
       END_IF
      END_IF
    WHILE dec index : POS

        rts

index:  .byte   0

.endproc ; EnumerateDrives


.proc LoadCatalogEntries
        copy8   #0, control_block+ControlBlock::num_entries
        copy16  #aux::EntryBuffer, aux_entry_ptr

        ;; Read VTOC
        CALL    do_read, A=#dos33::VTOCTrack, X=#dos33::VTOCSector
        jcs     exit_error
        lda     RWTS_SECTOR_BUF + dos33::VTOC::NumTracks
        cmp     #35
        jne     exit_error
        lda     RWTS_SECTOR_BUF + dos33::VTOC::NumSectors
        cmp     #16
        jne     exit_error

        copy8   RWTS_SECTOR_BUF + dos33::VTOC::VolumeNumber, control_block+ControlBlock::volume_number

        lda     RWTS_SECTOR_BUF + dos33::VTOC::FirstCatTrack
        ldx     RWTS_SECTOR_BUF + dos33::VTOC::FirstCatSector
    DO
        ;; For each sector
        jsr     do_read
        jcs     exit_error

        ldy     #dos33::FirstFileOffset

      DO
        ;; For each file
        sty     cur_cat_sector_offset ; +$00 `FileEntry::Track`
        lda     RWTS_SECTOR_BUF,y
        jeq     exit_success    ; $00 = entry free, so done

        cmp     #$FF            ; $FF = entry is deleted, so skip
        beq     next_file

        ;; Process valid file entry

        sta     entry_buf+aux::CatalogEntry::Track

        iny                     ; +$01 `FileEntry::Sector`
        copy8   RWTS_SECTOR_BUF,y, entry_buf+aux::CatalogEntry::Sector

        iny                     ; +$02 `FileEntry::TypeFlags`
        copy8   RWTS_SECTOR_BUF+aux::CatalogEntry::TypeFlags,y, entry_buf+aux::CatalogEntry::TypeFlags

        iny                     ; +$03 `FileEntry::Name`
        ldx     #0
       DO
        lda     RWTS_SECTOR_BUF,y
        and     #$7F            ; strip high bit
        sta     entry_buf+aux::CatalogEntry::Name+1,x
        iny
       WHILE inx : X <> #dos33::MaxFilenameLen

       DO
        dex
        lda     entry_buf+aux::CatalogEntry::Name+1,x
       WHILE A = #' '
        inx
        stx     entry_buf+aux::CatalogEntry::Name

        lda     cur_cat_sector_offset
        clc
        adc     #dos33::FileEntry::Length
        tay
        copy16  RWTS_SECTOR_BUF,y, entry_buf+aux::CatalogEntry::Length

        ;; Copy to buffer in Aux
        copy16  #entry_buf, STARTLO
        copy16  #entry_buf+.sizeof(aux::CatalogEntry)-1, ENDLO
        copy16  aux_entry_ptr, DESTINATIONLO
        CALL    AUXMOVE, C=1    ; main>aux
        add16_8 aux_entry_ptr, #.sizeof(aux::CatalogEntry)
        inc     control_block+ControlBlock::num_entries

next_file:
        lda     cur_cat_sector_offset
        clc
        adc     #.sizeof(dos33::FileEntry)
        tay
      WHILE CC

next_sector:
        lda     RWTS_SECTOR_BUF + dos33::NextCatSectorTrack
        ldx     RWTS_SECTOR_BUF + dos33::NextCatSectorSector
    WHILE NOT ZERO

exit_success:
        rts

exit_error:
        ;; TODO: Something useful here
        brk

aux_entry_ptr:
        .addr   0

cur_cat_sector_offset:
        .byte   0

entry_buf:
        .tag    aux::CatalogEntry

;;; A = track, X = sector
.proc do_read
        ldy     #<RWTS_SECTOR_BUF
        sty     $06
        ldy     #>RWTS_SECTOR_BUF
        sty     $06+1
        ldy     control_block+ControlBlock::unit_num
        jmp     RWTSRead
.endproc ; do_read

.endproc ; LoadCatalogEntries

;;; ============================================================

;;; Copied back and forth from main to aux
control_block:
        .tag    ControlBlock

.proc SendControlBlock
        ;; Copy to Aux
        copy16  #control_block, STARTLO
        copy16  #control_block+.sizeof(ControlBlock)-1, ENDLO
        copy16  #aux::control_block, DESTINATIONLO
        TAIL_CALL AUXMOVE, C=1  ; main>aux
.endproc ; SendControlBlock

.proc FetchControlBlock
        ;; Copy from Aux
        copy16  #aux::control_block, STARTLO
        copy16  #aux::control_block+.sizeof(ControlBlock)-1, ENDLO
        copy16  #control_block, DESTINATIONLO
        TAIL_CALL AUXMOVE, C=0  ; aux>main
.endproc ; FetchControlBlock

;;; ============================================================

.proc DoImport
        jmp     start

        DEFINE_CREATE_PARAMS create_params, path_buf, ACCESS_DEFAULT, SELF_MODIFIED_BYTE, SELF_MODIFIED
        DEFINE_OPEN_PARAMS open_params, path_buf, IO_BUF
        DEFINE_READWRITE_PARAMS write_params, RWTS_SECTOR_BUF, $100
        DEFINE_SET_EOF_PARAMS set_eof_params, SELF_MODIFIED
        DEFINE_CLOSE_PARAMS close_params
set_eof_flag:   .byte   0
tslist_offset:  .byte   0

PARAM_BLOCK muldiv_params, $10
number          .word           ; (in)
numerator       .word           ; (in)
denominator     .word           ; (in)
result          .word           ; (out)
remainder       .word           ; (out)
END_PARAM_BLOCK

start:
        jsr     FetchControlBlock

        ;; Fetch `CatalogEntry`
        copy8   control_block+ControlBlock::selected_index, muldiv_params::number
        copy8   #0, muldiv_params::number+1
        copy16  #.sizeof(aux::CatalogEntry), muldiv_params::numerator
        copy16  #1, muldiv_params::denominator
        JUMP_TABLE_MGTK_CALL MGTK::MulDiv, muldiv_params
        add16   muldiv_params::result, #aux::EntryBuffer, STARTLO
        add16   STARTLO, #.sizeof(aux::CatalogEntry)-1, ENDLO
        copy16  #entry_buf, DESTINATIONLO
        CALL    AUXMOVE, C=0    ; aux>main

        copy16  #0, control_block+ControlBlock::progress_num
        copy16  entry_buf+aux::CatalogEntry::Length, control_block+ControlBlock::progress_denom

        ;; --------------------------------------------------
        ;; Make the name ProDOS-friendly
        str_name := entry_buf + aux::CatalogEntry::Name

        ;; Truncate to 15 or less
        lda     str_name
    IF A >= #15
        lda     #15
    END_IF
        sta     str_name
        tax

        ;; Make uppercase or '.'
    DO
        lda     str_name,x
        jsr     ToUpperCase

        ;; Digit is fine
        jsr     IsDigit
      IF CS
        ;; Uppercase is fine
        jsr     IsUpperAlpha
       IF CS
        ;; Anything else becomes '.'
        lda     #'.'
        sta     str_name,x
       END_IF
      END_IF

    WHILE dex : NOT_ZERO

        ;; Can't start with non-alpha, replace with 'X'
        lda     str_name+1
    IF A < #'A'
        copy8   #'X', str_name+1
    END_IF

        ;; --------------------------------------------------

        ;; Construct full path

        lda     prefix_path
        clc
        adc     str_name
    IF A >= #kMaxPathLength     ; not +1 because we'll add '/'
        RETURN  A=#ERR_INVALID_PATHNAME
    END_IF

        COPY_STRING prefix_path, path_buf

        ldx     #0
        ldy     path_buf
        iny
        copy8   #'/', path_buf,y
    DO
        inx
        iny
        copy8   str_name,x, path_buf,y
    WHILE X <> str_name
        sty     path_buf

        ;; NOTE: Can't show alerts, as that will trash aux $E00...$1FFF

        ;; --------------------------------------------------

        ;; Load file's first Track/Sector List sector
        copy16  #TS_BUF, $06
        CALL    RWTSRead, A=entry_buf+aux::CatalogEntry::Track, X=entry_buf+aux::CatalogEntry::Sector, Y=control_block+ControlBlock::unit_num
        RTS_IF CS
        jsr     IncProgress

        ;; Load first file sector
        copy16  #RWTS_SECTOR_BUF, $06
        CALL    RWTSRead, A=TS_BUF+dos33::TSList::FirstDataT, X=TS_BUF+dos33::TSList::FirstDataS, Y=control_block+ControlBlock::unit_num
        RTS_IF CS
        jsr     IncProgress
        copy8   #dos33::TSList::FirstDataT+2, tslist_offset

        ;; Data offsets depend on type
        lda     entry_buf+aux::CatalogEntry::TypeFlags
        and     #$7F
        pha                     ; A = type

    IF A = #dos33::FileTypeBinary
        ;; Binary header:
        ;; +$00 WORD address (low/high)
        ;; +$02 WORD length (low/high)
        copy16  RWTS_SECTOR_BUF+0, create_params::aux_type
        SET_BIT7_FLAG set_eof_flag
        copy16  RWTS_SECTOR_BUF+2, set_eof_params::eof
        copy16  #RWTS_SECTOR_BUF+4, write_params::data_buffer
        copy16  #256-4, write_params::request_count
        jmp     translate_type
    END_IF

    IF A = #dos33::FileTypeApplesoft
        ;; Applesoft BASIC header:
        ;; +$00 WORD length (low/high)
        copy16  #$0801, create_params::aux_type
        copy16  RWTS_SECTOR_BUF+0, set_eof_params::eof
        SET_BIT7_FLAG set_eof_flag
        copy16  #RWTS_SECTOR_BUF+2, write_params::data_buffer
        copy16  #256-2, write_params::request_count
        jmp     translate_type
    END_IF

    IF A = #dos33::FileTypeInteger
        ;; Integer BASIC header:
        ;; +$00 WORD length (low/high)
        copy16  #$0000, create_params::aux_type
        copy16  RWTS_SECTOR_BUF+0, set_eof_params::eof
        SET_BIT7_FLAG set_eof_flag
        copy16  #RWTS_SECTOR_BUF+2, write_params::data_buffer
        copy16  #256-2, write_params::request_count
        jmp     translate_type
    END_IF

        copy16  #0, create_params::aux_type
        CLEAR_BIT7_FLAG set_eof_flag
        copy16  #RWTS_SECTOR_BUF, write_params::data_buffer
        copy16  #256, write_params::request_count
        FALL_THROUGH_TO translate_type

translate_type:
        ;; Set the type
        pla                     ; A = type
        jsr     clz
        copy8   prodos_type_table,x, create_params::file_type

        ;; Create target file
        JUMP_TABLE_MLI_CALL CREATE, create_params
        RTS_IF CS
        JUMP_TABLE_MLI_CALL OPEN, open_params
        RTS_IF CS
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     set_eof_params::ref_num
        sta     close_params::ref_num

        ;; --------------------------------------------------
        ;; Loop over sectors

write_sector:
        JUMP_TABLE_MLI_CALL WRITE, write_params
        ;; TODO: CLOSE on error
        RTS_IF CS

read_sector:
        ;; Read next sector
        ldy     tslist_offset
        beq     next_tslist_sector
        copy16  #RWTS_SECTOR_BUF, $06
        lda     TS_BUF+0,y      ; Track
        beq     finish
        ldx     TS_BUF+1,y      ; Sector
        CALL    RWTSRead, Y=control_block+ControlBlock::unit_num
        RTS_IF CS
        jsr     IncProgress
        inc     tslist_offset
        inc     tslist_offset

        ;; All remaining sectors are full data
        copy16  #RWTS_SECTOR_BUF, write_params::data_buffer
        copy16  #$100, write_params::request_count

        jmp     write_sector

        ;; --------------------------------------------------
        ;; Advance to file's next T/S List sector

next_tslist_sector:
        copy16  #TS_BUF, $06
        lda     TS_BUF+dos33::TSList::NextTrack
        beq     finish
        CALL    RWTSRead, X=TS_BUF+dos33::TSList::NextSector, Y=control_block+ControlBlock::unit_num
        RTS_IF CS
        jsr     IncProgress
        copy8   #dos33::TSList::FirstDataT, tslist_offset
        jmp     read_sector

        ;; --------------------------------------------------
        ;; Truncate to exact length (if known)

finish:
        copy16  control_block+ControlBlock::progress_denom, control_block+ControlBlock::progress_num
        jsr     SendControlBlock
        JSR_TO_AUX aux::Catalog::UpdateProgressMeter

    IF bit set_eof_flag : NS
        JUMP_TABLE_MLI_CALL SET_EOF, set_eof_params
    END_IF
        JUMP_TABLE_MLI_CALL CLOSE, close_params

        SET_BIT7_FLAG dirty_flag
        RETURN  A=#0            ; success

;;; C=1 if false
.proc IsUpperAlpha
        cmp     #'A'
        bcc     no
        cmp     #'Z'+1
        bcs     no
        rts

no:     RETURN  C=1
.endproc ; IsUpperAlpha

;;; C=1 if false
.proc IsDigit
        cmp     #'0'
        bcc     no
        cmp     #'9'+1
        bcs     no
        rts

no:     RETURN  C=1
.endproc ; IsDigit

;;; Count leading zeros
;;; Input: A = byte
;;; Output: X = leading zeros (0...8)
.proc clz
        ldx     #0
    DO
        lsr     a
        BREAK_IF CS
    WHILE inx : X <> #8
        rts
.endproc ; clz

.proc IncProgress
        inc16   control_block+ControlBlock::progress_num
        jsr     SendControlBlock
        JSR_TO_AUX aux::Catalog::UpdateProgressMeter
        rts
.endproc ; IncProgress

entry_buf:
        .tag    aux::CatalogEntry

path_buf:
        .res    ::kPathBufferSize, 0

;;; Index is CLZ of DOS 3.3 type
prodos_type_table:
        .byte   FT_INT          ; 'I'
        .byte   FT_BASIC        ; 'A'
        .byte   FT_BINARY       ; 'B'
        .byte   FT_TYPELESS     ; 'S'
        .byte   FT_REL          ; 'R'
        .byte   FT_TYPELESS     ; '1'
        .byte   FT_TYPELESS     ; '2'
        .byte   FT_TYPELESS     ; (unused)
        .byte   FT_TEXT         ; 'T'

.endproc ; DoImport

;;; ============================================================

dirty_flag:     .byte   0       ; bit7

prefix_path:    .res    ::kPathBufferSize, 0

.proc GetWinPath
        ptr := $06

        JUMP_TABLE_MGTK_CALL MGTK::FrontWindow, ptr
        lda     ptr             ; any window open?
        beq     fail
        cmp     #kMaxDeskTopWindows+1
        bcs     fail

        jsr     JUMP_TABLE_GET_WIN_PATH
        stax    ptr

        ldy     #0
        lda     (ptr),y
        tay
    DO
        copy8   (ptr),y, prefix_path,y
    WHILE dey : POS
        RETURN  A=#0

fail:   RETURN  A=#1

.endproc ; GetWinPath

;;; ============================================================

;;; Inspect boot block for DOS 3.3 signature
;;; Input: A = `unit_num`
;;; Output: Z=1 if DOS 3.3 disk, Z=0 otherwise
.proc IsDOS33Impl
        DEFINE_READWRITE_BLOCK_PARAMS read_block_params, RWTS_BLOCK_BUF, 0

start:
        sta     read_block_params::unit_num
        JUMP_TABLE_MLI_CALL READ_BLOCK, read_block_params
    IF ZERO
        lda     RWTS_BLOCK_BUF+1
        cmp     #$A5
      IF EQ
        lda     RWTS_BLOCK_BUF+2
        cmp     #$27
      END_IF
    END_IF
        rts
.endproc ; IsDOS33Impl
IsDOS33 := IsDOS33Impl::start

;;; ============================================================

;;; Input: A = Track, X = Sector, Y = unit_num, $06/$07 = 256-byte buffer
;;; Output: C=0 on success, C=1 on error
;;; Trashes: $08/$09
.scope RWTSImpl

;;; See ProDOS-8 Technical Reference Manual
;;; Appendix B.5 DOS 3.3 Disk Organization
;;; Block = (8 * Track) + Sector Offset
offset_table:   .byte   0, 7, 6, 6, 5, 5, 4, 4, 3, 3, 2, 2, 1, 1, 0, 7
half_table:     .byte   0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1

block_buf := RWTS_BLOCK_BUF

DEFINE_READWRITE_BLOCK_PARAMS block_params, block_buf, 0

.proc Read
        dst_ptr := $06
        src_ptr := $08

        jsr     ProcessParams

        lda     #<block_buf
        sta     src_ptr
        lda     #>block_buf
        adc     #0              ; C=1 if upper half
        sta     src_ptr+1

        ;; Read the whole block
        JUMP_TABLE_MLI_CALL READ_BLOCK, block_params
        RTS_IF CS

        ;; Copy sector data out from appropriate half
        ldy     #0
    DO
        copy8   (src_ptr),y, (dst_ptr),y
    WHILE dey : NOT_ZERO

        RETURN  C=0
.endproc ; Read

.proc Write
        src_ptr := $06
        dst_ptr := $08

        ;; TODO: Untested! Do not use until carefully verified
        brk

        jsr     ProcessParams

        lda     #<block_buf
        sta     dst_ptr
        lda     #>block_buf
        adc     #0              ; C=1 if upper half
        sta     dst_ptr+1

        ;; Read the whole block
        JUMP_TABLE_MLI_CALL READ_BLOCK, block_params
        RTS_IF CS

        ;; Copy sector data into place in appropriate half
        ldy     #0
    DO
        copy8   (src_ptr),y, (dst_ptr),y
    WHILE dey : NOT_ZERO

        ;; Write the updated block back out
        JUMP_TABLE_MLI_CALL WRITE_BLOCK, block_params
        rts
.endproc ; Write


.proc ProcessParams
        sty     block_params::unit_num

        ;; Calculate `block_num`/`half`
        ;; Block = (8 * Track) + Sector Offset
        pha
        lda     #0
        sta     block_params::block_num+1
        pla
        asl     a
        rol     block_params::block_num+1
        asl     a
        rol     block_params::block_num+1
        asl     a
        rol     block_params::block_num+1
        clc
        adc     offset_table,x
        sta     block_params::block_num
        bcc     :+
        inc     block_params::block_num+1
:
        lda     half_table,x
        ror     a               ; flag -> C
        rts
.endproc ; ProcessParams
.endscope ; RWTSImpl

;;; Exports
RWTSRead  := RWTSImpl::Read
RWTSWrite := RWTSImpl::Write

;;; ============================================================

        .include "../lib/is_diskii.s"
        .include "../lib/uppercase.s"

;;; ============================================================

.endscope ; main
        DA_END_MAIN_SEGMENT

;;; ============================================================
