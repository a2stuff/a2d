#!/usr/bin/env perl

use strict;
use warnings;

$/ = \1;
while (<STDIN>) {
  $_ = ord($_);
  my $op = $_ & 0b11000000;
  my $count = ($_ & 0b00111111) + 1;

  if ($op == 0b00000000) {
    # 0b00...... = 1 to 64 bytes follow - all different
    #print STDERR "Unpacking $count singleton(s)\n";
    while ($count--) {
      my $byte = <STDIN>;
      print $byte;
    }
  } elsif ($op == 0b01000000) {
    # 0b01...... = 3, 5, 6, or 7 repeats of next byte
    my $byte = <STDIN>;
    #print STDERR "Unpacking $count repeats of $byte\n";
    print $byte x $count;
  } elsif ($op == 0b10000000) {
    # 0b10...... = 1 to 64 repeats of next 4 bytes
    $/ = \4;
    my $bytes = <STDIN>;
    $/ = \1;
    #print STDERR "Unpacking $count repeats of quad $bytes\n";
    print $bytes x $count;
  } else {
    # 0b11...... = 1 to 64 repeats of next byte taken as 4 bytes
    my $byte = <STDIN>;
    #print STDERR "Unpacking $count * 4 repeats of $byte\n";
    print $byte x ($count * 4);
  }
}
