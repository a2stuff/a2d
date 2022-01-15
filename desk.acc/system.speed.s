;;; ============================================================
;;; SYSTEM.SPEED - Desk Accessory
;;;
;;; Allows toggling the machine's accelerator (if present)
;;; between normal and fast speed.
;;;
;;; Based on NORMFAST by "Roger" et. al. on comp.sys.apple2
;;; 3b74ddcf-190c-4591-bced-17e165ece668@googlegroups.com
;;; https://groups.google.com/d/topic/comp.sys.apple2/e-2Lx-CR1dM/discussion
;;;
;;; Should support:
;;; * Apple IIgs, IIc+, Macintosh IIe Option Card, Laser 128EX
;;; * FASTChip, Zip Chip, TransWarp I, UltraWarp
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "system.speed.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

kShortcutNorm = res_char_button_norm_shortcut
kShortcutFast = res_char_button_fast_shortcut

;;; ============================================================


        .org DA_LOAD_ADDRESS

start:
;;; ============================================================

        jmp     Copy2Aux


stash_stack:  .byte   $00

;;; ============================================================

.proc Copy2Aux

        end   := last

        tsx
        stx     stash_stack

        copy16  #start, STARTLO
        copy16  #end, ENDLO
        copy16  #start, DESTINATIONLO
        sec
        jsr     AUXMOVE

        ;; Run from Aux
        sta     RAMRDON
        sta     RAMWRTON

        jsr     RunDA

        ;; Back to main
        sta     RAMRDOFF
        sta     RAMWRTOFF

        ldx     stash_stack
        txs
        rts
.endproc

;;; ============================================================
;;; Param blocks

kDAWindowId     = 100
kDAWidth        = 290
kDAHeight       = 70
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

kButtonInsetX   = 25

        DEFINE_BUTTON norm, res_string_button_norm,   kButtonInsetX, 28
        DEFINE_BUTTON fast, res_string_button_fast,   kDAWidth - kButtonWidth - kButtonInsetX, 28
        DEFINE_BUTTON ok,   res_string_button_ok, kDAWidth - kButtonWidth - kButtonInsetX, 52

        DEFINE_LABEL title, res_string_dialog_title, 0, 18

;;; ============================================================

        .include "../lib/event_params.s"

;;; ============================================================

.params closewindow_params
window_id:     .byte   kDAWindowId
.endparams

pencopy:        .byte   0
penOR:          .byte   1
penXOR:         .byte   2
penBIC:         .byte   3
notpencopy:     .byte   4
notpenOR:       .byte   5
notpenXOR:      .byte   6
notpenBIC:      .byte   7

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
        DEFINE_POINT viewloc, kDALeft, kDATop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT cliprect, 0, 0, kDAWidth, kDAHeight
pattern:        .res    8,$FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

        DEFINE_RECT_INSET frame_rect1, 4, 2, kDAWidth, kDAHeight
        DEFINE_RECT_INSET frame_rect2, 5, 3, kDAWidth, kDAHeight


.params getwinport_params
window_id:      .byte   0
a_grafport:     .addr   grafport
.endparams

grafport:       .tag MGTK::GrafPort

;;; ============================================================
;;; Resources for an animation to show speed

kRunPosX        = 12
kRunPosY        = 51
kRunDistance    = 104
kRunWidth  = 21
kRunHeight = 11


run_pos:
        .byte   0

kCursorWidth  = 8
kCursorHeight = 12

        ;; Bounding rect for where the animation and cursor could overlap.
        ;; If the cursor is inside this rect, it is hidden before drawing
        ;; the bitmap.
        DEFINE_RECT_SZ anim_cursor_rect, kRunPosX - kCursorWidth + 1, kRunPosY - kCursorHeight + 2, kRunWidth + kRunDistance + kCursorWidth - 1, kRunHeight + kCursorHeight - 2
cursor_flag:
        .byte   0


.params frame_params
        DEFINE_POINT viewloc, kRunPosX, kRunPosY
mapbits:        .addr   frame1
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, 20, 10
.endparams

frame1:
        .byte   PX(%0000000),PX(%0000011),PX(%0000000)
        .byte   PX(%0000000),PX(%0001111),PX(%1100000)
        .byte   PX(%0000000),PX(%0001111),PX(%1100000)
        .byte   PX(%0000000),PX(%0111111),PX(%0000000)
        .byte   PX(%0000111),PX(%1001111),PX(%1100000)
        .byte   PX(%0011110),PX(%0111100),PX(%0011110)
        .byte   PX(%0000000),PX(%0111100),PX(%0000000)
        .byte   PX(%0000000),PX(%0111111),PX(%0000000)
        .byte   PX(%0011111),PX(%1110011),PX(%1100000)
        .byte   PX(%0000000),PX(%0000011),PX(%1100000)
        .byte   PX(%0000000),PX(%0000011),PX(%1100000)

frame2:
        .byte   PX(%0000000),PX(%0000011),PX(%0000000)
        .byte   PX(%0000000),PX(%0001111),PX(%1100000)
        .byte   PX(%0000000),PX(%0001111),PX(%1100000)
        .byte   PX(%0000000),PX(%0001111),PX(%0000000)
        .byte   PX(%0000000),PX(%0111111),PX(%0000000)
        .byte   PX(%0000001),PX(%1111111),PX(%1100000)
        .byte   PX(%0000001),PX(%1111111),PX(%0011110)
        .byte   PX(%0000000),PX(%0001111),PX(%1100000)
        .byte   PX(%0000000),PX(%0111111),PX(%1100000)
        .byte   PX(%0000001),PX(%1111100),PX(%0000000)
        .byte   PX(%0000000),PX(%0111100),PX(%0000000)

frame3:
        .byte   PX(%0000000),PX(%0000011),PX(%0000000)
        .byte   PX(%0000000),PX(%0001111),PX(%1100000)
        .byte   PX(%0000000),PX(%0001111),PX(%1100000)
        .byte   PX(%0000000),PX(%0001111),PX(%0000000)
        .byte   PX(%0000001),PX(%1111111),PX(%0011000)
        .byte   PX(%0000111),PX(%1001111),PX(%1111000)
        .byte   PX(%0000000),PX(%0001111),PX(%0000000)
        .byte   PX(%0000000),PX(%0111111),PX(%1100000)
        .byte   PX(%0000001),PX(%1110000),PX(%1111000)
        .byte   PX(%0000111),PX(%1000000),PX(%1111000)
        .byte   PX(%0000111),PX(%1000000),PX(%0000000)

kNumAnimFrames = 4

anim_table:
        .addr frame1
        .addr frame2
        .addr frame3
        .addr frame2
        ASSERT_ADDRESS_TABLE_SIZE anim_table, kNumAnimFrames

frame_counter:
        .byte   0


;;; ============================================================
;;; Initialize window, unpack the date.

.proc RunDA
        MGTK_CALL MGTK::OpenWindow, winfo

        MGTK_CALL MGTK::SetPort, winfo::port
        MGTK_CALL MGTK::SetPenMode, penXOR

        MGTK_CALL MGTK::FrameRect, frame_rect1
        MGTK_CALL MGTK::FrameRect, frame_rect2

        param_call DrawTitleString, title_label_str

        MGTK_CALL MGTK::FrameRect, ok_button_rect
        MGTK_CALL MGTK::MoveTo, ok_button_pos
        param_call DrawString, ok_button_label

        MGTK_CALL MGTK::FrameRect, norm_button_rect
        MGTK_CALL MGTK::MoveTo, norm_button_pos
        param_call DrawString, norm_button_label

        MGTK_CALL MGTK::FrameRect, fast_button_rect
        MGTK_CALL MGTK::MoveTo, fast_button_pos
        param_call DrawString, fast_button_label

        MGTK_CALL MGTK::FlushEvents
        ;; fall through
.endproc

;;; ============================================================
;;; Input loop

.proc InputLoop
        jsr     AnimFrame

        jsr     YieldLoop
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind

        cmp     #MGTK::EventKind::no_event
        jeq     OnMove

        cmp     #MGTK::EventKind::button_down
        jeq     OnClick

        cmp     #MGTK::EventKind::key_down
        bne     InputLoop
        ;; fall through
.endproc

.proc OnKey
        lda     event_params::modifiers
        bne     InputLoop
        lda     event_params::key

        cmp     #CHAR_RETURN
        beq     OnKeyOk

        cmp     #CHAR_ESCAPE
        beq     OnKeyOk

        cmp     #kShortcutNorm
        beq     OnKeyNorm
        cmp     #TO_LOWER(kShortcutNorm)
        beq     OnKeyNorm

        cmp     #kShortcutFast
        beq     OnKeyFast
        cmp     #TO_LOWER(kShortcutFast)
        beq     OnKeyFast

        jmp     InputLoop
.endproc

.proc OnKeyOk
        lda     winfo::window_id
        jsr     GetWindowPort
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        MGTK_CALL MGTK::PaintRect, ok_button_rect

        jmp     CloseWindow
.endproc

.proc OnKeyNorm
        lda     winfo::window_id
        jsr     GetWindowPort
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, norm_button_rect
        MGTK_CALL MGTK::PaintRect, norm_button_rect

        jsr     DoNorm
        jmp     InputLoop
.endproc

.proc OnKeyFast
        lda     winfo::window_id
        jsr     GetWindowPort
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, fast_button_rect
        MGTK_CALL MGTK::PaintRect, fast_button_rect

        jsr     DoFast
        jmp     InputLoop
.endproc

;;; ============================================================

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

.proc GetWindowPort
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        MGTK_CALL MGTK::SetPort, grafport
        rts
.endproc


;;; ============================================================

.proc OnMove
        lda     winfo::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx
        MGTK_CALL MGTK::InRect, anim_cursor_rect
        sta     cursor_flag
        jmp     InputLoop
.endproc

;;; ============================================================

.proc OnClick
        MGTK_CALL MGTK::FindWindow, findwindow_params

        lda     findwindow_params::window_id
        cmp     #kDAWindowId
        bne     miss

        lda     findwindow_params::which_area
        cmp     #MGTK::Area::content
        beq     hit

miss:   jmp     InputLoop

hit:    lda     winfo::window_id
        jsr     GetWindowPort
        lda     winfo::window_id
        sta     screentowindow_window_id
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        MGTK_CALL MGTK::MoveTo, screentowindow_windowx

        MGTK_CALL MGTK::InRect, ok_button_rect
        cmp     #MGTK::inrect_inside
        jeq     OnClickOk

        MGTK_CALL MGTK::InRect, norm_button_rect
        cmp     #MGTK::inrect_inside
        jeq     OnClickNorm

        MGTK_CALL MGTK::InRect, fast_button_rect
        cmp     #MGTK::inrect_inside
        jeq     OnClickFast

        jmp     InputLoop
.endproc

;;; ============================================================

.proc OnClickOk
        param_call ButtonEventLoop, kDAWindowId, ok_button_rect
        jeq     CloseWindow
        jmp     InputLoop
.endproc

;;; ============================================================

.proc OnClickNorm
        param_call ButtonEventLoop, kDAWindowId, norm_button_rect
        bne     :+
        jsr     DoNorm
:       jmp     InputLoop
.endproc

;;; ============================================================

.proc OnClickFast
        param_call ButtonEventLoop, kDAWindowId, fast_button_rect
        bne     :+
        jsr     DoFast
:       jmp     InputLoop
.endproc

;;; ============================================================

.proc DoNorm
        ;; Run NORMFAST with "normal" banks
        sta     RAMRDOFF
        sta     RAMWRTOFF
        sta     ALTZPOFF
        bit     ROMIN2

        jsr     NORMFAST_norm

        sta     RAMRDON
        sta     RAMWRTON
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        rts
.endproc

;;; ============================================================

.proc DoFast
        ;; Run NORMFAST with "normal" banks
        sta     RAMRDOFF
        sta     RAMWRTOFF
        sta     ALTZPOFF
        bit     ROMIN2

        jsr     NORMFAST_fast

        sta     RAMRDON
        sta     RAMWRTON
        sta     ALTZPON
        bit     LCBANK1
        bit     LCBANK1

        rts
.endproc

;;; ============================================================

.proc CloseWindow
        MGTK_CALL MGTK::CloseWindow, closewindow_params
        jsr     ClearUpdates
        rts
.endproc

;;; ============================================================
;;; Draw Title String (centered at top of port)
;;; Input: A,X = string address

.proc DrawTitleString
        text_params     := $6
        text_addr       := text_params + 0
        text_length     := text_params + 2
        text_width      := text_params + 3

        stax    text_addr       ; input is length-prefixed string
        ldy     #0
        lda     (text_addr),y
        sta     text_length
        inc16   text_addr       ; point past length
        MGTK_CALL MGTK::TextWidth, text_params

        sub16   #kDAWidth, text_width, title_label_pos::xcoord
        lsr16   title_label_pos::xcoord ; /= 2
        MGTK_CALL MGTK::MoveTo, title_label_pos
        MGTK_CALL MGTK::DrawText, text_params
        rts
.endproc

;;; ============================================================

.proc AnimFrame
        lda     frame_counter
        lsr                     ; /= 4
        lsr                     ;

        asl                     ; *= 2 - yes, this could be simplified
        tax
        copy16  anim_table,x, frame_params::mapbits

        add16_8   #kRunPosX, run_pos, frame_params::viewloc::xcoord

        bit     cursor_flag
        bpl     :+
        MGTK_CALL MGTK::HideCursor
:


        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::PaintBits, frame_params

        inc     frame_counter
        lda     frame_counter
        cmp     #kNumAnimFrames * 4
        bne     :+
        copy    #0, frame_counter

:       inc     run_pos
        lda     run_pos
        cmp     #kRunDistance
        bne     :+
        copy    #0, run_pos

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintBits, frame_params

:

        bit     cursor_flag
        bpl     :+
        MGTK_CALL MGTK::ShowCursor
:

        rts
.endproc

;;; ============================================================

        .include "../lib/buttonloop.s"
        .include "../lib/drawstring.s"
        .include "../lib/normfast.s"

;;; ============================================================


last := *
