;;; ============================================================
;;; Bootstrap
;;; ============================================================

        .org $290

.scope


L118B           := $118B
L2000           := $2000
MGTK            := $4000
FONT            := $8800
START           := $8E00
L9F00           := $9F00


        jmp     L02E5

        ora     (WNDLFT,x)
        .byte   $02
L0296:  .byte   0
        .byte   $03
L0298:  .byte   $80
L0299:  .byte   $02
        .byte   0
L029B:  php
L029C:  ora     ($04,x)
L029E:  .byte   0
L029F:  .byte   0
L02A0:  jsr     L9F00
        .byte   0
        .byte   0
        ora     ($00,x)
        asl     a
        .byte   $80
        .byte   $02
        .byte   0
L02AB:  .byte   0
L02AC:  .byte   0
L02AD:  .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
        .byte   0
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
        .byte   0
        .byte   0
        .byte   0
L02D0:  MLI_CALL SET_PREFIX, $0293
        beq     L02DD
        pla
        pla
        jmp     L03CB

L02DD:  rts

L02DE:  MLI_CALL OPEN, $0297
        rts

L02E5:  lda     ROMIN2
        copy16  #$2000, L03BF
        ldx     #$16
        lda     #$00
L02F6:  sta     $BF58,x
        dex
        bne     L02F6
        jsr     L02D0
        lda     $0220
        sta     L0296
        MLI_CALL GET_FILE_INFO, $02A7
        beq     L0310
        jmp     L03CB

L0310:  lda     L02AB
        cmp     #$B3
        bne     L031A
        jmp     L03C2

L031A:  cmp     #$06
        bne     L0342
        lda     L02AC
        sta     L03BF
        sta     L029F
        lda     L02AD
        sta     L03C0
        sta     L02A0
        cmp     #$0C
        bcs     L033B
        lda     #$BB
        sta     L029B
        bne     L037A
L033B:  lda     #$08
        sta     L029B
        bne     L037A
L0342:  cmp     #$FC
        bne     L037A
        copy16  #$02BC, L0298
L0350:  jsr     L02DE
        beq     L0371
        ldy     $0220
L0358:  lda     $0220,y
        cmp     #$2F
        beq     L0367
        dey
        cpy     #$01
        bne     L0358
        jmp     L03CB

L0367:  dey
        sty     $0220
        jsr     L02D0
        jmp     L0350

L0371:  lda     L0296
        sta     $0220
        jmp     L037F

L037A:  jsr     L02DE
        bne     L03CB
L037F:  lda     L029C
        sta     L029E
        MLI_CALL READ, $029D
        bne     L03CB
        MLI_CALL CLOSE, $02A5
        bne     L03CB
        lda     L02AB
        cmp     #$FC
        bne     L03AB
        jsr     L02D0
        ldy     $0280
L03A2:  lda     $0280,y
        sta     $2006,y
        dey
        bpl     L03A2
L03AB:  lda     #$03
        pha
        lda     #$C1
        pha
        jsr     L03C1
        lda     #$01
MOUSE_X_LO      := * + 2
        sta     $BF6F
        lda     #$CF
        sta     $BF58
L03BF           := * + 1
L03C0           := * + 2
        jmp     L2000

L03C1:  rts

L03C2:  jsr     L03C1
        MLI_CALL QUIT, $02C9
L03CB:  rts

        .byte   $03
        jmp     L118B

; DOS warmstart vector
DOSWARM:MLI_CALL CLOSE, $102F
        beq     L03DB
        jmp     L118B

L03DB:  jmp     L2000

        jsr     SLOT3ENTRY
        jsr     HOME
        lda     #$0C
        sta     CV
        jsr     VTAB
        lda     #$50
XFERSTARTLO:
        sec
XFERSTARTHI:
        .byte   $ED
        .byte   $5E

.endscope