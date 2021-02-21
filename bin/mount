#!/bin/bash

# Run this from the top level directory

set -e
source "bin/util.sh"

MOUNT_DIR="mount"

mkdir -p $MOUNT_DIR/test || (cecho red "permission denied"; exit 1)
rmdir $MOUNT_DIR/test

# Add file to mount directory
# Usage: add_file SRC DST TYPEAUXTYPE
function add_file {
    src="$1"
    type="${3:0:2}"
    auxh="${3:2:2}"
    auxl="${3:4:2}"
    dst="$2.\$$type"
    cp "$src" "$MOUNT_DIR/$dst" \
	&& xattr -wx prodos.AuxType "$auxl $auxh" "$MOUNT_DIR/$dst" \
        && (cecho green "- $dst" ) \
        || (cecho red "failed to mount $dst" ; return 1)
}

cecho yellow "Copying files to $MOUNT_DIR/"

perl -p -i -e 's/\r?\n/\r/g' "res/package/READ.ME" # Ensure Apple line endings
add_file "res/package/READ.ME" "READ.ME" 040000

add_file "desktop.system/out/desktop.system.SYS" "DESKTOP.SYSTEM" FF0000
add_file "desktop/out/desktop.built" "DESKTOP2" F10000

mkdir -p $MOUNT_DIR/OPTIONAL
add_file "selector/out/selector.built" "OPTIONAL/SELECTOR" F10000

for path in $(cat desk.acc/TARGETS | bin/targets.pl dirs); do
    uc=$(echo "$path" | tr /a-z/ /A-Z/)
    mkdir -p "$MOUNT_DIR/$uc"
done
for line in $(cat desk.acc/TARGETS | bin/targets.pl); do
    IFS=',' read -ra array <<< "$line"
    file="${array[0]}"
    path="${array[1]}"
    uc_file=$(echo "$file" | tr /a-z/ /A-Z/)
    uc_path=$(echo "$path" | tr /a-z/ /A-Z/)
    add_file "desk.acc/out/${file}.da" "${uc_path}/${uc_file}" F10640
done
