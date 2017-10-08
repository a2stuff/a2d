        .org $D000
        .setcpu "65C02"

        .include "apple2.inc"
        .include "../desk.acc/a2d.inc"
        .include "../inc/auxmem.inc"

L87F6           := $87F6
L8813           := $8813
LB600           := $B600

        ;; A2D call from aux>main, call in Y, params at (X,A)
.proc LD000
        sty     addr-1
        sta     addr
        stx     addr+1
        sta     RAMRDON
        sta     RAMWRTON
        A2D_CALL 0, 0, addr
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc


        ;; SET_POS with params at (X,A) followed by DRAW_TEXT call
.proc LD01C
        sta     addr
        stx     addr+1
        sta     RAMRDON
        sta     RAMWRTON
        A2D_CALL A2D_SET_POS, 0, addr
        ldy     #A2D_DRAW_TEXT
        lda     #<text_buffer
        ldx     #>text_buffer
        jsr     A2D_RELAY
        tay
        sta     RAMRDOFF
        sta     RAMWRTOFF
        tya
        rts
.endproc

        ;; DESKTOP call from aux>main, call in Y params at (X,A)
.proc LD040
        sty     addr-1
        sta     addr
        stx     addr+1
        sta     RAMRDON
        sta     RAMWRTON
        DESKTOP_CALL 0, 0, addr
        tay
        sta     RAMRDOFF
        sta     RAMWRTOFF
        tya
        rts
.endproc

        ;; Find first 0 in AUX $1F80 ... $1F7F; if present,
        ;; mark it 1 and return index+1 in A
.proc LD05E
        sta     RAMRDON
        sta     RAMWRTON
        ldx     #0
loop:   lda     $1F80,x
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
        sta     $1F80,x
        sta     RAMRDOFF
        sta     RAMWRTOFF
        tya
        rts
.endproc

        tay
        sta     RAMRDON
        sta     RAMWRTON
        dey
        lda     #0
        sta     $1F80,y
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts

        lda     #$80
        bne     LD09C
        lda     #$00
LD09C:  sta     LD106
        jsr     L87F6
        lda     LDE9F
        asl     a
        tax
        lda     LEC01,x
        sta     $06
        lda     LEC01+1,x
        sta     $07
        sta     RAMRDON
        sta     RAMWRTON
        bit     LD106
        bpl     LD0C6
        lda     LDEA0
        ldy     #$00
        sta     ($06),y
        jmp     LD0CD

LD0C6:  ldy     #$00
        lda     ($06),y
        sta     LDEA0
LD0CD:  lda     LEC13,x
        sta     $06
        lda     LEC13+1,x
        sta     $07
        bit     LD106
        bmi     LD0EC
        ldy     #0
LD0DE:  cpy     LDEA0
        beq     LD0FC
        lda     ($06),y
        sta     LDEA0+1,y
        iny
        jmp     LD0DE

LD0EC:  ldy     #0
LD0EE:  cpy     LDEA0
        beq     LD0FC
        lda     LDEA0+1,y
        sta     ($06),y
        iny
        jmp     LD0EE

LD0FC:  sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     L8813
        rts

LD106:  .byte   0
        rts                     ; ???

        sta     RAMRDON
        sta     RAMWRTON
        A2D_CALL $05, $06       ; ???
        lda     LEC25
        asl     a
        tax
        lda     LDFA1,x
        sta     $08
        lda     LDFA1+1,x
        sta     $09
        lda     $08
        clc
        adc     #$14
        sta     $08
        bcc     LD12E
        inc     $09
LD12E:  ldy     #$23
LD130:  lda     ($06),y
        sta     ($08),y
        dey
        bpl     LD130
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts

        ;; From MAIN, load AUX (X,A) into A
.proc LD13E
        stx     op+2
        sta     op+1
        sta     RAMRDON
        sta     RAMWRTON
op:     lda     $1234
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

.proc LD154
        ldx     #$00
        sta     RAMRDON
        sta     RAMWRTON
        jsr     LB600
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endproc

        .res    154, 0

        .byte   0,1,2,3,4,5,6,7

        .byte   $00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00
        .addr   buffer
buffer: .byte   $00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$20,$80,$00,$00
        .byte   $00,$00,$00,$0A,$00,$0A,$00,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$01,$01,$00
        .byte   $00,$00,$88,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$FF

LD293:
        .byte   px(%1010101)
        .byte   PX(%0101010)
        .byte   px(%1010101)
        .byte   PX(%0101010)
        .byte   px(%1010101)
        .byte   PX(%0101010)
        .byte   px(%1010101)
        .byte   PX(%0101010)

        .byte   $FF,$06,$EA
        .byte   $00,$00,$00,$00,$88,$00,$08,$00
        .byte   $13,$00,$00,$00,$00,$00,$00

;;; Cursors (bitmap, mask, hotspot)

;;; Pointer

LD2AD:
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0100000),px(%0000000)
        .byte   px(%0110000),px(%0000000)
        .byte   px(%0111000),px(%0000000)
        .byte   px(%0111100),px(%0000000)
        .byte   px(%0111110),px(%0000000)
        .byte   px(%0111111),px(%0000000)
        .byte   px(%0101100),px(%0000000)
        .byte   px(%0000110),px(%0000000)
        .byte   px(%0000110),px(%0000000)
        .byte   px(%0000011),px(%0000000)
        .byte   px(%0000000),px(%0000000)
        .byte   px(%1100000),px(%0000000)
        .byte   px(%1110000),px(%0000000)
        .byte   px(%1111000),px(%0000000)
        .byte   px(%1111100),px(%0000000)
        .byte   px(%1111110),px(%0000000)
        .byte   px(%1111111),px(%0000000)
        .byte   px(%1111111),px(%1000000)
        .byte   px(%1111111),px(%0000000)
        .byte   px(%0001111),px(%0000000)
        .byte   px(%0001111),px(%0000000)
        .byte   px(%0000111),px(%1000000)
        .byte   px(%0000111),px(%1000000)
        .byte   1,1

;;; Insertion Point
LD2DF:
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0110001),px(%1000000)
        .byte   px(%0001010),px(%0000000)
        .byte   px(%0000100),px(%0000000)
        .byte   px(%0000100),px(%0000000)
        .byte   px(%0000100),px(%0000000)
        .byte   px(%0000100),px(%0000000)
        .byte   px(%0000100),px(%0000000)
        .byte   px(%0001010),px(%0000000)
        .byte   px(%0110001),px(%1000000)
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0110001),px(%1000000)
        .byte   px(%1111011),px(%1100000)
        .byte   px(%0111111),px(%1000000)
        .byte   px(%0001110),px(%0000000)
        .byte   px(%0001110),px(%0000000)
        .byte   px(%0001110),px(%0000000)
        .byte   px(%0001110),px(%0000000)
        .byte   px(%0001110),px(%0000000)
        .byte   px(%0111111),px(%1000000)
        .byte   px(%1111011),px(%1100000)
        .byte   px(%0110001),px(%1000000)
        .byte   px(%0000000),px(%0000000)
        .byte   4, 5

;;; Watch
LD311:
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0100000),px(%0010000)
        .byte   px(%0100001),px(%0010000)
        .byte   px(%0100110),px(%0011000)
        .byte   px(%0100000),px(%0010000)
        .byte   px(%0100000),px(%0010000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0111111),px(%1110000)
        .byte   px(%0111111),px(%1110000)
        .byte   px(%1111111),px(%1111000)
        .byte   px(%1111111),px(%1111000)
        .byte   px(%1111111),px(%1111100)
        .byte   px(%1111111),px(%1111000)
        .byte   px(%1111111),px(%1111000)
        .byte   px(%0111111),px(%1110000)
        .byte   px(%0111111),px(%1110000)
        .byte   px(%0011111),px(%1100000)
        .byte   px(%0000000),px(%0000000)
        .byte   5, 5

        .res    384, 0

        .byte   $00,$00

alert_bitmap:
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),px(%0000000),PX(%1111111),PX(%1111111),px(%0000000),px(%0000000)
        .byte   px(%0111100),px(%1111100),px(%0000001),px(%1110000),PX(%0000111),px(%0000000),px(%0000000)
        .byte   px(%0111100),px(%1111100),px(%0000011),px(%1100000),px(%0000011),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0000111),PX(%1100111),px(%1111001),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0001111),PX(%1100111),px(%1111001),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),PX(%1111111),px(%1111001),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),PX(%1111111),px(%1110011),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),PX(%1111111),PX(%1100111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),PX(%1111111),PX(%1001111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),PX(%1111111),PX(%0011111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),px(%1111110),PX(%0111111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),px(%1111100),PX(%1111111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1111100),PX(%0011111),px(%1111100),PX(%1111111),px(%0000000),px(%0000000)
        .byte   px(%0111110),px(%0000000),PX(%0111111),PX(%1111111),PX(%1111111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1100000),PX(%1111111),px(%1111100),PX(%1111111),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1100001),PX(%1111111),PX(%1111111),PX(%1111111),px(%0000000),px(%0000000)
        .byte   px(%0111000),px(%0000011),PX(%1111111),PX(%1111111),px(%1111110),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   PX(%0111111),px(%1100000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)

LD56D:
        .word   $28, $8         ; left, top
        .addr   alert_bitmap
        .byte   $07             ; stride
        .byte   $00
        .word   0, 0, $24, $17  ; hoff, voff, width, height

        ;; Looks like window param blocks starting here

.proc winF
id:     .byte   $0F
flags:  .byte   A2D_CWF_NOTITLE
title:  .addr   0
hscroll:.byte   A2D_CWS_NOSCROLL
vscroll:.byte   A2D_CWS_NOSCROLL
hsmax:  .byte   0
hspos:  .byte   0
vsmax:  .byte   0
vspos:  .byte   0
        .byte   0,0             ; ???
w1:     .word   $96
h1:     .word   $32
w2:     .word   $1F4
h2:     .word   $8C
left:   .word   $4B
top:    .word   $23
addr:   .addr   A2D_SCREEN_ADDR
stride: .word   A2D_SCREEN_STRIDE
hoff:   .word   0
voff:   .word   0
width:  .word   $190
height: .word   $64
pattern:.res    8, $FF
mskand: .byte   A2D_DEFAULT_MSKAND
mskor:  .byte   A2D_DEFAULT_MSKOR
xpos:   .word   0
ypos:   .word   0
hthick: .byte   1
vthick: .byte   1
fill:   .byte   0
tmask:  .byte   A2D_DEFAULT_TMASK
font:   .addr   A2D_DEFAULT_FONT
next:   .addr   0
.endproc

.proc win12
id:     .byte   $12
flags:  .byte   A2D_CWF_NOTITLE
title:  .addr   0
hscroll:.byte   A2D_CWS_NOSCROLL
vscroll:.byte   A2D_CWS_NOSCROLL
hsmax:  .byte   0
hspos:  .byte   0
vsmax:  .byte   0
vspos:  .byte   0
        .byte   0,0             ; ???
w1:     .word   $96
h1:     .word   $32
w2:     .word   $1F4
h2:     .word   $8C
left:   .word   $19
top:    .word   $14
addr:   .addr   A2D_SCREEN_ADDR
stride: .word   A2D_SCREEN_STRIDE
hoff:   .word   0
voff:   .word   0
width:  .word   $1F4
height: .word   $99
pattern:.res    8, $FF
mskand: .byte   A2D_DEFAULT_MSKAND
mskor:  .byte   A2D_DEFAULT_MSKOR
xpos:   .word   0
ypos:   .word   0
hthick: .byte   1
vthick: .byte   1
mode:   .byte   0
tmask:  .byte   A2D_DEFAULT_TMASK
font:   .addr   A2D_DEFAULT_FONT
next:   .addr   0
.endproc

.proc win15
id:     .byte   $15
flags:  .byte   A2D_CWF_NOTITLE
title:  .addr   0
hscroll:.byte   A2D_CWS_NOSCROLL
vscroll:.byte   A2D_CWS_SCROLL_NORMAL
hsmax:  .byte   0
hspos:  .byte   0
vsmax:  .byte   3
vspos:  .byte   0
        .byte   0,0             ; ???
w1:     .word   $64
h1:     .word   $46
w2:     .word   $64
h2:     .word   $46
left:   .word   $35
top:    .word   $32
addr:   .addr   A2D_SCREEN_ADDR
stride: .word   A2D_SCREEN_STRIDE
hoff:   .word   0
voff:   .word   0
width:  .word   $7D
height: .word   $46
pattern:.res    8, $FF
mskand: .byte   A2D_DEFAULT_MSKAND
mskor:  .byte   A2D_DEFAULT_MSKOR
xpos:   .word   0
ypos:   .word   0
hthick: .byte   1
vthick: .byte   1
mode:   .byte   0
tmask:  .byte   A2D_DEFAULT_TMASK
font:   .addr   A2D_DEFAULT_FONT
next:   .addr   0
.endproc

.proc win18
id:     .byte   $18
flags:  .byte   A2D_CWF_NOTITLE
title:  .addr   0
hscroll:.byte   A2D_CWS_NOSCROLL
vscroll:.byte   A2D_CWS_NOSCROLL
hsmax:  .byte   0
hspos:  .byte   0
vsmax:  .byte   0
vspos:  .byte   0
        .byte   0,0             ; ???
w1:     .word   $96
h1:     .word   $32
w2:     .word   $1F4
h2:     .word   $8C
left:   .word   $50
top:    .word   $28
addr:   .addr   A2D_SCREEN_ADDR
stride: .word   A2D_SCREEN_STRIDE
hoff:   .word   0
voff:   .word   0
width:  .word   $190
height: .word   $6E
pattern:.res    8, $FF
mskand: .byte   A2D_DEFAULT_MSKAND
mskor:  .byte   A2D_DEFAULT_MSKOR
xpos:   .word   0
ypos:   .word   0
hthick: .byte   1
vthick: .byte   1
mode:   .byte   0
tmask:  .byte   A2D_DEFAULT_TMASK
font:   .addr   A2D_DEFAULT_FONT
next:   .addr   0
.endproc

.proc win1B
id:     .byte   $1B
flags:  .byte   A2D_CWF_NOTITLE
title:  .addr   0
hscroll:.byte   A2D_CWS_NOSCROLL
vscroll:.byte   A2D_CWS_NOSCROLL
hsmax:  .byte   0
hspos:  .byte   0
vsmax:  .byte   0
vspos:  .byte   0
        .byte   0,0             ; ???
w1:     .word   $96
h1:     .word   $32
w2:     .word   $1F4
h2:     .word   $8C
left:   .word   $69
top:    .word   $19
addr:   .addr   A2D_SCREEN_ADDR
stride: .word   A2D_SCREEN_STRIDE
hoff:   .word   0
voff:   .word   0
width:  .word   $15E
height: .word   $6E
pattern:.res    8, $FF
mskand: .byte   A2D_DEFAULT_MSKAND
mskor:  .byte   A2D_DEFAULT_MSKOR
xpos:   .word   0
ypos:   .word   0
hthick: .byte   1
vthick: .byte   1
mode:   .byte   0
tmask:  .byte   A2D_DEFAULT_TMASK
font:   .addr   A2D_DEFAULT_FONT
next:   .addr   0
.endproc

        ;; Coordinates for labels?
        .byte   $28,$00,$25,$00,$68,$01,$2F,$00,$2D,$00,$2E,$00,$28,$00,$3D,$00,$68,$01,$47,$00,$2D,$00,$46,$00,$00,$00,$12,$00,$28,$00,$12,$00,$28,$00,$23,$00,$28,$00,$00,$00

        .word   $4B, $23        ; left, top
        .addr   A2D_SCREEN_ADDR
        .word   A2D_SCREEN_STRIDE
        .word   0, 0            ; width, height

        .byte   $66,$01,$64,$00,$00,$04,$00,$02,$00,$5A,$01,$6C,$00,$05,$00,$03,$00,$59,$01,$6B,$00,$06,$00,$16,$00,$58,$01,$16,$00,$06,$00,$59,$00,$58,$01,$59,$00,$D2,$00,$5C,$00,$36,$01,$67,$00,$28,$00,$5C,$00,$8C,$00,$67,$00,$D7,$00,$66,$00,$2D,$00,$66,$00,$82,$00,$07,$00,$DC,$00,$13,$00

        PASCAL_STRING "Add an Entry ..."
        PASCAL_STRING "Edit an Entry ..."
        PASCAL_STRING "Delete an Entry ..."
        PASCAL_STRING "Run an Entry ..."
        PASCAL_STRING "Run list"
        PASCAL_STRING "Enter the full pathname of the run list file:"
        PASCAL_STRING "Enter the name (14 characters max)  you wish to appear in the run list"
        PASCAL_STRING "Add a new entry to the:"
        PASCAL_STRING {A2D_GLYPH_OAPPLE,"1 Run list"}
        PASCAL_STRING {A2D_GLYPH_OAPPLE,"2 Other Run list"}
        PASCAL_STRING "Down load:"
        PASCAL_STRING {A2D_GLYPH_OAPPLE,"3 at first boot"}
        PASCAL_STRING {A2D_GLYPH_OAPPLE,"4 at first use"}
        PASCAL_STRING {A2D_GLYPH_OAPPLE,"5 never"}
        PASCAL_STRING "Enter the full pathname of the run list file:"

        .byte   $00,$00,$00,$00,$00,$00,$00
        .byte   $00,$06,$00,$17,$00,$58,$01,$57
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00

        PASCAL_STRING "the DOS 3.3 disk in slot   drive   ?"

        .byte   $1A,$22

        PASCAL_STRING "the disk in slot   drive   ?"

        .byte   $12
        .byte   $1A,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$14,$00,$00,$00,$00
        .byte   $01,$06,$00,$00,$00,$00,$00,$00
        .byte   $01,$00

        PASCAL_STRING "  "

        PASCAL_STRING "Files"

        PASCAL_STRING "       "

        .byte   $00,$00,$00,$00,$0D
        .byte   $00,$00,$00,$00,$00,$7D,$00,$00
        .byte   $00,$02,$00,$00,$00,$00,$00,$02
        .byte   $01,$02,$00,$00,$57,$01,$28,$00
        .byte   $6B,$01,$30,$00,$6B,$01,$38,$00
        .byte   $57,$01,$4B,$00,$6B,$01,$53,$00
        .byte   $6B,$01,$5B,$00,$6B,$01,$63,$00
        .byte   $5A,$01,$29,$00,$64,$01,$2F,$00
        .byte   $5A,$01,$31,$00,$64,$01,$37,$00
        .byte   $5A,$01,$4C,$00,$64,$01,$52,$00
        .byte   $5A,$01,$54,$00,$64,$01,$5A,$00
        .byte   $5A,$01,$5C,$00,$64,$01,$62,$00
        .byte   $5A,$01,$29,$00,$E0,$01,$30,$00
        .byte   $5A,$01,$31,$00,$E0,$01,$37,$00
        .byte   $5A,$01,$4C,$00,$E0,$01,$53,$00
        .byte   $5A,$01,$54,$00,$E0,$01,$5B,$00
        .byte   $5A,$01,$5C,$00,$E0,$01,$63,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$04,$00,$02,$00,$F0,$01
        .byte   $97,$00,$1B,$00,$10,$00,$AE,$00
        .byte   $1A,$00,$C1,$00,$3A,$00,$25,$01
        .byte   $45,$00,$C1,$00,$59,$00,$25,$01
        .byte   $64,$00,$C1,$00,$2C,$00,$25,$01
        .byte   $37,$00,$C1,$00,$49,$00,$25,$01
        .byte   $54,$00,$C1,$00,$1E,$00,$25,$01
        .byte   $29,$00,$43,$01,$1E,$00,$43,$01
        .byte   $64,$00,$81,$D3,$00

        .word   $C6,$63
        PASCAL_STRING {"OK            ",A2D_GLYPH_RETURN}

        .word   $C6,$44
        PASCAL_STRING "Close"

        .word   $C6,$36
        PASCAL_STRING "Open"

        .word   $C6,$53
        PASCAL_STRING "Cancel        Esc"

        .word   $C6,$28
        PASCAL_STRING "Change Drive"

        .byte   $1C,$00,$19,$00,$1C
        .byte   $00,$70,$00,$1C,$00,$87,$00,$00
        .byte   $7F

        PASCAL_STRING " Disk: "

        PASCAL_STRING "Copy a File ..."
        PASCAL_STRING "Source filename:"
        PASCAL_STRING "Destination filename:"

        .byte   $1C,$00,$71,$00,$CF,$01,$7C,$00
        .byte   $1E,$00,$7B,$00,$1C,$00,$88,$00
        .byte   $CF,$01,$93,$00,$1E,$00,$92,$00

        PASCAL_STRING "Delete a File ..."
        PASCAL_STRING "File to delete:"

        .res    40, 0

        .addr   sd0s, sd1s, sd2s, sd3s, sd4s, sd5s, sd6s
        .addr   sd7s, sd8s, sd9s, sd10s, sd11s, sd12s, sd13s

        .addr   LE4F2

        .res    896, 0

        .byte   $00
LDE9F:  .byte   $00
LDEA0:  .res    256, 0
        .byte   $00

LDFA1:  .addr   $0000,win1,win2,win3,win4,win5,win6,win7,win8
        .addr   $0000
        .repeat 8,i
        .addr   buf2+i*$41
        .endrepeat

        .byte   $00,$00,$00,$00,$00

        .res    144, 0

        .byte   $00,$00,$00,$00,$0D,$00,$00,$00

        .res    440, 0

        .byte   $00,$00,$00,$00,$7F,$64,$00,$1C
        .byte   $00,$1E,$00,$32,$00,$1E,$00,$40
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$04,$00,$00,$00,$04,$00,$00
        .byte   $04,$00,$00,$00,$00,$00,$04,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00

        .addr   str_all

        .byte   $40,$00,$13,$00,$00,$00
        .byte   0,0,0,0
        .addr   sd0s
        .byte   0,0,0,0
        .addr   sd1s
        .byte   0,0,0,0
        .addr   sd2s
        .byte   0,0,0,0
        .addr   sd3s
        .byte   0,0,0,0
        .addr   sd4s
        .byte   0,0,0,0
        .addr   sd5s
        .byte   0,0,0,0
        .addr   sd6s
        .byte   0,0,0,0
        .addr   sd7s
        .byte   0,0,0,0
        .addr   sd8s
        .byte   0,0,0,0
        .addr   sd9s
        .byte   0,0,0,0
        .addr   sd10s
        .byte   0,0,0,0
        .addr   sd11s
        .byte   0,0,0,0
        .addr   sd12s
        .byte   0,0,0,0
        .addr   sd13s

        .byte   $07,$00,$00,$00
        .byte   $00,$00
        .byte   0,0,0,0
        .addr   s00
        .byte   0,0,0,0
        .addr   s01
        .byte   0,0,0,0
        .addr   s02
        .byte   0,0,0,0
        .addr   s03
        .byte   0,0,0,0
        .addr   s04
        .byte   0,0,0,0
        .addr   s05
        .byte   0,0,0,0

        .addr   $E47C

str_all:PASCAL_STRING "All"

sd0:    A2D_DEFSTRING "Slot    drive       ", sd0s
sd1:    A2D_DEFSTRING "Slot    drive       ", sd1s
sd2:    A2D_DEFSTRING "Slot    drive       ", sd2s
sd3:    A2D_DEFSTRING "Slot    drive       ", sd3s
sd4:    A2D_DEFSTRING "Slot    drive       ", sd4s
sd5:    A2D_DEFSTRING "Slot    drive       ", sd5s
sd6:    A2D_DEFSTRING "Slot    drive       ", sd6s
sd7:    A2D_DEFSTRING "Slot    drive       ", sd7s
sd8:    A2D_DEFSTRING "Slot    drive       ", sd8s
sd9:    A2D_DEFSTRING "Slot    drive       ", sd9s
sd10:   A2D_DEFSTRING "Slot    drive       ", sd10s
sd11:   A2D_DEFSTRING "Slot    drive       ", sd11s
sd12:   A2D_DEFSTRING "Slot    drive       ", sd12s
sd13:   A2D_DEFSTRING "Slot    drive       ", sd13s

s00:    PASCAL_STRING "Slot 0 "
s01:    PASCAL_STRING "Slot 0 "
s02:    PASCAL_STRING "Slot 0 "
s03:    PASCAL_STRING "Slot 0 "
s04:    PASCAL_STRING "Slot 0 "
s05:    PASCAL_STRING "Slot 0 "
s06:    PASCAL_STRING "Slot 0 "

        .addr   sd0, sd1, sd2, sd3, sd4, sd5, sd6, sd7
        .addr   sd8, sd9, sd10, sd11, sd12, sd13

        PASCAL_STRING "ProFile Slot x     "
        PASCAL_STRING "UniDisk 3.5  Sx,y  "
        PASCAL_STRING "RAMCard Slot x      "
        PASCAL_STRING "Slot    drive       "

LE4F2:
        .byte   $05,$00,$00,$00,$00,$00

        .byte   $00,$00,$00,$00
        .addr   str_add
        .byte   $00,$00,$00,$00
        .addr   str_edit
        .byte   $00,$00,$00,$00
        .addr   str_del
        .byte   $01,$00,$30,$30
        .addr   str_run
        .byte   $40,$00
        .byte   $13,$00,$00,$00,$01,$00,$31,$31
        .byte   $1E,$DB,$01,$00,$32,$32,$2E,$DB
        .byte   $01,$00,$33,$33,$3E,$DB,$01,$00
        .byte   $34,$34,$4E,$DB,$01,$00,$35,$35
        .byte   $5E,$DB,$01,$00,$36,$36,$6E,$DB
        .byte   $01,$00,$37,$37,$7E,$DB,$01,$00
        .byte   $38,$38,$8E,$DB

str_add:
        PASCAL_STRING "Add an Entry ..."
str_edit:
        PASCAL_STRING "Edit an Entry ..."
str_del:
        PASCAL_STRING "Delete an Entry ...      "
str_run:
        PASCAL_STRING "Run an Entry ..."

        .byte   $01,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00
        .addr   str_about
        .byte   $40,$00
        .byte   $13,$00,$00,$00

        .byte   0,0,0,0
        .addr   buf
        .byte   0,0,0,0
        .addr   buf + $10
        .byte   0,0,0,0
        .addr   buf + $20
        .byte   0,0,0,0
        .addr   buf + $30
        .byte   0,0,0,0
        .addr   buf + $40
        .byte   0,0,0,0
        .addr   buf + $50
        .byte   0,0,0,0
        .addr   buf + $60
        .byte   0,0,0,0
        .addr   buf + $70

str_about:
        PASCAL_STRING "About Apple II DeskTop ... "

buf:    .res    $80, 0

        .byte   $01,$00,$01,$00,$9A,$E6,$8E,$E6
        .byte   $00,$00,$00,$00,$00,$00,$01,$00
        .byte   $01,$00,$B7,$E6,$8E,$E6,$00,$00
        .byte   $00,$00,$00,$00,$01,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$B9,$E6

        PASCAL_STRING "Apple II DeskTop Version 1.1"

        .byte   $01,$20,$04
        .byte   $52,$69,$65,$6E,$00,$00,$00,$5D
        .byte   $E7,$A9,$E7,$F5,$E7,$41,$E8,$8D
        .byte   $E8,$D9,$E8,$25,$E9,$71,$E9,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$70,$00,$00,$00,$8C
        .byte   $00,$00,$00,$E7,$00,$00,$00

.proc text_buffer
        .addr   data
        .byte   0
data:   .res    55, 0
.endproc

.macro WIN_PARAMS_DEFN window_id, label, buflabel
.proc label
id:     .byte   window_id
flags:  .byte   A2D_CWF_ADDCLOSE | A2D_CWF_ADDRESIZE
title:  .addr   buflabel
hscroll:.byte   A2D_CWS_SCROLL_NORMAL
vscroll:.byte   A2D_CWS_SCROLL_NORMAL
hsmax:  .byte   3
hspos:  .byte   0
vsmax:  .byte   3
vspos:  .byte   0
        .byte   0,0             ; ???
w1:     .word   170
h1:     .word   50
w2:     .word   545
h2:     .word   175
left:   .word   20
top:    .word   27
addr:   .addr   A2D_SCREEN_ADDR
stride: .word   A2D_SCREEN_STRIDE
hoff:   .word   0
voff:   .word   0
width:  .word   440
height: .word   120
pattern:.res    8, $FF
mskand: .byte   A2D_DEFAULT_MSKAND
mskor:  .byte   A2D_DEFAULT_MSKOR
xpos:   .word   0
ypos:   .word   0
hthick: .byte   1
vthick: .byte   1
mode:   .byte   0
tmask:  .byte   A2D_DEFAULT_TMASK
font:   .addr   A2D_DEFAULT_FONT
next:   .addr   0
.endproc
buflabel:.res    18, 0
.endmacro

        WIN_PARAMS_DEFN 1, win1, win1buf
        WIN_PARAMS_DEFN 2, win2, win2buf
        WIN_PARAMS_DEFN 3, win3, win3buf
        WIN_PARAMS_DEFN 4, win4, win4buf
        WIN_PARAMS_DEFN 5, win5, win5buf
        WIN_PARAMS_DEFN 6, win6, win6buf
        WIN_PARAMS_DEFN 7, win7, win7buf
        WIN_PARAMS_DEFN 8, win8, win8buf

buf2:   .res    560, 0

        PASCAL_STRING " Items"

        .byte   $08,$00,$0A,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00

        PASCAL_STRING "K in disk"
        PASCAL_STRING "K available"
        PASCAL_STRING "      "

        .byte   $00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00

LEC01:  .byte   $00,$1B,$80,$1B,$00,$1C,$80,$1C,$00,$1D,$80,$1D,$00,$1E,$80,$1E,$00,$1F
LEC13:  .byte   $01,$1B,$81,$1B,$01,$1C,$81,$1C,$01,$1D,$81,$1D,$01,$1E,$81,$1E,$01,$1F

LEC25:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00
        .word   500, 160
        .byte   $00,$00,$00

        .res    147, 0
