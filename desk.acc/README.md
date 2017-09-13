Disassembly of the desk accessories:

* [Show Text File](show_text_file.s) - in progress! 90% complete
* [Calculator](calculator.s) - in progress! 90% complete
* [Date](date.s) - in progress! 50% complete
* [Puzzle](puzzle.s) - in progress! 75% complete
* Sort Directory - _not started_

New desk accessories:
* [Show Image File](show_image_file.s) - complete!

## Desk Accessory Details

* Loaded at $800 through (at least) $14FF
* Copy themselves from Main into Aux memory (same location)
* Can call into ProDOS MLI and A2D entry points ($4000, etc)

## Files

* `Makefile` - cleans/builds targets
* `go.sh` - bash script to build, verify, and copy files

* `orig/*.bin` - original binary (type $F1, start $800)
* `infos/*.info` - da65 "info" file - used to inform disassembly
* `*.s` - source (originally generated using da65, now modified)

## Build Instructions

On Unix-like systems (including Mac OS X) `make all` should build
build the desk accessory files (original and new) and output
files with a `.F1` suffix, representing the $F1 file type required.

For the original DAs, the `.F1` and `.bin` files can be compared
using `diff` to ensure that no changes have been introduced by the
disassembly process.

Tips:

* While I'm disassembling (i.e. guessing what entry points do
   and what parameters are, converting .word to .byte, etc) I
   leave this running in another window:

   `while true; do clear; ./go.sh; sleep 1; done`


## Install Instructions

Transfer the `.F1` files to your Apple (real or virtual) ensuring you:

* Drop the suffix
* Replace `.` in the name with spaces
* Ensure they have ProDOS file type `$F1`
* Ensure they have start address `$800`

The last two are tricky, and depend on how you're copying the files.
My process is to use Virtual ][ on my Mac and mount a folder as a
ProDOS drive; I copy one of the original DAs into the folder which
gives it the $F1 filetype as a suffix and start address as an invisible
resource stream. I then unmount the folder, overwrite the DA with
a newly built one, and remount the folder.

Finally:

* Drop the files into your `A2.DESKTOP\DESK.ACC` folder
* Restart so A2D picks up the new DA

Tips:

* You can use the Sort Directory DA to order the files, which controls
    the menu order:
  * Open the `A2.DESKTOP\DESK.ACC` folder
  * Press Open-Apple and click on the each file in the desired order
  * Select Sort Directory from the Apple menu, and verify the order
  * Restart
