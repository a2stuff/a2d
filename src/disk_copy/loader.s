;;; ============================================================
;;; Disk Copy - $1800 - $19FF
;;;
;;; Compiled as part of disk_copy.s
;;; ============================================================


        BEGINSEG Loader
.scope part2
        MLIEntry := MLI

        jmp     start

;;; ============================================================

io_buf := $1C00
load_buf := $4000

        DEFINE_OPEN_PARAMS open_params, filename, io_buf
filename:   PASCAL_STRING kPathnameDiskCopy

        DEFINE_READWRITE_PARAMS read_params, 0, 0
        DEFINE_SET_MARK_PARAMS set_mark_params, 0
        DEFINE_CLOSE_PARAMS close_params

        .byte   $00,$00

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

        MLI_CALL OPEN, open_params
        jcs     fail
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     set_mark_params::ref_num

        copy16  #kSegmentAuxLCOffset, set_mark_params::position
        MLI_CALL SET_MARK, set_mark_params
        jcs     fail
        copy16  #load_buf, read_params::data_buffer ; loads to temp address
        copy16  #kSegmentAuxLCLength, read_params::request_count
        MLI_CALL READ, read_params
        bcs     fail
        jsr     CopyToLC

        copy16  #kSegmentMainOffset, set_mark_params::position
        MLI_CALL SET_MARK, set_mark_params

        copy16  #kSegmentMainAddress, read_params::data_buffer
        copy16  #kSegmentMainLength, read_params::request_count
        MLI_CALL READ, read_params
        bcs     fail
        MLI_CALL CLOSE, close_params
        bcs     fail

        ;; Writes to `main::saved_ram_unitnum` etc. so must be after
        ;; the segments are loaded.
        jsr     DisconnectRAM

        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        jmp     auxlc::start

;;; This mimics the original behavior - just hang if the load fails.
;;; Note that a ProDOS QUIT will likely fail since the installed
;;; routine will try to reload DeskTop.
fail:   jmp     fail

;;; ============================================================
;;; Copy first chunk to the Language Card

.proc CopyToLC
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
        copy16  #load_buf, src
        add16   src, #kSegmentAuxLCLength, end
        copy16  #kSegmentAuxLCAddress, dst

        ;; Do the copy
        ldy     #0
    DO
        lda     (src),y
        sta     (dst),y
        inc     src
        inc     dst
        lda     src
      IF ZERO
        inc     src+1
        inc     dst+1
      END_IF
        ecmp16  src, end
    WHILE NE

        ;; Bank in ROM
        sta     ALTZPOFF
        bit     ROMIN2
        rts
.endproc ; CopyToLC

;;; ============================================================

        saved_ram_unitnum := main::saved_ram_unitnum
        saved_ram_drvec   := main::saved_ram_drvec
        saved_ram_buffer: .res 16
        .include "../lib/disconnect_ram.s"

;;; ============================================================

.endscope ; part2
        ENDSEG Loader
