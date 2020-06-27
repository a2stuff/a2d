# Desk Accessories

Disassembly of the original desk accessories:

* [Calculator](calculator.s) - complete!
* [Date](date.s) - complete!
* [Puzzle](puzzle.s) - complete!
* [Sort Directory](sort.directory.s) - complete!
* [Show Text File](show.text.file.s) - complete!

New desk accessories:

* [This Apple](this.apple.s)
  * Gives details about the computer, expanded memory, and what's in each slot.
* [Control Panel](control.panel.s)
  * Modify DeskTop settings: desktop pattern, double-click speed, insertion point blink speed. Also shows joystick calibration.
* [System Speed](system.speed.s)
  * Enable/disable system accelerator.
* [Eyes](eyes.s)
  * Eyes that follow the mouse.
* [Screen Dump](screen.dump.s)
  * Dumps a screenshot to an ImageWriter II attached to a Super Serial Card in Slot 1.
* [Key Caps](key.caps.s)
  * Shows an on-screen keyboard map, and indicates which key is pressed.
* [Run Basic Here](run.basic.here.s)
  * Launches BASIC.SYSTEM with PREFIX set to current window's directory.
* [Flying Toasters](flying.toaster.s)
  * Visual distractions.
* [Melt](melt.s)
  * Visual distractions.

Note that the new desk accessories require an updated version of Apple II DeskTop and **will not work** with DeskTop 1.1 or MouseDesk.

See [API.md](API.md) for programming details

# Preview Accessories

These files are a special class of Desk Accessory which reside in
the `PREVIEW` subdirectory relative to `DESKTOP2` (next to `DESK.ACC`).
These DAs will be invoked automatically for certain file types when
File > Open is run or the files are double-clicked.

* [Show Text File](show.text.file.s)
   * Handles text files (TXT $04)
* [Show Image File](show.image.file.s)
   * Handles image files (FOT $08 and some BIN $06)
   * Supports Hires and Double Hires images, including compressed images
   * Supports MiniPix/PrintShop clip-art
* [Show Font File](show.font.file.s)
   * Handles MGTK font files (FNT $07)

The files can optionally be copied into the `DESK.ACC` directory to
allow direct invocation from the Apple menu. This can be useful to
preview files of different file types e.g. image files saved as BIN
$06.

NOTE: ProDOS file type FNT $07 is reserved for Apple /// SOS font
files, but given their scarcity the type is re-used here.
