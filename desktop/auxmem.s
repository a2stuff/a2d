;;; ============================================================
;;; DeskTop - Aux Memory Segment
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

        RESOURCE_FILE "auxmem.res"

;;; ============================================================
;;; Segment loaded into AUX $4000-$BFFF
;;; ============================================================

.scope aux

        .org ::kSegmentDeskTopAuxAddress

        MLIEntry := MLI ; this makes no sense
        MGTKEntry := *
        .include "../mgtk/mgtk.s"

;;; ============================================================

        ASSERT_ADDRESS ::DEFAULT_FONT
        .incbin .concat("../mgtk/fonts/System.", kBuildLang)

        font_height     := DEFAULT_FONT+2

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
        ;; shares `generic_mask`

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
        ;; shares `generic_mask`

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
        ;; shares `generic_mask`

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
        ;; shares `generic_mask`

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
        ;; shares `generic_mask`

        PAD_TO $8E00

;;; ============================================================
;;; Entry point for "Icon ToolKit"
;;; ============================================================

        ITKEntry := *
        ASSERT_ADDRESS IconTK::MLI, "IconTK entry point"

.scope icon_toolkit

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

        DEFINE_RECT rect_dimmed, 0, 0, 0, 0

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
        ;; `text_buffer` contains only the characters; the length
        ;; is in `drawtext_params::textlen`
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
icon_list:  .res    (::kMaxIconCount+1), 0   ; list of allocated icons (index 0 not used)

icon_ptrs_low:  .res    (::kMaxIconCount+1), 0 ; addresses of icon details (index 0 not used)
icon_ptrs_high: .res    (::kMaxIconCount+1), 0 ; addresses of icon details (index 0 not used)

highlight_count:                ; number of highlighted icons
        .byte   0
highlight_list:                 ; selected icons
        .res    ::kMaxIconCount, 0

;;; Polygon holding the composite outlines of all icons being dragged.
;;; Re-use the "save area" ($800-$1AFF) since menus won't show during
;;; this kOperation.

        drag_outline_buffer := SAVE_AREA_BUFFER
        kMaxDraggableItems = kSaveAreaSize / (.sizeof(MGTK::Point) * 8 + 2)

;;; ============================================================

.params peekevent_params
kind:   .byte   0               ; spills into next block
.endparams

;;; `findwindow_params::window_id` is used as first part of
;;; GetWinPtr params structure including `window_ptr`.
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
penmode:        .byte   MGTK::pencopy
textbg:         .byte   MGTK::textbg_black
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
penmode:        .byte   MGTK::pencopy
textbg:         .byte   MGTK::textbg_black
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
penmode:        .byte   MGTK::pencopy
textbg:         .byte   MGTK::textbg_black
fontptr:        .addr   0
.endparams

;;; ============================================================
;;; IconTK command jump table

desktop_jump_table_low:
        .byte   0
        .byte   <AddIconImpl
        .byte   <HighlightIconImpl
        .byte   <DrawIconImpl
        .byte   <RemoveIconImpl
        .byte   <RemoveAllImpl
        .byte   <CloseWindowImpl
        .byte   <FindIconImpl
        .byte   <DragHighlightedImpl
        .byte   <UnhighlightIconImpl
        .byte   <RedrawDesktopIconsImpl
        .byte   <IconInRectImpl
        .byte   <EraseIconImpl

desktop_jump_table_high:
        .byte   0
        .byte   >AddIconImpl
        .byte   >HighlightIconImpl
        .byte   >DrawIconImpl
        .byte   >RemoveIconImpl
        .byte   >RemoveAllImpl
        .byte   >CloseWindowImpl
        .byte   >FindIconImpl
        .byte   >DragHighlightedImpl
        .byte   >UnhighlightIconImpl
        .byte   >RedrawDesktopIconsImpl
        .byte   >IconInRectImpl
        .byte   >EraseIconImpl

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
        ldx     #AS_BYTE(-4)
:       lda     $06 + 4,x
        pha
        inx
        bne     :-

        ;; Point ($06) at call command
        ldx     call_params
        ldy     call_params + 1
        inx
        bne     :+
        iny
:       stx     $06
        sty     $07

        ldy     #0
        lda     ($06),y
        tax
        copylohi  desktop_jump_table_low,x, desktop_jump_table_high,x, dispatch + 1
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
        bpl     :-
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
        ;; Parameter is an IconEntry
        ptr_icon := $06

        ;; Check if passed ID is already in the icon list
        ldy     #IconEntry::id
        lda     (ptr_icon),y ; A = icon id
        jsr     IsInIconList
        bne     :+
        return  #1              ; That icon id is already in use

        ;; Add it to `icon_list`
:       ldx     num_icons
        sta     icon_list,x
        inc     num_icons

        ;; Add to `icon_ptrs` table
        tax
        copylohi  ptr_icon, icon_ptrs_low,x, icon_ptrs_high,x

        lda     #1              ; $01 = allocated
        tay                     ; And IconEntry::state
        sta     (ptr_icon),y
        lsr

        rts
.endproc

;;; ============================================================
;;; Tests if the passed icon id is in `icon_list`
;;; Inputs: A = icon id
;;; Outputs: Z=1 if found (and X = index), Z=0 otherwise
;;; A is unmodified, X is trashed

.proc IsInIconList
        ldx     num_icons
:       dex
        bmi     done            ; X=#$FF, Z=0
        cmp     icon_list,x
        bne     :-              ; not found

done:   rts
.endproc

;;; ============================================================
;;; HighlightIcon

;;; param is pointer to icon id

.proc HighlightIconImpl
        params := $06
.struct HighlightIconParams
        icon    .byte
.endstruct

        ptr := $06              ; Overwrites params

        ;; Pointer to IconEntry
        ldy     #HighlightIconParams::icon
        lda     (params),y
        tax
        copylohi icon_ptrs_low,x, icon_ptrs_high,x, ptr

        ldy     #IconEntry::state
        lda     (ptr),y         ; valid icon?
        bne     :+
        return  #2              ; Invalid icon
:
        ;;and     #kIconEntryStateHighlighted
        .assert kIconEntryStateHighlighted = $40, error, "kIconEntryStateHighlighted must be $40"
        asl
        bpl     :+
        return  #3              ; Already highlighted
:
        ;; Mark highlighted
        ror
        ora     #kIconEntryStateHighlighted
        sta     (ptr),y

        ;; Append to highlight list
        ;;ldy     #IconEntry::id
        .assert (IconEntry::state - IconEntry::id) = 1, error, "id must be 1 less than state"
        dey
        lda     (ptr),y         ; A = icon id
        ldx     highlight_count
        sta     highlight_list,x
        inc     highlight_count

        ;; Move it to the head of the highlight list
        ldx     #1              ; new position
        jsr     ChangeHighlightIndex

        ldy     #IconEntry::id
        lda     (ptr),y         ; A = icon id
        ldx     #1              ; new position
        jmp     ChangeIconIndex
.endproc

;;; ============================================================
;;; DrawIcon

;;; * Assumes correct grafport already selected/maprect specified
;;; * Does not erase background

.proc DrawIconImpl
        params := $06
.struct DrawIconParams
        icon    .byte
.endstruct

        ptr := $06              ; Overwrites params

        ;; Pointer to IconEntry
        ldy     #DrawIconParams::icon
        lda     (params),y
        tax
        copylohi icon_ptrs_low,x, icon_ptrs_high,x, ptr

        ldy     #IconEntry::state
        lda     (ptr),y         ; valid icon?
        asl
        bmi     :+

        jsr     paint_icon_unhighlighted
        return  #0

:       jsr     paint_icon_highlighted
        return  #0
.endproc

;;; ============================================================
;;; RemoveIcon

;;; param is pointer to icon number

.proc RemoveIconImpl
        params := $06
.struct RemoveIconParams
        icon    .byte
.endstruct

        ptr := $08

        ;; Is it in `icon_list`?
        ldy     #RemoveIconParams::icon
        lda     (params),y
        jsr     IsInIconList
        beq     :+
        return  #1              ; Not found

        ;; Pointer to IconEntry
:       tax
        copylohi icon_ptrs_low,x, icon_ptrs_high,x, ptr

        ldy     #IconEntry::state ; valid icon?
        lda     (ptr),y
        bne     :+
        return  #2
:
        jsr     RemoveIconCommon
        return  #0
.endproc

;;; ============================================================
;;; Remove the icon at $08

.proc RemoveIconCommon
        ptr := $08

        ;; Move it to the end of `icon_list`
        ldy     #IconEntry::id
        lda     (ptr),y         ; icon num
        ldx     num_icons       ; new position
        jsr     ChangeIconIndex

        ;; Remove it
        dec     num_icons
        lda     #0
        ldx     num_icons
        sta     icon_list,x

        ;; Mark it as free
        ldy     #IconEntry::state
        lda     (ptr),y         ; A = state
        ;; Was it highlighted?
        ;;and     #kIconEntryStateHighlighted
        .assert kIconEntryStateHighlighted = $40, error, "kIconEntryStateHighlighted must be $40"
        asl
        asl                     ; carry set if highlighted
        lda     #0              ; not allocated
        sta     (ptr),y

        bcc     :+              ; not highlighted

        ;;ldy     #IconEntry::id
        .assert (IconEntry::state - IconEntry::id) = 1, error, "id must be 1 less than state"
        dey
        lda     (ptr),y         ; A = icon id
        jsr     RemoveFromHighlightList

:       rts
.endproc

;;; ============================================================
;;; EraseIcon

.proc EraseIconImpl
        params := $06
.struct EraseIconParams
        icon    .byte
.endstruct

        ptr := $06              ; Overwrites params

        ;; Pointer to IconEntry
        ldy     #EraseIconParams::icon
        lda     (params),y
        tax
        copylohi icon_ptrs_low,x, icon_ptrs_high,x, ptr

        jsr     CalcIconPoly
        lda     #$80            ; redraw highlighted
        jmp     erase_icon
.endproc

;;; ============================================================
;;; RemoveAll

;;; param is window id (0 = desktop)

.proc RemoveAllImpl
        params := $06
.struct RemoveAllParams
        window_id       .byte
.endstruct

        icon_ptr := $08

        lda     num_icons
        sta     count

loop:   ldx     count
        beq     done
        dec     count
        dex

        ldy     icon_list,x
        sty     icon
        copylohi icon_ptrs_low,y, icon_ptrs_high,y, icon_ptr
        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        and     #kIconEntryWinIdMask
        ldy     #RemoveAllParams::window_id
        cmp     (params),y
        bne     loop
        ITK_DIRECT_CALL IconTK::RemoveIcon, icon

        jmp     loop

done:   return  #0

        ;; IconTK::RemoveIcon params
icon:   .byte   0

count:  .byte   0
.endproc

;;; ============================================================
;;; CloseWindow

;;; param is window id

.proc CloseWindowImpl
        params := $06
.struct CloseWindowParams
        window_id       .byte
.endstruct

        ptr := $08

        lda     num_icons
        sta     count
count := * + 1
loop:   ldx     #SELF_MODIFIED_BYTE
        bne     L96E5
        txa
        rts

L96E5:  dec     count
        dex
        ldy     icon_list,x
        copylohi icon_ptrs_low,y, icon_ptrs_high,y, ptr
        ldy     #IconEntry::win_flags
        lda     (ptr),y
        and     #kIconEntryWinIdMask ; check window
        ldy     #CloseWindowParams::window_id
        cmp     (params),y ; match?
        bne     loop                 ; nope

        jsr     RemoveIconCommon

        jmp     loop
.endproc

;;; ============================================================
;;; FindIcon

.proc FindIconImpl
        params := $06
.struct FindIconParams
        coords  .tag MGTK::Point
        result  .byte
        window_id       .byte
.endstruct

        icon_ptr   := $06       ; for `CalcIconPoly` call
        out_params := $08

        ;; Copy coords at $6 to param block
        .assert FindIconParams::coords = 0, error, "coords must come first"
        ldy     #.sizeof(MGTK::Point)-1
:       lda     (params),y
        sta     moveto_params2,y
        dey
        bpl     :-

        copy16  params, out_params

        ldy     #FindIconParams::window_id
        lda     (params),y
        sta     window_id

        MGTK_CALL MGTK::MoveTo, moveto_params2

        ldx     #0
loop:   cpx     num_icons
        bne     :+

        ;; Nothing found
        ldy     #FindIconParams::result
        lda     #0
        sta     (out_params),y
        rts

        ;; Check the icon
:       txa
        pha
        ldy     icon_list,x
        copylohi icon_ptrs_low,y, icon_ptrs_high,y, icon_ptr

        ;; Matching window?
        ldy     #IconEntry::win_flags
        lda     (icon_ptr),y
        and     #kIconEntryWinIdMask

window_id := * + 1
        cmp     #SELF_MODIFIED_BYTE
        bne     :+

        ;; In poly?
        jsr     CalcIconPoly    ; requires `icon_ptr` set
        MGTK_CALL MGTK::InPoly, poly
        bne     inside          ; yes!

        ;; Nope, next
:       pla
        tax
        inx
        bne     loop            ; always

        ;; Found one!
inside: pla
        tax
        lda     icon_list,x
        ldy     #FindIconParams::result
        sta     (out_params),y
        rts
.endproc

;;; ============================================================
;;; DragHighlighted

.proc DragHighlightedImpl
        params := $06
.struct DragHighlightedParams
        icon    .byte
        coords  .tag    MGTK::Point
.endstruct

        ldy     #DragHighlightedParams::icon
        lda     ($06),y
        sta     icon_id
        tya
        sta     ($06),y

        ;; Copy coords (at params+1) to
        ldy     #DragHighlightedParams::coords + .sizeof(MGTK::Point)-1
:       lda     ($06),y
        sta     coords1-1,y
        sta     coords2-1,y
        dey
        ;;cpy     #DragHighlightedParams::coords-1
        .assert DragHighlightedParams::coords = 1, error, "coords must be 1"
        bne     :-

        jsr     PushPointers
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
.proc DragDetect

peek:   MGTK_CALL MGTK::PeekEvent, peekevent_params
        lda     peekevent_params::kind
        cmp     #MGTK::EventKind::drag
        beq     drag

ignore_drag:
        lda     #2              ; return value
        jmp     just_select

        ;; Compute mouse delta
drag:   lda     findwindow_params::mousex
        sec
        sbc     coords1x
        tax
        lda     findwindow_params::mousex + 1
        sbc     coords1x + 1

        kDragDelta = 5

        ;; compare x delta
        bpl     x_lo
        cpx     #AS_BYTE(-kDragDelta)
        bcc     is_drag
        bcs     check_deltay
x_lo:   cpx     #kDragDelta
        bcs     is_drag

        ;; compare y delta
check_deltay:
        lda     findwindow_params::mousey
        sec
        sbc     coords1y
        tax
        lda     findwindow_params::mousey + 1
        sbc     coords1y + 1
        bpl     y_lo
        cpx     #AS_BYTE(-kDragDelta)
        bcc     is_drag
        bcs     peek
y_lo:   cpx     #kDragDelta
        bcc     peek
.endproc

        ;; Meets the threshold - it is a drag, not just a click.
is_drag:
        lda     highlight_count
        cmp     #kMaxDraggableItems + 1
        bcs     DragDetect::ignore_drag ; too many

        ;; Was there a selection?
        copy16  #drag_outline_buffer, $08
        lda     highlight_count
        bne     :+
        lda     #3              ; return value
        jmp     just_select

:       lda     highlight_list  ; first entry
        jsr     GetIconWin
        sta     window_id2

        ;; Prepare grafports
        MGTK_CALL MGTK::InitPort, icon_grafport
        MGTK_CALL MGTK::InitPort, drag_outline_grafport
        MGTK_CALL MGTK::SetPort, drag_outline_grafport
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern
        MGTK_CALL MGTK::SetPenMode, penXOR

        ;; Since SetZP1 is used, ask MGTK to update the GrafPort.
        port_ptr := $06
        MGTK_CALL MGTK::GetPort, port_ptr

        COPY_BLOCK drag_outline_grafport::cliprect, iconinrect_params::rect

        ldx     highlight_count
        stx     L9C74

L98F2:  lda     highlight_count,x
        jsr     GetIconPtr
        stax    $06
        ldy     #IconEntry::id
        lda     ($06),y
        cmp     trash_icon_num
        bne     :+
        ldx     #$80
        stx     flag
:       sta     iconinrect_params::icon
        ITK_DIRECT_CALL IconTK::IconInRect, iconinrect_params::icon
        beq     L9954
        jsr     CalcIconPoly
        lda     L9C74
        cmp     highlight_count
        beq     L9936
        jsr     PushPointers

        lda     $08
        sec
        sbc     #kIconPolySize
        sta     $08
        bcs     :+
        dec     $08+1

:       ldy     #1              ; MGTK Polygon "not last" flag
        lda     #$80            ; more polygons to follow
        sta     ($08),y
        jsr     PopPointers

L9936:  ldy     #kIconPolySize-1

:       lda     poly,y
        sta     ($08),y
        dey
        bpl     :-

        lda     #8
        iny
        sta     ($08),y
        lda     $08
        clc
        adc     #kIconPolySize
        sta     $08
        bcc     L9954
        inc     $08+1
L9954:  dec     L9C74
        ldx     L9C74
        bne     L98F2

        COPY_BYTES 8, drag_outline_buffer+2, rect1

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
        bne     L99AA           ; always

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
        bne     L99E1           ; always

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
        ldy     #1              ; MGTK Polygon "not last" flag
        lda     ($08),y
        beq     L99FC
        lda     $08
        adc     #kIconPolySize - 1
        sta     $08
        bcc     L9972
        inc     $09
        jmp     L9972

L99FC:  jsr     XdrawOutline

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
        jsr     FindTargetAndHighlight
        jmp     peek

L9A31:  COPY_BYTES 4, findwindow_params, coords2

        ;; Still over the highlighted icon?
        lda     highlight_icon_id
        beq     :+
        copy    window_id, findwindow_params::window_id
        ITK_DIRECT_CALL IconTK::FindIcon, findwindow_params
        lda     findwindow_params::which_area ; Icon ID
        cmp     highlight_icon_id             ; already over it?
        beq     :+

        ;; No longer over the highlighted icon - unhighlight it
        jsr     XdrawOutline
        jsr     UnhighlightIcon
        jsr     XdrawOutline
        lda     #0
        sta     highlight_icon_id

:       sub16   findwindow_params::mousex, coords1x, rect3_x1
        sub16   findwindow_params::mousey, coords1y, rect3_y1
        jsr     SetRect2ToRect1

        ldx     #0
        stx     L9C75
:       add16   rect1_x2,x, rect3_x1,x, rect1_x2,x
        add16   rect1_x1,x, rect3_x1,x, rect1_x1,x
        inx
        inx
        cpx     #4
        bne     :-

        lda     rect1_x1+1
        bmi     L9AF7
        cmp16   rect1_x2, #kScreenWidth
        bcs     L9AFE
        jsr     SetCoords1xToMousex
        bcc     L9B0E           ; always

L9AF7:  jsr     L9CAA
        bmi     L9B0E
        bpl     L9B03
L9AFE:  jsr     L9CD1
        bmi     L9B0E
L9B03:  jsr     SetRect1ToRect2AndZeroRect3X
        sec
        ror     L9C75
L9B0E:  lda     rect1_y1+1
        bmi     L9B31
        cmp16   rect1_y1, #kMenuBarHeight
        bcc     L9B31
        cmp16   rect1_y2, #kScreenHeight
        bcs     L9B38
        jsr     SetCoords1yToMousey
        bcc     L9B48           ; always

L9B31:  jsr     L9D31
        bmi     L9B48
        bpl     L9B3D
L9B38:  jsr     L9D58
        bmi     L9B48
L9B3D:  jsr     SetRect1ToRect2AndZeroRect3Y
        lda     L9C75
        ora     #$40
        sta     L9C75
L9B48:  bit     L9C75
        bpl     L9B52
        bvc     L9B52
        jmp     peek

L9B52:  jsr     XdrawOutline
        copy16  #drag_outline_buffer, $08
L9B60:  ldy     #2
L9B62:  add16in ($08),y, rect3_x1, ($08),y
        iny
        add16in ($08),y, rect3_y1, ($08),y
        iny
        cpy     #kIconPolySize
        bne     L9B62
        ldy     #1              ; MGTK Polygon "not last" flag
        lda     ($08),y
        beq     L9B9C
        lda     $08
        clc
        adc     #kIconPolySize
        sta     $08
        bcc     L9B60
        inc     $08+1
        bcs     L9B60

L9B9C:  jsr     XdrawOutline
        jmp     peek

L9BA5:  jsr     XdrawOutline
        lda     highlight_icon_id
        beq     :+
        jsr     UnhighlightIcon
        jmp     L9C63

:       MGTK_CALL MGTK::FindWindow, findwindow_params
        lda     findwindow_params::window_id
        cmp     window_id2
        beq     L9BE1
        bit     flag
        bmi     L9BDC
        lda     findwindow_params::window_id
        bne     L9BD4
L9BD1:  jmp     DragDetect::ignore_drag

L9BD4:  ora     #$80
        sta     highlight_icon_id
        bne     L9C63           ; always

L9BDC:  lda     window_id2
        beq     L9BD1
L9BE1:  jsr     PushPointers
        ldx     highlight_count
L9BF3:  dex
        bmi     L9C18
        txa
        pha
        ldy     highlight_list,x
        copylohi  icon_ptrs_low,y, icon_ptrs_high,y, $06
        jsr     CalcIconPoly
        lda     #0              ; don't redraw highlighted
        jsr     erase_icon
        pla
        tax
        bpl     L9BF3           ; always

L9C18:  jsr     PopPointers
        ldx     highlight_count
        copy16  #drag_outline_buffer, $08
L9C29:  dex
        bmi     L9C63
        ldy     highlight_list,x
        copylohi icon_ptrs_low,y, icon_ptrs_high,y, $06
        ldy     #IconEntry::win_flags
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
        lda     $08
        clc
        adc     #kIconPolySize
        sta     $08
        bcc     L9C29
        inc     $08+1
        bne     L9C29           ; always

L9C63:  lda     #0

just_select:                    ; ???
        tay
        jsr     PopPointers
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

.proc SetRect2ToRect1
        COPY_STRUCT MGTK::Rect, rect1, rect2
        rts
.endproc

.proc L9CAA
        lda     rect1_x1
        cmp     L9C7E
        bne     :+
        lda     rect1_x1+1
        eor     L9C7E+1
        bne     :+
        rts

:       lda     #0
        sec
        sbc     rect2_x1
        tax
        lda     #0
        sbc     rect2_x1 + 1
        tay
        jmp     L9CF5
.endproc

.proc L9CD1
        lda     rect1_x2
        cmp     const_screen_width
        bne     L9CE4
        lda     rect1_x2+1
        eor     const_screen_width+1
        bne     L9CE4
        rts
.endproc

L9CE4:  lda     #<kScreenWidth
        sec
        sbc     rect2_x2
        tax
        lda     #>kScreenWidth
        sbc     rect2_x2 + 1
        tay
L9CF5:  stx     rect3_x1
        sty     rect3_x1 + 1
        txa
        clc
        adc     rect2_x1
        sta     rect1_x1
        tya
        adc     rect2_x1 + 1
        sta     rect1_x1 + 1
        txa
        clc
        adc     rect2_x2
        sta     rect1_x2
        tya
        adc     rect2_x2 + 1
        sta     rect1_x2 + 1
        txa
        clc
        adc     coords1x
        sta     coords1x
        tya
        adc     coords1x + 1
        sta     coords1x + 1
        return  #$FF

.proc L9D31
        lda     rect1_y1
        cmp     L9C80
        bne     :+
        lda     rect1_y1+1
        eor     L9C80+1
        bne     :+
        rts

:       lda     #<kMenuBarHeight
        sec
        sbc     rect2_y1
        tax
        lda     #>kMenuBarHeight
        sbc     rect2_y1 + 1
        tay
        jmp     L9D7C
.endproc

.proc L9D58
        lda     rect1_y2
        cmp     const_screen_height
        bne     L9D6B
        lda     rect1_y2+1
        eor     const_screen_height+1
        bne     L9D6B
        rts
.endproc

L9D6B:  lda     #<(kScreenHeight-1)
        sec
        sbc     rect2_y2
        tax
        lda     #>(kScreenHeight-1)
        sbc     rect2_y2 + 1
        tay
L9D7C:  stx     rect3_y1
        sty     rect3_y1 + 1
        txa
        clc
        adc     rect2_y1
        sta     rect1_y1
        tya
        adc     rect2_y1 + 1
        sta     rect1_y1 + 1
        txa
        clc
        adc     rect2_y2
        sta     rect1_y2
        tya
        adc     rect2_y2 + 1
        sta     rect1_y2 + 1
        txa
        clc
        adc     coords1y
        sta     coords1y
        tya
        adc     coords1y + 1
        sta     coords1y + 1
        return  #$FF

.proc SetRect1ToRect2AndZeroRect3X
        ldx     #0
        beq     SetRectCommon
.endproc

.proc SetRect1ToRect2AndZeroRect3Y
        ldx     #rect2_y1 - rect2_x1
        FALL_THROUGH_TO SetRectCommon
.endproc

.proc SetRectCommon
        copy16  rect2_y1,x, rect1_y1,x
        copy16  rect2_y2,x, rect1_y2,x
        copy16  #0, rect3_y1,x
        rts
.endproc

.proc SetCoords1xToMousex
        lda     findwindow_params::mousex+1
        sta     coords1x+1
        lda     findwindow_params::mousex
        sta     coords1x
        rts
.endproc

.proc SetCoords1yToMousey
        lda     findwindow_params::mousey+1
        sta     coords1y+1
        lda     findwindow_params::mousey
        sta     coords1y
        rts
.endproc

.proc FindTargetAndHighlight
        bit     flag
        bpl     :+
        rts

:       jsr     PushPointers
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
        bne     done            ; scrollbar, etc.
                                ; else 0 = MGTK::Ctl::not_a_control
        ;; Ignore if y coord < window's header height
        MGTK_CALL MGTK::GetWinPtr, findwindow_params::window_id
        win_ptr := $06
        copy16  window_ptr, win_ptr
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + MGTK::Point::ycoord
        add16in (win_ptr),y, #kWindowHeaderHeight + 1, headery
        cmp16   findwindow_params::mousey, headery
        bcc     done
        bcs     find_icon       ; always

        ;; --------------------------------------------------
        ;; On desktop - A=0, note that as window_id
desktop:
        sta     findwindow_params::window_id

find_icon:
        ITK_DIRECT_CALL IconTK::FindIcon, findwindow_params
        ldx     findwindow_params::which_area ; Icon ID
        beq     done

        ;; Over an icon
        stx     icon_num

        ptr := $06
        copylohi icon_ptrs_low,x, icon_ptrs_high,x, ptr

        ;; Highlighted?
        ldy     #IconEntry::state
        lda     (ptr),y
        ;;and     #kIconEntryStateHighlighted
        .assert kIconEntryStateHighlighted = $40, error, "kIconEntryStateHighlighted must be $40"
        asl
        bmi     done            ; Not valid (it's being dragged)

        ;; Is it a drop target?
        ;;ldy     #IconEntry::win_flags
        .assert (IconEntry::win_flags - IconEntry::state) = 1, error, "win_flags must be 1 more than state"
        iny
        lda     (ptr),y
        ;;and     #kIconEntryFlagsDropTarget
        .assert kIconEntryFlagsDropTarget = $40, error, "kIconEntryFlagsDropTarget must be $40"
        asl
        bpl     done

        ;; Stash window for the future
        lsr
        and     #kIconEntryWinIdMask
        sta     window_id

        ;; Highlight it!
        lda     icon_num
        sta     highlight_icon_id
        jsr     XdrawOutline
        jsr     HighlightIcon
        jsr     XdrawOutline

done:   jsr     PopPointers     ; do not tail-call optimise!
        rts

icon_num:
        .byte   0

headery:
        .word   0
.endproc

;;; Input: A = icon number
;;; Output: A,X = address of IconEntry
.proc GetIconPtr
        tay
        ldx     icon_ptrs_high,y
        lda     icon_ptrs_low,y
        rts
.endproc

;;; Input: A = icon number
;;; Output: A = window id (0=desktop)
;;; Trashes $06
.proc GetIconWin
        ptr := $06

        jsr     GetIconPtr
        stax    ptr
        ldy     #IconEntry::win_flags
        lda     (ptr),y
        and     #kIconEntryWinIdMask
        rts
.endproc

.proc XdrawOutline
        MGTK_CALL MGTK::SetPort, drag_outline_grafport
        MGTK_CALL MGTK::FramePoly, drag_outline_buffer
        rts
.endproc

.proc HighlightIcon
        jsr SetPortForHighlightIcon
        ITK_DIRECT_CALL IconTK::HighlightIcon, highlight_icon_id
        ITK_DIRECT_CALL IconTK::DrawIcon, highlight_icon_id
        MGTK_CALL MGTK::InitPort, icon_grafport
        rts
.endproc

.proc UnhighlightIcon
        jsr SetPortForHighlightIcon
        ITK_DIRECT_CALL IconTK::UnhighlightIcon, highlight_icon_id
        ITK_DIRECT_CALL IconTK::DrawIcon, highlight_icon_id
        MGTK_CALL MGTK::InitPort, icon_grafport
        rts
.endproc

;;; Set cliprect to `highlight_icon_id`'s window's content area, in screen
;;; space, using `icon_grafport`.
.proc SetPortForHighlightIcon
        ptr := $06

        lda     highlight_icon_id
        jsr     GetIconWin
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params ; into icon_grafport

        sub16   icon_grafport::cliprect::x2, icon_grafport::cliprect::x1, width
        sub16   icon_grafport::cliprect::y2, icon_grafport::cliprect::y1, height

        COPY_STRUCT MGTK::Point, icon_grafport::viewloc, icon_grafport::cliprect

        add16   icon_grafport::cliprect::x1, width, icon_grafport::cliprect::x2
        add16   icon_grafport::cliprect::y1, height, icon_grafport::cliprect::y2

        ;; Account for window header, and set port to icon_grafport
        jmp     ShiftPortDown

width:  .word   0
height: .word   0

.endproc


.endproc

;;; ============================================================
;;; UnhighlightIcon

;;; param is pointer to IconEntry

.proc UnhighlightIconImpl
        params := $06
.struct UnhighlightIconParams
        icon    .byte
.endstruct

        ptr := $06              ; Overwrites params

        ;; Pointer to IconEntry
        ldy     #UnhighlightIconParams::icon
        lda     (params),y
        tax
        copylohi icon_ptrs_low,x, icon_ptrs_high,x, ptr

        ;;ldy     #IconEntry::state
        .assert (IconEntry::state - UnhighlightIconParams::icon) = 1, error, "state must be 1 more than icon"
        iny
        lda     (ptr),y         ; valid icon?
        bne     :+
        return  #2              ; Invalid icon
:
        ;;and     #kIconEntryStateHighlighted
        .assert kIconEntryStateHighlighted = $40, error, "kIconEntryStateHighlighted must be $40"
        asl
        bmi     :+
        return  #3              ; Not highlighted
:
        ;; Mark not highlighted
        ror
        eor     #kIconEntryStateHighlighted
        sta     (ptr),y

        ;;ldy     #IconEntry::id
        .assert (IconEntry::state - IconEntry::id) = 1, error, "id must be 1 less than state"
        dey
        lda     (ptr),y
        jmp     RemoveFromHighlightList
.endproc

;;; ============================================================
;;; IconInRect

.proc IconInRectImpl
        params := $06
.struct IconInRectParams
        icon    .byte
        rect    .tag    MGTK::Rect
.endstruct

        ptr := $06

        jmp     start

icon:   .byte   0
        DEFINE_RECT rect, 0, 0, 0, 0

        ;; Copy params to local data
start:  ldy     #IconInRectParams::icon
        lda     (params),y
        sta     icon

        ldy     #IconInRectParams::rect + .sizeof(MGTK::Rect)-1
:       lda     (params),y
        sta     rect-1,y
        dey
        bne     :-

        ldx     icon
        copylohi icon_ptrs_low,x, icon_ptrs_high,x, ptr
        jsr     CalcIconPoly

        ;; Compare the rect against both the bitmap bbox and text bbox
        ;; See vertex diagram in CalcIconPoly

        ;; Bitmap's bbox: v0-v1-v2-v7

        ;; top of bitmap > bottom of rect --> outside
        scmp16  rect::y2, poly::v0::ycoord
        bmi     :+

        ;; left of bitmap > right of rect --> outside
        scmp16  rect::x2, poly::v0::xcoord
        bmi     :+

        ;; bottom of bitmap < top of rect --> outside
        scmp16  poly::v2::ycoord, rect::y1
        bmi     :+

        ;; right of bitmap < left of rect --> outside
        scmp16  poly::v1::xcoord, rect::x1
        bpl     inside

        ;; Text's bbox: v6-v3-v4-v5
:
        ;; top of text > bottom of rect --> outside
        scmp16  rect::y2, poly::v6::ycoord
        bmi     outside

        ;; left of text > right of rect --> outside
        scmp16  rect::x2, poly::v6::xcoord
        bmi     outside

        ;; bottom of text < top of rect --> outside
        scmp16  poly::v4::ycoord, rect::y1
        bmi     outside

        ;; right of text < left of rect --> outside
        scmp16  poly::v3::xcoord, rect::x1
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

dimmed_flag:  ; non-zero if dimmed volume/dir
        .byte   0

more_drawing_needed_flag:
        .byte   0

        DEFINE_POINT label_pos, 0, 0

no_clip_vol_icons_flag:
        .byte   0

.proc PaintIcon

unhighlighted:
        lda     #0
        sta     icon_flags
        beq     common          ; always

highlighted:
        copy    #$80, icon_flags ; is highlighted

common:
        ;; Test if icon is dimmed volume/folder
        ldy     #IconEntry::win_flags
        lda     ($06),y
        and     #kIconEntryFlagsDimmed
        sta     dimmed_flag

        lda     ($06),y
        and     #kIconEntryWinIdMask
        bne     :+

        ;;  Mark as "volume icon" on desktop (needs background)
        lda     icon_flags
        ora     #$40
        sta     icon_flags

        ;; copy icon entry coords and bits
        ;;ldy     #IconEntry::iconx
        .assert (IconEntry::iconx - IconEntry::win_flags) = 1, error, "iconx must be 1 more than win_flags"
:       iny
        lda     ($06),y
        sta     icon_paintbits_params::viewloc-IconEntry::iconx,y
        sta     mask_paintbits_params::viewloc-IconEntry::iconx,y
        cpy     #IconEntry::iconx + 5 ; x/y/bits
        bne     :-

        jsr     PushPointers

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
        jsr     PopPointers

        ;; Copy, pad, and measure name
        jsr     PrepareName

        ;; Center horizontally
        ;;  text_left = icon_left + icon_width/2 - text_width/2
        ;;            = (icon_left*2 + icon_width - text_width) / 2
        lda     icon_paintbits_params::viewloc::xcoord ; = icon_left
        asl ; *= 2
        tax
        lda     icon_paintbits_params::viewloc::xcoord + 1
        rol
        tay
        txa
        clc
        adc     icon_paintbits_params::maprect::x2 ; += icon_width
        tax
        tya
        adc     icon_paintbits_params::maprect::x2 + 1
        tay
        txa
        sec
        sbc     textwidth_params::result ; -= text_width
        sta     moveto_params2::xcoord
        tya
        sbc     textwidth_params::result + 1
        sta     moveto_params2::xcoord + 1
        rol
        ror     moveto_params2::xcoord + 1 ; /= 2 - signed!
        ror     moveto_params2::xcoord

        ;; Align vertically
        lda     icon_paintbits_params::viewloc::ycoord
        sec ; + 1
        adc     icon_paintbits_params::maprect::y2
        tax
        lda     icon_paintbits_params::viewloc::ycoord + 1
        adc     icon_paintbits_params::maprect::y2 + 1
        sta     moveto_params2::ycoord + 1
        txa
        clc
        adc     font_height
        sta     moveto_params2::ycoord
        bcc     :+
        inc     moveto_params2::ycoord + 1
:

        COPY_STRUCT MGTK::Point, moveto_params2, label_pos

        bit     icon_flags      ; volume icon (on desktop) ?
        bvc     DoPaint         ; nope
        bit     no_clip_vol_icons_flag
        bmi     DoPaint
        ;; TODO: This depends on a previous proc having adjusted
        ;; the grafport (for window maprect and window's items/used/free bar)

        ;; Volume (i.e. icon on desktop)
        MGTK_CALL MGTK::InitPort, grafport
        jsr     SetPortForVolIcon
:       jsr     CalcWindowIntersections
        jsr     DoPaint
        lda     more_drawing_needed_flag
        bne     :-
        MGTK_CALL MGTK::SetPortBits, grafport ; default maprect
        rts

.proc DoPaint
        MGTK_CALL MGTK::HideCursor

        ;; --------------------------------------------------
        ;; Icon

        ;; Shade (XORs background)
        lda     dimmed_flag
        beq     :+
        jsr     CalcDimmedRect
        jsr     Shade

        ;; Mask (cleared to white or black)
:       MGTK_CALL MGTK::SetPenMode, penOR
        bit     icon_flags
        bpl     :+
        MGTK_CALL MGTK::SetPenMode, penBIC
:       MGTK_CALL MGTK::PaintBits, mask_paintbits_params

        ;; Shade again (restores background)
        lda     dimmed_flag
        beq     :+
        jsr     Shade

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

.proc Shade
        MGTK_CALL MGTK::SetPattern, dark_pattern
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, rect_dimmed

done:   rts
.endproc

.endproc

;;; ============================================================

.proc CalcDimmedRect
        ldx     #0
:       add16   icon_paintbits_params::viewloc,x, icon_paintbits_params::maprect::topleft,x, rect_dimmed::topleft,x
        add16   icon_paintbits_params::viewloc,x, icon_paintbits_params::maprect::bottomright,x, rect_dimmed::bottomright,x
        inx
        inx
        cpx     #.sizeof(MGTK::Point)
        bne     :-
        rts
.endproc

.endproc ; PaintIcon
        paint_icon_unhighlighted := PaintIcon::unhighlighted
        paint_icon_highlighted := PaintIcon::highlighted


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

.proc CalcIconPoly
        entry_ptr := $6
        bitmap_ptr := $8

        jsr     PushPointers

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
        ;;ldy     #IconDefinition::maprect + MGTK::Rect::y2
        .assert (MGTK::Rect::y2 - MGTK::Rect::x2) = 2, error, "y2 must be 2 more than x2"
        iny
        add16in (bitmap_ptr),y, poly::v0::ycoord, poly::v2::ycoord
;;xxx
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
        ;;clc
        adc     poly::v2::ycoord
        sta     poly::v4::ycoord
        sta     poly::v5::ycoord
        lda     poly::v2::ycoord+1
        adc     #0
        sta     poly::v4::ycoord+1
        sta     poly::v5::ycoord+1

        ;; Copy, pad, and measure name
        jsr     PrepareName

        ;; Center horizontally

        ldy     #IconDefinition::maprect + MGTK::Rect::x2
        copy16in (bitmap_ptr),y, icon_width

        ;; Left edge of label (v5, v6)
        ;;  text_left = icon_left + icon_width/2 - text_width/2
        ;;            = (icon_left*2 + icon_width - text_width) / 2
        ;; NOTE: Left is computed before right to match rendering code
;;xxx
        copy16  poly::v0::xcoord, poly::v5::xcoord
        asl16   poly::v5::xcoord
        add16   poly::v5::xcoord, icon_width, poly::v5::xcoord
        sub16   poly::v5::xcoord, textwidth_params::result, poly::v5::xcoord
        asr16   poly::v5::xcoord ; signed
        copy16  poly::v5::xcoord, poly::v6::xcoord

        ;; Right edge of label (v3, v4)
        add16   poly::v5::xcoord, textwidth_params::result, poly::v3::xcoord
        copy16  poly::v3::xcoord, poly::v4::xcoord

        jsr     PopPointers     ; do not tail-call optimise!
        rts

icon_width:  .word   0
text_width:  .word   0

.endproc

;;; Copy name from IconEntry (ptr $06) to text_buffer,
;;; with leading/trailing spaces, and measure it.

.proc PrepareName
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
;;; RedrawDesktopIcons

.proc RedrawDesktopIconsImpl
        ;; No params

        ptr := $06

        jsr     PushPointers

        copy    #$80, no_clip_vol_icons_flag

        ldax    #mapinfo
        jsr     GetPortBits

        ldx     num_icons
loop:   dex
        bmi     done
        txa
        pha

        ldy     icon_list,x
        sty     icon

        ;; Is it an icon on the desktop?
        copylohi icon_ptrs_low,y, icon_ptrs_high,y, ptr
        ldy     #IconEntry::win_flags
        lda     (ptr),y
        and     #kIconEntryWinIdMask ; desktop icon
        bne     next                 ; no, skip it

        ;; In cliprect?
        ITK_DIRECT_CALL IconTK::IconInRect, icon
        beq     next            ; no, skip it

        ITK_DIRECT_CALL IconTK::DrawIcon, icon

next:   pla
        tax
        bpl     loop            ; always

done:   copy    #0, no_clip_vol_icons_flag
        jsr     PopPointers     ; do not tail-call optimise!
        rts

        ;; GetPortBits params
mapinfo:
        .tag    MGTK::MapInfo

        ;; IconTK::DrawIcon and IconTK::IconInRect params
icon    := mapinfo + MGTK::MapInfo::maprect - 1
rect    := mapinfo + MGTK::MapInfo::maprect

.endproc

;;; ============================================================
;;; A = icon number to move
;;; X = position in highlight list

.proc ChangeIconIndex
        stx     new_pos
        sta     icon_num

        ;; Find position of icon in icon table
        ldx     #0
:       lda     icon_list,x
        cmp     icon_num
        beq     :+
        inx
        cpx     num_icons
        bne     :-
        rts

        ;; Shift items down
:       lda     icon_list+1,x
        sta     icon_list,x
        inx
        cpx     num_icons
        bne     :-

        ;; Shift items up
        ldx     num_icons
:       cpx     new_pos
        beq     place
        lda     icon_list-2,x
        sta     icon_list-1,x
        dex
        jmp     :-

        ;; Place at new position
place:  ldx     new_pos
        lda     icon_num
        sta     icon_list-1,x
        rts

new_pos:        .byte   0
icon_num:       .byte   0
.endproc

;;; ============================================================
;;; A = icon number to move
;;; X = new position in highlight list

.proc ChangeHighlightIndex
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
;;; Remove icon from highlight list. Does not update icon's state.
;;; Inputs: A=icon id
.proc RemoveFromHighlightList

        ;; Move it to the end of the highlight list
        ldx     highlight_count ; new position
        jsr     ChangeHighlightIndex

        ;; Remove it from the highlight list
        dec     highlight_count
        lda     #0
        ldx     highlight_count
        sta     highlight_list,x

        rts
.endproc

;;; ============================================================
;;; Erase an icon; redraws overlapping icons as needed

erase_icon:
        sta     redraw_highlighted_flag
        MGTK_CALL MGTK::InitPort, icon_grafport
        MGTK_CALL MGTK::SetPort, icon_grafport
        jmp     LA3B9

        ;; For `RedrawIconsAfterErase`
redraw_highlighted_flag:
        .byte   0
LA3AC:  .byte   0
window_id:  .byte   0

        ;; IconTK::DrawIcon params
        ;; IconTK::IconInRect params (in `RedrawIconsAfterErase`)
icon:   .byte   0
icon_rect:
        .tag    MGTK::Rect

icon_in_window_flag:
        .byte   0

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
        and     #kIconEntryWinIdMask
        sta     window_id
        beq     volume

        ;; File (i.e. icon in window)
        copy    #$80, icon_in_window_flag
        MGTK_CALL MGTK::SetPattern, white_pattern
        MGTK_CALL MGTK::FrontWindow, frontwindow_params ; Use window's port
        lda     frontwindow_params::window_id
        sta     getwinport_params::window_id
        MGTK_CALL MGTK::GetWinPort, getwinport_params
        bne     ret             ; obscured!
        jsr     offset_icon_poly
        jsr     ShiftPortDown ; Further offset by window's items/used/free bar
        jsr     EraseWindowIcon
        jmp     RedrawIconsAfterErase
ret:    rts

        ;; Volume (i.e. icon on desktop)
volume:
        MGTK_CALL MGTK::InitPort, grafport
        jsr     SetPortForVolIcon
:       jsr     CalcWindowIntersections
        jsr     EraseDesktopIcon
        lda     more_drawing_needed_flag
        bne     :-
        MGTK_CALL MGTK::SetPortBits, grafport ; default maprect
        jmp     RedrawIconsAfterErase
.endproc

;;; ============================================================

.proc EraseDesktopIcon
        lda     #0
        sta     icon_in_window_flag

        MGTK_CALL MGTK::GetDeskPat, addr
        MGTK_CALL MGTK::SetPattern, 0, addr
        FALL_THROUGH_TO EraseWindowIcon
.endproc

.proc EraseWindowIcon
        ;; Construct a bounding rect from the icon's polygon.
        ;; Used in `RedrawIconsAfterErase`
        copy16  poly::v0::ycoord, icon_rect + MGTK::Rect::y1
        copy16  poly::v5::ycoord, icon_rect + MGTK::Rect::y2

        ;; Use lower of v6, v0
        scmp16  poly::v6::xcoord, poly::v0::xcoord
    IF_NEG
        copy16  poly::v6::xcoord, icon_rect + MGTK::Rect::x1
    ELSE
        copy16  poly::v0::xcoord, icon_rect + MGTK::Rect::x1
    END_IF

        ;; Use higher of v1, v3
        scmp16  poly::v3::xcoord, poly::v1::xcoord
    IF_POS
        copy16  poly::v3::xcoord, icon_rect + MGTK::Rect::x2
    ELSE
        copy16  poly::v1::xcoord, icon_rect + MGTK::Rect::x2
    END_IF

        MGTK_CALL MGTK::PaintPoly, poly
        rts
.endproc

;;; ============================================================
;;; After erasing an icon, redraw any overlapping icons

.proc RedrawIconsAfterErase
        ptr := $8

        jsr     PushPointers
        ldx     num_icons
loop:   dex                     ; any icons to draw?

        bpl     LA466

        bit     icon_in_window_flag
        bpl     :+
        ;; TODO: Is this restoration necessary?
        MGTK_CALL MGTK::InitPort, icon_grafport
        MGTK_CALL MGTK::SetPort, icon_grafport
:       jsr     PopPointers     ; do not tail-call optimise!
        rts

LA466:  txa
        pha
        ldy     icon_list,x
        cpy     LA3AC
        beq     next

        copylohi icon_ptrs_low,y, icon_ptrs_high,y, ptr

        ;; Same window?
        ldy     #IconEntry::win_flags
        lda     (ptr),y
        and     #kIconEntryWinIdMask
        cmp     window_id
        bne     next

        bit     redraw_highlighted_flag
    IF_NC
        ldy     #IconEntry::state
        lda     (ptr),y
        and     #kIconEntryStateHighlighted
        bne     next
    END_IF

        ldy     #IconEntry::id ; icon num
        lda     (ptr),y
        sta     icon
        bit     icon_in_window_flag ; windowed?
        bpl     :+           ; nope, desktop
        jsr     offset_icon_do  ; yes, adjust rect
:       ITK_DIRECT_CALL IconTK::IconInRect, icon
        beq     :+

        ITK_DIRECT_CALL IconTK::DrawIcon, icon

:       bit     icon_in_window_flag
        bpl     next
        lda     icon
        jsr     offset_icon_undo

next:   pla
        tax
        bpl     loop
.endproc

;;; ============================================================
;;; Offset coordinates for windowed icons

.proc OffsetIcon

offset_flags:  .byte   0        ; bit 7 = offset poly, bit 6 = undo offset, otherwise do offset

        DEFINE_POINT vl_offset, 0, 0
        DEFINE_POINT mr_offset, 0, 0

entry_poly:
        copy    #$80, offset_flags
        bmi     LA4E2           ; always

entry_do:
        pha
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
        bmi     OffsetPoly
        bvc     DoOffset
        jmp     UndoOffset

.proc OffsetPoly
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

.proc DoOffset
        ptr := $06

        pla
        tay
        jsr     PushPointers
        copylohi icon_ptrs_low,y, icon_ptrs_high,y, ptr
        ldy     #IconEntry::iconx
        add16in (ptr),y, vl_offset::xcoord, (ptr),y ; iconx += viewloc::xcoord
        iny
        add16in (ptr),y, vl_offset::ycoord, (ptr),y ; icony += viewloc::xcoord
        ldy     #IconEntry::iconx
        sub16in (ptr),y, mr_offset::xcoord, (ptr),y ; icony -= maprect::left
        iny
        sub16in (ptr),y, mr_offset::ycoord, (ptr),y ; icony -= maprect::top
        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc

.proc UndoOffset
        ptr := $06

        pla
        tay
        jsr     PushPointers
        copylohi icon_ptrs_low,y, icon_ptrs_high,y, ptr
        ldy     #IconEntry::iconx
        sub16in (ptr),y, vl_offset::xcoord, (ptr),y ; iconx -= viewloc::xcoord
        iny
        sub16in (ptr),y, vl_offset::ycoord, (ptr),y ; icony -= viewloc::xcoord
        ldy     #IconEntry::iconx
        add16in (ptr),y, mr_offset::xcoord, (ptr),y ; iconx += maprect::left
        iny
        add16in (ptr),y, mr_offset::ycoord, (ptr),y ; icony += maprect::top
        jsr     PopPointers     ; do not tail-call optimise!
        rts
.endproc

.endproc
        offset_icon_poly := OffsetIcon::entry_poly
        offset_icon_do := OffsetIcon::entry_do
        offset_icon_undo := OffsetIcon::entry_undo

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

.proc SetPortForVolIcon
        jsr     CalcIconPoly

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
        ldx     poly::v0::xcoord
        ldy     poly::v0::xcoord + 1
        cpx     poly::v5::xcoord
        tya
        sbc     poly::v5::xcoord + 1
        bcc     :+
        ldx     poly::v5::xcoord
        ldy     poly::v5::xcoord + 1
:       stx     portbits::cliprect::x1
        stx     portbits::viewloc::xcoord
        sty     portbits::cliprect::x1+1
        sty     portbits::viewloc::xcoord+1

        ;; Set up bounds_b
        lda     poly::v4::ycoord
        sta     bounds_b
        sta     portbits::cliprect::y2
        lda     poly::v4::ycoord+1
        sta     bounds_b+1
        sta     portbits::cliprect::y2+1

        ;; Set up bounds_r
        ldx     poly::v1::xcoord
        ldy     poly::v1::xcoord + 1
        cpx     poly::v3::xcoord
        tya
        sbc     poly::v3::xcoord + 1
        bcs     :+
        ldx     poly::v3::xcoord
        ldy     poly::v3::xcoord + 1
:
        ;; if (bounds_r > kScreenWidth - 1) bounds_r = kScreenWidth - 1
        cpx     #<(kScreenWidth - 1)
        tya
        sbc     #>(kScreenWidth - 1)
        bmi     done
        ldx     #<(kScreenWidth - 1)
        ldy     #>(kScreenWidth - 1)

done:   stx     bounds_r
        sty     bounds_r+1
        stx     portbits::cliprect::x2
        sty     portbits::cliprect::x2+1
        MGTK_CALL MGTK::SetPortBits, portbits
        rts
.endproc

;;; ============================================================

.proc CalcWindowIntersections
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
        ldx     cr_r
        ldy     cr_r+1
        inx
        stx     cr_l
        stx     vx
        bne     :+
        iny
:       sty     cr_l+1
        sty     vx+1

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
        eor     #4
        bne     do_pt
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
        asl
        lda     #0
        rol
        sta     more_drawing_needed_flag
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
        scmp16  cr_r, win_r
        bmi     case789

        ldx     win_r
        ldy     win_r + 1
        inx
        bne     :+
        iny
:       stx     cr_r
        sty     cr_r + 1
        jmp     vert

        ;; Cases 7/8/9 (and done)
        ;; if (win_l > cr_l)
        ;; . cr_r = win_l
case789:
        scmp16  win_l, cr_l
        bmi     vert

        copy16  win_l, cr_r
        jmp     reclip

        ;; Cases 3/6 (and done)
        ;; if (win_t > cr_t)
        ;; . cr_b = win_t
vert:   scmp16  win_t, cr_t
        bmi     :+

        copy16  win_t, cr_b
        copy    #1, more_drawing_needed_flag
        jmp     reclip

        ;; Cases 1/4 (and done)
        ;; if (win_b < cr_b)
        ;; . cr_t = win_b + 2
        ;; . vy   = win_b + 2
:       scmp16  win_b, cr_b
        bpl     case2

        ldx     win_b
        ldy     win_b+1
        inx
        stx     cr_t
        stx     vy
        bne     :+
        iny
:       sty     cr_t+1
        sty     vy+1
        copy    #1, more_drawing_needed_flag
        jmp     reclip

        ;; Case 2
        ;; if (win_r < stash_r)
        ;; . cr_l = win_r + 2
        ;; . vx   = win_r + 2
        ;; . cr_r = stash_r + 2 (workaround for https://github.com/a2stuff/a2d/issues/153)
case2:
        scmp16  win_r, stash_r
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
        ldx     bounds_r
        ldy     bounds_r + 1
        inx
        bne     :+
        iny
:       stx     cr_l
        sty     cr_l + 1
        jmp     set_bits
.endproc

;;; ============================================================

.proc ShiftPortDown
        ;; For window's items/used/free space bar
        kOffset = kWindowHeaderHeight + 1

        add16   icon_grafport::viewloc::ycoord, #kOffset, icon_grafport::viewloc::ycoord
        add16   icon_grafport::cliprect::y1, #kOffset, icon_grafport::cliprect::y1
        MGTK_CALL MGTK::SetPort, icon_grafport
        rts
.endproc

.endscope ; icon_toolkit

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
        .byte   PX(%0000000),PX(%0000111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000000),PX(%0111000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100)
        .byte   PX(%0000011),PX(%1000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100)
        .byte   PX(%0011100),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100)
        .byte   PX(%1100000),PX(%0000111),PX(%1100011),PX(%1100110),PX(%0000110),PX(%0001100)
        .byte   PX(%1100000),PX(%0000110),PX(%0110110),PX(%0110111),PX(%1011110),PX(%0001100)
        .byte   PX(%1100000),PX(%0000111),PX(%1100111),PX(%1110110),PX(%1110110),PX(%0001100)
        .byte   PX(%1100000),PX(%0000110),PX(%0110110),PX(%0110110),PX(%0000110),PX(%0001100)
        .byte   PX(%1100000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0000000),PX(%0001100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1110011),PX(%0011001),PX(%1001100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0110011),PX(%0011001),PX(%1001100)
        .byte   PX(%0000000),PX(%0000000),PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111100)

ramdisk_mask:
        .byte   PX(%0000000),PX(%0000111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000011),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
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
label_duplicate_icon:
        PASCAL_STRING res_string_menu_item_duplicate ; menu item

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
        DEFINE_MENU_ITEM label_duplicate_icon, 'D'
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
        kMenuItemIdDuplicate   = 9
        ;; --------------------
        kMenuItemIdCopyFile    = 11
        kMenuItemIdDeleteFile  = 12
        ;; --------------------
        kMenuItemIdQuit        = 14

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

        ;; Rects
        kPromptDialogWidth = 400
        kPromptDialogHeight = 107
        kPromptDialogLeft = (kScreenWidth - kPromptDialogWidth) / 2
        kPromptDialogTop  = (kScreenHeight - kPromptDialogHeight) / 2

        DEFINE_RECT_FRAME confirm_dialog_frame_rect, kPromptDialogWidth, kPromptDialogHeight

        DEFINE_BUTTON ok,     res_string_button_ok, 260, kPromptDialogHeight-19
        DEFINE_BUTTON cancel, res_string_button_cancel,   40, kPromptDialogHeight-19
        DEFINE_BUTTON yes,    res_string_prompt_button_yes, 200, kPromptDialogHeight-19,40,kButtonHeight
        DEFINE_BUTTON no,     res_string_prompt_button_no,  260, kPromptDialogHeight-19,40,kButtonHeight
        DEFINE_BUTTON all,    res_string_prompt_button_all, 320, kPromptDialogHeight-19,40,kButtonHeight

textbg_black:  .byte   $00
textbg_white:  .byte   $7F

;;; ============================================================

kDialogLabelHeight      = kSystemFontHeight
kDialogLabelBaseY       = 30
kDialogLabelRow1        = kDialogLabelBaseY + kDialogLabelHeight * 1
kDialogLabelRow2        = kDialogLabelBaseY + kDialogLabelHeight * 2
kDialogLabelRow3        = kDialogLabelBaseY + kDialogLabelHeight * 3
kDialogLabelRow4        = kDialogLabelBaseY + kDialogLabelHeight * 4
kDialogLabelRow5        = kDialogLabelBaseY + kDialogLabelHeight * 5
kDialogLabelRow6        = kDialogLabelBaseY + kDialogLabelHeight * 6

;;; ============================================================
;;; Prompt dialog resources

        kPromptDialogInsetLeft   = 8
        kPromptDialogInsetTop    = 25
        kPromptDialogInsetRight  = 8
        kPromptDialogInsetBottom = 20
        DEFINE_RECT clear_dialog_labels_rect, kPromptDialogInsetLeft, kPromptDialogInsetTop, kPromptDialogWidth-kPromptDialogInsetRight, kPromptDialogHeight-kPromptDialogInsetBottom

        ;; Offset cliprect for drawing labels within dialog
        ;; Coordinates are unchanged, but clipping rect is set
        ;; to `clear_dialog_labels_rect` so labels don't overflow.
.params prompt_dialog_labels_mapinfo
        DEFINE_POINT viewloc, kPromptDialogLeft+kPromptDialogInsetLeft, kPromptDialogTop+kPromptDialogInsetTop
        .addr   MGTK::screen_mapbits
        .byte   MGTK::screen_mapwidth
        .byte   0
        DEFINE_RECT maprect, kPromptDialogInsetLeft, kPromptDialogInsetTop, kPromptDialogWidth-kPromptDialogInsetRight, kPromptDialogHeight-kPromptDialogInsetBottom
.endparams

        DEFINE_RECT prompt_rect, 40, kDialogLabelRow5+1, 360, kDialogLabelRow6
        DEFINE_POINT current_target_file_pos, 75, kDialogLabelRow2
        DEFINE_POINT current_dest_file_pos, 75, kDialogLabelRow3
        DEFINE_RECT current_target_file_rect, 75, kDialogLabelRow1+1, kPromptDialogWidth - kPromptDialogInsetRight, kDialogLabelRow2
        DEFINE_RECT current_dest_file_rect, 75, kDialogLabelRow2+1, kPromptDialogWidth - kPromptDialogInsetRight, kDialogLabelRow3

;;; ============================================================
;;; "About" dialog resources

kAboutDialogWidth       = 400
kAboutDialogHeight      = 120

        DEFINE_RECT_FRAME about_dialog_frame_rect, kAboutDialogWidth, kAboutDialogHeight

str_about1:  PASCAL_STRING kDeskTopProductName
str_about2:  PASCAL_STRING res_string_copyright_line1
str_about3:  PASCAL_STRING res_string_copyright_line2
str_about4:  PASCAL_STRING res_string_copyright_line3
str_about5:  PASCAL_STRING res_string_about_text_line5
str_about6:  PASCAL_STRING res_string_about_text_line6
str_about7:  PASCAL_STRING res_string_about_text_line7
str_about8:  PASCAL_STRING kBuildDate
str_about9:  PASCAL_STRING .sprintf(res_string_noprod_version_format_long,::kDeskTopVersionMajor,::kDeskTopVersionMinor,kDeskTopVersionSuffix)

        ;; "Copy File" dialog strings
str_copy_title:
        PASCAL_STRING res_string_copy_dialog_title ; dialog title
str_copy_copying:
        PASCAL_STRING res_string_copy_label_status
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

        DEFINE_POINT delete_remaining_count_pos, 204, kDialogLabelRow4

        ;; "New Folder" dialog strings
str_in:
        PASCAL_STRING res_string_new_folder_label_in
str_enter_folder_name:
        PASCAL_STRING res_string_new_folder_label_name

        ;; "Rename Icon" dialog strings
str_rename_old:
        PASCAL_STRING res_string_rename_label_old
str_rename_new:
        PASCAL_STRING res_string_rename_label_new

        ;; "Duplicate" dialog strings
str_duplicate_original:
        PASCAL_STRING res_string_rename_label_original

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
str_info_yes:
        PASCAL_STRING res_string_get_info_label_yes
str_info_no:
        PASCAL_STRING res_string_get_info_label_no

        DEFINE_POINT unlock_remaining_count_pos, 205, kDialogLabelRow4
        DEFINE_POINT lock_remaining_count_pos, 195, kDialogLabelRow4

str_select_format:
        PASCAL_STRING res_string_format_disk_label_select
str_new_volume:
        PASCAL_STRING res_string_format_disk_label_enter_name
str_confirm_format_prefix:
        PASCAL_STRING res_string_format_disk_prompt_format_prefix
str_confirm_format_suffix:
        PASCAL_STRING res_string_format_disk_prompt_format_suffix
str_formatting:
        PASCAL_STRING res_string_format_disk_status_formatting
str_formatting_error:
        PASCAL_STRING res_string_format_disk_error

str_select_erase:
        PASCAL_STRING res_string_erase_disk_label_select
str_confirm_erase_prefix:
        PASCAL_STRING res_string_erase_disk_prompt_erase_prefix
str_confirm_erase_suffix:
        PASCAL_STRING res_string_erase_disk_prompt_erase_suffix
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

.proc AlertById
        jmp     start

;;; --------------------------------------------------
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
err_E0:  PASCAL_STRING res_string_warning_insert_system_disk
err_E1:  PASCAL_STRING res_string_warning_selector_list_full
;;; The same string is used for both of these cases as the second case
;;; (a single directory with too many items) is very difficult to hit.
;;; alt: `res_string_warning_too_many_files` for E3
err_E2:
err_E3:  PASCAL_STRING res_string_warning_window_must_be_closed
err_E4:  PASCAL_STRING res_string_warning_too_many_windows
err_E5:  PASCAL_STRING res_string_warning_save_changes

err_F5:  PASCAL_STRING res_string_errmsg_F5
err_F6:  PASCAL_STRING res_string_errmsg_F6
err_F7:  PASCAL_STRING res_string_errmsg_F7
err_F8:  PASCAL_STRING res_string_errmsg_F8
err_F9:  PASCAL_STRING res_string_errmsg_F9
err_FA:  PASCAL_STRING res_string_errmsg_FA
err_FB:  PASCAL_STRING res_string_errmsg_FB
err_FC:  PASCAL_STRING res_string_errmsg_FC
err_FD:  PASCAL_STRING res_string_errmsg_FD
err_FE:  PASCAL_STRING res_string_errmsg_FE

        ;; number of alert messages
        kNumAlerts = 30

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
        .byte   kErrInsertSystemDisk, kErrSelectorListFull, kErrWindowMustBeClosed
        .byte   kErrTooManyFiles, kErrTooManyWindows, kErrSaveChanges
        .byte   kErrBadReplacement, kErrUnsupportedFileType, kErrNoWindowsOpen
        .byte   kErrMoveCopyIntoSelf
        .byte   kErrDuplicateVolName, kErrFileNotOpenable, kErrNameTooLong
        .byte   kErrInsertSrcDisk, kErrInsertDstDisk, kErrBasicSysNotFound
        ASSERT_TABLE_SIZE alert_table, kNumAlerts

        ;; alert index to string address
message_table_low:
        .byte   <err_00,<err_27,<err_28,<err_2B,<err_40,<err_44,<err_45,<err_46
        .byte   <err_47,<err_48,<err_49,<err_4E,<err_52,<err_57
        .byte   <err_E0, <err_E1, <err_E2, <err_E3, <err_E4, <err_E5
        .byte   <err_F5,<err_F6,<err_F7,<err_F8,<err_F9,<err_FA
        .byte   <err_FB,<err_FC,<err_FD,<err_FE
        ASSERT_TABLE_SIZE message_table_low, kNumAlerts

message_table_high:
        .byte   >err_00,>err_27,>err_28,>err_2B,>err_40,>err_44,>err_45,>err_46
        .byte   >err_47,>err_48,>err_49,>err_4E,>err_52,>err_57
        .byte   >err_E0, >err_E1, >err_E2, >err_E3, >err_E4, >err_E5
        .byte   >err_F5,>err_F6,>err_F7,>err_F8,>err_F9,>err_FA
        .byte   >err_FB,>err_FC,>err_FD,>err_FE
        ASSERT_TABLE_SIZE message_table_high, kNumAlerts

alert_options_table:
        .byte   AlertButtonOptions::Ok             ; dummy
        .byte   AlertButtonOptions::Ok             ; ERR_IO_ERROR
        .byte   AlertButtonOptions::Ok             ; ERR_DEVICE_NOT_CONNECTED
        .byte   AlertButtonOptions::TryAgainCancel ; ERR_WRITE_PROTECTED
        .byte   AlertButtonOptions::Ok             ; ERR_INVALID_PATHNAME
        .byte   AlertButtonOptions::TryAgainCancel ; ERR_PATH_NOT_FOUND
        .byte   AlertButtonOptions::Ok             ; ERR_VOL_NOT_FOUND
        .byte   AlertButtonOptions::Ok             ; ERR_FILE_NOT_FOUND
        .byte   AlertButtonOptions::Ok             ; ERR_DUPLICATE_FILENAME
        .byte   AlertButtonOptions::Ok             ; ERR_OVERRUN_ERROR
        .byte   AlertButtonOptions::Ok             ; ERR_VOLUME_DIR_FULL
        .byte   AlertButtonOptions::Ok             ; ERR_ACCESS_ERROR
        .byte   AlertButtonOptions::Ok             ; ERR_NOT_PRODOS_VOLUME
        .byte   AlertButtonOptions::Ok             ; ERR_DUPLICATE_VOLUME

        .byte   AlertButtonOptions::OkCancel       ; kErrInsertSystemDisk
        .byte   AlertButtonOptions::Ok             ; kErrSelectorListFull
        .byte   AlertButtonOptions::Ok             ; kErrWindowMustBeClosed
        .byte   AlertButtonOptions::Ok             ; kErrTooManyFiles
        .byte   AlertButtonOptions::Ok             ; kErrTooManyWindows
        .byte   AlertButtonOptions::OkCancel       ; kErrSaveChanges

        .byte   AlertButtonOptions::Ok             ; kErrBadReplacement
        .byte   AlertButtonOptions::OkCancel       ; kErrUnsupportedFileType
        .byte   AlertButtonOptions::Ok             ; kErrNoWindowsOpen
        .byte   AlertButtonOptions::Ok             ; kErrMoveCopyIntoSelf
        .byte   AlertButtonOptions::Ok             ; kErrDuplicateVolName
        .byte   AlertButtonOptions::Ok             ; kErrFileNotOpenable
        .byte   AlertButtonOptions::Ok             ; kErrNameTooLong
        .byte   AlertButtonOptions::TryAgainCancel ; kErrInsertSrcDisk
        .byte   AlertButtonOptions::TryAgainCancel ; kErrInsertDstDisk
        .byte   AlertButtonOptions::Ok             ; kErrBasicSysNotFound
        ASSERT_TABLE_SIZE alert_options_table, kNumAlerts

.params alert_params
text:           .addr   0
buttons:        .byte   0       ; AlertButtonOptions
options:        .byte   AlertOptions::Beep | AlertOptions::SaveBack

.endparams

start:
        ;; --------------------------------------------------
        ;; Process options, populate `alert_params`

        ;; A = alert, X = options

        ;; Search for alert in table, set Y to index
        ldy     #kNumAlerts-1
:       cmp     alert_table,y
        beq     :+
        dey
        bpl     :-
        iny                     ; default
:

        ;; Look up message
        copylohi  message_table_low,y, message_table_high,y, alert_params::text

        ;; If options is 0, use table value; otherwise,
        ;; mask off low bit and it's the action (N and V bits)

        ;; %00000000 = Use default options
        ;; %0....... e.g. $01 = OK
        ;; %10...... e.g. $80 = Try Again, Cancel
        ;; %11...... e.g. $C0 = OK, Cancel

        cpx     #0
      IF_NE
        txa
        and     #$FE            ; ignore low bit, e.g. treat $01 as $00
        sta     alert_params::buttons
      ELSE
        copy    alert_options_table,y, alert_params::buttons
      END_IF

        ldax    #alert_params
        FALL_THROUGH_TO Alert
.endproc

;;; ============================================================
;;; Display alert
;;; Inputs: A,X=alert_params structure
;;;    { .addr text, .byte AlertButtonOptions, .byte AlertOptions }

        AlertYieldLoop = YieldLoopFromAux
        alert_grafport = desktop_grafport

        .define AD_YESNO 0
        .define AD_SAVEBG 1
        .define AD_WRAP 1
        .define AD_EJECTABLE 0

        .include "../lib/alert_dialog.s"

;;; ============================================================
;;; Copy current GrafPort MapInfo into target buffer
;;; Inputs: A,X = mapinfo address

.proc GetPortBits
        port_ptr := $06

        stax    dest_ptr

        MGTK_CALL MGTK::GetPort, port_ptr

        ldy     #.sizeof(MGTK::MapInfo)-1
:       lda     (port_ptr),y
        dest_ptr := *+1
        sta     SELF_MODIFIED,y
        dey
        bpl     :-

        rts
.endproc

;;; ============================================================

music_icon:
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%1100000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%0011000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%0000110)
        .byte   PX(%0100000),PX(%0000000),PX(%0000111),PX(%1111110)
        .byte   PX(%0100000),PX(%0000000),PX(%1111100),PX(%0000010)
        .byte   PX(%0100000),PX(%0011111),PX(%1111100),PX(%0000010)
        .byte   PX(%0100000),PX(%0011111),PX(%1000100),PX(%0000010)
        .byte   PX(%0100000),PX(%0010000),PX(%0000100),PX(%0000010)
        .byte   PX(%0100000),PX(%0010000),PX(%0000100),PX(%0000010)
        .byte   PX(%0100000),PX(%0010000),PX(%0111100),PX(%0000010)
        .byte   PX(%0100001),PX(%1110000),PX(%1111100),PX(%0000010)
        .byte   PX(%0100011),PX(%1110000),PX(%0111000),PX(%0000010)
        .byte   PX(%0100001),PX(%1100000),PX(%0000000),PX(%0000010)
        .byte   PX(%0100000),PX(%0000000),PX(%0000000),PX(%0000010)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111110)

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

archive_icon:
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%0000000),PX(%1000000),PX(%0000010),PX(%1100000)
        .byte   PX(%0000111),PX(%1000000),PX(%0000010),PX(%0011000)
        .byte   PX(%0000100),PX(%1000000),PX(%0000011),PX(%1111000)
        .byte   PX(%0111100),PX(%1000000),PX(%0000000),PX(%0001000)
        .byte   PX(%0100100),PX(%1000000),PX(%0000000),PX(%0001000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0100100),PX(%1000000),PX(%0000000),PX(%0001000)
        .byte   PX(%0100100),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%0100100),PX(%0000000),PX(%0000000),PX(%1000000)
        .byte   PX(%0100111),PX(%1111111),PX(%1111111),PX(%1000000)
        .byte   PX(%0100000),PX(%0000000),PX(%0000100),PX(%0000000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100),PX(%0000000)

archive_mask:
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%0000000),PX(%1111111),PX(%1111111),PX(%1100000)
        .byte   PX(%0000111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%0000111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1000000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111111),PX(%1000000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100),PX(%0000000)
        .byte   PX(%0111111),PX(%1111111),PX(%1111100),PX(%0000000)

;;; System (with .SYSTEM suffix)

app_icon:
        .byte   PX(%0000000),PX(%0000000),PX(%0011000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%1100110),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000011),PX(%0000001),PX(%1000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0001100),PX(%0000000),PX(%0110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0110000),PX(%0000000),PX(%0001100),PX(%0000000)
        .byte   PX(%0000001),PX(%1000000),PX(%0000000),PX(%0000011),PX(%0000000)
        .byte   PX(%0000110),PX(%0000000),PX(%0000000),PX(%0000000),PX(%1100000)
        .byte   PX(%0011000),PX(%0000000),PX(%0000001),PX(%1111100),PX(%0011000)
        .byte   PX(%1100000),PX(%0000000),PX(%0000110),PX(%0000011),PX(%0000110)
        .byte   PX(%0011000),PX(%0000000),PX(%0011000),PX(%1110000),PX(%1111000)
        .byte   PX(%0000110),PX(%0000111),PX(%1111111),PX(%1111100),PX(%0011110)
        .byte   PX(%0000001),PX(%1000000),PX(%0110000),PX(%1100000),PX(%0011110)
        .byte   PX(%0000000),PX(%0110000),PX(%0001110),PX(%0000000),PX(%0011110)
        .byte   PX(%0000000),PX(%0001100),PX(%0000001),PX(%1111111),PX(%1111110)
        .byte   PX(%0000000),PX(%0000011),PX(%0000001),PX(%1000000),PX(%0011110)
        .byte   PX(%0000000),PX(%0000000),PX(%1100110),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0011000),PX(%0000000),PX(%0000000)

app_mask:
        .byte   PX(%0000000),PX(%0000000),PX(%0011000),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%1111110),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000011),PX(%1111111),PX(%1000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0001111),PX(%1111111),PX(%1110000),PX(%0000000)
        .byte   PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111100),PX(%0000000)
        .byte   PX(%0000001),PX(%1111111),PX(%1111111),PX(%1111111),PX(%0000000)
        .byte   PX(%0000111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1100000)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111110)
        .byte   PX(%0011111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111100)
        .byte   PX(%0000111),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%0000001),PX(%1111111),PX(%1111111),PX(%1111111),PX(%1111000)
        .byte   PX(%0000000),PX(%0111111),PX(%1111111),PX(%1111100),PX(%1111000)
        .byte   PX(%0000000),PX(%0001111),PX(%1111111),PX(%1111000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000011),PX(%1111111),PX(%1000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%1111110),PX(%0000000),PX(%0000000)
        .byte   PX(%0000000),PX(%0000000),PX(%0011000),PX(%0000000),PX(%0000000)

;;; ============================================================

        PAD_TO ::kSegmentDeskTopAuxAddress + ::kSegmentDeskTopAuxLength

.endscope ; aux
