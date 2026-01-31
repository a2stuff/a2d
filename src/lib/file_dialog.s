;;; ============================================================
;;; Common File Picker Dialog
;;;
;;; Required includes:
;;; * lib/adjustfilecase.s
;;; * lib/doubleclick.s
;;; * lib/event_params.s
;;; * lib/file_dialog_res.s
;;;
;;; Requires these macros to be functional (via corresponding `XYZEntry`)
;;; * `MLI_CALL`
;;; * `MGTK_CALL`
;;; * `BTK_CALL`
;;; * `LBTK_CALL`
;;;
;;; Usage:
;;; * Save the stack pointer
;;; * Call `Init` with A=`kSelection*`, X=`kShow*`
;;; * Assign dialog title to Winfo's `title`
;;; * Modify flags:
;;;   * `selection_requirement_flags`
;;;   * `only_show_dirs_flag`
;;; * Call `OpenWindow` with AX = Winfo
;;; * Call `InitPathWithDefaultDevice` or `InitPath` with AX = path
;;; * Call `UpdateListFromPath`
;;;   * If `FD_EXTRAS` defined, can call `UpdateListFromPathAndSelectFile` instead
;;;
;;; Client must implement an event loop:
;;;   * Call `GetNextEvent`
;;;   * on `EventKind::key_down` call `HandleKey`
;;;   * on `EventKind::button_down` call `HandleClick`
;;;   * otherwise, if not `EventKind::no_event` call `ResetTypeDown`
;;; If custom controls are used, then `ResetTypeDown` should be called
;;; if one consumes an event. Call `CheckTypeDown` directly with key in
;;; A if doing modified type-down; returns Z=1 if consumed.
;;;
;;; Client must implement `HandleOK` in scope; when called:
;;;   * Call `GetPath` with AX = path buffer
;;;   * Validate; return if not valid
;;;     * While validating, state in `STATE_START`...`STATE_END` must be preserved.
;;;   * Call `CloseWindow`
;;;   * Restore the stack
;;;
;;; Client must implement `HandleCancel` in scope; when called:
;;;   * Call `CloseWindow`
;;;   * Restore the stack

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
        DEFINE_READWRITE_PARAMS read_params, dir_read_buf, kDirReadSize
        DEFINE_CLOSE_PARAMS close_params

only_show_dirs_flag:            ; bit7 set when selecting copy destination
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

;;; Input: A=`selection_requirement_flags`, X=`only_show_dirs_flag`

.proc Init
        sta     selection_requirement_flags
        stx     only_show_dirs_flag

        jsr     _SetCursorPointer
        jsr     ResetTypeDown
        copy8   #$FF, selected_index

        ;; Client must call `UpdateListFromPath` or
        ;; `UpdateListFromPathAndSelectFile` which will initialize the
        ;; dynamic button states.

        rts
.endproc ; Init

;;; ============================================================

.proc _MoveToWindowCoords
        lda     #file_dialog_res::kFilePickerDlgWindowID
        sta     screentowindow_params+MGTK::ScreenToWindowParams::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params+MGTK::ScreenToWindowParams::window
        rts
.endproc ; _MoveToWindowCoords

;;; ============================================================

.proc HandleClick
        jsr     ResetTypeDown

        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params+MGTK::FindWindowParams::which_area
    IF A <> #MGTK::Area::content
ret:    rts
    END_IF

        ;; Dialog window?
        lda     findwindow_params+MGTK::FindWindowParams::window_id
    IF A <> #file_dialog_res::kFilePickerDlgWindowID
        ;; No, assume list box (will fail gracefully if not)
        COPY_STRUCT MGTK::Point, event_params+MGTK::Event::coords, file_dialog_res::lb_params::coords
        LBTK_CALL LBTK::Click, file_dialog_res::lb_params
        bmi     ret
        jsr     DetectDoubleClick
        bmi     ret
        ldx     selected_index
        lda     file_list_index,x
      IF NC
        ;; File - accept it.
        BTK_CALL BTK::Flash, file_dialog_res::ok_button
        jmp     HandleOK
      END_IF
        ;; Folder - open it.
        BTK_CALL BTK::Flash, file_dialog_res::open_button
        jmp     _DoOpen
    END_IF

        jsr     _MoveToWindowCoords

        ;; --------------------------------------------------
        ;; Drives button

        MGTK_CALL MGTK::InRect, file_dialog_res::drives_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, file_dialog_res::drives_button
        RTS_IF NS
        jmp     _DoDrives
    END_IF

        ;; --------------------------------------------------
        ;; Open button

        MGTK_CALL MGTK::InRect, file_dialog_res::open_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, file_dialog_res::open_button
        RTS_IF NS
        jmp     _DoOpen
    END_IF

        ;; --------------------------------------------------
        ;; Close button

        MGTK_CALL MGTK::InRect, file_dialog_res::close_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, file_dialog_res::close_button
        RTS_IF NS
        jmp     _DoClose
    END_IF

        ;; --------------------------------------------------
        ;; OK button

        MGTK_CALL MGTK::InRect, file_dialog_res::ok_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, file_dialog_res::ok_button
        RTS_IF NS
        jmp     HandleOK
    END_IF

        ;; --------------------------------------------------
        ;; Cancel button

        MGTK_CALL MGTK::InRect, file_dialog_res::cancel_button::rect
    IF NOT_ZERO
        BTK_CALL BTK::Track, file_dialog_res::cancel_button
        RTS_IF NS
        jmp     HandleCancel
    END_IF


        rts
.endproc ; HandleClick

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
.ifdef FD_EXTRAS
.proc UpdateListFromPathAndSelectFile
        phax

        jsr     _ReadDir
        jsr     _UpdateDiskAndDirNames

        plax
        jsr     _FindFilenameIndex
        sta     selected_index

        LBTK_CALL LBTK::Init, file_dialog_res::lb_params
        jmp     _UpdateDynamicButtons
.endproc ; UpdateListFromPathAndSelectFile

;;; ============================================================
;;; Find index to filename in file_list_index.
;;; Input: A,X = ptr to filename
;;; Output: A = index, or $FF if not found

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
        jsr     _CompareStrings
        beq     found

        ;; No match - next!
        inc     index
        add16_8 curr_ptr, #16
        jmp     loop

failed: RETURN  A=#$FF

        ;; Now find index
found:  ldx     num_file_names
    DO
        dex
        lda     file_list_index,x
        and     #$7F
    WHILE A <> index
        txa
        rts
.endproc ; _FindFilenameIndex
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
    IF NC
        ;; Append filename temporarily
        jsr     _AppendSelectedFilename
    END_IF

        ldy     path_buf
    DO
        lda     path_buf,y
        ptr := *+1
        sta     SELF_MODIFIED,y
        dey
    WHILE POS

        bit     selected_index
    IF NC
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
        ldx     selected_index
        bmi     _ReturnNotAllowed ; no selection
        lda     file_list_index,x
        bpl     _ReturnNotAllowed ; not a folder
        FALL_THROUGH_TO _ReturnAllowed
.endproc ; _IsOpenAllowed

.proc _ReturnAllowed
        RETURN  C=0
.endproc ; _ReturnAllowed

.proc _ReturnNotAllowed
        RETURN  C=1
.endproc ; _ReturnNotAllowed

;;; ============================================================

;;; Output: C=0 if allowed, C=1 if not.
.proc _IsCloseAllowed
        jsr     _IsRootPath
        beq     _ReturnNotAllowed

        RETURN  C=0
.endproc ; _IsCloseAllowed

;;; ============================================================

;;; Output: C=0 if allowed, C=1 if not.
.proc _IsOKAllowed
        .assert kSelectionOptional           & $80 = $00, error, "enum mismatch"
        .assert kSelectionOptionalUnlessRoot & $80 = $00, error, "enum mismatch"
        .assert kSelectionRequiredNoDirs     & $80 = $80, error, "enum mismatch"
        .assert kSelectionRequiredDirsOK     & $80 = $80, error, "enum mismatch"

        bit     selection_requirement_flags
    IF NS
        ;; Selection required
        bit     selected_index
        bmi     _ReturnNotAllowed ; no selection

        .assert kSelectionRequiredNoDirs & $40 = $00, error, "enum mismatch"
        .assert kSelectionRequiredDirsOK & $40 = $40, error, "enum mismatch"

        ;; bit6 = dirs ok?
        bit     selection_requirement_flags
        bvs     _ReturnAllowed  ; dirs ok
        jsr     _IsOpenAllowed  ; C=0 if open allowed
        bcc     _ReturnNotAllowed ; but we want the inverse
        bcs     _ReturnAllowed    ; always
    END_IF

        ;; No selection required
        .assert kSelectionOptional           & $40 = $00, error, "enum mismatch"
        .assert kSelectionOptionalUnlessRoot & $40 = $40, error, "enum mismatch"

        ;; bit6 = root w/ no selection ok?
        bvc     _ReturnAllowed

        ;; selection required if not root
        bit     selected_index
        bmi     _IsCloseAllowed ; no selection, so only if not root
        bpl     _ReturnAllowed  ; always
.endproc ; _IsOKAllowed

;;; ============================================================

.proc _DoClose
        jsr     _IsCloseAllowed
    IF CC
        ;; Remove last segment
        jsr     _StripPathBufSegment

        lda     path_buf
      IF ZERO
        jsr     _SetRootPath
      END_IF

        jsr     UpdateListFromPath
    END_IF

        rts
.endproc ; _DoClose

;;; ============================================================
;;; Key handler

.proc HandleKey
        lda     event_params+MGTK::Event::key
        ldx     event_params+MGTK::Event::modifiers
        sta     file_dialog_res::lb_params::key
        stx     file_dialog_res::lb_params::modifiers

    IF A IN #CHAR_UP, #CHAR_DOWN
        jsr     ResetTypeDown
        LBTK_CALL LBTK::Key, file_dialog_res::lb_params
        rts
    END_IF

    IF X <> #0
        ;; With modifiers
        jsr     CheckTypeDown
        jeq     exit

        jsr     ResetTypeDown
        ldx     event_params+MGTK::Event::modifiers
        lda     event_params+MGTK::Event::key
    ELSE
        ;; --------------------------------------------------
        ;; No modifiers

        jsr     CheckTypeDown
        jeq     exit

        jsr     ResetTypeDown
        lda     event_params+MGTK::Event::key

      IF A = #CHAR_RETURN
        BTK_CALL BTK::Flash, file_dialog_res::ok_button
        RTS_IF NS
        jmp     HandleOK
      END_IF

      IF A = #CHAR_ESCAPE
        BTK_CALL BTK::Flash, file_dialog_res::cancel_button
        ;; always enabled
        jmp     HandleCancel
      END_IF

      IF A = #CHAR_CTRL_O
        BTK_CALL BTK::Flash, file_dialog_res::open_button
        RTS_IF NS
        jmp     _DoOpen
      END_IF

      IF A = #CHAR_CTRL_D
        BTK_CALL BTK::Flash, file_dialog_res::drives_button
        ;; always enabled
        jmp     _DoDrives
      END_IF

      IF A = #CHAR_CTRL_C
        jsr     _IsCloseAllowed
        RTS_IF NS
        jmp     _DoClose
      END_IF

    END_IF

exit:   rts
.endproc ; HandleKey

;;; ============================================================

.proc ResetTypeDown
        copy8   #0, type_down_buf
        rts
.endproc ; ResetTypeDown

;;; ============================================================

;;; Output: Z=1 if consumed, Z=0 otherwise
.proc CheckTypeDown
        CALL    _ToUpperCase, A=event_params+MGTK::Event::key
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
        RETURN  A=#$FF

file_char:
        ldx     type_down_buf
        RTS_IF X = #kMaxFilenameLength ; Z=1 to consume

        inx
        stx     type_down_buf
        sta     type_down_buf,x

        jsr     _FindMatch
    IF NC
      IF A <> selected_index
        sta     file_dialog_res::lb_params::new_selection
        LBTK_CALL LBTK::SetSelection, file_dialog_res::lb_params
        jsr     _UpdateDynamicButtons
      END_IF
    END_IF

        RETURN  A=#0

.proc _FindMatch
        lda     num_file_names
    IF ZERO
        RETURN  A=#$FF
    END_IF

        copy8   #0, index
    DO
        index := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     _GetFilenameForIndex
        stax    $06

        ldy     #0
        lda     ($06),y
        sta     len

        ;; compare strings (length >= 1)
cloop:  iny
        CALL    _ToUpperCase, A=($06),y
        cmp     type_down_buf,y
        bcc     next
        beq     :+
        bcs     found
:
        cpy     type_down_buf
        beq     found

        len := *+1
        cpy     #SELF_MODIFIED_BYTE
        bcc     cloop

next:   inc     index
        lda     index
    WHILE A <> num_file_names
        dec     index
found:  RETURN  A=index

.endproc ; _FindMatch

.endproc ; CheckTypeDown

;;; ============================================================

;;; Input: A = index (must be valid, not -1)
;;; Output: A,X = filename
.proc _GetFilenameForIndex
        tax
        lda     file_list_index,x
        and     #$7F
        FALL_THROUGH_TO _GetNthFilename
.endproc ; _GetFilenameForIndex

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
    IF A <> file_dialog_res::ok_button::state
        sta     file_dialog_res::ok_button::state
        BTK_CALL BTK::Hilite, file_dialog_res::ok_button
    END_IF

        ;; --------------------------------------------------
        ;; Open
        jsr     _IsOpenAllowed
        lda     #0
        ror                     ; C into high bit
        ASSERT_EQUALS BTK::kButtonStateDisabled, $80
    IF A <> file_dialog_res::open_button::state
        sta     file_dialog_res::open_button::state
        BTK_CALL BTK::Hilite, file_dialog_res::open_button
    END_IF

        ;; --------------------------------------------------
        ;; Close
        jsr     _IsCloseAllowed
        lda     #0
        ror                     ; C into high bit
        ASSERT_EQUALS BTK::kButtonStateDisabled, $80
    IF A <> file_dialog_res::close_button::state
        sta     file_dialog_res::close_button::state
        BTK_CALL BTK::Hilite, file_dialog_res::close_button
    END_IF

        rts
.endproc ; _UpdateDynamicButtons

;;; ============================================================

.proc NoOp
        rts
.endproc ; NoOp

;;; ============================================================

.proc OpenWindow
        ;; Pointers we'll need later
        stax    winfo_ptr

        ptr := $06
        stax    ptr
        ldy     #MGTK::Winfo::title
        lda     (ptr),y
        pha
        iny
        lda     (ptr),y
        pha

        ;; List box position
        ldy     #MGTK::Winfo::port+MGTK::GrafPort::viewloc
        add16in (ptr),y, #file_dialog_res::kListBoxLeft, file_dialog_res::winfo_listbox::port+MGTK::GrafPort::viewloc+MGTK::Point::xcoord
        iny
        add16in (ptr),y, #file_dialog_res::kListBoxTop, file_dialog_res::winfo_listbox::port+MGTK::GrafPort::viewloc+MGTK::Point::ycoord

        ;; Frame rect size
        ldy     #MGTK::Winfo::port+MGTK::GrafPort::maprect+MGTK::Rect::bottomright
        sub16in (ptr),y, #kBorderDX*2-1, file_dialog_res::dialog_frame_rect::x2
        iny
        sub16in (ptr),y, #kBorderDY*2-1, file_dialog_res::dialog_frame_rect::y2

        ;; Open and decorate the window

        MGTK_CALL MGTK::OpenWindow, SELF_MODIFIED, winfo_ptr

        MGTK_CALL MGTK::GetWinPort, file_dialog_res::fd_getwinport_params
        MGTK_CALL MGTK::SetPort, file_dialog_res::grafport

        MGTK_CALL MGTK::SetPenMode, file_dialog_res::notpencopy
        MGTK_CALL MGTK::SetPenSize, file_dialog_res::pensize_frame
        MGTK_CALL MGTK::FrameRect, file_dialog_res::dialog_frame_rect
        MGTK_CALL MGTK::SetPenSize, file_dialog_res::pensize_normal

        ;; Draw title
        copy16  file_dialog_res::grafport+MGTK::GrafPort::maprect+MGTK::Rect::x2, file_dialog_res::pos_title::xcoord
        lsr16   file_dialog_res::pos_title::xcoord ; /= 2
        MGTK_CALL MGTK::MoveTo, file_dialog_res::pos_title

        plax                    ; AX=title of passed Winfo
        jsr     _DrawStringCentered

        ;; Buttons
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

        ;; Separator between button groups
        MGTK_CALL MGTK::SetPenMode, file_dialog_res::notpencopy
        MGTK_CALL MGTK::SetPattern, file_dialog_res::checkerboard_pattern
        MGTK_CALL MGTK::MoveTo, file_dialog_res::button_sep_start
        MGTK_CALL MGTK::LineTo, file_dialog_res::button_sep_end

        ;; List box
        lda     #MGTK::Scroll::option_present | MGTK::Scroll::option_thumb
        sta     file_dialog_res::winfo_listbox::vscroll
        MGTK_CALL MGTK::OpenWindow, file_dialog_res::winfo_listbox

        rts
.endproc ; OpenWindow

;;; ============================================================

.proc CloseWindow
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo_listbox
        MGTK_CALL MGTK::CloseWindow, file_dialog_res::winfo ; Valid even if another winfo used
        rts
.endproc ; CloseWindow

;;; ============================================================

.proc _DrawStringCentered
        params := $06
        str := params
        width := params+2

        stax    str
        stax    @addr
        MGTK_CALL MGTK::StringWidth, params
        lsr16   width
        sub16   #0, width, params+MGTK::Point::xcoord
        copy16  #0, params+MGTK::Point::ycoord
        MGTK_CALL MGTK::Move, params
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        rts
.endproc ; _DrawStringCentered

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

found:  CALL    AdjustOnLineEntryCase, AX=#on_line_buffer
        jsr     _SetRootPath
        TAIL_CALL _AppendToPathBuf, AX=#on_line_buffer
.endproc ; InitPathWithDefaultDevice

;;; Input: AX = path
.proc InitPath
        ldy     #0
        sty     path_buf
        beq     _AppendToPathBuf ; always
.endproc ; InitPath

;;; ============================================================
;;; Assert: `selected_index` is valid (not -1)

.proc _AppendSelectedFilename
        lda     selected_index
        jsr     _GetFilenameForIndex
        FALL_THROUGH_TO _AppendToPathBuf
.endproc ; _AppendSelectedFilename

;;; ============================================================

;;; Appends filename at A,X to `path_buf`
;;; Output: C=0 on success, C=1 and path unchanged if too long

.proc _AppendToPathBuf
        ptr := $06
        stax    ptr

        ldx     path_buf
    IF X >= #2                  ; 0 = use full path, 1 = is root
        lda     #'/'
        sta     path_buf+1,x
        inc     path_buf
    END_IF

        ldy     #0
        lda     (ptr),y
        tay
        clc
        adc     path_buf

        ;; Enough room?
        cmp     #kPathBufferSize
    IF GE
        dec     path_buf
        rts                     ; C=1 failure
    END_IF

        pha
        tax
    DO
        lda     (ptr),y
        sta     path_buf,x
        dey
        dex
    WHILE X <> path_buf

        pla
        sta     path_buf

        RETURN  C=0             ; C=0 success
.endproc ; _AppendToPathBuf

;;; ============================================================

.proc _StripPathBufSegment
    DO
        ldx     path_buf
        BREAK_IF ZERO
        dec     path_buf
        lda     path_buf,x
    WHILE A <> #'/'
        rts
.endproc ; _StripPathBufSegment

;;; ============================================================

.proc _ReadDir
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch

        jsr     _IsRootPath
        jeq     _ReadDrives

        MLI_CALL OPEN, open_params
        bcs     err
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        MLI_CALL READ, read_params
    IF CS
err:    jsr     _SetRootPath
        jmp     _ReadDrives
    END_IF

        lda     #0
        sta     entry_index
        lda     #1
        sta     entry_in_block
        copy8   dir_read_buf+SubdirectoryHeader::entry_length, entry_length
        copy8   dir_read_buf+SubdirectoryHeader::entries_per_block, entries_per_block
        lda     dir_read_buf+SubdirectoryHeader::file_count
        and     #$7F            ; TODO: max of 128 entries, but this is still weird
        sta     num_file_names
        beq     close

        ptr := $06
        copy16  #dir_read_buf+.sizeof(SubdirectoryHeader), ptr

do_entry:
        CALL    AdjustFileEntryCase, AX=ptr

        ldy     #FileEntry::storage_type_name_length
        lda     (ptr),y
        and     #NAME_LENGTH_MASK
        beq     done_entry      ; deleted entry

        ldx     entry_index
        txa
        sta     file_list_index,x

        ;; Invisible?
        CALL    ReadSetting, X=#DeskTopSettings::options
        and     #DeskTopSettings::kOptionsShowInvisible
    IF ZERO
        ldy     #FileEntry::access
        lda     (ptr),y
        and     #ACCESS_I
      IF NOT_ZERO
        dec     num_file_names  ; invisible, so skip
        jmp     done_entry
      END_IF
    END_IF

        ;; Directory?
        ldy     #FileEntry::storage_type_name_length
        lda     (ptr),y
        and     #STORAGE_TYPE_MASK
        cmp     #ST_LINKED_DIRECTORY << 4
        beq     is_dir

        bit     only_show_dirs_flag
        bpl     not_dir         ; not dir, but show
        dec     num_file_names  ; not dir, so skip
        jmp     done_entry

        ;; Flag as "is dir"
is_dir:
        ldx     entry_index
        lda     file_list_index,x
        ora     #$80
        sta     file_list_index,x

not_dir:
        ldy     #FileEntry::storage_type_name_length
        lda     (ptr),y
        and     #NAME_LENGTH_MASK
        sta     (ptr),y

        CALL    _CopyIntoNthFilename, A=entry_index

        inc     entry_index

done_entry:
        inc     entry_in_block
        lda     entry_index
        cmp     num_file_names
        bne     next

close:  MLI_CALL CLOSE, close_params
        jsr     _SortFileNames
        jsr     _SetCursorPointer
        RETURN  C=0

next:   lda     entry_in_block
    IF A <> entries_per_block
        add16_8 ptr, entry_length
        jmp     do_entry
    END_IF

        ;; Next block
        MLI_CALL READ, read_params
        copy16  #dir_read_buf+$04, ptr ; skip past pointers
        copy8   #0, entry_in_block
        jmp     do_entry

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

        DEFINE_ON_LINE_PARAMS on_line_drives_params, 0, dir_read_buf

.proc _ReadDrives
        MLI_CALL ON_LINE, on_line_drives_params

        ptr := $06
        copy16  #dir_read_buf, ptr

        copy8   #0, num_file_names

    REPEAT
        ldy     #0
        lda     (ptr),y         ; A = unit_num | name_len
        and     #NAME_LENGTH_MASK
      IF ZERO
        iny                     ; 0 signals error or complete
        lda     (ptr),y
        bne     next            ; error, so skip
        BREAK_IF ZERO           ; always
      END_IF

        CALL    AdjustOnLineEntryCase, AX=ptr

        CALL    _CopyIntoNthFilename, A=num_file_names


        ldx     num_file_names
        txa
        ora     #$80            ; treat as folder
        sta     file_list_index,x

        inc     num_file_names

next:   add16_8 ptr, #16        ; advance to next
    FOREVER

        jsr     _SortFileNames
        jsr     _SetCursorPointer

        RETURN  C=0
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
    DO
        lda     (src_ptr),y
        sta     (dst_ptr),y
        dey
    WHILE POS

        rts
.endproc ; _CopyIntoNthFilename

;;; ============================================================

.proc _UpdateDiskAndDirNames
        MGTK_CALL MGTK::SetPort, file_dialog_res::grafport

        copy8   #kGlyphDiskLeft, file_dialog_res::filename_buf+1
        copy8   #kGlyphDiskRight, file_dialog_res::filename_buf+2
        copy8   #kGlyphSpacer, file_dialog_res::filename_buf+3

        ;; --------------------------------------------------
        ;; Disk Name

        MGTK_CALL MGTK::SetPenMode, file_dialog_res::pencopy

        MGTK_CALL MGTK::ShieldCursor, file_dialog_res::disk_name_rect
        MGTK_CALL MGTK::PaintRect, file_dialog_res::disk_name_rect

        jsr     _IsRootPath
    IF NE
        copy16  #path_buf, $06

        ldy     #3

        ;; Copy first segment
        ldx     #2              ; skip leading slash
      DO
        lda     path_buf,x
        BREAK_IF A = #'/'
        iny
        sta     file_dialog_res::filename_buf,y
        BREAK_IF X = path_buf
        inx
      WHILE NOT_ZERO            ; always
        sty     file_dialog_res::filename_buf

        MGTK_CALL MGTK::MoveTo, file_dialog_res::disk_label_pos
        CALL    _DrawStringCentered, AX=#file_dialog_res::filename_buf
    END_IF
        MGTK_CALL MGTK::UnshieldCursor

        ;; --------------------------------------------------
        ;; Dir Name

        MGTK_CALL MGTK::ShieldCursor, file_dialog_res::disk_name_rect
        MGTK_CALL MGTK::PaintRect, file_dialog_res::dir_name_rect
        copy16  #path_buf, $06

        jsr     _IsRootPath
    IF NE
        ;; Copy last segment
        ldx     path_buf
      DO
        lda     path_buf,x
        BREAK_IF A = #'/'
        dex
      WHILE NOT_ZERO            ; always
        inx

      IF X <> #2
        copy8   #kGlyphFolderLeft, file_dialog_res::filename_buf+1
        copy8   #kGlyphFolderRight, file_dialog_res::filename_buf+2
      END_IF

        ldy     #4
      DO
        lda     path_buf,x
        sta     file_dialog_res::filename_buf,y
        BREAK_IF X = path_buf
        iny
        inx
      WHILE NOT_ZERO            ; always
        sty     file_dialog_res::filename_buf

        MGTK_CALL MGTK::MoveTo, file_dialog_res::dir_label_pos
        CALL    _DrawStringCentered, AX=#file_dialog_res::filename_buf
    END_IF
        MGTK_CALL MGTK::UnshieldCursor

        rts
.endproc ; _UpdateDiskAndDirNames

;;; ============================================================
;;; Sorts `file_list_index` so names are in ascending order
;;; Assert: On entry, `file_list_index` table is populated 0...`num_file_names`-1

.proc _SortFileNames
        lda     num_file_names
        RTS_IF A < #2           ; can't sort < 2 records

        ;; --------------------------------------------------
        ;; Selection sort

        ;; Why not Quicksort? It turns out that for the limited number
        ;; of files we have here (<= 128), with the low overhead to
        ;; access the names (simple shift and add) this can sort all
        ;; of the names in under 2 seconds even with O(n^2). In
        ;; contrast, DeskTop has more complex storage which
        ;; dramatically increases the constant overhead, so a more
        ;; efficient sort is necessary.

        ptr1 := $06
        ptr2 := $08

        ldx     num_file_names
        dex
        stx     outer
    DO
        outer := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     _GetFilenameForIndex
        stax    ptr2

        lda     #0
        sta     inner
      DO
        inner := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     _GetFilenameForIndex
        stax    ptr1

        jsr     _CompareStrings
       IF GE
        ;; Swap
        ldx     inner
        ldy     outer
        swap8   file_list_index,x, file_list_index,y

        CALL    _GetFilenameForIndex, A=outer
        stax    ptr2
       END_IF

        inc     inner
        lda     inner
      WHILE A <> outer

        dec     outer
    WHILE NOT_ZERO
        rts

.endproc ; _SortFileNames

;;; ============================================================

;;; Inputs: $06, $08 are pts to strings
;;; Compare strings at $06 (1) and $08 (2).
;;; Returns C=0 for 1<2 , C=1 for 1>=2, Z=1 for 1=2
.proc _CompareStrings
        ptr1 := $06
        ptr2 := $08

        ldy     #0
        copy8   (ptr1),y, len1
        copy8   (ptr2),y, len2
        iny
    DO
        CALL    _ToUpperCase, A=(ptr2),y
        sta     char
        CALL    _ToUpperCase, A=(ptr1),y
        char := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     ret             ; differ at Yth character

        ;; End of string 1?
        len1 := *+1
        cpy     #SELF_MODIFIED_BYTE
      IF EQ
        cpy     len2            ; 1<2 or 1=2 ?
        rts
      END_IF

        ;; End of string 2?
        len2 := *+1
        cpy     #SELF_MODIFIED_BYTE
        beq     gt              ; 1>2
        iny
    WHILE NOT_ZERO              ; always

gt:     lda     #$FF            ; Z=0
        sec
ret:    rts
.endproc ; _CompareStrings

;;; ============================================================
;;; List Box
;;; ============================================================

ASSERT_EQUALS .sizeof(file_dialog_res::listbox_rec), .sizeof(LBTK::ListBoxRecord)
num_file_names := file_dialog_res::listbox_rec::num_items
selected_index := file_dialog_res::listbox_rec::selected_index
OnListSelectionChange := _UpdateDynamicButtons

;;; ============================================================

;;; Called with A = index, X,Y = addr of drawing pos (MGTK::Point)
.proc DrawListEntryProc
        pha
        pt_ptr := $06
        stxy    pt_ptr
        ldy     #.sizeof(MGTK::Point)-1
    DO
        lda     (pt_ptr),y
        sta     file_dialog_res::item_pos,y
        dey
    WHILE POS
        pla

        tax
        lda     file_list_index,x
        pha
        and     #$7F

        jsr     _GetNthFilename
        stax    ptr
        ldx     #kMaxFilenameLength
    DO
        ptr := *+1
        lda     SELF_MODIFIED,x
        sta     file_dialog_res::filename_buf,x
        dex
    WHILE POS
        copy16  #kListViewNameX, file_dialog_res::item_pos+MGTK::Point::xcoord
        MGTK_CALL MGTK::MoveTo, file_dialog_res::item_pos
        MGTK_CALL MGTK::DrawString, file_dialog_res::filename_buf

        ;; Folder glyph?
        copy16  #kListViewIconX, file_dialog_res::item_pos+MGTK::Point::xcoord
        MGTK_CALL MGTK::MoveTo, file_dialog_res::item_pos
        pla
    IF NS
        ldax    #file_dialog_res::str_folder

        ldy     path_buf
      IF Y = #1
        ldax    #file_dialog_res::str_vol
      END_IF

    ELSE
        ldax    #file_dialog_res::str_file
    END_IF
        stax    @addr
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        rts
.endproc ; DrawListEntryProc

;;; ============================================================

.endscope ; file_dialog_impl

;;; --------------------------------------------------
;;; "Exports"
;;; --------------------------------------------------

;;; Lifecycle
Init := file_dialog_impl::Init
OpenWindow := file_dialog_impl::OpenWindow
CloseWindow := file_dialog_impl::CloseWindow
InitPath := file_dialog_impl::InitPath
InitPathWithDefaultDevice := file_dialog_impl::InitPathWithDefaultDevice
UpdateListFromPath := file_dialog_impl::UpdateListFromPath
.ifdef FD_EXTRAS
UpdateListFromPathAndSelectFile := file_dialog_impl::UpdateListFromPathAndSelectFile
.endif

GetPath := file_dialog_impl::GetPath

;;; Event Handlers
HandleKey := file_dialog_impl::HandleKey
HandleClick := file_dialog_impl::HandleClick
CheckTypeDown := file_dialog_impl::CheckTypeDown
ResetTypeDown := file_dialog_impl::ResetTypeDown

;;; Configuration
kSelectionOptional           = %00000000 ; unused
kSelectionOptionalUnlessRoot = %01000000
kSelectionRequiredNoDirs     = %10000000
kSelectionRequiredDirsOK     = %11000000
kShowAllFiles                = %00000000
kShowOnlyDirectories         = %10000000

;;; State
STATE_START := file_dialog_impl::state_start
STATE_END   := file_dialog_impl::state_end

;;; Export, since qualified name is not known by this lib/.
::file_dialog_impl__DrawListEntryProc := file_dialog_impl::DrawListEntryProc
::file_dialog_impl__OnListSelectionChange := file_dialog_impl::OnListSelectionChange

