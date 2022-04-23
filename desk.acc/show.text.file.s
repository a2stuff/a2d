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

        jmp     Copy2Aux
.endproc


save_stack:.byte   0

;;; Copy $800 through $13FF (the DA) to aux
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
.endproc

call_main_trampoline   := $20 ; installed on ZP, turns off auxmem and calls...
call_main_addr         := call_main_trampoline+7        ; address patched in here

;;; Copy the following "CallMainTemplate" routine to $20
.scope
        sta     RAMWRTON
        sta     RAMRDON
        COPY_BYTES sizeof_CallMainTemplate+1, CallMainTemplate, call_main_trampoline
        jmp     CallInit
.endscope

.proc CallMainTemplate
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     SELF_MODIFIED   ; overwritten (in zp version)
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc
        sizeof_CallMainTemplate = .sizeof(CallMainTemplate)

.macro TRAMP_CALL addr
        copy16  #addr, call_main_addr
        jsr     call_main_trampoline
.endmacro

.macro TRAMP_CALL_WITH_A addr
        pha
        copy16  #addr, call_main_addr
        pla
        jsr     call_main_trampoline
.endmacro

;;; ============================================================

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

;;; ============================================================
;;; ProDOS MLI calls

.proc OpenFile
        jsr     CopyParamsAuxToMain
        sta     ALTZPOFF
        MLI_CALL OPEN, open_params
        sta     ALTZPON
        jsr     CopyParamsMainToAux
        rts
.endproc

.proc ReadFile
        jsr     CopyParamsAuxToMain
        sta     ALTZPOFF
        MLI_CALL READ, read_params
        sta     ALTZPON
        jsr     CopyParamsMainToAux
        rts
.endproc

.proc GetFileEof
        jsr     CopyParamsAuxToMain
        sta     ALTZPOFF
        MLI_CALL GET_EOF, get_eof_params
        sta     ALTZPON
        jsr     CopyParamsMainToAux
        rts
.endproc

.proc SetFileMark
        jsr     CopyParamsAuxToMain
        sta     ALTZPOFF
        MLI_CALL SET_MARK, set_mark_params
        sta     ALTZPON
        jsr     CopyParamsMainToAux
        rts
.endproc

.proc CloseFile
        jsr     CopyParamsAuxToMain
        sta     ALTZPOFF
        MLI_CALL CLOSE, close_params
        sta     ALTZPON
        jsr     CopyParamsMainToAux
        rts
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
        pha
        php
        sta     RAMWRTON
        ldy     #(params_end - params_start + 1)
loop:   lda     params_start - 1,y
        sta     params_start - 1,y
        dey
        bne     loop
        sta     RAMRDON
        plp
        pla
        rts
.endproc

;;; ----------------------------------------

params_start:
;;; This block gets copied between main/aux

;;; ProDOS MLI param blocks

;;; Two pages of data are read, but separately.
default_buffer  := $1700
kReadLength      = $0100

        .assert default_buffer + $200 < $1B00, error, "DA too big"
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
L0947:  .byte   $00
visible_flag:                   ; clear until text that should be visible is in view
        .byte   0
L0949:  .byte   $00

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

window_width:   .word   0
window_height:  .word   0

y_remaining:    .word   0

;;; Height of a line of text
kLineHeight = kSystemFontHeight + 1

;;; Number of lines per scroll tick
kScrollDelta = 1

;;; Farthest offset into the file that `DrawContent` made it
buf_mark:
        .word   0

last_visible_line:
        .word   0
first_visible_line:
        .word   0
current_line:
        .word   0

;;; Scroll by this number of ticks when doing page up/down
page_scroll_delta:
        .byte   0

fixed_mode_flag:
        .byte   0               ; 0 = proportional, otherwise = fixed

.params event_params
kind:  .byte   0

;;; if state is MGTK::EventKind::key_down
key             := *
modifiers       := *+1

;;; otherwise
coords  := *
mousex  := *                      ; spills into target query
mousey  := *+2

        .res    4               ; space for both
.endparams

.params findwindow_params       ; TODO: Make this address correct, via union
which_area:   .byte   0
window_id:    .byte   0
.endparams

.params growwindow_params
window_id:     .byte   kDAWindowId
mousex: .word   0
mousey: .word   0
it_grew:        .byte   0
.endparams

.params trackgoaway_params ; queried after close clicked to see if aborted/finished
goaway: .byte   0        ; 0 = aborted, 1 = clicked
.endparams

        .byte   0,0             ; ???

.params findcontrol_params        ; queried after a client click to identify target
mousex: .word   0
mousey: .word   0
which_ctl:      .byte   0       ; 0 = client, 1 = vscroll, 2 = hscroll
which_part:     .byte   0       ; 1 = up, 2 = down, 3 = above, 4 = below, 5 = thumb
.endparams

.params updatethumb_params      ; called to update scroll bar position
which_ctl:   .byte   0               ; 1 = vscroll, 2 = hscroll
thumbpos:    .byte   0               ; new position
.endparams

;;; Used when dragging vscroll thumb
.params trackthumb_params
which_ctl:   .byte   0               ; 1 = vscroll, 2 = hscroll
mousex: .word   0
mousey: .word   0
thumbpos:    .byte   0               ; position
thumbmoved:  .byte   0               ; 0 if not moved, 1 if moved
.endparams

.params drawtext_params
textptr:        .addr   0       ; address
textlen:        .byte   0       ; length
.endparams

kDefaultLeft    = 10
kDefaultTop     = 28
kDefaultWidth   = 512
kDefaultHeight  = 150

titlebuf:
        .res    16, 0

kVScrollMax = $FF

.params winfo
window_id:      .byte   kDAWindowId ; window identifier
options:        .byte   MGTK::Option::go_away_box ; window flags (2=include close port)
title:          .addr   titlebuf
hscroll:        .byte   MGTK::Scroll::option_none
vscroll:        .byte   MGTK::Scroll::option_normal
hthumbmax:      .byte   32
hthumbpos:      .byte   0
vthumbmax:      .byte   kVScrollMax
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   200
mincontlength:  .word   51
maxcontwidth:   .word   kDefaultWidth
maxcontlength:  .word   kDefaultHeight
port:
        DEFINE_POINT viewloc, kDefaultLeft, kDefaultTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDefaultWidth, kDefaultHeight
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
        DEFINE_POINT viewloc, kDefaultLeft, kDefaultTop
mapbits:        .word   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kDefaultWidth, kDefaultHeight
.endparams

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
        jsr     CalcWindowSize
        jsr     CalcPageScrollDelta
        jsr     CalcAndDrawMode
        jsr     DrawContent
        jsr     InitScrollBar
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc

;;; ============================================================
;;; Main Input Loop

.proc InputLoop
        jsr     YieldLoop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params
        cmp     #MGTK::EventKind::key_down    ; key?
        beq     OnKeyDown
        cmp     #MGTK::EventKind::button_down ; was clicked?
        bne     InputLoop      ; nope, keep waiting

        MGTK_CALL MGTK::FindWindow, event_params::coords
        lda     findwindow_params::window_id ; in our window?
        cmp     #kDAWindowId
        bne     InputLoop

        ;; which part of the window?
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        jeq     OnCloseClick

        ;; title and resize clicks need mouse location
        ldx     event_params::mousex
        stx     growwindow_params::mousex
        stx     findcontrol_params::mousex
        ldx     event_params::mousex+1
        stx     growwindow_params::mousex+1
        stx     findcontrol_params::mousex+1
        ldx     event_params::mousey
        stx     growwindow_params::mousey
        stx     findcontrol_params::mousey

        cmp     #MGTK::Area::dragbar
        beq     title
        cmp     #MGTK::Area::grow_box ; not enabled, so this will never match
        beq     InputLoop
        jsr     OnClientClick
        jmp     InputLoop

title:  jsr     OnTitleBarClick
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
        cmp     #CHAR_UP        ; Apple-Up = Page Up
      IF_EQ
        jsr     PageUp
        jmp     InputLoop
      END_IF

        cmp     #CHAR_DOWN      ; Apple-Down = Page Down
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
;;; Close Button

.proc OnCloseClick
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::goaway ; did click complete?
        bne     DoClose                    ; yes
        jmp     InputLoop                  ; no
.endproc

.proc DoClose
        jsr     CloseFile
        MGTK_CALL MGTK::CloseWindow, winfo
        jsr     ClearUpdates
        rts                     ; exits input loop
.endproc

;;; ============================================================
;;; Client Area

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
;;; Vertical Scroll Bar

.proc OnVScrollClick
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     trackthumb_params::which_ctl
        sta     updatethumb_params::which_ctl
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
        jeq     OnVScrollDownClick
        rts
.endproc

.proc OnVScrollThumbClick
        jsr     DoTrackthumb
        lda     trackthumb_params::thumbmoved
        beq     end
        lda     trackthumb_params::thumbpos
        sta     updatethumb_params::thumbpos
        jsr     UpdateVOffset
        jsr     UpdateVThumb
        jsr     DrawContent
        lda     L0947
        beq     end
        lda     L0949
        bne     end
        jsr     ClearWindow
end:    rts
.endproc

.proc OnVScrollAboveClick
loop:   jsr     PageUp
        jsr     CheckButtonRelease
        bcc     loop            ; repeat while button down
end:    rts
.endproc

.proc PageUp
        lda     winfo::vthumbpos
        beq     end
        sec
        lda     winfo::vthumbpos
        sbc     page_scroll_delta
        bcs     store
        lda     #0              ; underflow
store:  sta     updatethumb_params::thumbpos
        jsr     UpdateScrollPos
end:    rts
.endproc

.proc OnVScrollUpClick
loop:   jsr     ScrollUp
        jsr     CheckButtonRelease
        bcc     loop            ; repeat while button down
end:    rts
.endproc

.proc ScrollUp
        lda     winfo::vthumbpos
        beq     end
        sec
        sbc     #1
        sta     updatethumb_params::thumbpos
        jsr     UpdateScrollPos
end:    rts
.endproc

.proc ScrollTop
        lda     winfo::vthumbpos
        beq     end
force:  copy    #0, updatethumb_params::thumbpos
        jsr     UpdateScrollPos
end:    rts
.endproc
ForceScrollTop := ScrollTop::force

.proc OnVScrollBelowClick
loop:   jsr     PageDown
        jsr     CheckButtonRelease
        bcc     loop            ; repeat while button down
end:    rts
.endproc

.proc PageDown
        lda     winfo::vthumbpos
        cmp     winfo::vthumbmax ; pos == max ?
        beq     end
        clc
        lda     winfo::vthumbpos
        adc     page_scroll_delta ; pos + delta
        bcs     overflow
        cmp     winfo::vthumbmax ; >= max ?
        bcc     store            ; nope, it's good
overflow:
        lda     winfo::vthumbmax ; set to max
store:  sta     updatethumb_params::thumbpos
        jsr     UpdateScrollPos
end:    rts
.endproc

.proc OnVScrollDownClick
loop:   jsr     ScrollDown
        jsr     CheckButtonRelease
        bcc     loop            ; repeat while button down
end:    rts
.endproc

.proc ScrollDown
        lda     winfo::vthumbpos
        cmp     winfo::vthumbmax
        beq     end
        clc
        adc     #1
        sta     updatethumb_params::thumbpos
        jsr     UpdateScrollPos
end:    rts
.endproc

.proc ScrollBottom
        lda     winfo::vthumbpos
        cmp     winfo::vthumbmax
        beq     end
        copy    winfo::vthumbmax, updatethumb_params::thumbpos
        jsr     UpdateScrollPos
end:    rts
.endproc

.proc UpdateScrollPos       ; Returns with carry set if mouse released
        jsr     UpdateVOffset
        jsr     UpdateVThumb
        jsr     DrawContent
        rts
.endproc

.proc CheckButtonRelease
        jsr     WasButtonReleased
        clc
        bne     end
        sec
end:    rts
.endproc

.proc CalcPageScrollDelta
        ldax    window_height
        ldy     #kScrollDelta * kLineHeight
        jsr     Divide_16_8_16
        sta     page_scroll_delta
        dec     page_scroll_delta ; leave some overlap
        rts
.endproc

;;; ============================================================
;;; UI Helpers

        ;; Used at start of thumb EventKind::drag
.proc DoTrackthumb
        copy16  event_params::mousex, trackthumb_params::mousex
        lda     event_params::mousey
        sta     trackthumb_params::mousey
        MGTK_CALL MGTK::TrackThumb, trackthumb_params
        rts
.endproc

;;; Checks button state; z clear if button was released, set otherwise
.proc WasButtonReleased
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params
        cmp     #2
        rts
.endproc

.proc UpdateVOffset
        lda     updatethumb_params::thumbpos ; lo
        ldx     #0                           ; hi
        ldy     #kScrollDelta * kLineHeight
        jsr     Multiply_16_8_16
        stax    winfo::maprect::y1
        addax   window_height, winfo::maprect::y2

        jsr     CalcLinePosition

        lda     updatethumb_params::thumbpos ; lo
        ldx     #0                           ; hi
        ldy     #kScrollDelta
        jsr     Multiply_16_8_16
        stax    first_visible_line

        rts
.endproc

.proc UpdateHScroll
        lda     #MGTK::Ctl::horizontal_scroll_bar
        sta     updatethumb_params::which_ctl

        val := $06
        copy16  winfo::maprect::x1, val
        jsr     DivBy16
        sta     updatethumb_params::thumbpos
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        rts
.endproc

.proc UpdateVThumb       ; updatethumb_params::thumbpos set by caller
        lda     #MGTK::Ctl::vertical_scroll_bar
        sta     updatethumb_params::which_ctl
        MGTK_CALL MGTK::UpdateThumb, updatethumb_params
        rts
.endproc

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
        sta     L0949

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
        sta     L0947
        sta     line_pos::base+1
        sta     current_line
        sta     current_line+1
        sta     visible_flag
        lda     #kLineSpacing
        sta     line_pos::base
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
        lda     L0947
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
        sta     L0949
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
        sta     L0947
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
        sta     L0947
end:    rts
.endproc

;;; ============================================================

.proc CalcWindowSize
        sub16   winfo::maprect::x2, winfo::maprect::x1, window_width
        sub16   winfo::maprect::y2, winfo::maprect::y1, window_height
        FALL_THROUGH_TO CalcLinePosition
.endproc

;;; ============================================================

.proc CalcLinePosition
        copy16  winfo::maprect::y2, y_remaining
        copy16  #0, last_visible_line

loop:   lda     y_remaining+1
        bne     :+
        lda     y_remaining
        cmp     #kLineSpacing
        bcc     end

:       sec
        lda     y_remaining
        sbc     #kLineSpacing
        sta     y_remaining
        bcs     :+
        dec     y_remaining+1
:       inc     last_visible_line
        bne     loop
        inc     last_visible_line+1
        jmp     loop

end:    rts
.endproc

;;; ============================================================
;;; Assumes `buf_mark` represents the amount of file read for
;;; filling the first screen, and `get_eof_params::eof` is the
;;; file size.

.params setctlmax_params
which_ctl:      .byte   MGTK::Ctl::vertical_scroll_bar
ctlmax:         .byte   0
.endparams

.params activatectl_params
which_ctl:      .byte   MGTK::Ctl::vertical_scroll_bar
activate:       .byte   0
.endparams

.proc InitScrollBar
        lda     get_eof_params::eof+2
    IF_NE
        ;; File is > 64k, just use max scrollbar
        copy    #kVScrollMax, setctlmax_params::ctlmax
        MGTK_CALL MGTK::SetCtlMax, setctlmax_params
        copy    #1, activatectl_params::activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
        rts
    END_IF

        cmp16   buf_mark, get_eof_params::eof
    IF_POS
        ;; File entirely fit; deactivate scrollbar
        copy    #0, activatectl_params::activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
        rts
    END_IF

        ;; Use fraction of document shown (`eof` / `buf_mark`) and
        ;; the number of lines on a page (`page_scroll_delta`+1)
        ;; to guestimate the number of lines in the file.
        lda     get_eof_params::eof+1 ; lo
        ldx     #0                    ; hi
        ldy     buf_mark+1
        jsr     Divide_16_8_16
        ldy     page_scroll_delta
        jsr     Multiply_16_8_16
        sta     setctlmax_params::ctlmax
        MGTK_CALL MGTK::SetCtlMax, setctlmax_params
        copy    #1, activatectl_params::activate
        MGTK_CALL MGTK::ActivateCtl, activatectl_params
        rts
.endproc

;;; ============================================================

.proc DivBy16                   ; input in $06/$07, output in a
        val := $06

        ldx     #4
loop:   clc
        ror     val+1
        ror     val
        dex
        bne     loop
        lda     val
        rts
.endproc

;;; ============================================================

.proc ClearUpdates
        TRAMP_CALL JUMP_TABLE_CLEAR_UPDATES
        rts
.endproc

;;; ============================================================
;;; Title Bar (Proportional/Fixed mode button)

.proc OnTitleBarClick
        lda     event_params::mousex+1           ; mouse x high byte?
        cmp     mode_mapinfo_viewloc_xcoord+1
        bne     :+
        lda     event_params::mousex
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
        kLabelWidth = 80
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
        DEFINE_RECT mode_rect, 0, 0, kLabelWidth, kLabelHeight

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
        MGTK_CALL MGTK::PaintRect, mode_rect

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

        .include "../lib/muldiv.s"

;;; ============================================================

fixed_font:
        .incbin "../mgtk/fonts/fixed_width"

;;; ============================================================

da_end:

        .assert * <= default_buffer, error, .sprintf("DA overlaps with read buffer: $%04x", *)
