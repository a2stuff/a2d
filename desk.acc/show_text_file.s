        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/ascii.inc"
        .include "../inc/prodos.inc"
        .include "../inc/auxmem.inc"

        .include "../a2d.inc"
        .include "../desktop.inc" ; needed to get/clear DeskTop selection

        .org $800

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
        jsr     $1000           ; overwritten (in zp version)
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

;;; ==================================================
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

;;; ==================================================

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

.proc open_params
        .byte   3               ; param_count
        .addr   pathname        ; pathname
        .addr   $0C00           ; io_buffer
ref_num:.byte   0               ; ref_num
.endproc

default_buffer := $1200

.proc read_params
        .byte   4               ; param_count
ref_num:.byte   0               ; ref_num
buffer: .addr   default_buffer  ; data_buffer
        .word   $100            ; request_count
        .word   0               ; trans_count
.endproc

.proc get_eof_params
        .byte   2               ; param_count
ref_num:.byte   0               ; ref_num
        .byte   0,0,0           ; EOF (lo, mid, hi)
.endproc

.proc set_mark_params
        .byte   2               ; param_count
ref_num:.byte   0               ; ref_num
        .byte   0,0,0           ; position (lo, mid, hi)
.endproc

.proc close_params
        .byte   1               ; param_count
ref_num:.byte   0               ; ref_num
.endproc

.proc pathname                 ; 1st byte is length, rest is full path
length: .byte   $00
data:   .res    64, $00
.endproc

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

        window_id := 100

L095A:  .byte   $00
L095B:  .byte   $FA
L095C:  .byte   $01

.proc line_pos
left:   .word   0
base:   .word   0
.endproc

window_width:  .word   0
window_height: .word   0

L0965:  .byte   $00
L0966:  .byte   $00,$00
L0968:  .byte   $00
L0969:  .byte   $00
L096A:  .byte   $00
L096B:  .byte   $00
L096C:  .byte   $00
L096D:  .byte   $00

track_scroll_delta:
        .byte   $00

fixed_mode_flag:
        .byte   $00             ; 0 = proportional, otherwise = fixed

.proc input_params
state:  .byte   0
coords:                         ; spills into target query
xcoord: .word   0
ycoord: .word   0
.endproc
.proc target_params
elem:   .byte   0
win:    .byte   0
.endproc

.proc resize_drag_params
id:     .byte   window_id
xcoord: .word   0
ycoord: .word   0
        .byte   0               ; ???
.endproc

.proc close_btn_params          ; queried after close clicked to see if aborted/finished
state:  .byte   0               ; 0 = aborted, 1 = clicked
        .byte   0,0             ; ???
.endproc

.proc query_client_params       ; queried after a client click to identify target
xcoord: .word   0
ycoord: .word   0
part:   .byte   0               ; 0 = client, 1 = vscroll, 2 = hscroll
scroll: .byte   0               ; 1 = up, 2 = down, 3 = above, 4 = below, 5 = thumb
.endproc

        ;; param block used in dead code (resize?)
.proc resize_window_params
part:   .byte   0
L0987:  .byte   0
        ;; needs one more byte?
.endproc

.proc update_scroll_params      ; called to update scroll bar position
type:   .byte   0               ; 1 = vscroll, 2 = hscroll
pos:    .byte   0               ; new position
.endproc

;;; Used when dragging vscroll thumb
.proc thumb_drag_params
type:   .byte   0               ; 1 = vscroll, 2 = hscroll
xcoord: .word   0
ycoord: .word   0
pos:    .byte   0               ; position
moved:  .byte   0               ; 0 if not moved, 1 if moved
.endproc

.proc text_string
addr:   .addr   0               ; address
len:    .byte   0               ; length
.endproc

        default_width := 512
        default_height := 150
        default_left := 10
        default_top := 28

.proc window_params
id:     .byte   window_id       ; window identifier
flags:  .byte   A2D_CWF_ADDCLOSE; window flags (2=include close box)
title:  .addr   $1000           ; overwritten to point at filename
hscroll:.byte   A2D_CWS_NOSCROLL
vscroll:.byte   A2D_CWS_SCROLL_NORMAL
hsmax:  .byte   32
hspos:  .byte   0
vsmax:  .byte   255
vspos:  .byte   0
        .byte   0, 0            ; ???
w1:     .word   200
h1:     .word   51
w2:     .word   default_width
h2:     .word   default_height

.proc box
left:   .word   default_left
top:    .word   default_top
addr:   .addr   A2D_SCREEN_ADDR
stride: .word   A2D_SCREEN_STRIDE
hoff:   .word   0               ; Also used for A2D_FILL_RECT
voff:   .word   0
width:  .word   default_width
height: .word   default_height
.endproc

pattern:.res    8, $00
mskand: .byte   A2D_DEFAULT_MSKAND
mskor:  .byte   A2D_DEFAULT_MSKOR
xpos:   .word   0
ypos:   .word   0
hthick: .byte   1
vthick: .byte   1
mode:   .byte   0
tmask:  .byte   $7F
font:   .addr   A2D_DEFAULT_FONT
next:   .addr   0
.endproc

        ;; gets copied over window_params::box after mode is drawn
.proc default_box
left:   .word   default_left
top:    .word   default_top
addr:   .word   A2D_SCREEN_ADDR
stride: .word   A2D_SCREEN_STRIDE
hoff:   .word   0
voff:   .word   0
width:  .word   default_width
height: .word   default_height
.endproc

.proc init
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        ;; Get filename by checking DeskTop selected window/icon

        ;; Check that an icon is selected
        lda     #0
        sta     pathname::length
        lda     file_selected
        beq     abort           ; some file properties?
        lda     path_index      ; prefix index in table
        bne     :+
abort:  rts

        ;; Copy path (prefix) into pathname buffer.
:       src := $06
        dst := $08

        asl     a               ; (since address table is 2 bytes wide)
        tax
        lda     path_table,x          ; pathname ???
        sta     src
        lda     path_table+1,x
        sta     src+1
        ldy     #0
        lda     (src),y
        tax
        inc     src
        bne     :+
        inc     src+1
:       lda     #<(pathname::data)
        sta     dst
        lda     #>(pathname::data)
        sta     dst+1
        jsr     copy_pathname   ; copy x bytes (src) to (dst)

        ;; Append separator.
        lda     #'/'
        ldy     #0
        sta     (dst),y
        inc     pathname::length
        inc     dst
        bne     :+
        inc     dst+1

        ;; Get file entry.
:       lda     file_index      ; file index in table
        asl     a               ; (since table is 2 bytes wide)
        tax
        lda     file_table,x
        sta     src
        lda     file_table+1,x
        sta     src+1

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
        sta     window_params::title
        lda     src+1
        adc     #0
        sta     window_params::title+1

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
:       jsr     copy_pathname   ; copy x bytes (src) to (dst)

        ;; Clear selection (why???)
        lda     #<JUMP_TABLE_CLEAR_SEL
        sta     call_main_addr
        lda     #>JUMP_TABLE_CLEAR_SEL
        sta     call_main_addr+1
        jsr     call_main_trampoline

        jmp     open_file_and_init_window

.proc copy_pathname             ; copy x bytes from src to dst
        ldy     #0              ; incrementing path length and dst
loop:   lda     (src),y
        sta     (dst),y
        iny
        inc     pathname::length
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
        ldx     font_size_count
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
        A2D_CALL A2D_CREATE_WINDOW, window_params
        A2D_CALL A2D_SET_STATE, window_params::box
        jsr     calc_window_size
        jsr     calc_and_draw_mode
        jsr     draw_content
        A2D_CALL $2B            ; ???
        ;; fall through
.endproc

;;; ==================================================
;;; Main Input Loop

input_loop:
        A2D_CALL A2D_GET_INPUT, input_params
        lda     input_params
        cmp     #1              ; was clicked?
        bne     input_loop      ; nope, keep waiting

        A2D_CALL A2D_QUERY_TARGET, input_params::coords
        lda     target_params::win ; in our window?
        cmp     #window_id
        bne     input_loop

        ;; which part of the window?
        lda     target_params::elem
        cmp     #A2D_ELEM_CLOSE
        beq     on_close_click

        ;; title and resize clicks need mouse location
        ldx     input_params::xcoord
        stx     resize_drag_params::xcoord
        stx     query_client_params::xcoord
        ldx     input_params::xcoord+1
        stx     resize_drag_params::xcoord+1
        stx     query_client_params::xcoord+1
        ldx     input_params::ycoord
        stx     resize_drag_params::ycoord
        stx     query_client_params::ycoord

        cmp     #A2D_ELEM_TITLE
        beq     title
        cmp     #A2D_ELEM_RESIZE ; not enabled, so this will never match
        beq     input_loop
        jsr     on_client_click
        jmp     input_loop

title:  jsr     on_title_bar_click
        jmp     input_loop

;;; ==================================================
;;; Close Button

.proc on_close_click
        A2D_CALL A2D_CLOSE_CLICK, close_btn_params     ; wait to see if the click completes
        lda     close_btn_params::state ; did click complete?
        beq     input_loop      ; nope
        jsr     close_file
        A2D_CALL A2D_DESTROY_WINDOW, window_params
        DESKTOP_CALL DESKTOP_REDRAW_ICONS
        rts                     ; exits input loop
.endproc

;;; ==================================================
;;; Resize Handle

;;; This is dead code (no resize handle!) and may be buggy
.proc on_resize_click
        A2D_CALL A2D_DRAG_RESIZE, resize_drag_params
        jsr     redraw_screen
        jsr     calc_window_size

        max_width := default_width
        lda     #>max_width
        cmp     window_params::box::width+1
        bne     :+
        lda     #<max_width
        cmp     window_params::box::width
:       bcs     wider

        lda     #<max_width
        sta     window_params::box::width
        lda     #>max_width
        sta     window_params::box::width+1
        sec
        lda     window_params::box::width
        sbc     window_width
        sta     window_params::box::hoff
        lda     window_params::box::width+1
        sbc     window_width+1
        sta     window_params::box::hoff+1
wider:  lda     window_params::hscroll
        ldx     window_width
        cpx     #<max_width
        bne     enable
        ldx     window_width+1
        cpx     #>max_width
        bne     enable
        and     #(<~A2D_CWS_SCROLL_TRACK)       ; disable scroll
        jmp     :+

enable: ora     #A2D_CWS_SCROLL_TRACK           ; enable scroll

:       sta     window_params::hscroll
        sec
        lda     #<max_width
        sbc     window_width
        sta     $06
        lda     #>max_width
        sbc     window_width+1
        sta     $07
        jsr     div_by_16
        sta     resize_window_params::L0987
        lda     #A2D_HSCROLL
        sta     resize_window_params::part
        A2D_CALL A2D_RESIZE_WINDOW, resize_window_params ; change to clamped size ???
        jsr     calc_and_draw_mode
        jmp     finish_resize
.endproc

;;; ==================================================
;;; Client Area

;;; Non-title (client) area clicked
.proc on_client_click
        ;; On one of the scroll bars?
        A2D_CALL A2D_QUERY_CLIENT, query_client_params
        lda     query_client_params::part
        cmp     #A2D_VSCROLL
        beq     on_vscroll_click
        cmp     #A2D_HSCROLL
        bne     end
        jmp     on_hscroll_click
end:    rts
.endproc

;;; ==================================================
;;; Vertical Scroll Bar

.proc on_vscroll_click
        lda     #A2D_VSCROLL
        sta     thumb_drag_params::type
        sta     update_scroll_params::type
        lda     query_client_params::scroll
        cmp     #A2D_SCROLL_PART_THUMB
        beq     on_vscroll_thumb_click
        cmp     #A2D_SCROLL_PART_BELOW
        beq     on_vscroll_below_click
        cmp     #A2D_SCROLL_PART_ABOVE
        beq     on_vscroll_above_click
        cmp     #A2D_SCROLL_PART_UP
        beq     on_vscroll_up_click
        cmp     #A2D_SCROLL_PART_DOWN
        bne     end
        jmp     on_vscroll_down_click
end:    rts
.endproc

.proc on_vscroll_thumb_click
        jsr     do_thumb_drag
        lda     thumb_drag_params::moved
        beq     end
        lda     thumb_drag_params::pos
        sta     update_scroll_params::pos
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
loop:   lda     window_params::vspos
        beq     end
        jsr     calc_track_scroll_delta
        sec
        lda     window_params::vspos
        sbc     track_scroll_delta
        bcs     store
        lda     #0              ; underflow
store:  sta     update_scroll_params::pos
        jsr     update_scroll_pos
        bcc     loop            ; repeat while button down
end:    rts
.endproc

.proc on_vscroll_up_click
loop :  lda     window_params::vspos
        beq     end
        sec
        sbc     #1
        sta     update_scroll_params::pos
        jsr     update_scroll_pos
        bcc     loop            ; repeat while button down
end:    rts
.endproc

vscroll_max := $FA

.proc on_vscroll_below_click
loop:   lda     window_params::vspos
        cmp     #vscroll_max    ; pos == max ?
        beq     end
        jsr     calc_track_scroll_delta
        clc
        lda     window_params::vspos
        adc     track_scroll_delta ; pos + delta
        bcs     overflow
        cmp     #vscroll_max+1  ; > max ?
        bcc     store           ; nope, it's good
overflow:
        lda     #vscroll_max    ; set to max
store:  sta     update_scroll_params::pos
        jsr     update_scroll_pos
        bcc     loop            ; repeat while button down
end:    rts
.endproc

.proc on_vscroll_down_click
loop:   lda     window_params::vspos
        cmp     #vscroll_max
        beq     end
        clc
        adc     #1
        sta     update_scroll_params::pos
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
        lda     window_height   ; ceil(??? / 50)
        ldx     #0
loop:   inx
        sec
        sbc     #50
        cmp     #50
        bcs     loop
        stx     track_scroll_delta
        rts
.endproc

;;; ==================================================
;;; Horizontal Scroll Bar
;;; (Unused in STF DA, so most of this is speculation)

.proc on_hscroll_click
        lda     #A2D_HSCROLL
        sta     thumb_drag_params::type
        sta     update_scroll_params::type
        lda     query_client_params::scroll
        cmp     #A2D_SCROLL_PART_THUMB
        beq     on_hscroll_thumb_click
        cmp     #A2D_SCROLL_PART_AFTER
        beq     on_hscroll_after_click
        cmp     #A2D_SCROLL_PART_BEFORE
        beq     on_hscroll_before_click
        cmp     #A2D_SCROLL_PART_LEFT
        beq     on_hscroll_left_click
        cmp     #A2D_SCROLL_PART_RIGHT
        beq     on_hscroll_right_click
        rts
.endproc

.proc on_hscroll_thumb_click
        jsr     do_thumb_drag
        lda     thumb_drag_params::moved
        beq     end
        lda     thumb_drag_params::pos
        jsr     mul_by_16
        lda     $06
        sta     window_params::box::hoff
        lda     $07
        sta     window_params::box::hoff+1
        clc
        lda     window_params::box::hoff
        adc     window_width
        sta     window_params::box::width
        lda     window_params::box::hoff+1
        adc     window_width+1
        sta     window_params::box::width+1
        jsr     update_hscroll
        jsr     draw_content
end:    rts
.endproc

.proc on_hscroll_after_click
        ldx     #2
        lda     window_params::hsmax
        jmp     hscroll_common
.endproc

.proc on_hscroll_before_click
        ldx     #254
        lda     #0
        jmp     hscroll_common
.endproc

.proc on_hscroll_right_click
        ldx     #1
        lda     window_params::hsmax
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
loop:   lda     window_params::hspos
compare:cmp     #$0A            ; self-modified
        bne     continue
        rts
continue:
        clc
        lda     window_params::hspos
delta:  adc     #1              ; self-modified
        bmi     overflow
        cmp     window_params::hsmax
        beq     store
        bcc     store
        lda     window_params::hsmax
        jmp     store
overflow:
        lda     #0
store:  sta     window_params::hspos
        jsr     adjust_box_width
        jsr     update_hscroll
        jsr     draw_content
        jsr     was_button_released
        bne     loop
        rts
.endproc

;;; ==================================================
;;; UI Helpers

        ;; Used at start of thumb drag
.proc do_thumb_drag
        lda     input_params::xcoord
        sta     thumb_drag_params::xcoord
        lda     input_params::xcoord+1
        sta     thumb_drag_params::xcoord+1
        lda     input_params::ycoord
        sta     thumb_drag_params::ycoord
        A2D_CALL A2D_DRAG_SCROLL, thumb_drag_params
        rts
.endproc

;;; Checks button state; z clear if button was released, set otherwise
.proc was_button_released
        A2D_CALL A2D_GET_INPUT, input_params
        lda     input_params
        cmp     #2
        rts
.endproc

;;; only used from hscroll code?
.proc adjust_box_width
        lda     window_params::hspos
        jsr     mul_by_16
        clc
        lda     $06
        sta     window_params::box::hoff
        adc     window_width
        sta     window_params::box::width
        lda     $07
        sta     window_params::box::hoff+1
        adc     window_width+1
        sta     window_params::box::width+1
        rts
.endproc

.proc update_voffset
        lda     #0
        sta     window_params::box::voff
        sta     window_params::box::voff+1
        ldx     update_scroll_params::pos
loop:   beq     adjust_box_height
        clc
        lda     window_params::box::voff
        adc     #50
        sta     window_params::box::voff
        bcc     :+
        inc     window_params::box::voff+1
:       dex
        jmp     loop
.endproc

.proc adjust_box_height
        clc
        lda     window_params::box::voff
        adc     window_height
        sta     window_params::box::height
        lda     window_params::box::voff+1
        adc     window_height+1
        sta     window_params::box::height+1
        jsr     calc_line_position
        lda     #0
        sta     L096A
        sta     L096B
        ldx     update_scroll_params::pos
loop:   beq     end
        clc
        lda     L096A
        adc     #5
        sta     L096A
        bcc     :+
        inc     L096B
:       dex
        jmp     loop
end:    rts
.endproc

.proc update_hscroll
        lda     #2
        sta     update_scroll_params::type
        lda     window_params::box::hoff
        sta     $06
        lda     window_params::box::hoff+1
        sta     $07
        jsr     div_by_16
        sta     update_scroll_params::pos
        A2D_CALL A2D_UPDATE_SCROLL, update_scroll_params
        rts
.endproc

.proc update_vscroll            ; update_scroll_params::pos set by caller
        lda     #1
        sta     update_scroll_params::type
        A2D_CALL A2D_UPDATE_SCROLL, update_scroll_params
        rts
.endproc

.proc finish_resize             ; only called from dead code
        DESKTOP_CALL DESKTOP_REDRAW_ICONS
        A2D_CALL A2D_SET_STATE, window_params::box
        lda     window_params::hscroll
        ror     a               ; check if low bit (track enabled) is set
        bcc     :+
        jsr     update_hscroll
:       lda     window_params::vspos
        sta     update_scroll_params::pos
        jsr     update_vscroll
        jsr     draw_content
        jmp     input_loop
.endproc

.proc clear_window
        A2D_CALL A2D_SET_PATTERN, white_pattern
        A2D_CALL A2D_FILL_RECT, window_params::box::hoff
        A2D_CALL A2D_SET_PATTERN, black_pattern
        rts
.endproc

;;; ==================================================
;;; Content Rendering

.proc draw_content
        lda     #0
        sta     L0949
        jsr     assign_fixed_font_width_table_if_needed
        jsr     set_file_mark
        lda     #<default_buffer
        sta     read_params::buffer
        sta     $06
        lda     #>default_buffer
        sta     read_params::buffer+1
        sta     $07
        lda     #0
        sta     L0945
        sta     L0946
        sta     L0947
        sta     line_pos::base+1
        sta     L096C
        sta     L096D
        sta     L0948
        lda     #$0A            ; line spacing = 10
        sta     line_pos::base
        jsr     L0EDB

do_line:
        lda     L096D
        cmp     L096B
        bne     :+
        lda     L096C
        cmp     L096A
        bne     :+
        jsr     clear_window
        inc     L0948
:       A2D_CALL A2D_SET_POS, line_pos
        sec
        lda     #250
        sbc     line_pos::left
        sta     L095B
        lda     #1
        sbc     line_pos::left+1
        sta     L095C
        jsr     find_text_run
        bcs     L0ED7
        clc
        lda     text_string::len
        adc     $06
        sta     $06
        bcc     :+
        inc     $07
:       lda     L095A
        bne     do_line
        clc
        lda     line_pos::base
        adc     #$0A            ; line spacing = 10
        sta     line_pos::base
        bcc     :+
        inc     line_pos::base+1
:       jsr     L0EDB
        lda     L096C
        cmp     L0968
        bne     :+
        lda     L096D
        cmp     L0969
        beq     L0ED7
:       inc     L096C
        bne     :+
        inc     L096D
:       jmp     do_line

L0ED7:  jsr     restore_proportional_font_table_if_needed
        rts
.endproc

;;; ==================================================

.proc L0EDB                     ; ???
        lda     #250
        sta     L095B
        lda     #1
        sta     L095C
        lda     #3
        sta     line_pos::left
        lda     #0
        sta     line_pos::left+1
        sta     L095A
        rts
.endproc

;;; ==================================================

.proc find_text_run
        lda     #$FF
        sta     L0F9B
        lda     #0
        sta     run_width
        sta     run_width+1
        sta     L095A
        sta     text_string::len
        lda     $06
        sta     text_string::addr
        lda     $07
        sta     text_string::addr+1

loop:   lda     L0945
        bne     more
        lda     L0947
        beq     :+
        jsr     draw_text_run
        sec
        rts

:       jsr     ensure_page_buffered
more:   ldy     text_string::len
        lda     ($06),y
        and     #$7F            ; clear high bit
        sta     ($06),y
        inc     L0945
        cmp     #ASCII_RETURN
        beq     finish_text_run
        cmp     #' '            ; space character
        bne     :+
        sty     L0F9B
        pha
        lda     L0945
        sta     L0946
        pla
:       cmp     #ASCII_TAB
        bne     :+
        jmp     handle_tab

:       tay
        lda     font_width_table,y
        clc
        adc     run_width
        sta     run_width
        bcc     :+
        inc     run_width+1
:       lda     L095C
        cmp     run_width+1
        bne     :+
        lda     L095B
        cmp     run_width
:       bcc     :+
        inc     text_string::len
        jmp     loop

:       lda     #0
        sta     L095A
        lda     L0F9B
        cmp     #$FF
        beq     :+
        sta     text_string::len
        lda     L0946
        sta     L0945
:       inc     text_string::len
        ;; fall through
.endproc

finish_text_run:  jsr     draw_text_run
        ldy     text_string::len
        lda     ($06),y
        cmp     #ASCII_TAB
        beq     tab
        cmp     #ASCII_RETURN
        bne     :+
tab:    inc     text_string::len
:       clc
        rts

;;; ==================================================

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
:       lda     times70,x
        sta     line_pos::left
        lda     times70+1,x
        sta     line_pos::left+1
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

;;; ==================================================
;;; Draw a line of content

.proc draw_text_run
        lda     L0948
        beq     end
        lda     text_string::len
        beq     end
        A2D_CALL A2D_DRAW_TEXT, text_string
        lda     #1
        sta     L0949
end:    rts
.endproc

;;; ==================================================

.proc ensure_page_buffered
        lda     text_string::addr+1
        cmp     #>default_buffer
        beq     read

        ;; copy a page of characters from $1300 to the buffer
        ldy     #0
loop:   lda     $1300,y
        sta     default_buffer,y
        iny
        bne     loop

        dec     text_string::addr+1
        lda     text_string::addr
        sta     $06
        lda     text_string::addr+1
        sta     $07

read:   lda     #0
        sta     L0945
        jsr     read_file_page
        lda     read_params::buffer+1
        cmp     #>default_buffer
        bne     :+
        inc     read_params::buffer+1
:       rts
.endproc

;;; ==================================================

.proc read_file_page
        lda     read_params::buffer
        sta     store+1
        lda     read_params::buffer+1
        sta     store+2

        lda     #' '            ; fill buffer with spaces
        ldx     #0
        sta     RAMWRTOFF
store:  sta     default_buffer,x         ; self-modified
        inx
        bne     store

        sta     RAMWRTON        ; read file chunk
        lda     #$00
        sta     L0947
        jsr     read_file

        pha                     ; copy read buffer main>aux
        lda     #$00
        sta     STARTLO
        sta     DESTINATIONLO
        lda     #$FF
        sta     ENDLO
        lda     read_params::buffer+1
        sta     DESTINATIONHI
        sta     STARTHI
        sta     ENDHI
        sec                     ; main>aux
        jsr     AUXMOVE
        pla

        beq     end
        cmp     #$4C            ; ???
        beq     done
        brk                     ; ????
done:   lda     #$01
        sta     L0947
end:    rts
.endproc

.proc calc_window_size
        sec
        lda     window_params::box::width
        sbc     window_params::box::hoff
        sta     window_width
        lda     window_params::box::width+1
        sbc     window_params::box::hoff+1
        sta     window_width+1

        sec
        lda     window_params::box::height
        sbc     window_params::box::voff
        sta     window_height
        ;; fall through
.endproc

;;; ==================================================

.proc calc_line_position
        lda     window_params::box::height
        sta     L0965
        lda     window_params::box::height+1
        sta     L0966

        lda     #0
        sta     L0968
        sta     L0969
loop:   lda     L0966
        bne     :+
        lda     L0965
        cmp     #$0A            ; line spacing = 10
        bcc     end
:       sec
        lda     L0965
        sbc     #$0A            ; line spacing = 10
        sta     L0965
        bcs     :+
        dec     L0966
:       inc     L0968
        bne     loop
        inc     L0969
        jmp     loop
end:    rts
.endproc

;;; ==================================================

.proc div_by_16                 ; input in $06/$07, output in a
        ldx     #4
loop:   clc
        ror     $07
        ror     $06
        dex
        bne     loop
        lda     $06
        rts
.endproc

.proc mul_by_16                 ; input in a, output in $06/$07
        sta     $06
        lda     #0
        sta     $07
        ldx     #4
loop:   clc
        rol     $06
        rol     $07
        dex
        bne     loop
        rts
.endproc

.proc redraw_screen
        lda     #<JUMP_TABLE_REDRAW_ALL
        sta     call_main_addr
        lda     #>JUMP_TABLE_REDRAW_ALL
        sta     call_main_addr+1
        jsr     call_main_trampoline
        rts
.endproc

;;; ==================================================
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

;;; ==================================================
;;; Overwrite the font glyph width table (with 7s)
;;; when switching to fixed width mode.

.proc assign_fixed_font_width_table_if_needed
        lda     fixed_mode_flag ; if not fixed (i.e. proportional)
        beq     end             ; then exit
        ldx     font_size_count
        lda     #7              ; 7 pixels/character
loop:   sta     font_width_table - 1,x
        dex
        bne     loop
end:    rts
.endproc

;;; ==================================================
;;; Title Bar (Proportional/Fixed mode button)

.proc on_title_bar_click
        lda     input_params::xcoord+1           ; mouse x high byte?
        cmp     mode_box_left+1
        bne     :+
        lda     input_params::xcoord
        cmp     mode_box_left
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

fixed_str:      A2D_DEFSTRING "Fixed        "
prop_str:       A2D_DEFSTRING "Proportional"
        label_width := 50
        title_bar_height := 12
.proc mode_box                  ; bounding box for mode label
left:   .word   0
top:    .word   0
addr:   .word   A2D_SCREEN_ADDR
stride: .word   A2D_SCREEN_STRIDE
hoff:   .word   0
voff:   .word   0
width:  .word   80
height: .word   10
.endproc
mode_box_left := mode_box::left ; forward refs to mode_box::left don't work?
        ;; https://github.com/cc65/cc65/issues/479

.proc mode_pos
left:   .word   0               ; horizontal text offset
base:   .word   10              ; vertical text offset (to baseline)
.endproc

.proc calc_and_draw_mode
        sec
        lda     window_params::box::top
        sbc     #title_bar_height
        sta     mode_box::top
        clc
        lda     window_params::box::left
        adc     window_width
        pha
        lda     window_params::box::left+1
        adc     window_width+1
        tax
        sec
        pla
        sbc     #<label_width
        sta     mode_box::left
        txa
        sbc     #>label_width
        sta     mode_box::left+1
        ;; fall through...
.endproc

.proc draw_mode
        A2D_CALL A2D_SET_BOX, mode_box
        A2D_CALL A2D_SET_POS, mode_pos
        lda     fixed_mode_flag
        beq     else            ; is proportional?
        A2D_CALL A2D_DRAW_TEXT, fixed_str
        jmp     endif
else:   A2D_CALL A2D_DRAW_TEXT, prop_str

endif:  ldx     #$0F
loop:   lda     default_box,x
        sta     window_params::box,x
        dex
        bpl     loop
        A2D_CALL A2D_SET_BOX, window_params::box
        rts
.endproc
