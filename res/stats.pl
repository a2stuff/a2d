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

my $single = 0;
foreach my $key (keys %terms) {
    ++$single if $terms{$key} == 1;
}

my $terms = scalar(keys %terms);
my $unscoped = scalar(keys %unscoped);
my $scoped = $terms - $unscoped;

print "unscoped: $unscoped  scoped: $scoped  single: $single\n";
