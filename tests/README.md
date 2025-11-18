Run these with:

```sh
bin/mametest tests/SCRIPTNAME.lua
```

Tests can define custom MAME configuration. The contents of a config
block are executed by `mametest` to override environment variable that
are used when MAME launches.

* `MODEL` - the system type, e.g. "apple2ee", "apple2gsr1" etc
* `MODELARGS` - slot and other configuration, e.g. "-sl2 mouse"
* `DISKARGS` - disk configuration, e.g. "-hard1 a2d.hdv"
  * NOTE: This is parsed as space-delimited pairs and the second argument is copied to a temp directory so that the original disk images are not modified
* `RESOLUTION` - defaults to "560x384"; for IIgs should be set to "704x462"

Example:

```lua
--[[ BEGINCONFIG ==================================================

MODEL="apple2ee"
MODELARGS="-sl1 ssc -sl2 mouse -sl5 ramfactor -sl7 cffa2 -aux rw3"
DISKARGS="-hard1 out/a2d_800k.2mg -flop1 res/FLOPPY1.dsk"
RESOLUTION="560x384"

================================================== ]]-- ENDCONFIG
```
