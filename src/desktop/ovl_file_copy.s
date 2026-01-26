;;; ============================================================
;;; Overlay for File Copy
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

        BEGINSEG OverlayFileCopy

.scope FileCopyOverlay

.proc Run
        ;; Save stack
        tsx
        stx     saved_stack

        ;; Init the dialog, set title
        CALL    file_dialog::Init, A=#file_dialog::kSelectionOptionalUnlessRoot, X=#file_dialog::kShowOnlyDirectories
        copy16  #label_copy_selection, file_dialog_res::winfo::title

        ;; Dynamic callbacks
        COPY_BYTES file_dialog::kJumpTableSize, jt_callbacks, file_dialog::jump_table

        ;; Open the dialog
        CALL    file_dialog::OpenWindow, AX=#file_dialog_res::winfo

        ;; Set the path
        jsr     file_dialog::InitPathWithDefaultDevice
        jsr     file_dialog::UpdateListFromPath

        FALL_THROUGH_TO EventLoop
.endproc ; Run

.proc EventLoop
        jsr     SystemTask
        jsr     GetNextEvent

    IF A = #MGTK::EventKind::key_down
        jsr     file_dialog::HandleKey
    ELSE_IF A = #MGTK::EventKind::button_down
        jsr     file_dialog::HandleClick
    ELSE_IF A <> #MGTK::EventKind::no_event
        jsr     file_dialog::ResetTypeDown
    END_IF

        jmp     EventLoop
.endproc ; EventLoop

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
