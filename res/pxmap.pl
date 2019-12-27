#!/usr/bin/env perl

use strict;
use warnings;


while (<STDIN>) {
    chomp;
    s/[^ #]//g;
    tr/ #/01/;
    next unless $_;
    $_ .= '0' while length($_) % 7 != 0;

    my @a = m/(.......)/g;

    print '        .byte   ' . join(',', map { "PX(\%$_)" } @a) . "\n";
}
