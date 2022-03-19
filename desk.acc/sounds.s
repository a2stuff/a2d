;;; ============================================================
;;; SOUNDS - Desk Accessory
;;;
;;; A control panel offering selecting different alert sounds.
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "sounds.res"

        .include "apple2.inc"
        .include "opcodes.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

        MGTKEntry := MGTKAuxEntry

;;; ============================================================

        .org DA_LOAD_ADDRESS

da_start:

;;; Copy the DA to AUX for easy bank switching
.scope
        copy16  #da_start, STARTLO
        copy16  #da_end, ENDLO
        copy16  #da_start, DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE
.endscope

.scope
        ;; run the DA
        sta     RAMRDON         ; Run from Aux
        sta     RAMWRTON
        jsr     Init

        ;; tear down/exit
        lda     dialog_result
        sta     RAMRDOFF        ; Back to Main
        sta     RAMWRTOFF

        ;; Save settings if dirty
        jmi     SaveSettings
        rts

.endscope

;;; ============================================================

filename:
        PASCAL_STRING kFilenameBellProc

filename_buffer:
        .res kPathBufferSize

;;; The space between `WINDOW_ENTRY_TABLES` and `DA_IO_BUFFER` is usable in
;;; Main memory only.
        write_buffer := WINDOW_ENTRY_TABLES
        .assert DA_IO_BUFFER - write_buffer >= kBellProcLength, error, "Not enough room"

        DEFINE_CREATE_PARAMS create_params, filename, ACCESS_DEFAULT, $F1
        DEFINE_OPEN_PARAMS open_params, filename, DA_IO_BUFFER
        DEFINE_WRITE_PARAMS write_params, write_buffer, kBellProcLength
        DEFINE_CLOSE_PARAMS close_params

.proc SaveSettings
        ;; Run from Main, but with LCBANK1 in

        ;; Copy from LCBANK to somewhere ProDOS can read.
        COPY_BYTES kBellProcLength, BELLDATA, write_buffer

        ;; Write to desktop current prefix
        ldax    #filename
        stax    create_params::pathname
        stax    open_params::pathname
        jsr     DoWrite
        bcs     done            ; failed and canceled

        ;; Write to the original file location, if necessary
        jsr     JUMP_TABLE_GET_RAMCARD_FLAG
        beq     done
        ldax    #filename_buffer
        stax    create_params::pathname
        stax    open_params::pathname
        jsr     JUMP_TABLE_GET_ORIG_PREFIX
        jsr     AppendFilename
        jsr     DoWrite

done:   rts

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
        ;; Create if necessary
        copy16  DATELO, create_params::create_date
        copy16  TIMELO, create_params::create_time
        JUMP_TABLE_MLI_CALL CREATE, create_params

        JUMP_TABLE_MLI_CALL OPEN, open_params
        bcs     error
        lda     open_params::ref_num
        sta     write_params::ref_num
        sta     close_params::ref_num
        JUMP_TABLE_MLI_CALL WRITE, write_params
        php                     ; preserve result
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

.endproc

;;; ============================================================

;;; High bit set when anything changes.
dialog_result:
        .byte   0

.proc MarkDirty
        lda     #$80
        ora     dialog_result
        sta     dialog_result
        rts
.endproc

;;; ============================================================
;;; Resources
;;; ============================================================

kDAWindowId     = 62
kDAWidth        = 300
kDAHeight       = 100
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

str_title:
        PASCAL_STRING res_string_window_title

pensize_normal: .byte   1, 1
pensize_frame:  .byte   kBorderDX, kBorderDY

penXOR:         .byte   MGTK::penXOR
pencopy:        .byte   MGTK::pencopy
penBIC:         .byte   MGTK::penBIC
notpencopy:     .byte   MGTK::notpencopy

.params winfo
window_id:      .byte   kDAWindowId
options:        .byte   MGTK::Option::dialog_box
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
mincontlength:  .word   kDAHeight
maxcontwidth:   .word   kDAWidth
maxcontlength:  .word   kDAHeight
port:
        DEFINE_POINT viewloc, kDALeft, kDATop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDAWidth, kDAHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

        DEFINE_RECT_FRAME frame_rect, kDAWidth, kDAHeight

;;; ============================================================

        kMarginX = 18
        kMarginY = 10
        kTextHeight = kSystemFontHeight
        kButtonMarginY = 6

        DEFINE_BUTTON ok, res_string_button_ok, kDAWidth - kMarginX - kButtonWidth, kDAHeight - kMarginY - kButtonHeight

        DEFINE_LABEL alert_sound, res_string_label_alert, kMarginX, kMarginY+kTextHeight
        kLabelWidth = 105

        kScrollBarWidth = 20
        kListItemHeight = 10     ; default text size + 1
        kListRows = 6
        kListLeft = kMarginX + kLabelWidth
        kListTop = kMarginY
        kListRight  = kDAWidth - kMarginX - kScrollBarWidth
        kListBottom = kListTop + kListItemHeight * kListRows - 1
        DEFINE_RECT listbox_rect, kListLeft, kListTop, kListRight, kListBottom


kMaxTop = kNumSounds - kListRows
kListBoxWindowId = kDAWindowId + 1

.params winfo_listbox
        kLeft =   kListLeft + kDALeft
        kTop =    kListTop + kDATop
        kWidth = kListRight - kListLeft
        kHeight = kListBottom - kListTop

window_id:      .byte   kListBoxWindowId
options:        .byte   MGTK::Option::dialog_box
title:          .addr   0
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_normal
hthumbmax:      .byte   0
hthumbpos:      .byte   0
vthumbmax:      .byte   kMaxTop
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   100
mincontlength:  .word   kHeight
maxcontwidth:   .word   100
maxcontlength:  .word   kHeight
port:
        DEFINE_POINT viewloc, kLeft, kTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
maprect:
        DEFINE_RECT cliprect, 0, 0, kWidth, kHeight
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textbg:         .byte   MGTK::textbg_white
fontptr:        .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

        kListItemTextOffsetX = kTextBoxTextHOffset
        kListItemTextOffsetY = kListItemHeight - 1
        DEFINE_POINT itempos, kListItemTextOffsetX, 0
        DEFINE_RECT itemrect, 0, 0, winfo_listbox::kWidth, 0

;;; Current item at the top of the list box
top_row:
        .byte   0

;;; ============================================================

str_buzz:       PASCAL_STRING "ProDOS Buzz"
str_bonk:       PASCAL_STRING "IIgs Bonk"
str_bell:       PASCAL_STRING "Control-G"
str_silent:     PASCAL_STRING "Silent"
str_awbeep:     PASCAL_STRING "Apple Writer II"
str_dazzledraw: PASCAL_STRING "Dazzle Draw"
str_koala:      PASCAL_STRING "Koala Illustrator"
str_816paint:   PASCAL_STRING "816/Paint"
str_aal_swoop:  PASCAL_STRING "Assembly Line Swoop"
str_aal_blast:  PASCAL_STRING "Assembly Line Laser"
str_aal_bell:   PASCAL_STRING "Assembly Line Bell"
str_aal_klaxon: PASCAL_STRING "Assembly Line Klaxon"
        kNumSounds = 12

name_table:
        .addr   str_buzz, str_bonk, str_bell, str_silent
        .addr   str_awbeep, str_dazzledraw, str_koala, str_816paint
        .addr   str_aal_swoop, str_aal_blast, str_aal_bell, str_aal_klaxon
        ASSERT_ADDRESS_TABLE_SIZE name_table, kNumSounds

proc_table:
        .addr   Buzz, Bonk, ClassicBeep, Silent
        .addr   AwBeep, DazzleDraw, Koala, Paint816
        .addr   AALLaserSwoop, AALLaserBlast, AALSCBell, AALKlaxon
        ASSERT_ADDRESS_TABLE_SIZE proc_table, kNumSounds

selected_index:
        .byte   $FF

;;; ============================================================

        .include "../lib/event_params.s"

.params winport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport
.endparams

.params grafport
        DEFINE_POINT viewloc, 0, 0
mapbits:        .word   0
mapwidth:       .byte   0
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, 0, 0
pattern:        .res    8, 0
colormasks:     .byte   0, 0
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   0
penheight:      .byte   0
penmode:        .byte   MGTK::pencopy
textback:       .byte   0
textfont:       .addr   0
.endparams

;;; ============================================================
;;; Dialog Logic
;;; ============================================================

.proc Init
        MGTK_CALL MGTK::OpenWindow, winfo
        MGTK_CALL MGTK::OpenWindow, winfo_listbox

        jsr     DrawWindow

        jsr     SearchForCurrent
        sta     selected_index
    IF_POS
        jsr     ScrollIntoView
        lda     selected_index
        jsr     HighlightIndex
    END_IF

        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc

.proc InputLoop
        jsr     YieldLoop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        jeq     HandleDown
        cmp     #MGTK::EventKind::key_down
        beq     HandleKey

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

.proc Exit
        MGTK_CALL MGTK::CloseWindow, winfo_listbox
        MGTK_CALL MGTK::CloseWindow, winfo
        jsr     ClearUpdates
        rts
.endproc

;;; ============================================================

.proc HandleKey
        lda     event_params::modifiers
        bne     modifiers

        ;; --------------------------------------------------
        ;; No modifiers

        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     Exit

        cmp     #CHAR_RETURN
        beq     Exit

        ;; Select previous
        cmp     #CHAR_UP
    IF_EQ
        ldx     selected_index
      IF_MINUS
        ldx     #kNumSounds-1
      ELSE
        jeq     InputLoop
        dex
      END_IF
        txa
        jmp     SetSelection
    END_IF

        ;; Select next
        cmp     #CHAR_DOWN
    IF_EQ
        ldx     selected_index
      IF_MINUS
        ldx     #0
      ELSE
        cpx     #kNumSounds-1
        jeq     InputLoop
        inx
      END_IF
        txa
        jmp     SetSelection
    END_IF

        jmp     InputLoop

        ;; --------------------------------------------------
        ;; Modifiers
modifiers:
        lda     event_params::key

        ;; Select first
        cmp     #CHAR_UP
    IF_EQ
        lda     #0
        jmp     SetSelection
    END_IF

        ;; Select last
        cmp     #CHAR_DOWN
    IF_EQ
        lda     #kNumSounds-1
        jmp     SetSelection
    END_IF

        jmp     InputLoop

.proc SetSelection
        pha
        lda     selected_index
        jsr     HighlightIndex
        pla
        sta     selected_index
        jsr     ScrollIntoView
        lda     selected_index
        jsr     HighlightIndex
        lda     selected_index
        jsr     PlayIndex
        jmp     InputLoop
.endproc

.endproc

;;; ============================================================

.proc HandleDown
        copy16  event_params::xcoord, findwindow_params::mousex
        copy16  event_params::ycoord, findwindow_params::mousey
        MGTK_CALL MGTK::FindWindow, findwindow_params
        jne     InputLoop       ; TODO: Standardize behavior here across DAs

        lda     findwindow_params::window_id
        cmp     winfo::window_id
    IF_EQ
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        beq     HandleClick
        jmp     InputLoop
    END_IF

        cmp     winfo_listbox::window_id
    IF_EQ
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        beq     HandleListClick
        jmp     InputLoop
    END_IF

        jmp     InputLoop
.endproc

;;; ============================================================

.proc HandleClick
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::windowx

        ;; ----------------------------------------

        lda     winfo::window_id
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::windowx

        MGTK_CALL MGTK::InRect, ok_button_rect
        cmp     #MGTK::inrect_inside
    IF_EQ
        copy    winfo::window_id, winport_params::window_id
        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport
        param_call ButtonEventLoop, kDAWindowId, ok_button_rect
        jeq     Exit
        jmp     InputLoop
    END_IF

        ;; ----------------------------------------

        jmp     InputLoop
.endproc

;;; ============================================================

.proc HandleListClick
        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        jeq     HandleScroll

        cmp     #MGTK::Ctl::not_a_control
        jne     InputLoop

        lda     winfo_listbox::window_id
        sta     screentowindow_params::window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_params::windowx

        add16   screentowindow_params::windowy, winfo_listbox::cliprect::y1, tmp
        ldax    tmp
        ldy     #kListItemHeight
        jsr     Divide_16_8_16
        jsr     SelectIndex
        jmp     InputLoop

tmp:    .word   0
.endproc

;;; ============================================================

.proc HandleScroll
        lda     findcontrol_params::which_part

        ;; scroll up by one line
        cmp     #MGTK::Part::up_arrow
    IF_EQ
        lda     top_row
        cmp     #0
        jeq     done

        dec     top_row
        bpl     update
    END_IF

        ;; scroll down by one line
        cmp     #MGTK::Part::down_arrow
    IF_EQ
        lda     top_row
        cmp     #kMaxTop
        jcs     done

        inc     top_row
        bpl     update
    END_IF

        ;; scroll up by one page
        cmp     #MGTK::Part::page_up
    IF_EQ
        lda     top_row
        cmp     #kListRows
        bcs     :+
        lda     #0
        beq     store
:       sec
        sbc     #kListRows
        jmp     store
    END_IF

        ;; scroll down by one page
        cmp     #MGTK::Part::page_down
    IF_EQ
        lda     top_row
        clc
        adc     #kListRows
        cmp     #kMaxTop
        bcc     store
        lda     #kMaxTop
        jmp     store
    END_IF

        cmp     #MGTK::Part::thumb
    IF_EQ
        copy16  event_params::xcoord, trackthumb_params::mousex
        copy16  event_params::ycoord, trackthumb_params::mousey
        MGTK_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_params::thumbmoved
        beq     done
        lda     trackthumb_params::thumbpos
        FALL_THROUGH_TO store
    END_IF

store:  sta     top_row

update: copy    top_row, updatethumb_params::thumbpos
        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params

        jsr     UpdateViewport
        jsr     DrawListEntries
        lda     selected_index
        jsr     HighlightIndex

done:   jmp     InputLoop
.endproc

;;; ============================================================

.proc ScrollIntoView
        cmp     top_row
    IF_LT
        sta     top_row
        sta     updatethumb_params::thumbpos
        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        jsr     UpdateViewport
        jmp     DrawListEntries
    END_IF

        sec
        sbc     #kListRows-1
        bmi     ret
        cmp     top_row
        beq     ret
    IF_GE
        sta     top_row
        sta     updatethumb_params::thumbpos
        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        jsr     UpdateViewport
        jmp     DrawListEntries
    END_IF

ret:    rts
.endproc

;;; ============================================================

;;; Assumes `top_row` is set.
.proc UpdateViewport
        ;; Compute height of line (font height + 1)
        ;; Update top of maprect: 1 + top_row * line_height
        copy16  #0, winfo_listbox::cliprect::y1
        ldax    #kListItemHeight
        ldy     top_row
        jsr     Multiply_16_8_16
        stax    winfo_listbox::cliprect::y1
        addax   #winfo_listbox::kHeight, winfo_listbox::cliprect::y2

        rts
.endproc

;;; ============================================================

.proc SelectIndex
        cmp     #kNumSounds
        bcs     ret

        pha
        lda     selected_index
        jsr     HighlightIndex
        pla
        pha
        sta     selected_index
        jsr     HighlightIndex
        pla

        jmp     PlayIndex
ret:    rts
.endproc

;;; ============================================================

.proc PlayIndex
        ptr := $06

        ;; Look up routine
        asl
        tax
        lda     proc_table,x
        pha
        sta     ptr
        lda     proc_table+1,x
        pha
        sta     ptr+1

        ;; Put routine into location
        jsr     Install
        jsr     Swap

        ;; Play it
        php
        sei
        proc := *+1
        jsr     BELLPROC
        plp

        ;; And restore the memory (and pointers, in case trashed)
        pla
        sta     ptr+1
        pla
        sta     ptr
        jsr     Swap

        jsr     MarkDirty
        rts

.proc Swap
        .assert kBellProcLength <= 128, error, "Can't BPL this loop"
        ldy     #kBellProcLength - 1
:       lda     (ptr),y
        pha
        lda     BELLPROC,y
        sta     (ptr),y
        pla
        sta     BELLPROC,y
        dey
        bpl     :-

        rts
.endproc

.proc Install
        .assert kBellProcLength <= 128, error, "Can't BPL this loop"
        ldy     #kBellProcLength - 1
:       lda     (ptr),y
        sta     BELLDATA,y
        dey
        bpl     :-

        rts
.endproc

.endproc

;;; ============================================================

;;; A = index to toggle highlight
.proc HighlightIndex
        bmi     ret

        ldx     #0
        ldy     #kListItemHeight
        jsr     Multiply_16_8_16
        stax    itemrect::y1
        addax   #kListItemHeight-1, itemrect::y2

        copy    #kListBoxWindowId, winport_params::window_id
        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, itemrect
ret:    rts
.endproc


;;; ============================================================

.proc DrawWindow

        ;; Dialog Box
        copy    #kDAWindowId, winport_params::window_id
        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport

        MGTK_CALL MGTK::SetPenSize, pensize_frame
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, frame_rect
        MGTK_CALL MGTK::SetPenSize, pensize_normal

        MGTK_CALL MGTK::MoveTo, alert_sound_label_pos
        param_call DrawString, alert_sound_label_str


        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, ok_button_rect
        MGTK_CALL MGTK::MoveTo, ok_button_pos
        param_call DrawString, ok_button_label

        ;; ============================================================
        ;; List Box

        jsr     DrawListEntries
        rts
.endproc

;;; ============================================================

.proc DrawListEntries
        copy    #kListBoxWindowId, winport_params::window_id
        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport

        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, winfo_listbox::maprect

        lda     #0
        sta     index

        index := *+1
loop:   lda     #SELF_MODIFIED_BYTE
        ldx     #0
        ldy     #kListItemHeight
        jsr     Multiply_16_8_16
        addax   #kListItemTextOffsetY, itempos::ycoord
        MGTK_CALL MGTK::MoveTo, itempos

        ptr := $06
        lda     index
        asl
        tax
        copy16  name_table,x, ptr
        param_call_indirect DrawString, ptr

        inc     index
        lda     index
        cmp     #kNumSounds
        bne     loop

        rts
.endproc

;;; ============================================================

.proc SearchForCurrent
        ldax    #BELLDATA
        ldy     #kChecksumLength
        jsr     CRC
        sta     crc_lo
        stx     crc_hi

        lda     #0
        sta     index

        index := *+1
loop:   lda     #SELF_MODIFIED_BYTE

        asl
        tay
        lda     proc_table,y
        ldx     proc_table+1,y
        ldy     #kChecksumLength
        jsr     CRC

        crc_lo := *+1
        cmp     #SELF_MODIFIED_BYTE
        bne     next
        crc_hi := *+1
        cpx     #SELF_MODIFIED_BYTE
        bne     next

        ;; Match!
        lda     index
        rts

next:   inc     index
        lda     index
        cmp     #kNumSounds
        bne     loop

        ;; Not Found
        lda     #$FF
        rts

.endproc


;;; ============================================================

;;; Inputs: A,X = address, Y = number of bytes (<=128)
.proc CRC
        stax    addr

        lda     #0
        sta     hi
        dey

        addr := *+1
:       eor     SELF_MODIFIED,y
        rol                     ; shift left 16
        rol     hi
        php                     ; but stash the high bit that
        ror                     ; was shifted out, and shift
        plp                     ; it back in as the new low bit
        rol

        dey
        bpl     :-

        hi := *+1
        ldx     #SELF_MODIFIED_BYTE
        rts
.endproc

;;; ============================================================
;;; Sound Routines
;;; ============================================================

;;; Wrappers for sound procs, which place the routine at the
;;; correct location and verify the length.

kChecksumLength = 16

.macro SOUND_PROC name
        .define __CURRENT_SOUND_PROC name
.proc name
        .pushorg ::BELLPROC
.endmacro

.macro END_SOUND_PROC
        .poporg
.endproc
        .assert .sizeof(__CURRENT_SOUND_PROC) <= kBellProcLength, error, "Sound proc too large"
        .assert .sizeof(__CURRENT_SOUND_PROC) >= kChecksumLength, error, "Sound proc too small"
        .undefine __CURRENT_SOUND_PROC
.endmacro

;;; ============================================================
;;; Sound Routine: ProDOS Buzz

Buzz := *
        .include "../lib/default_sound.s"

;;; ============================================================
;;; Sound Routine: Control-G

SOUND_PROC ClassicBeep
        ;; Based on Apple II Monitor ROMs

bell1:  lda     #$40
        jsr     wait
        ldy     #$C0
bell2:  lda     #$0C
        jsr     wait
        lda     SPKR
        dey
        bne     bell2
        rts

wait:   sec
wait2:  pha
wait3:  sbc     #1
        bne     wait3
        pla
        sbc     #1
        bne     wait2
        rts
END_SOUND_PROC


;;; ============================================================
;;; Sound Routine: IIgs "Bonk"

;;; https://groups.google.com/g/comp.sys.apple2/c/bhDLdYXnmnE/m/I2-OCScyZaAJ
SOUND_PROC Bonk

;;; **********************************************************
;;; *                                                        *
;;; *         "Bonk" sound routine for Apple II              *
;;; *                                                        *
;;; *       Copyright Michael J. Mahon, 12/08/2009           *
;;; *                                                        *
;;; *  Uses 21.3kHz PWM to synthesize a squarewave sound of  *
;;; *  diminishing volume, mimicing the "bonk" IIgs sound.   *
;;; *                                                        *
;;; *  The PWM pulses are generated in 46-cycle loops, with  *
;;; *  the high duty cycle pulses varying between 7 cycles   *
;;; *  and 37 cycles, and the low duty cycle pulses always   *
;;; *  7 cycles.                                             *
;;; *                                                        *
;;; *  Sound generaton begins at maximum duty cycle (volume) *
;;; *  and diminshes by 1/15 on each volume step, until the  *
;;; *  volume has been reduced to zero (equal high and low   *
;;; *  duty cycle half-periods).                             *
;;; *                                                        *
;;; *  Input parameters are:                                 *
;;; *   'hperiod'  = Half-period of tone in 46-cycle samples *
;;; *   'vperiods' = Tone (full) periods per volume step     *
;;; *                                                        *
;;; *  Since 15 volume steps are required to diminish the    *
;;; *  volume to zero, the total sound duration is 15 times  *
;;; *  'vperiods' cycles of the generated tone.              *
;;; *                                                        *
;;; **********************************************************

;;; * Page zero data

;;; hperiod  :=   $06    ; Half-period in samples (<129) (Inlined to save bytes)
vperiods :=   $07        ; Periods until vol step
vctr     :=   $08        ; Volume step counter

;;; * Hardware definitions

SPKR     :=   $C030      ; Apple II speaker toggle

;;; Added to initialize ZP addr
        kHPeriod  = 83
        kVPeriods = 2

        lda     #kVPeriods
        sta     vperiods

;;; * Initialize

BONK:     lda   #15        ; Init to 15 steps
          sta   vctr       ;  of dimishing volume.
          lda   #0         ; Init modified branches.
          sta   vinc+1
          lda   #(hiduty-vdec-2)&$ff ; Point to hiduty
          sta   vdec+1
          ldy   #kHPeriod  ; Samples in half-period
          dey              ;  minus 1.
          tya              ; Save half-period count.
          ldx   vperiods   ; Countdown to volume step.

;;; * Generate high duty-cycle half of squarewave

          nop              ; String of NOPs is target
          nop              ;  of varying 'vdec' branch.
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
hidutym2:       nop
hiduty: sta   SPKR       ; Toggle speaker hi
vinc:   bpl   *+2        ; <modified: 0..15> (always)
          nop              ; String of NOPs is target
          nop              ;  of varying 'vinc' branch.
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          nop
          sta   SPKR       ; Toggle speaker lo
          dey              ; Count down half-period
vdec:   bpl   hiduty     ; <modified>

;;; * Generate first low duty-cycle half cycle of squarewave

          sta   SPKR       ; Toggle speaker hi
          bpl   *+2        ; (always)
          sta   SPKR       ; Toggle speaker lo
          dex              ; Time to dec volume?
          bne   dnostep    ; -No, delay then rejoin.
          dec   vctr       ; -Yes, volume = zero?
          beq   ret        ; -Yes, return.
          dec   vdec+1     ; -No, decrease duty
          inc   vinc+1     ;       cycle (volume).
          ldx   vperiods   ; Reload vol step counter
nostep:   tay              ; Reload half-period ctr
          bne   lodutym4   ; >0, gen more low pulses.
          beq   hidutym2   ; (always)

lodutym6:       nop              ; Kill 2 cycles
lodutym4:       nop              ; Kill 2 cycles
          nop              ; Kill 2 cycles
          sta   SPKR       ; Toggle speaker hi
          bpl   *+2        ; (always)
          sta   SPKR       ; Toggle speaker lo
          jsr   ret        ; Kill 12
          jsr   ret        ; Kill 12
          dey              ; Half-period expired?
          bpl   lodutym6   ; -No, keep looping.
          tay              ; -Yes, reset for hi loop
          bpl   hidutym2   ; (always)

dnostep:        jsr   ret        ; Kill 18 cycles
          nop
          nop
          nop
          bne   nostep     ;  and rejoin...

ret:    rts

END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: DazzleDraw's alert sound

SOUND_PROC DazzleDraw
        ldy     #$20
:       lda     #$1C
        sta     SPKR
        jsr     L9843
        dey
        bne     :-
        rts

L9843:
        sec
        pha
:       sbc     #$01
        bne     :-
        pla
        sbc     #$01
        bne     L9843
        rts
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: Apple Writer ]['s alert sound

SOUND_PROC AwBeep
        lda     #$80            ; STRAIGHT FROM APPLE WRITER ][
        jsr     beep1           ; (CANNIBALISM IS THE SINCEREST
        lda     #$a0            ; FORM OF FLATTERY)
beep1:  ldy     #$80
beep2:  tax
beep3:  dex
        bne     beep3
        bit     $c030           ; WHAP SPEAKER
        dey
        bne     beep2
nobeep: rts
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: Koala Illustrator's alert sound

SOUND_PROC Koala
        ;; From Koala Illustrator
        ;; $63B2

        ldy     #$60
        bne     L63BD
        ldy     #$08
        lda     L634F
        beq     L63C9
L63BD:  tya
        jsr     L63CA
        eor     #$FF
        jsr     L63CA
        dey
        bne     L63BD
        rts

L63CA:  tax
L63CB:  dex
        bne     L63CB
        bit     SPKR
L63C9:  rts

L634F:  .byte   $FF

END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: 816/Paint's alert sound

SOUND_PROC Paint816
        ;; $E5F6
        ldy     #$40
        ldx     #$15
        jsr     LE601
        ldy     #$30
        ldx     #$1A

LE601:  php
        sei
LE603:  txa
        jsr     LE612
        bit     SPKR
        dey
        bne     LE603
        plp
        rts

LE612:  sec
LE613:  pha
LE614:  sbc     #$01
        bne     LE614
        pla
        sbc     #$01
        bne     LE613
        rts
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: Laser Swoop from Apple Assembly Line

;;; http://www.txbobsc.com/aal/1981/aal8102.html#a1
SOUND_PROC AALLaserSwoop
;;; ---------------------------------
SPEAKER     := $C030
;;; ---------------------------------
PULSE_COUNT := $00
PULSE_WIDTH := $01
SWOOP_COUNT := $02
;;; ---------------------------------
SWOOP:  LDA #1                  ; ONE PULSE AT EACH WIDTH
        STA PULSE_COUNT
        LDA #160                ; START WITH MAXIMUM WIDTH
;;; (ALSO TRY VALUES OF 40, 80, 128, AND 160.)
        STA PULSE_WIDTH
@l1:    LDY PULSE_COUNT
@l2:    LDA SPEAKER             ; TOGGLE SPEAKER
        LDX PULSE_WIDTH
@l3:    DEX                     ; DELAY LOOP FOR ONE PULSE
        BNE @l3
        DEY                     ; LOOP FOR NUMBER OF PULSES
        BNE @l2                 ; AT EACH PULSE WIDTH
        DEC PULSE_WIDTH         ; SHRINK PULSE WIDTH
        BNE @l1                 ; TO LIMIT OF ZERO
        RTS
;;; ---------------------------------
;;; MULTI-SWOOPER
;;; ---------------------------------
SWOOP2: LDA #10                 ; NUMBER OF SWOOPS
        STA SWOOP_COUNT
@l1:    JSR SWOOP
        DEC SWOOP_COUNT
        BNE @l1
        RTS
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: Laser Blast from Apple Assembly Line

;;; http://www.txbobsc.com/aal/1981/aal8102.html#a1
SOUND_PROC AALLaserBlast
;;; ---------------------------------
;;;       ANOTHER LASER BLAST
;;; ---------------------------------
SPEAKER     := $C030
;;; ---------------------------------
BLAST:  LDY #4                  ; NUMBER OF SHOTS (NB: was 10 in original)
@l1:    LDX #64                 ; PULSE WIDTH OF FIRST PULSE
@l2:    TXA                     ; START A PULSE WITHIN A SHOT
@l3:    DEX                     ; DELAY FOR ONE PULSE
        BNE @l3
        TAX
        LDA SPEAKER             ; TOGGLE SPEAKER
        INX
        CPX #192                ; PULSE WIDTH OF LAST PULSE
        BNE @l2
        DEY                     ; FINISHED SHOOTING?
        BNE @l1                 ; NO
        RTS
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: "My Own Little Bell" from Apple Assembly Line

;;; https://www.txbobsc.com/aal/1982/aal8206.html#a7
SOUND_PROC AALSCBell
;;; ---------------------------------
;;; MY OWN LITTLE BELL
;;; --------------------------------
SPEAKER := $C030
;;; --------------------------------
SC_BELL:
        LDX #50
@l1:    LDA #14
        JSR MON_DELAY
        LDA SPEAKER
        LDA #10
        JSR MON_DELAY
        LDA SPEAKER
        LDA #6
        JSR MON_DELAY
        LDA SPEAKER
        DEX
        BNE @l1
        RTS

MON_DELAY:
wait:           sec
wait2:          pha
wait3:          sbc     #1
        bne     wait3
        pla
        sbc     #1
        bne     wait2
        rts
END_SOUND_PROC

;;; ============================================================
;;; Sound Routine: Klaxon from Apple Assembly Line

;;; https://www.txbobsc.com/aal/1988/aal8805.html#a3
SOUND_PROC AALKlaxon
;;; --------------------------------
;;;    from Robert C. Moore, Laurel, Maryland.
;;; --------------------------------
DURATION1  := 0
DURATION2  := 1
PITCH      := 2
;;; --------------------------------
SPEAKER    := $C030
;;; --------------------------------
BOBSC: JSR KLAXON
KLAXON:LDY #50      ; FIRST PRIMARY PITCH
       JSR SOUNDS
       LDY #80      ; SECOND PRIMARY PITCH
;;; --------------------------------
SOUNDS:
       STY PITCH    ; SAVE CALLER'S Y-PITCH
       LDA #20      ; LENGTH OF SOUND
       STA DURATION1
       LDX #63      ; SECONDARY PITCH
;;; --------------------------------
@l2:   DEX          ; COUNT DOWN SECONDARY CYCLE
       BNE @l3       ; ...NOT TIME FOR CLICK YET
       BIT SPEAKER  ; ...CLICK NOW
       LDX #63      ; START ANOTHER CYCLE
;;; --------------------------------
@l3:   DEY          ; COUNT DOWN PRIMARY CYCLE
       BNE @l4       ; ...NOT TIME FOR CLICK YET
       BIT SPEAKER  ; ...CLICK NOW
       LDY PITCH    ; START ANOTHER CYCLE
;;; --------------------------------
@l4:   DEC DURATION2 ; 256*20 TIMES ALTOGETHER
       BNE @l2
       DEC DURATION1
       BNE @l2
       RTS
;;; --------------------------------
T:     JSR KLAXON_2
KLAXON_2:
       LDY #60      ; FIRST PRIMARY PITCH
       JSR SOUNDS_2
       LDY #96      ; SECOND PRIMARY PITCH
;;; --------------------------------
SOUNDS_2:
       STY PITCH    ; SAVE CALLER'S Y-PITCH
       LDX #76      ; SECONDARY PITCH
       LDA #100     ; LENGTH OF SOUND
;;; --------------------------------
@l1:   PHA
@l2:   DEX          ; COUNT DOWN SECONDARY CYCLE
       BNE @l3       ; ...NOT TIME FOR CLICK YET
       BIT SPEAKER  ; ...CLICK NOW
       LDX #76      ; START ANOTHER CYCLE
;;; --------------------------------
@l3:   DEY          ; COUNT DOWN PRIMARY CYCLE
       BNE @l4       ; ...NOT TIME FOR CLICK YET
       BIT SPEAKER  ; ...CLICK NOW
       LDY PITCH    ; START ANOTHER CYCLE
;;; --------------------------------
@l4:   SBC #1       ; COUNT DOWN TOTAL TIME
       BNE @l2
       PLA
       SBC #1
       BNE @l1
       RTS
;;; --------------------------------
END_SOUND_PROC

;;; ============================================================
;;; "Silent" - flashes the menu bar

SOUND_PROC Silent
        ptr := $06

        jsr     InvertMenu

        ;; Delay using some heuristic.

        ;; Option #1: Hit speaker to slow accelerator, with inaudible pitch.
        ;;
        ;; (1) This causes Virtual ][ to stop playing sounds for a bit (!)
        ;; (2) This has an audible click in MAME (!)
        ;;         sta     SPKR
        ;;         sta     SPKR

        ;; Option #2: Wait based on double-click setting.
        ;;
        ;; The assumption is that users will adjust the setting based on
        ;; factors such as acceleration/emulation speed, so use it as
        ;; the basis of a timing loop.
        copy16  SETTINGS + DeskTopSettings::dblclick_speed, ptr
loop:   ldx     #48
:       dex
        bne     :-
        dec     ptr
        bne     loop
        dec     ptr+1
        bne     loop

        ;; TODO: Consider using VBL on Enh IIe/IIc/IIgs
        ;; https://comp.sys.apple2.narkive.com/dHkvl39d/vblank-apple-iic
        ;; Note that emulators tend to not throttle to 60/50Hz real time,
        ;; but have VBL synchronized to cycle counts.

        FALL_THROUGH_TO InvertMenu

.proc InvertMenu
        sta     SET80COL

        ldx     #kMenuBarHeight-1
rloop:  lda     hires_table_lo,x
        sta     ptr
        lda     hires_table_hi,x
        sta     ptr+1

        sta     PAGE2ON
        jsr     DoRow
        sta     PAGE2OFF
        jsr     DoRow

        dex
        bpl     rloop

        sta     CLR80COL

        rts

.proc DoRow
        ldy     #39
cloop:  lda     (ptr),y
        eor     #$7F
        sta     (ptr),y
        dey
        bpl     cloop
        rts
.endproc
.endproc

hires_table_lo:
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$80,$80,$80,$80,$80,$80,$80,$80

hires_table_hi:
	.byte	$20,$24,$28,$2c,$30,$34,$38,$3c
	.byte	$20,$24,$28,$2c,$30,$34,$38,$3c
END_SOUND_PROC


;;; ============================================================

        .include "../lib/drawstring.s"
        .include "../lib/buttonloop.s"
        .include "../lib/muldiv.s"

;;; ============================================================

da_end  := *
.assert * < WINDOW_ENTRY_TABLES, error, .sprintf("DA too big (at $%X)", *)
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but entry tables start at AUX $1B00

;;; ============================================================