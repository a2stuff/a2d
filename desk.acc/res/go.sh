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
    diff "orig/$1.bin" "out/$1.\$F1" \
        && (cecho green "diff $1 good" ) \
        || (tput blink ; cecho red "DIFF $1 BAD" ; return 1)
}

function stats {
    echo "$(printf '%-20s' $1)""$(../res/stats.pl < $1)"
}

function mount {
    uppercase=$(echo "$1" | tr /a-z/ /A-Z/)
    cp "out/$1" "mount/$uppercase" \
        && (cecho green "mounted $uppercase" ) \
        || (cecho red "failed to mount $uppercase" ; return 1)
}

#do_make clean
do_make all

# Verify original and output match
echo "Verifying diffs:"
verify "calculator"
verify "show.text.file"
verify "date"
verify "puzzle"

# Compute stats
echo "Stats:"
stats "calculator.s"
stats "show.text.file.s"
stats "date.s"
stats "puzzle.s"

# Mountable directory
echo "Copying files to mount/"
mount 'show.image.file.$F1'
mount 'this.apple.$F1'
