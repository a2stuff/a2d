#!/usr/bin/env perl

use strict;
use warnings;

my $depth = 0;

while (<STDIN>) {
    ++$depth if m/\.proc/ || m/\.scope/;

    print "$depth - $_";

    --$depth if m/\.endproc/ || m/\.endscope/;
}
