#!/bin/bash

# Run this from the top level directory

set -e
source "res/util.sh"

for i in desktop desk.acc desktop.system; do
    cecho yellow Building: $i
    cd $i
    res/go.sh
    cd ..
done

# Mountable directory for Virtual ][
if [ -d mount ]; then
    res/mount.sh
fi
