;;; ============================================================
;;; DARKNESS - Desk Accessory
;;;
;;; Paints the screen a dark pattern... and leaves it that way.
;;; For ensuring repaints are minimal. Best used bound to a
;;; menu item in Shortcuts and triggered with a shortcut key.
;;; ============================================================

        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

        MGTKEntry := MGTKAuxEntry

;;; ============================================================

        .org DA_LOAD_ADDRESS

da_start:
        jmp     Start

save_stack:.byte   0

.proc Start
        tsx
        stx     save_stack

        ;; Copy DA to AUX
        copy16  #da_start, STARTLO
        copy16  #da_start, DESTINATIONLO
        copy16  #da_end, ENDLO
        sec                     ; main>aux
        jsr     AUXMOVE

        ;; Transfer control to aux
        sta     RAMWRTON
        sta     RAMRDON

        ;; run the DA
        jsr     Init

        ;; tear down/exit
        sta     RAMRDOFF
        sta     RAMWRTOFF

        ldx     save_stack
        txs

        rts
.endproc

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

.proc Init
        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::SetPattern, pattern
        MGTK_CALL MGTK::PaintRect, rect

        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_HILITE_MENU
        sta     RAMWRTON
        sta     RAMRDON

        MGTK_CALL MGTK::ShowCursor
        rts
.endproc

;;; ============================================================

da_end  := *
.assert * < DA_IO_BUFFER, error, .sprintf("DA too big (at $%X)", *)

;;; ============================================================
