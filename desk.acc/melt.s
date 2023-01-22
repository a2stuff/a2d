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

        MGTKEntry := MGTKAuxEntry

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================
;;; Graphics Resources

event_params:   .tag MGTK::Event

;;; ============================================================
;;; DA Init

.proc Init
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

;;; ============================================================
;;; Main Input Loop

.proc InputLoop
        dec     delta
        bne     :+
        lda     #7
        sta     delta
:

        dec     deltac
        bne     :+
        lda     #27
        sta     deltac
:

        kNumCols = 40
        lda     col
        sec
        sbc     deltac
        bpl     :+
        clc
        adc     #kNumCols
:       sta     col


        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params + MGTK::Event::kind
        cmp     #MGTK::EventKind::button_down ; was clicked?
        beq     exit
        cmp     #MGTK::EventKind::key_down  ; any key?
        beq     exit

        jsr     Animate
        jmp     InputLoop

exit:
        MGTK_CALL MGTK::RedrawDeskTop

        MGTK_CALL MGTK::DrawMenu
        JSR_TO_MAIN JUMP_TABLE_HILITE_MENU

        MGTK_CALL MGTK::ShowCursor
        rts                     ; exits input loop
.endproc ; InputLoop

;;; ============================================================
;;; Animate

col:    .byte   20
delta:  .byte   3
deltac: .byte   31

.proc Animate

        kNumCols = 40

        src_ptr := $06
        dst_ptr := $08

        ldy     col

        ldx     #kScreenHeight - 1
        stx     row

yloop:  lda     hires_table_lo,x
        sta     dst_ptr
        lda     hires_table_hi,x
        sta     dst_ptr+1

        txa
        sec
        sbc     delta
        tax

        lda     hires_table_lo,x
        sta     src_ptr
        lda     hires_table_hi,x
        sta     src_ptr+1

        sta     PAGE2OFF
        lda     (src_ptr),y
        sta     (dst_ptr),y
        sta     PAGE2ON
        lda     (src_ptr),y
        sta     (dst_ptr),y

        dec     row
        ldx     row
        cpx     delta
        bcs     yloop

        ;; Black in at the top
yloop2: lda     hires_table_lo,x
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
        bpl     yloop2
        rts

row:    .byte   0

.endproc ; Animate

        .include "../inc/hires_table.inc"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
        JSR_TO_AUX Init
        rts
        DA_END_MAIN_SEGMENT

;;; ============================================================
