.org $290
; da65 V2.16 - Git f5e9b401
; Created:    2018-01-05 09:39:35
; Input file: orig/DESKTOP2_s6
; Page:       1


        .setcpu "6502"

A2D             := $4000
UNKNOWN_CALL    := $8E00
L9F00           := $9F00
MLI             := $BF00
RAMRDOFF        := $C002
RAMRDON         := $C003
RAMWRTOFF       := $C004
RAMWRTON        := $C005
ALTZPOFF        := $C008
ALTZPON         := $C009
LCBANK1         := $C08B
AUXMOVE         := $C311
XFER            := $C314
A2D_RELAY       := $D000
DESKTOP_RELAY   := $D040
FSUB            := $E7A7
FADD            := $E7BE
FMULT           := $E97F
FDIV            := $EA66
ROUND           := $EB2B
FLOAT           := $EB93
FIN             := $EC4A
FOUT            := $ED34
INIT            := $FB2F
BELL1           := $FBDD
HOME            := $FC58
COUT            := $FDED
SETKBD          := $FE89
SETVID          := $FE93
        jmp     L02E5

        ora     ($20,x)
        .byte   $02
L0296:  brk
        .byte   $03
L0298:  .byte   $80
L0299:  .byte   $02
        brk
L029B:  php
L029C:  ora     ($04,x)
L029E:  brk
L029F:  brk
L02A0:  jsr     L9F00
        brk
        brk
L02A5:  ora     ($00,x)
        asl     a
        .byte   $80
        .byte   $02
        brk
L02AB:  brk
L02AC:  brk
L02AD:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $0C
        .byte   $42
        eor     ($53,x)
        eor     #$43
        rol     $5953
        .byte   $53
        .byte   $54
        eor     $4D
        .byte   $04
        inc     $0280
        brk
        brk
        brk
L02D0:  jsr     MLI
        dec     $93
        .byte   $02
        beq     L02DD
        pla
        pla
        jmp     L03CB

L02DD:  rts

L02DE:  jsr     MLI
        iny
        .byte   $97
        .byte   $02
        rts

L02E5:  lda     $C082
        lda     #$00
        sta     L03B8
        lda     #$20
        sta     L03B9
        ldx     #$16
        lda     #$00
L02F6:  sta     $BF58,x
        dex
        bne     L02F6
        jsr     L02D0
        lda     $0220
        sta     L0296
        jsr     MLI
        cpy     $A7
        .byte   $02
        beq     L0310
        jmp     L03CB

L0310:  lda     L02AB
        cmp     #$B3
        bne     L031D
        jsr     L03C0
        jmp     L03BA

L031D:  cmp     #$06
        bne     L0345
        lda     L02AC
        sta     L03B8
        sta     L029F
        lda     L02AD
        sta     L03B9
        sta     L02A0
        cmp     #$0C
        bcs     L033E
        lda     #$BB
        sta     L029B
        bne     L037D
L033E:  lda     #$08
        sta     L029B
        bne     L037D
L0345:  cmp     #$FC
        bne     L037D
        lda     #$BC
        sta     L0298
        lda     #$02
        sta     L0299
L0353:  jsr     L02DE
        beq     L0374
        ldy     $0220
L035B:  lda     $0220,y
        cmp     #$2F
        beq     L036A
        dey
        cpy     #$01
        bne     L035B
        jmp     L03CB

L036A:  dey
        sty     $0220
        jsr     L02D0
        jmp     L0353

L0374:  lda     L0296
        sta     $0220
        jmp     L0382

L037D:  jsr     L02DE
        bne     L03CB
L0382:  lda     L029C
        sta     L029E
        jsr     MLI
        dex
        sta     $D002,x
        .byte   $3B
        jsr     MLI
        cpy     L02A5
        bne     L03CB
        lda     L02AB
        cmp     #$FC
        bne     L03AE
        jsr     L02D0
        ldy     $0280
L03A5:  lda     $0280,y
        sta     $2006,y
        dey
        bpl     L03A5
L03AE:  lda     #$03
        pha
        lda     #$B9
        pha
        jsr     L03C0
        .byte   $4C
L03B8:  brk
L03B9:  .byte   $20
L03BA:  jsr     MLI
        adc     $C9
        .byte   $02
L03C0:  lda     #$01
        sta     $BF6F
        lda     #$CF
        sta     $BF58
        rts

L03CB:  rts

        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
        brk
