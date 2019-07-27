        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../desktop.inc"
        .include "../inc/macros.inc"

;;; ============================================================

        .org $800

;;; ============================================================

        yax_call JUMP_TABLE_MGTK_RELAY, MGTK::HideCursor, 0
        yax_call JUMP_TABLE_MGTK_RELAY, MGTK::HiliteMenu, last_menu_click_params
        jsr     dump_screen
        yax_call JUMP_TABLE_MGTK_RELAY, MGTK::HiliteMenu, last_menu_click_params
        yax_call JUMP_TABLE_MGTK_RELAY, MGTK::ShowCursor, 0
        rts

;;; ============================================================

.proc dump_screen

        SLOT1   := $C100

        hbasl := $6
        screen_width  = 560
        screen_height = 192

        lda     ROMIN2
        jsr     print_screen
        lda     LCBANK1
        lda     LCBANK1
        rts

.proc send_spacing
        ldy     #0
:       lda     spacing_sequence,y
        beq     done
        jsr     cout
        iny
        jmp     :-
done:   rts
.endproc

.proc send_restore_state
        ldy     #$00
:       lda     restore_state,y
        beq     done
        jsr     cout
        iny
        jmp     :-
done:   rts
.endproc

.proc send_init_graphics
        ldx     #0
:       lda     init_graphics,x
        jsr     cout
        inx
        cpx     #6
        bne     :-
        rts
init_graphics:
        .byte   CHAR_ESCAPE,"G0560"     ; Graphics, 560 data bytes
.endproc

.proc send_row
        ;; Tell printer to expect graphics
        jsr     send_init_graphics
        ldy     #0
        sty     col_num
        lda     #1
        sta     mask
        lda     #0
        sta     x_coord
        sta     x_coord+1

col_loop:
        lda     #8              ; 8 vertical pixels per row
        sta     count
        lda     y_row
        sta     y_coord

        ;; Accumulate 8 pixels
y_loop: lda     y_coord
        jsr     compute_hbasl   ; Row address in screen

        lda     col_num
        lsr     a               ; Even or odd column?
        tay
        sta     PAGE2OFF        ; By default, read main mem $2000-$3FFF
        bcs     :+              ; But even columns come from aux, so...
        sta     PAGE2ON         ; Read aux mem $2000-$3FFF

:       lda     (hbasl),y       ; Grab the whole byte
        and     mask            ; Isolate the pixel we care about
        cmp     #1              ; Set carry if non-zero
        ror     accum           ; And slide it into place
        inc     y_coord
        dec     count
        bne     y_loop

        ;; Send the 8 pixels to the printer.
        lda     accum           ; Now output it
        eor     #$FF            ; Invert pixels (screen vs. print)
        sta     PAGE2OFF        ; Read main mem $2000-$3FFF
        jsr     cout            ; And actually print

        ;; Done all pixels across?
        lda     x_coord
        cmp     #<(screen_width-1)
        bne     :+
        lda     x_coord+1
        cmp     #>(screen_width-1)
        beq     done

        ;; Next pixel to the right
:       asl     mask
        bpl     :+              ; Only 7 pixels per column
        lda     #1
        sta     mask
        inc     col_num

:       inc     x_coord
        bne     col_loop
        inc     x_coord+1
        bne     col_loop

done:   sta     PAGE2OFF        ; Read main mem $2000-$3FFF
        rts
.endproc

.proc print_screen
        ;; Init printer
        jsr     pr_num_1
        jsr     send_spacing

        lda     #0
        sta     y_row

        ;; Print a row (560x8), CR+LF
loop:   jsr     send_row
        lda     #CHAR_RETURN
        jsr     cout
        lda     #CHAR_DOWN
        jsr     cout

        lda     y_coord
        sta     y_row
        cmp     #screen_height
        bcc     loop

        ;; Finish up
        lda     #CHAR_RETURN
        jsr     cout
        lda     #CHAR_RETURN
        jsr     cout
        jsr     send_restore_state

        rts
.endproc

        ;; Given y-coordinate in A, compute HBASL-equivalent
.proc compute_hbasl
        pha
        and     #$C7
        eor     #$08
        sta     $07
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        sta     hbasl
        pla
        and     #$38
        asl     a
        asl     a
        eor     hbasl
        asl     a
        rol     hbasl+1
        asl     a
        rol     hbasl+1
        eor     hbasl
        sta     hbasl
        rts
.endproc

.proc pr_num_1
        lda     #>SLOT1
        sta     COUT_HOOK+1
        lda     #<SLOT1
        sta     COUT_HOOK
        lda     #(CHAR_RETURN | $80)
        jsr     invoke_slot1
        rts
.endproc

.proc cout
        jsr     COUT
        rts
.endproc

y_row:  .byte   0              ; y-coordinate of row start (0, 8, ...)
x_coord:.word   0              ; x-coordinate of pixels being accumulated
y_coord:.byte   0              ; iterates y_row to y_row+7
mask:   .byte   0              ; mask for pixel being processed
accum:  .byte   0              ; accumulates pixels for output
count:  .byte   0              ; 8...1 while a row is output
col_num:.byte   0               ; 0...79

        .byte   0, 0

spacing_sequence:
        .byte   CHAR_ESCAPE,'e'         ; 107 DPI (horizontal)
        .byte   CHAR_ESCAPE,"T16"       ; distance between lines (16/144")
        .byte   CHAR_TAB,$4C,$20,$44,$8D ; ???
        .byte   CHAR_TAB,$5A,$8D     ; ???
        .byte   0

restore_state:
        .byte   CHAR_ESCAPE,'N'         ; 80 DPI (horizontal)
        .byte   CHAR_ESCAPE,"T24"       ; distance between lines (24/144")
        .byte   0

invoke_slot1:
        jmp     SLOT1

.endproc ; dump_screen

;;; ============================================================
