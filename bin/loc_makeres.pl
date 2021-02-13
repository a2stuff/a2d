#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

sub trim($) {
    my $s = shift; $s =~ s/^\s+|\s+$//g; return $s;
}

sub enquote($$) {
    my ($label, $value) = @_;

    return "\"$value\"" if $label =~ /^res_string_/;
    return "'$value'" if $label =~ /^res_char_/;
    return $value if $label =~ /^res_const_/;

    die "Bad label: \"$label\" at line $.\n";
}

sub indexes($$) {
    my ($string, $char) = @_;
    my @indexes = ();
    my $index = 0;
    while (1) {
        $index = index($string, $char, $index);
        last if $index == -1;
        push @indexes, ++$index;
    }
    return @indexes;
}

sub encode($$) {
    my ($lang, $s) = @_;
    if ($lang eq 'fr') {
        $s =~ tr/à˚ç§éùè¨/@[\\]{|}~/;
    } elsif ($lang eq 'de') {
        $s =~ tr/§ÄÖÜäöüß/@[\\]{|}~/;
    } elsif ($lang eq 'it') {
        $s =~ tr/£§˚çéùàòèì/#@[\\]`{|}~/;
    } else {
        die "Unknown lang: $lang\n";
    }

    die "Unencodable ($lang) in line $.: $s\n" unless $s =~ /^[\x20-\x7e]*$/;

    return $s;
}

sub hashes($) { my $s = shift; return join('', $s =~ m/#/g); }
sub percents($) { my $s = shift; return join('', $s =~ m/%\d*[dsc]/g); }
sub hexes($) { my $s = shift; return join('', $s =~ m/\\x../g); }

sub check($$$) {
    my ($label, $en, $t) = @_;
    return $en unless $t;

    # Ensure placeholders are still there
    die "Hashes mismatch at $label, line $.: $en / $t\n"
        unless hashes($en) eq hashes($t);
    die "Percents mismatch at $label, line $.: $en / $t\n"
        unless percents($en) eq percents($t);
    die "Hexes mismatch at $label, line $.: $en / $t\n"
        unless hexes($en) eq hexes($t);

    # Apply same leading/trailing spaces/periods
    $t =~ s/^[ .]+|[ .]+$//g;
    $t = $1 . $t . $2 if $en =~ m/^([ .]*).*?([ .]*)$/;

    return $t;
}


# Slurp in data
my $header = <STDIN>; # ignore header
my $last_file = '';
my %fhs = ();
my @langs = ('en', 'fr', 'de', 'it');
while (<STDIN>) {
    my ($file, $label, $comment, $en, $fr, $de, $it) = split(/\t/);
    my %strings = (en => $en, fr => $fr, de => $de, it => $it);

    next unless $file and $label;

    if ($file ne $last_file) {
        $last_file = $file;
        foreach my $lang (@langs) {
           open $fhs{$lang}, '>'.($file =~ s/\.s$/.res.$lang/r) or die $!;
        }
    }

    foreach my $lang (@langs) {
        my $str = $strings{$lang};

        if ($lang ne 'en') {
            $str = check($label, $en, $str);
            $str = encode($lang, $str);
        }
        print {$fhs{$lang}} ".define $label ", enquote($label, $str), "\n";

        if ($label =~ m/^res_string_.*_pattern$/ && $str =~ m/#/) {
            my $counter = 0;
            foreach my $index (indexes($str, '#')) {
                my $l = ($label =~ s/^res_string_/res_const_/r) . "_offset" . (++$counter);
                print {$fhs{$lang}} ".define $l $index\n";
            }
        }
    }
}
