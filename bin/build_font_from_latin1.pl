#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";
use Transcode;

my $lang = shift or die "Usage: $0 lang < font.latin1 > font.lang\n";

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
# Read source file
# --------------------------------------------------

binmode STDIN;
sub getbyte {
  my $b;
  read(STDIN, $b, 1);
  return ord($b);
}
my $type = getbyte();
die "Only type 0x00 supported\n" unless $type == 0x00;
my $last = getbyte();
die "Only src fonts length 256 supported\n" unless $last == 255;
my $num = $last+1;
my $height = getbyte();

my @chars;
for (my $i = 0; $i < $num; ++$i) {
  $chars[$i] = [];
}
my @widths;
for (my $i = 0; $i < $num; ++$i) {
  push @widths, getbyte();
}

for (my $row = 0; $row < $height; ++$row) {
  for (my $i = 0; $i < $num; ++$i) {
    push(@{$chars[$i]}, getbyte());
  }
}

# --------------------------------------------------
# Dump out font
# --------------------------------------------------

my @mapping = split('', getmap($lang));

binmode STDOUT;
print chr(0x00); # type
print chr(0x7F); # last
print chr($height); # height

for (my $i = 0; $i < 128; ++$i) {
  my $ucp = ord($mapping[$i]);
  print chr($widths[$ucp]);
}

for (my $row = 0; $row < $height; ++$row) {
  for (my $i = 0; $i < 128; ++$i) {
    my $ucp = ord($mapping[$i]);
    print chr(${$chars[$ucp]}[$row]);
  }
}
