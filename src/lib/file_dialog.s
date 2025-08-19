;;; ============================================================
;;; Common File Picker Dialog
;;;
;;; Required includes:
;;; * lib/adjustfilecase.s
;;; * lib/doubleclick.s
;;; * lib/event_params.s
;;; * lib/file_dialog_res.s
;;; * lib/get_next_event.s
;;;
;;; Requires these macros to be functional:
;;; * `MLI_CALL`
;;; * `MGTK_CALL`
;;; * `BTK_CALL`
;;;
;;; Requires the following proc definitions:
;;; * `SystemTask`
;;;
;;; If `FD_EXTENDED` is defined:
;;; * name field at bottom and extra clickable controls on right are supported
;;; * `LETK_CALL` is required

;;; ============================================================
;;; Memory map
;;;
;;;              Main
;;;          :           :
;;;          |           |
;;;          | DHR       |
;;;  $2000   +-----------+
;;;          |           |
;;;          |           |
;;;          |           |
;;;          |           |
;;;          | filenames | 128 x 16-byte filenames
;;;  $1800   +-----------+
;;;          | index     | position in list to filename
;;;  $1780   +-----------+
;;;          | (unused)  |
;;;  $1661   +-----------+
;;;          | path buf  |
;;;  $1620   +-----------+
;;;          | online buf|
;;;  $1610   +-----------+
;;;          | typedown  |
;;;  $1600   +-----------+
;;;          |           |
;;;          | dir buf   | current directory block
;;;  $1400   +-----------+
;;;          |           |
;;;          |           |
;;;          |           |
;;;          | IO Buffer | for reading directory
;;;  $1000   +-----------+
;;;          |           |
;;;          |           |
;;;          |           |
;;;          |           |
;;;          | (unused)  |
;;;   $800   +-----------+
;;;          |           |
;;;          :           :
;;;
;;; ============================================================

.scope file_dialog_impl

;;; Clients that do fancy things like show alerts without tearing down
;;; the dialog may overwrite the file dialog's state. By exporting
;;; where the state lives, clients can save/restore it as necessary
state_start     := $1600
state_end       := $1FFF

;;; Buffer used when selecting filename by holding Apple key and typing name.
;;; Length-prefixed string, initialized to 0 when the dialog is shown.
type_down_buf   := $1600        ; 16 bytes
on_line_buffer  := $1610        ; 16 bytes for ON_LINE calls
path_buf        := $1620        ; 65 bytes for path+length

;;; Map from index in file_names to list entry; high bit is
;;; set for directories.
file_list_index := $1780

;;; Sequence of 16-byte records, filenames in current directory.
file_names      := $1800

;;; ============================================================

        DEFINE_ON_LINE_PARAMS on_line_params, 0, on_line_buffer

        io_buf := $1000
        dir_read_buf := $1400
        kDirReadSize = $200

        DEFINE_OPEN_PARAMS open_params, path_buf, io_buf
        DEFINE_READ_PARAMS read_params, dir_read_buf, kDirReadSize
        DEFINE_CLOSE_PARAMS close_params

only_show_dirs_flag:            ; set when selecting copy destination
        .byte   0

;;; bit7 = 0 = no selection required
;;;   bit6 = 0 = no root
;;;   bit6 = 1 = root ok -- NOT USED
;;; bit7 = 1 = selection required
;;;   bit6 = 0 = no dirs
;;;   bit6 = 1 = dirs ok
selection_requirement_flags:
        .byte   0

;;; ============================================================

.proc Init
        jsr     _SetCursorPointer

        lda     #0
        sta     type_down_buf
        sta     only_show_dirs_flag
.ifdef FD_EXTENDED
        sta     cursor_ibeam_flag
        sta     extra_controls_flag
.endif

        copy8   #$FF, selected_index

        lda     #BTK::kButtonStateNormal
        sta     file_dialog_res::open_button::state
        sta     file_dialog_res::close_button::state
        sta     file_dialog_res::drives_button::state

        rts
.endproc ; Init

;;; ============================================================
;;; Flags set by invoker to alter behavior

.ifdef FD_EXTENDED
;;; Set when `click_handler_hook` should be called and name input present.
extra_controls_flag:
        .byte   0

;;; These vectors get patched by overlays that add controls.
click_handler_hook:
        .addr   NoOp
key_handler_hook:
        .addr   NoOp
.endif

;;; ============================================================

.proc EventLoop
.ifdef FD_EXTENDED
        bit     extra_controls_flag
    IF_NS
        LETK_CALL LETK::Idle, file_dialog_res::le_params
    END_IF
.endif
        jsr     SystemTask
        jsr     GetNextEvent

        cmp     #MGTK::EventKind::key_down
    IF_EQ
        jsr     _HandleKeyEvent
        jmp     EventLoop
    END_IF

        cmp     #MGTK::EventKind::button_down
    IF_EQ
        ldx     #0              ; Clear type-down
        stx     type_down_buf
        jsr     _HandleButtonDown
        jmp     EventLoop
    END_IF

        cmp     #kEventKindMouseMoved
    IF_EQ
        ldx     #0              ; Clear type-down
        stx     type_down_buf
.ifdef FD_EXTENDED
        bit     extra_controls_flag
      IF_NS
        jsr     _MoveToWindowCoords
        MGTK_CALL MGTK::InRect, file_dialog_res::line_edit_rect
        ASSERT_EQUALS MGTK::inrect_outside, 0
        beq     out
        jsr     _SetCursorIBeam
        jmp     EventLoop
out:    jsr     _UnsetCursorIBeam
        ;; Fall through to JMP
      END_IF
.endif
    END_IF

        jmp     EventLoop
.endproc ; EventLoop

;;; ============================================================

.proc _MoveToWindowCoords
        lda     #file_dialog_res::kFilePickerDlgWindowID
        sta     screentowindow_params+MGTK::ScreenToWindowParams::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params+MGTK::ScreenToWindowParams::window
        rts
.endproc ; _MoveToWindowCoords

;;; ============================================================

.proc _HandleButtonDown
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params+MGTK::FindWindowParams::which_area
        cmp     #MGTK::Area::content
        beq     :+
ret:    rts
:
        lda     findwindow_params+MGTK::FindWindowParams::window_id
        cmp     #file_dialog_res::kFilePickerDlgWindowID
        beq     not_list
        COPY_STRUCT MGTK::Point, event_params+MGTK::Event::coords, file_dialog_res::lb_params::coords
        LBTK_CALL LBTK::Click, file_dialog_res::lb_params
        bmi     ret
        jsr     DetectDoubleClick
        bmi     ret
        ldx     selected_index
        lda     file_list_index,x
    IF_NC
        ;; File - accept it.
        BTK_CALL BTK::Flash, file_dialog_res::ok_button
        jmp     HandleOK
    END_IF
        ;; Folder - open it.
        BTK_CALL BTK::Flash, file_dialog_res::open_button
        jmp     _DoOpen

not_list:
        jsr     _MoveToWindowCoords

        ;; --------------------------------------------------
        ;; Drives button

        MGTK_CALL MGTK::InRect, file_dialog_res::drives_button::rect
    IF_NOT_ZERO
        BTK_CALL BTK::Track, file_dialog_res::drives_button
        bmi     :+
        jsr     _DoDrives
:       rts
    END_IF

        ;; --------------------------------------------------
        ;; Open button

        MGTK_CALL MGTK::InRect, file_dialog_res::open_button::rect
    IF_NOT_ZERO
        BTK_CALL BTK::Track, file_dialog_res::open_button
        bmi     :+
        jsr     _DoOpen
:       rts
    END_IF

        ;; --------------------------------------------------
        ;; Close button

        MGTK_CALL MGTK::InRect, file_dialog_res::close_button::rect
    IF_NOT_ZERO
        BTK_CALL BTK::Track, file_dialog_res::close_button
        bmi     :+
        jsr     _DoClose
:       rts
    END_IF

        ;; --------------------------------------------------
        ;; OK button

        MGTK_CALL MGTK::InRect, file_dialog_res::ok_button::rect
    IF_NOT_ZERO
        BTK_CALL BTK::Track, file_dialog_res::ok_button
        bmi     :+
        jsr     HandleOK
:       rts
    END_IF

        ;; --------------------------------------------------
        ;; Cancel button

        MGTK_CALL MGTK::InRect, file_dialog_res::cancel_button::rect
    IF_NOT_ZERO
        BTK_CALL BTK::Track, file_dialog_res::cancel_button
        bmi     :+
        jsr     HandleCancel
:       rts
    END_IF


        ;; --------------------------------------------------
        ;; Extra controls
.ifdef FD_EXTENDED
        bit     extra_controls_flag
    IF_NS
        ;; Text Edit
        MGTK_CALL MGTK::InRect, file_dialog_res::line_edit_rect
      IF_NOT_ZERO
        COPY_STRUCT MGTK::Point, screentowindow_params+MGTK::ScreenToWindowParams::window, file_dialog_res::le_params::coords
        LETK_CALL LETK::Click, file_dialog_res::le_params
        rts
      END_IF

        ;; Additional controls
        jmp     (click_handler_hook)
    END_IF
.endif

        rts
.endproc ; _HandleButtonDown

;;; ============================================================
;;; Refresh the list view from the current path
;;; Clears selection.

.proc UpdateListFromPath
        jsr     _ReadDir
        jsr     _UpdateDiskAndDirNames
        copy8   #$FF, selected_index
        LBTK_CALL LBTK::Init, file_dialog_res::lb_params
        jmp     _UpdateDynamicButtons
.endproc ; UpdateListFromPath

;;; As above, but select filename passed in A,X
.ifdef FD_EXTENDED
.proc UpdateListFromPathAndSelectFile
        pha
        txa
        pha

        jsr     _ReadDir
        jsr     _UpdateDiskAndDirNames

        pla
        tax
        pla
        jsr     _FindFilenameIndex
        sta     selected_index

        LBTK_CALL LBTK::Init, file_dialog_res::lb_params
        jmp     _UpdateDynamicButtons
.endproc ; UpdateListFromPathAndSelectFile
.endif

;;; ============================================================

.ifdef FD_EXTENDED
.proc _SetCursorIBeam
        bit     cursor_ibeam_flag
        bmi     :+
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::ibeam
        copy8   #$80, cursor_ibeam_flag
:       rts
.endproc ; _SetCursorIBeam

.proc _UnsetCursorIBeam
        bit     cursor_ibeam_flag
        bpl     :+
        jsr     _SetCursorPointer
        copy8   #0, cursor_ibeam_flag
:       rts
.endproc ; _UnsetCursorIBeam

cursor_ibeam_flag:              ; high bit set when cursor is I-beam
        .byte   0
.endif

;;; ============================================================

.proc _SetCursorPointer
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        rts
.endproc ; _SetCursorPointer

;;; ============================================================
;;; Get the current path, including the selection (if any)

;;; Inputs: A,X = buffer to copy path into
.proc GetPath
        stax    ptr

        ;; Any selection?
        bit     selected_index
    IF_NC
        ;; Append filename temporarily
        jsr     _AppendSelectedFilename
    END_IF

        ldy     path_buf
:       lda     path_buf,y
        ptr := *+1
        sta     SELF_MODIFIED,y
        dey
        bpl     :-

        bit     selected_index
    IF_NC
        jsr     _StripPathBufSegment
    END_IF

        rts
.endproc ; GetPath

;;; ============================================================

.proc _DoOpen
        jsr     _AppendSelectedFilename
        jmp     UpdateListFromPath
.endproc ; _DoOpen

;;; ============================================================

.proc _DoDrives
        jsr     _SetRootPath
        jmp     UpdateListFromPath
.endproc ; _DoDrives

;;; ============================================================
;;; Set `path_buf` to "/"

.proc _SetRootPath
        copy8   #1, path_buf
        copy8   #'/', path_buf+1
        rts
.endproc ; _SetRootPath

;;; ============================================================

;;; Output: Z=1 if path is just '/'
;;; Trashes: A

.proc _IsRootPath
        lda     path_buf
        cmp     #1
        rts
.endproc ; _IsRootPath

;;; ============================================================

;;; Output: C=0 if allowed, C=1 if not.
.proc _IsOpenAllowed
        lda     selected_index
        bmi     no              ; no selection
        tax
        lda     file_list_index,x
        bpl     no              ; not a folder

yes:    clc
        rts

no:     sec
        rts
.endproc ; _IsOpenAllowed

;;; ============================================================

;;; Output: C=0 if allowed, C=1 if not.
.proc _IsCloseAllowed
        jsr     _IsRootPath
        beq     _IsOpenAllowed::no

        clc
        rts
.endproc ; _IsCloseAllowed

;;; ============================================================

;;; Output: C=0 if allowed, C=1 if not.
.proc _IsOKAllowed
        allowed     := _IsOpenAllowed::yes
        not_allowed := _IsOpenAllowed::no

        .assert kSelectionOptional           & $80 = $00, error, "enum mismatch"
        .assert kSelectionOptionalUnlessRoot & $80 = $00, error, "enum mismatch"
        .assert kSelectionRequiredNoDirs     & $80 = $80, error, "enum mismatch"
        .assert kSelectionRequiredDirsOK     & $80 = $80, error, "enum mismatch"

        bit     selection_requirement_flags
    IF_NS
        ;; Selection required
        bit     selected_index
        bmi     _IsOpenAllowed::no ; no selection

        .assert kSelectionRequiredNoDirs & $40 = $00, error, "enum mismatch"
        .assert kSelectionRequiredDirsOK & $40 = $40, error, "enum mismatch"

        ;; bit6 = dirs ok?
        bit     selection_requirement_flags
        bvs     allowed         ; dirs ok
        jsr     _IsOpenAllowed  ; C=0 if open allowed
        bcc     not_allowed     ; but we want the inverse
        bcs     allowed         ; always
    END_IF

        ;; No selection required
        .assert kSelectionOptional           & $40 = $00, error, "enum mismatch"
        .assert kSelectionOptionalUnlessRoot & $40 = $40, error, "enum mismatch"

        ;; bit6 = root w/ no selection ok?
        bvc     allowed

        ;; selection required if not root
        bit     selected_index
        bmi     _IsCloseAllowed ; no selection, so only if not root
        bpl     allowed         ; always
.endproc ; _IsOKAllowed

;;; ============================================================

.proc _DoClose
        jsr     _IsCloseAllowed
        bcs     ret

        ;; Remove last segment
        jsr     _StripPathBufSegment

        lda     path_buf
        bne     :+
        jsr     _SetRootPath
:

        jsr     UpdateListFromPath

ret:    rts
.endproc ; _DoClose

;;; ============================================================
;;; Key handler

.proc _HandleKeyEvent
        lda     event_params+MGTK::Event::key
        ldx     event_params+MGTK::Event::modifiers
        sta     file_dialog_res::lb_params::key
        stx     file_dialog_res::lb_params::modifiers

        cmp     #CHAR_UP
        beq     :+
        cmp     #CHAR_DOWN
:
    IF_EQ
        copy8   #0, type_down_buf
        LBTK_CALL LBTK::Key, file_dialog_res::lb_params
        rts
    END_IF

        cpx     #0
    IF_NE
        ;; With modifiers
        jsr     _CheckTypeDown
        jeq     exit

        copy8   #0, type_down_buf
        ldx     event_params+MGTK::Event::modifiers
        lda     event_params+MGTK::Event::key

.ifdef FD_EXTENDED
        bit     extra_controls_flag
      IF_NS
        ;; Hook for clients
        cmp     #'0'
        bcc     :+
        cmp     #'9'+1
        bcs     :+
        jmp     (key_handler_hook)
:
      END_IF
.endif

    ELSE
        ;; --------------------------------------------------
        ;; No modifiers

.ifndef FD_EXTENDED
        jsr     _CheckTypeDown
        jeq     exit
.else
        bit     extra_controls_flag
      IF_NC
        jsr     _CheckTypeDown
        jeq     exit
      END_IF
.endif

        copy8   #0, type_down_buf
        lda     event_params+MGTK::Event::key

        cmp     #CHAR_RETURN
      IF_EQ
        jsr     _IsOKAllowed
        RTS_IF_CS

        BTK_CALL BTK::Flash, file_dialog_res::ok_button
        jmp     HandleOK
      END_IF

        cmp     #CHAR_ESCAPE
      IF_EQ
        BTK_CALL BTK::Flash, file_dialog_res::cancel_button
        jmp     HandleCancel
      END_IF

        cmp     #CHAR_CTRL_O
      IF_EQ
        jsr     _IsOpenAllowed
        RTS_IF_CS

        BTK_CALL BTK::Flash, file_dialog_res::open_button
        jmp     _DoOpen
      END_IF

        cmp     #CHAR_CTRL_D
      IF_EQ
        BTK_CALL BTK::Flash, file_dialog_res::drives_button
        jmp     _DoDrives
      END_IF

        cmp     #CHAR_CTRL_C
      IF_EQ
        jsr     _IsCloseAllowed
        RTS_IF_CS

        BTK_CALL BTK::Flash, file_dialog_res::close_button
        jmp     _DoClose
      END_IF

    END_IF

.ifdef FD_EXTENDED
        bit     extra_controls_flag
      IF_NS
        ;; Edit control
        copy8   event_params+MGTK::Event::key, file_dialog_res::le_params::key
        copy8   event_params+MGTK::Event::modifiers, file_dialog_res::le_params::modifiers
        LETK_CALL LETK::Key, file_dialog_res::le_params
      END_IF
.endif


exit:   rts

;;; ============================================================

.proc _CheckTypeDown
        lda     event_params+MGTK::Event::key
        jsr     _ToUpperCase
        cmp     #'A'
        bcc     :+
        cmp     #'Z'+1
        bcc     file_char

:       ldx     type_down_buf
        beq     not_file_char

        cmp     #'.'
        beq     file_char
        cmp     #'0'
        bcc     not_file_char
        cmp     #'9'+1
        bcc     file_char

not_file_char:
        return  #$FF

file_char:
        ldx     type_down_buf
        cpx     #15
        RTS_IF_ZS               ; Z=1 to consume

        inx
        stx     type_down_buf
        sta     type_down_buf,x

        jsr     _FindMatch
        bmi     done
        cmp     selected_index
        beq     done
        sta     file_dialog_res::lb_params::new_selection
        LBTK_CALL LBTK::SetSelection, file_dialog_res::lb_params
        jmp     _UpdateDynamicButtons

done:   return  #0

.proc _FindMatch
        lda     num_file_names
        bne     :+
        return  #$FF
:
        copy8   #0, index

        index := *+1
loop:   ldx     #SELF_MODIFIED_BYTE
        lda     file_list_index,x
        and     #$7F
        jsr     _GetNthFilename
        stax    $06

        ldy     #0
        lda     ($06),y
        sta     len

        ldy     #1              ; compare strings (length >= 1)
cloop:  lda     ($06),y
        jsr     _ToUpperCase
        cmp     type_down_buf,y
        bcc     next
        beq     :+
        bcs     found
:
        cpy     type_down_buf
        beq     found

        iny
        len := *+1
        cpy     #SELF_MODIFIED_BYTE
        bcc     cloop
        beq     cloop

next:   inc     index
        lda     index
        cmp     num_file_names
        bne     loop
        dec     index
found:  return  index

.endproc ; _FindMatch

.endproc ; _CheckTypeDown

.endproc ; _HandleKeyEvent

;;; ============================================================

;;; Input: A = index
;;; Output: A,X = filename
.proc _GetNthFilename
        ldx     #$00
        stx     hi

        asl     a               ; * 16
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi
        asl     a
        rol     hi

        clc
        adc     #<file_names
        tay
        hi := *+1
        lda     #SELF_MODIFIED_BYTE
        adc     #>file_names

        tax
        tya
        rts
.endproc ; _GetNthFilename

;;; ============================================================

        .include "../lib/uppercase.s"
        _ToUpperCase := ToUpperCase

;;; ============================================================

.proc _UpdateDynamicButtons
        ;; --------------------------------------------------
        ;; OK
        jsr     _IsOKAllowed
        lda     #0
        ror                     ; C into high bit
        ASSERT_EQUALS BTK::kButtonStateDisabled, $80
        cmp     file_dialog_res::ok_button::state
        beq     :+              ; no change

        sta     file_dialog_res::ok_button::state
        BTK_CALL BTK::Hilite, file_dialog_res::ok_button
:
        ;; --------------------------------------------------
        ;; Open
        jsr     _IsOpenAllowed
        lda     #0
        ror                     ; C into high bit
        ASSERT_EQUALS BTK::kButtonStateDisabled, $80
        cmp     file_dialog_res::open_button::state
        beq     :+              ; no change

        sta     file_dialog_res::open_button::state
        BTK_CALL BTK::Hilite, file_dialog_res::open_button
:
        ;; --------------------------------------------------
        ;; Close
        jsr     _IsCloseAllowed
        lda     #0
        ror                     ; C into high bit
        ASSERT_EQUALS BTK::kButtonStateDisabled, $80
        cmp     file_dialog_res::close_button::state
        beq     :+              ; no change

        sta     file_dialog_res::close_button::state
        BTK_CALL BTK::Hilite, file_dialog_res::close_button
:
        rts
.endproc ; _UpdateDynamicButtons

;;; ============================================================

.proc NoOp
        rts
.endproc ; NoOp

;;; ============================================================

.proc OpenWindow

        ;; Save title string param
        pha
        txa
        pha

.ifdef FD_EXTENDED
        ;; Set correct sizes for the windows (dialog and listbox) based on options.
        ldx     #.sizeof(MGTK::Point)-1
:       bit     extra_controls_flag
    IF_NS
        copy8   file_dialog_res::extra_viewloc,x, file_dialog_res::winfo::viewloc,x
        copy8   file_dialog_res::extra_size,x, file_dialog_res::winfo::maprect+MGTK::Rect::bottomright,x
        copy8   file_dialog_res::extra_listloc,x, file_dialog_res::winfo_listbox::viewloc,x
    ELSE
        copy8   file_dialog_res::normal_viewloc,x, file_dialog_res::winfo::viewloc,x
        copy8   file_dialog_res::normal_size,x, file_dialog_res::winfo::maprect+MGTK::Rect::bottomright,x
        copy8   file_dialog_res::normal_listloc,x, file_dialog_res::winfo_listbox::viewloc,x
    END_IF
        dex
        bpl     :-
.endif

        MGTK_CALL MGTK::OpenWindow, file_dialog_res::winfo

        MGTK_CALL MGTK::SetPort, file_dialog_res::winfo::port
        MGTK_CALL MGTK::SetPenMode, file_dialog_res::notpencopy

.ifdef FD_EXTENDED
        bit     extra_controls_flag
    IF_NS
        MGTK_CALL MGTK::FrameRect, file_dialog_res::line_edit_rect
    END_IF
.endif
        MGTK_CALL MGTK::SetPenSize, file_dialog_res::pensize_frame
.ifndef FD_EXTENDED
        MGTK_CALL MGTK::FrameRect, file_dialog_res::dialog_frame_rect
.else
        bit     extra_controls_flag
    IF_NS
        MGTK_CALL MGTK::FrameRect, file_dialog_res::dialog_ex_frame_rect
    ELSE
        MGTK_CALL MGTK::FrameRect, file_dialog_res::dialog_frame_rect
    END_IF
.endif
        MGTK_CALL MGTK::SetPenSize, file_dialog_res::pensize_normal

        ;; Draw title
        copy16  file_dialog_res::winfo::maprect::x2, file_dialog_res::pos_title::xcoord
        lsr16   file_dialog_res::pos_title::xcoord ; /= 2
        MGTK_CALL MGTK::MoveTo, file_dialog_res::pos_title
        pla
        tax
        pla
        jsr     _DrawStringCentered

        jsr     _IsOKAllowed
        ror
        ASSERT_EQUALS BTK::kButtonStateDisabled, $80
        sta     file_dialog_res::ok_button::state
        BTK_CALL BTK::Draw, file_dialog_res::ok_button

        BTK_CALL BTK::Draw, file_dialog_res::cancel_button
        BTK_CALL BTK::Draw, file_dialog_res::drives_button

        jsr     _IsOpenAllowed
        ror
        ASSERT_EQUALS BTK::kButtonStateDisabled, $80
        sta     file_dialog_res::open_button::state
        BTK_CALL BTK::Draw, file_dialog_res::open_button

        jsr     _IsCloseAllowed
        ror
        ASSERT_EQUALS BTK::kButtonStateDisabled, $80
        sta     file_dialog_res::close_button::state
        BTK_CALL BTK::Draw, file_dialog_res::close_button

        MGTK_CALL MGTK::SetPenMode, file_dialog_res::penXOR
        MGTK_CALL MGTK::SetPattern, file_dialog_res::checkerboard_pattern
        MGTK_CALL MGTK::MoveTo, file_dialog_res::button_sep_start
        MGTK_CALL MGTK::LineTo, file_dialog_res::button_sep_end

.ifdef FD_EXTENDED
        bit     extra_controls_flag
    IF_NS
        MGTK_CALL MGTK::SetPattern, file_dialog_res::winfo::pattern
        MGTK_CALL MGTK::MoveTo, file_dialog_res::dialog_sep_start
        MGTK_CALL MGTK::LineTo, file_dialog_res::dialog_sep_end

        LETK_CALL LETK::Init, file_dialog_res::le_params
        LETK_CALL LETK::Activate, file_dialog_res::le_params
    END_IF
.endif

        lda     #MGTK::Scroll::option_present | MGTK::Scroll::option_thumb
        sta     file_dialog_res::winfo_listbox::vscroll
        MGTK_CALL MGTK::OpenWindow, file_dialog_res::winfo_listbox

        rts
.endproc ; OpenWindow

;;; ============================================================

.proc CloseWindow
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo_listbox
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo
.ifdef FD_EXTENDED
        jsr     _UnsetCursorIBeam
.endif
        rts
.endproc ; CloseWindow

;;; ============================================================

.proc DrawString
        ptr := $06
        params := $06

        stax    ptr
        ldy     #0
        lda     (ptr),y
        beq     ret
        sta     params+2
        inc16   params
        MGTK_CALL MGTK::DrawText, params
ret:    rts
.endproc ; DrawString

;;; ============================================================

.proc _DrawStringCentered
        ptr := $06
        params := $06

        stax    ptr
        ldy     #0
        lda     (ptr),y
        beq     ret
        sta     params+2
        inc16   params
        MGTK_CALL MGTK::TextWidth, params
        lsr16   params+3               ; width
        sub16   #0, params+3, params+3 ; deltax
        copy16  #0, params+5           ; deltay
        MGTK_CALL MGTK::Move, params+3
        MGTK_CALL MGTK::DrawText, params
ret:    rts
.endproc ; _DrawStringCentered

;;; ============================================================

.ifdef FD_EXTENDED
.proc DrawLineEditLabel
        pha                     ; save A,X
        txa
        pha
        MGTK_CALL MGTK::MoveTo, file_dialog_res::line_edit_label_pos
        pla                     ; restore A,X
        tax
        pla
        jmp     DrawString
.endproc ; DrawLineEditLabel
.endif

;;; ============================================================

.proc InitPathWithDefaultDevice
        copy8   DEVCNT, device_num

        device_num := *+1
retry:  ldx     #SELF_MODIFIED_BYTE
        lda     DEVLST,x

        and     #UNIT_NUM_MASK
        sta     on_line_params::unit_num
        MLI_CALL ON_LINE, on_line_params
        lda     on_line_buffer
        and     #NAME_LENGTH_MASK
        bne     found

        dec     device_num
        bpl     retry
        copy8   DEVCNT, device_num
        jmp     retry

found:  param_call AdjustOnLineEntryCase, on_line_buffer
        lda     #0
        sta     path_buf
        param_jump _AppendToPathBuf, on_line_buffer
.endproc ; InitPathWithDefaultDevice

;;; ============================================================
;;; Assert: `selected_index` is valid (not -1)

.proc _AppendSelectedFilename
        ldx     selected_index
        lda     file_list_index,x
        and     #$7F

        jsr     _GetNthFilename
        FALL_THROUGH_TO _AppendToPathBuf
.endproc ; _AppendSelectedFilename

;;; ============================================================

;;; Appends filename at A,X to `path_buf`
;;; Output: C=0 on success, C=1 and path unchanged if too long

.proc _AppendToPathBuf
        ptr := $06
        stax    ptr
        ldx     path_buf
        cpx     #1
        beq     :+
        lda     #'/'
        sta     path_buf+1,x
        inc     path_buf
:       ldy     #0
        lda     (ptr),y
        tay
        clc
        adc     path_buf

        ;; Enough room?
        cmp     #kPathBufferSize
        bcc     :+
        dec     path_buf
        rts                     ; C=1 failure
:
        pha
        tax
:       lda     (ptr),y
        sta     path_buf,x
        dey
        dex
        cpx     path_buf
        bne     :-

        pla
        sta     path_buf

        clc                     ; C=0 success
        rts
.endproc ; _AppendToPathBuf

;;; ============================================================

.proc _StripPathBufSegment
:       ldx     path_buf
        cpx     #0
        beq     :+
        dec     path_buf
        lda     path_buf,x
        cmp     #'/'
        bne     :-
:       rts
.endproc ; _StripPathBufSegment

;;; ============================================================

.proc _ReadDir
        jsr     _IsRootPath
        jeq     _ReadDrives

        MLI_CALL OPEN, open_params
        bcs     err
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        MLI_CALL READ, read_params
        bcc     :+
err:    copy8   #1, path_buf
        jmp     _ReadDrives
:
        lda     #0
        sta     entry_index
        lda     #1
        sta     entry_in_block
        copy8   dir_read_buf+SubdirectoryHeader::entry_length, entry_length
        copy8   dir_read_buf+SubdirectoryHeader::entries_per_block, entries_per_block
        lda     dir_read_buf+SubdirectoryHeader::file_count
        and     #$7F
        sta     num_file_names
        bne     :+
        jmp     close

        ptr := $06
:       copy16  #dir_read_buf+.sizeof(SubdirectoryHeader), ptr

l1:     param_call_indirect AdjustFileEntryCase, ptr

        ldy     #FileEntry::storage_type_name_length
        lda     (ptr),y
        and     #NAME_LENGTH_MASK
        beq     l6              ; deleted entry

        ldx     entry_index
        txa
        sta     file_list_index,x

        ;; Invisible?
        ldx     #DeskTopSettings::options
        jsr     ReadSetting
        and     #DeskTopSettings::kOptionsShowInvisible
    IF_ZERO
        ldy     #FileEntry::access
        lda     (ptr),y
        and     #ACCESS_I
      IF_NE
        dec     num_file_names  ; skip
        jmp     l6
      END_IF
    END_IF

        ;; Directory?
        ldy     #FileEntry::storage_type_name_length
        lda     (ptr),y
        and     #STORAGE_TYPE_MASK
        cmp     #ST_LINKED_DIRECTORY << 4
        beq     l3              ; is dir
        bit     only_show_dirs_flag
        bpl     l4              ; not dir, but show
        dec     num_file_names  ; skip
        jmp     l6

        ;; Flag as "is dir"
l3:     ldx     entry_index
        lda     file_list_index,x
        ora     #$80
        sta     file_list_index,x

l4:     ldy     #FileEntry::storage_type_name_length
        lda     (ptr),y
        and     #NAME_LENGTH_MASK
        sta     (ptr),y

        lda     entry_index
        jsr     _CopyIntoNthFilename

        inc     entry_index
l6:     inc     entry_in_block
        lda     entry_index
        cmp     num_file_names
        bne     next

close:  MLI_CALL CLOSE, close_params
        jsr     _SortFileNames
        clc
        rts

next:   lda     entry_in_block
        cmp     entries_per_block
        beq     :+
        add16_8 ptr, entry_length
        jmp     l1

:       MLI_CALL READ, read_params
        copy16  #dir_read_buf+$04, ptr
        lda     #$00
        sta     entry_in_block
        jmp     l1

entry_index:
        .byte   0
entry_in_block:
        .byte   0
entry_length:
        .byte   0
entries_per_block:
        .byte   0
.endproc ; _ReadDir

;;; ============================================================

        DEFINE_ON_LINE_PARAMS on_line_params_drives, 0, dir_read_buf

.proc _ReadDrives
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch

        MLI_CALL ON_LINE, on_line_params_drives

        ptr := $06
        copy16  #dir_read_buf, ptr

        copy8   #0, num_file_names

loop:   ldy     #0
        lda     (ptr),y         ; A = unit_num | name_len
        and     #NAME_LENGTH_MASK
        bne     :+
        iny                     ; 0 signals error or complete
        lda     (ptr),y
        bne     next            ; error, so skip
        beq     finish          ; always
:
        param_call_indirect AdjustOnLineEntryCase, ptr

        lda     num_file_names
        jsr     _CopyIntoNthFilename


        ldx     num_file_names
        txa
        ora     #$80            ; treat as folder
        sta     file_list_index,x

        inc     num_file_names

next:   add16_8 ptr, #16        ; advance to next
        jmp     loop

finish:
        jsr     _SortFileNames

        jsr     _SetCursorPointer
.ifdef FD_EXTENDED
        copy8   #0, cursor_ibeam_flag
.endif

        clc
        rts
.endproc ; _ReadDrives

;;; ============================================================
;;; Inputs: A = dst filename index; $06 = src ptr
;;; Trashes $08

.proc _CopyIntoNthFilename
        src_ptr := $06
        dst_ptr := $08
        jsr     _GetNthFilename
        stax    dst_ptr

        ldy     #0
        lda     (src_ptr),y
        tay
:       lda     (src_ptr),y
        sta     (dst_ptr),y
        dey
        bpl     :-

        rts
.endproc ; _CopyIntoNthFilename

;;; ============================================================

.proc _UpdateDiskAndDirNames
        MGTK_CALL MGTK::SetPort, file_dialog_res::winfo::port

        copy8   #kGlyphDiskLeft, file_dialog_res::filename_buf+1
        copy8   #kGlyphDiskRight, file_dialog_res::filename_buf+2
        copy8   #kGlyphSpacer, file_dialog_res::filename_buf+3

        ;; --------------------------------------------------
        ;; Disk Name

        MGTK_CALL MGTK::SetPenMode, file_dialog_res::pencopy
        MGTK_CALL MGTK::PaintRect, file_dialog_res::disk_name_rect

        jsr     _IsRootPath
    IF_NE
        copy16  #path_buf, $06

        ldy     #3

        ;; Copy first segment
        ldx     #2              ; skip leading slash
:       lda     path_buf,x
        cmp     #'/'
        beq     :+
        iny
        sta     file_dialog_res::filename_buf,y
        cpx     path_buf
        beq     :+
        inx
        bne     :-              ; always
:       sty     file_dialog_res::filename_buf

        MGTK_CALL MGTK::MoveTo, file_dialog_res::disk_label_pos
        param_call _DrawStringCentered, file_dialog_res::filename_buf
    END_IF

        ;; --------------------------------------------------
        ;; Dir Name

        MGTK_CALL MGTK::PaintRect, file_dialog_res::dir_name_rect
        copy16  #path_buf, $06

        jsr     _IsRootPath
    IF_NE
        ;; Copy last segment
        ldx     path_buf
:       lda     path_buf,x
        cmp     #'/'
        beq     :+
        dex
        bne     :-              ; always
:       inx

        cpx     #2
      IF_NE
        copy8   #kGlyphFolderLeft, file_dialog_res::filename_buf+1
        copy8   #kGlyphFolderRight, file_dialog_res::filename_buf+2
      END_IF

        ldy     #4
:       lda     path_buf,x
        sta     file_dialog_res::filename_buf,y
        cpx     path_buf
        beq     :+
        iny
        inx
        bne     :-              ; always
:       sty     file_dialog_res::filename_buf

        MGTK_CALL MGTK::MoveTo, file_dialog_res::dir_label_pos
        param_call _DrawStringCentered, file_dialog_res::filename_buf
    END_IF

        rts
.endproc ; _UpdateDiskAndDirNames

;;; ============================================================
;;; Sorts `file_list_index` so names are in ascending order
;;; Assert: On entry, `file_list_index` table is populated 0...`num_file_names`-1

.proc _SortFileNames
        lda     num_file_names
        cmp     #2
        RTS_IF_LT               ; can't sort < 2 records

        ;; --------------------------------------------------
        ;; Selection sort

        ptr1 := $06
        ptr2 := $08

        ldx     num_file_names
        dex
        stx     outer

        outer := *+1
oloop:  lda     #SELF_MODIFIED_BYTE
        jsr     _CalcPtr
        stax    ptr2

        lda     #0
        sta     inner

        inner := *+1
iloop:  lda     #SELF_MODIFIED_BYTE
        jsr     _CalcPtr
        stax    ptr1

        jsr     _CompareStrings
        bcc     next

        ;; Swap
        ldx     inner
        ldy     outer
        lda     file_list_index,x
        pha
        lda     file_list_index,y
        sta     file_list_index,x
        pla
        sta     file_list_index,y

        lda     outer
        jsr     _CalcPtr
        stax    ptr2

next:   inc     inner
        lda     inner
        cmp     outer
        bne     iloop

        dec     outer
        bne     oloop

        rts

.proc _CalcPtr
        tax
        lda     file_list_index,x
        and     #$7F
        jmp     _GetNthFilename
.endproc ; _CalcPtr

;;; Inputs: $06, $08 are pts to strings
;;; Compare strings at $06 (1) and $08 (2).
;;; Returns C=0 for 1<2 , C=1 for 1>=2, Z=1 for 1=2
.proc _CompareStrings
        ldy     #0
        copy8   (ptr1),y, len1
        copy8   (ptr2),y, len2
        iny

loop:   lda     (ptr2),y
        jsr     _ToUpperCase
        sta     char
        lda     (ptr1),y
        jsr     _ToUpperCase
        char := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     ret             ; differ at Yth character

        ;; End of string 1?
        len1 := *+1
        cpy     #SELF_MODIFIED_BYTE
        bne     :+
        cpy     len2            ; 1<2 or 1=2 ?
        rts

        ;; End of string 2?
        len2 := *+1
:       cpy     #SELF_MODIFIED_BYTE
        beq     gt              ; 1>2
        iny
        bne     loop            ; always

gt:     lda     #$FF            ; Z=0
        sec
ret:    rts
.endproc ; _CompareStrings

.endproc ; _SortFileNames

;;; ============================================================
;;; Find index to filename in file_list_index.
;;; Input: A,X = ptr to filename
;;; Output: A = index, or $FF if not found

.ifdef FD_EXTENDED
.proc _FindFilenameIndex
        name_ptr := $08
        curr_ptr := $06

        stax    name_ptr

        ;; Compare against each filename
        lda     #0
        sta     index
        copy16  #file_names, curr_ptr
loop:
        index := *+1
        lda     #SELF_MODIFIED_BYTE
        cmp     num_file_names
        beq     failed

        ;; Check length
        jsr     _SortFileNames::_CompareStrings
        beq     found

        ;; No match - next!
        inc     index
        add16_8 curr_ptr, #16
        jmp     loop

failed: return  #$FF

        ;; Now find index
found:  ldx     num_file_names
:       dex
        lda     file_list_index,x
        and     #$7F
        cmp     index
        bne     :-
        txa
        rts
.endproc ; _FindFilenameIndex
.endif

;;; ============================================================

.ifdef FD_EXTENDED

;;; Dynamically altered table of handlers.

kJumpTableSize = 6
jump_table:
HandleOK:       jmp     0
HandleCancel:   jmp     0
        ASSERT_EQUALS * - jump_table, kJumpTableSize

.endif ; FD_EXTENDED

;;; ============================================================
;;; List Box
;;; ============================================================

ASSERT_EQUALS .sizeof(file_dialog_res::listbox_rec), .sizeof(LBTK::ListBoxRecord)
num_file_names := file_dialog_res::listbox_rec::num_items
selected_index := file_dialog_res::listbox_rec::selected_index

.proc OnListSelectionChange
        jsr     _UpdateDynamicButtons
        rts
.endproc ; OnListSelectionChange

;;; ============================================================

;;; Called with A = index, X,Y = addr of drawing pos (MGTK::Point)
.proc DrawListEntryProc
        pha
        pt_ptr := $06
        stxy    pt_ptr
        ldy     #.sizeof(MGTK::Point)-1
:       lda     (pt_ptr),y
        sta     file_dialog_res::item_pos,y
        dey
        bpl     :-
        pla

        tax
        lda     file_list_index,x
        pha
        and     #$7F

        jsr     _GetNthFilename
        stax    ptr
        ldx     #kMaxFilenameLength
        ptr := *+1
:       lda     SELF_MODIFIED,x
        sta     file_dialog_res::filename_buf,x
        dex
        bpl     :-
        copy16  #kListViewNameX, file_dialog_res::item_pos+MGTK::Point::xcoord
        MGTK_CALL MGTK::MoveTo, file_dialog_res::item_pos
        param_call DrawString, file_dialog_res::filename_buf

        ;; Folder glyph?
        copy16  #kListViewIconX, file_dialog_res::item_pos+MGTK::Point::xcoord
        MGTK_CALL MGTK::MoveTo, file_dialog_res::item_pos
        pla
    IF_NS
        ldax    #file_dialog_res::str_folder

        ldy     path_buf
        cpy     #1
      IF_EQ
        ldax    #file_dialog_res::str_vol
      END_IF

    ELSE
        ldax    #file_dialog_res::str_file
    END_IF
        jmp     DrawString
.endproc ; DrawListEntryProc

;;; ============================================================

.endscope ; file_dialog_impl

;;; "Exports"
CloseWindow := file_dialog_impl::CloseWindow
EventLoop := file_dialog_impl::EventLoop
GetPath := file_dialog_impl::GetPath
InitPathWithDefaultDevice := file_dialog_impl::InitPathWithDefaultDevice
OpenWindow := file_dialog_impl::OpenWindow
Init := file_dialog_impl::Init
UpdateListFromPath := file_dialog_impl::UpdateListFromPath

only_show_dirs_flag := file_dialog_impl::only_show_dirs_flag
selection_requirement_flags := file_dialog_impl::selection_requirement_flags
kSelectionOptional           = %00000000 ; unused
kSelectionOptionalUnlessRoot = %01000000
kSelectionRequiredNoDirs     = %10000000
kSelectionRequiredDirsOK     = %11000000

path_buf := file_dialog_impl::path_buf

STATE_START := file_dialog_impl::state_start
STATE_END   := file_dialog_impl::state_end

::file_dialog_impl__DrawListEntryProc := file_dialog_impl::DrawListEntryProc
::file_dialog_impl__OnListSelectionChange := file_dialog_impl::OnListSelectionChange

.ifdef FD_EXTENDED
DrawLineEditLabel := file_dialog_impl::DrawLineEditLabel
UpdateListFromPathAndSelectFile := file_dialog_impl::UpdateListFromPathAndSelectFile

click_handler_hook := file_dialog_impl::click_handler_hook
key_handler_hook := file_dialog_impl::key_handler_hook
extra_controls_flag := file_dialog_impl::extra_controls_flag
jump_table := file_dialog_impl::jump_table
kJumpTableSize := file_dialog_impl::kJumpTableSize
.endif
