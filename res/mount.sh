#!/bin/bash

# Run this from the top level directory

set -e
source "res/util.sh"

mkdir -p mount/DESK.ACC || (cecho red "permission denied"; exit 1)

DA_AUX="40 06"

# Mount file
function mount_file {
    src="$1"
    dst="$2"
    cp "$src" "mount/$dst" \
        && (cecho green "mounted $dst" ) \
        || (cecho red "failed to mount $dst" ; return 1)
}

# Mount file with auxtype
function mount_aux {
    src="$1"
    dst="$2"
    aux="$3"
    cp "$src" "mount/$dst" \
	&& xattr -wx prodos.AuxType "$aux" "mount/$dst" \
        && (cecho green "mounted $dst" ) \
        || (cecho red "failed to mount $dst" ; return 1)
}


echo "Copying files to mount/"
mkdir -p mount

mount_file "desktop.system/out/desktop.system.SYS" "DESKTOP.SYSTEM.SYS"
mount_file "desktop/out/desktop.built" "DESKTOP2.\$F1"

mkdir -p mount/OPTIONAL
mount_file "selector/out/selector.built" "OPTIONAL/SELECTOR.\$F1"

mkdir -p mount/DESK.ACC
for file in $(cat desk.acc/TARGETS); do
    uc=$(echo "$file" | tr /a-z/ /A-Z/)
    mount_aux "desk.acc/out/${file}.da" "DESK.ACC/$uc.\$F1" "$DA_AUX"
done

mkdir -p mount/PREVIEW
for file in $(cat preview/TARGETS); do
    uc=$(echo "$file" | tr /a-z/ /A-Z/)
    mount_aux "preview/out/${file}.da" "PREVIEW/$uc.\$F1" "$DA_AUX"
done
