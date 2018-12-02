#!/bin/bash

# Run this from the ram.system directory

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

SOURCES="ram.system"

# Verify original and output match
echo "Verifying diffs:"
verify "RAM.SYSTEM.SYS" "ram.system.SYS"

# Compute stats
echo "Stats:"
for t in $SOURCES; do
    stats "$t.s"
done;
