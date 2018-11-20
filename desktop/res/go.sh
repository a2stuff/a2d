#!/bin/bash

# Run this from the desktop directory

set -e
source "../res/util.sh"

function stats {
    echo "$(printf '%-15s' $1)""$(../res/stats.pl < $1)"
}

#do_make clean
do_make all

COMMON="loader mgtk"
TARGETS="$COMMON desktop"
SOURCES="$COMMON desktop_main desktop_res desktop_aux invoker ovl1 ovl1a ovl1b ovl1c ovl2 ovl3 ovl4 ovl5 ovl6 ovl7"

# Compute stats
echo "Stats:"
for t in $SOURCES; do
    stats "$t.s"
done;

# Mountable directory for Virtual ][
if [ -d mount ]; then
    res/mount.sh
fi
