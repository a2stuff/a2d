# Selector

The Selector is an optional app that can be configured with shortcuts to launch other programs, without starting the full DeskTop.

## File Structure


The file is broken down into multiple segments:

| Purpose      | File Offset | Bank    | Address     | Length | Source              |
|--------------|-------------|---------|-------------|--------|---------------------|
| Bootstrap    | B$000000    | Main    | $2000-$2026 | L$0027 | `bootstrap.s`       |
| Quit Handler | B$000027    | Main    | $1000-$11FF | L$0200 | `quit_handler.s`    |
| Loader       | B$000300    | Main    | $2000-$22FF | L$0300 | `loader.s`          |
| Invoker      | B$000600    | Main    | $0290-$03EF | L$0160 | `../lib/invoker.s`  |
| MGTK + App   | B$000760    | Main    | $4000-$A1FF | L$6200 | `mgtk.s`, `app.s`   |
| Alert Dialog | B$006960    | Aux LC1 | $D000-$D7FF | L$0800 | `alert_dialog.s`    |
| Overlay 1    | B$007160    | Main    | $A400-$BEFF | L$1D00 | `ovl_file_dialog.s` |
| Overlay 2    | B$008E60    | Main    | $A400-$AEFF | L$0D00 | `ovl_file_copy.s`   |

## Segments

### Bootstrap - `bootstrap.s`

Short routine loaded at $2000.

Copies the next segment (Quit Handler) to the ProDOS quit handler, then invokes QUIT.

### Quit Handler - `quit_handler.s`

Invoked via ProDOS QUIT, so relocated/executed at $1000.

Loads the Loader - reads SELECTOR $600 bytes at $1D00, and jumps to $2000

(Note that the first chunk of bytes that end up at $1D00 are not used
as that is the Bootstrap and the Quit Handler code; this is followed by
padding. Just avoids a SET_MARK call.)

### Loader - `loader.s`

Loads the Invoker (page 2/3), MGTK and App (above graphics pages), and
Resources (Aux LC), then invokes the app.

### Invoker - `../lib/invoker.s`

Responsible for loading and invoking the selected app.
Handles BIN, BAS, SYS and S16 files, and selects
appropriate IO buffer location based on load address.

### MGTK and Selector App - `app.s`

* A copy of MGTK resides at $4000.
* The font is at $8600.
* The application entry point is $8E00.

### Alert Dialog - `alert_dialog.s`

Shows a modal alert dialog. Loaded to Aux LC1

### Overlay 1 - `ovl_file_dialog.s`

The File > Run a Program... implementation. Loaded to $A400.

Shows a file picker, and allow selecting an arbitrary program
to run.

### Overlay 2 - `ovl_file_copy.s`

Recursive copy implementation. Loaded to $A400.

Used when invoking a program via the selector with the option
"Copy to RAMCard" / "On first use" specified.


## Memory Map

```
       Main                  Aux                    ROM
$FFFF +-------------+       +-------------+       +-------------+
      | ProDOS      |       |             |       | Monitor     |
$F800 |             |       |             |       +-------------+
      |             |       |   Unused    |       | Applesoft   |
      |             |Bank2  |             |Bank2  |             |
$E000 |      +-----------+  |       +----------+  |             |
      |      | ProDOS    |  | Alert |  Unused  |  |             |
$D000 +------+-----------+  +-------+----------+  +-------------+
                                                  | I/O         |
                                                  |             |
$C000 +-------------+       +-------------+       +-------------+
      | ProDOS GP   |       |             |
$BF00 +-------------+       |             |
      | Sel.List    |       |             |
$B300 + - - - - - - +       |             |
      | Selector    |       |             |
      | Overlays    |       |             |
      |             |       |             |
      |             |       |             |
$A400 +-------------+       |             |
      | Settings    |       |             |
$A300 +-------------+       |             |
      | Selector    |       |             |
      | App Code    |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
$8E00 +-------------+       |             |
      | Resources   |       |             |
      |             |       |   Unused    |
      |             |       |             |
      | Font        |       |             |
$8600 +-------------+       |             |
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
$1C00 +-------------+       |   Unused    |
      | Save Area   |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
$0800 +-------------+       +-------------+
      | Drawing     |       |             |
      | Temp Buffer |       |             |
$0400 +-------------+       +-------------+
      | Invoker     |       |             |
$0300 +-------------+       +-------------+
      | Input Buf   |       | Input Buf   |
$0200 +-------------+       +-------------+
      | Stack       |       | Stack       |
$0100 +-------------+       +-------------+
      | Zero Page   |       | Zero Page   |
$0000 +-------------+       +-------------+
```
