Disassembly of the desk accessories:

* Calculator - _not started_
* Date - _not started_
* Puzzle - _not started_
* [Show Text File](show_text_file.s) - in progress!
* Sort Directory - _not started_

New desk accessories:
* [Show DHR File](show_dhr_file.s) - in progress!

## Desk Accessory Details

* Loaded at $800 through (at least) $14FF
* Copy themselves from Main into Aux memory (same location)
* Can call into ProDOS MLI and A2D entry points ($4000, etc)

## Files

* `Makefile` - cleans/builds targets
* `go.sh` - bash script to build, verify, and copy files

* `*.bin` - original binary (type $F1, start $800)
* `*.info` - da65 "info" file - used to inform disassembly
* `*.s` - source (originally generated using da65, now modified)
