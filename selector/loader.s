;;; ============================================================
;;; Loader
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        .org $2000

;;; Loads the Invoker (page 2/3), Selector App (at $4000...$A1FF),
;;; and Resources (Aux LC), then invokes the app.

.scope

        jmp     start

        alert_load_addr := $3400
        alert_final_addr := $D000

        ;; ProDOS parameter blocks

        io_buf := $3000

        DEFINE_OPEN_PARAMS open_params, str_selector, io_buf
        DEFINE_READ_PARAMS read_params1, INVOKER, kInvokerSegmentSize
        DEFINE_READ_PARAMS read_params2, MGTK, kAppSegmentSize
        DEFINE_READ_PARAMS read_params3, alert_load_addr, kAlertSegmentSize

        DEFINE_SET_MARK_PARAMS set_mark_params, kInvokerOffset
        DEFINE_CLOSE_PARAMS close_params

str_selector:
        PASCAL_STRING kFilenameSelector

;;; ============================================================

start:
        ;; Clear ProDOS memory bitmap
        lda     #0
        ldx     #$17
:       sta     BITMAP+1,x
        dex
        bpl     :-

        jsr     detect_mousetext
        jsr     init_progress

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
:       jsr     update_progress
        MLI_CALL READ, read_params1
        beq     :+
        brk
:       jsr     update_progress
        MLI_CALL READ, read_params2
        beq     :+
        brk
:       jsr     update_progress
        MLI_CALL READ, read_params3
        beq     :+
        brk
:       jsr     update_progress

        ;; Copy Alert segment to Aux LC1
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

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
        lda     ROMIN2

        MLI_CALL CLOSE, close_params

        jsr     load_settings

        ;; --------------------------------------------------
        ;; Invoke the Selector application
        jmp     START

;;; ============================================================

        .include "../lib/load_settings.s"
        DEFINEPROC_LOAD_SETTINGS io_buf, SAVE_AREA_BUFFER

;;; ============================================================

        kProgressVtab = 14
        kProgressStops = kNumSegments + 1
        kProgressTick = 40 / kProgressStops
        kProgressHtab = (80 - (kProgressTick * kProgressStops)) / 2
        kProgressWidth = kProgressStops * kProgressTick

.proc init_progress
        bit     supports_mousetext
        bpl     done

        lda     #kProgressVtab
        jsr     VTABZ
        lda     #kProgressHtab
        sta     CH

        ;; Enable MouseText
        lda     #$0F|$80
        jsr     COUT
        lda     #$1B|$80
        jsr     COUT

        ;; Draw progress track (alternating checkerboards)
        ldx     #kProgressWidth
:       lda     #'V'|$80
        jsr     COUT
        dex
        beq     :+
        lda     #'W'|$80
        jsr     COUT
        dex
        bne     :-

        ;; Disable MouseText
:       lda     #$18|$80
        jsr     COUT
        lda     #$0E|$80
        jsr     COUT

done:   rts
.endproc

.proc update_progress
        lda     #kProgressVtab
        jsr     VTABZ
        lda     #kProgressHtab
        sta     CH

        lda     count
        clc
        adc     #kProgressTick
        sta     count

        tax
        lda     #' '
:       jsr     COUT
        dex
        bne     :-

        rts

count:  .byte   0
.endproc

;;; ============================================================
;;; Try to detect an Enhanced IIe or later (IIc, IIgs, etc),
;;; to infer suport for MouseText characters.
;;; Done by testing testing for a ROM signature.
;;; Output: Sets `supports_mousetext` to $80.

.proc detect_mousetext
        lda     ZIDBYTE
        beq     enh    ; IIc/IIc+ have $00
        cmp     #$E0   ; IIe original has $EA, Enh. IIe, IIgs have $E0
        bne     done

enh:    copy    #$80, supports_mousetext

done:   rts
.endproc

supports_mousetext:
        .byte   0

;;; ============================================================

.endscope

        PAD_TO $2200
