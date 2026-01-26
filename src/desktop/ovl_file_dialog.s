;;; ============================================================
;;; Overlay for File Dialog (used by Copy/Add/Edit)
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

        BEGINSEG OverlayFileDialog

.scope file_dialog

        MLIEntry := main::MLIRelayImpl
        MGTKEntry := MGTKRelayImpl
        LETKEntry := LETKRelayImpl
        BTKEntry := BTKRelayImpl
        LBTKEntry := LBTKRelayImpl

;;; ============================================================

        FD_EXTRAS = 1
        .include "../lib/file_dialog.s"

kJumpTableSize = 6
jump_table:
HandleOK:       jmp     0
HandleCancel:   jmp     0
        ASSERT_EQUALS * - jump_table, kJumpTableSize

;;; ============================================================

.endscope ; file_dialog

        ENDSEG OverlayFileDialog
