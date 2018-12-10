#!/bin/bash

# Use Cadius to create a disk image for distribution
# https://github.com/mach-kernel/cadius

set -e

CADIUS="${CADIUS:-$HOME/dev/cadius/bin/release/cadius}"

DAS=$(cat desk.acc/TARGETS)

PACKDIR="out/package"
FINFO="$PACKDIR/_FileInformation.txt"
IMGFILE="out/A2DeskTop.po"
VOLNAME="A2.DESKTOP"

mkdir -p "$PACKDIR"
echo "" > "$FINFO"

# Prepare _FileInformation.txt file with extra ProDOS file entry data
# and copy renamed files into package directory.

for file in $DAS; do
    ucfile=$(echo $file | tr a-z A-Z)
    echo "$ucfile=Type(F1),AuxType(0640),VersionCreate(00),MinVersion(B9),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)" >> "$FINFO"
    cp "desk.acc/out/$file.built" "out/package/$ucfile"
done

cat > "$FINFO" <<EOF
DESKTOP.SYSTEM=Type(FF),AuxType(0),VersionCreate(00),MinVersion(B9),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)
DESKTOP2=Type(F1),AuxType(0),VersionCreate(00),MinVersion(B9),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)
EOF

cp "desktop.system/out/desktop.system.SYS" "$PACKDIR/DESKTOP.SYSTEM"
cp "desktop/out/DESKTOP2.built" "$PACKDIR/DESKTOP2"

# Create a new disk image.

$CADIUS CREATEVOLUME $IMGFILE $VOLNAME 800KB
$CADIUS CREATEFOLDER $IMGFILE "/$VOLNAME/DESK.ACC"

# Add the files into the disk image.

for file in $DAS; do
    ucfile=$(echo $file | tr a-z A-Z)
    $CADIUS ADDFILE $IMGFILE "/$VOLNAME/DESK.ACC" $PACKDIR/$ucfile
done

for file in DESKTOP.SYSTEM DESKTOP2; do
    $CADIUS ADDFILE $IMGFILE "/$VOLNAME" $PACKDIR/$file
done
