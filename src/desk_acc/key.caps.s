;;; ============================================================
;;; KEY.CAPS - Desk Accessory
;;;
;;; Displays a map of the keyboard, showing what key is pressed.
;;; ============================================================

        .include "../config.inc"
        RESOURCE_FILE "key.caps.res"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

kShortcutQuit = res_char_quit_shortcut

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

        kKeyWidth = 22
        kKeyHeight = 15

kDAWindowId     = $80
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
mincontheight:  .word   kDAHeight
maxcontwidth:   .word   kDAWidth
maxcontheight:  .word   kDAHeight
port:
        DEFINE_POINT viewloc, kDALeft, kDATop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved2:      .byte   0
        DEFINE_RECT maprect, 0, 0, kDAWidth, kDAHeight
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   2
penheight:      .byte   1
penmode:        .byte   MGTK::pencopy
textback:       .byte   MGTK::textbg_white
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
        REF_WINFO_MEMBERS
.endparams

str_title:
        PASCAL_STRING res_string_window_title

background_pattern:
        .byte   %11011101
        .byte   %01110111
        .byte   %11011101
        .byte   %01110111
        .byte   %11011101
        .byte   %01110111
        .byte   %11011101
        .byte   %01110111

        DEFINE_RECT background_rect, 0, 0, kDAWidth, kDAHeight

penXOR:
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

.params getwinport_params
window_id:      .byte   kDAWindowId
port:           .addr   grafport
.endparams

grafport:       .tag    MGTK::GrafPort

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

        DEFINE_RECT keys_bg_rect, kKeyboardLeft, kKeyboardTop, kKeyboardRight, kKeyboardTop + kKeyHeight * 5

.macro KEY_RECT ident, left, top, right, bottom
    .if .paramcount = 1
        DEFINE_RECT ident, 0, 0, 0, 0
    .elseif .paramcount = 3
        DEFINE_RECT ident, left, top, left + kKeyWidth, top + kKeyHeight
    .elseif .paramcount = 4
        DEFINE_RECT ident, left, top, right, top + kKeyHeight
    .else
        DEFINE_RECT ident, left, top, right, bottom
    .endif
.endmacro

key_locations:

        KEY_RECT kr00, kLeft0 +  1 * kKeyWidth, kRow0 ; Ctrl-@
        KEY_RECT kr01, kLeft2 +  0 * kKeyWidth, kRow2 ; Ctrl-A
        KEY_RECT kr02, kLeft3 +  4 * kKeyWidth, kRow3 ; Ctrl-B
        KEY_RECT kr03, kLeft3 +  2 * kKeyWidth, kRow3 ; Ctrl-C
        KEY_RECT kr04, kLeft2 +  2 * kKeyWidth, kRow2 ; Ctrl-D
        KEY_RECT kr05, kLeft1 +  2 * kKeyWidth, kRow1 ; Ctrl-E
        KEY_RECT kr06, kLeft2 +  3 * kKeyWidth, kRow2 ; Ctrl-F
        KEY_RECT kr07, kLeft2 +  4 * kKeyWidth, kRow2 ; Ctrl-G
        KEY_RECT kr08, kKeyboardRight - kKeyWidth * 4, kRow4, kKeyboardRight - kKeyWidth * 3 ; Ctrl-H (left arrow)
        KEY_RECT kr09, kKeyboardLeft, kRow1, kLeft1         ; Ctrl-I (tab)
        KEY_RECT kr0A, kKeyboardRight - kKeyWidth * 2, kRow4, kKeyboardRight - kKeyWidth * 1 ; Ctrl-J (down arrow)
        KEY_RECT kr0B, kKeyboardRight - kKeyWidth * 1, kRow4, kKeyboardRight - kKeyWidth * 0 ; Ctrl-K (up arrow)
        KEY_RECT kr0C, kLeft2 +  8 * kKeyWidth, kRow2 ; Ctrl-L
        KEY_RECT kr0D, kKeyboardRight - kKeyWidth *  7/4 - 1, kRow2, kKeyboardRight ; Ctrl-M (return)
        KEY_RECT kr0E, kLeft3 +  5 * kKeyWidth, kRow3 ; Ctrl-N
        KEY_RECT kr0F, kLeft1 +  8 * kKeyWidth, kRow1 ; Ctrl-O

        KEY_RECT kr10, kLeft1 +  9 * kKeyWidth, kRow1 ; Ctrl-P
        KEY_RECT kr11, kLeft1 +  0 * kKeyWidth, kRow1 ; Ctrl-Q
        KEY_RECT kr12, kLeft1 +  3 * kKeyWidth, kRow1 ; Ctrl-R
        KEY_RECT kr13, kLeft2 +  1 * kKeyWidth, kRow2 ; Ctrl-S
        KEY_RECT kr14, kLeft1 +  4 * kKeyWidth, kRow1 ; Ctrl-T
        KEY_RECT kr15, kKeyboardRight - kKeyWidth * 3, kRow4, kKeyboardRight - kKeyWidth * 2 ; Ctrl-U (right arrow)
        KEY_RECT kr16, kLeft3 +  3 * kKeyWidth, kRow3 ; Ctrl-V
        KEY_RECT kr17, kLeft1 +  1 * kKeyWidth, kRow1 ; Ctrl-W
        KEY_RECT kr18, kLeft3 +  1 * kKeyWidth, kRow3 ; Ctrl-X
        KEY_RECT kr19, kLeft1 +  5 * kKeyWidth, kRow1 ; Ctrl-Y
        KEY_RECT kr1A, kLeft3 +  0 * kKeyWidth, kRow3 ; Ctrl-Z
        KEY_RECT kr1B, kKeyboardLeft, kRow0, kLeft0         ; Ctrl-[ (escape)
        KEY_RECT kr1C, kLeft1 + 12 * kKeyWidth, kRow1 ; Ctrl-\
        KEY_RECT kr1D, kLeft1 + 11 * kKeyWidth, kRow1 ; Ctrl-]
        KEY_RECT kr1E, kLeft0 +  5 * kKeyWidth, kRow0 ; Ctrl-^
        KEY_RECT kr1F, kLeft0 + 10 * kKeyWidth, kRow0 ; Ctrl-_

        KEY_RECT kr20, kKeyboardLeft + kKeyWidth * 4, kRow4, kKeyboardRight - kKeyWidth * 5 ; (space)
        KEY_RECT kr21, kLeft0 +  0 * kKeyWidth, kRow0 ; !
        KEY_RECT kr22, kLeft2 + 10 * kKeyWidth, kRow2 ; "
        KEY_RECT kr23, kLeft0 +  2 * kKeyWidth, kRow0 ; #
        KEY_RECT kr24, kLeft0 +  3 * kKeyWidth, kRow0 ; $
        KEY_RECT kr25, kLeft0 +  4 * kKeyWidth, kRow0 ; %
        KEY_RECT kr26, kLeft0 +  6 * kKeyWidth, kRow0 ; &
        KEY_RECT kr27, kLeft2 + 10 * kKeyWidth, kRow2 ; '
        KEY_RECT kr28, kLeft0 +  8 * kKeyWidth, kRow0 ; (
        KEY_RECT kr29, kLeft0 +  9 * kKeyWidth, kRow0 ; )
        KEY_RECT kr2A, kLeft0 +  7 * kKeyWidth, kRow0 ; *
        KEY_RECT kr2B, kLeft0 + 11 * kKeyWidth, kRow0 ; +
        KEY_RECT kr2C, kLeft3 +  7 * kKeyWidth, kRow3 ; ,
        KEY_RECT kr2D, kLeft0 + 10 * kKeyWidth, kRow0 ; -
        KEY_RECT kr2E, kLeft3 +  8 * kKeyWidth, kRow3 ; .
        KEY_RECT kr2F, kLeft3 +  9 * kKeyWidth, kRow3 ; /

        KEY_RECT kr30, kLeft0 +  9 * kKeyWidth, kRow0 ; 0
        KEY_RECT kr31, kLeft0 +  0 * kKeyWidth, kRow0 ; 1
        KEY_RECT kr32, kLeft0 +  1 * kKeyWidth, kRow0 ; 2
        KEY_RECT kr33, kLeft0 +  2 * kKeyWidth, kRow0 ; 3
        KEY_RECT kr34, kLeft0 +  3 * kKeyWidth, kRow0 ; 4
        KEY_RECT kr35, kLeft0 +  4 * kKeyWidth, kRow0 ; 5
        KEY_RECT kr36, kLeft0 +  5 * kKeyWidth, kRow0 ; 6
        KEY_RECT kr37, kLeft0 +  6 * kKeyWidth, kRow0 ; 7
        KEY_RECT kr38, kLeft0 +  7 * kKeyWidth, kRow0 ; 8
        KEY_RECT kr39, kLeft0 +  8 * kKeyWidth, kRow0 ; 9
        KEY_RECT kr3A, kLeft2 +  9 * kKeyWidth, kRow2 ; :
        KEY_RECT kr3B, kLeft2 +  9 * kKeyWidth, kRow2 ; ;
        KEY_RECT kr3C, kLeft3 +  7 * kKeyWidth, kRow3 ; <
        KEY_RECT kr3D, kLeft0 + 11 * kKeyWidth, kRow0 ; =
        KEY_RECT kr3E, kLeft3 +  8 * kKeyWidth, kRow3 ; >
        KEY_RECT kr3F, kLeft3 +  9 * kKeyWidth, kRow3 ; ?

        KEY_RECT kr40, kLeft0 +  1 * kKeyWidth, kRow0 ; @
        KEY_RECT kr41, kLeft2 +  0 * kKeyWidth, kRow2 ; A
        KEY_RECT kr42, kLeft3 +  4 * kKeyWidth, kRow3 ; B
        KEY_RECT kr43, kLeft3 +  2 * kKeyWidth, kRow3 ; C
        KEY_RECT kr44, kLeft2 +  2 * kKeyWidth, kRow2 ; D
        KEY_RECT kr45, kLeft1 +  2 * kKeyWidth, kRow1 ; E
        KEY_RECT kr46, kLeft2 +  3 * kKeyWidth, kRow2 ; F
        KEY_RECT kr47, kLeft2 +  4 * kKeyWidth, kRow2 ; G
        KEY_RECT kr48, kLeft2 +  5 * kKeyWidth, kRow2 ; H
        KEY_RECT kr49, kLeft1 +  7 * kKeyWidth, kRow1 ; I
        KEY_RECT kr4A, kLeft2 +  6 * kKeyWidth, kRow2 ; J
        KEY_RECT kr4B, kLeft2 +  7 * kKeyWidth, kRow2 ; K
        KEY_RECT kr4C, kLeft2 +  8 * kKeyWidth, kRow2 ; L
        KEY_RECT kr4D, kLeft3 +  6 * kKeyWidth, kRow3 ; M
        KEY_RECT kr4E, kLeft3 +  5 * kKeyWidth, kRow3 ; N
        KEY_RECT kr4F, kLeft1 +  8 * kKeyWidth, kRow1 ; O

        KEY_RECT kr50, kLeft1 +  9 * kKeyWidth, kRow1 ; P
        KEY_RECT kr51, kLeft1 +  0 * kKeyWidth, kRow1 ; Q
        KEY_RECT kr52, kLeft1 +  3 * kKeyWidth, kRow1 ; R
        KEY_RECT kr53, kLeft2 +  1 * kKeyWidth, kRow2 ; S
        KEY_RECT kr54, kLeft1 +  4 * kKeyWidth, kRow1 ; T
        KEY_RECT kr55, kLeft1 +  6 * kKeyWidth, kRow1 ; U
        KEY_RECT kr56, kLeft3 +  3 * kKeyWidth, kRow3 ; V
        KEY_RECT kr57, kLeft1 +  1 * kKeyWidth, kRow1 ; W
        KEY_RECT kr58, kLeft3 +  1 * kKeyWidth, kRow3 ; X
        KEY_RECT kr59, kLeft1 +  5 * kKeyWidth, kRow1 ; Y
        KEY_RECT kr5A, kLeft3 +  0 * kKeyWidth, kRow3 ; Z
        KEY_RECT kr5B, kLeft1 + 10 * kKeyWidth, kRow1 ; [
        KEY_RECT kr5C, kLeft1 + 12 * kKeyWidth, kRow1 ; \
        KEY_RECT kr5D, kLeft1 + 11 * kKeyWidth, kRow1 ; ]
        KEY_RECT kr5E, kLeft0 +  5 * kKeyWidth, kRow0 ; ^
        KEY_RECT kr5F, kLeft0 + 10 * kKeyWidth, kRow0 ; _


        KEY_RECT kr60, kLeft4 +  0 * kKeyWidth, kRow4 ; `
        KEY_RECT kr61, kLeft2 +  0 * kKeyWidth, kRow2 ; a
        KEY_RECT kr62, kLeft3 +  4 * kKeyWidth, kRow3 ; b
        KEY_RECT kr63, kLeft3 +  2 * kKeyWidth, kRow3 ; c
        KEY_RECT kr64, kLeft2 +  2 * kKeyWidth, kRow2 ; d
        KEY_RECT kr65, kLeft1 +  2 * kKeyWidth, kRow1 ; e
        KEY_RECT kr66, kLeft2 +  3 * kKeyWidth, kRow2 ; f
        KEY_RECT kr67, kLeft2 +  4 * kKeyWidth, kRow2 ; g
        KEY_RECT kr68, kLeft2 +  5 * kKeyWidth, kRow2 ; h
        KEY_RECT kr69, kLeft1 +  7 * kKeyWidth, kRow1 ; i
        KEY_RECT kr6A, kLeft2 +  6 * kKeyWidth, kRow2 ; j
        KEY_RECT kr6B, kLeft2 +  7 * kKeyWidth, kRow2 ; k
        KEY_RECT kr6C, kLeft2 +  8 * kKeyWidth, kRow2 ; l
        KEY_RECT kr6D, kLeft3 +  6 * kKeyWidth, kRow3 ; m
        KEY_RECT kr6E, kLeft3 +  5 * kKeyWidth, kRow3 ; n
        KEY_RECT kr6F, kLeft1 +  8 * kKeyWidth, kRow1 ; o

        KEY_RECT kr70, kLeft1 +  9 * kKeyWidth, kRow1 ; p
        KEY_RECT kr71, kLeft1 +  0 * kKeyWidth, kRow1 ; q
        KEY_RECT kr72, kLeft1 +  3 * kKeyWidth, kRow1 ; r
        KEY_RECT kr73, kLeft2 +  1 * kKeyWidth, kRow2 ; s
        KEY_RECT kr74, kLeft1 +  4 * kKeyWidth, kRow1 ; t
        KEY_RECT kr75, kLeft1 +  6 * kKeyWidth, kRow1 ; u
        KEY_RECT kr76, kLeft3 +  3 * kKeyWidth, kRow3 ; v
        KEY_RECT kr77, kLeft1 +  1 * kKeyWidth, kRow1 ; w
        KEY_RECT kr78, kLeft3 +  1 * kKeyWidth, kRow3 ; x
        KEY_RECT kr79, kLeft1 +  5 * kKeyWidth, kRow1 ; y
        KEY_RECT kr7A, kLeft3 +  0 * kKeyWidth, kRow3 ; z
        KEY_RECT kr7B, kLeft1 + 10 * kKeyWidth, kRow1 ; {
        KEY_RECT kr7C, kLeft1 + 12 * kKeyWidth, kRow1 ; |
        KEY_RECT kr7D, kLeft1 + 11 * kKeyWidth, kRow1 ; }
        KEY_RECT kr7E, kLeft4 +  0 * kKeyWidth, kRow4 ; ~
        KEY_RECT kr7F, kKeyboardRight - kKeyWidth *  6/4, kRow0, kKeyboardRight ; (delete)
        ASSERT_RECORD_TABLE_SIZE key_locations, $80, .sizeof(MGTK::Rect)

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
        ASSERT_TABLE_SIZE key_mode, $80

        KEY_RECT rect_ctl, kKeyboardLeft, kRow2, kLeft2
        KEY_RECT rect_shl, kKeyboardLeft, kRow3, kLeft3
        KEY_RECT rect_cap, kKeyboardLeft, kRow4, kLeft4
        KEY_RECT rect_gap, kKeyboardLeft + kKeyWidth * 2, kRow4
        KEY_RECT rect_oap, kKeyboardLeft + kKeyWidth * 3, kRow4
        KEY_RECT rect_sap, kKeyboardRight - kKeyWidth * 5, kRow4, kKeyboardRight - kKeyWidth * 4
        KEY_RECT rect_shr, kKeyboardRight - kKeyWidth *  9/4 - 1, kRow3, kKeyboardRight

        DEFINE_POINT label_relpos, 8, 12

        DEFINE_RECT empty_rect, 0, 0, 0, 0

;;; New keyboard locations on IIgs/IIc+
;;;

        ;; Open Apple
        KEY_RECT rect_new_oap, kKeyboardLeft + kKeyWidth * 2, kRow4, kKeyboardLeft + kKeyWidth * 4
        ;; Solid Apple
        KEY_RECT rect_new_sap, kLeft4 +  0 * kKeyWidth, kRow4
        ;; Apostrophe/Tilde
        KEY_RECT rect_new_apos, kKeyboardLeft + kKeyWidth * 4, kRow4
        ;; Backslash/Vertical Bar
        KEY_RECT rect_new_bshl, kKeyboardRight - kKeyWidth * 5, kRow4, kKeyboardRight - kKeyWidth * 4
        ;; Space
        KEY_RECT rect_new_spc, kKeyboardLeft + kKeyWidth * 5, kRow4, kKeyboardRight - kKeyWidth * 5

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
        .word    kLeft1 + 12 * kKeyWidth, kRow1
        .word    kKeyboardRight, kRow1
        .word    kKeyboardRight, kRow3
        .word    kKeyboardRight - kKeyWidth *  7/4 - 1, kRow3
        .word    kKeyboardRight - kKeyWidth *  7/4 - 1, kRow2
        .word    kLeft1 + 12 * kKeyWidth, kRow2
        .word    kLeft1 + 12 * kKeyWidth, kRow1

poly_new_ret_inner:
        .byte   7               ; vertex count
        .byte   0               ; no more polys
        .word    kLeft1 + 12 * kKeyWidth + 4, kRow1 + 2
        .word    kKeyboardRight - 3, kRow1 + 2
        .word    kKeyboardRight - 3, kRow3 - 1
        .word    kKeyboardRight - kKeyWidth *  7/4 - 1 + 4, kRow3 - 1
        .word    kKeyboardRight - kKeyWidth *  7/4 - 1 + 4, kRow2 + 2
        .word    kLeft1 + 12 * kKeyWidth + 4, kRow2 + 2
        .word    kLeft1 + 12 * kKeyWidth + 4, kRow1 + 2

extended_layout_flag:           ; high bit set if IIgs/IIc+
        .byte   0

tmp_poly:
        .res    2 + 7 * .sizeof(MGTK::Point), 0

        DEFINE_RECT tmp_rect, 0, 0, 0, 0

;;; ============================================================

.proc Init
        jsr     CheckExtendedLayout ; returns C=1 if extended

        ;; Invert Carry if modifier is down
        lda     BUTN0
        ora     BUTN1
    IF NS
        rol
        eor     #$01
        ror
    END_IF
        bcc     continue

        ;; Swap in alternate layout
        SET_BIT7_FLAG extended_layout_flag
        COPY_BLOCK empty_rect, rect_gap ; Gap is eliminated
        COPY_BLOCK rect_new_bshl, kr5C ; [\|] replaces Solid Apple
        COPY_BLOCK rect_new_bshl, kr7C
        COPY_BLOCK rect_new_apos, kr60 ; [`~] takes away from Space
        COPY_BLOCK rect_new_apos, kr7E
        COPY_BLOCK rect_new_spc, kr20 ; Space is smaller
        COPY_BLOCK rect_new_oap, rect_oap ; Open Apple moves
        COPY_BLOCK rect_new_sap, rect_sap ; Solid Apple (Option) moves
        ;; Return key handled separately

continue:
        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     DrawWindow
        MGTK_CALL MGTK::FlushEvents
        FALL_THROUGH_TO InputLoop
.endproc ; Init

.proc InputLoop
        JSR_TO_MAIN JUMP_TABLE_SYSTEM_TASK
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_params::kind

        cmp     #MGTK::EventKind::button_down ; was clicked?
        jeq     HandleDown

        cmp     #MGTK::EventKind::key_down  ; any key?
        jeq     HandleKey

        jmp     InputLoop
.endproc ; InputLoop

.proc Exit
        MGTK_CALL MGTK::CloseWindow, winfo
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES
        rts
.endproc ; Exit

;;; ============================================================

.proc HandleKey
        lda     event_params::modifiers
        beq     start
        lda     event_params::key
        jsr     ToUpperCase
        cmp     #kShortcutQuit  ; Apple-Q to quit
        beq     Exit
        cmp     #kShortcutCloseWindow ; Apple-W to close window
        beq     Exit

start:  lda     KBD
        and     #CHAR_MASK
        sta     last_char

        jsr     ConstructKeyPoly

        MGTK_CALL MGTK::GetWinPort, getwinport_params
    IF A <> #MGTK::Error::window_obscured

        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintPoly, tmp_poly

:
      IF bit KBDSTRB : NS
        lda     KBD
        and     #CHAR_MASK
        cmp     last_char
        beq     :-
        MGTK_CALL MGTK::PaintPoly, tmp_poly
        jmp     start
      END_IF

        MGTK_CALL MGTK::PaintPoly, tmp_poly
    END_IF

        jmp     InputLoop

last_char:
        .byte   0

.endproc ; HandleKey

;;; ============================================================

.proc HandleDown
        copy16  event_params::xcoord, findwindow_params::mousex
        copy16  event_params::ycoord, findwindow_params::mousey
        MGTK_CALL MGTK::FindWindow, findwindow_params

        lda     findwindow_params::window_id
        cmp     #kDAWindowId
        jne     InputLoop

        lda     findwindow_params::which_area
        cmp     #MGTK::Area::close_box
        beq     HandleClose
        cmp     #MGTK::Area::dragbar
        beq     HandleDrag
        jmp     InputLoop
.endproc ; HandleDown

;;; ============================================================

.proc HandleClose
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        jeq     InputLoop
        jmp     Exit
.endproc ; HandleClose

;;; ============================================================

.proc HandleDrag
        copy8   winfo::window_id, dragwindow_params::window_id
        copy16  event_params::xcoord, dragwindow_params::dragx
        copy16  event_params::ycoord, dragwindow_params::dragy
        MGTK_CALL MGTK::DragWindow, dragwindow_params

        lda     dragwindow_params::moved
    IF NS
        ;; Draw DeskTop's windows and icons.
        JSR_TO_MAIN JUMP_TABLE_CLEAR_UPDATES

        ;; Draw DA's window
        jsr     DrawWindow
    END_IF

        jmp     InputLoop

.endproc ; HandleDrag

;;; ============================================================

.proc DrawWindow
        ptr := $06

        MGTK_CALL MGTK::GetWinPort, getwinport_params
        RTS_IF A = #MGTK::Error::window_obscured

        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor

        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::SetPattern, background_pattern
        MGTK_CALL MGTK::PaintRect, background_rect

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

        copy8   #127, char
    DO
        copy8   char, char_label
        tax
        ldy     key_mode,x
      IF NC
        ;; Compute address of key record
        sta     ptr
        copy8   #0, ptr+1
        asl16   ptr             ; * 8 = .sizeof(MGTK::Rect)
        asl16   ptr
        asl16   ptr
        add16   ptr, #key_locations, ptr

        ldy     #.sizeof(MGTK::Rect)-1
       DO
        copy8   (ptr),y, tmp_rect,y
       WHILE dey : POS

        MGTK_CALL MGTK::FrameRect, tmp_rect

       IF lda char : A >= #' ' AND A < #CHAR_DELETE
        MGTK_CALL MGTK::MoveTo, tmp_rect
        MGTK_CALL MGTK::Move, label_relpos
        MGTK_CALL MGTK::DrawText, drawtext_params_char
       END_IF
      END_IF

        dec     char
    WHILE lda char : POS

    IF bit extended_layout_flag : NS
        ;; Extended layout's non-rectangular Return key
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::SetPattern, winfo::pattern
        MGTK_CALL MGTK::PaintPoly, poly_new_ret
        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::FramePoly, poly_new_ret
    END_IF

        MGTK_CALL MGTK::ShowCursor
        rts

char:   .byte   0
.endproc ; DrawWindow

;;; ============================================================
;;; Returns Carry set if extended layout should be used.
;;; This is the layout of the Platinum IIe, IIc+ and IIgs.

.proc CheckExtendedLayout

        ;; Bank in ROM and do check
        bit     ROMIN2
        jsr     check
        bit     LCBANK1
        bit     LCBANK1
        rts

        ;; --------------------------------------------------
        ;; Do the check (with ROM banked in)

        ;; Is IIgs?
check:
        CALL    IDROUTINE, C=1  ; Clears carry if IIgs
    IF CC
        RETURN  C=1             ; Yes, is a IIgs
    END_IF

        ;; Is IIc+?
        lda     ZIDBYTE         ; $00 = IIc
    IF ZERO
        lda     ZIDBYTE2        ; $05 = IIc Plus
      IF A = #$05
        RETURN  C=1             ; Yes, is a IIc+
      END_IF
    END_IF

        ;; Can't distinguish Platinum IIe, even via shift key mod,
        ;; because unshifted state is high, just like no mod.

        RETURN  C=0             ; No - standard layout
.endproc ; CheckExtendedLayout

;;; ============================================================
;;; Construct "inner" polygon for key in A.
;;; Output: tmp_poly is populated

.proc ConstructKeyPoly
        ptr := $06

        cmp     #CHAR_RETURN
    IF EQ
      IF bit extended_layout_flag : NS
        ;; Special key
        COPY_BYTES      2 + 7 * .sizeof(MGTK::Point), poly_new_ret_inner, tmp_poly
        rts
      END_IF
    END_IF

        ;; Rectangular key

        ;; Compute address of rect
        sta     ptr
        copy8   #0, ptr+1
        asl16   ptr             ; * 8 = .sizeof(MGTK::Rect)
        asl16   ptr
        asl16   ptr
        add16   ptr, #key_locations, ptr

        ldy     #.sizeof(MGTK::Rect)-1
    DO
        copy8   (ptr),y, tmp_rect,y
    WHILE dey : POS

        copy8   #5, tmp_poly+0  ; # vertices
        copy8   #0, tmp_poly+1  ; no more polys
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
.endproc ; ConstructKeyPoly

;;; ============================================================

        .include "../lib/uppercase.s"

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT
        JSR_TO_AUX aux::Init
        rts
        DA_END_MAIN_SEGMENT

;;; ============================================================
