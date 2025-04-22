# Selector

The Selector is an optional app that can be configured with shortcuts to launch other programs, without starting the full DeskTop.

## File Structure

The file is broken down into multiple segments:

| Purpose      | Bank    | Address | Source               |
|--------------|---------|---------|----------------------|
| Bootstrap    | Main    | $2000   | `../lib/bootstrap.s` |
| Loader       | Main    | $2000   | `loader.s`           |
| Invoker      | Main    | $0290   | `../lib/invoker.s`   |
| App          | Main    | $4000   | `app.s`              |
| Alert Dialog | Aux LC1 | $D000   | `alert_dialog.s`     |
| File Dialog  | Main    | $A500   | `ovl_file_dialog.s`  |
| Copy Dialog  | Main    | $A500   | `ovl_file_copy.s`    |

See `selector.s` for the specific values. Segments are padded in the
file to ensure they appear at block boundaries, enabling faster
loading.

## Segments

### Bootstrap - `../lib/bootstrap.s`

The first $200 bytes are loaded at $2000 by `DESKTOP.SYSTEM`.

Copies the Quit Handler to the ProDOS quit handler, then invokes QUIT.

The Quit Handler is invoked via ProDOS QUIT, so relocated/executed at $1000.

Loads and invokes the Loader.

### Loader - `loader.s`

Loads the Invoker (page 2/3), MGTK and App (above graphics pages), and
Resources (Aux LC), then invokes the app.

### Invoker - `../lib/invoker.s`

Responsible for loading and invoking the selected app.
Handles BIN, BAS, SYS and S16 files, and selects
appropriate IO buffer location based on load address.

### Selector App - `app.s`

* A copy of MGTK resides at $4000.
* The font comes next.
* The application resources, entry point, and code follows.

### Alert Dialog - `alert_dialog.s`

Shows a modal alert dialog. Loaded to Aux LC1

### File Dialog Overlay - `ovl_file_dialog.s`

The File > Run a Program... implementation. Loaded after the app

Shows a file picker, and allow selecting an arbitrary program
to run.

### File Copy Overlay - `ovl_file_copy.s`

Recursive copy implementation. Loaded to $A600.

Used when invoking a program via the selector with the option
"Copy to RAMCard" / "On first use" specified.


## Memory Map

```
       Main                  Aux                    ROM
$FFFF +-------------+       +-------------+       +-------------+
      |.ProDOS......|       |             |       |.Monitor.....|
$F800 |.............|       |             |       +-------------+
      |.............|       |   Unused    |       |.Applesoft...|
      |.............|Bank2  |             |Bank2  |.............|
$E000 |......+-----------+  |       +----------+  |.............|
      |......|.ProDOS..*.|  | Alert |  Unused  |  |.............|
$D000 +------+-----------+  +-------+----------+  +-------------+
        * = BELLDATA/SETTINGS                     |.I/O.&.......|
                                                  |.Firmware....|
$C000 +-------------+       +-------------+       +-------------+
      |.ProDOS.GP...|       |             |
$BF00 +-------------+       |             |
      | Sel.List    |       |             |
$B300 + - - - - - - +       |             |
      | Selector    |       |             |
      | Overlays    |       |             |
      |             |       |             |
      |             |       |             |
$AA00 +-------------+       |             |
      | Selector    |       |             |
      |             |       |             |
      | App Code    |       |             |
      |             |       |             |
      | Resources   |       |             |
      |             |       |   Unused    |
      | Font        |       |             |
      |             |       |             |
      | MGTK        |       |             |
$4000 +-------------+       +-------------+
      |.Graphics....|       |.Graphics....|
      |.............|       |.............|
      |.............|       |.............|
      |.............|       |.............|
      |.............|       |.............|
      |.............|       |.............|
      |.............|       |.............|
      |.............|       |.............|
$2000 +-------------+       +-------------+
      | I/O Buffer  |       | Backup of   |
$1C00 +-------------+       | File Dialog |
      | Save Area   |       | state, when |
      |             |       | an alert is |
      |             |       | shown       |
      |             |       |             |
$0800 +-------------+       +-------------+
      | Drawing     |       | Drawing     |
      | Temp Buffer |       | Temp Buffer |
$0400 +-------------+       +-------------+
      | Invoker     |       |.ProDOS......|
$0300 +-------------+       |./RAM.driver.|
      | Input Buf   |       |.............|
$0200 +-------------+       +-------------+
      |.Stack.......|       |.Stack.......|
$0100 +-------------+       +-------------+
      | Zero Page   |       | Zero Page   |
$0000 +-------------+       +-------------+
```
