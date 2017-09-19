        .org $800
        .setcpu "65C02"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../inc/auxmem.inc"

        .include "a2d.inc"

;;; ==================================================

        jmp     copy2aux


stash_stack:  .byte   $00

;;; ==================================================
;;; MLI Call Param Blocks

filename:
        PASCAL_STRING "MD.SYSTEM"

.proc open_params
params: .byte   3
name:   .addr   filename
buffer: .addr   $0900
ref_num:.byte   0
.endproc

.proc set_mark_params
params: .byte   2
ref_num:.byte   0
pos:    .byte   $03,$00,$00
.endproc

.proc write_params
params: .byte   4
ref_num:.byte   0
buffer: .addr   write_buffer
request:.word   sizeof_write_buffer
trans:  .word   0
.endproc

.proc close_params
params: .byte    1
ref_num:.byte   0
.endproc

write_buffer:
        .byte   0,0
        sizeof_write_buffer := * - write_buffer

;;; ==================================================

.proc copy2aux

        start := start_da
        end   := last

        tsx
        stx     stash_stack
        sta     ALTZPOFF
        lda     ROMIN2
        lda     DATELO
        sta     datelo
        lda     DATEHI
        sta     datehi
        lda     #<start
        sta     STARTLO
        lda     #>start
        sta     STARTHI
        lda     #<end
        sta     ENDLO
        lda     #>end
        sta     ENDHI
        lda     #<start
        sta     DESTINATIONLO
        lda     #>start
        sta     DESTINATIONHI
        sec
        jsr     AUXMOVE

        lda     #<start
        sta     XFERSTARTLO
        lda     #>start
        sta     XFERSTARTHI
        php
        pla
        ora     #$40            ; set overflow: aux zp/stack
        pha
        plp
        sec                     ; control main>aux
        jmp     XFER
.endproc

;;; ==================================================
;;; Write date into MD.SYSTEM file and exit the DA

.proc save_date_and_exit
        sta     ALTZPON
        sta     write_buffer
        stx     write_buffer+1
        lda     LCBANK1
        lda     LCBANK1
        lda     write_buffer    ; Dialog committed?
        beq     skip

        ldy     #OPEN           ; open the file
        lda     #<open_params
        ldx     #>open_params
        jsr     JUMP_TABLE_MLI
        bne     skip

        lda     open_params::ref_num
        sta     set_mark_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num

        ldy     #SET_MARK       ; seek
        lda     #<set_mark_params
        ldx     #>set_mark_params
        jsr     JUMP_TABLE_MLI
        bne     close

        ldy     #WRITE          ; write the date
        lda     #<write_params
        ldx     #>write_params
        jsr     JUMP_TABLE_MLI

close:  ldy     #CLOSE          ; close the file
        lda     #<close_params
        ldx     #>close_params
        jsr     JUMP_TABLE_MLI

skip:   ldx     stash_stack     ; exit the DA
        txs
        rts
.endproc

;;; ==================================================

start_da:
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        jmp     init_window

;;; ==================================================
;;; Param blocks

        ;; The following 7 rects are iterated over to identify
        ;; a hit target for a click.

        num_hit_rects := 7
        first_hit_rect := *
        up_rect_index := 3
        down_rect_index := 4

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

.proc text_mask_params
mask:   .byte   0
.endproc

        .res    7, $00          ; ???
        .byte   $FF

.proc white_pattern
        .res    8, $FF
.endproc
        .byte   $FF             ; ??

selected_field:                 ; 1 = day, 2 = month, 3 = year, 0 = none (init)
        .byte   0

datelo: .byte   0
datehi: .byte   0

day:    .byte   26              ; Feb 26, 1985
month:  .byte   2               ; The date this was written?
year:   .byte   85

spaces_string:
        A2D_DEFSTRING "    "

day_pos:
        .word   43, 30
day_string:
        A2D_DEFSTRING "  "

month_pos:
        .word   87, 30
month_string:
        A2D_DEFSTRING "   "

year_pos:
        .word   133, 30
year_string:
        A2D_DEFSTRING "  "

.proc get_input_params
state:  .byte   0

key       := *
modifiers := *+1

xcoord    := *
ycoord    := *+2
        .byte   0,0,0,0
.endproc
        ;; xcoord/ycoord are used to query...
.proc query_target_params
xcoord    := *
ycoord    := *+2
element:.byte   0
id:     .byte   0
.endproc

        window_id := $64

.proc map_coords_params
id:     .byte   window_id
screen:
screenx:.word   0
screeny:.word   0
client:
clientx:.word   0
clienty:.word   0
.endproc

.proc destroy_window_params
id:     .byte   window_id
.endproc
        .byte $00,$01           ; ???

.proc fill_mode_params
mode:   .byte   $02             ; this should be normal, but we do inverts ???
.endproc
        .byte   $06             ; ???

.proc create_window_params
id:     .byte   window_id
flags:  .byte   A2D_CWF_NOTITLE
title:  .addr   0
hscroll:.byte   0
vscroll:.byte   0
hsmax:  .byte   0
hspos:  .byte   0
vsmax:  .byte   0
vspos:  .byte   0
        .byte   0, 0            ; ???
w1:     .word   100
h1:     .word   100
w2:     .word   $1F4
h2:     .word   $1F4
.proc box
left:   .word   180
top:    .word   50
saddr:  .addr   A2D_SCREEN_ADDR
stride: .word   A2D_SCREEN_STRIDE
hoff:   .word   0
voff:   .word   0
width:  .word   $C7
height: .word   $40
.endproc
pattern:.res    8,$00
mskand: .byte   A2D_DEFAULT_MSKAND
mskor:  .byte   A2D_DEFAULT_MSKOR
        .byte   $00,$00,$00,$00
hthick: .byte   4
vthick: .byte   2
        .byte   $00,$7F,$00,$88,$00,$00
.endproc

;;; ==================================================
;;; Initialize window, unpack the date.

init_window:
        jsr     save_zp

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

        A2D_CALL A2D_CREATE_WINDOW, create_window_params
        lda     #0
        sta     selected_field
        jsr     draw_window
        A2D_CALL $2B
        ;; fall through

;;; ==================================================
;;; Input loop

.proc input_loop
        A2D_CALL A2D_GET_INPUT, get_input_params
        lda     get_input_params::state
        cmp     #A2D_INPUT_DOWN
        bne     :+
        jsr     on_click
        jmp     input_loop

:       cmp     #A2D_INPUT_KEY
        bne     input_loop
.endproc

.proc on_key
        lda     get_input_params::modifiers
        bne     input_loop
        lda     get_input_params::key
        cmp     #KEY_RETURN
        bne     :+
        jmp     on_ok

:       cmp     #KEY_ESCAPE
        bne     :+
        jmp     on_cancel
:       cmp     #KEY_LEFT
        beq     on_key_left
        cmp     #KEY_RIGHT
        beq     on_key_right
        cmp     #KEY_DOWN
        beq     on_key_down
        cmp     #KEY_UP
        bne     input_loop

on_key_up:
        A2D_CALL A2D_FILL_RECT, up_arrow_rect
        lda     #up_rect_index
        sta     hit_rect_index
        jsr     do_inc_or_dec
        A2D_CALL A2D_FILL_RECT, up_arrow_rect
        jmp     input_loop

on_key_down:
        A2D_CALL A2D_FILL_RECT, down_arrow_rect
        lda     #down_rect_index
        sta     hit_rect_index
        jsr     do_inc_or_dec
        A2D_CALL A2D_FILL_RECT, down_arrow_rect
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

;;; ==================================================

.proc on_click
        A2D_CALL A2D_QUERY_TARGET, get_input_params::xcoord
        A2D_CALL A2D_SET_FILL_MODE, fill_mode_params
        A2D_CALL A2D_SET_PATTERN, white_pattern
        lda     query_target_params::id
        cmp     #window_id
        bne     miss
        lda     query_target_params::element
        bne     hit
miss:   rts

hit:    cmp     #A2D_ELEM_CLIENT
        bne     miss
        jsr     find_hit_target
        cpx     #0
        beq     miss
        txa
        sec
        sbc     #1
        asl     a
        tay
        lda     hit_target_jump_table,y
        sta     jump+1
        lda     hit_target_jump_table+1,y
        sta     jump+2
jump:   jmp     $1000           ; self modified

hit_target_jump_table:
        .addr   on_ok, on_cancel, on_up, on_down
        .addr   on_field_click, on_field_click, on_field_click
.endproc

;;; ==================================================

.proc on_ok
        A2D_CALL A2D_FILL_RECT, ok_button_rect

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
        A2D_CALL A2D_FILL_RECT, cancel_button_rect
        lda     #0
        sta     dialog_result
        jmp     destroy

on_up:
        txa
        pha
        A2D_CALL A2D_FILL_RECT, up_arrow_rect
        pla
        tax
        jsr     on_up_or_down
        rts

on_down:
        txa
        pha
        A2D_CALL A2D_FILL_RECT, down_arrow_rect
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
loop:   A2D_CALL A2D_GET_INPUT, get_input_params ; Repeat while mouse is down
        lda     get_input_params::state
        cmp     #A2D_INPUT_UP
        beq     :+
        jsr     do_inc_or_dec
        jmp     loop

:       lda     hit_rect_index
        cmp     #up_rect_index
        beq     :+

        A2D_CALL A2D_FILL_RECT, down_arrow_rect
        rts

:       A2D_CALL A2D_FILL_RECT, up_arrow_rect
        rts
.endproc

.proc do_inc_or_dec
        ptr := $7

        jsr     delay
        lda     hit_rect_index
        cmp     #up_rect_index
        beq     incr

decr:   lda     #<decrement_table
        sta     ptr
        lda     #>decrement_table
        sta     ptr+1
        jmp     go

incr:   lda     #<increment_table
        sta     ptr
        lda     #>increment_table
        sta     ptr+1

go:     lda     selected_field
        asl     a
        tay
        lda     (ptr),y
        sta     gosub+1
        iny
        lda     (ptr),y
        sta     gosub+2

gosub:  jsr     $1000           ; self modified
        A2D_CALL A2D_SET_TEXT_MASK, text_mask_params
        jmp     draw_selected_field
.endproc

hit_rect_index:
        .byte   0

;;; ==================================================

increment_table:
        .addr   0, increment_day, increment_month, increment_year
decrement_table:
        .addr   0, decrement_day, decrement_month, decrement_year


        day_min := 1
        day_max := 31
        month_min := 1
        month_max := 12
        year_min := 0
        year_max := 99

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

;;; ==================================================

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
        len := 3

        lda     #<str
        sta     ptr
        lda     #>str
        sta     ptr+1

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

;;; ==================================================
;;; Tear down the window and exit

dialog_result:  .byte   0

.proc destroy
        A2D_CALL A2D_DESTROY_WINDOW, destroy_window_params
        DESKTOP_CALL DESKTOP_REDRAW_ICONS

        ;; Copy the relay routine to the zero page
        dest := $20

        ldx     #sizeof_routine
loop:   lda     routine,x
        sta     dest,x
        dex
        bpl     loop
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
        sizeof_routine := * - routine
.endproc

;;; ==================================================
;;; Figure out which button was hit (if any).
;;; Index returned in X.

.proc find_hit_target
        lda     get_input_params::xcoord
        sta     map_coords_params::screenx
        lda     get_input_params::xcoord+1
        sta     map_coords_params::screenx+1
        lda     get_input_params::ycoord
        sta     map_coords_params::screeny
        lda     get_input_params::ycoord+1
        sta     map_coords_params::screeny+1
        A2D_CALL A2D_MAP_COORDS, map_coords_params
        A2D_CALL A2D_SET_POS, map_coords_params::client
        ldx     #1
        lda     #<first_hit_rect
        sta     test_addr
        lda     #>first_hit_rect
        sta     test_addr+1

loop:   txa
        pha
        A2D_CALL A2D_TEST_BOX, $1000, test_addr
        bne     done

        clc
        lda     test_addr
        adc     #8              ; size of 4 words
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

;;; ==================================================
;;; Params for the display

border_rect:
        .word   $04,$02,$C0,$3D

date_rect:
        .word   $20,$0F,$9A,$23

label_ok:
        A2D_DEFSTRING {"OK         ",A2D_GLYPH_RETURN} ;
label_cancel:
        A2D_DEFSTRING "Cancel  ESC"
label_uparrow:
        A2D_DEFSTRING A2D_GLYPH_UARROW
label_downarrow:
        A2D_DEFSTRING A2D_GLYPH_DARROW

label_cancel_pos:
        .word   $15,$38
label_ok_pos:
        .word   $6E,$38

label_uparrow_pos:
        .word   $AC,$13
label_downarrow_pos:
        .word   $AC,$27

.proc thickness_params
hthick: .byte   1
vthick: .byte   1
.endproc

;;; ==================================================
;;; Render the window contents

draw_window:
        A2D_CALL A2D_SET_STATE, create_window_params::box
        A2D_CALL A2D_DRAW_RECT, border_rect
        A2D_CALL A2D_SET_THICKNESS, thickness_params
        A2D_CALL A2D_DRAW_RECT, date_rect
        A2D_CALL A2D_DRAW_RECT, ok_button_rect
        A2D_CALL A2D_DRAW_RECT, cancel_button_rect

        A2D_CALL A2D_SET_POS, label_ok_pos
        A2D_CALL A2D_DRAW_TEXT, label_ok

        A2D_CALL A2D_SET_POS, label_cancel_pos
        A2D_CALL A2D_DRAW_TEXT, label_cancel

        A2D_CALL A2D_SET_POS, label_uparrow_pos
        A2D_CALL A2D_DRAW_TEXT, label_uparrow
        A2D_CALL A2D_DRAW_RECT, up_arrow_rect

        A2D_CALL A2D_SET_POS, label_downarrow_pos
        A2D_CALL A2D_DRAW_TEXT, label_downarrow
        A2D_CALL A2D_DRAW_RECT, down_arrow_rect

        jsr     prepare_day_string
        jsr     prepare_month_string
        jsr     prepare_year_string

        jsr     draw_day
        jsr     draw_month
        jsr     draw_year
        A2D_CALL A2D_SET_FILL_MODE, fill_mode_params
        A2D_CALL A2D_SET_PATTERN, white_pattern
        lda     #1
        jmp     highlight_selected_field

.proc draw_selected_field
        lda     selected_field
        cmp     #1
        beq     draw_day
        cmp     #2
        beq     draw_month
        jmp     draw_year
.endproc

.proc draw_day
        A2D_CALL A2D_SET_POS, day_pos
        A2D_CALL A2D_DRAW_TEXT, day_string
        rts
.endproc

.proc draw_month
        A2D_CALL A2D_SET_POS, month_pos
        A2D_CALL A2D_DRAW_TEXT, spaces_string ; variable width, so clear first
        A2D_CALL A2D_SET_POS, month_pos
        A2D_CALL A2D_DRAW_TEXT, month_string
        rts
.endproc

.proc draw_year
        A2D_CALL A2D_SET_POS, year_pos
        A2D_CALL A2D_DRAW_TEXT, year_string
        rts
.endproc

;;; ==================================================
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
        A2D_CALL A2D_FILL_RECT, year_rect
        rts

fill_day:
        A2D_CALL A2D_FILL_RECT, day_rect
        rts

fill_month:
        A2D_CALL A2D_FILL_RECT, month_rect
        rts
.endproc

;;; ==================================================
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

;;; ==================================================
;;; Save/restore Zero Page

.proc save_zp
        ldx     #$00
loop:   lda     $00,x
        sta     zp_buffer,x
        dex
        bne     loop
        rts
.endproc

.proc restore_zp
        ldx     #$00
loop:   lda     zp_buffer,x
        sta     $00,x
        dex
        bne     loop
        rts
.endproc

zp_buffer:
        .res    256, 0

;;; ==================================================
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
