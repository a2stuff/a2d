package Transcode;

# Transcode between Unicode and Apple II encodings

# Usage:
#  use Transcode;
#  print Transcode::encode($lang, $string); # Unicode to Apple
#  print Transcode::decode($lang, $string); # Apple to Unicode
#  print Transcode::transcode($dir, $lang, $string);
#
#   $dir: "encode" (Unicode to Apple) or "decode" (Apple to Unicode)
#   $lang: "fr", "de", "it", "es", "da", "sv", "pt", "nl", "bg"

use strict;
use warnings;
use utf8;

sub encode($$) {
  my ($lang, $string) = @_;
  return transcode('encode', $lang, $string);
}

sub decode($$) {
  my ($lang, $string) = @_;
  return transcode('decode', $lang, $string);
}

sub transcode($$$) {
  my ($dir, $lang, $string) = @_;

  die "$0: dir must be 'encode' or 'decode'\n" unless $dir eq 'encode' ||  $dir eq 'decode';
  my $decode = $dir eq 'decode';
  local $_ = $string;

  tr/\xA0/ / unless $decode; # NBSP to regular space

  # Based on Apple IIgs Hardware Reference Table C-1 (with " incorrectly showing for °)
  if      ($lang eq 'fr') { # ISO-646-FR (1973) / ISO-IR-025
    if ($decode) { tr/#@[\\]`{|}~/£à°ç§`éùè¨/; }
    else {         tr/£à°ç§`éùè¨/#@[\\]`{|}~/; }
  } elsif ($lang eq 'de') { # ISO-646-DE / ISO-IR-021
    if ($decode) { tr/#@[\\]`{|}~/#§ÄÖÜ`äöüß/; }
    else {         tr/#§ÄÖÜ`äöüß/#@[\\]`{|}~/; }
  } elsif ($lang eq 'it') { # ISO-646-IT / ISO-IR-015
    if ($decode) { tr/#@[\\]`{|}~/£§°çéùàòèì/; }
    else {         tr/£§°çéùàòèì/#@[\\]`{|}~/; }
  } elsif ($lang eq 'es') { # ISO-646-ES / ISO-IR-017
    if ($decode) { tr/#@[\\]`{|}~/£§¡Ñ¿`°ñç~/; }
    else {         tr/£§¡Ñ¿`°ñç~/#@[\\]`{|}~/; }
    # unofficial extensions for A2D
    if ($decode) { tr/\x10-\x14/áéíóú/; }
    else {         tr/áéíóú/\x10-\x14/; }
  } elsif ($lang eq 'nl') {
    # unofficial extensions for A2D
    if ($decode) { tr/\x10/ë/; }
    else {         tr/ë/\x10/; }
  } elsif ($lang eq 'da') { # ISO-646-DK / CP01107
    if ($decode) { tr/#@[\\]`{|}~/#@ÆØÅ`æøå~/; }
    else {         tr/#@ÆØÅ`æøå~/#@[\\]`{|}~/; }
  } elsif ($lang eq 'sv') { # ISO-646-SE / ISO-IR-010 (mostly)
    if ($decode) { tr/#@[\\]`{|}~/#@ÄÖÅ`äöå~/; }
    else {         tr/#@ÄÖÅ`äöå~/#@[\\]`{|}~/; }
  } elsif ($lang eq 'pt') { # Based on TK3000
    if ($decode) { tr/#&@[\\]_`{|}~/õêáãâçàéíúôó/; }
    else {         tr/õêáãâçàéíúôó/#&@[\\]_`{|}~/; }
  } elsif ($lang eq 'bg') { # Based on Pravetz 8A (KOI-7 N2 Bulgarian variant)
    if ($decode) { tr/`abcdefghijklmnopqrstuvwxyz{|}~/ЮАБЦДЕФГХИЙКЛМНОПЯРСТУЖВЬЪЗШЭЩЧ/; }
    else {         tr/ЮАБЦДЕФГХИЙКЛМНОПЯРСТУЖВЬЪЗШЭЩЧ/`abcdefghijklmnopqrstuvwxyz{|}~/; }
  } elsif ($lang eq 'en') {
    # no-op
  } else {
    die "$0: Unknown lang: $lang\n";
  }

  # See src/common.inc for how code points 0x00-0x1F are used. Note
  # that 0x12 and 0x13 are basically π and ÷ but since those are not
  # in all encodings (and are unused) they are left out of this
  # mapping.
  if ($decode) { tr/\x08\x0A\x0B\x0D\x0E\x0F\x15\x16\x17\x1B/←↓↑⏎©®→°◇◆/; }
  else         { tr/←↓↑⏎©®→°◇◆/\x08\x0A\x0B\x0D\x0E\x0F\x15\x16\x18\x1B/; }

  return $_;
}

1;
