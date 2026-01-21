;;; ============================================================
;;; MELT - Desk Accessory
;;;
;;; Wipes the screen in an amusing way.
;;; ============================================================

        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================
;;; Graphics Resources

event_params:   .tag MGTK::Event

;;; ============================================================
;;; DA Init

.proc Init
        jsr     InitRand

        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

;;; ============================================================
;;; Main Input Loop

.proc InputLoop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params + MGTK::Event::kind
        cmp     #MGTK::EventKind::button_down ; was clicked?
        beq     exit
        cmp     #MGTK::EventKind::key_down  ; any key?
        beq     exit

        MGTK_CALL MGTK::WaitVBL
        jsr     Animate
        jsr     Animate
        jsr     Animate
        jsr     Animate
        jmp     InputLoop

exit:
        MGTK_CALL MGTK::RedrawDeskTop

        MGTK_CALL MGTK::DrawMenuBar
        JSR_TO_MAIN JUMP_TABLE_HILITE_MENU

        MGTK_CALL MGTK::ShowCursor
        rts                     ; exits input loop
.endproc ; InputLoop

;;; ============================================================
;;; Animate

kDeltaMask = 7
delta:  .byte   0

.proc Animate

        ;; ----------------------------------------
        ;; Pick a vertical delta for the column in [1,7]
    DO
        jsr     Random
        and     #kDeltaMask
    WHILE ZERO
        sta     delta

        ;; ----------------------------------------
        ;; Pick a column

        ;; Purely random selection would pick a number in [0,39],
        ;; but that's boring.
        ;;
        ;; A nice bell curve can be produced by adding two numbers in
        ;; [0,39] and dividing by two. But the extreme edges have very
        ;; low probability so it doesn't look pleasant either.
        ;;
        ;; This adds two random numbers in [0,63] to get a bell curve,
        ;; then divides by two so we're back in [0,63], and then
        ;; subtracts to center on [0,39], and throws out anything out
        ;; of range. The result is a pleasing dip towards the middle
        ;; of the screen, but the edges aren't too slow to melt.

        kNumCols = 40
    DO
        tmp := $06
        jsr     Random
        and     #63
        sta     tmp
        jsr     Random
        and     #63
        clc
        adc     tmp
        lsr
        sec
        sbc     #(64 - kNumCols) / 2
        CONTINUE_IF NEG
    WHILE A >= #kNumCols
        tay                     ; Y = column

        ;; ----------------------------------------

        src_ptr := $06
        dst_ptr := $08

        ldx     #kScreenHeight - 1
        stx     row
    DO
        copylohi hires_table_lo,x, hires_table_hi,x, dst_ptr

        txa
        sec
        sbc     delta
        tax

        copylohi hires_table_lo,x, hires_table_hi,x, src_ptr

        sta     PAGE2OFF
        copy8   (src_ptr),y, (dst_ptr),y
        sta     PAGE2ON
        copy8   (src_ptr),y, (dst_ptr),y

        dec     row
        ldx     row
    WHILE X >= delta

        ;; Black in at the top
    DO
        lda     hires_table_lo,x
        sta     dst_ptr
        lda     hires_table_hi,x
        ora     #$20
        sta     dst_ptr+1

        lda     #0
        sta     PAGE2OFF
        sta     (dst_ptr),y
        sta     PAGE2ON
        sta     (dst_ptr),y

        dex
    WHILE POS
        rts

row:    .byte   0

.endproc ; Animate

        .include "../lib/prng.s"
        .include "../inc/hires_table.inc"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
        JSR_TO_AUX aux::Init
        rts
        DA_END_MAIN_SEGMENT

;;; ============================================================
