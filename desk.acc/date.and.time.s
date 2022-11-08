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
        .include "../common.inc"
        .include "../desktop/desktop.inc"

        MGTKEntry := MGTKAuxEntry
        BTKEntry := BTKAuxEntry

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
;;;          |             | |             |
;;;          | DA          | | DA (copy)   |
;;;   $800   +-------------+ +-------------+
;;;          :             : :             :
;;;
;;; ============================================================

        .org DA_LOAD_ADDRESS

;;; ============================================================

        jmp     Copy2Aux

stash_stack:  .byte   $00

;;; ============================================================

.proc Copy2Aux

        start := start_da
        end   := end_da

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
;;; Assert: Running from Main

.proc SaveAndExit
        bit     dialog_result
    IF_NS
        jsr     SaveDate
    END_IF

        bit     dialog_result
    IF_VS
        jsr     SaveSettings
    END_IF

        ldx     stash_stack     ; exit the DA
        txs
        rts
.endproc

;;; ============================================================

.proc save_date
filename:
        PASCAL_STRING kFilenameLauncher

filename_buffer:
        .res ::kPathBufferSize

        DEFINE_OPEN_PARAMS open_params, filename, DA_IO_BUFFER
        DEFINE_SET_MARK_PARAMS set_mark_params, kLauncherDateOffset
        DEFINE_WRITE_PARAMS write_params, write_buffer, sizeof_write_buffer
        DEFINE_CLOSE_PARAMS close_params

write_buffer:
        .res    .sizeof(DateTime), 0
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
.endproc ; save_date
SaveDate := save_date::SaveSettings

;;; ============================================================
;;;
;;; Everything from here on is copied to Aux
;;;
;;; ============================================================

start_da:
        jmp     init_window

;;; ============================================================
;;; Param blocks

        kDialogWidth = 287
        kDialogHeight = 75

        ;; The following rects are iterated over to identify
        ;; a hit target for a click.

        kNumHitRects = 8
        kUpRectIndex = 2
        kDownRectIndex = 3

        kControlMarginX = 16

        kFieldTop = 20
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
        DEFINE_RECT_SZ up_arrow_rect, kUpDownButtonLeft, 14, kUpDownButtonWidth, kUpDownButtonHeight
        DEFINE_RECT_SZ down_arrow_rect, kUpDownButtonLeft, 26, kUpDownButtonWidth, kUpDownButtonHeight
        DEFINE_RECT_SZ day_rect, kField1Left, kFieldTop, kFieldDigitsWidth, kFieldHeight
        DEFINE_RECT_SZ month_rect, kField2Left, kFieldTop, kFieldMonthWidth, kFieldHeight
        DEFINE_RECT_SZ year_rect, kField3Left, kFieldTop, kFieldDigitsWidth, kFieldHeight
        DEFINE_RECT_SZ hour_rect, kField4Left, kFieldTop, kFieldDigitsWidth, kFieldHeight
        DEFINE_RECT_SZ minute_rect, kField5Left, kFieldTop, kFieldDigitsWidth, kFieldHeight
        DEFINE_RECT_SZ period_rect, kField6Left, kFieldTop, kFieldDigitsWidth, kFieldHeight
        ASSERT_RECORD_TABLE_SIZE first_hit_rect, kNumHitRects, .sizeof(MGTK::Rect)

        DEFINE_POINT label_ok_pos, kOKButtonLeft + 5, kOKButtonTop + 10
        DEFINE_POINT label_uparrow_pos, kUpDownButtonLeft + 2, 23
        DEFINE_POINT label_downarrow_pos, kUpDownButtonLeft + 2, 35
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
        DEFINE_BUTTON ok_button_rec, kDAWindowId, res_string_button_ok, kGlyphReturn, kOKButtonLeft, kOKButtonTop
        DEFINE_BUTTON_PARAMS ok_button_params, ok_button_rec

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

str_date_separator:
        PASCAL_STRING "/"

str_time_separator:
        PASCAL_STRING ":"

        .include "../lib/event_params.s"

        kDAWindowId = 100

.params closewindow_params
window_id:     .byte   kDAWindowId
.endparams

penXOR:         .byte   MGTK::penXOR
notpencopy:     .byte   MGTK::notpencopy

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
        DEFINE_RECT maprect, 0, 0, kDialogWidth, kDialogHeight
pattern:        .res    8,$FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::notpencopy
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

;;; ============================================================
;;; 12/24 Hour Resources

;;; Padding between radio/checkbox and label
kLabelPadding = 5

kRadioButtonWidth       = 15
kRadioButtonHeight      = 7

.params rb_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   SELF_MODIFIED
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kRadioButtonWidth, kRadioButtonHeight
.endparams

checked_rb_bitmap:
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%1110001),PX(%1110001),PX(%1100000)
        .byte   PX(%1100111),PX(%1111100),PX(%1100000)
        .byte   PX(%1100111),PX(%1111100),PX(%1100000)
        .byte   PX(%1110001),PX(%1110001),PX(%1100000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)

unchecked_rb_bitmap:
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%1110000),PX(%0000001),PX(%1100000)
        .byte   PX(%1100000),PX(%0000000),PX(%1100000)
        .byte   PX(%1100000),PX(%0000000),PX(%1100000)
        .byte   PX(%1110000),PX(%0000001),PX(%1100000)
        .byte   PX(%0011100),PX(%0000111),PX(%0000000)
        .byte   PX(%0000111),PX(%1111100),PX(%0000000)

kOptionDisplayX = 30
kOptionDisplayY = 44

        DEFINE_LABEL clock_12hour, res_string_label_clock_12hour, kOptionDisplayX+60+kRadioButtonWidth+kLabelPadding-10, kOptionDisplayY+8
        DEFINE_LABEL clock_24hour, res_string_label_clock_24hour, kOptionDisplayX+120+kRadioButtonWidth+kLabelPadding, kOptionDisplayY+8
        ;; for hit testing; label width is added dynamically
        DEFINE_RECT_SZ rect_12hour, kOptionDisplayX+60-10, kOptionDisplayY, kRadioButtonWidth+kLabelPadding, kRadioButtonHeight
        DEFINE_RECT_SZ rect_24hour, kOptionDisplayX+120, kOptionDisplayY, kRadioButtonWidth+kLabelPadding, kRadioButtonHeight

.params date_bitmap_params
        DEFINE_POINT viewloc, 14, 40
mapbits:        .addr   date_bitmap
mapwidth:       .byte   6
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 39, 17
.endparams
date_bitmap:
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1000000),PX(%0000000),PX(%0000000)
        .byte   PX(%1100111),PX(%1111111),PX(%1111111),PX(%1111100),PX(%0000000),PX(%0000000)
        .byte   PX(%1100110),PX(%0000000),PX(%0000000),PX(%0001100),PX(%0000000),PX(%0000000)
        .byte   PX(%1100111),PX(%1111111),PX(%1111111),PX(%1111100),PX(%0000000),PX(%0000000)
        .byte   PX(%1100110),PX(%0000000),PX(%0000000),PX(%0001100),PX(%0001111),PX(%1111110)
        .byte   PX(%1100110),PX(%0001111),PX(%1111110),PX(%0001111),PX(%1110000),PX(%0000110)
        .byte   PX(%1100110),PX(%0011100),PX(%0000111),PX(%1111100),PX(%0000000),PX(%0000110)
        .byte   PX(%1100110),PX(%0011100),PX(%0000111),PX(%0000000),PX(%0111000),PX(%0000110)
        .byte   PX(%1100110),PX(%0000000),PX(%0011111),PX(%0000000),PX(%1111000),PX(%0000110)
        .byte   PX(%1100110),PX(%0000000),PX(%1111011),PX(%0000111),PX(%1111000),PX(%0000110)
        .byte   PX(%1100110),PX(%0000011),PX(%1100011),PX(%0000000),PX(%1111000),PX(%0000110)
        .byte   PX(%1100110),PX(%0001111),PX(%0000011),PX(%0000000),PX(%1111000),PX(%0000110)
        .byte   PX(%1100110),PX(%0011110),PX(%0000011),PX(%0000000),PX(%1111000),PX(%0000110)
        .byte   PX(%1100110),PX(%0011111),PX(%1111111),PX(%0000000),PX(%1111000),PX(%0000110)
        .byte   PX(%1111110),PX(%0000000),PX(%0000011),PX(%0000000),PX(%1111000),PX(%0000110)
        .byte   PX(%0000111),PX(%1111111),PX(%1111111),PX(%0000111),PX(%1111111),PX(%0000110)
        .byte   PX(%0000000),PX(%0000000),PX(%0000011),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%0000000),PX(%0000000),PX(%0000011),PX(%1111111),PX(%1111111),PX(%1111110)

.params time_bitmap_params
        DEFINE_POINT viewloc, kDialogWidth - 32 - 11, 39
mapbits:        .addr   time_bitmap
mapwidth:       .byte   5
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 31, 14
.endparams
time_bitmap:
        .byte   PX(%0000000),PX(%0001111),PX(%1111111),PX(%1000000),PX(%0000000)
        .byte   PX(%0000001),PX(%1110000),PX(%0000000),PX(%0111100),PX(%0000000)
        .byte   PX(%0000110),PX(%0000000),PX(%0110000),PX(%0000011),PX(%0000000)
        .byte   PX(%0011000),PX(%0000000),PX(%0110000),PX(%0000000),PX(%1100000)
        .byte   PX(%0110000),PX(%0000000),PX(%0110000),PX(%0000000),PX(%0110000)
        .byte   PX(%1100000),PX(%0000000),PX(%0110000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0110000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0110000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0001100),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000011),PX(%0000000),PX(%0011000)
        .byte   PX(%0110000),PX(%0000000),PX(%0000000),PX(%1100000),PX(%0110000)
        .byte   PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1100000)
        .byte   PX(%0000110),PX(%0000000),PX(%0000000),PX(%0000011),PX(%0000000)
        .byte   PX(%0000001),PX(%1110000),PX(%0000000),PX(%0111100),PX(%0000000)
        .byte   PX(%0000000),PX(%0001111),PX(%1111111),PX(%1000000),PX(%0000000)


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

        param_call MeasureString, clock_12hour_label_str
        addax   rect_12hour::x2
        param_call MeasureString, clock_24hour_label_str
        addax   rect_24hour::x2

        MGTK_CALL MGTK::OpenWindow, winfo
        lda     #0
        sta     selected_field
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop

;;; ============================================================
;;; Input loop

.proc InputLoop
        param_call JTRelay, JUMP_TABLE_YIELD_LOOP
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jsr     OnClick
        jmp     InputLoop

:       cmp     #MGTK::EventKind::key_down
        bne     InputLoop
        FALL_THROUGH_TO OnKey
.endproc

.proc OnKey
        MGTK_CALL MGTK::SetPort, winfo::port
        MGTK_CALL MGTK::SetPenMode, penXOR

        lda     event_params::modifiers
        bne     InputLoop
        lda     event_params::key

        cmp     #CHAR_RETURN
        jeq     OnKeyOk
        cmp     #CHAR_ESCAPE
        jeq     OnKeyOk

        ;; If there is a system clock, fields are read-only
        ldx     clock_flag
        bne     InputLoop

        ;; All controls are active
        cmp     #CHAR_LEFT
        beq     OnKeyLeft
        cmp     #CHAR_RIGHT
        beq     OnKeyRight
        cmp     #CHAR_DOWN
        beq     OnKeyDown
        cmp     #CHAR_UP
        bne     InputLoop
        FALL_THROUGH_TO OnKeyUp

.proc OnKeyUp
        MGTK_CALL MGTK::PaintRect, up_arrow_rect
        lda     #kUpRectIndex
        sta     hit_rect_index
        jsr     DoIncOrDec
        MGTK_CALL MGTK::PaintRect, up_arrow_rect
        jmp     InputLoop
.endproc

.proc OnKeyDown
        MGTK_CALL MGTK::PaintRect, down_arrow_rect
        lda     #kDownRectIndex
        sta     hit_rect_index
        jsr     DoIncOrDec
        MGTK_CALL MGTK::PaintRect, down_arrow_rect
        jmp     InputLoop
.endproc

.proc OnKeyLeft
        sec
        lda     selected_field
        sbc     #1
        bne     UpdateSelection
        bit     SETTINGS + DeskTopSettings::clock_24hours
    IF_NC
        lda     #Field::period
    ELSE
        lda     #Field::period-1
    END_IF
        jmp     UpdateSelection
.endproc

.proc OnKeyRight
        clc
        lda     selected_field
        adc     #1

        bit     SETTINGS + DeskTopSettings::clock_24hours
    IF_NC
        cmp     #Field::period+1
    ELSE
        cmp     #Field::period
    END_IF
        bne     UpdateSelection
        lda     #Field::day
        FALL_THROUGH_TO UpdateSelection
.endproc

.proc UpdateSelection
        jsr     SelectField
        jmp     InputLoop
.endproc
.endproc

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

        copy    #kDAWindowId, screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::window

        ;; ----------------------------------------

        MGTK_CALL MGTK::InRect, ok_button_rec::rect
        cmp     #MGTK::inrect_inside
        jeq     OnClickOk

        MGTK_CALL MGTK::InRect, rect_12hour
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #$00
        jmp     HandleOptionClick
        END_IF

        MGTK_CALL MGTK::InRect, rect_24hour
        cmp     #MGTK::inrect_inside
        IF_EQ
        lda     #$80
        jmp     HandleOptionClick
        END_IF

        ;; ----------------------------------------

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
        .addr   OnUp, OnDown
        .addr   OnFieldClick, OnFieldClick, OnFieldClick, OnFieldClick, OnFieldClick, OnFieldClick
        ASSERT_ADDRESS_TABLE_SIZE hit_target_jump_table, ::kNumHitRects
.endproc

;;; ============================================================

.proc OnClickOk
        BTK_CALL BTK::Track, ok_button_params
        beq     OnOk
        rts
.endproc

.proc OnKeyOk
        BTK_CALL BTK::Flash, ok_button_params
        FALL_THROUGH_TO OnOk
.endproc

.proc OnOk
        jsr     UpdateProDOS
        jmp     Destroy
.endproc

;;; ============================================================

.proc OnUp
        txa
        pha
        MGTK_CALL MGTK::PaintRect, up_arrow_rect
        pla
        tax
        jmp     OnUpOrDown
.endproc

.proc OnDown
        txa
        pha
        MGTK_CALL MGTK::PaintRect, down_arrow_rect
        pla
        tax
        jmp     OnUpOrDown
.endproc

.proc OnFieldClick
        txa
        sec
        sbc     #3
        jmp     SelectField
.endproc

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

        ;; Set day max, based on month/year.
        jsr     SetMonthLength

        ;; Hour requires special handling for 12-hour clock; patch the
        ;; min/max table depending on clock setting and period.
        bit     SETTINGS + DeskTopSettings::clock_24hours
    IF_NC
        lda     hour
        cmp     #12
      IF_LT
        copy    #kHourMin, min_table + Field::hour - 1
        copy    #11, max_table + Field::hour - 1
      ELSE
        copy    #12, min_table + Field::hour - 1
        copy    #kHourMax, max_table + Field::hour - 1
      END_IF
    ELSE
        copy    #kHourMin, min_table + Field::hour - 1
        copy    #kHourMax, max_table + Field::hour - 1
    END_IF

        lda     selected_field

        ;; Period also needs special handling
        cmp     #Field::period
        beq     TogglePeriod

        tax                     ; X = byte table offset
        asl     a
        tay                     ; Y = address table offset
        copy    min_table-1,x, min
        copy    max_table-1,x, max
        copy16  prepare_proc_table-2,y, prepare_proc
        copy16  field_table-2,y, ptr

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
        FALL_THROUGH_TO finish

finish:
        txa                     ; store new value
        sta     (ptr),y
        prepare_proc := *+1
        jsr     SELF_MODIFIED   ; update string
        lda     selected_field
        jsr     DrawField

        ;; If month changed, make sure day is in range and update if not.
        jsr     SetMonthLength
        lda     max_table+Field::day-1
        cmp     day
        bcs     :+
        sta     day
        MGTK_CALL MGTK::SetTextBG, settextbg_white_params
        jsr     PrepareDayString
        lda     #Field::day
        jsr     DrawField
:
        ;; Set dirty bit
        lda     #$80
        ora     dialog_result
        sta     dialog_result

        ;; Update ProDOS
        jmp     UpdateProDOS

min:    .byte   0
max:    .byte   0
.endproc

hit_rect_index:
        .byte   0

;;; ============================================================

.proc TogglePeriod
        ;; Flip to other period
        lda     hour
        cmp     #12             ; also sets C correctly for adc/sbc
    IF_LT
        adc     #12
    ELSE
        sbc     #12
    END_IF
        sta     hour

        lda     #Field::period
        jmp     DrawField
.endproc

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

str_am: PASCAL_STRING "AM"
str_pm: PASCAL_STRING "PM"

.proc PrepareYearString
        lda     year
        jsr     NumberToASCII
        sta     year_string+1
        stx     year_string+2
        rts
.endproc

.proc PrepareHourString
        lda     hour
        bit     SETTINGS + DeskTopSettings::clock_24hours
    IF_NC
        cmp     #0
        bne     :+
        lda     #12
:       cmp     #13
        bcc     :+
        sbc     #12
:
    END_IF

        jsr     NumberToASCII
        bit     SETTINGS + DeskTopSettings::clock_24hours
    IF_NC
        cmp     #'0'
        bne     :+
        lda     #' '
:
    END_IF
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
;;; bit7 = time changed
;;; bit6 = settings changed
dialog_result:  .byte   0

.proc Destroy
        MGTK_CALL MGTK::CloseWindow, closewindow_params
        param_call JTRelay, JUMP_TABLE_CLEAR_UPDATES

        lda     dialog_result
        ;; Actual new date/time set in ProDOS GP

        ;; Back to Main
        sta     RAMWRTOFF
        sta     RAMRDOFF

        sta     dialog_result

        jmp     SaveAndExit
.endproc

;;; ============================================================
;;; Figure out which button was hit (if any).
;;; Index returned in X.

.proc FindHitTarget
        ldx     #1
        copy16  #first_hit_rect, test_addr

loop:   txa
        pha
        MGTK_CALL MGTK::InRect, SELF_MODIFIED, test_addr
        bne     done

        ;; If there is a system clock, only the first button is active
        ldx     clock_flag
    IF_NE
        pla
        ldx     #0
        rts
    END_IF

        add16_8 test_addr, #.sizeof(MGTK::Rect)
        pla
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
        PASCAL_STRING kGlyphUpArrow
label_downarrow:
        PASCAL_STRING kGlyphDownArrow

;;; ============================================================
;;; Render the window contents

.proc DrawWindow
        MGTK_CALL MGTK::SetPort, winfo::port
        MGTK_CALL MGTK::FrameRect, date_rect
        MGTK_CALL MGTK::FrameRect, time_rect

        MGTK_CALL MGTK::PaintBits, date_bitmap_params
        MGTK_CALL MGTK::PaintBits, time_bitmap_params

        MGTK_CALL MGTK::MoveTo, date_sep1_pos
        param_call DrawString, str_date_separator
        MGTK_CALL MGTK::MoveTo, date_sep2_pos
        param_call DrawString, str_date_separator
        MGTK_CALL MGTK::MoveTo, time_sep_pos
        param_call DrawString, str_time_separator

        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        MGTK_CALL MGTK::SetPenMode, penXOR

        ;; If there is a system clock, only draw the OK button.
        ldx     clock_flag
    IF_EQ
        MGTK_CALL MGTK::MoveTo, label_uparrow_pos
        param_call DrawString, label_uparrow
        MGTK_CALL MGTK::FrameRect, up_arrow_rect

        MGTK_CALL MGTK::MoveTo, label_downarrow_pos
        param_call DrawString, label_downarrow
        MGTK_CALL MGTK::FrameRect, down_arrow_rect
    END_IF

        jsr     PrepareDayString
        jsr     PrepareMonthString
        jsr     PrepareYearString
        jsr     PrepareHourString
        jsr     PrepareMinuteString

        lda     #Field::day
        jsr     DrawField
        lda     #Field::month
        jsr     DrawField
        lda     #Field::year
        jsr     DrawField
        lda     #Field::hour
        jsr     DrawField
        lda     #Field::minute
        jsr     DrawField
        lda     #Field::period
        jsr     DrawField

        ;; If there is a system clock, don't draw the highlight.
        ldx     clock_flag
    IF_EQ
        lda     #Field::day
        jsr     SelectField
    END_IF

        ;; --------------------------------------------------

        MGTK_CALL MGTK::MoveTo, clock_12hour_label_pos
        param_call DrawString, clock_12hour_label_str
        MGTK_CALL MGTK::MoveTo, clock_24hour_label_pos
        param_call DrawString, clock_24hour_label_str

        BTK_CALL BTK::Draw, ok_button_params

        FALL_THROUGH_TO DrawOptionButtons
.endproc

.proc DrawOptionButtons
        MGTK_CALL MGTK::SetPenMode, notpencopy

        ldax    #rect_12hour
        ldy     SETTINGS + DeskTopSettings::clock_24hours
        cpy     #0
        jsr     DrawRadioButton

        ldax    #rect_24hour
        ldy     SETTINGS + DeskTopSettings::clock_24hours
        cpy     #$80
        jsr     DrawRadioButton

        rts
.endproc

;;; A = field
.proc DrawField
        pha
        cmp     selected_field
    IF_EQ
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
        param_jump DrawString, day_string
.endproc

.proc DrawMonth
        MGTK_CALL MGTK::MoveTo, month_pos
        param_call DrawString, spaces_string ; variable width, so clear first
        MGTK_CALL MGTK::MoveTo, month_pos
        param_jump DrawString, month_string
.endproc

.proc DrawYear
        MGTK_CALL MGTK::MoveTo, year_pos
        param_jump DrawString, year_string
.endproc

.proc DrawHour
        MGTK_CALL MGTK::MoveTo, hour_pos
        param_jump DrawString, hour_string
.endproc

.proc DrawMinute
        MGTK_CALL MGTK::MoveTo, minute_pos
        param_jump DrawString, minute_string
.endproc

.proc DrawPeriod
        MGTK_CALL MGTK::MoveTo, period_pos
        bit     SETTINGS + DeskTopSettings::clock_24hours
    IF_NS
        param_call DrawString, spaces_string
    ELSE
        lda     hour
        cmp     #12
      IF_LT
        param_jump DrawString, str_am
      ELSE
        param_jump DrawString, str_pm
      END_IF
    END_IF
        rts
.endproc
.endproc

;;; ============================================================
;;; Selected a field (dehighlight the old one, highlight the new one)
;;; Input: A = new field to select

.proc SelectField
        pha
        MGTK_CALL MGTK::SetPenMode, penXOR

        lda     selected_field  ; invert old
        jsr     invert
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
;;; Update the `max_table` for the max day given the month/year.

.proc SetMonthLength
        ;; Month lengths
        ldx     month
        ldy     month_length_table-1,x
        cpx     #2              ; February?
    IF_EQ
        lda     year            ; Handle leap years; interpreted as either
        and     #3              ; (1900+Y) or (Y<40 ? 2000+Y : 1900+Y) - which is
        bne     :+              ; correct for 1901 through 2199, so good enough.
        iny                     ;
:
    END_IF
        sty     max_table + Field::day - 1
        rts
.endproc

;;; ============================================================

.proc HandleOptionClick
        sta     SETTINGS + DeskTopSettings::clock_24hours
        MGTK_CALL MGTK::HideCursor
        jsr     DrawOptionButtons
        MGTK_CALL MGTK::ShowCursor

        ;; Set dirty bit
        lda     #$40
        ora     dialog_result
        sta     dialog_result

        lda     selected_field
        cmp     #Field::period
    IF_EQ
        lda     #Field::minute
        jsr     SelectField
    END_IF

        lda     #Field::period
        jsr     DrawField

        jsr     PrepareHourString
        lda     #Field::hour
        jsr     DrawField

        jmp     InputLoop
.endproc

;;; ============================================================

;;; A,X = pos ptr, Z = checked
.proc DrawRadioButton
        ptr := $06

        stax    ptr

    IF_EQ
        copy16  #checked_rb_bitmap, rb_params::mapbits
    ELSE
        copy16  #unchecked_rb_bitmap, rb_params::mapbits
    END_IF

        ldy     #3
:       lda     (ptr),y
        sta     rb_params::viewloc,y
        dey
        bpl     :-

        MGTK_CALL MGTK::PaintBits, rb_params
        rts
.endproc

;;; ============================================================
;;; Assert: Called from Aux

.proc UpdateProDOS
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
        rts
.endproc

;;; ============================================================
;;; Make call into Main from Aux (for JUMP_TABLE calls)
;;; Inputs: A,X = address

.proc JTRelay
        sta     RAMRDOFF
        sta     RAMWRTOFF
        stax    @addr
        @addr := *+1
        jsr     SELF_MODIFIED
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

;;; ============================================================

        .include "../lib/save_settings.s"
        .include "../lib/drawstring.s"
        .include "../lib/measurestring.s"

;;; ============================================================

end_da  := *
.assert * < write_buffer, error, .sprintf("DA too big (at $%X)", *)
.assert * < DA_IO_BUFFER, error, .sprintf("DA too big (at $%X)", *)

;;; ============================================================
