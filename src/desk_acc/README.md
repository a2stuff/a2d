# Desk Accessories

* [Calculator](calculator.s)
  * A basic four function calculator. Original DA from MouseDesk, with fixes.
* [Sort Directory](sort.directory.s)
  * Reorders the files in the active window by file type or selection. Original DA from MouseDesk, with fixes.
* [This Apple](this.apple.s)
  * Gives details about the computer, expanded memory, and what's in each slot.
* [Calendar](calendar.s)
  * Displays any month, from 1901 through 2155.
* [Key Caps](key.caps.s)
  * Shows an on-screen keyboard map, and indicates which key is pressed.
* [Run Basic Here](run.basic.here.s)
  * Launches BASIC.SYSTEM with PREFIX set to current window's directory.
* [Find Files](find.files.s)
  * Search a directory and descendants for filenames. Use ? and * as wildcards.
* [Scientific Calculator](sci.calc.s)
  * Calculator with trigonometry and other additional functions
* [Map](map.s)
  * World map with some searchable city locations.
* [Print Catalog](print.catalog.s)
  * Dumps a recursive catalog of filenames to a printer attached to Slot 1.
* [Change Type](change.type.s)
  * Shows the type and auxtype of selected files, and allows changing them.
* [DOS 3.3 Importer](dos33.import.s)
  * Allows importing from DOS 3.3 disks to the current window.

## Control Panels

* [Date and Time](date.and.time.s)
  * Based on the original Date DA from MouseDesk, expanded to include setting the time as well.
* [Control Panel](control.panel.s)
  * Modify DeskTop settings: desktop pattern, double-click speed, mouse tracking speed, and insertion point blink speed.
* [Sounds](sounds.s)
  * Select different alert sounds.
* [International](internationaloptions.s)
  * Modify regional options, including date, time, and number formats.
* [Options](options.s)
  * Modify options, including launching the selector or copying to RAMCard.
* [Joystick](joystick.s)
  * Shows joystick calibration.
* [System Speed](system.speed.s)
  * Enable/disable system accelerator.

## Entertainment

* [Bounce](bounce.s)
  * Bouncing shapes.
* [Eyes](eyes.s)
  * Eyes that follow the mouse.
* [Puzzle](puzzle.s)
  * Sliding tile puzzle. Original DA from MouseDesk, with fixes.
* [Lights Out](lights.out.s)
  * Try to turn out all the lights by clicking.
* [Neko](neko.s)
  * An animated cat who interacts with your mouse.
* [CD Remote](cd.remote.s)
  * Controls music playback on an AppleCD SC.

## Screen Savers

* [Flying Toasters](flying.toasters.s)
  * Visual distractions.
* [Maze](maze.s)
  * Visual distractions.
* [Melt](melt.s)
  * Visual distractions.
* [Invert](invert.s)
  * Visual distractions.
* [Helix](helix.s)
  * Visual distractions.
* [Analog Clock](analog.clock.s)
  * Displays the current time.
* [Digital Clock](digital.clock.s)
  * Displays the current time.
* [Matrix](matrix.s)
  * Digital rain.
* [Message](message.s)
  * Scrolls the typed message across the screen..
* [Rod's Pattern](rods.pattern.s)
  * Classic Apple II lo-res demo.

## Development Tools

* [Darkness](darkness.s)
  * A debugging tool that paints the whole screen a dark pattern.
* [Print Screen](print.screen.s)
  * Prints a screenshot to an ImageWriter II attached to a Super Serial Card in Slot 1.
* [Screenshot](screenshot.dump.s)
  * Saves a screenshot to the application directory.
* [Benchmark](benchmark.s)
  * Measures CPU speed using VBL.

Note that the new desk accessories require an updated version of Apple II DeskTop and **will not work** with DeskTop 1.1 or MouseDesk.

See [API.md](API.md) for programming details

# Preview Accessories

These files are a special class of Desk Accessory which reside in
the `MODULES` subdirectory relative to `DESKTOP` (next to `APPLE.MENU`).
These DAs will be invoked automatically for certain file types when
File > Open is run or the files are double-clicked.

* [Show Text File](show.text.file.s)
   * Handles text files (TXT $04). Original DA from MouseDesk, with fixes.
* [Show Image File](show.image.file.s)
   * Handles image files (FOT $08 and some BIN $06)
   * Supports Hires and Double Hires images, including compressed images
   * Supports MiniPix/PrintShop clip-art
* [Show Duet File](show.duet.file.s)
   * Handles Electric Duet music files ($D5/$D0E7)
* [Show Font File](show.font.file.s)
   * Handles MGTK font files (FNT $07)

The files can optionally be copied into the `APPLE.MENU` directory to
allow direct invocation from the Apple menu. This can be useful to
preview files of different file types e.g. image files saved as BIN
$06.

NOTE: ProDOS file type FNT $07 is reserved for Apple /// SOS font
files, but given their scarcity the type is re-used here.
