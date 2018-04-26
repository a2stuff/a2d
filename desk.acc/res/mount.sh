#!/bin/bash

# Run this from the desk.acc directory

set -e

function cecho {
    case $1 in
        red)    tput setaf 1 ;;
        green)  tput setaf 2 ;;
        yellow) tput setaf 3 ;;
    esac
    echo -e "$2"
    tput sgr0
}

function mount {
    uppercase=$(echo "$1" | tr /a-z/ /A-Z/)
    src="out/$1.built"
    dst="mount/$uppercase.\$F1"
    cp "$src" "$dst" \
	&& xattr -wx prodos.AuxType '40 06' "$dst" \
        && (cecho green "mounted $dst" ) \
        || (cecho red "failed to mount $dst" ; return 1)
}

mkdir -p mount
echo "Copying files to mount/"
mount 'show.image.file'
mount 'this.apple'
mount 'eyes'
