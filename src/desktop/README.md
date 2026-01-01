# DeskTop

This is the main application, presenting a desktop and windows with
icons for volumes and files, commands and gestures for moving and
copying files and manipulating disks.

The program file (`DESKTOP`) is large - 89k. It includes a loader and
the DeskTop app with both main memory and aux memory segments, filling
everything from $4000 to $FFFF (except for I/O space and ProDOS), and
still having more code segments swapped in dynamically.

## File Structure

The file is broken down into multiple segments:

| Purpose            | Bank    | Address | Sources               |
|--------------------|---------|---------|-----------------------|
| Bootstrap          | Main    | $2000   | `../lib/bootstrap.s`  |
| Loader             | Main    | A$2000  | `loader.s`            |
| Toolkits+Resources | Aux     | A$4000  | `auxmem.s`            |
| Relays+Resources   | Aux LC1 | A$D000  | `lc.s`,`res.s`        |
| Application Logic  | Main    | A$4000  | `main.s`              |
| Initializer        | Main    | A$0800  | `init.s`              |
| Invoker            | Main    | A$0290  | `../lib/invoker.s`    |
| Format/Erase       | Main    | A$0800  | `ovl_format_erase.s`  |
| Pick Shortcut      | Main    | A$5000  | `ovl_selector_pick.s` |
| File Dialog        | Main    | A$6000  | `ovl_file_dialog.s`   |
| File Copy          | Main    | A$7000  | `ovl_file_copy.s`     |
| Edit Shortcut      | Main    | A$7000  | `ovl_selector_edit.s` |

Lengths/offsets are defined in `desktop.s`. Segments are padded in the
file to ensure they appear at block boundaries, enabling faster
loading.

The DeskTop segments loaded into the Aux bank switched ("language
card") memory can be used from both main and aux, so contain relay
routines, resources, and buffers. More details below.

A monolithic source file `desktop.s` is used to assemble the entire
target. It includes other source files for each of the various
segments.

Note that Disk Copy (see `../disk_copy/`) used to be built into the
DeskTop binary as well, but has been pulled out.

## Segments and Overlays

### Bootstrap

`../lib/bootstrap.s`

The first $200 bytes are loaded at $2000 by `DESKTOP.SYSTEM`.

Invoked at $2000; patches the ProDOS QUIT routine (at LC2 $D100) then
invokes it. That gets copied to $1000-$11FF and run by ProDOS. This
stays resident so quitting from subsequent programs will re-run it.

The quit handler stashes the current prefix and re-patches ProDOS with
itself. It then loads in Loader segment of DeskTop and invokes it.

### Loader

`loader.s`

This code then loads the rest of the file as a sequence of segments,
moving them to the appropriate destination in aux/banked/main memory.

### Invoker

`../lib/invoker.s`

Loaded at $290-$03EF, this small routine is used to invoke a target,
e.g. a double-clicked file. System files are loaded/run at $2000,
binary files at the location specified by their aux type, and BASIC
files loaded by searching for BASIC.SYSTEM and running it with the
pathname passed at $2006 (see ProDOS TLM). Other file types are
invoked using BASIS.SYSTEM, if present.

### Initializer

(in `init.s`)

Loaded at $800, this does one-time initialization of the
DeskTop. It is later overwritten when any desk accessories are
run.

### "DeskTop" Application

The main application includes:
* `main.s`
* `auxmem.s`
* `lc.s`
* `res.s`

DeskTop code is in the lower 48k of both Main and Aux banks, and the
Aux language card areas. The main application logic is in Main, with
Aux and LC memory used for Mouse/Graphics, Icon, Button, LineEdit, and
Alert toolkits and resources.

When running, memory use includes:

* Main
 * $800-$1BFF is used as scratch space for a variety of routines.
   * Desk Accessories load into this space.
 * $1C00-$1FFF is used as a 1k ProDOS I/O buffer.
 * $2000-$3FFF is the hires graphics page.
 * $4000-$BEFF (`main.s`) is the main app logic.

($C000-$CFFF is reserved for I/O, and main $BF page and language card is ProDOS)

* Aux
 * $E00-$1FFF is a "save area"; used by MGTK to store the background
     when menus are drawn so it can be restored without redrawing. The
     save area is also used by DeskTop to save the background for
     alert dialogs, and icon outlines when dragging - basically, any
     modal operation.
   * Desk Accessories can use this space.
 * $2000-$3FFF is the hires graphics page.
 * $4000-$BFFF (`auxmem.s`) includes these:
   * [MouseGraphics ToolKit](../mgtk/MGTK.md)
   * Resources, including icons, font, menu definitions, etc.
   * [Icon ToolKit](APIs.md)
   * [LineEdit ToolKit](../toolkits/LETK.md)
   * [Button ToolKit](../toolkits/BTK.md)
   * [ListBox ToolKit](../toolkits/LBTK.md)
   * [Option Picker ToolKit](../toolkits/OPTK.md)
   * Alert dialog resources/code

...and in the Aux language card area (accessible from both aux and
main code) are relays, buffers and resources:

* Aux LC
 * $D000-$FFFF
   * main-to-aux relay calls (`lc.s`)
   * resources (menus, strings, window) (`res.s`)
   * buffer for IconEntries

The Aux memory language card bank 2 ($D000-$DFFF) holds `FileRecord`
entries, 32-byte structures which hold metadata for files in open
windows. This duplicates some info in the `IconEntry` tables (e.g.
name) but is used for operations such as alternate view types.

### Overlays

`ovl_*.s`

Interactive commands including disk format/erase, file
copy/delete, and Shortcuts add/edit/delete/run all dynamically load
main memory code overlays. When complete, any original code above
$4000 is reloaded (unless a full restart is required.)

Several of the overlays also use a common file selector dialog overlay
`ovl_file_dialog.s` ($6000-$6FFF).

#### Disk Format/Disk Erase

Simple overlay: `ovl_format_erase.s`, loaded into Main A$0800-$1BFF.
This re-uses much of DeskTop's dialog framework for prompts and progress.

#### Shortcuts - Delete Entry / Run Entry

Simple overlay: `ovl_selector_pick.s` ($5000-$5FFF).

#### Shortcuts - Add Entry / Edit Entry

Also uses `ovl_selector_pick.s` ($5000-$5FFF) but additionally uses overlay
`ovl_selector_edit.s` ($7000-$77FF) and the file selector dialog `ovl_file_dialog.s`
($6000-$6FFF).

#### File Copy

Overlay `ovl_file_copy.s` ($7000-$77FF), uses file selector dialog `ovl_file_dialog.s`
($6000-$6FFF).

## Memory Map

```
       Main                  Aux                    ROM
$FFFF +-------------+       +-------------+       +-------------+
      |.ProDOS......|       | DeskTop     |       |.Monitor.....|
$F800 |.............|       | Resources/  |       +-------------+
      |.............|       | Buffers     |       |.Applesoft...|
      |.............|Bank2  |             |Bank2  |.............|
$E000 |......+-----------+  |      +-----------+  |.............|
      |......|.ProDOS..*.|  |      | FileRecs  |  |.............|
$D000 +------+-----------+  +------+-----------+  +-------------+
        * = BELLDATA/SETTINGS                     |.I/O.&.......|
                                                  |.Firmware....|
$C000 +-------------+       +-------------+       +-------------+
      |.ProDOS.GP...|       | DeskTop     |
$BF00 +-------------+       | Utilities & |
      | Copy Buffer |       | Resources   |
      |             |       |             |
      |             |       | * ToolKits  |
$__00 +-------------+       | * Alerts    |
      | DeskTop     |       |             |
      | Application |       |             |
      | Code        |       |             |
      |             |       |             |
      |             |       |             |
      |             |       | Font        |
$8800 |             |       +-------------+
      |             |       | MGTK        |
      |             |       |             |
      |             |       |             |
      |             |       |             |
$7800 |      +------+       |             |
      |      | Ovl  |       |             |
$7000 |      +------+       |             |
      |      | Ovl  |       |             |
      |      |      |       |             |
$6000 |      +------+       |             |
      |      | Ovl  |       |             |
      |      |      |       |             |
$5000 |      +------+       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
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
      | Initializer |       | Desk Acc &  |
      | & Desk Acc  |       | Save Area   |
      | & Overlays  |       |             |
      | & I/O       |       |             |
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

Memory use by the Disk Copy overlay is not shown. See
[the Disk Copy README](../disk_copy/README.md).
