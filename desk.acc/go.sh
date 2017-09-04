#!/bin/bash

set -e

make clean
make all

# Verify original and output match
diff show_text_file.bin show_text_file.F1 \
    && echo "Files match"

cat show_dhr_file.F1 > mount/SHOW.DHR.FILE.\$F1 \
    && echo "Updated mounted file"

cat show_hgr_file.F1 > mount/SHOW.HGR.FILE.\$F1 \
    && echo "Updated mounted file"

# Show output for review
#less $list
#less dhr.list
