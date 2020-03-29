        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/macros.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk/mgtk_100B4.inc"

dummy1234       := $1234

INVOKER_PREFIX  := $0220
INVOKER_FILENAME:= $0280
INVOKER         := $0290
LOADER          := $2000
MGTK            := $4000
START           := $8E00


overlay_addr    := $A000
overlay1_offset = $6F60
overlay1_size   = $1F00
overlay2_offset = $8E60
overlay2_size   = $D00

;;; ============================================================
;;; Selector application
;;; ============================================================

        .include "selector1.s"
        .include "selector2.s"

        ;; Random chunk of BASIC.SYSTEM 1.1 padding out the file
        .incbin "inc/bs.dat"

        .include "selector3.s"
        .include "selector4.s"
        .include "selector5.s"
        .include "selector6.s"
        .include "selector7.s"
        .include "selector8.s"
