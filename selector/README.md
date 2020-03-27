
The file is broken down into multiple segments:

| Purpose       | File Offset | Bank   | Address      | Length | Source                    |
|---------------|-------------|--------|--------------|--------|---------------------------|
| Bootstrap     | B$00000000  | Main   | $A2000-$2026 | L$0027 | `selector1.s`             |
| Loader        |             | Main   | $A1000       |        | `selector2.s`             |
|               |             | Main   |              |        | `selector3.s`             |
| Invoker       |             | Main   | $A0290       | L$0160 | `selector4.s`             |
| MGTK + App    |             |        | $A4000-$9FFF | L$6000 | `selector5.s`             |
| Resources     |             | Aux LC | $AD000-$D800 | L$0800 | `selector6.s`             |
| Overlay 1     |             | Main   | $AA000-$BEFF | L$1F00 | `selector7.s`             |
| Overlay 2     |             | Main   | $AA000-      | L$0D00 | `selector8.s`             |

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

0600x$160  org $290 - Invoker code

0760x$6000 org $4000 - MGTK ($4000), Font ($8800), ...

6760x$800 org $D000  - resources

6F60x$1F00 org $A000 - overlay1

8E60x$D00 org $A000 - overlay2

9B60 == EOF

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
      | Selector    |       |             |
      | Overlays    |       |             |
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
