# `DESKTOP.FILE` File Format

DeskTop writes out this file on exit, and reads it back in on load.

The file length is always 626 bytes, although the end of the file
may be padding/garbage.

## Header

Header is one byte.

|  Offset  |  Length    | Description      |
|---------:|:----------:|:-----------------|
|  +$0000  |  byte (1)  | FileVersion      |

* **FileVersion**

   This is compared against `kDeskTopFileVersion` on load. If
   different, the file is ignored. (This is used to handle version
   skew.)

   The current version documented here is $82.

## Windows

File offset +$0001. There are a variable number of entries (0-8). Windows are
listed bottom-most to top-most for ease of opening.

Each window entry has this structure:

|  Offset  |  Length    | Description      |
|---------:|:----------:|:-----------------|
|  +$0000  |  byte (1)  | PathLength       |
|  +$0001  |  $40       | PathName         |
|  +$0041  |  byte (1)  | ViewType         |
|  +$0042  |  word (2)  | Position x-coord |
|  +$0044  |  word (2)  | Position y-coord |
|  +$0046  |  word (2)  | Viewport left    |
|  +$0048  |  word (2)  | Viewport top     |
|  +$004A  |  word (2)  | Viewport right   |
|  +$004C  |  word (2)  | Viewport bottom  |

* **PathLength** and **PathName**

   This is the ProDOS path of the window. The path length is always
   greater than zero.

* **ViewType**

   This defines the view style of the window:

   | Value | View Style     |
   |------:|:---------------|
   | $00   | Icons          |
   | $01   | Small Icons    |
   | $81   | By Name        |
   | $82   | By Date        |
   | $83   | By Size        |
   | $84   | By Type        |

* **Position**

   This is a point (2 words) defining the window position. This
   corresponds to the Winfo::GrafPort::viewloc member.

* **Viewport**

   This is a rect (4 words) defining the window viewport. This
   corresponds to the Winfo::GrafPort::maprect member.

## Sentinel

The final window entry is followed by a sentinel byte ($00).
