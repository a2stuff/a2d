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
        ;; Run the DA
        sta     RAMRDON
        sta     RAMWRTON
        jsr     init

        ;; Back to main for exit
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endscope

;;; ============================================================

kDAWindowId    = 60
kDAWidth        = kScreenWidth / 3
kDAHeight       = kScreenHeight / 3
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

str_title:
        PASCAL_STRING res_string_window_title    ; window title

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
mincontlength:  .word   kScreenHeight / 5
maxcontwidth:   .word   kScreenWidth
maxcontlength:  .word   kScreenHeight
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

.params winport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport
.endparams


.params preserve_zp_params
flag:   .byte   MGTK::zp_preserve
.endparams

.params overwrite_zp_params
flag:   .byte   MGTK::zp_overwrite
.endparams

.params screentowindow_params
window_id:      .byte   kDAWindowId
        DEFINE_POINT screen, 0, 0
        DEFINE_POINT window, 0, 0
.endparams
        mx := screentowindow_params::window::xcoord
        my := screentowindow_params::window::ycoord

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

kGrowBoxWidth = 17
kGrowBoxHeight = 7

.params grow_box_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   grow_box_bitmap
mapwidth:       .byte   3
reserved:       .byte   0
        DEFINE_RECT cliprect, 2, 2, 19, 9
.endparams

grow_box_bitmap:
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1000000),PX(%0000000),PX(%0000001)
        .byte   PX(%1001111),PX(%1111110),PX(%0000001)
        .byte   PX(%1001100),PX(%0000111),PX(%1111001)
        .byte   PX(%1001100),PX(%0000110),PX(%0011001)
        .byte   PX(%1001100),PX(%0000110),PX(%0011001)
        .byte   PX(%1001111),PX(%1111110),PX(%0011001)
        .byte   PX(%1000011),PX(%0000000),PX(%0011001)
        .byte   PX(%1000011),PX(%1111111),PX(%1111001)
        .byte   PX(%1000000),PX(%0000000),PX(%0000001)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)

;;; ============================================================

.proc init
        lda     #0
        sta     SHIFT_SIGN_EXT  ; Must zero before using FP ops

        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     draw_window
        MGTK_CALL MGTK::FlushEvents
        ;; fall through
.endproc

.proc input_loop
        jsr     yield_loop
        MGTK_CALL MGTK::GetEvent, event_params
        bne     exit
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down
        beq     handle_down
        cmp     #MGTK::EventKind::key_down
        beq     handle_key
        cmp     #MGTK::EventKind::no_event
        beq     handle_no_event
        jmp     input_loop
.endproc

.proc exit
        MGTK_CALL MGTK::CloseWindow, winfo
        jsr     clear_updates
        rts
.endproc

;;; ============================================================

.proc handle_key
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     exit
        bne     input_loop
.endproc

;;; ============================================================

.proc handle_down
        copy16  event_params::xcoord, findwindow_params::mousex
        copy16  event_params::ycoord, findwindow_params::mousey
        MGTK_CALL MGTK::FindWindow, findwindow_params
        bne     exit
        lda     findwindow_params::window_id
        cmp     winfo::window_id
        bne     input_loop
        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        beq     handle_close
        cmp     #MGTK::Area::dragbar
        jeq     handle_drag
        cmp     #MGTK::Area::content
        bne     :+
        jmp     handle_grow
:       jmp     input_loop
.endproc

;;; ============================================================

.proc handle_close
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        bne     exit
        jmp     input_loop
.endproc

;;; ============================================================

.proc handle_no_event
        ;; First time? Need to store last coords
        lda     has_last_coords
        bne     test
        inc     has_last_coords
        bne     moved

test:
        ;; Compute absolute X delta
        sub16   event_params::xcoord, screentowindow_params::screen::xcoord, delta
        lda     delta+1
        bpl     :+
        sub16   #0, delta, delta ; negate
:       cmp16   delta, #kMoveThresholdX
        bpl     moved

        ;; Compute absolute Y delta
        sub16   event_params::ycoord, screentowindow_params::screen::ycoord, delta
        lda     delta+1
        bpl     :+
        sub16   #0, delta, delta ; negate
:       cmp16   delta, #kMoveThresholdY
        bpl     moved

        ;; Hasn't moved enough
        jmp     done

moved:  copy16  event_params::xcoord, screentowindow_params::screen::xcoord
        copy16  event_params::ycoord, screentowindow_params::screen::ycoord
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        jsr     draw_window

done:   jmp     input_loop


delta:  .word   0
.endproc

;;; ============================================================

.proc handle_drag
        copy    winfo::window_id, dragwindow_params::window_id
        copy16  event_params::xcoord, dragwindow_params::dragx
        copy16  event_params::ycoord, dragwindow_params::dragy
        MGTK_CALL MGTK::DragWindow, dragwindow_params
common: lda     dragwindow_params::moved
        bpl     :+

        ;; Draw DeskTop's windows and icons
        jsr     clear_updates

        ;; Draw DA's window
        lda     #0
        sta     has_last_coords
        sta     has_drawn_outline
        jsr     draw_window

:       jmp     input_loop

.endproc

;;; ============================================================

.proc handle_grow
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
        copy    winfo::window_id, dragwindow_params::window_id
        copy16  event_params::xcoord, dragwindow_params::dragx
        copy16  event_params::ycoord, dragwindow_params::dragy
        MGTK_CALL MGTK::GrowWindow, dragwindow_params
        jmp     handle_drag::common

nope:   jmp     input_loop

tmpw:   .word   0
.endproc

;;; ============================================================

.proc yield_loop
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_YIELD_LOOP
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

.proc clear_updates
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_CLEAR_UPDATES
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc

;;; ============================================================

penxor: .byte   MGTK::penXOR
notpencopy:     .byte   MGTK::notpencopy

kPenW    = 8
kPenH    = 4
kPupilW  = kPenW * 2
kPupilH  = kPenH * 2

.params outline_pensize
penwidth:       .byte   kPenW
penheight:      .byte   kPenH
.endparams

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

.proc draw_window
        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, winport_params
        cmp     #MGTK::Error::window_obscured
        bne     :+
        rts
:
        ;; Defer until we have mouse coords
        lda     has_last_coords
        bne     :+
        rts
:

        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        copy16  winfo::maprect::x2, rx ; width / 4
        inc16 rx
        inc16 rx
        lsr16 rx
        lsr16 rx
        copy16  winfo::maprect::y2, ry ; height / 2
        inc16 ry
        inc16 ry
        lsr16 ry

        lda     has_drawn_outline
        beq     :+
        jmp     erase_pupils
:       inc     has_drawn_outline

        ;; Draw resize box
        MGTK_CALL MGTK::SetPenMode, notpencopy
        sub16   winfo::maprect::x2, #kGrowBoxWidth, grow_box_params::viewloc::xcoord
        sub16   winfo::maprect::y2, #kGrowBoxHeight, grow_box_params::viewloc::ycoord
        MGTK_CALL MGTK::PaintBits, grow_box_params

        ;; Draw outline
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::SetPenSize, outline_pensize

        copy16  rx, cx
        copy16  ry, cy
        jsr draw_outline

        add16   rx, cx, cx
        add16   rx, cx, cx
        jsr draw_outline

        ;; Skip erasing pupils if we're redrawing
        jmp     draw_pupils

erase_pupils:
        MGTK_CALL MGTK::SetPenMode, penxor
        MGTK_CALL MGTK::SetPenSize, pupil_pensize

        MGTK_CALL MGTK::MoveTo, pos_l
        MGTK_CALL MGTK::LineTo, pos_l
        MGTK_CALL MGTK::MoveTo, pos_r
        MGTK_CALL MGTK::LineTo, pos_r

draw_pupils:
        MGTK_CALL MGTK::SetPenMode, penxor
        MGTK_CALL MGTK::SetPenSize, pupil_pensize

        copy16  rx, cx
        copy16  ry, cy
        jsr     compute_pupil_pos
        sub16  ppx, #kPupilW/2, pos_l::xcoord
        sub16  ppy, #kPupilH/2, pos_l::ycoord
        MGTK_CALL MGTK::MoveTo, pos_l
        MGTK_CALL MGTK::LineTo, pos_l

        add16   rx, cx, cx
        add16   rx, cx, cx
        jsr     compute_pupil_pos
        sub16  ppx, #kPupilW/2, pos_r::xcoord
        sub16  ppy, #kPupilH/2, pos_r::ycoord
        MGTK_CALL MGTK::MoveTo, pos_r
        MGTK_CALL MGTK::LineTo, pos_r

        MGTK_CALL MGTK::ShowCursor
done:   rts

tmpw:   .word   0
.endproc

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

.proc compute_pupil_pos
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
tmpf:   DEFINE_FLOAT

scale:  DEFINE_FLOAT
dx:     DEFINE_FLOAT
dy:     DEFINE_FLOAT
pry:    DEFINE_FLOAT
prx:    DEFINE_FLOAT
cxf:    DEFINE_FLOAT
cyf:    DEFINE_FLOAT
.endproc

;;; ============================================================
;;; Draw eye outlines as a 36-sided polygon
;;; Inputs: cx, cy, rx, ry

.proc draw_outline
        kSegments = 36

        bit     ROMIN2

        FAC_LOAD_INT    segw
        FAC_DIV         CON_TWO_PI
        FAC_STORE       step

        sub16   cx, #kPenW/2, tmpw
        FAC_LOAD_INT    tmpw
        FAC_STORE       cxf

        sub16   cy, #kPenH/2, tmpw
        FAC_LOAD_INT    tmpw
        FAC_STORE       cyf

        sub16   rx, #kPenW/2, tmpw
        FAC_LOAD_INT    tmpw
        FAC_STORE       rxf

        sub16   ry, #kPenH/2, tmpw
        FAC_LOAD_INT    tmpw
        FAC_STORE       ryf

        lda     #kSegments
        sta     count

        jsr     ZERO_FAC
        FAC_STORE theta

        FAC_LOAD rxf
        FAC_ADD  cxf
        FAC_STORE_INT ptx

        FAC_LOAD cyf
        FAC_STORE_INT pty

        bit     LCBANK1
        bit     LCBANK1

        MGTK_CALL MGTK::MoveTo, drawpos

loop:
        bit     ROMIN2

        FAC_LOAD theta
        FAC_ADD step
        FAC_STORE theta

        jsr COS
        FAC_MUL rxf
        FAC_ADD cxf
        FAC_STORE_INT ptx

        FAC_LOAD theta
        jsr SIN
        FAC_MUL ryf
        FAC_ADD cyf
        FAC_STORE_INT pty

        bit     LCBANK1
        bit     LCBANK1

        MGTK_CALL MGTK::LineTo, drawpos

        dec     count
        bpl     loop
        rts

count:  .byte   0
segw:   .word   kSegments
tmpw:   .word   0
step:   DEFINE_FLOAT
theta:  DEFINE_FLOAT
rxf:    DEFINE_FLOAT
ryf:    DEFINE_FLOAT
cxf:    DEFINE_FLOAT
cyf:    DEFINE_FLOAT

        DEFINE_POINT drawpos, 0, 0
        ptx := drawpos::xcoord
        pty := drawpos::ycoord
.endproc


;;; ============================================================

da_end := *
.assert * < $1B00, error, "DA too big"
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but entry tables start at AUX $1B00
