#!/bin/bash

# Run this from the desktop.system directory

set -e
source "../res/util.sh"

function stats {
    echo "$(printf '%-15s' $1)""$(../res/stats.pl < $1)"
}

#do_make clean
do_make all

SOURCES="desktop.system"

# Compute stats
echo "Stats:"
for t in $SOURCES; do
    stats "$t.s"
done;
