#!/usr/bin/env perl

# Convert $xx into px(bbbbbbb) - input to A2D_DRAW_PATTERN

use strict;
use warnings;

while (<STDIN>) {
    s/(\$(..))/'px(%' . reverse(sprintf('%07b', hex($2))) . ')'/eg;
    print;
}
