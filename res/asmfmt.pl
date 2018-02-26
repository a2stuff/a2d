#!/usr/bin/env perl

use strict;
use warnings;

sub nospace($) {
    my ($s) = @_;
    $s =~ s/ //g;
    return $s;
}


my $tab = 8;
my $comment_column = 32;

# TODO: untabify input
# TODO: sigils to disable/enable formatting around blocks

while (<STDIN>) {
    chomp;
    my $orig = $_;
    $_ =~ s/^\s+|\s+$//g;

    if (m/^$/) {
        # empty line - ignore

    } elsif (m/^(;;;.*)/) {

        # full line comment - flush left
        $_ = $1;

    } elsif (m/^(;;.*)/) {

        # indented comment - one tab stop
        $_ = (' ' x $tab) . $1;

    } else {

        my $comment = '';
        if (m/^(.*?)(;.*)$/) {
            $_ = $1;
            $comment = $2;
        }

        if (m/^(\w+)\s*:=\s*(.*)$/) {

            # equate - flush left (!!), spaced out
            my ($identifier, $expression) = ($1 // '', $2 // '', $3 // '');

            $_ = '';
            $_ .= $identifier . ' ';
            $_ .= ' ' while length($_) % $tab;
            $_ .= ':= ' . $expression . ' ';

        } elsif (m/^(\.(?:end)?(?:proc|scope|macro))\s*(.*)$/) {

            # scope - flush left
            my ($opcode, $arguments) = ($1 // '', $2 // '');

            $_ = $opcode . ' ' . $arguments;

        } elsif (m/^(\.(?:if|elseif|else|endif))\s*(.*)$/) {

            # conditional - half indent left
            my ($opcode, $arguments) = ($1 // '', $2 // '');

            $_ = ' ' x ($tab/2);
            $_ .= $opcode . ' ' . $arguments;

        } elsif (m/^(\w*:)?\s*(\S+)?\s*(.*?)\s*(;.*)?$/) {

            # label / opcode / arguments / comment
            my ($label, $opcode, $arguments, $comment) = ($1 // '', $2 // '', $3 // '', $4 // '');

            $_ = '';
            $_ .= $label     . ' ';
            $_ .= ' ' while length($_) % $tab;
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

    die unless nospace($_) eq nospace($orig);

    print $_, "\n";
}
