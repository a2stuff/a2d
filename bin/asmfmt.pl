#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

my $TAB_WIDTH = 8;
my $OPERAND_COLUMN = 16;
my $COMMENT_COLUMN = 32;

sub nospace($) {
  my ($s) = @_;
  $s =~ s/\s//g;
  return $s;
}

sub respace_comment($) {
  my ($s) = @_;
  $s =~ s/^(;+)\s+(.*)/$1 $2/g;
  return $s;
}

sub max ($$) { $_[$_[0] < $_[1]] }
sub min ($$) { $_[$_[0] > $_[1]] }

my $tabstop = 0;
my $flow_indent = 4;

# TODO: untabify input
# TODO: sigils to disable/enable formatting around blocks

my @indents = ();
sub indent() { push @indents, $flow_indent; $flow_indent += ($flow_indent < 6) ? 2 : 1; }
sub dedent() { $flow_indent = pop @indents; }

while (<STDIN>) {
  chomp;
  my $orig = $_;
  $_ =~ s/^\s+|\s+$//g;

  if (m/^$/) {
    # empty line - ignore
    $tabstop = 0;

  } elsif (m/^(;;;.*)/) {

    # full line comment - flush left
    $_ = respace_comment($1);
    $tabstop = 0;

  } elsif (m/^(;;.*)/) {

    # indented comment - one tab stop
    $_ = (' ' x $TAB_WIDTH) . respace_comment($1);
    $tabstop = 0;

  } else {

    my $comment = '';
    if (m/^(.*?)(;.*)$/) {
      $_ = $1;
      $comment = respace_comment($2);
    }

    if (m/^(\w+)\s*:=\s*(.*)$/) {

      # equate
      my ($identifier, $expression) = ($1 // '', $2 // '', $3 // '');

      # TODO: Only indent w/in proc?
      $_ = ' ' x $TAB_WIDTH;
      $_ .= $identifier . ' ';
      $_ .= ':= ' . $expression . ' ';

    } elsif (m/^(\w+)\s*=\s*(.*)$/) {

      # symbol
      my ($identifier, $expression) = ($1 // '', $2 // '', $3 // '');

      # TODO: Only indent w/in proc?
      $_ = ' ' x $TAB_WIDTH;
      $_ .= $identifier . ' ';
      $_ .= '= ' . $expression . ' ';

    } elsif (m/^(\.(?:end)?(?:proc|scope|macro|struct|enum|params)\b)\s*(.*)$/ ||
             m/^(\b(?:END_)?(?:PROC_AT)\b)\s*(.*)$/) {

      # scope - flush left
      my ($opcode, $arguments) = ($1 // '', $2 // '');
      $tabstop = 0;

      $_ = $opcode;
      if ($arguments) {
        $_ .= ' ' . $arguments;
      }

      # for .endproc/.endscope, comment should be flush left
      if ($opcode =~ /^\.end/ && $comment) {
        $_ .= ' ' . $comment;
        $comment = '';
      }

    } elsif (m/^(\.(?:if\w*|elseif|else|endif)\b)\s*(.*)$/) {

      # conditional - flush left
      my ($opcode, $arguments) = ($1 // '', $2 // '');
      $tabstop = 0;

      $_ = $opcode . ' ' . $arguments;

    } elsif (m/^(\b(?:IF_\w+|ELSE_IF\w+|ELSE|END_IF|DO|REPEAT|WHILE_\w+|UNTIL_\w+)\b)\s*(.*)$/) {

      # conditional macros - dynamic indent
      my ($opcode, $arguments) = ($1 // '', $2 // '');
      $tabstop = 0;

      if ($opcode =~ m/^(ELSE_IF_\w+|ELSE|END_IF|WHILE_\w+|UNTIL_\w+)$/) {
        dedent();
      }

      $_ = ' ' x $flow_indent;
      $_ .= $opcode;

      if ($arguments) {
        $_ .= ' ';
        $_ .= ' ' while length($_) < $OPERAND_COLUMN;
        $_ .= $arguments;
      }

      if ($opcode =~ m/^(IF_\w+|ELSE|ELSE_IF_\w+|DO)$/) {
        indent();
      }

    } elsif (m/^(@?\w*:)?\s*(\S+)?\s*(.*?)\s*(;.*)?$/) {

      # label / opcode / arguments / comment
      my ($label, $opcode, $arguments, $comment) = ($1 // '', $2 // '', $3 // '', $4 // '');

      $_ = '';
      $_ .= $label     . ' ';
      $tabstop = 0 unless $label;

      $_ .= ' ' while length($_) % $TAB_WIDTH;

      $tabstop = max($tabstop, length($_));
      $_ .= ' ' while length($_) < $tabstop;

      $_ .= $opcode    . ' ';
      if ($opcode =~ m/^([a-z]{3}\w*)$|^(\.(byte|word|addr|res))$/) {
        $_ .= ' ' while length($_) < $OPERAND_COLUMN;
      }
      $_ .= $arguments . ' ';

    } else {
      die "Unexpected line: $_\n";
    }

    if ($comment ) {
      $_ .= ' ' while length($_) < $COMMENT_COLUMN;
      $_ .= $comment;
    }
  }

  $_ =~ s/\s+$//; # trim right

  #die "Mismatch:\n> $orig\n<$_\n" unless nospace($_) eq nospace($orig);

  print $_, "\n";
}
