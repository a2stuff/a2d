        .org $D000
        .setcpu "65C02"

        .include "apple2.inc"
        .include "../desk.acc/a2d.inc"
        .include "../inc/auxmem.inc"

L87F6           := $87F6
L8813           := $8813
LB600           := $B600

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

.scope
        sta     addr
        stx     addr+1
        sta     RAMRDON
        sta     RAMWRTON
        A2D_CALL $0E, 0, addr
        ldy     #$19
        lda     #$E9
        ldx     #$E6
        jsr     LD000
        tay
        sta     RAMRDOFF
        sta     RAMWRTOFF
        tya
        rts
.endscope

.scope
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
.endscope

        sta     RAMRDON
        sta     RAMWRTON
        ldx     #$00
LD066:  lda     $1F80,x
        beq     LD071
        inx
        cpx     #$7F
        bne     LD066
        rts

LD071:  inx
        txa
        dex
        tay
        lda     #$01
        sta     $1F80,x
        sta     RAMRDOFF
        sta     RAMWRTOFF
        tya
        rts

        tay
        sta     RAMRDON
        sta     RAMWRTON
        dey
        lda     #$00
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
        lda     LEC02,x
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
        lda     LEC14,x
        sta     $07
        bit     LD106
        bmi     LD0EC
        ldy     #$00
LD0DE:  cpy     LDEA0
        beq     LD0FC
        lda     ($06),y
        sta     LDEA0+1,y
        iny
        jmp     LD0DE

LD0EC:  ldy     #$00
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

LD106:  brk
        rts

        sta     RAMRDON
        sta     RAMWRTON
        jsr     A2D
        .byte   $05
        .addr   $06
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

        stx     LD14C
        sta     LD14B
        sta     RAMRDON
        sta     RAMWRTON
        .byte   $AD
LD14B:  .byte   $34
LD14C:  ora     ($8D)
        .byte   $02
        cpy     #$8D
        tsb     $C0
        rts

        ldx     #$00
        sta     RAMRDON
        sta     RAMWRTON
        jsr     LB600
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts

        .res    154, 0

        .byte   0,1,2,3,4,5,6,7

        .byte   $00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$15,$D2,$00
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

        .byte   $0F
        .byte   $01,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$96,$00,$32,$00,$F4
        .byte   $01,$8C,$00,$4B,$00,$23,$00,$00
        .byte   $20,$80,$00,$00,$00,$00,$00,$90
        .byte   $01,$64,$00,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$00,$00,$00,$00
        .byte   $00,$01,$01,$00,$7F,$00,$88,$00
        .byte   $00,$12,$01,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$96,$00,$32
        .byte   $00,$F4,$01,$8C,$00,$19,$00,$14
        .byte   $00,$00,$20,$80,$00,$00,$00,$00
        .byte   $00,$F4,$01,$99,$00,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$00,$00
        .byte   $00,$00,$00,$01,$01,$00,$7F,$00
        .byte   $88,$00,$00,$15,$01,$00,$00,$00
        .byte   $C1,$00,$00,$03,$00,$00,$00,$64
        .byte   $00,$46,$00,$64,$00,$46,$00,$35
        .byte   $00,$32,$00,$00,$20,$80,$00,$00
        .byte   $00,$00,$00,$7D,$00,$46,$00,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$01,$01,$00
        .byte   $7F,$00,$88,$00,$00,$18,$01,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$96,$00,$32,$00,$F4,$01,$8C
        .byte   $00,$50,$00,$28,$00,$00,$20,$80
        .byte   $00,$00,$00,$00,$00,$90,$01,$6E
        .byte   $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$00,$00,$00,$00,$00,$01
        .byte   $01,$00,$7F,$00,$88,$00,$00,$1B
        .byte   $01,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$96,$00,$32,$00,$F4
        .byte   $01,$8C,$00,$69,$00,$19,$00,$00
        .byte   $20,$80,$00,$00,$00,$00,$00,$5E
        .byte   $01,$6E,$00,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$00,$00,$00,$00
        .byte   $00,$01,$01,$00,$7F,$00,$88,$00
        .byte   $00,$28,$00,$25,$00,$68,$01,$2F
        .byte   $00,$2D,$00,$2E,$00,$28,$00,$3D
        .byte   $00,$68,$01,$47,$00,$2D,$00,$46
        .byte   $00,$00,$00,$12,$00,$28,$00,$12
        .byte   $00,$28,$00,$23,$00,$28,$00,$00
        .byte   $00,$4B,$00,$23,$00,$00,$20,$80
        .byte   $00,$00,$00,$00,$00,$66,$01,$64
        .byte   $00,$00,$04,$00,$02,$00,$5A,$01
        .byte   $6C,$00,$05,$00,$03,$00,$59,$01
        .byte   $6B,$00,$06,$00,$16,$00,$58,$01
        .byte   $16,$00,$06,$00,$59,$00,$58,$01
        .byte   $59,$00,$D2,$00,$5C,$00,$36,$01
        .byte   $67,$00,$28,$00,$5C,$00,$8C,$00
        .byte   $67,$00,$D7,$00,$66,$00,$2D,$00
        .byte   $66,$00,$82,$00,$07,$00,$DC,$00
        .byte   $13,$00

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
        .byte   $01,$00,$02,$20,$20

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
        .byte   $64,$00,$81,$D3,$00,$C6,$00,$63
        .byte   $00

        PASCAL_STRING {"OK            ",A2D_GLYPH_RETURN}

        .byte   $C6,$00,$44,$00

        PASCAL_STRING "Close"

        .byte   $C6,$00,$36,$00

        PASCAL_STRING "Open"

        .byte   $C6,$00,$53,$00

        PASCAL_STRING "Cancel        Esc"

        .byte   $C6,$00,$28,$00

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

        .byte   $00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00

        .addr   sd0s, sd1s, sd2s, sd3s, sd4s, sd5s, sd6s
        .addr   sd7s, sd8s, sd9s, sd10s, sd11s, sd12s, sd13s

        .addr   LE4F2

        .res    896, 0

        .byte   $00
LDE9F:  .byte   $00
LDEA0:  .res    256, 0
        .byte   $00

LDFA1:  .addr   $0000,$E723,$E76F,$E7BB,$E807,$E853,$E89F,$E8EB,$E937,$0000,$E983,$E9C4,$EA05,$EA46,$EA87,$EAC8,$EB09,$EB4A

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
        .byte   $06,$E3,$40,$00,$13,$00,$00,$00
        .byte   $00,$00,$00,$00,$0C,$E3,$00,$00
        .byte   $00,$00,$23,$E3,$00,$00,$00,$00
        .byte   $3A,$E3,$00,$00,$00,$00,$51,$E3
        .byte   $00,$00,$00,$00,$68,$E3,$00,$00
        .byte   $00,$00,$7F,$E3,$00,$00,$00,$00
        .byte   $96,$E3,$00,$00,$00,$00,$AD,$E3
        .byte   $00,$00,$00,$00,$C4,$E3,$00,$00
        .byte   $00,$00,$DB,$E3,$00,$00,$00,$00
        .byte   $F2,$E3,$00,$00,$00,$00,$09,$E4
        .byte   $00,$00,$00,$00,$20,$E4,$00,$00
        .byte   $00,$00,$37,$E4,$07,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$4C,$E4
        .byte   $00,$00,$00,$00,$54,$E4,$00,$00
        .byte   $00,$00,$5C,$E4,$00,$00,$00,$00
        .byte   $64,$E4,$00,$00,$00,$00,$6C,$E4
        .byte   $00,$00,$00,$00,$74,$E4,$00,$00
        .byte   $00,$00

        .addr   $E47C

        PASCAL_STRING "All"

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

        PASCAL_STRING "Slot 0 "
        PASCAL_STRING "Slot 0 "
        PASCAL_STRING "Slot 0 "
        PASCAL_STRING "Slot 0 "
        PASCAL_STRING "Slot 0 "
        PASCAL_STRING "Slot 0 "
        PASCAL_STRING "Slot 0 "

        .addr   sd0, sd1, sd2, sd3, sd4, sd5, sd6, sd7
        .addr   sd8, sd9, sd10, sd11, sd12, sd13

        PASCAL_STRING "ProFile Slot x     "
        PASCAL_STRING "UniDisk 3.5  Sx,y  "
        PASCAL_STRING "RAMCard Slot x      "
        PASCAL_STRING "Slot    drive       "

LE4F2:
        .byte   $05,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$46,$E5,$00,$00,$00,$00
        .byte   $57,$E5,$00,$00,$00,$00,$69,$E5
        .byte   $01,$00,$30,$30,$83,$E5,$40,$00
        .byte   $13,$00,$00,$00,$01,$00,$31,$31
        .byte   $1E,$DB,$01,$00,$32,$32,$2E,$DB
        .byte   $01,$00,$33,$33,$3E,$DB,$01,$00
        .byte   $34,$34,$4E,$DB,$01,$00,$35,$35
        .byte   $5E,$DB,$01,$00,$36,$36,$6E,$DB
        .byte   $01,$00,$37,$37,$7E,$DB,$01,$00
        .byte   $38,$38,$8E,$DB

        PASCAL_STRING "Add an Entry ..."
        PASCAL_STRING "Edit an Entry ..."
        PASCAL_STRING "Delete an Entry ...      "
        PASCAL_STRING "Run an Entry ..."

        .byte   $01,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$D6,$E5,$40,$00
        .byte   $13,$00,$00,$00,$00,$00,$00,$00
        .byte   $F2,$E5,$00,$00,$00,$00,$02,$E6
        .byte   $00,$00,$00,$00,$12,$E6,$00,$00
        .byte   $00,$00,$22,$E6,$00,$00,$00,$00
        .byte   $32,$E6,$00,$00,$00,$00,$42,$E6
        .byte   $00,$00,$00,$00,$52,$E6,$00,$00
        .byte   $00,$00,$62,$E6

        PASCAL_STRING "About Apple II DeskTop ... "

        .res    128, 0

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
        .byte   $00,$00,$00,$E7,$00,$00,$00,$EC
        .byte   $E6,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00

         ; Looks like a bunch of window params starting here-ish

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
saddr:  .addr   A2D_SCREEN_ADDR
stride: .word   A2D_SCREEN_STRIDE
hoff:   .word   0
voff:   .word   0
width:  .word   440
height: .word   120
pattern:.res    8, $FF
mskand: .byte   $FF
mskor:  .byte   $00
        .byte   0,0,0,0         ; ???
hthick: .byte   1
vthick: .byte   1
        .byte   0               ; ???
tmsk:   .byte   $7F
font:   .addr   $8800
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

        .res    560, 0

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
LEC01:  .byte   $00
LEC02:  .byte   $1B,$80,$1B,$00,$1C,$80,$1C,$00
        .byte   $1D,$80,$1D,$00,$1E,$80,$1E,$00
        .byte   $1F
LEC13:  .byte   $01
LEC14:  .byte   $1B,$81,$1B,$01,$1C,$81,$1C,$01
        .byte   $1D,$81,$1D,$01,$1E,$81,$1E,$01
        .byte   $1F
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
