;;; Render current time to right side of menu bar
;;;
;;; `ShowClockForceUpdate`: force an update, even if time hasn't changed
;;; `ShowClock`: only update if time has changed
;;;
;;; Requires:
;;;    `ReadSetting` defined
;;;    `MGTK_CALL` defined
;;;    lib/datetime.s for parsing functions
;;;    `dow_strings` table
;;;    `str_time` to populate
;;;    `str_4_spaces`

.scope menuclock_impl
        ENTRY_POINTS_FOR_BIT7_FLAG force_update, normal, force_flag

        lda     MACHID
        and     #kMachIDHasClock
        RTS_IF ZERO

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
    WHILE POS

        ;; Settings changed?
        CALL    ReadSetting, X=#DeskTopSettings::clock_24hours
        cmp     last_s1
        bne     update
        CALL    ReadSetting, X=#DeskTopSettings::intl_time_sep
        cmp     last_s2
        bne     update
        rts

update: COPY_STRUCT DateTime, DATELO, last_dt
        CALL    ReadSetting, X=#DeskTopSettings::clock_24hours
        sta     last_s1
        CALL    ReadSetting, X=#DeskTopSettings::intl_time_sep
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
        CALL    ParseDatetime, AX=#DATELO

        CALL    MakeTimeString, AX=#parsed_date

        CALL    DrawStringRight, AX=#str_time
        CALL    DrawStringRight, AX=#str_space

        ;; --------------------------------------------------
        ;; Day of Week

        ;; TODO: Make DOW calc work on ParsedDateTime
        sub16   parsed_date + ParsedDateTime::year, #1900, parsed_date + ParsedDateTime::year
        CALL    DayOfWeek, Y=parsed_date + ParsedDateTime::year, X=parsed_date + ParsedDateTime::month, A=parsed_date + ParsedDateTime::day
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

        CALL    DrawStringRight, AX=#str_4_spaces

        ;; --------------------------------------------------
        ;; Restore the previous GrafPort

        copy16  getport_params::portptr, @addr
        MGTK_CALL MGTK::SetPort, 0, @addr
        rts

;;; Draw string right-aligned to current coords, updating the
;;; current coords to be on the left side of the string.
.proc DrawStringRight
        params := $06
        str := params
        width := params+2

        stax    str
        stax    @addr
        MGTK_CALL MGTK::StringWidth, params
        sub16   #0, width, params+MGTK::Point::xcoord
        copy16  #0, params+MGTK::Point::ycoord
        MGTK_CALL MGTK::Move, params
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        MGTK_CALL MGTK::Move, params
        rts
.endproc ; DrawStringRight

last_dt:
        .tag    DateTime        ; previous date/time
last_s1:.byte   0               ; previous settings
last_s2:.byte   0               ; previous settings

force_flag:
        .byte   0               ; bit7 = force update
.endscope ; menuclock_impl

;;; Exports
ShowClock               := menuclock_impl::normal
ShowClockForceUpdate    := menuclock_impl::force_update
