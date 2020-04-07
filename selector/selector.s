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
LOADER          := $2000
MGTK            := $4000
FONT            := $8800
START           := $8E00

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

        .include "selector1.s"
        .include "selector2.s"

        ;; Ensure selector3 starts at correct offset from start of file.
        .res 473

        .include "selector3.s"
        .include "selector4.s"
        .include "selector5.s"
        .include "selector6.s"
        .include "selector7.s"
        .include "selector8.s"
