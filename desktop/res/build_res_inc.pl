#!/usr/bin/env perl
use strict;
use warnings;

my @symbols = ();
my @equates = ();

# TODO: Handle nested procs
my $proc = '';

while (<STDIN>) {
    chomp;
    next unless m/^00([0-9A-F]{4})  2  .. .. .. ..  (.*)/;
    my ($addr, $line) = ($1, $2);
    $line =~ s/;.*//;
    $line =~ s/^\s*|\s*$//;
    next unless $line;
    if ($line =~ m/^\.proc\s+(\S+)/) {
        $proc = $1;
        push @symbols, [$proc, $addr];
        next;
    }
    if ($line =~ m/^\.endproc/) {
        $proc = '';
        next;
    }

    if ($line =~ m/^(\S+)\s*:=\s*(.*)/) {
        my ($symbol, $value) = ($1, $2);
        next if $value =~ m/::/;
        $value =~ s/\*/\$$addr/; # foo := * + 2
        $symbol = $proc . '_' . $symbol if $proc;
        push @equates, [$symbol, $value];
        next;
    }

    if ($line =~ m/^(\S+):/) {
        my ($symbol) = ($1);
        $symbol = $proc . '_' . $symbol if $proc;
        push @symbols, [$symbol, $addr];
    }
}

foreach my $pair (@symbols) {
    printf "%-30s := \$%s\n", @$pair[0], @$pair[1];
}

foreach my $pair (@equates) {
    printf "%-24s := %s\n", @$pair[0], @$pair[1];
}
