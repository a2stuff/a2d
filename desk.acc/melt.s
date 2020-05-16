;;; ============================================================
;;; MELT - Desk Accessory
;;;
;;; Wipes the screen in an amusing way.
;;; ============================================================

        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        .org $800


        dummy1234 := $1234

da_start:
        jmp     start

save_stack:.byte   0

.proc start
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
        jsr     init

        ;; tear down/exit
        sta     RAMRDOFF
        sta     RAMWRTOFF

        ldx     save_stack
        txs

        rts
.endproc


;;; ============================================================
;;; Graphics Resources

        kDAWindowId = 100

event_params:   .tag MGTK::Event

.params window_title
        .byte 0                 ; length
.endparams

.params winfo
window_id:      .byte   kDAWindowId ; window identifier
options:        .byte   MGTK::Option::dialog_box
title:          .addr   window_title
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   32
hthumbpos:      .byte   0
vthumbmax:      .byte   32
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   kScreenWidth
mincontlength:  .word   kScreenHeight
maxcontwidth:   .word   kScreenWidth
maxcontlength:  .word   kScreenHeight
.params port
viewloc:        DEFINE_POINT 0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, kScreenWidth, kScreenHeight
.endparams
pattern:        .res    8, 0
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::notpencopy
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

;;; ============================================================
;;; DA Init

.proc init
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::FlushEvents
.endproc

;;; ============================================================
;;; Main Input Loop

.proc input_loop
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

        jsr     animate
        jmp     input_loop

exit:
        ;; Force desktop redraw
        MGTK_CALL MGTK::OpenWindow, winfo
        MGTK_CALL MGTK::CloseWindow, winfo

        MGTK_CALL MGTK::DrawMenu
        sta     RAMWRTOFF
        sta     RAMRDOFF
        yax_call JUMP_TABLE_MGTK_RELAY, MGTK::HiliteMenu, DeskTopInternals::last_menu_click_params
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

.proc animate

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
