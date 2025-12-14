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
* Aux: 8MB RAMWorks card
* Slot 1: 8MB RAMFactor card
* Slot 2: Mouse card
* Slot 4: Mockingboard
* Slot 6: Disk II Controller w/ 2 (empty) drives
* Slot 7: SCSI card, w/ 800K package image
* No-Slot Clock under system ROM

Tests can define custom MAME configuration. The contents of a config block are executed by `mametest` to override environment variable that are used when MAME launches.

* `MODEL` - the system type, e.g. `"apple2ee"`, `"apple2gsr1"` etc
* `MODELARGS` - slot and other configuration, e.g. `"-sl2 mouse"`
  * A slot can be emptied with empty single-quoted string, e.g. `-sl6 ''`
* `DISKARGS` - disk configuration, e.g. `"-hard1 a2d.hdv"`
  * NOTE: This is parsed as space-delimited pairs and the second argument is copied to a temp directory so that the original disk images are not modified
* `RESOLUTION` - defaults to `"560x384"`; for IIgs should be set to `"704x462"`

These variables can be used:

* `HARDIMG` has the path to the 800K package disk
* `FLOP1IMG` has the path to the 140K package disk #1 (desktop)
* `FLOP2IMG` has the path to the 140K package disk #2 (accessories)

Example:

```lua
--[[ BEGINCONFIG ==================================================

MODEL="apple2ee"
MODELARGS="-sl1 ssc -sl2 mouse -sl5 ramfactor -sl7 cffa2 -aux rw3"
DISKARGS="-hard1 out/a2d_800k.2mg -flop1 res/FLOPPY1.dsk"
RESOLUTION="560x384"

================================================== ENDCONFIG ]]
```

# Files

Most files in this directory correspond to `../notes/testplan.md`.

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

