#!/usr/bin/env perl

use strict;
use warnings;

my %terms;
my %unscoped;
my $depth = 0;

while (<STDIN>) {
    ++$depth if m/\.proc/ || m/\.scope/;
    --$depth if m/\.endproc/ || m/\.endscope/;
    foreach my $term (split /\b/, $_) {
        if ($term =~ /^L[0-9A-F]{4}$/) {
            $terms{$term} = 0 unless defined $terms{$term};
            $terms{$term} += 1;
            $unscoped{$term} = 1 if $depth < 2;
        }
    }
}

foreach my $term (sort keys %unscoped) {
    print "$term\n";
}
