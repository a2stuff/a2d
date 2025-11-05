;;; ============================================================

;;; Populate `str_time` with time. Uses `clock_24hours` flag in settings.
;;; Inputs: A,X = ParsedDateTime
;;; Outputs: `str_time` is populated
.proc MakeTimeString
        parsed_ptr := $06

        stax    parsed_ptr

        ;; Cache settings
        CALL    ReadSetting, X=#DeskTopSettings::clock_24hours
        sta     clock_24hours
        CALL    ReadSetting, X=#DeskTopSettings::intl_time_sep
        sta     intl_time_sep

        ldy     #ParsedDateTime::hour
        lda     (parsed_ptr),y
        sta     hour
        ldy     #ParsedDateTime::minute
        lda     (parsed_ptr),y
        sta     min

        ldy     #0              ; Index into time string

        ;; Hours
        lda     hour

        ;; 24->12 hour clock?
        bit     clock_24hours
    IF NC
      IF A >= #12
        sec
        sbc     #12             ; 12...23 -> 0...11
      END_IF

      IF A = #0
        lda     #12             ; 0 -> 12
      END_IF
    END_IF

        jsr     _Split
        pha
        txa                     ; tens (if > 0)
        bit     clock_24hours
    IF NC
        cmp     #0              ; if 12-hour clock && 0, skip
        beq     ones
    END_IF
        ora     #'0'
        iny
        sta     str_time,y
ones:   pla                     ; ones
        ora     #'0'
        iny
        sta     str_time,y

        ;; Separator
        intl_time_sep := *+1
        lda     #SELF_MODIFIED_BYTE
        iny
        sta     str_time,y

        ;; Minutes
        CALL    _Split, A=min
        pha
        txa                     ; tens
        ora     #'0'
        iny
        sta     str_time,y
        pla                     ; ones
        ora     #'0'
        iny
        sta     str_time,y

        bit     clock_24hours
        bmi     done

        ;; Space
        lda     #' '
        iny
        sta     str_time,y

        lda     hour
        cmp     #12
        bcs     :+
        lda     #'A'
        SKIP_NEXT_2_BYTE_INSTRUCTION
:       lda     #'P'
        iny
        sta     str_time,y
        lda     #'M'
        iny
        sta     str_time,y

done:   sty     str_time
        rts

hour:   .byte   0
min:    .byte   0
clock_24hours:
        .byte   0

;;; Input: A = number
;;; Output: X = tens, A = ones
.proc _Split
        ldx     #0
    DO
        BREAK_IF A < #10
        sec
        sbc     #10
        inx
    WHILE NOT_ZERO              ; always
        rts
.endproc ; _Split

.endproc ; MakeTimeString

;;; ============================================================

;;; Day of the Week calculation (valid 1900-03-01 to 2155-12-31)
;;; c/o http://6502.org/source/misc/dow.htm
;;; Inputs: Y = year (0=1900), X = month (1=Jan), A = day (1...31)
;;; Output: A = weekday (0=Sunday)
.proc DayOfWeek
        tmp := $06

        cpx     #3              ; Year starts in March to bypass
        bcs     :+              ; leap year problem
        dey                     ; If Jan or Feb, decrement year
:       eor     #$7F            ; Invert A so carry works right
        cpy     #200            ; Carry will be 1 if 22nd century
        adc     month_offset_table-1,X ; A is now day+month offset
        sta     tmp
        tya                     ; Get the year
        jsr     mod7            ; Do a modulo to prevent overflow
        sbc     tmp             ; Combine with day+month
        sta     tmp
        tya                     ; Get the year again
        lsr                     ; Divide it by 4
        lsr
        clc                     ; Add it to y+m+d and fall through
        adc     tmp

mod7:   adc     #7              ; Returns (A+3) modulo 7
        bcc     mod7            ; for A in 0..255
        rts

month_offset_table:
        .byte   1,5,6,3,1,5,3,0,4,2,6,4
        ASSERT_TABLE_SIZE month_offset_table, 12
.endproc ; DayOfWeek

;;; ============================================================
;;; Parse date/time
;;; Input: A,X = addr of datetime to parse
;;; $0A points at ParsedDateTime to be filled

.proc ParseDatetime
        parsed_ptr := $0A
        datetime_ptr := $0C

        stax    datetime_ptr

        ;; Null date? Leave as all zeros.
        ldy     #0
        lda     (datetime_ptr),y
        iny
        ora     (datetime_ptr),y ; null date?
        bne     not_null

        ldy     #.sizeof(ParsedDateTime)-1
    DO
        sta     (parsed_ptr),y
        dey
    WHILE POS
        rts

not_null:

.ifdef PRODOS_2_5
        ;; Is it a ProDOS 2.5 extended date/time? (see below)
        ldy     #3
        lda     (datetime_ptr),y
        and     #%11100000      ; Top 3 bits would be 0...
        bne     prodos_2_5      ; unless ProDOS 2.5a4+
.endif ; PRODOS_2_5

        ;; --------------------------------------------------
        ;; ProDOS 8 DateTime:
        ;;       byte 1            byte 0
        ;;  7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;; |    Year     |  Month  |   Day   |
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;;
        ;;       byte 3            byte 2
        ;;  7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;; |0 0 0|  Hour   | |0 0|  Minute   |
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;;

        ;; ----------------------------------------
        ;; Year
        ;; (top 7 bits of datehi, top 3 bits of timehi)
year:   lda     #0
        sta     ytmp+1

        ldy     #DateTime::datehi
        lda     (datetime_ptr),y ; First, calculate year-1900
        lsr     a
        php                     ; Save Carry bit
        sta     ytmp

        ;; 0-39 is 2000-2039
        ;; Per Technical Note: ProDOS #28: ProDOS Dates -- 2000 and Beyond
        ;; https://web.archive.org/web/2007/http://web.pdx.edu/~heiss/technotes/pdos/tn.pdos.28.html
tn28:   lda     ytmp            ; ytmp is still just one byte
    IF A < #40
        adc     #100
        sta     ytmp
    END_IF

do1900: ldy     #ParsedDateTime::year
        add16in ytmp, #1900, (parsed_ptr),y

        ;; ----------------------------------------
        ;; Month
        ;; (mix low bit from datehi with top 3 bits from datelo)
        plp                     ; Restore Carry bit
        ldy     #DateTime::datelo
        lda     (datetime_ptr),y
        ror     a
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ldy     #ParsedDateTime::month
        sta     (parsed_ptr),y

        ;; ----------------------------------------
        ;; Day
        ;; (low 5 bits of datelo)
        ldy     #DateTime::datelo
        lda     (datetime_ptr),y
        and     #%00011111
        ldy     #ParsedDateTime::day
        sta     (parsed_ptr),y

        ;; ----------------------------------------
        ;; Hour
        ldy     #DateTime::timehi
        lda     (datetime_ptr),y
        and     #%00011111
        ldy     #ParsedDateTime::hour
        sta     (parsed_ptr),y

        ;; ----------------------------------------
        ;; Minute
        ldy     #DateTime::timelo
        lda     (datetime_ptr),y
        and     #%00111111
        ldy     #ParsedDateTime::minute
        sta     (parsed_ptr),y

        rts

.ifdef PRODOS_2_5
        ;; --------------------------------------------------
        ;; ProDOS 8 2.5.0a4+ Extended DateTime:
        ;; https://prodos8.com/releases/prodos-25/
        ;;
        ;;       byte 1            byte 0
        ;;  7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;; | Day     | Hour      | Minute    |
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;;
        ;;       byte 3            byte 2
        ;;  7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;; | Month | Year                    |
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
prodos_2_5:
        ;; ----------------------------------------
        ;; day: 1-31
        ldy     #1
        lda     (datetime_ptr),y
        lsr
        lsr
        lsr
        ldy     #ParsedDateTime::day
        sta     (parsed_ptr),y

        ;; ----------------------------------------
        ;; month: 2-13
        ldy     #3
        lda     (datetime_ptr),y
        lsr
        lsr
        lsr
        lsr
        sec
        sbc     #1              ; make it 1-12
        ldy     #ParsedDateTime::month
        sta     (parsed_ptr),y

        ;; ----------------------------------------
        ;; year: 0-4095
        ldy     #2
        lda     (datetime_ptr),y
        ldy     #ParsedDateTime::year
        sta     (parsed_ptr),y

        ldy     #3
        lda     (datetime_ptr),y
        and     #%00001111
        ldy     #ParsedDateTime::year+1
        sta     (parsed_ptr),y

        ;; ----------------------------------------
        ;; hour: 0-23
        ldy     #0
        copy16in (datetime_ptr),y, ytmp
        ldx     #6
    DO
        lsr16   ytmp
        dex
    WHILE NOT_ZERO

        lda     ytmp
        and     #%00011111      ; should be unnecessary
        ldy     #ParsedDateTime::hour
        sta     (parsed_ptr),y

        ;; ----------------------------------------
        ;; minute: 0-59
        ldy     #0
        lda     (datetime_ptr),y
        and     #%00111111
        ldy     #ParsedDateTime::minute
        sta     (parsed_ptr),y

        rts
.endif ; PRODOS_2_5

ytmp:   .word   0

.endproc ; ParseDatetime
