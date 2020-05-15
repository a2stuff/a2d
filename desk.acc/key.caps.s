;;; ============================================================
;;; KEY.CAPS - Desk Accessory
;;;
;;; Displays a map of the keyboard, showing what key is pressed.
;;; ============================================================

        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

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

        kKeyWidth = 22
        kKeyHeight = 15

kDAWindowId    = 60
kDAWidth        = kKeyWidth * 31/2
kDAHeight       = kKeyHeight * 6
kDALeft         = (kScreenWidth - kDAWidth)/2
kDATop          = (kScreenHeight - kMenuBarHeight - kDAHeight)/2 + kMenuBarHeight

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
mincontwidth:   .word   kDAWidth
mincontlength:  .word   kDAHeight
maxcontwidth:   .word   kDAWidth
maxcontlength:  .word   kDAHeight
port:
viewloc:        DEFINE_POINT kDALeft, kDATop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
maprect:        DEFINE_RECT 0, 0, kDAWidth, kDAHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:          DEFINE_POINT 0, 0
penwidth:       .byte   2
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endparams

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
        DEFINE_RECT 0, 0, kDAWidth, kDAHeight

penxor:
        .byte   MGTK::penXOR
pencopy:
        .byte   MGTK::pencopy
notpencopy:
        .byte   MGTK::notpencopy

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

.params grafport
viewloc:        DEFINE_POINT 0, 0
mapbits:        .word   0
mapwidth:       .byte   0
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, 0, 0
pattern:        .res    8, 0
colormasks:     .byte   0, 0
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   0
penheight:      .byte   0
penmode:        .byte   0
textback:       .byte   0
textfont:       .addr   0
.endparams

.params drawtext_params_char
        .addr   char_label
        .byte   1
.endparams
char_label:  .byte   0

;;; ============================================================

        kKeyboardLeft = kKeyWidth/2
        kKeyboardTop  = kKeyHeight/2

        kKeyboardRight = kKeyboardLeft + kKeyWidth * 29/2

        kLeft0 = kKeyboardLeft + kKeyWidth
        kLeft1 = kKeyboardLeft + kKeyWidth *  6/4
        kLeft2 = kKeyboardLeft + kKeyWidth *  7/4
        kLeft3 = kKeyboardLeft + kKeyWidth *  9/4
        kLeft4 = kKeyboardLeft + kKeyWidth

        kRow0 = kKeyboardTop
        kRow1 = kKeyboardTop + 1 * kKeyHeight
        kRow2 = kKeyboardTop + 2 * kKeyHeight
        kRow3 = kKeyboardTop + 3 * kKeyHeight
        kRow4 = kKeyboardTop + 4 * kKeyHeight

keys_bg_rect:
        DEFINE_RECT kKeyboardLeft, kKeyboardTop, kKeyboardRight, kKeyboardTop + kKeyHeight * 5

.macro KEY_RECT left, top, right, bottom
    .if .paramcount = 0
        DEFINE_RECT 0,0,0,0
    .elseif .paramcount = 2
        DEFINE_RECT left, top, left + kKeyWidth, top + kKeyHeight
    .elseif .paramcount = 3
        DEFINE_RECT left, top, right, top + kKeyHeight
    .else
        DEFINE_RECT left, top, right, bottom
    .endif
.endmacro

key_locations:

kr00:   KEY_RECT kLeft0 +  1 * kKeyWidth, kRow0 ; Ctrl-@
kr01:   KEY_RECT kLeft2 +  0 * kKeyWidth, kRow2 ; Ctrl-A
kr02:   KEY_RECT kLeft3 +  4 * kKeyWidth, kRow3 ; Ctrl-B
kr03:   KEY_RECT kLeft3 +  2 * kKeyWidth, kRow3 ; Ctrl-C
kr04:   KEY_RECT kLeft2 +  2 * kKeyWidth, kRow2 ; Ctrl-D
kr05:   KEY_RECT kLeft1 +  2 * kKeyWidth, kRow1 ; Ctrl-E
kr06:   KEY_RECT kLeft2 +  3 * kKeyWidth, kRow2 ; Ctrl-F
kr07:   KEY_RECT kLeft2 +  4 * kKeyWidth, kRow2 ; Ctrl-G
kr08:   KEY_RECT kKeyboardRight - kKeyWidth * 4, kRow4, kKeyboardRight - kKeyWidth * 3 ; Ctrl-H (left arrow)
kr09:   KEY_RECT kKeyboardLeft, kRow1, kLeft1         ; Ctrl-I (tab)
kr0A:   KEY_RECT kKeyboardRight - kKeyWidth * 2, kRow4, kKeyboardRight - kKeyWidth * 1 ; Ctrl-J (down arrow)
kr0B:   KEY_RECT kKeyboardRight - kKeyWidth * 1, kRow4, kKeyboardRight - kKeyWidth * 0 ; Ctrl-K (up arrow)
kr0C:   KEY_RECT kLeft2 +  8 * kKeyWidth, kRow2 ; Ctrl-L
kr0D:   KEY_RECT kKeyboardRight - kKeyWidth *  7/4 - 1, kRow2, kKeyboardRight ; Ctrl-M (return)
kr0E:   KEY_RECT kLeft3 +  5 * kKeyWidth, kRow3 ; Ctrl-N
kr0F:   KEY_RECT kLeft1 +  8 * kKeyWidth, kRow1 ; Ctrl-O

kr10:   KEY_RECT kLeft1 +  9 * kKeyWidth, kRow1 ; Ctrl-P
kr11:   KEY_RECT kLeft1 +  0 * kKeyWidth, kRow1 ; Ctrl-Q
kr12:   KEY_RECT kLeft1 +  3 * kKeyWidth, kRow1 ; Ctrl-R
kr13:   KEY_RECT kLeft2 +  1 * kKeyWidth, kRow2 ; Ctrl-S
kr14:   KEY_RECT kLeft1 +  4 * kKeyWidth, kRow1 ; Ctrl-T
kr15:   KEY_RECT kKeyboardRight - kKeyWidth * 3, kRow4, kKeyboardRight - kKeyWidth * 2 ; Ctrl-U (right arrow)
kr16:   KEY_RECT kLeft3 +  3 * kKeyWidth, kRow3 ; Ctrl-V
kr17:   KEY_RECT kLeft1 +  1 * kKeyWidth, kRow1 ; Ctrl-W
kr18:   KEY_RECT kLeft3 +  1 * kKeyWidth, kRow3 ; Ctrl-X
kr19:   KEY_RECT kLeft1 +  5 * kKeyWidth, kRow1 ; Ctrl-Y
kr1A:   KEY_RECT kLeft3 +  0 * kKeyWidth, kRow3 ; Ctrl-Z
kr1B:   KEY_RECT kKeyboardLeft, kRow0, kLeft0         ; Ctrl-[ (escape)
kr1C:   KEY_RECT kLeft1 + 12 * kKeyWidth, kRow1 ; Ctrl-\
kr1D:   KEY_RECT kLeft1 + 11 * kKeyWidth, kRow1 ; Ctrl-]
kr1E:   KEY_RECT kLeft0 +  5 * kKeyWidth, kRow0 ; Ctrl-^
kr1F:   KEY_RECT kLeft0 + 10 * kKeyWidth, kRow0 ; Ctrl-_

kr20:   KEY_RECT kKeyboardLeft + kKeyWidth * 4, kRow4, kKeyboardRight - kKeyWidth * 5 ; (space)
kr21:   KEY_RECT kLeft0 +  0 * kKeyWidth, kRow0 ; !
kr22:   KEY_RECT kLeft2 + 10 * kKeyWidth, kRow2 ; "
kr23:   KEY_RECT kLeft0 +  2 * kKeyWidth, kRow0 ; #
kr24:   KEY_RECT kLeft0 +  3 * kKeyWidth, kRow0 ; $
kr25:   KEY_RECT kLeft0 +  4 * kKeyWidth, kRow0 ; %
kr26:   KEY_RECT kLeft0 +  6 * kKeyWidth, kRow0 ; &
kr27:   KEY_RECT kLeft2 + 10 * kKeyWidth, kRow2 ; '
kr28:   KEY_RECT kLeft0 +  8 * kKeyWidth, kRow0 ; (
kr29:   KEY_RECT kLeft0 +  9 * kKeyWidth, kRow0 ; )
kr2A:   KEY_RECT kLeft0 +  7 * kKeyWidth, kRow0 ; *
kr2B:   KEY_RECT kLeft0 + 11 * kKeyWidth, kRow0 ; +
kr2C:   KEY_RECT kLeft3 +  7 * kKeyWidth, kRow3 ; ,
kr2D:   KEY_RECT kLeft0 + 10 * kKeyWidth, kRow0 ; -
kr2E:   KEY_RECT kLeft3 +  8 * kKeyWidth, kRow3 ; .
kr2F:   KEY_RECT kLeft3 +  9 * kKeyWidth, kRow3 ; /

kr30:   KEY_RECT kLeft0 +  9 * kKeyWidth, kRow0 ; 0
kr31:   KEY_RECT kLeft0 +  0 * kKeyWidth, kRow0 ; 1
kr32:   KEY_RECT kLeft0 +  1 * kKeyWidth, kRow0 ; 2
kr33:   KEY_RECT kLeft0 +  2 * kKeyWidth, kRow0 ; 3
kr34:   KEY_RECT kLeft0 +  3 * kKeyWidth, kRow0 ; 4
kr35:   KEY_RECT kLeft0 +  4 * kKeyWidth, kRow0 ; 5
kr36:   KEY_RECT kLeft0 +  5 * kKeyWidth, kRow0 ; 6
kr37:   KEY_RECT kLeft0 +  6 * kKeyWidth, kRow0 ; 7
kr38:   KEY_RECT kLeft0 +  7 * kKeyWidth, kRow0 ; 8
kr39:   KEY_RECT kLeft0 +  8 * kKeyWidth, kRow0 ; 9
kr3A:   KEY_RECT kLeft2 +  9 * kKeyWidth, kRow2 ; :
kr3B:   KEY_RECT kLeft2 +  9 * kKeyWidth, kRow2 ; ;
kr3C:   KEY_RECT kLeft3 +  7 * kKeyWidth, kRow3 ; <
kr3D:   KEY_RECT kLeft0 + 11 * kKeyWidth, kRow0 ; =
kr3E:   KEY_RECT kLeft3 +  8 * kKeyWidth, kRow3 ; >
kr3F:   KEY_RECT kLeft3 +  9 * kKeyWidth, kRow3 ; ?

kr40:   KEY_RECT kLeft0 +  1 * kKeyWidth, kRow0 ; @
kr41:   KEY_RECT kLeft2 +  0 * kKeyWidth, kRow2 ; A
kr42:   KEY_RECT kLeft3 +  4 * kKeyWidth, kRow3 ; B
kr43:   KEY_RECT kLeft3 +  2 * kKeyWidth, kRow3 ; C
kr44:   KEY_RECT kLeft2 +  2 * kKeyWidth, kRow2 ; D
kr45:   KEY_RECT kLeft1 +  2 * kKeyWidth, kRow1 ; E
kr46:   KEY_RECT kLeft2 +  3 * kKeyWidth, kRow2 ; F
kr47:   KEY_RECT kLeft2 +  4 * kKeyWidth, kRow2 ; G
kr48:   KEY_RECT kLeft2 +  5 * kKeyWidth, kRow2 ; H
kr49:   KEY_RECT kLeft1 +  7 * kKeyWidth, kRow1 ; I
kr4A:   KEY_RECT kLeft2 +  6 * kKeyWidth, kRow2 ; J
kr4B:   KEY_RECT kLeft2 +  7 * kKeyWidth, kRow2 ; K
kr4C:   KEY_RECT kLeft2 +  8 * kKeyWidth, kRow2 ; L
kr4D:   KEY_RECT kLeft3 +  6 * kKeyWidth, kRow3 ; M
kr4E:   KEY_RECT kLeft3 +  5 * kKeyWidth, kRow3 ; N
kr4F:   KEY_RECT kLeft1 +  8 * kKeyWidth, kRow1 ; O

kr50:   KEY_RECT kLeft1 +  9 * kKeyWidth, kRow1 ; P
kr51:   KEY_RECT kLeft1 +  0 * kKeyWidth, kRow1 ; Q
kr52:   KEY_RECT kLeft1 +  3 * kKeyWidth, kRow1 ; R
kr53:   KEY_RECT kLeft2 +  1 * kKeyWidth, kRow2 ; S
kr54:   KEY_RECT kLeft1 +  4 * kKeyWidth, kRow1 ; T
kr55:   KEY_RECT kLeft1 +  6 * kKeyWidth, kRow1 ; U
kr56:   KEY_RECT kLeft3 +  3 * kKeyWidth, kRow3 ; V
kr57:   KEY_RECT kLeft1 +  1 * kKeyWidth, kRow1 ; W
kr58:   KEY_RECT kLeft3 +  1 * kKeyWidth, kRow3 ; X
kr59:   KEY_RECT kLeft1 +  5 * kKeyWidth, kRow1 ; Y
kr5A:   KEY_RECT kLeft3 +  0 * kKeyWidth, kRow3 ; Z
kr5B:   KEY_RECT kLeft1 + 10 * kKeyWidth, kRow1 ; [
kr5C:   KEY_RECT kLeft1 + 12 * kKeyWidth, kRow1 ; \
kr5D:   KEY_RECT kLeft1 + 11 * kKeyWidth, kRow1 ; ]
kr5E:   KEY_RECT kLeft0 +  5 * kKeyWidth, kRow0 ; ^
kr5F:   KEY_RECT kLeft0 + 10 * kKeyWidth, kRow0 ; _


kr60:   KEY_RECT kLeft4 +  0 * kKeyWidth, kRow4 ; `
kr61:   KEY_RECT kLeft2 +  0 * kKeyWidth, kRow2 ; a
kr62:   KEY_RECT kLeft3 +  4 * kKeyWidth, kRow3 ; b
kr63:   KEY_RECT kLeft3 +  2 * kKeyWidth, kRow3 ; c
kr64:   KEY_RECT kLeft2 +  2 * kKeyWidth, kRow2 ; d
kr65:   KEY_RECT kLeft1 +  2 * kKeyWidth, kRow1 ; e
kr66:   KEY_RECT kLeft2 +  3 * kKeyWidth, kRow2 ; f
kr67:   KEY_RECT kLeft2 +  4 * kKeyWidth, kRow2 ; g
kr68:   KEY_RECT kLeft2 +  5 * kKeyWidth, kRow2 ; h
kr69:   KEY_RECT kLeft1 +  7 * kKeyWidth, kRow1 ; i
kr6A:   KEY_RECT kLeft2 +  6 * kKeyWidth, kRow2 ; j
kr6B:   KEY_RECT kLeft2 +  7 * kKeyWidth, kRow2 ; k
kr6C:   KEY_RECT kLeft2 +  8 * kKeyWidth, kRow2 ; l
kr6D:   KEY_RECT kLeft3 +  6 * kKeyWidth, kRow3 ; m
kr6E:   KEY_RECT kLeft3 +  5 * kKeyWidth, kRow3 ; n
kr6F:   KEY_RECT kLeft1 +  8 * kKeyWidth, kRow1 ; o

kr70:   KEY_RECT kLeft1 +  9 * kKeyWidth, kRow1 ; p
kr71:   KEY_RECT kLeft1 +  0 * kKeyWidth, kRow1 ; q
kr72:   KEY_RECT kLeft1 +  3 * kKeyWidth, kRow1 ; r
kr73:   KEY_RECT kLeft2 +  1 * kKeyWidth, kRow2 ; s
kr74:   KEY_RECT kLeft1 +  4 * kKeyWidth, kRow1 ; t
kr75:   KEY_RECT kLeft1 +  6 * kKeyWidth, kRow1 ; u
kr76:   KEY_RECT kLeft3 +  3 * kKeyWidth, kRow3 ; v
kr77:   KEY_RECT kLeft1 +  1 * kKeyWidth, kRow1 ; w
kr78:   KEY_RECT kLeft3 +  1 * kKeyWidth, kRow3 ; x
kr79:   KEY_RECT kLeft1 +  5 * kKeyWidth, kRow1 ; y
kr7A:   KEY_RECT kLeft3 +  0 * kKeyWidth, kRow3 ; z
kr7B:   KEY_RECT kLeft1 + 10 * kKeyWidth, kRow1 ; {
kr7C:   KEY_RECT kLeft1 + 12 * kKeyWidth, kRow1 ; |
kr7D:   KEY_RECT kLeft1 + 11 * kKeyWidth, kRow1 ; }
kr7E:   KEY_RECT kLeft4 +  0 * kKeyWidth, kRow4 ; ~
kr7F:   KEY_RECT kKeyboardRight - kKeyWidth *  6/4, kRow0, kKeyboardRight ; (delete)

        ;; shift/plain
        kModeS = $80           ; shifted (symbols)/unshifted (letters) - don't draw
        kModeC = $80           ; unrepresented control - don't draw
        kModeP = 0             ; plain - draw

key_mode:
        .byte   kModeC         ; Ctrl-@
        .byte   kModeC         ; Ctrl-A
        .byte   kModeC         ; Ctrl-B
        .byte   kModeC         ; Ctrl-C
        .byte   kModeC         ; Ctrl-D
        .byte   kModeC         ; Ctrl-E
        .byte   kModeC         ; Ctrl-F
        .byte   kModeC         ; Ctrl-G
        .byte   kModeP         ; Ctrl-H (left arrow)
        .byte   kModeP         ; Ctrl-I (tab)
        .byte   kModeP         ; Ctrl-J (down arrow)
        .byte   kModeP         ; Ctrl-K (up arrow)
        .byte   kModeC         ; Ctrl-L
        .byte   kModeP         ; Ctrl-M (return)
        .byte   kModeC         ; Ctrl-N
        .byte   kModeC         ; Ctrl-O

        .byte   kModeC         ; Ctrl-P
        .byte   kModeC         ; Ctrl-Q
        .byte   kModeC         ; Ctrl-R
        .byte   kModeC         ; Ctrl-S
        .byte   kModeC         ; Ctrl-T
        .byte   kModeP         ; Ctrl-U (right arrow)
        .byte   kModeC         ; Ctrl-V
        .byte   kModeC         ; Ctrl-W
        .byte   kModeC         ; Ctrl-X
        .byte   kModeC         ; Ctrl-Y
        .byte   kModeC         ; Ctrl-Z
        .byte   kModeP         ; Ctrl-[ (escape)
        .byte   kModeC         ; Ctrl-\
        .byte   kModeC         ; Ctrl-]
        .byte   kModeC         ; Ctrl-^
        .byte   kModeC         ; Ctrl-_

        .byte   kModeP         ; (space)
        .byte   kModeS         ; !
        .byte   kModeS         ; "
        .byte   kModeS         ; #
        .byte   kModeS         ; $
        .byte   kModeS         ; %
        .byte   kModeS         ; &
        .byte   kModeP         ; '
        .byte   kModeS         ; (
        .byte   kModeS         ; )
        .byte   kModeS         ; *
        .byte   kModeS         ; +
        .byte   kModeP         ; ,
        .byte   kModeP         ; -
        .byte   kModeP         ; .
        .byte   kModeP         ; /

        .byte   kModeP         ; 0
        .byte   kModeP         ; 1
        .byte   kModeP         ; 2
        .byte   kModeP         ; 3
        .byte   kModeP         ; 4
        .byte   kModeP         ; 5
        .byte   kModeP         ; 6
        .byte   kModeP         ; 7
        .byte   kModeP         ; 8
        .byte   kModeP         ; 9
        .byte   kModeS         ; :
        .byte   kModeP         ; ;
        .byte   kModeS         ; <
        .byte   kModeP         ; =
        .byte   kModeS         ; >
        .byte   kModeS         ; ?

        .byte   kModeS         ; @
        .byte   kModeP         ; A
        .byte   kModeP         ; B
        .byte   kModeP         ; C
        .byte   kModeP         ; D
        .byte   kModeP         ; E
        .byte   kModeP         ; F
        .byte   kModeP         ; G
        .byte   kModeP         ; H
        .byte   kModeP         ; I
        .byte   kModeP         ; J
        .byte   kModeP         ; K
        .byte   kModeP         ; L
        .byte   kModeP         ; M
        .byte   kModeP         ; N
        .byte   kModeP         ; O

        .byte   kModeP         ; P
        .byte   kModeP         ; Q
        .byte   kModeP         ; R
        .byte   kModeP         ; S
        .byte   kModeP         ; T
        .byte   kModeP         ; U
        .byte   kModeP         ; V
        .byte   kModeP         ; W
        .byte   kModeP         ; X
        .byte   kModeP         ; Y
        .byte   kModeP         ; Z
        .byte   kModeP         ; [
        .byte   kModeP         ; \
        .byte   kModeP         ; ]
        .byte   kModeS         ; ^
        .byte   kModeS         ; _

        .byte   kModeP         ; `
        .byte   kModeS         ; a
        .byte   kModeS         ; b
        .byte   kModeS         ; c
        .byte   kModeS         ; d
        .byte   kModeS         ; e
        .byte   kModeS         ; f
        .byte   kModeS         ; g
        .byte   kModeS         ; h
        .byte   kModeS         ; i
        .byte   kModeS         ; j
        .byte   kModeS         ; k
        .byte   kModeS         ; l
        .byte   kModeS         ; m
        .byte   kModeS         ; n
        .byte   kModeS         ; o

        .byte   kModeS         ; p
        .byte   kModeS         ; q
        .byte   kModeS         ; r
        .byte   kModeS         ; s
        .byte   kModeS         ; t
        .byte   kModeS         ; u
        .byte   kModeS         ; v
        .byte   kModeS         ; w
        .byte   kModeS         ; x
        .byte   kModeS         ; y
        .byte   kModeS         ; z
        .byte   kModeS         ; {
        .byte   kModeS         ; |
        .byte   kModeS         ; }
        .byte   kModeS         ; ~
        .byte   kModeP         ; DEL (FIX)

rect_ctl: KEY_RECT   kKeyboardLeft, kRow2, kLeft2
rect_shl: KEY_RECT   kKeyboardLeft, kRow3, kLeft3
rect_cap: KEY_RECT   kKeyboardLeft, kRow4, kLeft4
rect_gap: KEY_RECT   kKeyboardLeft + kKeyWidth * 2, kRow4
rect_oap: KEY_RECT   kKeyboardLeft + kKeyWidth * 3, kRow4
rect_sap: KEY_RECT   kKeyboardRight - kKeyWidth * 5, kRow4, kKeyboardRight - kKeyWidth * 4
rect_shr: KEY_RECT   kKeyboardRight - kKeyWidth *  9/4 - 1, kRow3, kKeyboardRight

label_relpos:   DEFINE_POINT 8, 12

empty_rect:       DEFINE_RECT 0, 0, 0, 0

;;; New keyboard locations on IIgs/IIc+
;;;

rect_new_oap:                   ; Open Apple
        KEY_RECT kKeyboardLeft + kKeyWidth * 2, kRow4, kKeyboardLeft + kKeyWidth * 4
rect_new_sap:                   ; Solid Apple
        KEY_RECT kLeft4 +  0 * kKeyWidth, kRow4
rect_new_apos:                  ; Apostrophe/Tilde
        KEY_RECT kKeyboardLeft + kKeyWidth * 4, kRow4
rect_new_bshl:                  ; Backslash/Vertical Bar
        KEY_RECT kKeyboardRight - kKeyWidth * 5, kRow4, kKeyboardRight - kKeyWidth * 4
rect_new_spc:                   ; Space
        KEY_RECT kKeyboardLeft + kKeyWidth * 5, kRow4, kKeyboardRight - kKeyWidth * 5

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
        DEFINE_POINT kLeft1 + 12 * kKeyWidth, kRow1
        DEFINE_POINT kKeyboardRight, kRow1
        DEFINE_POINT kKeyboardRight, kRow3
        DEFINE_POINT kKeyboardRight - kKeyWidth *  7/4 - 1, kRow3
        DEFINE_POINT kKeyboardRight - kKeyWidth *  7/4 - 1, kRow2
        DEFINE_POINT kLeft1 + 12 * kKeyWidth, kRow2
        DEFINE_POINT kLeft1 + 12 * kKeyWidth, kRow1

poly_new_ret_inner:
        .byte   7               ; vertex count
        .byte   0               ; no more polys
        DEFINE_POINT kLeft1 + 12 * kKeyWidth + 4, kRow1 + 2
        DEFINE_POINT kKeyboardRight - 3, kRow1 + 2
        DEFINE_POINT kKeyboardRight - 3, kRow3 - 1
        DEFINE_POINT kKeyboardRight - kKeyWidth *  7/4 - 1 + 4, kRow3 - 1
        DEFINE_POINT kKeyboardRight - kKeyWidth *  7/4 - 1 + 4, kRow2 + 2
        DEFINE_POINT kLeft1 + 12 * kKeyWidth + 4, kRow2 + 2
        DEFINE_POINT kLeft1 + 12 * kKeyWidth + 4, kRow1 + 2

extended_layout_flag:           ; high bit set if IIgs/IIc+
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

        jsr     check_extended_layout
        bcc     continue

        ;; Swap in alternate layout
        copy    #$80, extended_layout_flag
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
        and     #CHAR_MASK
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
        and     #CHAR_MASK
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

        ;; Draw DeskTop's windows and icons.
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_REDRAW_ALL
        sta     RAMRDON
        sta     RAMWRTON

        ;; Draw DA's window
        jsr     draw_window

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

        bit     extended_layout_flag
        bpl     :+

        ;; Extended layout's non-rectangular Return key
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
;;; Returns Carry set if extended (IIgs/IIc+) layout should be used

.proc check_extended_layout

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
        jsr     IDROUTINE       ; Clears carry if IIgs
        bcs     :+              ; No, carry still set
        sec                     ; Yes, is a IIgs
        rts

        ;; Is IIc+?
:       lda     ZIDBYTE         ; $00 = IIc
        bne     done
        lda     ZIDBYTE2        ; $05 = IIc Plus
        cmp     #$05
        bne     done
        sec                     ; Yes, is a IIc+
        rts

done:   clc                     ; No - standard layout
        rts
.endproc

;;; ============================================================
;;; Construct "inner" polygon for key in A.
;;; Output: tmp_poly is populated

.proc construct_key_poly
        ptr := $06

        cmp     #CHAR_RETURN
        bne     normal
        bit     extended_layout_flag
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

da_end  := *
.assert * < $1B00, error, "DA too big"
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but icon tables start at AUX $1B00
