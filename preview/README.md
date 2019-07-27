# Preview

These files are a special class of Desk Accessory which reside in
the `PREVIEW` subdirectory relative to `DESKTOP2` (next to `DESK.ACC`).
These DAs will be invoked automatically for certain file types when
File > Open is run or the files are double-clicked.

* [show.text.file](show.text.file.s)
   * Handles text files (TXT $04)
* [show.image.file](show.image.file.s)
   * Handles image files (FOT $08)
   * 8k Hires or 16k Double Hires images are supported
* [show.font.file](show.font.file.s)
   * Handles MGTK font files (FNT $07)

The files can optionally be copied into the `DESK.ACC` directory to
allow direct invocation from the Apple menu. This can be useful to
preview files of different file types e.g. image files saved as BIN
$06.

See [API.md](../desk.acc/API.md) for programming details.

See the DA [README.md](../desk.acc/README.md) for build and installation
details.

NOTE: ProDOS file type FNT $07 is reserved for Apple /// SOS font
files, but given their scarcity the type is re-used here.
