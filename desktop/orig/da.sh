#!/usr/bin/env bash

set -e

CC65=~/dev/cc65/bin
CAFLAGS="--target apple2enh --list-bytes 0"
LDFLAGS="--config apple2-asm.cfg"


function doseg {
    ../../desk.acc/res/make_info.pl $2 < "DESKTOP2_seg_$1" > "seg_$1.info"
    echo ".org \$$2" > "seg_$1.s"
    $CC65/da65 "DESKTOP2_seg_$1" --info "seg_$1.info" >> "seg_$1.s"
    $CC65/ca65 $CAFLAGS --listing "seg_$1.list" -o "seg_$1.o" "seg_$1.s"
    $CC65/ld65 $LDFLAGS -o "seg_$1.built" "seg_$1.o"
    diff "DESKTOP2_seg_$1" "seg_$1.built"
}

# Aux Memory Segment
#doseg 00000_0057F 2000
#doseg 00580_0857F 4000
#doseg 08580_0A27F D000
#doseg 0A280_0A77F FB00

#doseg 0A780_1267F 4000

#doseg 12680_1BCDF
