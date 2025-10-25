;;; ============================================================
;;; DATE.AND.TIME - Desk Accessory
;;;
;;; Shows the current ProDOS date/time, and allows editing if there
;;; is no clock driver installed. Also exposes the 12/24-hour clock
;;; setting, and will update the settings file.
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "date.and.time.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../toolkits/btk.inc"
        .include "../lib/alert_dialog.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================
;;; Memory map
;;;
;;;               Main            Aux
;;;          :             : :             :
;;;          |             | |             |
;;;          | DHR         | | DHR         |
;;;  $2000   +-------------+ +-------------+
;;;          | IO Buffer   | |             |
;;;  $1C00   +-------------+ |             |
;;;          | write_buffer| |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          |             | |             |
;;;          | stub & save | | GUI code &  |
;;;          | settings    | | resource    |
;;;   $800   +-------------+ +-------------+
;;;          :             : :             :
;;;
;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

.proc RunDA
        sty     clock_flag
        jsr     init_window
        RETURN  A=dialog_result
.endproc ; RunDA

;;; ============================================================
;;; Param blocks

        kDialogWidth = 287
        kDialogHeight = 75

        ;; The following rects are iterated over to identify
        ;; a hit target for a click.

        kNumHitRects = 8
        kUpRectIndex = 1        ; 1-based
        kDownRectIndex = 2

        kControlMarginX = 16

        kFieldTop = 14
        kField1Left = 22
        kField2Left = kField1Left + 40
        kField3Left = kField2Left + 48
        kField4Left = kField3Left + 46
        kField5Left = kField4Left + 40
        kField6Left = kField5Left + 28
        kFieldDigitsWidth = 22
        kFieldMonthWidth = 30
        kFieldHeight = 10
        kFieldPaddingY = 5

        kUpDownButtonWidth = 10
        kUpDownButtonHeight = 10
        kUpDownButtonLeft = kDialogWidth - kUpDownButtonWidth - kControlMarginX

        first_hit_rect := *
        DEFINE_RECT_SZ up_arrow_rect, kUpDownButtonLeft, kFieldTop - 6, kUpDownButtonWidth, kUpDownButtonHeight
        DEFINE_RECT_SZ down_arrow_rect, kUpDownButtonLeft, kFieldTop + 6, kUpDownButtonWidth, kUpDownButtonHeight
        DEFINE_RECT_SZ day_rect, kField1Left, kFieldTop, kFieldDigitsWidth, kFieldHeight
        DEFINE_RECT_SZ month_rect, kField2Left, kFieldTop, kFieldMonthWidth, kFieldHeight
        DEFINE_RECT_SZ year_rect, kField3Left, kFieldTop, kFieldDigitsWidth, kFieldHeight
        DEFINE_RECT_SZ hour_rect, kField4Left, kFieldTop, kFieldDigitsWidth, kFieldHeight
        DEFINE_RECT_SZ minute_rect, kField5Left, kFieldTop, kFieldDigitsWidth, kFieldHeight
        DEFINE_RECT_SZ period_rect, kField6Left, kFieldTop, kFieldDigitsWidth, kFieldHeight
        ASSERT_RECORD_TABLE_SIZE first_hit_rect, kNumHitRects, .sizeof(MGTK::Rect)

        DEFINE_POINT label_uparrow_pos, kUpDownButtonLeft + 2, kFieldTop + 3
        DEFINE_POINT label_downarrow_pos, kUpDownButtonLeft + 2, kFieldTop + 15
        DEFINE_POINT day_pos, kField1Left + 6, kFieldTop + 10
        DEFINE_POINT month_pos, kField2Left + 6, kFieldTop + 10
        DEFINE_POINT year_pos, kField3Left + 6, kFieldTop + 10
        DEFINE_POINT hour_pos, kField4Left + 6, kFieldTop + 10
        DEFINE_POINT minute_pos, kField5Left + 6, kFieldTop + 10
        DEFINE_POINT period_pos, kField6Left + 6, kFieldTop + 10

        DEFINE_POINT date_sep1_pos, kField2Left - 12, kFieldTop + 10
        DEFINE_POINT date_sep2_pos, kField3Left - 12, kFieldTop + 10
        DEFINE_POINT time_sep_pos,  kField5Left -  9, kFieldTop + 10

        DEFINE_RECT_SZ date_rect, kControlMarginX, kFieldTop-kFieldPaddingY, 122, kFieldHeight+kFieldPaddingY*2
        DEFINE_RECT_SZ time_rect, 150, kFieldTop-kFieldPaddingY, 102, kFieldHeight+kFieldPaddingY*2

        kOKButtonLeft = kDialogWidth - kButtonWidth - kControlMarginX
        kOKButtonTop = kDialogHeight - kButtonHeight - 7
        DEFINE_BUTTON ok_button, kDAWindowId, res_string_button_ok, kGlyphReturn, kOKButtonLeft, kOKButtonTop

.params settextbg_black_params
backcolor:   .byte   0          ; black
.endparams

.params settextbg_white_params
backcolor:   .byte   $FF        ; white
.endparams

.enum Field
        none    = 0
        day     = 1
        month   = 2
        year    = 3
        hour    = 4
        minute  = 5
        period  = 6
.endenum

selected_field:
        .byte   Field::none

clock_flag:
        .byte   0

;;; Originally Feb 26, 1985 (the author date?); now updated by build.
day:    .byte   kBuildDD
month:  .byte   kBuildMM
year:   .byte   kBuildYY
hour:   .byte   0
minute: .byte   0

spaces_string:
        PASCAL_STRING "    "

day_string:
        PASCAL_STRING "  "

month_string:
        PASCAL_STRING "   "

year_string:
        PASCAL_STRING "  "

hour_string:
        PASCAL_STRING "  "

minute_string:
        PASCAL_STRING "  "

str_date_separator:             ; populated from settings at runtime
        PASCAL_STRING {SELF_MODIFIED_BYTE}

str_time_separator:             ; populated from settings at runtime
        PASCAL_STRING {SELF_MODIFIED_BYTE}

        .include "../lib/event_params.s"

        kDAWindowId = $80

.params closewindow_params
window_id:     .byte   kDAWindowId
.endparams

penXOR:         .byte   MGTK::penXOR

.params winfo
window_id:      .byte   kDAWindowId
options:        .byte   MGTK::Option::dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   0
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   100
mincontheight:  .word   100
maxcontwidth:   .word   500
maxcontheight:  .word   500
port:
        DEFINE_POINT viewloc, (kScreenWidth-kDialogWidth)/2, (kScreenHeight-kDialogHeight)/2
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDialogWidth, kDialogHeight
pattern:        .res    8,$FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::notpencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

;;; ============================================================
;;; 12/24 Hour Resources


kOptionDisplayX = 150
kOptionDisplayY = 34

        DEFINE_BUTTON clock_12hour_button, kDAWindowId, res_string_label_clock_12hour, res_string_shortcut_apple_1, kOptionDisplayX, kOptionDisplayY
        DEFINE_BUTTON clock_24hour_button, kDAWindowId, res_string_label_clock_24hour, res_string_shortcut_apple_2, kOptionDisplayX, kOptionDisplayY+10

.params date_bitmap_params
        DEFINE_POINT viewloc, 14, 34
mapbits:        .addr   date_bitmap
mapwidth:       .byte   6
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 39, 17
        REF_MAPINFO_MEMBERS
.endparams
date_bitmap:
        PIXELS  "######################..................."
        PIXELS  "##..######################..............."
        PIXELS  "##..##..................##..............."
        PIXELS  "##..######################..............."
        PIXELS  "##..##..................##.....##########"
        PIXELS  "##..##....##########....#######........##"
        PIXELS  "##..##...###......########.............##"
        PIXELS  "##..##...###......###........###.......##"
        PIXELS  "##..##..........#####.......####.......##"
        PIXELS  "##..##........####.##....#######.......##"
        PIXELS  "##..##......####...##.......####.......##"
        PIXELS  "##..##....####.....##.......####.......##"
        PIXELS  "##..##...####......##.......####.......##"
        PIXELS  "##..##...############.......####.......##"
        PIXELS  "######.............##.......####.......##"
        PIXELS  "....#################....##########....##"
        PIXELS  "...................##..................##"
        PIXELS  "...................######################"

.params time_bitmap_params
        DEFINE_POINT viewloc, kDialogWidth - 32 - 11, 33
mapbits:        .addr   time_bitmap
mapwidth:       .byte   5
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 31, 14
        REF_MAPINFO_MEMBERS
.endparams
time_bitmap:
        PIXELS  "..........############.........."
        PIXELS  "......####............####......"
        PIXELS  "....##.........##.........##...."
        PIXELS  "..##...........##...........##.."
        PIXELS  ".##............##............##."
        PIXELS  "##.............##.............##"
        PIXELS  "##.............##.............##"
        PIXELS  "##.............##.............##"
        PIXELS  "##...............##...........##"
        PIXELS  "##.................##.........##"
        PIXELS  ".##..................##......##."
        PIXELS  "..##........................##.."
        PIXELS  "....##....................##...."
        PIXELS  "......####............####......"
        PIXELS  "..........############.........."

;;; ============================================================
;;; Copy of ProDOS DATE/TIME

.params auxdt
DATELO: .byte   0
DATEHI: .byte   0
TIMELO: .byte   0
TIMEHI: .byte   0
.endparams

;;; ============================================================
;;; Cached settings

clock_24hours:  .byte   0

;;; ============================================================
;;; Initialize window, unpack the date.

init_window:
        ;; Cache settings
        CALL    ReadSetting, X=#DeskTopSettings::intl_date_sep
        sta     str_date_separator+1
        CALL    ReadSetting, X=#DeskTopSettings::intl_time_sep
        sta     str_time_separator+1
        CALL    ReadSetting, X=#DeskTopSettings::clock_24hours
        sta     clock_24hours

        jsr     GetDateFromProDOS

        ;; If null date, just leave the baked in default
        lda     auxdt::DATELO
        ora     auxdt::DATEHI
    IF NOT_ZERO

        ;; Crack the date bytes. Format is:
        ;; |     DATEHI    | |    DATELO     |
        ;;  7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;; |    Year     |  Month  |   Day   |
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+

        lda     auxdt::DATEHI
        lsr     a
        sta     year

        lda     auxdt::DATELO
        and     #%11111
        sta     day

        lda     auxdt::DATEHI
        ror     a
        lda     auxdt::DATELO
        ror     a
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     month

        ;; |     TIMEHI    | |    TIMELO     |
        ;;  7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;; |0 0 0|  Hour   | |0 0|  Minute   |
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+

        lda     auxdt::TIMEHI
        and     #%00011111
        sta     hour

        lda     auxdt::TIMELO
        and     #%00111111
        sta     minute

    END_IF

        MGTK_CALL MGTK::OpenWindow, winfo
        copy8   #0, selected_field
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop

;;; ============================================================
;;; Input loop

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
    IF A = #MGTK::EventKind::button_down
        jsr     OnClick
        jmp     InputLoop
    END_IF

        cmp     #MGTK::EventKind::key_down
        bne     InputLoop
        FALL_THROUGH_TO OnKey
.endproc ; InputLoop

.proc OnKey
        MGTK_CALL MGTK::SetPort, winfo::port
        MGTK_CALL MGTK::SetPenMode, penXOR

        lda     event_params::key

        ldx     event_params::modifiers
    IF NOT_ZERO
        jsr     ToUpperCase
        cmp     #kShortcutCloseWindow
        jeq     OnKeyOK

      IF A = #'1'
        CALL    HandleOptionClick, A=#0
        jmp     InputLoop
      END_IF

      IF A = #'2'
        CALL    HandleOptionClick, A=#$80
        jmp     InputLoop
      END_IF

        jmp     InputLoop
    END_IF

        cmp     #CHAR_RETURN
        jeq     OnKeyOK
        cmp     #CHAR_ESCAPE
        jeq     OnKeyOK

        ;; If there is a system clock, fields are read-only
        ldx     clock_flag
        bne     InputLoop

        ;; All controls are active
        cmp     #CHAR_LEFT
        beq     OnKeyLeft
        cmp     #CHAR_RIGHT
        beq     OnKeyRight
        cmp     #CHAR_TAB
        beq     OnKeyRight
        cmp     #CHAR_DOWN
        beq     OnKeyDown
        cmp     #CHAR_UP
        bne     InputLoop
        FALL_THROUGH_TO OnKeyUp

.proc OnKeyUp
        jsr     InvertUp
        copy8   #kUpRectIndex, hit_rect_index
        jsr     DoIncOrDec
        jsr     InvertUp
        jmp     InputLoop
.endproc ; OnKeyUp

.proc OnKeyDown
        jsr     InvertDown
        copy8   #kDownRectIndex, hit_rect_index
        jsr     DoIncOrDec
        jsr     InvertDown
        jmp     InputLoop
.endproc ; OnKeyDown

.proc OnKeyLeft
        sec
        lda     selected_field
        sbc     #1
        bne     UpdateSelection
        bit     clock_24hours
    IF NC
        lda     #Field::period
    ELSE
        lda     #Field::period-1
    END_IF
        jmp     UpdateSelection
.endproc ; OnKeyLeft

.proc OnKeyRight
        clc
        lda     selected_field
        adc     #1

        bit     clock_24hours
    IF NC
        cmp     #Field::period+1
    ELSE
        cmp     #Field::period
    END_IF
        bne     UpdateSelection
        lda     #Field::day
        FALL_THROUGH_TO UpdateSelection
.endproc ; OnKeyRight

.proc UpdateSelection
        jsr     SelectField
        jmp     InputLoop
.endproc ; UpdateSelection
.endproc ; OnKey

;;; ============================================================

.proc OnClick
        MGTK_CALL MGTK::FindWindow, event_params::xcoord
        lda     findwindow_params::window_id
        cmp     #kDAWindowId
        bne     miss
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        beq     hit
miss:   rts
hit:
        ;; ----------------------------------------

        MGTK_CALL MGTK::SetPort, winfo::port
        MGTK_CALL MGTK::SetPenMode, penXOR

        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        ;; ----------------------------------------

        MGTK_CALL MGTK::InRect, ok_button::rect
        jne     OnClickOK

        MGTK_CALL MGTK::InRect, clock_12hour_button::rect
    IF NOT_ZERO
        TAIL_CALL HandleOptionClick, A=#$00
    END_IF

        MGTK_CALL MGTK::InRect, clock_24hour_button::rect
    IF NOT_ZERO
        TAIL_CALL HandleOptionClick, A=#$80
    END_IF

        ;; ----------------------------------------

        ;; If there is a system clock, fields are read-only
        ldx     clock_flag
        bne     miss

        jsr     FindHitTarget
        cpx     #0
        beq     miss
        txa
        asl     a
        tay
        copy16  hit_target_jump_table-2,y, jump
        jump := *+1
        jmp     SELF_MODIFIED

hit_target_jump_table:
        ;; Called w/ X = index
        .addr   OnUp, OnDown
        .addr   OnFieldClick, OnFieldClick, OnFieldClick, OnFieldClick, OnFieldClick, OnFieldClick
        ASSERT_ADDRESS_TABLE_SIZE hit_target_jump_table, aux::kNumHitRects
.endproc ; OnClick

;;; ============================================================

.proc OnClickOK
        BTK_CALL BTK::Track, ok_button
    IF ZERO
        pla                     ; pop OnClick
        pla
        jmp     OnOK
    END_IF
        rts
.endproc ; OnClickOK

.proc OnKeyOK
        BTK_CALL BTK::Flash, ok_button
        FALL_THROUGH_TO OnOK
.endproc ; OnKeyOK

.proc OnOK
        lda     clock_flag
    IF ZERO
        jsr     UpdateProDOS
    END_IF
        jmp     Destroy
.endproc ; OnOK

;;; ============================================================

.proc OnUp
        txa
        pha
        jsr     InvertUp
        pla
        tax
        jmp     OnUpOrDown
.endproc ; OnUp

.proc OnDown
        txa
        pha
        jsr     InvertDown
        pla
        tax
        jmp     OnUpOrDown
.endproc ; OnDown

.proc OnFieldClick
        dex
        dex
        txa

        bit     clock_24hours
    IF NS
        RTS_IF A = #Field::period
    END_IF

        jmp     SelectField
.endproc ; OnFieldClick

.proc OnUpOrDown
        stx     hit_rect_index
loop:   MGTK_CALL MGTK::GetEvent, event_params ; Repeat while mouse is down

        lda     event_params::kind
    IF A <> #MGTK::EventKind::button_up
        jsr     DoIncOrDec
        jmp     loop
    END_IF

        lda     hit_rect_index
        cmp     #kUpRectIndex
        jeq     InvertUp
        jmp     InvertDown
.endproc ; OnUpOrDown

.proc DoIncOrDec
        ptr := $6

        jsr     Delay

        ;; Set day max, based on month/year.
        jsr     SetMonthLength

        ;; Hour requires special handling for 12-hour clock; patch the
        ;; min/max table depending on clock setting and period.
        bit     clock_24hours
    IF NC
        lda     hour
      IF A < #12
        copy8   #kHourMin, min_table + Field::hour - 1
        copy8   #11, max_table + Field::hour - 1
      ELSE
        copy8   #12, min_table + Field::hour - 1
        copy8   #kHourMax, max_table + Field::hour - 1
      END_IF
    ELSE
        copy8   #kHourMin, min_table + Field::hour - 1
        copy8   #kHourMax, max_table + Field::hour - 1
    END_IF

        lda     selected_field

        ;; Period also needs special handling
        cmp     #Field::period
        beq     TogglePeriod

        tax                     ; X = byte table offset
        asl     a
        tay                     ; Y = address table offset
        copy8   min_table-1,x, min
        copy8   max_table-1,x, max
        copy16  prepare_proc_table-2,y, prepare_proc
        copy16  field_table-2,y, ptr

        ldy     #0              ; Y = 0
        lda     (ptr),y
        tax                     ; X = value

        lda     hit_rect_index
        cmp     #kUpRectIndex
        beq     incr

        ;; Decrement
    IF X = min
        ldx     max
        inx
    END_IF
        dex
        jmp     finish

        ;; Increment
incr:
    IF X = max
        ldx     min
        dex
    END_IF
        inx
        FALL_THROUGH_TO finish

finish:
        txa                     ; store new value
        sta     (ptr),y
        prepare_proc := *+1
        jsr     SELF_MODIFIED   ; update string
        CALL    DrawField, A=selected_field

        ;; If month changed, make sure day is in range and update if not.
        jsr     SetMonthLength
        lda     max_table+Field::day-1
    IF A < day
        sta     day
        MGTK_CALL MGTK::SetTextBG, settextbg_white_params
        jsr     PrepareDayString
        CALL    DrawField, A=#Field::day
    END_IF
        rts

min:    .byte   0
max:    .byte   0
.endproc ; DoIncOrDec

hit_rect_index:
        .byte   0

;;; ============================================================

.proc TogglePeriod
        ;; Flip to other period
        lda     hour
    IF A < #12                  ; also sets C correctly for adc/sbc
        adc     #12
    ELSE
        sbc     #12
    END_IF
        sta     hour

        TAIL_CALL DrawField, A=#Field::period
.endproc ; TogglePeriod

;;; ============================================================

        kNumFields = 6

        kDayMin = 1
        kDayMax = 31
        kMonthMin = 1
        kMonthMax = 12
        kYearMin = 0
        kYearMax = 99
        kHourMin = 0
        kHourMax = 23
        kMinuteMin = 0
        kMinuteMax = 59

;;; The following tables don't include period (which gets special handling)

field_table:
        .addr   day, month, year, hour, minute
        ASSERT_ADDRESS_TABLE_SIZE field_table, kNumFields-1

min_table:
        .byte   kDayMin, kMonthMin, kYearMin, kHourMin, kMinuteMin
        ASSERT_TABLE_SIZE min_table, kNumFields-1

max_table:
        .byte   kDayMax, kMonthMax, kYearMax, kHourMax, kMinuteMax
        ASSERT_TABLE_SIZE max_table, kNumFields-1

prepare_proc_table:
        .addr   PrepareDayString, PrepareMonthString, PrepareYearString, PrepareHourString, PrepareMinuteString
        ASSERT_ADDRESS_TABLE_SIZE prepare_proc_table, kNumFields-1

month_length_table:
        .byte   31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
        ASSERT_TABLE_SIZE month_length_table, 12

;;; ============================================================

.proc PrepareDayString
        CALL    NumberToASCII, A=day
        sta     day_string+1    ; first char
        stx     day_string+2    ; second char
        rts
.endproc ; PrepareDayString

.proc PrepareMonthString
        lda     month           ; month * 3 - 1
        asl     a
        clc
        adc     month
        tax
        dex

        ptr := $07
        str := month_string + 1
        kLength = 3

        copy16  #str, ptr

        ldy     #kLength - 1
    DO
        copy8   month_name_table,x, (ptr),y
        dex
        dey
    WHILE POS

        rts
.endproc ; PrepareMonthString

month_name_table:
        .byte   .sprintf("%3s", res_string_month_abbrev_1)
        .byte   .sprintf("%3s", res_string_month_abbrev_2)
        .byte   .sprintf("%3s", res_string_month_abbrev_3)
        .byte   .sprintf("%3s", res_string_month_abbrev_4)
        .byte   .sprintf("%3s", res_string_month_abbrev_5)
        .byte   .sprintf("%3s", res_string_month_abbrev_6)
        .byte   .sprintf("%3s", res_string_month_abbrev_7)
        .byte   .sprintf("%3s", res_string_month_abbrev_8)
        .byte   .sprintf("%3s", res_string_month_abbrev_9)
        .byte   .sprintf("%3s", res_string_month_abbrev_10)
        .byte   .sprintf("%3s", res_string_month_abbrev_11)
        .byte   .sprintf("%3s", res_string_month_abbrev_12)
        ASSERT_RECORD_TABLE_SIZE month_name_table, 12, 3

str_am: PASCAL_STRING "AM"
str_pm: PASCAL_STRING "PM"

.proc PrepareYearString
        CALL    NumberToASCII, A=year
        sta     year_string+1
        stx     year_string+2
        rts
.endproc ; PrepareYearString

.proc PrepareHourString
        lda     hour
        bit     clock_24hours
    IF NC
      IF A = #0
        lda     #12
      END_IF
      IF A >= #13
        sbc     #12
      END_IF
    END_IF

        jsr     NumberToASCII
        bit     clock_24hours
    IF NC
      IF A = #'0'
        lda     #' '
      END_IF
    END_IF
        sta     hour_string+1
        stx     hour_string+2
        rts
.endproc ; PrepareHourString

.proc PrepareMinuteString
        CALL    NumberToASCII, A=minute
        sta     minute_string+1
        stx     minute_string+2
        rts
.endproc ; PrepareMinuteString

;;; ============================================================
;;; Tear down the window and exit

;;; Used in Aux to store result during tear-down
;;; bit7 = time changed
;;; bit6 = options changed
dialog_result:  .byte   0

.proc Destroy
        MGTK_CALL MGTK::CloseWindow, closewindow_params

        ;; Dates in DeskTop list views may be invalidated, so if date
        ;; or settings changed, force a full redraw to avoid artifacts.
        lda     dialog_result
    IF NOT_ZERO
        MGTK_CALL MGTK::RedrawDeskTop
    END_IF

        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts
.endproc ; Destroy

;;; ============================================================
;;; Figure out which button was hit (if any).
;;; Index returned in X.

.proc FindHitTarget
        ldx     #1
        copy16  #first_hit_rect, test_addr

    DO
        txa
        pha
        MGTK_CALL MGTK::InRect, SELF_MODIFIED, test_addr
        bne     done

        add16_8 test_addr, #.sizeof(MGTK::Rect)
        pla
        tax
        inx
    WHILE X <> #kNumHitRects+1

        RETURN  X=#0

done:   pla
        tax
        rts
.endproc ; FindHitTarget

;;; ============================================================
;;; Params for the display

pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY
        DEFINE_RECT_FRAME frame_rect, kDialogWidth, kDialogHeight

label_uparrow:
        PASCAL_STRING kGlyphUpArrow
label_downarrow:
        PASCAL_STRING kGlyphDownArrow

;;; ============================================================
;;; Render the window contents

.proc DrawWindow
        MGTK_CALL MGTK::SetPort, winfo::port

        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        MGTK_CALL MGTK::FrameRect, date_rect
        MGTK_CALL MGTK::FrameRect, time_rect

        MGTK_CALL MGTK::PaintBitsHC, date_bitmap_params
        MGTK_CALL MGTK::PaintBitsHC, time_bitmap_params

        MGTK_CALL MGTK::MoveTo, date_sep1_pos
        CALL    DrawString, AX=#str_date_separator
        MGTK_CALL MGTK::MoveTo, date_sep2_pos
        CALL    DrawString, AX=#str_date_separator
        MGTK_CALL MGTK::MoveTo, time_sep_pos
        CALL    DrawString, AX=#str_time_separator

        MGTK_CALL MGTK::SetPenMode, penXOR

        ;; If there is a system clock, only draw the OK button.
        ldx     clock_flag
    IF ZERO
        MGTK_CALL MGTK::MoveTo, label_uparrow_pos
        CALL    DrawString, AX=#label_uparrow
        MGTK_CALL MGTK::FrameRect, up_arrow_rect

        MGTK_CALL MGTK::MoveTo, label_downarrow_pos
        CALL    DrawString, AX=#label_downarrow
        MGTK_CALL MGTK::FrameRect, down_arrow_rect
    END_IF

        jsr     PrepareDayString
        jsr     PrepareMonthString
        jsr     PrepareYearString
        jsr     PrepareHourString
        jsr     PrepareMinuteString

        CALL    DrawField, A=#Field::day
        CALL    DrawField, A=#Field::month
        CALL    DrawField, A=#Field::year
        CALL    DrawField, A=#Field::hour
        CALL    DrawField, A=#Field::minute
        CALL    DrawField, A=#Field::period

        ;; If there is a system clock, don't draw the highlight.
        ldx     clock_flag
    IF ZERO
        CALL    SelectField, A=#Field::day
    END_IF

        ;; --------------------------------------------------

        BTK_CALL BTK::Draw, ok_button
        BTK_CALL BTK::RadioDraw, clock_12hour_button
        BTK_CALL BTK::RadioDraw, clock_24hour_button

        FALL_THROUGH_TO UpdateOptionButtons
.endproc ; DrawWindow

.proc UpdateOptionButtons
        lda     clock_24hours
        cmp     #0
        jsr     ZToButtonState
        sta     clock_12hour_button::state
        BTK_CALL BTK::RadioUpdate, clock_12hour_button

        lda     clock_24hours
        cmp     #$80
        jsr     ZToButtonState
        sta     clock_24hour_button::state
        BTK_CALL BTK::RadioUpdate, clock_24hour_button

        rts
.endproc ; UpdateOptionButtons

.proc ZToButtonState
    IF ZC
        RETURN  A=#BTK::kButtonStateNormal
    END_IF
        RETURN  A=#BTK::kButtonStateChecked
.endproc ; ZToButtonState

;;; A = field
.proc DrawField
        pha
    IF A = selected_field
        MGTK_CALL MGTK::SetTextBG, settextbg_black_params
    ELSE
        MGTK_CALL MGTK::SetTextBG, settextbg_white_params
    END_IF

        pla
        cmp     #Field::day
        beq     DrawDay
        cmp     #Field::month
        beq     DrawMonth
        cmp     #Field::year
        beq     DrawYear
        cmp     #Field::hour
        beq     DrawHour
        cmp     #Field::minute
        beq     DrawMinute
        cmp     #Field::period
        beq     DrawPeriod
        rts

.proc DrawDay
        MGTK_CALL MGTK::MoveTo, day_pos
        TAIL_CALL DrawString, AX=#day_string
.endproc ; DrawDay

.proc DrawMonth
        MGTK_CALL MGTK::MoveTo, month_pos
        CALL    DrawString, AX=#spaces_string ; variable width, so clear first
        MGTK_CALL MGTK::MoveTo, month_pos
        TAIL_CALL DrawString, AX=#month_string
.endproc ; DrawMonth

.proc DrawYear
        MGTK_CALL MGTK::MoveTo, year_pos
        TAIL_CALL DrawString, AX=#year_string
.endproc ; DrawYear

.proc DrawHour
        MGTK_CALL MGTK::MoveTo, hour_pos
        TAIL_CALL DrawString, AX=#hour_string
.endproc ; DrawHour

.proc DrawMinute
        MGTK_CALL MGTK::MoveTo, minute_pos
        TAIL_CALL DrawString, AX=#minute_string
.endproc ; DrawMinute

.proc DrawPeriod
        MGTK_CALL MGTK::MoveTo, period_pos
        bit     clock_24hours
    IF NS
        CALL    DrawString, AX=#spaces_string
    ELSE
        lda     hour
      IF A < #12
        TAIL_CALL DrawString, AX=#str_am
      ELSE
        TAIL_CALL DrawString, AX=#str_pm
      END_IF
    END_IF
        rts
.endproc ; DrawPeriod
.endproc ; DrawField

;;; ============================================================

.proc InvertUp
        MGTK_CALL MGTK::InflateRect, shrink
        MGTK_CALL MGTK::PaintRect, up_arrow_rect
        MGTK_CALL MGTK::InflateRect, grow
        rts

.params shrink
        .addr   up_arrow_rect
        .word   AS_WORD(-1)
        .word   AS_WORD(-1)
.endparams
.params grow
        .addr   up_arrow_rect
        .word   1
        .word   1
.endparams
.endproc ; InvertUp

.proc InvertDown
        MGTK_CALL MGTK::InflateRect, shrink
        MGTK_CALL MGTK::PaintRect, down_arrow_rect
        MGTK_CALL MGTK::InflateRect, grow
        rts
.params shrink
        .addr   down_arrow_rect
        .word   AS_WORD(-1), AS_WORD(-1)
.endparams
.params grow
        .addr   down_arrow_rect
        .word   1, 1
.endparams
.endproc ; InvertDown

;;; ============================================================
;;; Selected a field (dehighlight the old one, highlight the new one)
;;; Input: A = new field to select

.proc SelectField
        pha
        MGTK_CALL MGTK::SetPenMode, penXOR

        CALL    invert, A=selected_field  ; invert old

        pla                     ; update to new
        sta     selected_field
        FALL_THROUGH_TO invert

invert: cmp     #Field::day
        beq     fill_day
        cmp     #Field::month
        beq     fill_month
        cmp     #Field::year
        beq     fill_year
        cmp     #Field::hour
        beq     fill_hour
        cmp     #Field::minute
        beq     fill_minute
        cmp     #Field::period
        beq     fill_period
        rts

fill_day:
        MGTK_CALL MGTK::PaintRect, day_rect
        rts

fill_month:
        MGTK_CALL MGTK::PaintRect, month_rect
        rts

fill_year:
        MGTK_CALL MGTK::PaintRect, year_rect
        rts

fill_hour:
        MGTK_CALL MGTK::PaintRect, hour_rect
        rts

fill_minute:
        MGTK_CALL MGTK::PaintRect, minute_rect
        rts

fill_period:
        MGTK_CALL MGTK::PaintRect, period_rect
        rts

.endproc ; SelectField

;;; ============================================================
;;; Delay

.proc Delay
        lda     #255
        sec
    DO
        pha
      DO
        sbc     #1
      WHILE NOT_ZERO
        pla
        sbc     #1
    WHILE NOT_ZERO
        rts
.endproc ; Delay

;;; ============================================================
;;; Convert number to two ASCII digits (in A, X)

.proc NumberToASCII
        ldy     #0
loop:
    IF A >= #10
        sec
        sbc     #10
        iny
        jmp     loop
    END_IF
        ora     #'0'
        tax
        tya
        ora     #'0'
        rts
.endproc ; NumberToASCII

;;; ============================================================
;;; Update the `max_table` for the max day given the month/year.

.proc SetMonthLength
        ;; Month lengths
        ldx     month
        ldy     month_length_table-1,x
    IF X = #2                   ; February?
        lda     year            ; Handle leap years; interpreted as either
        and     #3              ; (1900+Y) or (Y<40 ? 2000+Y : 1900+Y) - which is
      IF ZERO                   ; correct for 1901 through 2199, so good enough.
        iny
      END_IF
    END_IF
        sty     max_table + Field::day - 1
        rts
.endproc ; SetMonthLength

;;; ============================================================

.proc HandleOptionClick
        sta     clock_24hours
        CALL    WriteSetting, X=#DeskTopSettings::clock_24hours

        jsr     UpdateOptionButtons

        ;; Set dirty bit
        lda     dialog_result
        ora     #$40            ; settings changed
        sta     dialog_result

        lda     selected_field
    IF A = #Field::period
        CALL    SelectField, A=#Field::minute
    END_IF

        CALL    DrawField, A=#Field::period

        jsr     PrepareHourString
        CALL    DrawField, A=#Field::hour

        rts                     ; back to `InputLoop`
.endproc ; HandleOptionClick

;;; ============================================================
;;; Assert: Called from Aux

.proc GetDateFromProDOS
        copy16  #DATELO, STARTLO
        copy16  #DATELO+.sizeof(DateTime)-1, ENDLO
        copy16  #auxdt, DESTINATIONLO
        TAIL_CALL AUXMOVE, C=1  ; main>aux
.endproc ; GetDateFromProDOS

;;; ============================================================
;;; Assert: Called from Aux

.proc UpdateProDOS
        ;; Pack the date bytes
        lda     month
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        ora     day
        sta     auxdt::DATELO
        lda     year
        rol     a
        sta     auxdt::DATEHI

        copy8   minute, auxdt::TIMELO
        copy8   hour, auxdt::TIMEHI

        ;; Get the current ProDOS date/time
        copy16  #DATELO, STARTLO
        copy16  #DATELO+.sizeof(DateTime)-1, ENDLO
        copy16  #current, DESTINATIONLO
        CALL    AUXMOVE, C=1    ; main>aux

        ;; Is it different?
        ecmp16  current+DateTime::datelo, auxdt::DATELO
        bne     update
        ecmp16  current+DateTime::timelo, auxdt::TIMELO
        beq     done

update:
        ;; Update the ProDOS date/time
        copy16  #auxdt, STARTLO
        copy16  #auxdt+.sizeof(DateTime)-1, ENDLO
        copy16  #DATELO, DESTINATIONLO
        CALL    AUXMOVE, C=0    ; aux>main

        ;; Set dirty bit
        lda     dialog_result
        ora     #$80            ; date changed
        sta     dialog_result

done:   rts

current:
        .tag    DateTime

.endproc ; UpdateProDOS

;;; ============================================================

        .include "../lib/uppercase.s"
        .include "../lib/drawstring.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT

;;; ============================================================

.scope main
        lda     MACHID
        and     #kMachIDHasClock
        tay                     ; A,X are trashed by macro
        JSR_TO_AUX aux::RunDA
        sta     result

        bit     result
    IF NS
        jsr     SaveDate
    END_IF

        bit     result
    IF VS
        jsr     SaveSettings
    END_IF

        rts

result: .byte   0
.endscope ; main

;;; ============================================================

.proc save_date
filename:
        PASCAL_STRING kFilenameLauncher

filename_buffer:
        .res ::kPathBufferSize

        DEFINE_OPEN_PARAMS open_params, filename, DA_IO_BUFFER
        DEFINE_SET_MARK_PARAMS set_mark_params, kLauncherDateOffset
        DEFINE_READWRITE_PARAMS write_params, write_buffer, sizeof_write_buffer
        DEFINE_CLOSE_PARAMS close_params

write_buffer:
        .tag    DateTime
        sizeof_write_buffer = * - write_buffer

.proc SaveSettings
        ;; ProDOS GP has the updated data, copy somewhere usable.
        COPY_STRUCT DateTime, DATELO, write_buffer

        ;; Write to desktop current prefix
        ldax    #filename
        stax    open_params::pathname
        jsr     DoWrite
        bcs     done            ; failed and canceled

        ;; Write to the original file location, if necessary
        jsr     JUMP_TABLE_GET_RAMCARD_FLAG
        beq     done
        ldax    #filename_buffer
        stax    open_params::pathname
        jsr     JUMP_TABLE_GET_ORIG_PREFIX
        jsr     AppendFilename
        jsr     DoWrite

done:   rts
.endproc ; SaveSettings

.proc AppendFilename
        ;; Append filename to buffer
        inc     filename_buffer ; Add '/' separator
        ldx     filename_buffer
        copy8   #'/', filename_buffer,x

        ldx     #0              ; Append filename
        ldy     filename_buffer
    DO
        inx
        iny
        copy8   filename,x, filename_buffer,y
    WHILE X <> filename
        sty     filename_buffer
        rts
.endproc ; AppendFilename

.proc DoWrite
        ;; First time - ask if we should even try.
        copy8   #kErrSaveChanges, message

retry:
        JUMP_TABLE_MLI_CALL OPEN, open_params
        bcs     error
        lda     open_params::ref_num
        sta     set_mark_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num

        JUMP_TABLE_MLI_CALL SET_MARK, set_mark_params ; seek
        bcs     close
        JUMP_TABLE_MLI_CALL WRITE, write_params
close:  php                     ; preserve result
        JUMP_TABLE_MLI_CALL CLOSE, close_params
        plp
        bcc     ret             ; succeeded

error:
        message := *+1
        lda     #SELF_MODIFIED_BYTE
        jsr     JUMP_TABLE_SHOW_ALERT

        ;; Second time - prompt to insert.
        ldx     #kErrInsertSystemDisk
        stx     message

        cmp     #kAlertResultOK
        beq     retry

        sec                     ; failed
ret:    rts

second_try_flag:
        .byte   0
.endproc ; DoWrite
.endproc ; save_date
SaveDate := save_date::SaveSettings

;;; ============================================================

        .include "../lib/save_settings.s"
        .assert * < write_buffer, error, .sprintf("DA too big (at $%X)", *)

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
