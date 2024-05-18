#!/usr/bin/env perl

# Transcode between UTF-8 and Apple II encodings

# args: dir lang
#   dir: "encode" (UTF-8 to Apple) or "decode" (Apple to UTF-8)
#   lang: "fr", "de", "it", "es", "da", "sv", "pt", "nl"
#   e.g. transcode.pl to fr < in > out
#   e.g. transcode.pl from fr < in > out

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";
use Transcode;

my $dir = shift || die " Usage: $0 dir encoding\n";
my $lang = shift || die "Usage: $0 dir encoding\n";

if ($dir eq 'encode') {
  binmode(STDIN, ':utf8');
  binmode(STDOUT);
} else {
  binmode(STDIN);
  binmode(STDOUT, ':utf8');
}

while (<>) {
    print Transcode::transcode($dir, $lang, $_);
}
