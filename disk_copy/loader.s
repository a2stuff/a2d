;;; ============================================================
;;; Disk Copy - $1800 - $19FF
;;;
;;; Compiled as part of disk_copy.s
;;; ============================================================


.scope part2
        .org $1800

        MLIEntry := MLI

        jmp     start

;;; ============================================================

io_buf := $1C00
load_buf := $4000

        DEFINE_OPEN_PARAMS open_params, filename, io_buf
filename:   PASCAL_STRING kFilenameDiskCopy

        DEFINE_READ_PARAMS read_params, 0, 0
        DEFINE_SET_MARK_PARAMS set_mark_params, kSegmentAuxLCOffset
        DEFINE_CLOSE_PARAMS close_params

        .byte   $00,$00

buf1:   .addr   load_buf
dest1:  .addr   kSegmentAuxLCAddress
len1:   .word   kSegmentAuxLCLength

buf2:   .addr   kSegmentMainAddress
len2:   .word   kSegmentMainLength

;;; ============================================================

start:
        ;; Set stack pointers to arbitrarily low values for use when
        ;; interrupts occur. DeskTop does not utilize this convention,
        ;; so the values are set low so that interrupts which do (for
        ;; example, the IIgs Control Panel) don't trash DeskTop's use
        ;; of the stacks.
        ;; See the Apple IIe Technical Reference Manual, pp. 153-154
        lda     #$41
        sta     ALTZPON
        sta     $0100           ; Main stack pointer, in Aux ZP
        sta     $0101           ; Aux stack pointer, in Aux ZP
        sta     ALTZPOFF

        ;; Free up system bitmap
        ldx     #BITMAP_SIZE-3
        lda     #0
L183F:  sta     BITMAP+1,x
        dex
        bpl     L183F

        MLI_CALL OPEN, open_params
        bcs     fail
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     set_mark_params::ref_num

        MLI_CALL SET_MARK, set_mark_params
        bcs     fail
        copy16  buf1, read_params::data_buffer
        copy16  len1, read_params::request_count
        MLI_CALL READ, read_params
        bcs     fail
        jsr     CopyToLc

        copy16  buf2, read_params::data_buffer
        copy16  len2, read_params::request_count
        MLI_CALL READ, read_params
        bcs     fail
        MLI_CALL CLOSE, close_params
        bcs     fail

        jsr     LoadSettings

        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        jmp     auxlc__start

;;; This mimics the original behavior - just hang if the load fails.
;;; Note that a ProDOS QUIT will likely fail since the installed
;;; routine will try to reload DeskTop.
fail:   jmp     fail

;;; ============================================================
;;; Copy first chunk to the Language Card

.proc CopyToLc
        src := $6
        end := $8
        dst := $A

        ;; Bank in AUX LC
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

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
        bit     ROMIN2
        rts
.endproc

;;; ============================================================

        SETTINGS_IO_BUF := io_buf
        SETTINGS_LOAD_BUF := load_buf
        .include "../lib/load_settings.s"

;;; ============================================================

        PAD_TO $1A00

.endscope ; part2
