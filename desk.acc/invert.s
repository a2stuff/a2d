;;; ============================================================
;;; INVERT - Desk Accessory
;;;
;;; Inverts the screen.
;;; ============================================================

        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

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
;;; Graphics Resources

event_params:   .tag MGTK::Event
grafport:       .tag MGTK::GrafPort
penxor:         .byte   MGTK::penXOR
        DEFINE_RECT rect, 0, 0, kScreenWidth-1, kScreenHeight-1


;;; ============================================================
;;; DA Init

.proc Init
        jsr     Invert
        MGTK_CALL MGTK::FlushEvents
.endproc

;;; ============================================================
;;; Main Input Loop

.proc InputLoop
loop:   MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params + MGTK::Event::kind
        cmp     #MGTK::EventKind::button_down ; was clicked?
        beq     exit
        cmp     #MGTK::EventKind::key_down  ; any key?
        beq     exit
        jmp     loop

exit:   jsr     Invert
        rts
.endproc

;;; ============================================================
;;; Invert

.proc Invert
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::SetPenMode, penxor
        MGTK_CALL MGTK::PaintRect, rect
        MGTK_CALL MGTK::ShowCursor
        rts
.endproc

;;; ============================================================

da_end:
