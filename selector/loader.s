;;; ============================================================
;;; Loader
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        .org kSegmentLoaderAddress

;;; Loads the Invoker (page 2/3), Selector App (at $4000...$A1FF),
;;; and Resources (Aux LC), then invokes the app.

.proc InstallSegments
        jmp     start

        alert_load_addr := $3400
        alert_final_addr := kSegmentAlertAddress

        ;; ProDOS parameter blocks

        io_buf := $3000

        DEFINE_OPEN_PARAMS open_params, str_selector, io_buf
        DEFINE_READ_PARAMS read_params1, INVOKER, kSegmentInvokerLength
        DEFINE_READ_PARAMS read_params2, kSegmentAppAddress, kSegmentAppLength
        DEFINE_READ_PARAMS read_params3, alert_load_addr, kSegmentAlertLength

        DEFINE_SET_MARK_PARAMS set_mark_params, kSegmentInvokerOffset
        DEFINE_CLOSE_PARAMS close_params

str_selector:
        PASCAL_STRING kFilenameSelector

;;; ============================================================

start:
        ;; Initialize system bitmap
        ldx     #BITMAP_SIZE-1
        lda     #0
:       sta     BITMAP,x
        dex
        bpl     :-
        lda     #%00000001      ; ProDOS global page
        sta     BITMAP+BITMAP_SIZE-1
        lda     #%11001111      ; ZP, Stack, Text Page 1
        sta     BITMAP

        jsr     DetectMousetext
        jsr     InitProgress

        ;; Open up Selector itself
        MLI_CALL OPEN, open_params
        beq     L2049
        brk

L2049:  lda     open_params::ref_num
        sta     set_mark_params::ref_num
        sta     read_params1::ref_num
        sta     read_params2::ref_num
        sta     read_params3::ref_num

        kNumSegments = 3

        ;; Read various segments into final or temp locations
        MLI_CALL SET_MARK, set_mark_params
        beq     :+
        brk
:       jsr     UpdateProgress
        MLI_CALL READ, read_params1
        beq     :+
        brk
:       jsr     UpdateProgress
        MLI_CALL READ, read_params2
        beq     :+
        brk
:       jsr     UpdateProgress
        MLI_CALL READ, read_params3
        beq     :+
        brk
:       jsr     UpdateProgress

        ;; Copy Alert segment to Aux LC1
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        ;; Set stack pointers to arbitrarily low values for use when
        ;; interrupts occur. DeskTop does not utilize this convention,
        ;; so the values are set low so that interrupts which do (for
        ;; example, the IIgs Control Panel) don't trash DeskTop's use
        ;; of the stacks.
        ;; See the Apple IIe Technical Reference Manual, pp. 153-154
        lda     #$80
        sta     $0100           ; Main stack pointer, in Aux ZP
        sta     $0101           ; Aux stack pointer, in Aux ZP

        ldx     #0
:       .repeat 8, i
        lda     alert_load_addr + ($100 * i),x
        sta     alert_final_addr + ($100 * i),x
        .endrepeat
        inx
        bne     :-

        sta     ALTZPOFF
        bit     ROMIN2

        MLI_CALL CLOSE, close_params

        jsr     LoadSettings

        ;; --------------------------------------------------
        ;; Invoke the Selector application
        jmp     START

;;; ============================================================

        SETTINGS_IO_BUF := io_buf
        SETTINGS_LOAD_BUF := SAVE_AREA_BUFFER
        .include "../lib/load_settings.s"

;;; ============================================================

        kProgressStops = kNumSegments + 1
        .include "../lib/loader_progress.s"

;;; ============================================================

.endproc ; InstallSegments

        PAD_TO kSegmentLoaderAddress + kSegmentLoaderLength
