;;; ============================================================
;;; DeskTop - Main Memory Segment
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

;;; ============================================================
;;; Segment loaded into AUX $D000-$FFFF
;;; ============================================================

        .org $D000

;;; Constants needed in both main and aux

        menu_id_apple := 1
        menu_id_file := 2
        menu_id_view := 4
        menu_id_special := 5
        menu_id_startup := 8
        menu_id_selector := 3

;;; Various routines callable from MAIN

;;; ============================================================
;;; MGTK call from main>aux, call in Y, params at (X,A)

.proc MGTK_RELAY_IMPL
        .assert * = MGTK_RELAY, error, "Entry point mismatch"
        sty     addr-1
        stax    addr
        sta     RAMRDON
        sta     RAMWRTON
        MGTK_CALL 0, 0, addr
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

;;; ============================================================
;;; SET_POS with params at (X,A) followed by DRAW_TEXT call

.proc SETPOS_DRAWTEXT_RELAY
        stax    addr
        sta     RAMRDON
        sta     RAMWRTON
        MGTK_CALL MGTK::MoveTo, 0, addr
        MGTK_RELAY_CALL MGTK::DrawText, text_buffer2
        tay
        sta     RAMRDOFF
        sta     RAMWRTOFF
        tya
        rts
.endproc

;;; ============================================================
;;; DESKTOP call from main>aux, call in Y params at (X,A)

.proc DESKTOP_RELAY_IMPL
        .assert * = DESKTOP_RELAY, error, "Entry point mismatch"
        sty     addr-1
        stax    addr
        sta     RAMRDON
        sta     RAMWRTON
        DESKTOP_CALL 0, 0, addr
        tay
        sta     RAMRDOFF
        sta     RAMWRTOFF
        tya
        rts
.endproc

;;; ============================================================
;;; Used/Free icon map (Aux $1F80 - $1FFF)

        free_icon_map := $1F80

;;; Find first available free icon in the map; if
;;; available, mark it and return index+1.

.proc DESKTOP_ALLOC_ICON
        sta     RAMRDON
        sta     RAMWRTON
        ldx     #0
loop:   lda     free_icon_map,x
        beq     :+
        inx
        cpx     #$7F
        bne     loop
        rts

:       inx
        txa
        dex
        tay
        lda     #1
        sta     free_icon_map,x
        sta     RAMRDOFF
        sta     RAMWRTOFF
        tya
        rts
.endproc

;;; Mark the specified icon as free

.proc DESKTOP_FREE_ICON
        tay
        sta     RAMRDON
        sta     RAMWRTON
        dey
        lda     #0
        sta     free_icon_map,y
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

;;; ============================================================
;;; Copy data to/from buffers (see cached_window_id / cached_window_icon_list / window_icon_count_table/2) ???

.proc DESKTOP_COPY_BUF_IMPL
        ptr := $6

from:
        lda     #$80
        bne     :+              ; always

to:
        lda     #$00

:       sta     flag
        jsr     desktop_main_push_zp_addrs

        lda     cached_window_id
        asl     a               ; * 2
        tax
        copy16  window_icon_count_table,x, ptr

        sta     RAMRDON
        sta     RAMWRTON
        bit     flag
        bpl     set_length

        ;; assign length from cached_window_icon_list
        lda     cached_window_icon_count
        ldy     #0
        sta     (ptr),y
        jmp     set_copy_ptr

        ;; assign length to cached_window_icon_list
set_length:
        ldy     #0
        lda     (ptr),y
        sta     cached_window_icon_count

set_copy_ptr:
        copy16  window_icon_list_table,x, ptr
        bit     flag
        bmi     copy_from

        ;; copy into cached_window_icon_list
        ldy     #0              ; flag clear...
:       cpy     cached_window_icon_count
        beq     done
        lda     (ptr),y
        sta     cached_window_icon_list,y
        iny
        jmp     :-

        ;; copy from cached_window_icon_list
copy_from:
        ldy     #0
:       cpy     cached_window_icon_count
        beq     done
        lda     cached_window_icon_list,y
        sta     (ptr),y
        iny
        jmp     :-

done:   sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     desktop_main_pop_zp_addrs
        rts

flag:   .byte   0
        rts                     ; ???
.endproc
        DESKTOP_COPY_FROM_BUF := DESKTOP_COPY_BUF_IMPL::from
        DESKTOP_COPY_TO_BUF := DESKTOP_COPY_BUF_IMPL::to

;;; ============================================================
;;; Assign active state to active_window_id window

.proc DESKTOP_ASSIGN_STATE
        src := $6
        dst := $8

        sta     RAMRDON
        sta     RAMWRTON
        MGTK_CALL MGTK::GetPort, src ; grab window state

        lda     active_window_id   ; which desktop window?
        asl     a
        tax
        copy16  win_table,x, dst
        lda     dst
        clc
        adc     #20             ; add offset
        sta     dst
        bcc     :+
        inc     dst+1

:       ldy     #35             ; copy 35 bytes into window state
loop:   lda     (src),y
        sta     (dst),y
        dey
        bpl     loop

        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

;;; ============================================================
;;; From MAIN, load AUX (X,A) into A

.proc DESKTOP_AUXLOAD
        stx     op+2
        sta     op+1
        sta     RAMRDON
        sta     RAMWRTON
op:     lda     dummy1234
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

;;; ============================================================
;;; From MAIN, show alert

;;; ...with prompt #0
.proc DESKTOP_SHOW_ALERT0
        ldx     #$00
        ;; fall through
.endproc

;;; ... with prompt # in X
.proc DESKTOP_SHOW_ALERT
        sta     RAMRDON
        sta     RAMWRTON
        jsr     desktop_aux::show_alert_indirection
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

;;; ============================================================

        .assert * = $D166, error, "Segment length mismatch"
        PAD_TO $D200

        .include "desktop_res.s"

        .assert * = $FFBA, error, "Segment length mismatch"
        PAD_TO $10000
