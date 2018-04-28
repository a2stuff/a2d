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

See [API.md](API.md) for programming details

## Files

* `Makefile` - cleans/builds targets
* `orig/*.bin` - original binary (type $F1, auxtype $0640, start $800)
* `*.s` - source (originally generated using da65, now modified)

## Build Instructions

On Unix-like systems (including Mac OS X) `make all` should build
build the desk accessory files (original and new) into `out/`
output with a `.built` suffix.

For the original DAs, the `.built` and `.bin` files can be compared
using `diff` to ensure that no changes have been introduced by the
disassembly process.

With `desk.acc` as the current directory, run `res/go.sh` to automatically
verify that the files are unchanged from the original, and also generate
semi-useful stats showing disassembly progress.

## Getting The DAs Onto Your Apple II

There are a handful of approaches for getting the files on your real
or virtual Apple.

### Create a Disk Image

To produce a ProDOS disk image with the DA files, install and build the
[Cadius](https://github.com/mach-kernel/cadius) tool:

```
git clone https://github.com/mach-kernel/cadius /tmp/cadius
make -C /tmp/cadius
CADIUS=/tmp/cadius/bin/release/cadius
```

Then from the `desk.acc/` directory, run: `go/package.sh`

This will generate: `desk.acc/out/DeskAccessories.po`

Mount this disk image in your emulator, or transfer it to a real floppy
with [ADTPro](http://adtpro.com/), then follow the install instructions
below.

### Mount Folder in Virtual ]\[

If you use [Virtual \]\[](http://www.virtualii.com/) as your emulator,
you can skip creating a disk image.

With `desk.acc` as your current directory, run the `res/mount.sh`
script. This will create a `desk.acc/mount` folder and the built files
will automatically be copied in. Then run Virtual ]\[ and use the
**Media** > **Mount Folder as ProDOS Disk...** menu item, then select
the `desk.acc/mount` folder. A new ProDOS volume called `/MOUNT` will
be available. (Tip: use the **Special** > **Check Drives** command in
A2D to make it appear.)

(The `res/go.sh` script will helpfully run `res/mount.sh`
automatically if the `mount` folder already exists.)

### Other

If you need to copy the files some other way (e.g. via
[CiderPress](http://a2ciderpress.com/)), you need to do the following:

Transfer the `.built` files in the `out` directory, ensuring you:

* Drop the `.built` suffix
* Ensure they have ProDOS file type `$F1`
* Ensure they have start address `$0800`
* Ensure they have auxtype `$0640` (to match the originals)

The last three are tricky, and depend on how you're copying the files.

## Install Instructions

Once you have the files accessible on your Apple:

* Copy the files into your `A2.DESKTOP/DESK.ACC` folder (using A2D or any other tool)
* Restart so A2D picks up the new DA

Tips:

* You can use the Sort Directory DA to order the files, which controls
    the menu order:
  * Open the `A2.DESKTOP/DESK.ACC` folder
  * Hold Open-Apple and click on each file in the desired order
  * Select Sort Directory from the Apple menu, and verify the order
  * Restart
