;;; ============================================================
;;; DATE.AND.TIME - Desk Accessory
;;;
;;; Shows the current ProDOS date/time, and allows editing if there is
;;; no clock driver installed or we know how to write to it. Also
;;; exposes the 12/24-hour clock setting, and will update the settings
;;; file.
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

;;; Input: Y = read only flag (zero or non-zero)
.proc RunDA
        sty     readonly_flag
        jsr     init_window
        RETURN  A=dialog_result
.endproc ; RunDA

;;; ============================================================
;;; Param blocks

        kDialogWidth = 287
        kDialogHeight = 77

        ;; The following rects are iterated over to identify
        ;; a hit target for a click.

        kNumHitRects = 8
        kUpRectIndex = 1        ; 1-based
        kDownRectIndex = 2

        kMarginX = kModalDialogInsetX
        kMarginY = kModalDialogInsetY

        kFieldTop = kMarginY + 5
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
        kUpDownButtonLeft = kDialogWidth - kUpDownButtonWidth - kMarginX

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

        DEFINE_RECT_SZ date_rect, kMarginX, kFieldTop-kFieldPaddingY, 122, kFieldHeight+kFieldPaddingY*2
        DEFINE_RECT_SZ time_rect, 150, kFieldTop-kFieldPaddingY, 102, kFieldHeight+kFieldPaddingY*2

        kOKButtonLeft = (kDialogWidth + 1) - kButtonWidth - kMarginX
        kOKButtonTop  = (kDialogHeight + 1) - kButtonHeight - kMarginY
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

;;; DA is read-only if there is a system clock but we don't know
;;; how to update it.
readonly_flag:                  ; zero (read/write) or non-zero (read-only)
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

        DEFINE_BUTTON clock_12hour_button, kDAWindowId, res_string_label_clock_12hour, res_string_shortcut_apple_1, kOptionDisplayX, kOptionDisplayY, 80
        DEFINE_BUTTON clock_24hour_button, kDAWindowId, res_string_label_clock_24hour, res_string_shortcut_apple_2, kOptionDisplayX, kOptionDisplayY+10, 80

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
        MGTK_CALL MGTK::HideCursor
        copy8   #0, selected_field
        jsr     DrawWindow
        MGTK_CALL MGTK::ShowCursor
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

        ldx     readonly_flag
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
    IF bit clock_24hours : NC
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

    IF bit clock_24hours : NC
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

        ldx     readonly_flag
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
        lda     readonly_flag
    IF ZERO
      IF bit dialog_result : NS
        jsr     UpdateProDOS
      END_IF
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

    IF bit clock_24hours : NS
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
    IF bit clock_24hours : NC
      IF lda hour : A < #12
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

        ;; Set dirty bit
        lda     dialog_result
        ora     #$80            ; date changed
        sta     dialog_result

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
    WHILE dex : dey : POS

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
    IF bit clock_24hours : NC
      IF A = #0
        lda     #12
      END_IF
      IF A >= #13
        sbc     #12
      END_IF
    END_IF

        jsr     NumberToASCII
    IF bit clock_24hours : NC AND A = #'0'
        lda     #' '
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

        MGTK_CALL MGTK::PaintBits, date_bitmap_params
        MGTK_CALL MGTK::PaintBits, time_bitmap_params

        MGTK_CALL MGTK::MoveTo, date_sep1_pos
        MGTK_CALL MGTK::DrawString, str_date_separator
        MGTK_CALL MGTK::MoveTo, date_sep2_pos
        MGTK_CALL MGTK::DrawString, str_date_separator
        MGTK_CALL MGTK::MoveTo, time_sep_pos
        MGTK_CALL MGTK::DrawString, str_time_separator

        MGTK_CALL MGTK::SetPenMode, penXOR

        ldx     readonly_flag
    IF ZERO
        MGTK_CALL MGTK::MoveTo, label_uparrow_pos
        MGTK_CALL MGTK::DrawString, label_uparrow
        MGTK_CALL MGTK::FrameRect, up_arrow_rect

        MGTK_CALL MGTK::MoveTo, label_downarrow_pos
        MGTK_CALL MGTK::DrawString, label_downarrow
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

        ldx     readonly_flag
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
        MGTK_CALL MGTK::DrawString, day_string
        rts
.endproc ; DrawDay

.proc DrawMonth
        MGTK_CALL MGTK::MoveTo, month_pos
        MGTK_CALL MGTK::DrawString, spaces_string ; variable width, so clear first
        MGTK_CALL MGTK::MoveTo, month_pos
        MGTK_CALL MGTK::DrawString, month_string
        rts
.endproc ; DrawMonth

.proc DrawYear
        MGTK_CALL MGTK::MoveTo, year_pos
        MGTK_CALL MGTK::DrawString, year_string
        rts
.endproc ; DrawYear

.proc DrawHour
        MGTK_CALL MGTK::MoveTo, hour_pos
        MGTK_CALL MGTK::DrawString, hour_string
        rts
.endproc ; DrawHour

.proc DrawMinute
        MGTK_CALL MGTK::MoveTo, minute_pos
        MGTK_CALL MGTK::DrawString, minute_string
        rts
.endproc ; DrawMinute

.proc DrawPeriod
        MGTK_CALL MGTK::MoveTo, period_pos

    IF bit clock_24hours : NS
        MGTK_CALL MGTK::DrawString, spaces_string
    ELSE_IF lda hour : A < #12
      MGTK_CALL MGTK::DrawString, str_am
    ELSE
      MGTK_CALL MGTK::DrawString, str_pm
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

        ldx     #5
    DO
        txa
        pha
        MGTK_CALL MGTK::WaitVBL
        pla
        tax
    WHILE dex : POS

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

    IF lda selected_field : A = #Field::period
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

        ;; Update the ProDOS date/time
        copy16  #auxdt, STARTLO
        copy16  #auxdt+.sizeof(DateTime)-1, ENDLO
        copy16  #DATELO, DESTINATIONLO
        CALL    AUXMOVE, C=0    ; aux>main

        rts
.endproc ; UpdateProDOS

;;; ============================================================

        .include "../lib/uppercase.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT

;;; ============================================================

.scope main
        ;; Ensure we've got the latest time.
        JUMP_TABLE_MLI_CALL GET_TIME

        lda     MACHID
        and     #kMachIDHasClock
    IF ZERO
        ;; no system clock - DA is read/write
        ldy     #0
    ELSE
        jsr     CanSetClock     ; returns C=0 if clock can be set
        lda     #0
        ror
        tay
    END_IF

        JSR_TO_AUX aux::RunDA   ; Y = read-only flag
        sta     result

    IF bit result : NS
        jsr     MaybeSetClock
    END_IF

    IF bit result : VS
        jsr     SaveSettings

        ;; If we failed to save settings (e.g. write protected), don't
        ;; bother trying to save the date as that is more error prone;
        ;; e.g. if write protected, the CLOSE will fail leaving the IO
        ;; buffer and file control block permanently in use.
        bcs     ret
    END_IF

    IF bit result : NS
        jsr     SaveDate
    END_IF

ret:
        rts

result: .byte   0
.endscope ; main

;;; ============================================================

.scope save_date
filename:
        PASCAL_STRING kFilenameLauncher

write_buffer:
        .tag    DateTime
        sizeof_write_buffer = * - write_buffer

        ;; If running from RAMCard, we temporarily swap the ProDOS
        ;; prefix for writing back to the startup disk.
current_prefix:
        .res ::kPathBufferSize
orig_prefix:
        .res ::kPathBufferSize

        DEFINE_OPEN_PARAMS open_params, filename, DA_IO_BUFFER
        DEFINE_SET_MARK_PARAMS set_mark_params, kLauncherDateOffset
        DEFINE_READWRITE_PARAMS write_params, write_buffer, sizeof_write_buffer
        DEFINE_CLOSE_PARAMS close_params

        DEFINE_GET_PREFIX_PARAMS current_prefix_params, current_prefix
        DEFINE_GET_PREFIX_PARAMS orig_prefix_params, orig_prefix


.proc SaveSettings
        ;; ProDOS GP has the updated data, copy somewhere usable.
        COPY_STRUCT DateTime, DATELO, write_buffer

        ;; First time - ask if we should even try.
        CLEAR_BIT7_FLAG retry_flag

        ;; Write to desktop current prefix
        jsr     _DoWrite
        bcs     done            ; failed and canceled

        ;; Write to the original file location, if necessary
        jsr     JUMP_TABLE_GET_RAMCARD_FLAG
    IF ZC
        CALL    JUMP_TABLE_GET_ORIG_PREFIX, AX=#orig_prefix
        JUMP_TABLE_MLI_CALL GET_PREFIX, current_prefix_params
retry:
        JUMP_TABLE_MLI_CALL SET_PREFIX, orig_prefix_params
      IF CS
        jsr     _CheckRetry
        beq     retry
        sec                     ; failed
        rts
      END_IF
        jsr     _DoWrite
        JUMP_TABLE_MLI_CALL SET_PREFIX, current_prefix_params
        ;; Assert: Succeeded (otherwise RAMCard was deleted out from under us)
    END_IF
        clc

done:   rts
.endproc ; SaveSettings

.proc _DoWrite
    DO
        JUMP_TABLE_MLI_CALL OPEN, open_params
      IF CC
        lda     open_params::ref_num
        sta     set_mark_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        JUMP_TABLE_MLI_CALL SET_MARK, set_mark_params ; seek
        bcs     :+
        JUMP_TABLE_MLI_CALL WRITE, write_params
:       php                     ; preserve result
        JUMP_TABLE_MLI_CALL CLOSE, close_params
        ;; BUG: If write protected, this will leave the `io_buffer` in use!
        plp
      END_IF
      IF CS
        jsr     _CheckRetry
        REDO_IF EQ
        bne     failed          ; always
      END_IF
    DONE
        rts                     ; C=0

failed:
        sec
        rts                     ; C=1
.endproc ; _DoWrite

;;; Before calling: ensure `retry_flag` was cleared at some point.
;;; Input: A = ProDOS error code
;;; Output: Z = 1 if retry was selected
.proc _CheckRetry
    IF bit retry_flag : NC
        ;; First time - prompt see if we want to try saving.
        SET_BIT7_FLAG retry_flag
        CALL    JUMP_TABLE_SHOW_ALERT, A=#kErrSaveChanges ; OK/Cancel
        cmp     #kAlertResultOK
        rts                     ; Z=1 if OK selected (i.e. retry)
    END_IF

        ;; Special case
    IF A = #ERR_VOL_NOT_FOUND
        lda     #kErrInsertSystemDisk ; Try Again/Cancel
    END_IF
        jsr     JUMP_TABLE_SHOW_ALERT ; arbitrary ProDOS error
        ;; Responses are either OK or Try Again/Cancel
        cmp     #kAlertResultTryAgain
        rts
.endproc ; _CheckRetry

retry_flag:        .byte   0 ; bit7

.endscope ; save_date
SaveDate := save_date::SaveSettings

;;; ============================================================
;;; Setting the System Real-Time Clock
;;; ============================================================
;;; ProDOS only defines driver support for reading system clocks.
;;; Setting the date/time on the clock needs code specific to the
;;; clock hardware.
;;;
;;; This is handled here by pairs of routines that (1) probe for
;;; specific clock hardware, and (2) write the updated date/time to
;;; the clock hardware. The first routine often self-modifies the
;;; second with the results of probing, e.g. the specific slot I/O
;;; locations. The logic is split into two routines because we need to
;;; determine if we can update the clock before the UI is shown; if
;;; there is a system clock but we can't update it, then the UI is
;;; read-only.

;;; Output: C=0 if can set clock, C=1 otherwise
.proc CanSetClock
        jsr     IsIIgs          ; C=0 if IIgs
        bcc     ret

        jsr     DetectThunderClock ; C=0 if detected
        bcc     ret

        jsr     DetectNoSlotClockInSlotROM ; C=0 if detected
        bcc     ret

        jsr     DetectNoSlotClockInInternalROM ; C=0 if detected
        bcc     ret

        jsr     DetectROMXClock ; C=0 if detected
        bcc     ret

        jsr     DetectTheCricketClock ; C=0 if detected
        bcc     ret

        ;; Otherwise
        sec

ret:    rts
.endproc ; CanSetClock

;;; NOTE: This structure matches the No-Slot Clock since it is a
;;; superset of other clocks. Most clocks want BCD, so the conversion
;;; is done here.

.params DateToWrite
year:   .byte   0               ; BCD year (last two digits)
month:  .byte   0               ; BCD month (jan=1, dec=12)
day:    .byte   0               ; BCD day (1..31)
dow:    .byte   0               ; day of week (1=monday, 7=sunday)
hours:  .byte   0               ; BCD hours (0...23)
minutes:.byte   0               ; BCD minutes (0..59)
seconds:.byte   0               ; BCD seconds (0..59)
frac:   .byte   0               ; BCD fraction (0..99)
.endparams

;;; Input: ProDOS's `DATELO`...`TIMEHI` set to new time.
.proc MaybeSetClock
        ;; --------------------------------------------------
        ;; Compute date/time to write

        ;;       DATEHI           DATELO
        ;;  7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;; |    Year     |  Month  |   Day   |
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;;
        ;;       TIMEHI           TIMELO
        ;;  7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;; |0 0 0|  Hour   | |0 0|  Minute   |
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+


        lda     DATEHI
        lsr
        php                     ; save C
        sta     year
        jsr     _ToBCD
        sta     DateToWrite::year

        lda     DATELO
        plp                     ; restore C
        ror
        lsr
        lsr
        lsr
        lsr
        sta     month
        jsr     _ToBCD
        sta     DateToWrite::month

        lda     DATELO
        and     #%00011111
        sta     day
        jsr     _ToBCD
        sta     DateToWrite::day

        lda     TIMEHI
        and     #%00011111
        jsr     _ToBCD
        sta     DateToWrite::hours

        lda     TIMELO
        and     #%00111111
        jsr     _ToBCD
        sta     DateToWrite::minutes

        lda     #0
        sta     DateToWrite::seconds
        sta     DateToWrite::frac

        ;; Compute day of week
        lda     year
        ;; 0-39 is 2000-2039
        ;; Per Technical Note: ProDOS #28: ProDOS Dates -- 2000 and Beyond
    IF A < #40
        ;; Assert: C = 0
        adc     #100
    END_IF
        tay                     ; Y = year - 1900
        CALL    DayOfWeek, X=month, A=day
    IF A = #0
        lda     #7
    END_IF
        sta     DateToWrite::dow

        ;; --------------------------------------------------
        ;; Write to clock, if we know how

        jsr     IsIIgs          ; C=0 if IIgs
    IF CC
        TAIL_CALL SetIIgsClock
    END_IF

        jsr     DetectThunderClock ; C=0 if detected
    IF CC
        TAIL_CALL SetThunderClock
    END_IF

        jsr     DetectNoSlotClockInSlotROM ; C=0 if detected
    IF CC
        TAIL_CALL SetNoSlotClockInSlotROM
    END_IF

        jsr     DetectNoSlotClockInInternalROM ; C=0 if detected
    IF CC
        TAIL_CALL SetNoSlotClockInInternalROM
    END_IF

        jsr     DetectROMXClock ; C=0 if detected
    IF CC
        TAIL_CALL SetROMXClock
    END_IF

        jsr     DetectTheCricketClock ; C=0 if detected
    IF CC
        TAIL_CALL SetTheCricketClock
    END_IF

        rts

;;; Temporary non-BCD copy of values, for day-of-week calculation
day:    .byte   0
month:  .byte   0
year:   .byte   0

.proc _ToBCD
        ldx     #AS_BYTE(-1)
        sec
    DO
        inx
        sbc     #10
    WHILE CS
        adc     #10
        ;; Now X = tens, A = ones
        sta     lo
        txa
        asl
        asl
        asl
        asl
        lo := *+1
        ora     #SELF_MODIFIED_BYTE
        rts
.endproc ; _ToBCD

.endproc ; MaybeSetClock

;;; ============================================================

;;; No Slot Clock - Internal ROM and Slot ROM are handled by separate
;;; routines to minimize the complexity of self-modified code. Drivers
;;; typically merge these paths since space is critical.

.proc SetNoSlotClockInInternalROM

        C8ROM := $C800

        ;; --------------------------------------------------
        ;; Save CPU state, disable interrupts

        php
        sei

        ;; --------------------------------------------------
        ;; Configure card to enable ROM

        lda     PTRIG           ; Slow ZIP, IIc+ accelerator, etc
        lda     $C00B           ; Ultrawarp bug workaround c/o @bobbimanners
        lda     RDCXROM         ; save status of SLOTCXROM (high = enabled)
        pha
        sta     SETINTCXROM     ; read internal ROM
        lda     C8ROM+$04       ; TODO: What is this for???

        ;; --------------------------------------------------
        ;; Unlock the NSC by bit-banging.

        ldx     #8
    DO
        lda     NSCUnlockSequence-1,x
        sec                     ; set high bit, so we know when we're done
        ror     a               ; rotate out next offset
      DO
        pha
        lda     #0
        rol     a
        tay                     ; Y=offset (0 or 1)
        lda     C8ROM,y
        pla
        lsr     a               ; rotate out next offset
      WHILE NOT ZERO
    WHILE dex : NOT ZERO

        ;; --------------------------------------------------
        ;; Write 8 bytes * 8 bits of clock data by bit-banging

        ldx     #8
    DO
        lda     DateToWrite-1,x ; byte to write
        sec                     ; set high bit, so we know when we're done
        ror     a               ; rotate out next offset
      DO
        pha
        lda     #0
        rol     a
        tay                     ; Y=offset (0 or 1)
        lda     C8ROM,y
        pla
        lsr     a               ; rotate out next offset
      WHILE NOT ZERO
    WHILE dex : NOT ZERO

        ;; --------------------------------------------------
        ;; Restore MMU and CPU state

        pla
    IF NC
        sta     SETSLOTCXROM
    END_IF

        plp

        rts
.endproc ; SetNoSlotClockInInternalROM

.proc DetectNoSlotClockInInternalROM

        C8ROM := $C800

        ;; --------------------------------------------------
        ;; Save CPU state, disable interrupts

        php
        sei

        ;; --------------------------------------------------
        ;; Configure MMU to use internal ROM not slot ROM

        lda     PTRIG           ; Slow ZIP, IIc+ accelerator, etc
        lda     $C00B           ; Ultrawarp bug workaround c/o @bobbimanners
        lda     RDCXROM         ; save status of SLOTCXROM (high = enabled)
        pha
        sta     SETINTCXROM     ; read internal ROM
        lda     C8ROM+$04       ; TODO: What is this for???

        ;; --------------------------------------------------
        ;; Read reference sample of ROM data

        ldx     #8
    DO
        ldy     #8
      DO
        lda     C8ROM+$04
        ror     a
        ror     rom_buf-1,x
      WHILE dey : NOT ZERO
    WHILE dex : NOT ZERO

        ;; --------------------------------------------------
        ;; Unlock the NSC by bit-banging.

        ldx     #8
    DO
        lda     NSCUnlockSequence-1,x
        sec                     ; set high bit, so we know when we're done
        ror     a               ; rotate out next offset
      DO
        pha
        lda     #0
        rol     a
        tay                     ; Y=offset (0 or 1)
        lda     C8ROM,y
        pla
        lsr     a               ; rotate out next offset
      WHILE NOT ZERO
    WHILE dex : NOT ZERO

        ;; --------------------------------------------------
        ;; Read 8 bytes * 8 bits of (possible) clock data

        ldx     #8
    DO
        ldy     #8
      DO
        lda     C8ROM+$04
        ror     a
        ror     nsc_buf-1,x
      WHILE dey : NOT ZERO
    WHILE dex : NOT ZERO

        ;; --------------------------------------------------
        ;; Restore MMU and CPU state

        pla
    IF NC
        sta     SETSLOTCXROM
    END_IF

        plp

        ;; --------------------------------------------------
        ;; Check for a match

        ldx     #8
    DO
        lda     rom_buf-1,x
      IF A <> nsc_buf-1,x
        ;; differs, so NSC intercepted the read
        clc
        rts
      END_IF
    WHILE dex : NOT ZERO

        sec
        rts

.endproc ; DetectNoSlotClockInInternalROM

;;; ------------------------------------------------------------

.proc SetNoSlotClockInSlotROM

        SLOTnROM := $C000

        ;; --------------------------------------------------
        ;; Save CPU state, disable interrupts

        php
        sei

        ;; --------------------------------------------------
        ;; Configure card to enable ROM

        lda     PTRIG           ; Slow ZIP, IIc+ accelerator, etc
        lda     $C00B           ; Ultrawarp bug workaround c/o @bobbimanners
        lda     C8OFF
        pha
        slot_hi1 := *+2
        sta     SLOTnROM        ; Select slot ROM; self-modified ($Cn00)
        slot_hi2 := *+2
        lda     SLOTnROM+$04    ; TODO: What is this for???; self-modified ($Cn04)

        ;; --------------------------------------------------
        ;; Unlock the NSC by bit-banging.

        ldx     #8
    DO
        lda     NSCUnlockSequence-1,x
        sec                     ; set high bit, so we know when we're done
        ror     a               ; rotate out next offset
      DO
        pha
        lda     #0
        rol     a
        tay                     ; Y=offset (0 or 1)
        slot_hi3 := *+2
        lda     $C000,y         ; self-modified ($Cn00)
        pla
        lsr     a               ; rotate out next offset
      WHILE NOT ZERO
    WHILE dex : NOT ZERO

        ;; --------------------------------------------------
        ;; Write 8 bytes * 8 bits of clock data by bit-banging

        ldx     #8
    DO
        lda     DateToWrite-1,x ; byte to write
        sec                     ; set high bit, so we know when we're done
        ror     a               ; rotate out next offset
      DO
        pha
        lda     #0
        rol     a
        tay                     ; Y=offset (0 or 1)
        slot_hi4 := *+2
        lda     $C000,y         ; self-modified ($Cn00)
        pla
        lsr     a               ; rotate out next offset
      WHILE NOT ZERO
    WHILE dex : NOT ZERO

        ;; --------------------------------------------------
        ;; Restore MMU and CPU state

        pla
    IF NC
        sta     C8OFF
    END_IF

        plp

        rts

.endproc ; SetNoSlotClockInSlotROM

.proc DetectNoSlotClockInSlotROM

        SLOTnROM := $C000

        ;; Scan slot ROMs (including motherboard C3 firmware)
        lda     #$C7
        sta     slot_hi1
    DO
        lda     slot_hi1
        sta     slot_hi2
        sta     slot_hi3
        sta     slot_hi4
        sta     slot_hi5

        ;; Skip slots with no firmware ROM
        jsr     IsSlotPopulated ; A=$Cn
        jcc     next_slot       ; C=0 if not populated

        ;; Skip slots with a Z80, as probing would activate it
        copy8   #$00, $06
        copy8   slot_hi1, $07
        CALL    WithInterruptsDisabled, AX=#DetectZ80
        jcs     next_slot

        ;; --------------------------------------------------
        ;; Save CPU state, disable interrupts

        php
        sei

        ;; --------------------------------------------------
        ;; Configure card to enable ROM

        lda     PTRIG           ; Slow ZIP, IIc+ accelerator, etc
        lda     $C00B           ; Ultrawarp bug workaround c/o @bobbimanners
        lda     C8OFF
        pha
        slot_hi1 := *+2
        sta     SLOTnROM        ; Select slot ROM; self-modified ($Cn00)
        slot_hi2 := *+2
        lda     SLOTnROM+$04    ; TODO: What is this for???; self-modified ($Cn04)

        ;; --------------------------------------------------
        ;; Read reference sample of ROM data

        ldx     #8
      DO
        ldy     #8
       DO
        slot_hi3 := *+2         ; self-modified ($Cn04)
        lda     $C004
        ror     a
        ror     rom_buf-1,x
       WHILE dey : NOT ZERO
      WHILE dex : NOT ZERO

        ;; --------------------------------------------------
        ;; Unlock the NSC by bit-banging.

        ldx     #8
      DO
        lda     NSCUnlockSequence-1,x
        sec                     ; set high bit, so we know when we're done
        ror     a               ; rotate out next offset
       DO
        pha
        lda     #0
        rol     a
        tay                     ; Y=offset (0 or 1)
        slot_hi4 := *+2
        lda     $C000,y         ; self-modified ($Cn00)
        pla
        lsr     a               ; rotate out next offset
       WHILE NOT ZERO
      WHILE dex : NOT ZERO

        ;; --------------------------------------------------
        ;; Read 8 bytes * 8 bits of (possible) clock data

        ldx     #8
      DO
        ldy     #8
       DO
        slot_hi5 := *+2
        lda     SLOTnROM+$04    ; self-modified ($Cn04)
        ror     a
        ror     nsc_buf-1,x
       WHILE dey : NOT ZERO
      WHILE dex : NOT ZERO

        ;; --------------------------------------------------
        ;; Restore MMU and CPU state

        pla
      IF NC
        sta     C8OFF
      END_IF

        plp

        ;; --------------------------------------------------
        ;; Check for a match

        ldx     #8
      DO
        lda     rom_buf-1,x
       IF A <> nsc_buf-1,x
        ;; differs, so NSC intercepted the read
        lda     slot_hi1
        sta     SetNoSlotClockInSlotROM::slot_hi1
        sta     SetNoSlotClockInSlotROM::slot_hi2
        sta     SetNoSlotClockInSlotROM::slot_hi3
        sta     SetNoSlotClockInSlotROM::slot_hi4
        clc
        rts
       END_IF
      WHILE dex : NOT ZERO

next_slot:
        dec     slot_hi1
    WHILE lda slot_hi1 : A <> #$C0

        sec
        rts

.endproc ; DetectNoSlotClockInSlotROM

;;; ------------------------------------------------------------

rom_buf := $10
nsc_buf := $20

NSCUnlockSequence:
        .byte   $5C, $A3, $3A, $C5
        .byte   $5C, $A3, $3A, $C5

;;; ------------------------------------------------------------

.proc SetIIgsClock
.pushcpu
.p816
.a8
        lda     DateToWrite::month
        jsr     _FromBCD
        dec                     ; IIgs wants month 0..11
        pha
        lda     DateToWrite::day
        jsr     _FromBCD
        dec                     ; IIgs wants day 0..30
        pha
        lda     DateToWrite::year
        jsr     _FromBCD
        pha
        lda     DateToWrite::hours
        jsr     _FromBCD
        pha
        lda     DateToWrite::minutes
        jsr     _FromBCD
        pha
        lda     DateToWrite::seconds
        jsr     _FromBCD
        pha

.i16
        clc                     ; leave emulation mode
        xce
        rep     #$30

        ldx     #$0E03          ; `WriteTimeHex`
        jsl     $E10000         ; Toolbox Call

        sec                     ; re-enter emulation mode
        xce
        sep     #$30
        rts
.popcpu

.proc _FromBCD
        temp := $06

        ;; From https://6502.org/users/mycorner/6502/shorts/bcd2bin.html
        tax                             ; copy BCD value
        and     #$F0                    ; mask top nibble
        lsr     a                       ; /2 (/16*8)
        sta     temp                    ; save it
        lsr     a                       ; /4 (/16*4)
        lsr     a                       ; /8 (/16*2)
        adc     temp                    ; add /2 (carry always clear)
                                        ; ((n/16*8)+(n/16*2) = (n/16*10))
        sta     temp                    ; save it
        txa                             ; get original back
        and     #$0F                    ; mask low nibble
        adc     temp                    ; add shifted (carry always clear)

        rts
.endproc ; _FromBCD

.endproc ; SetIIgsClock

;;; ------------------------------------------------------------

.proc SetThunderClock
        CLOCK_WRT  := $C00B
        CLOCK_MODE := $05F8 - $C0 ; screen hole (+ `slot_hi`)

        ;; Prepare initialization sequence
        CALL    BCDToDigits, A=DateToWrite::month
        stx     seq + 1
        sta     seq + 2

        CALL    BCDToDigits, A=DateToWrite::dow
        sta     seq + 4

        CALL    BCDToDigits, A=DateToWrite::day
        stx     seq + 6
        sta     seq + 7

        CALL    BCDToDigits, A=DateToWrite::hours
        stx     seq + 9
        sta     seq + 10

        CALL    BCDToDigits, A=DateToWrite::minutes
        stx     seq + 12
        sta     seq + 13

        CALL    BCDToDigits, A=DateToWrite::seconds
        stx     seq + 15
        sta     seq + 16

        ;; Save current mode
        ldx     slot_hi
        lda     CLOCK_MODE,x
        pha

        ldx     #0
    DO
        lda     seq,x
        slot_hi := *+2
        jsr     CLOCK_WRT       ; self-modified
    WHILE inx : X < #kSeqLength

        ;; Restore mode
        pla
        ldx     slot_hi
        sta     CLOCK_MODE,x
        rts

seq:
        .byte   "!mm w dd HH MM SS\r"
        kSeqLength = * - seq

.endproc ; SetThunderClock

;;; Output: C=0 if found; `SetThunderClock` modified
.proc DetectThunderClock
        copy8   #$C7, slot_hi

    DO
        ;; Anything in the slot?
        CALL    IsSlotPopulated, A=slot_hi
        bcc     next_slot       ; C=0 if not populated

        ldx     #kSigLength
      DO
        ldy     sig_offsets - 1,x

        slot_hi := *+2
        lda     $C000,y
        cmp     sig_bytes - 1,x
        bne     next_slot
      WHILE dex : NOT ZERO

        ;; match!
        copy8   slot_hi, SetThunderClock::slot_hi
        clc
        rts

next_slot:
        dec     slot_hi
    WHILE lda slot_hi : A <> #$C0
        sec
        rts

kSigLength = 4
sig_offsets:    .byte   $00, $02, $04, $06
sig_bytes:      .byte   $08, $28, $58, $70
.endproc ; DetectThunderClock

;;; ------------------------------------------------------------

.proc SetTheCricketClock

;;; SSC I/O Registers (for Slot 2)
TDREG    := $C088 + $20         ; ACIA Transmit Register (write)
RDREG    := $C088 + $20         ; ACIA Receive Register (read)
STATUS   := $C089 + $20         ; ACIA Status/Reset Register
COMMAND  := $C08A + $20         ; ACIA Command Register (read/write)
CONTROL  := $C08B + $20         ; ACIA Control Register (read/write)

;;; Offsets into template strings below; here to avoid ca65 warnings.
kDOWOffset    = 3               ; Offset in `date_seq` for "MON" (etc)
kMonthOffset  = 7               ; Offset in `date_seq`
kDayOffset    = 10              ; Offset in `date_seq`
kYearOffset   = 13              ; Offset in `date_seq`
kHourOffset   = 3               ; Offset in `time_seq`
kMinuteOffset = 6               ; Offset in `time_seq`
kSecondOffset = 9               ; Offset in `time_seq`

        ;; Prepare strings
        ldx     DateToWrite::dow
        copy8   dow_table1-1,x, date_seq + kDOWOffset+0
        copy8   dow_table2-1,x, date_seq + kDOWOffset+1
        copy8   dow_table3-1,x, date_seq + kDOWOffset+2

        CALL BCDToDigits, A=DateToWrite::month
        stx     date_seq+kMonthOffset
        sta     date_seq+kMonthOffset+1

        CALL BCDToDigits, A=DateToWrite::day
        stx     date_seq+kDayOffset
        sta     date_seq+kDayOffset+1

        CALL BCDToDigits, A=DateToWrite::year
        stx     date_seq+kYearOffset
        sta     date_seq+kYearOffset+1

        CALL BCDToDigits, A=DateToWrite::hours
        stx     time_seq+kHourOffset
        sta     time_seq+kHourOffset+1

        CALL BCDToDigits, A=DateToWrite::minutes
        stx     time_seq+kMinuteOffset
        sta     time_seq+kMinuteOffset+1

        CALL BCDToDigits, A=DateToWrite::seconds
        stx     time_seq+kSecondOffset
        sta     time_seq+kSecondOffset+1

        ;; Disable interrupts
        php
        sei

        ;; Save ACIA state
        lda     COMMAND
        pha
        lda     CONTROL
        pha

        ;; Reset SSC
        sta     KBDSTRB         ; Port 2 DSR line connected to KBDSTRB
        lda     #0
        sta     COMMAND
        sta     CONTROL

        ;; Configure SSC
        lda     #%00001011      ; no parity/echo/interrupts, RTS low, DTR low
        sta     COMMAND
        lda     #%10011110      ; 9600 baud, 8 data bits, 2 stop bits
        sta     CONTROL

        ;; Clock Commands
        ldx     #0
    DO
        CALL    _SendByte, A=date_seq,x
    WHILE inx : A <> #CHAR_RETURN|$80

        ldx     #0
    DO
        CALL    _SendByte, A=time_seq,x
    WHILE inx : A <> #CHAR_RETURN|$80

        ;; Restore ACIA state
        pla
        sta     CONTROL
        pla
        sta     COMMAND

        ;; Restore interrupts
        plp

        rts

.proc _SendByte
        ora     #$80            ; The Cricket! requires high bit set
        pha
:       lda     STATUS
        and     #(1 << 4)       ; transmit register empty? (bit 4)
        beq     :-              ; nope, keep waiting
        pla
        sta     TDREG
        rts
.endproc ; _SendByte

;;; Templates for command sequences sent to The Cricket!
date_seq:       .byte   "SD WWW MM/DD/YY\r"
time_seq:       .byte   "ST HH:MM:SS\r"

;;; "MON", "TUE", etc., but in easily indexable form
dow_table1:     .byte   "MTWTFSS"
dow_table2:     .byte   "OUEHRAU"
dow_table3:     .byte   "NEDUITN"

.endproc ; SetTheCricketClock

.proc DetectTheCricketClock
        copy16  #$C200, $06
        CALL    WithInterruptsDisabled, AX=#DetectTheCricket ; returns C=1 if found
        ror
        eor     #$80            ; invert C
        rol
        rts
.endproc ; DetectTheCricketClock

;;; ------------------------------------------------------------

;;; https://jdmicro.com/documentation/romxce/ROMXce+%20API%20Reference.pdf

.proc SetROMXClock

kBufSize = 7
RTC_BUF := $2B0

REG_RTCSEC   = $00 ; bit 7=start oscillator, bit 6-4=SECTEN, bit 3-0=SECONE
REG_RTCMIN   = $01 ; bit 6-4=MINTEN, bit 3-0=MINONE
REG_RTCHOUR  = $02 ; bit 6=12/24 hour, bit 5-4=HRTEN, bit 3-0=HRONE
REG_RTCWKDAY = $03 ; bit 5=OSCRUN, bit 4=PWRFAIL, bit 3=VBATEN, bit 2-0=WKDAY
REG_RTCDATE  = $04 ; bit 5-4=DATETEN, bit 3-0=DATEONE
REG_RTCMTH   = $05 ; bit 5=LPYR, bit 4=MTHTEN, bit 3-0=MTHONE
REG_RTCYEAR  = $06 ; bit 7-4=YRTEN, bit 3-0=YRONE

ZipSlo        :=  $C0E0       ; ZIP CHIP slowdown

;;; ROMX locations
SEL_MBANK     :=  $F851       ; Select Main bank reg
Set_Clock     :=  $C803

        ;; Disable interrupts
        php
        sei

        ;; Preserve `RTC_BUF` contents
        ldx     #kBufSize-1
    DO
        lda     RTC_BUF,x
        pha
    WHILE dex : POS

        ;; Prepare new values in `RTC_BUF`
        lda     DateToWrite::seconds
        ora     #(1<<7)         ; bit 7 = 1 = oscillator enabled
        sta     RTC_BUF+REG_RTCSEC

        lda     DateToWrite::minutes
        sta     RTC_BUF+REG_RTCMIN

        lda     DateToWrite::hours
        sta     RTC_BUF+REG_RTCHOUR ; bit 6 = 0 = 24-hour mode enabled

        lda     DateToWrite::dow
        ora     #(1<<3)         ; bit 3 = 1 = external battery enabled
        sta     RTC_BUF+REG_RTCWKDAY

        lda     DateToWrite::day
        sta     RTC_BUF+REG_RTCDATE

        lda     DateToWrite::month
        sta     RTC_BUF+REG_RTCMTH

        lda     DateToWrite::year
        sta     RTC_BUF+REG_RTCYEAR

        ;; Unlock the ROMX and call firmware routine

        bit     ROMIN2          ; enable ROM

        bit     ZipSlo          ; disable ZIP
        bit     $FACA           ; enable ROMXe, temp bank 0
        bit     $FACA
        bit     $FAFE

        lda     RDCXROM         ; save status of SLOTCXROM
        pha
        sta     SETINTCXROM     ; turn on internal ROM

        jsr     Set_Clock

        pla
    IF NC
        sta     SETSLOTCXROM
    END_IF

        bit     SEL_MBANK       ; restore original bank (unconditionally)

        bit     LCBANK1         ; normal LC banking
        bit     LCBANK1

        ;; Restore `RTC_BUF` contents
        ldx     #0
    DO
        pla
        sta     RTC_BUF,x
    WHILE inx : X < #kBufSize

        ;; Restore interrupts
        plp

        rts

.endproc ; SetROMXClock

.proc DetectROMXClock
ZipSlo        :=  $C0E0       ; ZIP CHIP slowdown

;;; ROMX locations
FWReadClock   :=  $D8F0       ; Firmware clock driver routine
SigCk         :=  $DFFE       ; ROMX sig bytes
SEL_MBANK     :=  $F851       ; Select Main bank reg

        ;; Disable interrupts
        php
        sei

        ;; Try to detect ROMX and RTC
        bit     ROMIN2          ; enable ROM

        bit     ZipSlo          ; disable ZIP
        bit     $FACA           ; enable ROMXe, temp bank 0
        bit     $FACA
        bit     $FAFE

        lda     SigCk           ; Check for ROMX signature bytes
        cmp     #$4A
        bne     nope
        lda     SigCk+1
        cmp     #$CD
        bne     nope
        lda     FWReadClock     ; is RTC code there?
        cmp     #$AD
        bne     nope
        clc                     ; found clock!
        bcc     :+
nope:   sec                     ; not found
:

        bit     SEL_MBANK       ; restore original bank (unconditionally)

        bit     LCBANK1
        bit     LCBANK1

        ;; Restore interrupts
        rol                     ; stash C
        plp
        ror                     ; restore C

        rts

.endproc ; DetectROMXClock

;;; ============================================================

;;; Input: A = slot (low nibble)
;;; Output: C=1 if populated, C=0 otherwise
.proc IsSlotPopulated
        and     #%00001111      ; allow $Cn to be passed
        tax
        inx
        lda     SLTBYT
    DO
        lsr     a               ; bit N into C
    WHILE dex : NOT ZERO
        rts
.endproc ; IsSlotPopulated

;;; ============================================================

;;; Calls `IDROUTINE` with carry set; returns carry clear if
;;; IIgs. Assumes we're running with LCBank1 banked in, and
;;; restores that state afterwards.
;;; Output: C=0 if IIgs, C=1 otherwise
.proc IsIIgs
        bit     ROMIN2          ; Check ROM - is this a IIgs?
        CALL    IDROUTINE, C=1
        bit     LCBANK1
        bit     LCBANK1
        rts
.endproc ; IsIIgs

;;; ============================================================

;;; Input: A = BCD number
;;; Output: A = low digit, X = high digit ('0'-'9')

.proc BCDToDigits
        pha
        lsr
        lsr
        lsr
        lsr
        ora     #'0'
        tax

        pla
        and     #$0F
        ora     #'0'
        rts
.endproc ; BCDToDigits

;;; ============================================================

        .include "../lib/detect_z80.s"
        .include "../lib/detect_thecricket.s"
        .include "../lib/day_of_week.s"
        .include "../lib/save_settings.s"
        .include "../lib/with_interrupts_disabled.s"
        .assert * < write_buffer, error, .sprintf("DA too big (at $%X)", *)

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
