#!/usr/bin/env bash

set -e

CC65=~/dev/cc65/bin

function daseg {
    #../../desk.acc/res/make_info.pl $2 < "orig/DESKTOP2_$1" > "infos/$1.info"
    echo ".org \$$2" > "$1.s"
    $CC65/da65 "orig/DESKTOP2_$1" --info "infos/$1.info" >> "$1.s"
}

#daseg s0_loader 2000
daseg s4_main1 4000
#daseg 12680_1BCDF

make
make check
