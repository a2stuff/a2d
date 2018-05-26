        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

;;; ============================================================

        .org $800

        dummy1000 := $1000


;;; Modified to toggle fixed width
font_type       := DEFAULT_FONT+0
font_last_char  := DEFAULT_FONT+1
font_height     := DEFAULT_FONT+2
font_width_table := DEFAULT_FONT+3 ; width in pixels, indexed by ASCII code


start:  jmp     copy2aux

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
        ldx     #sizeof_call_main_template
loop:   lda     call_main_template,x
        sta     call_main_trampoline,x
        dex
        bpl     loop
        jmp     call_init
.endscope

.proc call_main_template
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     dummy1000       ; overwritten (in zp version)
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc
        sizeof_call_main_template := * - call_main_template

.proc call_init
        ;; run the DA
        jsr     init

        ;; tear down/exit
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
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

io_buf          := $0C00
default_buffer  := $1200
read_length     := $0100

        DEFINE_OPEN_PARAMS open_params, pathbuf, io_buf
        DEFINE_READ_PARAMS read_params, default_buffer, read_length
        DEFINE_GET_EOF_PARAMS get_eof_params
        DEFINE_SET_MARK_PARAMS set_mark_params, 0
        DEFINE_CLOSE_PARAMS close_params

pathbuf:        .res    65, 0

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

        da_window_id := 100

        line_spacing := 10
        right_const := 506

L095A:  .byte   $00
L095B:  .word   right_const

.proc line_pos
left:   .word   0
base:   .word   0
.endproc

window_width:  .word   0
window_height: .word   0

y_remaining:  .word   0
unused: .byte   0
line_count:  .word   0
L096A:  .word   0
L096C:  .word   0

track_scroll_delta:
        .byte   $00

fixed_mode_flag:
        .byte   $00             ; 0 = proportional, otherwise = fixed

.proc event_params
kind:  .byte   0
coords:                         ; spills into target query
mousex: .word   0
mousey: .word   0
.endproc

.proc findwindow_params
which_area:   .byte   0
window_id:    .byte   0
.endproc

.proc growwindow_params
window_id:     .byte   da_window_id
mousex: .word   0
mousey: .word   0
it_grew:        .byte   0
.endproc

.proc trackgoaway_params ; queried after close clicked to see if aborted/finished
goaway: .byte   0        ; 0 = aborted, 1 = clicked
.endproc

        .byte   0,0             ; ???

.proc findcontrol_params        ; queried after a client click to identify target
mousex: .word   0
mousey: .word   0
which_ctl:      .byte   0       ; 0 = client, 1 = vscroll, 2 = hscroll
which_part:     .byte   0       ; 1 = up, 2 = down, 3 = above, 4 = below, 5 = thumb
.endproc

        ;; param block used in dead code (resize?)
.proc setctlmax_params
which_ctl:      .byte   0
ctlmax:         .byte   0
        ;; needs one more byte?
.endproc

.proc updatethumb_params      ; called to update scroll bar position
which_ctl:   .byte   0               ; 1 = vscroll, 2 = hscroll
thumbpos:    .byte   0               ; new position
.endproc

;;; Used when dragging vscroll thumb
.proc trackthumb_params
which_ctl:   .byte   0               ; 1 = vscroll, 2 = hscroll
mousex: .word   0
mousey: .word   0
thumbpos:    .byte   0               ; position
thumbmoved:  .byte   0               ; 0 if not moved, 1 if moved
.endproc

.proc drawtext_params
textptr:        .addr   0       ; address
textlen:        .byte   0       ; length
.endproc

        default_width := 512
        default_height := 150
        default_left := 10
        default_top := 28

.proc winfo
window_id:      .byte   da_window_id ; window identifier
options:        .byte   MGTK::option_go_away_box ; window flags (2=include close port)
title:          .addr   dummy1000 ; overwritten to point at filename
hscroll:        .byte   MGTK::scroll_option_none
vscroll:        .byte   MGTK::scroll_option_normal
hthumbmax:      .byte   32
hthumbpos:      .byte   0
vthumbmax:      .byte   255
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   200
mincontlength:  .word   51
maxcontwidth:   .word   default_width
maxcontlength:  .word   default_height
port:
viewloc:        DEFINE_POINT default_left, default_top, viewloc
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
maprect:        DEFINE_RECT 0, 0, default_width, default_height, maprect
pattern:        .res    8, $00
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endproc


        ;; gets copied over winfo::port after mode is drawn
.proc default_port
viewloc:        DEFINE_POINT default_left, default_top
mapbits:        .word   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
maprect:        DEFINE_RECT 0, 0, default_width, default_height
.endproc

.proc init
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        ;; Get filename by checking DeskTop selected window/icon

        ;; Check that an icon is selected
        lda     #0
        sta     pathbuf
        lda     selected_file_count
        beq     abort           ; some file properties?
        lda     path_index      ; prefix index in table
        bne     :+
abort:  rts

        ;; Copy path (prefix) into pathbuf.
:       src := $06
        dst := $08

        asl     a               ; (since address table is 2 bytes wide)
        tax
        copy16  path_table,x, src
        ldy     #0
        lda     (src),y
        tax
        inc     src
        bne     :+
        inc     src+1
:       copy16  #pathbuf+1, dst
        jsr     copy_pathbuf   ; copy x bytes (src) to (dst)

        ;; Append separator.
        lda     #'/'
        ldy     #0
        sta     (dst),y
        inc     pathbuf
        inc     dst
        bne     :+
        inc     dst+1

        ;; Get file entry.
:       lda     selected_file_list      ; file index in table
        asl     a               ; (since table is 2 bytes wide)
        tax
        copy16  file_table,x, src

        ;; Exit if a directory.
        ldy     #2              ; 2nd byte of entry
        lda     (src),y
        and     #$70            ; check that one of bits 4,5,6 is set ???
        ;; some vague patterns, but unclear
        ;; basic = $32,$33, text = $52, sys = $11,$14,??, bin = $23,$24,$33
        ;; dir = $01 (so not shown)
        bne     :+
        rts                     ; abort ???

        ;; Set window title to point at filename (9th byte of entry)
        ;; (title includes the spaces before/after from the icon)
:       clc
        lda     src             ; name is 9 bytes into entry
        adc     #9
        sta     winfo::title
        lda     src+1
        adc     #0
        sta     winfo::title+1

        ;; Append filename to path.
        ldy     #9
        lda     (src),y         ; grab length
        tax                     ; name has spaces before/after
        dex                     ; so subtract 2 to get actual length
        dex
        clc
        lda     src
        adc     #11             ; 9 = length, 10 = space, 11 = name
        sta     src
        bcc     :+
        inc     src+1
:       jsr     copy_pathbuf    ; copy x bytes (src) to (dst)

        ;; Clear selection (why???)
        copy16  #JUMP_TABLE_CLEAR_SEL, call_main_addr
        jsr     call_main_trampoline

        jmp     open_file_and_init_window

.proc copy_pathbuf              ; copy x bytes from src to dst
        ldy     #0              ; incrementing path length and dst
loop:   lda     (src),y
        sta     (dst),y
        iny
        inc     pathbuf
        dex
        bne     loop
        tya
        clc
        adc     dst
        sta     dst
        bcc     end
        inc     dst+1
end:    rts
.endproc

.endproc

        font_width_backup := $1100

.proc open_file_and_init_window
        lda     #0
        sta     fixed_mode_flag

        ;; make backup of font width table; overwritten if fixed
        ldx     font_last_char
        sta     RAMWRTOFF
loop:   lda     font_width_table - 1,x
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

input_loop:
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params
        cmp     #1              ; was clicked?
        bne     input_loop      ; nope, keep waiting

        MGTK_CALL MGTK::FindWindow, event_params::coords
        lda     findwindow_params::window_id ; in our window?
        cmp     #da_window_id
        bne     input_loop

        ;; which part of the window?
        lda     findwindow_params::which_area
        cmp     #MGTK::area_close_box
        beq     on_close_click

        ;; title and resize clicks need mouse location
        ldx     event_params::mousex
        stx     growwindow_params::mousex
        stx     findcontrol_params::mousex
        ldx     event_params::mousex+1
        stx     growwindow_params::mousex+1
        stx     findcontrol_params::mousex+1
        ldx     event_params::mousey
        stx     growwindow_params::mousey
        stx     findcontrol_params::mousey

        cmp     #MGTK::area_dragbar
        beq     title
        cmp     #MGTK::area_grow_box ; not enabled, so this will never match
        beq     input_loop
        jsr     on_client_click
        jmp     input_loop

title:  jsr     on_title_bar_click
        jmp     input_loop

;;; ============================================================
;;; Close Button

.proc on_close_click
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway ; did click complete?
        beq     input_loop      ; nope
        jsr     close_file
        MGTK_CALL MGTK::CloseWindow, winfo
        DESKTOP_CALL DT_REDRAW_ICONS
        rts                     ; exits input loop
.endproc

;;; ============================================================
;;; Resize Handle

;;; This is dead code (no resize handle!) and may be buggy
.proc on_resize_click
        MGTK_CALL MGTK::GrowWindow, growwindow_params
        jsr     redraw_screen
        jsr     calc_window_size

        max_width := default_width
        lda     #>max_width
        cmp     winfo::maprect::x2+1
        bne     :+
        lda     #<max_width
        cmp     winfo::maprect::x2
:       bcs     wider

        copy16  #max_width, winfo::maprect::x2
        sec
        lda     winfo::maprect::x2
        sbc     window_width
        sta     winfo::maprect::x1
        lda     winfo::maprect::x2+1
        sbc     window_width+1
        sta     winfo::maprect::x1+1
wider:  lda     winfo::hscroll
        ldx     window_width
        cpx     #<max_width
        bne     enable
        ldx     window_width+1
        cpx     #>max_width
        bne     enable
        and     #(<~MGTK::scroll_option_active)       ; disable scroll
        jmp     :+

enable: ora     #MGTK::scroll_option_active           ; enable scroll

:       sta     winfo::hscroll

        val := $06

        sec
        lda     #<max_width
        sbc     window_width
        sta     val
        lda     #>max_width
        sbc     window_width+1
        sta     val+1
        jsr     div_by_16
        sta     setctlmax_params::ctlmax
        lda     #MGTK::ctl_horizontal_scroll_bar
        sta     setctlmax_params::which_ctl
        MGTK_CALL MGTK::SetCtlMax, setctlmax_params ; change to clamped size ???
        jsr     calc_and_draw_mode
        jmp     finish_resize
.endproc

;;; ============================================================
;;; Client Area

;;; Non-title (client) area clicked
.proc on_client_click
        ;; On one of the scroll bars?
        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        cmp     #MGTK::ctl_vertical_scroll_bar
        beq     on_vscroll_click
        cmp     #MGTK::ctl_horizontal_scroll_bar
        bne     end
        jmp     on_hscroll_click
end:    rts
.endproc

;;; ============================================================
;;; Vertical Scroll Bar

.proc on_vscroll_click
        lda     #MGTK::ctl_vertical_scroll_bar
        sta     trackthumb_params::which_ctl
        sta     updatethumb_params::which_ctl
        lda     findcontrol_params::which_part
        cmp     #MGTK::part_thumb
        beq     on_vscroll_thumb_click
        cmp     #MGTK::part_page_down
        beq     on_vscroll_below_click
        cmp     #MGTK::part_page_up
        beq     on_vscroll_above_click
        cmp     #MGTK::part_up_arrow
        beq     on_vscroll_up_click
        cmp     #MGTK::part_down_arrow
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
loop:   lda     winfo::vthumbpos
        beq     end
        jsr     calc_track_scroll_delta
        sec
        lda     winfo::vthumbpos
        sbc     track_scroll_delta
        bcs     store
        lda     #0              ; underflow
store:  sta     updatethumb_params::thumbpos
        jsr     update_scroll_pos
        bcc     loop            ; repeat while button down
end:    rts
.endproc

.proc on_vscroll_up_click
loop :  lda     winfo::vthumbpos
        beq     end
        sec
        sbc     #1
        sta     updatethumb_params::thumbpos
        jsr     update_scroll_pos
        bcc     loop            ; repeat while button down
end:    rts
.endproc

vscroll_max := $FA

.proc on_vscroll_below_click
loop:   lda     winfo::vthumbpos
        cmp     #vscroll_max    ; pos == max ?
        beq     end
        jsr     calc_track_scroll_delta
        clc
        lda     winfo::vthumbpos
        adc     track_scroll_delta ; pos + delta
        bcs     overflow
        cmp     #vscroll_max+1  ; > max ?
        bcc     store           ; nope, it's good
overflow:
        lda     #vscroll_max    ; set to max
store:  sta     updatethumb_params::thumbpos
        jsr     update_scroll_pos
        bcc     loop            ; repeat while button down
end:    rts
.endproc

.proc on_vscroll_down_click
loop:   lda     winfo::vthumbpos
        cmp     #vscroll_max
        beq     end
        clc
        adc     #1
        sta     updatethumb_params::thumbpos
        jsr     update_scroll_pos
        bcc     loop            ; repeat while button down
end:    rts
.endproc

.proc update_scroll_pos         ; Returns with carry set if mouse released
        jsr     update_voffset
        jsr     update_vscroll
        jsr     draw_content
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
;;; Horizontal Scroll Bar
;;; (Unused in STF DA, so most of this is speculation)

.proc on_hscroll_click
        lda     #MGTK::ctl_horizontal_scroll_bar
        sta     trackthumb_params::which_ctl
        sta     updatethumb_params::which_ctl
        lda     findcontrol_params::which_part
        cmp     #MGTK::part_thumb
        beq     on_hscroll_thumb_click
        cmp     #MGTK::part_page_right
        beq     on_hscroll_after_click
        cmp     #MGTK::part_page_left
        beq     on_hscroll_before_click
        cmp     #MGTK::part_left_arrow
        beq     on_hscroll_left_click
        cmp     #MGTK::part_right_arrow
        beq     on_hscroll_right_click
        rts
.endproc

.proc on_hscroll_thumb_click
        jsr     do_trackthumb
        lda     trackthumb_params::thumbmoved
        beq     end

        res := $06
        lda     trackthumb_params::thumbpos
        jsr     mul_by_16
        copy16  res, winfo::maprect::x1

        clc
        lda     winfo::maprect::x1
        adc     window_width
        sta     winfo::maprect::x2
        lda     winfo::maprect::x1+1
        adc     window_width+1
        sta     winfo::maprect::x2+1
        jsr     update_hscroll
        jsr     draw_content
end:    rts
.endproc

.proc on_hscroll_after_click
        ldx     #2
        lda     winfo::hthumbmax
        jmp     hscroll_common
.endproc

.proc on_hscroll_before_click
        ldx     #254
        lda     #0
        jmp     hscroll_common
.endproc

.proc on_hscroll_right_click
        ldx     #1
        lda     winfo::hthumbmax
        jmp     hscroll_common
.endproc

.proc on_hscroll_left_click
        ldx     #255
        lda     #0
        ;; fall through
.endproc

.proc hscroll_common
        sta     compare+1
        stx     delta+1
loop:   lda     winfo::hthumbpos
compare:cmp     #$0A            ; self-modified
        bne     continue
        rts
continue:
        clc
        lda     winfo::hthumbpos
delta:  adc     #1              ; self-modified
        bmi     overflow
        cmp     winfo::hthumbmax
        beq     store
        bcc     store
        lda     winfo::hthumbmax
        jmp     store
overflow:
        lda     #0
store:  sta     winfo::hthumbpos
        jsr     adjust_box_width
        jsr     update_hscroll
        jsr     draw_content
        jsr     was_button_released
        bne     loop
        rts
.endproc

;;; ============================================================
;;; UI Helpers

        ;; Used at start of thumb event_kind_drag
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
        DESKTOP_CALL DT_REDRAW_ICONS
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
        lda     #line_spacing
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
        adc     #line_spacing
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
        copy16  #right_const, L095B
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
        and     #$7F            ; clear high bit
        sta     (ptr),y
        inc     L0945
        cmp     #CHAR_RETURN
        beq     finish_text_run
        cmp     #' '            ; space character
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
        lda     font_width_table,y
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

        lda     drawtext_params::textptr+1
        cmp     #>default_buffer
        beq     read

        ;; TODO: Where does $1300 come from ???
        ;; copy a page of characters from $1300 to the buffer
        ldy     #0
loop:   lda     $1300,y
        sta     default_buffer,y
        iny
        bne     loop

        dec     drawtext_params::textptr+1
        copy16  drawtext_params::textptr, ptr

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
        copy16  read_params::data_buffer, store_addr

        lda     #' '            ; fill buffer with spaces
        ldx     #0
        sta     RAMWRTOFF

        store_addr := *+1
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
        cmp     #line_spacing
        bcc     end

:       sec
        lda     y_remaining
        sbc     #line_spacing
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
        copy16  #JUMP_TABLE_REDRAW_ALL, call_main_addr
        jsr     call_main_trampoline
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
        dest  := font_width_table

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
        ldx     font_last_char
        lda     #7              ; 7 pixels/character
loop:   sta     font_width_table - 1,x
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
:       bcc     ignore

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

ignore: clc                     ; Click ignored
        rts
.endproc

fixed_str:      DEFINE_STRING "Fixed        "
prop_str:       DEFINE_STRING "Proportional"
        label_width := 50
        title_bar_height := 12

.proc mode_mapinfo                  ; bounding port for mode label
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .word   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, 80, 10, maprect
.endproc
mode_mapinfo_viewloc_xcoord := mode_mapinfo::viewloc::xcoord

.proc mode_pos
left:   .word   0               ; horizontal text offset
base:   .word   10              ; vertical text offset (to baseline)
.endproc

.proc calc_and_draw_mode
        sec
        lda     winfo::viewloc::ycoord
        sbc     #title_bar_height
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
        sbc     #<label_width
        sta     mode_mapinfo::viewloc::xcoord
        txa
        sbc     #>label_width
        sta     mode_mapinfo::viewloc::xcoord+1
        ;; fall through...
.endproc

.proc draw_mode
        MGTK_CALL MGTK::SetPortBits, mode_mapinfo
        MGTK_CALL MGTK::MoveTo, mode_pos
        lda     fixed_mode_flag
        beq     else            ; is proportional?
        MGTK_CALL MGTK::DrawText, fixed_str
        jmp     endif
else:   MGTK_CALL MGTK::DrawText, prop_str

endif:  ldx     #.sizeof(MGTK::MapInfo) - 1
loop:   lda     default_port,x
        sta     winfo::port,x
        dex
        bpl     loop
        MGTK_CALL MGTK::SetPortBits, winfo::port
        rts
.endproc
