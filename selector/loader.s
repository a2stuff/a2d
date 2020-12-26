;;; ============================================================
;;; Loader
;;;
;;; Compiled as part of selector.s
;;; ============================================================

        .org $2000

;;; Loads the Invoker (page 2/3), Selector App (at $4000...$9FFF),
;;; and Resources (Aux LC), then invokes the app.

.scope

        jmp     start

        resources_load_addr := $3400
        resources_final_addr := $D000

        ;; ProDOS parameter blocks

        io_buf := $3000

        DEFINE_OPEN_PARAMS open_params, str_selector, io_buf
        DEFINE_READ_PARAMS read_params1, INVOKER, kInvokerSegmentSize
        DEFINE_READ_PARAMS read_params2, MGTK, kAppSegmentSize
        DEFINE_READ_PARAMS read_params3, resources_load_addr, kResourcesSegmentSize

        DEFINE_SET_MARK_PARAMS set_mark_params, $600
        DEFINE_CLOSE_PARAMS close_params

str_selector:
        PASCAL_STRING "Selector" ; do not localize

        DEFINE_OPEN_PARAMS open_config_params, str_config, io_buf
        DEFINE_READ_PARAMS read_config_params, SETTINGS, .sizeof(DeskTopSettings)

str_config:
        PASCAL_STRING "DeskTop.config" ; do not localize

;;; ============================================================

start:
        ;; Clear ProDOS memory bitmap
        lda     #0
        ldx     #$17
:       sta     BITMAP+1,x
        dex
        bpl     :-

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

        ;; Copy Resources segment to Aux LC1
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        ldx     #0
:       .repeat 8, i
        lda     resources_load_addr + ($100 * i),x
        sta     resources_final_addr + ($100 * i),x
        .endrepeat
        inx
        bne     :-

        sta     ALTZPOFF
        sta     ROMIN2

        MLI_CALL CLOSE, close_params

        ;; --------------------------------------------------
        ;; Try loading settings

        ;; Load the settings file; on failure, just skip
        MLI_CALL OPEN, open_config_params
        bcs     :+
        lda     open_config_params::ref_num
        sta     read_config_params::ref_num
        MLI_CALL READ, read_config_params
        bcs     :+

        ;; Check version bytes; ignore on mismatch
        lda     SETTINGS + DeskTopSettings::version_major
        cmp     #kDeskTopVersionMajor
        bne     :+
        lda     SETTINGS + DeskTopSettings::version_minor
        cmp     #kDeskTopVersionMinor
        bne     :+

        ;; Finish up
:       MLI_CALL CLOSE, close_params

        ;; --------------------------------------------------
        ;; Invoke the Selector application
        jmp     START


.proc update_progress

        kProgressVtab = 14
        kProgressStops = kNumSegments + 1
        kProgressTick = 40 / kProgressStops
        kProgressHtab = (80 - (kProgressTick * kProgressStops)) / 2

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

.endscope

        PAD_TO $2200
