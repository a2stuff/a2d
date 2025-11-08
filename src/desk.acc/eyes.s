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

;;; ============================================================

.proc Init
        copy8   #0, SHIFT_SIGN_EXT ; Must zero before using FP ops

        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     HandleDown
        cmp     #MGTK::EventKind::key_down
        beq     HandleKey
        cmp     #MGTK::EventKind::no_event
        beq     HandleNoEvent
        jmp     InputLoop
.endproc ; InputLoop

.proc Exit
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
        cmp     #kShortcutCloseWindow
        beq     Exit
        bne     InputLoop       ; always
    END_IF

        cmp     #CHAR_ESCAPE
        beq     Exit
        bne     InputLoop       ; always
.endproc ; HandleKey

;;; ============================================================

.proc HandleDown
        copy16  event_params::xcoord, findwindow_params::mousex
        copy16  event_params::ycoord, findwindow_params::mousey
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     #kDAWindowId
        bne     InputLoop
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        beq     HandleClose
        cmp     #MGTK::Area::dragbar
        jeq     HandleDrag
        cmp     #MGTK::Area::content
        jeq     HandleGrow
        jmp     InputLoop
.endproc ; HandleDown

;;; ============================================================

.proc HandleClose
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        bne     Exit
        jmp     InputLoop
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
        cmp16   delta, #kMoveThresholdX
        bcs     moved

        ;; Compute absolute Y delta
        sub16   event_params::ycoord, screentowindow_params::screen::ycoord, delta
        lda     delta+1
    IF NEG
        sub16   #0, delta, delta ; negate
    END_IF
        cmp16   delta, #kMoveThresholdY
        bcs     moved

        ;; Hasn't moved enough
        jmp     done

moved:  copy16  event_params::xcoord, screentowindow_params::screen::xcoord
        copy16  event_params::ycoord, screentowindow_params::screen::ycoord
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        jsr     DrawWindow

done:   jmp     InputLoop


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

        jmp     InputLoop
.endproc ; HandleDrag

;;; ============================================================

.proc HandleGrow
        ;; Is the hit within the grow box area?
        copy16  event_params::xcoord, screentowindow_params::screen::xcoord
        copy16  event_params::ycoord, screentowindow_params::screen::ycoord
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        sub16   winfo::maprect::x2, mx, tmpw
        cmp16   #kGrowBoxWidth, tmpw
        bcc     nope
        sub16   winfo::maprect::y2, my, tmpw
        cmp16   #kGrowBoxHeight, tmpw
        bcc     nope

        ;; Initiate the grow... re-using the drag logic
        copy8   #kDAWindowId, dragwindow_params::window_id
        copy16  event_params::xcoord, dragwindow_params::dragx
        copy16  event_params::ycoord, dragwindow_params::dragy
        MGTK_CALL MGTK::GrowWindow, dragwindow_params
        jmp     HandleDrag::common

nope:   jmp     InputLoop

tmpw:   .word   0
.endproc ; HandleGrow

;;; ============================================================

penXOR: .byte   MGTK::penXOR
notpencopy:     .byte   MGTK::notpencopy

kPenW    = 8
kPenH    = 4
kPupilW  = kPenW * 2
kPupilH  = kPenH * 2

.params pupil_pensize
penwidth:       .byte   kPupilW
penheight:      .byte   kPupilH
.endparams

;;; Flag set once we have coords from a move event
has_last_coords:
        .byte   0

;;; Flag set once outline is drawn (cleared on window move)
has_drawn_outline:
        .byte   0

;;; Minimum threshold to move to trigger a redraw, to avoid flicker.
kMoveThresholdX = 5
kMoveThresholdY = 5

;;; Saved coords
        DEFINE_POINT pos_l, 0, 0
        DEFINE_POINT pos_r, 0, 0

;;; ============================================================

.proc DrawWindow
        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        RTS_IF A = #MGTK::Error::window_obscured

        ;; Defer until we have mouse coords
        lda     has_last_coords
        RTS_IF ZERO

        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        lda     has_drawn_outline
        jne     erase_pupils
        inc     has_drawn_outline

        MGTK_CALL MGTK::SetPenMode, notpencopy

        ;; Draw resize box
        sub16   winfo::maprect::x2, #kGrowBoxWidth, grow_box_params::viewloc::xcoord
        sub16   winfo::maprect::y2, #kGrowBoxHeight, grow_box_params::viewloc::ycoord
        MGTK_CALL MGTK::PaintBits, grow_box_params

        ;; Draw outline

        MGTK_CALL MGTK::SetZP1, setzp_params_nopreserve

        ;; Left
        copy16  #0, eye_rect+MGTK::Rect::x1
        copy16  #0, eye_rect+MGTK::Rect::y1
        copy16  winfo::maprect::x2, eye_rect+MGTK::Rect::x2
        lsr16   eye_rect+MGTK::Rect::x2
        add16   winfo::maprect::y2, #1, eye_rect+MGTK::Rect::y2
        jsr     DrawEyeball

        ;; Right
        copy16  eye_rect+MGTK::Rect::x2, eye_rect+MGTK::Rect::x1
        copy16  winfo::maprect::x2, eye_rect+MGTK::Rect::x2
        jsr     DrawEyeball

        MGTK_CALL MGTK::SetZP1, setzp_params_preserve

        ;; Skip erasing pupils if we're redrawing
        jmp     draw_pupils

erase_pupils:
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::SetPenSize, pupil_pensize

        MGTK_CALL MGTK::MoveTo, pos_l
        MGTK_CALL MGTK::LineTo, pos_l
        MGTK_CALL MGTK::MoveTo, pos_r
        MGTK_CALL MGTK::LineTo, pos_r

draw_pupils:
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::SetPenSize, pupil_pensize

        add16 winfo::maprect::x2, #2, rx ; width / 4
        lsr16 rx
        lsr16 rx
        add16 winfo::maprect::y2, #2, ry ; height / 2
        lsr16 ry

        copy16  rx, cx
        copy16  ry, cy
        jsr     ComputePupilPos
        sub16  ppx, #kPupilW/2, pos_l::xcoord
        sub16  ppy, #kPupilH/2, pos_l::ycoord
        MGTK_CALL MGTK::MoveTo, pos_l
        MGTK_CALL MGTK::LineTo, pos_l

        add16   rx, cx, cx
        add16   rx, cx, cx
        jsr     ComputePupilPos
        sub16  ppx, #kPupilW/2, pos_r::xcoord
        sub16  ppy, #kPupilH/2, pos_r::ycoord
        MGTK_CALL MGTK::MoveTo, pos_r
        MGTK_CALL MGTK::LineTo, pos_r

        MGTK_CALL MGTK::ShowCursor
        rts
.endproc ; DrawWindow

;;; ============================================================
;;; Assumes the pen is 1px x 1px
;;; Inputs: `eye_rect` must be set up by the caller

.proc DrawEyeball
        COPY_STRUCT MGTK::Rect, eye_rect, io_params::rect
        copy16  #outer_oval, io_params::oval
        sub16   io_params::rect::right, io_params::rect::left, io_params::width
        sub16   io_params::rect::bottom, io_params::rect::top, io_params::height
        jsr     InitOval

        add16   eye_rect+MGTK::Rect::x1, #kPenW, io_params::rect::left
        add16   eye_rect+MGTK::Rect::y1, #kPenH, io_params::rect::top
        sub16   eye_rect+MGTK::Rect::x2, #kPenW, io_params::rect::right
        sub16   eye_rect+MGTK::Rect::y2, #kPenH, io_params::rect::bottom
        copy16  #inner_oval, io_params::oval
        sub16   io_params::rect::right, io_params::rect::left, io_params::width
        sub16   io_params::rect::bottom, io_params::rect::top, io_params::height
        jsr     InitOval

        copy16  outer_oval+OvalRec::top, yy

loop:
        copy16  #outer_oval, bo_params::oval
        copy16  yy, bo_params::vert
        jsr     BumpOval

        copy16  #inner_oval, bo_params::oval
        copy16  yy, bo_params::vert
        jsr     BumpOval

        copy16  yy, rect+MGTK::Rect::y1
        copy16  yy, rect+MGTK::Rect::y2

        cmp16   yy, inner_oval+OvalRec::top
        bcc     outer_only
        cmp16   yy, inner_oval+OvalRec::bottom
        bcs     outer_only

        ;; Need to draw the left and right edges
        copy16  outer_oval+OvalRec::leftEdge+2, rect+MGTK::Rect::x1
        copy16  inner_oval+OvalRec::leftEdge+2, rect+MGTK::Rect::x2
        MGTK_CALL MGTK::PaintRect, rect

        copy16  inner_oval+OvalRec::rightEdge+2, rect+MGTK::Rect::x1
        copy16  outer_oval+OvalRec::rightEdge+2, rect+MGTK::Rect::x2
        MGTK_CALL MGTK::PaintRect, rect

        jmp     next

        ;; Only need to draw the outer oval
outer_only:
        copy16  outer_oval+OvalRec::leftEdge+2, rect+MGTK::Rect::x1
        copy16  outer_oval+OvalRec::rightEdge+2, rect+MGTK::Rect::x2
        MGTK_CALL MGTK::PaintRect, rect

next:
        inc16   yy
        cmp16   yy, outer_oval+OvalRec::bottom
        jcc     loop

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
        copy16 io_params::rect::top, oval+OvalRec::top

        ;; oval.bottom [16.0] = rect.bottom [16.0]
        copy16 io_params::rect::bottom, oval+OvalRec::bottom

        ;; --------------------------------------------------
        ;; Check ovalWidth/Height, pin at 0

        ;; if (ovalWidth [16.0] < 0)
        ;;   ovalWidth [16.0] = 0
        bit     ovalWidth+1
    IF NEG
        copy16  #0, ovalWidth
    END_IF

        ;; if (ovalHeight [16.0] < 0)
        ;;   ovalHeight [16.0] = 0
        bit     ovalHeight+1
    IF NEG
        copy16  #0, ovalHeight
    END_IF

        ;; --------------------------------------------------
        ;; Check ovalWidth/Height, trim if bigger than rect

        ;; d0 [16.0] = rect.right [16.0] - rect.left [16.0]
        sub16   io_params::rect::right, io_params::rect::left, d0

        ;; if (ovalWidth [16.0] > d0 [16.0])
        ;;   ovalWidth [16.0] = d0 [16.0]
        cmp16   ovalWidth, d0
    IF LT
        copy16  d0, ovalWidth
    END_IF

        ;; d0 [16.0] = rect.bottom [16.0] - rect.top [16.0]
        sub16   io_params::rect::bottom, io_params::rect::top, d0

        ;; if (ovalHeight [16.0] > d0 [16.0])
        ;;   ovalHeight [16.0] = rect.bottom [16.0] - rect.top [16.0]
        cmp16   ovalHeight, d0
    IF LT
        copy16  d0, ovalHeight
    END_IF

        ;; --------------------------------------------------
        ;; Set up left/right edges, numbers

        ;; oval.rightEdge [16.16] = rect.right [16.0]
        copy16 #0, oval+OvalRec::rightEdge
        copy16 io_params::rect::right, oval+OvalRec::rightEdge+2

        ;; oval.leftEdge [16.16] = rect.left [16.0]
        copy16 #0, oval+OvalRec::leftEdge
        copy16 io_params::rect::left, oval+OvalRec::leftEdge+2

        ;; ovalWidthDiv2 [16.16] = ovalWidth [16.0] / 2
        copy16  #0, ovalWidthDiv2
        copy16  ovalWidth, ovalWidthDiv2+2
        lsr32   ovalWidthDiv2

        ;; oval.leftEdge [16.16] = oval.leftEdge [16.16] + ovalWidthDiv2 [16.16]
        add32   oval+OvalRec::leftEdge, ovalWidthDiv2, oval+OvalRec::leftEdge

        ;; oval.rightEdge [16.16] = oval.rightEdge [16.16] - ovalWidthDiv2 [16.16]
        sub32   oval+OvalRec::rightEdge, ovalWidthDiv2, oval+OvalRec::rightEdge

        ;; oval.oneHalf [16.16] = 0.5
        copy32  #$00008000, oval+OvalRec::oneHalf

        ;; Bias
        ;; oval.rightEdge [16.16] = oval.rightEdge [16.16] + oval.oneHalf [16.16]
        add32   oval+OvalRec::rightEdge, oval+OvalRec::oneHalf, oval+OvalRec::rightEdge

        ;; --------------------------------------------------
        ;; Init y to -height + 1

        ;; oval.y [16.0] = 1 - ovalHeight [16.0]
        sub16 #1, ovalHeight, oval+OvalRec::yy

        ;; --------------------------------------------------
        ;; Init rSqYSq to 2*ovalHeight-1

        ;; oval.rSqYSq [32.0] = 2 * ovalHeight [16.0] - 1
        copy32  ovalHeight, oval+OvalRec::rSqYSq
        asl32   oval+OvalRec::rSqYSq
        sub32   oval+OvalRec::rSqYSq, #1, oval+OvalRec::rSqYSq

        ;; --------------------------------------------------
        ;; Init square to 0

        ;; oval.square [16.16] = 0
        copy32  #0, oval+OvalRec::square

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
        dey
    WHILE NOT_ZERO
.endscope ; fixed_div


        ;; oval.oddNum [16.16] = aspect_ratio [16.16] * aspect_ratio [16.16];
        copy32  aspect_ratio, temp

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
        copy32  oval+OvalRec::oddNum, oval+OvalRec::oddBump
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
        cmp16   vert, oval+OvalRec::top
        RTS_IF LT

        ;; if (vert [16.0] >= oval.bottom [16.0])
        ;;   return;
        cmp16   vert, oval+OvalRec::bottom
        RTS_IF GE

        ;; d0 [16.0] = oval.y [16.0];
        copy16  oval+OvalRec::yy, d0

        ;; oval.y [16.0] = oval.y [16.0] + 2;
        add16   oval+OvalRec::yy, #2, oval+OvalRec::yy

        ;; --------------------------------------------------
        ;; while square < rSqYSq make oval bigger

loop1:
        ;; while (oval.square [16.16] < oval.rSqYSq [32.0] ) {
        cmp16   oval+OvalRec::square+2, oval+OvalRec::rSqYSq
        jcs     endloop1

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

endloop1:
        ;; --------------------------------------------------
        ;; while square > rSqYSq make oval smaller

loop2:
        ;; while (oval.square [16.16] > oval.rSqYSq [32.0]) {
        cmp16   oval+OvalRec::square+2, oval+OvalRec::rSqYSq
        jcc     endloop2

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
endloop2:

        ;; oval.rSqYSq [32.0] = oval.rSqYSq [32.0] - (4 * (d0 [16.0] + 1)));

        copy16  d0, temp        ; temp = d0
        lda     #0
        bit     temp+1          ; sign-extend
    IF NS
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
        dey
    WHILE POS

        rts
.endproc ; SaveOval

;;; Load `oval` from `OvalRec` addr at $06
.proc LoadOval
        ptr := $06

        ldy     #.sizeof(OvalRec)-1
    DO
        copy8   (ptr),y, oval,y
        dey
    WHILE POS

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
