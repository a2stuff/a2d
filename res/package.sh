#!/bin/bash

# Use Cadius to create a disk image for distribution
# https://github.com/mach-kernel/cadius

set -e

CADIUS="${CADIUS:-$HOME/dev/cadius/bin/release/cadius}"

DA_DIRS="desk.acc preview"

PACKDIR="out/package"
FINFO="$PACKDIR/_FileInformation.txt"
IMGFILE="out/A2DeskTop.po"
VOLNAME="A2.DeskTop"

function titlecase {
    echo "$@" | perl -pne 's/(^(.)|\.(.))/uc($1)/eg'
}

mkdir -p "$PACKDIR"
echo "" > "$FINFO"

# Prepare _FileInformation.txt file with extra ProDOS file entry data
# and copy renamed files into package directory.

for da_dir in $DA_DIRS; do
    for file in $(cat $da_dir/TARGETS); do
        tcfile=$(titlecase $file)
        echo "$tcfile=Type(F1),AuxType(0640),VersionCreate(00),MinVersion(00),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)" >> "$FINFO"
        cp "$da_dir/out/$file.da" "out/package/$tcfile"
    done
done

cat >> "$FINFO" <<EOF
DeskTop.system=Type(FF),AuxType(0),VersionCreate(00),MinVersion(00),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)
DeskTop2=Type(F1),AuxType(0),VersionCreate(00),MinVersion(00),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)
ProDOS=Type(FF),AuxType(0),VersionCreate(00),MinVersion(00),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)
BASIC.system=Type(FF),AuxType(0),VersionCreate(00),MinVersion(00),Access(E3),FolderInfo1(000000000000000000000000000000000000),FolderInfo2(000000000000000000000000000000000000)
EOF

cp "desktop.system/out/desktop.system.SYS" "$PACKDIR/DeskTop.system"
cp "desktop/out/DESKTOP2.built" "$PACKDIR/DeskTop2"

# If ProDOS/BASIC.system are present in res/, install them too.
if [ -e "res/package/PRODOS" ]; then
    cp "res/package/PRODOS" "$PACKDIR/ProDOS"
fi
if [ -e "res/package/BASIC.SYSTEM" ]; then
    cp "res/package/BASIC.SYSTEM" "$PACKDIR/BASIC.system"
fi

# Create a new disk image.

rm -f $IMGFILE

$CADIUS CREATEVOLUME $IMGFILE $VOLNAME 800KB
for da_dir in $DA_DIRS; do
    $CADIUS CREATEFOLDER $IMGFILE "/$VOLNAME/$(titlecase $da_dir)"
done

# Add the files into the disk image.

for da_dir in $DA_DIRS; do
    for file in $(cat $da_dir/TARGETS); do
        $CADIUS ADDFILE $IMGFILE "/$VOLNAME/$(titlecase $da_dir)" "$PACKDIR/$(titlecase $file)"
    done
done

for file in DeskTop.system DeskTop2; do
    $CADIUS ADDFILE $IMGFILE "/$VOLNAME" "$PACKDIR/$file"
done

for file in ProDOS BASIC.system; do
    if [ -e "$PACKDIR/$file" ]; then
        $CADIUS ADDFILE $IMGFILE "/$VOLNAME" "$PACKDIR/$file"
    fi
done
