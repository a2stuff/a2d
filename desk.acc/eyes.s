        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"
        .include "../inc/fp_macros.inc"

;;; ============================================================

        .org $800

entry:

;;; Copy the DA to AUX for easy bank switching
.scope
        lda     ROMIN2
        copy16  #$0800, STARTLO
        copy16  #da_end, ENDLO
        copy16  #$0800, DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE
        lda     LCBANK1
        lda     LCBANK1
.endscope

.scope
        ;; run the DA
        sta     RAMRDON
        sta     RAMWRTON
        jsr     init

        ;; tear down/exit
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endscope

;;; ============================================================

screen_width    := 560
screen_height   := 192

da_window_id    := 60
da_width        := screen_width / 3
da_height       := screen_height / 3
da_left         := (screen_width - da_width)/2
da_top          := 50

str_title:
        PASCAL_STRING "Eyes"

;;; TODO: Allow resizing

.proc winfo
window_id:      .byte   da_window_id
options:        .byte   MGTK::option_go_away_box
title:          .addr   str_title
hscroll:        .byte   MGTK::scroll_option_none
vscroll:        .byte   MGTK::scroll_option_none
hthumbmax:      .byte   32
hthumbpos:      .byte   0
vthumbmax:      .byte   32
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   da_width
mincontlength:  .word   da_height
maxcontwidth:   .word   da_width
maxcontlength:  .word   da_height
port:
viewloc:        DEFINE_POINT da_left, da_top
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
maprect:        DEFINE_RECT 0, 0, da_width, da_height
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:          DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endproc

;;; ============================================================


.proc event_params
kind:  .byte   0
;;; event_kind_key_down
key             := *
modifiers       := * + 1
;;; event_kind_update
window_id       := *
;;; otherwise
xcoord          := *
ycoord          := * + 2
        .res    4
.endproc

.proc findwindow_params
mousex:         .word   0
mousey:         .word   0
which_area:     .byte   0
window_id:      .byte   0
.endproc

.proc trackgoaway_params
clicked:        .byte   0
.endproc

.proc dragwindow_params
window_id:      .byte   0
dragx:          .word   0
dragy:          .word   0
moved:          .byte   0
.endproc

.proc winport_params
window_id:      .byte   da_window_id
port:           .addr   grafport
.endproc


.proc preserve_zp_params
flag:   .byte   MGTK::zp_preserve
.endproc

.proc overwrite_zp_params
flag:   .byte   MGTK::zp_overwrite
.endproc

.proc screentowindow_params
window_id:      .byte   da_window_id
        DEFINE_POINT 0, 0, screen
        DEFINE_POINT 0, 0, window
.endproc
        mx := screentowindow_params::window::xcoord
        my := screentowindow_params::window::ycoord

.proc grafport
viewloc:        DEFINE_POINT 0, 0
mapbits:        .word   0
mapwidth:       .word   0
cliprect:       DEFINE_RECT 0, 0, 0, 0
pattern:        .res    8, 0
colormasks:     .byte   0, 0
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   0
penheight:      .byte   0
penmode:        .byte   0
textback:       .byte   0
textfont:       .addr   0
.endproc

;;; ============================================================

.proc init
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        MGTK_CALL MGTK::SetZP1, preserve_zp_params
        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     draw_window
        MGTK_CALL MGTK::FlushEvents
        ;; fall through
.endproc

.proc input_loop
        MGTK_CALL MGTK::GetEvent, event_params
        bne     exit
        lda     event_params::kind
        cmp     #MGTK::event_kind_button_down
        beq     handle_down
        cmp     #MGTK::event_kind_key_down
        beq     handle_key
        cmp     #MGTK::event_kind_no_event
        beq     handle_no_event
        jmp     input_loop
.endproc

.proc exit
        MGTK_CALL MGTK::CloseWindow, winfo
        DESKTOP_CALL DT_REDRAW_ICONS
        MGTK_CALL MGTK::SetZP1, overwrite_zp_params
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
        cmp     #MGTK::area_close_box
        beq     handle_close
        cmp     #MGTK::area_dragbar
        beq     handle_drag
        jmp     input_loop
.endproc

;;; ============================================================

.proc handle_close
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        beq     input_loop
        bne     exit
.endproc

;;; ============================================================

.proc handle_no_event
        ;; First time? Need to store last coords
        lda     has_last_coords
        bne     test
        inc     has_last_coords
        bne     moved

        ;; Moved?
test:
        lda     event_params::xcoord
        cmp     screentowindow_params::screen::xcoord
        bne     moved
        lda     event_params::xcoord+1
        cmp     screentowindow_params::screen::xcoord+1
        bne     moved
        lda     event_params::ycoord
        cmp     screentowindow_params::screen::ycoord
        bne     moved
        lda     event_params::ycoord+1
        cmp     screentowindow_params::screen::ycoord+1
        beq     done

moved:  copy16  event_params::xcoord, screentowindow_params::screen::xcoord
        copy16  event_params::ycoord, screentowindow_params::screen::ycoord
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params
        jsr     draw_window

done:   jmp     input_loop

.endproc

;;; ============================================================

.proc handle_drag
        copy    winfo::window_id, dragwindow_params::window_id
        copy16  event_params::xcoord, dragwindow_params::dragx
        copy16  event_params::ycoord, dragwindow_params::dragy
        MGTK_CALL MGTK::DragWindow, dragwindow_params
        lda     dragwindow_params::moved
        bpl     :+

        ;; Draw DeskTop's windows
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_REDRAW_ALL
        sta     RAMRDON
        sta     RAMWRTON

        ;; Draw DA's window
        lda     #0
        sta     has_last_coords
        sta     has_drawn_outline
        jsr     draw_window

        ;; Draw DeskTop icons
        DESKTOP_CALL DT_REDRAW_ICONS

:       jmp     input_loop

.endproc

;;; ============================================================

penxor: .byte   MGTK::penXOR
notpencopy:     .byte   MGTK::notpencopy

penw    := 8
penh    := 4
pupilw  := penw * 2
pupilh  := penh * 2

.proc outline_pensize
penwidth:       .byte   penw
penheight:      .byte   penh
.endproc

.proc pupil_pensize
penwidth:       .byte   pupilw
penheight:      .byte   pupilh
.endproc

;;; Flag set once we have coords from a move event
has_last_coords:
        .byte   0

;;; Flag set once outline is drawn (cleared on window move)
has_drawn_outline:
        .byte   0

;;; Saved coords
pos_l:        DEFINE_POINT 0, 0, pos_l
pos_r:        DEFINE_POINT 0, 0, pos_r

;;; ============================================================

.proc draw_window
        ptr := $06

        ;; Defer until we have mouse coords
        lda     has_last_coords
        bne     :+
        rts
:

        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, winport_params
        cmp     #MGTK::error_window_obscured
        bne     :+
        rts
:

        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        lda     has_drawn_outline
        bne     erase_pupils
        inc     has_drawn_outline

        ;; Draw outline
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::SetPenSize, outline_pensize

        copy16  #da_width/4, cx
        copy16  #da_height/2, cy
        jsr draw_outline
        copy16  #da_width * 3/4, cx
        copy16  #da_height/2, cy
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

        copy16  #da_width/4, cx
        copy16  #da_height/2, cy
        jsr     compute_pupil_pos
        sub16  ppx, #pupilw/2, pos_l::xcoord
        sub16  ppy, #pupilh/2, pos_l::ycoord
        MGTK_CALL MGTK::MoveTo, pos_l
        MGTK_CALL MGTK::LineTo, pos_l

        copy16  #da_width*3/4, cx
        copy16  #da_height/2, cy
        jsr     compute_pupil_pos
        sub16  ppx, #pupilw/2, pos_r::xcoord
        sub16  ppy, #pupilh/2, pos_r::ycoord
        MGTK_CALL MGTK::MoveTo, pos_r
        MGTK_CALL MGTK::LineTo, pos_r

        MGTK_CALL MGTK::ShowCursor
done:   rts
.endproc

;;; ============================================================
;;; Common input params

rx:     .word   da_width/4
ry:     .word   da_height/2

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
        lda     ROMIN2

        fac_load_int    cx
        fac_store       cxf

        fac_load_int    cy
        fac_store       cyf

        ;; pupil shouldn't overlap border
        sub16  rx, #penw, tmpw
        sub16  tmpw, #pupilw, tmpw
        fac_load_int tmpw
        fac_store prx

        sub16  ry, #penh, tmpw
        sub16  tmpw, #pupilh, tmpw
        fac_load_int    tmpw
        fac_store       pry

        ;; x scale, so math is circular
        ;; xs = pry / prx

        fac_load        prx
        fac_div         pry
        fac_store       scale

        ;; mouse delta, in transformed space
        ;; dx = (mx - cx) * xs
        ;; dy = mx - cy

        fac_load_int    mx      ; dx = (mx - cx) * xs
        fac_store       tmpf
        fac_load        cxf
        fac_sub         tmpf
        fac_mul         scale
        fac_store       dx

        fac_load_int    my      ; dy = mx - cy
        fac_store       tmpf
        fac_load        cyf
        fac_sub         tmpf
        fac_store       dy

        ;; d = SQR(dx * dx + dy * dy)

        fac_load        dx
        fac_mul         dx
        fac_store       tmpf
        fac_load        dy
        fac_mul         dy
        fac_add         tmpf

        jsr             SQR     ; ??? Crashes here after window drag

        ;; if d > pry:
        ;;   f = pry / d
        ;;   dx = f * dx
        ;;   dy = f * dy

        fac_comp pry
        bmi     skip

        fac_div         pry     ; f = pry / d
        fac_store       tmpf

        fac_mul         dx      ; dx = f * dx
        fac_store       dx

        fac_load        tmpf    ; dy = f * dy
        fac_mul         dy
        fac_store       dy
skip:

        ;; plot coords
        ;; ppx = (dx / xs) + cx
        ;; ppy = dy + cy

        fac_load        scale   ; ppx = (dx / xs) + cx
        fac_div         dx
        fac_add         cxf
        fac_store_int   ppx

        fac_load        dy      ; ppy = dy + cy
        fac_add         cyf
        fac_store_int   ppy

        lda     LCBANK1
        lda     LCBANK1

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
        segments := 36

        lda     ROMIN2

        fac_load_int    segw
        fac_div         CON_TWO_PI
        fac_store       step

        sub16   cx, #penw/2, tmpw
        fac_load_int    tmpw
        fac_store       cxf

        sub16   cy, #penh/2, tmpw
        fac_load_int    tmpw
        fac_store       cyf

        sub16   rx, #penw/2, tmpw
        fac_load_int    tmpw
        fac_store       rxf

        sub16   ry, #penh/2, tmpw
        fac_load_int    tmpw
        fac_store       ryf

        lda     #segments
        sta     count

        jsr     ZERO_FAC
        fac_store theta

        fac_load rxf
        fac_add  cxf
        fac_store_int ptx

        fac_load cyf
        fac_store_int pty

        lda     LCBANK1
        lda     LCBANK1

        MGTK_CALL MGTK::MoveTo, drawpos

loop:
        lda     ROMIN2

        fac_load theta
        fac_add step
        fac_store theta

        jsr COS
        fac_mul rxf
        fac_add cxf
        fac_store_int ptx

        fac_load theta
        jsr SIN
        fac_mul ryf
        fac_add cyf
        fac_store_int pty

        lda     LCBANK1
        lda     LCBANK1

        MGTK_CALL MGTK::LineTo, drawpos

        dec     count
        bpl     loop
        rts

count:  .byte   0
segw:   .word   segments
tmpw:   .word   0
step:   DEFINE_FLOAT
theta:  DEFINE_FLOAT
rxf:    DEFINE_FLOAT
ryf:    DEFINE_FLOAT
cxf:    DEFINE_FLOAT
cyf:    DEFINE_FLOAT

drawpos:        DEFINE_POINT 0, 0, drawpos
        ptx := drawpos::xcoord
        pty := drawpos::ycoord
.endproc


;;; ============================================================

da_end  = *
.assert * < $1B00, error, "DA too big"
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but icon tables start at AUX $1B00
