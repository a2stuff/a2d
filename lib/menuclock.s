;;; Render current time to right side of menu bar
;;;
;;; Requires:
;;;    `SETTINGS` defined
;;;    `LIB_MLI_CALL` defined
;;;    `LIB_MGTK_CALL` defined
;;;    lib/datetime.s for parsing functions
;;;    lib/drawstring.s for string drawing
;;;    `dow_strings` table
;;;    `str_time` to populate
;;;    `str_4_spaces`

.proc ShowClockImpl
;;; Entry point: force an update, even if time hasn't changed
force_update:
        copy    #$80, force_flag
        bne     common          ; always

;;; Entry point: only update if time has changed
normal: copy    #0, force_flag

common: lda     MACHID
        and     #1              ; bit 0 = clock card
        bne     :+
        rts

:       LIB_MLI_CALL GET_TIME, 0

        bit     force_flag      ; forced update
        bmi     update

        ;; Changed?
        ldx     #.sizeof(DateTime)-1
:       lda     DATELO,x
        cmp     last_dt,x
        bne     update
        dex
        bpl     :-
        lda     SETTINGS + DeskTopSettings::clock_24hours
        cmp     last_s
        bne     update
        rts

update: COPY_STRUCT DateTime, DATELO, last_dt
        copy    SETTINGS + DeskTopSettings::clock_24hours, last_s

        ;; --------------------------------------------------
        ;; Save the current GrafPort and use a custom one for drawing

        LIB_MGTK_CALL MGTK::GetPort, getport_params
        LIB_MGTK_CALL MGTK::InitPort, clock_grafport
        LIB_MGTK_CALL MGTK::SetPort, clock_grafport

        LIB_MGTK_CALL MGTK::MoveTo, pos_clock

        ;; --------------------------------------------------
        ;; Day of Week

        copy16  #parsed_date, $0A
        ldax    #DATELO
        jsr     ParseDatetime

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
        sta     dow_str_params::addr
        lda     #0
        adc     #>dow_strings
        sta     dow_str_params::addr+1
        LIB_MGTK_CALL MGTK::DrawText, dow_str_params

        ;; --------------------------------------------------
        ;; Time

        ldax    #parsed_date
        jsr     MakeTimeString

        param_call DrawString, str_time
        param_call DrawString, str_4_spaces ; in case it got shorter

        ;; --------------------------------------------------
        ;; Restore the previous GrafPort

        copy16  getport_params::portptr, @addr
        LIB_MGTK_CALL MGTK::SetPort, 0, @addr
        rts

last_dt:
        .tag    DateTime        ; previous date/time
last_s: .byte   0               ; previous settings

force_flag:
        .byte   0               ; force update if high bit set
.endproc
ShowClock := ShowClockImpl::normal
ShowClockForceUpdate := ShowClockImpl::force_update
