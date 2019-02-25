#!/bin/bash

# Run this from the top level directory

set -e
source "res/util.sh"

mkdir -p mount/desk.acc || (cecho red "permission denied"; exit 1)

# Mount file xxx.built as $F1 file
function mount_f1 {
    srcdir="$2"
    dstdir="$3"
    uppercase=$(echo "$1" | tr /a-z/ /A-Z/)
    src="$srcdir/out/$1.built"
    dst="$dstdir/$uppercase.\$F1"
    cp "$src" "$dst" \
        && (cecho green "mounted $dst" ) \
        || (cecho red "failed to mount $dst" ; return 1)
}

# Mount file xxx.built as $F1 file, with DA auxtype
function mount_da {
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

# Mount file xxx.SYS as SYS file
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

echo "Copying files to mount/"
mkdir -p mount

mount_f1 "desktop2" "desktop" "mount"
mount_sys "desktop.system" "desktop.system" "mount"

mkdir -p mount/desk.acc
for file in $(cat desk.acc/TARGETS); do
    mount_da "$file" "desk.acc" "mount/desk.acc"
done

mkdir -p mount/preview
for file in $(cat preview/TARGETS); do
    mount_da "$file" "preview" "mount/preview"
done
