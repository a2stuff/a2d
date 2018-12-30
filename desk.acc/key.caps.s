        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

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

        key_width = 22
        key_height = 15

da_window_id    = 60
da_width        = key_width * 31/2
da_height       = key_height * 6
da_left         = (screen_width - da_width)/2
da_top          = 50

.proc winfo
window_id:      .byte   da_window_id
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
penwidth:       .byte   2
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endproc

str_title:
        PASCAL_STRING "Key Caps"

background_pattern:
        .byte   %11011101
        .byte   %01110111
        .byte   %11011101
        .byte   %01110111
        .byte   %11011101
        .byte   %01110111
        .byte   %11011101
        .byte   %01110111

background_rect:
        DEFINE_RECT 0, 0, da_width, da_height

penxor:
        .byte   MGTK::penXOR
pencopy:
        .byte   MGTK::pencopy
notpencopy:
        .byte   MGTK::notpencopy

;;; ============================================================

.proc event_params
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

.proc drawtext_params_char
        .addr   char_label
        .byte   1
.endproc
char_label:  .byte   0

;;; ============================================================

        kb_left = key_width/2
        kb_top  = key_height/2

        kb_right = kb_left + key_width * 29/2

        left0 = kb_left + key_width
        left1 = kb_left + key_width *  6/4
        left2 = kb_left + key_width *  7/4
        left3 = kb_left + key_width *  9/4
        left4 = kb_left + key_width

        row0 = kb_top
        row1 = kb_top + 1 * key_height
        row2 = kb_top + 2 * key_height
        row3 = kb_top + 3 * key_height
        row4 = kb_top + 4 * key_height

keys_bg_rect:
        DEFINE_RECT kb_left, kb_top, kb_right, kb_top + key_height * 5

.macro KEY_RECT left, top, right, bottom
    .if .paramcount = 0
        DEFINE_RECT 0,0,0,0
    .elseif .paramcount = 2
        DEFINE_RECT left, top, left + key_width, top + key_height
    .else
        DEFINE_RECT left, top, right, bottom
    .endif
.endmacro

key_locations:
        KEY_RECT left0 +  1 * key_width, row0 ; Ctrl-@
        KEY_RECT left2 +  0 * key_width, row2 ; Ctrl-A
        KEY_RECT left3 +  4 * key_width, row3 ; Ctrl-B
        KEY_RECT left3 +  2 * key_width, row3 ; Ctrl-C
        KEY_RECT left2 +  2 * key_width, row2 ; Ctrl-D
        KEY_RECT left1 +  2 * key_width, row1 ; Ctrl-E
        KEY_RECT left2 +  3 * key_width, row2 ; Ctrl-F
        KEY_RECT left2 +  4 * key_width, row2 ; Ctrl-G
        KEY_RECT kb_right - key_width * 4, row4, kb_right - key_width * 3, row4 + key_height ; Ctrl-H (left arrow)
        KEY_RECT kb_left, row1, left1, row1 + key_height ; Ctrl-I (tab)
        KEY_RECT kb_right - key_width * 2, row4, kb_right - key_width * 1, row4 + key_height ; Ctrl-J (down arrow)
        KEY_RECT kb_right - key_width * 1, row4, kb_right - key_width * 0, row4 + key_height ; Ctrl-K (up arrow)
        KEY_RECT left2 +  8 * key_width, row2 ; Ctrl-L
        KEY_RECT kb_right - key_width *  7/4 - 1, row2, kb_right, row2 + key_height ; Ctrl-M (return)
        KEY_RECT left3 +  5 * key_width, row3 ; Ctrl-N
        KEY_RECT left1 +  8 * key_width, row1 ; Ctrl-O

        KEY_RECT left1 +  9 * key_width, row1 ; Ctrl-P
        KEY_RECT left1 +  0 * key_width, row1 ; Ctrl-Q
        KEY_RECT left1 +  3 * key_width, row1 ; Ctrl-R
        KEY_RECT left2 +  1 * key_width, row2 ; Ctrl-S
        KEY_RECT left1 +  4 * key_width, row1 ; Ctrl-T
        KEY_RECT kb_right - key_width * 3, row4, kb_right - key_width * 2, row4 + key_height ; Ctrl-U (right arrow)
        KEY_RECT left3 +  3 * key_width, row3 ; Ctrl-V
        KEY_RECT left1 +  1 * key_width, row1 ; Ctrl-W
        KEY_RECT left3 +  1 * key_width, row3 ; Ctrl-X
        KEY_RECT left1 +  5 * key_width, row1 ; Ctrl-Y
        KEY_RECT left3 +  0 * key_width, row3 ; Ctrl-Z
        KEY_RECT kb_left, row0, left0, row0 + key_height ; Ctrl-[ (escape)
        KEY_RECT left1 + 12 * key_width, row1 ; Ctrl-\
        KEY_RECT left1 + 11 * key_width, row1 ; Ctrl-]
        KEY_RECT left0 +  5 * key_width, row0 ; Ctrl-^
        KEY_RECT left0 + 10 * key_width, row0 ; Ctrl-_

        KEY_RECT kb_left + key_width * 4, row4, kb_right - key_width * 5, row4 + key_height ; (space)
        KEY_RECT left0 +  0 * key_width, row0 ; !
        KEY_RECT left2 + 10 * key_width, row2 ; "
        KEY_RECT left0 +  2 * key_width, row0 ; #
        KEY_RECT left0 +  3 * key_width, row0 ; $
        KEY_RECT left0 +  4 * key_width, row0 ; %
        KEY_RECT left0 +  6 * key_width, row0 ; &
        KEY_RECT left2 + 10 * key_width, row2 ; '
        KEY_RECT left0 +  8 * key_width, row0 ; (
        KEY_RECT left0 +  9 * key_width, row0 ; )
        KEY_RECT left0 +  7 * key_width, row0 ; *
        KEY_RECT left0 + 11 * key_width, row0 ; +
        KEY_RECT left3 +  7 * key_width, row3 ; ,
        KEY_RECT left0 + 10 * key_width, row0 ; -
        KEY_RECT left3 +  8 * key_width, row3 ; .
        KEY_RECT left3 +  9 * key_width, row3 ; /

        KEY_RECT left0 +  9 * key_width, row0 ; 0
        KEY_RECT left0 +  0 * key_width, row0 ; 1
        KEY_RECT left0 +  1 * key_width, row0 ; 2
        KEY_RECT left0 +  2 * key_width, row0 ; 3
        KEY_RECT left0 +  3 * key_width, row0 ; 4
        KEY_RECT left0 +  4 * key_width, row0 ; 5
        KEY_RECT left0 +  5 * key_width, row0 ; 6
        KEY_RECT left0 +  6 * key_width, row0 ; 7
        KEY_RECT left0 +  7 * key_width, row0 ; 8
        KEY_RECT left0 +  8 * key_width, row0 ; 9
        KEY_RECT left0 +  9 * key_width, row2 ; :
        KEY_RECT left2 +  9 * key_width, row2 ; ;
        KEY_RECT left3 +  7 * key_width, row3 ; <
        KEY_RECT left0 + 11 * key_width, row0 ; =
        KEY_RECT left3 +  8 * key_width, row3 ; >
        KEY_RECT left3 +  9 * key_width, row3 ; ?

        KEY_RECT left0 +  1 * key_width, row0 ; @
        KEY_RECT left2 +  0 * key_width, row2 ; A
        KEY_RECT left3 +  4 * key_width, row3 ; B
        KEY_RECT left3 +  2 * key_width, row3 ; C
        KEY_RECT left2 +  2 * key_width, row2 ; D
        KEY_RECT left1 +  2 * key_width, row1 ; E
        KEY_RECT left2 +  3 * key_width, row2 ; F
        KEY_RECT left2 +  4 * key_width, row2 ; G
        KEY_RECT left2 +  5 * key_width, row2 ; H
        KEY_RECT left1 +  7 * key_width, row1 ; I
        KEY_RECT left2 +  6 * key_width, row2 ; J
        KEY_RECT left2 +  7 * key_width, row2 ; K
        KEY_RECT left2 +  8 * key_width, row2 ; L
        KEY_RECT left3 +  6 * key_width, row3 ; M
        KEY_RECT left3 +  5 * key_width, row3 ; N
        KEY_RECT left1 +  8 * key_width, row1 ; O

        KEY_RECT left1 +  9 * key_width, row1 ; P
        KEY_RECT left1 +  0 * key_width, row1 ; Q
        KEY_RECT left1 +  3 * key_width, row1 ; R
        KEY_RECT left2 +  1 * key_width, row2 ; S
        KEY_RECT left1 +  4 * key_width, row1 ; T
        KEY_RECT left1 +  6 * key_width, row1 ; U
        KEY_RECT left3 +  3 * key_width, row3 ; V
        KEY_RECT left1 +  1 * key_width, row1 ; W
        KEY_RECT left3 +  1 * key_width, row3 ; X
        KEY_RECT left1 +  5 * key_width, row1 ; Y
        KEY_RECT left3 +  0 * key_width, row3 ; Z
        KEY_RECT left1 + 10 * key_width, row1 ; [
        KEY_RECT left1 + 12 * key_width, row1 ; \
        KEY_RECT left1 + 11 * key_width, row1 ; ]
        KEY_RECT left0 +  5 * key_width, row0 ; ^
        KEY_RECT left0 + 10 * key_width, row0 ; _

        KEY_RECT left4 +  0 * key_width, row4 ; `
        KEY_RECT left2 +  0 * key_width, row2 ; a
        KEY_RECT left3 +  4 * key_width, row3 ; b
        KEY_RECT left3 +  2 * key_width, row3 ; c
        KEY_RECT left2 +  2 * key_width, row2 ; d
        KEY_RECT left1 +  2 * key_width, row1 ; e
        KEY_RECT left2 +  3 * key_width, row2 ; f
        KEY_RECT left2 +  4 * key_width, row2 ; g
        KEY_RECT left2 +  5 * key_width, row2 ; h
        KEY_RECT left1 +  7 * key_width, row1 ; i
        KEY_RECT left2 +  6 * key_width, row2 ; j
        KEY_RECT left2 +  7 * key_width, row2 ; k
        KEY_RECT left2 +  8 * key_width, row2 ; l
        KEY_RECT left3 +  6 * key_width, row3 ; m
        KEY_RECT left3 +  5 * key_width, row3 ; n
        KEY_RECT left1 +  8 * key_width, row1 ; o

        KEY_RECT left1 +  9 * key_width, row1 ; p
        KEY_RECT left1 +  0 * key_width, row1 ; q
        KEY_RECT left1 +  3 * key_width, row1 ; r
        KEY_RECT left2 +  1 * key_width, row2 ; s
        KEY_RECT left1 +  4 * key_width, row1 ; t
        KEY_RECT left1 +  6 * key_width, row1 ; u
        KEY_RECT left3 +  3 * key_width, row3 ; v
        KEY_RECT left1 +  1 * key_width, row1 ; w
        KEY_RECT left3 +  1 * key_width, row3 ; x
        KEY_RECT left1 +  5 * key_width, row1 ; y
        KEY_RECT left3 +  0 * key_width, row3 ; z
        KEY_RECT left1 + 10 * key_width, row1 ; {
        KEY_RECT left1 + 12 * key_width, row1 ; |
        KEY_RECT left1 + 11 * key_width, row1 ; }
        KEY_RECT left4 +  0 * key_width, row4 ; ~
        KEY_RECT kb_right - key_width *  6/4, row0, kb_right, row0 + key_height ; (delete)

        ;; shift/plain
        kmode_s = $80           ; shifted (symbols)/unshifted (letters) - don't draw
        kmode_c = $80           ; unrepresented control - don't draw
        kmode_p = 0             ; plain - draw

key_mode:
        .byte   kmode_c         ; Ctrl-@
        .byte   kmode_c         ; Ctrl-A
        .byte   kmode_c         ; Ctrl-B
        .byte   kmode_c         ; Ctrl-C
        .byte   kmode_c         ; Ctrl-D
        .byte   kmode_c         ; Ctrl-E
        .byte   kmode_c         ; Ctrl-F
        .byte   kmode_c         ; Ctrl-G
        .byte   kmode_p         ; Ctrl-H (left arrow)
        .byte   kmode_p         ; Ctrl-I (tab)
        .byte   kmode_p         ; Ctrl-J (down arrow)
        .byte   kmode_p         ; Ctrl-K (up arrow)
        .byte   kmode_c         ; Ctrl-L
        .byte   kmode_p         ; Ctrl-M (return)
        .byte   kmode_c         ; Ctrl-N
        .byte   kmode_c         ; Ctrl-O

        .byte   kmode_c         ; Ctrl-P
        .byte   kmode_c         ; Ctrl-Q
        .byte   kmode_c         ; Ctrl-R
        .byte   kmode_c         ; Ctrl-S
        .byte   kmode_c         ; Ctrl-T
        .byte   kmode_p         ; Ctrl-U (right arrow)
        .byte   kmode_c         ; Ctrl-V
        .byte   kmode_c         ; Ctrl-W
        .byte   kmode_c         ; Ctrl-X
        .byte   kmode_c         ; Ctrl-Y
        .byte   kmode_c         ; Ctrl-Z
        .byte   kmode_p         ; Ctrl-[ (escape)
        .byte   kmode_c         ; Ctrl-\
        .byte   kmode_c         ; Ctrl-]
        .byte   kmode_c         ; Ctrl-^
        .byte   kmode_c         ; Ctrl-_

        .byte   kmode_p         ; (space)
        .byte   kmode_s         ; !
        .byte   kmode_s         ; "
        .byte   kmode_s         ; #
        .byte   kmode_s         ; $
        .byte   kmode_s         ; %
        .byte   kmode_s         ; &
        .byte   kmode_p         ; '
        .byte   kmode_s         ; (
        .byte   kmode_s         ; )
        .byte   kmode_s         ; *
        .byte   kmode_s         ; +
        .byte   kmode_p         ; ,
        .byte   kmode_p         ; -
        .byte   kmode_p         ; .
        .byte   kmode_p         ; /

        .byte   kmode_p         ; 0
        .byte   kmode_p         ; 1
        .byte   kmode_p         ; 2
        .byte   kmode_p         ; 3
        .byte   kmode_p         ; 4
        .byte   kmode_p         ; 5
        .byte   kmode_p         ; 6
        .byte   kmode_p         ; 7
        .byte   kmode_p         ; 8
        .byte   kmode_p         ; 9
        .byte   kmode_s         ; :
        .byte   kmode_p         ; ;
        .byte   kmode_s         ; <
        .byte   kmode_p         ; =
        .byte   kmode_s         ; >
        .byte   kmode_s         ; ?

        .byte   kmode_s         ; @
        .byte   kmode_p         ; A
        .byte   kmode_p         ; B
        .byte   kmode_p         ; C
        .byte   kmode_p         ; D
        .byte   kmode_p         ; E
        .byte   kmode_p         ; F
        .byte   kmode_p         ; G
        .byte   kmode_p         ; H
        .byte   kmode_p         ; I
        .byte   kmode_p         ; J
        .byte   kmode_p         ; K
        .byte   kmode_p         ; L
        .byte   kmode_p         ; M
        .byte   kmode_p         ; N
        .byte   kmode_p         ; O

        .byte   kmode_p         ; P
        .byte   kmode_p         ; Q
        .byte   kmode_p         ; R
        .byte   kmode_p         ; S
        .byte   kmode_p         ; T
        .byte   kmode_p         ; U
        .byte   kmode_p         ; V
        .byte   kmode_p         ; W
        .byte   kmode_p         ; X
        .byte   kmode_p         ; Y
        .byte   kmode_p         ; Z
        .byte   kmode_p         ; [
        .byte   kmode_p         ; \
        .byte   kmode_p         ; ]
        .byte   kmode_s         ; ^
        .byte   kmode_s         ; _

        .byte   kmode_p         ; `
        .byte   kmode_s         ; a
        .byte   kmode_s         ; b
        .byte   kmode_s         ; c
        .byte   kmode_s         ; d
        .byte   kmode_s         ; e
        .byte   kmode_s         ; f
        .byte   kmode_s         ; g
        .byte   kmode_s         ; h
        .byte   kmode_s         ; i
        .byte   kmode_s         ; j
        .byte   kmode_s         ; k
        .byte   kmode_s         ; l
        .byte   kmode_s         ; m
        .byte   kmode_s         ; n
        .byte   kmode_s         ; o

        .byte   kmode_s         ; p
        .byte   kmode_s         ; q
        .byte   kmode_s         ; r
        .byte   kmode_s         ; s
        .byte   kmode_s         ; t
        .byte   kmode_s         ; u
        .byte   kmode_s         ; v
        .byte   kmode_s         ; w
        .byte   kmode_s         ; x
        .byte   kmode_s         ; y
        .byte   kmode_s         ; z
        .byte   kmode_s         ; {
        .byte   kmode_s         ; |
        .byte   kmode_s         ; }
        .byte   kmode_s         ; ~
        .byte   kmode_p         ; DEL (FIX)



rect_ctl: DEFINE_RECT   kb_left, row2, left2, row2 + key_height
rect_shl: DEFINE_RECT   kb_left, row3, left3, row3 + key_height
rect_cap: DEFINE_RECT   kb_left, row4, left4, row4 + key_height
rect_gap: DEFINE_RECT   kb_left + key_width * 2, row4, kb_left + key_width * 3, row4 + key_height
rect_oap: DEFINE_RECT   kb_left + key_width * 3, row4, kb_left + key_width * 4, row4 + key_height
rect_sap: DEFINE_RECT   kb_right - key_width * 5, row4, kb_right - key_width * 4, row4 + key_height
rect_shr: DEFINE_RECT   kb_right - key_width *  9/4 - 1, row3, kb_right, row3 + key_height

label_relpos:   DEFINE_POINT 8, 12

tmp_rect:       DEFINE_RECT 0, 0, 0, 0, tmp_rect

;;; ============================================================

.proc init
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     draw_window
        MGTK_CALL MGTK::FlushEvents
        ;; fall through
.endproc

.proc input_loop
        MGTK_CALL MGTK::GetEvent, event_params
        bne     exit
        lda     event_params::kind
        cmp     #MGTK::EventKind::button_down ; was clicked?
        bne     :+
        jmp     handle_down


:       cmp     #MGTK::EventKind::key_down  ; any key?
        bne     :+
        jmp     handle_key


:       jmp     input_loop
.endproc

.proc exit
        MGTK_CALL MGTK::CloseWindow, winfo
        DESKTOP_CALL DT_REDRAW_ICONS
        rts                     ; exits input loop
.endproc

;;; ============================================================

.proc handle_key
        ptr := $06

        ;; Apple-Q to quit
        lda     event_params::modifiers
        beq     start
        lda     event_params::key
        cmp     #'Q'
        beq     exit

start:  lda     KBD
        and     #$7F
        sta     last_char

        ;; Compute address of point
        sta     ptr
        copy    #0, ptr+1
        asl16   ptr             ; * 8 = .sizeof(MGTK::Rect)
        asl16   ptr
        asl16   ptr
        add16   ptr, #key_locations, ptr

copy_rect:
        ldy     #.sizeof(MGTK::Rect)-1
:       lda     (ptr),y
        sta     tmp_rect,y
        dey
        bpl     :-

        add16   tmp_rect::x1, #4, tmp_rect::x1
        add16   tmp_rect::y1, #2, tmp_rect::y1
        sub16   tmp_rect::x2, #3, tmp_rect::x2
        sub16   tmp_rect::y2, #2, tmp_rect::y2

        MGTK_CALL MGTK::GetWinPort, winport_params
        cmp     #MGTK::Error::window_obscured
        beq     done

        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::SetPenMode, penxor
        MGTK_CALL MGTK::PaintRect, tmp_rect

:       bit     KBDSTRB
        bpl     :+

        lda     KBD
        and     #$7F
        cmp     last_char
        beq     :-
        MGTK_CALL MGTK::PaintRect, tmp_rect
        jmp     start


:       MGTK_CALL MGTK::PaintRect, tmp_rect

done:   jmp     input_loop

last_char:
        .byte   0
.endproc

;;; ============================================================

.proc handle_down
        copy16  event_params::xcoord, findwindow_params::mousex
        copy16  event_params::ycoord, findwindow_params::mousey
        MGTK_CALL MGTK::FindWindow, findwindow_params
        bpl     :+
        jmp     exit
:       lda     findwindow_params::window_id
        cmp     winfo::window_id
        bpl     :+
        jmp     input_loop
:       lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        beq     handle_close
        cmp     #MGTK::Area::dragbar
        beq     handle_drag
        jmp     input_loop
.endproc

;;; ============================================================

.proc handle_close
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        bne     :+
        jmp     input_loop
:       jmp     exit
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
        jsr     draw_window

        ;; Draw DeskTop icons
        DESKTOP_CALL DT_REDRAW_ICONS

:       jmp     input_loop

.endproc

;;; ============================================================

.proc draw_window
        ptr := $06

        MGTK_CALL MGTK::GetWinPort, winport_params
        cmp     #MGTK::Error::window_obscured
        bne     :+
        rts

:       MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::SetPattern, background_pattern
        MGTK_CALL MGTK::PaintRect, background_rect

        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::SetPattern, winfo::pattern
        MGTK_CALL MGTK::PaintRect, keys_bg_rect
        MGTK_CALL MGTK::SetPattern, background_pattern
        MGTK_CALL MGTK::PaintRect, rect_gap
        MGTK_CALL MGTK::SetPattern, winfo::pattern

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FrameRect, rect_ctl
        MGTK_CALL MGTK::FrameRect, rect_shl
        MGTK_CALL MGTK::FrameRect, rect_cap
        MGTK_CALL MGTK::FrameRect, rect_shr
        MGTK_CALL MGTK::FrameRect, rect_oap
        MGTK_CALL MGTK::FrameRect, rect_sap

        copy    #127, char

loop:
        lda     char
        sta     char_label

        tax
        ldy     key_mode,x
        bpl     :+
        jmp     next

        ;; Compute address of key record
:       sta     ptr
        copy    #0, ptr+1
        asl16   ptr             ; * 8 = .sizeof(MGTK::Rect)
        asl16   ptr
        asl16   ptr
        add16   ptr, #key_locations, ptr

        ldy     #.sizeof(MGTK::Rect)-1
:       lda     (ptr),y
        sta     tmp_rect,y
        dey
        bpl     :-

        MGTK_CALL MGTK::FrameRect, tmp_rect

        lda     char
        cmp     #' '
        bcc     next
        cmp     #CHAR_DELETE
        bcs     next

        MGTK_CALL MGTK::MoveTo, tmp_rect
        MGTK_CALL MGTK::Move, label_relpos
        MGTK_CALL MGTK::DrawText, drawtext_params_char

next:   dec     char
        lda     char
        bmi     :+
        jmp     loop

:       MGTK_CALL MGTK::ShowCursor
        rts

char:   .byte   0
.endproc

da_end  = *
.assert * < $1B00, error, "DA too big"
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but icon tables start at AUX $1B00
