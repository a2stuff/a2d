        .org $800
        .setcpu "65C02"

        .include "apple2.inc"
        .include "../inc/prodos.inc"
        .include "../inc/auxmem.inc"

        .include "a2d.inc"

ROMIN2          := $C082
DATELO  := $BF90
DATEHI  := $BF91

KEY_ENTER       := $0D
KEY_ESCAPE      := $1B
KEY_LEFT        := $08
KEY_DOWN        := $0A
KEY_UP          := $0B
KEY_RIGHT       := $15

L0020           := $0020
L1000           := $1000

;;; ==================================================

        jmp     copy2aux

stash_stack:  .byte   $00

        PASCAL_STRING "MD.SYSTEM" ; ??
        .byte   $03,$04,$08,$00,$09
L0813:  .byte   $00,$02
L0815:  .byte   $00,$03,$00,$00,$04
L081A:  .byte   $00,$23,$08,$02,$00,$00,$00,$01
L0822:  .byte   $00
L0823:  .byte   $00
L0824:  .byte   $00

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

L086B:  sta     ALTZPON
        sta     L0823
        stx     L0824
        lda     LCBANK1
        lda     LCBANK1
        lda     L0823
        beq     L08B3
        ldy     #$C8
        lda     #$0E
        ldx     #$08
        jsr     JUMP_TABLE_21
        bne     L08B3
        lda     L0813
        sta     L0815
        sta     L081A
        sta     L0822
        ldy     #$CE
        lda     #$14
        ldx     #$08
        jsr     JUMP_TABLE_21
        bne     L08AA
        ldy     #$CB
        lda     #$19
        ldx     #$08
        jsr     JUMP_TABLE_21
L08AA:  ldy     #$CC
        lda     #$21
        ldx     #$08
        jsr     JUMP_TABLE_21
L08B3:  ldx     stash_stack
        txs
        rts

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


L08FC:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF

.proc white_pattern
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.endproc
        .byte   $FF

selected_field:
        .byte   0

datelo: .byte   0
datehi: .byte   0

day:    .byte   26              ; Feb 26, 1985
month:  .byte   2               ; The date this was written?
year:   .byte   85

spaces_string:
        A2D_DEFSTRING "    "

day_pos:
        .word   $2B,$1E
day_string:
        A2D_DEFSTRING "  "

month_pos:
        .word   $57,$1E
month_string:
        A2D_DEFSTRING "   "

year_pos:
        .word   $85,$1E
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

L0947:  .byte   window_id,$00,$01

.proc fill_mode_params
mode:   .byte   $02
.endproc
        .byte   $06

.proc create_window_params
id:     .byte   window_id
flags:  .byte   $01
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
left:   .word   $B4
top:    .word   $32
saddr:  .addr   A2D_SCREEN_ADDR
stride: .word   A2D_SCREEN_STRIDE
hoff:   .word   0
voff:   .word   0
width:  .word   $C7
height: .word   $40
.endproc
.endproc
        ;; ???
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF,$00,$00,$00,$00,$00,$04,$02
        .byte   $00,$7F,$00,$88,$00,$00

;;; ==================================================

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
        jsr     L0CF0
        A2D_CALL $2B

;;; ==================================================
;;; Input loop

input_loop:
        A2D_CALL A2D_GET_INPUT, get_input_params
        lda     get_input_params::state
        cmp     #A2D_INPUT_DOWN
        bne     :+
        jsr     L0A45
        jmp     input_loop

:       cmp     #A2D_INPUT_KEY
        bne     input_loop

on_key:
        lda     get_input_params::modifiers
        bne     input_loop
        lda     get_input_params::key
        cmp     #KEY_ENTER
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
        bne     L0A3F
        lda     #3
        jmp     L0A3F

on_key_right:
        clc
        lda     selected_field
        adc     #1
        cmp     #4
        bne     L0A3F
        lda     #1
L0A3F:  jsr     L0DB4
        jmp     input_loop

;;; ==================================================

.proc L0A45
        A2D_CALL A2D_QUERY_TARGET, get_input_params::xcoord
        A2D_CALL A2D_SET_FILL_MODE, fill_mode_params
        A2D_CALL A2D_SET_PATTERN, white_pattern
        lda     query_target_params::id
        cmp     #window_id
        bne     miss
        lda     query_target_params::element
        bne     L0A64
miss:   rts

L0A64:  cmp     #A2D_ELEM_CLIENT
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
jump:   jmp     L1000           ; self modified

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
        jmp     L0DB4

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

        jsr     L0DF2
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

gosub:  jsr     L1000           ; self modified
        A2D_CALL $0C, L08FC
        jmp     draw_selected_field
.endproc

hit_rect_index:
        .byte   0

;;; ==================================================

increment_table:
        .addr   0, increment_day, increment_month, increment_year
decrement_table:
        .addr   0, decrement_day, decrement_month, decrement_year

increment_day:
        clc
        lda     day
        adc     #1
        cmp     #32
        bne     :+
        lda     #1
:       sta     day
        jmp     prepare_day_string

increment_month:
        clc
        lda     month
        adc     #1
        cmp     #13
        bne     :+
        lda     #1
:       sta     month
        jmp     prepare_month_string

increment_year:
        clc
        lda     year
        adc     #1
        cmp     #100
        bne     :+
        lda     #0
:       sta     year
        jmp     prepare_year_string

decrement_day:
        dec     day
        bne     :+
        lda     #31
        sta     day
:       jmp     prepare_day_string

decrement_month:
        dec     month
        bne     :+
        lda     #12
        sta     month
:       jmp     prepare_month_string

decrement_year:
        dec     year
        bpl     :+
        lda     #99
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

prepare_year_string:
        lda     year
        jsr     number_to_ascii
        sta     year_string+3
        stx     year_string+4
        rts

;;; ==================================================

dialog_result:  .byte   0

.proc destroy
        A2D_CALL A2D_DESTROY_WINDOW, L0947
        jsr     UNKNOWN_CALL
        .byte   $0C
        .addr   0

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
        jmp     L086B
.endproc
        sizeof_routine := * - routine
.endproc

;;; ==================================================

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
        adc     #$08            ; byte offset
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

border_rect:  .byte   $04,$00,$02,$00,$C0,$00,$3D,$00
date_rect:  .byte   $20,$00,$0F,$00,$9A,$00,$23,$00

label_ok:
        A2D_DEFSTRING {"OK         ",$0D} ; ends with newline
label_cancel:
        A2D_DEFSTRING "Cancel  ESC"
label_uparrow:
        A2D_DEFSTRING $0B ; up arrow
label_downarrow:
        A2D_DEFSTRING $0A ; down arrow

label_cancel_pos:
        .word   $15,$38
label_ok_pos:
        .word   $6E,$38

label_uparrow_pos:
        .word   $AC,$13
label_downarrow_pos:
        .word   $AC,$27

        ;; Params for $0A call
L0CEE:  .byte   $01,$01

;;; ==================================================
;;; Render the window contents

L0CF0:  A2D_CALL A2D_SET_BOX1, create_window_params::box
        A2D_CALL A2D_DRAW_RECT, border_rect
        A2D_CALL $0A, L0CEE     ; ????
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
        jmp     L0DB4

draw_selected_field:
        lda     selected_field
        cmp     #1
        beq     draw_day
        cmp     #2
        beq     draw_month
        jmp     draw_year

draw_day:
        A2D_CALL A2D_SET_POS, day_pos
        A2D_CALL A2D_DRAW_TEXT, day_string
        rts

draw_month:
        A2D_CALL A2D_SET_POS, month_pos
        A2D_CALL A2D_DRAW_TEXT, spaces_string ; variable width, so clear first
        A2D_CALL A2D_SET_POS, month_pos
        A2D_CALL A2D_DRAW_TEXT, month_string
        rts

draw_year:
        A2D_CALL A2D_SET_POS, year_pos
        A2D_CALL A2D_DRAW_TEXT, year_string
        rts

;;; ==================================================

L0DB4:  pha
        lda     selected_field
        beq     L0DD1
        cmp     #1
        bne     L0DC4
        jsr     L0DE4
        jmp     L0DD1

L0DC4:  cmp     #2
        bne     L0DCE
        jsr     L0DEB
        jmp     L0DD1

L0DCE:  jsr     L0DDD
L0DD1:  pla
        sta     selected_field
        cmp     #1
        beq     L0DE4
        cmp     #2
        beq     L0DEB
L0DDD:  A2D_CALL A2D_FILL_RECT, year_rect
        rts

L0DE4:  A2D_CALL A2D_FILL_RECT, day_rect
        rts

L0DEB:  A2D_CALL A2D_FILL_RECT, month_rect
        rts

L0DF2:  lda     #$FF
        sec
L0DF5:  pha
L0DF6:  sbc     #$01
        bne     L0DF6
        pla
        sbc     #$01
        bne     L0DF5
        rts

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
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00

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
