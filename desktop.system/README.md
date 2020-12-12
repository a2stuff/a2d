# DeskTop diassembly notes - DESKTOP.SYSTEM

`desktop.system.s`

A short (8k) loader program. This is responsible for copying the rest
to a RAM card (if available), then invoking the main app. The second
half is used to copy Selector entries to RAMCard on first boot.

The file is present in the original distribution as `DESKTOP1` but is
renamed `DESKTOP.SYSTEM` in many disk images to be launched at boot.

The main app (`DESKTOP2`) is invoked by loading only the first segment,
which in turn loads the rest of the segments of the file.
