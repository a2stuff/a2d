;;; ============================================================
;;; ROUND.CORNERS - Desk Accessory
;;;
;;; Hack that rounds the corners of the screen.
;;; ============================================================

        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../desktop/desktop.inc"

;;; ============================================================

        DA_HEADER
        DA_START_AUX_SEGMENT

;;; ============================================================

kRoundWidth = 7
kRoundHeight = 5

grafport:
        .tag    MGTK::GrafPort
penmode:
        .byte   MGTK::penBIC

nw_bitmap:
        PIXELS  "#######"
        PIXELS  "####..."
        PIXELS  "##....."
        PIXELS  "#......"
        PIXELS  "#......"
.params nw_params
        DEFINE_POINT viewloc, 0, 0
mapbits:        .addr   nw_bitmap
mapwidth:       .byte   1
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kRoundWidth-1, kRoundHeight-1
.endparams

ne_bitmap:
        PIXELS  "#######"
        PIXELS  "...####"
        PIXELS  ".....##"
        PIXELS  "......#"
        PIXELS  "......#"
.params ne_params
        DEFINE_POINT viewloc, kScreenWidth-kRoundWidth, 0
mapbits:        .addr   ne_bitmap
mapwidth:       .byte   1
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kRoundWidth-1, kRoundHeight-1
.endparams

sw_bitmap:
        PIXELS  "#......"
        PIXELS  "#......"
        PIXELS  "##....."
        PIXELS  "####..."
        PIXELS  "#######"
.params sw_params
        DEFINE_POINT viewloc, 0, kScreenHeight-kRoundHeight
mapbits:        .addr   sw_bitmap
mapwidth:       .byte   1
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kRoundWidth-1, kRoundHeight-1
.endparams

se_bitmap:
        PIXELS  "......#"
        PIXELS  "......#"
        PIXELS  ".....##"
        PIXELS  "...####"
        PIXELS  "#######"
.params se_params
        DEFINE_POINT viewloc, kScreenWidth-kRoundWidth, kScreenHeight-kRoundHeight
mapbits:        .addr   se_bitmap
mapwidth:       .byte   1
reserved:       .byte   0
        DEFINE_RECT maprect, 0, 0, kRoundWidth-1, kRoundHeight-1
.endparams

;;; ============================================================

        DA_END_AUX_SEGMENT

;;; ============================================================

        DA_START_MAIN_SEGMENT

.proc Run
        JUMP_TABLE_MGTK_CALL MGTK::InitPort, aux::grafport
        JUMP_TABLE_MGTK_CALL MGTK::SetPort, aux::grafport
        JUMP_TABLE_MGTK_CALL MGTK::HideCursor
        JUMP_TABLE_MGTK_CALL MGTK::SetPenMode, aux::penmode
        JUMP_TABLE_MGTK_CALL MGTK::PaintBits, aux::nw_params
        JUMP_TABLE_MGTK_CALL MGTK::PaintBits, aux::ne_params
        JUMP_TABLE_MGTK_CALL MGTK::PaintBits, aux::sw_params
        JUMP_TABLE_MGTK_CALL MGTK::PaintBits, aux::se_params
        JUMP_TABLE_MGTK_CALL MGTK::ShowCursor
        rts
.endproc ; Run

        DA_END_MAIN_SEGMENT

;;; ============================================================
