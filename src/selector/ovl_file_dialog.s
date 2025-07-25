;;; ============================================================
;;; Run a Program File Picker Dialog - Overlay #1
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        BEGINSEG OverlayFileDialog

.scope file_dialog
        .org ::OVERLAY_ADDR

        BTKEntry := app::BTKEntry
        LBTKEntry := app::LBTKEntry

;;; ============================================================

ep_init:
        tsx
        stx     saved_stack

        copy8   #$80, require_selection_flag
        jsr     Init
        param_call OpenWindow, app::str_run_a_program
        jsr     InitPathWithDefaultDevice
        jsr     UpdateListFromPath
        jmp     EventLoop

;;; ============================================================


ep_loop:
        jmp     EventLoop

;;; ============================================================

buf_path:
        .res    ::kPathBufferSize, 0

saved_stack:
        .byte   0

;;; ============================================================
;;; File Picker Dialog

        .include "../lib/file_dialog_res.s"

;;; ============================================================

.proc HandleOK
        param_call GetPath, buf_path

        ldx     saved_stack
        txs
        ldy     #<buf_path
        ldx     #>buf_path
        return  #$00
.endproc ; HandleOK

;;; ============================================================

.proc HandleCancel
        jsr     CloseWindow
        ldx     saved_stack
        txs
        return  #$FF
.endproc ; HandleCancel

;;; ============================================================

;;; Required proc definitions:
SystemTask              := app::SystemTask
DetectDoubleClick       := app::DetectDoubleClick
AdjustOnLineEntryCase   := app::AdjustOnLineEntryCase
AdjustFileEntryCase     := app::AdjustFileEntryCase
ReadSetting             := app::ReadSetting

        .include "../lib/file_dialog.s"
        .include "../lib/get_next_event.s"

;;; ============================================================

.endscope ; file_dialog

file_dialog_init   := file_dialog::ep_init
file_dialog_loop   := file_dialog::ep_loop

;;; ============================================================

;;; File Dialog and Alerts compete over "save area" (main $800-$1FFF)
;;; so allow preserving the state while an alert is shown.

.proc SaveFileDialogState
        sec                          ; main>aux
        bcs     _MoveFileDialogState ; always
.endproc ; SaveFileDialogState

.proc RestoreFileDialogState
        clc                          ; aux>main
        FALL_THROUGH_TO _MoveFileDialogState
.endproc ; RestoreFileDialogState

;;; C set by caller
.proc _MoveFileDialogState
        pha
        txa
        pha
        tya
        pha

        copy16  #file_dialog::STATE_START, STARTLO
        copy16  #file_dialog::STATE_END, ENDLO
        copy16  #file_dialog::STATE_START, DESTINATIONLO
        jsr     AUXMOVE

        pla
        tay
        pla
        tax
        pla

        rts
.endproc ; _MoveFileDialogState

;;; ============================================================

        ENDSEG OverlayFileDialog
        .assert * <= $BF00, error, "Overwrites ProDOS Global Page"
