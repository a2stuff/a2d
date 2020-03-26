#!/usr/bin/env perl

use strict;
use warnings;

my $org = $ARGV[0] || '2000';

print <<"END_HEADER";
GLOBAL {
  STARTADDR       \$$org;
  PAGELENGTH      0;                  # No paging
  CPU             "6502";
};
ASMINC { FILE "../inc/apple2.inc"; };
ASMINC { FILE "../../cc65/asminc/apple2.inc"; };
END_HEADER

print <<'END_LABELS';


LABEL { NAME "MGTK"; ADDR $4000; PARAMSIZE 3; };
LABEL { NAME "MLI"; ADDR $BF00; PARAMSIZE 3; };

LABEL { NAME "FONT"; ADDR $8800; };
LABEL { NAME "START"; ADDR $8E00; };

END_LABELS

print <<'END_SEGS';
RANGE { START $0000; END $87FF; TYPE Code; };
RANGE { START $8800; END $8DFF; TYPE ByteTable; };
RANGE { START $8E00; END $FFFF; TYPE Code; };
#RANGE { START $DA20; END $DAFF; TYPE ByteTable; };
#RANGE { START $E690; END $E6BF; TYPE ByteTable; };
#RANGE { START $FB00; END $FFFF; TYPE ByteTable; };
END_SEGS
