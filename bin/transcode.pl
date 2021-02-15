#!/usr/bin/env perl

# Transcode between UTF-8 and Apple II encodings

# args: dir lang
#   dir: "to" (UTF-8 to Apple) or "from" (Apple to UTF-8)
#   lang: "fr", "de", "it"
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
    if ($lang eq 'fr') {
        if ($dir eq 'from') { tr/#@[\\]`{|}~/£à˚ç§`éùè¨/; } else { tr/£à˚ç§`éùè¨/#@[\\]`{|}~/; }
    } elsif ($lang eq 'de') {
        if ($dir eq 'from') { tr/#@[\\]`{|}~/#§ÄÖÜ`äöüß/; } else { tr/#§ÄÖÜ`äöüß/#@[\\]`{|}~/; }
    } elsif ($lang eq 'it') {
        if ($dir eq 'from') { tr/#@[\\]`{|}~/£§˚çéùàòèì/; } else { tr/£§˚çéùàòèì/#@[\\]`{|}~/; }
    } elsif ($lang eq 'es') {
        if ($dir eq 'from') { tr/#@[\\]`{|}~/£§¡Ñ¿`˚ñç~/; } else { tr/£§¡Ñ¿`˚ñç~/#@[\\]`{|}~/; }
    } elsif ($lang eq 'en') {
        # no-op
    }
    else { die "$0: Unknown lang: $lang\n"; }

    print;
}
