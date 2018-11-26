#!/bin/bash

# Run this from the top level directory

set -e

cd desktop.system
res/go.sh
cd ..

cd desktop
res/go.sh
cd ..

cd desk.acc
res/go.sh
cd ..

# Mountable directory for Virtual ][
if [ -d mount ]; then
    res/mount.sh
fi
