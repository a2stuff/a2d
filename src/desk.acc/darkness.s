;;; ============================================================
;;; DARKNESS - Desk Accessory
;;;
;;; Paints the screen a dark pattern... and leaves it that way.
;;; For ensuring repaints are minimal. Best used bound to a
;;; menu item in Shortcuts and triggered with a shortcut key.
;;; ============================================================

        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

        DEFINE_RECT rect, 0, 0, kScreenWidth - 1, kScreenHeight - 1

pattern:
        .byte   %10001000
        .byte   %00000000
        .byte   %00100010
        .byte   %00000000
        .byte   %10001000
        .byte   %00000000
        .byte   %00100010
        .byte   %00000000

pencopy:
        .byte   MGTK::pencopy

grafport:
        .tag    MGTK::GrafPort

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT

;;; ============================================================

.proc Init
        JUMP_TABLE_MGTK_CALL MGTK::InitPort, aux::grafport
        JUMP_TABLE_MGTK_CALL MGTK::SetPort, aux::grafport
        JUMP_TABLE_MGTK_CALL MGTK::HideCursor
        JUMP_TABLE_MGTK_CALL MGTK::SetPenMode, aux::pencopy
        JUMP_TABLE_MGTK_CALL MGTK::SetPattern, aux::pattern
        JUMP_TABLE_MGTK_CALL MGTK::PaintRect, aux::rect

        jsr     JUMP_TABLE_HILITE_MENU

        JUMP_TABLE_MGTK_CALL MGTK::ShowCursor
        rts
.endproc ; Init

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
