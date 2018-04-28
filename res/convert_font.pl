#!/usr/bin/env perl

# Input: HCRG-style Font (768 bytes)
# Output: MGTK font definition

# Usage: perl convert.pl < font_data > font.bin

use strict;
use warnings;
$SIG{__WARN__} = sub { die @_ };

my @chars;
my $NCCS = 32;
my $NCHARS = 128;

# Fill in control characters
for (my $i = 0; $i < $NCCS; ++$i) {
    $chars[$i] = "\x00" x 8;
}

for (my $i = 0; $i < $NCHARS - $NCCS; ++$i) {
    read(STDIN, $chars[$i + $NCCS], 8);
}

my @out;

push @out, 0x00; # single width
push @out, 0x7f; # last character
push @out, 8; # height

# compute glyph widths
for (my $i = 0; $i < $NCHARS; ++$i) {

    my @bytes = map { ord($_) & 0x7f } split('', $chars[$i]);

    my $bits = 0;
    for (my $b = 0; $b < 8; ++$b) {
        $bits = $bits | $bytes[$b];
    }

    $chars[$i] = join('', map { chr } @bytes);

    my $w =
        $bits >= (1<<6) ? 7 :
        $bits >= (1<<5) ? 6 :
        $bits >= (1<<4) ? 5 :
        $bits >= (1<<3) ? 4 :
        $bits >= (1<<2) ? 3 :
        $bits >= (1<<1) ? 2 : 1;

    push @out, $w;
}

# bits
for (my $b = 0; $b < 8; ++$b) {
    for (my $i = 0; $i < $NCHARS; ++$i) {
        push @out, ord(substr($chars[$i], $b, 1));
    }
}

# source output for ca65
#while (scalar @out) {
#    my @chunk = splice(@out, 0, 8);
#    @chunk = map { sprintf('$%02x', $_) } @chunk;
#    print "        .byte     " . join(',', @chunk) . "\n";
#}

print join('', map { chr($_) } @out);
