;;; Render current time to right side of menu bar
;;;
;;; Requires:
;;;    `ReadSetting` defined
;;;    `MGTK_CALL` defined
;;;    lib/datetime.s for parsing functions
;;;    `dow_strings` table
;;;    `str_time` to populate
;;;    `str_4_spaces`

.scope menuclock_impl
;;; Entry point: force an update, even if time hasn't changed
force_update:
        copy8   #$80, force_flag
        bne     common          ; always

;;; Entry point: only update if time has changed
normal: copy8   #0, force_flag

common: lda     MACHID
        and     #kMachIDHasClock
        RTS_IF_ZERO

        MLI_CALL GET_TIME, 0

        bit     force_flag      ; forced update
        bmi     update

        ;; Time changed?
        ldx     #.sizeof(DateTime)-1
    DO
        lda     DATELO,x
        cmp     last_dt,x
        bne     update
        dex
    WHILE_POS

        ;; Settings changed?
        ldx     #DeskTopSettings::clock_24hours
        jsr     ReadSetting
        cmp     last_s1
        bne     update
        ldx     #DeskTopSettings::intl_time_sep
        jsr     ReadSetting
        cmp     last_s2
        bne     update
        rts

update: COPY_STRUCT DateTime, DATELO, last_dt
        ldx     #DeskTopSettings::clock_24hours
        jsr     ReadSetting
        sta     last_s1
        ldx     #DeskTopSettings::intl_time_sep
        jsr     ReadSetting
        sta     last_s2

        ;; --------------------------------------------------
        ;; Save the current GrafPort and use a custom one for drawing

        MGTK_CALL MGTK::GetPort, getport_params
        MGTK_CALL MGTK::InitPort, clock_grafport
        MGTK_CALL MGTK::SetPort, clock_grafport

        MGTK_CALL MGTK::MoveTo, pos_clock

        ;; Components are drawn right-to-left.

        ;; --------------------------------------------------
        ;; Time

        copy16  #parsed_date, $0A
        ldax    #DATELO
        jsr     ParseDatetime

        ldax    #parsed_date
        jsr     MakeTimeString

        param_call DrawStringRight, str_time
        param_call DrawStringRight, str_space

        ;; --------------------------------------------------
        ;; Day of Week

        ;; TODO: Make DOW calc work on ParsedDateTime
        sub16   parsed_date + ParsedDateTime::year, #1900, parsed_date + ParsedDateTime::year
        ldy     parsed_date + ParsedDateTime::year
        ldx     parsed_date + ParsedDateTime::month
        lda     parsed_date + ParsedDateTime::day
        jsr     DayOfWeek
        asl                     ; * 4
        asl
        clc
        adc     #<dow_strings
        tay
        lda     #0
        adc     #>dow_strings
        tax
        tya
        jsr     DrawStringRight

        ;; --------------------------------------------------
        ;; In case string got shorter

        param_call DrawStringRight, str_4_spaces

        ;; --------------------------------------------------
        ;; Restore the previous GrafPort

        copy16  getport_params::portptr, @addr
        MGTK_CALL MGTK::SetPort, 0, @addr
        rts

;;; Draw string right-aligned to current coords, updating the
;;; current coords to be on the left side of the string.
.proc DrawStringRight
        params := $6
        textptr := $6
        textlen := $8
        result := $9

        stax    textptr
        ldy     #0
        lda     (textptr),y
        sta     textlen
        inc16   textptr
        MGTK_CALL MGTK::TextWidth, params
        sub16   #0, result, result
        lda     #0
        sta     result+2
        sta     result+3
        MGTK_CALL MGTK::Move, result
        MGTK_CALL MGTK::DrawText, params
        MGTK_CALL MGTK::Move, result
        rts
.endproc ; DrawStringRight

last_dt:
        .tag    DateTime        ; previous date/time
last_s1:.byte   0               ; previous settings
last_s2:.byte   0               ; previous settings

force_flag:
        .byte   0               ; force update if high bit set
.endscope ; menuclock_impl

;;; Exports
ShowClock               := menuclock_impl::normal
ShowClockForceUpdate    := menuclock_impl::force_update
