        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

;;; ============================================================

        .org $800

;;; ============================================================

        jmp     copy2aux


stash_stack:  .byte   $00

;;; ============================================================
;;; MLI Call Param Blocks

filename:
        PASCAL_STRING "DESKTOP.SYSTEM"

        DEFINE_OPEN_PARAMS open_params, filename, $900
        DEFINE_SET_MARK_PARAMS set_mark_params, 3
        DEFINE_WRITE_PARAMS write_params, write_buffer, sizeof_write_buffer
        DEFINE_CLOSE_PARAMS close_params

write_buffer:
        .byte   0,0
        sizeof_write_buffer = * - write_buffer

;;; ============================================================

.proc copy2aux

        start := start_da
        end   := last

        tsx
        stx     stash_stack
        sta     ALTZPOFF
        lda     ROMIN2

        lda     MACHID
        and     #%00000001      ; bit 0 = clock card
        sta     clock_flag

        lda     DATELO
        sta     datelo
        lda     DATEHI
        sta     datehi

        copy16  #start, STARTLO
        copy16  #end, ENDLO
        copy16  #start, DESTINATIONLO
        sec
        jsr     AUXMOVE

        copy16  #start, XFERSTARTLO
        php
        pla
        ora     #$40            ; set overflow: aux zp/stack
        pha
        plp
        sec                     ; control main>aux
        jmp     XFER
.endproc

;;; ============================================================
;;; Write date into DESKTOP.SYSTEM file and exit the DA

.proc save_date_and_exit
        sta     ALTZPON
        sta     write_buffer
        stx     write_buffer+1
        lda     LCBANK1
        lda     LCBANK1
        lda     write_buffer    ; Dialog committed?
        beq     skip

        ;; If there is a system clock, don't write out the date.
        ldx     clock_flag
        bne     skip

        ldy     #OPEN           ; open the file
        ldax    #open_params
        jsr     JUMP_TABLE_MLI
        bne     skip

        lda     open_params::ref_num
        sta     set_mark_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num

        ldy     #SET_MARK       ; seek
        ldax    #set_mark_params
        jsr     JUMP_TABLE_MLI
        bne     close

        ldy     #WRITE          ; write the date
        ldax    #write_params
        jsr     JUMP_TABLE_MLI

close:  ldy     #CLOSE          ; close the file
        ldax    #close_params
        jsr     JUMP_TABLE_MLI

skip:   ldx     stash_stack     ; exit the DA
        txs
        rts
.endproc

;;; ============================================================

start_da:
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        jmp     init_window

;;; ============================================================
;;; Param blocks

        ;; The following 7 rects are iterated over to identify
        ;; a hit target for a click.

        num_hit_rects = 7
        first_hit_rect = *
        up_rect_index = 3
        down_rect_index = 4

ok_button_rect:
        .word   $6A,$2E,$B5,$39
cancel_button_rect:
        .word   $10,$2E,$5A,$39
up_arrow_rect:
        .word   $AA,$0A,$B4,$14
down_arrow_rect:
        .word   $AA,$1E,$B4,$28
day_rect:
        .word   $25,$14,$3B,$1E
month_rect:
        .word   $51,$14,$6F,$1E
year_rect:
        .word   $7F,$14,$95,$1E

.proc settextbg_params
backcolor:   .byte   0          ; black
.endproc

        .res    7, $00          ; ???
        .byte   $FF

.proc white_pattern
        .res    8, $FF
.endproc
        .byte   $FF             ; ??

selected_field:                 ; 1 = day, 2 = month, 3 = year, 0 = none (init)
        .byte   0

clock_flag:
        .byte   0

datelo: .byte   0
datehi: .byte   0

day:    .byte   26              ; Feb 26, 1985
month:  .byte   2               ; The date this was written?
year:   .byte   85

spaces_string:
        DEFINE_STRING "    "

day_pos:
        .word   43, 30
day_string:
        DEFINE_STRING "  "

month_pos:
        .word   87, 30
month_string:
        DEFINE_STRING "   "

year_pos:
        .word   133, 30
year_string:
        DEFINE_STRING "  "

.proc event_params
kind:  .byte   0

key       := *
modifiers := *+1

xcoord    := *
ycoord    := *+2
        .byte   0,0,0,0
.endproc
        ;; xcoord/ycoord are used to query...
.proc findwindow_params
mousex    := *
mousey    := *+2
which_area:.byte   0
window_id: .byte   0
.endproc

        da_window_id = 100

.proc screentowindow_params
window_id:     .byte   da_window_id
screen:
screenx:.word   0
screeny:.word   0
window:
windowx:.word   0
windowy:.word   0
.endproc

.proc closewindow_params
window_id:     .byte   da_window_id
.endproc
        .byte $00,$01           ; ???

.proc penmode_params
penmode:   .byte   $02             ; this should be normal, but we do inverts ???
.endproc
        .byte   $06             ; ???

.proc winfo
window_id:     .byte   da_window_id
options:.byte   MGTK::Option::dialog_box
title:  .addr   0
hscroll:.byte   MGTK::Scroll::option_none
vscroll:.byte   MGTK::Scroll::option_none
hthumbmax:  .byte   0
hthumbpos:  .byte   0
vthumbmax:  .byte   0
vthumbpos:  .byte   0
status:     .byte       0
reserved:       .byte   0
mincontwidth:     .word   100
mincontlength:     .word   100
maxcontwidth:     .word   500
maxcontlength:     .word   500
port:
viewloc:        DEFINE_POINT 180, 50
mapbits:   .addr   MGTK::screen_mapbits
mapwidth: .word   MGTK::screen_mapwidth
cliprect:       DEFINE_RECT 0, 0, 199, 64
pattern:.res    8,$00
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc: DEFINE_POINT 0, 0
penwidth: .byte   4
penheight: .byte   2
penmode:   .byte   0
textback:  .byte   $7F
textfont:   .addr   DEFAULT_FONT
nextwinfo:   .addr   0
.endproc

;;; ============================================================
;;; Initialize window, unpack the date.

init_window:
        jsr     save_zp

        ;; If null date, just leave the baked in default
        lda     datelo
        ora     datehi
        beq     :+

        ;; Crack the date bytes. Format is:
        ;;   |    DATEHI     |    DATELO     |
        ;;   |7 6 5 4 3 2 1 0 7 6 5 4 3 2 1 0|
        ;;   |    year     | month |  day    |

        lda     datehi
        lsr     a
        sta     year

        lda     datelo
        and     #%11111
        sta     day

        lda     datehi
        ror     a
        lda     datelo
        ror     a
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     month

:       MGTK_CALL MGTK::OpenWindow, winfo
        lda     #0
        sta     selected_field
        jsr     draw_window
        MGTK_CALL MGTK::FlushEvents
        ;; fall through

;;; ============================================================
;;; Input loop

.proc input_loop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jsr     on_click
        jmp     input_loop

:       cmp     #MGTK::EventKind::key_down
        bne     input_loop
.endproc

.proc on_key
        lda     event_params::modifiers
        bne     input_loop
        lda     event_params::key
        cmp     #CHAR_RETURN
        bne     :+
        jmp     on_ok

        ;; If there is a system clock, only the first button is active
:       ldx     clock_flag
        bne     input_loop

        cmp     #CHAR_ESCAPE
        bne     :+
        jmp     on_cancel
:       cmp     #CHAR_LEFT
        beq     on_key_left
        cmp     #CHAR_RIGHT
        beq     on_key_right
        cmp     #CHAR_DOWN
        beq     on_key_down
        cmp     #CHAR_UP
        bne     input_loop

on_key_up:
        MGTK_CALL MGTK::PaintRect, up_arrow_rect
        lda     #up_rect_index
        sta     hit_rect_index
        jsr     do_inc_or_dec
        MGTK_CALL MGTK::PaintRect, up_arrow_rect
        jmp     input_loop

on_key_down:
        MGTK_CALL MGTK::PaintRect, down_arrow_rect
        lda     #down_rect_index
        sta     hit_rect_index
        jsr     do_inc_or_dec
        MGTK_CALL MGTK::PaintRect, down_arrow_rect
        jmp     input_loop

on_key_left:
        sec
        lda     selected_field
        sbc     #1
        bne     update_selection
        lda     #3
        jmp     update_selection

on_key_right:
        clc
        lda     selected_field
        adc     #1
        cmp     #4
        bne     update_selection
        lda     #1

update_selection:
        jsr     highlight_selected_field
        jmp     input_loop
.endproc

;;; ============================================================

.proc on_click
        MGTK_CALL MGTK::FindWindow, event_params::xcoord
        MGTK_CALL MGTK::SetPenMode, penmode_params
        MGTK_CALL MGTK::SetPattern, white_pattern
        lda     findwindow_params::window_id
        cmp     #da_window_id
        bne     miss
        lda     findwindow_params::which_area
        bne     hit
miss:   rts

hit:    cmp     #MGTK::Area::content
        bne     miss
        jsr     find_hit_target
        cpx     #0
        beq     miss
        txa
        sec
        sbc     #1
        asl     a
        tay
        copy16  hit_target_jump_table,y, jump+1
jump:   jmp     $1000           ; self modified

hit_target_jump_table:
        .addr   on_ok, on_cancel, on_up, on_down
        .addr   on_field_click, on_field_click, on_field_click
.endproc

;;; ============================================================

.proc on_ok
        MGTK_CALL MGTK::PaintRect, ok_button_rect

        ;; Pack the date bytes and store
        sta     RAMWRTOFF
        lda     month
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        ora     day
        sta     DATELO
        lda     year
        rol     a
        sta     DATEHI
        sta     RAMWRTON

        lda     #1
        sta     dialog_result
        jmp     destroy
.endproc

on_cancel:
        MGTK_CALL MGTK::PaintRect, cancel_button_rect
        lda     #0
        sta     dialog_result
        jmp     destroy

on_up:
        txa
        pha
        MGTK_CALL MGTK::PaintRect, up_arrow_rect
        pla
        tax
        jsr     on_up_or_down
        rts

on_down:
        txa
        pha
        MGTK_CALL MGTK::PaintRect, down_arrow_rect
        pla
        tax
        jsr     on_up_or_down
        rts

on_field_click:
        txa
        sec
        sbc     #4
        jmp     highlight_selected_field

.proc on_up_or_down
        stx     hit_rect_index
loop:   MGTK_CALL MGTK::GetEvent, event_params ; Repeat while mouse is down
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_up
        beq     :+
        jsr     do_inc_or_dec
        jmp     loop

:       lda     hit_rect_index
        cmp     #up_rect_index
        beq     :+

        MGTK_CALL MGTK::PaintRect, down_arrow_rect
        rts

:       MGTK_CALL MGTK::PaintRect, up_arrow_rect
        rts
.endproc

.proc do_inc_or_dec
        ptr := $7

        jsr     delay
        lda     hit_rect_index
        cmp     #up_rect_index
        beq     incr

decr:   copy16  #decrement_table, ptr
        jmp     go

incr:   copy16  #increment_table, ptr

go:     lda     selected_field
        asl     a
        tay
        copy16in (ptr),y, gosub+1

gosub:  jsr     $1000           ; self modified
        MGTK_CALL MGTK::SetTextBG, settextbg_params
        jmp     draw_selected_field
.endproc

hit_rect_index:
        .byte   0

;;; ============================================================

increment_table:
        .addr   0, increment_day, increment_month, increment_year
decrement_table:
        .addr   0, decrement_day, decrement_month, decrement_year


        day_min = 1
        day_max = 31
        month_min = 1
        month_max = 12
        year_min = 0
        year_max = 99

increment_day:
        clc
        lda     day
        adc     #1
        cmp     #day_max+1
        bne     :+
        lda     #month_min
:       sta     day
        jmp     prepare_day_string

increment_month:
        clc
        lda     month
        adc     #1
        cmp     #month_max+1
        bne     :+
        lda     #month_min
:       sta     month
        jmp     prepare_month_string

increment_year:
        clc
        lda     year
        adc     #1
        cmp     #year_max+1
        bne     :+
        lda     #year_min
:       sta     year
        jmp     prepare_year_string

decrement_day:
        dec     day
        bne     :+
        lda     #day_max
        sta     day
:       jmp     prepare_day_string

decrement_month:
        dec     month
        bne     :+
        lda     #month_max
        sta     month
:       jmp     prepare_month_string

decrement_year:
        dec     year
        bpl     :+
        lda     #year_max
        sta     year
:       jmp     prepare_year_string

;;; ============================================================

.proc prepare_day_string
        lda     day
        jsr     number_to_ascii
        sta     day_string+3    ; first char
        stx     day_string+4    ; second char
        rts
.endproc

.proc prepare_month_string
        lda     month           ; month * 3 - 1
        asl     a
        clc
        adc     month
        tax
        dex

        ptr := $07
        str := month_string + 3
        len = 3

        copy16  #str, ptr

        ldy     #len - 1
loop:   lda     month_name_table,x
        sta     (ptr),y
        dex
        dey
        bpl     loop

        rts
.endproc

month_name_table:
        .byte   "Jan","Feb","Mar","Apr","May","Jun"
        .byte   "Jul","Aug","Sep","Oct","Nov","Dec"

.proc prepare_year_string
        lda     year
        jsr     number_to_ascii
        sta     year_string+3
        stx     year_string+4
        rts
.endproc

;;; ============================================================
;;; Tear down the window and exit

dialog_result:  .byte   0

.proc destroy
        MGTK_CALL MGTK::CloseWindow, closewindow_params
        DESKTOP_CALL DT_REDRAW_ICONS

        ;; Copy the relay routine to the zero page
        dest := $20

        COPY_BYTES sizeof_routine+1, routine, dest
        lda     dialog_result
        beq     skip

        ;; Pack date bytes, store in X, A
        lda     month
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        ora     day
        tay
        lda     year
        rol     a
        tax
        tya

skip:   jmp     dest

.proc routine
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jmp     save_date_and_exit
.endproc
        sizeof_routine = * - routine
.endproc

;;; ============================================================
;;; Figure out which button was hit (if any).
;;; Index returned in X.

.proc find_hit_target
        copy16  event_params::xcoord, screentowindow_params::screenx
        copy16  event_params::ycoord, screentowindow_params::screeny
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        ldx     #1
        copy16  #first_hit_rect, test_addr

loop:   txa
        pha
        MGTK_CALL MGTK::InRect, $1000, test_addr
        bne     done

        ;; If there is a system clock, only the first button is active
        ldx     clock_flag
        beq     next
        pla
        ldx     #0
        rts


next:   clc
        lda     test_addr
        adc     #.sizeof(MGTK::Rect)
        sta     test_addr
        bcc     :+
        inc     test_addr+1
:       pla
        tax
        inx
        cpx     #num_hit_rects+1
        bne     loop

        ldx     #0
        rts

done:   pla
        tax
        rts
.endproc

;;; ============================================================
;;; Params for the display

border_rect:
        .word   $04,$02,$C0,$3D

date_rect:
        .word   $20,$0F,$9A,$23

label_ok:
        DEFINE_STRING {"OK         ",GLYPH_RETURN} ;
label_cancel:
        DEFINE_STRING "Cancel  ESC"
label_uparrow:
        DEFINE_STRING GLYPH_UARROW
label_downarrow:
        DEFINE_STRING GLYPH_DARROW

label_cancel_pos:
        .word   $15,$38
label_ok_pos:
        .word   $6E,$38

label_uparrow_pos:
        .word   $AC,$13
label_downarrow_pos:
        .word   $AC,$27

.proc setpensize_params
penwidth: .byte   1
penheight: .byte   1
.endproc

;;; ============================================================
;;; Render the window contents

.proc draw_window
        MGTK_CALL MGTK::SetPort, winfo::port
        MGTK_CALL MGTK::FrameRect, border_rect
        MGTK_CALL MGTK::SetPenSize, setpensize_params
        MGTK_CALL MGTK::FrameRect, date_rect

        MGTK_CALL MGTK::FrameRect, ok_button_rect
        MGTK_CALL MGTK::MoveTo, label_ok_pos
        MGTK_CALL MGTK::DrawText, label_ok

        ;; If there is a system clock, only draw the OK button.
        ldx     clock_flag
        bne     :+

        MGTK_CALL MGTK::FrameRect, cancel_button_rect
        MGTK_CALL MGTK::MoveTo, label_cancel_pos
        MGTK_CALL MGTK::DrawText, label_cancel

        MGTK_CALL MGTK::MoveTo, label_uparrow_pos
        MGTK_CALL MGTK::DrawText, label_uparrow
        MGTK_CALL MGTK::FrameRect, up_arrow_rect

        MGTK_CALL MGTK::MoveTo, label_downarrow_pos
        MGTK_CALL MGTK::DrawText, label_downarrow
        MGTK_CALL MGTK::FrameRect, down_arrow_rect

:       jsr     prepare_day_string
        jsr     prepare_month_string
        jsr     prepare_year_string

        jsr     draw_day
        jsr     draw_month
        jsr     draw_year

        ;; If there is a system clock, don't draw the highlight.
        ldx     clock_flag
        beq     :+
        rts

:       MGTK_CALL MGTK::SetPenMode, penmode_params
        MGTK_CALL MGTK::SetPattern, white_pattern
        lda     #1
        jmp     highlight_selected_field
.endproc

.proc draw_selected_field
        lda     selected_field
        cmp     #1
        beq     draw_day
        cmp     #2
        beq     draw_month
        jmp     draw_year
.endproc

.proc draw_day
        MGTK_CALL MGTK::MoveTo, day_pos
        MGTK_CALL MGTK::DrawText, day_string
        rts
.endproc

.proc draw_month
        MGTK_CALL MGTK::MoveTo, month_pos
        MGTK_CALL MGTK::DrawText, spaces_string ; variable width, so clear first
        MGTK_CALL MGTK::MoveTo, month_pos
        MGTK_CALL MGTK::DrawText, month_string
        rts
.endproc

.proc draw_year
        MGTK_CALL MGTK::MoveTo, year_pos
        MGTK_CALL MGTK::DrawText, year_string
        rts
.endproc

;;; ============================================================
;;; Highlight selected field
;;; Previously selected field in A, newly selected field at top of stack.

.proc highlight_selected_field
        pha
        lda     selected_field  ; initial state is 0, so nothing
        beq     update          ; to invert back to normal

        cmp     #1              ; day?
        bne     :+
        jsr     fill_day
        jmp     update

:       cmp     #2              ; month?
        bne     :+
        jsr     fill_month
        jmp     update

:       jsr     fill_year       ; year!

update: pla                     ; update selection
        sta     selected_field
        cmp     #1
        beq     fill_day
        cmp     #2
        beq     fill_month

fill_year:
        MGTK_CALL MGTK::PaintRect, year_rect
        rts

fill_day:
        MGTK_CALL MGTK::PaintRect, day_rect
        rts

fill_month:
        MGTK_CALL MGTK::PaintRect, month_rect
        rts
.endproc

;;; ============================================================
;;; Delay

.proc delay
        lda     #255
        sec
loop1:  pha

loop2:  sbc     #1
        bne     loop2

        pla
        sbc     #1
        bne     loop1
        rts
.endproc

;;; ============================================================
;;; Save/restore Zero Page

.proc save_zp
        ldx     #0
loop:   lda     $00,x
        sta     zp_buffer,x
        dex
        bne     loop
        rts
.endproc

.proc restore_zp
        ldx     #0
loop:   lda     zp_buffer,x
        sta     $00,x
        dex
        bne     loop
        rts
.endproc

zp_buffer:
        .res    256, 0

;;; ============================================================
;;; Convert number to two ASCII digits (in A, X)

.proc number_to_ascii
        ldy     #0
loop:   cmp     #10
        bcc     :+
        sec
        sbc     #10
        iny
        jmp     loop

:       clc
        adc     #'0'
        tax
        tya
        clc
        adc     #'0'
        rts
.endproc

        rts                     ; ???

last := *
