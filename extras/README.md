# Extras

## AWLaunch.system

BASIS.SYSTEM-compatible launcher invoked by DeskTop for AppleWorks 5.1
files. Checks for AppleWorks on DeskTop's hard disk as
/<vol>/AW5/APLWORKS.SYSTEM and if found will load it and install an
UltraMacros task that is patched at runtime to include the target
AWP/ASP/ADB file path.

* `awlaunch.system.s` is the system file.

* `awlaunch_task.bin` is the compiled task file. When updated, string
    offsets in the system file must be updated as well.
