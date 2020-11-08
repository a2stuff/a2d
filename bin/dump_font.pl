#!/usr/bin/env perl
use strict;
use warnings;

# Displays the glyphs from an MGTK font.

sub getbyte {
    my $b;
    read(STDIN, $b, 1);
    return ord($b);
}

my $type = getbyte();
my $last = getbyte();
my $height = getbyte();
my $num = $last + 1;
my $cols = $type ? 2 : 1;

print "type: $type\n";
print "chars: $num\n";
print "height: $height\n";

my @chars;
for (my $i = 0; $i < $num; ++$i) {
    $chars[$i] = '';
}

my @widths;
for (my $i = 0; $i < $num; ++$i) {
    push @widths, getbyte();
}

for (my $row = 0; $row < $height; ++$row) {
    for (my $col = 0; $col < $cols; ++$col) {
        for (my $c = 0; $c < $num; ++$c) {
            my $bits = sprintf("%07b", getbyte());
            $bits =~ tr/01/.#/;
            $bits = reverse $bits;

            $chars[$c] .= $bits;
        }
    }
    for (my $c = 0; $c < $num; ++$c) {
        $chars[$c] .= "\n";
    }
}

for (my $i = 0; $i < $num; ++$i) {
    $chars[$i] =
        join("\n",
             map { substr($_, 0, $widths[$i]) }
             split("\n", $chars[$i]));
}

for (my $i = 0; $i < $num; ++$i) {
    print "== 0x".sprintf("%02x",$i)." ==\n$chars[$i]\n";
}
