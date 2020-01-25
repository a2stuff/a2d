## Build Instructions

Cross-development on a Unix-like system (including macOS 10) is assumed.

Fetch, build, and install [cc65](http://cc65.github.io/cc65/):

```
git clone https://github.com/cc65/cc65 cc65
cd cc65
make ca65 ld65 avail
```

Within the `a2d` repo, `make` should build all targets, including DeskTop itself, desk accessories, and preview accessories.

## Getting DeskTop Onto Your Apple II

There are a handful of approaches for getting the files on your real or virtual Apple II.

### Create a Disk Image

> Useful with ADTPro, solid-state drives like Floppy Emu, or emulators.

To produce a ProDOS disk image, install and build [Cadius](https://github.com/mach-kernel/cadius):

```
git clone https://github.com/mach-kernel/cadius /tmp/cadius
cd /tmp/cadius
make -C /tmp/cadius
CADIUS=/tmp/cadius/bin/release/cadius
```

Then run: `res/package.sh`

This will generate: `out/A2.DeskTop.po` (an 800k image containing the full application) and `A2DeskTop.1.po` and `A2DeskTop.2.po` (the files split into two 143k images).

Mount these disk images in your emulator, or transfer them to real floppies with [ADTPro](http://adtpro.com/), then follow the install instructions below.

### Install to an Existing Disk Image

> Useful with solid-state drives like Floppy Emu, or emulators.

Install and build [Cadius](https://github.com/mach-kernel/cadius) (instructions above)

Set these environment variables:

```sh
INSTALL_IMG=/path/to/image/file.2mg
INSTALL_PATH=/prodos/folder
```

Then run: `make && make install`. This will create the target ProDOS directory if necessary, then copy the built files in, overwriting an existing files.

### Mount Folder in Virtual ]\[

> Useful with the Virtual ]\[ emulator

If you use [Virtual \]\[](http://www.virtualii.com/) as your emulator, you can skip creating a disk image.

At the top level of the repo, run `mkdir mount` then run `make`. After building all targets, this will copy the built files in. Run Virtual ]\[ and use the **Media** > **Mount Folder as ProDOS Disk...** menu item, then select the `mount/` folder. A new ProDOS volume called `MOUNT` will be available.

### Other

If you need to copy the files some other way (e.g. via [CiderPress](http://a2ciderpress.com/)), it's probably easiest to transfer the files from the disk images created by `res/package.sh` as they will have the appropriate ProDOS file types and aux types.

## Install Instructions

Apple II DeskTop works best on a mass storage device. Once you have the files accessible on your Apple, transfer them to your hard disk. It's best to create a top level `A2.DESKTOP` directory and copy the files/folders into it, with the following structure:

```
   /HD/
     A2.DeskTop/
       DeskTop.system
       DeskTop2
       Desk.Acc/
         Calculator
         Control.Panel
         Date
         ...
       Preview/
         Show.Font.File
         Show.Image.File
         ...
```
