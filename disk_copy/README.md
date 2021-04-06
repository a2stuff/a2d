
# Disk Copy diassembly notes

Disk Copy is built as part of DeskTop (see `../desktop/desktop.s`) and
relies on DeskTop for loading/invoking MGTK and the initial Disk Copy
load. Once running, it takes over all memory and functions as a
separate application.

| Purpose       | Bank    | Address | Sources          |
|---------------|---------|---------|------------------|
| MGTK          | Aux     | A$4000  | `mgtk.s`         |
| Disk Copy 1/4 | Main    | A$0800  | `disk_copy1.s`   |
| Disk Copy 2/4 | Main    | A$1800  | `disk_copy2.s`   |
| Disk Copy 3/4 | Aux LC1 | A$D000  | `disk_copy3.s`   |
| Disk Copy 4/4 | Main    | A$0800  | `disk_copy4.s`   |

Lengths/offsets are defined in `../desktop/internal.inc`.

## Structure

The Disk Copy command in DeskTop loads several overlays, which
effectively become a new application.

The first part (`disk_copy1.s`, $800-$9FF) loads into main memory
like the other DeskTop overlays, but in turn it loads a second short
($200-byte) overlay (`disk_copy2.s`, $1800-$19FF). This then loads
app code and a replacement for the resources in the aux language card area
(`disk_copy3.s`, Aux LC $D000-$F1FF) and another block of code in
main memory (`disk_copy4.s`, Main $0800-$12FF). When exiting, the
DeskTop is restarted from the beginning.


## Memory Map

```
       Main                  Aux                    ROM
$FFFF +-------------+       +-------------+       +-------------+
      |.ProDOS......|       |#############|       |.Monitor.....|
$F800 |.............|       |#############|       +-------------+
$F200 |.............|       +-------------+       |.Applesoft...|
      |.............|Bank2  | App Logic   |Bank2  |.............|
$E000 |......+-----------+  | &    +-----------+  |.............|
      |......|.ProDOS....|  | Rsrc |###########|  |.............|
$D000 +------+-----------+  +------+-----------+  +-------------+
                                                  |.I/O.........|
                                                  |.............|
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
      | Scratch     |       |#############|
$1300 +-------------+       |#############|
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
`disk_copy4.s`.

In Quick Copy mode, the volume's bitmap is loaded at $4000 upwards
(and then marked as used in the memory bitmap) and used to track which
blocks to copy. In Disk Copy mode, a synthetic bitmap is used instead
(to copy all blocks).
