#!/usr/bin/env bash

# Use Cadius to install A2D onto an existing file.
# https://github.com/mach-kernel/cadius
#
# Usage:
#
#   INSTALL_IMG=/path/to/hd.2mg INSTALL_PATH=/hd/a2.desktop bin/install.sh

set -e
source "bin/util.sh"

if [ -z "$INSTALL_IMG" ]; then
    cecho red "Variable \$INSTALL_IMG not set, aborting."
    exit 1
fi
if [ -z "$INSTALL_PATH" ]; then
    cecho red "Variable \$INSTALL_PATH not set, aborting."
    exit 1
fi
if ! command -v "cadius" >/dev/null; then
    cecho red "Cadius not installed."
    exit 1
fi

cecho yellow "Installing into image: $INSTALL_IMG at path: $INSTALL_PATH"

PACKDIR="out/install"

mkdir -p $PACKDIR

# Add the files into the disk images.
# Usage: add_file IMGFILE SRCFILE DSTFOLDER DSTFILE TYPESUFFIX
add_file () {
    img_file="$1"
    src_file="$2"
    folder="$3"
    dst_file="$4"
    suffix="$5"
    tmp_file="$PACKDIR/$dst_file#$suffix"

    cecho green "- $folder/$dst_file"

    cp "$src_file" "$tmp_file"
    suppress cadius DELETEFILE "$img_file" "$folder/$dst_file"
    suppress cadius ADDFILE "$img_file" "$folder" "$tmp_file" --quiet --no-case-bits
    rm "$tmp_file"
}

suppress cadius CREATEFOLDER "$INSTALL_IMG" "$INSTALL_PATH" --quiet --no-case-bits

perl -p -i -e 's/\r?\n/\r/g' "res/package/READ.ME" # Ensure Apple line endings
add_file "$INSTALL_IMG" "res/package/READ.ME" "$INSTALL_PATH" "Read.Me" 040000

add_file "$INSTALL_IMG" "desktop.system/out/desktop.system.SYS" "$INSTALL_PATH" "DeskTop.system" FF0000
add_file "$INSTALL_IMG" "desktop/out/desktop.built" "$INSTALL_PATH" "DeskTop2" F10000


if [ "$1" = "selector" ]; then
    suppress cadius DELETEFILE "$INSTALL_IMG" "$INSTALL_PATH/optional/selector"
    suppress cadius DELETEFILE "$INSTALL_IMG" "$INSTALL_PATH/optional"
    add_file "$INSTALL_IMG" "selector/out/selector.built" "$INSTALL_PATH" "Selector" F10000
else
    suppress cadius DELETEFILE "$INSTALL_IMG" "$INSTALL_PATH/selector"
    suppress cadius CREATEFOLDER "$INSTALL_IMG" "$INSTALL_PATH/optional" --quiet --no-case-bits
    add_file "$INSTALL_IMG" "selector/out/selector.built" "$INSTALL_PATH/optional" "Selector" F10000
fi

for path in $(cat desk.acc/TARGETS | bin/targets.pl dirs); do
    suppress cadius CREATEFOLDER "$INSTALL_IMG" "$INSTALL_PATH/$path" --quiet --no-case-bits
done
for line in $(cat desk.acc/TARGETS | bin/targets.pl); do
    IFS=',' read -ra array <<< "$line"
    file="${array[0]}"
    path="${array[1]}"
    add_file "$INSTALL_IMG" "desk.acc/out/$file.da" "$INSTALL_PATH/$path" $file F10640
done

rmdir "$PACKDIR"
