#!/usr/bin/env bash

set -e

CC65=~/dev/cc65/bin
CAFLAGS="--target apple2enh --list-bytes 0"
LDFLAGS="--config apple2-asm.cfg"


function daseg {
    #../../desk.acc/res/make_info.pl $2 < "orig/DESKTOP2_$1" > "infos/$1.info"
    echo ".org \$$2" > "$1.s"
    $CC65/da65 "orig/DESKTOP2_$1" --info "infos/$1.info" >> "$1.s"
}
function asmseg {
    $CC65/ca65 $CAFLAGS --listing "$1.list" -o "$1.o" "$1.s"
    $CC65/ld65 $LDFLAGS -o "$1.built" "$1.o"
    diff "orig/DESKTOP2_$1" "$1.built" && echo "$1 ok"
}


#daseg s0_loader 2000
#asmseg s0_loader 2000

# s1 has been disassembled by hand
asmseg s1_aux1 4000

# s2 has been disassembled by hand
asmseg s2_aux2 D000

# s3 has been disassembled by hand
asmseg s3_aux3 D000

#daseg s4_main1 4000
#asmseg s4_main1 4000

#daseg 12680_1BCDF
#asmseg 12680_1BCDF
