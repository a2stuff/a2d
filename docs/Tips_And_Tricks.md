△ = Open Apple

▲ = Solid Apple

# Undiscoverable Features

* When dragging a selection of files to a destination on the same volume, the files will be moved by default. Hold down **△** before letting go of the mouse button to force a copy instead. Files dragged to a different volume will always be copied.
* Hold down **△** when launching `DESKTOP.SYSTEM` to prevent DeskTop from being copied to a RAM card. (A tip is now shown for this while copying.)
* Desk Accessory files with high bit set in the aux type field ($8640) will not appear in the Apple menu.
* You can't run a Binary file by double-clicking, but you can run it with the **△O** shortcut or holding down **△** or **▲** while selecting **File > Open**.
* The Sort Directory desk accessory has two modes:
    * If any files are selected, these are moved to the start of the directory listing, in selection order; other files appear after, order unchanged.
    * If no files are selected, all files are sorted by type: DIR, then TXT, then SYS, then others in descending (numeric) order.
* Hold down **△** or **▲** when opening a folder using double-click or **File > Open** to close the parent folder.
    * Note: Does not work with the **△O** shortcut.
* The Control Panel desk accessory writes settings back to the `DESKTOP2` file when it is closed. If it is not present, or is locked, the settings will not be saved for the next session.


# File Types

* Binary files (type $06) with aux type $2000 or $4000 are treated as Graphics files (HR/DHR)
* Binary files (type $06) with aux type $5800 are treated as Graphics files (Minipix/Print Shop)
* Desk Accessory files have type $F1, and auxtype $640 or $8640


# Secrets and Mysteries

* The Calculator desk accessory has a tiny monogram resembling "JB" drawn in the title bar - possibly "J. Bernard" thanked in the credits?
* The string "Rien" appears in a couple of places in the code. Is this a name?
* In the "This Apple" desk accessory, type **E** to see what other Apple models look like.
