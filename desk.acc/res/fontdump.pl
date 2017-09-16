#!/usr/bin/env perl
use strict;
use warnings;

# Dumps the font glyphs from DESKTOP2.$F1
# (Located at $8883 in memory)

my $num = 0x80;

my @chars;
for (my $i = 0; $i < $num; ++$i) {
    $chars[$i] = '';
}

seek(STDIN, 0x4E03, 0);
my $c = 0;

for (my $row = 0; $row < 9; ++$row) {
    for (my $c = 0; $c < $num; ++$c) {
        for (my $shift = 0; $shift < 1; ++$shift) {
            my $b;
            read(STDIN, $b, 1);
            $b = ord($b);
            my $bits = sprintf("%07b", $b);
            $bits =~ tr/01/ #/;
            $bits = reverse $bits;

            $chars[$c] .= $bits;
        }
        $chars[$c] .= "\n";
    }
}


for (my $i = 0; $i < $num; ++$i) {
    print "==".sprintf("%02x",$i)."==\n$chars[$i]";
}
