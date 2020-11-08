#!/usr/bin/env perl

use strict;
use warnings;

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

my $tab = 8;
my $comment_column = 32;
my $tabstop = 0;

# TODO: untabify input
# TODO: sigils to disable/enable formatting around blocks

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
        $_ = (' ' x $tab) . respace_comment($1);
        $tabstop = 0;

    } else {

        my $comment = '';
        if (m/^(.*?)(;.*)$/) {
            $_ = $1;
            $comment = respace_comment($2);
        }

        if (m/^(\w+)\s*:=\s*(.*)$/) {

            # equate - flush left (!!), spaced out
            my ($identifier, $expression) = ($1 // '', $2 // '', $3 // '');

            $_ = '';
            $_ .= $identifier . ' ';
            $_ .= ' ' while length($_) % $tab;

            $tabstop = max($tabstop, length($_));
            $_ .= ' ' while length($_) < $tabstop;

            $_ .= ':= ' . $expression . ' ';

        } elsif (m/^(\w+)\s*=\s*(.*)$/) {

            # symbol - flush left (!!), spaced out
            my ($identifier, $expression) = ($1 // '', $2 // '', $3 // '');

            $_ = '';
            $_ .= $identifier . ' ';
            $_ .= ' ' while length($_) % $tab;

            $tabstop = max($tabstop, length($_));
            $_ .= ' ' while length($_) < $tabstop;

            $_ .= '= ' . $expression . ' ';

        } elsif (m/^(\.(?:end)?(?:proc|scope|macro|struct|enum|params)\b)\s*(.*)$/ ||
                 m/^(\b(?:END_)?(?:PROC_AT)\b)\s*(.*)$/) {

            # scope - flush left
            my ($opcode, $arguments) = ($1 // '', $2 // '');
            $tabstop = 0;

            $_ = $opcode . ' ' . $arguments;

        } elsif (m/^(\.(?:if\w*|elseif|else|endif)\b)\s*(.*)$/ ||
                 m/^(\b(?:IF_\w+|ELSE|END_IF)\b)\s*(.*)$/) {

            # conditional - half indent left
            my ($opcode, $arguments) = ($1 // '', $2 // '');
            $tabstop = 0;

            $_ = ' ' x ($tab/2);
            $_ .= $opcode . ' ' . $arguments;

        } elsif (m/^(\w*:)?\s*(\S+)?\s*(.*?)\s*(;.*)?$/) {

            # label / opcode / arguments / comment
            my ($label, $opcode, $arguments, $comment) = ($1 // '', $2 // '', $3 // '', $4 // '');

            $_ = '';
            $_ .= $label     . ' ';
            $tabstop = 0 unless $label;

            $_ .= ' ' while length($_) % $tab;

            $tabstop = max($tabstop, length($_));
            $_ .= ' ' while length($_) < $tabstop;

            $_ .= $opcode    . ' ';
            if ($opcode =~ m/^([a-z]{3}\w*)$|^(\.(byte|word|addr|res))$/) {
                $_ .= ' ' while length($_) % $tab;
            }
            $_ .= $arguments . ' ';

        } else {
            die "Unexpected line: $_\n";
        }

        if ($comment ) {
            $_ .= ' ' while length($_) < $comment_column;
            $_ .= $comment;
        }
    }

    $_ =~ s/\s+$//; # trim right

    die "Mismatch:\n> $orig\n<$_\n"unless nospace($_) eq nospace($orig);

    print $_, "\n";
}
