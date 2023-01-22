#!/usr/bin/env perl -pi
#
# Add "; FooProc" comments to .endproc/.endscope control commands
#
# Usage: endproc.pl sourcefile.s ...
#

use strict;
use warnings;

BEGIN {
    my @stack = ();
}

our @stack;
if (m/\.(?:proc|scope)\b\s*(\w*)/) {
    push(@stack, $1);
} elsif (m/(\.end(?:proc|scope))\b/) {
    my $label = pop(@stack);
    $_ = "$1 ; $label\n" if $label;
}
