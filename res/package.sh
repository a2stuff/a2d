#!/bin/bash

# Use Cadius to create a disk image for distribution
# https://github.com/mach-kernel/cadius

set -e

CADIUS="${CADIUS:-$HOME/dev/cadius/bin/release/cadius}"

DAS=$(cat desk.acc/TARGETS)
PRS=$(cat preview/TARGETS)

PACKDIR="out/package"
FINFO="$PACKDIR/_FileInformation.txt"
IMGFILE="out/A2DeskTop.po"
VOLNAME="A2.DeskTop"

mkdir -p "$PACKDIR"
echo "" > "$FINFO"

# Prepare _FileInformation.txt file with extra ProDOS file entry data
# and copy renamed files into package directory.

for file in $DAS; do
    ucfile=$(echo $file | tr a-z A-Z)
    echo "$ucfile=Type(F1),AuxType(0640),VersionCreate(00),MinVersion(00),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)" >> "$FINFO"
    cp "desk.acc/out/$file.built" "out/package/$ucfile"
done
for file in $PRS; do
    ucfile=$(echo $file | tr a-z A-Z)
    echo "$ucfile=Type(F1),AuxType(0640),VersionCreate(00),MinVersion(00),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)" >> "$FINFO"
    cp "preview/out/$file.built" "out/package/$ucfile"
done

cat >> "$FINFO" <<EOF
DeskTop.system=Type(FF),AuxType(0),VersionCreate(00),MinVersion(00),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)
DeskTop2=Type(F1),AuxType(0),VersionCreate(00),MinVersion(00),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)
EOF

cp "desktop.system/out/desktop.system.SYS" "$PACKDIR/DeskTop.system"
cp "desktop/out/DESKTOP2.built" "$PACKDIR/DeskTop2"

# Create a new disk image.

$CADIUS CREATEVOLUME $IMGFILE $VOLNAME 800KB
$CADIUS CREATEFOLDER $IMGFILE "/$VOLNAME/Desk.Acc"
$CADIUS CREATEFOLDER $IMGFILE "/$VOLNAME/Preview"

# Add the files into the disk image.

for file in $DAS; do
    ucfile=$(echo $file | tr a-z A-Z)
    $CADIUS ADDFILE $IMGFILE "/$VOLNAME/Desk.Acc" $PACKDIR/$ucfile
done

for file in $PRS; do
    ucfile=$(echo $file | tr a-z A-Z)
    $CADIUS ADDFILE $IMGFILE "/$VOLNAME/Preview" $PACKDIR/$ucfile
done

for file in DeskTop.system DeskTop2; do
    $CADIUS ADDFILE $IMGFILE "/$VOLNAME" $PACKDIR/$file
done
