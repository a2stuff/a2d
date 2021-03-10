## Build Instructions

Cross-development on a Unix-like system (including macOS 10) is assumed.

Fetch, build, and install [cc65](http://cc65.github.io/cc65/):

```
git clone https://github.com/cc65/cc65
make -C cc65 ca65 ld65 avail
```

Fetch and build Apple II DeskTop:

```
git clone https://github.com/a2stuff/a2d
cd a2d
make
```

This will build all targets, including DeskTop itself, desk accessories, and preview accessories, and the optional Selector app.

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

This will generate: `A2DeskTop_800k.2mg` (an 800k image containing the full application) and `A2DeskTop_140k_disk1.po` and `A2DeskTop_140k_disk2.po` (the files split into two 140k images).

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

This will create the target ProDOS directory if necessary, then copy the built files in, overwriting an existing files.

Optionally, to have Selector installed, run: `make installsel`

### Option #3: Mount Folder in Virtual ]\[

> Useful with the Virtual ]\[ emulator

If you use [Virtual \]\[](http://www.virtualii.com/) as your emulator, you can skip creating a disk image.

After building, run: `make mount`

This will copy the built files into the `mount/` directory  with appropriate file types/auxtypes set. Run Virtual ]\[ and use the **Media** > **Mount Folder as ProDOS Disk...** menu item, then select the `mount/` folder. A new ProDOS volume called `/MOUNT` will be available, containing DeskTop.

### Other

If you need to copy the files some other way (e.g. via [CiderPress](http://a2ciderpress.com/)), it's probably easiest to transfer the files from the disk images created by `bin/package` as they will have the appropriate ProDOS file types and aux types.


## Install Instructions

Apple II DeskTop works best on a mass storage device. Once you have the files accessible on your Apple, transfer them to your hard disk. It's best to create a top level `A2.DESKTOP` directory and copy the files/folders into it, with the following structure:

```
   Name                   Type  AuxType

   /HD/
     A2.DESKTOP/          DIR
       DESKTOP.SYSTEM     SYS
       SELECTOR           $F1   $0000     (Optional)
       DESKTOP2           $F1   $0000
       DESK.ACC/          DIR
         CALCULATOR       $F1   $0641
         EYES             $F1   $0641
         CONTROL.PANELS/  DIR
           DATE           $F1   $0641
           SYSTEM.SPEED   $F1   $0641
           ...
         ...
       PREVIEW/           DIR
         SHOW.FONT.FILE   $F1   $0641
         SHOW.IMAGE.FILE  $F1   $0641
         ...
```
