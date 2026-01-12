> NOTE: This is all extremely experimental.
> * Requires macOS
> * Probably some other stuff

Run in a terminal with:

```sh
make                              # build latest
make package                      # create required disk images

export MAMEDIR=<path to your MAME directory>
export MAMEEXE=<path to your MAME executable>

bin/mametest tests/SCRIPTNAME.lua
```

Options:

* `--only PATTERN` - run only matching named test steps (`*` and `?` are wildcards, `|` to separate multiple patterns); useful for fast iteration
* `--skip N` - skip the first N tests
* `--count N` - run at most N tests
* `--visible` - show the emulator window (default is headless)
* `--audible` - play the emulator audio (default is silent)
* `--nosnaps` - don't generate snapshots
* `--console` - don't ask MAME to run the script (but do load its config, see below), launch the Lua console instead
* `--slow` - run at normal speed (default is unthrottled)
* `--debug` - run with MAME's debugger
* `--listmedia` - print MAME's list of drive options
* `--listslots` - print MAME's list of slot options

## Configuration

The default system configuration is:

* Apple IIe Enhanced (`apple2ee`)
* Aux: Extended 80 Column Card
* Slot 2: Mouse card
* Slot 4: Mockingboard
* Slot 6: Disk II Controller w/ 2 (empty) drives
* Slot 7: CFFA2 card, w/ 800K package image
* No-Slot Clock under system ROM

> TODO: Make the default config simpler:
> * slot 4 empty by default

Tests can define custom MAME configuration. The contents of a config block are executed by `mametest` to override environment variable that are used when MAME launches.

* `MODEL` - the system type, e.g. `"apple2ee"`, `"apple2gsr1"` etc
* `MODELARGS` - slot and other configuration, e.g. `"-sl2 mouse"`
  * A slot can be emptied with empty single-quoted string, e.g. `-sl6 ''`
  * Note that MAME's defaults for each model are different. See the [MAMEDEV Page](https://wiki.mamedev.org/index.php/Driver:Apple_II#The_default_configurations) for specifics.
* `DISKARGS` - disk configuration, e.g. `"-hard1 a2d.hdv"`
  * NOTE: This is parsed as space-delimited pairs and the second argument is copied to a temp directory so that the original disk images are not modified
* `RESOLUTION` - defaults to `"560x384"`; for IIgs should be set to `"704x462"`
* `WAITFORDESKTOP` - defaults to `true`; set it to `false` for the rare tests that shouldn't wait for DeskTop to be ready before starting the script
* `CHECKAUXMEMORY` - defaults to `true`; set it to `false` for the rare tests that run on an Apple IIe without an 80 column card

These environment variables can be used:

* `HARDIMG` has the path to the 800K package disk
* `FLOP1IMG` has the path to the 140K package disk #1 (desktop)
* `FLOP2IMG` has the path to the 140K package disk #2 (accessories)

Example:

```lua
--[[ BEGINCONFIG ==================================================

MODEL="apple2ee"
MODELARGS="-sl1 ssc -sl2 mouse -sl5 ramfactor -sl7 scsi -aux rw3"
DISKARGS="-hard1 out/a2d_800k.2mg -flop1 res/FLOPPY1.dsk"
RESOLUTION="560x384"

================================================== ENDCONFIG ]]
```

## ADTPro VEDrive

Tests using ADTPro's Virtual Ethernet Drive are supported if you're using Ample's MAME.

* Have https://github.com/bobbimanners/ProDOS-Utils/ cloned parallel to your `a2d` repo
* Specify an `uthernet2` card in the test config; works in Slot 3 with `-sl3`
* Define `VEDISK1` and `VEDISK2` in the test config, pointing at .po, .hdv or .2mg disk images.

If you get a warning from Ample/MAME about VMNet Permissions, follow the instructions.

See `tests/infrastructure/vedrive.lua` for an example.


# Files

## `lib/` - Libraries

This directory is part of the package path, so scripts can just `a2d = require("a2d")`, etc. But shouldn't need to.

* `lib/autoboot.lua` - the file that MAME is actually launched with. It has boilerplate to simplify test scripts.
* `lib/test.lua` - basic test infrastructure; exposed as a `test` global.
* `lib/apple2.lua` - utilities for driving Apple II systems in MAME; exposed as an `apple2` global.
* `lib/a2d.lua` - utilities for driving Apple II DeskTop specifically; exposed as an `a2d` global.

## `screenshots/`

Not tests - these just dump screenshots of the app, for documentation or e.g. validating fonts.

## `config/`

Not tests, just example machine configurations. These verify that the abstractions in `lib/apple2.lua` work.

## `infrastructure/`

Tests for the testing libraries themselves.

## `desk_acc/`, `desktop/`, `disk_copy/`, `selector/`, `launcher/`

Tests specific to various components of the application.

# Tips For Authoring Tests

* Apple IIc and IIc+ models are slow in MAME. @mgcaret points out that on real hardware the processor slows to 1MHZ when accessing 800K drives. Prefer using a `superdrive` card in an Apple IIe instead.
* Drive assignments are a pain, especialy with SCSI cards. See the [MAMEDEV Page](https://wiki.mamedev.org/index.php/Driver:Apple_II#More_configuration) for some notes. Basically, MAME does things bottom-up, whereas the Apple II ("autostart ROM") and SCSI do things top-down.
* Controlling the mouse precisely with MAME is elusive, so MouseKeys mode is used in most tests. Is it most convenient with the `a2d.InMouseKeys()` helper. This works great with some exceptions:
  * Since it is quantized (and differently for x/y), errors creep in over time. Add an `m.Home()` if this happens.
  * You can't press shortcut keys or <kbd>Esc</kbd> in MouseKeys mode. This makes testing edge cases challenging.
* The API in `a2d` is limited to driving the UI primarily through the keyboard. For example, `a2d.OpenPath()` works bu closing all windows, then using type-down selection on each segment followed by the OA+SA+Down shortcut to open the selection while closing the current window. This is generally sufficient but some things require creativity:
  * As noted, methods like `a2d.SelectPath()` and `a2d.OpenPath()` by default close all windows first. If you need multiple windows open for an operation you need get creative()
    * Add a shortcut (e.g. via `a2d.AddShortcut()`) for a dependent window, use `a2d.OpenPath()` to open the initial window, then `a2d.OAShortcut("1")` (etc) to open the second window.
    * Use the `{keep_windows=true}` option to override the default. But note that this works by setting focus to the desktop and opening windows via typing. If you open "/DISK1" and then try to open "/DISK1/FOLDER1" the second "hijacks" the window of the first. Re-ordering the actions is usually sufficient.
* The `a2d` library implicitly has short waits after each action using `a2d.WaitForRepaint()`. The duration of this delay can (and should) be changed by calling `a2d.ConfigureRepaintTiming()`. While this is convenient, experience has shown that manual delays using `emu.wait(N)` after an action that "takes too long" are more maintainable; adding a single extra wait is better than trying to tweak the global settings.. Even better, of course, are using functions that delay until a milestone has been reached (the desktop is visible, an alert is showing, etc).
* Access to virtual disk drives is via the `manager.machine.images` collection.
  * The accessed objects provide:
    * `drive.filename` - get the current image path
    * `drive:load(name)` - insert/replace a disk image
    * `drive:unload()` - eject a disk image
  * The keys in `images` depend heavily on the configuration:
    * For a Disk II controller in Slot 6:
      * `local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]`
      * `local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]`
    * For a Superdrive controller in Slot 5:
      * `local s5d1 = manager.machine.images[":sl5:superdrive:fdc:0:35hd"]`
      * `local s5d2 = manager.machine.images[":sl5:superdrive:fdc:1:35hd"]`
    * For a SCSI controller in Slot 7:
      * `local s7d1 = manager.machine.images[":sl7:scsi:scsibus:6:harddisk:image"]`
    * For an Apple IIgs or Apple IIc+
      * `local s6d1 = manager.machine.images[":fdc:0:525"]`
      * `local s6d2 = manager.machine.images[":fdc:1:525"]`
      * `local s5d1 = manager.machine.images[":fdc:2:35dd"]`
      * `local s5d2 = manager.machine.images[":fdc:3:35dd"]`
  * ... and so on. Since this depends so heavily on the configuration which varies between tests, no abstraction is (currently) provided for this. The convention is to provide this mapping at the top of the test file for tests that do interact with the virtual drives.


