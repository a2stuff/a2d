#!/bin/bash

# Run this from the top level directory

# Use nulib2 to create a ShrinkIt! archive for distribution
# https://nulib.com

set -e

PNULIB2=`which nulib2`
PNULIB2="${PNULIB2:-$HOME/dev/nulib2/nulib2/nulib2}"
NULIB2="${NULIB2:-$PNULIB2}"

set -e
source "res/util.sh"

tempdir=$(mktemp -d -t SHK)
[ -d "${tempdir}" ] || (cecho red "cannot make tempdir"; exit 1)

mkdir -p "${tempdir}/desk.acc" || (cecho red "permission denied"; exit 1)

rm -f A2D.SHK

# With $F1 type, aux type $0000
function mount_f1 {
    srcdir="$2"
    dstdir="$3"
    uppercase=$(echo "$1" | tr /a-z/ /A-Z/)
    src="$srcdir/out/$1.built"
    dst="$dstdir/$uppercase#F10000"
    cp "$src" "$dst" \
        && (cecho green "wrote $dst" ) \
        || (cecho red "failed to write $dst" ; return 1)
}

# With $F1 type, aux type $0640
function mount_da {
    srcdir="$2"
    dstdir="$3"
    uppercase=$(echo "$1" | tr /a-z/ /A-Z/)
    src="$srcdir/out/$1.da"
    dst="$dstdir/$uppercase#F10640"
    cp "$src" "$dst" \
        && (cecho green "wrote $dst" ) \
        || (cecho red "failed to write $dst" ; return 1)
}


function mount_sys {
    srcdir="$2"
    dstdir="$3"
    uppercase=$(echo "$1" | tr /a-z/ /A-Z/)
    src="$srcdir/out/$1.SYS"
    dst="$dstdir/$uppercase#FF0000"
    cp "$src" "$dst" \
        && (cecho green "wrote $dst" ) \
        || (cecho red "failed to write $dst" ; return 1)
}

echo "Copying files to ${tempdir}/"
mkdir -p mount

mount_f1 "desktop2" "desktop" "${tempdir}"
mount_sys "desktop.system" "desktop.system" "${tempdir}"

mkdir -p "${tempdir}/desk.acc"
for file in $(cat desk.acc/TARGETS); do
    mount_da "$file" "desk.acc" "${tempdir}/desk.acc"
done

mkdir -p "${tempdir}/preview"
for file in $(cat preview/TARGETS); do
    mount_da "$file" "preview" "${tempdir}/preview"
done
cdir=`pwd`
cd "${tempdir}"
nulib2 aer "${cdir}/A2D.SHK" * || (cecho red "failed to write ${cdir}/A2D.SHK" ; return 1)
cd "${cdir}"
rm -rf "${tempdir}"
ls -l A2D.SHK
