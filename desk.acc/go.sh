#!/bin/bash

set -e

#make clean
make all

function verify {
    diff "$1.bin" "$1.F1" && echo "$1: files match"
}

# Verify original and output match
verify "calculator"
verify "show_text_file"

cat show_image_file.F1 > mount/SHOW.IMAGE.FILE.\$F1 \
    && echo "Updated mounted file"
