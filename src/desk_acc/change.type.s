;;; ============================================================
;;; CHANGE.TYPE - Desk Accessory
;;;
;;; Shows the ProDOS type and auxtype of selected files, and lets the
;;; user edit either or both.
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "change.type.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../toolkits/btk.inc"
        .include "../toolkits/letk.inc"
        .include "../toolkits/icontk.inc"
        .include "../lib/alert_dialog.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================
;;; Window

        kDialogWidth = 287
        kDialogHeight = 75

        kDAWindowId = $80

.params closewindow_params
window_id:     .byte   kDAWindowId
.endparams

.params winfo
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
mincontwidth:   .word   100
mincontheight:  .word   100
maxcontwidth:   .word   500
maxcontheight:  .word   500
port:
        DEFINE_POINT viewloc, (kScreenWidth-kDialogWidth)/2, (kScreenHeight-kDialogHeight)/2
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDialogWidth, kDialogHeight
pattern:        .res    8,$FF
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

pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY
        DEFINE_RECT_FRAME frame_rect, kDialogWidth, kDialogHeight

;;; ============================================================
;;; Buttons

        kControlMarginX = 16

        kOKButtonLeft = kDialogWidth - kButtonWidth - kControlMarginX
        kCancelButtonLeft = kControlMarginX
        kButtonTop = kDialogHeight - kButtonHeight - 7

        DEFINE_BUTTON ok_button, kDAWindowId, res_string_button_ok, kGlyphReturn, kOKButtonLeft, kButtonTop
        DEFINE_BUTTON cancel_button, kDAWindowId, res_string_button_cancel, res_string_button_cancel_shortcut, kCancelButtonLeft, kButtonTop

;;; ============================================================
;;; Line Edits

auxtype_focused_flag:
        .byte   0

str_type:
        PASCAL_STRING "00"
str_auxtype:
        PASCAL_STRING "0000"

        kTextBoxLeft = 145
        kTextBoxWidth = 40
        kTypeY = 18
        kAuxtypeY = 35

        DEFINE_LINE_EDIT type_line_edit_rec, kDAWindowId, str_type, kTextBoxLeft, kTypeY, kTextBoxWidth, 2
        DEFINE_LINE_EDIT_PARAMS type_le_params, type_line_edit_rec
        DEFINE_RECT_SZ type_rect, kTextBoxLeft, kTypeY, kTextBoxWidth, kTextBoxHeight

        DEFINE_LINE_EDIT auxtype_line_edit_rec, kDAWindowId, str_auxtype, kTextBoxLeft, kAuxtypeY, kTextBoxWidth, 4
        DEFINE_LINE_EDIT_PARAMS auxtype_le_params, auxtype_line_edit_rec
        DEFINE_RECT_SZ auxtype_rect, kTextBoxLeft, kAuxtypeY, kTextBoxWidth, kTextBoxHeight

        DEFINE_LABEL type, res_string_label_type, kTextBoxLeft-2, kTypeY+kSystemFontHeight+1
        DEFINE_LABEL auxtype, res_string_label_auxtype, kTextBoxLeft-2, kAuxtypeY+kSystemFontHeight+1

;;; ============================================================
;;; Alerts

.params AlertNoFilesSelected
        .addr   str_err_no_files_selected
        .byte   AlertButtonOptions::OK
        .byte   AlertOptions::Beep | AlertOptions::SaveBack
.endparams
str_err_no_files_selected:
        PASCAL_STRING res_string_err_no_files_selected

.params AlertDirectoriesNotOK
        .addr   str_err_directories_not_ok
        .byte   AlertButtonOptions::OK
        .byte   AlertOptions::Beep | AlertOptions::SaveBack
.endparams
str_err_directories_not_ok:
        PASCAL_STRING res_string_err_directories_not_supported

;;; ============================================================

        .include "../lib/event_params.s"

;;; ============================================================

;;; Copied from/to main
.params data
type_valid:     .byte   0
type:           .byte   SELF_MODIFIED_BYTE

auxtype_valid:  .byte   0
auxtype:        .word   SELF_MODIFIED
.endparams

;;; ============================================================

.proc RunDA

    IF bit data::type_valid : NC
        copy8   #0, str_type
    ELSE
        copy8   #2, str_type
        CALL    GetDigits, A=data::type
        sta     str_type+1
        stx     str_type+2
    END_IF


    IF bit data::auxtype_valid : NC
        copy8   #0, str_auxtype
    ELSE
        copy8   #4, str_auxtype
        CALL    GetDigits, A=data::auxtype+1
        sta     str_auxtype+1
        stx     str_auxtype+2
        CALL    GetDigits, A=data::auxtype
        sta     str_auxtype+3
        stx     str_auxtype+4
    END_IF

        MGTK_CALL MGTK::OpenWindow, winfo
        MGTK_CALL MGTK::HideCursor

        LETK_CALL LETK::Init, type_le_params
        LETK_CALL LETK::Init, auxtype_le_params

        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents

        LETK_CALL LETK::Activate, type_le_params
        MGTK_CALL MGTK::ShowCursor

        FALL_THROUGH_TO InputLoop
.endproc ; RunDA

;;; ============================================================
;;; Input loop

.proc InputLoop

    IF bit auxtype_focused_flag : NC
        LETK_CALL LETK::Idle, type_le_params
    ELSE
        LETK_CALL LETK::Idle, auxtype_le_params
    END_IF

        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        jsr     GetNextEvent

        cmp     #kEventKindMouseMoved
        jeq     HandleMouseMoved

        cmp     #MGTK::EventKind::button_down
        jeq     HandleButtonDown

        cmp     #MGTK::EventKind::key_down
        jeq     HandleKeyDown

        jmp     InputLoop
.endproc ; InputLoop

;;; ==================================================

.proc HandleMouseMoved
        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        MGTK_CALL MGTK::InRect, type_rect
    IF NOT_ZERO
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::ibeam
        jmp     InputLoop
    END_IF

        MGTK_CALL MGTK::InRect, auxtype_rect
    IF NOT_ZERO
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::ibeam
        jmp     InputLoop
    END_IF

        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        jmp     InputLoop
.endproc ; HandleMouseMoved

;;; ============================================================

.proc HandleButtonDown
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     #kDAWindowId
        jne     InputLoop

        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        MGTK_CALL MGTK::InRect, ok_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, ok_button
        jpl     ExitOK
        jmp     InputLoop
    END_IF

        MGTK_CALL MGTK::InRect, cancel_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, cancel_button
        jpl     ExitCancel
        jmp     InputLoop
    END_IF

        MGTK_CALL MGTK::InRect, type_rect
    IF NOT_ZERO
        jsr     FocusType
        COPY_STRUCT screentowindow_params::window, type_le_params::coords
        LETK_CALL LETK::Click, type_le_params
        jmp     InputLoop
    END_IF

        MGTK_CALL MGTK::InRect, auxtype_rect
    IF NOT_ZERO
        jsr     FocusAuxtype
        COPY_STRUCT screentowindow_params::window, auxtype_le_params::coords
        LETK_CALL LETK::Click, auxtype_le_params
        jmp     InputLoop
    END_IF

        jmp     InputLoop
.endproc ; HandleButtonDown

;;; ============================================================

.proc HandleKeyDown
        lda     event_params::key

        ldx     event_params::modifiers
    IF NOT_ZERO
        jsr     ToUpperCase
        cmp     #kShortcutCloseWindow
        jeq     ExitCancel

        jmp     InputLoop
    END_IF

    IF A = #CHAR_ESCAPE
        BTK_CALL BTK::Flash, cancel_button
        jmp     ExitCancel
    END_IF

    IF A = #CHAR_RETURN
        BTK_CALL BTK::Flash, ok_button
        jmp     ExitOK
    END_IF

    IF A = #CHAR_TAB

      IF bit auxtype_focused_flag : NC
        jsr     FocusAuxtype
      ELSE
        jsr     FocusType
      END_IF
        jmp     InputLoop
    END_IF

        jsr     IsControlChar
    IF CS
        jsr     IsHexChar
      IF CS
        jmp     InputLoop
      END_IF
    END_IF


    IF bit auxtype_focused_flag : NC
        sta     type_le_params::key
        copy8   event_params::modifiers, type_le_params::modifiers
        LETK_CALL LETK::Key, type_le_params
    ELSE
        sta     auxtype_le_params::key
        copy8   event_params::modifiers, auxtype_le_params::modifiers
        LETK_CALL LETK::Key, auxtype_le_params
    END_IF

        jmp     InputLoop

;;; Input: A=character
;;; Output: C=0 if control, C=1 if not
.proc IsControlChar
        cmp     #CHAR_DELETE
        bcs     yes

        cmp     #' '
        rts                     ; C=0 (if less) or 1

yes:    RETURN  C=0
.endproc ; IsControlChar

;;; Input: A=character
;;; Output: C=0 if valid hex character, C=1 otherwise
.proc IsHexChar
        jsr     ToUpperCase

        cmp     #'0'
        bcc     no
        cmp     #'9'+1
        bcc     yes

        cmp     #'A'
        bcc     no
        cmp     #'F'+1
        bcc     yes

no:     RETURN  C=1

yes:    RETURN  C=0
.endproc ; IsHexChar
.endproc ; HandleKeyDown

;;; ============================================================

;;; No-op if type already focused
.proc FocusType
    IF bit auxtype_focused_flag : NS
        LETK_CALL LETK::Deactivate, auxtype_le_params
        LETK_CALL LETK::Activate, type_le_params
        CLEAR_BIT7_FLAG auxtype_focused_flag
    END_IF
        rts
.endproc ; FocusType

;;; No-op if auxtype already focused
.proc FocusAuxtype
    IF bit auxtype_focused_flag : NC
        LETK_CALL LETK::Deactivate, type_le_params
        LETK_CALL LETK::Activate, auxtype_le_params
        SET_BIT7_FLAG auxtype_focused_flag
    END_IF
        rts
.endproc ; FocusAuxtype

;;; ============================================================

.proc PadType
    DO
        lda     str_type
        BREAK_IF A = #2
        copy8   str_type+1, str_type+2
        copy8   #'0', str_type+1
        inc     str_type
    WHILE NOT_ZERO              ; always
        rts
.endproc ; PadType

.proc PadAuxtype
    DO
        lda     str_auxtype
        BREAK_IF A = #4
        copy8   str_auxtype+3, str_auxtype+4
        copy8   str_auxtype+2, str_auxtype+3
        copy8   str_auxtype+1, str_auxtype+2
        copy8   #'0', str_auxtype+1
        inc     str_auxtype
    WHILE NOT_ZERO              ; always
        rts
.endproc ; PadAuxtype

;;; ============================================================

.proc ExitOK
        lda     #$80
        bne     Exit            ; always
.endproc ; ExitOK

.proc ExitCancel
        lda     #0
        FALL_THROUGH_TO Exit
.endproc ; ExitCancel

.proc Exit
        pha
        MGTK_CALL MGTK::CloseWindow, closewindow_params
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES

        lda     str_type
    IF ZERO
        CLEAR_BIT7_FLAG data::type_valid
    ELSE
        SET_BIT7_FLAG data::type_valid
        jsr     PadType
        CALL    DigitsToByte, A=str_type+1, X=str_type+2
        sta     data::type
    END_IF

        lda     str_auxtype
    IF ZERO
        CLEAR_BIT7_FLAG data::auxtype_valid
    ELSE
        SET_BIT7_FLAG data::auxtype_valid
        jsr     PadAuxtype
        CALL    DigitsToByte, A=str_auxtype+1, X=str_auxtype+2
        sta     data::auxtype+1
        CALL    DigitsToByte, A=str_auxtype+3, X=str_auxtype+4
        sta     data::auxtype
    END_IF

        pla
        rts

;;; Input: A = ASCII digit
;;; Output A = value in low nibble
.proc DigitToNibble
    IF A < #'9'+1
        and     #%00001111
        rts
    END_IF

        sec
        sbc     #('A' - 10)
        rts
.endproc ; DigitToNibble

;;; Inputs: A,X = ASCII digits (first, second)
;;; Output: A = byte
.proc DigitsToByte
        jsr     DigitToNibble
        asl
        asl
        asl
        asl
        sta     mod
        txa
        jsr     DigitToNibble
        mod := *+1
        ora     #SELF_MODIFIED_BYTE
        rts
.endproc ; DigitsToByte

.endproc ; Exit

;;; ============================================================
;;; Render the window contents

.proc DrawWindow
        MGTK_CALL MGTK::SetPort, winfo::port

        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        MGTK_CALL MGTK::MoveTo, type_label_pos
        CALL    DrawStringRight, AX=#type_label_str

        MGTK_CALL MGTK::MoveTo, auxtype_label_pos
        CALL    DrawStringRight, AX=#auxtype_label_str

        MGTK_CALL MGTK::FrameRect, type_rect
        MGTK_CALL MGTK::FrameRect, auxtype_rect

        BTK_CALL BTK::Draw, ok_button
        BTK_CALL BTK::Draw, cancel_button

        rts
.endproc ; DrawWindow

;;; ============================================================

;;; Input: A = value
;;; Output: A,X = high/low nibbles as ASCII digits
.proc GetDigits
        tay

        lsr                     ; high nibble
        lsr
        lsr
        lsr
        tax
        lda     digits,x
        pha

        tya

        and     #$0F            ; low nibble
        tax
        lda     digits,x
        tax                     ; X = low digit

        pla                     ; A = high digit
        rts

digits: .byte   "0123456789ABCDEF"
.endproc ; GetDigits

;;; ============================================================

.proc DrawStringRight
        params := $06
        str := params
        width := params+2

        stax    str
        stax    @addr
        MGTK_CALL MGTK::StringWidth, params
        sub16   #0, width, params+MGTK::Point::xcoord
        copy16  #0, params+MGTK::Point::ycoord
        MGTK_CALL MGTK::Move, params
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        rts
.endproc ; DrawStringRight

;;; ============================================================

        .include "../lib/uppercase.s"
        .include "../lib/get_next_event.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
        jmp     Main

;;; ============================================================

;;; Copied to/from aux
.params data
type_valid:     .byte   0       ; bit7
type:           .byte   SELF_MODIFIED_BYTE

auxtype_valid:  .byte   0       ; bit7
auxtype:        .word   SELF_MODIFIED
.endparams
.assert .sizeof(data) = .sizeof(aux::data), error, "size mismatch"

;;; ============================================================

saved_stack:
        .byte   0

.proc Main
        tsx
        stx     saved_stack

        jsr     JUMP_TABLE_GET_SEL_WIN
    IF ZERO
        TAIL_CALL JUMP_TABLE_SHOW_ALERT_PARAMS, AX=#aux::AlertNoFilesSelected
    END_IF

        jsr     JUMP_TABLE_GET_SEL_COUNT
    IF ZERO
        TAIL_CALL JUMP_TABLE_SHOW_ALERT_PARAMS, AX=#aux::AlertNoFilesSelected
    END_IF

        jsr     GetTypes

        copy16  #data, STARTLO
        copy16  #data+.sizeof(data)-1, ENDLO
        copy16  #aux::data, DESTINATIONLO
        CALL    AUXMOVE, C=1    ; main>aux

        JSR_TO_AUX aux::RunDA
        RTS_IF NC               ; cancel

        copy16  #aux::data, STARTLO
        copy16  #aux::data+.sizeof(data)-1, ENDLO
        copy16  #data, DESTINATIONLO
        CALL    AUXMOVE, C=0    ; aux>main

        jsr     ApplyTypes

        jsr     JUMP_TABLE_GET_SEL_WIN
        jmp     JUMP_TABLE_ACTIVATE_WINDOW
.endproc ; Main

.proc Abort
        ldx     saved_stack
        txs
        rts
.endproc ; Abort

;;; ============================================================


path:           .res    ::kPathBufferSize

        DEFINE_GET_FILE_INFO_PARAMS gfi_params, path

;;; Assert: at least one file selected
.proc GetTypes
        copy16  #callback, IterationCallback
        jsr     IterateSelectedFiles
        rts

callback:
        pha                     ; A = index
        jsr     GetFileInfo
        pla
    IF ZERO
        ;; First - use this type/auxtype
        copy8   gfi_params::file_type, data::type
        copy16  gfi_params::aux_type, data::auxtype
        lda     #$80
        sta     data::type_valid
        sta     data::auxtype_valid
    ELSE
        ;; Rest - determine if same type/auxtype
        lda     gfi_params::file_type
      IF A <> data::type
        CLEAR_BIT7_FLAG data::type_valid
      END_IF

        ecmp16  gfi_params::aux_type, data::auxtype
      IF NE
        CLEAR_BIT7_FLAG data::auxtype_valid
      END_IF

    END_IF
        rts
.endproc ; GetTypes

;;; Assert: at least one file selected
.proc ApplyTypes
        lda     data::type_valid
        ora     data::auxtype_valid
        RTS_IF NC

        copy16  #callback, IterationCallback
        jsr     IterateSelectedFiles
        rts

callback:
        jsr     GetFileInfo
        RTS_IF NOT_ZERO

    IF bit data::type_valid : NS
        ;; Disallow changing type to/from directory
        lda     data::type
        cmp     gfi_params::file_type
      IF NE
        ;; type change - either one dir?
        lda     data::type
       IF A = #FT_DIRECTORY
        jsr     ShowDirError
        jmp     skip
       END_IF

        lda     gfi_params::file_type
       IF A = #FT_DIRECTORY
        jsr     ShowDirError
        jmp     skip
       END_IF
      END_IF

        copy8   data::type, gfi_params::file_type
    END_IF
skip:

    IF bit data::auxtype_valid : NS
        copy16  data::auxtype, gfi_params::aux_type
    END_IF

        jmp     SetFileInfo
.endproc ; ApplyTypes

IterationCallback:
        .word   SELF_MODIFIED

.proc IterateSelectedFiles
        copy8   #0, index
        ptr := $06

        ;; Get win path
        jsr     JUMP_TABLE_GET_SEL_WIN
        jsr     JUMP_TABLE_GET_WIN_PATH
        stax    ptr
        ldy     #0
        lda     (ptr),y
        tay
    DO
        copy8   (ptr),y, path,y
    WHILE dey : POS

    DO
        lda     path
        pha

        ;; Get icon ptr
        CALL    JUMP_TABLE_GET_SEL_ICON, A=index
        addax   #IconEntry::name, ptr

        ;; Compose path
        ldx     path
        inx
        copy8   #'/', path,x
        ldy     #0
        copy8   (ptr),y, len
      DO
        iny
        inx
        copy8   (ptr),y, path,x
        len := *+1
        cpy     #SELF_MODIFIED_BYTE
      WHILE NE
        stx     path

        ;; Execute callback
        CALL    do_callback, A=index

        ;; Next
        pla
        sta     path

        inc     index
        jsr     JUMP_TABLE_GET_SEL_COUNT
    WHILE A <> index

        rts

do_callback:
        jmp     (IterationCallback)

index:  .byte   0
.endproc ; IterateSelectedFiles

.proc GetFileInfo
        copy8   #$A, gfi_params::param_count ; GET_FILE_INFO
        JUMP_TABLE_MLI_CALL GET_FILE_INFO, gfi_params
        jcs     Abort
        rts
.endproc ; GetFileInfo

.proc SetFileInfo
        copy8   #7, gfi_params::param_count ; SET_FILE_INFO
        JUMP_TABLE_MLI_CALL SET_FILE_INFO, gfi_params
        jcs     Abort
        rts
.endproc ; SetFileInfo

;;; ============================================================

.proc ShowDirError
    IF bit flag : NC
        CALL    JUMP_TABLE_SHOW_ALERT_PARAMS, AX=#aux::AlertDirectoriesNotOK
        SET_BIT7_FLAG flag
    END_IF
        rts

flag:   .byte   0
.endproc ; ShowDirError

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
