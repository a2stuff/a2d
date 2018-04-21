Disassembly of the original desk accessories:

* [Calculator](calculator.s) - complete!
* [Date](date.s) - complete!
* [Puzzle](puzzle.s) - complete!
* [Show Text File](show.text.file.s) - in progress! 95% complete
* [Sort Directory](sort.directory.s) - in progress! 40% complete

New desk accessories:
* [Show Image File](show.image.file.s) - complete!
* [This Apple](this.apple.s) - complete!
* [Eyes](eyes.s) - complete!

## Desk Accessory Details

* Loaded at $800 through (at least) $14FF
* Copy themselves from Main into Aux memory (same location)
* Can call into ProDOS MLI and MGTK/A2D entry points ($4000, etc)
* See [API.md](API.md) for programming details

## Files

* `Makefile` - cleans/builds targets
* `orig/*.bin` - original binary (type $F1, auxtype $0640, start $800)
* `*.s` - source (originally generated using da65, now modified)

## Build Instructions

On Unix-like systems (including Mac OS X) `make all` should build
build the desk accessory files (original and new) into `out/`
output with a `.$F1` suffix, representing the $F1 file type required.

For the original DAs, the `.$F1` and `.bin` files can be compared
using `diff` to ensure that no changes have been introduced by the
disassembly process.


## Install Instructions

Transfer the `.$F1` files to your Apple (real or virtual) ensuring you:

* Drop the suffix
* Replace `.` in the name with spaces
* Ensure they have ProDOS file type `$F1`
* Ensure they have start address `$800`

The last two are tricky, and depend on how you're copying the files.
My process is to use Virtual ]\[ on my Mac and mount a folder as a
ProDOS drive; I copy one of the original DAs into the folder which
gives it the $F1 filetype as a suffix and start address as an invisible
resource stream. I then unmount the folder, overwrite the DA with
a newly built one, and remount the folder.

This is done by the `res/go.sh` script.

Finally:

* Drop the files into your `A2.DESKTOP\DESK.ACC` folder
* Restart so A2D picks up the new DA

Tips:

* You can use the Sort Directory DA to order the files, which controls
    the menu order:
  * Open the `A2.DESKTOP\DESK.ACC` folder
  * Press Open-Apple and click on each file in the desired order
  * Select Sort Directory from the Apple menu, and verify the order
  * Restart

## Package Instructions

To produce a ProDOS disk image with the , install and build the
[Cadius](https://github.com/mach-kernel/cadius) tool:

```
git clone https://github.com/mach-kernel/cadius /tmp/cadius
make -C /tmp/cadius
CADIUS=/tmp/cadius/bin/release/cadius
```

Then from the `desk.acc/` directory, run: `go/package.sh`

This will generate: `desk.acc/out/DeskAccessories.2mg`

Mount this disk image in your emulator, or transfer it to a real floppy
with [ADTPro](http://adtpro.com/), then follow the last steps of the 
install instructions above.
