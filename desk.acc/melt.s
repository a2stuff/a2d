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

;;; ============================================================
;;; DA Init

.proc Init
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::FlushEvents
.endproc

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
        sta     RAMWRTOFF
        sta     RAMRDOFF
        jsr     JUMP_TABLE_HILITE_MENU
        sta     RAMWRTON
        sta     RAMRDON

        MGTK_CALL MGTK::ShowCursor
        rts                     ; exits input loop
.endproc

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

.endproc

        .include "../inc/hires_table.inc"

;;; ============================================================

da_end:
