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

    die "Unencodable in line $.: $s\n" unless $s =~ /^[\x20-\x7e]*$/;

    return $s;
}

sub hashes($) { my $s = shift; return $s =~ s/^[^#]$//; }
sub percents($) { my $s = shift; return join('', $s =~ m/%\d*[dsc]/g); }

sub check($$$) {
    my ($label, $en, $t) = @_;
    return $en unless $t;

    # Ensure placeholders are still there
    die "Hashes mismatch at $label, line $.: $en / $t\n"
        unless hashes($en) eq hashes($t);
    die "Percents mismatch at $label, line $.: $en / $t\n"
        unless percents($en) eq percents($t);

    # Apply same leading/trailing spaces
    $t = trim($t);
    $t = $1 . $t . $2 if $en =~ m/^(\s*).*(\s*)$/;

    return $t;
}


# Slurp in data
my $header = <STDIN>; # ignore header
my $last_file = '';
my %fhs = ();
while (<STDIN>) {
    my ($file, $label, $comment, $en, $fr, $de, $it) = split(/\t/);
    next unless $file and $label;

    if ($file ne $last_file) {
        $last_file = $file;
        open $fhs{'en'}, '>'.($file =~ s/\.s$/.res.en/r) or die $!;
    }

    # TODO: Check/encode/output all translations
    check($label, $en, $it);
    $it = encode('it', $it);

    print {$fhs{'en'}} ".define $label ", enquote($label, $en), "\n";
}
