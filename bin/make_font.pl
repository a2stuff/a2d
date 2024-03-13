#!/usr/bin/env perl

# Input: Font description in text format (what dump_font.pl outputs)
# Output: MGTK font data

use strict;
use warnings;

sub from2 { unpack("N", pack("B32", substr("0" x 32 . shift, -32))); }

$_ = <STDIN>; chomp;
die "expected type (line $.)\n" unless m/^type: (\d+)$/;
my $type = $1;
die "only types 0x00/0x80 supported (line $.)\n" unless $type == 0x00 || $type == 0x80;

$_ = <STDIN>; chomp;
die "expected type (line $.)\n" unless m/^chars: (\d+)$/;
my $chars = $1;

$_ = <STDIN>; chomp;
die "expected type (line $.)\n" unless m/^height: (\d+)$/;
my $height = $1;

my @widths = ();
my @chars = ();
for (my $c = 0; $c < $chars; ++$c) {
    $_ = <STDIN>; chomp;
    die "expected char header, saw $_ (line $.)\n" unless m/^== 0x(\w+) ==$/;
    die sprintf("expected 0x%02x, saw 0x$1 (line $.)\n", $c) unless hex($1) == $c;

    for (my $r = 0; $r < $height; ++$r) {
        $_ = <STDIN>; chomp;
        die "expected bitmap, saw $_ (line $.)\n" unless m/^[.#]*$/;
        my $len = length($_);
        if (defined $widths[$c]) {
            die sprintf("changed width: 0x%02x (line $.)\n", $c) unless $widths[$c] == $len;
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
        print chr($chars[$c][$r] & 0x7F);
    }
    if ($type == 0x80) {
        for (my $c = 0; $c < $chars; ++$c) {
            print chr($chars[$c][$r] >> 7);
        }
    }
}
