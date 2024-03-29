# Extras

## AWLaunch.system

BASIS.SYSTEM-compatible launcher invoked by DeskTop for AppleWorks 5.1
files. Checks for AppleWorks on DeskTop's hard disk as
/<vol>/AW5/APLWORKS.SYSTEM and if found will load it and install an
UltraMacros task that is patched at runtime to include the target
AWP/ASP/ADB file path.

* `awlaunch.system.s` is the system file.

* `awlaunch_task.bin` is the compiled task file. When updated, two
    string offsets in the system file must be updated as well - these
    are the offsets of the second byte of the second and third $22/$22
    sequences in the file respectively. Offset location +$13/$14 in
    the macro table itself contains the address of the end of that
    particular macro table, assuming that the location of the table is
    $EF00. The end of the table contains the sequence $00/$1E.
