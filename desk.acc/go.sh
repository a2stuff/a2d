#!/bin/bash

set -e

make clean
make all

# Verify original and output match
diff show_text_file.bin show_text_file.F1 \
    && echo "Files match"

cat show_image_file.F1 > mount/SHOW.IMAGE.FILE.\$F1 \
    && echo "Updated mounted file"

# Show output for review
#less $list
#less dhr.list
