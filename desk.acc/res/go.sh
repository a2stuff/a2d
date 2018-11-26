#!/bin/bash

# Run this from the desk.acc directory

set -e
source "../res/util.sh"

function verify {
    diff "orig/$1.bin" "out/$1.built" \
        && (cecho green "diff $1 good" ) \
        || (tput blink ; cecho red "DIFF $1 BAD" ; return 1)
}

function stats {
    echo "$(printf '%-20s' $1)""$(../res/stats.pl < $1)"
}

#do_make clean
do_make all

# Verify original and output match
echo "Verifying diffs:"
verify "calculator"
verify "show.text.file"
verify "date"
verify "puzzle"
verify "sort.directory"

# Compute stats
echo "Stats:"
stats "calculator.s"
stats "show.text.file.s"
stats "date.s"
stats "puzzle.s"
stats "sort.directory.s"
