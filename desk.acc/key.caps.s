        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../mgtk/mgtk.inc"
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
    .elseif .paramcount = 3
        DEFINE_RECT left, top, right, top + key_height
    .else
        DEFINE_RECT left, top, right, bottom
    .endif
.endmacro

key_locations:

kr00:   KEY_RECT left0 +  1 * key_width, row0 ; Ctrl-@
kr01:   KEY_RECT left2 +  0 * key_width, row2 ; Ctrl-A
kr02:   KEY_RECT left3 +  4 * key_width, row3 ; Ctrl-B
kr03:   KEY_RECT left3 +  2 * key_width, row3 ; Ctrl-C
kr04:   KEY_RECT left2 +  2 * key_width, row2 ; Ctrl-D
kr05:   KEY_RECT left1 +  2 * key_width, row1 ; Ctrl-E
kr06:   KEY_RECT left2 +  3 * key_width, row2 ; Ctrl-F
kr07:   KEY_RECT left2 +  4 * key_width, row2 ; Ctrl-G
kr08:   KEY_RECT kb_right - key_width * 4, row4, kb_right - key_width * 3 ; Ctrl-H (left arrow)
kr09:   KEY_RECT kb_left, row1, left1         ; Ctrl-I (tab)
kr0A:   KEY_RECT kb_right - key_width * 2, row4, kb_right - key_width * 1 ; Ctrl-J (down arrow)
kr0B:   KEY_RECT kb_right - key_width * 1, row4, kb_right - key_width * 0 ; Ctrl-K (up arrow)
kr0C:   KEY_RECT left2 +  8 * key_width, row2 ; Ctrl-L
kr0D:   KEY_RECT kb_right - key_width *  7/4 - 1, row2, kb_right ; Ctrl-M (return)
kr0E:   KEY_RECT left3 +  5 * key_width, row3 ; Ctrl-N
kr0F:   KEY_RECT left1 +  8 * key_width, row1 ; Ctrl-O

kr10:   KEY_RECT left1 +  9 * key_width, row1 ; Ctrl-P
kr11:   KEY_RECT left1 +  0 * key_width, row1 ; Ctrl-Q
kr12:   KEY_RECT left1 +  3 * key_width, row1 ; Ctrl-R
kr13:   KEY_RECT left2 +  1 * key_width, row2 ; Ctrl-S
kr14:   KEY_RECT left1 +  4 * key_width, row1 ; Ctrl-T
kr15:   KEY_RECT kb_right - key_width * 3, row4, kb_right - key_width * 2 ; Ctrl-U (right arrow)
kr16:   KEY_RECT left3 +  3 * key_width, row3 ; Ctrl-V
kr17:   KEY_RECT left1 +  1 * key_width, row1 ; Ctrl-W
kr18:   KEY_RECT left3 +  1 * key_width, row3 ; Ctrl-X
kr19:   KEY_RECT left1 +  5 * key_width, row1 ; Ctrl-Y
kr1A:   KEY_RECT left3 +  0 * key_width, row3 ; Ctrl-Z
kr1B:   KEY_RECT kb_left, row0, left0         ; Ctrl-[ (escape)
kr1C:   KEY_RECT left1 + 12 * key_width, row1 ; Ctrl-\
kr1D:   KEY_RECT left1 + 11 * key_width, row1 ; Ctrl-]
kr1E:   KEY_RECT left0 +  5 * key_width, row0 ; Ctrl-^
kr1F:   KEY_RECT left0 + 10 * key_width, row0 ; Ctrl-_

kr20:   KEY_RECT kb_left + key_width * 4, row4, kb_right - key_width * 5 ; (space)
kr21:   KEY_RECT left0 +  0 * key_width, row0 ; !
kr22:   KEY_RECT left2 + 10 * key_width, row2 ; "
kr23:   KEY_RECT left0 +  2 * key_width, row0 ; #
kr24:   KEY_RECT left0 +  3 * key_width, row0 ; $
kr25:   KEY_RECT left0 +  4 * key_width, row0 ; %
kr26:   KEY_RECT left0 +  6 * key_width, row0 ; &
kr27:   KEY_RECT left2 + 10 * key_width, row2 ; '
kr28:   KEY_RECT left0 +  8 * key_width, row0 ; (
kr29:   KEY_RECT left0 +  9 * key_width, row0 ; )
kr2A:   KEY_RECT left0 +  7 * key_width, row0 ; *
kr2B:   KEY_RECT left0 + 11 * key_width, row0 ; +
kr2C:   KEY_RECT left3 +  7 * key_width, row3 ; ,
kr2D:   KEY_RECT left0 + 10 * key_width, row0 ; -
kr2E:   KEY_RECT left3 +  8 * key_width, row3 ; .
kr2F:   KEY_RECT left3 +  9 * key_width, row3 ; /

kr30:   KEY_RECT left0 +  9 * key_width, row0 ; 0
kr31:   KEY_RECT left0 +  0 * key_width, row0 ; 1
kr32:   KEY_RECT left0 +  1 * key_width, row0 ; 2
kr33:   KEY_RECT left0 +  2 * key_width, row0 ; 3
kr34:   KEY_RECT left0 +  3 * key_width, row0 ; 4
kr35:   KEY_RECT left0 +  4 * key_width, row0 ; 5
kr36:   KEY_RECT left0 +  5 * key_width, row0 ; 6
kr37:   KEY_RECT left0 +  6 * key_width, row0 ; 7
kr38:   KEY_RECT left0 +  7 * key_width, row0 ; 8
kr39:   KEY_RECT left0 +  8 * key_width, row0 ; 9
kr3A:   KEY_RECT left0 +  9 * key_width, row2 ; :
kr3B:   KEY_RECT left2 +  9 * key_width, row2 ; ;
kr3C:   KEY_RECT left3 +  7 * key_width, row3 ; <
kr3D:   KEY_RECT left0 + 11 * key_width, row0 ; =
kr3E:   KEY_RECT left3 +  8 * key_width, row3 ; >
kr3F:   KEY_RECT left3 +  9 * key_width, row3 ; ?

kr40:   KEY_RECT left0 +  1 * key_width, row0 ; @
kr41:   KEY_RECT left2 +  0 * key_width, row2 ; A
kr42:   KEY_RECT left3 +  4 * key_width, row3 ; B
kr43:   KEY_RECT left3 +  2 * key_width, row3 ; C
kr44:   KEY_RECT left2 +  2 * key_width, row2 ; D
kr45:   KEY_RECT left1 +  2 * key_width, row1 ; E
kr46:   KEY_RECT left2 +  3 * key_width, row2 ; F
kr47:   KEY_RECT left2 +  4 * key_width, row2 ; G
kr48:   KEY_RECT left2 +  5 * key_width, row2 ; H
kr49:   KEY_RECT left1 +  7 * key_width, row1 ; I
kr4A:   KEY_RECT left2 +  6 * key_width, row2 ; J
kr4B:   KEY_RECT left2 +  7 * key_width, row2 ; K
kr4C:   KEY_RECT left2 +  8 * key_width, row2 ; L
kr4D:   KEY_RECT left3 +  6 * key_width, row3 ; M
kr4E:   KEY_RECT left3 +  5 * key_width, row3 ; N
kr4F:   KEY_RECT left1 +  8 * key_width, row1 ; O

kr50:   KEY_RECT left1 +  9 * key_width, row1 ; P
kr51:   KEY_RECT left1 +  0 * key_width, row1 ; Q
kr52:   KEY_RECT left1 +  3 * key_width, row1 ; R
kr53:   KEY_RECT left2 +  1 * key_width, row2 ; S
kr54:   KEY_RECT left1 +  4 * key_width, row1 ; T
kr55:   KEY_RECT left1 +  6 * key_width, row1 ; U
kr56:   KEY_RECT left3 +  3 * key_width, row3 ; V
kr57:   KEY_RECT left1 +  1 * key_width, row1 ; W
kr58:   KEY_RECT left3 +  1 * key_width, row3 ; X
kr59:   KEY_RECT left1 +  5 * key_width, row1 ; Y
kr5A:   KEY_RECT left3 +  0 * key_width, row3 ; Z
kr5B:   KEY_RECT left1 + 10 * key_width, row1 ; [
kr5C:   KEY_RECT left1 + 12 * key_width, row1 ; \
kr5D:   KEY_RECT left1 + 11 * key_width, row1 ; ]
kr5E:   KEY_RECT left0 +  5 * key_width, row0 ; ^
kr5F:   KEY_RECT left0 + 10 * key_width, row0 ; _


kr60:   KEY_RECT left4 +  0 * key_width, row4 ; `
kr61:   KEY_RECT left2 +  0 * key_width, row2 ; a
kr62:   KEY_RECT left3 +  4 * key_width, row3 ; b
kr63:   KEY_RECT left3 +  2 * key_width, row3 ; c
kr64:   KEY_RECT left2 +  2 * key_width, row2 ; d
kr65:   KEY_RECT left1 +  2 * key_width, row1 ; e
kr66:   KEY_RECT left2 +  3 * key_width, row2 ; f
kr67:   KEY_RECT left2 +  4 * key_width, row2 ; g
kr68:   KEY_RECT left2 +  5 * key_width, row2 ; h
kr69:   KEY_RECT left1 +  7 * key_width, row1 ; i
kr6A:   KEY_RECT left2 +  6 * key_width, row2 ; j
kr6B:   KEY_RECT left2 +  7 * key_width, row2 ; k
kr6C:   KEY_RECT left2 +  8 * key_width, row2 ; l
kr6D:   KEY_RECT left3 +  6 * key_width, row3 ; m
kr6E:   KEY_RECT left3 +  5 * key_width, row3 ; n
kr6F:   KEY_RECT left1 +  8 * key_width, row1 ; o

kr70:   KEY_RECT left1 +  9 * key_width, row1 ; p
kr71:   KEY_RECT left1 +  0 * key_width, row1 ; q
kr72:   KEY_RECT left1 +  3 * key_width, row1 ; r
kr73:   KEY_RECT left2 +  1 * key_width, row2 ; s
kr74:   KEY_RECT left1 +  4 * key_width, row1 ; t
kr75:   KEY_RECT left1 +  6 * key_width, row1 ; u
kr76:   KEY_RECT left3 +  3 * key_width, row3 ; v
kr77:   KEY_RECT left1 +  1 * key_width, row1 ; w
kr78:   KEY_RECT left3 +  1 * key_width, row3 ; x
kr79:   KEY_RECT left1 +  5 * key_width, row1 ; y
kr7A:   KEY_RECT left3 +  0 * key_width, row3 ; z
kr7B:   KEY_RECT left1 + 10 * key_width, row1 ; {
kr7C:   KEY_RECT left1 + 12 * key_width, row1 ; |
kr7D:   KEY_RECT left1 + 11 * key_width, row1 ; }
kr7E:   KEY_RECT left4 +  0 * key_width, row4 ; ~
kr7F:   KEY_RECT kb_right - key_width *  6/4, row0, kb_right ; (delete)

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

rect_ctl: KEY_RECT   kb_left, row2, left2
rect_shl: KEY_RECT   kb_left, row3, left3
rect_cap: KEY_RECT   kb_left, row4, left4
rect_gap: KEY_RECT   kb_left + key_width * 2, row4
rect_oap: KEY_RECT   kb_left + key_width * 3, row4
rect_sap: KEY_RECT   kb_right - key_width * 5, row4, kb_right - key_width * 4
rect_shr: KEY_RECT   kb_right - key_width *  9/4 - 1, row3, kb_right

label_relpos:   DEFINE_POINT 8, 12

empty_rect:       DEFINE_RECT 0, 0, 0, 0

;;; New keyboard locations on IIgs/IIc+
;;;

rect_new_oap:                   ; Open Apple
        KEY_RECT kb_left + key_width * 2, row4, kb_left + key_width * 4
rect_new_sap:                   ; Solid Apple
        KEY_RECT left4 +  0 * key_width, row4
rect_new_apos:                  ; Apostrophe/Tilde
        KEY_RECT kb_left + key_width * 4, row4
rect_new_bshl:                  ; Backslash/Vertical Bar
        KEY_RECT kb_right - key_width * 5, row4, kb_right - key_width * 4
rect_new_spc:                   ; Space
        KEY_RECT kb_left + key_width * 5, row4, kb_right - key_width * 5

;;; Non-rectangular Return key handled by a Polygon:
;;;
;;;       1/7--2
;;;        |   |
;;;    5---6   |
;;;    |       |
;;;    4-------3

poly_new_ret:
        .byte   7               ; vertex count
        .byte   0               ; no more polys
        DEFINE_POINT left1 + 12 * key_width, row1
        DEFINE_POINT kb_right, row1
        DEFINE_POINT kb_right, row3
        DEFINE_POINT kb_right - key_width *  7/4 - 1, row3
        DEFINE_POINT kb_right - key_width *  7/4 - 1, row2
        DEFINE_POINT left1 + 12 * key_width, row2
        DEFINE_POINT left1 + 12 * key_width, row1

poly_new_ret_inner:
        .byte   7               ; vertex count
        .byte   0               ; no more polys
        DEFINE_POINT left1 + 12 * key_width + 4, row1 + 2
        DEFINE_POINT kb_right - 3, row1 + 2
        DEFINE_POINT kb_right - 3, row3 - 1
        DEFINE_POINT kb_right - key_width *  7/4 - 1 + 4, row3 - 1
        DEFINE_POINT kb_right - key_width *  7/4 - 1 + 4, row2 + 2
        DEFINE_POINT left1 + 12 * key_width + 4, row2 + 2
        DEFINE_POINT left1 + 12 * key_width + 4, row1 + 2

modern_layout_flag:             ; high bit set if IIgs/IIc+
        .byte   0

tmp_poly:
        .res    2 + 7 * .sizeof(MGTK::Point), 0

tmp_rect:
        DEFINE_RECT 0,0,0,0, tmp_rect

;;; ============================================================

.proc init
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        jsr     check_modern_layout
        bcc     continue

        ;; Swap in alternate layout
        copy    #$80, modern_layout_flag
        COPY_STRUCT MGTK::Rect, empty_rect, rect_gap ; Gap is eliminated
        COPY_STRUCT MGTK::Rect, rect_new_bshl, kr5C ; [\|] replaces Solid Apple
        COPY_STRUCT MGTK::Rect, rect_new_bshl, kr7C
        COPY_STRUCT MGTK::Rect, rect_new_apos, kr60 ; [`~] takes away from Space
        COPY_STRUCT MGTK::Rect, rect_new_apos, kr7E
        COPY_STRUCT MGTK::Rect, rect_new_spc, kr20 ; Space is smaller
        COPY_STRUCT MGTK::Rect, rect_new_oap, rect_oap ; Open Apple moves
        COPY_STRUCT MGTK::Rect, rect_new_sap, rect_sap ; Solid Apple (Option) moves
        ;; Return key handled separately

continue:
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
        ;; Apple-Q to quit
        lda     event_params::modifiers
        beq     start
        lda     event_params::key
        cmp     #'Q'
        beq     exit

start:  lda     KBD
        and     #$7F
        sta     last_char

        jsr     construct_key_poly

        MGTK_CALL MGTK::GetWinPort, winport_params
        cmp     #MGTK::Error::window_obscured
        beq     done

        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::SetPenMode, penxor
        MGTK_CALL MGTK::PaintPoly, tmp_poly

:       bit     KBDSTRB
        bpl     :+

        lda     KBD
        and     #$7F
        cmp     last_char
        beq     :-
        MGTK_CALL MGTK::PaintPoly, tmp_poly
        jmp     start


:       MGTK_CALL MGTK::PaintPoly, tmp_poly

done:   jmp     input_loop

last_char:
        .byte   0

return_flag:
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
:

        bit     modern_layout_flag
        bpl     :+

        ;; Modern layout's non-rectangular Return key
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::SetPattern, winfo::pattern
        MGTK_CALL MGTK::PaintPoly, poly_new_ret
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FramePoly, poly_new_ret

:       MGTK_CALL MGTK::ShowCursor
        rts

char:   .byte   0
.endproc

;;; ============================================================
;;; Returns Carry set if modern (IIgs/IIc+) layout should be used

.proc check_modern_layout

        ;; Button down? (Hack for testing)
        lda     BUTN0
        ora     BUTN1
        bpl     :+
        sec
        rts
:

        ;; Bank in ROM and do check
        lda     ROMIN2
        jsr     check
        lda     LCBANK1
        lda     LCBANK1
        rts

        ;; --------------------------------------------------
        ;; Do the check (with ROM banked in)

        ;; Is IIgs?
check:  sec
        jsr     ID_BYTE_FE1F    ; Clears carry if IIgs
        bcs     :+              ; No, carry still set
        sec                     ; Yes, is a IIgs
        rts

        ;; Is IIc+?
:       lda     ID_BYTE_FBC0    ; $00 = IIc
        bne     done
        lda     ID_BYTE_FBBF    ; $05 = IIc Plus
        cmp     #$05
        bne     done
        sec                     ; Yes, is a IIc+
        rts

done:   clc                     ; No - older layout
        rts
.endproc

;;; ============================================================
;;; Construct "inner" polygon for key in A.
;;; Output: tmp_poly is populated

.proc construct_key_poly
        ptr := $06

        cmp     #CHAR_RETURN
        bne     normal
        bit     modern_layout_flag
        bpl     normal

        ;; Special key
        COPY_BYTES      2 + 7 * .sizeof(MGTK::Point), poly_new_ret_inner, tmp_poly
        rts

        ;; Rectangular key
normal:
        ;; Compute address of rect
        sta     ptr
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

        copy    #5, tmp_poly+0  ; # vertices
        copy    #0, tmp_poly+1  ; no more polys
        add16   tmp_rect::x1, #4, tmp_poly+2 + (0 * .sizeof(MGTK::Point))
        add16   tmp_rect::y1, #2, tmp_poly+2 + (0 * .sizeof(MGTK::Point))+2

        sub16   tmp_rect::x2, #3, tmp_poly+2 + (1 * .sizeof(MGTK::Point))
        add16   tmp_rect::y1, #2, tmp_poly+2 + (1 * .sizeof(MGTK::Point))+2

        sub16   tmp_rect::x2, #3, tmp_poly+2 + (2 * .sizeof(MGTK::Point))
        sub16   tmp_rect::y2, #1, tmp_poly+2 + (2 * .sizeof(MGTK::Point))+2

        add16   tmp_rect::x1, #4, tmp_poly+2 + (3 * .sizeof(MGTK::Point))
        sub16   tmp_rect::y2, #1, tmp_poly+2 + (3 * .sizeof(MGTK::Point))+2

        add16   tmp_rect::x1, #4, tmp_poly+2 + (4 * .sizeof(MGTK::Point))
        add16   tmp_rect::y1, #2, tmp_poly+2 + (4 * .sizeof(MGTK::Point))+2
        rts
.endproc

da_end  = *
.assert * < $1B00, error, "DA too big"
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but icon tables start at AUX $1B00
