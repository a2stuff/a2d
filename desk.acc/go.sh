#!/bin/bash

set -e

function do_make {
    make "$1" \
        && (tput setaf 2 ; echo "make $1 good" ; tput sgr0 ) \
        || (tput setaf 1 ; tput blink ; echo "MAKE $1 BAD" ; tput sgr0 ; return 1)
}

function verify {
    diff "orig/$1.bin" "$1.F1" \
        && (tput setaf 2 ; echo "diff $1 good" ; tput sgr0 ) \
        || (tput setaf 1 ; tput blink ; echo -e "DIFF $1 BAD" ; tput sgr0 ; return 1)
}

#do_make clean
do_make all

# Verify original and output match
verify "calculator"
verify "show_text_file"
verify "date"
verify "puzzle"

cat show_image_file.F1 > mount/SHOW.IMAGE.FILE.\$F1 \
    && echo "Updated mounted file"
