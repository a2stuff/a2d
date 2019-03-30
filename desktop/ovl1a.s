;;; ============================================================
;;; Overlay for Disk Copy - $1800 - $19FF (file 2/4)
;;; ============================================================

.proc disk_copy_overlay2
        .org $1800

        jmp     start

;;; ============================================================

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

;;; ============================================================

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

        jmp     disk_copy_overlay3_start

;;; ============================================================
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

;;; ============================================================

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

;;; ============================================================

;;; Padded with a chunk of BASIC.SYSTEM 1.1
;;; (Loaded at: $A721 - $A7FF; file offset $1120)

        .incbin "inc/bs.dat"

;;; ============================================================

        PAD_TO $1A00

.endproc ; disk_copy_overlay2