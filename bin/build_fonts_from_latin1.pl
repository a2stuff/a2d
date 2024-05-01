#!/usr/bin/env perl

use strict;
use warnings;
use IPC::Open2;
use Encode qw(decode encode);

my $font = shift or die "Usage: $0 fontname\n";

# --------------------------------------------------
# Get mapping - given a language code, returns a
# Unicode string with that encoding's code points
# 0 through 127.
# --------------------------------------------------

sub getmap($) {
  my ($lang) = @_;

  my $pid = open2(*CHILD_OUT, *CHILD_IN, 'bin/transcode.pl', ('from', $lang)) or die $!;
  for (my $i = 0; $i < 128; ++$i) {
    print CHILD_IN chr($i);
  }
  close(CHILD_IN);

  my $octets = do { local $/; <CHILD_OUT>};
  close(CHILD_OUT);
  waitpid($pid, 0);
  return decode('UTF-8', $octets);
}

# --------------------------------------------------
# Read source file
# --------------------------------------------------

my $src = "${font}.latin1";
open SRC, '<' . $src or die $!;
binmode(SRC);
sub getbyte {
    my $b;
    read(SRC, $b, 1);
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

close SRC;


# --------------------------------------------------
# Dump out fonts
# --------------------------------------------------

foreach my $lang (qw(da de en es fr it nl pt sv)) {
  my @mapping = split('', getmap($lang));

  my $dst = "${font}.${lang}";
  open DST, '>' . $dst or die $!;
  binmode(DST);
  print DST chr(0x00); # type
  print DST chr(0x7F); # last
  print DST chr($height); # height

  for (my $i = 0; $i < 128; ++$i) {
    my $ucp = ord($mapping[$i]);
    print DST chr($widths[$ucp]);
  }

  for (my $row = 0; $row < $height; ++$row) {
    for (my $i = 0; $i < 128; ++$i) {
      my $ucp = ord($mapping[$i]);
      print DST chr(${$chars[$ucp]}[$row]);
    }
  }

  close DST;
}
