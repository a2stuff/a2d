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
END_HEADER

print <<'END_LABELS';

LABEL { NAME "RAMRDOFF"; ADDR $C002; };
LABEL { NAME "RAMRDON"; ADDR $C003; };
LABEL { NAME "RAMWRTOFF"; ADDR $C004; };
LABEL { NAME "RAMWRTON"; ADDR $C005; };
LABEL { NAME "ALTZPOFF"; ADDR $C008; };
LABEL { NAME "ALTZPON"; ADDR $C009; };
LABEL { NAME "LCBANK1"; ADDR $C08B; };
LABEL { NAME "AUXMOVE"; ADDR $C311; };
LABEL { NAME "XFER"; ADDR $C314; };

LABEL { NAME "A2D"; ADDR $4000; };
LABEL { NAME "UNKNOWN_CALL"; ADDR $8E00; };
LABEL { NAME "MLI"; ADDR $BF00; };


END_LABELS

print <<'END_SEGS';
#RANGE { START $8800; END $939E; TYPE ByteTable; };
#RANGE { START $DA20; END $DAFF; TYPE ByteTable; };
#RANGE { START $E690; END $E6BF; TYPE ByteTable; };
#RANGE { START $FB00; END $FFFF; TYPE ByteTable; };
END_SEGS




my $ptr = hex($org);

my @last = (-1, -1, -1);
my $b;
while (read(STDIN, $b, 1)) {
    $b = ord($b);
    #print sprintf("%04x: \$%02x\n", $ptr, $b);
    ++$ptr;

    shift @last;
    push @last, $b;
    my $lastaddr = $last[1] | ($last[2] << 8);

    if ($last[0] == 0x20 &&
        ($lastaddr == 0x4000 || $lastaddr == 0x8E00 || $lastaddr == 0xBF00)) {
        die "expected 3 more\n" unless read(STDIN, $b, 3) == 3;
        print sprintf(
            "RANGE { START \$%04x; END \$%04x; TYPE ByteTable; };\n" .
            "RANGE { START \$%04x; END \$%04x; TYPE AddrTable; };\n",
            $ptr, $ptr, $ptr+1, $ptr+2
            );

        $ptr += 3;
        next;
    }
}
