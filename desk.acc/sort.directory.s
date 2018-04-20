        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"

        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

        .org $800

;;; ============================================================

        cli
        jmp     start

L0804:  .byte   0

save_stack:
        .byte   0

;;; ============================================================

start:  tsx
        stx     save_stack
        jmp     L0932

L080D:  ldx     save_stack
        txs
        lda     a:$0A
        bne     L0817
        rts

L0817:  lda     #$40
        pha
        lda     #$0B
        pha
        lda     a:$0A
        rts

;;; ============================================================
;;; ProDOS Relays

.proc open
        sta     ALTZPOFF
        MLI_CALL OPEN, open_params
        sta     ALTZPON
        rts
.endproc

.proc read
        sta     ALTZPOFF
        MLI_CALL READ, read_params
        sta     ALTZPON
        rts
.endproc

.proc write_block
        sta     ALTZPOFF
        MLI_CALL WRITE_BLOCK, block_params
        sta     ALTZPON
        rts
.endproc

.proc read_block
        sta     ALTZPOFF
        MLI_CALL READ_BLOCK, block_params
        sta     ALTZPON
        rts
.endproc

.proc on_line
        sta     ALTZPOFF
        MLI_CALL ON_LINE, on_line_params
        sta     ALTZPON
        rts
.endproc
        .byte   0

;;; unused ???
.proc write
        sta     ALTZPOFF
        MLI_CALL WRITE, write_params
        sta     ALTZPON
        rts
.endproc

;;; unused ???
.proc set_mark
        sta     ALTZPOFF
        MLI_CALL SET_MARK, set_mark_params
        sta     ALTZPON
        rts
.endproc

;;; unused ???
.proc get_file_info
        sta     ALTZPOFF
        MLI_CALL GET_FILE_INFO, file_info_params
        sta     ALTZPON
        rts
.endproc

;;; unused ???
.proc set_file_info
        sta     ALTZPOFF
        MLI_CALL SET_FILE_INFO, file_info_params
        sta     ALTZPON
        rts
.endproc

.proc close
        sta     ALTZPOFF
        MLI_CALL CLOSE, close_params
        sta     ALTZPON
        rts
.endproc

;;; ============================================================

        DEFINE_ON_LINE_PARAMS on_line_params,, on_line_buffer
on_line_buffer:
        .res    16, 0

        DEFINE_SET_MARK_PARAMS set_mark_params, $2B
        DEFINE_READ_BLOCK_PARAMS block_params, 0, 0

        .byte   0

        DEFINE_OPEN_PARAMS open_params, path_buf, $1C00
        DEFINE_READ_PARAMS read_params, $0E00, $0E00
        DEFINE_WRITE_PARAMS write_params, $0E00, $0E00
        DEFINE_CLOSE_PARAMS close_params

        DEFINE_GET_FILE_INFO_PARAMS file_info_params, path_buf
        .res    3               ; for SET_FILE_INFO ???

path_buf:
        .res    65, 0

;;; ============================================================

L0932:  sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        yax_call JUMP_TABLE_MGTK_RELAY, MGTK::FrontWindow, $0A
        lda     $0A
        beq     L094C
        cmp     #$09
        bcc     L094F
L094C:  jmp     L080D

L094F:  asl     a
        tay
        lda     $DFB3,y
        sta     $06
        lda     $DFB4,y
        sta     $07
        ldy     #$00
        sty     $10
        lda     ($06),y
        sta     L0976
        sta     path_buf
L0967:  iny
        lda     ($06),y
        and     #$7F
        cmp     #$61
        bcc     L0972
        and     #$DF
L0972:  sta     path_buf,y
        L0976 := *+1
        cpy     #0
        bne     L0967
        ldy     $BF31
        sty     L0A92
L097F:  ldy     L0A92
        lda     $BF32,y
        and     #$F0
        sta     on_line_params::unit_num
        jsr     on_line
        bne     L0994
        jsr     L0AB0
        beq     L099C
L0994:  dec     L0A92
        bpl     L097F
L0999:  jmp     L080D

L099C:  lda     on_line_params::unit_num
        sta     L0804
        jsr     open
        bne     L0999
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     close_params::ref_num
        jsr     read
        jsr     close
        bne     L0999
        ldx     #$02
L09BA:  .byte   $AD
        .byte   $02
L09BC:  asl     $959D
        asl     a
        .byte   $AD
        .byte   $03
L09C2:  asl     $969D
        asl     a
        ora     L0A95,x
        beq     L09DD
        inc     L09BC
        inc     L09BC
        inc     L09C2
        inc     L09C2
        inx
        inx
        cpx     #$0E
        bne     L09BA
L09DD:  txa
        clc
        adc     #$0E
        sta     L0A93
        jsr     L0B40
L09E7:  jsr     L0B16
        bcs     L0A3B
        ldy     #$00
        lda     ($06),y
        and     #$F0
        beq     L09E7
        ldy     #$25
        lda     ($06),y
        sta     L0A95
        iny
        lda     ($06),y
        sta     L0A96
        jsr     L0AE8
        lda     L0804
        sta     block_params::unit_num
        lda     #$00
        sta     L0A94
L0A0F:  lda     L0A94
        asl     a
        tay
        lda     L0A95,y
        sta     block_params::block_num
        lda     L0A96,y
        sta     block_params::block_num+1
        ora     block_params::block_num
        beq     L0A3E
        tya
        clc
        adc     #$0E
        sta     block_params::data_buffer+1
        lda     #$00
        sta     block_params::data_buffer
        jsr     write_block
        bne     L0A3B
        inc     L0A94
        bne     L0A0F
L0A3B:  jmp     L080D

L0A3E:  copy16  #$1C00, block_params::data_buffer
        jsr     L0B40
L0A4B:  jsr     L0B16
        bcs     L0A8E
        ldy     #$00
        lda     ($06),y
        and     #$F0
        beq     L0A4B
        cmp     #$D0
        bne     L0A4B
        ldy     #$11
        lda     ($06),y
        sta     block_params::block_num
        iny
        lda     ($06),y
        sta     block_params::block_num+1
        jsr     read_block
        bne     L0A8F
        lda     $07
        sec
        sbc     #$0E
        and     #$FE
        tay
        lda     L0A95,y
        sta     $1C27
        lda     L0A96,y
        sta     $1C28
        lda     L0AAF
        sta     $1C29
        jsr     write_block
        jmp     L0A4B

L0A8E:  pla
L0A8F:  jmp     L080D

L0A92:  .byte   0
L0A93:  .byte   0
L0A94:  .byte   0
L0A95:  .byte   0
L0A96:  .byte   0
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
L0AAF:  .byte   0

L0AB0:  lda     on_line_buffer
        and     #$0F
        sta     on_line_buffer
        ldy     #$00
L0ABA:  iny
        lda     on_line_buffer,y
        and     #$7F
        cmp     #$61
        bcc     L0AC6
        and     #$DF
L0AC6:  cmp     path_buf+1,y
        bne     L0AE5
        cpy     on_line_buffer
        bne     L0ABA
        lda     on_line_buffer
        clc
        adc     #$01
        cmp     path_buf
        beq     L0AE2
        lda     path_buf+2,y
        cmp     #$2F
        bne     L0AE5
L0AE2:  return  #$00

L0AE5:  return  #$FF

L0AE8:  lda     #$00
        sta     L0B15
        jsr     L0B40
        jsr     L0B16
L0AF3:  copy16  $06, $08
        jsr     L0B16
        bcs     L0B0F
        jsr     L0B5E
        bcc     L0AF3
        jsr     L0B4E
        lda     #$FF
        sta     L0B15
        bne     L0AF3
L0B0F:  lda     L0B15
        bne     L0AE8
        rts

L0B15:  .byte   0

;;; ============================================================

L0B16:  inc     L0AAF
        lda     $06
        clc
        adc     #$27
        sta     $06
        bcc     L0B24
        inc     $07
L0B24:  lda     $06
        cmp     #$FF
        bne     L0B3C
        inc     $07
        lda     #$01
        sta     L0AAF
        lda     #$04
        sta     $06
        lda     $07
        cmp     L0A93
        bcs     L0B3E
L0B3C:  clc
        rts

L0B3E:  sec
        rts

L0B40:  lda     #$01
        sta     L0AAF
        lda     #$04
        sta     $06
        lda     #$0E
        sta     $07
        rts

L0B4E:  ldy     #$26
L0B50:  lda     ($06),y
        pha
        lda     ($08),y
        sta     ($06),y
        pla
        sta     ($08),y
        dey
        bpl     L0B50
        rts

L0B5E:  ldy     #$00
        lda     ($06),y
        and     #$F0
        bne     L0B69
        jmp     L0BF0

L0B69:  lda     ($08),y
        and     #$F0
        bne     L0B72
        jmp     L0BEE

L0B72:  lda     $DF21
        beq     L0B7F
        lda     $DF20
        beq     L0B7F
        jmp     L0BF5

L0B7F:  lda     $08
        ldx     $09
        jsr     L0CFC
        bcc     L0BF0
        lda     $06
        ldx     $07
        jsr     L0CFC
        bcc     L0BEE
        ldy     #$00
        lda     ($08),y
        and     #$F0
        sta     L0BF2
        ldy     #$00
        lda     ($06),y
        and     #$F0
        sta     L0BF3
        lda     L0BF2
        cmp     #$D0
        beq     L0BB3
        lda     L0BF3
        cmp     #$D0
        beq     L0BEE
        bne     L0BC1
L0BB3:  lda     L0BF3
        cmp     #$D0
        bne     L0BF0
        jsr     L0D33
        bcc     L0BF0
        bcs     L0BEE
L0BC1:  lda     #$04
        jsr     L0CBE
        bne     L0BCC
        bcc     L0BF0
        bcs     L0BEE
L0BCC:  lda     #$FF
        jsr     L0CBE
        bne     L0BD7
        bcc     L0BF0
        bcs     L0BEE
L0BD7:  lda     #$FD
        sta     L0BF4
L0BDC:  dec     L0BF4
        lda     L0BF4
        beq     L0BF0
        jsr     L0CBE
        bne     L0BDC
        bcs     L0BEE
        jmp     L0BF0

L0BEE:  sec
        rts

L0BF0:  clc
        rts

L0BF2:  .byte   0
L0BF3:  .byte   0
L0BF4:  .byte   0

;;; ============================================================

L0BF5:  ldx     $DF21
L0BF8:  dex
        bmi     L0C4A
        lda     $DF22,x
        asl     a
        tay
        lda     $DD9F,y
        clc
        adc     #$09
        sta     $10
        lda     $DDA0,y
        adc     #$00
        sta     $11
        ldy     #$00
        lda     ($10),y
        sec
        sbc     #$02
        sta     L0C24
        inc16   $10
L0C1F:  lda     ($06),y
        and     #$0F

        L0C24 := *+1
        cmp     #$0

        bne     L0BF8
        sta     L0C47
L0C2A:  iny
        lda     ($10),y
        and     #$7F
        cmp     #$61
        bcc     L0C35
        and     #$DF
L0C35:  sta     L0C43
        lda     ($06),y
        and     #$7F
        cmp     #$61
        bcc     L0C42
        and     #$DF

        L0C43 := *+1
L0C42:  cmp     #0

        bne     L0BF8

        L0C47 := *+1
        cpy     #0

        bne     L0C2A
L0C4A:  stx     L0CBC
        ldx     $DF21
L0C50:  dex
        bmi     L0CA2
        lda     $DF22,x
        asl     a
        tay
        lda     $DD9F,y
        clc
        adc     #$09
        sta     $10
        lda     $DDA0,y
        adc     #$00
        sta     $11
        ldy     #$00
        lda     ($10),y
        sec
        sbc     #$02
        sta     L0C7C
        inc16   $10
L0C77:  lda     ($08),y
        and     #$0F

        L0C7C := *+1
        cmp     #0

        bne     L0C50
        sta     L0C9F
L0C82:  iny
        lda     ($10),y
        and     #$7F
        cmp     #$61
        bcc     L0C8D
        and     #$DF
L0C8D:  sta     L0C9B
        lda     ($08),y
        and     #$7F
        cmp     #$61
        bcc     L0C9A
        and     #$DF
        L0C9B := *+1
L0C9A:  cmp     #0
        bne     L0C50

        L0C9F := *+1
        cpy     #0

        bne     L0C82
L0CA2:  stx     L0CBD
        lda     L0CBC
        and     L0CBD
        cmp     #$FF
        beq     L0CBA
        lda     L0CBD
        cmp     L0CBC
        beq     L0CBA
        rts

        sec
        rts

L0CBA:  clc
        rts

L0CBC:  .byte   0
L0CBD:  .byte   0
L0CBE:  sta     L0CFB
        ldy     #$10
        lda     ($08),y
        sta     L0CF1
        lda     ($06),y
        sta     L0CF2
        lda     L0CF1
        cmp     L0CFB
        beq     L0CDF
        lda     L0CF2
        cmp     L0CFB
        beq     L0CF7
        bne     L0CEE
L0CDF:  lda     L0CF2
        cmp     L0CFB
        bne     L0CF3
        jsr     L0D33
        bcc     L0CF3
        bcs     L0CF7
L0CEE:  return  #$FF

L0CF1:  .byte   0
L0CF2:  .byte   0
L0CF3:  lda     #$00
        clc
        rts

L0CF7:  lda     #$00
        sec
        rts

L0CFB:  .byte   0
L0CFC:  stax    $00
        ldy     #$10
        lda     ($00),y
        cmp     #$FF
        bne     L0D29
        ldy     #$00
        lda     ($00),y
        and     #$0F
        sec
        sbc     #$06
        bcc     L0D29
        tay
        ldx     #$00
        dey
L0D17:  iny
        inx
        lda     ($00),y
        and     #$7F
        cmp     L0D2B,x
        bne     L0D29
        cpx     L0D2B
        bne     L0D17
        clc
        rts

L0D29:  sec
        rts

L0D2B:  .byte   $07
        rol     $5953
        .byte   $53
        .byte   $54
        eor     $4D
L0D33:  ldy     #$00
        lda     ($08),y
        and     #$0F
        sta     L0D6B
        sta     L0D5C
        lda     ($06),y
        and     #$0F
        sta     L0D6C
        cmp     L0D5C
        bcs     L0D4E
        sta     L0D5C
L0D4E:  ldy     #$00
L0D50:  iny
        lda     ($08),y
        cmp     ($06),y
        beq     L0D5B
        bcc     L0D69
L0D59:  sec
        rts

        L0D5C := *+1
L0D5B:  cpy     #0
        bne     L0D50
        lda     L0D6B
        cmp     L0D6C
        beq     L0D69
        bcs     L0D59
L0D69:  clc
        rts

L0D6B:  .byte   0
L0D6C:  .byte   0
