        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

;;; ==================================================
;;; Overlay for Disk Copy #2
;;; ==================================================

        .org $1800
.proc disk_copy_overlay2

        jmp     start

L1A39           := $1A39
L1A3B           := $1A3B
LA798           := $A798
LA839           := $A839
LA83D           := $A83D
LA8E8           := $A8E8
LA960           := $A960
LAA00           := $AA00
LAA1B           := $AA1B
LAA3A           := $AA3A
LAB37           := $AB37

;;; ==================================================

        DEFINE_OPEN_PARAMS open_params, filename, $1C00
filename:   PASCAL_STRING "DeskTop2"

        DEFINE_READ_PARAMS read_params, 0, 0
        DEFINE_SET_MARK_PARAMS set_mark_params, $133E0
        DEFINE_CLOSE_PARAMS close_params

        .byte   $00,$00

buf1:   .addr   $4000
dest1:  .addr   $D000
len1:   .word   $2200

buf2:   .addr   $800
len2:   .word   $B00

;;; ==================================================

start:  lda     #$41            ; ???
        sta     RAMWRTON
        sta     $0100
        sta     $0101
        sta     RAMWRTOFF

        ;; Free up system bitmap
        ldx     #BITMAP_SIZE-3
        lda     #0
L183F:  sta     BITMAP+1,x
        dex
        bpl     L183F

        yax_call MLI_RELAY, OPEN, open_params
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     set_mark_params::ref_num

        yax_call MLI_RELAY, SET_MARK, set_mark_params
        copy16  buf1, read_params::data_buffer
        copy16  len1, read_params::request_count
        yax_call MLI_RELAY, READ, read_params
        jsr     copy_to_lc

        copy16  buf2, read_params::data_buffer
        copy16  len2, read_params::request_count
        yax_call MLI_RELAY, READ, read_params
        yax_call MLI_RELAY, CLOSE, close_params
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        jmp     MGTK_RELAY

;;; ==================================================
;;; Copy first chunk to the Language Card

.proc copy_to_lc
        src := $6
        end := $8
        dst := $A

        ;; Bank in AUX LC
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        txa
        asl     a
        tax

        ;; Set up pointers
        lda     buf1
        sta     src
        clc
        adc     len1
        sta     end
        lda     buf1+1
        sta     src+1
        adc     len1+1
        sta     end+1
        lda     dest1
        sta     dst
        lda     dest1+1
        sta     dst+1

        ;; Do the copy
        ldy     #0
loop:   lda     (src),y
        sta     (dst),y
        inc     src
        inc     dst
        lda     src
        bne     :+
        inc     src+1
        inc     dst+1
:       lda     src+1
        cmp     end+1
        bne     loop
        lda     src
        cmp     end
        bne     loop

        ;; Bank in ROM
        sta     ALTZPOFF
        lda     ROMIN2
        rts
.endproc

;;; ==================================================

.proc MLI_RELAY
        sty     call
        stax    params
        php
        sei
        jsr     MLI
call:   .byte   0
params: .addr   0
        plp
        and     #$FF
self:   bne     self            ; hang if fails
        rts
.endproc

;;; ==================================================

        tax
        bne     L192C
        bcc     L1998
        lda     $BE54
        lsr     a
        bcs     L1962
L192C:  jmp     LA839

        lda     $BE53
        cmp     #$06
        bne     L192C
        jmp     LA798

        jsr     LAA1B
        beq     L192C
        cmp     #$41
        beq     L198C
        jsr     LAB37
        sty     $BCAD
        ldy     #$13
        sty     $BCAE
        ldy     #$40
        sty     $BE56
        jsr     LA960
        bcs     L1961
        lda     $BE6B
        cmp     #$08
        bcc     L1991
L195E:  lda     #$02
        sec
L1961:  rts

L1962:  lsr     a
        bcc     L1987
        jsr     LAA3A
        beq     L192C
        dex
        lda     #$82
        sta     $BCA9
        ldy     #$01
        jsr     LAA00
        dey
        dey
        sty     $0280
        lda     #$03
        sta     $BE56
        dex
        jsr     LAA3A
        bne     L192C
        bcc     L1998
L1987:  jsr     LAA3A
        beq     L192C
L198C:  jsr     LA8E8
        bcs     L1961
L1991:  jsr     LAA3A
        bne     L192C
        bcs     L1987
L1998:  lda     $BE61
        beq     L195E
        cmp     #$08
        bcs     L195E
        lda     $BE62
        beq     L195E
        cmp     #$03
        bcs     L195E
        lda     $BE54
        and     #$21
        lsr     a
        beq     L19BB
        lda     $BE42
        bne     L19BB
        lda     #$0F
        sec
        rts

L19BB:  bcc     L19FD
        lda     $BE55
        and     #$04
        beq     L19FD
        lda     $BE56
        lsr     a
        bcs     L19D3
        lda     $BE54
        and     #$90
        beq     L1A39
        bpl     L19FD
L19D3:  lda     $BCBD
        eor     #$2F
        beq     L19DF
        lda     $BF9A
        beq     L19F8
L19DF:  lda     $BE57
        and     #$04
        beq     L19FD
        bcs     L19F8
        lda     #$00
        sta     $BCBC
        sta     $BCBD
        lda     #$01
        ora     $BE56
        sta     $BE56
L19F8:  jsr     LA83D
        bcs     L1A3B
L19FD:  lda     $BE53

;;; ==================================================

        PAD_TO $1A00
.endproc ; disk_copy_overlay2