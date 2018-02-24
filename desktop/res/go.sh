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
    diff "orig/DESKTOP2_$1" "out/$1.built" \
        && (cecho green "diff $1 good" ) \
        || (tput blink ; cecho red "DIFF $1 BAD" ; return 1)
}

function stats {
    echo "$1: "$(../res/stats.pl < "$1")
}

#do_make clean
do_make all

TARGETS="loader mgtk desktop invoker ovl1 ovl1a ovl2 ovl3 ovl5 ovl6 ovl7"

# Verify original and output match
echo "Verifying diffs:"
for t in $TARGETS; do
    verify $t
done;

# Compute stats
echo "Unidentified symbols:"
for t in $TARGETS; do
    stats "$t.s"
done;
