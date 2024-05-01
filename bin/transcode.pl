#!/usr/bin/env perl

# Transcode between UTF-8 and Apple II encodings

# args: dir lang
#   dir: "to" (UTF-8 to Apple) or "from" (Apple to UTF-8)
#   lang: "fr", "de", "it", "es", "da", "sv", "pt", "nl"
#   e.g. transcode.pl to fr < in > out
#   e.g. transcode.pl from fr < in > out

use strict;
use warnings;
use utf8;
binmode(STDOUT, ":utf8");

my $dir = shift || die " Usage: $0 dir encoding\n";
my $lang = shift || die "Usage: $0 dir encoding\n";

die "$0: dir must be 'to' or 'from'\n" unless $dir eq 'to' ||  $dir eq 'from';

while (<>) {
    tr/\xA0/ / if $dir eq 'to'; # NBSP to regular space

    # Based on Apple IIgs Hardware Reference Table C-1 (with " incorrectly showing for °)
    if      ($lang eq 'fr') {
        if ($dir eq 'from') { tr/#@[\\]`{|}~/£à°ç§`éùè¨/; } else { tr/£à°ç§`éùè¨/#@[\\]`{|}~/; } # ISO-646-FR (1973) / ISO-IR-025
    } elsif ($lang eq 'de') {
        if ($dir eq 'from') { tr/#@[\\]`{|}~/#§ÄÖÜ`äöüß/; } else { tr/#§ÄÖÜ`äöüß/#@[\\]`{|}~/; } # ISO-646-DE / ISO-IR-021
    } elsif ($lang eq 'it') {
        if ($dir eq 'from') { tr/#@[\\]`{|}~/£§°çéùàòèì/; } else { tr/£§°çéùàòèì/#@[\\]`{|}~/; } # ISO-646-IT / ISO-IR-015
    } elsif ($lang eq 'es') {
        if ($dir eq 'from') { tr/#@[\\]`{|}~/£§¡Ñ¿`°ñç~/; } else { tr/£§¡Ñ¿`°ñç~/#@[\\]`{|}~/; } # ISO-646-ES / ISO-IR-017
        # unofficial extensions for A2D
        if ($dir eq 'from') { tr/\x10-\x14/áéíóú/; } else { tr/áéíóú/\x10-\x14/; }
    } elsif ($lang eq 'nl') {
        # unofficial extensions for A2D
        if ($dir eq 'from') { tr/\x10/ë/; } else { tr/ë/\x10/; }
    } elsif ($lang eq 'da') {
        if ($dir eq 'from') { tr/#@[\\]`{|}~/#@ÆØÅ`æøå~/; } else { tr/#@ÆØÅ`æøå~/#@[\\]`{|}~/; } # ISO-646-DK / CP01107
    } elsif ($lang eq 'sv') {
        if ($dir eq 'from') { tr/#@[\\]`{|}~/#@ÄÖÅ`äöå~/; } else { tr/#@ÄÖÅ`äöå~/#@[\\]`{|}~/; } # ISO-646-SE / ISO-IR-010 (mostly)
    } elsif ($lang eq 'pt') {
        # Based on TK3000
       if ($dir eq 'from') { tr/#&@[\\]_`{|}~/õêáãâçàéíúôó/; }
       else                { tr/õêáãâçàéíúôó/#&@[\\]_`{|}~/; }
    } elsif ($lang eq 'en') {
        # no-op
    }
    else { die "$0: Unknown lang: $lang\n"; }

    print;
}
