;;; ============================================================
;;; DeskTop - Aux Memory Segment
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

        RESOURCE_FILE "aux.res"

;;; ============================================================
;;; Segment loaded into AUX $4000-$BFFF
;;; ============================================================

.proc aux

        .org $4000

        .include "../mgtk/mgtk.s"

        ASSERT_ADDRESS $8600

;;; ============================================================

graphics_icon:
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000001)
        .byte   PX(%1000110),PX(%0000000),PX(%0000000),PX(%0000001)
        .byte   PX(%1001111),PX(%0000000),PX(%0000011),PX(%0000001)
        .byte   PX(%1000110),PX(%0000000),PX(%0000111),PX(%1000001)
        .byte   PX(%1000000),PX(%0001100),PX(%0001111),PX(%1100001)
        .byte   PX(%1000000),PX(%0111111),PX(%0011111),PX(%1110001)
        .byte   PX(%1000011),PX(%1111111),PX(%1111111),PX(%1111001)
        .byte   PX(%1001111),PX(%1111111),PX(%1111111),PX(%1111001)
        .byte   PX(%1001111),PX(%1111111),PX(%1111111),PX(%1111001)
        .byte   PX(%1001111),PX(%1111111),PX(%1111111),PX(%1111001)
        .byte   PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000001)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)

graphics_mask:
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)

cmd_file_icon:
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0011111),PX(%1111100),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0111100),PX(%0011001),PX(%1001100)
        .byte   PX(%0000000),PX(%0111100),PX(%0000110),PX(%0110000)
        .byte   PX(%0000000),PX(%0111100),PX(%0011001),PX(%1001100)
        .byte   PX(%0000000),PX(%0111100),PX(%0000110),PX(%0110000)
        .byte   PX(%0000000),PX(%0111100),PX(%0011001),PX(%1001100)
        .byte   PX(%0011111),PX(%1111100),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        ;; shares top part of graphics_mask


awp_icon:                       ; AppleWorks Word Processing
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%1100000)
        .byte   PX(%0100011),PX(%0001000),PX(%1000100),PX(%0011000)
        .byte   PX(%0100100),PX(%1001010),PX(%1000100),PX(%0000110)
        .byte   PX(%0100111),PX(%1001010),PX(%1000111),PX(%1111110)
        .byte   PX(%0100100),PX(%1000101),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%0111100),PX(%1110011),PX(%1110010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100011),PX(%1100111),PX(%1100111),PX(%1100010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100011),PX(%1111001),PX(%1111001),PX(%1100010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100011),PX(%1001110),PX(%0111100),PX(%1100010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)

asp_icon:                       ; AppleWorks Spreadsheet
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%1100000)
        .byte   PX(%0100011),PX(%0001000),PX(%1000100),PX(%0011000)
        .byte   PX(%0100100),PX(%1001010),PX(%1000100),PX(%0000110)
        .byte   PX(%0100111),PX(%1001010),PX(%1000111),PX(%1111110)
        .byte   PX(%0100100),PX(%1000101),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100011),PX(%1111111),PX(%1111111),PX(%1100010)
        .byte   PX(%0100011),PX(%0010010),PX(%0100100),PX(%1100010)
        .byte   PX(%0100011),PX(%1111111),PX(%1111111),PX(%1100010)
        .byte   PX(%0100011),PX(%0010010),PX(%0100100),PX(%1100010)
        .byte   PX(%0100011),PX(%1111111),PX(%1111111),PX(%1100010)
        .byte   PX(%0100011),PX(%0010010),PX(%0100100),PX(%1100010)
        .byte   PX(%0100011),PX(%1111111),PX(%1111111),PX(%1100010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        ;; shares generic_mask

adb_icon:                       ; AppleWorks Database
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%1100000)
        .byte   PX(%0100011),PX(%0001000),PX(%1000100),PX(%0011000)
        .byte   PX(%0100100),PX(%1001010),PX(%1000100),PX(%0000110)
        .byte   PX(%0100111),PX(%1001010),PX(%1000111),PX(%1111110)
        .byte   PX(%0100100),PX(%1000101),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100111),PX(%1110011),PX(%1110011),PX(%1110010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100111),PX(%1111111),PX(%1111111),PX(%1110010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100111),PX(%1110011),PX(%1110011),PX(%1110010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100111),PX(%1110011),PX(%1110011),PX(%1110010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        ;; shares generic_mask

iigs_file_icon:
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%1100000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%0011000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%0000110)
        .byte   PX(%0101111),PX(%1011111),PX(%0000111),PX(%1111110)
        .byte   PX(%0100010),PX(%0000100),PX(%0000000),PX(%0000010)
        .byte   PX(%0100010),PX(%0000100),PX(%0000000),PX(%0000010)
        .byte   PX(%0100010),PX(%0000100),PX(%0000000),PX(%0000010)
        .byte   PX(%0100010),PX(%0000100),PX(%0011100),PX(%0110010)
        .byte   PX(%0100010),PX(%0000100),PX(%0100000),PX(%1000010)
        .byte   PX(%0100010),PX(%0000100),PX(%0100110),PX(%0110010)
        .byte   PX(%0100010),PX(%0000100),PX(%0100010),PX(%0001010)
        .byte   PX(%0101111),PX(%1011111),PX(%0011100),PX(%0110010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        ;; shares generic_mask

rel_file_icon:
        .byte   PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000110),PX(%0110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0011000),PX(%0001100),PX(%0000000)
        .byte   PX(%0000000),PX(%1100000),PX(%0000011),PX(%0000000)
        .byte   PX(%0000011),PX(%0000000),PX(%0000000),PX(%1100000)
        .byte   PX(%0001100),PX(%1111001),PX(%1110100),PX(%0011000)
        .byte   PX(%0110000),PX(%1000101),PX(%0000100),PX(%0000110)
        .byte   PX(%1000000),PX(%1111101),PX(%1100100),PX(%0000001)
        .byte   PX(%0110000),PX(%1001001),PX(%0000100),PX(%0000110)
        .byte   PX(%0001100),PX(%1000101),PX(%1110111),PX(%1011000)
        .byte   PX(%0000011),PX(%0000000),PX(%0000000),PX(%1100000)
        .byte   PX(%0000000),PX(%1100000),PX(%0000011),PX(%0000000)
        .byte   PX(%0000000),PX(%0011000),PX(%0001100),PX(%0000000)
        .byte   PX(%0000000),PX(%0000110),PX(%0110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000)
        ;; shares binary_mask

        PAD_TO $8800

;;; ============================================================

        ASSERT_ADDRESS ::DEFAULT_FONT
        .incbin .concat("../mgtk/fonts/A2D.FONT.", LANG)

        font_height     := DEFAULT_FONT+2

;;; ============================================================

        ASSERT_ADDRESS $8D03

font_icon:
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%1100000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%0011000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%0000110)
        .byte   PX(%0100000),PX(%0110000),PX(%0000111),PX(%1111110)
        .byte   PX(%0100000),PX(%0110000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%1111000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%1011000),PX(%0000011),PX(%1100010)
        .byte   PX(%0100001),PX(%1001100),PX(%0000110),PX(%1110010)
        .byte   PX(%0100001),PX(%0001100),PX(%0000000),PX(%0110010)
        .byte   PX(%0100011),PX(%1111110),PX(%0000111),PX(%1110010)
        .byte   PX(%0100010),PX(%0000110),PX(%0001100),PX(%0110010)
        .byte   PX(%0100110),PX(%0000011),PX(%0001100),PX(%0110010)
        .byte   PX(%0101111),PX(%0000111),PX(%1000111),PX(%1111010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        ;; shares generic_mask

;;; Basic

basic_icon:
        .byte   PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000110),PX(%0110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0011000),PX(%0001100),PX(%0000000)
        .byte   PX(%0000000),PX(%1100000),PX(%0000011),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111110),PX(%0111000),PX(%1111010),PX(%0111100)
        .byte   PX(%0100010),PX(%1000100),PX(%1000010),PX(%1000110)
        .byte   PX(%0111100),PX(%1111100),PX(%1111010),PX(%1000000)
        .byte   PX(%0100010),PX(%1000100),PX(%0001010),PX(%1000110)
        .byte   PX(%0111110),PX(%1000100),PX(%1111010),PX(%0111100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%1100000),PX(%0000011),PX(%0000000)
        .byte   PX(%0000000),PX(%0011000),PX(%0001100),PX(%0000000)
        .byte   PX(%0000000),PX(%0000110),PX(%0110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000)

basic_mask:
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000111),PX(%1110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0011111),PX(%1111100),PX(%0000000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%0000000),PX(%0011111),PX(%1111100),PX(%0000000)
        .byte   PX(%0000000),PX(%0000111),PX(%1110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)

a2d_file_icon:
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%1100000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%0011000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%0000110)
        .byte   PX(%0100000),PX(%0000000),PX(%0000111),PX(%1111110)
        .byte   PX(%0100000),PX(%0000000),PX(%1100000),PX(%0000010)
        .byte   PX(%0100000),PX(%0000001),PX(%1000000),PX(%0000010)
        .byte   PX(%0100000),PX(%0011100),PX(%0111000),PX(%0000010)
        .byte   PX(%0100000),PX(%1111111),PX(%1111110),PX(%0000010)
        .byte   PX(%0100001),PX(%1111111),PX(%1110000),PX(%0000010)
        .byte   PX(%0100001),PX(%1111111),PX(%1110000),PX(%0000010)
        .byte   PX(%0100001),PX(%1111111),PX(%1111110),PX(%0000010)
        .byte   PX(%0100000),PX(%1111111),PX(%1111100),PX(%0000010)
        .byte   PX(%0100000),PX(%0111100),PX(%1111000),PX(%0000010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)
        ;; shares generic_mask

        PAD_TO $8E00

;;; ============================================================
;;; Entry point for "Icon TookKit"
;;; ============================================================

        ASSERT_ADDRESS IconTK::MLI, "IconTK entry point"

.proc icon_toolkit

        jmp     ITK_DIRECT

;;; ============================================================

kPolySize = 8

.params poly
num_vertices:   .byte   kPolySize
lastpoly:       .byte   0       ; 0 = last poly
vertices:
        DEFINE_POINT v0, 0, 0
        DEFINE_POINT v1, 0, 0
        DEFINE_POINT v2, 0, 0
        DEFINE_POINT v3, 0, 0
        DEFINE_POINT v4, 0, 0
        DEFINE_POINT v5, 0, 0
        DEFINE_POINT v6, 0, 0
        DEFINE_POINT v7, 0, 0
.endparams

.params icon_paintbits_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   0
mapwidth:       .byte   0
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 0, 0
.endparams

.params mask_paintbits_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   0
mapwidth:       .byte   0
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 0, 0
.endparams

        DEFINE_RECT rect_opendir, 0, 0, 0, 0

.params textwidth_params
textptr:        .addr   text_buffer
textlen:        .byte   0
result: .word   0
.endparams
settextbg_params    := textwidth_params::result + 1  ; re-used

.params drawtext_params
textptr:        .addr   text_buffer
textlen:        .byte   0
.endparams
        ;; text_buffer contains only the characters; the length
        ;; is in drawtext_params::textlen
text_buffer:
        .res    19, 0

white_pattern:
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111

checkerboard_pattern:
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010

dark_pattern:
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100

;;; ============================================================
;;; Icon (i.e. file, volume) details

num_icons:  .byte   0
icon_table: .res    127, 0      ; index into icon_ptrs
icon_ptrs:  .res    256, 0      ; addresses of icon details

has_highlight:                  ; 1 = has highlight, 0 = no highlight
        .byte   0
highlight_count:                ; number of highlighted icons
        .byte   0
highlight_list:                 ; selected icons
        .res    127, 0

;;; Polygon holding the composite outlines of all icons being dragged.
;;; Re-use the "save area" ($800-$1AFF) since menus won't show during
;;; this kOperation.

        drag_outline_buffer := SAVE_AREA_BUFFER
        kMaxDraggableItems = kSaveAreaSize / (.sizeof(MGTK::Point) * 8 + 2)

;;; ============================================================

.params peekevent_params
kind:   .byte   0               ; spills into next block
.endparams

;;; findwindow_params::window_id is used as first part of
;;; GetWinPtr params structure including window_ptr.
.params findwindow_params
mousex: .word   0
mousey: .word   0
which_area:     .byte   0
window_id:      .byte   0
.endparams
window_ptr:  .word   0          ; do not move this; see above

.params findcontrol_params
mousex: .word   0
mousey: .word   0
which_ctl:      .byte   0
which_part:     .byte   0
.endparams

.params grafport
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, kScreenWidth-1, kScreenHeight-1
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   $96     ; ???
textbg: .byte   MGTK::textbg_black
fontptr:        .addr   DEFAULT_FONT
.endparams

;;; Grafport used to draw icon outlines during drag
.params drag_outline_grafport
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   0
mapwidth:       .byte   0
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, 0, 0
penpattern:     .res    8, 0
colormasks:     .byte   0, 0
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   0
penheight:      .byte   0
penmode:        .byte   0
textbg: .byte   MGTK::textbg_black
fontptr:        .addr   0
.endparams

.params getwinport_params
window_id:      .byte   0
a_grafport:     .addr   icon_grafport
.endparams

.params icon_grafport
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   0
mapwidth:       .byte   0
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, 0, 0
penpattern:     .res    8, 0
colormasks:     .byte   0, 0
        DEFINE_POINT penloc, 0, 0
penwidth:       .byte   0
penheight:      .byte   0
penmode:        .byte   0
textbg: .byte   MGTK::textbg_black
fontptr:        .addr   0
.endparams

;;; ============================================================
;;; IconTK command jump table

desktop_jump_table:
        .addr   0
        .addr   AddIconImpl
        .addr   HighlightIconImpl
        .addr   RedrawIconImpl
        .addr   RemoveIconImpl
        .addr   HighlightAllImpl
        .addr   RemoveAllImpl
        .addr   CloseWindowImpl
        .addr   GetHighlightedImpl
        .addr   FindIconImpl
        .addr   DragHighlighted
        .addr   UnhighlightIconImpl
        .addr   RedrawIconsImpl
        .addr   IconInRectImpl
        .addr   EraseIconImpl

.macro  ITK_DIRECT_CALL    op, addr, label
        jsr ITK_DIRECT
        .byte   op
        .addr   addr
.endmacro

;;; IconTK entry point (after jump)

.proc ITK_DIRECT

        ;; Stash return value from stack, adjust by 3
        ;; (command byte, params addr)
        pla
        sta     call_params
        clc
        adc     #<3
        tax
        pla
        sta     call_params+1
        adc     #>3
        pha
        txa
        pha

        ;; Save $06..$09 on the stack
        ldx     #0
:       lda     $06,x
        pha
        inx
        cpx     #4
        bne     :-

        ;; Point ($06) at call command
        add16   call_params, #1, $06

        ldy     #0
        lda     ($06),y
        asl     a
        tax
        copy16  desktop_jump_table,x, dispatch + 1
        iny
        lda     ($06),y
        tax
        iny
        lda     ($06),y
        sta     $07
        stx     $06

dispatch:
        jsr     SELF_MODIFIED

        tay
        ldx     #3
:       pla
        sta     $06,x
        dex
        cpx     #$FF
        bne     :-
        tya
        rts

call_params:  .addr     0
.endproc

.params moveto_params2
xcoord: .word   0
ycoord: .word   0
.endparams

;;; ============================================================
;;; AddIcon

.proc AddIconImpl
        PARAM_BLOCK params, $06
ptr_icon:       .addr   0
        END_PARAM_BLOCK

        ldy     #0
        lda     (params::ptr_icon),y
        ldx     num_icons
        beq     proceed
        dex
:       cmp     icon_table,x
        beq     fail
        dex
        bpl     :-
        bmi     proceed
fail:   return  #1

proceed:
        jsr     sub
        jsr     paint_icon_unhighlighted
        lda     #1
        tay
        sta     (params::ptr_icon),y
        return  #0

sub:    ldx     num_icons       ; ???
        sta     icon_table,x
        inc     num_icons
        asl     a
        tax
        copy16  params::ptr_icon, icon_ptrs,x
        rts
.endproc

;;; ============================================================
;;; HighlightIcon

;;; param is pointer to icon id

.proc HighlightIconImpl
        PARAM_BLOCK params, $06
ptr_icon:       .addr   0
        END_PARAM_BLOCK
        ptr := $06              ; Overwrites param

        ldx     num_icons
        beq     bail1
        dex
        ldy     #0
        lda     (params::ptr_icon),y
:       cmp     icon_table,x
        beq     :+
        dex
        bpl     :-

bail1:  return  #1              ; Not found

:       asl     a
        tax
        copy16  icon_ptrs,x, ptr ; ptr now points at IconEntry
        ldy     #IconEntry::state
        lda     (ptr),y
        bne     :+           ; Already set ??? Routine semantics are incorrect ???
        return  #2

:       lda     has_highlight
        beq     L9498

        ;; Already in highlight list?
        dey
        lda     (ptr),y
        ldx     highlight_count
        dex
:       cmp     highlight_list,x
        beq     bail3
        dex
        bpl     :-
        jmp     L949D

bail3:  return  #3              ; Already in list

L9498:  lda     #1
        sta     has_highlight

        ;; Append to highlight list
L949D:  ldx     highlight_count
        ldy     #0
        lda     (ptr),y
        sta     highlight_list,x
        inc     highlight_count

        lda     (ptr),y         ; icon num
        ldx     #1              ; new position
        jsr     change_highlight_index

        ldy     #IconEntry::id
        lda     (ptr),y         ; icon num
        ldx     #1              ; new position
        jsr     change_icon_index

        ;; Redraw
        ldy     #IconEntry::id
        lda     (ptr),y         ; icon num
        sta     icon
        ITK_DIRECT_CALL IconTK::RedrawIcon, icon
        return  #0              ; Highlighted

        ;; IconTK::RedrawIcon params
icon:   .byte   0
.endproc

;;; ============================================================
;;; RedrawIcon

;;; * Assumes correct grafport already selected/maprect specified
;;; * Does not erase background

.proc RedrawIconImpl
        PARAM_BLOCK params, $06
ptr_icon:       .addr   0
        END_PARAM_BLOCK
        ptr := $06              ; Overwrites param

        ;; Find icon by number
        ldx     num_icons
        beq     bail1
        dex
        ldy     #0
        lda     (params::ptr_icon),y
:       cmp     icon_table,x
        beq     found
        dex
        bpl     :-

bail1:  return  #1              ; Not found

        ;; Pointer to icon details
found:  asl     a
        tax
        copy16  icon_ptrs,x, ptr

        lda     has_highlight   ; Anything highlighted?
        bne     :+
        jmp     done

:       ldx     highlight_count
        dex
        ldy     #0
        lda     (ptr),y

        ;; Find in highlight list
:       cmp     highlight_list,x
        beq     found2
        dex
        bpl     :-
        jmp     done

found2: jsr     paint_icon_highlighted
        return  #0

done:   jsr     paint_icon_unhighlighted
        return  #0
.endproc

;;; ============================================================
;;; RemoveIcon

;;; param is pointer to icon number

.proc RemoveIconImpl
        PARAM_BLOCK params, $06
ptr_icon:       .addr   0
        END_PARAM_BLOCK
        ptr := $06              ; Overwrites param

        ;; Find icon by number
        ldy     #0
        ldx     num_icons
        beq     bail1
        dex
        lda     (params::ptr_icon),y
:       cmp     icon_table,x
        beq     found
        dex
        bpl     :-

bail1:  return  #1              ; Not found

        ;; Pointer to icon details
found:  asl     a
        tax
        copy16  icon_ptrs,x, ptr
        ldy     #IconEntry::state
        lda     (ptr),y
        bne     :+

        return  #2              ; Not highlighted

        ;; Unhighlight
:       jsr     calc_icon_poly
        jsr     erase_icon

        ;; Move it to the end of the icon list
        ldy     #IconEntry::id
        lda     (ptr),y         ; icon num
        ldx     num_icons       ; new position
        jsr     change_icon_index

        ;; Remove it from the list
        dec     num_icons
        lda     #0
        ldx     num_icons
        sta     icon_table,x

        ;; Clear its flag
        ldy     #IconEntry::state
        lda     #0
        sta     (ptr),y

        lda     has_highlight
        beq     done

        ;; Find it in the highlight list
        ldx     highlight_count
        dex
        ldy     #0
        lda     (ptr),y
:       cmp     highlight_list,x
        beq     found2
        dex
        bpl     :-
        jmp     done            ; not found

        ;; Move it to the end of the highlight list
found2: ldx     highlight_count ; new position
        jsr     change_highlight_index

        ;; Remove it from the highlight list and update flag
        dec     highlight_count
        lda     highlight_count
        bne     :+
        lda     #0
        sta     has_highlight
:       lda     #0
        ldx     highlight_count
        sta     highlight_list,x

done:   return  #0              ; Unhighlighted
.endproc

;;; ============================================================
;;; EraseIcon

.proc EraseIconImpl
        PARAM_BLOCK params, $06
ptr_icon_idx:   .addr   0
        END_PARAM_BLOCK
        ptr := $06              ; Overwrites param

        ldy     #0
        lda     (params::ptr_icon_idx),y
        asl     a
        tax
        copy16  icon_ptrs,x, ptr
        jmp     erase_icon
.endproc

;;; ============================================================
;;; HighlightAll

;;; Highlight all icons in the specified window.
;;; (Unused?)

.proc HighlightAllImpl
        jmp     start

buffer := SAVE_AREA_BUFFER

        PARAM_BLOCK params, $06
ptr_window_id:      .addr    0
        END_PARAM_BLOCK

        ptr := $08

        ;; IconTK::HighlightIcon params
icon:   .byte   0

start:  lda     HighlightIconImpl ; ???
        beq     start2
        lda     highlight_list
        sta     icon
        ITK_DIRECT_CALL IconTK::UnhighlightIcon, icon
        jmp     start

start2:
        ;; Zero out buffer
        ldx     #kMaxIconCount-1
        lda     #0
:       sta     buffer,x
        dex
        bpl     :-
        ldx     #0
        stx     icon

        ;; Walk through icons, find ones in the same window
        ;; as the entry at ($06).
loop:   lda     icon_table,x
        asl     a
        tay
        copy16  icon_ptrs,y, ptr
        ldy     #IconEntry::win_type
        lda     (ptr),y
        and     #kIconEntryWinIdMask
        ldy     #0
        cmp     (params::ptr_window_id),y
        bne     :+

        ;; Append icon number to buffer.
        ldy     #IconEntry::id
        lda     (ptr),y
        ldy     icon
        sta     buffer,y
        inc     icon

:       inx
        cpx     num_icons
        bne     loop

        ldx     #0
        txa
        pha

        ;; Highlight all the icons.
loop2:  lda     buffer,x
        bne     :+
        pla
        rts

:       sta     icon
        ITK_DIRECT_CALL IconTK::HighlightIcon, icon
        pla
        tax
        inx
        txa
        pha
        jmp     loop2
.endproc

;;; ============================================================
;;; RemoveAll

;;; param is window id (0 = desktop)

.proc RemoveAllImpl
        jmp     start

        PARAM_BLOCK params, $06
ptr_window_id:      .addr    0
        END_PARAM_BLOCK

        icon_ptr := $08

        ;; IconTK::RemoveIcon params
icon:   .byte   0

count:  .byte   0

start:  lda     num_icons
        sta     count

loop:   ldx     count
        cpx     #0
        beq     done
        dec     count
        dex
        lda     icon_table,x
        sta     icon
        asl     a
        tax
        copy16  icon_ptrs,x, icon_ptr
        ldy     #IconEntry::win_type
        lda     (icon_ptr),y
        and     #kIconEntryWinIdMask
        ldy     #0
        cmp     (params::ptr_window_id),y
        bne     loop
        ITK_DIRECT_CALL IconTK::RemoveIcon, icon
        jmp     loop

done:   return  #0
.endproc

;;; ============================================================
;;; CloseWindow

;;; param is window id

.proc CloseWindowImpl
        PARAM_BLOCK params, $06
window_id:      .addr   0
        END_PARAM_BLOCK

        ptr := $08

        jmp     start

icon:   .byte   0
count:  .byte   0

start:  lda     num_icons
        sta     count
loop:   ldx     count
        bne     L96E5
        return  #0

L96E5:  dec     count
        dex
        lda     icon_table,x
        sta     icon
        asl     a
        tax
        copy16  icon_ptrs,x, ptr
        ldy     #IconEntry::win_type
        lda     (ptr),y
        and     #kIconEntryWinIdMask ; check window
        ldy     #0
        cmp     (params::window_id),y ; match?
        bne     loop                 ; nope

        ;; Move to end of icon list
        ldy     #IconEntry::id
        lda     (ptr),y         ; icon num
        ldx     num_icons       ; icon index
        jsr     change_icon_index

        dec     num_icons
        lda     #0
        ldx     num_icons
        sta     icon_table,x
        ldy     #IconEntry::state
        lda     #0
        sta     (ptr),y
        lda     has_highlight
        beq     L9758
        ldx     #0
        ldy     #0
L972B:  lda     (ptr),y
        cmp     highlight_list,x
        beq     L973B
        inx
        cpx     highlight_count
        bne     L972B
        jmp     L9758

L973B:  lda     (ptr),y         ; icon num
        ldx     highlight_count ; new position
        jsr     change_highlight_index
        dec     highlight_count
        lda     highlight_count
        bne     L9750
        lda     #0
        sta     has_highlight
L9750:  lda     #0
        ldx     highlight_count
        sta     highlight_list,x
L9758:  jmp     loop
.endproc

;;; ============================================================
;;; GetHighlighted

;;; Copies highlighted icon numbers to ($06)

.proc GetHighlightedImpl
        ldx     #0
        ldy     #0
:       lda     highlight_list,x
        sta     ($06),y
        cpx     highlight_count
        beq     done
        iny
        inx
        jmp     :-

done:   return  #0
.endproc

;;; ============================================================
;;; FindIcon

.proc FindIconImpl
        jmp     start

        coords := $6

        ;; Copy coords at $6 to param block
start:  ldy     #3
:       lda     (coords),y
        sta     moveto_params2,y
        dey
        bpl     :-

        ;; Overwrite y with x ???
        copy16  $06, $08

        ;; ???
        ldy     #5
        lda     ($06),y
        sta     L97F5
        MGTK_CALL MGTK::MoveTo, moveto_params2
        ldx     #0
L97AA:  cpx     num_icons
        bne     L97B9
        ldy     #4
        lda     #0
        sta     ($08),y
        sta     L97F6
        rts

L97B9:  txa
        pha
        lda     icon_table,x
        asl     a
        tax
        copy16  icon_ptrs,x, $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #kIconEntryWinIdMask
        cmp     L97F5
        bne     L97E0
        jsr     calc_icon_poly
        MGTK_CALL MGTK::InPoly, poly
        bne     inside
L97E0:  pla
        tax
        inx
        jmp     L97AA

inside: pla
        tax
        lda     icon_table,x
        ldy     #4
        sta     ($08),y
        sta     L97F6
        rts

L97F5:  .byte   0
L97F6:  .byte   0
.endproc

;;; ============================================================
;;; DragHighlighted

.proc DragHighlighted
        ldy     #IconEntry::id
        lda     ($06),y
        sta     icon_id
        tya
        sta     ($06),y

        ;; Copy coords (at params+1) to
        ldy     #.sizeof(MGTK::Point)
:       lda     ($06),y
        sta     coords1-1,y
        sta     coords2-1,y
        dey
        cpy     #0
        bne     :-

        jsr     push_pointers
        jmp     start           ; skip over data

icon_id:
        .byte   $00

deltax: .word   0
deltay: .word   0

        ;; IconTK::HighlightIcon params
highlight_icon_id:  .byte   $00

window_id:      .byte   0
window_id2:     .byte   0
flag:           .byte   0       ; ???

        ;; IconTK::IconInRect params
.params iconinrect_params
icon:  .byte    0
rect:  .tag     MGTK::Rect
.endparams

start:  lda     #0
        sta     highlight_icon_id
        sta     flag

;;; Determine if it's a drag or just a click
.proc drag_detect

peek:   MGTK_CALL MGTK::PeekEvent, peekevent_params
        lda     peekevent_params::kind
        cmp     #MGTK::EventKind::drag
        beq     drag

ignore_drag:
        lda     #2              ; return value
        jmp     just_select

        ;; Compute mouse delta
drag:   sub16   findwindow_params::mousex, coords1x, deltax
        sub16   findwindow_params::mousey, coords1y, deltay

        kDragDelta = 5

        ;; compare x delta
        lda     deltax+1
        bpl     x_lo
        lda     deltax
        cmp     #AS_BYTE(-kDragDelta)
        bcc     is_drag
        jmp     check_deltay
x_lo:   lda     deltax
        cmp     #kDragDelta
        bcs     is_drag

        ;; compare y delta
check_deltay:
        lda     deltay+1
        bpl     y_lo
        lda     deltay
        cmp     #AS_BYTE(-kDragDelta)
        bcc     is_drag
        jmp     peek
y_lo:   lda     deltay
        cmp     #kDragDelta
        bcs     is_drag
        jmp     peek
.endproc

        ;; Meets the threshold - it is a drag, not just a click.
is_drag:
        lda     highlight_count
        cmp     #kMaxDraggableItems + 1
        bcc     :+
        jmp     drag_detect::ignore_drag ; too many

        ;; Was there a selection?
:       copy16  #drag_outline_buffer, $08
        lda     has_highlight
        bne     :+
        lda     #3              ; return value
        jmp     just_select

:       lda     highlight_list
        jsr     get_icon_win
        sta     window_id2

        ;; Prepare grafports
        MGTK_CALL MGTK::InitPort, icon_grafport
        MGTK_CALL MGTK::InitPort, drag_outline_grafport
        MGTK_CALL MGTK::SetPort, drag_outline_grafport
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern
        MGTK_CALL MGTK::SetPenMode, penXOR

        COPY_STRUCT MGTK::Rect, drag_outline_grafport::cliprect, iconinrect_params::rect

        ldx     highlight_count
        stx     L9C74

L98F2:  lda     highlight_count,x
        jsr     get_icon_ptr
        stax    $06
        ldy     #IconEntry::id
        lda     ($06),y
        cmp     #kTrashIconNum
        bne     :+
        ldx     #$80
        stx     flag
:       sta     iconinrect_params::icon
        ITK_DIRECT_CALL IconTK::IconInRect, iconinrect_params::icon
        beq     L9954
        jsr     calc_icon_poly
        lda     L9C74
        cmp     highlight_count
        beq     L9936
        jsr     push_pointers

        lda     $08
        sec
        sbc     #kIconPolySize
        sta     $08
        bcs     :+
        dec     $08+1

:       ldy     #IconEntry::state
        lda     #$80            ; Highlighted
        sta     ($08),y
        jsr     pop_pointers

L9936:  ldx     #kIconPolySize-1
        ldy     #kIconPolySize-1

:       lda     poly,x
        sta     ($08),y
        dey
        dex
        bpl     :-

        lda     #8
        ldy     #0
        sta     ($08),y
        lda     $08
        clc
        adc     #kIconPolySize
        sta     $08
        bcc     L9954
        inc     $08+1
L9954:  dec     L9C74
        beq     :+
        ldx     L9C74
        jmp     L98F2

:       COPY_BYTES 8, drag_outline_buffer+2, rect1

        copy16  #drag_outline_buffer, $08

L9972:  ldy     #2

L9974:  lda     ($08),y
        cmp     rect1_x1
        iny
        lda     ($08),y
        sbc     rect1_x1+1
        bcs     L9990
        lda     ($08),y
        sta     rect1_x1+1
        dey
        lda     ($08),y
        sta     rect1_x1
        iny
        jmp     L99AA

L9990:  dey
        lda     ($08),y
        cmp     rect1_x2
        iny
        lda     ($08),y
        sbc     rect1_x2+1
        bcc     L99AA

        lda     ($08),y
        sta     rect1_x2+1
        dey
        lda     ($08),y
        sta     rect1_x2
        iny

L99AA:  iny
        lda     ($08),y
        cmp     rect1_y1
        iny
        lda     ($08),y
        sbc     rect1_y1+1
        bcs     L99C7

        lda     ($08),y
        sta     rect1_y1+1
        dey
        lda     ($08),y
        sta     rect1_y1
        iny
        jmp     L99E1

L99C7:  dey
        lda     ($08),y
        cmp     rect1_y2
        iny
        lda     ($08),y
        sbc     rect1_y2+1
        bcc     L99E1

        lda     ($08),y
        sta     rect1_y2+1
        dey
        lda     ($08),y
        sta     rect1_y2
        iny

L99E1:  iny
        cpy     #kIconPolySize
        bne     L9974
        ldy     #IconEntry::state
        lda     ($08),y
        beq     L99FC
        add16   $08, #kIconPolySize, $08
        jmp     L9972

L99FC:  jsr     xdraw_outline

peek:   MGTK_CALL MGTK::PeekEvent, peekevent_params
        lda     peekevent_params::kind
        cmp     #MGTK::EventKind::drag
        beq     L9A1E
        jmp     L9BA5

L9A1E:  ldx     #3
L9A20:  lda     findwindow_params,x
        cmp     coords2,x
        bne     L9A31
        dex
        bpl     L9A20
        jsr     find_target_and_highlight
        jmp     peek

L9A31:  COPY_BYTES 4, findwindow_params, coords2

        ;; Still over the highlighted icon?
        lda     highlight_icon_id
        beq     :+
        lda     window_id
        sta     findwindow_params::window_id
        ITK_DIRECT_CALL IconTK::FindIcon, findwindow_params
        lda     findwindow_params::which_area ; Icon ID
        cmp     highlight_icon_id             ; already over it?
        beq     :+

        ;; No longer over the highlighted icon - unhighlight it
        jsr     xdraw_outline
        jsr     unhighlight_icon
        jsr     xdraw_outline
        lda     #0
        sta     highlight_icon_id

:       sub16   findwindow_params::mousex, coords1x, rect3_x1
        sub16   findwindow_params::mousey, coords1y, rect3_y1
        jsr     set_rect2_to_rect1

        ldx     #0
:       add16   rect1_x2,x, rect3_x1,x, rect1_x2,x
        add16   rect1_x1,x, rect3_x1,x, rect1_x1,x
        inx
        inx
        cpx     #4
        bne     :-

        lda     #0
        sta     L9C75
        lda     rect1_x1+1
        bmi     L9AF7
        cmp16   rect1_x2, #kScreenWidth
        bcs     L9AFE
        jsr     set_coords1x_to_mousex
        jmp     L9B0E

L9AF7:  jsr     L9CAA
        bmi     L9B0E
        bpl     L9B03
L9AFE:  jsr     L9CD1
        bmi     L9B0E
L9B03:  jsr     set_rect1_to_rect2_and_zero_rect3_x
        lda     L9C75
        ora     #$80
        sta     L9C75
L9B0E:  lda     rect1_y1+1
        bmi     L9B31
        cmp16   rect1_y1, #kMenuBarHeight
        bcc     L9B31
        cmp16   rect1_y2, #kScreenHeight
        bcs     L9B38
        jsr     set_coords1y_to_mousey
        jmp     L9B48

L9B31:  jsr     L9D31
        bmi     L9B48
        bpl     L9B3D
L9B38:  jsr     L9D58
        bmi     L9B48
L9B3D:  jsr     set_rect1_to_rect2_and_zero_rect3_y
        lda     L9C75
        ora     #$40
        sta     L9C75
L9B48:  bit     L9C75
        bpl     L9B52
        bvc     L9B52
        jmp     peek

L9B52:  jsr     xdraw_outline
        copy16  #drag_outline_buffer, $08
L9B60:  ldy     #2
L9B62:  add16in ($08),y, rect3_x1, ($08),y
        iny
        add16in ($08),y, rect3_y1, ($08),y
        iny
        cpy     #kIconPolySize
        bne     L9B62
        ldy     #IconEntry::state
        lda     ($08),y
        beq     L9B9C
        lda     $08
        clc
        adc     #kIconPolySize
        sta     $08
        bcc     L9B99
        inc     $08+1
L9B99:  jmp     L9B60

L9B9C:  jsr     xdraw_outline
        jmp     peek

L9BA5:  jsr     xdraw_outline
        lda     highlight_icon_id
        beq     :+
        jsr     unhighlight_icon
        jmp     L9C63

:       MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     window_id2
        beq     L9BE1
        bit     flag
        bmi     L9BDC
        lda     findwindow_params::window_id
        bne     L9BD4
L9BD1:  jmp     drag_detect::ignore_drag

L9BD4:  ora     #$80
        sta     highlight_icon_id
        jmp     L9C63

L9BDC:  lda     window_id2
        beq     L9BD1
L9BE1:  jsr     push_pointers
        ldx     highlight_count
L9BF3:  dex
        bmi     L9C18
        txa
        pha
        lda     highlight_list,x
        asl     a
        tax
        copy16  icon_ptrs,x, $06
        jsr     calc_icon_poly
        jsr     erase_icon
        pla
        tax
        jmp     L9BF3

L9C18:  jsr     pop_pointers
        ldx     highlight_count
        dex
        txa
        pha
        copy16  #drag_outline_buffer, $08
L9C29:  lda     highlight_list,x
        asl     a
        tax
        copy16  icon_ptrs,x, $06
        ldy     #IconEntry::win_type
        lda     ($08),y
        iny
        sta     ($06),y
        lda     ($08),y
        iny
        sta     ($06),y
        lda     ($08),y
        iny
        sta     ($06),y
        lda     ($08),y
        iny
        sta     ($06),y
        pla
        tax
        dex
        bmi     L9C63
        txa
        pha
        lda     $08
        clc
        adc     #kIconPolySize
        sta     $08
        bcc     L9C60
        inc     $08+1
L9C60:  jmp     L9C29

L9C63:  lda     #0

just_select:                    ; ???
        tay
        jsr     pop_pointers
        tya
        tax
        ldy     #0
        lda     highlight_icon_id
        sta     ($06),y
        txa
        rts

L9C74:  .byte   $00
L9C75:  .byte   $00

rect1:
rect1_x1:       .word   0
rect1_y1:       .word   0
rect1_x2:       .word   0
rect1_y2:       .word   0

L9C7E:  .word   0
L9C80:  .word   kMenuBarHeight
const_screen_width:     .word   kScreenWidth
const_screen_height:    .word   kScreenHeight

rect2:
rect2_x1:       .word   0
rect2_y1:       .word   0
rect2_x2:       .word   0
rect2_y2:       .word   0

coords1:
coords1x:       .word   0
coords1y:       .word   0

coords2:        .tag MGTK::Point

rect3:
rect3_x1:       .word   0
rect3_y1:       .word   0
rect3_x2:       .word   0       ; Unused???
rect3_y2:       .word   0       ; Unused???

.proc set_rect2_to_rect1
        COPY_STRUCT MGTK::Rect, rect1, rect2
        rts
.endproc

.proc L9CAA
        lda     rect1_x1
        cmp     L9C7E
        bne     :+
        lda     rect1_x1+1
        cmp     L9C7E+1
        bne     :+
        return  #0

:       sub16   #0, rect2_x1, rect3_x1
        jmp     L9CF5
.endproc

.proc L9CD1
        lda     rect1_x2
        cmp     const_screen_width
        bne     L9CE4
        lda     rect1_x2+1
        cmp     const_screen_width+1
        bne     L9CE4
        return  #0
.endproc

L9CE4:  sub16   #kScreenWidth, rect2_x2, rect3_x1
L9CF5:  add16   rect2_x1, rect3_x1, rect1_x1
        add16   rect2_x2, rect3_x1, rect1_x2
        add16   coords1x, rect3_x1, coords1x
        return  #$FF

.proc L9D31
        lda     rect1_y1
        cmp     L9C80
        bne     :+
        lda     rect1_y1+1
        cmp     L9C80+1
        bne     :+
        return  #0

:       sub16   #kMenuBarHeight, rect2_y1, rect3_y1
        jmp     L9D7C
.endproc

.proc L9D58
        lda     rect1_y2
        cmp     const_screen_height
        bne     L9D6B
        lda     rect1_y2+1
        cmp     const_screen_height+1
        bne     L9D6B
        return  #0
.endproc

L9D6B:  sub16   #kScreenHeight-1, rect2_y2, rect3_y1
L9D7C:  add16   rect2_y1, rect3_y1, rect1_y1
        add16   rect2_y2, rect3_y1, rect1_y2
        add16   coords1y, rect3_y1, coords1y
        return  #$FF

.proc set_rect1_to_rect2_and_zero_rect3_x
        copy16  rect2_x1, rect1_x1
        copy16  rect2_x2, rect1_x2
        lda     #0
        sta     rect3_x1
        sta     rect3_x1+1
        rts
.endproc

.proc set_rect1_to_rect2_and_zero_rect3_y
        copy16  rect2_y1, rect1_y1
        copy16  rect2_y2, rect1_y2
        lda     #0
        sta     rect3_y1
        sta     rect3_y1+1
        rts
.endproc

.proc set_coords1x_to_mousex
        lda     findwindow_params::mousex+1
        sta     coords1x+1
        lda     findwindow_params::mousex
        sta     coords1x
        rts
.endproc

.proc set_coords1y_to_mousey
        lda     findwindow_params::mousey+1
        sta     coords1y+1
        lda     findwindow_params::mousey
        sta     coords1y
        rts
.endproc

.proc find_target_and_highlight
        bit     flag
        bpl     :+
        rts

:       jsr     push_pointers
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::which_area
        beq     desktop

        ;; --------------------------------------------------
        ;; In a window - ensure it's in the content area
        cmp     #MGTK::Area::content
        beq     :+
        jmp     done            ; menubar, titlebar, etc
:       COPY_STRUCT MGTK::Point, findwindow_params::mousex, findcontrol_params::mousex
        MGTK_CALL MGTK::FindControl, findcontrol_params
        lda     findcontrol_params::which_ctl
        beq     :+              ; 0 = MGTK::Ctl::not_a_control
        jmp     done            ; scrollbar, etc.

        ;; Ignore if y coord < window's header height
:       MGTK_CALL MGTK::GetWinPtr, findwindow_params::window_id
        win_ptr := $06
        copy16  window_ptr, win_ptr
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + MGTK::Point::ycoord
        add16in (win_ptr),y, #kWindowHeaderHeight + 1, headery
        cmp16   findwindow_params::mousey, headery
        bmi     done
        bpl     find_icon       ; always

        ;; --------------------------------------------------
        ;; On desktop - A=0, note that as window_id
desktop:
        sta     findwindow_params::window_id

find_icon:
        ITK_DIRECT_CALL IconTK::FindIcon, findwindow_params
        lda     findwindow_params::which_area ; Icon ID
        bne     :+
        jmp     done

        ;; Is the icon in the highlight list?
:       ldx     highlight_count
        dex
:       cmp     highlight_list,x
        beq     done
        dex
        bpl     :-

        ;; Over an icon
        ptr := $06
        sta     icon_num
        cmp     #kTrashIconNum
        beq     :+
        asl     a
        tax
        copy16  icon_ptrs,x, ptr

        ;; Which window?
        ldy     #IconEntry::win_type
        lda     (ptr),y
        and     #kIconEntryWinIdMask
        sta     window_id

        ;; Is it a drop target?
        lda     (ptr),y
        and     #kIconEntryTypeMask
        bne     done

        ;; Highlight it!
        lda     icon_num
:       sta     highlight_icon_id
        jsr     xdraw_outline
        jsr     highlight_icon
        jsr     xdraw_outline

done:   jsr     pop_pointers
        rts

icon_num:
        .byte   0

headery:
        .word   0
.endproc

;;; Input: A = icon number
;;; Output: A,X = address of IconEntry
.proc get_icon_ptr
        asl     a
        tay
        lda     icon_ptrs+1,y
        tax
        lda     icon_ptrs,y
        rts
.endproc

;;; Input: A = icon number
;;; Output: A = window id (0=desktop)
;;; Trashes $06
.proc get_icon_win
        ptr := $06

        jsr     get_icon_ptr
        stax    ptr
        ldy     #IconEntry::win_type
        lda     (ptr),y
        and     #kIconEntryWinIdMask
        rts
.endproc

.proc xdraw_outline
        MGTK_CALL MGTK::SetPort, drag_outline_grafport
        MGTK_CALL MGTK::FramePoly, drag_outline_buffer
        rts
.endproc

.proc highlight_icon
        jsr set_port_for_highlight_icon
        ITK_DIRECT_CALL IconTK::HighlightIcon, highlight_icon_id
        MGTK_CALL MGTK::InitPort, icon_grafport
        rts
.endproc

.proc unhighlight_icon
        jsr set_port_for_highlight_icon
        ITK_DIRECT_CALL IconTK::UnhighlightIcon, highlight_icon_id
        MGTK_CALL MGTK::InitPort, icon_grafport
        rts
.endproc

;;; Set cliprect to `highlight_icon_id`'s window's content area, in screen
;;; space, using `icon_grafport`.
.proc set_port_for_highlight_icon
        ptr := $06

        lda     highlight_icon_id
        jsr     get_icon_win
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params ; into icon_grafport

        sub16   icon_grafport::cliprect::x2, icon_grafport::cliprect::x1, width
        sub16   icon_grafport::cliprect::y2, icon_grafport::cliprect::y1, height

        COPY_STRUCT MGTK::Point, icon_grafport::viewloc, icon_grafport::cliprect

        add16   icon_grafport::cliprect::x1, width, icon_grafport::cliprect::x2
        add16   icon_grafport::cliprect::y1, height, icon_grafport::cliprect::y2

        ;; Account for window header, and set port to icon_grafport
        jmp     shift_port_down

width:  .word   0
height: .word   0

.endproc


.endproc

;;; ============================================================
;;; UnhighlightIcon

;;; param is pointer to IconEntry

.proc UnhighlightIconImpl
        PARAM_BLOCK params, $06
ptr_iconent:    .addr   0
        END_PARAM_BLOCK

start:  lda     has_highlight
        bne     :+
        return  #1              ; No selection

        ;; Move it to the end of the highlight list
:       ldx     highlight_count ; new position
        ldy     #IconEntry::id
        lda     (params::ptr_iconent),y         ; icon num
        jsr     change_highlight_index

        ;; Remove it from the highlight list and update flag
        ldx     highlight_count
        lda     #0
        sta     highlight_count,x
        dec     highlight_count
        lda     highlight_count
        bne     :+
        lda     #0              ; Clear flag if no more highlighted
        sta     has_highlight

        ;; Redraw
:       ldy     #IconEntry::id
        lda     (params::ptr_iconent),y
        sta     icon
        ITK_DIRECT_CALL IconTK::RedrawIcon, icon
        return  #0

        ;; IconTK::RedrawIcon params
icon:   .byte   0
.endproc

;;; ============================================================
;;; IconInRect

.proc IconInRectImpl
        jmp     start

icon:   .byte   0
        DEFINE_RECT rect, 0, 0, 0, 0

start:  ldy     #0
        lda     ($06),y
        sta     icon
        ldy     #8
:       lda     ($06),y
        sta     rect-1,y
        dey
        bne     :-

        lda     icon
        asl     a
        tax
        copy16  icon_ptrs,x, $06
        jsr     calc_icon_poly

        ;; See vertex diagram in calc_icon_poly

        ;; ----------------------------------------
        ;; Easy parts: extremes

        ;; top of icon > bottom of rect --> outside
        cmp16   rect::y2, poly::v0::ycoord
        bmi     outside

        ;; bottom of icon < top of rect --> outside
        cmp16   poly::v5::ycoord, rect::y1
        bmi     outside

        ;; left of icon text >= right of rect --> outside
        cmp16   poly::v5::xcoord, rect::x2
        bpl     outside

        ;; right of icon text < left of rect --> outside
        cmp16   poly::v4::xcoord, rect::x1
        bmi     outside

        ;; ----------------------------------------
        ;; Harder parts: rect above text on left/right

        ;; top of icon text < bottom of rect --> inside
        cmp16   poly::v7::ycoord, rect::y2
        bmi     inside

        ;; left of icon bitmap >= right of rect --> outside
        cmp16   poly::v7::xcoord, rect::x2
        bpl     outside

        ;; right of icon bitmap >= left of rect --> inside
        cmp16   poly::v2::xcoord, rect::x1
        bpl     inside

outside:
        return  #0

inside:
        return  #1
.endproc

;;; ============================================================
;;; Paint icon
;;; * Assumes grafport selected and maprect configured
;;; * Does not erase background

icon_flags: ; bit 7 = highlighted, bit 6 = volume icon
        .byte   0

open_flag:  ; non-zero if open volume/dir
        .byte   0

more_drawing_needed_flag:
        .byte   0

        DEFINE_POINT label_pos, 0, 0

.proc paint_icon

unhighlighted:
        lda     #0
        sta     icon_flags
        beq     common

highlighted:  copy    #$80, icon_flags ; is highlighted

.proc common
        ;; Test if icon is open volume/folder
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #kIconEntryOpenMask
        sta     open_flag

        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #kIconEntryWinIdMask
        bne     :+

        ;;  Mark as "volume icon" on desktop (needs background)
        lda     icon_flags
        ora     #$40
        sta     icon_flags

        ;; copy icon entry coords and bits
:       ldy     #IconEntry::iconx
:       lda     ($06),y
        sta     icon_paintbits_params::viewloc-IconEntry::iconx,y
        sta     mask_paintbits_params::viewloc-IconEntry::iconx,y
        iny
        cpy     #IconEntry::iconx + 6 ; x/y/bits
        bne     :-

        jsr     push_pointers

        ;; copy icon definition bits
        copy16  icon_paintbits_params::mapbits, $08
        ldy     #.sizeof(MGTK::MapInfo) - .sizeof(MGTK::Point) - 1
:       lda     ($08),y
        sta     icon_paintbits_params::mapbits,y
        sta     mask_paintbits_params::mapbits,y
        dey
        bpl     :-

        ;; Icon definition is followed by pointer to mask address.
        ldy     #.sizeof(MGTK::MapInfo) - .sizeof(MGTK::Point)
        copy16in ($08),y, mask_paintbits_params::mapbits
        jsr     pop_pointers

        ;; Copy, pad, and measure name
        jsr     prepare_name

        ;; Center horizontally
        ;;  text_left = icon_left + icon_width/2 - text_width/2
        ;;            = (icon_left*2 + icon_width - text_width) / 2
        copy16  icon_paintbits_params::viewloc::xcoord, moveto_params2::xcoord ; = icon_left
        asl16   moveto_params2::xcoord ; *= 2
        add16   moveto_params2::xcoord, icon_paintbits_params::maprect::x2, moveto_params2::xcoord ; += icon_width
        sub16   moveto_params2::xcoord, textwidth_params::result, moveto_params2::xcoord ; -= text_width
        asr16   moveto_params2::xcoord ; /= 2 - signed!

        ;; Align vertically
        add16_8 icon_paintbits_params::viewloc::ycoord, icon_paintbits_params::maprect::y2, moveto_params2::ycoord
        add16   moveto_params2::ycoord, #1, moveto_params2::ycoord
        add16_8 moveto_params2::ycoord, font_height, moveto_params2::ycoord

        COPY_STRUCT MGTK::Point, moveto_params2, label_pos

        bit     icon_flags      ; volume icon (on desktop) ?
        bvc     do_paint        ; nope
        ;; TODO: This depends on a previous proc having adjusted
        ;; the grafport (for window maprect and window's items/used/free bar)

        ;; Volume (i.e. icon on desktop)
        MGTK_CALL MGTK::InitPort, grafport
        jsr     set_port_for_vol_icon
:       jsr     calc_window_intersections
        jsr     do_paint
        lda     more_drawing_needed_flag
        bne     :-
        MGTK_CALL MGTK::SetPortBits, grafport ; default maprect
        rts

.endproc

.proc do_paint
        MGTK_CALL MGTK::HideCursor

        ;; --------------------------------------------------
        ;; Icon

        ;; Shade (XORs background)
        lda     open_flag
        beq     :+
        jsr     calc_rect_opendir
        jsr     shade

        ;; Mask (cleared to white or black)
:       MGTK_CALL MGTK::SetPenMode, penOR
        bit     icon_flags
        bpl     :+
        MGTK_CALL MGTK::SetPenMode, penBIC
:       MGTK_CALL MGTK::PaintBits, mask_paintbits_params

        ;; Shade again (restores background)
        lda     open_flag
        beq     :+
        jsr     shade

        ;; Icon (drawn in black or white)
:       MGTK_CALL MGTK::SetPenMode, penBIC
        bit     icon_flags
        bpl     :+
        MGTK_CALL MGTK::SetPenMode, penOR
:       MGTK_CALL MGTK::PaintBits, icon_paintbits_params

        ;; --------------------------------------------------

        ;; Label
        COPY_STRUCT MGTK::Point, label_pos, moveto_params2
        MGTK_CALL MGTK::MoveTo, moveto_params2
        bit     icon_flags      ; highlighted?
        bmi     :+
        lda     #MGTK::textbg_white
        bne     setbg
:       lda     #MGTK::textbg_black
setbg:  sta     settextbg_params
        MGTK_CALL MGTK::SetTextBG, settextbg_params
        MGTK_CALL MGTK::DrawText, drawtext_params
        MGTK_CALL MGTK::ShowCursor

        copy    #MGTK::textbg_white, settextbg_params
        MGTK_CALL MGTK::SetTextBG, settextbg_params
        MGTK_CALL MGTK::SetPattern, white_pattern

        rts

.proc shade
        MGTK_CALL MGTK::SetPattern, dark_pattern
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect_opendir

done:   rts
.endproc

.endproc

;;; ============================================================

.proc calc_rect_opendir
        ldx     #0
:       add16   icon_paintbits_params::viewloc,x, icon_paintbits_params::maprect::topleft,x, rect_opendir::topleft,x
        add16   icon_paintbits_params::viewloc,x, icon_paintbits_params::maprect::bottomright,x, rect_opendir::bottomright,x
        inx
        inx
        cpx     #.sizeof(MGTK::Point)
        bne     :-
        rts
.endproc

.endproc ; paint_icon
        paint_icon_unhighlighted := paint_icon::unhighlighted
        paint_icon_highlighted := paint_icon::highlighted


;;; ============================================================

;;;              v0          v1
;;;               +----------+
;;;               |          |
;;;               |          |
;;;               |          |
;;;            v7 |          | v2
;;;      v6 +-----+          +-----+ v3
;;;         |                      |
;;;      v5 +----------------------+ v4
;;;

kIconPolySize = (8 * .sizeof(MGTK::Point)) + 2

.proc calc_icon_poly
        entry_ptr := $6
        bitmap_ptr := $8

        jsr     push_pointers

        ;; v0 - copy from icon entry
        ldy     #IconEntry::iconx+3
        ldx     #3
:       lda     (entry_ptr),y
        sta     poly::v0,x
        dey
        dex
        bpl     :-

        ;; Top edge (v0, v1)
        copy16  poly::v0::ycoord, poly::v1::ycoord

        ;; Left edge of icon (v0, v7)
        copy16  poly::v0::xcoord, poly::v7::xcoord

        ldy     #IconEntry::iconbits
        copy16in (entry_ptr),y, bitmap_ptr

        ;; Right edge of icon (v1, v2)
        ldy     #IconDefinition::maprect + MGTK::Rect::x2
        lda     (bitmap_ptr),y
        clc
        adc     poly::v0::xcoord
        sta     poly::v1::xcoord
        sta     poly::v2::xcoord
        iny
        lda     (bitmap_ptr),y
        adc     poly::v0::xcoord+1
        sta     poly::v1::xcoord+1
        sta     poly::v2::xcoord+1

        ;; Bottom edge of icon (v2, v7)
        ldy     #IconDefinition::maprect + MGTK::Rect::y2
        add16in (bitmap_ptr),y, poly::v0::ycoord, poly::v2::ycoord

        lda     poly::v2::ycoord ; 2px down
        clc
        adc     #2
        sta     poly::v2::ycoord
        sta     poly::v3::ycoord
        sta     poly::v6::ycoord
        sta     poly::v7::ycoord
        lda     poly::v2::ycoord+1
        adc     #0
        sta     poly::v2::ycoord+1
        sta     poly::v3::ycoord+1
        sta     poly::v6::ycoord+1
        sta     poly::v7::ycoord+1

        ;; Bottom edge of label (v4, v5)
        lda     font_height
        clc
        adc     poly::v2::ycoord
        sta     poly::v4::ycoord
        sta     poly::v5::ycoord
        lda     poly::v2::ycoord+1
        adc     #0
        sta     poly::v4::ycoord+1
        sta     poly::v5::ycoord+1

        ;; Copy, pad, and measure name
        jsr     prepare_name

        ;; Center horizontally

        ldy     #IconDefinition::maprect + MGTK::Rect::x2
        copy16in (bitmap_ptr),y, icon_width

        ;; Left edge of label (v5, v6)
        ;;  text_left = icon_left + icon_width/2 - text_width/2
        ;;            = (icon_left*2 + icon_width - text_width) / 2
        ;; NOTE: Left is computed before right to match rendering code
        copy16  poly::v0::xcoord, poly::v5::xcoord
        asl16   poly::v5::xcoord
        add16   poly::v5::xcoord, icon_width, poly::v5::xcoord
        sub16   poly::v5::xcoord, textwidth_params::result, poly::v5::xcoord
        asr16   poly::v5::xcoord ; signed
        copy16  poly::v5::xcoord, poly::v6::xcoord

        ;; Right edge of label (v3, v4)
        add16   poly::v5::xcoord, textwidth_params::result, poly::v3::xcoord
        copy16  poly::v3::xcoord, poly::v4::xcoord

        jsr     pop_pointers
        rts

icon_width:  .word   0
text_width:  .word   0

.endproc

;;; Copy name from IconEntry (ptr $06) to text_buffer,
;;; with leading/trailing spaces, and measure it.

.proc prepare_name
        .assert text_buffer - 1 = drawtext_params::textlen, error, "location mismatch"

        dest := drawtext_params::textlen
        ptr := $06

        ldy     #.sizeof(IconEntry)
        ldx     #.sizeof(IconEntry) - IconEntry::name
:       lda     (ptr),y
        sta     dest + 1,x
        dey
        dex
        bpl     :-

        ldy     dest + 1
        iny
        iny
        sty     dest

        lda     #' '
        sta     dest + 1
        sta     dest,y

        copy    drawtext_params::textlen, textwidth_params::textlen
        MGTK_CALL MGTK::TextWidth, textwidth_params

        rts
.endproc

;;; ============================================================
;;; RedrawIcons

.proc RedrawIconsImpl
        ptr := $06

        jmp     start

        ;; IconTK::RedrawIcon params
icon:  .byte   0

done:   jsr     pop_pointers
        rts

start:  jsr     push_pointers

        MGTK_CALL MGTK::InitPort, icon_grafport
        MGTK_CALL MGTK::SetPort, icon_grafport

        ldx     num_icons
        dex
loop:   bmi     done
        txa
        pha
        lda     icon_table,x
        asl     a
        tax
        copy16  icon_ptrs,x, ptr
        ldy     #IconEntry::win_type
        lda     (ptr),y
        and     #kIconEntryWinIdMask ; desktop icon
        bne     next                   ; no, skip it

        ldy     #IconEntry::id
        lda     (ptr),y
        sta     icon
        ITK_DIRECT_CALL IconTK::RedrawIcon, icon

next:   pla
        tax
        dex
        jmp     loop
.endproc

;;; ============================================================
;;; A = icon number to move
;;; X = position in highlight list

.proc change_icon_index
        stx     new_pos
        sta     icon_num

        ;; Find position of icon in icon table
        ldx     #0
:       lda     icon_table,x
        cmp     icon_num
        beq     :+
        inx
        cpx     num_icons
        bne     :-
        rts

        ;; Shift items down
:       lda     icon_table+1,x
        sta     icon_table,x
        inx
        cpx     num_icons
        bne     :-

        ;; Shift items up
        ldx     num_icons
:       cpx     new_pos
        beq     place
        lda     icon_table-2,x
        sta     icon_table-1,x
        dex
        jmp     :-

        ;; Place at new position
place:  ldx     new_pos
        lda     icon_num
        sta     icon_table-1,x
        rts

new_pos:        .byte   0
icon_num:       .byte   0
.endproc

;;; ============================================================
;;; A = icon number to move
;;; X = position in highlight list

.proc change_highlight_index
        stx     new_pos
        sta     icon_num

        ;; Find position of icon in highlight list
        ldx     #0
:       lda     highlight_list,x
        cmp     icon_num
        beq     :+
        inx
        cpx     highlight_count
        bne     :-
        rts

        ;; Shift items down
:       lda     highlight_list+1,x
        sta     highlight_list,x
        inx
        cpx     highlight_count
        bne     :-

        ;; Shift items up
        ldx     highlight_count
:       cpx     new_pos
        beq     place
        lda     highlight_list-2,x
        sta     highlight_list-1,x
        dex
        jmp     :-

        ;; Place at new position
place:  ldx     new_pos
        lda     icon_num
        sta     highlight_list-1,x
        rts

new_pos:        .byte   0
icon_num:       .byte   0
.endproc

;;; ============================================================

.proc push_pointers
        ;; save return addr
        pla
        sta     stash
        pla
        sta     stash+1

        ;; push $06...$09 to stack
        ldx     #0
:       lda     $06,x
        pha
        inx
        cpx     #4
        bne     :-

        ;; restore return addr
        lda     stash+1
        pha
        lda     stash
        pha
        rts

stash:  .word   0
.endproc

;;; ============================================================

.proc pop_pointers
        ;; save return addr
        pla
        sta     stash
        pla
        sta     stash+1

        ;; pull $06...$09 to stack
        ldx     #3
:       pla
        sta     $06,x
        dex
        bpl     :-

        ;; restore return addr
        lda     stash+1
        pha
        lda     stash
        pha
        rts

stash:  .word   0

.endproc

;;; ============================================================
;;; Erase an icon; redraws overlapping icons as needed

erase_icon:
        MGTK_CALL MGTK::InitPort, icon_grafport
        MGTK_CALL MGTK::SetPort, icon_grafport
        jmp     LA3B9

LA3AC:  .byte   0
LA3AD:  .byte   0

        ;; IconTK::RedrawIcon params
LA3AE:  .byte   0

LA3AF:  .word   0
LA3B1:  .word   0
LA3B3:  .byte   0
        .byte   0
        .byte   0
        .byte   0
LA3B7:  .byte   0

.params frontwindow_params
window_id:      .byte   0
.endparams

.proc LA3B9
        ldy     #0
        lda     ($06),y
        sta     LA3AC
        iny
        iny
        lda     ($06),y
        and     #$0F            ; type - is volume?
        sta     LA3AD
        beq     volume

        ;; File (i.e. icon in window)
        copy    #$80, LA3B7
        MGTK_CALL MGTK::SetPattern, white_pattern
        MGTK_CALL MGTK::FrontWindow, frontwindow_params ; Use window's port
        lda     frontwindow_params::window_id
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        jsr     offset_icon_poly
        jsr     shift_port_down ; Further offset by window's items/used/free bar
        jsr     erase_window_icon
        jmp     redraw_icons_after_erase

        ;; Volume (i.e. icon on desktop)
volume:
        MGTK_CALL MGTK::InitPort, grafport
        jsr     set_port_for_vol_icon
:       jsr     calc_window_intersections
        jsr     erase_desktop_icon
        lda     more_drawing_needed_flag
        bne     :-
        MGTK_CALL MGTK::SetPortBits, grafport ; default maprect
        jmp     redraw_icons_after_erase
.endproc

;;; ============================================================

.proc erase_desktop_icon
        lda     #0
        sta     LA3B7

        MGTK_CALL MGTK::GetDeskPat, addr
        MGTK_CALL MGTK::SetPattern, 0, addr
        ;; fall through
.endproc

.proc erase_window_icon
        copy16  poly::v0::ycoord, LA3B1
        copy16  poly::v6::xcoord, LA3AF
        COPY_BLOCK poly::v4, LA3B3
        MGTK_CALL MGTK::PaintPoly, poly
        rts
.endproc

;;; ============================================================
;;; After erasing an icon, redraw any overlapping icons

.proc redraw_icons_after_erase
        ptr := $8

        jsr     push_pointers
        ldx     num_icons
        dex                     ; any icons to draw?

loop:   cpx     #$FF            ; =-1
        bne     LA466

        bit     LA3B7
        bpl     :+
        ;; TODO: Is this restoration necessary?
        MGTK_CALL MGTK::InitPort, icon_grafport
        MGTK_CALL MGTK::SetPort, icon_grafport
:       jsr     pop_pointers
        rts

LA466:  txa
        pha
        lda     icon_table,x
        cmp     LA3AC
        beq     next
        asl     a
        tax
        copy16  icon_ptrs,x, ptr
        ldy     #IconEntry::win_type
        lda     (ptr),y
        and     #$07            ; window_id
        cmp     LA3AD
        bne     next

        ;; Is icon highlighted?
        lda     has_highlight
        beq     LA49D
        ldy     #IconEntry::id ; icon num
        lda     (ptr),y
        ldx     #0
:       cmp     highlight_list,x
        beq     next            ; skip it ???
        inx
        cpx     highlight_count
        bne     :-

LA49D:  ldy     #IconEntry::id ; icon num
        lda     (ptr),y
        sta     LA3AE
        bit     LA3B7           ; windowed?
        bpl     LA4AC           ; nope, desktop
        jsr     offset_icon_do  ; yes, adjust rect
LA4AC:  ITK_DIRECT_CALL IconTK::IconInRect, LA3AE
        beq     :+

        ITK_DIRECT_CALL IconTK::RedrawIcon, LA3AE

:       bit     LA3B7
        bpl     next
        lda     LA3AE
        jsr     offset_icon_undo

next:   pla
        tax
        dex
        jmp     loop
.endproc

;;; ============================================================
;;; Offset coordinates for windowed icons

.proc offset_icon

offset_flags:  .byte   0        ; bit 7 = offset poly, bit 6 = undo offset, otherwise do offset

        DEFINE_POINT vl_offset, 0, 0
        DEFINE_POINT mr_offset, 0, 0

entry_poly:
        copy    #$80, offset_flags
        bmi     LA4E2           ; always

entry_do:  pha
        lda     #$40
        sta     offset_flags
        jmp     LA4E2

entry_undo:  pha
        lda     #0
        sta     offset_flags

LA4E2:  ldy     #MGTK::GrafPort::viewloc
:       lda     icon_grafport,y
        sta     vl_offset,y
        iny
        cpy     #MGTK::GrafPort::viewloc + .sizeof(MGTK::Point)
        bne     :-

        ldy     #MGTK::GrafPort::maprect
:       lda     icon_grafport,y
        sta     mr_offset - MGTK::GrafPort::maprect,y
        iny
        cpy     #MGTK::GrafPort::maprect + .sizeof(MGTK::Point)
        bne     :-

        bit     offset_flags
        bmi     offset_poly
        bvc     do_offset
        jmp     undo_offset

.proc offset_poly
        ldx     #0
loop1:  sub16   poly::vertices+0,x, vl_offset::xcoord, poly::vertices+0,x
        sub16   poly::vertices+2,x, vl_offset::ycoord, poly::vertices+2,x
        inx
        inx
        inx
        inx
        cpx     #kPolySize * .sizeof(MGTK::Point)
        bne     loop1
        ldx     #0

loop2:  add16   poly::vertices+0,x, mr_offset::xcoord, poly::vertices+0,x
        add16   poly::vertices+2,x, mr_offset::ycoord, poly::vertices+2,x
        inx
        inx
        inx
        inx
        cpx     #kPolySize * .sizeof(MGTK::Point)
        bne     loop2
        rts
.endproc

.proc do_offset
        ptr := $06

        pla
        tay
        jsr     push_pointers
        tya
        asl     a
        tax
        copy16  icon_ptrs,x, ptr
        ldy     #IconEntry::iconx
        add16in (ptr),y, vl_offset::xcoord, (ptr),y ; iconx += viewloc::xcoord
        iny
        add16in (ptr),y, vl_offset::ycoord, (ptr),y ; icony += viewloc::xcoord
        ldy     #IconEntry::iconx
        sub16in (ptr),y, mr_offset::xcoord, (ptr),y ; icony -= maprect::left
        iny
        sub16in (ptr),y, mr_offset::ycoord, (ptr),y ; icony -= maprect::top
        jsr     pop_pointers
        rts
.endproc

.proc undo_offset
        ptr := $06

        pla
        tay
        jsr     push_pointers
        tya
        asl     a
        tax
        copy16  icon_ptrs,x, ptr
        ldy     #IconEntry::iconx
        sub16in (ptr),y, vl_offset::xcoord, (ptr),y ; iconx -= viewloc::xcoord
        iny
        sub16in (ptr),y, vl_offset::ycoord, (ptr),y ; icony -= viewloc::xcoord
        ldy     #IconEntry::iconx
        add16in (ptr),y, mr_offset::xcoord, (ptr),y ; iconx += maprect::left
        iny
        add16in (ptr),y, mr_offset::ycoord, (ptr),y ; icony += maprect::top
        jsr     pop_pointers
        rts
.endproc

.endproc
        offset_icon_poly := offset_icon::entry_poly
        offset_icon_do := offset_icon::entry_do
        offset_icon_undo := offset_icon::entry_undo

;;; ============================================================
;;; This handles drawing volume icons "behind" windows. It is
;;; done by comparing the bounding rect of the icon (including
;;; label) with windows, and returning a reduced clipping rect.
;;; Since the overlap may be concave, multiple calls may be
;;; necessary; a flag is set if another call is required.
;;;
;;; The algorithm is as follows:
;;;
;;; * Take the bounding box for the icon+label (bounds_*), and
;;;    use it as an initial clipping rect.
;;; * Test each corner of the rect.
;;; * If the corner is inside a window, compute the window bounds.
;;;    (Complicated by title bars, scroll bars, and borders.)
;;; * Consider each case where a window and rect overlap. There
;;;    are 9 cases (8 interesting, one degenerate).
;;; * Reduce the clipping rect to the leftmost exposed portion.
;;; * Recheck the corners, since another window may be overlapped.
;;; * Once a minimal rect is achieved, set a flag indicating if
;;;    another call is needed, and return.
;;; * Caller draws the icon into the clipping rect. If flag was
;;;    set, the caller calls in again.
;;; * On re-entry, return to the initial bounding box but with
;;;    an updated left edge.
;;;
;;; ============================================================

;;; Initial bounds, saved for re-entry.
bounds_l:  .word   0               ; written but never read???
bounds_t:  .word   0
bounds_r:  .word   0
bounds_b:  .word   0

.params portbits
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT cliprect, 0, 0, 0, 0
.endparams

.proc set_port_for_vol_icon
        jsr     calc_icon_poly

        ;; Set up bounds_t
        lda     poly::v0::ycoord
        sta     bounds_t
        sta     portbits::cliprect::y1
        sta     portbits::viewloc::ycoord
        lda     poly::v0::ycoord+1
        sta     bounds_t+1
        sta     portbits::cliprect::y1+1
        sta     portbits::viewloc::ycoord+1

        ;; Set up bounds_l
        copy16  poly::v0::xcoord, bounds_l
        cmp16   bounds_l, poly::v5::xcoord
        bcc     :+
        copy16  poly::v5::xcoord, bounds_l
:       lda     bounds_l
        sta     portbits::cliprect::x1
        sta     portbits::viewloc::xcoord
        lda     bounds_l+1
        sta     portbits::cliprect::x1+1
        sta     portbits::viewloc::xcoord+1

        ;; Set up bounds_b
        lda     poly::v4::ycoord
        sta     bounds_b
        sta     portbits::cliprect::y2
        lda     poly::v4::ycoord+1
        sta     bounds_b+1
        sta     portbits::cliprect::y2+1

        ;; Set up bounds_r
        copy16  poly::v1::xcoord, bounds_r
        cmp16   bounds_r, poly::v3::xcoord
        bcs     :+
        copy16  poly::v3::xcoord, bounds_r
:       lda     bounds_r
        sta     portbits::cliprect::x2
        lda     bounds_r+1
        sta     portbits::cliprect::x2+1

        ;; if (bounds_r > kScreenWidth - 1) bounds_r = kScreenWidth - 1
        cmp16   bounds_r, #kScreenWidth - 1
        bmi     done
        lda     #<(kScreenWidth - 1)
        sta     bounds_r
        sta     portbits::cliprect::x2
        lda     #>(kScreenWidth - 1)
        sta     bounds_r+1
        sta     portbits::cliprect::x2+1

done:   MGTK_CALL MGTK::SetPortBits, portbits
        rts
.endproc

;;; ============================================================

.proc calc_window_intersections
        ptr := $06

        jmp     start

.params findwindow_params
mousex: .word   0
mousey: .word   0
which_area:     .byte   0
window_id:      .byte   0
.endparams

pt_num: .byte   0

scrollbar_flags:
        .byte   0               ; bit 7 = hscroll present; bit 6 = vscroll present
dialogbox_flag:
        .byte   0               ; bit 7 = dialog box

;;; Points at corners of icon's bounding rect
;;; pt1 +----+ pt2
;;;     |    |
;;; pt4 +----+ pt3
        DEFINE_POINT pt1, 0, 0
        DEFINE_POINT pt2, 0, 0
        DEFINE_POINT pt3, 0, 0
        DEFINE_POINT pt4, 0, 0

.params getwinframerect_params
window_id:      .byte   0
        DEFINE_RECT rect, 0, 0, 0, 0
.endparams

stash_r: .word   0


        ;; Viewport/Cliprect to adjust
        vx := portbits::viewloc::xcoord
        vy := portbits::viewloc::ycoord
        cr_l := portbits::cliprect::x1
        cr_t := portbits::cliprect::y1
        cr_r := portbits::cliprect::x2
        cr_b := portbits::cliprect::y2

start:  lda     more_drawing_needed_flag
        beq     reclip

        ;; --------------------------------------------------
        ;; Re-entry - pick up where we left off

        ;; cr_l = cr_r + 1
        ;; vx   = cr_r + 1
        lda     cr_r
        clc
        adc     #1
        sta     cr_l
        sta     vx
        lda     cr_r+1
        adc     #0
        sta     cr_l+1
        sta     vx+1

        ;; cr_t = bounds_t
        ;; cr_r = bounds_r
        ;; cr_b = bounds_b
        COPY_BYTES 6, bounds_t, cr_t

        ;; vy = cr_t
        copy16  cr_t, vy

        ;; Corners of bounding rect (clockwise from upper-left)
        ;; pt1::xcoord = pt4::xcoord = cr_l
        ;; pt1::ycoord = pt2::ycoord = cr_t
        ;; pt2::xcoord = pt3::xcoord = cr_r
        ;; pt3::ycoord = pt4::ycoord = cr_b
reclip: lda     cr_l
        sta     pt1::xcoord
        sta     pt4::xcoord
        lda     cr_l+1
        sta     pt1::xcoord+1
        sta     pt4::xcoord+1
        lda     cr_t
        sta     pt1::ycoord
        sta     pt2::ycoord
        lda     cr_t+1
        sta     pt1::ycoord+1
        sta     pt2::ycoord+1
        lda     cr_r
        sta     pt2::xcoord
        sta     pt3::xcoord
        lda     cr_r+1
        sta     pt2::xcoord+1
        sta     pt3::xcoord+1
        lda     cr_b
        sta     pt3::ycoord
        sta     pt4::ycoord
        lda     cr_b+1
        sta     pt3::ycoord+1
        sta     pt4::ycoord+1

        lda     #0
        sta     pt_num

next_pt:
        ;; Done all 4 points?
        lda     pt_num
        cmp     #4
        bne     do_pt
        lda     #0
        sta     pt_num

        ;; --------------------------------------------------
        ;; Finish up

set_bits:
        ;; Ensure clip right does not exceed screen bounds.
        ;; Fixes https://github.com/a2stuff/a2d/issues/182
        ;; TODO: Enforce this in the algorithm instead?
        cmp16   cr_r, bounds_r
        bcc     :+
        copy16  bounds_r, cr_r

:       MGTK_CALL MGTK::SetPortBits, portbits
        ;; if (cr_r < bounds_r) more drawing is needed
        cmp16   cr_r, bounds_r
        bmi     :+
        copy    #0, more_drawing_needed_flag
        rts

:       copy    #1, more_drawing_needed_flag
        rts

        ;; ==================================================
        ;; Find window at Nth point, and compute bounds

do_pt:  lda     pt_num
        asl     a               ; *4 (.sizeof(Point))
        asl     a
        tax

        ;; Look up window at Nth point
        ldy     #0
:       lda     pt1::xcoord,x
        sta     findwindow_params,y
        iny
        inx
        cpy     #4
        bne     :-

        inc     pt_num
        MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        beq     next_pt

        ;; --------------------------------------------------
        ;; Compute window edges (including non-content area)

        win_l := getwinframerect_params::rect::x1
        win_t := getwinframerect_params::rect::y1
        win_r := getwinframerect_params::rect::x2
        win_b := getwinframerect_params::rect::y2

        copy    findwindow_params::window_id, getwinframerect_params::window_id
        MGTK_CALL MGTK::GetWinFrameRect, getwinframerect_params

        ;; TODO: Determine why these are necessary:
        dec16   win_l
        dec16   win_t
        dec16   win_r

        ;; ==================================================
        ;; At this point, win_r/t/l/b are the window edges,
        ;; cr_r/t/l/b are the rect we know has at least one
        ;; corner overlapping the window.
        ;;
        ;; Cases (#=icon, %=result, :=window)
        ;;
        ;; .  1 ::::    4 ::::    7 ::::
        ;; .    ::::      ::::      ::::
        ;; .    :::##     :##:     %#:::
        ;; .       %#      %%      %#
        ;; .
        ;; .  2 ::::    5 ::::    8 ::::
        ;; .    :::#%     :##:     %#:::
        ;; .    :::#%     :##:     %#:::
        ;; .    ::::      ::::      ::::
        ;; .
        ;; .       %#      %%      %#
        ;; .  3 :::##   6 :##:   9 %#:::
        ;; .    ::::      ::::      ::::
        ;; .    ::::      ::::      ::::

        copy16  cr_r, stash_r   ; in case this turns out to be case 2

        ;; Cases 1/2/3 (and continue below)
        ;; if (cr_r > win_r)
        ;; . cr_r = win_r + 1
        cmp16   cr_r, win_r
        bmi     :+

        add16   win_r, #1, cr_r
        jmp     vert

        ;; Cases 7/8/9 (and done)
        ;; if (win_l > cr_l)
        ;; . cr_r = win_l
:       cmp16   win_l, cr_l
        bmi     vert

        copy16  win_l, cr_r
        jmp     reclip

        ;; Cases 3/6 (and done)
        ;; if (win_t > cr_t)
        ;; . cr_b = win_t
vert:   cmp16   win_t, cr_t
        bmi     :+

        copy16  win_t, cr_b
        copy    #1, more_drawing_needed_flag
        jmp     reclip

        ;; Cases 1/4 (and done)
        ;; if (win_b < cr_b)
        ;; . cr_t = win_b + 2
        ;; . vy   = win_b + 2
:       cmp16   win_b, cr_b
        bpl     :+

        lda     win_b
        clc
        adc     #1
        sta     cr_t
        sta     vy
        lda     win_b+1
        adc     #0
        sta     cr_t+1
        sta     vy+1
        copy    #1, more_drawing_needed_flag
        jmp     reclip

        ;; Case 2
        ;; if (win_r < stash_r)
        ;; . cr_l = win_r + 2
        ;; . vx   = win_r + 2
        ;; . cr_r = stash_r + 2 (workaround for https://github.com/a2stuff/a2d/issues/153)
:       cmp16   win_r, stash_r
        bpl     :+

        lda     win_r
        clc
        adc     #2
        sta     cr_l
        sta     vx
        lda     win_r+1
        adc     #0
        sta     cr_l+1
        sta     vx+1
        add16   stash_r, #2, cr_r
        jmp     reclip

        ;; Case 5 - done!
:       copy16  bounds_r, cr_r
        add16   bounds_r, #1, cr_l
        jmp     set_bits
.endproc

;;; ============================================================

.proc shift_port_down
        ;; For window's items/used/free space bar
        kOffset = kWindowHeaderHeight + 1

        add16   icon_grafport::viewloc::ycoord, #kOffset, icon_grafport::viewloc::ycoord
        add16   icon_grafport::cliprect::y1, #kOffset, icon_grafport::cliprect::y1
        MGTK_CALL MGTK::SetPort, icon_grafport
        rts
.endproc

.endproc ; icon_toolkit

;;; ============================================================

floppy140_pixels:
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1100000),PX(%0000011),PX(%1000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000011),PX(%1000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000011),PX(%1000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000011),PX(%1000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000011),PX(%1000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000111),PX(%1100000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000011),PX(%1000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%0011000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)

floppy140_mask:
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)

ramdisk_pixels:
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100)
        .byte   PX(%1100000),PX(%0001111),PX(%1000111),PX(%1100110),PX(%0000110),PX(%0001100)
        .byte   PX(%1100000),PX(%0001100),PX(%1100110),PX(%0110111),PX(%1011110),PX(%0001100)
        .byte   PX(%1100000),PX(%0001111),PX(%1000111),PX(%1110110),PX(%1110110),PX(%0001100)
        .byte   PX(%1100000),PX(%0001100),PX(%1100110),PX(%0110110),PX(%0000110),PX(%0001100)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1110011),PX(%0011001),PX(%1001100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0110011),PX(%0011001),PX(%1001100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111100)

ramdisk_mask:
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111100)

floppy800_pixels:
        .byte   PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1100011),PX(%0000000),PX(%1100111)
        .byte   PX(%1100011),PX(%0000000),PX(%1100111)
        .byte   PX(%1100011),PX(%1111111),PX(%1100011)
        .byte   PX(%1100000),PX(%0000000),PX(%0000011)
        .byte   PX(%1100000),PX(%0000000),PX(%0000011)
        .byte   PX(%1100111),PX(%1111111),PX(%1110011)
        .byte   PX(%1100110),PX(%0000000),PX(%0110011)
        .byte   PX(%1100110),PX(%0000000),PX(%0110011)
        .byte   PX(%1100110),PX(%0000000),PX(%0110011)
        .byte   PX(%1100110),PX(%0000000),PX(%0110011)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)

floppy800_mask:
        .byte   PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)

profile_pixels:
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1110000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100011),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0011000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1110000)
        .byte   PX(%0000111),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000111),PX(%0000000)

profile_mask:
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1110000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1110000)
        .byte   PX(%0000111),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000111),PX(%0000000)

fileshare_pixels:
        .byte   PX(%0000000),PX(%0000000),PX(%0011001),PX(%1111111),PX(%1000000)
        .byte   PX(%0000000),PX(%0000000),PX(%1100110),PX(%0000000),PX(%1110000)
        .byte   PX(%0011111),PX(%1110011),PX(%0000001),PX(%1000000),PX(%1111100)
        .byte   PX(%0011000),PX(%0011111),PX(%1100000),PX(%0110000),PX(%0001100)
        .byte   PX(%0011000),PX(%0000000),PX(%0011000),PX(%0001100),PX(%0001100)
        .byte   PX(%0011000),PX(%0000000),PX(%0011000),PX(%0110000),PX(%0001100)
        .byte   PX(%0011000),PX(%0000000),PX(%0011001),PX(%1000000),PX(%0001100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0110000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000110)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000110),PX(%0110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0001110),PX(%0111000),PX(%0000000)
        .byte   PX(%1100111),PX(%1111111),PX(%1111000),PX(%0001111),PX(%1110011)
        .byte   PX(%0000000),PX(%0000000),PX(%0000001),PX(%1000000),PX(%0000000)
        .byte   PX(%1100111),PX(%1111111),PX(%1111110),PX(%0111111),PX(%1110011)

fileshare_mask:
        .byte   PX(%0000000),PX(%0000000),PX(%0011001),PX(%1111111),PX(%1000000)
        .byte   PX(%0000000),PX(%0000000),PX(%1111111),PX(%1111111),PX(%1110000)
        .byte   PX(%0011111),PX(%1110011),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000111),PX(%1110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0001111),PX(%1111000),PX(%0000000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111110),PX(%0111111),PX(%1111111)

trash_pixels:
        .byte   PX(%0000001),PX(%1111111),PX(%1000000)
        .byte   PX(%0000011),PX(%1000001),PX(%1100000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1100000),PX(%0000000),PX(%0000011)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1100000),PX(%0000000),PX(%0000011)
        .byte   PX(%1100100),PX(%0010000),PX(%1000011)
        .byte   PX(%1100010),PX(%0001000),PX(%0100011)
        .byte   PX(%1100010),PX(%0001000),PX(%0100011)
        .byte   PX(%1100010),PX(%0001000),PX(%0100011)
        .byte   PX(%1100010),PX(%0001000),PX(%0100011)
        .byte   PX(%1100010),PX(%0001000),PX(%0100011)
        .byte   PX(%1100010),PX(%0001000),PX(%0100011)
        .byte   PX(%1100010),PX(%0001000),PX(%0100011)
        .byte   PX(%1100010),PX(%0001000),PX(%0100011)
        .byte   PX(%1100100),PX(%0010000),PX(%1000011)
        .byte   PX(%1100000),PX(%0000000),PX(%0000011)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)

trash_mask:
        .byte   PX(%0000001),PX(%1111111),PX(%1000000)
        .byte   PX(%0000011),PX(%1111111),PX(%1100000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111)

;;; ============================================================
;;; Menus

label_apple:
        PASCAL_STRING kGlyphSolidApple
label_file:
        PASCAL_STRING res_string_menu_bar_item_file    ; menu bar item
label_view:
        PASCAL_STRING res_string_menu_bar_item_view    ; menu bar item
label_special:
        PASCAL_STRING res_string_menu_bar_item_special ; menu bar item
label_startup:
        PASCAL_STRING res_string_menu_bar_item_startup ; menu bar item
label_selector:
        PASCAL_STRING res_string_menu_bar_item_selector ; menu bar item

label_new_folder:
        PASCAL_STRING res_string_menu_item_new_folder ; menu item
label_open:
        PASCAL_STRING res_string_menu_item_open ; menu item
label_close:
        PASCAL_STRING res_string_menu_item_close ; menu item
label_close_all:
        PASCAL_STRING res_string_menu_item_close_all ; menu item
label_select_all:
        PASCAL_STRING res_string_menu_item_select_all ; menu item
label_copy_file:
        PASCAL_STRING res_string_menu_item_copy_file ; menu item
label_delete_file:
        PASCAL_STRING res_string_menu_item_delete_file ; menu item
label_eject:
        PASCAL_STRING res_string_menu_item_eject ; menu item
label_quit:
        PASCAL_STRING res_string_menu_item_quit ; menu item

label_by_icon:
        PASCAL_STRING res_string_menu_item_by_icon ; menu item
label_by_name:
        PASCAL_STRING res_string_menu_item_by_name ; menu item
label_by_date:
        PASCAL_STRING res_string_menu_item_by_date ; menu item
label_by_size:
        PASCAL_STRING res_string_menu_item_by_size ; menu item
label_by_type:
        PASCAL_STRING res_string_menu_item_by_type ; menu item

label_check_all_drives:
        PASCAL_STRING res_string_menu_item_check_all_drives ; menu item
label_check_drive:
        PASCAL_STRING res_string_menu_item_check_drive ; menu item
label_format_disk:
        PASCAL_STRING res_string_menu_item_format_disk ; menu item
label_erase_disk:
        PASCAL_STRING res_string_menu_item_erase_disk ; menu item
label_disk_copy:
        PASCAL_STRING res_string_menu_item_disk_copy ; menu item
label_lock:
        PASCAL_STRING res_string_menu_item_lock ; menu item
label_unlock:
        PASCAL_STRING res_string_menu_item_unlock ; menu item
label_get_info:
        PASCAL_STRING res_string_menu_item_get_info ; menu item
label_get_size:
        PASCAL_STRING res_string_menu_item_get_size ; menu item
label_rename_icon:
        PASCAL_STRING res_string_menu_item_rename_icon ; menu item

desktop_menu:
        DEFINE_MENU_BAR 6
@items: DEFINE_MENU_BAR_ITEM kMenuIdApple, label_apple, apple_menu
        DEFINE_MENU_BAR_ITEM kMenuIdFile, label_file, file_menu
        DEFINE_MENU_BAR_ITEM kMenuIdView, label_view, view_menu
        DEFINE_MENU_BAR_ITEM kMenuIdSpecial, label_special, special_menu
        DEFINE_MENU_BAR_ITEM kMenuIdStartup, label_startup, startup_menu
        DEFINE_MENU_BAR_ITEM kMenuIdSelector, label_selector, selector_menu
        ASSERT_RECORD_TABLE_SIZE @items, 6, .sizeof(MGTK::MenuBarItem)

file_menu:
        DEFINE_MENU kMenuSizeFile
@items: DEFINE_MENU_ITEM label_new_folder, res_char_menu_item_new_folder_shortcut
        DEFINE_MENU_ITEM label_open, res_char_menu_item_open_shortcut
        DEFINE_MENU_ITEM label_close, res_char_menu_item_close_shortcut
        DEFINE_MENU_ITEM label_close_all
        DEFINE_MENU_ITEM label_select_all, res_char_menu_item_select_all_shortcut
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM label_get_info, res_char_menu_item_get_info_shortcut
        DEFINE_MENU_ITEM_NOMOD label_rename_icon, CHAR_RETURN, CHAR_RETURN
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM label_copy_file
        DEFINE_MENU_ITEM label_delete_file
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM label_quit, res_char_menu_item_quit_shortcut
        ASSERT_RECORD_TABLE_SIZE @items, ::kMenuSizeFile, .sizeof(MGTK::MenuItem)

        kMenuItemIdNewFolder   = 1
        kMenuItemIdOpen        = 2
        kMenuItemIdClose       = 3
        kMenuItemIdCloseAll    = 4
        kMenuItemIdSelectAll   = 5
        ;; --------------------
        kMenuItemIdGetInfo     = 7
        kMenuItemIdRenameIcon  = 8
        ;; --------------------
        kMenuItemIdCopyFile    = 10
        kMenuItemIdDeleteFile  = 11
        ;; --------------------
        kMenuItemIdQuit        = 13

view_menu:
        DEFINE_MENU kMenuSizeView
@items: DEFINE_MENU_ITEM label_by_icon
        DEFINE_MENU_ITEM label_by_name
        DEFINE_MENU_ITEM label_by_date
        DEFINE_MENU_ITEM label_by_size
        DEFINE_MENU_ITEM label_by_type
        ASSERT_RECORD_TABLE_SIZE @items, ::kMenuSizeView, .sizeof(MGTK::MenuItem)

        kMenuItemIdViewByIcon = 1
        kMenuItemIdViewByName = 2
        kMenuItemIdViewByDate = 3
        kMenuItemIdViewBySize = 4
        kMenuItemIdViewByType = 5

special_menu:
        DEFINE_MENU kMenuSizeSpecial
@items: DEFINE_MENU_ITEM label_check_all_drives
        DEFINE_MENU_ITEM label_check_drive
        DEFINE_MENU_ITEM label_eject, res_char_menu_item_eject_shortcut
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM label_format_disk
        DEFINE_MENU_ITEM label_erase_disk
        DEFINE_MENU_ITEM label_disk_copy
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM label_lock
        DEFINE_MENU_ITEM label_unlock
        DEFINE_MENU_ITEM label_get_size
        ASSERT_RECORD_TABLE_SIZE @items, ::kMenuSizeSpecial, .sizeof(MGTK::MenuItem)

        kMenuItemIdCheckAll    = 1
        kMenuItemIdCheckDrive  = 2
        kMenuItemIdEject       = 3
        ;; --------------------
        kMenuItemIdFormatDisk  = 5
        kMenuItemIdEraseDisk   = 6
        kMenuItemIdDiskCopy    = 7
        ;; --------------------
        kMenuItemIdLock        = 9
        kMenuItemIdUnlock      = 10
        kMenuItemIdGetSize     = 11

;;; ============================================================

        .include "../lib/drawstring.s"
        .include "../lib/muldiv.s"
        .include "../lib/bell.s"

;;; ============================================================

        PAD_TO $AE00

;;; ============================================================

        ;; Rects
        kPromptDialogWidth = 400
        kPromptDialogHeight = 107

        DEFINE_RECT_INSET confirm_dialog_outer_rect, 4, 2, kPromptDialogWidth, kPromptDialogHeight
        DEFINE_RECT_INSET confirm_dialog_inner_rect, 5, 3, kPromptDialogWidth, kPromptDialogHeight

        DEFINE_BUTTON ok,     res_string_button_ok, 260, kPromptDialogHeight-19
        DEFINE_BUTTON cancel, res_string_button_cancel,   40, kPromptDialogHeight-19
        DEFINE_BUTTON yes,    res_string_button_yes,               200, kPromptDialogHeight-19,40,kButtonHeight
        DEFINE_BUTTON no,     res_string_button_no,                260, kPromptDialogHeight-19,40,kButtonHeight
        DEFINE_BUTTON all,    res_string_button_all,               320, kPromptDialogHeight-19,40,kButtonHeight

textbg_black:  .byte   $00
textbg_white:  .byte   $7F

;;; ============================================================

kDialogLabelHeight      = 9
kDialogLabelBaseY       = 30
kDialogLabelRow1        = kDialogLabelBaseY + kDialogLabelHeight * 1
kDialogLabelRow2        = kDialogLabelBaseY + kDialogLabelHeight * 2
kDialogLabelRow3        = kDialogLabelBaseY + kDialogLabelHeight * 3
kDialogLabelRow4        = kDialogLabelBaseY + kDialogLabelHeight * 4
kDialogLabelRow5        = kDialogLabelBaseY + kDialogLabelHeight * 5
kDialogLabelRow6        = kDialogLabelBaseY + kDialogLabelHeight * 6

;;; ============================================================
;;; Prompt dialog resources

        DEFINE_RECT clear_dialog_labels_rect, 39, 25, 360, kPromptDialogHeight-20

        DEFINE_RECT prompt_rect, 40, kDialogLabelRow5+1, 360, kDialogLabelRow6
        DEFINE_POINT current_target_file_pos, 75, kDialogLabelRow2
        DEFINE_POINT current_dest_file_pos, 75, kDialogLabelRow3
        DEFINE_RECT current_target_file_rect, 75, kDialogLabelRow1+1, 394, kDialogLabelRow2
        DEFINE_RECT current_dest_file_rect, 75, kDialogLabelRow2+1, 394, kDialogLabelRow3

;;; ============================================================
;;; "About" dialog resources

kAboutDialogWidth       = 400
kAboutDialogHeight      = 120

        DEFINE_RECT_INSET about_dialog_outer_rect, 4, 2, kAboutDialogWidth, kAboutDialogHeight
        DEFINE_RECT_INSET about_dialog_inner_rect, 5, 3, kAboutDialogWidth, kAboutDialogHeight

str_about1:  PASCAL_STRING kDeskTopProductName
str_about2:  PASCAL_STRING res_string_about_text_line2
str_about3:  PASCAL_STRING res_string_about_text_line3
str_about4:  PASCAL_STRING res_string_about_text_line4
str_about5:  PASCAL_STRING res_string_about_text_line5
str_about6:  PASCAL_STRING res_string_about_text_line6
str_about7:  PASCAL_STRING res_string_about_text_line7
str_about8:  PASCAL_STRING kBuildDate
str_about9:  PASCAL_STRING .sprintf("Version %d.%d%s",::kDeskTopVersionMajor,::kDeskTopVersionMinor,kDeskTopVersionSuffix) ; do not localize

        ;; "Copy File" dialog strings
str_copy_title:
        PASCAL_STRING res_string_copy_dialog_title ; dialog title
str_copy_copying:
        PASCAL_STRING res_string_copy_label_statsus
str_copy_from:
        PASCAL_STRING res_string_copy_label_from
str_copy_to:
        PASCAL_STRING res_string_copy_label_to
str_copy_remaining:
        PASCAL_STRING res_string_copy_status_files_remaining

        ;; "Move File" dialog strings
str_move_title:
        PASCAL_STRING res_string_move_dialog_title ; dialog title
str_move_moving:
        PASCAL_STRING res_string_move_label_status
str_move_remaining:
        PASCAL_STRING res_string_move_status_files_remaining

str_exists_prompt:
        PASCAL_STRING res_string_prompt_overwrite
str_large_copy_prompt:
        PASCAL_STRING res_string_errmsg_too_large_to_copy
str_large_move_prompt:
        PASCAL_STRING res_string_errmsg_too_large_to_move

        DEFINE_POINT copy_file_count_pos, 110, kDialogLabelRow1
        DEFINE_POINT copy_file_count_pos2, 170, kDialogLabelRow4

        ;; "Delete" dialog strings
str_delete_title:
        PASCAL_STRING res_string_delete_dialog_title ; dialog title
str_delete_ok:
        PASCAL_STRING res_string_prompt_delete_ok
str_ok_empty:
        PASCAL_STRING res_string_prompt_ok_empty_trash
str_file_colon:
        PASCAL_STRING res_string_label_file
str_delete_remaining:
        PASCAL_STRING res_string_delete_remaining
str_delete_locked_file:
        PASCAL_STRING res_string_delete_prompt_locked_file

        DEFINE_POINT delete_file_count_pos, 145, kDialogLabelRow4

        DEFINE_POINT delete_remaining_count_pos, 204, kDialogLabelRow4

        DEFINE_POINT delete_file_count_pos2, 300, kDialogLabelRow4

        ;; "New Folder" dialog strings
str_in_colon:
        PASCAL_STRING res_string_new_folder_label_in
str_enter_folder_name:
        PASCAL_STRING res_string_new_folder_label_name

        ;; "Rename Icon" dialog strings
str_rename_old:
        PASCAL_STRING res_string_rename_label_old
str_rename_new:
        PASCAL_STRING res_string_rename_label_new

        ;; "Get Info" dialog strings
str_info_name:
        PASCAL_STRING res_string_get_info_label_name
str_info_locked:
        PASCAL_STRING res_string_get_info_label_locked
str_info_file_size:
        PASCAL_STRING res_string_get_info_label_file_size
str_info_create:
        PASCAL_STRING res_string_get_info_label_create
str_info_mod:
        PASCAL_STRING res_string_get_info_label_mod
str_info_type:
        PASCAL_STRING res_string_get_info_label_type
str_info_protected:
        PASCAL_STRING res_string_get_info_label_protected
str_info_vol_size:
        PASCAL_STRING res_string_get_info_label_vol_size

str_colon:
        PASCAL_STRING res_string_get_info_colon_prefix

        DEFINE_POINT unlock_remaining_count_pos2, 160, kDialogLabelRow4
        DEFINE_POINT lock_remaining_count_pos2, 145, kDialogLabelRow4
        DEFINE_POINT files_pos, 200, kDialogLabelRow4
        DEFINE_POINT files_pos2, 185, kDialogLabelRow4
        DEFINE_POINT unlock_remaining_count_pos, 205, kDialogLabelRow4
        DEFINE_POINT lock_remaining_count_pos, 195, kDialogLabelRow4

str_select_format:
        PASCAL_STRING res_string_format_disk_label_select
str_new_volume:
        PASCAL_STRING res_string_format_disk_label_enter_name
str_confirm_format:
        PASCAL_STRING res_string_format_disk_prompt_format
str_formatting:
        PASCAL_STRING res_string_format_disk_status_formatting
str_formatting_error:
        PASCAL_STRING res_string_format_disk_error

str_select_erase:
        PASCAL_STRING res_string_erase_disk_label_select
str_confirm_erase:
        PASCAL_STRING res_string_erase_disk_prompt_erase
str_erasing:
        PASCAL_STRING res_string_erase_disk_status_erasing
str_erasing_error:
        PASCAL_STRING res_string_erase_disk_error

        ;; "Unlock File" dialog strings
str_unlock_ok:
        PASCAL_STRING res_string_unlock_prompt
str_unlock_remaining:
        PASCAL_STRING res_string_unlock_status_remaining

        ;; "Lock File" dialog strings
str_lock_ok:
        PASCAL_STRING res_string_lock_prompt
str_lock_remaining:
        PASCAL_STRING res_string_lock_status_remaining

        ;; "Get Size" dialog strings
str_size_number:
        PASCAL_STRING res_string_get_size_label_count
str_size_blocks:
        PASCAL_STRING res_string_get_size_label_space

str_download:
        PASCAL_STRING res_string_download_dialog_title ; dialog title

str_ramcard_full:
        PASCAL_STRING res_string_download_error_ramcard_full

str_blank:
        PASCAL_STRING " "       ; do not localize

str_warning:
        PASCAL_STRING res_string_warning_dialog_title

str_insert_system_disk:
        PASCAL_STRING res_string_warning_insert_system_disk

str_selector_list_full:
        PASCAL_STRING res_string_warning_selector_list_full_line1
str_selector_list_full2:
        PASCAL_STRING res_string_warning_selector_list_full_line2

str_window_must_be_closed:
        PASCAL_STRING res_string_warning_window_must_be_closed

str_too_many_windows:
        PASCAL_STRING res_string_warning_too_many_windows

str_save_selector_list:
        PASCAL_STRING res_string_warning_save_selector_list_line1
str_save_selector_list2:
        PASCAL_STRING res_string_warning_save_selector_list_line2

;;; ============================================================
;;; Show Alert Dialog
;;; Call show_alert_dialog with prompt number A, options in X
;;; Options:
;;;    0 = use defaults for alert number; otherwise, look at top 2 bits
;;;  %0....... e.g. $01 = OK
;;;  %10...... e.g. $80 = Try Again, Cancel
;;;  %11...... e.g. $C0 = OK, Cancel
;;; Return value:
;;;   0 = Try Again
;;;   1 = Cancel
;;;   2 = OK

.proc Alert
        jmp     start

alert_bitmap:
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000000),PX(%1111111),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111100),PX(%1111100),PX(%0000001),PX(%1110000),PX(%0000111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111100),PX(%1111100),PX(%0000011),PX(%1100000),PX(%0000011),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0000111),PX(%1100111),PX(%1111001),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0001111),PX(%1100111),PX(%1111001),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111111),PX(%1111001),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111111),PX(%1110011),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111111),PX(%1100111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111111),PX(%1001111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111111),PX(%0011111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111110),PX(%0111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111100),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1111100),PX(%0011111),PX(%1111100),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111110),PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1100000),PX(%1111111),PX(%1111100),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1100001),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0000000),PX(%0000000)
        .byte   PX(%0111000),PX(%0000011),PX(%1111111),PX(%1111111),PX(%1111110),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0111111),PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000)

.params alert_bitmap_params
        DEFINE_POINT viewloc, 20, 8
mapbits:        .addr   alert_bitmap
mapwidth:       .byte   7
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, 36, 23
.endparams

kAlertRectWidth         = 420
kAlertRectHeight        = 55
kAlertRectLeft          = (::kScreenWidth - kAlertRectWidth)/2
kAlertRectTop           = (::kScreenHeight - kAlertRectHeight)/2

        DEFINE_RECT_SZ alert_rect, kAlertRectLeft, kAlertRectTop, kAlertRectWidth, kAlertRectHeight
        DEFINE_RECT_INSET alert_inner_frame_rect1, 4, 2, kAlertRectWidth, kAlertRectHeight
        DEFINE_RECT_INSET alert_inner_frame_rect2, 5, 3, kAlertRectWidth, kAlertRectHeight

.params portmap
        DEFINE_POINT viewloc, kAlertRectLeft, kAlertRectTop
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kAlertRectWidth, kAlertRectHeight
.endparams

        DEFINE_BUTTON ok,        res_string_alert_button_ok,  20, 37
        DEFINE_BUTTON try_again, res_string_alert_button_try_again,     20, 37
        DEFINE_BUTTON cancel,    res_string_alert_button_cancel,     300, 37

        DEFINE_POINT pos_prompt, 75, 29

alert_options:  .byte   0
prompt_addr:    .addr   0


;;; ============================================================
;;; Messages

err_00:  PASCAL_STRING res_string_errmsg_00
err_27:  PASCAL_STRING res_string_errmsg_27
err_28:  PASCAL_STRING res_string_errmsg_28
err_2B:  PASCAL_STRING res_string_errmsg_2B
err_40:  PASCAL_STRING res_string_errmsg_40
err_44:  PASCAL_STRING res_string_errmsg_44
err_45:  PASCAL_STRING res_string_errmsg_45
err_46:  PASCAL_STRING res_string_errmsg_46
err_47:  PASCAL_STRING res_string_errmsg_47
err_48:  PASCAL_STRING res_string_errmsg_48
err_49:  PASCAL_STRING res_string_errmsg_49
err_4E:  PASCAL_STRING res_string_errmsg_4E
err_52:  PASCAL_STRING res_string_errmsg_52
err_57:  PASCAL_STRING res_string_errmsg_57
        ;; Below are internal (not ProDOS MLI) error codes.
err_F9:  PASCAL_STRING res_string_errmsg_F9
err_FA:  PASCAL_STRING res_string_errmsg_FA
err_FB:  PASCAL_STRING res_string_errmsg_FB
err_FC:  PASCAL_STRING res_string_errmsg_FC
err_FD:  PASCAL_STRING res_string_errmsg_FD
err_FE:  PASCAL_STRING res_string_errmsg_FE

        ;; number of alert messages
        kNumAlerts = 20
alert_count:
        .byte   kNumAlerts

        ;; message number-to-index table
        ;; (look up by scan to determine index)
alert_table:
        ;; ProDOS MLI error codes:
        .byte   $00, ERR_IO_ERROR, ERR_DEVICE_NOT_CONNECTED, ERR_WRITE_PROTECTED
        .byte   ERR_INVALID_PATHNAME, ERR_PATH_NOT_FOUND, ERR_VOL_NOT_FOUND
        .byte   ERR_FILE_NOT_FOUND, ERR_DUPLICATE_FILENAME, ERR_OVERRUN_ERROR
        .byte   ERR_VOLUME_DIR_FULL, ERR_ACCESS_ERROR, ERR_NOT_PRODOS_VOLUME
        .byte   ERR_DUPLICATE_VOLUME

        ;; Internal error codes:
        .byte   kErrDuplicateVolName, kErrFileNotOpenable, kErrNameTooLong
        .byte   kErrInsertSrcDisk, kErrInsertDstDisk, kErrBasicSysNotFound
        ASSERT_TABLE_SIZE alert_table, kNumAlerts

        ;; alert index to string address
prompt_table:
        .addr   err_00,err_27,err_28,err_2B,err_40,err_44,err_45,err_46
        .addr   err_47,err_48,err_49,err_4E,err_52,err_57,err_F9,err_FA
        .addr   err_FB,err_FC,err_FD,err_FE
        ASSERT_ADDRESS_TABLE_SIZE prompt_table, kNumAlerts

        ;; alert index to action (0 = Cancel, $80 = Try Again)
alert_options_table:
        .byte   kAlertOptionsOK, kAlertOptionsOK
        .byte   kAlertOptionsOK, kAlertOptionsTryAgainCancel
        .byte   kAlertOptionsOK, kAlertOptionsTryAgainCancel
        .byte   kAlertOptionsOK, kAlertOptionsOK
        .byte   kAlertOptionsOK, kAlertOptionsOK
        .byte   kAlertOptionsOK, kAlertOptionsOK
        .byte   kAlertOptionsOK, kAlertOptionsOK
        .byte   kAlertOptionsOK, kAlertOptionsOK
        .byte   kAlertOptionsOK, kAlertOptionsTryAgainCancel
        .byte   kAlertOptionsTryAgainCancel, kAlertOptionsOK
        ASSERT_TABLE_SIZE alert_options_table, kNumAlerts

        ;; Actual entry point
start:  pha                     ; error code
        txa
        pha                     ; options
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::SetCursor, pointer_cursor
        MGTK_CALL MGTK::ShowCursor

        ;; play bell
        jsr     Bell

        ;; Set up GrafPort
        ldx     #.sizeof(MGTK::Point)-1
        lda     #0
:       sta     main_grafport_viewloc_xcoord,x
        sta     main_grafport_cliprect_x1,x
        dex
        bpl     :-

        ;; TODO: Figure out these constants.
        copy16  #550, main_grafport_cliprect_x2
        copy16  #185, main_grafport_cliprect_y2
        MGTK_CALL MGTK::SetPort, main_grafport

        ;; Compute save bounds
        ldax    portmap::viewloc::xcoord ; left
        jsr     CalcXSaveBounds
        sty     save_x1_byte
        sta     save_x1_bit

        lda     portmap::viewloc::xcoord ; right
        clc
        adc     portmap::maprect::x2
        pha
        lda     portmap::viewloc::xcoord+1
        adc     portmap::maprect::x2+1
        tax
        pla
        jsr     CalcXSaveBounds
        sty     save_x2_byte
        sta     save_x2_bit

        lda     portmap::viewloc::ycoord ; top
        sta     save_y1
        clc
        adc     portmap::maprect::y2 ; bottom
        sta     save_y2

        MGTK_CALL MGTK::HideCursor
        jsr     save_dialog_background
        MGTK_CALL MGTK::ShowCursor

        ;; Draw alert box and bitmap
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::PaintRect, alert_rect ; alert background
        MGTK_CALL MGTK::SetPenMode, penXOR ; ensures corners are inverted
        MGTK_CALL MGTK::FrameRect, alert_rect ; alert outline
        MGTK_CALL MGTK::SetPortBits, portmap::viewloc::xcoord
        MGTK_CALL MGTK::FrameRect, alert_inner_frame_rect1 ; inner 2x border
        MGTK_CALL MGTK::FrameRect, alert_inner_frame_rect2
        MGTK_CALL MGTK::SetPenMode, pencopy

        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::PaintBits, alert_bitmap_params
        MGTK_CALL MGTK::ShowCursor

        ;; --------------------------------------------------
        ;; Process Options

        ;; A=alert/X=options
        pla                     ; options
        tax
        pla                     ; alert number

        ;; Search for alert in table, populate prompt_addr
        ldy     alert_count
        dey
:       cmp     alert_table,y
        beq     :+
        dey
        bpl     :-

        ldy     #0              ; default
:       tya
        asl     a
        tay
        copy16  prompt_table,y, prompt_addr

        ;; If options is 0, use table value; otherwise,
        ;; mask off low bit and it's the action (N and V bits)

        ;; %00000000 = Use default options
        ;; %0....... e.g. $01 = OK
        ;; %10...... e.g. $80 = Try Again, Cancel
        ;; %11...... e.g. $C0 = OK, Cancel

        cpx     #0
        beq     :+
        txa
        and     #$FE            ; ignore low bit, e.g. treat $01 as $00
        sta     alert_options
        jmp     draw_buttons

:       tya
        lsr     a
        tay
        lda     alert_options_table,y
        sta     alert_options

        ;; Draw appropriate buttons
draw_buttons:
        MGTK_CALL MGTK::SetPenMode, penXOR

        bit     alert_options    ; high bit clear = Cancel
        bpl     ok_button

        ;; Cancel button
        MGTK_CALL MGTK::FrameRect, cancel_button_rect
        MGTK_CALL MGTK::MoveTo, cancel_button_pos
        param_call DrawString, cancel_button_label

        bit     alert_options
        bvs     ok_button

        ;; Try Again button
        MGTK_CALL MGTK::FrameRect, try_again_button_rect
        MGTK_CALL MGTK::MoveTo, try_again_button_pos
        param_call DrawString, try_again_button_label

        jmp     draw_prompt

        ;; OK button
ok_button:
        MGTK_CALL MGTK::FrameRect, ok_button_rect
        MGTK_CALL MGTK::MoveTo, ok_button_pos
        param_call DrawString, ok_button_label

        ;; Prompt string
draw_prompt:
        MGTK_CALL MGTK::MoveTo, pos_prompt
        param_call_indirect DrawString, prompt_addr

        ;; --------------------------------------------------
        ;; Event Loop

event_loop:
        MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_down
        bne     :+
        jmp     handle_button_down

:       cmp     #MGTK::EventKind::key_down
        bne     event_loop

        ;; --------------------------------------------------
        ;; Key Down
        lda     event_key
        and     #CHAR_MASK
        bit     alert_options   ; has Cancel?
        bpl     check_ok        ; nope
        cmp     #CHAR_ESCAPE    ; yes, maybe Escape?
        bne     :+

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, cancel_button_rect
        lda     #kAlertResultCancel
        jmp     finish

:       bit     alert_options   ; has Try Again?
        bvs     check_ok        ; nope
        cmp     #TO_LOWER(kShortcutTryAgain)  ; yes, maybe A/a ?
        bne     :+
was_a:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, try_again_button_rect
        lda     #kAlertResultTryAgain
        jmp     finish

:       cmp     #kShortcutTryAgain
        beq     was_a
        cmp     #CHAR_RETURN    ; also allow Return as default
        beq     was_a
        jmp     event_loop

check_ok:
        cmp     #CHAR_RETURN
        bne     :+
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, ok_button_rect
        lda     #kAlertResultOK
        jmp     finish

:       jmp     event_loop

        ;; --------------------------------------------------
        ;; Buttons

handle_button_down:
        jsr     event_coords_to_local
        MGTK_CALL MGTK::MoveTo, event_coords

        bit     alert_options
        bpl     check_ok_rect

        MGTK_CALL MGTK::InRect, cancel_button_rect ; Cancel?
        cmp     #MGTK::inrect_inside
        bne     :+
        ldax    #cancel_button_rect
        jsr     alert_button_event_loop
        bne     no_button
        lda     #kAlertResultCancel
        jmp     finish

:       bit     alert_options
        bvs     check_ok_rect

        MGTK_CALL MGTK::InRect, try_again_button_rect ; Try Again?
        cmp     #MGTK::inrect_inside
        bne     no_button
        ldax    #try_again_button_rect
        jsr     alert_button_event_loop
        bne     no_button
        lda     #kAlertResultTryAgain
        jmp     finish

check_ok_rect:
        MGTK_CALL MGTK::InRect, ok_button_rect ; OK?
        cmp     #MGTK::inrect_inside
        bne     no_button
        ldax    #ok_button_rect
        jsr     alert_button_event_loop
        bne     no_button
        lda     #kAlertResultOK
        jmp     finish

no_button:
        jmp     event_loop

finish: pha
        MGTK_CALL MGTK::HideCursor
        jsr     restore_dialog_background
        MGTK_CALL MGTK::ShowCursor
        pla
        rts

;;; ------------------------------------------------------------
;;; Event loop during button press - initial invert and
;;; inverting as mouse is dragged in/out.
;;; (The |button_event_loop| proc is not used as these buttons
;;; are not in a window, so ScreenToWindow can not be used.)
;;; Inputs: A,X = rect address
;;; Output: A=0/N=0/Z=1 = click, A=$80/N=1/Z=0 = cancel

.proc alert_button_event_loop
        stax    rect_addr1
        stax    rect_addr2
        lda     #0
        sta     flag
        MGTK_CALL MGTK::SetPenMode, penXOR
        jsr     invert

loop:   MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     button_up
        jsr     event_coords_to_local
        MGTK_CALL MGTK::MoveTo, event_coords
        MGTK_CALL MGTK::InRect, SELF_MODIFIED, rect_addr1
        cmp     #MGTK::inrect_inside
        beq     inside
        lda     flag
        beq     toggle
        jmp     loop

inside: lda     flag
        bne     toggle
        jmp     loop

toggle: jsr     invert
        lda     flag
        eor     #$80
        sta     flag
        jmp     loop

button_up:
        lda     flag
        rts

invert: MGTK_CALL MGTK::PaintRect, SELF_MODIFIED, rect_addr2
        rts


        ;; High bit clear if button is depressed
flag:   .byte   0
.endproc

        ;; --------------------------------------------------

.proc event_coords_to_local
        sub16   event_xcoord, portmap::viewloc::xcoord, event_xcoord
        sub16   event_ycoord, portmap::viewloc::ycoord, event_ycoord
        rts
.endproc

        .include "../lib/savedialogbackground.s"
        save_dialog_background := dialog_background::Save
        restore_dialog_background := dialog_background::Restore


.endproc
        show_alert_dialog := Alert::start

;;; ============================================================

        .include "../lib/doubleclick.s"
        .include "../lib/buttonloop.s"

;;; ============================================================

        PAD_TO $C000

.endproc ; aux
