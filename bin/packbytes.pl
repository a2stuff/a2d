#!/usr/bin/env perl

use strict;
use warnings;

# Inspiration: https://github.com/markpmlim/PackBytesAndUnpackBytes/blob/master/IIgsCodecs.playground/Sources/Encoder.swift

$/ = \1;

my @bytes = ();
push(@bytes, $_) while <STDIN>;

my @singletons = ();

sub dumpSingletons() {
    while (scalar(@singletons)) {
        my $n = scalar(@singletons);
        $n = 64 if $n > 64;
        # 0b00...... = 1 to 64 bytes follow - all different
        #print STDERR "Packing $n singleton(s)\n";
        print chr(0b00000000 | ($n - 1));
        print shift(@singletons) while $n--;
    }
}

while (scalar(@bytes)) {
    my $count = 0;
    my $head = $bytes[$count++];
    $count++ while ($count < scalar(@bytes)) && ($bytes[$count] eq $head);

    if ($count > 2) {
        dumpSingletons();

        if ($count < 8 && ($count % 4)) {
            # 0b01...... = 3, 5, 6, or 7 repeats of next byte
            splice(@bytes, 0, $count);
            #print STDERR "Packing $count repeats of $head\n";
            print chr(0b01000000 | ($count - 1));
            print $head;
        } else {
            # 0b11...... = 1 to 64 repeats of next byte taken as 4 bytes
            $count = int($count / 4);
            $count = 64 if $count > 64;
            splice(@bytes, 0, $count * 4);
            #print STDERR "Packing $count * 4 repeats of $head\n";
            print chr(0b11000000 | ($count - 1));
            print $head;
        }

        next;
    }

    if (scalar(@bytes) >= 8) {
        my $b0 = $bytes[0];
        my $b1 = $bytes[1];
        my $b2 = $bytes[2];
        my $b3 = $bytes[3];
        $count = 0;
        while ($b0 eq $bytes[$count*4+0] &&
               $b1 eq $bytes[$count*4+1] &&
               $b2 eq $bytes[$count*4+2] &&
               $b3 eq $bytes[$count*4+3] &&
               $count < 64) {
            ++$count;
        }
        if ($count > 1) {
            dumpSingletons();

            # 0b10...... = 1 to 64 repeats of next 4 bytes
            splice(@bytes, 0, $count*4);
            #print STDERR "Packing $count repeats of quad $b0$b1$b2$b3\n";
            print chr(0b10000000 | ($count - 1));
            print $b0, $b1, $b2, $b3;

            next;
        }
    }

    push(@singletons, shift(@bytes));
}

dumpSingletons();
