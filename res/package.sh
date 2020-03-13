#!/usr/bin/env bash

# Use Cadius to create disk images for distribution
# https://github.com/mach-kernel/cadius

set -e

tput setaf 2 && echo "Building disk images" && tput sgr0

if ! command -v "cadius" >/dev/null; then
    tput setaf 1 && echo "Cadius not installed." && tput sgr0
    exit 1
fi

DA_DIRS="desk.acc preview"

PACKDIR="out/package"

# One 800k image (complete), and two 140k images (two parts).

IMGFILE_COMPLETE="out/A2DeskTop.po"
IMGFILE_PART1="out/A2DeskTop.1.po"
IMGFILE_PART2="out/A2DeskTop.2.po"

VOLNAME_COMPLETE="A2.DeskTop"
VOLNAME_PART1="A2.DeskTop.1"
VOLNAME_PART2="A2.DeskTop.2"

function titlecase {
    echo "$@" | perl -pne 's/(^(.)|\.(.))/uc($1)/eg'
}

mkdir -p $PACKDIR

# Create disk images.

rm -f $IMGFILE_COMPLETE
rm -f $IMGFILE_PART1
rm -f $IMGFILE_PART2

cadius CREATEVOLUME $IMGFILE_COMPLETE $VOLNAME_COMPLETE 800KB --quiet --no-case-bits

cadius CREATEVOLUME $IMGFILE_PART1 $VOLNAME_PART1 140KB --quiet --no-case-bits
cadius CREATEVOLUME $IMGFILE_PART2 $VOLNAME_PART2 140KB --quiet --no-case-bits

# Add the files into the disk images.

add_file () {
    img_file="$1"
    src_file="$2"
    folder="$3"
    dst_file="$4"
    suffix="$5"
    tmp_file="$PACKDIR/$dst_file#$suffix"

    cp "$src_file" "$tmp_file"
    cadius ADDFILE "$img_file" "$folder" "$tmp_file" --quiet --no-case-bits
    rm "$tmp_file"
}

# Add ProDOS, if present in res/package
if [ -e "res/package/PRODOS" ]; then
    add_file $IMGFILE_COMPLETE "res/package/PRODOS" "/$VOLNAME_COMPLETE" "ProDOS" FF0000
fi

add_file $IMGFILE_COMPLETE "desktop.system/out/desktop.system.SYS" "/$VOLNAME_COMPLETE" "DeskTop.system" FF0000
add_file $IMGFILE_PART1 "desktop.system/out/desktop.system.SYS" "/$VOLNAME_PART1" "DeskTop.system" FF0000

add_file $IMGFILE_COMPLETE "desktop/out/DESKTOP2.built" "/$VOLNAME_COMPLETE" "DeskTop2" F10000
add_file $IMGFILE_PART1 "desktop/out/DESKTOP2.built" "/$VOLNAME_PART1" "DeskTop2" F10000

for da_dir in $DA_DIRS; do
    folder1="/$VOLNAME_COMPLETE/$(titlecase $da_dir)"
    folder2="/$VOLNAME_PART2/$(titlecase $da_dir)"
    cadius CREATEFOLDER $IMGFILE_COMPLETE $folder1 --quiet --no-case-bits
    cadius CREATEFOLDER $IMGFILE_PART2 $folder2 --quiet --no-case-bits
    for file in $(cat $da_dir/TARGETS); do
        add_file "$IMGFILE_COMPLETE" "$da_dir/out/$file.da" $folder1 $(titlecase $file) F10640
        add_file "$IMGFILE_PART2" "$da_dir/out/$file.da" $folder2 $(titlecase $file) F10640
    done
done

# Add BASIC.SYSTEM, if present in res/package
if [ -e "res/package/BASIC.SYSTEM" ]; then
    add_file "$IMGFILE_COMPLETE" "res/package/BASIC.SYSTEM" "/$VOLNAME_COMPLETE" "BASIC.system" FF2000
fi


# Verify and clean up

tput setaf 2 && echo "Catalog of 800k disk:" && tput sgr0
cadius CATALOG $IMGFILE_COMPLETE --quiet

tput setaf 2 && echo "Catalog of 140k disk 1:" && tput sgr0
cadius CATALOG $IMGFILE_PART1 --quiet

tput setaf 2 && echo "Catalog of 140k disk 2:" && tput sgr0
cadius CATALOG $IMGFILE_PART2 --quiet

rmdir "$PACKDIR"
