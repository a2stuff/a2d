#!/usr/bin/env perl

# stats.pl < source.s            -- dump stats
# stats.pl unscoped < source.s   -- list Lxxxx symbols not within 2 scopes
# stats.pl single < source.s     -- list Lxxxx symbols with no references

use strict;
use warnings;

my $command = shift(@ARGV) // "";

my %defs;
my %refs;
my %unscoped;
my $depth = 0;

while (<STDIN>) {
    ++$depth if m/\.proc/ || m/\.scope/;
    --$depth if m/\.endproc/ || m/\.endscope/;

    if (m/^(L[0-9A-F]{4}):(.*)/) {
        my $def = $1;
        $_ = $2;
        $defs{$def} = ($defs{$def} // 0) + 1;
        $unscoped{$def} = 1 if $depth < 2;
    }

    foreach my $term (split /(?<!::)\b/, $_) {
        if ($term =~ /^L[0-9A-F]{4}$/) {
            $refs{$term} = 0 unless defined $refs{$term};
            $refs{$term} += 1;
        }
    }
}

my $unrefed = 0;
foreach my $def (keys %defs) {
    ++$unrefed unless defined $refs{$def};
}

my $defs = scalar(keys %defs);
my $unscoped = scalar(keys %unscoped);
my $scoped = $defs - $unscoped;

if ($command eq "unscoped") {
    foreach my $def (sort keys %unscoped) {
        print "$def\n";
    }
} elsif ($command eq "unrefed") {
    foreach my $def (sort keys %defs) {
        print "$def\n" unless defined $refs{$def};
    }
} elsif ($command eq "") {
    print "unscoped: $unscoped  scoped: $scoped  unrefed: $unrefed\n";
} else {
    die "Unknown command: $command\n";
}
