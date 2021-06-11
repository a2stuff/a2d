#!/usr/bin/env perl

# Check the executable version, ensure it's recent enough.
# Usage: check_ver.pl EXECUTABLE REQUIRED_VERSION

use v5.10;
use strict;
use warnings;
use version 0.77;

my $executable = shift(@ARGV) or die "$0: Missing executable name\n";

my $required = shift(@ARGV) or die "$0: Missing required version\n";
my $rver = version->parse($required . '.0');

my $out = `$executable --version 2>&1`;
die "$0: Can't determine $executable version\n" unless $out =~ m/^$executable V(\S+)/;
$out = $1;
my $ver = version->parse('v' . $out . '.0');

die "$0: Required $executable $rver, saw $ver\n" unless $ver >= $rver;
