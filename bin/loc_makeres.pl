#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";
use Transcode;

binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

sub trim($) {
  my $s = shift; $s =~ s/^\s+|\s+$//g; return $s;
}

sub enquote($$) {
  my ($label, $value) = @_;

  if ($label =~ /^res_string_/) {
    $value =~ s/"/\\x22/g; # Escape double quotes
    return "\"$value\"";
  }
  return "\"$value\"" if $label =~ /^res_string_/;
  return "'$value'" if $label =~ /^res_char_/;
  return $value if $label =~ /^res_const_/;
  return "\"$value\"" if $label =~ /^res_filename_/;

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

# Encodes into source strings (with escaping)
sub encode($$) {
  my ($lang, $s) = @_;

  $s =~ tr/\xA0/ /; # NBSP to regular space
  $s =~ tr/\\/\xFF/; # Protect \ temporarily, for \xNN sequences (etc)

  $s = Transcode::encode($lang, $s);

  $s =~ s|\\|\\\\|g; # Escape newly generated \
  $s =~ tr/\xFF/\\/; # Restore the original \ (see above)
  $s =~ s/([\x10-\x14])/sprintf("\\x%02x",ord($1))/seg; # Escape control chars

  die "Unencodable ($lang) in line $.: $s\n" unless $s =~ /^[\x20-\x7e]*$/;

  return $s;
}

sub hashes($) { my $s = shift; return join('', $s =~ m/#/g); }
sub percents($) { my $s = shift; return join('', $s =~ m/%\d*[dsc]/g); }
sub hexes($) { my $s = shift; return join('', $s =~ m/\\x../g); }
sub punct($) { my $s = shift; $s =~ m/([.:?!]*)\s*$/; return $1; }

sub check($$$$) {
  my ($lang, $label, $en, $t) = @_;
  return $en unless $t;

  # Apply same leading/trailing spaces
  if ($label !~ /^res_char_/) {
    $t =~ s/^[ ]+|[ ]+$//g;
    $t = $1 . $t . $2 if $en =~ m/^([ ]*).*?([ ]*)$/;
  }

  # Ensure placeholders are still there
  die "Hashes mismatch at $label, line $.: $en / $t\n"
      unless hashes($en) eq hashes($t);
  die "Percents mismatch at $label, line $.: $en / $t\n"
      unless percents($en) eq percents($t);
  die "Hexes mismatch at $label, line $.: $en / $t\n"
      unless hexes($en) eq hexes($t);
  die "Punctuation mismatch at $label, line $.: '$en' / '$t'\n"
      unless $label =~ /^res_char_/ || punct($en) eq punct($t);

  die "Bad filename at $label, line $.: '$en' / '$t'\n"
      if $label =~ /^res_filename/ && not ($t =~ /^[A-Za-z][A-Za-z0-9.]*$/ && length($t) <= 15);

  # Language specific checks:
  if ($lang eq 'fr') {
    die "Expect space before punctuation in $lang, line $.: $t\n"
        if $t =~ m/\S[!?:]/;
  } else {
    die "Expect no space before punctuation in $lang, line $.: $t\n"
        if $t =~ m/\s[!?:]/;
  }

  die "Bad char resource in $lang, line $.: $t\n"
      if $label =~ /^res_char_/ && length($t) != 1;
  die "Bad const resource in $lang, line $.: $t\n"
      if $label =~ /^res_const_/ && $t !~ /^\d+$/;

  if (0) {
    warn "String > 2x in $lang, line $.: '$en' / '$t'\n"
        if length($t) / length($en) > 2;
  }

  return $t;
}


# Slurp in data
my $header = <STDIN>; # ignore header
my $last_file = '';
my %fhs = ();
my @langs = ('en', 'fr', 'de', 'it', 'es', 'pt', 'sv', 'da', 'nl', 'bg');

my %dupes = ();

while (<STDIN>) {
  my ($file, $label, $comment, $en, $fr, $de, $it, $es, $pt, $sv, $da, $nl, $bg) = split(/\t/);
  my %strings = (en => $en, fr => $fr, de => $de, it => $it, es => $es, pt => $pt, sv => $sv, da => $da, nl => $nl, bg => $bg);

  next unless $file and $label;

  if ($file ne $last_file) {
    $last_file = $file;
    foreach my $lang (@langs) {
      my $outfile = $file;
      $outfile =~ s|/|/res/|;
      $outfile =~ s|\.s$|.res.$lang|;
      open $fhs{$lang}, '>src/'.$outfile or die $!;
    }

    %dupes = ();
  }

  if (0 && $label =~ m/res_string_/) {
    if (defined $dupes{$en}) {
      say STDERR "Possible dupe: '$en' - $dupes{$en} / $label";
    } else {
      $dupes{$en} = $label;
    }
  }


  foreach my $lang (@langs) {
    my $str = $strings{$lang};

    if ($lang ne 'en') {
      $str = check($lang, $label, $en, $str);

      if ($lang eq 'bg') {
        $str =~ s/(%\d*\w|\\r|\\x\w\w|.)/length $1 == 1 ? uc($1) : $1/eg;
      }

      $str = encode($lang, $str);
    } else {
      check($lang, $label, $en, $en);
    }

    if ($str =~ m/^(.*)##(.*)$/) {
      # If string has '##', split into prefix/suffix.
      print {$fhs{$lang}} ".define ${label}_prefix ", enquote($label, $1), "\n";
      print {$fhs{$lang}} ".define ${label}_suffix ", enquote($label, $2), "\n";
    } else {
      # Normal case.
      print {$fhs{$lang}} ".define $label ", enquote($label, $str), "\n";

      # If string is a pattern, emit constants for the offsets of #.
      if ($label =~ m/^res_string_.*_pattern$/ && $str =~ m/#/) {
        my $counter = 0;
        foreach my $index (indexes($str, '#')) {
          my $l = ($label =~ s/^res_string_/res_const_/r) . "_offset" . (++$counter);
          print {$fhs{$lang}} ".define $l $index\n";
        }
      }
    }
  }
}
