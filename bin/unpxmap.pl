#!/usr/bin/env perl

use strict;
use warnings;


while (<STDIN>) {
    chomp;
    next unless m/PX\(/i;
    s/[^01]//g;
    tr/01/ #/;
    print $_, "\n";
}
