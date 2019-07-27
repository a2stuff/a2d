#!/bin/bash

# Run this from the desktop directory

set -e
source "../res/util.sh"

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

TARGETS="loader mgtk desktop"
SOURCES="loader ../mgtk/mgtk desktop_main desktop_res desktop_aux invoker ovl1 ovl1a ovl1b ovl1c ovl2 ovl3 ovl4 ovl5 ovl6 ovl7"

# Verify original and output match
echo "Verifying diffs:"
for t in $TARGETS; do
    verify "DESKTOP2_$t" "$t.built"
done;
verify "DESKTOP2.\$F1" "DESKTOP2.built"

# Compute stats
echo "Stats:"
for t in $SOURCES; do
    stats "$t.s"
done;
