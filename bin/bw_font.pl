#!/usr/bin/env perl
use strict;
use warnings;

# Displays the glyphs from a BeagleWrite font.

my $offset = 0;

sub getbyte {
    my $b;
    read(STDIN, $b, 1) or die "EOF";
    ++$offset;
    return ord($b);
}

sub getword {
    my $b1 = getbyte();
    my $b2 = getbyte();
    return $b2 * 256 + $b1;
}

my @widths = ();
my @offsets = ();

my $signature = getbyte();
die "BAD! Expected signature 0x20, saw $signature\n" unless $signature == 0x20;

my $max = getbyte();
my $height = getbyte();
my $baseline = getbyte();
my $eof = getword();

printf("Signature: %02x\n", $signature);
printf("Max char : %02x\n", $max);
printf("Height   : %02x\n", $height);
printf("Baseline : %02x\n", $baseline);
printf("EOF      : %04x\n", $eof);

for (my $i = 0; $i < $max-32+1; ++$i) {
    printf("== char header: %d / '%c' ==\n", $i, $i+32);
    my $offset = getword();
    my $width = getbyte();

    printf(" Offset : %04x\n", $offset);
    printf(" Width  : %02x\n", $width);

    push @offsets, $offset;
    push @widths, $width;
}

for (my $i = 0; $i < $max-32+1; ++$i) {
    my $o = $offsets[$i];
    my $width = $widths[$i];
    printf("== char: %d / '%c' / w=%d ==\n", $i, $i+32, $width);
    if ($o != $offset) {
        die "BAD! char $i offset $offset expected $o\n";
    }
    for (my $line = 0; $line < $height; ++$line) {
        my $s = sprintf("%07b", getbyte());
        my $w = $width;
        while ($w > 8) {
            $s = sprintf("%07b", getbyte()) . $s;
            $w -= 8;
        }
        $s =~ tr/01/ #/;
        $s = reverse($s);
        print "$s\n";
    }
}
if ($offset != $eof) {
    die "BAD EOF offset $offset expected $eof\n";
}


__END__
while (1) {
    my $b2 = sprintf("%07b", getbyte());
    my $s = $b2 . $b1;
    $s =~ tr/01/ #/;
    $s = reverse($s);
    print "$s\n";
}



__END__;

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
