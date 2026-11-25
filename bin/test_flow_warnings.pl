#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd qw(cwd);
my $path = cwd;

sub do_case($$) {
  my ($code, $expected_error) = @_;

  my $filename = "/tmp/file.s";

  open(my $fh, ">", $filename);
  print $fh <<EOF;

  .include "../config.inc"
  .include "../inc/macros.inc"

  target := \$1234
  .org \$2000

  $code

EOF
  close ($fh);

  my $out = `ca65 --target apple2 --include-dir $path/src/extras -o /tmp/file.o $filename 2>&1`;
  utf8::decode($out);
  $out =~ tr/‘’/''/;

  my @errors = ($out =~ /Error: .*$/mg);
  if (scalar @errors > 1) {
    print "Multiple errors from:\n";
    print "Code:     $code\n";
    print "Expected: $expected_error\n";
    print join("\n", @errors);
    print "\n\n";
    return;
  } elsif (scalar @errors == 0) {
    print "No errors from:\n";
    print "Code:     $code\n";
    print "Expected: $expected_error\n";
    print "\n";
    return;
  }

  my $saw;
  if (!$?) {
    die "No error from '$code', expected: $expected_error\n";
  } elsif ($out =~ /^\/tmp\/file\.s:\d+: Error: User error: (.*)$/m) {
    $saw = $1;
  } elsif ($out =~ /^\/tmp\/file\.s:\d+: Error: (.*)$/m) {
    $saw = $1;
  } else {
    die "No detectable error from '$code', saw instead:\n$out\n\nExpected: $expected_error\n";
  }

  if ($saw ne $expected_error) {
    print "Code:     $code\n";
    print "Expected: $expected_error\n";
    print "Saw:      $saw\n";
    print "\n";
  }
}

open(my $fh, '<', 'src/extras/asmtest.system.s');
my $in_cases = 0;
while (<$fh>) {
  chomp;
  next unless $_;
  if (!$in_cases) {
    if ($_ eq '__BEGIN_CASES__') {
      $in_cases = 1;
      next;
    }
  } else {
    if ($_ eq '__END_CASES__') {
      $in_cases = 0;
      next;
    } elsif (m/^ *(.*?) +; +(.*)$/) {
      do_case($1, $2);
    } else {
      die "Unexpected in cases: '$_'\n";
    }
  }
}
close($fh);
