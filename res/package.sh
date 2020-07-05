#!/usr/bin/env bash

# Use Cadius to create disk images for distribution
# https://github.com/mach-kernel/cadius

set -e
source "res/util.sh"

if ! command -v "cadius" >/dev/null; then
    cecho red "Cadius not installed."
    exit 1
fi

cecho yellow "Building disk images"

tempdir=$(mktemp -d -t SHK)
test -d "${tempdir}" || (cecho red "cannot make tempdir"; exit 1)

# One 800k image (complete), and two 140k images (two parts).

mkdir out
IMGFILE_COMPLETE="out/A2DeskTop.po"
IMGFILE_PART1="out/A2DeskTop.1.po"
IMGFILE_PART2="out/A2DeskTop.2.po"

VOLNAME_COMPLETE="A2.DeskTop"
VOLNAME_PART1="A2.DeskTop.1"
VOLNAME_PART2="A2.DeskTop.2"

# Create disk images.

rm -f $IMGFILE_COMPLETE
rm -f $IMGFILE_PART1
rm -f $IMGFILE_PART2

cadius CREATEVOLUME $IMGFILE_COMPLETE $VOLNAME_COMPLETE 800KB --quiet --no-case-bits > /dev/null

cadius CREATEVOLUME $IMGFILE_PART1 $VOLNAME_PART1 140KB --quiet --no-case-bits > /dev/null
cadius CREATEVOLUME $IMGFILE_PART2 $VOLNAME_PART2 140KB --quiet --no-case-bits > /dev/null

# Add the files into the disk images.
# Usage: add_file IMGFILE SRCFILE DSTFOLDER DSTFILE TYPESUFFIX
add_file () {
    img_file="$1"
    src_file="$2"
    folder="$3"
    dst_file="$4"
    suffix="$5"
    tmp_file="$tempdir/$dst_file#$suffix"

    cp "$src_file" "$tmp_file"
    cadius ADDFILE "$img_file" "$folder" "$tmp_file" --quiet --no-case-bits > /dev/null
    rm "$tmp_file"
}

# Add ProDOS, if present in res/package
if [ -e "res/package/PRODOS" ]; then
    add_file $IMGFILE_COMPLETE "res/package/PRODOS" "/$VOLNAME_COMPLETE" "ProDOS" FF0000
fi

perl -p -i -e 's/\r?\n/\r/g' "res/package/READ.ME" # Ensure Apple line endings
add_file $IMGFILE_COMPLETE "res/package/READ.ME" "/$VOLNAME_COMPLETE" "Read.Me" 040000
add_file $IMGFILE_PART1 "res/package/READ.ME" "/$VOLNAME_PART1" "Read.Me" 040000

add_file $IMGFILE_COMPLETE "desktop.system/out/desktop.system.SYS" "/$VOLNAME_COMPLETE" "DeskTop.system" FF0000
add_file $IMGFILE_PART1 "desktop.system/out/desktop.system.SYS" "/$VOLNAME_PART1" "DeskTop.system" FF0000

add_file $IMGFILE_COMPLETE "desktop/out/desktop.built" "/$VOLNAME_COMPLETE" "DeskTop2" F10000
add_file $IMGFILE_PART1 "desktop/out/desktop.built" "/$VOLNAME_PART1" "DeskTop2" F10000

cadius CREATEFOLDER $IMGFILE_COMPLETE "/$VOLNAME_COMPLETE/Optional" --quiet --no-case-bits > /dev/null
cadius CREATEFOLDER $IMGFILE_PART2 "/$VOLNAME_PART2/Optional" --quiet --no-case-bits > /dev/null

add_file $IMGFILE_COMPLETE "selector/out/selector.built" "/$VOLNAME_COMPLETE/Optional" "Selector" F10000
add_file $IMGFILE_PART2 "selector/out/selector.built" "/$VOLNAME_PART2/Optional" "Selector" F10000

for path in $(cat desk.acc/TARGETS | res/targets.pl dirs); do
    cadius CREATEFOLDER $IMGFILE_COMPLETE "/$VOLNAME_COMPLETE/$path" --quiet --no-case-bits > /dev/null
    cadius CREATEFOLDER $IMGFILE_COMPLETE "/$VOLNAME_PART2/$path" --quiet --no-case-bits > /dev/null
done
for line in $(cat desk.acc/TARGETS | res/targets.pl); do
    IFS=',' read -ra array <<< "$line"
    file="${array[0]}"
    path="${array[1]}"
    add_file "$IMGFILE_COMPLETE" "desk.acc/out/$file.da" "/$VOLNAME_COMPLETE/$path" $file F10640
    add_file "$IMGFILE_PART2" "desk.acc/out/$file.da" "/$VOLNAME_PART2/$path" $file F10640
done

# Add BASIC.SYSTEM, if present in res/package
if [ -e "res/package/BASIC.SYSTEM" ]; then
    add_file "$IMGFILE_COMPLETE" "res/package/BASIC.SYSTEM" "/$VOLNAME_COMPLETE" "BASIC.system" FF2000
fi


# Verify and clean up

cecho green "Catalog of 800k disk:"
cadius CATALOG $IMGFILE_COMPLETE --quiet

cecho green "Catalog of 140k disk 1:"
cadius CATALOG $IMGFILE_PART1 --quiet

cecho green "Catalog of 140k disk 2:"
cadius CATALOG $IMGFILE_PART2 --quiet

rmdir "$tempdir"
