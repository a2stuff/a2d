;;; ============================================================
;;; Overlay for Disk Copy - $1800 - $19FF (file 2/4)
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

.proc part2
        .org $1800

        jmp     start

;;; ============================================================

        DEFINE_OPEN_PARAMS open_params, filename, $1C00
filename:   PASCAL_STRING "DeskTop2" ; do not localize

        DEFINE_READ_PARAMS read_params, 0, 0
        DEFINE_SET_MARK_PARAMS set_mark_params, kOverlayDiskCopy3Offset
        DEFINE_CLOSE_PARAMS close_params

        .byte   $00,$00

buf1:   .addr   $4000
dest1:  .addr   kOverlayDiskCopy3Address
len1:   .word   kOverlayDiskCopy3Length

buf2:   .addr   kOverlayDiskCopy4Address
len2:   .word   kOverlayDiskCopy4Length

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

        MLI_RELAY_CALL OPEN, open_params
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     set_mark_params::ref_num

        MLI_RELAY_CALL SET_MARK, set_mark_params
        copy16  buf1, read_params::data_buffer
        copy16  len1, read_params::request_count
        MLI_RELAY_CALL READ, read_params
        jsr     copy_to_lc

        copy16  buf2, read_params::data_buffer
        copy16  len2, read_params::request_count
        MLI_RELAY_CALL READ, read_params
        MLI_RELAY_CALL CLOSE, close_params
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        jmp     auxlc__start

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
        jsr     MLI
call:   .byte   0
params: .addr   0
self:   bne     self            ; hang if fails
        rts
.endproc

;;; ============================================================

        PAD_TO $1A00

.endproc ; part2