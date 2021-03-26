#!/usr/bin/env perl

use strict;
use warnings;

my @lo;
my @hi;

for (my $i = 0; $i < 256; ++$i) {
    my $bits = $i;
    my $accum = 0;
    for (my $b = 0; $b < 7; ++$b) {
        if ($bits & 1) {
            $accum = $accum | (0b11 << ($b * 2));
        }
        $bits = $bits >> 1;
    }
    my $lo;
    my $hi;
    if ($bits & 1) {
        # palette bit set is easy case
        $lo = ($accum & 0x7f);
        $hi = (($accum >> 7) & 0xff);
    } else {
        # otherwise, encode spill bit into hi bit of main mem (hi)
        my $spill = $accum & 1;
        $accum = $accum >> 1;
        $lo = ($accum & 0x7f);
        $hi = (($accum >> 7) & 0xff) | ($spill << 7); # encode spill bit
    }
    push @lo, $lo;
    push @hi, $hi;
}

print "\n";
print ";;; HR to DHR - Aux Mem Bytes\n";
print "hr_to_dhr_aux:\n";
for (my $i = 0; $i < 256; $i += 8) {
    print "        .byte   ";
    for (my $j = 0; $j < 8; ++$j) {
        print sprintf("\$%02x", $lo[$i + $j]);
        print ", " unless $j == 7;
    }
    print "\n";
}
print "\n";
print ";;; HR to DHR - Main Mem Bytes\n";
print "hr_to_dhr_main:\n";
for (my $i = 0; $i < 256; $i += 8) {
    print "        .byte   ";
    for (my $j = 0; $j < 8; ++$j) {
        print sprintf("\$%02x", $hi[$i + $j]);
        print ", " unless $j == 7;
    }
    print "\n";
}
