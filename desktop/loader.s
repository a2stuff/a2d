        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/auxmem.inc"
        .include "../inc/prodos.inc"

L02B4           := $02B4
L02B6           := $02B6
L02C3           := $02C3
L02C5           := $02C5
L02E6           := $02E6
L035F           := $035F
L0393           := $0393
L03B3           := $03B3
L03C1           := $03C1
L03E5           := $03E5
L0800           := $0800

L7ECA           := $7ECA

        .org $2000

;;; Patch self in as ProDOS QUIT routine (LCBank2 $D100)
;;; and invoke QUIT

.proc install_as_quit

        src     := quit_routine
        dst     := $D100

        lda     LCBANK2
        lda     LCBANK2

        ldy     #$00
loop:   lda     src,y
        sta     dst,y
        lda     src+$100,y
        sta     dst+$100,y
        dey
        bne     loop
        lda     ROMIN2

        MLI_CALL QUIT, quit_params

.proc quit_params
params: .byte   4
        .byte   0
        .word   0
        .byte   0
        .word   0
.endproc
.endproc ; install_as_quit

;;; New QUIT routine. Gets relocated to $1000 by ProDOS before
;;; being executed.

.proc quit_routine
        .org    $1000

        jmp     L1044

        .byte   $00,"Mouse Desk",$00

        PASCAL_STRING "Loading Apple II DeskTop"
        PASCAL_STRING "DeskTop2"

L1031:
        .byte   $04,$00,$00
        .byte   $1E,$00,$04,$00,$00
L1039:  .byte   $01,$00
L103B:  .byte   $01,$90,$11,$03,$28,$10,$00,$1A,$00
L1044:  lda     ROMIN2
        jsr     SETVID
        jsr     SETKBD
        sta     CLR80VID
        sta     SETALTCHAR
        sta     CLR80COL
        jsr     SLOT3ENTRY
L2080:  jsr     HOME
        lda     #$00
        sta     SHADOW          ; ??? IIgs specific?
        lda     #$40
        sta     RAMWRTON
        sta     $0100
        sta     $0101
        sta     RAMWRTOFF
        lda     #$0C
        sta     $25
        jsr     VTAB
        lda     #$50
        sec
        sbc     $100F
        lsr     a
        sta     $24
        ldy     #$00
L20A8:  lda     $1010,y
        ora     #$80
        jsr     COUT
        iny
        cpy     $100F
        bne     L20A8
        MLI_CALL CLOSE, L1039
        ldx     #$17
        lda     #$01
        sta     $BF58,x
        dex
        lda     #$00
L20C6:  sta     $BF58,x
        dex
        bpl     L20C6
        lda     #$CF
        sta     $BF58
        lda     $1003
        bne     L210F
L20D6:  MLI_CALL GET_PREFIX, L103B
L20DC:  .byte   $F0
L20DD:  .byte   $03
        jmp     L118B

L20E1:  lda     #$FF
        sta     $1003
        lda     $03FE
        sta     $1189
        lda     $03FF
        sta     $118A
        lda     LCBANK2
        lda     LCBANK2
        ldy     #$00
L20FA:  lda     $1000,y
        sta     $D100,y
        lda     $1100,y
        sta     $D200,y
        dey
        bne     L20FA
        lda     ROMIN2
        jmp     L10F4

L210F:  lda     $1189
        sta     $03FE
        lda     $118A
        sta     $03FF
L10F4:  MLI_CALL SET_PREFIX, L103B
        beq     L2126
        jmp     L1129

L2126:  .byte   $20
L2127:  brk
        .byte   $BF, $C8, $3E
        .byte   $10
        .byte   $F0
L212D:  .byte   $03
L212E:  jmp     L118B

L2131:  lda     $1043
        sta     $1032
        MLI_CALL READ, L1031
        beq     L2142
        jmp     L118B

L2142:  MLI_CALL CLOSE, L1039
        beq     L214D
        jmp     L118B

L214D:  jmp     $2000

L1129:  jsr     SLOT3ENTRY
        jsr     HOME
        lda     #$0C
        sta     $25
        jsr     VTAB
        lda     #$50
        sec
        sbc     $1160
        lsr     a
        sta     $24
        ldy     #$00
L2168:  .byte   $B9
L2169:  adc     ($11,x)
        ora     #$80
        jsr     COUT
        iny
        cpy     $1160
        bne     L2168
L2176:  sta     KBDSTRB
L2179:  lda     CLR80COL
        bpl     L2179
        and     #$7F
        cmp     #$0D
        bne     L2176
        jmp     L1044

        PASCAL_STRING "Insert the system disk and Press Return."
        .byte   $00,$00
L118B:  sta     $6
        jmp     $FF69

        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$4C,$4C,$20,$03,$18,$20,$00
        .byte   $30,$00,$04,$00,$00,$00,$00,$00
        .byte   $00,$00,$01,$00,$02,$00,$80,$05
        .byte   $00

        PASCAL_STRING "DeskTop2"

        .byte   $00,$3F,$00,$40,$00,$40
        .byte   $00,$40,$00,$08,$90,$02,$00,$40
        .byte   $00,$D0,$00,$FB,$00,$40,$00,$08
        .byte   $90,$02,$00,$80,$00,$1D,$00,$05
        .byte   $00,$7F,$00,$08,$60,$01,$01,$02
        .byte   $02,$00,$00,$00,$06,$A2,$17,$A9
        .byte   $00
L2250:  sta     $BF59,x
        dex
        bpl     L2250
        php
        sei
        MLI_CALL OPEN, $2003
        plp
        and     #$FF
        beq     L2264
        brk
L2264:  lda     $2008
        sta     $2014
        sta     $200A
        php
        sei
        MLI_CALL SET_MARK, $2013
        plp
        and     #$FF
        beq     L227B
        brk
L227B:  lda     #$00
        sta     $20DC
        lda     $20DC
        cmp     $204B
        bne     L2299
        php
        sei
        MLI_CALL CLOSE, $2011
        plp
        and     #$FF
        beq     L2296
        brk
L2296:  jmp     L0800

L2299:  asl     a
        tax
        lda     $2021,x
        sta     $200B
        lda     $2022,x
        sta     $200C
        lda     $2039,x
        sta     $200D
        lda     $203A,x
        sta     $200E
        php
        sei
        MLI_CALL READ, $2009
        plp
        and     #$FF
        beq     L22C1
        brk
L22C1:  ldx     $20DC
        lda     $2045,x
        beq     L22D6
        cmp     #$02
        beq     L22D3
        jsr     $212E
        jmp     $20D6

L22D3:  jsr     $20DD
L22D6:  inc     $20DC
        jmp     $2080

        brk
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        lda     #$80
        sta     $0100
        sta     $0101
        lda     #$00
        sta     $06
        sta     $08
        lda     $20DC
        asl     a
        tax
        lda     $202E,x
        sta     $09
        lda     $200C
        sta     $07
        clc
        adc     $203A,x
        sta     $212D
        lda     $2039,x
        beq     L2312
        inc     $212D
L2312:  ldy     #$00
L2314:  lda     ($06),y
        sta     ($08),y
        iny
        bne     L2314
        inc     $07
        inc     $09
        lda     $07
        cmp     $212D
        bne     L2314
        sta     ALTZPOFF
        lda     ROMIN2
        rts

        brk
        lda     #$00
        sta     $06
        sta     $08
        lda     $20DC
        asl     a
        tax
        lda     $202E,x
        sta     $09
        lda     $200C
        sta     $07
        clc
        adc     $203A,x
        sta     $2168
        sta     RAMRDOFF
        sta     RAMWRTON
        ldy     #$00
L2352:  lda     ($06),y
        sta     ($08),y
        iny
        bne     L2352
        inc     $07
        inc     $09
        lda     $07
        cmp     $2168
        bne     L2352
        sta     RAMWRTOFF
        rts

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
        pha
        lda     BUTN0
        and     BUTN1
        bpl     L2410
        lda     KBD
        cmp     #$D0
        beq     L2414
L2410:  pla
        jmp     L7ECA

L2414:  sta     KBDSTRB
        sta     SET80COL
        sta     SET80VID
        sta     DHIRESON
        lda     TXTCLR
        lda     HIRES
        sta     ALTZPOFF
        sta     ROMIN2
        lda     #$00
        sta     $03C5
        jmp     L035F

        ldy     #$00
        lda     $03CF,y
        beq     L2442
        jsr     L03C1
        iny
        jmp     L02B6

L2442:  rts

        ldy     #$00
        lda     $03DE,y
        beq     L2451
        jsr     L03C1
        iny
        jmp     L02C5

L2451:  rts

        ldx     #$00
L2454:  lda     $02E0,x
        jsr     L03C1
        inx
        cpx     #$06
        bne     L2454
        rts

        .byte   $1B
        .byte   $47, $30
        and     $36,x
        bmi     L2487
        .byte   $D2, $02
        ldy     #$00
        sty     $03CC
        lda     #$01
        sta     $03C9
        lda     #$00
        sta     $03C6
        sta     $03C7
L247B:  lda     #$08
        sta     $03CB
        lda     $03C5
        sta     $03C8
L2486:  .byte   $AD
L2487:  iny
        .byte   $03
        jsr     L0393
        lda     $03CC
        lsr     a
        tay
        sta     LOWSCR
        bcs     L2499
        sta     HISCR
L2499:  lda     ($06),y
        and     $03C9
        cmp     #$01
        ror     $03CA
        inc     $03C8
        dec     $03CB
        bne     L2486
        lda     $03CA
        eor     #$FF
        sta     LOWSCR
        jsr     L03C1
        lda     $03C6
        cmp     #$2F
        bne     L24C4
        lda     $03C7
        cmp     #$02
        beq     L24DB
L24C4:  asl     $03C9
        bpl     L24D1
        lda     #$01
        sta     $03C9
        inc     $03CC
L24D1:  inc     $03C6
        bne     L247B
        inc     $03C7
        bne     L247B
L24DB:  sta     LOWSCR
        rts

        jsr     L03B3
        jsr     L02B4
L24E5:  jsr     L02E6
        lda     #$0D
        jsr     L03C1
        lda     #$0A
        jsr     L03C1
        lda     $03C8
        sta     $03C5
        cmp     #$C0
        bcc     L24E5
        lda     #$0D
        jsr     L03C1
        lda     #$0D
        jsr     L03C1
        jsr     L02C3
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        rts

        pha
        and     #$C7
        eor     #$08
        sta     $07
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        sta     $06
        pla
        and     #$38
        asl     a
        asl     a
        eor     $06
        asl     a
        rol     $07
        asl     a
        rol     $07
        eor     $06
        sta     $06
        rts

        lda     #$C1
        sta     $37
        lda     #$00
        sta     $36
        lda     #$8D
        jsr     L03E5
        rts

        jsr     COUT
        rts

        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$1B,$65,$1B,$54,$31,$36
        .byte   $09,$4C,$20,$44,$8D,$09,$5A,$8D
        .byte   $00,$1B,$4E,$1B,$54,$32,$34,$00
        .byte   $4C,$00,$C1,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00
.endproc ; quit_routine
