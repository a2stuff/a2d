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

        kMaxStringLength = 48

buf:    .byte   res_string_message_placeholder
        .res    kMaxStringLength - (* - buf),0

font:   .incbin "../mgtk/fonts/ATHENS"

.params text_params
data:   .addr   buf
length: .byte   .strlen(res_string_message_placeholder)
width:  .word   0               ; for `TextWidth` call
.endparams

        DEFINE_RECT rect, 0, (kScreenHeight - kFontHeight)/2, kScreenWidth-1, (kScreenHeight + kFontHeight)/2

event_params:   .tag MGTK::Event

notpencopy:     .byte   MGTK::notpencopy
textbg:         .byte   0

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
        cmp     #' '
        bcs     printable

        ;; --------------------------------------------------
        ;; Non-printable
        cmp     #CHAR_ESCAPE
        beq     InputLoop::exit

        cmp     #CHAR_LEFT
    IF_EQ
        dec16   delta
        jmp     InputLoop
    END_IF

        cmp     #CHAR_RIGHT
    IF_EQ
        inc16   delta
        jmp     InputLoop
    END_IF

        jmp     InputLoop

        ;; --------------------------------------------------
        ;; Printable

printable:
        bit     placeholder_flag
    IF_NS
        ldx     #0
        stx     text_params::length
        stx     placeholder_flag
    END_IF

        ldx     text_params::length
        cpx     #kMaxStringLength
    IF_LT
        sta     buf,x
        inc     text_params::length
    END_IF

        jmp     InputLoop

        ;; --------------------------------------------------
        ;; Backspace

backspace:
        bit     placeholder_flag
    IF_NS
        ldx     #0
        stx     text_params::length
        stx     placeholder_flag
    END_IF

        lda     text_params::length
    IF_NOT_ZERO
        dec     text_params::length
    END_IF

        jmp     InputLoop

.endproc ; HandleKeyDown

;;; ============================================================
;;; Animate

.proc Animate
        MGTK_CALL MGTK::MoveTo, text_pos

        lda     text_params::length
    IF_ZERO
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
      IF_NEG
        MGTK_CALL MGTK::PaintRect, rect
      END_IF

        add16   text_pos::xcoord, text_params::width, rect::x1
        copy16  #kScreenWidth-1, rect::x2
        scmp16  rect::x1, rect::x2
      IF_NEG
        MGTK_CALL MGTK::PaintRect, rect
      END_IF

    END_IF

        add16   text_pos::xcoord, delta, text_pos::xcoord

        lda     delta+1
    IF_NS
        tmp := $06
        add16   text_pos::xcoord, text_params::width, tmp
        lda     tmp+1
      IF_NS
        copy16  #kScreenWidth-1, text_pos::xcoord
      END_IF
    ELSE
        scmp16  text_pos::xcoord, #kScreenWidth
      IF_POS
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
