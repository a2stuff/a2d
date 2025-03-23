#!/usr/bin/env perl

# Input: Font description in text format
#   type: 0 | 128
#   height: 0-16
#   == U+xxxx ==
#   .#.#.#.#
#   ...
# Output: MGTK font data


use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";
use Transcode;

my $lang = shift or die "Usage: $0 lang < font.unicode.txt > font.lang\n";

# Note: MGTK supports smaller fonts.
my $CHARS = 128;

# --------------------------------------------------
# Get mapping - given a language code, returns a
# Unicode string with that encoding's code points
# 0 through 127.
# --------------------------------------------------

sub getmap($) {
  my ($lang) = @_;

  my $s = '';
  for (my $i = 0; $i < 128; ++$i) {
    $s .= chr($i);
  }

  return Transcode::decode($lang, $s);
}

# --------------------------------------------------
# Utilities

sub from2 { unpack("N", pack("B32", substr("0" x 32 . shift, -32))); }


# --------------------------------------------------
# Read source file
# --------------------------------------------------

$_ = <STDIN>; chomp;
die "expected type (line $.)\n" unless m/^type: (\d+)$/;
my $type = $1;
die "only types 0x00/0x80 supported (line $.)\n" unless $type == 0x00 || $type == 0x80;

$_ = <STDIN>; chomp;
die "expected height (line $.)\n" unless m/^height: (\d+)$/;
my $height = $1;

my @widths = ();
my @chars = ();
while ($_ = <STDIN>) {
  chomp;
  die "expected char header, saw $_ (line $.)\n" unless m/^== U\+([0-9A-F]{4}) ==$/i;
  my $c = hex($1);

  for (my $r = 0; $r < $height; ++$r) {
    $_ = <STDIN>; chomp;
    die "expected bitmap, saw $_ (line $.)\n" unless m/^[.#]*$/;
    my $len = length($_);
    if (defined $widths[$c]) {
      die sprintf("changed width: U+%04X (line $.)\n", $c) unless $widths[$c] == $len;
    } else {
      $widths[$c] = $len;
    }

    $_ =~ tr/.#/01/;
    my $n = reverse($_);
    $chars[$c][$r] = from2($n);
  }
}

# --------------------------------------------------
# Dump out font
# --------------------------------------------------

my @mapping = split('', getmap($lang));
# TODO: map through ord()

binmode STDOUT;
print chr(0x00); # type
print chr($CHARS-1); # last
print chr($height); # height

for (my $i = 0; $i < $CHARS; ++$i) {
  my $ucp = ord($mapping[$i]);
  die sprintf("No glyph for required code point U+%04X\n", $ucp) unless defined $widths[$ucp];
}

for (my $i = 0; $i < $CHARS; ++$i) {
  my $ucp = ord($mapping[$i]);
  print chr($widths[$ucp]);
}

for (my $row = 0; $row < $height; ++$row) {
  for (my $i = 0; $i < $CHARS; ++$i) {
    my $ucp = ord($mapping[$i]);
    print chr(${$chars[$ucp]}[$row]);
  }
}
