#!/bin/bash

set -e

function cecho {
    case $1 in
        red)    tput setaf 1 ;;
        green)  tput setaf 2 ;;
        yellow) tput setaf 3 ;;
    esac
    echo -e "$2"
    tput sgr0
}

function do_make {
    make $MAKE_FLAGS "$1" \
        && (cecho green "make $1 good") \
        || (tput blink ; cecho red "MAKE $1 BAD" ; return 1)
}

function verify {
    diff "orig/$1" "out/$2" \
        && (cecho green "diff $2 good" ) \
        || (tput blink ; cecho red "DIFF $2 BAD" ; return 1)
}

function stats {
    echo "$(printf '%-15s' $1)""$(../res/stats.pl < $1)"
}

#do_make clean
do_make all

COMMON="loader mgtk invoker ovl1 ovl1a ovl1b ovl1c ovl2"
TARGETS="desktop $COMMON ovl34567"
SOURCES="sys desktop_main desktop_res desktop_aux $COMMON ovl3 ovl4 ovl5 ovl6 ovl7"

# Verify original and output match
echo "Verifying diffs:"
for t in $TARGETS; do
    verify "DESKTOP2_$t" "$t.built"
done;
verify "DESKTOP.SYSTEM.SYS" "sys.SYS"

# Compute stats
echo "Stats:"
for t in $SOURCES; do
    stats "$t.s"
done;
