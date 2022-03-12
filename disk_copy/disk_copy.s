        .include "../config.inc"

        .include "apple2.inc"
        .include "opcodes.inc"
        .include "../inc/apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/prodos.inc"
        .include "../inc/smartport.inc"
        .include "../mgtk/mgtk.inc"
        .include "../common.inc"
        .include "disk_copy.inc"

;;; ============================================================
;;; Memory Constants

;;; MGTK - left over in Aux by DeskTop
MGTKAuxEntry    := $4000

;;; Font - left over in  Aux by DeskTop
DEFAULT_FONT    := $8800

;;; Settings - loaded over top of auxlc
SETTINGS        := $F200 - .sizeof(DeskTopSettings)

;;; Alert Sound - ditto
BELLDATA        := SETTINGS - kBellProcLength

;;; ============================================================
;;; File Segments

_segoffset .set 0
.macro DEFSEG name, addr, len
        .ident(.sprintf("k%sAddress", .string(name))) = addr
        .ident(.sprintf("k%sLength", .string(name))) = len
        .ident(.sprintf("k%sOffset", .string(name))) = _segoffset
        _segoffset .set _segoffset + len
.endmacro

;;; Segments
        DEFSEG Loader,             DISK_COPY_BOOTSTRAP, kDiskCopyBootstrapLength
        DEFSEG OverlayDiskCopy3,   $D000, $2200
        DEFSEG OverlayDiskCopy4,   $0800, $0B00

;;; ============================================================
;;; Disk Copy application

.scope disk_copy
        .include "loader.s"
        .include "auxlc.s"
        .include "main.s"
.endscope
