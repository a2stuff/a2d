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
L1059:  jsr     HOME
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
L1081:  lda     $1010,y
        ora     #$80
        jsr     COUT
        iny
        cpy     $100F
        bne     L1081
        MLI_CALL CLOSE, L1039
        ldx     #$17
        lda     #$01
        sta     $BF58,x
        dex
        lda     #$00
L109F:  sta     $BF58,x
        dex
        bpl     L109F
        lda     #$CF
        sta     $BF58
        lda     $1003
        bne     L10E8
L10AF:  MLI_CALL GET_PREFIX, L103B
L10B5:  .byte   $F0
L10B6:  .byte   $03
        jmp     L118B

L10BA:  lda     #$FF
        sta     $1003
        lda     $03FE
        sta     $1189
        lda     $03FF
        sta     $118A
        lda     LCBANK2
        lda     LCBANK2
        ldy     #$00
L10D3:  lda     $1000,y
        sta     $D100,y
        lda     $1100,y
        sta     $D200,y
        dey
        bne     L10D3
        lda     ROMIN2
        jmp     L10F4

L10E8:  lda     $1189
        sta     $03FE
        lda     $118A
        sta     $03FF
L10F4:  MLI_CALL SET_PREFIX, L103B
        beq     L10FF
        jmp     L1129

L10FF:  .byte   $20
L1100:  brk
        .byte   $BF, $C8, $3E
        .byte   $10
        .byte   $F0
L1106:  .byte   $03
L1107:  jmp     L118B

L110A:  lda     $1043
        sta     $1032
        MLI_CALL READ, L1031
        beq     L111B
        jmp     L118B

L111B:  MLI_CALL CLOSE, L1039
        beq     L1126
        jmp     L118B

L1126:  jmp     $2000

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
L1141:  .byte   $B9
L1142:  adc     ($11,x)
        ora     #$80
        jsr     COUT
        iny
        cpy     $1160
        bne     L1141
L114F:  sta     KBDSTRB
L1152:  lda     CLR80COL
        bpl     L1152
        and     #$7F
        cmp     #$0D
        bne     L114F
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
L1229:  sta     $BF59,x
        dex
        bpl     L1229
        php
        sei
        MLI_CALL OPEN, $2003
        plp
        and     #$FF
        beq     L123D
        brk
L123D:  lda     $2008
        sta     $2014
        sta     $200A
        php
        sei
        MLI_CALL SET_MARK, $2013
        plp
        and     #$FF
        beq     L1254
        brk
L1254:  lda     #$00
        sta     $20DC
        lda     $20DC
        cmp     $204B
        bne     L1272
        php
        sei
        MLI_CALL CLOSE, $2011
        plp
        and     #$FF
        beq     L126F
        brk
L126F:  jmp     L0800

L1272:  asl     a
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
        beq     L129A
        brk
L129A:  ldx     $20DC
        lda     $2045,x
        beq     L12AF
        cmp     #$02
        beq     L12AC
        jsr     $212E
        jmp     $20D6

L12AC:  jsr     $20DD
L12AF:  inc     $20DC
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
        beq     L12EB
        inc     $212D
L12EB:  ldy     #$00
L12ED:  lda     ($06),y
        sta     ($08),y
        iny
        bne     L12ED
        inc     $07
        inc     $09
        lda     $07
        cmp     $212D
        bne     L12ED
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
L132B:  lda     ($06),y
        sta     ($08),y
        iny
        bne     L132B
        inc     $07
        inc     $09
        lda     $07
        cmp     $2168
        bne     L132B
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
        bpl     L13E9
        lda     KBD
        cmp     #$D0
        beq     L13ED
L13E9:  pla
        jmp     L7ECA

L13ED:  sta     KBDSTRB
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
        beq     L141B
        jsr     L03C1
        iny
        jmp     L02B6

L141B:  rts

        ldy     #$00
        lda     $03DE,y
        beq     L142A
        jsr     L03C1
        iny
        jmp     L02C5

L142A:  rts

        ldx     #$00
L142D:  lda     $02E0,x
        jsr     L03C1
        inx
        cpx     #$06
        bne     L142D
        rts

        .byte   $1B
        .byte   $47, $30
        and     $36,x
        bmi     L1460
        .byte   $D2, $02
        ldy     #$00
        sty     $03CC
        lda     #$01
        sta     $03C9
        lda     #$00
        sta     $03C6
        sta     $03C7
L1454:  lda     #$08
        sta     $03CB
        lda     $03C5
        sta     $03C8
L145F:  .byte   $AD
L1460:  iny
        .byte   $03
        jsr     L0393
        lda     $03CC
        lsr     a
        tay
        sta     LOWSCR
        bcs     L1472
        sta     HISCR
L1472:  lda     ($06),y
        and     $03C9
        cmp     #$01
        ror     $03CA
        inc     $03C8
        dec     $03CB
        bne     L145F
        lda     $03CA
        eor     #$FF
        sta     LOWSCR
        jsr     L03C1
        lda     $03C6
        cmp     #$2F
        bne     L149D
        lda     $03C7
        cmp     #$02
        beq     L14B4
L149D:  asl     $03C9
        bpl     L14AA
        lda     #$01
        sta     $03C9
        inc     $03CC
L14AA:  inc     $03C6
        bne     L1454
        inc     $03C7
        bne     L1454
L14B4:  sta     LOWSCR
        rts

        jsr     L03B3
        jsr     L02B4
L14BE:  jsr     L02E6
        lda     #$0D
        jsr     L03C1
        lda     #$0A
        jsr     L03C1
        lda     $03C8
        sta     $03C5
        cmp     #$C0
        bcc     L14BE
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
