#!/bin/bash

# Use Cadius to create a disk image for distribution
# https://github.com/mach-kernel/cadius

set -e

CADIUS="${CADIUS:-$HOME/dev/cadius/bin/release/cadius}"

DAS="calculator show.text.file date puzzle sort.directory \
    show.image.file this.apple eyes"

PACKDIR="out/package"
FINFO="$PACKDIR/_FileInformation.txt"
IMGFILE="out/DeskAccessories.po"
VOLNAME="DESK.ACC"

mkdir -p "$PACKDIR"
echo "" > "$FINFO"

# Prepare _FileInformation.txt file with extra ProDOS file entry data
# and copy renamed files into package directory.

for file in $DAS; do
    ucfile=$(echo $file | tr a-z A-Z)
    echo "$ucfile=Type(F1),AuxType(0640),VersionCreate(00),MinVersion(B9),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)" >> "$FINFO"
    cp "out/$file.built" "out/package/$ucfile"
done

# Create a new disk image.

$CADIUS CREATEVOLUME $IMGFILE $VOLNAME 143KB

# Add the files into the disk image.

for file in $DAS; do
    ucfile=$(echo $file | tr a-z A-Z)
    $CADIUS ADDFILE $IMGFILE "/$VOLNAME" $PACKDIR/$ucfile
done
