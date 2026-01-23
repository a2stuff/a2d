## Build Instructions

Cross-development on a Unix-like system. Tested on macOS 14 and Linux Ubuntu Xenial 16.04.

Fetch, build, and install [cc65](http://cc65.github.io/cc65/):

```
git clone https://github.com/cc65/cc65
make -C cc65 && make -C cc65 avail
```

A very recent version of cc65 will be required, as recent compiler features and symbols from `asminc/apple2.inc` are used, and these change fairly often.

Fetch and build Apple II DeskTop:

```
git clone https://github.com/a2stuff/a2d
cd a2d
make
```

This will build all targets, including DeskTop itself, the Disk Copy and Shortcuts modules, desk accessories, and a handful of other files.

If you have a newish version of GNU Make then you can perform parallel builds e.g. `gmake -j8`. GNU Make 3.81 (the version that comes with Xcode utilities on macOS) has a bug which will hang when building. Fixes welcome!

## Getting DeskTop Onto Your Apple II

There are a handful of approaches for getting the files on your real or virtual Apple II.

### Option #1: Create a Disk Image

> Useful with ADTPro, solid-state drives like Floppy Emu, or emulators.

To produce a ProDOS disk image, install and build [Cadius](https://github.com/mach-kernel/cadius):

```
git clone https://github.com/mach-kernel/cadius
make -C cadius && make -C cadius install
```

Then run: `make package`

This will generate: `A2DeskTop-...2mg` and `.hdv` (800KB/32MB images containing the full application) and `A2DeskTop-..._140k_disk1.po`, `..._disk2.po`, etc. (the files split across multiple 140k images). The version (e.g. `alpha30`) and language (e.g. `en`) are defined in `config.inc`.

Mount these disk images in your emulator, or transfer them to real floppies with [ADTPro](http://adtpro.com/), then follow the install instructions below.

### Option #2: Install to an Existing Disk Image

> Useful with solid-state drives like Floppy Emu, or emulators.

Build and install [Cadius](https://github.com/mach-kernel/cadius) (instructions above)

Set these environment variables:

```sh
INSTALL_IMG=/path/to/image/file.2mg     # e.g. ~/Documents/hd.2mg
INSTALL_PATH=/prodos/directory          # e.g. /HD/A2.DESKTOP
```

Then run: `make install`

This will create the target ProDOS directory if necessary, then copy the built files in, overwriting any existing files.

After building and installing, you can use `bin/setopt sel` and `bin/setopt nosel` to toggle whether Shortcuts starts or not, and `bin/setopt ram` and `bin/setopt noram` to toggle whether DeskTop is copied to a RAMCard or not. These can be controlled within DeskTop using the Options control panel, but being able to toggle these on the command line is useful during development.

If DeskTop hasn't created `LOCAL/DESKTOP.CONFIG` yet, run `bin/defopt` first to create a default options file.

Optional:
* Define `INSTALL_NOLOCDA=1` to skip localizing DA filenames; useful if you switch languages during development and don't want to clutter your install.
* Define `INSTALL_NOSAMPLES=1` to skip installing sample media, which can be slow.

### Option #3: Mount Folder in Virtual ]\[

> Useful with the Virtual ]\[ emulator

If you use [Virtual \]\[](http://www.virtualii.com/) as your emulator, you can skip creating a disk image.

After building, run: `make mount`

This will copy the built files into the `mount/` directory with appropriate file types/auxtypes set. Run Virtual ]\[ and use the **Media** > **Mount Folder as ProDOS Disk...** menu item, then select the `mount/` folder. A new ProDOS volume called `/MOUNT` will be available, containing DeskTop.

### Option #4: Build ShrinkIt file

If you have a workflow amenable to ShrinkIt disk images, first install `nulib2`, then run `make shk`. This will create an `A2D.SHK` file.

### Other

If you need to copy the files some other way (e.g. via [CiderPress](http://a2ciderpress.com/)), it's probably easiest to transfer the files from the disk images created by `make package` as they will have the appropriate ProDOS file types and aux types.


## Install Instructions

Apple II DeskTop works best on a mass storage device. Once you have the files accessible on your Apple, transfer them to your hard disk. It's best to create a top level `A2.DESKTOP` directory and copy the files/folders into it, with the following structure:

```
   Name                   Type  AuxType

   /HD/
     A2.DESKTOP/          DIR
       DESKTOP.SYSTEM     SYS
       MODULES/           DIR
         DESKTOP          $F1   $0000
         DISK.COPY        $F1   $0000
         SELECTOR         $F1   $0000
         THIS.APPLE       $F1   $0642
         SHOW.FONT.FILE   $F1   $0642
         SHOW.IMAGE.FILE  $F1   $0642
         ...
       APPLE.MENU/        DIR
         CALCULATOR       $F1   $0642
         CALENDAR         $F1   $0642
         CONTROL.PANELS/  DIR
           DATE.AND.TIME  $F1   $0642
           SYSTEM.SPEED   $F1   $0642
           ...
         ...
       EXTRAS/            DIR
         UNSHRINK         SYS
         ...
```

## Running

Invoke `DESKTOP.SYSTEM` to launch the app. By default, DeskTop will launch. You can use the control panel Options to configure Shortcuts to start instead, which will show a dialog containing any shortcuts you have configured in DeskTop, for faster access to programs.
