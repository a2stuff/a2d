#!/usr/bin/env bash

set -e

CC65=~/dev/cc65/bin
CAFLAGS="--target apple2enh --list-bytes 0"
LDFLAGS="--config apple2-asm.cfg"


function doseg {
    #../../desk.acc/res/make_info.pl $2 < "DESKTOP2_seg_$1" > "seg_$1.info"
    echo ".org \$$2" > "seg_$1.s"
    $CC65/da65 "DESKTOP2_seg_$1" --info "seg_$1.info" >> "seg_$1.s"
    $CC65/ca65 $CAFLAGS --listing "seg_$1.list" -o "seg_$1.o" "seg_$1.s"
    $CC65/ld65 $LDFLAGS -o "seg_$1.built" "seg_$1.o"
    diff "DESKTOP2_seg_$1" "seg_$1.built"
}


doseg s0_loader 2000

doseg s1_aux1 4000
doseg s2_aux2 D000
doseg s3_aux3 FB00
doseg s4_main1 4000

#doseg 12680_1BCDF
