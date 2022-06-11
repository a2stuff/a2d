;;; ============================================================
;;; Button Routines
;;; ============================================================
;;; API:
;;; * `ButtonClick` - call on button down to track mouse
;;; * `ButtonFlash` - flash button when shortcut key pressed
;;; Internal procs are prefixed with `_`
;;; ============================================================
;;; Requires:
;;; * `penXOR`
;;; * `event_params`
;;; * `screentowindow_params` (overlapping `event_params`)
;;; * `screentowindow_window_id`
;;; * `getwinport_params` - which must reference...
;;; * `grafport_win`
;;; ============================================================

;;; ============================================================
;;; Event loop during button press - initial invert and
;;; inverting as mouse is dragged in/out.
;;; Input: A,X = rect address, Y = window_id
;;; Output: A=0/N=0/Z=1 = click, A=$80/N=1/Z=0 = cancel
;;; Note: Sets current GrafPort to window's port.

.proc ButtonClick
        sty     window_id
        stax    rect_addr1
        stax    rect_addr2

        tya
        jsr     _ButtonSetWinPort

        ;; Initial state
        copy    #0, down_flag

        ;; Do initial inversion
        MGTK_CALL MGTK::SetPenMode, penXOR
        jsr     Invert

        ;; Event loop
loop:   MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     exit
        lda     window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_window
        MGTK_CALL MGTK::InRect, SELF_MODIFIED, rect_addr1

        cmp     #MGTK::inrect_inside
        beq     inside
        lda     down_flag       ; outside but was inside?
        beq     toggle
        bne     loop            ; always

inside: lda     down_flag       ; already depressed?
        beq     loop

toggle: jsr     Invert
        lda     down_flag
        eor     #$80
        sta     down_flag
        jmp     loop

exit:   lda     down_flag       ; was depressed?
        bne     :+
        jsr     Invert
:       lda     down_flag
        rts

        ;; --------------------------------------------------

Invert: MGTK_CALL MGTK::PaintRect, SELF_MODIFIED, rect_addr2
        rts

        ;; --------------------------------------------------

down_flag:
        .byte   0

window_id:
        .byte   0
.endproc

;;; ============================================================
;;; Flash button, following keypress
;;; Input: A,X = rect address, Y = window_id
;;; Note: Sets current GrafPort to window's port.

.proc ButtonFlash
        stax    rect_addr
        tya
        jsr     _ButtonSetWinPort
        MGTK_CALL MGTK::SetPenMode, penXOR
        jsr     Invert
        FALL_THROUGH_TO Invert

Invert: MGTK_CALL MGTK::PaintRect, SELF_MODIFIED, rect_addr
        rts
.endproc

;;; ============================================================
;;; Helper

.proc _ButtonSetWinPort
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, grafport_win
        rts
.endproc
