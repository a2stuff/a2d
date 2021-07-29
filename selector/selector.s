        .include "../config.inc"

        .include "apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"

INVOKER_PREFIX  := $0220
INVOKER_FILENAME:= $0280
INVOKER         := $0290
SAVE_AREA_BUFFER:= $0800
LOADER          := $2000
MGTK            := $4000
MGTK::MLI       := MGTK
FONT            := $8800
START           := $8E00

SETTINGS        := $8D80

.enum AlertID
selector_unable_to_run  = $00
io_error                = $27
no_device               = $28
pathname_does_not_exist = $44
insert_source_disk      = $45
file_not_found          = $46
insert_system_disk      = $FE
basic_system_not_found  = $FF
.endenum

kAlertResultTryAgain    = 0
kAlertResultCancel      = 1
kAlertResultOK          = 0     ; NOTE: Different than DeskTop (=2)

;;; SELECTOR file structure

kInvokerOffset          = $600
kInvokerSegmentSize     = $160
kAppSegmentSize         = $6200
kAlertSegmentSize       = $800
OVERLAY_ADDR            := MGTK + kAppSegmentSize
kOverlay1Offset         = kInvokerOffset + kInvokerSegmentSize + kAppSegmentSize + kAlertSegmentSize
kOverlay1Size           = $1D00
kOverlay2Offset         = kOverlay1Offset + kOverlay1Size
kOverlay2Size           = $D00

;;; ============================================================
;;; Selector application
;;; ============================================================

        .include "bootstrap.s"
        .include "quit_handler.s"

        ;; Ensure loader.starts at correct offset from start of file.
        .res 473

        .include "loader.s"
        .include "invoker.s"
        .include "app.s"
        .include "alert_dialog.s"
        .include "ovl_file_dialog.s"
        .include "ovl_file_copy.s"
