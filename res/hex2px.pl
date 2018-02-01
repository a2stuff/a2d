#!/usr/bin/env perl

# Convert $xx into px(bbbbbbb) - MGTK pattern/bits

use strict;
use warnings;

while (<STDIN>) {
    s/(\$([0-7][0-9A-F])\b)/'px(%' . reverse(sprintf('%07b', hex($2))) . ')'/ieg;
    s/(\$([89A-F][0-9A-F])\b)/'PX(%' . reverse(sprintf('%07b', 0x7f & hex($2))) . ')'/ieg;
    print;
}
