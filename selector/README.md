0000-00026 org $2000 - copies 0027x$200 to LC2 $D100 (quit handler) then invokes QUIT

0027x$200  org $1000 - stashes prefix (etc)
                     - reads SELECTOR $600 bytes at $1C00 (thru $21FF)
                     - jumps to $2000

open questions:
* does the code from $0227 to $03FF get used? (loaded $1E27..$1FFF)
* does the code just before $0227 get used? (loaded just before $1E27..$1FFF)
  (probably copied incidentally to LC2)

....

0400x$200  org $2000 - reads SELECTOR offset $600, $160 bytes to $0290
                     - reads SELECTOR offset $760, $6000 bytes to $4000
                     - reads SELECTOR offset $6760, $800 bytes to $3400
                     - copies $3400-$3BFF to LC1 $D000-$D7FF
                     - jumps to $8E00

0600x$160

0760x$6000 org $4000 - MGTK ($4000), Font ($8800), ...

6760x$800 org $D000  - resources

6F60 ...             - ???????? overlays?





dd skip=$((0x0000)) count=$((0x0027)) bs=1 if=orig/SELECTOR.\$F1 of=orig/selector1
dd skip=$((0x0027)) count=$((0x0200)) bs=1 if=orig/SELECTOR.\$F1 of=orig/selector2
dd skip=$((0x0227)) count=$((0x03D9)) bs=1 if=orig/SELECTOR.\$F1 of=orig/selector3 # ???
dd skip=$((0x0600)) count=$((0x0160)) bs=1 if=orig/SELECTOR.\$F1 of=orig/selector4
dd skip=$((0x0760)) count=$((0x6000)) bs=1 if=orig/SELECTOR.\$F1 of=orig/selector5
dd skip=$((0x6760)) count=$((0x0800)) bs=1 if=orig/SELECTOR.\$F1 of=orig/selector6
dd skip=$((0x6F60)) count=$((0xFFFF)) bs=1 if=orig/SELECTOR.\$F1 of=orig/selector7


../res/make_info.pl 2000 > selector.info && da65 -i selector.info orig/selector1 | ../res/refactor.pl > selector1.s
../res/make_info.pl 1000 > selector.info && da65 -i selector.info orig/selector2 | ../res/refactor.pl > selector2.s
../res/make_info.pl 1E27 > selector.info && da65 -i selector.info orig/selector3 | ../res/refactor.pl > selector3.s
../res/make_info.pl 0290 > selector.info && da65 -i selector.info orig/selector4 | ../res/refactor.pl > selector4.s
../res/make_info.pl 4000 > selector.info && da65 -i selector.info orig/selector5 | ../res/refactor.pl > selector5.s
../res/make_info.pl D000 > selector.info && da65 -i selector.info orig/selector6 | ../res/refactor.pl > selector6.s


## Memory Map

```
       Main                  Aux                    ROM
$FFFF +-------------+       +-------------+       +-------------+
      | ProDOS      |       |             |       | Monitor     |
$F800 |             |       |             |       +-------------+
      |             |       |  (Unused?)  |       | Applesoft   |
      |             |Bank2  |             |Bank2  |             |
$E000 |      +-----------+  |      +-----------+  |             |
      |      | ProDOS    |  | Res  | (Unused?) |  |             |
$D000 +------+-----------+  +------+-----------+  +-------------+
                                                  | I/O         |
                                                  |             |
$C000 +-------------+       +-------------+       +-------------+
      | ProDOS GP   |       |             |
$BF00 +-------------+       |             |
      |             |       |             |
      |             |       |             |
      |  (Unused?)  |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
$A000 +-------------+       |             |
      | Selector    |       |             |
      | App Code    |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
$8E00 +-------------+       |             |
      |             |       |             |
      | Resources?  |       |             |
      |             |       |  (Unused?)  |
      |             |       |             |
      |    ???      |       |             |
      |             |       |             |
      |             |       |             |
$8800 | Font?       |       |             |
      |             |       |             |
$8580 +-------------+       |             |
      | MGTK        |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
$4000 +-------------+       +-------------+
      | Graphics    |       | Graphics    |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
$2000 +-------------+       +-------------+
      | I/O Buffer  |       |             |
$1C00 +-------------+       |  (Unused?)  |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
$0800 +-------------+       +-------------+
      | Drawing     |       |             |
      | Temp Buffer |       |             |
$0400 +-------------+       +-------------+
      | ???         |       |             |
$0300 +-------------+       +-------------+
      | Input Buf   |       | Input Buf   |
$0200 +-------------+       +-------------+
      | Stack       |       | Stack       |
$0100 +-------------+       +-------------+
      | Zero Page   |       | Zero Page   |
$0000 +-------------+       +-------------+
```

To Identify:
* Save Area
