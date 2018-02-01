#!/bin/bash

set -e

function do_make {
    make "$1" \
        && (tput setaf 2 ; echo "make $1 good" ; tput sgr0 ) \
        || (tput setaf 1 ; tput blink ; echo "MAKE $1 BAD" ; tput sgr0 ; return 1)
}

function verify {
    diff "orig/DESKTOP2_$1" "$1.built" \
        && (tput setaf 2 ; echo "diff $1 good" ; tput sgr0 ) \
        || (tput setaf 1 ; tput blink ; echo -e "DIFF $1 BAD" ; tput sgr0 ; return 1)
}

function stats {
    echo "$1: "$(../res/stats.pl < "$1")
}

#do_make clean
do_make all

TARGETS="loader mgtk desktop invoker"

# Verify original and output match
echo "Verifying diffs:"
for t in $TARGETS; do
    verify $t
done;

echo "Unidentified symbols:"
for t in $TARGETS; do
    stats "$t.s"
done;
