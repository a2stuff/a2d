
# Disk Copy diassembly notes



This is large - 111k. It includes a loader and the DeskTop app with
both main memory and aux memory segments, filling everything from
$4000 to $FFFF (except for I/O space and ProDOS), and still having
more code segments swapped in dynamically.

The file is broken down into multiple segments:

| Purpose       | Bank    | Address | Sources                        |
|---------------|---------|---------|--------------------------------|
| MGTK          | Aux     | A$4000  | `mgtk.s`                       |
| Disk Copy 1/4 | Main    | A$0800  | `ovl_disk_copy1.s`             |
| Disk Copy 2/4 | Main    | A$1800  | `ovl_disk_copy2.s`             |
| Disk Copy 3/4 | Aux LC1 | A$D000  | `ovl_disk_copy3.s`             |
| Disk Copy 4/4 | Main    | A$0800  | `ovl_disk_copy4.s`             |

Lengths/offsets are defined in `internal.inc`.

A monolithic source file `desktop.s` is used to assemble the entire
target. It includes other source files for each of the various
segments.

## Structure

The Disk Copy command in DeskTop loads several overlays, which
effectively become a new application.

The first part (`ovl_disk_copy1.s`, $800-$9FF) loads into main memory
like the other DeskTop overlays, but in turn it loads a second short
($200-byte) overlay (`ovl_disk_copy2.s`, $1800-$19FF). This then loads
a replacement for the resources in the aux language card area
(`ovl_disk_copy3.s`, Aux LC $D000-$F1FF) and another block of code in
main memory (`ovl_disk_copy4.s`, Main $0800-$12FF). When exiting, the
DeskTop is restarted from the beginning.


## Memory Map

```
       Main                  Aux                    ROM
$FFFF +-------------+       +-------------+       +-------------+
      |.ProDOS......|       | Copy Buffer |       |.Monitor.....|
$F800 |.............|       | #4          |       +-------------+
$F200 |.............|       +-------------+       |.Applesoft...|
      |.............|Bank2  | App Logic   |Bank2  |.............|
$E000 |......+-----------+  | &    +-----------+  |.............|
      |......|.ProDOS....|  | Rsrc | CpyBuf #5 |  |.............|
$D000 +------+-----------+  +------+-----------+  +-------------+
                                                  |.I/O.........|
                                                  |.............|
$C000 +-------------+       +-------------+       +-------------+
      |.ProDOS.GP...|       |             |
$BF00 +-------------+       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       | Copy Buffer |
      |             |       | #3          |
$9000 |             |       +-------------+
      |             |       |             |
      |             |       | Font        |
$8800 |             |       +-------------+
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      |             |       |             |
      | Copy Buffer |       |             |
      | #1          |       | MGTK        |
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
      | I/O Buffer  |       |             |
$1C00 +-------------+       |             |
      | Volume      |       |             |
      | Bitmap      |       |             |
$1400 +-------------+       |             |
      | ???         |       |             |
$1300 +-------------+       |             |
      |             |       |             |
      |             |       | Copy Buffer |
      | I/O Code    |       | #2          |
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
