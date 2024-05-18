#!/usr/bin/env perl

# stats.pl < source.s            -- dump stats
# stats.pl unscoped < source.s   -- list Lxxxx symbols not within 2 scopes
# stats.pl scoped < source.s     -- list Lxxxx symbols within 2 scopes
# stats.pl raw < source.s        -- list $xxxx usage

use v5.10;
use strict;
use warnings;

my $command = shift(@ARGV) // "";

my %defs;
my %refs;
my %scoped;
my %unscoped;
my %raw;
my $depth = 0;

while (<STDIN>) {
  s/;.*//;

  ++$depth if m/\.proc/ || m/\.scope/;
  --$depth if m/\.endproc/ || m/\.endscope/;

  next if m/\.assert|\.org|PAD_TO|ASSERT/;
  s/\b[^L]\w+ \s* :?= \s* \$[0-9A-F]+//x; # trust assignments of absolutes

  if (m/^(L[0-9A-F]{4})(?::|\s+:=)(.*)/) {
    my $def = $1;
    $_ = $2;
    $defs{$def} = ($defs{$def} // 0) + 1;
    $unscoped{$def} = 1 if $depth < 2;
    $scoped{$def} = 1 if $depth >= 2;
  }

  foreach my $term (split /[ (),+\-*\/<>#:]/, $_) {
    $term =~ s/\s+//g;
    next unless $term;
    if ($term =~ m/^L[0-9A-F]{4}$/) {
      $refs{$term} = 1 + ($refs{$term} // 0);
    } elsif ($term =~ m/^\$[0-9A-F]{4}$/) {
      $raw{$term} = 1 + ($raw{$term} // 0);
    }
  }
}

my $defs = scalar(keys %defs);
my $unscoped = scalar(keys %unscoped);
my $raws = scalar(keys %raw);
my $scoped = scalar(keys %scoped);

if ($command eq "unscoped") {
  foreach my $def (sort keys %unscoped) {
    print "$def\n";
  }
} elsif ($command eq "scoped") {
  foreach my $def (sort keys %scoped) {
    print "$def\n";
  }
} elsif ($command eq "raw") {
  foreach my $addr (sort keys %raw) {
    print "$addr\n";
  }
} elsif ($command eq "") {
  printf("unscoped: %4d  scoped: %4d  raw: %4d\n",
         $unscoped, $scoped, $raws);
} else {
  die "Unknown command: $command\n";
}
