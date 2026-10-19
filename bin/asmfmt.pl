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

sub nextTabStopPast ($) {
  my ($c) = @_;
  while ($c % $TAB_WIDTH) { ++$c; }
  return $c;
}

sub pad_to_next_tabstop () {
  $_ .= ' ' while length($_) % $TAB_WIDTH;
}
sub pad_to ($) {
  my ($col) = @_;
  $_ .= ' ' while length($_) < $col;
}

my $flow_indent = 4;
my @blocktype = ('');

sub in_proc_body() {
  for (my $i = $#blocktype; $i >= 0; --$i) {
    return 0 if $blocktype[$i] eq 'param_block';
    return 1 if $blocktype[$i] eq '.proc';
  }
  return 0;
}

# TODO: untabify input
# TODO: sigils to disable/enable formatting around blocks

my $last_comment_column = $COMMENT_COLUMN;

my @indents = ();
sub indent() {
  push @indents, $flow_indent;
  $flow_indent += ($flow_indent < 6) ? 2 : 1;
}
sub dedent() {
  $flow_indent = pop @indents;
  die "unmatched indent/dedent" unless defined $flow_indent;
}

my $cc_col = 0;

while (<STDIN>) {
  chomp;
  my $orig = $_;
  $_ =~ s/^\s+|\s+$//g;

  if (m/^$/) {
    # empty line - ignore
    $last_comment_column = $COMMENT_COLUMN;

  } elsif (m/^(;;;.*)/) {

    # TODO: reconsider formatting

    # full line comment - flush left
    #     $_ = respace_comment($1);
    $last_comment_column = $COMMENT_COLUMN;

  } elsif (m/^(;;.*)/) {

    # indented comment - one tab stop
    #    $_ = (' ' x $TAB_WIDTH) . respace_comment($1);
    $_ = (' ' x $TAB_WIDTH) . $1;
    $last_comment_column = $COMMENT_COLUMN;

  } else {

    # strip off end-of-line comments
    my $comment = '';
    if (m/^(.*?)\s*(;.*)$/) {
      $_ = $1;
      $comment = respace_comment($2);
    }

    # TODO: Better "normal label" handling

    if (m/^PARAM_BLOCK/) {
      push(@blocktype, 'param_block');
      # flush left
    } elsif (m/^END_PARAM_BLOCK/) {
      pop(@blocktype);
      # flush left
    } elsif (m/^\.params/) {
      push(@blocktype, '.params');
      # flush left
    } elsif (m/^\.endparams/) {
      pop(@blocktype);
      # flush left
    } elsif (m/^((?:\w|::)+)\s*:=\s*(.*)$/) {

      # equate
      my ($identifier, $expression) = ($1 // '', $2 // '');

      $_ = in_proc_body() ? ' 'x$TAB_WIDTH : '';
      $_ .= $identifier . ' ';
      pad_to($OPERAND_COLUMN) if !in_proc_body() || $blocktype[-1] eq '.params';
      $_ .= ':= ' . $expression . ' ';

      # TODO: Try to align with previous if also equate

    } elsif (m/^((?:\w|::)+)\s*=\s*(.*)$/) {

      # symbol
      my ($identifier, $expression) = ($1 // '', $2 // '');

      $_ = in_proc_body() ? ' 'x$TAB_WIDTH : '';
      $_ .= $identifier . ' ';
      pad_to_next_tabstop();
      $_ .= '= ' . $expression . ' ';

      # TODO: Try to align with previous if also symbol

    } elsif (m/^(\.(?:end)?(?:proc|scope|macro|struct|union|enum|params)\b)\s*(.*)$/ ||
             m/^(\b(?:END_)?(?:PROC_AT)\b)\s*(.*)$/) {

      # TODO: Indent .struct/.enum (codebase is inconsistent)

      # scope - flush left
      my ($opcode, $arguments) = ($1 // '', $2 // '');

      $_ = $opcode;
      if ($arguments) {
        $_ .= ' ' . $arguments;
      }

      # for .endproc/.endscope, comment should be flush left
      if ($opcode =~ /^\.end/ && $comment) {
        $_ .= ' ' . $comment;
        $comment = '';
      }

      if ($opcode eq '.proc' || $opcode eq '.scope') {
        push(@blocktype, $opcode)
      } elsif ($opcode eq '.endproc' || $opcode eq '.endscope') {
        pop(@blocktype);
      } elsif ($opcode eq '.macro') {
        $cc_col = 4;
      } elsif ($opcode eq '.endmacro') {
        $cc_col = 0;
      }

    } elsif (m/^(\.(?:if\w*|elseif|else|endif|define|undef)\b|__FLOW\S+|F2\S+)\s*(.*)$/) {

      # control structures
      my ($opcode, $arguments) = ($1 // '', $2 // '');


      $cc_col -= 2 if $opcode =~ m/^\.(?:elseif|else|endif)$/;

      $_ = '';
      pad_to($cc_col);
      $_ .= $opcode . ' ' . $arguments;

      $cc_col += 2 if $opcode =~ m/^\.(?:if\w*|elseif|else)$/;


    } elsif (m/^(@?\w*:)?\s*(\b(?:SET|(?!ELSE|END)[A-Z]+_IF)\b.*)/ ||
             m/^(@?\w*:)?\s*(\bIF\b.*\b(?:GOTO|JUMP|REDO|CONTINUE|BREAK|RETURN)\b.*)/ ||

             # TODO: might just be a wrapped IF ... OR (etc)
             m/^(@?\w*:)?\s*(\bIF\b.*\\$)/) {

      # "Flow" statements , including shortcut IF ... GOTO (etc)
      my ($label, $statement) = ($1 // '', $2 // '');

      $_ = '';
      $_ .= $label;
      $_ .= ' ';
      pad_to_next_tabstop();
      $_ .= $statement;

    } elsif (m/^(\b(?:IF|ELSE_IF|ELSE|END_IF|DO|DONE|REPEAT|FOREVER|WHILE|UNTIL)\b)\s*(.*)$/) {

      # "Flow" structure macros - dynamic indent
      my ($opcode, $arguments) = ($1 // '', $2 // '');

      dedent() if $opcode =~ m/^(ELSE_IF|ELSE|END_IF|DONE|FOREVER|WHILE|UNTIL)$/;

      $_ = '';
      pad_to($flow_indent);
      $_ .= $opcode;

      if ($arguments) {
        $_ .= ' ';
        if ($opcode =~ m/^(IF|ELSE_IF|WHILE|UNTIL)$/) {
          $arguments =~ s/ +/ /g;
        } else {
          pad_to($OPERAND_COLUMN);
        }
        $_ .= $arguments;
      }

      indent() if $opcode =~ m/^(IF|ELSE|ELSE_IF|DO|REPEAT)$/;
    } elsif ($blocktype[-1] eq 'param_block') {

      # TODO: Also handle .struct, .union

      die "unexpected '$_' in PARAM_BLOCK" unless m/^(\S*)\s+(\.\w+.*)$/;

      my ($name, $allocator) = ($1 // '', $2 // '');

      $_ = $name;
      pad_to(16); # ???
      $_ .= $allocator;

    } elsif (m/^(@?\w*:)?\s*(\S+)?\s*(.*?)\s*(;.*)?$/) {

      # label / opcode / arguments / comment
      my ($label, $opcode, $arguments, $comment) = ($1 // '', $2 // '', $3 // '', $4 // '');

      $_ = '';
      $_ .= $label;
      $_ .= ' ';
      pad_to_next_tabstop();
      $_ .= $opcode;

      if ($opcode =~ m/^\.(byte|word|dword|addr|res|tag)$/) {
        $_ .= ' ';
        pad_to($OPERAND_COLUMN);
        pad_to_next_tabstop();
      } elsif ($opcode =~ m/^(BEGINSEG|ENDSEG)$/) {
        $_ .= ' ';
      } elsif ($opcode =~ m/^([a-z]\w*|[A-Z_]+)$/) {
        $_ .= ' ';
        pad_to($OPERAND_COLUMN);
      } else {
        $_ .= ' ';
      }
      $_ .= $arguments;


      # TODO: Try to align with previous if similar

    } else {
      die "Unexpected line: $_\n";
    }

    # Re-apply comment
    if ($comment) {
      $_ .= ' ';
      pad_to($last_comment_column);
      $last_comment_column = length($_);
      $_ .= $comment;
    } else {
      $last_comment_column = $COMMENT_COLUMN;
    }
  }

  $_ =~ s/\s+$//; # trim right

  #die "Mismatch:\n> $orig\n<$_\n" unless nospace($_) eq nospace($orig);

  print $_, "\n";

  # Continuation? Next line is the same + 2 spaces
  $_ =~ m/^(\s*)/;
  my $spaces = $1;
  while ($_ =~ m/^[^;]*\\$/) {
    $_ = <STDIN>;
    chomp;
    $_ =~ s/^\s+|\s+$//g;
    print $spaces, '  ', $_, "\n";
  }

}
