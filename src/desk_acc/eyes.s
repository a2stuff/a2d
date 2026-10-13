;;; ============================================================
;;; EYES - Desk Accessory
;;;
;;; Shows a resizable window with eyes that follow the mouse.
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "eyes.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"
        .include "../inc/fp_macros.inc"

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

.proc AuxStart
        ;; Mostly use ZP preservation mode, since we use ROM FP routines.
        MGTK_CALL MGTK::SetZP1, setzp_params_preserve
        jsr     Init
        MGTK_CALL MGTK::SetZP1, setzp_params_nopreserve
        rts
.endproc ; AuxStart

;;; ============================================================

kDAWindowId    = $80
kDAWidth        = kScreenWidth / 3
kDAHeight       = kScreenHeight / 3
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
mincontwidth:   .word   kScreenWidth / 5
mincontheight:  .word   kScreenHeight / 5
maxcontwidth:   .word   kScreenWidth
maxcontheight:  .word   kScreenHeight
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

;;; ============================================================


.params event_params
kind:  .byte   0
;;; EventKind::key_down
key             := *
modifiers       := * + 1
;;; EventKind::update
window_id       := *
;;; otherwise
xcoord          := *
ycoord          := * + 2
        .res    4
.endparams

.params findwindow_params
mousex:         .word   0
mousey:         .word   0
which_area:     .byte   0
window_id:      .byte   0
.endparams

.params trackgoaway_params
clicked:        .byte   0
.endparams

.params dragwindow_params
window_id:      .byte   0
dragx:          .word   0
dragy:          .word   0
moved:          .byte   0
.endparams

.params getwinport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport
.endparams

.params screentowindow_params
window_id:      .byte   kDAWindowId
        DEFINE_POINT screen, 0, 0
        DEFINE_POINT window, 0, 0
.endparams
        mx := screentowindow_params::window::xcoord
        my := screentowindow_params::window::ycoord

grafport:       .tag    MGTK::GrafPort

kGrowBoxWidth = 17
kGrowBoxHeight = 7

.params grow_box_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   grow_box_bitmap
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT maprect, 2, 2, 19, 9
        REF_MAPINFO_MEMBERS
.endparams

grow_box_bitmap:
        PIXELS  "#####################"
        PIXELS  "#...................#"
        PIXELS  "#..##########.......#"
        PIXELS  "#..##......#######..#"
        PIXELS  "#..##......##...##..#"
        PIXELS  "#..##......##...##..#"
        PIXELS  "#..##########...##..#"
        PIXELS  "#....##.........##..#"
        PIXELS  "#....#############..#"
        PIXELS  "#...................#"
        PIXELS  "#####################"

setzp_params_nopreserve:        ; performance over convenience
        .byte   MGTK::zp_overwrite

setzp_params_preserve:          ; convenience over performance
        .byte   MGTK::zp_preserve

;;; ============================================================

.struct OvalRec
        top     .word           ; int [16.0]
        bottom  .word           ; int [16.0]
        yy      .word           ; int [16.0]
        rSqYSq  .dword          ; longint [32.0]
        square  .dword          ; fixed [16.16]
        oddNum  .dword          ; fixed [16.16]
        oddBump .dword          ; fixed [16.16]
        leftEdge .dword         ; fixed [16.16]
        rightEdge .dword        ; fixed [16.16]
        oneHalf .dword          ; fixed [16.16]
.endstruct

;;; Parameters for `InitOval` call
.params io_params
.params rect
left:   .word   0               ; int [16.0]
top:    .word   0               ; int [16.0]
right:  .word   0               ; int [16.0]
bottom: .word   0               ; int [16.0]
.endparams
oval:   .addr   0               ; int [16.0]
width:  .word   0               ; int [16.0]
height: .word   0               ; int [16.0]
.endparams

;;; Parameters for `BumpOval` call
.params bo_params
oval:   .addr   0
vert:   .word   0               ; [16.0]
.endparams

;;; Used by DrawEyeball
eye_rect:
        .tag    MGTK::Rect

pupil_rect:
        .tag    MGTK::Rect

;;; ============================================================

.proc Init
        copy8   #0, SHIFT_SIGN_EXT ; Must zero before using FP ops

        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

.proc InputLoop
    REPEAT
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK

        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
      IF A = #MGTK::EventKind::button_down
        jsr     HandleDown
      ELSE_IF A = #MGTK::EventKind::key_down
        jsr     HandleKey
      ELSE_IF A = #MGTK::EventKind::no_event
        jsr     HandleNoEvent
      END_IF

    FOREVER
.endproc ; InputLoop

.proc Exit
        ;; Don't return to `InputLoop`
        pla
        pla
        MGTK_CALL MGTK::CloseWindow, winfo
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts
.endproc ; Exit

;;; ============================================================

.proc HandleKey
        lda     event_params::key

        ldx     event_params::modifiers
    IF NOT_ZERO
        jsr     ToUpperCase
        IF A = #kShortcutCloseWindow GOTO Exit
        rts
    END_IF

        IF A = #CHAR_ESCAPE GOTO Exit
        rts
.endproc ; HandleKey

;;; ============================================================

.proc HandleDown
        copy16  event_params::xcoord, findwindow_params::mousex
        copy16  event_params::ycoord, findwindow_params::mousey
        MGTK_CALL MGTK::FindWindow, findwindow_params
        RTS_IF u8 findwindow_params::window_id <> #kDAWindowId

        lda     findwindow_params::which_area
        IF A = #MGTK::Area::close_box GOTO HandleClose
        IF A = #MGTK::Area::dragbar   JUMP HandleDrag
        IF A = #MGTK::Area::content   JUMP HandleGrow
        rts
.endproc ; HandleDown

;;; ============================================================

.proc HandleClose
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        bne     Exit
        rts
.endproc ; HandleClose

;;; ============================================================

.proc HandleNoEvent
        ;; First time? Need to store last coords
        lda     has_last_coords
        bne     test
        inc     has_last_coords
        bne     moved

test:
        ;; Compute absolute X delta
        sub16   event_params::xcoord, screentowindow_params::screen::xcoord, delta
        lda     delta+1
    IF NEG
        sub16   #0, delta, delta ; negate
    END_IF

    IF u16 delta < #kMoveThresholdX

        ;; Compute absolute Y delta
        sub16   event_params::ycoord, screentowindow_params::screen::ycoord, delta
        lda     delta+1
      IF NEG
        sub16   #0, delta, delta ; negate
      END_IF

      IF u16 delta < #kMoveThresholdY
        ;; Hasn't moved enough
        jmp     done
      END_IF
    END_IF

moved:  copy16  event_params::xcoord, screentowindow_params::screen::xcoord
        copy16  event_params::ycoord, screentowindow_params::screen::ycoord
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        jsr     DrawWindow

done:   rts


delta:  .word   0
.endproc ; HandleNoEvent

;;; ============================================================

.proc HandleDrag
        copy8   #kDAWindowId, dragwindow_params::window_id
        copy16  event_params::xcoord, dragwindow_params::dragx
        copy16  event_params::ycoord, dragwindow_params::dragy
        MGTK_CALL MGTK::DragWindow, dragwindow_params
common:
        lda     dragwindow_params::moved
    IF NS
        ;; Draw DeskTop's windows and icons
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES

        ;; Draw DA's window
        lda     #0
        sta     has_last_coords
        sta     has_drawn_outline
        jsr     DrawWindow
    END_IF

        rts
.endproc ; HandleDrag

;;; ============================================================

.proc HandleGrow
        ;; Is the hit within the grow box area?
        copy16  event_params::xcoord, screentowindow_params::screen::xcoord
        copy16  event_params::ycoord, screentowindow_params::screen::ycoord
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params

        sub16   winfo::maprect::x2, mx, tmpw
    IF u16 #kGrowBoxWidth >= tmpw
        sub16   winfo::maprect::y2, my, tmpw
      IF u16 #kGrowBoxHeight >= tmpw

        ;; Initiate the grow... re-using the drag logic
        copy8   #kDAWindowId, dragwindow_params::window_id
        copy16  event_params::xcoord, dragwindow_params::dragx
        copy16  event_params::ycoord, dragwindow_params::dragy
        MGTK_CALL MGTK::GrowWindow, dragwindow_params
        jmp     HandleDrag::common

      END_IF
    END_IF

        rts

tmpw:   .word   0
.endproc ; HandleGrow

;;; ============================================================

pencopy:        .byte   MGTK::pencopy
notpencopy:     .byte   MGTK::notpencopy

kPenW    = 8
kPenH    = 4
kPupilW  = kPenW * 2
kPupilH  = kPenH * 2

;;; Flag set once we have coords from a move event
has_last_coords:
        .byte   0

;;; Flag set once outline is drawn (cleared on window move)
has_drawn_outline:
        .byte   0

;;; Minimum threshold to move to trigger a redraw, to avoid flicker.
kMoveThresholdX = 10
kMoveThresholdY = 5

;;; Saved coords
        DEFINE_POINT pos_l, 0, 0
        DEFINE_POINT pos_r, 0, 0

        DEFINE_POINT last_l, 0, 0
        DEFINE_POINT last_r, 0, 0

;;; ============================================================

.proc DrawWindow
        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        RTS_IF A = #MGTK::Error::window_obscured

        CLEAR_BIT7_FLAG skip_erase_flag

        ;; Defer until we have mouse coords
        lda     has_last_coords
        RTS_IF ZERO

        MGTK_CALL MGTK::SetPort, grafport

        lda     has_drawn_outline
        jne     done_outline
        inc     has_drawn_outline

        MGTK_CALL MGTK::SetPenMode, notpencopy

        ;; Draw resize box
        SET s16 grow_box_params::viewloc::xcoord = winfo::maprect::x2 - #kGrowBoxWidth,
        SET s16 grow_box_params::viewloc::ycoord = winfo::maprect::y2 - #kGrowBoxHeight
        MGTK_CALL MGTK::PaintBits, grow_box_params

        ;; Draw outline

        MGTK_CALL MGTK::SetZP1, setzp_params_nopreserve

        ;; Left
        SET s16 eye_rect+MGTK::Rect::x1 = #0
        SET s16 eye_rect+MGTK::Rect::y1 = #0
        SET s16 eye_rect+MGTK::Rect::x2 = winfo::maprect::x2
        SET s16 eye_rect+MGTK::Rect::x2 >>= #1
        SET s16 eye_rect+MGTK::Rect::y2 = winfo::maprect::y2 + #1
        jsr     DrawEyeball

        ;; Right
        SET s16 eye_rect+MGTK::Rect::x1 = (eye_rect+MGTK::Rect::x2)
        SET s16 eye_rect+MGTK::Rect::x2 = winfo::maprect::x2
        jsr     DrawEyeball

        MGTK_CALL MGTK::SetZP1, setzp_params_preserve

        ;; Skip erasing pupils if we're redrawing
        SET_BIT7_FLAG skip_erase_flag
done_outline:

        ;; Save previous coords (for erasing)
        COPY_STRUCT pos_l, last_l
        COPY_STRUCT pos_r, last_r

        ;; Compute new coords
        SET s16 rx = winfo::maprect::x2 + #2 ; width / 4
        SET s16 rx >>= #1
        SET s16 rx >>= #1
        SET s16 ry = winfo::maprect::y2 + #2 ; height / 2
        SET s16 ry >>= #1

        SET s16 cx = rx
        SET s16 cy = ry
        jsr     ComputePupilPos
        SET s16 pos_l::xcoord = ppx - #kPupilW/2
        SET s16 pos_l::ycoord = ppy - #kPupilH/2

        SET s16 cx = rx + cx
        SET s16 cx = rx + cx
        jsr     ComputePupilPos
        SET s16 pos_r::xcoord = ppx - #kPupilW/2
        SET s16 pos_r::ycoord = ppy - #kPupilH/2

        ;; Do one pupil at a time to minimize flicker
        MGTK_CALL MGTK::SetZP1, setzp_params_nopreserve ; go fast

    IF bit skip_erase_flag : NC
        MGTK_CALL MGTK::SetPenMode, pencopy
        ldax    last_l::xcoord
        stax    pupil_rect+MGTK::Rect::x1
        addax   #kPupilW, pupil_rect+MGTK::Rect::x2
        ldax    last_l::ycoord
        stax    pupil_rect+MGTK::Rect::y1
        addax   #kPupilH, pupil_rect+MGTK::Rect::y2
        jsr     _DrawPupil
    END_IF
        MGTK_CALL MGTK::SetPenMode, notpencopy
        ldax    pos_l::xcoord
        stax    pupil_rect+MGTK::Rect::x1
        addax   #kPupilW, pupil_rect+MGTK::Rect::x2
        ldax    pos_l::ycoord
        stax    pupil_rect+MGTK::Rect::y1
        addax   #kPupilH, pupil_rect+MGTK::Rect::y2
        jsr     _DrawPupil

    IF bit skip_erase_flag : NC
        MGTK_CALL MGTK::SetPenMode, pencopy
        ldax    last_r::xcoord
        stax    pupil_rect+MGTK::Rect::x1
        addax   #kPupilW, pupil_rect+MGTK::Rect::x2
        ldax    last_r::ycoord
        stax    pupil_rect+MGTK::Rect::y1
        addax   #kPupilH, pupil_rect+MGTK::Rect::y2
        jsr     _DrawPupil
    END_IF
        MGTK_CALL MGTK::SetPenMode, notpencopy
        ldax    pos_r::xcoord
        stax    pupil_rect+MGTK::Rect::x1
        addax   #kPupilW, pupil_rect+MGTK::Rect::x2
        ldax    pos_r::ycoord
        stax    pupil_rect+MGTK::Rect::y1
        addax   #kPupilH, pupil_rect+MGTK::Rect::y2
        jsr     _DrawPupil

        MGTK_CALL MGTK::SetZP1, setzp_params_preserve
        rts

;;; Caller must set up `pupil_rect`
.proc _DrawPupil
        MGTK_CALL MGTK::ShieldCursor, pupil_rect
        MGTK_CALL MGTK::PaintRect, pupil_rect
        MGTK_CALL MGTK::UnshieldCursor
        MGTK_CALL MGTK::CheckEvents
        rts
.endproc ; _DrawPupil

skip_erase_flag:        .byte   0 ; bit7

.endproc ; DrawWindow

;;; ============================================================
;;; Assumes the pen is 1px x 1px
;;; Inputs: `eye_rect` must be set up by the caller

.proc DrawEyeball
        MGTK_CALL MGTK::ShieldCursor, eye_rect

        COPY_STRUCT MGTK::Rect, eye_rect, io_params::rect
        SET u16 io_params::oval = #outer_oval
        SET s16 io_params::width  = io_params::rect::right  - io_params::rect::left
        SET s16 io_params::height = io_params::rect::bottom - io_params::rect::top
        jsr     InitOval

        SET s16 io_params::rect::left   = (eye_rect+MGTK::Rect::x1) + #kPenW
        SET s16 io_params::rect::top    = (eye_rect+MGTK::Rect::y1) + #kPenH
        SET s16 io_params::rect::right  = (eye_rect+MGTK::Rect::x2) - #kPenW
        SET s16 io_params::rect::bottom = (eye_rect+MGTK::Rect::y2) - #kPenH
        SET u16 io_params::oval = #inner_oval
        SET s16 io_params::width  = io_params::rect::right  - io_params::rect::left
        SET s16 io_params::height = io_params::rect::bottom - io_params::rect::top
        jsr     InitOval

        SET s16 yy = (outer_oval+OvalRec::top)

    DO
        SET s16 bo_params::oval = #outer_oval
        SET s16 bo_params::vert = yy
        jsr     BumpOval

        SET s16 bo_params::oval = #inner_oval
        SET s16 bo_params::vert = yy
        jsr     BumpOval

        SET s16 rect+MGTK::Rect::y1 = yy
        SET s16 rect+MGTK::Rect::y2 = yy

      IF u16 yy >= inner_oval+OvalRec::top AND u16 yy < inner_oval+OvalRec::bottom
        ;; Need to draw the left and right edges
        SET s16 rect+MGTK::Rect::x1 = (outer_oval+OvalRec::leftEdge+2)
        SET s16 rect+MGTK::Rect::x2 = (inner_oval+OvalRec::leftEdge+2)
        MGTK_CALL MGTK::PaintRect, rect

        SET s16 rect+MGTK::Rect::x1 = (inner_oval+OvalRec::rightEdge+2)
        SET s16 rect+MGTK::Rect::x2 = (outer_oval+OvalRec::rightEdge+2)
        MGTK_CALL MGTK::PaintRect, rect
     ELSE
         ;; Only need to draw the outer oval
        SET s16 rect+MGTK::Rect::x1 = (outer_oval+OvalRec::leftEdge+2)
        SET s16 rect+MGTK::Rect::x2 = (outer_oval+OvalRec::rightEdge+2)
        MGTK_CALL MGTK::PaintRect, rect
     END_IF

    WHILE u16 ++yy < outer_oval+OvalRec::bottom

        MGTK_CALL MGTK::UnshieldCursor
        rts

yy:     .word   0
rect:   .tag    MGTK::Rect
outer_oval:
        .tag    OvalRec
inner_oval:
        .tag    OvalRec

.endproc ; DrawEyeball


;;; ============================================================
;;; Common input params

rx:     .word   0
ry:     .word   0

cx:     .word   0
cy:     .word   0

;;; ============================================================
;;; Compute pupil location
;;;
;;; Inputs: mx, my, cx, cy, rx, ry
;;; Outputs: ppx, ppy

ppx:    .word   0
ppy:    .word   0

.proc ComputePupilPos
        ;; TODO: Do this with integer math instead.

        bit     ROMIN2

        FAC_LOAD_INT    cx
        FAC_STORE       cxf

        FAC_LOAD_INT    cy
        FAC_STORE       cyf

        ;; pupil shouldn't overlap border
        sub16  rx, #kPenW, tmpw
        sub16  tmpw, #kPupilW, tmpw
        FAC_LOAD_INT tmpw
        FAC_STORE prx

        sub16  ry, #kPenH, tmpw
        sub16  tmpw, #kPupilH, tmpw
        FAC_LOAD_INT    tmpw
        FAC_STORE       pry

        ;; x scale, so math is circular
        ;; xs = pry / prx

        FAC_LOAD        prx
        FAC_DIV         pry
        FAC_STORE       scale

        ;; mouse delta, in transformed space
        ;; dx = (mx - cx) * xs
        ;; dy = mx - cy

        FAC_LOAD_INT    mx      ; dx = (mx - cx) * xs
        FAC_STORE       tmpf
        FAC_LOAD        cxf
        FAC_SUB         tmpf
        FAC_MUL         scale
        FAC_STORE       dx

        FAC_LOAD_INT    my      ; dy = mx - cy
        FAC_STORE       tmpf
        FAC_LOAD        cyf
        FAC_SUB         tmpf
        FAC_STORE       dy

        ;; d = SQR(dx * dx + dy * dy)

        FAC_LOAD        dx
        FAC_MUL         dx
        FAC_STORE       tmpf
        FAC_LOAD        dy
        FAC_MUL         dy
        FAC_ADD         tmpf

        jsr             SQR

        ;; if d > pry:
        ;;   f = pry / d
        ;;   dx = f * dx
        ;;   dy = f * dy

        FAC_COMP pry
        bmi     skip

        FAC_DIV         pry     ; f = pry / d
        FAC_STORE       tmpf

        FAC_MUL         dx      ; dx = f * dx
        FAC_STORE       dx

        FAC_LOAD        tmpf    ; dy = f * dy
        FAC_MUL         dy
        FAC_STORE       dy
skip:

        ;; plot coords
        ;; ppx = (dx / xs) + cx
        ;; ppy = dy + cy

        FAC_LOAD        scale   ; ppx = (dx / xs) + cx
        FAC_DIV         dx
        FAC_ADD         cxf
        FAC_STORE_INT   ppx

        FAC_LOAD        dy      ; ppy = dy + cy
        FAC_ADD         cyf
        FAC_STORE_INT   ppy

        bit     LCBANK1
        bit     LCBANK1

        rts

tmpw:   .word   0
        DEFINE_FLOAT tmpf

        DEFINE_FLOAT scale
        DEFINE_FLOAT dx
        DEFINE_FLOAT dy
        DEFINE_FLOAT pry
        DEFINE_FLOAT prx
        DEFINE_FLOAT cxf
        DEFINE_FLOAT cyf
.endproc ; ComputePupilPos

;;; ============================================================
;;; Oval Routines (based on QuickDraw)
;;; ============================================================

.scope oval

;;; Temp `OvalRec`
oval := $50

;;; Set up `io_params` before calling.
.proc InitOval
        ovalHeight := io_params::height ; [16.0]
        ovalWidth  := io_params::width  ; [16.0]

        ;; --------------------------------------------------
        ;; Local variables

.struct
        .org $10
        d0              .word   ; [16.0]
        ovalWidthDiv2   .dword  ; [16.16]
        aspect_ratio    .dword  ; [16.16]
        temp            .dword
        product         .res 8  ; [32.32]
.endstruct

        ;; --------------------------------------------------
        ;; Init top/bottom to rect top/bottom

        ;; oval.top [16.0] = rect.top [16.0]
        SET u16 oval+OvalRec::top = io_params::rect::top

        ;; oval.bottom [16.0] = rect.bottom [16.0]
        SET u16 oval+OvalRec::bottom = io_params::rect::bottom

        ;; --------------------------------------------------
        ;; Check ovalWidth/Height, pin at 0

        ;; if (ovalWidth [16.0] < 0)
        ;;   ovalWidth [16.0] = 0
    IF bit ovalWidth+1 : NEG
        SET u16 ovalWidth = #0
    END_IF

        ;; if (ovalHeight [16.0] < 0)
        ;;   ovalHeight [16.0] = 0
    IF bit ovalHeight+1 : NEG
        SET u16 ovalHeight = #0
    END_IF

        ;; --------------------------------------------------
        ;; Check ovalWidth/Height, trim if bigger than rect

        ;; d0 [16.0] = rect.right [16.0] - rect.left [16.0]
        SET u16 d0 = io_params::rect::right - io_params::rect::left

        ;; if (ovalWidth [16.0] > d0 [16.0])
        ;;   ovalWidth [16.0] = d0 [16.0]
    IF u16 ovalWidth < d0
        SET u16 ovalWidth = d0
    END_IF

        ;; d0 [16.0] = rect.bottom [16.0] - rect.top [16.0]
        SET u16 d0 = io_params::rect::bottom - io_params::rect::top

        ;; if (ovalHeight [16.0] > d0 [16.0])
        ;;   ovalHeight [16.0] = rect.bottom [16.0] - rect.top [16.0]
    IF u16 ovalHeight < d0
        SET u16 ovalHeight = d0
    END_IF

        ;; --------------------------------------------------
        ;; Set up left/right edges, numbers

        ;; oval.rightEdge [16.16] = rect.right [16.0]
        SET u16 oval+OvalRec::rightEdge = #0
        SET u16 oval+OvalRec::rightEdge+2 = io_params::rect::right

        ;; oval.leftEdge [16.16] = rect.left [16.0]
        SET u16 oval+OvalRec::leftEdge = #0
        SET u16 oval+OvalRec::leftEdge+2 = io_params::rect::left

        ;; ovalWidthDiv2 [16.16] = ovalWidth [16.0] / 2
        SET u16 ovalWidthDiv2 =  #0
        SET u16 ovalWidthDiv2+2 =  ovalWidth
        SET u32 ovalWidthDiv2 >>= #1

        ;; oval.leftEdge [16.16] = oval.leftEdge [16.16] + ovalWidthDiv2 [16.16]
        SET u32 oval+OvalRec::leftEdge = (oval+OvalRec::leftEdge) + ovalWidthDiv2

        ;; oval.rightEdge [16.16] = oval.rightEdge [16.16] - ovalWidthDiv2 [16.16]
        SET u32 oval+OvalRec::rightEdge = (oval+OvalRec::rightEdge) - ovalWidthDiv2

        ;; oval.oneHalf [16.16] = 0.5
        SET u32 oval+OvalRec::oneHalf = #$00008000

        ;; Bias
        ;; oval.rightEdge [16.16] = oval.rightEdge [16.16] + oval.oneHalf [16.16]
        SET u32 oval+OvalRec::rightEdge = (oval+OvalRec::rightEdge) + oval+OvalRec::oneHalf

        ;; --------------------------------------------------
        ;; Init y to -height + 1

        ;; oval.y [16.0] = 1 - ovalHeight [16.0]
        SET u16 oval+OvalRec::yy = #1 - ovalHeight

        ;; --------------------------------------------------
        ;; Init rSqYSq to 2*ovalHeight-1

        ;; oval.rSqYSq [32.0] = 2 * ovalHeight [16.0] - 1
        SET u32 oval+OvalRec::rSqYSq = ovalHeight
        asl32   oval+OvalRec::rSqYSq
        SET u32 oval+OvalRec::rSqYSq = (oval+OvalRec::rSqYSq) - #1

        ;; --------------------------------------------------
        ;; Init square to 0

        ;; oval.square [16.16] = 0
        SET u32 oval+OvalRec::square = #0

        ;; --------------------------------------------------
        ;; oddNum = 1 * aspect ratio squared

        ;; aspect_ratio [16.16] = ovalHeight [16.0] / ovalWidth [16.0];
.scope fixed_div
        dividend   := ovalHeight   ; [16.0]
        divisor    := ovalWidth    ; [16.0]
        quotient   := aspect_ratio ; [16.16]
        remainder  := temp         ; [16.0]

        copy16  #0, remainder

        ldy     #32
    DO
        asl32   quotient
        asl     dividend
        rol     dividend+1
        rol     remainder
        rol     remainder+1

        lda     remainder
        sec
        sbc     divisor
        tax
        lda     remainder+1
        sbc     divisor+1
      IF CS
        stx     remainder
        sta     remainder+1
        inc     quotient
      END_IF
    WHILE dey : NOT_ZERO
.endscope ; fixed_div


        ;; oval.oddNum [16.16] = aspect_ratio [16.16] * aspect_ratio [16.16];
        SET u32 temp = aspect_ratio

.scope
multiplier      := aspect_ratio
multiplicand    := temp

        ;; This is a 32-bit multiply with a 64-bit product, used for
        ;; [16.16] * [16.16] => [32.32]
        ;; Based on: http://www.6502.org/source/integers/32muldiv.htm

        lda     #0              ; Clear upper half of product
        sta     product+4
        sta     product+5
        sta     product+6
        sta     product+7

        ldx     #32             ; Process 32 bits

        ;; Shift multiplier
shift:
        lsr     multiplier+3
        ror     multiplier+2
        ror     multiplier+1
        ror     multiplier
        bcc     rotate

        lda     product+4
        clc
        adc     multiplicand
        sta     product+4
        lda     product+5
        adc     multiplicand+1
        sta     product+5
        lda     product+6
        adc     multiplicand+2
        sta     product+6
        lda     product+7
        adc     multiplicand+3

        ;; Rotate partial product
rotate:
        ror     a
        sta     product+7
        ror     product+6
        ror     product+5
        ror     product+4
        ror     product+3
        ror     product+2
        ror     product+1
        ror     product

        ;; Loop
        dex
        bne     shift

        ;; Only need 16.16 result
        copy32  product+2, z:oval+OvalRec::oddNum
.endscope

        ;; --------------------------------------------------
        ;; oddBump = 2 * aspect ratio squared

        ;; oval.oddBump [16.16] = 2 * oval.oddNum [16.16];
        SET u32 oval+OvalRec::oddBump = (oval+OvalRec::oddNum)
        asl32   oval+OvalRec::oddBump

        ;; --------------------------------------------------
        ;; Finish

        ptr := $06
        copy16  io_params::oval, ptr
        jmp     SaveOval

.endproc ; InitOval

;;; Set up `bo_params` before calling.
.proc BumpOval

        ptr := $06
        vert := bo_params::vert

        ;; --------------------------------------------------
        ;; Local variables

.struct
        .org $10
        d0     .word            ; [16.0]
        temp   .dword
.endstruct

        ;; --------------------------------------------------
        ;; Copy to working OvalRec

        copy16  bo_params::oval, ptr
        jsr     LoadOval

        ;; --------------------------------------------------
        ;; Algorithm

        ;; if (vert [16.0] < oval.top [16.0])
        ;;   return;
        RTS_IF u16 vert < oval+OvalRec::top

        ;; if (vert [16.0] >= oval.bottom [16.0])
        ;;   return;
        RTS_IF u16 vert >= oval+OvalRec::bottom

        ;; d0 [16.0] = oval.y [16.0];
        copy16  oval+OvalRec::yy, d0

        ;; oval.y [16.0] = oval.y [16.0] + 2;
        add16   oval+OvalRec::yy, #2, oval+OvalRec::yy

        ;; --------------------------------------------------
        ;; while square < rSqYSq make oval bigger

loop1:
        ;; while (oval.square [16.16] < oval.rSqYSq [32.0] ) {
    IF u16 oval+OvalRec::square+2 < oval+OvalRec::rSqYSq

        ;; oval.rightEdge [16.16] = oval.rightEdge [16.16] + oval.oneHalf [16.16];
        add32   oval+OvalRec::rightEdge, oval+OvalRec::oneHalf, oval+OvalRec::rightEdge

        ;; oval.leftEdge [16.16] = oval.leftEdge [16.16] - oval.oneHalf [16.16];
        sub32   oval+OvalRec::leftEdge, oval+OvalRec::oneHalf, oval+OvalRec::leftEdge

        ;; oval.square [16.16] = oval.square [16.16] + oval.oddNum [16.16];
        add32   oval+OvalRec::square, oval+OvalRec::oddNum, oval+OvalRec::square

        ;; oval.oddNum [16.16] = oval.oddNum [16.16] + oval.oddBump [16.16];
        add32   oval+OvalRec::oddNum, oval+OvalRec::oddBump, oval+OvalRec::oddNum

        ;; }
        jmp     loop1
    END_IF

        ;; --------------------------------------------------
        ;; while square > rSqYSq make oval smaller

loop2:
        ;; while (oval.square [16.16] > oval.rSqYSq [32.0]) {
    IF u16 oval+OvalRec::square+2 >= oval+OvalRec::rSqYSq

        ;; oval.rightEdge [16.16] = oval.rightEdge [16.16] - oval.oneHalf [16.16];
        sub32   oval+OvalRec::rightEdge, oval+OvalRec::oneHalf, oval+OvalRec::rightEdge

        ;; oval.leftEdge [16.16] = oval.leftEdge [16.16] + oval.oneHalf [16.16];
        add32   oval+OvalRec::leftEdge, oval+OvalRec::oneHalf, oval+OvalRec::leftEdge

        ;; oval.oddNum [16.16] = oval.oddNum [16.16] - oval.oddBump [16.16];
        sub32   oval+OvalRec::oddNum, oval+OvalRec::oddBump, oval+OvalRec::oddNum

        ;; oval.square [16.16] = oval.square [16.16] - oval.oddNum [16.16];
        sub32   oval+OvalRec::square, oval+OvalRec::oddNum, oval+OvalRec::square

        ;; }
        jmp     loop2
    END_IF

        ;; oval.rSqYSq [32.0] = oval.rSqYSq [32.0] - (4 * (d0 [16.0] + 1)));

        copy16  d0, temp        ; temp = d0
        lda     #0
    IF bit temp+1 : NS          ; sign-extend
        lda     #$FF
    END_IF
        sta     temp+2
        sta     temp+3

        add32   temp, #1, temp  ; temp = d0 + 1

        asl32   temp            ; temp = 4 * (d0 + 1)
        asl32   temp

        sub32   oval+OvalRec::rSqYSq, temp, oval+OvalRec::rSqYSq

        ;; --------------------------------------------------
        ;; Finish

        FALL_THROUGH_TO SaveOval
.endproc ; BumpOval

;;; Write `oval` to `OvalRec` addr at $06
.proc SaveOval
        ptr := $06

        ldy     #.sizeof(OvalRec)-1
    DO
        copy8   oval,y, (ptr),y
    WHILE dey : POS

        rts
.endproc ; SaveOval

;;; Load `oval` from `OvalRec` addr at $06
.proc LoadOval
        ptr := $06

        ldy     #.sizeof(OvalRec)-1
    DO
        copy8   (ptr),y, oval,y
    WHILE dey : POS

        rts
.endproc ; LoadOval

.endscope ; oval
InitOval := oval::InitOval
BumpOval := oval::BumpOval

;;; ============================================================

        .include "../lib/uppercase.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT

        JSR_TO_AUX aux::AuxStart
        rts

        DA_END_MAIN_SEGMENT

;;; ============================================================
