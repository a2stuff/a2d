;;; ============================================================
;;; DATE - Desk Accessory
;;;
;;; Shows the current ProDOS date, and allows editing if there
;;; is no clock driver installed.
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "date.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        .org DA_LOAD_ADDRESS

;;; ============================================================

        jmp     copy2aux


stash_stack:  .byte   $00

;;; ============================================================
;;; MLI Call Param Blocks

filename:
        PASCAL_STRING kFilenameLauncher

        DEFINE_OPEN_PARAMS open_params, filename, DA_IO_BUFFER
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

        lda     MACHID
        and     #%00000001      ; bit 0 = clock card
        sta     clock_flag

        copy16  DATELO, datelo

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
        ;; ASSERT: Running from Main

        stax    write_buffer
        lda     write_buffer    ; Dialog committed?
        beq     skip

        ;; If there is a system clock, don't write out the date.
        ldx     clock_flag
        bne     skip

        param_call JUMP_TABLE_MLI, OPEN, open_params ; open the file
        bne     skip

        lda     open_params::ref_num
        sta     set_mark_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num

        param_call JUMP_TABLE_MLI, SET_MARK, set_mark_params ; seek
        bne     close

        param_call JUMP_TABLE_MLI, WRITE, write_params ; write the date

close:  param_call JUMP_TABLE_MLI, CLOSE, close_params ; close the file

skip:   ldx     stash_stack     ; exit the DA
        txs
        rts
.endproc

;;; ============================================================

start_da:
        jmp     init_window

;;; ============================================================
;;; Param blocks

        ;; The following 7 rects are iterated over to identify
        ;; a hit target for a click.

        kNumHitRects = 7
        kUpRectIndex = 3
        kDownRectIndex = 4

        first_hit_rect := *
        DEFINE_RECT_SZ ok_button_rect, 106, 46, 75, 11
        DEFINE_RECT_SZ cancel_button_rect, 16, 46, 74, 11
        DEFINE_RECT_SZ up_arrow_rect, 170, 10, 10, 10
        DEFINE_RECT_SZ down_arrow_rect, 170, 30, 10, 10
        DEFINE_RECT_SZ day_rect, 37, 20, 22, 10
        DEFINE_RECT_SZ month_rect, 81, 20, 30, 10
        DEFINE_RECT_SZ year_rect, 127, 20, 22, 10

.params settextbg_params
backcolor:   .byte   0          ; black
.endparams

.params white_pattern
        .res    8, $FF
.endparams

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
        PASCAL_STRING "    "    ; do not localize

        DEFINE_POINT day_pos, 43, 30
day_string:
        PASCAL_STRING "  "      ; do not localize

        DEFINE_POINT month_pos, 87, 30
month_string:
        PASCAL_STRING "   "     ; do not localize

        DEFINE_POINT year_pos, 133, 30
year_string:
        PASCAL_STRING "  "      ; do not localize

.params event_params
kind:  .byte   0

key       := *
modifiers := *+1

xcoord    := *
ycoord    := *+2
        .byte   0,0,0,0
.endparams
        ;; xcoord/ycoord are used to query...
.params findwindow_params
mousex    := *
mousey    := *+2
which_area:.byte   0
window_id: .byte   0
.endparams

        kDAWindowId = 100

.params screentowindow_params
window_id:     .byte   kDAWindowId
screen:
screenx:.word   0
screeny:.word   0
window:
windowx:.word   0
windowy:.word   0
.endparams

.params closewindow_params
window_id:     .byte   kDAWindowId
.endparams

.params penmode_params
penmode:   .byte   MGTK::penXOR
.endparams

.params winfo
window_id:      .byte   kDAWindowId
options:        .byte   MGTK::Option::dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   0
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   100
mincontlength:  .word   100
maxcontwidth:   .word   500
maxcontlength:  .word   500
port:
        DEFINE_POINT viewloc, 180, 50
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT cliprect, 0, 0, 199, 64
pattern:        .res    8,$00
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   4
penheight:      .byte   2
penmode:        .byte   MGTK::pencopy
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

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
        beq     :+
        cmp     #CHAR_ESCAPE    ; allow Escape to close as well
        bne     input_loop
        jmp     on_ok

        ;; All controls are active
:       cmp     #CHAR_ESCAPE
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
        lda     #kUpRectIndex
        sta     hit_rect_index
        jsr     do_inc_or_dec
        MGTK_CALL MGTK::PaintRect, up_arrow_rect
        jmp     input_loop

on_key_down:
        MGTK_CALL MGTK::PaintRect, down_arrow_rect
        lda     #kDownRectIndex
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
        cmp     #kDAWindowId
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
jump:   jmp     SELF_MODIFIED

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
        cmp     #kUpRectIndex
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
        cmp     #kUpRectIndex
        beq     incr

decr:   copy16  #decrement_table, ptr
        jmp     go

incr:   copy16  #increment_table, ptr

go:     lda     selected_field
        asl     a
        tay
        copy16in (ptr),y, gosub+1

gosub:  jsr     SELF_MODIFIED
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


        kDayMin = 1
        kDayMax = 31
        kMonthMin = 1
        kMonthMax = 12
        kYearMin = 0
        kYearMax = 99

increment_day:
        clc
        lda     day
        adc     #1
        cmp     #kDayMax+1
        bne     :+
        lda     #kMonthMin
:       sta     day
        jmp     prepare_day_string

increment_month:
        clc
        lda     month
        adc     #1
        cmp     #kMonthMax+1
        bne     :+
        lda     #kMonthMin
:       sta     month
        jmp     prepare_month_string

increment_year:
        clc
        lda     year
        adc     #1
        cmp     #kYearMax+1
        bne     :+
        lda     #kYearMin
:       sta     year
        jmp     prepare_year_string

decrement_day:
        dec     day
        bne     :+
        lda     #kDayMax
        sta     day
:       jmp     prepare_day_string

decrement_month:
        dec     month
        bne     :+
        lda     #kMonthMax
        sta     month
:       jmp     prepare_month_string

decrement_year:
        dec     year
        bpl     :+
        lda     #kYearMax
        sta     year
:       jmp     prepare_year_string

;;; ============================================================

.proc prepare_day_string
        lda     day
        jsr     number_to_ascii
        sta     day_string+1    ; first char
        stx     day_string+2    ; second char
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
        str := month_string + 1
        kLength = 3

        copy16  #str, ptr

        ldy     #kLength - 1
loop:   lda     month_name_table,x
        sta     (ptr),y
        dex
        dey
        bpl     loop

        rts
.endproc

month_name_table:
        STRING  res_string_month_abbrev_1
        STRING  res_string_month_abbrev_2
        STRING  res_string_month_abbrev_3
        STRING  res_string_month_abbrev_4
        STRING  res_string_month_abbrev_5
        STRING  res_string_month_abbrev_6
        STRING  res_string_month_abbrev_7
        STRING  res_string_month_abbrev_8
        STRING  res_string_month_abbrev_9
        STRING  res_string_month_abbrev_10
        STRING  res_string_month_abbrev_11
        STRING  res_string_month_abbrev_12
        ASSERT_RECORD_TABLE_SIZE month_name_table, 12, 3

.proc prepare_year_string
        lda     year
        jsr     number_to_ascii
        sta     year_string+1
        stx     year_string+2
        rts
.endproc

;;; ============================================================
;;; Tear down the window and exit

dialog_result:  .byte   0

.proc destroy
        MGTK_CALL MGTK::CloseWindow, closewindow_params

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
        sizeof_routine = .sizeof(routine)
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
        MGTK_CALL MGTK::InRect, SELF_MODIFIED, test_addr
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
        cpx     #kNumHitRects+1
        bne     loop

        ldx     #0
        rts

done:   pla
        tax
        rts
.endproc

;;; ============================================================
;;; Params for the display

        DEFINE_RECT border_rect, 4, 2, 192, 61

        DEFINE_RECT_SZ date_rect, 32, 15, 122, 20

label_ok:
        PASCAL_STRING res_string_label_ok ; button label
label_cancel:
        PASCAL_STRING res_string_label_cancel ; button label
label_uparrow:
        PASCAL_STRING kGlyphUpArrow ; do not localize
label_downarrow:
        PASCAL_STRING kGlyphDdownArrow ; do not localize

        DEFINE_POINT label_cancel_pos, 21, 56
        DEFINE_POINT label_ok_pos, 110, 56

        DEFINE_POINT label_uparrow_pos, 172, 19
        DEFINE_POINT label_downarrow_pos, 172, 39

.params setpensize_params
penwidth: .byte   1
penheight: .byte   1
.endparams

;;; ============================================================
;;; Render the window contents

.proc draw_window
        MGTK_CALL MGTK::SetPort, winfo::port
        MGTK_CALL MGTK::FrameRect, border_rect
        MGTK_CALL MGTK::SetPenSize, setpensize_params
        MGTK_CALL MGTK::FrameRect, date_rect

        MGTK_CALL MGTK::FrameRect, ok_button_rect
        MGTK_CALL MGTK::MoveTo, label_ok_pos
        param_call DrawString, label_ok

        ;; If there is a system clock, only draw the OK button.
        ldx     clock_flag
        bne     :+

        MGTK_CALL MGTK::FrameRect, cancel_button_rect
        MGTK_CALL MGTK::MoveTo, label_cancel_pos
        param_call DrawString, label_cancel

        MGTK_CALL MGTK::MoveTo, label_uparrow_pos
        param_call DrawString, label_uparrow
        MGTK_CALL MGTK::FrameRect, up_arrow_rect

        MGTK_CALL MGTK::MoveTo, label_downarrow_pos
        param_call DrawString, label_downarrow
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
        param_call DrawString, day_string
        rts
.endproc

.proc draw_month
        MGTK_CALL MGTK::MoveTo, month_pos
        param_call DrawString, spaces_string ; variable width, so clear first
        MGTK_CALL MGTK::MoveTo, month_pos
        param_call DrawString, month_string
        rts
.endproc

.proc draw_year
        MGTK_CALL MGTK::MoveTo, year_pos
        param_call DrawString, year_string
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

;;; ============================================================

        .include "../lib/drawstring.s"

;;; ============================================================

last := *
