;;; ============================================================
;;; Procs to set monochrome and color DHR mode
;;;
;;; API:
;;; * `SetColorMode` - set DHR color mode
;;; * `SetMonoMode` - set DHR monochrome mode
;;; * `SetRGBMode` - set preferred mode per settings
;;; * `ResetIIgsRGB` - set preferred mode, but only on IIgs
;;;  (use as periodic task to reset mode after Control Panel)
;;;
;;; Required includes:
;;; * `lib/readwrite_settings.s`
;;;
;;; Required definitions:
;;; * `machine_config::iigs_flag` - high bit set if on IIgs
;;; * `machine_config::megaii_flag` - high bit set if Mega II system
;;; * `machine_config::lcm_eve_flag` - high bit set if LCM EVE present
;;; ============================================================

.proc SetRGBMode
        ldx     #DeskTopSettings::rgb_color
        jsr     ReadSetting
        bpl     SetMonoMode
        FALL_THROUGH_TO SetColorMode
.endproc ; SetRGBMode

.proc SetColorMode
        bit     machine_config::iigs_flag
        bmi     iigs

        bit     machine_config::megaii_flag
        bmi     megaii

        bit     machine_config::lcm_eve_flag
        bmi     lcmeve

        ;; AppleColor Card - Mode 2 (Color 140x192)
        ;; Also: Video-7 and Le Chat Mauve Feline
        sta     SET80VID        ; set register to 1
        sta     AN3_OFF
        sta     AN3_ON          ; shift in 1 as first bit
        sta     AN3_OFF
        sta     AN3_ON          ; shift in 1 as second bit
        sta     DHIRESON        ; re-enable DHR
        rts

        ;; Le Chat Mauve Eve - COL140 mode
        ;; (AN3 off, HR1 off, HR2 off, HR3 off)
lcmeve: sta     AN3_OFF
        sta     HR1_OFF
        sta     HR2_OFF
        sta     HR3_OFF
        rts

        ;; Apple IIgs - DHR Color (Composite)
iigs:   lda     #$00            ; Color
        sta     MONOCOLOR
        FALL_THROUGH_TO megaii

        ;; Mega II - DHR Color (RGB)
megaii: lda     NEWVIDEO
        and     #<~(1<<5)       ; Color
        sta     NEWVIDEO
        rts
.endproc ; SetColorMode

.proc SetMonoMode
        bit     machine_config::iigs_flag
        bmi     iigs

        bit     machine_config::megaii_flag
        bmi     megaii

        bit     machine_config::lcm_eve_flag
        bmi     lcmeve

        ;; AppleColor Card - Mode 1 (Monochrome 560x192)
        ;; Also: Video-7 and Le Chat Mauve Feline
        sta     CLR80VID        ; set register to 0
        sta     AN3_OFF
        sta     AN3_ON          ; shift in 0 as first bit
        sta     AN3_OFF
        sta     AN3_ON          ; shift in 0 as second bit
        sta     SET80VID        ; re-enable DHR
        sta     DHIRESON
        rts

        ;; Le Chat Mauve Eve - BW560 mode
        ;; (AN3 off, HR1 off, HR2 on, HR3 on)
lcmeve: sta     AN3_OFF
        sta     HR1_OFF
        sta     HR2_ON
        sta     HR3_ON
        rts

        ;; Apple IIgs - DHR B&W (Composite)
iigs:   lda     #$80            ; Mono
        sta     MONOCOLOR
        FALL_THROUGH_TO megaii

        ;; Mega II - DHR B&W (RGB)
megaii: lda     NEWVIDEO
        ora     #(1<<5)         ; B&W
        sta     NEWVIDEO
done:   rts
.endproc ; SetMonoMode

;;; On IIgs, force preferred RGB mode. No-op otherwise.
.proc ResetIIgsRGB
        bit     machine_config::iigs_flag
        bpl     SetMonoMode::done ; nope

        ldx     #DeskTopSettings::rgb_color
        jsr     ReadSetting
        bmi     SetColorMode::iigs
        bpl     SetMonoMode::iigs ; always
.endproc ; ResetIIgsRGB
