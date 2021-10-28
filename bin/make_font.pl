#!/usr/bin/env perl

# Input: Font description in text format (what dump_font.pl outputs)
# Output: MGTK font data

use strict;
use warnings;

sub from2 { unpack("N", pack("B32", substr("0" x 32 . shift, -32))); }

$_ = <STDIN>; chomp;
die "expected type\n" unless m/^type: (\d+)$/;
my $type = $1;
die "only type 0 supported\n" unless $type == 0;

$_ = <STDIN>; chomp;
die "expected type\n" unless m/^chars: (\d+)$/;
my $chars = $1;

$_ = <STDIN>; chomp;
die "expected type\n" unless m/^height: (\d+)$/;
my $height = $1;

my @widths = ();
my @chars = ();
for (my $c = 0; $c < $chars; ++$c) {
    $_ = <STDIN>; chomp;
    die "expected char header, saw $_\n" unless m/^== 0x(\w+) ==$/;
    die sprintf("expected 0x%02x, saw 0x$1\n", $c) unless hex($1) == $c;

    for (my $r = 0; $r < $height; ++$r) {
        $_ = <STDIN>; chomp;
        die "expected bitmap, saw $_\n" unless m/^[.#]+$/;
        my $len = length($_);
        if (defined $widths[$c]) {
            die sprintf("changed width: 0x%02x\n", $c) unless $widths[$c] == $len;
        } else {
            $widths[$c] = $len;
        }

        $_ =~ tr/.#/01/;
        my $n = reverse($_);
        $chars[$c][$r] = from2($n);
    }
}

binmode STDOUT;

print chr($type), chr($chars-1), chr($height);
print pack('C*', @widths);
for (my $r = 0; $r < $height; ++$r) {
    for (my $c = 0; $c < $chars; ++$c) {
        print chr($chars[$c][$r]);
    }
}
