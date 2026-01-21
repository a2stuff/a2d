;;; ============================================================
;;; MESSAGE - Desk Accessory
;;;
;;; The typed message scrolls across the screen
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "message.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

.proc AuxStart
        ;; Run the DA
        jmp     Init
.endproc ; AuxStart

;;; ============================================================
;;; Resources

        kFontHeight = 11

delta:  .word   AS_WORD(-3)
        DEFINE_POINT text_pos, kScreenWidth, (kScreenHeight + kFontHeight)/2

placeholder_flag:
        .byte   $80

        kPadChar = ' '

        ;; Limit because MGTK mispaints if string is wider than screen
        kMaxStringLength = 44

        ;; Always leave enough for a leading and trailing space
buf:    .byte   .sprintf("%c%s%c", kPadChar, res_string_message_placeholder, kPadChar)
        .res    kMaxStringLength - (* - buf),0

font:   .incbin "../../res/fonts/Athens"

.params text_params
data:   .addr   buf
length: .byte   .strlen(res_string_message_placeholder)+2
width:  .word   0               ; for `TextWidth` call
.endparams

        DEFINE_RECT rect, 0, (kScreenHeight - kFontHeight)/2, kScreenWidth-1, (kScreenHeight + kFontHeight)/2

event_params:   .tag MGTK::Event

notpencopy:     .byte   MGTK::notpencopy
textbg:         .byte   MGTK::textbg_black

grafport:       .tag MGTK::GrafPort


;;; ============================================================
;;; DA Init

.proc Init
        MGTK_CALL MGTK::HideCursor

        MGTK_CALL MGTK::InitPort, grafport
        MGTK_CALL MGTK::SetPort, grafport

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::PaintRect, grafport + MGTK::GrafPort::maprect

        MGTK_CALL MGTK::SetFont, font
        MGTK_CALL MGTK::SetTextBG, textbg

        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

;;; ============================================================
;;; Main Input Loop

.proc InputLoop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params + MGTK::Event::kind
        cmp     #MGTK::EventKind::key_down  ; any key?
        beq     HandleKeyDown
        cmp     #MGTK::EventKind::button_down ; was clicked?
        beq     exit

        jsr     Animate
        jmp     InputLoop

exit:
        MGTK_CALL MGTK::RedrawDeskTop

        MGTK_CALL MGTK::DrawMenuBar
        JSR_TO_MAIN JUMP_TABLE_HILITE_MENU

        MGTK_CALL MGTK::ShowCursor
        rts                     ; exits input loop
.endproc ; InputLoop

;;; ============================================================
;;; Handle Key

.proc HandleKeyDown
        lda     event_params + MGTK::Event::key
        cmp     #CHAR_DELETE
        beq     backspace
        cmp     #kPadChar
        bcs     printable

        ;; --------------------------------------------------
        ;; Non-printable

        cmp     #CHAR_ESCAPE
        beq     InputLoop::exit

    IF A = #CHAR_LEFT
        dec16   delta
        jmp     InputLoop
    END_IF

    IF A = #CHAR_RIGHT
        inc16   delta
        jmp     InputLoop
    END_IF

        jmp     InputLoop

        ;; --------------------------------------------------
        ;; Printable (append char, preserving trailing space)

printable:
        jsr     maybe_init

        ldx     text_params::length
        dex
    IF X < #kMaxStringLength-1
        sta     buf,x
        copy8   #kPadChar, buf+1,x
        inc     text_params::length
    END_IF

        jmp     InputLoop

        ;; --------------------------------------------------
        ;; Backspace (truncate, preserving trailing space)

backspace:
        jsr     maybe_init

        lda     text_params::length
    IF A >= #3
        dec     text_params::length
        ldx     text_params::length
        copy8   #kPadChar, buf-1,x
    END_IF

        jmp     InputLoop

        ;; --------------------------------------------------
        ;; Initialize on first input
        ;; Preserves A
maybe_init:
        bit     placeholder_flag
    IF NS
        ldx     #0
        stx     placeholder_flag
        ldx     #2
        stx     text_params::length
        ldx     #kPadChar
        stx     buf+1
    END_IF
        rts

.endproc ; HandleKeyDown

;;; ============================================================
;;; Animate

.proc Animate
        ;; Pace the animation
        MGTK_CALL MGTK::WaitVBL

        MGTK_CALL MGTK::MoveTo, text_pos

        lda     text_params::length
    IF ZERO
        copy16  #0, rect::x1
        copy16  #kScreenWidth-1, rect::x2
        MGTK_CALL MGTK::PaintRect, rect
    ELSE
        MGTK_CALL MGTK::DrawText, text_params
        MGTK_CALL MGTK::TextWidth, text_params

        ;; Clear before/after
        copy16  #0, rect::x1
        sub16   text_pos::xcoord, #1, rect::x2
        scmp16  rect::x1, rect::x2
      IF NEG
        MGTK_CALL MGTK::PaintRect, rect
      END_IF

        add16   text_pos::xcoord, text_params::width, rect::x1
        copy16  #kScreenWidth-1, rect::x2
        scmp16  rect::x1, rect::x2
      IF NEG
        MGTK_CALL MGTK::PaintRect, rect
      END_IF

    END_IF

        add16   text_pos::xcoord, delta, text_pos::xcoord

        lda     delta+1
    IF NS
        tmp := $06
        add16   text_pos::xcoord, text_params::width, tmp
        lda     tmp+1
      IF NS
        copy16  #kScreenWidth-1, text_pos::xcoord
      END_IF
    ELSE
        scmp16  text_pos::xcoord, #kScreenWidth
      IF POS
        sub16   #0, text_params::width, text_pos::xcoord
      END_IF
    END_IF

        rts
.endproc ; Animate

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT

        JSR_TO_AUX aux::AuxStart
        rts

        DA_END_MAIN_SEGMENT

;;; ============================================================
