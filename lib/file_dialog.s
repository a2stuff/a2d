;;; ============================================================
;;; Common File Picker Dialog
;;;
;;; Required includes:
;;; * lib/adjustfilecase.s
;;; * lib/doubleclick.s
;;; * lib/event_params.s
;;; * lib/file_dialog_res.s
;;; * lib/get_next_event.s
;;; * lib/muldiv.s
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

;;; Buffer used when selecting filename by holding Apple key and typing name.
;;; Length-prefixed string, initialized to 0 when the dialog is shown.
type_down_buf   := $1600        ; 16 bytes
on_line_buffer  := $1610        ; 16 bytes for ON_LINE calls
path_buf        := $1620        ; 65 bytes for path+length

;;; Map from index in file_names to list entry; high bit is
;;; set for directories.
file_list_index := $1780

num_file_names  := $177F

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

dir_count:
        .byte   0

selected_index:                 ; $FF if none
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

        copy    #$FF, selected_index

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
        MGTK_CALL MGTK::InRect, file_dialog_res::input1_rect
        .assert MGTK::inrect_outside = 0, error, "enum mismatch"
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
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        rts
.endproc ; _MoveToWindowCoords

;;; ============================================================

.proc _HandleButtonDown
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        beq     :+
ret:    rts
:
        lda     findwindow_params::window_id
        cmp     #file_dialog_res::kFilePickerDlgWindowID
        beq     not_list
        jsr     ListClick
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
        MGTK_CALL MGTK::InRect, file_dialog_res::input1_rect
      IF_NOT_ZERO
        COPY_STRUCT MGTK::Point, screentowindow_params::window, file_dialog_res::le_params::coords
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
        copy    #$FF, selected_index
        jsr     ListInit
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

        jsr     ListInit
        jmp     _UpdateDynamicButtons
.endproc ; UpdateListFromPathAndSelectFile
.endif

;;; ============================================================

.ifdef FD_EXTENDED
.proc _SetCursorIBeam
        bit     cursor_ibeam_flag
        bmi     :+
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::ibeam
        copy    #$80, cursor_ibeam_flag
:       rts
.endproc ; _SetCursorIBeam

.proc _UnsetCursorIBeam
        bit     cursor_ibeam_flag
        bpl     :+
        jsr     _SetCursorPointer
        copy    #0, cursor_ibeam_flag
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
        copy    #1, path_buf
        copy    #'/', path_buf+1
        rts
.endproc ; _SetRootPath

;;; ============================================================

;;; Output: C=0 if allowed, C=1 if not.
.proc _IsOpenAllowed
        lda     selected_index
        bmi     no              ; no selection
        tax
        lda     file_list_index,x
        bpl     no              ; not a folder

        clc
        rts

no:     sec
        rts
.endproc ; _IsOpenAllowed

;;; ============================================================

;;; Output: C=0 if allowed, C=1 if not.
.proc _IsCloseAllowed
        lda     path_buf
        cmp     #1
        beq     no

        clc
        rts

no:     sec
        rts
.endproc ; _IsCloseAllowed

;;; ============================================================

_IsOKAllowed := _IsCloseAllowed

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
        lda     event_params::key
        jsr     IsListKey
    IF_EQ
        copy    #0, type_down_buf
        jmp     ListKey
    END_IF

        ldx     event_params::modifiers
    IF_NE
        ;; With modifiers
        jsr     _CheckTypeDown
        jeq     exit

        copy    #0, type_down_buf
        ldx     event_params::modifiers
        lda     event_params::key

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

        copy    #0, type_down_buf
        lda     event_params::key

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
        copy    event_params::key, file_dialog_res::le_params::key
        copy    event_params::modifiers, file_dialog_res::le_params::modifiers
        LETK_CALL LETK::Key, file_dialog_res::le_params
      END_IF
.endif


exit:   rts

;;; ============================================================

.proc _CheckTypeDown
        lda     event_params::key
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
        jsr     ListSetSelection
        jmp     _UpdateDynamicButtons

done:   return  #0

.proc _FindMatch
        lda     num_file_names
        bne     :+
        return  #$FF
:
        copy    #0, index

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
        .assert BTK::kButtonStateDisabled = $80, error, "const mismatch"
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
        .assert BTK::kButtonStateDisabled = $80, error, "const mismatch"
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
        .assert BTK::kButtonStateDisabled = $80, error, "const mismatch"
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
        copy    file_dialog_res::extra_viewloc,x, file_dialog_res::winfo::viewloc,x
        copy    file_dialog_res::extra_size,x, file_dialog_res::winfo::maprect+MGTK::Rect::bottomright,x
        copy    file_dialog_res::extra_listloc,x, file_dialog_res::winfo_listbox::viewloc,x
    ELSE
        copy    file_dialog_res::normal_viewloc,x, file_dialog_res::winfo::viewloc,x
        copy    file_dialog_res::normal_size,x, file_dialog_res::winfo::maprect+MGTK::Rect::bottomright,x
        copy    file_dialog_res::normal_listloc,x, file_dialog_res::winfo_listbox::viewloc,x
    END_IF
        dex
        bpl     :-
.endif

        MGTK_CALL MGTK::OpenWindow, file_dialog_res::winfo

        lda     #MGTK::Scroll::option_present | MGTK::Scroll::option_thumb
        sta     file_dialog_res::winfo_listbox::vscroll
        MGTK_CALL MGTK::OpenWindow, file_dialog_res::winfo_listbox

        MGTK_CALL MGTK::SetPort, file_dialog_res::winfo::port
        MGTK_CALL MGTK::SetPenMode, file_dialog_res::notpencopy

.ifdef FD_EXTENDED
        bit     extra_controls_flag
    IF_NS
        MGTK_CALL MGTK::FrameRect, file_dialog_res::input1_rect
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
        .assert BTK::kButtonStateDisabled = $80, error, "const mismatch"
        sta     file_dialog_res::ok_button::state
        BTK_CALL BTK::Draw, file_dialog_res::ok_button

        BTK_CALL BTK::Draw, file_dialog_res::cancel_button
        BTK_CALL BTK::Draw, file_dialog_res::drives_button

        jsr     _IsOpenAllowed
        ror
        .assert BTK::kButtonStateDisabled = $80, error, "const mismatch"
        sta     file_dialog_res::open_button::state
        BTK_CALL BTK::Draw, file_dialog_res::open_button

        jsr     _IsCloseAllowed
        ror
        .assert BTK::kButtonStateDisabled = $80, error, "const mismatch"
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
        MGTK_CALL MGTK::MoveTo, file_dialog_res::input1_label_pos
        pla                     ; restore A,X
        tax
        pla
        jmp     DrawString
.endproc ; DrawLineEditLabel
.endif

;;; ============================================================

.proc InitPathWithDefaultDevice
        copy    DEVCNT, device_num

        device_num := *+1
retry:  ldx     #SELF_MODIFIED_BYTE
        lda     DEVLST,x

        and     #UNIT_NUM_MASK
        sta     on_line_params::unit_num
        MLI_CALL ON_LINE, on_line_params
        lda     on_line_buffer
        and     #NAME_LENGTH_MASK
        sta     on_line_buffer
        bne     found

        dec     device_num
        bpl     retry
        copy    DEVCNT, device_num
        jmp     retry

found:  param_call AdjustVolumeNameCase, on_line_buffer
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
        lda     path_buf
        cmp     #1
        jeq     _ReadDrives

        MLI_CALL OPEN, open_params
        bcs     err
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        MLI_CALL READ, read_params
        bcc     :+
err:    copy    #1, path_buf
        jmp     _ReadDrives
:
        lda     #0
        sta     d1
        sta     d2
        sta     dir_count
        lda     #1
        sta     d3
        copy16  dir_read_buf+SubdirectoryHeader::entry_length, entry_length
        lda     dir_read_buf+SubdirectoryHeader::file_count
        and     #$7F
        sta     num_file_names
        bne     :+
        jmp     close

        ptr := $06
:       copy16  #dir_read_buf+.sizeof(SubdirectoryHeader), ptr

l1:     param_call_indirect AdjustFileEntryCase, ptr

        ldy     #0
        lda     (ptr),y
        and     #NAME_LENGTH_MASK
        bne     l2
        jmp     l6

l2:     ldx     d1
        txa
        sta     file_list_index,x
        ldy     #0
        lda     (ptr),y
        and     #STORAGE_TYPE_MASK
        cmp     #ST_LINKED_DIRECTORY << 4
        beq     l3
        bit     only_show_dirs_flag
        bpl     l4
        inc     d2
        jmp     l6

l3:     lda     file_list_index,x
        ora     #$80
        sta     file_list_index,x
        inc     dir_count
l4:     ldy     #$00
        lda     (ptr),y
        and     #NAME_LENGTH_MASK
        sta     (ptr),y

        lda     d1
        jsr     _CopyIntoNthFilename

        inc     d1
        inc     d2
l6:     inc     d3
        lda     d2
        cmp     num_file_names
        bne     next

close:  MLI_CALL CLOSE, close_params
        bit     only_show_dirs_flag
        bpl     :+
        lda     dir_count
        sta     num_file_names
:       jsr     _SortFileNames
        clc
        rts

next:   lda     d3
        cmp     d4
        beq     :+
        add16_8 ptr, entry_length
        jmp     l1

:       MLI_CALL READ, read_params
        copy16  #dir_read_buf+$04, ptr
        lda     #$00
        sta     d3
        jmp     l1

d1:     .byte   0
d2:     .byte   0
d3:     .byte   0
entry_length:
        .byte   0
d4:     .byte   0
.endproc ; _ReadDir

;;; ============================================================

        DEFINE_ON_LINE_PARAMS on_line_params_drives, 0, dir_read_buf

.proc _ReadDrives
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch

        MLI_CALL ON_LINE, on_line_params_drives

        ptr := $06
        copy16  #dir_read_buf, ptr

        copy    #0, num_file_names

loop:   ldy     #0
        lda     (ptr),y         ; A = unit_num | name_len
        and     #NAME_LENGTH_MASK
        bne     :+
        iny                     ; 0 signals error or complete
        lda     (ptr),y
        bne     next            ; error, so skip
        beq     finish          ; always
:
        sta     (ptr),y         ; A = name_len

        param_call_indirect AdjustVolumeNameCase, ptr

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
        copy    #0, cursor_ibeam_flag
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

        copy    #kGlyphDiskLeft, file_dialog_res::filename_buf+1
        copy    #kGlyphDiskRight, file_dialog_res::filename_buf+2
        copy    #kGlyphSpacer, file_dialog_res::filename_buf+3

        ;; --------------------------------------------------
        ;; Disk Name

        MGTK_CALL MGTK::SetPenMode, file_dialog_res::pencopy
        MGTK_CALL MGTK::PaintRect, file_dialog_res::disk_name_rect

        lda     path_buf
        cmp     #1
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

        lda     path_buf
        cmp     #1
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
        copy    #kGlyphFolderLeft, file_dialog_res::filename_buf+1
        copy    #kGlyphFolderRight, file_dialog_res::filename_buf+2
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
        copy    (ptr1),y, len1
        copy    (ptr2),y, len2
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
        .assert * - jump_table = kJumpTableSize, error, "Table size mismatch"

.endif ; FD_EXTENDED

;;; ============================================================
;;; List Box
;;; ============================================================

.proc OnListSelectionChange
        jsr     _UpdateDynamicButtons
        rts
.endproc ; OnListSelectionChange

.scope listbox
        winfo = file_dialog_res::winfo_listbox
        kRows = file_dialog_res::kListRows
        num_items = num_file_names
        item_pos = file_dialog_res::picker_entry_pos
.endscope ; listbox
listbox::selected_index = selected_index

        .include "../lib/listbox.s"

;;; ============================================================

;;; Called with A = index
.proc DrawListEntryProc
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
        copy16  #kListViewNameX, listbox::item_pos+MGTK::Point::xcoord
        MGTK_CALL MGTK::MoveTo, listbox::item_pos
        param_call DrawString, file_dialog_res::filename_buf

        ;; Folder glyph?
        copy16  #kListViewIconX, listbox::item_pos+MGTK::Point::xcoord
        MGTK_CALL MGTK::MoveTo, listbox::item_pos
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
NoOp := file_dialog_impl::NoOp
OpenWindow := file_dialog_impl::OpenWindow
Init := file_dialog_impl::Init
UpdateListFromPath := file_dialog_impl::UpdateListFromPath

only_show_dirs_flag := file_dialog_impl::only_show_dirs_flag
path_buf := file_dialog_impl::path_buf

.ifdef FD_EXTENDED
DrawLineEditLabel := file_dialog_impl::DrawLineEditLabel
UpdateListFromPathAndSelectFile := file_dialog_impl::UpdateListFromPathAndSelectFile

click_handler_hook := file_dialog_impl::click_handler_hook
key_handler_hook := file_dialog_impl::key_handler_hook
extra_controls_flag := file_dialog_impl::extra_controls_flag
jump_table := file_dialog_impl::jump_table
kJumpTableSize := file_dialog_impl::kJumpTableSize
.endif
