#!/bin/bash

# Use Cadius to create a disk image for distribution
# https://github.com/mach-kernel/cadius

set -e

CADIUS="${CADIUS:-$HOME/dev/cadius/bin/release/cadius}"

PACKDIR="out/package"
FINFO="$PACKDIR/_FileInformation.txt"
IMGFILE="out/DeskTop.po"
VOLNAME="A2.DESKTOP"

mkdir -p "$PACKDIR"

# Prepare _FileInformation.txt file with extra ProDOS file entry data
# and copy renamed files into package directory.

cat > "$FINFO" <<EOF
DESKTOP.SYSTEM=Type(FF),AuxType(0),VersionCreate(00),MinVersion(B9),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)
DESKTOP2=Type(F1),AuxType(0),VersionCreate(00),MinVersion(B9),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)
EOF

cp "out/sys.SYS" "$PACKDIR/DESKTOP.SYSTEM"
cp "out/DESKTOP2.built" "$PACKDIR/DESKTOP2"

# Create a new disk image.

$CADIUS CREATEVOLUME $IMGFILE $VOLNAME 143KB

# Add the files into the disk image.

for file in DESKTOP.SYSTEM DESKTOP2; do
    $CADIUS ADDFILE $IMGFILE "/$VOLNAME" $PACKDIR/$file
done

# Add an empty folder for desk accessories (which are on a separate disk).
$CADIUS CREATEFOLDER $IMGFILE "/$VOLNAME/DESK.ACC"
