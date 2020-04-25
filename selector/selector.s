        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"

dummy0000       := $0000
dummy1234       := $1234

INVOKER_PREFIX  := $0220
INVOKER_FILENAME:= $0280
INVOKER         := $0290
SAVE_AREA_BUFFER:= $0800
LOADER          := $2000
MGTK            := $4000
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

kInvokerSegmentSize     = $160
kAppSegmentSize         = $6000
kResourcesSegmentSize   = $800
OVERLAY_ADDR            := $A000
kOverlay1Offset         = $6F60
kOverlay1Size           = $1F00
kOverlay2Offset         = $8E60
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
