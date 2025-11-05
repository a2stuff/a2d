# Disk Copy

Disk Copy relies on DeskTop for loading/invoking MGTK and the default
font. Once running, it takes over all memory and functions as a
separate application.

It was originally built as part of the monolithic DeskTop binary but
has been pulled out into a separate file to simplify building and
maintenance, and potentially running on lower capacity devices.

| Purpose                 | Bank    | Address | Source     |
|-------------------------|---------|---------|------------|
| Loader                  | Main    | A$1800  | `loader.s` |
| App Logic and Resources | Aux LC1 | A$D000  | `auxlc.s`  |
| Disk Copy Logic         | Main    | A$0800  | `main.s`   |

Lengths/offsets are defined in `disk_copy.s`. Segments are padded in
the file to ensure they appear at block boundaries, enabling faster
loading.

## Structure

DeskTop's `CmdDiskCopy` loads Disk Copy's $200-byte loader into main
memory (`loader.s` at $1800), does sometidying, then hands over
control. This then loads app code and a replacement for the resources
in the aux language card area (`auxlc.s` at $D000) and
another block of code in main memory (`main.s` at $0800).
When exiting, the DeskTop is restarted from the beginning.

## Memory Map

```
       Main                  Aux                    ROM
$FFFF +-------------+       +-------------+       +-------------+
      |.ProDOS......|       |#############|       |.Monitor.....|
$F800 |.............|       |#############|       +-------------+
$F000 |.............|       +-------------+       |.Applesoft...|
      |.............|Bank2  | App Logic   |Bank2  |.............|
$E000 |......+-----------+  | &    +-----------+  |.............|
      |......|.ProDOS..*.|  | Rsrc |###########|  |.............|
$D000 +------+-----------+  +------+-----------+  +-------------+
        * = BELLDATA/SETTINGS                     |.I/O.&.......|
                                                  |.Firmware....|
$C000 +-------------+       +-------------+       +-------------+
      |.ProDOS.GP...|       |#############|
$BF00 +-------------+       |#############|
      |#############|       |#############|
      |#############|       |#############|
      |#############|       |#############|
      |#############|       |#############|
      |#############|       |#############|
      |#############|       |#############|
      |#############|       |#############|
$9000 |#############|       +-------------+
      |#############|       |             |
      |#############|       | Font        |      # = Copy Buffer
$8800 |#############|       +-------------+
      |#############|       |             |
      |#############|       |             |
      |#############|       |             |
      |#############|       |             |
      |# # # # # # #        |             |
      | # # # # # # |       |             |
      |             |       |             |
      |Volume Bitmap|       | MGTK        |
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
      | I/O Buffer  |       |#############|
$1C00 +-------------+       |#############|
      |#############|       |#############|
      |#############|       |#############|
$1400 +-------------+       |#############|
      |             |       |#############|
      |             |       |#############|
      |             |       |#############|
      | I/O Code    |       |#############|
$0800 +-------------+       +-------------+
      | Drawing     |       | Drawing     |
      | Temp Buffer |       | Temp Buffer |
$0400 +-------------+       +-------------+
      |             |       |.ProDOS......|
$0300 +-------------+       |./RAM.driver.|
      | Input Buf   |       |.............|
$0200 +-------------+       +-------------+
      |.Stack.......|       |.Stack.......|
$0100 +-------------+       +-------------+
      | Zero Page   |       | Zero Page   |
$0000 +-------------+       +-------------+
```

All free memory is used for buffer space during copies. A detailed
memory bitmap is maintained with available/reserved page-pairs marked
for main, aux, and aux-lcbank2 addresses. See `memory_bitmap` in
`main.s`.

In Quick Copy mode, the volume's bitmap is loaded at $4000 upwards
(and then marked as used in the memory bitmap) and used to track which
blocks to copy. In Disk Copy mode, a synthetic bitmap is used instead
(to copy all blocks).
