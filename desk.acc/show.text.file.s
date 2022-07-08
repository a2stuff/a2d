        .include "../config.inc"
        RESOURCE_FILE "show.text.file.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

        MGTKEntry := MGTKAuxEntry

;;; ============================================================
;;; Memory map
;;;
;;;              Main           Aux
;;;          :           : :           :
;;;          |           | |           |
;;;          | DHR       | | DHR       |
;;;  $2000   +-----------+ +-----------+
;;;          | IO Buffer | |Win Tables |
;;;  $1C00   +-----------+ |           |
;;;  $1B00   |           | +-----------+
;;;          |           | |           |
;;;          | (unused)  | | (unused)  |
;;;          |           | |           |
;;;  $1900   +-----------+ +-----------+
;;;          | buf2      | | buf2 copy | These buffers hold 2 pages of the
;;;  $1800   +-----------+ +-----------+ text file, and are loaded/swapped
;;;          | buf1      | | buf2 copy | as the file is scrolled.
;;;  $1700   +-----------+ +-----------+
;;;          |           | |           |
;;;          |           | |           |
;;;          |           | |           |
;;;          |           | |           | This DA runs primarily out of the
;;;          |           | |           | copy in Aux. The upper bytes of
;;;          | DA        | | DA (Copy) | the code in main are overwritten.
;;;   $800   +-----------+ +-----------+
;;;          :           : :           :
;;;

;;; ============================================================

        .org DA_LOAD_ADDRESS

        MLIEntry := MLI

.proc Start
        INVOKE_PATH := $220
        lda     INVOKE_PATH
    IF_EQ
        rts
    END_IF
        COPY_STRING INVOKE_PATH, pathbuf

        ;; Set window title to filename
        ldy     pathbuf
:       lda     pathbuf,y       ; find last '/'
        cmp     #'/'
        beq     :+
        dey
        bne     :-
:       ldx     #0
:       lda     pathbuf+1,y     ; copy filename
        sta     titlebuf+1,x
        inx
        iny
        cpy     pathbuf
        bne     :-
        stx     titlebuf

        FALL_THROUGH_TO Copy2Aux
.endproc

;;; Copy the DA to aux
.proc Copy2Aux
        tsx
        stx     save_stack
        sta     RAMWRTON
        ldy     #0
src:    lda     Start,y         ; self-modified
dst:    sta     Start,y         ; self-modified
        dey
        bne     src
        sta     RAMWRTOFF
        inc     src+2
        inc     dst+2
        sta     RAMWRTON
        lda     dst+2
        cmp     #.hibyte(da_end)+1
        bne     src

        FALL_THROUGH_TO CallInit
.endproc

.proc CallInit
        ;; run the DA
        jsr     Init

        ;; tear down/exit
        sta     RAMRDOFF
        sta     RAMWRTOFF
        ldx     save_stack
        txs
        rts
.endproc

save_stack:.byte   0

;;; ============================================================
;;; ProDOS MLI calls

.proc OpenFile
        jsr     CopyParamsAuxToMain
        sta     ALTZPOFF
        MLI_CALL OPEN, open_params
        sta     ALTZPON
        jmp     CopyParamsMainToAux
.endproc

.proc ReadFile
        jsr     CopyParamsAuxToMain
        sta     ALTZPOFF
        MLI_CALL READ, read_params
        sta     ALTZPON
        jmp     CopyParamsMainToAux
.endproc

.proc GetFileEof
        jsr     CopyParamsAuxToMain
        sta     ALTZPOFF
        MLI_CALL GET_EOF, get_eof_params
        sta     ALTZPON
        jmp     CopyParamsMainToAux
.endproc

.proc SetFileMark
        jsr     CopyParamsAuxToMain
        sta     ALTZPOFF
        MLI_CALL SET_MARK, set_mark_params
        sta     ALTZPON
        jmp     CopyParamsMainToAux
.endproc

.proc CloseFile
        jsr     CopyParamsAuxToMain
        sta     ALTZPOFF
        MLI_CALL CLOSE, close_params
        sta     ALTZPON
        jmp     CopyParamsMainToAux
.endproc

;;; ============================================================

;;; Copies param blocks from Aux to Main
.proc CopyParamsAuxToMain
        ldy     #(params_end - params_start + 1)
        sta     RAMWRTOFF
loop:   lda     params_start - 1,y
        sta     params_start - 1,y
        dey
        bne     loop
        sta     RAMRDOFF
        rts
.endproc

;;; Copies param blocks from Main to Aux
.proc CopyParamsMainToAux
        php
        pha
        sta     RAMWRTON
        ldy     #(params_end - params_start + 1)
loop:   lda     params_start - 1,y
        sta     params_start - 1,y
        dey
        bne     loop
        sta     RAMRDON
        pla
        plp
        rts
.endproc

;;; ----------------------------------------

params_start:
;;; This block gets copied between main/aux

;;; ProDOS MLI param blocks

;;; Two pages of data are read, but separately.
default_buffer  := $1700
kReadLength      = $0100

        .assert default_buffer + $200 < WINDOW_ENTRY_TABLES, error, "DA too big"
        ;;  I/O Buffer starts at MAIN $1C00
        ;;  ... but entry tables start at AUX $1B00

        DEFINE_OPEN_PARAMS open_params, pathbuf, DA_IO_BUFFER
        DEFINE_READ_PARAMS read_params, default_buffer, kReadLength
        DEFINE_GET_EOF_PARAMS get_eof_params
        DEFINE_SET_MARK_PARAMS set_mark_params, 0
        DEFINE_CLOSE_PARAMS close_params

pathbuf:        .res    kPathBufferSize, 0

L0945:  .byte   $00
L0946:  .byte   $00

read_flag:                      ; set when the file is successfully read
        .byte   0
visible_flag:                   ; clear until text that should be visible is in view
        .byte   0
view_dirty_flag:                ; clear until text is drawn
        .byte   0

params_end := * + 4       ; bug in original? (harmless as this is static)
;;; ----------------------------------------

black_pattern:
        .res    8, $00

white_pattern:
        .res    $8, $FF

        kDAWindowId = 100

        kLineSpacing = 10
        kWrapWidth = 506

tab_flag:                       ; set if last character seen was a tab
        .byte   0
remaining_width:
        .word   kWrapWidth

.params line_pos
left:   .word   0
base:   .word   0
.endparams

y_remaining:    .word   0

;;; Height of a line of text
kLineHeight = kSystemFontHeight + 1

kLinesPerPage = kDAHeight / kLineHeight


;;; Number of lines per scroll tick
kLineScrollDelta = 1

;;; Scroll by this number of lines when doing page up/down
kPageScrollDelta = kLinesPerPage - 1

;;; Farthest offset into the file that `DrawContent` made it
buf_mark:
        .word   0

;;; Approximated on load: max = (LinesPerPage * EOF / BytesShown) - LinesPerPage
;;; Assert: max_visible_line + kPageScrollDelta <= $FFFF
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
mincontlength:  .word   51
maxcontwidth:   .word   kDAWidth
maxcontlength:  .word   kDAHeight
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
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams


        ;; gets copied over winfo::port after mode is drawn
.params default_port
        DEFINE_POINT viewloc, kDALeft, kDATop
mapbits:        .word   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kDAWidth, kDAHeight
.endparams

;;; ============================================================
;;; Open the file and create the DA window

.proc Init
        lda     #0
        sta     fixed_mode_flag

        ;; open file, get length
        jsr     OpenFile
        beq     :+
        rts

:       lda     open_params::ref_num
        sta     read_params::ref_num
        sta     set_mark_params::ref_num
        sta     get_eof_params::ref_num
        sta     close_params::ref_num
        jsr     GetFileEof

        ;; create window
        MGTK_CALL MGTK::OpenWindow, winfo
        MGTK_CALL MGTK::SetPort, winfo::port
        jsr     CalcAndDrawMode
        jsr     DrawContent
        jsr     InitScrollBar
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc

;;; ============================================================
;;; Main Input Loop

.proc InputLoop
        param_call JTRelay, JUMP_TABLE_YIELD_LOOP
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params
        cmp     #MGTK::EventKind::key_down    ; key?
        beq     OnKeyDown
        cmp     #MGTK::EventKind::button_down ; was clicked?
        bne     InputLoop      ; nope, keep waiting

        FALL_THROUGH_TO OnButtonDown
.endproc

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
        jsr     OnClientClick
        jmp     InputLoop

title:  jsr     OnTitleBarClick
        jmp     InputLoop
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
;;; Key

.proc OnKeyDown
        ldx     event_params::modifiers
        beq     no_mod

        ;; Modifiers
        lda     event_params::key

        cpx     #3
    IF_EQ
        ;; Double modifiers
        cmp     #CHAR_UP        ; OA+SA+Up = Home
      IF_EQ
        jsr     ScrollTop
        jmp     InputLoop
      END_IF

        cmp     #CHAR_DOWN      ; OA+SA+Down = End
      IF_EQ
        jsr     ScrollBottom
        ;; jmp     InputLoop
      END_IF
    ELSE
        ;; Single modifier
        cmp     #CHAR_UP        ; Apple+Up = Page Up
      IF_EQ
        jsr     PageUp
        jmp     InputLoop
      END_IF

        cmp     #CHAR_DOWN      ; Apple+Down = Page Down
      IF_EQ
        jsr     PageDown
        ;; jmp     InputLoop
      END_IF
    END_IF

        jmp     InputLoop

        ;; No modifiers
no_mod:
        lda     event_params::key

        cmp     #CHAR_ESCAPE
        jeq     DoClose

        cmp     #' '
    IF_EQ
        jsr     ToggleMode
        jmp     InputLoop
    END_IF

        cmp     #CHAR_UP
    IF_EQ
        jsr     ScrollUp
        jmp     InputLoop
    END_IF

        cmp     #CHAR_DOWN
    IF_EQ
        jsr     ScrollDown
        ;; jmp     InputLoop
    END_IF

        jmp     InputLoop
.endproc

;;; ============================================================
;;; Click on Close Button

.proc OnCloseClick
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway ; did click complete?
        bne     DoClose                    ; yes
        jmp     InputLoop                  ; no
.endproc

.proc DoClose
        jsr     CloseFile
        MGTK_CALL MGTK::CloseWindow, winfo
        param_jump JTRelay, JUMP_TABLE_CLEAR_UPDATES ; exits input loop
.endproc

;;; ============================================================
;;; Click on Client Area

;;; Non-title (client) area clicked
.proc OnClientClick
        ;; On one of the scroll bars?
        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        cmp     #MGTK::Ctl::vertical_scroll_bar
        beq     OnVScrollClick
end:    rts
.endproc

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
.endproc

.proc OnVScrollThumbClick
        copy    #MGTK::Ctl::vertical_scroll_bar, trackthumb_params::which_ctl
        MGTK_CALL MGTK::TrackThumb, trackthumb_params
        lda     trackthumb_params::thumbmoved
        beq     end

        ;; `first_visible_line` = `trackthumb_params::thumbpos` * `max_visible_line` / 256
        ;; [16] = ( [8] * [16] ) >> 8
        copy    trackthumb_params::thumbpos, multiplier ; lo
        copy    #0, multiplier+1                        ; hi
        copy16  max_visible_line, multiplicand
        jsr     Mul_16_16
        copy16  product+1, first_visible_line

        jsr     UpdateScrollPos

end:    rts
.endproc

.proc OnVScrollBelowClick
loop:   jsr     PageDown
        jsr     CheckButtonRelease
        bcc     loop            ; repeat while button down
        rts
.endproc

.proc OnVScrollAboveClick
loop:   jsr     PageUp
        jsr     CheckButtonRelease
        bcc     loop            ; repeat while button down
        rts
.endproc

.proc OnVScrollDownClick
loop:   jsr     ScrollDown
        jsr     CheckButtonRelease
        bcc     loop            ; repeat while button down
        rts
.endproc

.proc OnVScrollUpClick
loop:   jsr     ScrollUp
        jsr     CheckButtonRelease
        bcc     loop            ; repeat while button down
        rts
.endproc

;;; ============================================================

;;; Returns Z=1 if at top, Z=0 otherwise
.proc IsAtTop
        lda     first_visible_line
        bne     ret
        lda     first_visible_line+1
ret:    rts
.endproc

;;; Returns Z=1 if at bottom, Z=0 otherwise
.proc IsAtBottom
        lda     first_visible_line
        cmp     max_visible_line
        bne     ret
        lda     first_visible_line+1
        cmp     max_visible_line+1
ret:    rts
.endproc

;;; ============================================================

.proc ScrollUp
        jsr     IsAtTop
        beq     ret

        cmp16   first_visible_line, #kLineScrollDelta ; would be too far?
        bcc     ForceScrollTop                        ; yes, clamp to top
        sub16   first_visible_line, #kLineScrollDelta, first_visible_line
        jsr     UpdateScrollPos

ret:    rts
.endproc

.proc PageUp
        jsr     IsAtTop
        beq     ret

        cmp16   first_visible_line, #kPageScrollDelta ; would be too far?
        bcc     ForceScrollTop                        ; yes, clamp to top
        sub16   first_visible_line, #kPageScrollDelta, first_visible_line
        jsr     UpdateScrollPos

ret:    rts
.endproc

.proc ScrollTop
        jsr     IsAtTop
        beq     ret

force:  copy16  #0, first_visible_line
        jsr     UpdateScrollPos

ret:    rts
.endproc
ForceScrollTop := ScrollTop::force

.proc ScrollDown
        jsr     IsAtBottom
        beq     ret

        add16   first_visible_line, #kLineScrollDelta, first_visible_line
        cmp16   first_visible_line, max_visible_line ; too far down?
        bcs     ForceScrollBottom                    ; yes, clamp to bottom
        jsr     UpdateScrollPos

ret:    rts
.endproc

.proc PageDown
        jsr     IsAtBottom
        beq     ret

        add16   first_visible_line, #kPageScrollDelta, first_visible_line
        cmp16   first_visible_line, max_visible_line ; too far down?
        bcs     ForceScrollBottom                    ; yes, clamp to bottom
        jsr     UpdateScrollPos

ret:    rts
.endproc

.proc ScrollBottom
        jsr     IsAtBottom
        beq     ret

force:  copy16  max_visible_line, first_visible_line
        jsr     UpdateScrollPos

ret:    rts
.endproc
ForceScrollBottom := ScrollBottom::force

;;; ============================================================

.proc UpdateScrollPos
        ;; Update viewport
        copy16  first_visible_line, multiplier
        copy16  #kLineScrollDelta * kLineHeight, multiplicand
        jsr     Mul_16_16
        ldax    product
        stax    winfo::maprect::y1
        addax   #kDAHeight, winfo::maprect::y2

        ;; Update thumb position

        ;; `updatethumb_params::thumbpos` = `first_visible_line` * 256 / `max_visible_line`
        ;; [8] = ([16] << 8) / [16]
        lda     #0              ; zero everything
        ldx     #3
:       sta     numerator,x
        sta     denominator,x
        dex
        bpl     :-
        copy16  first_visible_line, numerator+1 ; = `first_visible_line` * 256
        copy16  max_visible_line, denominator   ; = `max_visible_line`
        jsr     Div_32_32
        lda     quotient+1
    IF_NOT_ZERO
        lda     #kVScrollMax
    ELSE
        lda     quotient
    END_IF
        sta     updatethumb_params::thumbpos

        copy    #MGTK::Ctl::vertical_scroll_bar, updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params

        jmp     DrawContent
.endproc

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
.endproc

;;; ============================================================
;;; UI Helpers

.proc ClearWindow
        MGTK_CALL MGTK::SetPattern, white_pattern
        MGTK_CALL MGTK::PaintRect, winfo::maprect::x1
        MGTK_CALL MGTK::SetPattern, black_pattern
        rts
.endproc

;;; ============================================================
;;; Content Rendering

.proc DrawContent
        ptr := $06

        lda     #0
        sta     view_dirty_flag

        sta     buf_mark
        sta     buf_mark+1

        lda     fixed_mode_flag
    IF_ZERO
        MGTK_CALL MGTK::SetFont, DEFAULT_FONT
    ELSE
        MGTK_CALL MGTK::SetFont, fixed_font
    END_IF

        jsr     SetFileMark
        lda     #<default_buffer
        sta     read_params::data_buffer
        sta     ptr
        lda     #>default_buffer
        sta     read_params::data_buffer+1
        sta     ptr+1
        lda     #0
        sta     L0945
        sta     L0946
        sta     read_flag
        sta     line_pos::base+1
        sta     current_line
        sta     current_line+1
        sta     visible_flag

        add16   first_visible_line, #kLinesPerPage - 1, last_visible_line
        copy    #kLineSpacing, line_pos::base
        jsr     ResetLine

do_line:
        lda     current_line+1
        cmp     first_visible_line+1
        bne     :+
        lda     current_line
        cmp     first_visible_line
        bne     :+
        jsr     ClearWindow
        inc     visible_flag
:
        ;; Position cursor, update remaining width
moveto: MGTK_CALL MGTK::MoveTo, line_pos
        sec
        lda     #<kWrapWidth
        sbc     line_pos::left
        sta     remaining_width
        lda     #>kWrapWidth
        sbc     line_pos::left+1
        sta     remaining_width+1

        ;; Identify next run of characters
        jsr     FindTextRun
        bcs     done

        ;; Update pointer into buffer for next time
        clc
        lda     drawtext_params::textlen
        adc     ptr
        sta     ptr
        bcc     :+
        inc     ptr+1
:
        ;; Did the run end due to a tab?
        lda     tab_flag
        bne     moveto          ; yes, keep going

        ;; Nope - wrap to next line!
        clc
        lda     line_pos::base
        adc     #kLineSpacing
        sta     line_pos::base
        bcc     :+
        inc     line_pos::base+1
:       jsr     ResetLine

        ;; Have we drawn all visible lines?
        lda     current_line
        cmp     last_visible_line
        bne     :+
        lda     current_line+1
        cmp     last_visible_line+1
        beq     done
:
        ;; Nope - continue on next line
        inc     current_line
        bne     :+
        inc     current_line+1
:       jmp     do_line

done:   MGTK_CALL MGTK::SetFont, DEFAULT_FONT
        lda     visible_flag
        bne     :+
        jsr     ClearWindow
:
        sub16   ptr, #default_buffer, ptr
        add16   ptr, buf_mark, buf_mark
        rts


;;; `first_visible_line` + `kLinesPerPage`
last_visible_line:
        .word   0

current_line:
        .word   0
.endproc

;;; ============================================================
;;; Input: A = character
;;; Output: A = width

.proc GetCharWidth
        tay
        lda     fixed_mode_flag
    IF_ZERO
        lda     DEFAULT_FONT + MGTK::Font::charwidth,y
    ELSE
        lda     fixed_font + MGTK::Font::charwidth,y
    END_IF
        rts
.endproc

;;; ============================================================

.proc ResetLine
        copy16  #kWrapWidth, remaining_width
        copy16  #3, line_pos::left
        sta     tab_flag        ; reset
        rts
.endproc

;;; ============================================================

.proc FindTextRun
        ptr := $06

        lda     #$FF
        sta     L0F9B
        lda     #0
        sta     run_width
        sta     run_width+1
        sta     tab_flag
        sta     drawtext_params::textlen
        copy16  ptr, drawtext_params::textptr

loop:   lda     L0945
        bne     more
        lda     read_flag
        beq     :+
        jsr     DrawTextRun
        sec
        rts

:       jsr     EnsurePageBuffered
more:   ldy     drawtext_params::textlen
        lda     (ptr),y
        and     #CHAR_MASK
        sta     (ptr),y
        inc     L0945
        cmp     #CHAR_RETURN
        beq     FinishTextRun
        cmp     #' '
        bne     :+

        sty     L0F9B
        pha
        lda     L0945
        sta     L0946
        pla

:       cmp     #CHAR_TAB
        jeq     HandleTab

        jsr     GetCharWidth
        clc
        adc     run_width
        sta     run_width
        bcc     :+
        inc     run_width+1
:
        ;; Is there room?
        lda     remaining_width+1
        cmp     run_width+1
        bne     :+
        lda     remaining_width
        cmp     run_width
:       bcc     :+
        inc     drawtext_params::textlen
        jmp     loop

:       lda     #0
        sta     tab_flag
        lda     L0F9B
        cmp     #$FF
        beq     :+
        sta     drawtext_params::textlen
        lda     L0946
        sta     L0945
:       inc     drawtext_params::textlen
        FALL_THROUGH_TO FinishTextRun
.endproc

.proc FinishTextRun
        ptr := $06

        jsr     DrawTextRun
        ldy     drawtext_params::textlen
        lda     (ptr),y
        cmp     #CHAR_TAB
        beq     tab
        cmp     #CHAR_RETURN
        bne     :+
tab:    inc     drawtext_params::textlen
:       clc
        rts
.endproc

;;; ============================================================

L0F9B:  .byte   0
run_width:  .word   0

.proc HandleTab
        lda     #1
        sta     tab_flag
        add16   run_width, line_pos::left, line_pos::left
        ldx     #0
loop:   lda     times70+1,x
        cmp     line_pos::left+1
        bne     :+
        lda     times70,x
        cmp     line_pos::left
:       bcs     :+
        inx
        inx
        cpx     #14
        beq     done
        jmp     loop
:       copy16  times70,x, line_pos::left
        jmp     FinishTextRun
done:   lda     #0
        sta     tab_flag
        jmp     FinishTextRun

times70:.word   70
        .word   140
        .word   210
        .word   280
        .word   350
        .word   420
        .word   490
.endproc

;;; ============================================================
;;; Draw a line of content

.proc DrawTextRun
        lda     visible_flag    ; skip if not in visible range
        beq     end
        lda     drawtext_params::textlen
        beq     end
        MGTK_CALL MGTK::DrawText, drawtext_params
        lda     #1
        sta     view_dirty_flag
end:    rts
.endproc

;;; ============================================================

.proc EnsurePageBuffered
        ptr := $06

        ;; Pointing at second page already?
        lda     drawtext_params::textptr+1
        cmp     #>default_buffer
        beq     read

        ;; No, shift second page down.
        ldy     #0
loop:   lda     default_buffer+$100,y
        sta     default_buffer,y
        iny
        bne     loop

        dec     drawtext_params::textptr+1
        copy16  drawtext_params::textptr, ptr
        inc     buf_mark+1

        ;; Read into second page.
read:   lda     #0
        sta     L0945
        jsr     ReadFilePage
        lda     read_params::data_buffer+1
        cmp     #>default_buffer
        bne     :+
        inc     read_params::data_buffer+1
:       rts
.endproc

;;; ============================================================

.proc ReadFilePage
        copy16  read_params::data_buffer, @store_addr

        lda     #' '            ; fill buffer with spaces
        ldx     #0
        sta     RAMWRTOFF

        @store_addr := *+1
store:  sta     default_buffer,x         ; self-modified
        inx
        bne     store

        sta     RAMWRTON        ; read file chunk
        lda     #0
        sta     read_flag
        jsr     ReadFile

        pha                     ; copy read buffer main>aux
        lda     #$00
        sta     STARTLO
        sta     DESTINATIONLO
        lda     #$FF
        sta     ENDLO
        lda     read_params::data_buffer+1
        sta     DESTINATIONHI
        sta     STARTHI
        sta     ENDHI
        sec                     ; main>aux
        jsr     AUXMOVE
        pla

        beq     end
        cmp     #ERR_END_OF_FILE
        beq     done
        brk                     ; crash on other error
done:   lda     #1
        sta     read_flag
end:    rts
.endproc

;;; ============================================================

;;; Assumes `buf_mark` represents the amount of file read for
;;; filling the first screen, and `get_eof_params::eof` is the
;;; file size.

.proc InitScrollBar
        lda     get_eof_params::eof+2
    IF_NE
        ;; File is > 64k, cap to 64k (and ignore bankbyte)
        lda     #$FF
        sta     get_eof_params::eof
        sta     get_eof_params::eof+1
    END_IF
        ;; Treat get_eof_params::eof as 16 bit from here.

        cmp16   buf_mark, get_eof_params::eof
    IF_GE
        ;; File entirely fit; deactivate scrollbar
        copy    #0, activatectl_params::activate
        copy    #MGTK::Ctl::vertical_scroll_bar, activatectl_params::which_ctl
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
        rts
    END_IF

        ;; Use fraction of document shown (`buf_mark` / `eof`) and
        ;; the number of lines on a page (`kLinesPerPage`)
        ;; to guestimate the number of lines in the file.
        ;; num_lines = `kFudgePercent` * `kLinesPerPage` * ( `eof` / `buf_mark` )
        ;; `max_visible_line` = num_lines - `kLinesPerPage`
        kFudgePercent = 15      ; over-estimate by 15%
        copy16  #(kLinesPerPage * (kFudgePercent+100) / 100), multiplier
        copy16  get_eof_params::eof, multiplicand
        jsr     Mul_16_16
        copy32  product, numerator
        copy16  buf_mark, denominator
        copy16  #0, denominator+2
        jsr     Div_32_32

        lda     quotient+2
        ora     quotient+3
    IF_NOT_ZERO
        ;; Maxed out
        copy16  #($FFFF - kLinesPerPage), max_visible_line
    ELSE
        sub16   quotient, #kLinesPerPage, max_visible_line
    END_IF

        copy    #1, activatectl_params::activate
        copy    #MGTK::Ctl::vertical_scroll_bar, activatectl_params::which_ctl
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
        rts
.endproc

;;; ============================================================
;;; Title Bar (Proportional/Fixed mode button)

.proc OnTitleBarClick
        lda     event_params::xcoord+1           ; mouse x high byte?
        cmp     mode_mapinfo_viewloc_xcoord+1
        bne     :+
        lda     event_params::xcoord
        cmp     mode_mapinfo_viewloc_xcoord
:       bcs     ToggleMode
        clc                     ; Click ignored
        rts
.endproc

.proc ToggleMode
        ;; Toggle the state and redraw
        lda     fixed_mode_flag
        eor     #$FF
        sta     fixed_mode_flag

        jsr     DrawMode
        jsr     ForceScrollTop
        jsr     InitScrollBar
        sec                     ; Click consumed
        rts
.endproc

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
.endparams
mode_mapinfo_viewloc_xcoord := mode_mapinfo::viewloc::xcoord

        DEFINE_POINT mode_pos, 0, 9

.params winframerect_params
window_id:      .byte   kDAWindowId
        DEFINE_RECT rect, 0, 0, 0, 0
.endproc

;;; ============================================================

.proc CalcAndDrawMode

        MGTK_CALL MGTK::GetWinFrameRect, winframerect_params

        sub16_8 winframerect_params::rect::x2, #kLabelWidth+1, mode_mapinfo::viewloc::xcoord
        add16_8 winframerect_params::rect::y1, #1, mode_mapinfo::viewloc::ycoord

        FALL_THROUGH_TO DrawMode
.endproc

.proc DrawMode
        ;; Set up port
        MGTK_CALL MGTK::SetPortBits, mode_mapinfo

        ;; Clear background
        MGTK_CALL MGTK::SetPattern, white_pattern
        MGTK_CALL MGTK::PaintRect, mode_mapinfo::maprect

        ;; Center string
        text_params     := $6
        text_addr       := text_params + 0
        text_length     := text_params + 2
        text_width      := text_params + 3

        lda     fixed_mode_flag
    IF_NOT_ZERO
        ldax    #fixed_str
    ELSE
        ldax    #prop_str
    END_IF
        stax    text_addr

        ldy     #0
        lda     (text_addr),y
        sta     text_length
        inc16   text_addr       ; point past length
        MGTK_CALL MGTK::TextWidth, text_params

        sub16   #kLabelWidth, text_width, mode_pos::xcoord
        lsr16   mode_pos::xcoord ; /= 2
        MGTK_CALL MGTK::MoveTo, mode_pos
        MGTK_CALL MGTK::DrawText, text_params

        ;; Reset port
        COPY_STRUCT MGTK::MapInfo, default_port, winfo::port
        MGTK_CALL MGTK::SetPortBits, winfo::port
        rts
.endproc

;;; ============================================================
;;; 32 bit by 32 bit division with 32 bit result
;;; Based on: https://www.reddit.com/r/asm/comments/nbu2dj/32_bit_division_subroutine_on_the_6502/gy21eog/

numerator       := $10
denominator     := $14
quotient        := numerator

.proc Div_32_32
remainder       := $18
temp            := $1C

        ldx     #4-1
        lda     #0
:       sta     remainder,x
        dex
        bpl     :-

        ldx     #32             ; bits
divloop:
        asl     numerator+0
        rol     numerator+1
        rol     numerator+2
        rol     numerator+3

        rol     remainder+0
        rol     remainder+1
        rol     remainder+2
        rol     remainder+3

        sec
subtract:
        lda     remainder+0
        sbc     denominator+0
        sta     temp+0

        lda     remainder+1
        sbc     denominator+1
        sta     temp+1

        lda     remainder+2
        sbc     denominator+2
        sta     temp+2

        lda     remainder+3
        sbc     denominator+3
        sta     temp+3

        bcc     next            ; remainder > divisor?
        inc     numerator       ; yes

        ldy     #4-1            ; remainder = temp
:       lda     temp,y
        sta     remainder,y
        dey
        bpl     :-

next:   dex
        bne     divloop

        rts
.endproc

;;; ============================================================
;;; 16 bit by 16 bit multiply with 32 bit product

multiplier      := $10
multiplicand    := $12
product         := $14

.proc Mul_16_16
        lda     #0
        sta     product+2
        sta     product+3

        ldx     #16
shift:
        lsr     multiplier+1
        ror     multiplier
        bcc     rotate
        lda     product+2
        clc
        adc     multiplicand
        sta     product+2
        lda     product+3
        adc     multiplicand+1
rotate:
        ror     a
        sta     product+3
        ror     product+2
        ror     product+1
        ror     product
        dex
        bne     shift

        rts
.endproc

;;; ============================================================

fixed_font:
        .incbin .concat("../mgtk/fonts/Monaco.", kBuildLang)

;;; ============================================================

da_end:

        .assert * <= default_buffer, error, .sprintf("DA overlaps with read buffer: $%04x", *)
