
The file is broken down into multiple segments:

| Purpose      | File Offset | Bank   | Address      | Length | Source        |
|--------------|-------------|--------|--------------|--------|---------------|
| Bootstrap    | B$00000000  | Main   | $A2000-$2026 | L$0027 | `selector1.s` |
| Quit Handler | B$00000027  | Main   | $A1000-$11FF | L$0200 | `selector2.s` |
| Loader       | B$00000400  | Main   | $A2000-$21FF | L$0200 | `selector3.s` |
| Invoker      | B$00000600  | Main   | $A0290-$03EF | L$0160 | `selector4.s` |
| MGTK + App   | B$00000760  |        | $A4000-$9FFF | L$6000 | `selector5.s` |
| Resources    | B$00006760  | Aux LC | $AD000-$D7FF | L$0800 | `selector6.s` |
| Overlay 1    | B$00006F60  | Main   | $AA000-$BEFF | L$1F00 | `selector7.s` |
| Overlay 2    | B$00008E60  | Main   | $AA000-$ACFF | L$0D00 | `selector8.s` |

## Segments

### Bootstrap - `selector1.s`

Short routine loaded at $2000.

Copies the next segment (Quit Handler) to the ProDOS quit handler, then invokes QUIT.

### Quit Handler - `selector2.s`

Invoked via ProDOS QUIT, so relocated/executed at $1000.

Loads the Loader - reads SELECTOR $600 bytes at $1C00, and jumps to $2000

(Note that the first chunk of bytes that end up at $1C00 are not used
as that is the Bootstrap and the Quit Handler code; this is followed by
padding.)

### Loader - `selector3.s`

Loads the Invoker (page 2/3), MGTK and App (above graphics pages), and
Resources (Aux LC), then invokes the app.

### Invoker - `selector4.s`

Responsible for loading and invoking the selected app. Very similar to
the code in DeskTop. Handles BIN, BAS, SYS and S16 files, and selects
appropriate IO buffer location based on load address.

### MGTK and Selector App - `selector5.s`

* A copy of MGTK resides at $4000.
* The font is at $8800.
* The application entry point is $8E00.

The MGTK copy runs out of Main (rather than Aux) and is version
1.0.0 Beta 4, slightly older than the 1.0.0 Final 1 used in DeskTop.
Some command numbers are different.

### Resources - `selector6.s`

A handful of resources for MGTK and routines. Loaded to Aux LC1

### Overlay 1 - `selector7.s`

TBD. Loaded to $A000.

### Overlay 2 - `selector8.s`

TBD. Loaded to $A000.


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
