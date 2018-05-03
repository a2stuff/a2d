        .setcpu "6502"

        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"
        .include "../inc/prodos.inc"

        .org $D200
        .include "desktop_res.s"