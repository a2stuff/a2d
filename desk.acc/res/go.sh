#!/bin/bash

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

function do_make {
    make "$1" \
        && (cecho green "make $1 good") \
        || (tput blink ; cecho red "MAKE $1 BAD" ; return 1)
}

function verify {
    diff "orig/$1.bin" "out/$1.F1" \
        && (cecho green "diff $1 good" ) \
        || (tput blink ; cecho red "DIFF $1 BAD" ; return 1)
}

function stats {
    echo "$1: "$(../res/stats.pl < "$1")
}

#do_make clean
do_make all

# Verify original and output match
echo "Verifying diffs:"
verify "calculator"
verify "show_text_file"
verify "date"
verify "puzzle"

echo "Unidentified symbols:"
stats "calculator.s"
stats "show_text_file.s"
stats "date.s"
stats "puzzle.s"

cat out/show_image_file.F1 > mount/SHOW.IMAGE.FILE.\$F1 \
    && echo "Updated mountable file (SIF)"

#cat calc_fixed.F1 > mount/TEST.\$F1 \
#    && echo "Updated mountable file (Test)"
