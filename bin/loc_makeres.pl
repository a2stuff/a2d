#!/usr/bin/env perl

# Generates the src/*/res/*.res.* files with localized strings.

# Instructions:
#   1. Go to the localization sheet (https://docs.google.com/spreadsheets/d/1NIZQM4ua6ruLJk_P7MfTKN9S5LNwHwYJM_UhvY-ep3A/edit?usp=sharing)
#   2. Click in the top left to select all rows/columns
#   3. Edit > Copy
#   4. On the command line: pbpaste > bin/loc_makeres.pl

# Notes:
#   * Requires python-bidi: pip install python-bidi

use strict;
use warnings;
use IPC::Open2;

use FindBin;
use lib "$FindBin::Bin";
use Transcode;

binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

# Language definitions
my %langs = (
  'en' => {'dir' => 'LTR'},
  'fr' => {'dir' => 'LTR'},
  'de' => {'dir' => 'LTR'},
  'it' => {'dir' => 'LTR'},
  'es' => {'dir' => 'LTR'},
  'pt' => {'dir' => 'LTR'},
  'sv' => {'dir' => 'LTR'},
  'da' => {'dir' => 'LTR'},
  'nl' => {'dir' => 'LTR'},
  'bg' => {'dir' => 'LTR'},
  'he' => {'dir' => 'RTL'},
    );
sub dir($) { my $lang = shift; return $langs{$lang}{dir}; }

# Prep
die "Failed\n" unless system("echo '' | bin/pybidi.py > /dev/null") == 0;
my $pybidi_pid = open2(my $bidi_out, my $bidi_in, 'bin/pybidi.py');
binmode($bidi_in, ':utf8');
binmode($bidi_out, ':utf8');

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

# Logical order to visual order (BiDi)
sub display($$) {
  my ($lang, $str) = @_;

  if (dir($lang) eq 'RTL') {
    # Wrap escapes in LRE...PDF
    $str =~ s/(%\d*[a-z]|\\r|\\x\w\w)/\x{202A}$1\x{202C}/g;

    # Convert from logical to visual order
    print $bidi_in $str, "\n";
    local $.;
    $str = <$bidi_out>;
    chomp $str;
  }

  return $str;
}

sub hashes($) { my $s = shift; return join('', $s =~ m/#/g); }
sub percents($) { my $s = shift; return join('', $s =~ m/%\d*[a-z]/g); }
sub hexes($) { my $s = shift; return join('', $s =~ m/\\x\w\w/g); }
sub punct($) { my $s = shift; $s =~ m/([.:?!]*)\s*$/; return $1; }

sub check($$$$) {
  my ($lang, $label, $en, $t) = @_;
  return $en unless $t;

  # Ensure placeholders are still there
  die "Hashes mismatch at $label, line $.: '$en' / '$t'\n"
      unless hashes($en) eq hashes($t);
  die "Percents mismatch at $label, line $.: '$en' / '$t'\n"
      unless percents($en) eq percents($t);
  die "Hexes mismatch at $label, line $.: '$en' / '$t'\n"
      unless hexes($en) eq hexes($t);
  die "Punctuation mismatch at $label, line $.: '$en' / '$t'\n"
      unless $label =~ /^res_char_/ ||
      punct($en) eq (dir($lang) eq 'RTL' ? reverse punct($t) : punct($t));

  die "Bad filename at $label, line $.: '$en' / '$t'\n"
      if $label =~ /^res_filename/ && not ($t =~ /^[A-Za-z][A-Za-z0-9.]*$/ && length($t) <= 15);

  # Language specific checks:
  if ($lang eq 'fr') {
    die "Expect space before punctuation in $lang, line $.: '$t'\n"
        if $t =~ m/\S[!?:]/;
  } else {
    die "Expect no space before punctuation in $lang, line $.: '$t'\n"
        if $t =~ m/\s[!?:]/;
  }

  die "Bad char resource in $lang, line $.: '$t'\n"
      if $label =~ /^res_char_/ && length($t) != 1;
  die "Bad const resource in $lang, line $.: '$t'\n"
      if $label =~ /^res_const_/ && $t !~ /^\d+$/;

  if (0) {
    warn "String > 2x in $lang, line $.: '$en' / '$t'\n"
        if length($t) / length($en) > 2;
  }

  return $t;
}

# Slurp in data
my $header = <STDIN>;
chomp $header;
my @header = split(/\t/, $header);

my $last_file = '';
my %fhs = ();
my @langs = keys %langs;

my %dupes = ();

while (<STDIN>) {
  my @cols = split(/\t/);
  my %strings = ();
  for (my $i = 0; $i < scalar @header; ++$i) {
    $strings{$header[$i]} = $cols[$i];
  }
  my ($file, $label) = ($strings{File}, $strings{Label});
  next unless $file and $label;
  my $en = $strings{en};

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

  $en =~ m/^(\s*).*?(\s*)$/;
  my ($en_leading_ws, $en_trailing_ws) = ($1, $2);

  foreach my $lang (@langs) {
    my $str = $strings{$lang};
    my $has_str = !!$str;

    # NOTE: Most of the following is a no-op for EN but is applied
    # anyway for consistency and to verify the processing.

    # If not given, use EN; otherwise, apply a set of validation rules.
    $str = check($lang, $label, $en, $str);

    # Remove leading/trailing whitespace.
    $str =~ s/^\s+|\s+$//g unless $label =~ /^res_char_/;

    # For encodings that preclude lowercase English, convert to uppercase.
    if (Transcode::decode($lang, 'a') ne 'a') {
      $str =~ s/(%\d*[a-z]|\\r|\\x\w\w|.)/length $1 == 1 ? uc($1) : $1/eg;
    }

    # Convert from logical to visual order.
    $str = display($lang, $str) if $has_str;

    # Match EN leading/trailing whitespace, in visual order.
    $str = $en_leading_ws . $str . $en_trailing_ws unless $label =~ /^res_char_/;

    # Transcode from Unicode to appropriate 7-bit encoding.
    $str = encode($lang, $str);

    if ($str =~ m/^(.*)##(.*)$/) {
      # If string has '##', split into prefix/suffix.
      # NOTE: For RTL no change is needed, since visual order remains "prefix ... suffix"
      my ($prefix, $suffix) = ($1, $2);
      print {$fhs{$lang}} ".define ${label}_prefix ", enquote($label, $prefix), "\n";
      print {$fhs{$lang}} ".define ${label}_suffix ", enquote($label, $suffix), "\n";
    } else {
      # Normal case.
      print {$fhs{$lang}} ".define $label ", enquote($label, $str), "\n";

      # If string is a pattern, emit constants for the offsets of #.
      if ($label =~ m/^res_string_.*_pattern$/ && $str =~ m/#/) {
        my $counter = 0;
        my @indexes = indexes($str, '#');
        if (dir($lang) eq 'RTL' && $label !~ /version_pattern/) {
          # Invert (logical order vs. visual order)
          @indexes = reverse @indexes;
        }
        foreach my $index (@indexes) {
          my $l = ($label =~ s/^res_string_/res_const_/r) . "_offset" . (++$counter);
          print {$fhs{$lang}} ".define $l $index\n";
        }
      }
    }
  }
}
