;;; ============================================================
;;; DeskTop - Aux Memory Segment
;;;
;;; Compiled as part of desktop.s
;;; ============================================================

;;; ============================================================
;;; Segment loaded into AUX $8580-$BFFF (follows MGTK)
;;; ============================================================

.proc desktop_aux

        .org $8580

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

        PAD_TO $8800

;;; ============================================================

        .assert * = DEFAULT_FONT, error, "Entry point mismatch"
        .incbin "../mgtk/fonts/A2D.FONT"

        font_height     := DEFAULT_FONT+2

;;; ============================================================

        .assert * = $8D03, error, "Segment length mismatch"
        PAD_TO $8E00

;;; ============================================================
;;; Entry point for "Icon TookKit"
;;; ============================================================

        .assert * = IconTK::MLI, error, "IconTK entry point must be at $8E00"

.proc icon_toolkit

        jmp     ITK_DIRECT

;;; ============================================================

.params poly
num_vertices:   .byte   8
lastpoly:       .byte   0       ; 0 = last poly
vertices:
v0:     DEFINE_POINT 0, 0, v0
v1:     DEFINE_POINT 0, 0, v1
v2:     DEFINE_POINT 0, 0, v2
v3:     DEFINE_POINT 0, 0, v3
v4:     DEFINE_POINT 0, 0, v4
v5:     DEFINE_POINT 0, 0, v5
v6:     DEFINE_POINT 0, 0, v6
v7:     DEFINE_POINT 0, 0, v7
.endparams

.params icon_paintbits_params
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   0
mapwidth:       .byte   0
reserved:       .byte   0
maprect:        DEFINE_RECT 0,0,0,0,maprect
.endparams

.params mask_paintbits_params
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   0
mapwidth:       .byte   0
reserved:       .byte   0
maprect:        DEFINE_RECT 0,0,0,0,maprect
.endparams

rect_opendir:      DEFINE_RECT 0,0,0,0, rect_opendir

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

.params findwindow_params2
mousex: .word   0
mousey: .word   0
which_area:     .byte   0
window_id:      .byte   0
.endparams

.params grafport
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, kScreenWidth-1, kScreenHeight-1
penpattern:     .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc: DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   $96     ; ???
textbg: .byte   MGTK::textbg_black
fontptr:        .addr   DEFAULT_FONT
.endparams

;;; Grafport used to draw icon outlines during drag
.params drag_outline_grafport
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   0
mapwidth:       .byte   0
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, 0, 0
penpattern:     .res    8, 0
colormasks:     .byte   0, 0
penloc: DEFINE_POINT 0, 0
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
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   0
mapwidth:       .byte   0
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, 0, 0, cliprect
penpattern:     .res    8, 0
colormasks:     .byte   0, 0
penloc: DEFINE_POINT 0, 0
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
        jsr     dummy0000

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

        ldy     #4
:       lda     ($06),y
        sta     L9C8D,y
        sta     L9C92-1,y       ; ???
        dey
        cpy     #0
        bne     :-

        jsr     push_pointers
        lda     icon_id
        jsr     L9EB4
        stax    $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #kIconEntryWinIdMask
        sta     win_id
        jmp     L983D           ; skip over data

win_id: .byte   $00             ; written but not read

icon_id:
        .byte   $00

deltax: .word   0
deltay: .word   0

        ;; IconTK::HighlightIcon params
highlight_icon_id:  .byte   $00

L9831:  .byte   $00
L9832:  .byte   $00
L9833:  .byte   $00
L9834:  .byte   $00
L9835:  .byte   $00,$00,$00,$00,$00,$00,$00,$00

L983D:  lda     #0
        sta     highlight_icon_id
        sta     L9833

peek_loop:
        MGTK_CALL MGTK::PeekEvent, peekevent_params
        lda     peekevent_params::kind
        cmp     #MGTK::EventKind::drag
        beq     L9857

ignore_drag:
        lda     #2              ; return value
        jmp     just_select

        ;; Compute mouse delta
L9857:  sub16   findwindow_params2::mousex, L9C8E, deltax
        sub16   findwindow_params2::mousey, L9C90, deltay

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
        jmp     peek_loop
y_lo:   lda     deltay
        cmp     #kDragDelta
        bcs     is_drag
        jmp     peek_loop

        ;; Meets the threshold - it is a drag, not just a click.
is_drag:
        lda     highlight_count
        cmp     #kMaxDraggableItems + 1
        bcc     :+
        jmp     ignore_drag     ; too many

        ;; Was there a selection?
:       copy16  #drag_outline_buffer, $08
        lda     has_highlight
        bne     :+
        lda     #3              ; return value
        jmp     just_select

:       lda     highlight_list
        jsr     L9EB4
        stax    $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #kIconEntryWinIdMask
        sta     L9832

        ;; Prepare grafports
        MGTK_CALL MGTK::InitPort, icon_grafport
        MGTK_CALL MGTK::InitPort, drag_outline_grafport
        MGTK_CALL MGTK::SetPort, drag_outline_grafport
        MGTK_CALL MGTK::SetPattern, checkerboard_pattern
        MGTK_CALL MGTK::SetPenMode, penXOR

        ;; TODO: This is needed, but why?
        COPY_STRUCT MGTK::Rect, drag_outline_grafport::cliprect, L9835

        ldx     highlight_count
        stx     L9C74
L98F2:  lda     highlight_count,x
        jsr     L9EB4
        stax    $06
        ldy     #0
        lda     ($06),y
        cmp     #1
        bne     L9909
        ldx     #$80
        stx     L9833
L9909:  sta     L9834
        ITK_DIRECT_CALL IconTK::IconInRect, L9834
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
        bcs     L992D
        dec     $08+1

L992D:  ldy     #IconEntry::state
        lda     #$80            ; Highlighted
        sta     ($08),y
        jsr     pop_pointers
L9936:  ldx     #kIconPolySize-1
        ldy     #kIconPolySize-1

L993A:  lda     poly,x
        sta     ($08),y
        dey
        dex
        bpl     L993A

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
        beq     L995F
        ldx     L9C74
        jmp     L98F2

L995F:  COPY_BYTES 8, drag_outline_buffer+2, L9C76

        copy16  #drag_outline_buffer, $08
L9972:  ldy     #2

L9974:  lda     ($08),y
        cmp     L9C76
        iny
        lda     ($08),y
        sbc     L9C76+1
        bcs     L9990
        lda     ($08),y
        sta     L9C76+1
        dey
        lda     ($08),y
        sta     L9C76
        iny
        jmp     L99AA

L9990:  dey
        lda     ($08),y
        cmp     L9C7A
        iny
        lda     ($08),y
        sbc     L9C7A+1
        bcc     L99AA

        lda     ($08),y
        sta     L9C7A+1
        dey
        lda     ($08),y
        sta     L9C7A
        iny

L99AA:  iny
        lda     ($08),y
        cmp     L9C78
        iny
        lda     ($08),y
        sbc     L9C78+1
        bcs     L99C7

        lda     ($08),y
        sta     L9C78+1
        dey
        lda     ($08),y
        sta     L9C78
        iny
        jmp     L99E1

L99C7:  dey
        lda     ($08),y
        cmp     L9C7C
        iny
        lda     ($08),y
        sbc     L9C7C+1
        bcc     L99E1

        lda     ($08),y
        sta     L9C7C+1
        dey
        lda     ($08),y
        sta     L9C7C
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
L9A0E:  MGTK_CALL MGTK::PeekEvent, peekevent_params
        lda     peekevent_params::kind
        cmp     #MGTK::EventKind::drag
        beq     L9A1E
        jmp     L9BA5

L9A1E:  ldx     #3
L9A20:  lda     findwindow_params2,x
        cmp     L9C92,x
        bne     L9A31
        dex
        bpl     L9A20
        jsr     L9E14
        jmp     L9A0E

L9A31:  COPY_BYTES 4, findwindow_params2, L9C92

        lda     highlight_icon_id
        beq     L9A84
        lda     L9831
        sta     findwindow_params2::window_id
        ITK_DIRECT_CALL IconTK::FindIcon, findwindow_params2
        lda     findwindow_params2::which_area
        cmp     highlight_icon_id
        beq     L9A84
        jsr     xdraw_outline
        MGTK_CALL MGTK::SetPort, icon_grafport
        ITK_DIRECT_CALL IconTK::UnhighlightIcon, highlight_icon_id
        jsr     xdraw_outline
        lda     #0
        sta     highlight_icon_id
L9A84:  sub16   findwindow_params2::mousex, L9C8E, L9C96
        sub16   findwindow_params2::mousey, L9C90, L9C98
        jsr     L9C9E
        ldx     #0
L9AAF:  add16   L9C7A,x, L9C96,x, L9C7A,x
        add16   L9C76,x, L9C96,x, L9C76,x
        inx
        inx
        cpx     #4
        bne     L9AAF
        lda     #0
        sta     L9C75
        lda     L9C76+1
        bmi     L9AF7
        cmp16   L9C7A, #kScreenWidth
        bcs     L9AFE
        jsr     L9DFA
        jmp     L9B0E

L9AF7:  jsr     L9CAA
        bmi     L9B0E
        bpl     L9B03
L9AFE:  jsr     L9CD1
        bmi     L9B0E
L9B03:  jsr     L9DB8
        lda     L9C75
        ora     #$80
        sta     L9C75
L9B0E:  lda     L9C78+1
        bmi     L9B31
        cmp16   L9C78, #13
        bcc     L9B31
        cmp16   L9C7C, #kScreenHeight
        bcs     L9B38
        jsr     L9E07
        jmp     L9B48

L9B31:  jsr     L9D31
        bmi     L9B48
        bpl     L9B3D
L9B38:  jsr     L9D58
        bmi     L9B48
L9B3D:  jsr     L9DD9
        lda     L9C75
        ora     #$40
        sta     L9C75
L9B48:  bit     L9C75
        bpl     L9B52
        bvc     L9B52
        jmp     L9A0E

L9B52:  jsr     xdraw_outline
        copy16  #drag_outline_buffer, $08
L9B60:  ldy     #2
L9B62:  add16in ($08),y, L9C96, ($08),y
        iny
        add16in ($08),y, L9C98, ($08),y
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
        jmp     L9A0E

L9BA5:  jsr     xdraw_outline
        lda     highlight_icon_id
        beq     :+
        MGTK_CALL MGTK::SetPort, icon_grafport
        ITK_DIRECT_CALL IconTK::UnhighlightIcon, highlight_icon_id
        jmp     L9C63

:       MGTK_CALL MGTK::FindWindow, findwindow_params2
        lda     findwindow_params2::window_id
        cmp     L9832
        beq     L9BE1
        bit     L9833
        bmi     L9BDC
        lda     findwindow_params2::window_id
        bne     L9BD4
L9BD1:  jmp     ignore_drag

L9BD4:  ora     #$80
        sta     highlight_icon_id
        jmp     L9C63

L9BDC:  lda     L9832
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
L9C76:  .word   0
L9C78:  .word   0
L9C7A:  .word   0
L9C7C:  .word   0
L9C7E:  .word   0
L9C80:  .word   13
const_screen_width:  .word   kScreenWidth
const_screen_height:  .word   kScreenHeight
L9C86:  .word   0
L9C88:  .word   0
L9C8A:  .word   0
L9C8C:  .byte   $00

L9C8D:  .byte   0
L9C8E:  .word   0
L9C90:  .word   0

L9C92:  .res    4
L9C96:  .word   0
L9C98:  .word   0
        .byte   $00,$00,$00,$00

L9C9E:  COPY_STRUCT MGTK::Rect, L9C76, L9C86
        rts

L9CAA:  lda     L9C76
        cmp     L9C7E
        bne     L9CBD
        lda     L9C76+1
        cmp     L9C7E+1
        bne     L9CBD
        return  #0

L9CBD:  sub16   #0, L9C86, L9C96
        jmp     L9CF5

L9CD1:  lda     L9C7A
        cmp     const_screen_width
        bne     L9CE4
        lda     L9C7A+1
        cmp     const_screen_width+1
        bne     L9CE4
        return  #0

L9CE4:  sub16   #kScreenWidth, L9C8A, L9C96
L9CF5:  add16   L9C86, L9C96, L9C76
        add16   L9C8A, L9C96, L9C7A
        add16   L9C8E, L9C96, L9C8E
        return  #$FF

L9D31:  lda     L9C78
        cmp     L9C80
        bne     L9D44
        lda     L9C78+1
        cmp     L9C80+1
        bne     L9D44
        return  #0

L9D44:  sub16   #13, L9C88, L9C98
        jmp     L9D7C

L9D58:  lda     L9C7C
        cmp     const_screen_height
        bne     L9D6B
        lda     L9C7C+1
        cmp     const_screen_height+1
        bne     L9D6B
        return  #0

L9D6B:  sub16   #kScreenHeight-1, L9C8C, L9C98
L9D7C:  add16   L9C88, L9C98, L9C78
        add16   L9C8C, L9C98, L9C7C
        add16   L9C90, L9C98, L9C90
        return  #$FF

L9DB8:  copy16  L9C86, L9C76
        copy16  L9C8A, L9C7A
        lda     #0
        sta     L9C96
        sta     L9C96+1
        rts

L9DD9:  copy16  L9C88, L9C78
        copy16  L9C8C, L9C7C
        lda     #0
        sta     L9C98
        sta     L9C98+1
        rts

L9DFA:  lda     findwindow_params2::mousex+1
        sta     L9C8E+1
        lda     findwindow_params2::mousex
        sta     L9C8E
        rts

L9E07:  lda     findwindow_params2::mousey+1
        sta     L9C90+1
        lda     findwindow_params2::mousey
        sta     L9C90
        rts

L9E14:  bit     L9833
        bpl     L9E1A
        rts

L9E1A:  jsr     push_pointers
        MGTK_CALL MGTK::FindWindow, findwindow_params2
        lda     findwindow_params2::which_area
        bne     L9E2B
        sta     findwindow_params2::window_id
L9E2B:  ITK_DIRECT_CALL IconTK::FindIcon, findwindow_params2
        lda     findwindow_params2::which_area ; Icon ID
        bne     L9E39
        jmp     L9E97

L9E39:  ldx     highlight_count
        dex
L9E3D:  cmp     highlight_list,x
        beq     L9E97
        dex
        bpl     L9E3D
        sta     L9EB3
        cmp     #kTrashIconNum
        beq     :+
        asl     a
        tax
        copy16  icon_ptrs,x, $06
        ldy     #IconEntry::win_type
        lda     ($06),y
        and     #kIconEntryWinIdMask
        sta     L9831
        lda     ($06),y
        and     #kIconEntryTypeMask
        bne     L9E97
        lda     L9EB3
:       sta     highlight_icon_id
        jsr     xdraw_outline
        MGTK_CALL MGTK::SetPort, icon_grafport
        ITK_DIRECT_CALL IconTK::HighlightIcon, highlight_icon_id
        jsr     xdraw_outline
L9E97:  jsr     pop_pointers
        rts

L9EB3:  .byte   0
L9EB4:  asl     a
        tay
        lda     icon_ptrs+1,y
        tax
        lda     icon_ptrs,y
        rts

.proc xdraw_outline
        MGTK_CALL MGTK::SetPort, drag_outline_grafport
        MGTK_CALL MGTK::FramePoly, drag_outline_buffer
        rts
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
rect:   DEFINE_RECT 0,0,0,0,rect

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

L9F94:  .byte   0
        .byte   0
        .byte   0
        .byte   0

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

        ldy     #9
:       lda     ($06),y
        sta     rect_opendir::y2,y
        iny
        cpy     #$1D
        bne     :-

:       lda     drawtext_params::textlen
        sta     textwidth_params::textlen
        MGTK_CALL MGTK::TextWidth, textwidth_params
        lda     textwidth_params::result
        cmp     icon_paintbits_params::maprect::x2
        bcs     :+
        inc     drawtext_params::textlen
        ldx     drawtext_params::textlen
        lda     #' '
        sta     text_buffer-1,x
        jmp     :-

:       lsr     a
        sta     moveto_params2::xcoord+1
        lda     icon_paintbits_params::maprect::x2
        lsr     a
        sta     moveto_params2::xcoord
        lda     moveto_params2::xcoord+1
        sec
        sbc     moveto_params2::xcoord
        sta     moveto_params2::xcoord
        sub16_8 icon_paintbits_params::viewloc::xcoord, moveto_params2::xcoord, moveto_params2::xcoord
        add16_8 icon_paintbits_params::viewloc::ycoord, icon_paintbits_params::maprect::y2, moveto_params2::ycoord
        add16   moveto_params2::ycoord, #1, moveto_params2::ycoord
        add16_8 moveto_params2::ycoord, font_height, moveto_params2::ycoord

        COPY_STRUCT MGTK::Point, moveto_params2, L9F94

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
        COPY_STRUCT MGTK::Point, L9F94, moveto_params2
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
loop:   add16   icon_paintbits_params::viewloc::xcoord,x, icon_paintbits_params::maprect::x1,x, rect_opendir::x1,x
        add16   icon_paintbits_params::viewloc::xcoord,x, icon_paintbits_params::maprect::x2,x, rect_opendir::x2,x
        inx
        inx
        cpx     #4
        bne     loop
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
;;; (Label is always at least as wide as the icon)

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
        ldy     #8              ; bitmap x2
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
        ldy     #10             ; bitmap y2
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

        ;; Compute text width
        ldy     #.sizeof(IconEntry)+1
        ldx     #19             ; len byte + 15 chars + 2 spaces
:       lda     (entry_ptr),y
        sta     text_buffer-1,x
        dey
        dex
        bpl     :-

        ;; Pad with spaces until it's at least as wide as the icon
:       lda     drawtext_params::textlen
        sta     textwidth_params::textlen
        MGTK_CALL MGTK::TextWidth, textwidth_params
        ldy     #8              ; bitmap x2 offset
        lda     textwidth_params::result
        cmp     (bitmap_ptr),y
        bcs     got_width
        inc     drawtext_params::textlen
        ldx     drawtext_params::textlen
        lda     #' '
        sta     text_buffer-1,x
        jmp     :-

got_width:
        lsr     a               ; width / 2
        sta     text_width
        lda     ($08),y         ; still has bitmap x2 offset
        lsr     a               ; / 2
        sta     icon_width

        ;; Left edge of label (v5, v6)
        lda     text_width
        sec
        sbc     icon_width
        sta     icon_width
        lda     poly::v0::xcoord
        sec
        sbc     icon_width
        sta     poly::v6::xcoord
        sta     poly::v5::xcoord
        lda     poly::v0::xcoord+1
        sbc     #0
        sta     poly::v6::xcoord+1
        sta     poly::v5::xcoord+1

        ;; Right edge of label (v3, v4)
        inc     textwidth_params::result
        inc     textwidth_params::result
        lda     poly::v5::xcoord
        clc
        adc     textwidth_params::result
        sta     poly::v3::xcoord
        sta     poly::v4::xcoord
        lda     poly::v5::xcoord+1
        adc     #0
        sta     poly::v3::xcoord+1
        sta     poly::v4::xcoord+1
        jsr     pop_pointers
        rts

icon_width:  .byte   0
text_width:  .byte   0

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

vl_offset:  DEFINE_POINT 0,0,vl_offset
mr_offset:  DEFINE_POINT 0,0,mr_offset

entry_poly:  copy    #$80, offset_flags
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
        cpx     #32
        bne     loop1
        ldx     #0

loop2:  add16   poly::vertices+0,x, mr_offset::xcoord, poly::vertices+0,x
        add16   poly::vertices+2,x, mr_offset::ycoord, poly::vertices+2,x
        inx
        inx
        inx
        inx
        cpx     #32
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
viewloc:        DEFINE_POINT 0, 0, viewloc
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, 0, 0, cliprect
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
        lda     poly::v5::xcoord
        sta     bounds_l
        sta     portbits::cliprect::x1
        sta     portbits::viewloc::xcoord
        lda     poly::v5::xcoord+1
        sta     bounds_l+1
        sta     portbits::cliprect::x1+1
        sta     portbits::viewloc::xcoord+1

        ;; Set up bounds_r/b
        ldx     #3
:       lda     poly::v4,x
        sta     bounds_r,x      ; right and bottom
        sta     portbits::cliprect::x2,x
        dex
        bpl     :-

        ;; if (bounds_r > kScreenWidth - 1) bounds_r = kScreenWidth - 2
        cmp16   bounds_r, #kScreenWidth - 1
        bmi     done
        lda     #<(kScreenWidth - 2)
        sta     bounds_r
        sta     portbits::cliprect::x2
        lda     #>(kScreenWidth - 2)
        sta     bounds_r+1
        sta     portbits::cliprect::x2+1

done:   MGTK_CALL MGTK::SetPortBits, portbits
        rts
.endproc

;;; ============================================================

.proc calc_window_intersections
        ptr := $06

        jmp     start

;;; findwindow_params::window_id is used as first part of
;;; GetWinPtr params structure including window_ptr.
.params findwindow_params
mousex: .word   0
mousey: .word   0
which_area:     .byte   0
window_id:      .byte   0
.endparams
window_ptr:  .word   0          ; do not move this; see above

pt_num: .byte   0

scrollbar_flags:
        .byte   0               ; bit 7 = hscroll present; bit 6 = vscroll present
dialogbox_flag:
        .byte   0               ; bit 7 = dialog box

;;; Points at corners of icon's bounding rect
;;; pt1 +----+ pt2
;;;     |    |
;;; pt4 +----+ pt3
pt1:    DEFINE_POINT 0,0,pt1
pt2:    DEFINE_POINT 0,0,pt2
pt3:    DEFINE_POINT 0,0,pt3
pt4:    DEFINE_POINT 0,0,pt4

bounds:     DEFINE_RECT 0,0,0,0, bounds

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
        MGTK_CALL MGTK::SetPortBits, portbits
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
        lda     findwindow_params::which_area
        beq     next_pt

        ;; --------------------------------------------------
        ;; Compute window edges (including non-content area)

        ;; Uses Winfo's port's viewloc as window location, Winfo's port's
        ;; cliprect as size. GetWinPort result is invalid if obscured.

        ;; Window edges
        win_l := bounds::x1
        win_t := bounds::y1
        win_r := bounds::x2
        win_b := bounds::y2

        jsr     push_pointers

        MGTK_CALL MGTK::GetWinPtr, findwindow_params::window_id
        copy16  window_ptr, ptr

        ;; Left/Top
        ldx     #.sizeof(MGTK::Point)-1
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::viewloc + .sizeof(MGTK::Point)-1
:       lda     (ptr),y
        sta     win_l,x
        dey
        dex
        bpl     :-

        ;; Width/Height
        ldx     #.sizeof(MGTK::Point)-1
        ldy     #MGTK::Winfo::port + MGTK::GrafPort::maprect + MGTK::Rect::x2 + .sizeof(MGTK::Point)-1
:       lda     (ptr),y
        sta     win_r,x
        dey
        dex
        bpl     :-

        ;; Make absolute
        add16   win_r, win_l, win_r
        add16   win_b, win_t, win_b

        ;; Check window properties
        ldy     #MGTK::Winfo::options
        lda     (ptr),y         ; options
        and     #MGTK::Option::dialog_box
        bne     :+              ; yes
        sta     dialogbox_flag
        beq     @continue
:       copy    #$80, dialogbox_flag
@continue:

        ldy     #MGTK::Winfo::hscroll
        lda     (ptr),y         ; hscroll
        and     #MGTK::Scroll::option_present
        sta     scrollbar_flags
        iny
        lda     (ptr),y         ; vscroll
        and     #MGTK::Scroll::option_present
        lsr     a
        ora     scrollbar_flags
        sta     scrollbar_flags

        ;; TODO: I *think* win_l/t/r/b are supposed to be 1px beyond
        ;; window's bounds, but aren't consistently so. ???

        ;; 1px implicit left borders, and move 1px beyond bounds ???
        sub16   win_l, #2, win_l

        ;; 1px implicit bottom border
        add16   win_b, #1, win_b
        ;; TODO: 1px implicit right border?

        kTitleBarHeight = 14    ; Should be 12? (But no visual bugs)
        kScrollBarWidth = 20
        kScrollBarHeight = 10

        ;; NOTE: algorithm does not account for 1px implicit border applied to dialogs and windows

        ;; --------------------------------------------------
        ;; Adjust window rect to account for title bar

        ;; Is dialog? (i.e. no title bar)
        bit     dialogbox_flag
        bmi     :+
        sub16   win_t, #kTitleBarHeight, win_t
:

        ;; --------------------------------------------------
        ;; Adjust window rect to account for scroll bars

        ;; Horizontal scrollbar?
        bit     scrollbar_flags
        bpl     :+
        add16   win_r, #kScrollBarWidth, win_r
:

        ;; Vertical scrollbar?
        bit     scrollbar_flags
        bvc     :+
        add16   win_b, #kScrollBarHeight, win_b
:

        ;; --------------------------------------------------

        jsr     pop_pointers


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
        kOffset = 15

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

label_apple:
        PASCAL_STRING kGlyphSolidApple
label_file:
        PASCAL_STRING "File"
label_view:
        PASCAL_STRING "View"
label_special:
        PASCAL_STRING "Special"
label_startup:
        PASCAL_STRING "Startup"
label_selector:
        PASCAL_STRING "Selector"

label_new_folder:
        PASCAL_STRING "New Folder ..."
label_open:
        PASCAL_STRING "Open"
label_close:
        PASCAL_STRING "Close Window"
label_close_all:
        PASCAL_STRING "Close All"
label_select_all:
        PASCAL_STRING "Select All"
label_copy_file:
        PASCAL_STRING "Copy a File ..."
label_delete_file:
        PASCAL_STRING "Delete a File ..."
label_eject:
        PASCAL_STRING "Eject Disk"
label_quit:
        PASCAL_STRING "Quit"

label_by_icon:
        PASCAL_STRING "as Icons"
label_by_name:
        PASCAL_STRING "by Name"
label_by_date:
        PASCAL_STRING "by Date"
label_by_size:
        PASCAL_STRING "by Size"
label_by_type:
        PASCAL_STRING "by Type"

label_check_all_drives:
        PASCAL_STRING "Check All Drives"
label_check_drive:
        PASCAL_STRING "Check Drive"
label_format_disk:
        PASCAL_STRING "Format a Disk ..."
label_erase_disk:
        PASCAL_STRING "Erase a Disk ..."
label_disk_copy:
        PASCAL_STRING "Disk Copy ..."
label_lock:
        PASCAL_STRING "Lock"
label_unlock:
        PASCAL_STRING "Unlock"
label_get_info:
        PASCAL_STRING "Get Info"
label_get_size:
        PASCAL_STRING "Get Size"
label_rename_icon:
        PASCAL_STRING "Rename ..."

desktop_menu:
        DEFINE_MENU_BAR 6
        DEFINE_MENU_BAR_ITEM kMenuIdApple, label_apple, apple_menu
        DEFINE_MENU_BAR_ITEM kMenuIdFile, label_file, file_menu
        DEFINE_MENU_BAR_ITEM kMenuIdView, label_view, view_menu
        DEFINE_MENU_BAR_ITEM kMenuIdSpecial, label_special, special_menu
        DEFINE_MENU_BAR_ITEM kMenuIdStartup, label_startup, startup_menu
        DEFINE_MENU_BAR_ITEM kMenuIdSelector, label_selector, selector_menu

file_menu:
        DEFINE_MENU 13
        DEFINE_MENU_ITEM label_new_folder, 'F', 'f'
        DEFINE_MENU_ITEM label_open, 'O', 'o'
        DEFINE_MENU_ITEM label_close, 'W', 'w'
        DEFINE_MENU_ITEM label_close_all
        DEFINE_MENU_ITEM label_select_all, 'A', 'a'
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM label_get_info, 'I', 'i'
        DEFINE_MENU_ITEM label_rename_icon
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM label_copy_file, 'Y', 'y'
        DEFINE_MENU_ITEM label_delete_file, 'D', 'd'
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM label_quit, 'Q', 'q'

        kMenuItemIdNewFolder   = 1
        kMenuItemIdOpen         = 2
        kMenuItemIdClose        = 3
        kMenuItemIdCloseAll    = 4
        kMenuItemIdSelectAll   = 5
        ;; --------------------
        kMenuItemIdGetInfo     = 7
        kMenuItemIdRenameIcon  = 8
        ;; --------------------
        kMenuItemIdCopyFile    = 10
        kMenuItemIdDeleteFile  = 11
        ;; --------------------
        kMenuItemIdQuit         = 13

view_menu:
        DEFINE_MENU 5
        DEFINE_MENU_ITEM label_by_icon, 'J', 'j'
        DEFINE_MENU_ITEM label_by_name, 'N', 'n'
        DEFINE_MENU_ITEM label_by_date, 'T', 't'
        DEFINE_MENU_ITEM label_by_size, 'K', 'k'
        DEFINE_MENU_ITEM label_by_type, 'L', 'l'

        kMenuItemIdViewByIcon = 1
        kMenuItemIdViewByName = 2
        kMenuItemIdViewByDate = 3
        kMenuItemIdViewBySize = 4
        kMenuItemIdViewByType = 5

special_menu:
        DEFINE_MENU 11
        DEFINE_MENU_ITEM label_check_all_drives
        DEFINE_MENU_ITEM label_check_drive
        DEFINE_MENU_ITEM label_eject, 'E', 'e'
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM label_format_disk, 'S', 's'
        DEFINE_MENU_ITEM label_erase_disk, 'Z', 'z'
        DEFINE_MENU_ITEM label_disk_copy
        DEFINE_MENU_SEPARATOR
        DEFINE_MENU_ITEM label_lock
        DEFINE_MENU_ITEM label_unlock
        DEFINE_MENU_ITEM label_get_size

        kMenuItemIdCheckAll    = 1
        kMenuItemIdCheckDrive  = 2
        kMenuItemIdEject        = 3
        ;; --------------------
        kMenuItemIdFormatDisk  = 5
        kMenuItemIdEraseDisk   = 6
        kMenuItemIdDiskCopy    = 7
        ;; --------------------
        kMenuItemIdLock         = 9
        kMenuItemIdUnlock       = 10
        kMenuItemIdGetSize     = 11

        PAD_TO $AE00

;;; ============================================================

        ;; Rects
        kAlertDialogWidth = 400
        kAlertDialogHeight = 107

confirm_dialog_outer_rect:  DEFINE_RECT 4,2,kAlertDialogWidth-4,kAlertDialogHeight-2
confirm_dialog_inner_rect:  DEFINE_RECT 5,3,kAlertDialogWidth-5,kAlertDialogHeight-3
cancel_button_rect:  DEFINE_RECT 40,kAlertDialogHeight-19,140,kAlertDialogHeight-8
LAE18:  DEFINE_RECT 193,30,293,41
ok_button_rect:  DEFINE_RECT 260,kAlertDialogHeight-19,360,kAlertDialogHeight-8
yes_button_rect:  DEFINE_RECT 200,kAlertDialogHeight-19,240,kAlertDialogHeight-8
no_button_rect:  DEFINE_RECT 260,kAlertDialogHeight-19,300,kAlertDialogHeight-8
all_button_rect:  DEFINE_RECT 320,kAlertDialogHeight-19,360,kAlertDialogHeight-8

str_ok_label:
        PASCAL_STRING {"OK            ",kGlyphReturn}

ok_label_pos:  DEFINE_POINT 265,kAlertDialogHeight-9
cancel_label_pos:  DEFINE_POINT 45,kAlertDialogHeight-9
yes_label_pos:  DEFINE_POINT 205,kAlertDialogHeight-9
no_label_pos:  DEFINE_POINT 265,kAlertDialogHeight-9
all_label_pos:  DEFINE_POINT 325,kAlertDialogHeight-9

        .byte   $1C,$00,$70,$00
        .byte   $1C,$00,$87,$00

textbg_black:  .byte   $00
textbg_white:  .byte   $7F

        kDialogLabelHeight = 9
        kDialogLabelBaseY = 30
        .define DIALOG_LABEL_Y(num) (((num)*(kDialogLabelHeight))+(kDialogLabelBaseY))

clear_dialog_labels_rect:  DEFINE_RECT 39,25,360,kAlertDialogHeight-20
prompt_rect:  DEFINE_RECT 40,(DIALOG_LABEL_Y {5})+1,360,(DIALOG_LABEL_Y {6})
current_target_file_pos:  DEFINE_POINT 75,DIALOG_LABEL_Y {2}
current_dest_file_pos:  DEFINE_POINT 75,DIALOG_LABEL_Y {3}
current_target_file_rect:  DEFINE_RECT 75,(DIALOG_LABEL_Y {1})+1,394,(DIALOG_LABEL_Y {2})
current_dest_file_rect:  DEFINE_RECT 75,(DIALOG_LABEL_Y {2})+1,394,(DIALOG_LABEL_Y {3})

str_cancel_label:
        PASCAL_STRING "Cancel        Esc"
str_yes_label:
        PASCAL_STRING " Yes"
str_no_label:
        PASCAL_STRING " No"
str_all_label:
        PASCAL_STRING " All"

LAEB6:  PASCAL_STRING "Source filename:"
LAEC7:  PASCAL_STRING "Destination filename:"

        ;; "About" dialog resources

        kAboutDialogWidth = 400
        kAboutDialogHeight = 120

about_dialog_outer_rect:  DEFINE_RECT 4, 2, kAboutDialogWidth-4, kAboutDialogHeight-2
about_dialog_inner_rect:  DEFINE_RECT 5, 3, kAboutDialogWidth-5, kAboutDialogHeight-3

str_about1:  PASCAL_STRING "Apple II DeskTop"
str_about2:  PASCAL_STRING "Copyright Apple Computer Inc., 1986"
str_about3:  PASCAL_STRING "Copyright Version Soft, 1985 - 1986"
str_about4:  PASCAL_STRING "All Rights Reserved"
str_about5:  PASCAL_STRING "Authors: Stephane Cavril, Bernard Gallet, Henri Lamiraux"
str_about6:  PASCAL_STRING "Richard Danais and Luc Barthelet"
str_about7:  PASCAL_STRING "With thanks to: A. Gerard, J. Gerber, P. Pahl, J. Bernard"
str_about8:  PASCAL_STRING RELEASE_DATE
str_about9:  PASCAL_STRING .sprintf("Version %d.%d%s",::VERSION_MAJOR,::VERSION_MINOR,VERSION_SUFFIX)

        ;; "Copy File" dialog strings
str_copy_title:
        PASCAL_STRING "Copy ..."
str_copy_copying:
        PASCAL_STRING "Now Copying "
str_copy_from:
        PASCAL_STRING "from:"
str_copy_to:
        PASCAL_STRING "to :"
str_copy_remaining:
        PASCAL_STRING "Files remaining to copy: "

        ;; "Move File" dialog strings
str_move_title:
        PASCAL_STRING "Move ..."
str_move_moving:
        PASCAL_STRING "Now Moving "
str_move_remaining:
        PASCAL_STRING "Files remaining to move: "

str_exists_prompt:
        PASCAL_STRING "That file already exists. Do you want to write over it ?"
str_large_prompt:
        PASCAL_STRING "This file is too large to copy, click OK to continue."

copy_file_count_pos:
        DEFINE_POINT 110, DIALOG_LABEL_Y {1}
copy_file_count_pos2:
        DEFINE_POINT 170, DIALOG_LABEL_Y {4}

        ;; "Delete" dialog strings
str_delete_title:
        PASCAL_STRING "Delete ..."
str_delete_ok:
        PASCAL_STRING "Click OK to delete:"
str_ok_empty:
        PASCAL_STRING "Clicking OK will immediately empty the trash of:"
str_file_colon:
        PASCAL_STRING "File:"
str_delete_remaining:
        PASCAL_STRING "Files remaining to be deleted:"
str_delete_locked_file:
        PASCAL_STRING "This file is locked, do you want to delete it anyway ?"

delete_file_count_pos:
        DEFINE_POINT 145, DIALOG_LABEL_Y {4}

delete_remaining_count_pos:
        DEFINE_POINT 204, DIALOG_LABEL_Y {4}

delete_file_count_pos2:
        DEFINE_POINT 300, DIALOG_LABEL_Y {4}

        ;; "New Folder" dialog strings
str_new_folder_title:
        PASCAL_STRING "New Folder ..."
str_in_colon:
        PASCAL_STRING "in:"
str_enter_folder_name:
        PASCAL_STRING "Enter the folder name:"

        ;; "Rename Icon" dialog strings
str_rename_title:
        PASCAL_STRING "Rename an Icon ..."
str_rename_old:
        PASCAL_STRING "Rename: "
str_rename_new:
        PASCAL_STRING "New name:"

        ;; "Get Info" dialog strings
str_info_title:
        PASCAL_STRING "Get Info ..."
str_info_name:
        PASCAL_STRING "Name"
str_info_locked:
        PASCAL_STRING "Locked"
str_info_size:
        PASCAL_STRING "Size"
str_info_create:
        PASCAL_STRING "Creation date"
str_info_mod:
        PASCAL_STRING "Last modification"
str_info_type:
        PASCAL_STRING "Type"
str_info_protected:
        PASCAL_STRING "Write protected"
str_info_blocks:
        PASCAL_STRING "Blocks free/size"

str_colon:
        PASCAL_STRING ": "

unlock_remaining_count_pos2:  DEFINE_POINT 160,DIALOG_LABEL_Y {4}
lock_remaining_count_pos2:  DEFINE_POINT 145,DIALOG_LABEL_Y {4}
files_pos:  DEFINE_POINT 200,DIALOG_LABEL_Y {4}
files_pos2:  DEFINE_POINT 185,DIALOG_LABEL_Y {4}
unlock_remaining_count_pos:  DEFINE_POINT 205,DIALOG_LABEL_Y {4}
lock_remaining_count_pos: DEFINE_POINT 195,DIALOG_LABEL_Y {4}

str_format_disk:  PASCAL_STRING "Format a Disk ..."
str_select_format:  PASCAL_STRING "Select the location where the disk is to be formatted"
str_new_volume:  PASCAL_STRING "Enter the name of the new volume:"
str_confirm_format:  PASCAL_STRING "Do you want to format "
str_formatting:  PASCAL_STRING "Formatting the disk...."
str_formatting_error:  PASCAL_STRING "Formatting error. Check drive, then click OK to try again."

str_erase_disk:  PASCAL_STRING "Erase a Disk ..."
str_select_erase:  PASCAL_STRING "Select the location where the disk is to be erased"
str_confirm_erase:  PASCAL_STRING "Do you want to erase "
str_erasing:  PASCAL_STRING "Erasing the disk...."
str_erasing_error:  PASCAL_STRING "Erasing error. Check drive, then click OK to try again."

        ;; "Unlock File" dialog strings
str_unlock_title:
        PASCAL_STRING "Unlock ..."
str_unlock_ok:
        PASCAL_STRING "Click OK to unlock "
str_unlock_remaining:
        PASCAL_STRING "Files remaining to be unlocked: "

        ;; "Lock File" dialog strings
str_lock_title:
        PASCAL_STRING "Lock ..."
str_lock_ok:
        PASCAL_STRING "Click OK to lock "
str_lock_remaining:
        PASCAL_STRING "Files remaining to be locked: "

        ;; "Get Size" dialog strings
str_size_title:
        PASCAL_STRING "Get Size ..."
str_size_number:
        PASCAL_STRING "Number of files"
str_size_blocks:
        PASCAL_STRING "Blocks used on disk"

        .word   110,35,110,43

str_download:
        PASCAL_STRING "Copy to RAMCard ..."

str_ramcard_full:
        PASCAL_STRING "The RAMCard is full. The copy was not completed."

str_1_space:
        PASCAL_STRING " "

str_warning:
        PASCAL_STRING "Warning !"
str_insert_system_disk:
        PASCAL_STRING "Please insert the system disk."
str_selector_list_full:
        PASCAL_STRING "The Selector list is full. You must delete an entry"
str_before_new_entries:
        PASCAL_STRING "before you can add new entries."
str_window_must_be_closed:
        PASCAL_STRING "A window must be closed before opening this new catalog."

str_too_many_windows:
        PASCAL_STRING "There are too many windows open on the desktop !"
str_save_selector_list:
        PASCAL_STRING "Do you want to save the new Selector list"
str_on_system_disk:
        PASCAL_STRING "on the system disk ?"

;;; ============================================================

show_alert_indirection:
        jmp     show_alert_dialog

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
        DEFINE_POINT 20, 8      ; viewloc
        .addr   alert_bitmap    ; mapbits
        .byte   7               ; mapwidth
        .byte   0               ; reserved
        DEFINE_RECT 0, 0, 36, 23 ; maprect
.endparams

alert_rect:
        DEFINE_RECT 65, 87, 485, 142
alert_inner_frame_rect1:
        DEFINE_RECT 4, 2, 416, 53
alert_inner_frame_rect2:
        DEFINE_RECT 5, 3, 415, 52

.params portmap
viewloc:        DEFINE_POINT 65, 87, viewloc
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .byte   MGTK::screen_mapwidth
reserved:       .byte   0
maprect:        DEFINE_RECT 0, 0, 420, 55, maprect
.endparams


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

.proc show_alert_dialog_impl

ok_label:
        PASCAL_STRING {"OK            ",kGlyphReturn}

try_again_rect:
        DEFINE_RECT 20,37,120,48
try_again_pos:
        DEFINE_POINT 25,47

cancel_rect:
        DEFINE_RECT 300,37,400,48
cancel_pos:
        DEFINE_POINT 305,47

pos_prompt: DEFINE_POINT 75,29, pos_prompt

alert_action:  .byte   $00
prompt_addr:    .addr   0

try_again_label:
        PASCAL_STRING "Try Again     A"
cancel_label:
        PASCAL_STRING "Cancel     Esc"

err_00:  PASCAL_STRING "System Error"
err_27:  PASCAL_STRING "I/O error"
err_28:  PASCAL_STRING "No device connected"
err_2B:  PASCAL_STRING "The disk is write protected."
err_40:  PASCAL_STRING "The syntax of the pathname is invalid."
err_44:  PASCAL_STRING "Part of the pathname doesn't exist."
err_45:  PASCAL_STRING "The volume cannot be found."
err_46:  PASCAL_STRING "The file cannot be found."
err_47:  PASCAL_STRING "That name already exists. Please use another name."
err_48:  PASCAL_STRING "The disk is full."
err_49:  PASCAL_STRING "The volume directory cannot hold more than 51 files."
err_4E:  PASCAL_STRING "The file is locked."
err_52:  PASCAL_STRING "This is not a ProDOS disk."
err_57:  PASCAL_STRING "There is another volume with that name on the desktop."
        ;; Below are internal (not ProDOS MLI) error codes.
err_F9:  PASCAL_STRING "There are 2 volumes with the same name."
err_FA:  PASCAL_STRING "This file cannot be opened."
err_FB:  PASCAL_STRING "That name is too long."
err_FC:  PASCAL_STRING "Please insert source disk"
err_FD:  PASCAL_STRING "Please insert destination disk"
err_FE:  PASCAL_STRING "BASIC.SYSTEM not found"

        ;; number of alert messages
alert_count:
        .byte   20

        ;; message number-to-index table
        ;; (look up by scan to determine index)
alert_table:
        ;; ProDOS MLI error codes:
        .byte   $00, ERR_IO_ERROR,ERR_DEVICE_NOT_CONNECTED, ERR_WRITE_PROTECTED
        .byte   ERR_INVALID_PATHNAME, ERR_PATH_NOT_FOUND, ERR_VOL_NOT_FOUND
        .byte   ERR_FILE_NOT_FOUND, ERR_DUPLICATE_FILENAME, ERR_OVERRUN_ERROR
        .byte   ERR_VOLUME_DIR_FULL, ERR_ACCESS_ERROR, ERR_NOT_PRODOS_VOLUME
        .byte   ERR_DUPLICATE_VOLUME

        ;; Internal error codes:
        .byte   kErrDuplicateVolName, kErrFileNotOpenable, kErrNameTooLong
        .byte   kErrInsertSrcDisk, kErrInsertDstDisk, kErrBasicSysNotFound

        ;; alert index to string address
prompt_table:
        .addr   err_00,err_27,err_28,err_2B,err_40,err_44,err_45,err_46
        .addr   err_47,err_48,err_49,err_4E,err_52,err_57,err_F9,err_FA
        .addr   err_FB,err_FC,err_FD,err_FE

        ;; alert index to action (0 = Cancel, $80 = Try Again)
alert_action_table:
        .byte   kAlertOptionsDefault, kAlertOptionsDefault
        .byte   kAlertOptionsDefault, kAlertOptionsTryAgainCancel
        .byte   kAlertOptionsDefault, kAlertOptionsTryAgainCancel
        .byte   kAlertOptionsDefault, kAlertOptionsDefault
        .byte   kAlertOptionsDefault, kAlertOptionsDefault
        .byte   kAlertOptionsDefault, kAlertOptionsDefault
        .byte   kAlertOptionsDefault, kAlertOptionsDefault
        .byte   kAlertOptionsDefault, kAlertOptionsDefault
        .byte   kAlertOptionsDefault, kAlertOptionsTryAgainCancel
        .byte   kAlertOptionsTryAgainCancel, kAlertOptionsDefault

        ;; Actual entry point
start:  pha                     ; error code
        txa
        pha                     ; options
        MGTK_CALL MGTK::HideCursor
        MGTK_CALL MGTK::SetCursor, pointer_cursor
        MGTK_CALL MGTK::ShowCursor

        ;; play bell
        sta     ALTZPOFF
        sta     ROMIN2
        jsr     BELL1
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1

        ;; Set up GrafPort
        ldx     #.sizeof(MGTK::Point)-1
        lda     #0
:       sta     grafport3_viewloc_xcoord,x
        sta     grafport3_cliprect_x1,x
        dex
        bpl     :-

        copy16  #550, grafport3_cliprect_x2
        copy16  #185, grafport3_cliprect_y2
        MGTK_CALL MGTK::SetPort, grafport3

        ;; Compute save bounds
        ldax    portmap::viewloc::xcoord
        jsr     LBF8B

        sty     LBFCA
        sta     LBFCD
        lda     portmap::viewloc::xcoord
        clc
        adc     portmap::maprect::x2
        pha
        lda     portmap::viewloc::xcoord+1
        adc     portmap::maprect::x2+1
        tax
        pla
        jsr     LBF8B

        sty     LBFCC
        sta     LBFCE
        lda     portmap::viewloc::ycoord
        sta     LBFC9
        clc
        adc     portmap::maprect::y2
        sta     LBFCB

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
        sta     alert_action
        jmp     draw_buttons

:       tya
        lsr     a
        tay
        lda     alert_action_table,y
        sta     alert_action

        ;; Draw appropriate buttons
draw_buttons:
        MGTK_CALL MGTK::SetPenMode, penXOR

        bit     alert_action    ; high bit clear = Cancel
        bpl     ok_button

        ;; Cancel button
        MGTK_CALL MGTK::FrameRect, cancel_rect
        MGTK_CALL MGTK::MoveTo, cancel_pos
        addr_call draw_pascal_string, cancel_label

        bit     alert_action
        bvs     ok_button

        ;; Try Again button
        MGTK_CALL MGTK::FrameRect, try_again_rect
        MGTK_CALL MGTK::MoveTo, try_again_pos
        addr_call draw_pascal_string, try_again_label

        jmp     draw_prompt

        ;; OK button
ok_button:
        MGTK_CALL MGTK::FrameRect, try_again_rect
        MGTK_CALL MGTK::MoveTo, try_again_pos
        addr_call draw_pascal_string, ok_label

        ;; Prompt string
draw_prompt:
        MGTK_CALL MGTK::MoveTo, pos_prompt
        addr_call_indirect draw_pascal_string, prompt_addr

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
        bit     alert_action    ; has Cancel?
        bpl     check_ok        ; nope
        cmp     #CHAR_ESCAPE    ; yes, maybe Escape?
        bne     :+

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, cancel_rect
        lda     #kAlertResultCancel
        jmp     finish

:       bit     alert_action    ; has Try Again?
        bvs     check_ok        ; nope
        cmp     #'a'            ; yes, maybe A/a ?
        bne     :+
was_a:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, try_again_rect
        lda     #kAlertResultTryAgain
        jmp     finish

:       cmp     #'A'
        beq     was_a
        cmp     #CHAR_RETURN    ; also allow Return as default
        beq     was_a
        jmp     event_loop

check_ok:
        cmp     #CHAR_RETURN
        bne     :+
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, try_again_rect
        lda     #kAlertResultOK
        jmp     finish

:       jmp     event_loop

handle_button_down:
        jsr     LBDE1
        MGTK_CALL MGTK::MoveTo, event_coords
        bit     alert_action
        bpl     LBC42
        MGTK_CALL MGTK::InRect, cancel_rect
        cmp     #MGTK::inrect_inside
        bne     :+
        jmp     LBCE9
:       bit     alert_action
        bvs     LBC42
        MGTK_CALL MGTK::InRect, try_again_rect
        cmp     #MGTK::inrect_inside
        bne     LBC52
        jmp     LBC6D

LBC42:  MGTK_CALL MGTK::InRect, try_again_rect
        cmp     #MGTK::inrect_inside
        bne     LBC52
        jmp     LBD65

LBC52:  jmp     event_loop

finish: pha
        MGTK_CALL MGTK::HideCursor
        jsr     restore_dialog_background
        MGTK_CALL MGTK::ShowCursor
        pla
        rts

LBC6D:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, try_again_rect
        lda     #0
        sta     LBCE8
LBC84:  MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     LBCDB
        jsr     LBDE1
        MGTK_CALL MGTK::MoveTo, event_coords
        MGTK_CALL MGTK::InRect, try_again_rect
        cmp     #MGTK::inrect_inside
        beq     LBCB5
        lda     LBCE8
        beq     LBCBD
        jmp     LBC84

LBCB5:  lda     LBCE8
        bne     LBCBD
        jmp     LBC84

LBCBD:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, try_again_rect
        lda     LBCE8
        clc
        adc     #$80
        sta     LBCE8
        jmp     LBC84

LBCDB:  lda     LBCE8
        beq     LBCE3
        jmp     event_loop

LBCE3:  lda     #kAlertResultTryAgain
        jmp     finish

LBCE8:  .byte   0
LBCE9:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, cancel_rect
        lda     #0
        sta     LBD64
LBD00:  MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     LBD57
        jsr     LBDE1
        MGTK_CALL MGTK::MoveTo, event_coords
        MGTK_CALL MGTK::InRect, cancel_rect
        cmp     #MGTK::inrect_inside
        beq     LBD31
        lda     LBD64
        beq     LBD39
        jmp     LBD00

LBD31:  lda     LBD64
        bne     LBD39
        jmp     LBD00

LBD39:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, cancel_rect
        lda     LBD64
        clc
        adc     #$80
        sta     LBD64
        jmp     LBD00

LBD57:  lda     LBD64
        beq     LBD5F
        jmp     event_loop

LBD5F:  lda     #kAlertResultCancel
        jmp     finish

LBD64:  .byte   0
LBD65:  lda     #0
        sta     LBDE0
        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, try_again_rect
LBD7C:  MGTK_CALL MGTK::GetEvent, event_params
        lda     event_kind
        cmp     #MGTK::EventKind::button_up
        beq     LBDD3
        jsr     LBDE1
        MGTK_CALL MGTK::MoveTo, event_coords
        MGTK_CALL MGTK::InRect, try_again_rect
        cmp     #MGTK::inrect_inside
        beq     LBDAD
        lda     LBDE0
        beq     LBDB5
        jmp     LBD7C

LBDAD:  lda     LBDE0
        bne     LBDB5
        jmp     LBD7C

LBDB5:  MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::PaintRect, try_again_rect
        lda     LBDE0
        clc
        adc     #$80
        sta     LBDE0
        jmp     LBD7C

LBDD3:  lda     LBDE0
        beq     LBDDB
        jmp     event_loop

LBDDB:  lda     #kAlertResultOK
        jmp     finish


LBDE0:  .byte   0

LBDE1:  sub16   event_xcoord, portmap::viewloc::xcoord, event_xcoord
        sub16   event_ycoord, portmap::viewloc::ycoord, event_ycoord
        rts

.endproc
        show_alert_dialog := show_alert_dialog_impl::start


;;; ============================================================
;;; Save/Restore Dialog Background
;;;
;;; This reuses the "save area" ($800-$1AFF) used by MGTK for
;;; quickly restoring menu backgrounds.

.proc dialog_background

        ptr := $06

.proc save
        copy16  #SAVE_AREA_BUFFER, addr
        lda     LBFC9
        jsr     LBF10
        lda     LBFCB
        sec
        sbc     LBFC9
        tax
        inx
LBE21:  lda     LBFCA
        sta     LBE5C
LBE27:  lda     LBE5C
        lsr     a
        tay
        sta     PAGE2OFF        ; main $2000-$3FFF
        bcs     LBE34
        sta     PAGE2ON         ; aux $2000-$3FFF
LBE34:  lda     (ptr),y
        addr := *+1
        sta     dummy1234
        inc16   addr
        lda     LBE5C
        cmp     LBFCC
        bcs     LBE4E
        inc     LBE5C
        bne     LBE27
LBE4E:  jsr     LBF52
        dex
        bne     LBE21
        ldax    addr
        rts

        .byte   0
LBE5C:  .byte   0
.endproc

.proc restore
        copy16  #SAVE_AREA_BUFFER, addr
        ldx     LBFCD
        ldy     LBFCE
        lda     #$FF
        cpx     #0
        beq     LBE78
LBE73:  clc
        rol     a
        dex
        bne     LBE73
LBE78:  sta     LBF0C
        eor     #$FF
        sta     LBF0D
        lda     #$01
        cpy     #$00
        beq     LBE8B
LBE86:  sec
        rol     a
        dey
        bne     LBE86
LBE8B:  sta     LBF0E
        eor     #$FF
        sta     LBF0F
        lda     LBFC9
        jsr     LBF10
        lda     LBFCB
        sec
        sbc     LBFC9
        tax
        inx
        lda     LBFCA
        sta     LBF0B
LBEA8:  lda     LBFCA
        sta     LBF0B
LBEAE:  lda     LBF0B
        lsr     a
        tay
        sta     PAGE2OFF        ; main $2000-$3FFF
        bcs     :+
        sta     PAGE2ON         ; aux $2000-$3FFF

        addr := *+1
:       lda     SAVE_AREA_BUFFER ; self-modified

        pha
        lda     LBF0B
        cmp     LBFCA
        beq     LBEDD
        cmp     LBFCC
        bne     LBEEB
        lda     (ptr),y
        and     LBF0F
        sta     (ptr),y
        pla
        and     LBF0E
        ora     (ptr),y
        pha
        jmp     LBEEB

LBEDD:  lda     (ptr),y
        and     LBF0D
        sta     (ptr),y
        pla
        and     LBF0C
        ora     (ptr),y
        pha
LBEEB:  pla
        sta     (ptr),y
        inc16   addr
        lda     LBF0B
        cmp     LBFCC
        bcs     LBF03
        inc     LBF0B
        bne     LBEAE
LBF03:  jsr     LBF52
        dex
        bne     LBEA8
        rts

        .byte   $00
LBF0B:  .byte   $00
LBF0C:  .byte   $00
LBF0D:  .byte   $00
LBF0E:  .byte   $00
LBF0F:  .byte   $00
.endproc

;;; Address calculations for dialog background display buffer.

.proc LBF10
        sta     LBFCF
        and     #$07
        sta     LBFB0
        lda     LBFCF
        and     #$38
        sta     LBFAF
        lda     LBFCF
        and     #$C0
        sta     LBFAE
        jsr     LBF2C
        rts
.endproc

.proc LBF2C
        lda     LBFAE
        lsr     a
        lsr     a
        ora     LBFAE
        pha
        lda     LBFAF
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     LBF51
        pla
        ror     a
        sta     ptr
        lda     LBFB0
        asl     a
        asl     a
        ora     LBF51
        ora     #$20
        sta     ptr+1
        clc
        rts

LBF51:  .byte   0

.endproc

.proc LBF52
        lda     LBFB0
        cmp     #7
        beq     LBF5F
        inc     LBFB0
        jmp     LBF2C

LBF5F:  lda     #0
        sta     LBFB0
        lda     LBFAF
        cmp     #56
        beq     LBF74
        clc
        adc     #8
        sta     LBFAF
        jmp     LBF2C

LBF74:  lda     #0
        sta     LBFAF
        lda     LBFAE
        clc
        adc     #64
        sta     LBFAE
        cmp     #192
        beq     LBF89
        jmp     LBF2C

LBF89:  sec
        rts
.endproc

.endproc ; dialog_background
        save_dialog_background := dialog_background::save
        restore_dialog_background := dialog_background::restore

;;; ============================================================

.proc LBF8B
        ldy     #0
        cpx     #2
        bne     :+
        ldy     #73
        clc
        adc     #1

:       cpx     #1
        bne     :+
        ldy     #36
        clc
        adc     #4
        bcc     :+
        iny
        sbc     #7
:       cmp     #7
        bcc     :+
        sbc     #7
        iny
        bne     :-

:       rts
.endproc

LBFAE:  .byte   $00
LBFAF:  .byte   $00
LBFB0:  .byte   $00,$FF,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00
LBFC9:  .byte   $00
LBFCA:  .byte   $00
LBFCB:  .byte   $00
LBFCC:  .byte   $00
LBFCD:  .byte   $00
LBFCE:  .byte   $00
LBFCF:  .byte   $00

        ;; Draw pascal string; address in (X,A)
.proc draw_pascal_string
        PARAM_BLOCK drawtext_params, $06
data:   .addr   0
length: .byte   0
        END_PARAM_BLOCK

        stax    drawtext_params::data
        ldy     #0
        lda     (drawtext_params::data),y         ; Check length
        beq     end
        sta     drawtext_params::length
        inc16   drawtext_params::data ; skip past length
        MGTK_CALL MGTK::DrawText, drawtext_params
end:    rts
.endproc


        PAD_TO $C000

.endproc ; desktop_aux
