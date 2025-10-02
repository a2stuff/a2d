;;; ============================================================
;;; Recursive File Copy - Overlay #2
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        BEGINSEG OverlayCopyDialog

.scope file_copier

        AdjustFileEntryCase := app::AdjustFileEntryCase

;;; Called with `INVOKER_PREFIX` set to path of entry to copy
.proc Exec
        jsr     OpenWindow

        jsr     PrepSrcAndDstPaths
        jsr     EnumerateFiles
        bne     skip

        jsr     DrawWindowContent

        jsr     PrepSrcAndDstPaths
        jsr     CopyFiles

skip:
        pha
        jsr     CloseWindow
        pla

        rts
.endproc ; Exec

;;; ============================================================
;;; Recursive Enumerate & Copy Logic
;;; ============================================================

;;;          |             |
;;;          | Code        |
;;;   $2000  +-------------+
;;;          |.............|
;;;          |.(unused)....|
;;;   $1F00  +-------------+
;;;          |             |
;;;          | R/W Buffer  |
;;;   $1500  +-------------+
;;;          |             |
;;;          | Dst IO Buf  |
;;;   $1100  +-------------+
;;;          |             |
;;;          | Src I/O Buf |
;;;    $D00  +-------------+
;;;          |.(unused)....|
;;;    $C00  +-------------+
;;;          |             |
;;;          | Dir I/O Buf |
;;;    $800  +-------------+
;;;          :             :

;;; --------------------------------------------------
;;; Required identifiers:
;;; --------------------------------------------------

dir_io_buffer :=  $800  ; 1024 bytes for I/O
src_io_buffer :=  $D00  ; 1024 bytes for I/O
dst_io_buffer := $1100  ; 1024 bytes for I/O
copy_buffer   := $1500  ; Read/Write buffer

kCopyBufferSize = $A00

;;; Since this is only ever "copy to RAMCard" / "on use" we assume it
;;; is okay if it already exists.
::kCopyIgnoreDuplicateErrorOnCreate = 1

;;; --------------------------------------------------
;;; Callbacks
;;; --------------------------------------------------

;;; Jump table - populated by operation
op_jt_addrs:
op_jt_addr1:  .addr   CopyProcessDirectoryEntry
op_jt_addr2:  .addr   RemoveDstPathSegment
op_jt_addr3:  .addr   NoOp
kOpJTSize = * - op_jt_addrs

OpCheckCancel     := CheckCancel
OpInsertSource    := ShowInsertSourceDiskPrompt
OpHandleErrorCode := HandleErrorCode
OpHandleNoSpace   := ShowDiskFullError
OpUpdateProgress  := UpdateWindowContent

OpProcessDirectoryEntry:
        jmp     (op_jt_addr1)
OpResumeDirectory:
        jmp     (op_jt_addr2)
OpFinishDirectory:
        jmp     (op_jt_addr3)

;;; --------------------------------------------------
;;; Library
;;; --------------------------------------------------

        .include "../lib/recursive_copy.s"

;;; ============================================================
;;; Copy Specialization
;;; ============================================================

;;; Jump table for `CopyFiles`
copy_jt:
        .addr   CopyProcessDirectoryEntry ; callback for `OpProcessDirectoryEntry`
        .addr   RemoveDstPathSegment      ; callback for `OpResumeDirectory`
        .addr   NoOp                      ; callback for `OpFinishDirectory`

;;; ============================================================
;;; Paths for overall copy operation

dst_path:       .res    64, 0
src_path:       .res    64, 0
filename:       .res    16, 0

src_path_slash_index:           ; TODO: Written but never read?
        .byte   0

saved_stack:
        .byte   0

        DEFINE_CLOSE_PARAMS close_everything_params ; used in case of error

;;; ============================================================

.proc CopyFiles
        ;; Prepare jump table
        ldy     #kOpJTSize-1
    DO
        copy8   copy_jt,y, op_jt_addrs,y
        dey
    WHILE_POS

        tsx
        stx     saved_stack

        jsr     CopyPathsFromBufsToSrcAndDst
        MLI_CALL GET_FILE_INFO, get_dst_file_info_params
    IF_CS
        jmp     HandleErrorCode
    END_IF

        blocks := $06

        ;; Is there enough space?
        sub16   get_dst_file_info_params::aux_type, get_dst_file_info_params::blocks_used, blocks
        cmp16   blocks, blocks_total
    IF_LT
        jmp     ShowDiskFullError
    END_IF

        ;; Append `filename` to `pathname_dst`
        ldx     pathname_dst
        copy8   #'/', pathname_dst+1,x
        inc     pathname_dst
        ldy     #0
        ldx     pathname_dst
    DO
        iny
        inx
        copy8   filename,y, pathname_dst,x
    WHILE_Y_NE filename
        stx     pathname_dst

        jmp     DoCopy
.endproc ; CopyFiles

;;; ============================================================
;;; Enumeration Specialization
;;; ============================================================

;;; Jump table for `EnumerateFiles`
enum_jt:
        .addr   EnumerateVisitFile ; callback for `OpProcessDirectoryEntry`
        .addr   NoOp               ; callback for `OpResumeDirectory`
        .addr   NoOp               ; callback for `OpFinishDirectory`

;;; ============================================================
;;; Initially populated during enumeration, used during copy for UI
;;; updates.

file_count:
        .word   0
total_count:
        .word   0
blocks_total:
        .word   0

;;; ============================================================

.proc EnumerateFiles
        ;; Prepare jump table
        ldy     #kOpJTSize-1
    DO
        copy8   enum_jt,y, op_jt_addrs,y
        dey
    WHILE_POS

        tsx
        stx     saved_stack

        lda     #$00
        sta     file_count
        sta     file_count+1
        sta     blocks_total
        sta     blocks_total+1

        jsr     CopyPathsFromBufsToSrcAndDst
retry:  MLI_CALL GET_FILE_INFO, get_src_file_info_params
    IF_CS
      IF_A_EQ_ONE_OF #ERR_VOL_NOT_FOUND, #ERR_FILE_NOT_FOUND
        jsr     ShowInsertSourceDiskPrompt
        jmp     retry
      END_IF
        jmp     HandleErrorCode
    END_IF

        copy8   get_src_file_info_params::storage_type, storage_type
        cmp     #ST_VOLUME_DIRECTORY
        beq     is_dir
        cmp     #ST_LINKED_DIRECTORY
        beq     is_dir
        lda     #$00
        beq     set
is_dir: lda     #$FF
set:    sta     is_dir_flag
        beq     visit
        jsr     ProcessDirectory

        lda     storage_type
    IF_A_EQ     #ST_VOLUME_DIRECTORY
        ;; If copying a volume dir to RAMCard, the volume dir
        ;; will not be counted as a file during enumeration but
        ;; will be counted during copy, so include it to avoid
        ;; off-by-one.
        ;; https://github.com/a2stuff/a2d/issues/564
        inc16   file_count
        jsr     UpdateFileCountDisplay
        return  #0

        ;; TODO: Move these somewhere more sensible.
is_dir_flag:
        .byte   0               ; TODO: Written but never read?
storage_type:
        .byte   0               ; TODO: Move inline/SMC
    END_IF

visit:  jsr     EnumerateVisitFile
        return  #0
.endproc ; EnumerateFiles

;;; ============================================================

.proc EnumerateVisitFile
        jsr     AppendFileEntryToSrcPath
        ;; TODO: We have the `FileEntry`, just use `FileEntry::blocks_used`!
        MLI_CALL GET_FILE_INFO, get_src_file_info_params
    IF_CC
        add16   blocks_total, get_src_file_info_params::blocks_used, blocks_total
    END_IF
        inc16   file_count
        jsr     RemoveSrcPathSegment
        jmp     UpdateFileCountDisplay
.endproc ; EnumerateVisitFile

;;; ============================================================
;;; Common Logic
;;; ============================================================
;;; Used by both `EnumerateFiles` and `CopyFiles` to prepare
;;; for the operations.

;;; ============================================================
;;; Copy `src_path` to `pathname_src` and `dst_path` to `pathname_dst`
;;; and note last '/' in src.

.proc CopyPathsFromBufsToSrcAndDst
        ldy     #0
        sta     src_path_slash_index
        dey

        ;; Copy `src_path` to `pathname_src`
        ;; ... but record index of last '/'
    DO
        iny
        lda     src_path,y
      IF_A_EQ   #'/'
        sty     src_path_slash_index
      END_IF
        sta     pathname_src,y
    WHILE_Y_NE  src_path

        ;; Copy `dst_path` to `pathname_dst`
        ldy     dst_path
    DO
        copy8   dst_path,y, pathname_dst,y
        dey
    WHILE_POS

        rts
.endproc ; CopyPathsFromBufsToSrcAndDst

;;; ============================================================
;;; Input: `INVOKER_PREFIX` has path to copy

.proc PrepSrcAndDstPaths
        COPY_STRING INVOKER_PREFIX, src_path

        ldy     src_path
    DO
        lda     src_path,y
        BREAK_IF_A_EQ #'/'
        dey
    WHILE_NOT_ZERO
        dey
        sty     src_path

    DO
        lda     src_path,y
        BREAK_IF_A_EQ #'/'
        dey
    WHILE_POS

        ldx     #0
    DO
        iny
        inx
        copy8   src_path,y, filename,x
    WHILE_Y_NE  src_path
        stx     filename

        param_call app::CopyRAMCardPrefix, dst_path

        rts
.endproc ; PrepSrcAndDstPaths

;;; ============================================================
;;; Copy Progress UI
;;; ============================================================

.params winfo
        kWindowId = $0B
        kWidth = 350
        kHeight = 70
window_id:      .byte   kWindowId
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
mincontwidth:   .word   150
mincontheight:  .word   50
maxcontwidth:   .word   500
maxcontheight:  .word   140
port:
        DEFINE_POINT viewloc, 100, 50
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kWidth, kHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

        DEFINE_RECT_FRAME rect_frame, winfo::kWidth, winfo::kHeight

        DEFINE_LABEL download, res_string_label_download, 116, 16

        kProgressDialogDefaultX = 20
        kProgressDialogPathLeft = 100
        kProgressDialogPathWidth = winfo::kWidth - kProgressDialogPathLeft - kProgressDialogDefaultX

        DEFINE_POINT pos_copying, kProgressDialogDefaultX, 32
        DEFINE_POINT pos_path, kProgressDialogPathLeft, 32
        DEFINE_POINT pos_remaining, kProgressDialogDefaultX, 45

str_copying:
        PASCAL_STRING res_string_label_copying

        DEFINE_RECT rect_clear_count, 18, 24, winfo::kWidth-kBorderDX*2, 32
        DEFINE_RECT rect_clear_details, kBorderDX*2, 24, winfo::kWidth-kBorderDX*2, winfo::kHeight-kBorderDY*2

str_files_to_copy:
        PASCAL_STRING res_string_label_files_to_copy
str_files_remaining:
        PASCAL_STRING res_string_label_files_remaining
str_spaces:
        PASCAL_STRING "    "
str_from_int:
        PASCAL_STRING "000,000"

        kProgressBarTop = 51
        kProgressBarInset = 20
        kProgressBarWidth = winfo::kWidth - kProgressBarInset*2
        kProgressBarHeight = 7
        DEFINE_RECT_SZ progress_frame, kProgressBarInset-1, kProgressBarTop-1, kProgressBarWidth+2, kProgressBarHeight+2
        DEFINE_RECT_SZ progress_meter, kProgressBarInset, kProgressBarTop,  kProgressBarWidth,kProgressBarHeight

progress_pattern:
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001


;;; ============================================================

.proc OpenWindow
        MGTK_CALL MGTK::OpenWindow, winfo
        lda     #winfo::kWindowId
        jsr     app::GetWindowPort

        MGTK_CALL MGTK::SetPenMode, app::notpencopy
        MGTK_CALL MGTK::SetPenSize, app::pensize_frame
        MGTK_CALL MGTK::FrameRect, rect_frame
        MGTK_CALL MGTK::SetPenSize, app::pensize_normal

        MGTK_CALL MGTK::MoveTo, download_label_pos
        param_call DrawString, download_label_str
        rts
.endproc ; OpenWindow

;;; ============================================================

.params progress_muldiv_params
number:         .word   kProgressBarWidth ; (in) constant
numerator:      .word   0                 ; (in) populated dynamically
denominator:    .word   0                 ; (in) populated dynamically
result:         .word   0                 ; (out)
remainder:      .word   0                 ; (out)
.endparams

.proc DrawWindowContent
        lda     #winfo::kWindowId
        jsr     app::GetWindowPort
        MGTK_CALL MGTK::PaintRect, rect_clear_details

        MGTK_CALL MGTK::SetPenMode, app::notpencopy
        MGTK_CALL MGTK::FrameRect, progress_frame

        copy16  file_count, total_count
        FALL_THROUGH_TO UpdateWindowContent
.endproc

.proc UpdateWindowContent
        dec     file_count
        lda     file_count
    IF_A_EQ     #$FF
        dec     file_count+1
    END_IF

        lda     #winfo::kWindowId
        jsr     app::GetWindowPort

        ldax    file_count
        jsr     IntToString
        MGTK_CALL MGTK::PaintRect, rect_clear_count
        MGTK_CALL MGTK::MoveTo, pos_copying
        param_call DrawString, str_copying
        MGTK_CALL MGTK::MoveTo, pos_path
        COPY_STRING pathname_src, display_path
        param_call DrawDialogPath, display_path
        MGTK_CALL MGTK::MoveTo, pos_remaining
        param_call DrawString, str_files_remaining
        param_call DrawString, str_from_int
        param_call DrawString, str_spaces

        sub16   total_count, file_count, progress_muldiv_params::numerator
        copy16  total_count, progress_muldiv_params::denominator
        MGTK_CALL MGTK::MulDiv, progress_muldiv_params
        add16   progress_muldiv_params::result, progress_meter::x1, progress_meter::x2
        MGTK_CALL MGTK::SetPattern, progress_pattern
        MGTK_CALL MGTK::PaintRect, progress_meter

        rts

;;; Copy of `pathname_src` modified for display
display_path:
        .res    ::kPathBufferSize, 0
.endproc ; UpdateWindowContent

;;; ============================================================

.proc UpdateFileCountDisplay
        lda     #winfo::kWindowId
        jsr     app::GetWindowPort

        ldax    file_count
        jsr     IntToString
        MGTK_CALL MGTK::MoveTo, pos_copying
        param_call DrawString, str_files_to_copy
        param_call DrawString, str_from_int
        param_jump DrawString, str_spaces
.endproc ; UpdateFileCountDisplay

;;; ============================================================

.proc ShowInsertSourceDiskPrompt
        lda     #AlertID::insert_source_disk
        jsr     app::ShowAlert
        .assert kAlertResultCancel <> 0, error, "Branch assumes enum value"
    IF_ZERO                         ; `kAlertResultCancel` = 1
        jmp     app::SetCursorWatch ; try again
    END_IF
        jmp     RestoreStackAndReturn
.endproc ; ShowInsertSourceDiskPrompt

;;; ============================================================

.proc ShowDiskFullError
        lda     #AlertID::not_enough_room
        jsr     app::ShowAlert
        jmp     RestoreStackAndReturn
.endproc ; ShowDiskFullError

;;; ============================================================

.proc HandleErrorCode
        lda     #AlertID::copy_incomplete
        jsr     app::ShowAlert
        FALL_THROUGH_TO RestoreStackAndReturn
.endproc ; HandleErrorCode

;;; ============================================================

.proc RestoreStackAndReturn
        MLI_CALL CLOSE, close_everything_params
        ldx     saved_stack
        txs
        return  #$FF
.endproc ; RestoreStackAndReturn

;;; ============================================================

.proc CloseWindow
        MGTK_CALL MGTK::CloseWindow, winfo
        rts
.endproc ; CloseWindow

;;; ============================================================

;;; Aborts if Escape key is down
.proc CheckCancel
        MGTK_CALL MGTK::GetEvent, app::event_params
        lda     app::event_params::kind
    IF_A_EQ     #MGTK::EventKind::key_down
        lda     app::event_params::key
        cmp     #CHAR_ESCAPE
        beq     RestoreStackAndReturn
    END_IF

        rts
.endproc ; CheckCancel

;;; ============================================================

        .include "../lib/drawdialogpath.s"

        ReadSetting := app::ReadSetting
        .include "../lib/inttostring.s"
        .include "../lib/drawstring.s"

;;; ============================================================

.endscope ; file_copier

file_copier__Exec   := file_copier::Exec

        ENDSEG OverlayCopyDialog
