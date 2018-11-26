#!/bin/bash

# Run this from the top level directory
source "res/util.sh"

set -e

mkdir -p mount/desk.acc

function mount_f1 {
    srcdir="$2"
    dstdir="$3"
    uppercase=$(echo "$1" | tr /a-z/ /A-Z/)
    src="$srcdir/out/$1.built"
    dst="$dstdir/$uppercase.\$F1"
    cp "$src" "$dst" \
	&& xattr -wx prodos.AuxType '40 06' "$dst" \
        && (cecho green "mounted $dst" ) \
        || (cecho red "failed to mount $dst" ; return 1)
}

function mount_sys {
    srcdir="$2"
    dstdir="$3"
    uppercase=$(echo "$1" | tr /a-z/ /A-Z/)
    src="$srcdir/out/$1.SYS"
    dst="$dstdir/$uppercase.SYS"
    cp "$src" "$dst" \
        && (cecho green "mounted $dst" ) \
        || (cecho red "failed to mount $dst" ; return 1)
}

targets=$(cat desk.acc/TARGETS)

mkdir -p mount
echo "Copying files to mount/"
for file in $targets; do
    mount_f1 "$file" "desk.acc" "mount/desk.acc"
done

mount_f1 "desktop2" "desktop" "mount"
mount_sys "desktop.system" "desktop.system" "mount"
