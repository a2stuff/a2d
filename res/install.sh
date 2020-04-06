#!/usr/bin/env bash

# Use Cadius to install A2D onto an existing file.
# https://github.com/mach-kernel/cadius
#
# Usage:
#
#   INSTALL_IMG=/path/to/hd.2mg INSTALL_PATH=/hd/a2.desktop res/install.sh

set -e

if [ -z "$INSTALL_IMG" ]; then
    tput setaf 1 && echo "Variable \$INSTALL_IMG not set, aborting." && tput sgr0
    exit 1
fi
if [ -z "$INSTALL_PATH" ]; then
    tput setaf 1 && echo "Variable \$INSTALL_PATH not set, aborting." && tput sgr0
    exit 1
fi
if ! command -v "cadius" >/dev/null; then
    tput setaf 1 && echo "Cadius not installed." && tput sgr0
    exit 1
fi

tput setaf 3 && echo "Installing into image: $INSTALL_IMG at path: $INSTALL_PATH" && tput sgr0

DA_DIRS="desk.acc preview"

PACKDIR="out/install"

mkdir -p $PACKDIR

# Add the files into the disk images.

add_file () {
    img_file="$1"
    src_file="$2"
    folder="$3"
    dst_file="$4"
    suffix="$5"
    tmp_file="$PACKDIR/$dst_file#$suffix"

    tput setaf 2 && echo "- $folder/$dst_file" && tput sgr0

    cp "$src_file" "$tmp_file"
    cadius DELETEFILE "$img_file" "$folder/$dst_file" > /dev/null
    cadius ADDFILE "$img_file" "$folder" "$tmp_file" --quiet --no-case-bits > /dev/null
    rm "$tmp_file"
}

cadius CREATEFOLDER "$INSTALL_IMG" "$INSTALL_PATH" --quiet --no-case-bits > /dev/null
cadius CREATEFOLDER "$INSTALL_IMG" "$INSTALL_PATH/optional" --quiet --no-case-bits > /dev/null

perl -p -i -e 's/\r?\n/\r/g' "res/package/READ.ME" # Ensure Apple line endings
add_file "$INSTALL_IMG" "res/package/READ.ME" "$INSTALL_PATH" "Read.Me" 040000

add_file "$INSTALL_IMG" "desktop.system/out/desktop.system.SYS" "$INSTALL_PATH" "DeskTop.system" FF0000
add_file "$INSTALL_IMG" "desktop/out/DESKTOP2.built" "$INSTALL_PATH" "DeskTop2" F10000
add_file "$INSTALL_IMG" "selector/out/selector.built" "$INSTALL_PATH/optional" "Selector" F10000
cadius DELETEFILE "$INSTALL_IMG" "$INSTALL_PATH/selector" > /dev/null

for da_dir in $DA_DIRS; do
    folder="$INSTALL_PATH/$da_dir"
    cadius CREATEFOLDER "$INSTALL_IMG" "$folder" --quiet --no-case-bits > /dev/null
    for file in $(cat $da_dir/TARGETS); do
        add_file "$INSTALL_IMG" "$da_dir/out/$file.da" "$folder" $file F10640
    done
done



rmdir "$PACKDIR"
