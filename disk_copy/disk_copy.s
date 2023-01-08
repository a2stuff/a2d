        .include "../config.inc"

        BTK_SHORT = 1

        .include "apple2.inc"
        .include "opcodes.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../inc/smartport.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "../toolkits/btk.inc"
        .include "disk_copy.inc"

;;; ============================================================
;;; Memory Constants

;;; MGTK - left over in Aux by DeskTop
MGTKAuxEntry    := $4000

;;; Font - left over in  Aux by DeskTop
DEFAULT_FONT    := $8680

;;; Settings - loaded over top of auxlc
SETTINGS        := kSegmentAuxLCAddress + kSegmentAuxLCLength - .sizeof(DeskTopSettings)

;;; Alert Sound - ditto
BELLDATA        := SETTINGS - kBellProcLength

;;; ============================================================
;;; File Segments

        INITSEG 0
        DEFSEG Loader,          DISK_COPY_BOOTSTRAP, kDiskCopyBootstrapLength
        DEFSEG SegmentAuxLC,    $D000, $2400
        DEFSEG SegmentMain,     $0800, $0C00

;;; ============================================================
;;; Disk Copy application

        RESOURCE_FILE "disk_copy.res"

        .include "loader.s"
        .include "auxlc.s"
        .include "main.s"
