;;; ============================================================
;;; SHOW.TEXT.FILE - Desk Accessory
;;;
;;; Preview accessory for plain text files.
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "show.text.file.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================
;;; Memory map
;;;
;;;              Main           Aux
;;;          :           : :           :
;;;          |           | |           |
;;;          | DHR       | | DHR       |
;;;  $2000   +-----------+ +-----------+
;;;          | IO Buffer | |           |
;;;  $1C00   +-----------+ |           |
;;;          |           | |           |
;;;          |           | |           | Records offsets into the file
;;;          | (unused)  | | line      | every Nth line so scrolling
;;;          |           | | offsets   | is fast.
;;;  $1900   +-----------+ +-----------+
;;;          | buf2      | | buf2 copy | These buffers hold 2 pages of the
;;;  $1800   +-----------+ +-----------+ text file, and are loaded/swapped
;;;          | buf1      | | buf2 copy | as the file is scrolled.
;;;  $1700   +-----------+ +-----------+
;;;          |           | |           |
;;;          |           | |           |
;;;          |           | |           |
;;;          |           | |           |
;;;          |           | | UI code & |
;;;          | file I/O  | | resources |
;;;   $800   +-----------+ +-----------+
;;;          :           : :           :
;;;

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

;;; Keep in sync with main copy!
mli_params:
        DEFINE_OPEN_PARAMS open_params, INVOKE_PATH, DA_IO_BUFFER
        DEFINE_READWRITE_PARAMS read_params, default_buffer, kReadLength
        DEFINE_GET_EOF_PARAMS get_eof_params
        DEFINE_SET_MARK_PARAMS set_mark_params, 0
        DEFINE_CLOSE_PARAMS close_params
sizeof_mli_params = * - mli_params

visible_flag:                   ; clear until text that should be visible is in view
        .byte   0

params_end := * + 4       ; bug in original? (harmless as this is static)
;;; ----------------------------------------

        kDAWindowId = $80

        kLineSpacing = 10
        kWrapWidth = 506

tab_flag:                       ; set if last character seen was a tab
        .byte   0
remaining_width:
        .word   kWrapWidth

kLinePosLeft = 3
.params line_pos
left:   .word   0
base:   .word   0
.endparams

y_remaining:    .word   0

;;; Height of a line of text
kLineHeight = kSystemFontHeight + 1

kLinesPerPage = kDAHeight / kLineHeight

        DEFINE_RECT_SZ line_shield_rect, kLinePosLeft, 0, kWrapWidth, 0

;;; Number of lines per scroll tick
kLineScrollDelta = 1

;;; Scroll by this number of lines when doing page up/down
kPageScrollDelta = kLinesPerPage - 1

;;; When bit7 set, the whole file is rendered, and line offsets are recorded.
;;; When bit7 clear, line offsets are used to accelerate rendering.
record_offsets_flag:
        .byte   0

;;; Farthest offset into the file that `DrawContent` made it
buf_mark:
        .word   0

;;; Calculated on initial load
max_visible_line:
        .word   0

;;; Scroll position in document
first_visible_line:
        .word   0

fixed_mode_flag:
        .byte   0               ; 0 = proportional, otherwise = fixed


        .include "../lib/event_params.s"

.params trackgoaway_params      ; queried after close clicked to see if aborted/finished
goaway:         .byte   0       ; 0 = aborted, 1 = clicked
.endparams


.params drawtext_params
textptr:        .addr   0       ; address
textlen:        .byte   0       ; length
.endparams

kDALeft    = 10
kDATop     = 28
kDAWidth   = 512
kDAHeight  = 150

titlebuf:
        .res    16, 0

kVScrollMax = $FF

.params winfo
window_id:      .byte   kDAWindowId ; window identifier
options:        .byte   MGTK::Option::go_away_box ; window flags (2=include close port)
title:          .addr   titlebuf
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_normal
hthumbmax:      .byte   32      ; unused
hthumbpos:      .byte   0
vthumbmax:      .byte   kVScrollMax
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   200
mincontheight:  .word   51
maxcontwidth:   .word   kDAWidth
maxcontheight:  .word   kDAHeight
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
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams


        ;; gets copied over winfo::port after mode is drawn
.params default_port
        DEFINE_POINT viewloc, kDALeft, kDATop
mapbits:        .word   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kDAWidth, kDAHeight
        REF_MAPINFO_MEMBERS
.endparams

.params muldiv_params
number:         .word   0       ; (in)
numerator:      .word   0       ; (in)
denominator:    .word   0       ; (in)
result:         .word   0       ; (out)
remainder:      .word   0       ; (out)
.endparams

;;; ============================================================
;;; Open the file and create the DA window

.proc Init
        copy8   #0, fixed_mode_flag

        ;; open file, get length
        JSR_TO_MAIN OpenFile
        RTS_IF NOT_ZERO

        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     set_mark_params::ref_num
        sta     get_eof_params::ref_num
        sta     close_params::ref_num
        JSR_TO_MAIN GetFileEof

        ;; create window
        MGTK_CALL MGTK::OpenWindow, winfo
        MGTK_CALL MGTK::SetPort, winfo::port
        jsr     CalcAndDrawMode
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch
        SET_BIT7_FLAG record_offsets_flag
        jsr     DrawContent
        CLEAR_BIT7_FLAG record_offsets_flag
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        jsr     InitScrollBar
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

;;; ============================================================
;;; Main Input Loop

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params
        cmp     #MGTK::EventKind::key_down    ; key?
        beq     OnKeyDown
        cmp     #MGTK::EventKind::button_down ; was clicked?
        bne     InputLoop      ; nope, keep waiting

        FALL_THROUGH_TO OnButtonDown
.endproc ; InputLoop

;;; ============================================================

.proc OnButtonDown
        MGTK_CALL MGTK::FindWindow, event_params::coords
        lda     findwindow_params::window_id ; in our window?
        cmp     #kDAWindowId
        bne     InputLoop

        ;; which part of the window?
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        jeq     OnCloseClick

        cmp     #MGTK::Area::dragbar
        beq     title
        cmp     #MGTK::Area::grow_box ; not enabled, so this will never match
        beq     InputLoop
        jsr     OnContentClick
        jmp     InputLoop

title:  jsr     OnTitleBarClick
        jmp     InputLoop
.endproc ; OnButtonDown

;;; ============================================================
;;; Key

.proc OnKeyDown
        ldx     event_params::modifiers
        beq     no_mod

        ;; Modifiers
        lda     event_params::key
        jsr     ToUpperCase

    IF X = #3
        ;; Double modifiers
      IF A = #CHAR_UP           ; OA+SA+Up = Home
        jsr     ScrollTop
        jmp     InputLoop
      END_IF

      IF A = #CHAR_DOWN         ; OA+SA+Down = End
        jsr     ScrollBottom
        ;; jmp     InputLoop
      END_IF
    ELSE
        ;; Single modifier
      IF A = #CHAR_UP           ; Apple+Up = Page Up
        jsr     PageUp
        jmp     InputLoop
      END_IF

      IF A = #CHAR_DOWN         ; Apple+Down = Page Down
        jsr     PageDown
        ;; jmp     InputLoop
      END_IF

        cmp     #kShortcutCloseWindow
        jeq     DoClose
    END_IF

        jmp     InputLoop

        ;; No modifiers
no_mod:
        lda     event_params::key

        cmp     #CHAR_ESCAPE
        jeq     DoClose

    IF A = #' '
        jsr     ToggleMode
        jmp     InputLoop
    END_IF

    IF A = #CHAR_UP
        jsr     ScrollUp
        jmp     InputLoop
    END_IF

    IF A = #CHAR_DOWN
        jsr     ScrollDown
        ;; jmp     InputLoop
    END_IF

        jmp     InputLoop
.endproc ; OnKeyDown

;;; ============================================================
;;; Click on Close Button

.proc OnCloseClick
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway ; did click complete?
        bne     DoClose                    ; yes
        jmp     InputLoop                  ; no
.endproc ; OnCloseClick

.proc DoClose
        JSR_TO_MAIN CloseFile
        MGTK_CALL MGTK::CloseWindow, winfo
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts                     ; exits input loop
.endproc ; DoClose

;;; ============================================================
;;; Click on Content Area

;;; Non-title (content) area clicked
.proc OnContentClick
        ;; On one of the scroll bars?
        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        beq     OnVScrollClick
end:    rts
.endproc ; OnContentClick

;;; ============================================================
;;; Click on Vertical Scroll Bar

.proc OnVScrollClick
        lda     findcontrol_params::which_part
        cmp     #MGTK::Part::thumb
        beq     OnVScrollThumbClick
        cmp     #MGTK::Part::page_down
        beq     OnVScrollBelowClick
        cmp     #MGTK::Part::page_up
        beq     OnVScrollAboveClick
        cmp     #MGTK::Part::up_arrow
        beq     OnVScrollUpClick
        cmp     #MGTK::Part::down_arrow
        beq     OnVScrollDownClick
        rts
.endproc ; OnVScrollClick

.proc OnVScrollThumbClick
        copy8   #MGTK::Ctl::vertical_scroll_bar, trackthumb_params::which_ctl
        MGTK_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_params::thumbmoved
        beq     end

        ;; `first_visible_line` = `trackthumb_params::thumbpos` * `max_visible_line` / `kVScrollMax`
        copy16  max_visible_line, muldiv_params::number
        copy8   trackthumb_params::thumbpos, muldiv_params::numerator ; lo
        copy8   #0, muldiv_params::numerator+1                        ; hi
        copy16  #kVScrollMax, muldiv_params::denominator
        MGTK_CALL MGTK::MulDiv, muldiv_params
        copy16  muldiv_params::result, first_visible_line

        jsr     UpdateScrollPos

end:    rts
.endproc ; OnVScrollThumbClick

.proc OnVScrollBelowClick
repeat: jsr     PageDown
        jsr     CheckButtonRelease
        bcc     repeat            ; repeat while button down
        rts
.endproc ; OnVScrollBelowClick

.proc OnVScrollAboveClick
repeat: jsr     PageUp
        jsr     CheckButtonRelease
        bcc     repeat            ; repeat while button down
        rts
.endproc ; OnVScrollAboveClick

.proc OnVScrollDownClick
repeat: jsr     ScrollDown
        jsr     CheckButtonRelease
        bcc     repeat            ; repeat while button down
        rts
.endproc ; OnVScrollDownClick

.proc OnVScrollUpClick
repeat: jsr     ScrollUp
        jsr     CheckButtonRelease
        bcc     repeat            ; repeat while button down
        rts
.endproc ; OnVScrollUpClick

;;; ============================================================

;;; Returns Z=1 if at top, Z=0 otherwise
.proc IsAtTop
        lda     first_visible_line
        bne     ret
        lda     first_visible_line+1
ret:    rts
.endproc ; IsAtTop

;;; Returns Z=1 if at bottom, Z=0 otherwise
.proc IsAtBottom
        ecmp16  first_visible_line, max_visible_line
        rts
.endproc ; IsAtBottom

;;; ============================================================

.proc ScrollUp
        jsr     IsAtTop
        beq     ret

        cmp16   first_visible_line, #kLineScrollDelta ; would be too far?
        bcc     ForceScrollTop                        ; yes, clamp to top
        sub16   first_visible_line, #kLineScrollDelta, first_visible_line
        jsr     UpdateScrollPos

ret:    rts
.endproc ; ScrollUp

.proc PageUp
        jsr     IsAtTop
        beq     ret

        cmp16   first_visible_line, #kPageScrollDelta ; would be too far?
        bcc     ForceScrollTop                        ; yes, clamp to top
        sub16   first_visible_line, #kPageScrollDelta, first_visible_line
        jsr     UpdateScrollPos

ret:    rts
.endproc ; PageUp

.proc ScrollTop
        jsr     IsAtTop
        beq     ret

force:  copy16  #0, first_visible_line
        jsr     UpdateScrollPos

ret:    rts
.endproc ; ScrollTop
ForceScrollTop := ScrollTop::force

.proc ScrollDown
        jsr     IsAtBottom
        beq     ret

        add16   first_visible_line, #kLineScrollDelta, first_visible_line
        cmp16   first_visible_line, max_visible_line ; too far down?
        bcs     ForceScrollBottom                    ; yes, clamp to bottom
        jsr     UpdateScrollPos

ret:    rts
.endproc ; ScrollDown

.proc PageDown
        jsr     IsAtBottom
        beq     ret

        add16   first_visible_line, #kPageScrollDelta, first_visible_line
        cmp16   first_visible_line, max_visible_line ; too far down?
        bcs     ForceScrollBottom                    ; yes, clamp to bottom
        jsr     UpdateScrollPos

ret:    rts
.endproc ; PageDown

.proc ScrollBottom
        jsr     IsAtBottom
        beq     ret

force:  copy16  max_visible_line, first_visible_line
        jsr     UpdateScrollPos

ret:    rts
.endproc ; ScrollBottom
ForceScrollBottom := ScrollBottom::force

;;; ============================================================

.proc UpdateScrollPos
        ;; Update viewport
        copy16  first_visible_line, muldiv_params::number
        copy16  #kLineScrollDelta * kLineHeight, muldiv_params::numerator
        copy16  #1, muldiv_params::denominator
        MGTK_CALL MGTK::MulDiv, muldiv_params
        ldax    muldiv_params::result
        stax    winfo::maprect::y1
        addax   #kDAHeight, winfo::maprect::y2
        MGTK_CALL MGTK::SetPort, winfo::port

        ;; Update thumb position

        ;; `updatethumb_params::thumbpos` = `first_visible_line` * `kVScrollMax` / `max_visible_line`
        copy16  #kVScrollMax, muldiv_params::number
        copy16  first_visible_line, muldiv_params::numerator
        copy16  max_visible_line, muldiv_params::denominator
        MGTK_CALL MGTK::MulDiv, muldiv_params
        lda     muldiv_params::result+1
    IF NOT_ZERO
        lda     #kVScrollMax
    ELSE
        lda     muldiv_params::result
    END_IF
        sta     updatethumb_params::thumbpos

        lda     winfo::vscroll
        and     #MGTK::Scroll::option_active
    IF NOT_ZERO
        copy8   #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
    END_IF

        jmp     DrawContent
.endproc ; UpdateScrollPos

;;; ============================================================

;;; Returns with carry set if button was released
.proc CheckButtonRelease
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params
        cmp     #MGTK::EventKind::button_up
        clc
        bne     end
        sec
end:    rts
.endproc ; CheckButtonRelease

;;; ============================================================
;;; Content Rendering

.proc DrawContent
        ptr := $06

        offset_ptr := $08

        bit     record_offsets_flag
    IF NS
        ;; Render the whole file (visible and invisible), and record
        ;; offsets for every Nth line as we go.
        copy16  #0, line_offsets
        copy16  #line_offsets+2, offset_ptr
        copy8   #kLineOffsetDelta, offset_counter

        ;; Start off on 0th line, start of file, and top of window
        copy16  #0, current_line
        copy16  #0, set_mark_params::position
        JSR_TO_MAIN SetFileMark
        copy16  #0, line_pos::base
    ELSE
        ;; Start off at first offset before `first_visible_line`
        ;; using floor(`first_visible_line` / `kLineOffsetDelta`) * `kLineOffsetDelta`
        copy16  first_visible_line, current_line
        ldx     #kLineOffsetShift
    DO
        lsr16   current_line        ; /= `kLineOffsetDelta`
        dex
    WHILE NOT_ZERO

        copy16  current_line, offset_ptr
        ldx     #kLineOffsetShift
    DO
        asl16   current_line        ; *= `kLineOffsetDelta`
        dex
    WHILE NOT_ZERO

        ;; Use previously recorded offset into file.
        asl16   offset_ptr
        add16   offset_ptr, #line_offsets, offset_ptr
        ldy     #0
        copy16in (offset_ptr),y, set_mark_params::position
        JSR_TO_MAIN SetFileMark

        ;; And adjust to the appropriate offset for that line in the viewport.
        copy16  current_line, muldiv_params::number
        copy16  #kLineHeight, muldiv_params::numerator
        copy16  #1, muldiv_params::denominator
        MGTK_CALL MGTK::MulDiv, muldiv_params
        copy16  muldiv_params::result, line_pos::base
    END_IF

        ;; Select appropriate font
        lda     fixed_mode_flag
    IF ZERO
        MGTK_CALL MGTK::SetFont, DEFAULT_FONT
    ELSE
        MGTK_CALL MGTK::SetFont, fixed_font
    END_IF

        ;; Calc last visible line, so we can optimize some operations
        add16   first_visible_line, #kLinesPerPage - 1, last_visible_line

        copy16  #default_buffer, read_params::data_buffer
        copy16  #default_buffer, ptr
        copy16  #0, buf_mark

        ;; Populate buffer pages
        jsr     ReadFilePage               ; first page
        inc     read_params::data_buffer+1 ; subsequent reads go to second page
        jsr     ReadFilePage               ; second page

        copy8   #0, visible_flag

        MGTK_CALL MGTK::ShieldCursor, winfo::maprect
        MGTK_CALL MGTK::PaintRect, winfo::maprect
        MGTK_CALL MGTK::UnshieldCursor

        ;; --------------------------------------------------
        ;; Loop over lines

    REPEAT
        ;; Reset state / flags
        copy16  line_pos::base, line_shield_rect::y1
        add16_8 line_pos::base, #kLineSpacing
        copy16  line_pos::base, line_shield_rect::y2
        copy16  #kWrapWidth, remaining_width
        copy16  #kLinePosLeft, line_pos::left
        copy8   #0, tab_flag

        ldx     #0
        cmp16   current_line, first_visible_line
      IF GE
        cmp16   last_visible_line, current_line
       IF GE
        inx
       END_IF
      END_IF
        stx     visible_flag

        MGTK_CALL MGTK::ShieldCursor, line_shield_rect

        ;; Position cursor, update remaining width
    DO
        MGTK_CALL MGTK::MoveTo, line_pos
        sub16   #kWrapWidth, line_pos::left, remaining_width

        ;; Identify next run of characters
        jsr     FindTextRun
      IF CS
        ;; EOF - finish up
        MGTK_CALL MGTK::UnshieldCursor
        jmp     done
      END_IF

        ;; Update pointer into buffer for next time
        add16_8 ptr, drawtext_params::textlen

        ;; Did the run end due to a tab?
        lda     tab_flag
    WHILE NOT ZERO              ; yes, keep going

        ;; --------------------------------------------------
        ;; End of line

        MGTK_CALL MGTK::UnshieldCursor

        bit     record_offsets_flag
      IF NS
        ;; Doing a full pass. Determine current file offset.
        sub16   ptr, #default_buffer, cur_offset
        add16   cur_offset, buf_mark, cur_offset

        ;; Maybe record it
        dec     offset_counter
       IF ZERO
        ldy     #0
        copy16in cur_offset, (offset_ptr),y
        add16_8 offset_ptr, #2
        copy8   #kLineOffsetDelta, offset_counter ; reset
       END_IF

        ;; EOF? If so, stop!
        cmp16   cur_offset, get_eof_params::eof
        bcs     done
      ELSE
        ;; Just rendering what's visible. Are we done?
        ecmp16  current_line, last_visible_line
        beq     done
      END_IF

        ;; Nope - continue on next line
        inc16   current_line

        ;; Keep mouse cursor somewhat responsive
        MGTK_CALL MGTK::CheckEvents
    FOREVER

        ;; --------------------------------------------------

done:   MGTK_CALL MGTK::SetFont, DEFAULT_FONT

        bit     record_offsets_flag
    IF NS
        sub16   current_line, #kLinesPerPage - 1, max_visible_line
      IF NEG
        copy16  #0, max_visible_line
      END_IF
    END_IF

        rts

;;; `first_visible_line` + `kLinesPerPage`
last_visible_line:
        .word   0

current_line:
        .word   0

;;; Counts down to 0; when 0, an offset is recorded in `line_offsets`
;;; and `offset_ptr` is incremented.
offset_counter:
        .byte   0

cur_offset:
        .word   0
.endproc ; DrawContent

;;; ============================================================
;;; Input: A = character
;;; Output: A = width

.proc GetCharWidth
        tay
        lda     fixed_mode_flag
    IF ZERO
        lda     DEFAULT_FONT + MGTK::Font::charwidth,y
    ELSE
        lda     fixed_font + MGTK::Font::charwidth,y
    END_IF
        rts
.endproc ; GetCharWidth

;;; ============================================================

;;; Output: C=1 if done
.proc FindTextRun
        ptr := $06

        copy8   #$FF, L0F9B
        lda     #0
        sta     run_width
        sta     run_width+1
        sta     tab_flag
        sta     drawtext_params::textlen
        copy16  ptr, drawtext_params::textptr

loop:
        jsr     EnsurePageBuffered
        ldy     drawtext_params::textlen
        lda     (ptr),y
        and     #CHAR_MASK
        sta     (ptr),y
        cmp     #CHAR_RETURN
        beq     FinishTextRun
    IF A = #' '
        sty     L0F9B
    END_IF

        cmp     #CHAR_TAB
        jeq     HandleTab

        jsr     GetCharWidth
        clc
        adc     run_width
        sta     run_width
        bcc     :+
        inc     run_width+1
:
        ;; Is there room?
        cmp16   remaining_width, run_width
    IF GE
        inc     drawtext_params::textlen
        jmp     loop
    END_IF

        copy8   #0, tab_flag
        lda     L0F9B
    IF A <> #$FF
        sta     drawtext_params::textlen
    END_IF
        inc     drawtext_params::textlen
        FALL_THROUGH_TO FinishTextRun
.endproc ; FindTextRun

.proc FinishTextRun
        ptr := $06

        jsr     DrawTextRun
        ldy     drawtext_params::textlen
        lda     (ptr),y
    IF A IN #CHAR_TAB, #CHAR_RETURN
        inc     drawtext_params::textlen
    END_IF
        RETURN  C=0
.endproc ; FinishTextRun

;;; ============================================================

L0F9B:  .byte   0
run_width:  .word   0

.proc HandleTab
        copy8   #1, tab_flag
        add16   run_width, line_pos::left, line_pos::left
        ldx     #0
loop:   cmp16   times70,x, line_pos::left
    IF LT
        inx
        inx
        cpx     #14
        beq     done
        jmp     loop
    END_IF

        copy16  times70,x, line_pos::left
        jmp     FinishTextRun

done:
        copy8   #0, tab_flag
        jmp     FinishTextRun

times70:.word   70
        .word   140
        .word   210
        .word   280
        .word   350
        .word   420
        .word   490
.endproc ; HandleTab

;;; ============================================================
;;; Draw a line of content

.proc DrawTextRun
        lda     visible_flag    ; skip if not in visible range
        beq     end
        lda     drawtext_params::textlen
        beq     end
        MGTK_CALL MGTK::DrawText, drawtext_params
end:    rts
.endproc ; DrawTextRun

;;; ============================================================

.proc EnsurePageBuffered
        ptr := $06

        ;; Pointing at second page already?
        lda     drawtext_params::textptr+1
    IF A <> #>default_buffer
        ;; Yes, shift second page down.
        ldy     #0
      DO
        copy8   default_buffer+$100,y, default_buffer,y
        iny
      WHILE NOT_ZERO

        ;; Adjust pointers down a page too.
        dec     drawtext_params::textptr+1
        copy16  drawtext_params::textptr, ptr
        inc     buf_mark+1

        ;; And re-populate second page.
        jsr     ReadFilePage
    END_IF

        rts
.endproc ; EnsurePageBuffered

;;; ============================================================

.proc ReadFilePage
        copy16  read_params::data_buffer, @store_addr

        lda     #' '            ; fill buffer with spaces
        ldx     #0
        @store_addr := *+1
store:  sta     default_buffer,x         ; self-modified
        inx
        bne     store

        jsr     prep
        CALL    AUXMOVE, C=0    ; aux>main

        JSR_TO_MAIN ReadFile

        pha                     ; copy read buffer main>aux
        jsr     prep
        CALL    AUXMOVE, C=1    ; main>aux
        pla

        beq     done
        cmp     #ERR_END_OF_FILE
        beq     done
        brk                     ; crash on other error

done:   rts


prep:   lda     #$00
        sta     STARTLO
        sta     DESTINATIONLO
        lda     #$FF
        sta     ENDLO
        lda     read_params::data_buffer+1
        sta     DESTINATIONHI
        sta     STARTHI
        sta     ENDHI
        rts

.endproc ; ReadFilePage

;;; ============================================================

;;; Assumes `max_visible_line` is set.

.proc InitScrollBar
        ldx     #MGTK::activatectl_activate
        lda     max_visible_line
        ora     max_visible_line+1
    IF ZERO
        ;; File entirely fits; deactivate scrollbar
        ldx     #MGTK::activatectl_deactivate
    END_IF
        stx     activatectl_params::activate
        copy8   #MGTK::Ctl::vertical_scroll_bar, activatectl_params::which_ctl
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
        rts
.endproc ; InitScrollBar

;;; ============================================================
;;; Title Bar (Proportional/Fixed mode button)

.proc OnTitleBarClick
        cmp16   event_params::xcoord, mode_mapinfo_viewloc_xcoord
        bcs     ToggleMode
        RETURN  C=0             ; Click ignored
.endproc ; OnTitleBarClick

.proc ToggleMode
        ;; Toggle the state and redraw
        lda     fixed_mode_flag
        eor     #$FF
        sta     fixed_mode_flag

        jsr     DrawMode
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::watch
        SET_BIT7_FLAG record_offsets_flag
        jsr     ForceScrollTop
        CLEAR_BIT7_FLAG record_offsets_flag
        MGTK_CALL MGTK::SetCursor, MGTK::SystemCursor::pointer
        jsr     InitScrollBar
        RETURN  C=1             ; Click consumed
.endproc ; ToggleMode

;;; ============================================================

fixed_str:      PASCAL_STRING res_string_button_fixed
prop_str:       PASCAL_STRING res_string_button_prop
        kLabelWidth = 110
        kLabelHeight = 10

.params mode_mapinfo                  ; bounding port for mode label
        DEFINE_POINT viewloc, 0, 0
mapbits:        .word   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kLabelWidth, kLabelHeight
        REF_MAPINFO_MEMBERS
.endparams
mode_mapinfo_viewloc_xcoord := mode_mapinfo::viewloc::xcoord

        DEFINE_POINT mode_pos, 0, 10

.params winframerect_params
window_id:      .byte   kDAWindowId
        DEFINE_RECT rect, 0, 0, 0, 0
.endproc ; aux

;;; ============================================================

.proc CalcAndDrawMode

        MGTK_CALL MGTK::GetWinFrameRect, winframerect_params

        sub16_8 winframerect_params::rect::x2, #kLabelWidth+1, mode_mapinfo::viewloc::xcoord
        add16_8 winframerect_params::rect::y1, #1, mode_mapinfo::viewloc::ycoord

        FALL_THROUGH_TO DrawMode
.endproc ; CalcAndDrawMode

.proc DrawMode
        ;; Set up port
        MGTK_CALL MGTK::SetPortBits, mode_mapinfo

        ;; Clear background
        MGTK_CALL MGTK::PaintRect, mode_mapinfo::maprect

        ;; Center string
        text_params     := $6
        text_addr       := text_params + 0
        text_length     := text_params + 2
        text_width      := text_params + 3

        lda     fixed_mode_flag
    IF NOT_ZERO
        ldax    #fixed_str
    ELSE
        ldax    #prop_str
    END_IF
        stax    text_addr

        ldy     #0
        copy8   (text_addr),y, text_length
        inc16   text_addr       ; point past length
        MGTK_CALL MGTK::TextWidth, text_params

        sub16   #kLabelWidth, text_width, mode_pos::xcoord
        lsr16   mode_pos::xcoord ; /= 2
        MGTK_CALL MGTK::MoveTo, mode_pos
        MGTK_CALL MGTK::DrawText, text_params

        ;; Reset port
        COPY_STRUCT default_port, winfo::port
        MGTK_CALL MGTK::SetPortBits, winfo::port
        rts
.endproc ; DrawMode

;;; ============================================================

        .include "../lib/uppercase.s"

;;; ============================================================

fixed_font:
        .incbin .concat("../../out/Monaco.", kBuildLang, ".font")

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
        jmp     Start
;;; ============================================================

        MLIEntry := MLI

        INVOKE_PATH := $220

filename:       .res    16

        DEFINE_GET_FILE_INFO_PARAMS get_info_params, INVOKE_PATH

.proc Start
        lda     INVOKE_PATH
        beq     ret

        ;; Don't show directory files (volumes/subdirectories)
        JUMP_TABLE_MLI_CALL GET_FILE_INFO, get_info_params
        bcs     ret
        lda     get_info_params::file_type
        cmp     #FT_DIRECTORY
        beq     ret

        ;; Set window title to filename
        ldy     INVOKE_PATH
    DO
        lda     INVOKE_PATH,y       ; find last '/'
        BREAK_IF A = #'/'
        dey
    WHILE NOT_ZERO

        ldx     #0
    DO
        copy8   INVOKE_PATH+1,y, filename+1,x ; copy filename
        inx
        iny
    WHILE Y <> INVOKE_PATH
        stx     filename

        copy16  #filename, STARTLO
        copy16  #filename+kMaxFilenameLength, ENDLO
        copy16  #aux::titlebuf, DESTINATIONLO
        CALL    AUXMOVE, C=1    ; main>aux

        ;; Run the DA
        JSR_TO_AUX aux::Init

ret:    rts
.endproc ; Start

;;; ============================================================
;;; ProDOS MLI calls

.proc OpenFile
        jsr     CopyParamsAuxToMain
        sta     ALTZPOFF
        MLI_CALL OPEN, open_params
        sta     ALTZPON
        jmp     CopyParamsMainToAux
.endproc ; OpenFile

.proc ReadFile
        jsr     CopyParamsAuxToMain
        sta     ALTZPOFF
        MLI_CALL READ, read_params
        sta     ALTZPON
        jmp     CopyParamsMainToAux
.endproc ; ReadFile

.proc GetFileEof
        jsr     CopyParamsAuxToMain
        sta     ALTZPOFF
        MLI_CALL GET_EOF, get_eof_params
        sta     ALTZPON
        jmp     CopyParamsMainToAux
.endproc ; GetFileEof

.proc SetFileMark
        jsr     CopyParamsAuxToMain
        sta     ALTZPOFF
        MLI_CALL SET_MARK, set_mark_params
        sta     ALTZPON
        jmp     CopyParamsMainToAux
.endproc ; SetFileMark

.proc CloseFile
        jsr     CopyParamsAuxToMain
        sta     ALTZPOFF
        MLI_CALL CLOSE, close_params
        sta     ALTZPON
        jmp     CopyParamsMainToAux
.endproc ; CloseFile

;;; ============================================================

;;; Copies param blocks from Aux to Main
.proc CopyParamsAuxToMain
        copy16  #aux::mli_params, STARTLO
        copy16  #aux::mli_params + aux::sizeof_mli_params - 1, ENDLO
        copy16  #mli_params, DESTINATIONLO
        TAIL_CALL AUXMOVE, C=0  ; aux>main
.endproc ; CopyParamsAuxToMain

;;; Copies param blocks from Main to Aux
;;; Preserves A and P
.proc CopyParamsMainToAux
        php
        pha

        copy16  #mli_params, STARTLO
        copy16  #mli_params + sizeof_mli_params - 1, ENDLO
        copy16  #aux::mli_params, DESTINATIONLO
        CALL    AUXMOVE, C=1    ; main>aux

        pla
        plp
        rts
.endproc ; CopyParamsMainToAux



;;; Two pages of data are read, but separately.
default_buffer  := $1700
kReadLength      = $0100
        .assert default_buffer + $200 < DA_IO_BUFFER, error, "DA too big"

line_offsets    := $1900
kLineOffsetShift = 4            ; every 16th
kLineOffsetDelta = 1 << kLineOffsetShift


;;; ProDOS MLI param blocks
;;; This block gets copied between main/aux

;;; Keep in sync with aux copy!
mli_params:
        DEFINE_OPEN_PARAMS open_params, INVOKE_PATH, DA_IO_BUFFER
        DEFINE_READWRITE_PARAMS read_params, default_buffer, kReadLength
        DEFINE_GET_EOF_PARAMS get_eof_params
        DEFINE_SET_MARK_PARAMS set_mark_params, 0
        DEFINE_CLOSE_PARAMS close_params
sizeof_mli_params = * - mli_params
.assert sizeof_mli_params = aux::sizeof_mli_params, error, "size mismatch"

;;; ============================================================

        DA_END_MAIN_SEGMENT

;;; ============================================================
