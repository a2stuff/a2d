;;; ============================================================
;;; Loader
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        BEGINSEG SegmentLoader

;;; Loads the Invoker (page 2/3), Selector App (at $4000...$A1FF),
;;; and Resources (Aux LC), then invokes the app.

.proc InstallSegments
        jmp     start

        alert_load_addr := $3400
        alert_final_addr := kSegmentAlertAddress

        ;; ProDOS parameter blocks

        io_buf := $3000

        DEFINE_OPEN_PARAMS open_params, str_selector, io_buf
        DEFINE_READWRITE_PARAMS read_segment_invoker_params, kSegmentInvokerAddress, kSegmentInvokerLength
        DEFINE_READWRITE_PARAMS read_segment_app_params, kSegmentAppAddress, kSegmentAppLength
        DEFINE_READWRITE_PARAMS read_segment_alert_params, alert_load_addr, kSegmentAlertLength

        DEFINE_SET_MARK_PARAMS set_mark_segment_invoker_params, kSegmentInvokerOffset
        DEFINE_SET_MARK_PARAMS set_mark_segment_app_params, kSegmentAppOffset
        DEFINE_SET_MARK_PARAMS set_mark_segment_alert_params, kSegmentAlertOffset
        DEFINE_CLOSE_PARAMS close_params

str_selector:
        PASCAL_STRING kPathnameSelector

;;; ============================================================

start:
        ;; Old ProDOS leaves interrupts inhibited on start.
        ;; Do this for good measure.
        cli

        jsr     DetectMousetext
        jsr     InitProgress

        ;; Open up Selector itself
        MLI_CALL OPEN, open_params
    IF CS
        brk
    END_IF

        lda     open_params::ref_num
        sta     set_mark_segment_invoker_params::ref_num
        sta     set_mark_segment_app_params::ref_num
        sta     set_mark_segment_alert_params::ref_num
        sta     read_segment_invoker_params::ref_num
        sta     read_segment_app_params::ref_num
        sta     read_segment_alert_params::ref_num

        kNumSegments = 3

        ;; Read various segments into final or temp locations
        jsr     UpdateProgress

        MLI_CALL SET_MARK, set_mark_segment_invoker_params
        jcs     crash
        MLI_CALL READ, read_segment_invoker_params
        jcs     crash
        jsr     UpdateProgress

        MLI_CALL SET_MARK, set_mark_segment_app_params
        jcs     crash
        MLI_CALL READ, read_segment_app_params
        jcs     crash
        jsr     UpdateProgress

        MLI_CALL SET_MARK, set_mark_segment_alert_params
        jcs     crash
        MLI_CALL READ, read_segment_alert_params
        jcs     crash
        jsr     UpdateProgress

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
    DO
        .repeat (::kSegmentAlertLength / $100), i
        lda     alert_load_addr + ($100 * i),x
        sta     alert_final_addr + ($100 * i),x
        .endrepeat
    WHILE inx : NOT_ZERO

        sta     ALTZPOFF
        bit     ROMIN2

        MLI_CALL CLOSE, close_params

        ;; --------------------------------------------------
        ;; Invoke the Selector application
        jmp     ::app::entry

crash:  brk

;;; ============================================================

        kProgressStops = kNumSegments + 1
        .include "../lib/loader_progress.s"

;;; ============================================================

.endproc ; InstallSegments

        ENDSEG SegmentLoader
