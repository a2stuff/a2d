;;; ============================================================
;;; Overlay for File Copy
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

        BEGINSEG OverlayFileCopy

.scope FileCopyOverlay

.proc Run
        tsx
        stx     saved_stack

        jsr     file_dialog::Init
        SET_BIT7_FLAG file_dialog::only_show_dirs_flag
        copy8   #file_dialog::kSelectionOptionalUnlessRoot, file_dialog::selection_requirement_flags

        CALL    file_dialog::OpenWindow, AX=#label_copy_selection
        jsr     file_dialog::InitPathWithDefaultDevice
        jsr     file_dialog::UpdateListFromPath
        COPY_BYTES file_dialog::kJumpTableSize, jt_callbacks, file_dialog::jump_table

        jmp     file_dialog::EventLoop
.endproc ; Run

saved_stack:
        .byte   0

jt_callbacks:
        jmp     HandleOK
        jmp     HandleCancel
        .assert * - jt_callbacks = file_dialog::kJumpTableSize, error, "Table size error"

;;; ============================================================

.proc HandleOK
        CALL    file_dialog::GetPath, AX=#path_buf0

        jsr     file_dialog::CloseWindow
        copy16  #path_buf0, $6
        ldx     saved_stack
        txs
        RETURN  A=#$00
.endproc ; HandleOK

;;; ============================================================

.proc HandleCancel
        jsr     file_dialog::CloseWindow
        ldx     saved_stack
        txs
        RETURN  A=#$FF
.endproc ; HandleCancel

;;; ============================================================

.endscope ; FileCopyOverlay

        ENDSEG OverlayFileCopy
