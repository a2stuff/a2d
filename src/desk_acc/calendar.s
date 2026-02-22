;;; ============================================================
;;; CALENDAR - Desk Accessory
;;;
;;; A simple month calendar
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "calendar.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../toolkits/btk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

kDayDX = 35
kDayDY = 13

kDAWindowId     = $80
kDAWidth        = kDayDX * 7
kDAHeight       = kDayDY * 8 - 2
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

str_title:
        PASCAL_STRING res_string_window_title

.params winfo
window_id:      .byte   kDAWindowId
options:        .byte   MGTK::Option::go_away_box
title:          .addr   str_title
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_none
hthumbmax:      .byte   32
hthumbpos:      .byte   0
vthumbmax:      .byte   32
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   kDAWidth
mincontheight:  .word   kDAHeight
maxcontwidth:   .word   kDAWidth
maxcontheight:  .word   kDAHeight
port:
        DEFINE_POINT viewloc, kDALeft, kDATop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDAWidth, kDAHeight
pattern:        .res    8, $00
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

;;; ============================================================

str_sun: PASCAL_STRING res_string_weekday_abbrev_1
str_mon: PASCAL_STRING res_string_weekday_abbrev_2
str_tue: PASCAL_STRING res_string_weekday_abbrev_3
str_wed: PASCAL_STRING res_string_weekday_abbrev_4
str_thu: PASCAL_STRING res_string_weekday_abbrev_5
str_fri: PASCAL_STRING res_string_weekday_abbrev_6
str_sat: PASCAL_STRING res_string_weekday_abbrev_7

day_str_table:
        .addr   str_sun, str_mon, str_tue, str_wed, str_thu, str_fri, str_sat
        ASSERT_ADDRESS_TABLE_SIZE day_str_table, 7

str_jan: PASCAL_STRING res_string_month_name_1
str_feb: PASCAL_STRING res_string_month_name_2
str_mar: PASCAL_STRING res_string_month_name_3
str_apr: PASCAL_STRING res_string_month_name_4
str_may: PASCAL_STRING res_string_month_name_5
str_jun: PASCAL_STRING res_string_month_name_6
str_jul: PASCAL_STRING res_string_month_name_7
str_aug: PASCAL_STRING res_string_month_name_8
str_sep: PASCAL_STRING res_string_month_name_9
str_oct: PASCAL_STRING res_string_month_name_10
str_nov: PASCAL_STRING res_string_month_name_11
str_dec: PASCAL_STRING res_string_month_name_12

month_str_table:
        .addr   str_jan, str_feb, str_mar, str_apr, str_may, str_jun
        .addr   str_jul, str_aug, str_sep, str_oct, str_nov, str_dec
        ASSERT_ADDRESS_TABLE_SIZE month_str_table, 12

month_len_table:
        .byte   31, 28, 31, 30, 31, 30
        .byte   31, 31, 30, 31, 30, 31
        ASSERT_TABLE_SIZE month_len_table, 12


        kDayXPos = 10
        kDayYPos = 23
        kDayXOff = kDayDX
        DEFINE_POINT pos_sun, kDayXPos + kDayXOff * 0, kDayYPos
        DEFINE_POINT pos_mon, kDayXPos + kDayXOff * 1, kDayYPos
        DEFINE_POINT pos_tue, kDayXPos + kDayXOff * 2, kDayYPos
        DEFINE_POINT pos_wed, kDayXPos + kDayXOff * 3, kDayYPos
        DEFINE_POINT pos_thu, kDayXPos + kDayXOff * 4, kDayYPos
        DEFINE_POINT pos_fri, kDayXPos + kDayXOff * 5, kDayYPos
        DEFINE_POINT pos_sat, kDayXPos + kDayXOff * 6, kDayYPos

day_pos_table:
        .addr   pos_sun, pos_mon, pos_tue, pos_wed, pos_thu, pos_fri, pos_sat
        ASSERT_ADDRESS_TABLE_SIZE day_pos_table, 7

        kGridXPos = 35
        kGridYPos = 25
        kGridDX = kDayDX
        kGridDY = kDayDY

grid_lines:
        DEFINE_POINT gl1a, 0,        kGridYPos + kGridDY * 0
        DEFINE_POINT gl1b, kDAWidth, kGridYPos + kGridDY * 0
        DEFINE_POINT gl2a, 0,        kGridYPos + kGridDY * 1
        DEFINE_POINT gl2b, kDAWidth, kGridYPos + kGridDY * 1
        DEFINE_POINT gl3a, 0,        kGridYPos + kGridDY * 2
        DEFINE_POINT gl3b, kDAWidth, kGridYPos + kGridDY * 2
        DEFINE_POINT gl4a, 0,        kGridYPos + kGridDY * 3
        DEFINE_POINT gl4b, kDAWidth, kGridYPos + kGridDY * 3
        DEFINE_POINT gl5a, 0,        kGridYPos + kGridDY * 4
        DEFINE_POINT gl5b, kDAWidth, kGridYPos + kGridDY * 4
        DEFINE_POINT gl6a, 0,        kGridYPos + kGridDY * 5
        DEFINE_POINT gl6b, kDAWidth, kGridYPos + kGridDY * 5

        DEFINE_POINT gl7a,  kGridXPos + kGridDX * 0, kGridYPos
        DEFINE_POINT gl7b,  kGridXPos + kGridDX * 0, kDAHeight
        DEFINE_POINT gl8a,  kGridXPos + kGridDX * 1, kGridYPos
        DEFINE_POINT gl8b,  kGridXPos + kGridDX * 1, kDAHeight
        DEFINE_POINT gl9a,  kGridXPos + kGridDX * 2, kGridYPos
        DEFINE_POINT gl9b,  kGridXPos + kGridDX * 2, kDAHeight
        DEFINE_POINT gl10a, kGridXPos + kGridDX * 3, kGridYPos
        DEFINE_POINT gl10b, kGridXPos + kGridDX * 3, kDAHeight
        DEFINE_POINT gl11a, kGridXPos + kGridDX * 4, kGridYPos
        DEFINE_POINT gl11b, kGridXPos + kGridDX * 4, kDAHeight
        DEFINE_POINT gl12a, kGridXPos + kGridDX * 5, kGridYPos
        DEFINE_POINT gl12b, kGridXPos + kGridDX * 5, kDAHeight
        kNumGridLines = 12

grid_pen:
        .byte   2, 1

        kArrowDX = 16
        kArrowDY = 10
        DEFINE_BUTTON left_button, kDAWindowId, kGlyphLeftArrow,, 40, 2, kArrowDX, kArrowDY
        DEFINE_BUTTON right_button, kDAWindowId, kGlyphRightArrow,, kDAWidth - kArrowDX - 40, 2, kArrowDX, kArrowDY

        DEFINE_RECT rect_month_year, kArrowDX+44, 0, kDAWidth-kArrowDX-44, 11

        DEFINE_POINT pos_month_year, SELF_MODIFIED, 11
str_space:
        PASCAL_STRING " "
str_year:
        PASCAL_STRING "0000"

        DEFINE_POINT date_base, 12, kGridYPos + 11
        DEFINE_POINT date_pos, 0, 0

str_date:
        PASCAL_STRING "   "


;;; ============================================================

        .include "../lib/event_params.s"

.params trackgoaway_params
clicked:        .byte   0
.endparams

.params getwinport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport
.endparams

grafport:       .tag    MGTK::GrafPort


;;; ============================================================
;;; Common Resources

;;; Copied from ProDOS
.params auxdt
DATELO: .byte   0
DATEHI: .byte   0
TIMELO: .byte   0
TIMEHI: .byte   0
.endparams

;;; Parsed
.params datetime
year:   .word   kBuildYYYY
month:  .byte   kBuildMM
day:    .byte   kBuildDD
hour:   .byte   0
minute: .byte   0
.endparams
        .assert .sizeof(datetime) = .sizeof(ParsedDateTime), error, "size mismatch"

first_dow:
        .byte   0

;;; ============================================================

.proc Init
        ;; Grab current ProDOS date/time
        copy16  #DATELO, STARTLO
        copy16  #DATELO+.sizeof(DateTime)-1, ENDLO
        copy16  #auxdt, DESTINATIONLO
        CALL    AUXMOVE, C=1    ; main>aux

        ;; If it is valid, parse it
        lda     auxdt::DATELO
        ora     auxdt::DATEHI
    IF NOT_ZERO
        copy16  #datetime, $A   ; populate this struct
        CALL    ParseDatetime, AX=#auxdt ; use current date
    END_IF

        ;; Load "first day of week" from settings
        CALL    ReadSetting, X=#DeskTopSettings::intl_first_dow
        sta     first_dow

        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        jeq     HandleDown
        cmp     #MGTK::EventKind::apple_key
        jeq     HandleDown
        cmp     #MGTK::EventKind::key_down
        beq     HandleKey

        jmp     InputLoop
.endproc ; InputLoop

.proc Exit
        MGTK_CALL MGTK::CloseWindow, winfo
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts
.endproc ; Exit

;;; ============================================================

.proc HandleKey
        lda     event_params::key
        cmp     #CHAR_LEFT
        jeq     DecDate
        cmp     #CHAR_UP
        jeq     DecDate
        cmp     #CHAR_RIGHT
        jeq     IncDate
        cmp     #CHAR_DOWN
        jeq     IncDate

        ldx     event_params::modifiers
    IF NOT_ZERO
        jsr     ToUpperCase
        cmp     #kShortcutCloseWindow
        beq     Exit
        bne     InputLoop       ; always
    END_IF

        cmp     #CHAR_ESCAPE
        beq     Exit
        bne     InputLoop       ; always
.endproc ; HandleKey

;;; ============================================================

.proc HandleDown
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     #kDAWindowId
        jne     InputLoop
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        jeq     HandleClose
        cmp     #MGTK::Area::dragbar
        jeq     HandleDrag
        cmp     #MGTK::Area::content
        jeq     HandleClick
        jmp     InputLoop
.endproc ; HandleDown

;;; ============================================================

.proc DecDate
        BTK_CALL BTK::Flash, left_button

        lda     BUTN0
        and     BUTN1
    IF NS
        sub16_8 datetime + ParsedDateTime::year, #10
        jmp     check
    END_IF

        lda     BUTN0
        ora     BUTN1
        bmi     year

        dec     datetime + ParsedDateTime::month
        bne     fin

        copy8   #12, datetime + ParsedDateTime::month
year:   dec16   datetime + ParsedDateTime::year
check:  cmp16   datetime + ParsedDateTime::year, #1901
        bcs     fin
        copy16  #2155, datetime + ParsedDateTime::year

fin:    jsr     UpdateWindow
        jmp     InputLoop
.endproc ; DecDate

.proc IncDate
        BTK_CALL BTK::Flash, right_button

        lda     BUTN0
        and     BUTN1
    IF NS
        add16_8 datetime + ParsedDateTime::year, #10
        jmp     check
    END_IF

        lda     BUTN0
        ora     BUTN1
        bmi     year

        inc     datetime + ParsedDateTime::month
        lda     datetime + ParsedDateTime::month
        cmp     #13
        bcc     fin

        copy8   #1, datetime + ParsedDateTime::month
year:   inc16   datetime + ParsedDateTime::year
check:  cmp16   datetime + ParsedDateTime::year, #2155
        bcc     fin
        copy16  #1901, datetime + ParsedDateTime::year

fin:    jsr     UpdateWindow
        jmp     InputLoop
.endproc ; IncDate

;;; ============================================================

.proc HandleClose
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        jne     Exit
        jmp     InputLoop
.endproc ; HandleClose

;;; ============================================================

.proc HandleDrag
        copy8   #kDAWindowId, dragwindow_params::window_id
        MGTK_CALL MGTK::DragWindow, dragwindow_params
common:
        bit     dragwindow_params::moved
    IF NS
        ;; Draw DeskTop's windows and icons.
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES

        ;; Draw DA's window
        jsr     DrawWindow
    END_IF

        jmp     InputLoop
.endproc ; HandleDrag


;;; ============================================================

.proc HandleClick
        copy8   #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        MGTK_CALL MGTK::InRect, left_button::rect
        jne     DecDate

        MGTK_CALL MGTK::InRect, right_button::rect
        jne     IncDate

        jmp     InputLoop
.endproc ; HandleClick

;;; ============================================================

pencopy:        .byte   MGTK::pencopy
notpencopy:     .byte   MGTK::notpencopy
notpenXOR:      .byte   MGTK::notpenXOR


;;; ============================================================

.proc PaintWindow
        ENTRY_POINTS_FOR_BIT7_FLAG draw, update, full_flag

        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        RTS_IF A = #MGTK::Error::window_obscured

        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        ;; --------------------------------------------------

        ;; Leap year adjustment (NOTE: only handles mod-4 rule, not mod-100 rule)
        lda     datetime + ParsedDateTime::year ; low byte
        and     #3              ; modulo 4
    IF ZERO
        lda     #29
    ELSE
        lda     #28
    END_IF
        sta     month_len_table+1

        ;; --------------------------------------------------
        ;; Draw month and year

        lda     datetime + ParsedDateTime::month
        asl
        tax
        copy16  month_str_table-2,x, ptr_str_month
        jsr     MakeYearString

        ;; Measure month + space + year width, to center
        copy16  #0, width
        CALL    MeasureString, AX=ptr_str_month
        addax   width
        CALL    MeasureString, AX=#str_space
        addax   width
        CALL    MeasureString, AX=#str_year
        addax   width
        sub16   #kDAWidth, width, pos_month_year::xcoord
        lsr16   pos_month_year::xcoord

        ;; Erase background if needed
        bit     full_flag
    IF NC
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::PaintRect, rect_month_year
    END_IF

        ;; Draw month + space + year
        MGTK_CALL MGTK::MoveTo, pos_month_year
        copy16  ptr_str_month, @addr
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr
        MGTK_CALL MGTK::DrawString, str_space
        MGTK_CALL MGTK::DrawString, str_year

        ;; --------------------------------------------------
        ;; Grid lines

        bit     full_flag
    IF NS
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::SetPenSize, grid_pen

        copy8   #kNumGridLines - 1, index
      DO
        lda     index
        asl                     ; *8 == .sizeof(MGTK::Point) * 2
        asl
        asl

        pha
        clc
        adc     #<grid_lines
        sta     pt_start
        lda     #0
        adc     #>grid_lines
        sta     pt_start+1

        pla
        clc
        adc     #<(grid_lines+.sizeof(MGTK::Point))
        sta     pt_end
        lda     #0
        adc     #>(grid_lines+.sizeof(MGTK::Point))
        sta     pt_end+1

        MGTK_CALL MGTK::MoveTo, SELF_MODIFIED, pt_start
        MGTK_CALL MGTK::LineTo, SELF_MODIFIED, pt_end

      WHILE dec index : POS
    END_IF

        ;; --------------------------------------------------
        ;; Day names

        bit full_flag
    IF NS
        copy8   #6, index
      DO
        lda     index
        asl
        tax
        copy16  day_pos_table,x, pos_addr
        MGTK_CALL MGTK::MoveTo, SELF_MODIFIED, pos_addr

        lda     index
        clc
        adc     first_dow
      IF A >= #7
        ;; C=1
        sbc     #7
      END_IF

        asl
        tax
        copy16  day_str_table,x, @addr
        MGTK_CALL MGTK::DrawString, SELF_MODIFIED, @addr

      WHILE dec index : POS
    END_IF

        ;; --------------------------------------------------
        ;; Date numbers

        ;; Find day-of-week for first day of month
        sub16   datetime + ParsedDateTime::year, #1900, tmp
        CALL    DayOfWeek, Y=tmp, X=datetime + ParsedDateTime::month, A=#1 ; Y,M,D; 0=sun
        sta     tmp

        ;; Start a few days earlier, to erase previous days
        lda     #1
        sec
        sbc     tmp
        clc
        adc     first_dow
    IF POS AND A >= #2
        ;; C=1
        sbc     #7
    END_IF
        sta     date

        ;; Find length of month
        ldx     datetime + ParsedDateTime::month
        copy8   month_len_table-1,x, mlen
        inc     mlen

        ;; Start in top-left of grid
        copy8   #0, col
        copy8   #0, row
        COPY_BLOCK date_base, date_pos

    DO
        ;; Assume it's an empty cell.
        copy8   #3, str_date
        lda     #' '
        sta     str_date+1
        sta     str_date+2

        ;; A valid day?
        lda     date
        beq     draw_date
        cmp     mlen
        bcs     draw_date

        ;; Create the string.
        copy8   #2, str_date
        copy8   #' ', str_date+1 ; assume 1 digit
        lda     date
        ldx     #0
      DO
        BREAK_IF A < #10
        sbc     #10
      WHILE inx : NOT_ZERO      ; always

        ora     #'0'            ; convert to digit
        sta     str_date+2      ; units place
        txa
      IF NOT_ZERO
        ora     #'0'            ; convert to digit
        sta     str_date+1      ; tens place
      END_IF

        ;; Draw it
draw_date:
        MGTK_CALL MGTK::MoveTo, date_pos
        MGTK_CALL MGTK::DrawString, str_date
        add16_8 date_pos::xcoord, #kDayDX

        ;; Next
        inc     col
        lda     col
      IF A = #7
        copy8   #0, col
        inc     row
        copy16  date_base::xcoord, date_pos
        add16_8 date_pos::ycoord, #kDayDY
      END_IF

        inc     date
        lda     date
    WHILE A <> #39              ; extra, to erase previous days

        ;; --------------------------------------------------
        ;; Left/right arrow buttons

        bit     full_flag
    IF NS
        BTK_CALL BTK::Draw, left_button
        BTK_CALL BTK::Draw, right_button
    END_IF

        ;; --------------------------------------------------
        ;; Finish up

        MGTK_CALL MGTK::ShowCursor
        rts

        ;; --------------------------------------------------

;;; High bit set if this is a full repaint
full_flag:
        .byte   0


;;; Variables for drawing month/year display
width:  .word   0
ptr_str_month:
        .addr   0

;;; Variables for drawing grid
index:  .byte   0

;;; Variables when drawing day numbers
tmp:    .word   0
dow:    .byte   5               ; day of week of 1st day of month (0=sun)

date:   .byte   0
mlen:   .byte   0               ; month length + 1
row:    .byte   0
col:    .byte   0               ; sun=0, etc
.endproc ; PaintWindow
DrawWindow := PaintWindow::draw
UpdateWindow := PaintWindow::update

;;; ============================================================
;;; Populates `str_year` from `datetime` (a `ParsedDateTime`)
;;; ASSERT: year between 1900 and 2155

.proc MakeYearString
        copy16  datetime+ParsedDateTime::year, tmp

        ldy     #1

        ldx     #AS_BYTE(-1)
    DO
        inx
        sub16   tmp, #1000, tmp
    WHILE CS
        add16   tmp, #1000, tmp
        txa
        ora     #'0'            ; convert to digit
        sta     str_year,y
        iny

        ldx     #AS_BYTE(-1)
    DO
        inx
        sub16   tmp, #100, tmp
    WHILE CS
        add16   tmp, #100, tmp
        txa
        ora     #'0'            ; convert to digit
        sta     str_year,y
        iny

        ldx     #AS_BYTE(-1)
    DO
        inx
        sub16   tmp, #10, tmp
    WHILE CS
        add16   tmp, #10, tmp
        txa
        ora     #'0'            ; convert to digit
        sta     str_year,y
        iny

        lda     tmp
        ora     #'0'            ; convert to digit
        sta     str_year,y
        rts

tmp:    .word   0
.endproc ; MakeYearString

;;; ============================================================

.proc MeasureString
        ptr := $06
        width := $08

        stax    ptr
        MGTK_CALL MGTK::StringWidth, ptr
        ldax    width
        rts
.endproc ; MeasureString

;;; ============================================================

        .include "../lib/uppercase.s"

        str_time := 0           ; unused
        .include "../lib/datetime.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT

        JSR_TO_AUX aux::Init
        rts

        DA_END_MAIN_SEGMENT

;;; ============================================================
