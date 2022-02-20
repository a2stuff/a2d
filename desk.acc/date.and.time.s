;;; ============================================================
;;; DATE.AND.TIME - Desk Accessory
;;;
;;; Shows the current ProDOS date/time, and allows editing if there
;;; is no clock driver installed.
;;; ============================================================

        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        .org DA_LOAD_ADDRESS

;;; ============================================================

        jmp     Copy2Aux


stash_stack:  .byte   $00

;;; ============================================================

.proc Copy2Aux

        start := start_da
        end   := last

        tsx
        stx     stash_stack

        lda     MACHID
        and     #%00000001      ; bit 0 = clock card
        sta     clock_flag

        copy16  #start, STARTLO
        copy16  #end, ENDLO
        copy16  #start, DESTINATIONLO
        sec
        jsr     AUXMOVE

        copy16  #start, XFERSTARTLO
        php
        pla
        ora     #$40            ; set overflow: aux zp/stack
        pha
        plp
        sec                     ; control main>aux
        jmp     XFER
.endproc

;;; ============================================================
;;; Maybe write the date into DESKTOP.SYSTEM file and exit the DA
;;; Inputs: A=1 if dialog committed; A=0 if dialog cancelled
;;; Assert: Running from Main

.proc SaveDateAndExit
        beq     skip

        ;; If there is a system clock, don't write out the date.
        ldx     clock_flag
        bne     skip

        ;; ProDOS GP has the updated data, copy somewhere usable.
        COPY_STRUCT DateTime, DATELO, write_buffer

        jsr     SaveSettings

skip:   ldx     stash_stack     ; exit the DA
        txs
        rts
.endproc

;;; ============================================================

filename:
        PASCAL_STRING kFilenameLauncher

filename_buffer:
        .res kPathBufferSize

        DEFINE_OPEN_PARAMS open_params, filename, DA_IO_BUFFER
        DEFINE_SET_MARK_PARAMS set_mark_params, kLauncherDateOffset
        DEFINE_WRITE_PARAMS write_params, write_buffer, sizeof_write_buffer
        DEFINE_CLOSE_PARAMS close_params

write_buffer:
        .res    .sizeof(DateTime), 0
        sizeof_write_buffer = * - write_buffer

.proc SaveSettings
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
.endproc

.proc AppendFilename
        ;; Append filename to buffer
        inc     filename_buffer ; Add '/' separator
        ldx     filename_buffer
        lda     #'/'
        sta     filename_buffer,x

        ldx     #0              ; Append filename
        ldy     filename_buffer
:       inx
        iny
        lda     filename,x
        sta     filename_buffer,y
        cpx     filename
        bne     :-
        sty     filename_buffer
        rts
.endproc

.proc DoWrite
        ;; First time - ask if we should even try.
        copy    #kErrSaveChanges, message

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
.endproc

;;; ============================================================
;;;
;;; Everything from here on is copied to Aux
;;;
;;; ============================================================

start_da:
        jmp     init_window

;;; ============================================================
;;; Param blocks

        kDialogWidth = 259
        kDialogHeight = 64

        ;; The following rects are iterated over to identify
        ;; a hit target for a click.

        kNumHitRects = 9
        kUpRectIndex = 3
        kDownRectIndex = 4

        kCancelButtonLeft = 16
        kOKButtonLeft = kDialogWidth - kButtonWidth - 16
        kOKCancelButtonTop = 46

        kFieldTop = 20
        kField1Left = 22
        kField2Left = kField1Left + 40
        kField3Left = kField2Left + 48
        kField4Left = kField3Left + 46
        kField5Left = kField4Left + 40
        kFieldDigitsWidth = 22
        kFieldMonthWidth = 30
        kFieldHeight = 10

        kUpDownButtonLeft = 233
        kUpDownButtonWidth = 10
        kUpDownButtonHeight = 10

        first_hit_rect := *
        DEFINE_RECT_SZ ok_button_rect, kOKButtonLeft, kOKCancelButtonTop, kButtonWidth, kButtonHeight
        DEFINE_RECT_SZ cancel_button_rect, kCancelButtonLeft, kOKCancelButtonTop, kButtonWidth, kButtonHeight
        DEFINE_RECT_SZ up_arrow_rect, kUpDownButtonLeft, 14, kUpDownButtonWidth, kUpDownButtonHeight
        DEFINE_RECT_SZ down_arrow_rect, kUpDownButtonLeft, 26, kUpDownButtonWidth, kUpDownButtonHeight
        DEFINE_RECT_SZ day_rect, kField1Left, kFieldTop, kFieldDigitsWidth, kFieldHeight
        DEFINE_RECT_SZ month_rect, kField2Left, kFieldTop, kFieldMonthWidth, kFieldHeight
        DEFINE_RECT_SZ year_rect, kField3Left, kFieldTop, kFieldDigitsWidth, kFieldHeight
        DEFINE_RECT_SZ hour_rect, kField4Left, kFieldTop, kFieldDigitsWidth, kFieldHeight
        DEFINE_RECT_SZ minute_rect, kField5Left, kFieldTop, kFieldDigitsWidth, kFieldHeight
        ASSERT_RECORD_TABLE_SIZE first_hit_rect, kNumHitRects, .sizeof(MGTK::Rect)

        DEFINE_POINT label_ok_pos, kOKButtonLeft + 5, kOKCancelButtonTop + 10
        DEFINE_POINT label_cancel_pos, kCancelButtonLeft + 5, kOKCancelButtonTop + 10
        DEFINE_POINT label_uparrow_pos, kUpDownButtonLeft + 2, 23
        DEFINE_POINT label_downarrow_pos, kUpDownButtonLeft + 2, 35
        DEFINE_POINT day_pos, kField1Left + 6, kFieldTop + 10
        DEFINE_POINT month_pos, kField2Left + 6, kFieldTop + 10
        DEFINE_POINT year_pos, kField3Left + 6, kFieldTop + 10
        DEFINE_POINT hour_pos, kField4Left + 6, kFieldTop + 10
        DEFINE_POINT minute_pos, kField5Left + 6, kFieldTop + 10

        DEFINE_POINT date_sep1_pos, kField2Left - 12, kFieldTop + 10
        DEFINE_POINT date_sep2_pos, kField3Left - 12, kFieldTop + 10
        DEFINE_POINT time_sep_pos,  kField5Left -  9, kFieldTop + 10

        DEFINE_RECT_SZ date_rect, 16, 15, 122, 20
        DEFINE_RECT_SZ time_rect, 150, 15, 74, 20

.params settextbg_params
backcolor:   .byte   0          ; black
.endparams

.params white_pattern
        .res    8, $FF
.endparams

selected_field:                 ; 1 = day, 2 = month, 3 = year, 4 = hour, 5 = minute, 0 = none (init)
        .byte   0

clock_flag:
        .byte   0

;;; Originally Feb 26, 1985 (the author date?); now updated by build.
day:    .byte   kBuildDD
month:  .byte   kBuildMM
year:   .byte   kBuildYY
hour:   .byte   0
minute: .byte   0

spaces_string:
        PASCAL_STRING "    "    ; do not localize

day_string:
        PASCAL_STRING "  "      ; do not localize

month_string:
        PASCAL_STRING "   "     ; do not localize

year_string:
        PASCAL_STRING "  "      ; do not localize

hour_string:
        PASCAL_STRING "  "      ; do not localize

minute_string:
        PASCAL_STRING "  "      ; do not localize

str_date_separator:
        PASCAL_STRING "/"       ; do not localize

str_time_separator:
        PASCAL_STRING ":"       ; do not localize

.params event_params
kind:  .byte   0

key       := *
modifiers := *+1

xcoord    := *
ycoord    := *+2
        .byte   0,0,0,0
.endparams
        ;; xcoord/ycoord are used to query...
.params findwindow_params
mousex    := *                  ; TODO: These are wrong; fix this union
mousey    := *+2
which_area:.byte   0
window_id: .byte   0
.endparams


        kDAWindowId = 100

.params screentowindow_params
window_id:     .byte   kDAWindowId
screen:
screenx:.word   0
screeny:.word   0
window:
windowx:.word   0
windowy:.word   0
.endparams

.params closewindow_params
window_id:     .byte   kDAWindowId
.endparams

penxor:         .byte   MGTK::penXOR
notpenxor:      .byte   MGTK::notpenXOR

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
mincontlength:  .word   100
maxcontwidth:   .word   500
maxcontlength:  .word   500
port:
        DEFINE_POINT viewloc, (kScreenWidth-kDialogWidth)/2, (kScreenHeight-kDialogHeight)/2
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT cliprect, 0, 0, kDialogWidth, kDialogHeight
pattern:        .res    8,$00
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

;;; ============================================================
;;; Initialize window, unpack the date.

init_window:
        ;; Read from ProDOS GP in Main
        sta     RAMRDOFF

        ;; If null date, just leave the baked in default
        lda     DATELO
        ora     DATEHI
        beq     :+

        ;; Crack the date bytes. Format is:
        ;; |    DATEHI   |      DATELO       |
        ;;  7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;; |    Year     |  Month  |   Day   |
        ;; +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
        ;;   |7 6 5 4 3 2 1 0 7 6 5 4 3 2 1 0|
        ;;   |    year     | month |  day    |

        lda     DATEHI
        lsr     a
        sta     year

        lda     DATELO
        and     #%11111
        sta     day

        lda     DATEHI
        ror     a
        lda     DATELO
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

        lda     TIMEHI
        and     #%00011111
        sta     hour

        lda     TIMELO
        and     #%00111111
        sta     minute

:       sta     RAMRDON

        MGTK_CALL MGTK::OpenWindow, winfo
        lda     #0
        sta     selected_field
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        ;; fall through

;;; ============================================================
;;; Input loop

.proc InputLoop
        jsr     YieldLoop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jsr     OnClick
        jmp     InputLoop

:       cmp     #MGTK::EventKind::key_down
        bne     InputLoop
        ;; fall through
.endproc

.proc OnKey
        lda     event_params::modifiers
        bne     InputLoop
        lda     event_params::key

        cmp     #CHAR_RETURN
        jeq     OnOk

        ;; If there is a system clock, only the first button is active
        ldx     clock_flag
        beq     :+
        cmp     #CHAR_ESCAPE    ; allow Escape to close as well
        bne     InputLoop
        jmp     OnOk

        ;; All controls are active
:       cmp     #CHAR_ESCAPE
        jeq     on_cancel
        cmp     #CHAR_LEFT
        beq     on_key_left
        cmp     #CHAR_RIGHT
        beq     on_key_right
        cmp     #CHAR_DOWN
        beq     OnKeyDown
        cmp     #CHAR_UP
        bne     InputLoop

on_key_up:
        MGTK_CALL MGTK::PaintRect, up_arrow_rect
        lda     #kUpRectIndex
        sta     hit_rect_index
        jsr     DoIncOrDec
        MGTK_CALL MGTK::PaintRect, up_arrow_rect
        jmp     InputLoop

OnKeyDown:
        MGTK_CALL MGTK::PaintRect, down_arrow_rect
        lda     #kDownRectIndex
        sta     hit_rect_index
        jsr     DoIncOrDec
        MGTK_CALL MGTK::PaintRect, down_arrow_rect
        jmp     InputLoop

on_key_left:
        sec
        lda     selected_field
        sbc     #1
        bne     update_selection
        lda     #5
        jmp     update_selection

on_key_right:
        clc
        lda     selected_field
        adc     #1
        cmp     #6
        bne     update_selection
        lda     #1
        ;; fall through

update_selection:
        jsr     HighlightSelectedField
        jmp     InputLoop
.endproc

.proc YieldLoop
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_YIELD_LOOP
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

.proc ClearUpdates
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_CLEAR_UPDATES
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

;;; ============================================================

.proc OnClick
        MGTK_CALL MGTK::FindWindow, event_params::xcoord
        MGTK_CALL MGTK::SetPenMode, penxor
        MGTK_CALL MGTK::SetPattern, white_pattern
        lda     findwindow_params::window_id
        cmp     #kDAWindowId
        bne     miss
        lda     findwindow_params::which_area
        bne     hit
miss:   rts

hit:    cmp     #MGTK::Area::content
        bne     miss
        jsr     FindHitTarget
        cpx     #0
        beq     miss
        txa
        sec
        sbc     #1
        asl     a
        tay
        copy16  hit_target_jump_table,y, jump+1
jump:   jmp     SELF_MODIFIED

hit_target_jump_table:
        .addr   OnOk, on_cancel, on_up, on_down
        .addr   on_field_click, on_field_click, on_field_click, on_field_click, on_field_click
.endproc

;;; ============================================================

.proc OnOk
        MGTK_CALL MGTK::PaintRect, ok_button_rect

        ;; Pack the date bytes and store in ProDOS GP
        sta     RAMWRTOFF

        lda     month
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        ora     day
        sta     DATELO
        lda     year
        rol     a
        sta     DATEHI

        lda     minute
        sta     TIMELO
        lda     hour
        sta     TIMEHI

        sta     RAMWRTON

        lda     #1
        sta     dialog_result
        jmp     Destroy
.endproc

on_cancel:
        MGTK_CALL MGTK::PaintRect, cancel_button_rect
        lda     #0
        sta     dialog_result
        jmp     Destroy

on_up:
        txa
        pha
        MGTK_CALL MGTK::PaintRect, up_arrow_rect
        pla
        tax
        jsr     OnUpOrDown
        rts

on_down:
        txa
        pha
        MGTK_CALL MGTK::PaintRect, down_arrow_rect
        pla
        tax
        jsr     OnUpOrDown
        rts

on_field_click:
        txa
        sec
        sbc     #4
        jmp     HighlightSelectedField

.proc OnUpOrDown
        stx     hit_rect_index
loop:   MGTK_CALL MGTK::GetEvent, event_params ; Repeat while mouse is down
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_up
        beq     :+
        jsr     DoIncOrDec
        jmp     loop

:       lda     hit_rect_index
        cmp     #kUpRectIndex
        beq     :+

        MGTK_CALL MGTK::PaintRect, down_arrow_rect
        rts

:       MGTK_CALL MGTK::PaintRect, up_arrow_rect
        rts
.endproc

.proc DoIncOrDec
        ptr := $6

        jsr     Delay

        lda     selected_field
        tax                     ; X = byte table offset
        asl     a
        tay                     ; Y = address table offset
        copy    min_table,x, min
        copy    max_table,x, max
        copy16  prepare_proc_table,y, prepare_proc
        copy16  field_table,y, ptr

        ldy     #0              ; Y = 0
        lda     (ptr),y
        tax                     ; X = value

        lda     hit_rect_index
        cmp     #kUpRectIndex
        beq     incr

decr:
        cpx     min
        bne     :+
        ldx     max
        inx
:       dex
        jmp     finish

incr:
        cpx     max
        bne     :+
        ldx     min
        dex
:       inx
        ;; fall through

finish:
        txa                     ; store new value
        sta     (ptr),y
        prepare_proc := *+1
        jsr     SELF_MODIFIED   ; update string
        MGTK_CALL MGTK::SetTextBG, settextbg_params
        jmp     DrawSelectedField

min:    .byte   0
max:    .byte   0
.endproc

hit_rect_index:
        .byte   0

;;; ============================================================

        kNumFields = 5

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

field_table:
        .addr   0, day, month, year, hour, minute
        ASSERT_ADDRESS_TABLE_SIZE field_table, kNumFields+1

min_table:
        .byte   0, kDayMin, kMonthMin, kYearMin, kHourMin, kMinuteMin
        ASSERT_TABLE_SIZE min_table, kNumFields+1

max_table:
        .byte   0, kDayMax, kMonthMax, kYearMax, kHourMax, kMinuteMax
        ASSERT_TABLE_SIZE max_table, kNumFields+1

prepare_proc_table:
        .addr   0, PrepareDayString, PrepareMonthString, PrepareYearString, PrepareHourString, PrepareMinuteString
        ASSERT_ADDRESS_TABLE_SIZE prepare_proc_table, kNumFields+1

;;; ============================================================

.proc PrepareDayString
        lda     day
        jsr     NumberToASCII
        sta     day_string+1    ; first char
        stx     day_string+2    ; second char
        rts
.endproc

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
loop:   lda     month_name_table,x
        sta     (ptr),y
        dex
        dey
        bpl     loop

        rts
.endproc

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

.proc PrepareYearString
        lda     year
        jsr     NumberToASCII
        sta     year_string+1
        stx     year_string+2
        rts
.endproc

.proc PrepareHourString
        lda     hour
        jsr     NumberToASCII
        sta     hour_string+1
        stx     hour_string+2
        rts
.endproc

.proc PrepareMinuteString
        lda     minute
        jsr     NumberToASCII
        sta     minute_string+1
        stx     minute_string+2
        rts
.endproc

;;; ============================================================
;;; Tear down the window and exit

;;; Used in Aux to store result during tear-down
dialog_result:  .byte   0

.proc Destroy
        MGTK_CALL MGTK::CloseWindow, closewindow_params
        jsr     ClearUpdates

        lda     dialog_result
        ;; Actual new date/time set in ProDOS GP

        ;; Back to Main
        sta     RAMWRTOFF
        sta     RAMRDOFF

        jmp     SaveDateAndExit
.endproc

;;; ============================================================
;;; Figure out which button was hit (if any).
;;; Index returned in X.

.proc FindHitTarget
        copy16  event_params::xcoord, screentowindow_params::screenx
        copy16  event_params::ycoord, screentowindow_params::screeny
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        ldx     #1
        copy16  #first_hit_rect, test_addr

loop:   txa
        pha
        MGTK_CALL MGTK::InRect, SELF_MODIFIED, test_addr
        bne     done

        ;; If there is a system clock, only the first button is active
        ldx     clock_flag
        beq     next
        pla
        ldx     #0
        rts


next:   clc
        lda     test_addr
        adc     #.sizeof(MGTK::Rect)
        sta     test_addr
        bcc     :+
        inc     test_addr+1
:       pla
        tax
        inx
        cpx     #kNumHitRects+1
        bne     loop

        ldx     #0
        rts

done:   pla
        tax
        rts
.endproc

;;; ============================================================
;;; Params for the display

pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY
        DEFINE_RECT_FRAME frame_rect, kDialogWidth, kDialogHeight

label_ok:
        PASCAL_STRING res_string_button_ok ; button label
label_cancel:
        PASCAL_STRING res_string_button_cancel ; button label
label_uparrow:
        PASCAL_STRING kGlyphUpArrow ; do not localize
label_downarrow:
        PASCAL_STRING kGlyphDownArrow ; do not localize

;;; ============================================================
;;; Render the window contents

.proc DrawWindow
        MGTK_CALL MGTK::SetPort, winfo::port
        MGTK_CALL MGTK::FrameRect, date_rect
        MGTK_CALL MGTK::FrameRect, time_rect

        MGTK_CALL MGTK::MoveTo, date_sep1_pos
        param_call DrawString, str_date_separator
        MGTK_CALL MGTK::MoveTo, date_sep2_pos
        param_call DrawString, str_date_separator
        MGTK_CALL MGTK::MoveTo, time_sep_pos
        param_call DrawString, str_time_separator

        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        MGTK_CALL MGTK::SetPenMode, notpenxor

        MGTK_CALL MGTK::FrameRect, ok_button_rect
        MGTK_CALL MGTK::MoveTo, label_ok_pos
        param_call DrawString, label_ok

        ;; If there is a system clock, only draw the OK button.
        ldx     clock_flag
        bne     :+

        MGTK_CALL MGTK::FrameRect, cancel_button_rect
        MGTK_CALL MGTK::MoveTo, label_cancel_pos
        param_call DrawString, label_cancel

        MGTK_CALL MGTK::MoveTo, label_uparrow_pos
        param_call DrawString, label_uparrow
        MGTK_CALL MGTK::FrameRect, up_arrow_rect

        MGTK_CALL MGTK::MoveTo, label_downarrow_pos
        param_call DrawString, label_downarrow
        MGTK_CALL MGTK::FrameRect, down_arrow_rect

:       jsr     PrepareDayString
        jsr     PrepareMonthString
        jsr     PrepareYearString
        jsr     PrepareHourString
        jsr     PrepareMinuteString

        jsr     DrawDay
        jsr     DrawMonth
        jsr     DrawYear
        jsr     DrawHour
        jsr     DrawMinute

        ;; If there is a system clock, don't draw the highlight.
        ldx     clock_flag
        beq     :+
        rts

:       MGTK_CALL MGTK::SetPenMode, penxor
        MGTK_CALL MGTK::SetPattern, white_pattern
        lda     #1
        jmp     HighlightSelectedField
.endproc

.proc DrawSelectedField
        lda     selected_field
        cmp     #1
        beq     DrawDay
        cmp     #2
        beq     DrawMonth
        cmp     #3
        beq     DrawYear
        cmp     #4
        beq     DrawHour
        bne     DrawMinute      ; always
.endproc

.proc DrawDay
        MGTK_CALL MGTK::MoveTo, day_pos
        param_call DrawString, day_string
        rts
.endproc

.proc DrawMonth
        MGTK_CALL MGTK::MoveTo, month_pos
        param_call DrawString, spaces_string ; variable width, so clear first
        MGTK_CALL MGTK::MoveTo, month_pos
        param_call DrawString, month_string
        rts
.endproc

.proc DrawYear
        MGTK_CALL MGTK::MoveTo, year_pos
        param_call DrawString, year_string
        rts
.endproc

.proc DrawHour
        MGTK_CALL MGTK::MoveTo, hour_pos
        param_call DrawString, hour_string
        rts
.endproc

.proc DrawMinute
        MGTK_CALL MGTK::MoveTo, minute_pos
        param_call DrawString, minute_string
        rts
.endproc

;;; ============================================================
;;; Highlight selected field
;;; Input: A = new field to select

.proc HighlightSelectedField
        pha
        lda     selected_field  ; initial state is 0, so nothing
        beq     update          ; to invert back to normal

        cmp     #1              ; day?
        bne     :+
        jsr     fill_day
        jmp     update

:       cmp     #2              ; month?
        bne     :+
        jsr     fill_month
        jmp     update

:       cmp     #3              ; year?
        bne     :+
        jsr     fill_year
        jmp     update

:       cmp     #4              ; hour?
        bne     :+
        jsr     fill_hour
        jmp     update

:       jsr     fill_minute     ; minute!

update: pla                     ; update selection
        sta     selected_field
        cmp     #1
        beq     fill_day
        cmp     #2
        beq     fill_month
        cmp     #3
        beq     fill_year
        cmp     #4
        beq     fill_hour
        bne     fill_minute     ; always

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

.endproc

;;; ============================================================
;;; Delay

.proc Delay
        lda     #255
        sec
loop1:  pha

loop2:  sbc     #1
        bne     loop2

        pla
        sbc     #1
        bne     loop1
        rts
.endproc

;;; ============================================================
;;; Convert number to two ASCII digits (in A, X)

.proc NumberToASCII
        ldy     #0
loop:   cmp     #10
        bcc     :+
        sec
        sbc     #10
        iny
        jmp     loop

:       ora     #'0'
        tax
        tya
        ora     #'0'
        rts
.endproc

;;; ============================================================

        .include "../lib/drawstring.s"

;;; ============================================================

last := *
