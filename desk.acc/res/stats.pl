#!/usr/bin/env perl

use strict;
use warnings;

my %terms;
while (<STDIN>) {
    foreach my $term (split /\b/, $_) {
        $terms{$term} = 1 if $term =~ /^L[0-9A-F]{4}$/;
    }
}

print scalar(keys %terms), "\n";
