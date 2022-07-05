# `DESKTOP.FILE` File Format

DeskTop writes out this file on exit, and reads it back in on load.

The file length is always 586 bytes, although the end of the file
may be padding/garbage.

## Header

Header is one byte.

+000: FileVersion (byte)

   This is compared against `kDeskTopFileVersion` on load. If
   different, the file is ignored. (This is used to handle version
   skew.)

## Windows

Offset +001. There are a variable number of entries (0-8). Windows are
listed bottom-most to top-most for ease of opening.

Each window entry has this structure:

+000: PathLength (byte)
+001: PathName (64 bytes)

   This is the ProDOS path of the window. The path length is always
   greater than zero.

+065: Bounds (8 bytes)

   This is a rect (4 words) defining the window bounds.

## Sentinel

The final window entry is followed by a sentinel byte ($00).
