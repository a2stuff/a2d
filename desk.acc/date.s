        .org $800
        .setcpu "65C02"

        .include "apple2.inc"
        .include "../inc/prodos.inc"
        .include "../inc/auxmem.inc"

        .include "a2d.inc"

ROMIN2          := $C082
DATELO  := $BF90
DATEHI  := $BF91


L0000           := $0000
L0020           := $0020
L1000           := $1000
L4021           := $4021

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
        jsr     L4021
        bne     L08B3
        lda     L0813
        sta     L0815
        sta     L081A
        sta     L0822
        ldy     #$CE
        lda     #$14
        ldx     #$08
        jsr     L4021
        bne     L08AA
        ldy     #$CB
        lda     #$19
        ldx     #$08
        jsr     L4021
L08AA:  ldy     #$CC
        lda     #$21
        ldx     #$08
        jsr     L4021
L08B3:  ldx     stash_stack
        txs
        rts

start_da:
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        jmp     L0986

ok_button_rect:
        .word   $6A,$2E,$B5,$39
cancel_button_rect:
        .word   $10,$2E,$5A,$39
up_arrow_rect:
        .word   $AA,$0A,$B4,$14
down_arrow_rect:
        .word   $AA,$1E,$B4,$28

fill_rect_params3:
        .word   $25,$14,$3B,$1E
fill_rect_params7:
        .word   $51,$14,$6F,$1E
fill_rect_params6:
        .word   $7F,$14,$95,$1E

L08FC:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF

.proc white_pattern
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.endproc
        .byte   $FF

selected_field:
        .byte   0

datelo:  .byte   $00
datehi:  .byte   $00

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
L0937:  .byte   $00
L0938:  .byte   $00
L0939:  .byte   $00
L093A:  .byte   $00
L093B:  .byte   $00
.endproc

L093C:  .byte   $00
L093D:  .byte   $00
L093E:  .byte   $64
L093F:  .byte   $00
L0940:  .byte   $00
L0941:  .byte   $00
L0942:  .byte   $00
L0943:  .byte   $00,$00,$00,$00
L0947:  .byte   $64,$00,$01

.proc fill_mode_params
mode:   .byte   $02
.endproc
        .byte   $06

.proc create_window_params
id:     .byte   $64
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

L0986:  jsr     L0E00
        lda     datehi
        lsr     a
        sta     year
        lda     datelo
        and     #$1F
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
L09BB:  A2D_CALL A2D_GET_INPUT, get_input_params
        lda     get_input_params::L0937
        cmp     #$01
        bne     L09CE
        jsr     L0A45
        jmp     L09BB

L09CE:  cmp     #$03
        bne     L09BB
        lda     get_input_params::L0939
        bne     L09BB
        lda     get_input_params::L0938
        cmp     #$0D
        bne     L09E1
        jmp     L0A92

L09E1:  cmp     #$1B
        bne     L09E8
        jmp     L0ABB

L09E8:  cmp     #$08
        beq     L0A26
        cmp     #$15
        beq     L0A33
        cmp     #$0A
        beq     L0A0F
        cmp     #$0B
        bne     L09BB
        A2D_CALL A2D_FILL_RECT, up_arrow_rect
        lda     #$03
        sta     L0B50
        jsr     L0B17
        A2D_CALL A2D_FILL_RECT, up_arrow_rect
        jmp     L09BB

L0A0F:  A2D_CALL A2D_FILL_RECT, down_arrow_rect
        lda     #$04
        sta     L0B50
        jsr     L0B17
        A2D_CALL A2D_FILL_RECT, down_arrow_rect
        jmp     L09BB

L0A26:  sec
        lda     selected_field
        sbc     #1
        bne     L0A3F
        lda     #3
        jmp     L0A3F

L0A33:  clc
        lda     selected_field
        adc     #1
        cmp     #4
        bne     L0A3F
        lda     #1
L0A3F:  jsr     L0DB4
        jmp     L09BB

L0A45:  A2D_CALL A2D_QUERY_TARGET, get_input_params::L0938
        A2D_CALL A2D_SET_FILL_MODE, fill_mode_params
        A2D_CALL A2D_SET_PATTERN, white_pattern
        lda     L093D
        cmp     #$64
        bne     L0A63
        lda     L093C
        bne     L0A64
L0A63:  rts

L0A64:  cmp     #$02
        bne     L0A63
        jsr     L0C54
        cpx     #$00
        beq     L0A63
        txa
        sec
        sbc     #$01
        asl     a
        tay
        lda     L0A84,y
        sta     L0A82
        lda     L0A85,y
        sta     L0A83
L0A82           := * + 1
L0A83           := * + 2
        jmp     L1000

L0A84:  .byte   $92
L0A85:  .byte   $0A,$BB,$0A,$C9,$0A,$D7,$0A,$E5
        .byte   $0A,$E5,$0A,$E5,$0A
L0A92:  A2D_CALL A2D_FILL_RECT, ok_button_rect
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
        lda     #$01
        sta     L0C1A
        jmp     L0C1B

L0ABB:  A2D_CALL A2D_FILL_RECT, cancel_button_rect
        lda     #$00
        sta     L0C1A
        jmp     L0C1B

        txa
        pha
        A2D_CALL A2D_FILL_RECT, up_arrow_rect
        pla
        tax
        jsr     L0AEC
        rts

        txa
        pha
        A2D_CALL A2D_FILL_RECT, down_arrow_rect
        pla
        tax
        jsr     L0AEC
        rts

        txa
        sec
        sbc     #$04
        jmp     L0DB4

L0AEC:  stx     L0B50
L0AEF:  A2D_CALL A2D_GET_INPUT, get_input_params
        lda     get_input_params::L0937
        cmp     #$02
        beq     L0B02
        jsr     L0B17
        jmp     L0AEF

L0B02:  lda     L0B50
        cmp     #$03
        beq     L0B10
        A2D_CALL A2D_FILL_RECT, down_arrow_rect
        rts

L0B10:  A2D_CALL A2D_FILL_RECT, up_arrow_rect
        rts

L0B17:  jsr     L0DF2
        lda     L0B50
        cmp     #$03
        beq     L0B2C
        lda     #$59
        sta     $07
        lda     #$0B
        sta     $08
        jmp     L0B34

L0B2C:  lda     #$51
        sta     $07
        lda     #$0B
        sta     $08
L0B34:  lda     selected_field
        asl     a
        tay
        lda     ($07),y
        sta     L0B45
        iny
        lda     ($07),y
        sta     L0B46
L0B45           := * + 1
L0B46           := * + 2
        jsr     L1000
        A2D_CALL $0C, L08FC
        jmp     L0D73

L0B50:  .byte   $00,$00,$00,$61,$0B,$73,$0B,$85
        .byte   $0B,$00,$00,$97,$0B,$A4,$0B,$B1
        .byte   $0B
        clc
        lda     day
        adc     #$01
        cmp     #$20
        bne     L0B6D
        lda     #$01
L0B6D:  sta     day
        jmp     prepare_day_string

        clc
        lda     month
        adc     #$01
        cmp     #$0D
        bne     L0B7F
        lda     #$01
L0B7F:  sta     month
        jmp     prepare_month_string

        clc
        lda     year
        adc     #$01
        cmp     #$64
        bne     L0B91
        lda     #$00
L0B91:  sta     year
        jmp     prepare_year_string

        dec     day
        bne     L0BA1
        lda     #$1F
        sta     day
L0BA1:  jmp     prepare_day_string

        dec     month
        bne     L0BAE
        lda     #$0C
        sta     month
L0BAE:  jmp     prepare_month_string

        dec     year
        bpl     L0BBB
        lda     #$63
        sta     year
L0BBB:  jmp     prepare_year_string

.proc prepare_day_string
        lda     day
        jsr     div_by_10_then_ascii
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

        lda     #<str
        sta     ptr
        lda     #>str
        sta     ptr+1

        ldy     #2
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
        jsr     div_by_10_then_ascii
        sta     year_string+3
        stx     year_string+4
        rts

L0C1A:  brk
L0C1B:  A2D_CALL A2D_DESTROY_WINDOW, L0947
        jsr     UNKNOWN_CALL
        .byte   $0C
        .addr   L0000
        ldx     #$09
L0C29:  lda     L0C4B,x
        sta     L0020,x
        dex
        bpl     L0C29
        lda     L0C1A
        beq     L0C48
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
L0C48:  jmp     L0020

L0C4B:  sta     RAMRDOFF
        sta     RAMWRTOFF
        jmp     L086B

L0C54:  lda     get_input_params::L0938
        sta     L093F
        lda     get_input_params::L0939
        sta     L0940
        lda     get_input_params::L093A
        sta     L0941
        lda     get_input_params::L093B
        sta     L0942
        A2D_CALL A2D_MAP_COORDS, L093E
        A2D_CALL A2D_SET_POS, L0943
        ldx     #$01
        lda     #$C4
        sta     L0C8A
        lda     #$08
        sta     L0C8A+1
L0C84:  txa
        pha
        A2D_CALL A2D_TEST_BOX, $1000, L0C8A
        bne     L0CA6
        clc
        lda     L0C8A
        adc     #$08
        sta     L0C8A
        bcc     L0C9C
        inc     L0C8A+1
L0C9C:  pla
        tax
        inx
        cpx     #$08
        bne     L0C84
        ldx     #$00
        rts

L0CA6:  pla
        tax
        rts

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

L0D73:  lda     selected_field
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
L0DDD:  A2D_CALL A2D_FILL_RECT, fill_rect_params6
        rts

L0DE4:  A2D_CALL A2D_FILL_RECT, fill_rect_params3
        rts

L0DEB:  A2D_CALL A2D_FILL_RECT, fill_rect_params7
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

L0E00:  ldx     #$00
L0E02:  lda     L0000,x
        sta     L0E16,x
        dex
        bne     L0E02
        rts

        ldx     #$00
L0E0D:  lda     L0E16,x
        sta     L0000,x
        dex
        bne     L0E0D
        rts

L0E16:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
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

.proc div_by_10_then_ascii      ; A = A / 10, X = remainder, results in ASCII form
        ldy     #$00
loop:   cmp     #$0A            ; Y = A / 10
        bcc     :+
        sec
        sbc     #$0A
        iny
        jmp     loop

:       clc                     ; then convert to ASCII
        adc     #'0'
        tax
        tya
        clc
        adc     #'0'
        rts                     ; remainder in X, result in A
.endproc

        rts                     ; ???

last := *
