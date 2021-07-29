        .include "../config.inc"
        RESOURCE_FILE "show.text.file.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"
        .include "../desktop/icontk.inc"

;;; ============================================================
;;; Memory map
;;;
;;;              Main           Aux
;;;          :           : :           :
;;;          |           | |           |
;;;          | DHR       | | DHR       |
;;;  $2000   +-----------+ +-----------+
;;;          | IO Buffer | |Win Tables |
;;;  $1C00   +-----------+ |           |
;;;  $1B00   |           | +-----------+
;;;          |           | |           |
;;;          | (unused)  | | (unused)  |
;;;          |           | |           |
;;;  $1400   +-----------+ +-----------+
;;;          | buf2      | | buf2 copy | These buffers hold 2 pages of the
;;;  $1300   +-----------+ +-----------+ text file, and are loaded/swapped
;;;          | buf1      | | buf2 copy | as the file is scrolled.
;;;  $1200   +-----------+ +-----------+
;;;          | Font Bkup | |           |
;;;  $1100   +-----------+ |           |
;;;          | (unused)  | |           |
;;;  $1000   +-----------+ |           |
;;;          | IO Buffer | |           |
;;;   $C00   +-----------+ |           |
;;;          |           | |           |
;;;          |           | |           |
;;;          | DA        | | DA (Copy) |
;;;   $800   +-----------+ +-----------+
;;;          :           : :           :
;;;

;;; DeskTop's font is modified to be fixed-width when the mode is toggled;
;;; the original widths are stored in this buffer, and restored on exit
;;; if needed.
font_width_backup       := $1100



;;; ============================================================

        .org DA_LOAD_ADDRESS

.proc start
        INVOKE_PATH := $220
        lda     INVOKE_PATH
    IF_EQ
        rts
    END_IF
        COPY_STRING INVOKE_PATH, pathbuf

        ;; Set window title to filename
        ldy     pathbuf
:       lda     pathbuf,y       ; find last '/'
        cmp     #'/'
        beq     :+
        dey
        bne     :-
:       ldx     #1
:       lda     pathbuf+1,y     ; copy filename
        sta     titlebuf,x
        inx
        iny
        cpy     pathbuf
        bne     :-
        stx     titlebuf

        jmp     copy2aux
.endproc


save_stack:.byte   0

;;; Copy $800 through $13FF (the DA) to aux
.proc copy2aux
        tsx
        stx     save_stack
        sta     RAMWRTON
        ldy     #0
src:    lda     start,y         ; self-modified
dst:    sta     start,y         ; self-modified
        dey
        bne     src
        sta     RAMWRTOFF
        inc     src+2
        inc     dst+2
        sta     RAMWRTON
        lda     dst+2
        cmp     #$14
        bne     src
.endproc

call_main_trampoline   := $20 ; installed on ZP, turns off auxmem and calls...
call_main_addr         := call_main_trampoline+7        ; address patched in here

;;; Copy the following "call_main_template" routine to $20
.scope
        sta     RAMWRTON
        sta     RAMRDON
        COPY_BYTES sizeof_call_main_template+1, call_main_template, call_main_trampoline
        jmp     call_init
.endscope

.proc call_main_template
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     SELF_MODIFIED   ; overwritten (in zp version)
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc
        sizeof_call_main_template = .sizeof(call_main_template)

.macro TRAMP_CALL addr
        copy16  #addr, call_main_addr
        jsr     call_main_trampoline
.endmacro

.macro TRAMP_CALL_WITH_A addr
        pha
        copy16  #addr, call_main_addr
        pla
        jsr     call_main_trampoline
.endmacro

;;; ============================================================

.proc call_init
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
;;; ProDOS MLI calls

.proc open_file
        jsr     copy_params_aux_to_main
        sta     ALTZPOFF
        MLI_CALL OPEN, open_params
        sta     ALTZPON
        jsr     copy_params_main_to_aux
        rts
.endproc

.proc read_file
        jsr     copy_params_aux_to_main
        sta     ALTZPOFF
        MLI_CALL READ, read_params
        sta     ALTZPON
        jsr     copy_params_main_to_aux
        rts
.endproc

.proc get_file_eof
        jsr     copy_params_aux_to_main
        sta     ALTZPOFF
        MLI_CALL GET_EOF, get_eof_params
        sta     ALTZPON
        jsr     copy_params_main_to_aux
        rts
.endproc

.proc set_file_mark
        jsr     copy_params_aux_to_main
        sta     ALTZPOFF
        MLI_CALL SET_MARK, set_mark_params
        sta     ALTZPON
        jsr     copy_params_main_to_aux
        rts
.endproc

.proc close_file
        jsr     copy_params_aux_to_main
        sta     ALTZPOFF
        MLI_CALL CLOSE, close_params
        sta     ALTZPON
        jsr     copy_params_main_to_aux
        rts
.endproc

;;; ============================================================

;;; Copies param blocks from Aux to Main
.proc copy_params_aux_to_main
        ldy     #(params_end - params_start + 1)
        sta     RAMWRTOFF
loop:   lda     params_start - 1,y
        sta     params_start - 1,y
        dey
        bne     loop
        sta     RAMRDOFF
        rts
.endproc

;;; Copies param blocks from Main to Aux
.proc copy_params_main_to_aux
        pha
        php
        sta     RAMWRTON
        ldy     #(params_end - params_start + 1)
loop:   lda     params_start - 1,y
        sta     params_start - 1,y
        dey
        bne     loop
        sta     RAMRDON
        plp
        pla
        rts
.endproc

;;; ----------------------------------------

params_start:
;;; This block gets copied between main/aux

;;; ProDOS MLI param blocks

;;; Two pages of data are read, but separately.
default_buffer  := $1200
kReadLength      = $0100

        DEFINE_OPEN_PARAMS open_params, pathbuf, DA_IO_BUFFER
        DEFINE_READ_PARAMS read_params, default_buffer, kReadLength
        DEFINE_GET_EOF_PARAMS get_eof_params
        DEFINE_SET_MARK_PARAMS set_mark_params, 0
        DEFINE_CLOSE_PARAMS close_params

pathbuf:        .res    kPathBufferSize, 0

L0945:  .byte   $00
L0946:  .byte   $00
L0947:  .byte   $00
L0948:  .byte   $00
L0949:  .byte   $00

params_end := * + 4       ; bug in original? (harmless as this is static)
;;; ----------------------------------------

black_pattern:
        .res    8, $00

white_pattern:
        .res    $8, $FF

        kDAWindowId = 100

        kLineSpacing = 10
        kRightConst = 506

L095A:  .byte   $00
L095B:  .word   kRightConst

.params line_pos
left:   .word   0
base:   .word   0
.endparams

window_width:   .word   0
window_height:  .word   0

y_remaining:    .word   0
line_count:     .word   0
L096A:  .word   0
L096C:  .word   0

track_scroll_delta:
        .byte   $00

fixed_mode_flag:
        .byte   $00             ; 0 = proportional, otherwise = fixed

.params event_params
kind:  .byte   0

;;; if state is MGTK::EventKind::key_down
key             := *
modifiers       := *+1

;;; otherwise
coords  := *
mousex  := *                      ; spills into target query
mousey  := *+2

        .res    4               ; space for both
.endparams

.params findwindow_params
which_area:   .byte   0
window_id:    .byte   0
.endparams

.params growwindow_params
window_id:     .byte   kDAWindowId
mousex: .word   0
mousey: .word   0
it_grew:        .byte   0
.endparams

.params trackgoaway_params ; queried after close clicked to see if aborted/finished
goaway: .byte   0        ; 0 = aborted, 1 = clicked
.endparams

        .byte   0,0             ; ???

.params findcontrol_params        ; queried after a client click to identify target
mousex: .word   0
mousey: .word   0
which_ctl:      .byte   0       ; 0 = client, 1 = vscroll, 2 = hscroll
which_part:     .byte   0       ; 1 = up, 2 = down, 3 = above, 4 = below, 5 = thumb
.endparams

.params updatethumb_params      ; called to update scroll bar position
which_ctl:   .byte   0               ; 1 = vscroll, 2 = hscroll
thumbpos:    .byte   0               ; new position
.endparams

;;; Used when dragging vscroll thumb
.params trackthumb_params
which_ctl:   .byte   0               ; 1 = vscroll, 2 = hscroll
mousex: .word   0
mousey: .word   0
thumbpos:    .byte   0               ; position
thumbmoved:  .byte   0               ; 0 if not moved, 1 if moved
.endparams

.params drawtext_params
textptr:        .addr   0       ; address
textlen:        .byte   0       ; length
.endparams

kDefaultLeft    = 10
kDefaultTop     = 28
kDefaultWidth   = 512
kDefaultHeight  = 150

titlebuf:
        .res    16, 0

.params winfo
window_id:      .byte   kDAWindowId ; window identifier
options:        .byte   MGTK::Option::go_away_box ; window flags (2=include close port)
title:          .addr   titlebuf
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_normal
hthumbmax:      .byte   32
hthumbpos:      .byte   0
vthumbmax:      .byte   255
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   200
mincontlength:  .word   51
maxcontwidth:   .word   kDefaultWidth
maxcontlength:  .word   kDefaultHeight
port:
        DEFINE_POINT viewloc, kDefaultLeft, kDefaultTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDefaultWidth, kDefaultHeight
pattern:        .res    8, $00
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams


        ;; gets copied over winfo::port after mode is drawn
.params default_port
        DEFINE_POINT viewloc, kDefaultLeft, kDefaultTop
mapbits:        .word   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kDefaultWidth, kDefaultHeight
.endparams

.proc init
        lda     #0
        sta     fixed_mode_flag

        ;; make backup of font width table; overwritten if fixed
        ldx     DEFAULT_FONT + MGTK::Font::lastchar
        sta     RAMWRTOFF
loop:   lda     DEFAULT_FONT + MGTK::Font::charwidth - 1,x
        sta     font_width_backup - 1,x
        dex
        bne     loop
        sta     RAMWRTON

        ;; open file, get length
        jsr     open_file
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     set_mark_params::ref_num
        sta     get_eof_params::ref_num
        sta     close_params::ref_num
        jsr     get_file_eof

        ;; create window
        MGTK_CALL MGTK::OpenWindow, winfo
        MGTK_CALL MGTK::SetPort, winfo::port
        jsr     calc_window_size
        jsr     calc_and_draw_mode
        jsr     draw_content
        MGTK_CALL MGTK::FlushEvents
        ;; fall through
.endproc

;;; ============================================================
;;; Main Input Loop

.proc input_loop
        jsr     yield_loop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params
        cmp     #MGTK::EventKind::key_down    ; key?
        beq     on_key_down
        cmp     #MGTK::EventKind::button_down ; was clicked?
        bne     input_loop      ; nope, keep waiting

        MGTK_CALL MGTK::FindWindow, event_params::coords
        lda     findwindow_params::window_id ; in our window?
        cmp     #kDAWindowId
        bne     input_loop

        ;; which part of the window?
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        bne     :+
        jmp     on_close_click

        ;; title and resize clicks need mouse location
:       ldx     event_params::mousex
        stx     growwindow_params::mousex
        stx     findcontrol_params::mousex
        ldx     event_params::mousex+1
        stx     growwindow_params::mousex+1
        stx     findcontrol_params::mousex+1
        ldx     event_params::mousey
        stx     growwindow_params::mousey
        stx     findcontrol_params::mousey

        cmp     #MGTK::Area::dragbar
        beq     title
        cmp     #MGTK::Area::grow_box ; not enabled, so this will never match
        beq     input_loop
        jsr     on_client_click
        jmp     input_loop

title:  jsr     on_title_bar_click
        jmp     input_loop
.endproc

.proc yield_loop
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_YIELD_LOOP
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

;;; ============================================================
;;; Key

.proc on_key_down
        lda     event_params::modifiers
        beq     no_mod

        ;; Modifiers
        lda     event_params::key

        cmp     #CHAR_DOWN      ; Apple-Down = Page Down
        bne     :+
        jsr     page_down
        jmp     input_loop

:       cmp     #CHAR_UP        ; Apple-Up = Page Up
        bne     :+
        jsr     page_up
        jmp     input_loop

:       cmp     #CHAR_LEFT      ; Apple-Left = Home
        bne     :+
        jsr     scroll_top
        jmp     input_loop

:       cmp     #CHAR_RIGHT     ; Apple-Right = End
        bne     :+
        jsr     scroll_bottom

:       jmp     input_loop

        ;; No modifiers
no_mod:
        lda     event_params::key

        cmp     #CHAR_ESCAPE
        bne     :+
        jmp     do_close

:       cmp     #' '
        bne     :+
        jsr     toggle_mode
        jmp     input_loop

:       cmp     #CHAR_DOWN
        bne     :+
        jsr     scroll_down
        jmp     input_loop

:       cmp     #CHAR_UP
        bne     :+
        jsr     scroll_up

:       jmp     input_loop
.endproc

;;; ============================================================
;;; Close Button

.proc on_close_click
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway ; did click complete?
        bne     do_close        ; yes
        jmp     input_loop      ; no
.endproc

.proc do_close
        jsr     close_file
        MGTK_CALL MGTK::CloseWindow, winfo
        rts                     ; exits input loop
.endproc

;;; ============================================================
;;; Client Area

;;; Non-title (client) area clicked
.proc on_client_click
        ;; On one of the scroll bars?
        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        beq     on_vscroll_click
end:    rts
.endproc

;;; ============================================================
;;; Vertical Scroll Bar

.proc on_vscroll_click
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     trackthumb_params::which_ctl
        sta     updatethumb_params::which_ctl
        lda     findcontrol_params::which_part
        cmp     #MGTK::Part::thumb
        beq     on_vscroll_thumb_click
        cmp     #MGTK::Part::page_down
        beq     on_vscroll_below_click
        cmp     #MGTK::Part::page_up
        beq     on_vscroll_above_click
        cmp     #MGTK::Part::up_arrow
        beq     on_vscroll_up_click
        cmp     #MGTK::Part::down_arrow
        bne     end
        jmp     on_vscroll_down_click
end:    rts
.endproc

.proc on_vscroll_thumb_click
        jsr     do_trackthumb
        lda     trackthumb_params::thumbmoved
        beq     end
        lda     trackthumb_params::thumbpos
        sta     updatethumb_params::thumbpos
        jsr     update_voffset
        jsr     update_vscroll
        jsr     draw_content
        lda     L0947
        beq     end
        lda     L0949
        bne     end
        jsr     clear_window
end:    rts
.endproc

.proc on_vscroll_above_click
loop:   jsr     page_up
        jsr     check_button_release
        bcc     loop            ; repeat while button down
end:    rts
.endproc

.proc page_up
        lda     winfo::vthumbpos
        beq     end
        jsr     calc_track_scroll_delta
        sec
        lda     winfo::vthumbpos
        sbc     track_scroll_delta
        bcs     store
        lda     #0              ; underflow
store:  sta     updatethumb_params::thumbpos
        jsr     update_scroll_pos
end:    rts
.endproc

.proc on_vscroll_up_click
loop:   jsr     scroll_up
        jsr     check_button_release
        bcc     loop            ; repeat while button down
end:    rts
.endproc

.proc scroll_up
        lda     winfo::vthumbpos
        beq     end
        sec
        sbc     #1
        sta     updatethumb_params::thumbpos
        jsr     update_scroll_pos
end:    rts
.endproc

.proc scroll_top
        lda     winfo::vthumbpos
        beq     end
        copy    #0, updatethumb_params::thumbpos
        jsr     update_scroll_pos
end:    rts
.endproc

kVScrollMax = $FA

.proc on_vscroll_below_click
loop:   jsr     page_down
        jsr     check_button_release
        bcc     loop            ; repeat while button down
end:    rts
.endproc

.proc page_down
        lda     winfo::vthumbpos
        cmp     #kVScrollMax    ; pos == max ?
        beq     end
        jsr     calc_track_scroll_delta
        clc
        lda     winfo::vthumbpos
        adc     track_scroll_delta ; pos + delta
        bcs     overflow
        cmp     #kVScrollMax+1  ; > max ?
        bcc     store           ; nope, it's good
overflow:
        lda     #kVScrollMax    ; set to max
store:  sta     updatethumb_params::thumbpos
        jsr     update_scroll_pos
end:    rts
.endproc

.proc on_vscroll_down_click
loop:   jsr     scroll_down
        jsr     check_button_release
        bcc     loop            ; repeat while button down
end:    rts
.endproc

.proc scroll_down
        lda     winfo::vthumbpos
        cmp     #kVScrollMax
        beq     end
        clc
        adc     #1
        sta     updatethumb_params::thumbpos
        jsr     update_scroll_pos
end:    rts
.endproc

.proc scroll_bottom
        lda     winfo::vthumbpos
        cmp     #kVScrollMax
        beq     end
        copy    #kVScrollMax, updatethumb_params::thumbpos
        jsr     update_scroll_pos
end:    rts
.endproc

.proc update_scroll_pos         ; Returns with carry set if mouse released
        jsr     update_voffset
        jsr     update_vscroll
        jsr     draw_content
        rts
.endproc

.proc check_button_release
        jsr     was_button_released
        clc
        bne     end
        sec
end:    rts
.endproc

.proc calc_track_scroll_delta
        lda     window_height   ; ceil(height / 50)
        ldx     #0
loop:   inx
        sec
        sbc     #50
        cmp     #50
        bcs     loop
        stx     track_scroll_delta
        rts
.endproc

;;; ============================================================
;;; UI Helpers

        ;; Used at start of thumb EventKind::drag
.proc do_trackthumb
        copy16  event_params::mousex, trackthumb_params::mousex
        lda     event_params::mousey
        sta     trackthumb_params::mousey
        MGTK_CALL MGTK::TrackThumb, trackthumb_params
        rts
.endproc

;;; Checks button state; z clear if button was released, set otherwise
.proc was_button_released
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params
        cmp     #2
        rts
.endproc

;;; only used from hscroll code?
.proc adjust_box_width

        res := $06
        lda     winfo::hthumbpos
        jsr     mul_by_16
        clc
        lda     res
        sta     winfo::maprect::x1
        adc     window_width
        sta     winfo::maprect::x2
        lda     res+1
        sta     winfo::maprect::x1+1
        adc     window_width+1
        sta     winfo::maprect::x2+1
        rts
.endproc

.proc update_voffset
        lda     #0
        sta     winfo::maprect::y1
        sta     winfo::maprect::y1+1
        ldx     updatethumb_params::thumbpos
loop:   beq     adjust_box_height
        clc
        lda     winfo::maprect::y1
        adc     #50
        sta     winfo::maprect::y1
        bcc     :+
        inc     winfo::maprect::y1+1
:       dex
        jmp     loop
.endproc

.proc adjust_box_height
        clc
        lda     winfo::maprect::y1
        adc     window_height
        sta     winfo::maprect::y2
        lda     winfo::maprect::y1+1
        adc     window_height+1
        sta     winfo::maprect::y2+1
        jsr     calc_line_position
        lda     #0
        sta     L096A
        sta     L096A+1
        ldx     updatethumb_params::thumbpos
loop:   beq     end
        clc
        lda     L096A
        adc     #5
        sta     L096A
        bcc     :+
        inc     L096A+1
:       dex
        jmp     loop
end:    rts
.endproc

.proc update_hscroll
        lda     #2
        sta     updatethumb_params::which_ctl

        val := $06
        copy16  winfo::maprect::x1, val
        jsr     div_by_16
        sta     updatethumb_params::thumbpos
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        rts
.endproc

.proc update_vscroll            ; updatethumb_params::thumbpos set by caller
        lda     #1
        sta     updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        rts
.endproc

.proc finish_resize             ; only called from dead code
        MGTK_CALL MGTK::SetPort, winfo::port
        lda     winfo::hscroll
        ror     a               ; check if low bit (track enabled) is set
        bcc     :+
        jsr     update_hscroll
:       lda     winfo::vthumbpos
        sta     updatethumb_params::thumbpos
        jsr     update_vscroll
        jsr     draw_content
        jmp     input_loop
.endproc

.proc clear_window
        MGTK_CALL MGTK::SetPattern, white_pattern
        MGTK_CALL MGTK::PaintRect, winfo::maprect::x1
        MGTK_CALL MGTK::SetPattern, black_pattern
        rts
.endproc

;;; ============================================================
;;; Content Rendering

.proc draw_content
        ptr := $06

        lda     #0
        sta     L0949
        jsr     assign_fixed_font_width_table_if_needed
        jsr     set_file_mark
        lda     #<default_buffer
        sta     read_params::data_buffer
        sta     ptr
        lda     #>default_buffer
        sta     read_params::data_buffer+1
        sta     ptr+1
        lda     #0
        sta     L0945
        sta     L0946
        sta     L0947
        sta     line_pos::base+1
        sta     L096C
        sta     L096C+1
        sta     L0948
        lda     #kLineSpacing
        sta     line_pos::base
        jsr     reset_line

do_line:
        lda     L096C+1
        cmp     L096A+1
        bne     :+
        lda     L096C
        cmp     L096A
        bne     :+
        jsr     clear_window
        inc     L0948
:       MGTK_CALL MGTK::MoveTo, line_pos
        sec
        lda     #250
        sbc     line_pos::left
        sta     L095B
        lda     #1
        sbc     line_pos::left+1
        sta     L095B+1
        jsr     find_text_run
        bcs     done
        clc
        lda     drawtext_params::textlen
        adc     ptr
        sta     ptr
        bcc     :+
        inc     ptr+1
:       lda     L095A
        bne     do_line
        clc
        lda     line_pos::base
        adc     #kLineSpacing
        sta     line_pos::base
        bcc     :+
        inc     line_pos::base+1
:       jsr     reset_line
        lda     L096C
        cmp     line_count
        bne     :+
        lda     L096C+1
        cmp     line_count+1
        beq     done
:       inc     L096C
        bne     :+
        inc     L096C+1
:       jmp     do_line

done:   jsr     restore_proportional_font_table_if_needed
        rts
.endproc

;;; ============================================================

.proc reset_line
        copy16  #kRightConst, L095B
        copy16  #3, line_pos::left
        sta     L095A
        rts
.endproc

;;; ============================================================

.proc find_text_run
        ptr := $06

        lda     #$FF
        sta     L0F9B
        lda     #0
        sta     run_width
        sta     run_width+1
        sta     L095A
        sta     drawtext_params::textlen
        copy16  ptr, drawtext_params::textptr

loop:   lda     L0945
        bne     more
        lda     L0947
        beq     :+
        jsr     draw_text_run
        sec
        rts

:       jsr     ensure_page_buffered
more:   ldy     drawtext_params::textlen
        lda     (ptr),y
        and     #CHAR_MASK
        sta     (ptr),y
        inc     L0945
        cmp     #CHAR_RETURN
        beq     finish_text_run
        cmp     #' '
        bne     :+
        sty     L0F9B
        pha
        lda     L0945
        sta     L0946
        pla
:       cmp     #CHAR_TAB
        bne     :+
        jmp     handle_tab

:       tay
        lda     DEFAULT_FONT + MGTK::Font::charwidth,y
        clc
        adc     run_width
        sta     run_width
        bcc     :+
        inc     run_width+1
:       lda     L095B+1
        cmp     run_width+1
        bne     :+
        lda     L095B
        cmp     run_width
:       bcc     :+
        inc     drawtext_params::textlen
        jmp     loop

:       lda     #0
        sta     L095A
        lda     L0F9B
        cmp     #$FF
        beq     :+
        sta     drawtext_params::textlen
        lda     L0946
        sta     L0945
:       inc     drawtext_params::textlen
        ;; fall through
.endproc

.proc finish_text_run
        ptr := $06

        jsr     draw_text_run
        ldy     drawtext_params::textlen
        lda     (ptr),y
        cmp     #CHAR_TAB
        beq     tab
        cmp     #CHAR_RETURN
        bne     :+
tab:    inc     drawtext_params::textlen
:       clc
        rts
.endproc

;;; ============================================================

L0F9B:  .byte   0
run_width:  .word   0

.proc handle_tab
        lda     #1
        sta     L095A
        clc
        lda     run_width
        adc     line_pos::left
        sta     line_pos::left
        lda     run_width+1
        adc     line_pos::left+1
        sta     line_pos::left+1
        ldx     #0
loop:   lda     times70+1,x
        cmp     line_pos::left+1
        bne     :+
        lda     times70,x
        cmp     line_pos::left
:       bcs     :+
        inx
        inx
        cpx     #14
        beq     done
        jmp     loop
:       copy16  times70,x, line_pos::left
        jmp     finish_text_run
done:   lda     #0
        sta     L095A
        jmp     finish_text_run

times70:.word   70
        .word   140
        .word   210
        .word   280
        .word   350
        .word   420
        .word   490
.endproc

;;; ============================================================
;;; Draw a line of content

.proc draw_text_run
        lda     L0948
        beq     end
        lda     drawtext_params::textlen
        beq     end
        MGTK_CALL MGTK::DrawText, drawtext_params
        lda     #1
        sta     L0949
end:    rts
.endproc

;;; ============================================================

.proc ensure_page_buffered
        ptr := $06

        ;; Pointing at second page already?
        lda     drawtext_params::textptr+1
        cmp     #>default_buffer
        beq     read

        ;; No, shift second page down.
        ldy     #0
loop:   lda     default_buffer+$100,y
        sta     default_buffer,y
        iny
        bne     loop

        dec     drawtext_params::textptr+1
        copy16  drawtext_params::textptr, ptr

        ;; Read into second page.
read:   lda     #0
        sta     L0945
        jsr     read_file_page
        lda     read_params::data_buffer+1
        cmp     #>default_buffer
        bne     :+
        inc     read_params::data_buffer+1
:       rts
.endproc

;;; ============================================================

.proc read_file_page
        copy16  read_params::data_buffer, @store_addr

        lda     #' '            ; fill buffer with spaces
        ldx     #0
        sta     RAMWRTOFF

        @store_addr := *+1
store:  sta     default_buffer,x         ; self-modified
        inx
        bne     store

        sta     RAMWRTON        ; read file chunk
        lda     #0
        sta     L0947
        jsr     read_file

        pha                     ; copy read buffer main>aux
        lda     #$00
        sta     STARTLO
        sta     DESTINATIONLO
        lda     #$FF
        sta     ENDLO
        lda     read_params::data_buffer+1
        sta     DESTINATIONHI
        sta     STARTHI
        sta     ENDHI
        sec                     ; main>aux
        jsr     AUXMOVE
        pla

        beq     end
        cmp     #ERR_END_OF_FILE
        beq     done
        brk                     ; crash on other error
done:   lda     #1
        sta     L0947
end:    rts
.endproc

.proc calc_window_size
        sec
        lda     winfo::maprect::x2
        sbc     winfo::maprect::x1
        sta     window_width
        lda     winfo::maprect::x2+1
        sbc     winfo::maprect::x1+1
        sta     window_width+1

        sec
        lda     winfo::maprect::y2
        sbc     winfo::maprect::y1
        sta     window_height
        ;; fall through
.endproc

;;; ============================================================

.proc calc_line_position
        copy16  winfo::maprect::y2, y_remaining

        lda     #0
        sta     line_count
        sta     line_count+1

loop:   lda     y_remaining+1
        bne     :+
        lda     y_remaining
        cmp     #kLineSpacing
        bcc     end

:       sec
        lda     y_remaining
        sbc     #kLineSpacing
        sta     y_remaining
        bcs     :+
        dec     y_remaining+1
:       inc     line_count
        bne     loop
        inc     line_count+1
        jmp     loop

end:    rts
.endproc

;;; ============================================================

.proc div_by_16                 ; input in $06/$07, output in a
        val := $06

        ldx     #4
loop:   clc
        ror     val+1
        ror     val
        dex
        bne     loop
        lda     val
        rts
.endproc

.proc mul_by_16                 ; input in a, output in $06/$07
        res := $06

        sta     res
        lda     #0
        sta     res+1
        ldx     #4
loop:   clc
        rol     res
        rol     res+1
        dex
        bne     loop
        rts
.endproc

.proc redraw_screen
        TRAMP_CALL JUMP_TABLE_CLEAR_UPDATES_REDRAW_ICONS
        rts
.endproc

;;; ============================================================
;;; Restore the font glyph width table when switching
;;; back to proportional mode.

.proc restore_proportional_font_table_if_needed
        lda     fixed_mode_flag ; if not fixed (i.e. proportional)
        beq     done            ; then exit

        start := font_width_backup
        end   := font_width_backup + $7E
        dest  := DEFAULT_FONT + MGTK::Font::charwidth

        lda     #<start
        sta     STARTLO
        lda     #<end
        sta     ENDLO
        lda     #>start
        sta     STARTHI
        sta     ENDHI

        lda     #>dest
        sta     DESTINATIONHI
        lda     #<dest
        sta     DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE
done:   rts
.endproc

;;; ============================================================
;;; Overwrite the font glyph width table (with 7s)
;;; when switching to fixed width mode.

.proc assign_fixed_font_width_table_if_needed
        lda     fixed_mode_flag ; if not fixed (i.e. proportional)
        beq     end             ; then exit
        ldx     DEFAULT_FONT + MGTK::Font::lastchar
        lda     #7              ; 7 pixels/character
loop:   sta     DEFAULT_FONT + MGTK::Font::charwidth - 1,x
        dex
        bne     loop
end:    rts
.endproc

;;; ============================================================
;;; Title Bar (Proportional/Fixed mode button)

.proc on_title_bar_click
        lda     event_params::mousex+1           ; mouse x high byte?
        cmp     mode_mapinfo_viewloc_xcoord+1
        bne     :+
        lda     event_params::mousex
        cmp     mode_mapinfo_viewloc_xcoord
:       bcs     toggle_mode
        clc                     ; Click ignored
        rts
.endproc

.proc toggle_mode
        ;; Toggle the state and redraw
        lda     fixed_mode_flag
        beq     set_flag
        dec     fixed_mode_flag ; clear flag (mode = proportional)
        jsr     restore_proportional_font_table_if_needed
        jmp     redraw

set_flag:
        inc     fixed_mode_flag ; set flag (mode = fixed)
redraw: jsr     draw_mode
        jsr     draw_content
        sec                     ; Click consumed
        rts
.endproc

;;; ============================================================

fixed_str:      PASCAL_STRING res_string_button_fixed
prop_str:       PASCAL_STRING res_string_button_prop
        kLabelWidth = 50

.params mode_mapinfo                  ; bounding port for mode label
        DEFINE_POINT viewloc, 0, 0
mapbits:        .word   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 80, 10
.endparams
mode_mapinfo_viewloc_xcoord := mode_mapinfo::viewloc::xcoord

.params mode_pos
left:   .word   0               ; horizontal text offset
base:   .word   10              ; vertical text offset (to baseline)
.endparams

;;; ============================================================

.proc calc_and_draw_mode
        sec
        lda     winfo::viewloc::ycoord
        sbc     #kTitleBarHeight
        sta     mode_mapinfo::viewloc::ycoord
        clc
        lda     winfo::viewloc::xcoord
        adc     window_width
        pha
        lda     winfo::viewloc::xcoord+1
        adc     window_width+1
        tax
        sec
        pla
        sbc     #<kLabelWidth
        sta     mode_mapinfo::viewloc::xcoord
        txa
        sbc     #>kLabelWidth
        sta     mode_mapinfo::viewloc::xcoord+1
        ;; fall through...
.endproc

.proc draw_mode
        MGTK_CALL MGTK::SetPortBits, mode_mapinfo
        MGTK_CALL MGTK::MoveTo, mode_pos
        lda     fixed_mode_flag
        beq     else            ; is proportional?
        param_call DrawString, fixed_str
        jmp     endif
else:   param_call DrawString, prop_str

endif:  COPY_STRUCT MGTK::MapInfo, default_port, winfo::port
        MGTK_CALL MGTK::SetPortBits, winfo::port
        rts
.endproc

;;; ============================================================

        .include "../lib/drawstring.s"

;;; ============================================================

        .assert * <= default_buffer, error, "DA overlaps with read buffer"
