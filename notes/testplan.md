# Release Qualification Test Cases

> Status: Work in Progress

The `/TESTS` volume can be found as `res/tests.hdv` in the repo. Test cases should start with a fresh copy of this volume, as some cases will modify the volume.

When steps say to a path e.g. `/TESTS/FOLDER/SUBFOLDER`, open the volume then each subsequent folder, leaving intermediate windows open.

# Launcher

* Without starting DeskTop, launch `BASIC.SYSTEM`. Set a prefix (e.g. `PREFIX /RAM`). Invoke `DESKTOP.SYSTEM` with an absolute path (e.g. `-/A2.DESKTOP/DESKTOP.SYSTEM`). Verify that it starts correctly.
* Move DeskTop into a subdirectory of a volume (e.g. `/VOL/A2D`). Without starting DeskTop, launch `BASIC.SYSTEM`. Set a prefix to a parent directory of desktop (e.g. `PREFIX /VOL`). Invoke `DESKTOP.SYSTEM` with a relative path (e.g. `-A2D/DESKTOP.SYSTEM`). Verify that it starts correctly.
* Configure a system with a RAMCard, and ensure DeskTop is configured to copy to RAMCard on startup. Configure a shortcut to copy to RAMCard "at boot". Launch DeskTop. Verify the shortcut's files were copied to RAMCard. Quit DeskTop. Re-launch DeskTop from the original startup disk. Eject the disk containing the shortcut. Run the shortcut. Verify that it launches correctly.
* Configure a system with a RAMCard, and ensure DeskTop is configured to copy to RAMCard on startup. Configure a shortcut to copy to RAMCard "at boot". Launch DeskTop. While the shortcut's files are copying to RAMCard, press Esc. Verify that when the DeskTop appears the Apple menu is not activated.
* Configure an Apple II+ system. Invoke `DESKTOP.SYSTEM` from a launcher (e.g. Bitsy Bye). Verify the launcher is restarted and does not crash or hang.
* Configure an Apple IIe system with no card in the Aux slot. Invoke `DESKTOP.SYSTEM` from a launcher (e.g. Bitsy Bye). Verify the launcher is restarted and does not crash or hang.
* Launch `BASIC.SYSTEM`. Save a file to `/RAM`. Invoke `DESKTOP.SYSTEM`. Verify that a warning is shown about `/RAM` not being empty. Press Esc. Verify that the ProDOS launcher is re-invoked. Verify that the file is still present in `/RAM`.
* Configure a system with a RAMCard, and ensure DeskTop is configured to copy to RAMCard on startup. Invoke `DESKTOP.SYSTEM`. After the progress bar advances a few ticks but before it gets more than halfway, press Escape. Wait for DeskTop to start. File > Quit. Invoke `DESKTOP.SYSTEM` again. Open the `SAMPLE.MEDIA` folder and select `APPLEVISION`. File > Open. Verify that it starts.
* Configure a system with a RAMCard, and ensure DeskTop is configured to copy to RAMCard on startup, but hasn't yet. Manually copy all DeskTop files to the RAMCard. Launch the copy of `DESKTOP.SYSTEM` on the RAMCard. Verify that it doesn't try to copy itself to that RAMCard.


# DeskTop

* Open a volume, open a folder, close just the volume window; re-open the volume, re-open the folder, ensure the previous window is activated.

* Open a window for a volume; open a window for a folder; close volume window; close folder window. Repeat 10 times to verify that the volume table doesn't have leaks.

* Start DeskTop with a hard disk and a 5.25" floppy mounted. Remove the floppy, and double-click the floppy icon, and dismiss the "The volume cannot be found." dialog. Verify that the floppy icon disappears, and that no additional icons are added.

* Launch DeskTop. Open a window for a removable disk. Quit DeskTop. Remove the disk. Restart DeskTop. Verify that 8 windows can be opened, and no render glitches occur.

* Launch DeskTop. Open a volume window with many items. Adjust the window so that the scrollbars are active. Drag a file icon slightly within the middle of the view, so that the scrollbars don't change. Verify that the scrollbars don't repaint/flicker.

* Launch DeskTop. Open a window with only one icon. Drag icon so name is to left of window bounds. Ensure icon name renders.

* Launch DeskTop. Open a volume window with icons. Drag leftmost icon to the left to make horizontal scrollbar activate. Click horizontal scrollbar so viewport shifts left. Verify dragged icon still renders.
* Launch DeskTop. Open a volume window with icons. Drag leftmost icon to the left to make horizontal scrollbar activate. Click horizontal scrollbar so viewport shifts left. Move window to the right so it overlaps desktop icons. Verify DeskTop doesn't lock up.
* Launch DeskTop. Open a volume window with icons. Resize the window so that the horizontal scrollbar is active. Move the window so the left edge of the scrollbar thumb is off-screen to the left. Click on the right arrow, and verify that the window scrolls correctly. Repeat for the page right region.

* Launch DeskTop. Open a window with a single icon. Move the icon so it overlaps the left edge of the window. Verify scrollbar appears. Hold scroll arrow. Verify icon scrolls into view, and eventually the scrollbar deactivates. Repeat with right edge.
* Launch DeskTop. Open a window with 11-15 icons. Verify scrollbars are not active.

* Launch DeskTop. Open a volume window with multiple icons but that do not require the scrollbars to be active. Drag the first icon over to the right so that it is partially clipped by the window's right or bottom edge. Verify that the appropriate scrollbars activate.

* Launch DeskTop. Open a folder using Apple menu (e.g. Control Panels) or a shortcut. Verify that the used/free numbers are non-zero.

* Launch DeskTop. Open a folder containing subfolders. Select all the icons in the folder. Double-click one of the subfolders. Verify that the selection is retained in the parent window, with the subfolder icons dimmed. Position a child window over top of the parent so it overlaps some of the icons. Close the child window. Verify that the parent window correctly shows only the previously opened folder as selected.

* Launch DeskTop. Open a window containing folders and files. Scroll the window so a folder is partially or fully outside the visual area (e.g. behind title bar, header, or scrollbars). Drag a file icon over the obscured part of the folder. Verify the folder doesn't highlight.
* Launch DeskTop. Open a window containing folders and files. Scroll the window so a folder is partially or fully outside the visual area (e.g. behind title bar, header, or scrollbars). Drag a file icon over the visible part of the folder. Verify the folder highlights but doesn't render past window bounds. Continue dragging over the obscured part of the folder. Verify that the folder unhighlights.

* Launch DeskTop. Open two windows containing folders and files. Drag a file icon from one window over a folder in the other window. Verify that the folder highlights. Drop the file. Verify that the file is copied or moved to the correct target folder.
* Launch DeskTop. Open two windows containing folders and files. Scroll one window so a folder is partially or fully outside the visual area (e.g. behind title bar, header, or scrollbars). Drag a file icon from the other window over the obscured part of the folder. Verify the folder doesn't highlight.
* Launch DeskTop. Open two windows containing folders and files. Scroll one window so a folder is partially or fully outside the visual area (e.g. behind title bar, header, or scrollbars). Drag a file icon from the other window over the visible part of the folder. Verify the folder highlights but doesn't render past window bounds. Continue dragging over the obscured part of the folder. Verify that the folder unhighlights.

* Launch DeskTop. Open a window containing folders and files. Open another window, for an empty volume. Drag an icon from the first to the second. Ensure no scrollbars activate in the target window.
* Launch DeskTop. Open a window containing folders and files, with no scrollbars active. Open another window. Drag an icon from the first to the second. Ensure no scrollbars activate in the source window.

* Launch DeskTop. Open two windows. Select a file in one window. Activate the other window by clicking its title bar. File > Duplicate. Enter a new name. Verify that the window with the selected file refreshes.
* Launch DeskTop. Open two windows. Select a file in one window. Activate the other window by clicking its title bar. File > Rename. Enter a new name. Verify that the icon is renamed.

* Configure a system with removable disks. (e.g. Virtual II OmniDisks) Launch DeskTop. Verify that volume icons are positioned without gaps (down from the top-right, then across the bottom right to left). Eject one of the middle volumes. Verify icon disappears. Insert a new volume. Verify icon takes up the vacated spot. Repeat test, ejecting multiple volumes verify that positions are filled in order (down from the top-right, etc).
* Configure a system with removable disks. (e.g. Virtual II OmniDisks) Launch DeskTop. Open a volume icon. Open a folder icon. Eject the disk using the hardware (or emulator). Verify that DeskTop doesn't crash and that both windows close.

* Launch DeskTop. Double-click on a file that DeskTop can't open (and where no `BASIS.SYSTEM` is present). Click OK in the "This file cannot be opened." alert. Double-click on the file again. Verify that the alert renders with an opaque background.

* Launch DeskTop. Open `/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789/ABCDEF123`. Try to copy a file into the folder. Verify that stray pixels do not appear in the top line of the screen.

* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Open `/TESTS`. Open `/TESTS/HUNDRED.FILES`. Try opening volumes/folders until there are less than 8 windows but more than 127 icons. Verify that the "A window must be closed..." dialog has no Cancel button.
* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Open `/TESTS`. Open `/TESTS/HUNDRED.FILES`. Close `/TESTS`. Open an empty volume and create multiple new folders. Verify that 127 icons can be shown.
* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Open windows bringing the total icons to 127. File > New Folder. Verify that a warning is shown and the window is closed. Repeat, with multiple windows open. Verify that everything repaints correctly, and that no volume or folder icon incorrectly displays as dimmed.
* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Open windows bringing the total icons to 127. Use File > Copy To... to copy a file into a directory represented by an open window. Verify that after the copy, a warning is shown, the window is closed, and that no volume or folder icon incorrectly displays as dimmed.
* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Open windows bringing the total icons to 127. Drag a file icon from another volume (to copy it) into an open window. Verify that after a copy, a warning is shown and the window is closed, and that no volume or folder icon incorrectly displays as dimmed.
* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Open windows bringing the total icons to 127. Drag a volume icon into an open window. Verify that after the copy, a warning is shown and the window is closed, and that no volume or folder icon incorrectly displays as dimmed.

* Use an emulator that supports dynamically inserting SmartPort disks, e.g. Virtual ][. Insert disks A, B, C, D in drives starting at the highest slot first, e.g. S7D1, S7D2, S5D1, S5D2. Launch DeskTop. Verify that the disks appear in order A, B, C, D. Eject the disks, and wait for DeskTop to remove the icons. Pause the emulator, and reinsert the disks in the same drives. Un-pause the emulator. Verify that the disks appear on the DeskTop in the same order. Eject the disks again, pause, and insert the disks into the drives in reverse order (A in S5D2, etc). Un-pause the emulator. Verify that the disks appear in reverse order on the DeskTop.
* Use an emulator that supports dynamically inserting SmartPort disks, e.g. Virtual ][. Launch DeskTop. Insert an unformatted SmartPort disk image. When prompted to format, click OK. Verify that the prompt for the name includes the correct slot and drive designation for the disk.

* Configure a system with two volumes of the same name. Launch DeskTop. Verify that an error is shown, and only one volume appears.

* Launch DeskTop. Select multiple volume icons (at least 4). Drag the bottom icon up so that the top two icons are completely off the screen. Release the mouse button. Drag the icons back down. Verify that while dragging, all icons have outlines, and when done dragging all icons reposition correctly.
* Launch DeskTop. Open a window with at least 3 rows of icons. Position the window at the top of the screen. Edit > Select All. Drag an icon from the bottom row so that the top icons end up completely off-screen. Release the mouse button. Drag the icons back down. Verify that all icons reposition correctly.
* Launch DeskTop. Open a window with multiple icons. Select multiple icons (e.g. 3). Start dragging the icons. Note the shape of the drag outlines. Drag over a volume icon. Verify that the drag outline does not become permanently clipped.
* Launch DeskTop. Open a window with multiple icons. Resize the window so some of the icons aren't visible without scrolling. Edit > Select All. Drag the icons. Verify that drag outlines are shown even for hidden icons.
* Launch DeskTop. Open `/TESTS/HUNDRED.FILES`. Edit > Select All. Start dragging the icons. Verify that the drag is not prevented.

* Launch DeskTop. Open a window for a volume icon. Open a folder within the window. Select the volume icon. Special > Check Drive. Verify that both windows are closed.
* Launch DeskTop. Open a window for a volume icon. Special > Check All Drives. Verify that all windows close, and that volume icons are correctly updated.
* Launch DeskTop. Special > Check All Drives. Verify that no error is shown.
* Launch DeskTop. Mount a new drive that will appear in the middle of the drive order. Special > Check All Drives. Verify that no new volumes overdraw old volumes.
* Launch DeskTop. Select a volume icon and Special > Eject Disk.... Special > Check All Drives. Verify that DeskTop doesn't hang or crash.
* Insert a ProDOS formatted disk in a Disk II drive. Launch DeskTop. Select the 5.25" disk icon. Replace the disk in the Disk II drive with a Pascal formatted disk. Special > Check Drive. When prompted to format it, click Cancel. Edit > Select All. Verify that DeskTop doesn't crash or hang.
* Launch DeskTop. Insert a Pascal formatted disk in a Disk II drive. Special > Check All Drives. Verify that a prompt to format the disk is shown.

* Launch DeskTop. Open a window. Create folders A, B and C. Open A, and create a folder X. Open B, and create a folder Y. Drag A and B into C. Double-click on X. Verify it opens. Double-click on Y. Verify it opens. Open C. Double-click on A. Verify that the existing A window activates. Double-click on B. Verify that the existing B window activates.

* Launch DeskTop. Open a volume window containing a folder. Open the folder window. Note that the folder icon is dimmed. Close the volume window. Open the volume window again. Verify that the folder icon is dimmed.
* Launch DeskTop. Open a volume window. In the volume window, create a new folder F1 and open it. Note that the F1 icon is dimmed. In the volume window, create a new folder F2. Verify that the F1 icon is still dimmed.
* Launch DeskTop. Open a volume window containing a file and a folder. Open the folder window. Drag the file to the folder icon (not the window). Verify that the folder window activates and updates to show the file.

* Launch DeskTop. Open a volume containing no files. Verify that the default minimum window size is used - about 170px by 50px not counting title/scrollbars.

* Launch DeskTop. Open two windows. Attempt to drag the inactive window by dragging its title bar. Verify that the window activates and the drag works.
* Launch DeskTop. Open two windows. Click on an icon in the inactive window. Verify that the window activates and that the icon is selected.
* Launch DeskTop. Open two volume windows. Click and drag in the inactive window without selecting any icons. Verify that the window activates and that the drag rectangle appears, and that when the button is released the volume icon is selected.
* Launch DeskTop. Open two volume windows. Click in the inactive window without selecting any icons. Verify that the window activates and the volume icon is selected.
* Launch DeskTop. Open a volume window. Click on the desktop to clear selection. Click in an empty area within the window. Verify that the volume icon is selected.
* Launch DeskTop. Open a volume window. Select a file icon. Click in an empty area within the window. Verify that the volume icon is selected.

* Launch DeskTop. Select a volume icon. Drag it over an empty space on the desktop. Release the mouse button. Verify that the icon is moved.
* Launch DeskTop. Select a volume icon. Drag it over an empty space on the desktop. Without releasing the mouse button, press the Escape key. Verify that the drag is canceled and the icon does not move.
* Launch DeskTop. Select a volume icon. Drag it over an empty space on the desktop. Hold either Apple key or both Apple keys and release the mouse button. Verify that the drag is canceled and the icon does not move.
* Launch DeskTop. Select a volume icon. Drag it over another icon on the desktop, which should highlight. Without releasing the mouse button, press the Escape key. Verify that the drag is canceled, the target icon is unhighlighted, and the dragged icon does not move.
* Launch DeskTop. Select a file icon. Drag it over an empty space in the window. Without releasing the mouse button, press the Escape key. Verify that the drag is canceled and the icon does not move.
* Launch DeskTop. Select a file icon. Drag it over a folder icon, which should highlight. Without releasing the mouse button, press the Escape key. Verify that the drag is canceled, the target icon is unhighlighted, and the dragged icon does not move.
* Launch DeskTop. Clear selection. Hold both Open-Apple and Solid-Apple and start to drag a volume icon. Verify that the drag outline of the volume is shown.

* Launch DeskTop. Open `/TESTS/FOLDER`. Start dragging `FLE` and do not release the button. Drag it over then off `SUBFOLDER`. Verify the folder highlights/unhighlights. Drag it over then off a volume icon. Verify that the volume icon highlights/unhighlights. Drag it over the folder icon again. Verify that the folder highlights.

* Repeat the following:
  * For these permutations, as the specified window area:
    * Title bar
    * Scroll bars
    * Resize box
    * Header (items/in disk/available)
  * Verify:
    * Launch DeskTop. Open a window with a file icon. Drag the icon so that the mouse pointer is over the same window's specified area. Release the mouse button. Verify that the icon does not move.
    * Launch DeskTop. Open two windows for different volumes. Drag an icon from one window over the specified area of the other window. Release the mouse button. Verify that the file is copied to the target volume.

* Launch DeskTop. Open `/TESTS/FILE.TYPES`. Select `ROOM.A2FC`. File > Open. Press Escape. Apple Menu > Calculator (or any other DA). Verify that the DA launches correctly.

* Launch DeskTop. Apple Menu > About Apple II DeskTop. Click anywhere on the screen. Verify that the dialog closes.
* Launch DeskTop. Apple Menu > About Apple II DeskTop. Press any non-modifier key screen. Verify that the dialog closes.

* Launch DeskTop. Open `/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789`. Rename the `/TESTS` volume to `/TESTSXXXXXXXXXX` so that the total path length of the innermost files would be longer than 64 characters. Repeat the following operations, and verify that an error is shown and DeskTop doesn't crash or hang:
  * Select the `ABCDEF123` folder. File > Open.
  * Select the `ABCDEF123` folder. File > Get Info.
  * Select the `ABCDEF123` folder. File > Rename
  * Select the `ABCDEF123` folder. File > Duplicate
  * Select the `ABCDEF123` folder. File > Copy To... (and pick a target)
  * Select the `ABCDEF123` folder. Shortcuts > Add a Shortcut...
  * Drag a file icon onto the `ABCDEF123` folder.
  * Drag the `ABCDEF123` folder to another volume.
  * Drag the `ABCDEF123` folder to the Trash.
  * Repeat the previous cases, but with `LONGIMAGE` file.
* Copy `MODULES/SHOW.IMAGE.FILE` to the `APPLE.MENU` folder. Restart. Open `/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789`. Rename the `/TESTS` volume to `/TESTSXXXXXXXXXX`. Select the `LONGIMAGE` file. Apple Menu > Show Image File. Verify that an alert is shown.
* Open `/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789`. Copy `APPLE.MENU/KEY.CAPS` to the  folder. Rename the `/TESTS` volume to `/TESTSXXXXXXXXXX`. Select the copy of `KEY.CAPS`. File > Open. Verify that an alert is shown.

* From `BASIC.SYSTEM`, create `/VOL/A/B` on an otherwise empty volume. Launch DeskTop. Open `/VOL/A`. Close `/VOL`. Open another volume with multiple icons. Verify that the window for `A` still renders the icon for `B` correctly.

* Repeat the following test cases for these operations: Copy, Move, Delete:
  * Select multiple files. Start the operation. During the initial count of the files, press Escape. Verify that the count is canceled and the progress dialog is closed, and that the window contents do not refresh.
  * Select multiple files. Start the operation. After the initial count of the files is complete and the actual operation has started, press Escape. Verify that the operation is canceled and the progress dialog is closed, and that (apart from the source window for Copy) the window contents do refresh.

* Open `/TESTS/HUNDRED.FILES`, without resizing the window. Scroll up and down by one tick, by one page, and to the top/bottom. Verify that such operations scroll by an integral number of icons, i.e. the last row of labels are always the same distance from the bottom of the window.

* Launch DeskTop. Open a volume window with enough icons that a scrollbar appears. Click on an active part of the scrollbar. Verify that the scrollbar responds immediately, not after the double-click detection delay expires.
* Launch DeskTop. Open a volume window where the vertical and horizontal scrollbars are inactive. Click on each inactive scrollbar. Verify nothing happens.

* Open `TESTS/FILE.TYPES`. Verify that an icon appears for the `TEST08` file.
* Open `TESTS/FILE.TYPES`. Verify that an icon appears for the `TEST01` file.


## Selection

* Launch DeskTop. Open a window. Select a file icon. Drag a selection rectangle around another file icon in the same window. Verify that the initial selection is cleared and only the second icon is selected.
* Launch DeskTop. Select a volume icon. Drag a selection rectangle around another volume icon. Verify that the initial selection is cleared and only the second icon is selected.

* Repeat the following cases with these modifiers: Open-Apple, Shift (on a IIgs), Shift (on a Platinum IIe):
  * Launch DeskTop. Click on a volume icon. Hold modifier and click a different volume icon. Verify that selection is extended.
  * Launch DeskTop. Select two volume icons. Hold modifier and click on the desktop, not on an icon. Verify that selection is not cleared.
  * Launch DeskTop. Select one or more volume icons. Hold modifier and click a selected volume icon. Verify that it is deselected.
  * Launch DeskTop. Hold modifier and double-click on a non-selected volume icon. Verify that it highlights then unhighlights, and does not open.
  * Launch DeskTop. Select a volume icon. Wait a few seconds for the double-click timer to expire. Hold modifier and double-click the selected volume icon. Verify that it unhighlights then highlights, and does not open.
  * Launch DeskTop. Select a volume icon. Hold modifier down and drag a selection rectangle around another volume icon. Verify that both are selected.
  * Launch DeskTop. Open a volume containing files. Click on a file icon. Hold modifier and click a different file icon. Verify that selection is extended.
  * Launch DeskTop. Open a volume containing files. Select two file icons. Hold modifier and click on the window, not on an icon. Verify that selection is not cleared.
  * Launch DeskTop. Open a window. Select an icon. Hold modifier and double-click an empty spot in the window (not on an icon). Verify that the selection is not cleared.
  * Launch DeskTop. Open a window. Select an icon. Hold modifier down and drag a selection rectangle around another icon. Verify that both are selected.
  * Launch DeskTop. Open a volume window. Select two file icons. Hold modifier and click a selected file icon. Verify that it is deselected.
  * Launch DeskTop. Open a volume window. Select one file icon. Hold modifier and click the selected file icon. Verify that it is deselected, and that the volume icon does not become selected.
  * Launch DeskTop. Open a window. Hold modifier and double-click on a non-selected file icon. Verify that it highlights then unhighlights, and does not open.
  * Launch DeskTop. Open a window. Select a file icon. Wait a few seconds for the double-click timer to expire. Hold modifier and double-click the selected file icon. Verify that it unhighlights then highlights, and does not open.
  * Launch DeskTop. Open a volume window. Hold modifier, and drag-select icons in the window. Release the modifier. Verify that the volume icon is no longer selected. Click an empty area in the window to clear selection. Verify that the selection in the window clears, and that the volume icon becomes selected.
  * Launch DeskTop. Open a volume window. Select a folder icon. Hold modifier, and double-click another folder icon. Verify that selection toggles on the second folder, and no folders are opened.

* Launch DeskTop. Open two windows containing file icons. Clear selection by clicking on the desktop. Run these cases:
  * Click on an icon in the inactive window. Verify that the icon highlights on mouse down, and the window activates on mouse up.
  * Drag an icon within in the inactive window. Verify that the icon moves and the window does not activate until mouse-up.
  * Drag an icon from the inactive window to a volume icon that does not have an open window. Verify that the active window remains active.
  * Open a volume icon so a third window appears. Click the first window to activate it. Drag an icon from the second window to the volume icon. Verify that the third window activates.

* Launch DeskTop. Open two windows containing file icons. Clear selection by clicking on the desktop. Repeat the following cases with these modifiers: Open-Apple, Shift (on a IIgs), Shift (on a Platinum IIe):
  * Select an icon. Activate the other window by clicking on the title bar. Hold modifier and click another icon in the inactive window. Verify that the icon highlights on mouse down, and the window activates on mouse up, and both icons are selected.
  * Select an icon. Activate the other window by clicking on the title bar. Hold modifier and click the selected icon in the inactive window. Verify that the icon unhighlights and the window activates on mouse down.
  * Select an icon. Activate the other window by clicking on the title bar. Hold modifier and drag another icon within the inactive window. Verify that the icon highlights and both icons are dragged, and that the window activates on mouse down.

* Launch DeskTop. Click on a volume icon. Hold Solid-Apple and click on a different volume icon. Verify that selection changes to the second icon.
* Launch DeskTop. Open a volume containing files. Click on a file icon. Hold Solid-Apple and click on a different file icon. Verify that selection changes to the second icon.

* Launch DeskTop. Open a volume window. Select an icon. Click in the header area (items/use/etc). Verify that selection is not cleared.

* Launch DeskTop. Open a volume window. Adjust the window so it is small and roughly centered on the screen. In the middle of the window, start a drag-selection. Move the mouse cursor in circles around the outside of the window and within the window. Verify that one corner of the selection rectangle remains fixed where the drag-selection was started.

* Launch DeskTop. Open two windows for two different volumes. Select an icon in one window. Click on the title bar, scroll bars, or header of the other window to activate it. Verify that the icon in the first window is still selected. Click on the title bar, scroll bar or header of the active window. Verify that the icon in the first window is still selected. Click on the content area of the active window. Verify that the icon is no longer selected, and the window's corresponding volume icon becomes selected when the mouse button is released.
* Launch DeskTop. Open a window for a volume icon and a window for a folder icon. Click in the content area of the volume icon's window. Verify that the volume icon is selected. Click in the content area of the folder icon's window. Verify that the folder icon is selected.
* Launch DeskTop. Open a window for a volume icon and a window for a folder icon within that volume. Close the window for the volume icon. Click in the content area of the folder icon's window. Verify that the volume icon is selected.

* Launch DeskTop. Open a window. Select a file icon. Apple Menu > Control Panels. Verify that the previously selected file is no longer selected.

* Launch DeskTop, ensuring no windows are open. Edit > Select All. Verify that the volume icons are selected.
* Launch DeskTop. Open a window. Click a volume icon. Edit > Select All. Verify that volume icons are selected.
* Launch DeskTop. Open a window. Click a volume icon. Click on the open window's title bar. Edit > Select All. Verify that icons within the window are selected. Repeat for the window's header and scroll bars.
* Launch DeskTop. Open a window. Click a volume icon. Click an empty area within the window. Edit > Select All. Verify that icons within the window are selected.
* Launch DeskTop. Open a window. Click a volume icon. Click an icon within the window. Edit > Select All. Verify that icons within the window are selected.
* Launch DeskTop. Open a window. Click a volume icon. Click an empty space on the desktop. Edit > Select All. Verify that volume icons are selected.
* Launch DeskTop. Open a window. Click a file icon. Click an empty space on the desktop. Edit > Select All. Verify that volume icons are selected.

* Launch DeskTop. Open a volume window. Drag a selection rectangle so that it covers only the top row of pixels of an icon. Verify that the icon is selected.


## Repaints

* Open a window. Position two icons so one overlaps another. Select both. Drag both to a new location. Verify that the icons are repainted in the new location, and erased from the old location.
* Open a window. Position two icons so one overlaps another. Select only one icon. Drag it to a new location. Verify that the the both icons repaint correctly.

* Position a volume icon in the middle of the DeskTop. Incrementally move a window so that it obscures all 8 positions around it (top, top right, right, etc). Select and deselect the icon at each position. Ensure the icon repaints fully, and no part of the window is over-drawn.
* Position a window partially overlapping desktop icons. Select overlapped desktop icons. Drag icons a few pixels to the right. Verify that window is not over-drawn.
* Position two windows so that the right edges are exactly aligned, and the windows vertically overlap by several pixels. Activate the upper window. Drag a floppy disk volume icon so that it is partially occluded by the bottom-right of the upper window. Verify that the visible parts of the icon repaint correctly and that DeskTop does not hang.
* Position two windows so that the left edges are exactly aligned, and the windows vertically overlap by several pixels. Activate the upper window. Drag a floppy disk volume icon so that it is partially occluded by the bottom-left corner of the upper window. Verify that the visible parts of the icon repaint correctly and that DeskTop does not hang.
* Position two windows so that the bottom-right corner of one overlaps the top-left corner of the other by several few pixels. Drag a floppy disk volume icon so that it should show on both sides of overlap. Verify that the visible parts of the icon repaint correctly.
* Position a window so that the right edge overlaps volume icons. Select the volume icons. Clear selection by clicking on the desktop. Verify that the right edge of the window is not overdrawn.
* Open five volume windows containing many files so that the windows have large initial sizes. Drag the top-most so that the right edge aligns with another window's right edge and overlaps a volume icon. Drag another window that was previously overlapping the same icon so that the right edge aligns with the other windows. Verify that the volume icons repaint correctly and that the system does not hang.

* Repeat the following cases with these modifiers: Open-Apple, Shift (on a IIgs), Shift (on a Platinum IIe):
  * Launch DeskTop. Open a volume window with many icons. Click on a file icon to select it. Modifier-click the icon to deselect it. Drag-select on the desktop covering a large area. Verify that no file icons are erroneously painted.
  * Launch DeskTop. Open a volume window with many icons. Modifier-click on a file icon to select it. Drag-select on the desktop covering a large area. Verify that no file icons are erroneously painted.

* Launch DeskTop. Open a volume window. Click in the header area (items/use/etc). On the desktop, drag a selection rectangle around the window. Verify that nothing is selected, and that file icons don't paint onto the desktop.
* Launch DeskTop. Open a volume window. Adjust the window so that the scrollbars are active. Scroll the window. On the desktop, drag a selection rectangle around the window. Verify that nothing is selected, and that file icons don't paint onto the desktop.

* Launch DeskTop. Open two windows. Select a file in one window. Activate the other window and move it so that it partially obscures the selected file (e.g. with the title bar). File > Rename. Enter a new name. Verify that the active window is not mis-painted.

* Launch DeskTop. Open 3 windows. Close the top one. Verify that the repaint is correct.
* Launch DeskTop. Close all windows. Press an arrow key multiple times. Verify that only one volume icon is highlighted at a time.

* For the following cases, "obscure a window" means to move a window to the bottom of the screen so that only the title bar is visible:
  * Launch DeskTop. Open a window with icons. View > by Name. Obscure the window. View > as Icons. Verify that the window contents don't appear on the desktop. Move the window so the contents are visible. Verify that it contains icons.
  * Launch DeskTop. Open a window with icons. Obscure the window. View > by Name. Verify that the window contents don't appear on the desktop. Move the window so the contents are visible. Verify that the contents display as a list.
  * Launch DeskTop. Open a window with at least two icons. Select the first icon. Obscure the window. Press the right arrow key. Verify that the icons don't appear on the desktop.
  * Launch DeskTop. Open a window with icons. Obscure the window. Edit > Select All. Verify that the icons don't appear on the desktop.
  * Launch DeskTop. Open a window with icons. Edit > Select All. Obscure the window. Click on the desktop to clear selection. Verify that the icons don't appear on the desktop.
  * Launch DeskTop. Open a window with folder icons. Open a second window from one of the folders. Verify that the folder icon in the first window is dimmed. Obscure the first window. Close the second window. Verify that the folder icon doesn't appear on the desktop.
  * Launch DeskTop. Open a window with icons. Select (but don't open) a folder. Obscure the window. File > Open. Verify that the folder icon does not appear on the desktop.
  * Launch DeskTop. Open `/TESTS`. Select (but don't open) `TOO.MANY.FILES`. Obscure the window. File > Open. Verify that the folder icon does not appear on the desktop.
  * Launch DeskTop. Open a window. Obscure the window. File > New Folder, enter a name. Verify that the folder icon doesn't appear on the desktop.
  * Launch DeskTop. Open a window with icons. Obscure the window. File > Quit. Relaunch DeskTop. Verify that the restored window's icons don't appear on the desktop, and that the menu bar is not glitched.
  * Launch DeskTop. Open two windows with icons. Obscure one window. Click on the other window's title bar. Click on the obscured window's title bar. Verify that the window contents don't repaint on the desktop.
  * Launch DeskTop. Open two windows with icons. Activate a window, View > by Name, and then obscure the window. Click on the other window's title bar. Click on the obscured window's title bar. Verify that the window contents don't repaint on the desktop.
  * Launch DeskTop. Open a window with icons. Select an icon. Obscure the window. File > Rename, enter a new name. Verify that the icon does not paint on the desktop.

* Launch DeskTop. Open a window. Try to move the window so that the title bar intersects the menu bar. Verify that the window ends up positioned partially behind the menu bar.
* Launch DeskTop. Open two windows. Move them both so their title bars are partially behind the menu bar. Apple+Tab between the windows. Verify that the title bars do not mispaint on top of the menu bar.

* Launch DeskTop. Drag a volume icon so that it overlaps the menu bar, but the mouse pointer is below the menu bar. Release the mouse button. Verify that the icon doesn't paint on top of the menu bar. Edit > Select All. Verify that the icon doesn't repaint on top of the menu bar.

* Launch DeskTop. Open a window containing many folders. Select up to 7 folders. File > Open. Verify that as windows continue to open, the originally selected folders don't mispaint on top of them. (This will be easier to observe in emulators with acceleration disabled.)

* Launch DeskTop. Open a window containing multiple icons. Drag-select several icons. Click on the desktop to clear selection. Click on a volume icon. Click elsewhere on the desktop. Verify the icon isn't mispainted.
* Launch DeskTop. Open a window containing multiple icons. Drag-select several icons. Click on the desktop to clear selection. Click on a volume icon. File > Rename. Enter a new valid name. Verify that no alert is shown.

* Launch DeskTop. Open a window. Create a folder with a short name (e.g. "A"). Open the folder. Drag the folder's window so it covers just the left edge of the icon. Drag it away. Verify that the folder repaints. Repeat for the right edge.

* Launch DeskTop. Open a volume window containing a folder. Open the folder. Verify that the folder appears as dimmed. Position the window partially over the dimmed folder. Move the window to reveal the whole folder. Verify that the folder is repainted cleanly (no visual glitches).
* Launch DeskTop. Open a volume window containing two folders (1 and 2). Open both folder windows, and verify that both folder icons are dimmed. Position folder 1's window partially covering folder 1's and folder 2's icons. Activate folder 1's window, and close it. Verify that the visible portions of folder 1 repaint (not dimmed) and folder 2 repaint (dimmed).
* Disable any acceleration. Launch DeskTop. Open a volume window containing a folder with a long name. Double-click the folder to open it. Verify that when the icon is painting as dimmed that the dimming effect doesn't extend past the bounding box of the icon, even temporarily.

* Launch DeskTop. Apple Menu > Control Panels. Close the window by clicking on the close box. Verify nothing mis-paints.

* Launch DeskTop. Open a window containing a folder. Open the folder window. Position the folder window so that it partially covers the "in disk" and "available" entries in the lower window. Drag a large file into the folder window. Verify that the "in disk" and "available" values update in the folder window. Drag the folder window away. Verify that the parent window "in disk" and "available" values repaint with the old values, and without visual artifacts. Activate the parent window. Verify that the "in disk" and "available" values now update.

* Launch DeskTop. Open a volume window with icons. Move window so only header is visible. Verify that DeskTop doesn't render garbage or lock up.

* Launch DeskTop. Open two volume windows with icons. Move top window down so only header is visible. Click on other window to activate it. Verify that the window header does not disappear.

* Launch DeskTop. Position a volume icon near the center of the screen. Drag another volume onto it. Verify that after the copy dialog closes, the volume icon is still visible.
* Launch DeskTop. Position a volume icon near the center of the screen. Open the volume icon, and move/size the window to ensure the volume icon is visible. Drag another volume onto the window. Verify that after the copy dialog closes, the volume icon is still visible.
* Launch DeskTop. Position a volume icon near the center of the screen. Open the volume icon, and move/size the window to ensure the volume icon is visible. Drag another volume onto the window. Drag the same volume icon onto the window. Cancel the copy. Verify that after the copy dialog closes, the volume icon is still visible.

* Launch DeskTop. Position a volume icon near the center of the screen. Open a second volume icon, and move/size the window to ensure the first volume icon is visible. Drag a file icon onto the first volume icon. Verify that after the copy dialog closes, the volume icon is still visible.
* Launch DeskTop. Position a volume icon near the center of the screen. Open the volume icon, and move/size the window to ensure the volume icon is visible. Open a second volume icon, and move/size the window to ensure the first volume icon is visible. Drag a file icon from the second window into the first window. Verify that after the copy dialog closes, the volume icon is still visible.
* Launch DeskTop. Position a volume icon near the center of the screen. Open the volume icon, and move/size the window to ensure the volume icon is visible. Open a second volume icon, and move/size the window to ensure the first volume icon is visible. Drag a file icon from the second window into the first window. Repeat the drag, and cancel the copy dialog. Verify that after the copy dialog closes, the volume icon is still visible.
* Launch DeskTop. Position a volume icon near the center of the screen. Open the volume icon, and move/size the window to ensure the volume icon is visible. Drag a file icon to the trash. Verify that after the delete dialog closes, the volume icon is still visible.

* Launch DeskTop. Open two windows. In the first window, position two icons so they overlap. Select the first icon. Verify that it draws "on top" of the other icon. Activate the other window without changing selection. Drag it over the icons. Drag it off the icons. Verify that the selected icon is still "on top". Hold Open-Apple and click the selected icon to deselect it. Verify that it draws "on top" of the other icon. Activate the other window without changing selection. Drag it over the icons. Drag it off the icons. Verify that the previously selected icon is still "on top". Repeat the above tests with the other icon.

* Launch DeskTop. Open a volume. Open a folder within the volume. Activate the first window. Special > Check All Drives. Verify that the icons are erased and repaint properly.

* Launch DeskTop. Open a volume. Open a folder. Drag the folder window so that it obscures the top-most edge of an icon in the volume window. Drag the folder away. Verify that the icon in the volume window repaints.

* Launch DeskTop. Open a volume. Drag the window so that it partially covers some volume icons. Drag the window to the bottom of the screen so that only the top of the title bar is visible. Verify that the volume icons repaint correctly.
* Launch DeskTop. Open a volume containing a file icon. Select the file icon. Drag the window to the bottom of the screen so that only the top of the title bar is visible. Verify that the file icon doesn't mispaint onto the desktop.


## Menus

* Launch DeskTop. Clear the selection (e.g. by clicking on the DeskTop). Verify that:
  * Special > Eject Disk and Special > Check Drive are disabled.
  * File > Duplicate and Special > Make Alias are disabled.
  * File > Rename and Edit > Cut/Copy/Paste/Clear are disabled.
  * File > Delete is disabled.
  * File > Open, File > Get Info, and File > Copy To... are disabled.
  * Special > Show Original is disabled.
* Launch DeskTop. Select only the Trash icon. Verify that:
  * Special > Eject Disk and Special > Check Drive are disabled.
  * File > Duplicate and Special > Make Alias are disabled.
  * File > Rename and Edit > Cut/Copy/Paste/Clear are disabled.
  * File > Delete is disabled.
  * File > Open, File > Get Info, and File > Copy To... are disabled.
  * Special > Show Original is disabled.
* Launch DeskTop. Select a volume. Verify that:
  * Special > Eject Disk and Special > Check Drive are enabled.
  * File > Duplicate and Special > Make Alias are disabled.
  * File > Rename and Edit > Cut/Copy/Paste/Clear are enabled.
  * File > Delete is disabled.
  * File > Open, File > Get Info, and File > Copy To... are enabled.
  * Special > Show Original is disabled.
* Launch DeskTop. Select two volume icons. Verify that:
  * Special > Eject Disk and Special > Check Drive are enabled.
  * File > Duplicate and Special > Make Alias are disabled.
  * File > Rename and Edit > Cut/Copy/Paste/Clear are disabled.
  * File > Delete is disabled.
  * File > Open, File > Get Info, and File > Copy To... are enabled.
  * Special > Show Original is disabled.
* Launch DeskTop. Select a volume icon and the Trash icon. Verify that:
  * Special > Eject Disk and Special > Check Drive are enabled.
  * File > Duplicate and Special > Make Alias are disabled.
  * File > Rename and Edit > Cut/Copy/Paste/Clear are disabled.
  * File > Delete is disabled.
  * File > Open, File > Get Info, and File > Copy To... are enabled.
  * Special > Show Original is disabled.
* Launch DeskTop. Open a volume window, and select a single file which is not an alias. Verify that:
  * Special > Eject Disk and Special > Check Drive are disabled.
  * File > Duplicate and Special > Make Alias are enabled.
  * File > Rename and Edit > Cut/Copy/Paste/Clear are enabled.
  * File > Delete is enabled.
  * File > Open, File > Get Info, and File > Copy To... are enabled.
  * Special > Show Original is disabled.
* Launch DeskTop. Open a volume window, and select a single file which is an alias. Verify that:
  * Special > Eject Disk and Special > Check Drive are disabled.
  * File > Duplicate and Special > Make Alias are enabled.
  * File > Rename and Edit > Cut/Copy/Paste/Clear are enabled.
  * File > Delete is enabled.
  * File > Open, File > Get Info, and File > Copy To... are enabled.
  * Special > Show Original is enabled.
* Launch DeskTop. Open a volume window, and select two files. Verify that:
  * Special > Eject Disk and Special > Check Drive are disabled.
  * File > Duplicate and Special > Make Alias are disabled.
  * File > Rename and Edit > Cut/Copy/Paste/Clear are disabled.
  * File > Delete is enabled.
  * File > Open, File > Get Info, and File > Copy To... are enabled.
  * Special > Show Original is disabled.
* Launch DeskTop. Close all windows. Verify that File > New Folder, File > Close, File > Close All, and everything in the View menu are disabled.
* Launch DeskTop. Open a window. Verify that File > New Folder, File > Close, File > Close All, and everything in the View menu are enabled.
* Launch DeskTop. Open a window for a removable disk. Quit DeskTop. Remove the disk. Restart DeskTop. Open a different volume's window. Close it. Open it again. Verify that items in the File menu needing a window (New Folder, Close, etc) are correctly enabled.


## Open

* Open a volume with double-click.
* Open a directory with double-click.
* Open a text file with double-click.

* Open a volume with File > Open.
* Open a directory with File > Open.
* Open a text file with File > Open.

* Launch DeskTop. Select a volume. File > Open. Verify that the volume icon is dimmed but still selected.
* Launch DeskTop. Double-click a volume. Verify that the volume icon is still selected.
* Launch DeskTop. Select a folder. File > Open. Verify that the folder icon is dimmed but still selected.
* Launch DeskTop. Double-click a folder. Verify that the folder icon is still selected.
* Launch DeskTop. Open a window containing a folder. Position the window so that the folder icon will not be obscured when opened. Select the folder. File > Open. Verify that the folder icon is dimmed but still selected.
* Launch DeskTop. Open a window containing a folder. Position the window so that the folder icon will not be obscured when opened. Double-click the folder. Verify that the folder icon is dimmed but still selected.

* Launch DeskTop. Select a volume icon. Open it. Verify that the open animation starts at the icon location. (This will be easier to observe in emulators with acceleration disabled.)

* Launch DeskTop. Close all windows. Open an empty volume (e.g. `/RAMA`). Repeat File > New Folder... 7 times, accepting the default names (New.Folder through New.Folder.7). Edit > Select All. File > Open. File > New Folder. Verify that the new folder is created within New.Folder.7 and no alert appears.

* Launch DeskTop. Manually (not via DeskTop) eject the startup disk. Select the startup disk icon. File > Open. Verify that the alert displays correctly.

* Configure a system with `/HD1`, `/HD1/FOLDER1`, and `/HD2`. Launch DeskTop. Open `/HD1`. Open `/HD1/FOLDER1`. Close `/HD1`. Open `/HD2`. Re-open `/HD1`. Re-open `/HD/FOLDER1`. Verify that the previously opened window is activated.

* Launch DeskTop. Open a window and select multiple folder icons. File > Open. Verify that the folders open, and that the icons remain selected and become dimmed.


## Close Window

* Open two windows. Click the close box on the active window. Verify that only the active window closes.
* Open two windows. Open the File menu, then press Solid-Apple+W. Verify that only the top window closes. Repeat with Caps Lock off.
* Open two windows. Open the File menu, then press Open-Apple+W. Verify that only the top window closes. Repeat with Caps Lock off.

* Launch DeskTop. Select two volume icons. Double-click one of the volume icons. Verify that two windows open.
* Launch DeskTop. Open a window. Select two folder icons. Double-click one of the folder icons. Verify that two windows open.
* Launch DeskTop. Open a window. Select a folder icon. Open the File menu, then press Solid-Apple+O. Verify that the folder opens, and the original window remains open. Repeat with Caps Lock off.
* Launch DeskTop. Open a window. Select a folder icon. Open the File menu, then press Open-Apple+O. Verify that the folder opens, and the original window remains open. Repeat with Caps Lock off.

* Launch DeskTop. Open a window. Click the close box. Verify that the close animation runs. Open a window. File > Close. Verify that the close animation runs.

* Launch DeskTop. Open a volume icon. Open a folder icon. Activate the volume window. Click the close box. Verify that the close animation doesn't leave garbage in the menu bar.

* Launch DeskTop. Open a window. Click the close box. Verify that the close animation does not leave a stray rectangle on the screen.

* Launch DeskTop. Open `/TESTS/FOLDER`. Close the `TESTS` window. Close the `FOLDER` window. Verify that it animates into the volume icon, which becomes selected.
* Launch DeskTop. Open `/TESTS/FOLDER/SUBFOLDER`. Close the `SUBFOLDER` window. Verify that it animates into the `SUBFOLDER` icon in the `FOLDER` window and becomes selected.
* Launch DeskTop. Open `/TESTS/FOLDER/SUBFOLDER`. Close the `TESTS` window. Close the `FOLDER` window. Verify that it animates into the volume icon, which becomes selected.


## Open Then Close

* Launch DeskTop. Open a window. Hold Solid-Apple and double-click a folder icon. Verify that the folder opens, and that the original window closes.
* Launch DeskTop. Open a window. Select a folder icon. Hold Solid-Apple and select File > Open. Verify that the folder opens, and that the original window closes.
* Launch DeskTop. Open a window. Select a folder icon. Hold Open-Apple and select File > Open. Verify that the folder opens, and that the original window closes.
* Launch DeskTop. Open a window. Select a folder icon. Press Open-Apple+Solid-Apple+O. Verify that the folder opens, and that the original window closes. Repeat with Caps Lock off.
* Launch DeskTop. Open a window. Select a folder icon. Press Open-Apple+Solid-Apple+Down. Verify that the folder opens, and that the original window closes.
* Launch DeskTop. Open a window. Select a folder icon. Open the File menu, then press Open-Apple+Solid-Apple+O. Verify that the folder opens, and the original window closes. Repeat with Caps Lock off.
* Launch DeskTop. Ensure nothing is selected. Press Open-Apple+Solid-Apple+O. Verify that nothing happens. Repeat with Caps Lock off.
* Launch DeskTop. Ensure nothing is selected. Press Open-Apple+Solid-Apple+Down. Verify that nothing happens.


## Open Enclosing Folder

* Launch DeskTop. Open a volume window. Open a folder. Close the volume window. Press Open-Apple+Up. Verify that the volume window re-opens, and that the folder icon is selected. Press Open-Apple+Up again. Verify that the volume icon is selected.
* Launch DeskTop. Open a volume window. Open a folder. Press Open-Apple+Up. Verify that the volume window is activated, and that the folder icon is selected. Press Open-Apple+Up again. Verify that the volume icon is selected.
* Launch DeskTop. Open a volume window. Open a folder. Activate the volume window. Switch the window's view to by Name. Activate the folder window. Press Open-Apple+Up. Verify that the volume window is activated, and that the folder icon is selected. Press Open-Apple+Up again. Verify that the volume icon is selected.

* Launch DeskTop. Open a volume window with multiple files. Open a folder. Press Open-Apple+Up. Verify that the volume window is shown and the folder is selected. Press Right Arrow. Verify that only a single icon shows as selected.
* Launch DeskTop. Open a volume window with multiple files. Open a folder. Close the volume window. Press Open-Apple+Up. Verify that the volume window is shown and the folder is selected. Press Right Arrow. Verify that only a single icon shows as selected.


## Open Enclosing Folder Then Close

* Launch DeskTop. Open a volume window. Open a folder. Close the volume window. Press Open-Apple+Solid-Apple+Up. Verify that the volume window re-opens, and that the folder window closes, and that the folder icon is selected. Press Open-Apple+Solid-Apple+Up again. Verify that the volume window closes, and the volume icon is selected.
* Launch DeskTop. Open a volume window. Open a folder. Press Open-Apple+Solid-Apple+Up. Verify that the volume window is activated, and that the folder window closes, and that the folder icon is selected. Press Open-Apple+Solid-Apple+Up again. Verify that the volume window closes, and that the volume icon is selected.
* Launch DeskTop. Open a volume window. Open a folder. Activate the volume window. Switch the window's view to by Name. Activate the folder window. Press Open-Apple+Solid-Apple+Up. Verify that the volume window is activated, and that the folder window closes, and that the folder icon is selected. Press Open-Apple+Solid-Apple+Up again. Verify that the volume window closes, and that the volume icon is selected.

* Launch DeskTop. Open a volume window with multiple files. Open a folder. Press Open-Apple+Solid-Apple+Up. Verify that the folder window is closed, the volume window is shown, and the folder is selected. Press Right Arrow. Verify that only a single icon shows as selected.
* Launch DeskTop. Open a volume window with multiple files. Open a folder. Close the volume window. Press Open-Apple+Solid-Apple+Up. Verify that the folder window is closed, the volume window is shown, and the folder is selected. Press Right Arrow. Verify that only a single icon shows as selected.


## Close All

* Repeat the following case with these modifiers: Open-Apple, Solid-Apple:
  * Open two windows. Hold modifier and click the close box on the active window. Verify that all windows close.
* Open two windows. Press Open-Apple+Solid-Apple+W. Verify that all windows close. Repeat with Caps Lock off.
* Open two windows. Hold Solid-Apple and select File > Close. Verify that all windows close.
* Open two windows. Hold Open-Apple and select File > Close. Verify that all windows close.
* Open two windows. Open the File menu, then press Open-Apple+Solid-Apple+W. Verify that all windows close. Repeat with Caps Lock off.


## View Menu

* Open folder with files. View > by Date. Verify that DeskTop does not hang.

* Open folder with new files. Use View > by Date; verify dates after 1999 show correctly.
* Open folder with new files. Use View > by Date. Verify that two files modified on the same date are correctly ordered by time.

* Open folder with zero files. Use View > by Name. Verify that there is no crash.
* Open folder with one file. Use View > by Name. Verify that the entry paints correctly.

* Launch DeskTop. Open a window with files with dates with long month names (e.g. "February 29, 2020"). View > by Name. Resize the window so the lines are cut off on the right. Move the horizontal scrollbar all the way to the right. Verify that the right edges of all lines are visible.
* Launch DeskTop. Open a window containing a folder. View > by Name. Open the folder. Verify that in the new window, the horizontal scrollbar is inactive.

* Launch DeskTop. Open a volume window. View > by Name. Open a separate volume window. Open a folder window. Open a subfolder window. View > by Name. Close the window. Verify DeskTop doesn't crash.
* Launch DeskTop. Open a volume window. Open a folder window. View > by Name. Verify that the selection is still in the volume window, and that there is no selection in the folder window.
* Launch DeskTop. Open a volume window. Open a folder window. Select a file in the folder window. View > by Name. Verify that the selection is still in the folder window.

* Repeat for the Shortcuts > Add, Edit, Delete, and Run a Shortcut commands
  * Launch DeskTop. Open a volume window. View > by Name. Run the command from the Shortcuts menu. Cancel. Verify that the window entries repaint correctly (correct types, sizes, dates) and DeskTop doesn't crash.

* Launch DeskTop. On a volume, create folders named "A1", "B1", "A", and "B". View > by Name. Verify that the order is: "A", "A1", "B", "B1".

* Launch DeskTop. Open `/TESTS/FILE.TYPES`. View > by Type. Verify that the files are sorted by type name, first alphabetically followed by $XX types in numeric order.
* Launch DeskTop. Open a window containing multiple files. View > by Size. Verify that the files are sorted by size in descending order, with directories at the end.

* Launch DeskTop. Open window containing icons. View > by Name. Verify that selection is supported:
  * The icon bitmap and name can be clicked on.
  * Drag-selecting the icon bitmap and/or name selects.
  * Selected icons can be dragged to other windows or volume icons to initiate a move or copy.
  * Dragging a selected icon over a non-selected folder icon in the same window causes it to highlight, and initiates a move or copy (depending on modifier keys).
* Launch DeskTop. Open window containing icons. View > by Name. Select one or more icons. Drag them within the window but not over any other icons. Release the mouse button. Verify that the icons do not move.
* Launch DeskTop. Open window containing icons. View > by Name. Select an icon. File > Rename. Enter a new name that would change the ordering. Verify that the window is refreshed and the icons are correctly sorted by name, and that the icon is still selected.
* Launch DeskTop. Open two windows containing icons. View > by Name. Select an icon. Activate the other window. Verify that selection remains in the first window. File > Rename. Enter a new name that would change the ordering. Verify that the first window is activated and refreshed and the icons are correctly sorted by name, and that the icon is still selected and scrolled into view.
* Launch DeskTop. Open a window containing a folder. Open a folder. Activate the parent window and verify that the folder's icon is dimmed. View > by Name. Verify that the folder's icon is still dimmed. View > as Icons. Verify that the folder's icon is still dimmed.
* Launch DeskTop. Open a window containing a folder. View > by Name. Verify that the volume's icon is dimmed. View > as Icon. Verify that the volume's icon is still dimmed.

* Launch DeskTop. Open a volume window. Verify that the default view is "as Icons". View > by Name. Open a folder. Verify that the new folder's view is "by Name". Open a different volume window. Verify that it is "as Icons".
* Launch DeskTop. Open the A2.Desktop volume. View > as Small Icons. Open the Apple.Menu folder. Open the Control.Panels folder. Verify that the view is still "as Small Icons". Activate a different window. Apple Menu > Control Panels. Verify that the Control.Panels window is activated, and the view is still "as Small Icons".

* Launch DeskTop. Open a volume window. Select volume icons on the desktop. Switch window's view to by Name. Verify that the volume icons are still selected, and that File > Get Info is still enabled (and shows the volume info). Switch window's view back to as Icons. Verify that the desktop volume icons are still selected.
* Launch DeskTop. Open a window containing file icons. Select one or more file icons in the window. Select a different View option. Verify that the icons in the window remain selected.
* Launch DeskTop. Open a window containing file icons. Hold Open-Apple and select multiple files in a specific order. Select a different View option. Apple Menu > Sort Directory. View > as Icons. Verify that the icons appear in the selected order.
* Launch DeskTop. Open a window containing file icons. Select one or more volume icons on the desktop. Select a different View option. Verify that the volume icons on the desktop remain selected.

* Launch DeskTop. Open a window. Verify that the appropriate View option is checked. Close the window. Verify that the View menu items are all disabled, and that none are checked.


## ProDOS Interaction

* Launch DeskTop, File > Quit, run `BASIC.SYSTEM`. Ensure `/RAM` exists.

* File > Quit - verify that there is no crash under ProDOS 8.

* Launch DeskTop. Special > Copy Disk. Quit back to DeskTop. Invoke `BASIC.SYSTEM`. Ensure `/RAM` exists.

* Configure a system with 14 devices. Launch and then exit DeskTop. Load another ProDOS app that enumerates devices. Verify that all expected devices are present, and that there's no "Slot 0, Drive 1" entry.

* Launch DeskTop. Invoke `EXTRAS/BINSCII`. Verify that the display is not truncated.

* Preview an image file (e.g. SAMPLE.MEDIA/ROOM). Press Right Arrow to preview the next image. Press Escape to exit. Invoke a system file or binary file (e.g. KARATEKA.YELL). Verify it launches correctly with no crash.

* Configure a system with a Mockingboard. Launch DeskTop. Open `AUTUMN.PT3` in the `SAMPLE.MEDIA` folder. Verify that the `PT3PLR.SYSTEM` player launches correctly and that it plays the selected song.


## File Moving and Copying

* Move a file by dragging - same volume - target is window.
* Move a file by dragging - same volume - target is volume icon.
* Move a file by dragging - same volume - target is folder icon.

* Copy a file by dragging - same volume - target is window, holding Solid-Apple.
* Copy a file by dragging - same volume - target is volume icon, holding Solid-Apple.
* Copy a file by dragging - same volume - target is folder icon, holding Solid-Apple.

* Copy a file by dragging - different volume - target is window.
* Copy a file by dragging - different volume - target is volume icon.

* Select multiple files, including a folder containing files. Drag the files to a folder on the same volume. Verify that the progress dialog shows "Moving" and that the number of files listed matches the number of selected files.
* Select multiple files, including a folder containing files. Hold Solid-Apple and drag the files to a folder on the same volume. Verify that the progress dialog shows "Copying" and that the number of files listed matches the number of selected files plus the number of files in the folder.
* Select multiple files, including a folder containing files. Hold Solid-Apple and drag the files to another volume. Verify that the progress dialog shows "Moving" and that the number of files listed matches the number of selected files plus the number of files in the folder.

* Select a volume icon. Hold Solid-Apple and drag the volume icon to another volume icon or window from another volume. Verify that the progress dialog shows "Copying" and that the number of files listed matches the number of files in the volume.

* Launch DeskTop. Try to move a file (drag on same volume) where there is not enough space to make a temporary copy, e.g. a 100K file on a 140K disk. Verify that the file is moved successfully and no error is shown.
* Launch DeskTop. Try to copy a file (drag to different volume) where there is not enough space to make the copy. Verify that the error message says that the file is too large to copy.
* Launch DeskTop. Drag multiple selected files to a different volume, where one of the middle files will be too large to fit on the target volume but that subsequently selected files will fit. Verify that an error message says that the file is too large to copy, and that clicking OK continues to copy the remaining files.
* Launch DeskTop. Drag a single folder or volume containing multiple files to a different volume, where one of the files will be too large to fit on the target volume but all other files will fit. Verify that an error message says that the file is too large to copy, and that clicking OK continues to copy the remaining files.

* Launch DeskTop. Open a window. File > New Folder, enter name. Copy the file to another folder or volume. Verify that the "Files remaining" count bottoms out at 0.
* Launch DeskTop. Open a window. File > New Folder, enter name. Move the file to another folder or volume. Verify that the "Files remaining" count bottoms out at 0.
* Launch DeskTop. Copy multiple selected files to another volume. Repeat the copy. When prompted to overwrite, alternate clicking Yes and No. Verify that the "Files remaining" count decreases to zero.

* Load DeskTop. Create a folder e.g. `/RAM/F`. Try to copy the folder into itself using File > Copy To.... Verify that an error is shown.
* Load DeskTop. Create a folder e.g. `/RAM/F`. Open the containing window, and the folder itself. Try to move it into itself by dragging. Verify that an error is shown.
* Load DeskTop. Create a folder e.g. `/RAM/F`, and a sibling folder e.g. `/RAM/B`. Open the containing window, and the first folder itself. Select both folders, and try to move both into the first folder's window by dragging. Verify that an error is shown before any moves occur.
* Load DeskTop. Create a folder e.g. `/RAM/F`. Open the containing window, and the folder itself. Try to copy it into itself by dragging with an Apple key depressed. Verify that an error is shown.
* Load DeskTop. Open a volume window. Drag a file icon from the volume window to the volume icon. Verify that an error is shown.
* Load DeskTop. Create a folder, and a file within the folder with the same name as the folder (e.g. `/RAM/F` and `/RAM/F/F`). Try to copy the file over the folder using File > Copy To.... Verify that an error is shown.
* Load DeskTop. Create a folder, and a file within the folder with the same name as the folder (e.g. `/RAM/F` and `/RAM/F/F`). Try to move the file over the folder using drag and drop. Verify that an error is shown.
* Load DeskTop. Create a folder, and a file within the folder with the same name as the folder, and another file (e.g. `/RAM/F` and `/RAM/F/F` and `/RAM/F/B`). Select both files and try to move them into the parent folder using drag and drop. Verify that an error is shown before any files are moved.

* Load DeskTop. Create a folder on a volume. Create a non-folder file with the same name as the folder on a second volume. Drag the folder to the second volume. When prompted to overwrite, click Yes. Verify that the volume contains a folder of the appropriate name.
* Load DeskTop. Create a folder on a volume, containing a non-folder file. Create a non-folder file with the same name as the folder on a second volume. Drag the folder to the second volume. When prompted to overwrite, click Yes. Verify that the volume contains a folder of the appropriate name, containing a non-folder file.
* Load DeskTop. Create a non-folder file on a volume. Create a folder with the same name as the file on a second volume. Drag the file onto the second volume. Verify that an alert is shown about overwriting a directory.

* Ensure the startup disk has a name that would be case-adjusted by DeskTop, e.g. `/HD` but that shows as "Hd". Launch DeskTop. Open the startup disk. Apple Menu > Control Panels. Drag a DA file to the startup disk window. Verify that the file is moved, not copied.

* Launch DeskTop. Use File > Copy To... to copy a file. Verify that the file is indeed copied, not moved.
* Launch DeskTop. Drag a file icon to a same-volume window so it is moved, not copied. Use File > Copy To... to copy a file. Verify that the file is indeed copied, not moved.

For the following cases, open `/TESTS` and `/TESTS/FOLDER`:
* Drag a file icon from another volume onto the `TESTS` icon. Verify that the `TESTS` window activates and refreshes, and that the `TESTS` window's used/free numbers update. Click on the `FOLDER` window. Verify that the `FOLDER` window's used/free numbers update.
* Drag a file icon from another volume onto the `TESTS` window. Verify that the `TESTS` window activates and refreshes, and that the `TESTS` window's item count/used/free numbers update. Click on the `FOLDER` window. Verify that the `FOLDER` window's used/free numbers update.
* Copy a file from another volume to the `TESTS` icon using File > Copy To.... Verify that the `TESTS` window activates and refreshes, and that the `TESTS` window's item count/used/free numbers update. Click on the `FOLDER` window. Verify that the `FOLDER` window's used/free numbers update.
* Drag a file icon from another volume onto the `FOLDER` window. Verify that the `FOLDER` window activates and refreshes, and that the `FOLDER` window's item count/used/free numbers update. Click on the `TESTS` window. Verify that the `TESTS` window's used/free numbers update.
* Copy file from another volume to `/TESTS/FOLDER` using File > Copy File.... Verify that the `FOLDER` window activates and refreshes, and that the `FOLDER` window's item count/used/free numbers update. Click on the `TESTS` window. Verify that the `TESTS` window's used/free numbers update.
* Drag a file icon from the `TESTS` window to the trash. Verify that the `TESTS` window refreshes, and that the `TESTS` window's item count/used/free numbers update. Click on the `FOLDER` window. Verify that the `FOLDER` window's used/free numbers update.
* Delete a file from the `TESTS` window using File > Delete. Verify that the `TESTS` window refreshes, and that the `TESTS` window's item count/used/free numbers update. Click on the `FOLDER` window. Verify that the `FOLDER` window's used/free numbers update.
* Drag a file icon from the `FOLDER` window to the trash. Verify that the `FOLDER` window refreshes, and that the `FOLDER` window's item count/used/free numbers update. Click on the `TESTS` window. Verify that the `TESTS` window's used/free numbers update.
* Delete a file from the `FOLDER` window using File > Delete. Verify that the `FOLDER` window refreshes, and that the `FOLDER` window's item count/used/free numbers update. Click on the `TESTS` window. Verify that the `TESTS` window's used/free numbers update.
* Duplicate a file in the `FOLDER` window using File > Duplicate. Verify that the `FOLDER` window refreshes, and that the `FOLDER` window's item count/used/free numbers update. Click on the `TESTS` window. Verify that the `TESTS` window's used/free numbers update.
* Drag a file icon in the `TESTS` window onto the `FOLDER` icon while holding Apple to copy it. Verify that the `FOLDER` window activates and refreshes, and that the `FOLDER` window's item count/used/free numbers update. Click on the `TESTS` window. Verify that the `TESTS` window's used/free numbers update.
* Drag a file icon in the `TESTS` window onto the `FOLDER` window while holding Apple to copy it. Verify that the `FOLDER` window activates and refreshes, and that the `FOLDER` window's item count/used/free numbers update. Click on the `TESTS` window. Verify that the `TESTS` window's used/free numbers update.

* Repeat the following in an active and inactive window. In the inactive window case, verify that at the end of the test that the window is activated.
  * Drag a single file icon and drop it within the same window. Verify the icon is moved.
  * Drag multiple file icons and drop them within the same window. Verify the icons are moved.
  * Drag a single file icon and drop it within the same window while holding either Open-Apple or Solid-Apple. Verify the icon is duplicated.
  * Drag multiple file icons and drop them within the same window while holding either Open-Apple or Solid-Apple. Verify nothing happens.
  * Drag a single file icon and drop it within the same window while holding both Open-Apple and Solid-Apple. Verify that an alias is created.
  * Drag multiple file icons and drop them within the same window while holding both Open-Apple and Solid-Apple. Verify nothing happens.

* Launch DeskTop. Find a folder containing a file where the folder and file's creation dates (File > Get Info) differ. Copy the folder. Select the file in the copied folder. File > Get Info. Verify that the file creation and modification dates match the original.
* Launch DeskTop. Find a folder containing files and folders. Copy the folder to another volume. Using File > Get Info, compare the source and destination folders and files (both the top level folder and nested folders). Verify that the creation and modification dates match the original.
* Launch DeskTop. Drag a volume icon onto another volume icon (with sufficient capacity). Verify that no alert is shown. Repeat, but drag onto a volume window instead.
* Launch DeskTop. Drag a volume icon onto a folder icon (with sufficient capacity). Verify that no alert is shown, and that the folder's creation date is unchanged and its modification date is updated. Repeat, but drag onto a folder window instead.
* Launch DeskTop. Drag a volume icon onto another volume icon where there is not enough capacity for all of the files but there is capacity for some files. Verify that the copy starts and that when an alert is shown the progress dialog references a specific file, not the source volume itself.

* Launch DeskTop. Open two windows containing multiple files. Select multiples files in the first window. File > Copy To.... Select the second window's location as a destination and click OK. During the initial count of the files, press Escape. Verify that the count is canceled and the progress dialog is closed, and that the second window's contents do not refresh.
* Launch DeskTop. Open two windows containing multiple files. Select multiples files in the first window. File > Copy To.... Select the second window's location as a destination and click OK. After the initial count of the files is complete and the actual operation has started, press Escape. Verify that the second window's contents do refresh.

* Launch DeskTop. Drag `/TESTS/EMPTY.FOLDER` to another volume. Verify that it is copied.

* Configure a system with removable disks, e.g. Disk II in S6D1, and prepare two ProDOS disks with volume names `SRC` and `DST`, and a small file (2K or less is ideal) on `SRC`. Mount `SRC`. Launch DeskTop. Open `SRC` and select the file. File > Copy To.... Eject the disk and insert `DST`. Click Drives. Select `DST` and click OK. When prompted, insert the appropriate source and destination disks until the copy is complete. Inspect the contents of the file and verify that it was copied byte-for-byte correctly.

* Launch DeskTop. Drag a file to another volume to copy it. Open the volume and select the newly copied file. File > Get Info. Check Locked and click OK. Drag a file with a different type but the same name to the volume. When prompted to overwrite, click Yes. Verify that the file was replaced.

* Load DeskTop. Open a window for a volume in a Disk II drive. Remove the disk from the Disk II drive. Hold Solid-Apple and drag a file to another volume to move it. When prompted to insert the disk, click Cancel. Verify that when the window closes the disk icon is no longer dimmed.


## File Deletion

* Launch DeskTop. Open two windows. Select a file in one window. Activate the other window by clicking its title bar. File > Delete. Click OK. Verify that the window with the deleted file refreshes.

* Launch DeskTop. Open a window. Create folders A, B and C. Drag B onto C. Drag A to the trash. Click OK in the delete confirmation dialog. Verify that after the deletion, no alerts appear and volume icons can still be selected.
* Launch DeskTop. Open a window. Create folders A and B. Drag B onto A. Drag A to the trash. Verify that the confirmation dialog counts 2 files. Click OK. Verify that the count stops at 0, and does not wrap to 65,535.

* Launch DeskTop. Open a volume window. Create a folder. Open the folder's window. Go back to the volume window, and drag the folder icon to the trash. Click OK in the delete confirmation dialog. Verify that the folder's window closes.
* Launch DeskTop. Open a volume window. Create a folder. Open the folder's window. Activate the folder's parent window and select the folder icon. File > Delete. Click OK in the delete confirmation dialog. Verify that the folder's window closes.

* Open `/TESTS/DELETION`. Select `X`. File > Delete. Verify that a prompt is shown for deleting each file in deepest-first order (B, Z, Y, X). Click Yes at each prompt. Verify that all files are deleted.

* Load DeskTop. Open a window for a volume in a Disk II drive. Remove the disk from the Disk II drive. Drag a file to the trash. When prompted to insert the disk, click Cancel. Verify that when the window closes the disk icon is no longer dimmed.


## Get Info

* File > Get Info a non-folder file. Verify that the size shows as "_size_K".
* File > Get Info a folder containing 0 files. Verify that the size shows as "_size_K for 1 item".
* File > Get Info a folder containing 1 file. Verify that the size shows as "_size_K for 2 items".
* File > Get Info a folder containing 2 or more files. Verify that the size shows as "_size_K for _count_ items", including the folder itself.
* File > Get Info a volume containing 0 files. Verify that the size shows as "_size_K for 0 items / _total_K".
* File > Get Info a volume containing 1 file. Verify that the size shows as "_size_K for 1 item / _total_K".
* File > Get Info a volume containing 2 or more files. Verify that the size shows as "_size_K for _count_ items / _total_K".

* Open folder with new files. Use File > Get Info; verify dates after 1999 show correctly.

* Launch DeskTop. Select a 32MB volume. File > Get Info. Verify total size shows as 32,768K not 0K.

* Launch DeskTop. Select a volume icon, where the volume contains no files. File > Get Info. Verify that numbers are shown for number of files (0) and space used (a few K).
* Launch DeskTop. Select a file icon. File > Get Info. Verify that the size shown is correct. Select a directory. File > Get Info, and dismiss. Now select the original file icon again, and File > Get Info. Verify that the size shown is still correct.
* Use real hardware, not an emulator. Launch DeskTop. Select a volume icon. File > Get Info. Verify that a "The specified path name is invalid." alert is not shown.

* Launch DeskTop. Select a volume with more than 255 files in a folder (e.g. Total Replay). File > Get Info. Verify that the count finishes.
* Launch DeskTop. Select `/TESTS/PROPERTIES/KNOWN.SIZE`. File > Get Info. Verify that "Size" is "17K for 2 items".

* Launch DeskTop. Select a 5.25 disk volume. Remove the disk. File > Get Info. Verify that an alert is shown. Click OK. Verify that DeskTop doesn't hang or crash.
* Launch DeskTop. Select a file on a 5.25 disk. Remove the disk. File > Get Info. Verify that an alert is shown. Click OK. Verify that DeskTop doesn't hang or crash.
* Launch DeskTop. Select two files on a 5.25 disk. Remove the disk. File > Get Info. Verify that an alert is shown. Insert the disk again. Click OK. Verify that details are shown for the second file.

* Select a volume or folder containing multiple files. File > Get Info. During the count of the files, press Escape. Verify that the count is canceled.
* Select a volume or folder containing multiple files. File > Get Info. During the count of the files, eject the disk. Verify that an alert appears. Reinsert the disk. Click Try Again. Verify that the count of files continues and paints in the correct location.

* Open `/TESTS/FILE.TYPES`. Select `PACKED.FOT`. File > Get Info. Verify that the AuxType displays as `$4001`. Click OK. View > by Name. View > as Icons. File > Get Info. Verify that the AuxType still displays correctly.

* Open a volume window containing a folder. Select the folder. File > Get Info. Check Locked. Click OK. Close the volume window. Re-open the volume window. Verify that the folder is still a folder.


## New Folder, Rename & Duplicate

* Create a new folder (File > New Folder) - verify that it is selected / scrolled into view.
* Select a file. File > Duplicate. Verify that the new file is selected / scrolled into view / prompting for rename.
* Select a file, ensuring that the file's containing window's folder or volume icon is present. File > Duplicate. Verify that only the new file is selected, and not the parent window's folder or volume icon.

* Launch DeskTop. Select an icon. File > Rename. Enter a new name. Press Return. Verify that the icon updates with the new name.
* Launch DeskTop. Select an icon. File > Rename. Enter a new name. Press Escape. Verify that the icon doesn't change.
* Launch DeskTop. Select an icon. File > Rename. Enter a new name. Click away. Verify that the icon updates with the new name.
* Launch DeskTop. Select an icon. File > Rename. Make the name empty. Press Return. Verify that the icon doesn't change.
* Launch DeskTop. Select an icon. File > Rename. Make the name empty. Press Escape. Verify that the icon doesn't change.
* Launch DeskTop. Select an icon. File > Rename. Make the name empty. Click away. Verify that the icon doesn't change.

* Launch DeskTop. Select a file icon. File > Rename. Enter a unique name. Verify that the icon updates with the new name.
* Launch DeskTop. Select a file icon. File > Rename. Click away without changing the name. Verify that icon doesn't change.
* Launch DeskTop. Select a volume icon. File > Rename. Enter a unique name. Verify that the icon updates with the new name.
* Launch DeskTop. Select a volume icon. File > Rename. Click away without changing the name. Verify that the icon doesn't change.

* Repeat the following for volume icons and file icons:
  * Launch DeskTop. Select the icon. Click the icon's name. Verify that a rename prompt appears.
  * Launch DeskTop. Select the icon. Click the icon's bitmap. Verify that no rename prompt appears.
  * Launch DeskTop. With no selection, click the icon's name. Verify that no rename prompt appears.
  * Launch DeskTop. With multiple icons selected, click an icon's name. Verify that no rename prompt appears.

* Launch DeskTop. Select the Trash icon. Click the icon's name. Verify that no rename prompt appears.

* Launch DeskTop. Select a file icon. Position the window so that the icon is entirely off-screen. File > Rename. Press Escape to cancel. Verify that the window title bar activates and nothing mispaints on the desktop.
* Launch DeskTop. Close all windows. Select a volume icon. Move the icon so that the name is entirely off-screen. File > Rename. Press Escape to cancel. Verify that nothing mispaints on the desktop.
* Launch DeskTop. Open a window. Select a volume icon. Move the icon so that the name is entirely off-screen. File > Rename. Press Escape to cancel. Verify that the window title bar activates and nothing mispaints on the desktop.
* Launch DeskTop. Open two windows. Select a volume icon. Move the icon so that the name is entirely off-screen. File > Rename. Press Escape to cancel. Verify that the previously active window title bar is reactivated and that nothing mispaints on the desktop.

* Repeat the following cases for File > New Folder, File > Rename, and File > Duplicate:
  * Launch DeskTop. Open a window and (if needed) select a file. Run the command. Enter a name, but place the caret in the middle of the name (e.g. "exam|ple"). Click away. Verify that the full name is used.
  * Launch DeskTop. Open `/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789`. Use the command to try creating, duplicating, or renaming a folder within the nested folders that is longer than the path limit (e.g. `NAMEISTOOLARGE`). Verify that an error is shown but the dialog is not dismissed. Shorten the name under the length limit (e.g. `NAMEISOK`) and verify that the command is successful.

* Launch DeskTop. Open a volume. File > New Folder, create A. File > New Folder, create B. Drag B onto A. File > New Folder. Verify DeskTop doesn't hang.

* Launch DeskTop. Try to rename a volume to have the same name as another. Verify that an error is shown.
* Launch DeskTop. Select a volume icon. File > Rename. Enter the name of another volume. Verify that a "That name already exists." alert is shown. Click OK. Verify that the rename prompt is still showing with the entered name and it is editable.
* Launch DeskTop. Open a window. Select a file icon. File > Rename. Enter the name of a file in the same window. Verify that a "That name already exists." alert is shown. Click OK. Verify that the rename prompt is still showing with the entered name and it is editable.
* Launch DeskTop. Open a volume window. Open a folder window. Select the volume icon and rename it. Verify that neither window is closed, and volume window is renamed.
* Launch DeskTop. Open a volume window. Open a folder window. Activate the volume window. View > By Name. Select the folder icon. Rename it. Verify that the folder window is renamed.
* Launch DeskTop. Open a volume window. Position a file icon with a short name near the left edge of the window, but far enough away that the scrollbars are not active. Rename the file icon with a long name. Verify that the window's scrollbars activate.
* Launch DeskTop. Open a volume window. Position a file icon with a long name near the left edge of the window, so that the name is partially cut off and the scrollbars activate. Rename the file icon with a short name. Verify that the window's scrollbars deactivate.
* Launch DeskTop. Close all windows. Select a volume icon. File > Rename, enter a new name. Verify that there is no mis-painting of a scrollbar on the desktop.

* Launch DeskTop. Give a volume a long name (e.g. 15 'M's). Move the icon to the top third of the screen, and so that the name is partially offscreen to the right. Verify that the name is clipped by the right edge of the screen and doesn't mispaint on the left edge. Open the volume. Move the window so the name in the title bar is in the top third of the screen and partially offscreen to the right. Verify that the name is clipped and does not mispaint within the window.

* Launch DeskTop. Open a window. File > New Folder, enter a unique name. File > New Folder, enter the same name. Verify that an alert is shown. Dismiss the alert. Verify that the input field still has the previously typed name.
* Launch DeskTop. Open a window. File > New Folder, enter a unique name. File > New Folder, enter the same name. Verify that an alert is shown. Dismiss the alert. Enter a new unique name. Verify that the second folder is created as a sibling to the first folder, not as a child.

* Repeat the following cases for File > New Folder, File > Duplicate, and File > Delete:
  * Launch DeskTop. Open a window and (if needed) select a file. Run the command. Verify that when the window is refreshed, the scrollbars are inactive or at the top/left positions.

* Select a folder containing many files. File > Duplicate. During the initial count of the files, press Escape. Verify that the count is canceled and the progress dialog is closed, and that the window contents do not refresh.
* Select a folder containing many files. File > Duplicate. After the initial count of the files is complete and the actual operation has started, press Escape. Verify that the operation is canceled and the progress dialog is closed, and that the window contents do refresh, but that no rename prompt appears.

* Find make a copy of a `PRODOS` system file. Rename it to have a ".SYSTEM" suffix. Verify that it updates to have an application icon. Rename it again to remove the suffix. Verify that it updates to have a system file icon. Repeat several times. Verify that the icon has not shifted in position.

## Name Casing

* Verify that GS/OS volume name cases show correctly.
* Verify that GS/OS file name cases show correctly in `/TESTS/PROPERTIES/GS.OS.NAMES`
* Verify that AppleWorks file name cases show correctly in `/TESTS/PROPERTIES/AW.NAMES`

* Launch DeskTop. Select an AppleWorks file icon. File > Rename. Specify a name using a mix of uppercase and lowercase. Close the containing window and re-open it. Verify that the filename case is retained.
* Launch DeskTop. Select an AppleWorks file icon. File > Duplicate. Specify a name using a mix of uppercase and lowercase. Close the containing window and re-open it. Verify that the filename case is retained.

* Launch DeskTop. In the Options control panel, uncheck "Preserve uppercase and lowercase in names". Then run these test cases:
  * File > New Folder. Enter a name with mixed case (e.g. "lower.UPPER.MiX"). Verify that the name appears with heuristic word casing (e.g. "Lower.Upper.Mix"). Close the window and re-open it. Verify that the name remains unchanged.
  * Select a non-AppleWorks file. File > Rename. Enter a name with mixed case (e.g. "lower.UPPER.MiX"). Verify that the name appears with heuristic word casing (e.g. "Lower.Upper.Mix"). Close the window and re-open it. Verify that the name remains unchanged.
  * Select a non-AppleWorks file. File > Duplicate. Enter a name with mixed case (e.g. "lower.UPPER.MiX"). Verify that the name appears with heuristic word casing (e.g. "Lower.Upper.Mix"). Close the window and re-open it. Verify that the name remains unchanged.
  * Select a disk. Special > Format Disk. Enter a name with mixed case (e.g. "lower.UPPER.MiX"). Let the operation complete. Verify that the name appears with heuristic word casing (e.g. "Lower.Upper.Mix"). Restart DeskTop. Verify that the name remains unchanged.
  * Select a disk. Special > Erase Disk. Enter a name with mixed case (e.g. "lower.UPPER.MiX"). Let the operation complete. Verify that the name appears with heuristic word casing (e.g. "Lower.Upper.Mix"). Restart DeskTop. Verify that the name remains unchanged.

* Launch DeskTop. In the Options control panel, check "Preserve uppercase and lowercase in names". Then run these test cases:
  * File > New Folder. Enter a name with mixed case (e.g. "lower.UPPER.MiX"). Verify that the name appears with the specified case (e.g. "Lower.Upper.Mix"). Close the window and re-open it. Verify that the name remains unchanged.
  * Select a non-AppleWorks file. File > Rename. Enter a name with mixed case (e.g. "lower.UPPER.MiX"). Verify that the name appears with the specified case (e.g. "Lower.Upper.Mix"). Close the window and re-open it. Verify that the name remains unchanged.
  * Select a non-AppleWorks file. File > Duplicate. Enter a name with mixed case (e.g. "lower.UPPER.MiX"). Verify that the name appears with the specified (e.g. "Lower.Upper.Mix"). Close the window and re-open it. Verify that the name remains unchanged.
  * Select a disk. Special > Format Disk. Enter a name with mixed case (e.g. "lower.UPPER.MiX"). Let the operation complete. Verify that the name appears with the specified case (e.g. "lower.UPPER.MiX"). Restart DeskTop. Verify that the name remains unchanged.
  * Select a disk. Special > Erase Disk. Enter a name with mixed case (e.g. "lower.UPPER.MiX"). Let the operation complete. Verify that the name appears with the specified case (e.g. "lower.UPPER.MiX"). Restart DeskTop. Verify that the name remains unchanged.

* Launch DeskTop. In the Options control panel, check "Preserve uppercase and lowercase in names". File > New Folder. Enter a name with mixed case (e.g. "lower.UPPER.MiX"). In the Options control panel, uncheck "Preserve uppercase and lowercase in names". Select the folder. File > Rename. Click away without changing the name. Verify that the name appears with heuristic word casing (e.g. "Lower.Upper.Mix"). Close the window and re-open it. Verify that the name remains unchanged.

* Launch DeskTop. In the Options control panel, check "Preserve uppercase and lowercase in names". File > New Folder. Enter a name with mixed case (e.g. "lower.UPPER.MiX"). Select the folder. Then run these test cases:
  * Drag it to another volume to copy it. Verify that the copied file retains the same mixed case name.
  * Drag it to another folder on the same volume to move it. Verify that the moved file retains the same mixed case name.
  * Hold Solid-Apple and drag it to another volume to move it. Verify that the moved file retains the same mixed case name.
  * Hold Solid-Apple and drag it to another folder on the same volume to copy it. Verify that the copied file retains the same mixed case name.

* Launch DeskTop. In the Options control panel, check "Preserve uppercase and lowercase in names". Rename one volume with mixed case e.g. "vol1.MIXED". Rename a second volume with differently mixed case, e.g. "VOL2.mixed". Drag the first volume to the second. Verify that the newly created folder is named with the same case as the dragged volume.


## Window Headers

* Open a folder with no items. Verify window header says "0 Items"
* Open a folder with only one item. Verify window header says "1 Item"
* Open a folder with two items. Verify window header says "2 Items"
* Open a folder with no items. File > New Folder. Enter a name. Verify that the window header says "1 Item"
* Open a folder with only one item. File > New Folder. Enter a name. Verify that the window header says "2 Items"

* Open window for an otherwise empty RAMDisk volume. Note the "K in disk" and "K available" values in the header. File > New Folder. Enter a name. Verify that the "K in disk" increases by 0.5, and that the "K available" decreases by 0 or 1. File > New Folder. Enter another name. Verify that the "K in disk" increases by 0.5, and that the "K available" decreases by 0 or 1.
* Open two windows for different volumes. Note the "items", "K in disk" and "K available" values in the header of the second window. File > New Folder. Enter a name. Verify that the "items" value increases by one, and "K in disk" increases by 0, 0.5 or 1, and that the "K available" decreases by 0, 0.5 or 1.

* Open a window. Drag the window so that the left edge of the window is offscreen. Verify that the "X Items" display gets cut off. Drag the window so that the right edge of the window is offscreen. Verify that the "XK available" display gets cut off. Repeat with the window sized so that both scrollbars appear and thumbs moved to the middle of the scrollbars.


## Window Restoration

* Launch DeskTop. Open a subdirectory folder. Quit and relaunch DeskTop. Verify that the used/free numbers in the restored windows are non-zero.

* Launch DeskTop. Open some windows. Special > Copy Disk. Quit back to DeskTop. Verify that the windows are restored.
* Launch DeskTop. Close all windows. Special > Copy Disk. Quit back to DeskTop. Verify that no windows are restored.

* Load DeskTop. Open a volume. Adjust the window size so that horizontal and vertical scrolling is required. Scroll to the bottom-right. Quit DeskTop, reload. Verify that the window size and scroll position was restored correctly.
* Load DeskTop. Open a volume. Quit DeskTop, reload. Verify that the volume window was restored, and that the volume icon is dimmed. Close the volume window. Verify that the volume icon is no longer dimmed.
* Load DeskTop. Open a window containing icons. View > by Name. Quit DeskTop, reload. Verify that the window is restored, and that it shows the icons in a list sorted by name, and that View > by Name is checked. Repeat for other View menu options.
* Load DeskTop. Open a window for a volume in a Disk II drive. Quit DeskTop. Remove the disk from the Disk II drive. Load DeskTop. Verify that the Disk II drive is only polled once on startup, not twice.

* Launch DeskTop. Open a window. File > Quit. Launch DeskTop again. Ensure the window is restored. Try to drag-select volume icons. Verify that they are selected.

* Launch DeskTop. Open a volume window. Rename the volume to "TRASH" (all uppercase). File > Quit. Load DeskTop. Verify that the restored window is named "TRASH" not "Trash".


## Apple Menu

* Rename the `APPLE.MENU` directory. Launch DeskTop. Verify that the Apple Menu has two "About" items and no separator.
* Create a new `APPLE.MENU` directory. Launch DeskTop. Verify that the Apple Menu has two "About" items and no separator.
* Create a new `APPLE.MENU` directory. Copy the `CHANGE.TYPE` accessory into it. Launch DeskTop. Verify that the Apple Menu has two "About" items, a separator, and "Change Type". Select the Change Type icon. Apple Menu > Change Type. Change the type to $8642. Restart DeskTop. Verify that the Apple Menu has two "About" items, and no separator.
* Open the `APPLE.MENU` directory. Use Apple Menu > Change Type accessory to change the AuxType of an accessory (e.g. `CALCULATOR`) from $0642 to $8642. Restart DeskTop. Verify that the accessory is not shown in the Apple Menu.
* Eject the startup disk. Select an accessory (e.g. Calculator) from the Apple Menu. Verify that an alert is shown prompting to reinsert the startup disk. Insert the startup disk and click OK. Verify that the accessory launches.
* Eject the startup disk. Select a folder (e.g. Control Panels) from the Apple Menu. Verify that an alert is shown prompting to reinsert the startup disk. Insert the startup disk and click OK. Verify that the folder window opens.

## Shortcuts (in DeskTop)

* Delete the `LOCAL/SELECTOR.LIST` file from the startup disk, if it was present. Launch DeskTop. Verify that DeskTop does not hang.
* Delete the `LOCAL/SELECTOR.LIST` file from the startup disk, if it was present. Launch DeskTop. Verify that Shortcuts > Edit a Shortcut..., Shortcuts > Delete a Shortcut..., and Shortcuts > Run a Shortcut... are disabled, and the menu has no separator. Add a shortcut. Verify that Shortcuts > Edit a Shortcut..., Shortcuts > Delete a Shortcut..., and Shortcuts > Run a Shortcut... are now enabled, and the menu has a separator, and the shortcut appears. Delete the shortcut. Verify that the menu has its initial state again.
* Delete the `LOCAL/SELECTOR.LIST` file from the startup disk, if it was present. Launch DeskTop. Verify that Shortcuts > Edit a Shortcut..., Shortcuts > Delete a Shortcut..., and Shortcuts > Run a Shortcut... are disabled, and the menu has no separator. Add a shortcut to "list only". Verify that Shortcuts > Edit a Shortcut..., Shortcuts > Delete a Shortcut..., and Shortcuts > Run a Shortcut... are now enabled, but the menu still has no separator or shortcuts. Delete the shortcut. Verify that the menu has its initial state again.

* Repeat for the Shortcuts > Edit, Delete, and Run a Shortcut commands
  * Ensure at least one Shortcut exists. Launch DeskTop. Eject the startup disk. Run the command from the Shortcuts menu. Verify that a prompt is shown asking to insert the system disk. Click Cancel. Verify that DeskTop does not crash or hang. Reinsert the startup disk. Run the command again. Verify that the dialog appears correctly.

* Launch DeskTop. Shortcuts > Add a Shortcut.... Check "at boot". Click Cancel. Shortcuts > Add a Shortcut.... Verify "at boot" is not checked.
* Launch DeskTop. Shortcuts > Add a Shortcut.... Check "at first use". Click Cancel. Shortcuts > Add a Shortcut.... Verify "at first use" is not checked.
* Launch DeskTop. Shortcuts > Add a Shortcut.... Check "list only". Click Cancel. Shortcuts > Add a Shortcut.... Verify "list only" is not checked.
* Launch DeskTop. Shortcuts > Add a Shortcut.... Select a target. Check "list only" and "at first use". Click OK. Restart DeskTop. Shortcuts > Edit a Shortcut... Select the previously created shortcut. Click Cancel. Shortcuts > Add a Shortcut.... Verify that "list only" and "at first use" are not checked.

* Launch DeskTop. Create a shortcut, "menu and list" / "at boot". Create a second shortcut, "menu and list", "at first use". Create a third shortcut, "menu and list", "never". Delete the first shortcut. Verify that the remaining shortcuts are "at first use" and "never".
* Launch DeskTop. Create a shortcut, "list only" / "at boot". Create a second shortcut, "list only", "at first use". Create a third shortcut, "list only", "never". Delete the first shortcut. Verify that the remaining shortcuts are "at first use" and "never".
* Launch DeskTop. Delete all shortcuts. Create a shortcut, "list only" / "never". Edit the shortcut. Verify that it is still "list only" / "never". Change it to "menu and list", and click OK. Verify that it appears in the Shortcuts menu.

* Launch DeskTop. Configure a shortcut with the target being a directory. Open a window. Select a file icon. Invoke the shortcut. Verify that the previously selected file is no longer selected.

* Launch DeskTop. Create 8 shortcuts. Shortcuts > Add a Shortcut.... Check "menu and list". Pick a file, enter a name, OK. Verify that a relevant alert is shown.
* Launch DeskTop. Create 1 shortcut which is "menu and list" and 16 shortcuts which are "list only". Shortcuts > Edit a Shortcut.... Select the "menu and list" shortcut and click OK. Check "list only", and click OK. Verify that an alert is shown.
* Launch DeskTop. Create 8 shortcuts which are "menu and list" and 1 shortcut which is "list only". Shortcuts > Edit a Shortcut.... Select the "list only" shortcut and click OK. Check "menu and list", and click OK. Verify that an alert is shown.

* Launch DeskTop. Shortcuts > Add a Shortcut... and create a shortcut for a volume that is not the first volume on the DeskTop. Shortcuts > Edit a Shortcut... and select the new shortcut. Verify that the file picker shows the volume name as selected.
* Launch DeskTop. Shortcuts > Add a Shortcut.... Verify that if the target is a volume directory and either "at boot" or "at first use" is selected, then an alert is shown when trying to commit the dialog.
* Launch DeskTop. Shortcuts > Add a Shortcut.... Verify that if the target is an alias (link file) and either "at boot" or "at first use" is selected, then an alert is shown when trying to commit the dialog.

* Launch DeskTop. Select a file icon. Shortcuts > Add a Shortcut... Verify that the file dialog is navigated to the selected file's folder and the file is selected.
* Launch DeskTop. Select a volume icon. Shortcuts > Add a Shortcut... Verify that the file dialog is initialized to the list of drives and the volume is selected.
* Launch DeskTop. Clear selection. Shortcuts > Add a Shortcut... Verify that the file dialog is initialized to the startup disk and no file is selected.

* Configure a shortcut for a program with many associated files to copy to RAMCard "at boot". Reboot, and launch `DESKTOP.SYSTEM`. While DeskTop is being copied to RAMCard, press Escape to cancel. Verify that none of the program's files were copied to the RAMCard. Once DeskTop starts, invoke the shortcut. Verify that the program starts correctly.
* Configure a shortcut for a program with many associated files to copy to RAMCard "at boot". Reboot, and launch `DESKTOP.SYSTEM`. While the program's files are being copied to RAMCard, press Escape to cancel. Verify that not all of the files were copied to the RAMCard. Once DeskTop starts, invoke the shortcut. Verify that the program starts correctly.
* Configure a shortcut for a program with many associated files to copy to RAMCard "at boot". Reboot, and launch `DESKTOP.SYSTEM`. Verify that all of the files were copied to the RAMCard. Once DeskTop starts, eject the disk containing the program. Invoke the shortcut. Verify that the program starts correctly.
* Configure a shortcut for a program with many associated files to copy to RAMCard "at first use". Invoke the shortcut. Verify that the files are copied to the RAMCard, and that the program starts correctly. Return to DeskTop by quitting the program. Eject the disk containing the program. Invoke the shortcut. Verify that the program starts correctly.
* Configure a shortcut for a program with many associated files to copy to RAMCard "at first use". Invoke the shortcut. While the program's files are being copied to RAMCard, press Escape to cancel. Verify that not all of the files were copied to the RAMCard. Delete the folder from the RAMCard. Invoke the shortcut again. Verify that the files are copied to the RAMCard and that the program starts correctly.

* Configure a shortcut for a program with many associated files to copy to RAMCard "at first use". Open a window for the RAMCard volume. Invoke the shortcut. During the initial count of the program's files are being counted, press Escape to cancel. Verify that the volume window contents do not not refresh.
* Configure a shortcut for a program with many associated files to copy to RAMCard "at first use". Open a window for the RAMCard volume. Invoke the shortcut. After the initial count of the files is complete and the actual copy has started, press Escape to cancel. Verify that the volume window contents do refresh.

* Repeat the following:
  * For these permutations:
    * Shortcut in (1) menu and list, and (2) list only.
    * Shortcut set to copy to RAMCard (1) on boot, (2) on first use, (3) never.
    * DeskTop set to (1) Copy to RAMCard, (2) not copying to RAMCard.
  * Launch DeskTop. Configure the shortcut. Restart. Launch DeskTop. Run the shortcut. Verify that it executes correctly.

* Configure at least two shortcuts. Launch DeskTop. Shortcuts > Run a Shortcut.... Cancel. Verify that neither shortcut is invoked.

* Launch DeskTop. Shortcuts > Run a Shortcut. Verify the OK button is disabled. Click on an item. Verify the OK button becomes enabled. Click on a blank option. Verify the OK button becomes disabled. Use the arrow keys to move selection. Verify that the OK button becomes enabled.

* Configure DeskTop to copy to RAMCard on start. Add a shortcut for an application file that can be launched from DeskTop in the root of a disk named with mixed case using GS/OS, and configure it to copy to RAMCard "on first use". Invoke the shortcut. Exit back to DeskTop. Verify that the folder name on the RAMCard has the same mixed case as the original disk.

* Launch DeskTop. Create a shortcut for a folder that is the 8th entry in the menu. Shortcuts > Edit a Shortcut... Select the entry. Click OK. Verify that DeskTop does not hang.


## File Types

* Put image file in `APPLE.MENU`, start DeskTop. Select it from the Apple menu. Verify image is shown.
* Put text file in `APPLE.MENU`, start DeskTop. Select it from the Apple menu. Verify text is shown.
* Put font file in `APPLE.MENU`, start DeskTop. Select it from the Apple menu. Verify font is shown.

* Put BASIC program in `APPLE.MENU`, start DeskTop. Select it from the Apple menu. Verify it runs.
* Put System program in `APPLE.MENU`, start DeskTop. Select it from the Apple menu. Verify it runs.

* Launch DeskTop. Open `SAMPLE.MEDIA`. Double-click `KARATEKA.YELL`. Verify that an alert is shown. Click Cancel. Verify the alert closes but nothing else happens. Repeat, but click OK. Verify that it executes.
* Launch DeskTop. Open `SAMPLE.MEDIA`. Hold Solid-Apple and double-click `KARATEKA.YELL`. Verify that it executes.
* Launch DeskTop. Open `SAMPLE.MEDIA`. Select `KARATEKA.YELL`. File > Open. Verify that it executes.
* Launch DeskTop. Open `SAMPLE.MEDIA`. Select `KARATEKA.YELL`. Press Open-Apple+O. Verify that it executes.
* Launch DeskTop. Open `SAMPLE.MEDIA`. Select `KARATEKA.YELL`. Press Solid-Apple+O. Verify that it executes.

* Launch DeskTop. Select a SYS file. Rename it to have a .SYSTEM suffix. Verify that it has an application (diamond and hand) icon, without moving.
* Launch DeskTop. Select a SYS file. Rename it to not have a .SYSTEM suffix. Verify that it has a system (computer) icon, without moving.
* Launch DeskTop. Select a TXT file. Rename it to have a .SHK suffix. Verify that it has an archive icon, without moving.
* Launch DeskTop. Select a TXT file. Rename it to have a .BXY suffix. Verify that it has an archive icon, without moving.
* Launch DeskTop. Select a TXT file. Rename it to have a .BNY suffix. Verify that it has an archive icon, without moving.

* Launch DeskTop. File > New Folder.... Name it with a .A2FC suffix. Verify that it still has a folder icon.

* Launch DeskTop. Try to copy files including a GS/OS forked file in the selection. Verify that an alert is shown, with the filename visible in the progress dialog. Verify that if OK is clicked, the operation continues with other files, and the watch cursor is shown.
* Launch DeskTop. Try to copy files including a GS/OS forked file in the selection. Verify that an alert is shown, with the filename visible in the progress dialog. Verify that if Cancel is clicked the operation is aborted.
* Launch DeskTop. Try to copy files including a GS/OS forked file contained in a selected folder. Verify that an alert is shown, with the filename visible in the progress dialog. Verify that if OK is clicked, the operation continues with other files, and if Cancel is clicked the operation is aborted.
* Launch DeskTop. Try to delete files including a GS/OS forked file in the selection. Verify that an alert is shown, with the filename visible in the progress dialog. Verify that if OK is clicked, the operation continues with other files, and if Cancel is clicked the operation is aborted.
* Launch DeskTop. Try to delete files including a GS/OS forked file contained in a selected folder. Verify that an alert is shown, with the filename visible in the progress dialog. Verify that if OK is clicked, the operation continues with other files, and if Cancel is clicked the operation is aborted. Note that non-empty directories will fail to be deleted.
* Launch DeskTop. Using drag/drop, try to copy or move a folder containing a GS/OS forked file, where the source and destination windows are visible. When an alert is shown, click OK. Verify that the source and destination windows are updated.
* Launch DeskTop. Using drag/drop, try to copy a volume containing a GS/OS forked file and other files, where the destination window is visible. When an alert is shown, click OK. Verify that the destination window is updated.
* Launch DeskTop. Using File > Copy To..., try to copy a folder containing a GS/OS forked file, where the source and destination windows are visible. When an alert is shown, click OK. Verify that the source and destination windows are updated.
* Launch DeskTop. Using drag/drop, try to delete a GS/OS forked file. When the delete confirmation dialog is shown, click Cancel. Verify that the source window is not updated.
* Launch DeskTop. Using drag/drop, try to delete a GS/OS forked file. When the delete confirmation dialog is shown, click OK. When an alert is shown, click OK. Verify that the source window is updated.
* Launch DeskTop. Using File > Delete try to delete a GS/OS forked file, where the containing window is visible. When the delete confirmation dialog is shown, click OK. When an alert is shown, click OK. Verify that the containing window is updated.

## RAMCard

* Repeat the following:
  * For these permutations:
    * DeskTop (1) copied to RAMCard and (2) not copied to RAMCard.
    * Renaming (1) the volume that DeskTop loaded from, and renaming (2) the DeskTop folder itself. (For #2, move all DeskTop files to a subfolder.)
  * Verify that the following still function:
    * File > Copy To... (overlays)
    * Special > Copy Disk (and that File > Quit returns to DeskTop) (overlay + quit handler)
    * Apple Menu > Calculator (desk accessories)
    * Apple Menu > Control Panels (relative folders)
    * Control Panel, change desktop pattern, close, quit, restart (settings)
    * Windows are saved on exit/restored on restart (configuration)
    * Invoking another application (e.g. `BASIC.SYSTEM`), then quitting back to DeskTop (quit handler)
    * Modifying shortcuts (selector)

* Configure a system without a RAMCard. Launch DeskTop. Verify that the volume containing DeskTop appears in the top right corner of the desktop. File > Copy To.... Verify that the volume containing DeskTop is the first disk shown.
* Configure a system with a RAMCard, and set DeskTop to copy itself to the RAMCard on startup. Launch DeskTop. Verify that the non-RAMCard volume containing DeskTop appears in the top right corner of the desktop. File > Copy To.... Verify that the non-RAMCard volume containing DeskTop is the first disk shown. From within DeskTop, launch another app e.g. Basic.system. Eject the DeskTop volume. Exit the app back to DeskTop. Verify that the remaining volumes appear in default order.
* Configure a system with a RAMCard, and set DeskTop to not copy itself to the RAMCard on startup. Launch DeskTop. Verify that the non-RAMCard volume containing DeskTop appears in the top right corner of the desktop. File > Copy To.... Verify that the non-RAMCard volume containing DeskTop is the first disk shown.

* Configure a system with a RAMCard, and set DeskTop to copy itself to the RAMCard on startup. Launch DeskTop. Create a shortcut for a non-executable file at the root of a volume, set to "Copy to RAMCard" "at first use". Run the shortcut. Verify that the "Files remaining" count bottoms out at 0. Close the alert. Drag a volume icon to another volume. Verify that the "Files remaining" count bottoms out at 0.


## Format/Erase

* Repeat the following cases for Special > Format Disk and Special > Erase Disk:
  * Launch DeskTop. Run the command. Ensure left/right arrows move selection correctly.
  * Launch DeskTop. Run the command. Verify that the device order shown matches the order of volumes shown on the DeskTop (boot device first, etc). Select a device and proceed with the operation. Verify the correct device was formatted or erased.
  * Launch DeskTop. Run the command. For the new name, enter a volume name not currently in use. Verify that you are not prompted for a new name.
  * Launch DeskTop. Run the command. For the new name, enter the name of a volume in a different slot/drive. Verify that an alert shows, indicating that the name is in use.
  * Launch DeskTop. Run the command. For the new name, enter the name of the current disk in that slot/drive. Verify that you are not prompted for a new name.
  * Launch DeskTop. Run the command. Select a disk (other than the startup disk) and click OK. Enter a name, but place the caret in the middle of the name (e.g. "exam|ple"). Click OK. Verify that the full name is used.
  * Launch DeskTop. Run the command. Select an empty drive. Let the operation continue until it fails. Verify that an error message is shown.
  * Configure a system with at least 9 volumes. Launch DeskTop. Run the command. Select a volume in the third column. Click OK. Verify that the selection rectangle is fully erased.
  * Configure a system with 13 volumes, not counting `/RAM`. Launch DeskTop. Run the command. Verify that all 13 volumes are shown.
  * Launch DeskTop. Select a volume icon. Run the command. Enter a new name and click OK. Click OK to confirm the operation. Verify that the icon for the volume is updated with the new name.
  * Launch DeskTop. Run the command. Select a slot/drive containing an existing volume. Enter a new name and click OK. Click OK to confirm the operation. Verify that the icon for the volume is updated with the new name.
  * Launch DeskTop. Run the command. Select a slot/drive containing an existing volume. Enter a new name and click OK. Verify that the confirmation prompt shows the volume with adjusted case matching the volume's icon, with quotes around the name.
  * Launch DeskTop. Run the command. Select a slot/drive containing an existing volume with a GS/OS-cased name and click OK. Enter a new name and click OK. Verify that the confirmation prompt shows the volume with the correct case matching the volume's icon, with quotes around the name.
  * Launch DeskTop. Run the command. Select a slot/drive containing a Pascal disk. Enter a new name and click OK. Verify that the confirmation prompt shows the Pascal volume name (e.g. "TGP:"), with quotes around the name.
  * Launch DeskTop. Run the command. Select a slot/drive containing a DOS 3.3 disk. Enter a new name and click OK. Verify that the confirmation prompt shows "the DOS 3.3 disk in slot # drive #", without quotes.
  * Launch DeskTop. Run the command. Select a slot/drive containing an unformatted disk. Enter a new name and click OK. Verify that the confirmation prompt shows "the disk in slot # drive #", without quotes.
  * Launch DeskTop. Select a volume icon. Run the command. Verify that the device selector is skipped. Enter a new volume name. Verify that the confirmation prompt refers to the selected volume.
  * Repeat the following case with: no selection, Trash selected, multiple volume icons selected, a single file selected, and multiple files selected:
    * Launch DeskTop. Set selection as specified. Run the command. Verify that the device selector is not skipped.
  * Launch DeskTop. Make sure no volume icon is selected. Run the command. Verify the OK button is disabled. Click on an item. Verify the OK button becomes enabled. Click on a blank option. Verify the OK button becomes disabled. Use the arrow keys to move selection. Verify that the OK button becomes enabled.
  * Launch DeskTop. Make sure no volume icon is selected. Run the command. Click an item, then click OK. Verify that the device location is shown, and that the OK button becomes disabled. Enter text. Verify that the OK button is enabled. Delete all of the text. Verify that the OK button becomes disabled. Enter text. Verify that the OK button becomes enabled.
  * Launch DeskTop. Select a volume icon. Run the command. Verify that the OK button is disabled. Enter text. Verify that the device location is shown, and that the OK button is enabled. Delete all of the text. Verify that the OK button becomes disabled. Enter text. Verify that the OK button becomes enabled.

* Launch DeskTop. Insert a non-formatted disk into a SmartPort drive (e.g. Virtual ][ OmniDisk). Verify that a prompt is shown to format the disk. Click OK. Enter a name, and click OK. Verify that the correct slot and drive are shown in the confirmation prompt.

## Keyboard

* Close all windows. Start typing a volume name. Verify that a prefix-matching volume, or the subsequent volume (in lexicographic order) is selected, or the last volume (in lexicographic order).
* Close all windows. Start typing a volume name. Move the mouse. Start typing another filename. Verify that the matching is reset.
* Open `/TESTS/TYPING.SELECT/ORDER`. Start typing a filename. Verify that a prefix-matching file in the window, or the subsequent file (in lexicographic order), or the last file (in lexicographic order) is selected. For example, if the files "Alfa" and "Whiskey" and the volume "Tests" are present, typing "A" selects "Alfa", typing "AB" selects "Alfa", typing "AL" selects "Alfa", typing "ALFAA" selects "Whiskey", typing "B" selects "Whiskey", typing "Z" selects "Whiskey". Repeat including file names with numbers and periods.
* Open `/TESTS/TYPING.SELECT`. Start typing a filename. Move the mouse. Start typing another filename. Verify that the matching is reset.
* Open `/TESTS/TYPING.SELECT`. Start typing a filename. Press an arrow key. Start typing another filename. Verify that the matching is reset.
* Open a window containing no files. Start typing a filename. Verify that nothing is selected.
* Open `/TESTS/TYPING.SELECT/CASE`. Verify the files appear with correct names. Press a letter. Verify that the first file starting with that letter is selected.
* Disable any acceleration. Close all windows. Restart DeskTop. Type the first letter of a volume name to select it. Quickly press Open-Apple+O. Verify the volume opens.
* Disable any acceleration. Close all windows. Restart DeskTop. Type the first letter of a volume name to select it. Quickly click on the File menu. Verify that Open is enabled.

* Repeat the following:
  * For these permutations:
    * Close all windows.
    * Open a window containing no file icons.
    * Open a window containing file icons.
  * Run these steps:
    * Clear selection. Press Tab repeatedly. Verify that icons in the active window (or desktop if no window is open) are selected in lexicographic order, starting with first in lexicographic order.
    * Select an icon. Press Tab. Verify that the next icon in the active window (or desktop if no window is open) in lexicographic order is selected.
    * Clear selection. Press \` repeatedly. Verify that icons in the active window (or desktop if no window is open) are selected in lexicographic order, starting with first in lexicographic order.
    * Select an icon. Press \`. Verify that the next icon in the active window (or desktop if no window is open) in lexicographic order is selected.
    * Clear selection. Press Shift+\` repeatedly. Verify that icons in the active window (or desktop if no window is open) are selected in reverse lexicographic order, starting with last in lexicographic order.
    * Select an icon. Press Shift+\`. Verify that the previous icon in the active window (or desktop if no window is open) in lexicographic order is selected.
  * On a IIgs and a Platinum IIe:
    * Clear selection. Press Shift+Tab repeatedly. Verify that icons in the active window (or desktop if no window is open) are selected in reverse lexicographic order, starting with last in lexicographic order.
    * Select an icon. Press Shift+Tab. Verify that the previous icon in the active window (or desktop if no window is open) in lexicographic order is selected.

* Open a volume window containing no file icons. Clear selection by clicking on the desktop. Press Tab repeatedly. Verify selection does not change, scrollbars do not appear in the window, and DeskTop does not crash. Close the window. Verify that the volume icon is no longer dimmed.
* Open a volume window containing no file icons. Clear selection by clicking on the desktop. Type 'Z' repeatedly. Verify selection does not change, scrollbars do not appear in the window, and DeskTop does not crash. Close the window. Verify that the volume icon is no longer dimmed.

* Launch DeskTop. Close all windows. Clear selection by clicking on the desktop. Press Right Arrow key. Verify that the first (non-Trash) volume icon is selected. Repeat with Down Arrow key.
* Launch DeskTop. Close all windows. Clear selection by clicking on the desktop. Press Left Arrow key. Verify that Trash icon is selected. Repeat with Up Arrow key.
* Launch DeskTop. Close all windows. Select a volume icon. Press an arrow key. Verify that the next icon in the specified direction is selected, if any. If none, verify that selection remains unchanged.
* Launch DeskTop. Close all windows. Eject all disks, and verify that only the Trash icon remains. Clear selection by clicking on the desktop. Press an arrow key. Verify that the Trash icon is selected.

* Launch DeskTop. Open a window. Press Right Arrow key. Verify that the first icon in the window is selected. Repeat with Down Arrow key.
* Launch DeskTop. Open a window. Press Left Arrow key. Verify that the last icon in the window is selected. Repeat with Up Arrow key.
* Launch DeskTop. Open two windows, both containing icons. Select an icon in one window. Activate the other window without changing selection. Press Right Arrow key. Verify that the first icon in the active window is selected. Repeat with Down Arrow key.
* Launch DeskTop. Open two windows, both containing icons. Select an icon in one window. Activate the other window without changing selection. Press Left Arrow key. Verify that the last icon in the active window is selected. Repeat with Up Arrow key.
* Launch DeskTop. Open a window containing multiple icons. Select an icon in the window. Press an arrow key. Verify that the next icon in the specified direction is selected, if any. If none, verify that selection remains unchanged.

* Launch DeskTop. Open a window. Click a volume icon. Press an arrow key. Verify that the next volume icon in visual order is selected
* Launch DeskTop. Open a window. Click a volume icon. Click on the open window's title bar. Press an arrow key. Verify that an icon within the window is selected. Repeat for the window's header and scroll bars.
* Launch DeskTop. Open a window. Click a volume icon. Click an empty area within the window. Press an arrow key. Verify that an icon within the window is selected.
* Launch DeskTop. Open a window. Click a volume icon. Click an icon within the window. Press an arrow key. Verify that the next file icon in visual order within the window is selected.
* Launch DeskTop. Open a window. Click a volume icon. Click an empty space on the desktop. Press the Down Arrow key. Verify that the first volume icon in visual order on the desktop is selected.
* Launch DeskTop. Open a window. Click a file icon. Click an empty space on the desktop. Press the Down Arrow key. Verify that the first file icon in visual order within the window is selected.

* Launch DeskTop. Open one window containing icons, the other containing no icons. Select an icon in the first window. Activate the other window without changing selection. Press an arrow key. Verify that selection remains unchanged.

* Launch DeskTop. Open a window containing icons. View > by Date. Press the Right Arrow key. Verify that selection remains unchanged. Repeat with the Left Arrow key.
* Launch DeskTop. Open a window containing icons. View > by Date. Clear selection by clicking on the desktop. Press the Down Arrow key. Verify that the first icon in visual order is selected. Press the Down Arrow key again. Verify that the next icon in visual order is selected. Repeat, and verify that selection does not wrap around.
* Launch DeskTop. Open a window containing icons. View > by Date. Clear selection by clicking on the desktop. Press the Up Arrow key. Verify that the last icon in visual order is selected. Press the Up Arrow key again. Verify that the previous icon in visual order is selected. Repeat, and verify that selection does not wrap around.

* Repeat the following cases with these modifiers: Open-Apple, Solid-Apple:
  * Launch DeskTop. Open 3 windows (A, B, C). Hold modifier and press Tab repeatedly. Verify that windows are activated and cycle in forward order (A, B, C, A, B, C, ...).
  * Launch DeskTop. Open 3 windows (A, B, C). Hold modifier and press \` repeatedly. Verify that windows are activated cycle in forward order (A, B, C, A, B, C, ...).
  * Launch DeskTop. Open 3 windows (A, B, C). Hold modifier and press Shift+\` repeatedly. Verify that windows are activated cycle in reverse order (B, A, C, B, A, C, ...).
  * On a IIgs: Launch DeskTop. Open 3 windows (A, B, C). Hold modifier and press Shift+Tab repeatedly. Verify that windows are activated cycle in reverse order (B, A, C, B, A, C, ...).
  * On a Platinum IIe: Launch DeskTop. Open 3 windows (A, B, C). Hold modifier and press Shift+Tab repeatedly. Verify that windows are activated cycle in reverse order (B, A, C, B, A, C, ...).

* Launch DeskTop. Clear selection by closing all windows and clicking on the desktop. Press Apple+Down. Verify that nothing happens.

* Launch DeskTop. Close all windows. Edit > Select All. Press the Right Arrow key. Verify that a single volume icon becomes selected.
* Launch DeskTop. Open a window containing icons. Edit > Select All. Press the Right Arrow key. Verify that a single file icon becomes selected.

## Hardware Configurations

* Configure a system with a drive controller (Disk II or SmartPort) in slot 2. Launch DeskTop. Verify that Slot 2 appears in the Startup menu.

### Real-Time Clock

* Run on system with real-time clock; verify that time shows in top-right of menu.
* Run on system with real-time clock. Click on a volume icon. Verify that the clock still renders correctly.

### RAM Expansions

The following tests all require:
* A RAM disk such as RAMWorks (and a ProDOS driver) or a RAMFactor/"Slinky" memory expansion card.
* Configuring DeskTop to install itself to the RAMCard on boot. This is not the default (as of v1.5) but can be controlled using the Options control panel.

* Run DeskTop on a system with RAMWorks and using `RAM.DRV.SYSTEM`. Verify that sub-directories under `APPLE.MENU` are copied to `/RAM/DESKTOP/APPLE.MENU`.
* Run DeskTop on a system with RAMFactor/"Slinky" RAMDisk. Verify that sub-directories under `APPLE.MENU` are copied to `/RAM5/DESKTOP/APPLE.MENU` (or appropriate volume path).

* Launch DeskTop, ensure it copies itself to RAMCard. Delete the `LOCAL/DESKTOP.CONFIG` file from the startup disk, if it was present. Go into Control Panels and change a setting. Verify that `LOCAL/DESKTOP.CONFIG` is written to the startup disk.
* Launch DeskTop, ensure it copies itself to RAMCard. Delete the `LOCAL/SELECTOR.LIST` file from the startup disk, if it was present. Shortcuts > Add a Shortcut, and create a new shortcut. Verify that `LOCAL/SELECTOR.LIST` is written to the startup disk.

* Configure a system with a RAMCard of at least 1MB, then run the following tests:
  * Launch DeskTop. Create a shortcut for `/TESTS/RAMCARD/SHORTCUT/BASIC.SYSTEM`, set to copy to RAMCard at boot. Ensure DeskTop is set to copy to RAMCard on startup. Restart DeskTop. Verify that the directory is successfully copied.
  * Launch DeskTop. Create a shortcut for `/TESTS/RAMCARD/SHORTCUT/BASIC.SYSTEM`, set to copy to RAMCard at first use. Ensure DeskTop is set to copy to RAMCard on startup. Ensure DeskTop is set to launch Shortcuts. Quit DeskTop. Launch Shortcuts. Select the shortcut. Verify that the directory is successfully copied.

* Launch DeskTop, ensure it copies itself to RAMCard. Drag a file icon to a same-volume window so it is moved. Configure a shortcut to copy to RAMCard "at first use". Invoke the shortcut. Verify that the shortcut's files were indeed copied, not moved.

* Launch DeskTop, ensure it copies itself to RAMCard. Configure a shortcut with the target in the root of a volume, and to Copy to RAMCard at first use. Quit DeskTop. Launch Shortcuts. Invoke the shortcut. Verify that the copy count goes to zero and doesn't blank out.
* Launch DeskTop, ensure it copies itself to RAMCard. Configure a shortcut with the target in a directory, not the root of a volume, and to Copy to RAMCard at first use. Quit DeskTop. Launch Shortcuts. Invoke the shortcut. Verify that the copy count goes to zero and doesn't blank out.
* Launch DeskTop, ensure it copies itself to RAMCard. Configure a shortcut set to Copy to RAMCard at first use. Invoke the shortcut. Verify that it correctly copies to the RAMCard and runs.

* Launch DeskTop, ensure it copies itself to RAMCard. Modify a shortcut. Verify that no prompt is shown. Power cycle and launch DeskTop. Verify that the shortcut modifications are present.
* Launch DeskTop, ensure it copies itself to RAMCard. Eject the startup disk. Modify a shortcut. Verify that a prompt is shown asking about saving the changes. Insert the system disk, and click OK. Verify that no further prompt is shown. Power cycle and launch DeskTop. Verify that the shortcut modifications are present.
* Launch DeskTop, ensure it copies itself to RAMCard. Eject the startup disk. Modify a shortcut. Verify that a prompt is shown asking about saving the changes. Click OK. Verify that another prompt is shown asking to insert the system disk. Insert the system disk, and click OK. Verify that no further prompt is shown. Power cycle and launch DeskTop. Verify that the shortcut modifications are present.

* Repeat the following cases with the Options. International, and Control Panel DAs, and the Date and Time DA (on a system without a real-time clock):
  * Launch DeskTop, ensure it copies itself to RAMCard. Launch the DA and modify a setting. Verify that no prompt is shown. Power cycle and launch DeskTop. Verify that the modifications are present.
  * Launch DeskTop, ensure it copies itself to RAMCard. Eject the startup disk. Launch the DA and Modify a setting. Verify that a prompt is shown asking about saving the changes. Insert the system disk, and click OK. Verify that no further prompt is shown. Power cycle and launch DeskTop. Verify that the modifications are present.
  * Launch DeskTop, ensure it copies itself to RAMCard. Eject the startup disk. Launch the DA and modify a setting. Verify that a prompt is shown asking about saving the changes. Click OK. Verify that another prompt is shown asking to insert the system disk. Insert the system disk, and click OK. Verify that no further prompt is shown. Power cycle and launch DeskTop. Verify that the modifications are present.

* Launch DeskTop, ensure it copies itself to RAMCard. Open the RAM Disk volume. Open the Desktop folder. Apple Menu > Control Panels. Drag Apple.Menu from the Desktop folder to the Control.Panels window. Verify that an alert is shown that an item can't be moved or copied into itself.

* Invoke `DESKTOP.SYSTEM`, ensure it copies itself to RAMCard. Quit DeskTop. Restart DeskTop from the original startup disk. Shortcuts > Edit a Shortcut. Select a shortcut, modify it (e.g. change its name) and click OK. Verify that no prompt is shown for saving changes to the startup disk.
* Invoke `DESKTOP.SYSTEM`, ensure it copies itself to RAMCard. Quit DeskTop. Restart DeskTop from the original startup disk. Eject the startup disk. Special > Format Disk. Verify that no prompt for the startup disk is shown.
* Invoke `DESKTOP.SYSTEM`, and hit Escape when copying to RAMCard. Once DeskTop has started, eject the startup disk. Special > Format Disk. Verify that a prompt to insert the system disk is shown.

* Boot to `BASIC.SYSTEM` (without going through `DESKTOP.SYSTEM` first). Run the following commands: `CREATE /RAM5/DESKTOP`, `CREATE /RAM5/DESKTOP/MODULES`, `BSAVE /RAM5/DESKTOP/MODULES/DESKTOP,A0,L0` (substituting the RAM disk's name for `RAM5`). Launch `DESKTOP.SYSTEM`. Verify the install doesn't hang silently or loop endlessly.

### SmartPort

* Configure a system with more than 2 drives on a SmartPort controller. Boot ProDOS 2.4 (any patch version). Launch DeskTop. Special > Format Disk. Verify that correct device names are shown for the mirrored drives.
* Configure a system with more than 2 drives on a SmartPort controller. Boot into ProDOS 2.0.1, 2.0.2, or 2.0.3. Launch DeskTop. Special > Format Disk. Verify that correct device names are shown for the mirrored drives.
* Run on a system with a single slot providing 3 or 4 drives (e.g. CFFA, BOOTI, Floppy Emu); verify that all show up.
* Configure a system with a SmartPort controller in slot 1 and one drive. Launch DeskTop. Special > Format Disk. Select the drive in slot 1. Verify that the format succeeds. Repeat for slots 2, 4, 5, 6 and 7.

* With a Floppy Emu in SmartPort mode, ensure that the 32MB image shows up as an option.

### RGB Display

* On an RGB system (IIgs, etc), go to Control Panel, check RGB Color. Verify that the display shows in color. Preview an image, and verify that the image shows in color and the DeskTop remains in color after exiting.
* On an RGB system (IIgs, etc), go to Control Panel, uncheck RGB Color. Verify that the display shows in monochrome. Preview an image, and verify that the image shows in color and the DeskTop returns to monochrome after exiting.
* Using MAME (e.g. via Ample), configure a system with Machine Configuration > Monitor Type > Video-7 RGB. Start DeskTop. Open a window. Apple Menu > Run Basic Here. Type `HGR : HCOLOR=3 : HPLOT 0,0 TO 100,100`. Verify a diagonal line appears.

### Z80 Card

* Configure a system with a Z80 card and without a No-Slot Clock. Boot a package disk including the CLOCK.SYSTEM driver. Verify that it doesn't hang.

### ZIP CHIP

* Run DeskTop on a IIe with a ZIP CHIP installed.. Apple Menu > About This Apple II. Verify that a ZIP CHIP is reported.

### Apple IIgs

* On a IIgs, launch DeskTop. Verify that it appears in monochrome. Quit DeskTop and launch another graphical ProDOS-8 program. Verify that it appears in color.

* On an IIgs, go to Control Panel, check RGB Color. Verify that the display shows in color. Enter the IIgs control panel (Control+Shift+Open-Apple+Esc), and exit. Verify that DeskTop remains in color.
* On an IIgs, go to Control Panel, uncheck RGB Color. Verify that the display shows in monochrome. Enter the IIgs control panel (Control+Shift+Open-Apple+Esc), and exit. Verify that DeskTop resets to monochrome.

* Configure a IIgs system with ejectable disks. Launch DeskTop. Select the ejectable volume. Special > Eject Disk. Verify that an alert is not shown.

* Configure a IIgs via the system control panel to have a RAM disk:
  * Launch DeskTop. Verify that the `RAM5` volume is shown with a RAMDisk icon.
  * Configure DeskTop to copy to RAMCard on startup, and restart. Verify it is copied to `/RAM5`.

* On a IIgs, go to Apple Menu > About This Apple II. Verify the memory count is not "000,000".

* On a IIgs, launch DeskTop. Launch a IIgs-native program e.g. NoiseTracker. Exit and return to DeskTop. Verify that the display is not garbled.

* On the KEGS, GSport or GSplus IIgs emulators, launch DeskTop. Verify the emulator does not crash.

* On the Crossrunner IIgs emulator, launch DeskTop. Verify it does not hang on startup.

* Use the Options control panel (in DeskTop) to show Shortcuts on startup. Launch Shortcuts. File > Run a Program.... Select `BASIC.SYSTEM` and click OK. that super-hires mode is not erroneously activated.

### Apple IIc

* Run DeskTop on a IIc (or IIc+). Start `BASIC.SYSTEM`. Run `POKE 1275,0`. `BYE` to return to DeskTop. Verify that the progress bar has a gray background, not "VWVWVW..."

### Apple IIc+

* Run DeskTop on a IIc+ from a 3.5" floppy on internal drive. Verify that the disk doesn't spin constantly.
* Configure a disk with ProDOS 2.4.3. Run DeskTop on a IIc+. Create a shortcut to launch `BASIC.SYSTEM`. Use Control Panel > Options to set Shortcuts to run on startup. Restart. From Shortcuts, invoke the `BASIC.SYSTEM` shortcut. Verify that it doesn't crash. Restart. From Shortcuts, invoke DeskTop. Verify that it doesn't crash.
* Run DeskTop on a IIc+. Apple Menu > About This Apple II. Verify that a ZIP CHIP is not reported.

### Laser 128

* Run on Laser 128; verify that 800k image files on Floppy Emu show as 3.5" floppy icons.
* Run on Laser 128, with a Floppy Emu. Select a volume icon. Special > Eject Disk. Verify that the Floppy Emu does not crash.
* Run on Laser 128. Launch DeskTop. Open a volume. Click on icons one by one. Verify selection changes from icon to icon, and isn't extended as if a Open-Apple key/button or Shift is down.
* Run on Laser 128EX at 3.6MHz and multiple SmartPort devices. Launch DeskTop. Move the mouse for several seconds. Verify that the system does not hang.

### Macintosh IIe Option Card

* Run on a Macintosh equipped with the IIe Option Card. Verify that DeskTop runs and the system does not hang.

# Preview

Text File:
* Verify that Escape key exits.
* Verify that Space toggles Proportional/Fixed mode.
* Verify that clicking in the right part of the title bar toggles Proportional/Fixed mode.
* Verify that the "Proportional" label has the same baseline as the window title. Click on "Proportional". Verify that the "Fixed" label has the same baseline as the window title.
* Verify that DeskTop's selection is not cleared on exit.
* Open `/TESTS/FILE.TYPES/SHORT.TEXT`.
  * Verify that the scrollbar is inactive.
  * Click "Proportional". Verify that the scrollbar remains inactive.
  * Click "Fixed". Verify that the scrollbar remains inactive.
* Open `/TESTS/FILE.TYPES/LONG.TEXT`.
  * Verify that the scrollbar is active.
  * Verify that Up/Down Arrow keys scroll by one line.
  * Verify that Open-Apple plus Up/Down Arrow keys scroll by page.
  * Verify that Solid-Apple plus Up/Down Arrow keys scroll by page.
  * Verify that Open-Apple plus Solid-Apple plus Up/Down Arrow keys scroll to start/end.
  * Click the Proportional/Fixed button on the title bar. Verify that the view is scrolled to the top.
  * Scroll somewhere in the file. Click the scrollbar thumb without moving it. Verify the thumb doesn't move and the content doesn't scroll.
  * Verify that dragging the scroll thumb to the middle shows approximately the middle of the file.
  * Verify that Up/Down Arrow keys scroll by one line consistently.
  * Verify that the first page of content appears immediately, and that the watch cursor is shown while the rest of the file is parsed. With any acceleration disabled, use Open-Apple+Solid-Apple+Down to jump to the bottom of the file. Verify that the view is displayed without undue delay.
* Open `/TESTS/FILE.TYPES/TABS`. Verify that the file displays all lines correctly.
* Open `/TESTS/FILE.TYPES/SUDOKU.STORY`. Click on "Proportional" to change to "Fixed" font. Scroll down using down arrow key until bottom line reads "with". Scroll down again using down arrow key. Verify that the file correctly scrolled down one line. Scroll to the bottom of the file. Ensure the entire file is visible.
* Open `/TESTS/FILE.TYPES/TOGGLE.ME`. Click "Proportional" to toggle to "Fixed". Verify that the scrollbar activates and that the thumb is at the top. Scroll down. Click "Fixed" to toggle to "Proportional". Verify that the scrollbar deactivates.

Image File:
* Verify that Escape key exits.
* Verify that Apple+W exits.
* On a IIgs or with RGB card:
  * Verify that space bar toggles color/mono.
  * Open `/TESTS/FILE.TYPES/HRMONO.A2HR`. Verify it displays as mono by default.
  * Open `/TESTS.FILE.TYPES/HRCOLOR.A2LC`. Verify it displays as color by default.
* Configure a system with a real-time clock. Launch DeskTop. Preview an image file. Exit the preview. Verify that the menu bar clock reappears immediately.
* In a directory with multiple images, preview one image. Verify that Left Arrow shows the previous image (and wraps around), Right Arrow shows the next image (and wraps around), Apple+Left Arrow shows the first image, and Apple+Right Arrow shows the last image. Note that order is per the natural directory order, e.g. as shown in View > as Icons.
* Open `/TESTS/FILE.TYPES/PACKED.FOT`. Verify that the preview does not immediately exit after the image loads.
* In a directory with multiple images, preview one image. Press S. Verify that a slideshow starts. Press S again, verify that the slideshow stops.
* In a directory with multiple images, preview one image. Press S. Verify that a slideshow starts. Press D (or any key that doesn't have a special purpose). Verify that the slideshow stops. Press S. Verify that a slideshow starts again.
* In a directory with multiple images, preview one image. Press S. Verify that a slideshow starts. Press Left Arrow. Verify that the previous image is shown, and that the slideshow stops. Press S. Verify that a slideshow starts again.
* Click on the File menu, then close it. Double-click an image file. Press Escape to close the preview. Verify that the File menu is not highlighted.
* Preview an image file. Verify that the mouse cursor is hidden. Without moving the mouse, press the Escape key. Verify that after the desktop repaints the mouse cursor becomes visible without needing to move the mouse first.

* Put `SHOW.IMAGE.FILE` in `APPLE.MENU`, start DeskTop.
    * Select no icon, select DA from Apple menu. Verify nothing happens other than open/close animation and screen refresh.
    * Select volume icon, select DA from Apple menu. Verify nothing happens other than open/close animation and screen refresh.
    * Select folder icon, select DA from Apple menu. Verify nothing happens other than open/close animation and screen refresh.
    * Select image file icon, select DA from Apple menu. Verify image is shown.
* Put `SHOW.TEXT.FILE` in `APPLE.MENU`, start DeskTop.
    * Select no icon, select DA from Apple menu. Verify nothing happens other than open/close animation.
    * Select volume icon, select DA from Apple menu. Verify nothing happens other than open/close animation.
    * Select folder icon, select DA from Apple menu. Verify nothing happens other than open/close animation.
    * Select text file icon, select DA from Apple menu. Verify text is shown.
* Put `SHOW.FONT.FILE` in `APPLE.MENU`, start DeskTop.
    * Select no icon, select DA from Apple menu. Verify nothing happens other than open/close animation.
    * Select volume icon, select DA from Apple menu. Verify nothing happens other than open/close animation.
    * Select folder icon, select DA from Apple menu. Verify nothing happens other than open/close animation.
    * Select font file icon, select DA from Apple menu. Verify font is shown.
* Put `SHOW.DUET.FILE` in `APPLE.MENU`, start DeskTop.
    * Select no icon, select DA from Apple menu. Verify nothing happens other than open/close animation.
    * Select volume icon, select DA from Apple menu. Verify nothing happens other than open/close animation.
    * Select folder icon, select DA from Apple menu. Verify nothing happens other than open/close animation.
    * Select Electric Duet file icon, select DA from Apple menu. Verify music is played.

# Desk Accessories

* Launch DeskTop. Open the APPLE.MENU folder. Select a desk accessory icon. File > Open. Verify that the desk accessory launches.

Repeat for every desk accessory that runs in a movable window:
* Launch DeskTop. Open the DA. Click on the title bar but don't move the window. Verify that the window doesn't repaint if the window is not moved.

Repeat for every desk accessory that runs in a window.
* Launch DeskTop. Open the DA. Hold Apple (either Open-Apple or Solid-Apple) and press W. Verify that the desk accessory exits. Repeat with caps-lock off.

## Control Panel

* Launch DeskTop. Open the Control Panel DA. Use the pattern editor to create a custom pattern, then click the desktop preview to apply it. Close the DA. Open the Control Panel DA. Click the right arrow above the desktop preview. Verify that the default checkerboard pattern is shown.

* Launch DeskTop, invoke Control Panel DA. Under Mouse Tracking, toggle Slow and Fast. Verify that the mouse cursor doesn't warp to a new position, and that the mouse cursor doesn't flash briefly on the left edge of the screen.

* Open the Control Panel DA. Eject the startup disk. Close the DA without changing any settings. Verify that you are not prompted to save.
* Open the Control Panel DA. Eject the startup disk. Modify a setting and close the DA. Verify that you are prompted to save.

* Configure a system with a color display. Open the Control Panel DA. Check "RGB Color" if needed to ensure the display is in color. Select one of the vertically striped patterns that appears as a solid color. Click the preview area. Verify that the color matches the preview. Move the DA window. Verify that colors still match. Repeat with other patterns.

* Configure a system with a RAMCard, and ensure DeskTop is configured to copy to RAMCard on startup. Launch DeskTop. Apple Menu > Control Panels. Open Control Panel. Modify a setting e.g. the desktop pattern. Close the window. Reboot the system. Verify that the setting is retained.

## Options

* Open the Options DA. Eject the startup disk. Close the DA without changing any settings. Verify that you are not prompted to save.
* Open the Options DA. Eject the startup disk. Modify a setting and close the DA. Verify that you are prompted to save.
* Open the Options DA. Move the window to the bottom of the screen so only the title bar is visible. Press Apple-1, Apple-2, Apple-3. Verify that checkboxes don't mis-paint on the screen. Move the window back up. Verify that the state of the checkboxes has toggled.
* Open the Options DA. Close the DA. Apple Menu > Run Basic Here. Verify that the system does not crash to the monitor.

## Sounds

* Open the Sounds DA. Select one of the "Obnoxious" sounds. Exit the DA. Run `BASIC.SYSTEM` from the EXTRAS/ folder. Verify that the system does not crash to the monitor.

## International

* Open the Control Panels folder. View > by Name. Open International. Change the date format from M/D/Y to D/M/Y or vice versa. Click OK. Verify that the entire desktop repaints, and that dates in the window are shown with the new format.
* Open the Control Panels folder. View > by Name. Open International. Close without changing anything. Verify that only a minimal repaint happens.

## Calculator and Sci.Calc

* Run Apple Menu > Calculator. Move the Calculator window. Verify that the mouse cursor is drawn correctly.

* Run Apple Menu > Calculator. Verify that the mouse cursor does not jump to the top-left of the screen.

* Run Apple Menu > Calculator. Drag the Calculator window over a volume icon. Then drag the Calculator window to the bottom of the screen so that only the title bar is visible. Verify that volume icon redraws properly.

* Run Apple Menu > Calculator. Drag the Calculator window to bottom of screen so only title bar is visible. Type numbers on the keyboard. Verify no numbers are painted on screen. Move window back up. Verify the typed numbers were input.

Repeat for Calculator and Sci.Calc:
* With an English build, run the DA. Verify that '.' appears as the decimal separator in calculation results and that '.' when typed functions as a decimal separator.
* With an Italian build, run the DA. Verify that ',' appears as the decimal separator in calculation result and that ',' when typed functions as a decimal separator. Verify that when '.' is typed, ',' appears.
* Enter '1' '-' '2' '='. Verify that the system does not hang.
* Enter '1' '/' '2' '='. Verify that the result has a 0 before the decimal (i.e. "0.5").
* Enter '0' '-' '.' '5' '='. Verify that the result has a 0 before the decimal (i.e. "-0.5").

With Sci.Calc:
* Enter '1' '+' '2' 'SIN' '='. Verify that the result is 1.034...
* Enter '1' 'SIN' '+' '2' '='. Verify that the result is 2.017...
* Enter '4' '5' 'SIN'. Verify that the result is 0.707...
* Enter '4' '5' '+/-' 'SIN'. Verify that the result is -0.707...
* Enter '1' '8' '0' 'COS'. Verify that the result is -1
* Enter '4' '5' 'SIN' 'ASIN. Verify that the result is approximately 45.
* Enter '4' '5' 'COS' 'ACOS'. Verify that the result is approximately 45.
* Enter '8' '9' 'TAN' 'ATAN'. Verify that the result is approximately 89.

## Date & Time

* Open `/TESTS/FILE.TYPES`. View > by Name. Apple Menu > Control Panels > Date and Time. Change the time format from 12- to 24-hour or vice versa. Click OK. Verify that the entire desktop repaints, and that dates in the windows are shown with the new format.

Run these tests on a system with a real-time clock:

* Apple Menu > Control Panels > Date and Time. Press Escape key. Verify the desk accessory exits. Repeat with the Return key.
* Launch DeskTop. Apple Menu > Control Panels > Date and Time. Verify that the date and time are read-only.
* Launch DeskTop. Run the Date and Time DA, and change the setting to 12 hour. Verify that the time is shown as 12-hour, and if less than 10 is displayed without a leading 0.
* Launch DeskTop. Run the Date and Time DA, and change the setting to 24 hour. Verify that the time is shown as 24-hour, and if less than 10 is displayed with a leading 0.

Run these tests on a system without a real-time clock:

* Run Apple Menu > Control Panels > Date and Time. Set date. Reboot system, and re-run DeskTop. Create a new folder. Use File > Get Info. Verify that the date was saved/restored.
* Launch DeskTop. Run the Date and Time DA, and change the setting to 12 hour. Verify that the time is shown as 12-hour, and if less than 10 is displayed without a leading 0. Use the Right Arrow and Left Arrow keys and the mouse, and verify that the AM/PM field is selectable. Select the AM/PM field. Use the up and down arrow keys and the arrow buttons, and verify that the field toggles. Select the hours field. Use the up and down arrow keys and the arrow buttons, and verify that the field cycles from 1 through 12.
* Launch DeskTop. Run the Date and Time DA, and change the setting to 24 hour. Verify that the time is shown as 24-hour, and if less than 10 is displayed with a leading 0. Use the Right Arrow and Left Arrow keys and the mouse, and verify that the AM/PM field is not selectable. Use the up and down arrow keys and the arrow buttons, and verify that the field cycles from 0 through 23.
* Launch DeskTop. Run the Date and Time DA. Change the month and year, and verify that the day range is clamped to 28, 29, 30 or 31 as appropriate, including for leap years.
* Launch DeskTop. Run the Date and Time DA. Click on the up/down arrows. Verify that they invert correctly when the button is down.
* Launch DeskTop. Run the Date and Time DA. Click in the various fields (day/month/year/hour/minutes/period). Verify that the appropriate field highlights.
* Launch DeskTop. Run the Date and Time DA. Change the setting to 12 hour. Click on the AM/PM field. Verify that the field highlights.
* Launch DeskTop. Run the Date and Time DA. Change the setting to 24 hour. Click where the AM/PM field would be, to the right of the minutes field. Verify that nothing happens.
* Launch DeskTop. Run the Date and Time DA. Click the year field. Click the up arrow. Verify that the year increments. Click the down arrow. Verify that the year decrements. Verify that only the clicked buttons highlight, and that they un-highlight correctly when the button is released.
* Apple Menu > Control Panels. View > by Name. Run Date and Time. Change the date to the same date as one of the files in the folder. Click OK. Verify that the entire desktop repaints, and that dates in the window are shown with "Today".
* Start with a fresh disk image. Run DeskTop. Apple Menu > Control Panels. View > by Name. Open Date and Time. Verify that the date shown in the dialog matches the file dates. Click OK without changing anything. Verify that the entire desktop repaints, and that dates in the window are shown with "Today". Open Date and Time. Click OK without changing anything. Verify that the entire desktop does not repaint.

## Calendar

* Configure a system with a real-time clock. Launch DeskTop. Run the Calendar DA. Verify that it starts up showing the current month and year correctly.
* Configure a system without a real-time clock. Launch DeskTop. Run the Calendar DA. Verify that it starts up showing the build's release month and year correctly.

## Sort Directory

* Open `/TESTS/SORT.DIRECTORY/ORDER`. File > Quit. Re-launch DeskTop. Apple Menu > Sort Directory. Verify that the files in the window are sorted.

* Open `/TESTS/SORT.DIRECTORY`. Open the `ORDER` folder by double-clicking. Apple Menu > Sort Directory. Verify that files are sorted by type/name.

* Load DeskTop. Ensure that every ProDOS device is online and represented by an icon. Open `/TESTS/HUNDRED.FILES`. Apple Menu > Sort Directory. Make sure all the files are sorted lexicographically (e.g. F1, F10, F100, F101, ...)

* Open `/TESTS/SORT.DIRECTORY/TWO.SYS.FILES`. Apple Menu > Sort Directory. Verify that the files are sorted as `A.SYSTEM` then `B.SYSTEM`.

## Key Caps

* Launch DeskTop. Run Apple Menu > Key Caps desk accessory. Turn Caps Lock off. Hold Apple (either one) and press the Q key. Verify the desk accessory exits.
* Repeat on an Apple IIe, Apple IIc, and Laser 128:
  * Launch DeskTop. Apple Menu > Key Caps. Verify that the "original" layout is shown, with the backslash above the Return key.
* Repeat on an Apple IIc+ and Apple IIgs:
  * Launch DeskTop. Apple Menu > Key Caps. Verify that the "extended" layout is shown, with the backslash to the right of the space bar.
* Launch DeskTop. Run Apple Menu > Key Caps desk accessory. Press the semicolon/colon key. Verify that the highlight is correctly positioned.

## Map

* Launch DeskTop. Apple Menu > Control Panels. Open Map. Type a known city name e.g. "San Francisco". Click Find. Verify that the city is highlighted on the map and the Latitude/Longitude are updated.
* Launch DeskTop. Apple Menu > Control Panels. Open Map. Wait for the blinking indicator to be visible (this will be easier to observe in emulators with acceleration disabled), and drag the window to a new location. Type a city name (e.g. "San Francisco"). Click Find. Verify that the indicator blinks correctly only in the new location.

## Screen Savers

* Launch DeskTop. Apple Menu > Screen Savers. Select Melt. File > Open (or Apple+O). Click to exit. Press Apple+Down. Click to exit. Verify that the File menu is not highlighted.
* Configure a system with a real-time clock. Launch DeskTop. Apple Menu > Screen Savers. Run a screen saver that uses the full graphics screen and conceals the menu (Flying Toasters or Melt). Exit it. Verify that the menu bar clock reappears immediately.

* Launch DeskTop. Apple Menu > Screen Savers. Run Matrix. Click the mouse button. Verify that the screen saver exits. Run Matrix. Press a key. Verify that the screen saver exits.

* Configure a system with no real-time clock. Launch DeskTop. Apple Menu > Screen Savers. Run Analog Clock. Verify that an alert is shown.
* Configure a system with no real-time clock. Launch DeskTop. Apple Menu > Screen Savers. Run Digital Clock. Verify that an alert is shown.

## About This Apple II

* Configure a system with a Mockingboard and a Zip Chip, with acceleration enabled (MAME works). Launch DeskTop. Apple Menu > About This Apple II. Verify that the Mockingboard is detected.

* Configure multiple drives connected to a SmartPort controller on a higher numbered slot, a single drive connected to a SmartPort controller in a lower numbered slot. Launch DeskTop. Apple Menu > About This Apple II. Verify that the name on the lower numbered slot doesn't have an extra character at the end.

* Run on Laser 128 with memory expansion. Launch DeskTop. Copy a file to `/RAM5`. Apple Menu > About This Apple II, close it. Verify that the file is still present on `/RAM5`.

* Boot a system with only the 140k_disk1 image. Verify that About This Apple II is present in the Apple Menu.

* Configure a IIc or IIc+ in MAME. Launch DeskTop. Apple > About This Apple II. Verify that the system doesn't hang probing Slot 2.

* Configure a IIe system with a 16MB RAMFactor card (e.g. GR8RAM from https://garrettsworkshop.com/) with a single 16MB partition. Apple > About This Apple II. Verify that the calculated memory size is accurate, i.e. it is not off by 64k.

* Configure a system without a RAMWorks. Verify that the DA does not erroneously detect 16MB of RAMWorks memory.

## System Speed

* Run System Speed DA. Click Normal then click OK. Verify DeskTop does not lock up.
* Run System Speed DA. Click Fast then click OK. Verify DeskTop does not lock up.
* Run DeskTop on a IIc. Launch Control Panel > System Speed. Click Normal and Fast. Verify that the display does not switch from DHR to HR.
* Run System Speed DA. Position the cursor to the left of the animation, where it is not flickering, and move it up and down. Verify that stray pixels are not left behind by the animation.

## Puzzle

* Launch DeskTop. Apple Menu > Puzzle. Verify that the puzzle does not show as scrambled until the mouse button is clicked on the puzzle or a key is pressed. Repeat and verify that the puzzle is scrambled differently each time.
* Launch DeskTop. Apple Menu > Puzzle. Verify that you can move and close the window using the title bar before the puzzle is scrambled.
* Launch DeskTop. Apple Menu > Puzzle. Verify that you can close the window using Esc or Apple+W before the puzzle is scrambled.
* Launch DeskTop. Apple Menu > Puzzle. Scramble then solve the puzzle. After the victory sound plays, click on the puzzle again. Verify that the puzzle scrambles and that it can be solved again.
* Launch DeskTop. Apple Menu > Puzzle. Scramble the puzzle. Move the window so that only the title bar of the window is visible on screen. Use the arrow keys to move puzzle pieces. Verify that the puzzle pieces don't mispaint on the desktop.

## Run Basic Here

* Launch DeskTop. Open a volume window. Apple Menu > Run Basic Here. Verify that `/RAM` exists.
* Launch DeskTop. Open a window for a volume that is not the startup disk. Apple Menu > Run Basic Here. Verify that the PREFIX is set correctly.
* Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Ensure `BASIC.SYSTEM` is present on the startup disk. Open a window. Apple Menu > Run Basic Here. Verify that `BASIC.SYSTEM` starts.

## Joystick

* Configure a system with only a single joystick (or paddles 0 and 1). Run the DA. Verify that only a single indicator is shown.
* Configure a system with two joysticks (or paddles 2 and 3). Run the DA. Verify that after the second joystick is moved, a second indicator is shown.
* Configure a system with a single joystick. Run the DA. Move the joystick to the right and bottom extremes. Verify that the indicator does not wrap to the left or top edges.

## Find Files

* Launch DeskTop. Close all windows. Apple Menu > Find Files. Type `PRODOS` and click Search. Verify that all volumes are searched recursively.
* Launch DeskTop. Open a volume window. Apple Menu > Find Files. Type `PRODOS` and click Search. Verify that only that volume's contents are searched recursively.
* Launch DeskTop. Open a volume window. Open a folder window. Apple Menu > Find Files. Type "PRODOS" and click Search. Verify that only that folder's contents are searched recursively.
* Launch DeskTop. Open a window. Apple Menu > Find Files. Type `*` and click Search. Select a file in the list. Press Open-Apple+O. Verify that the Find Files window closes, that a window containing the file opens, and that the file icon is selected.
* Launch DeskTop. Open a window. Apple Menu > Find Files. Type `*` and click Search. Select a file in the list. Press Solid-Apple+O. Verify that the Find Files window closes, that a window containing the file opens, and that the file icon is selected.
* Launch DeskTop. Open a window. Apple Menu > Find Files. Type `*` and click Search. Double-click a file in the list. Verify that the Find Files window closes, that a window containing the file opens, and that the file icon is selected.
* Launch DeskTop. Open a volume window. Open a folder window. Activate the volume window. Apple Menu > Find Files. Type `*` and click Search. Double-click a file in the list that's inside the folder. Verify that the Find Files window closes, and that the file icon is selected.

* Create a set of nested directories, 21 levels deep or more (e.g. `/VOL/D/D/D/D/D/D/D/D/D/D/D/D/D/D/D/D/D/D/D/D/D`). Launch DeskTop and open the volume. Apple Menu > Find Files. Type `*` and click Search. Verify that the DA doesn't crash. (Not all files will be found, though.)
* Rename `/TESTS` to `/ABCDEF123456789`. Open the volume. Apple Menu > Find Files. Type *. Verify that the DA doesn't crash.
* Open `/TESTS/FIND.FILES`. Apple Menu > Find Files. Type `*` and click Search. Verify that the DA doesn't crash. (But the deeply nested `NOT.FOUND` file will not be found.)

* Open `/TESTS/FOLDER/`. Apple Menu > Find Files. Type `*` and click Search. Press Down Arrow once. Type Return. Press Down Arrow again. Verify that only one entry in the list appears highlighted.

## Print Screen

* Configure a system with an SSC in Slot 1 and an ImageWriter II. Invoke the Print Screen DA. Verify it prints a screenshot.
* Configure a system with a non-SSC in Slot 1. Invoke the Print Screen DA. Verify an alert is shown.
* Configure a system with an SSC in Slot 1 and an ImageWriter II. Invoke the Print Screen DA. Invoke the Print Catalog DA. Verify that the catalog is printed on separate lines, not all overprinted on the same line onto one.
* Using MAME (e.g. via Ample), configure a system with an SSC in Slot 1 and a Serial Printer. Invoke the Print Screen DA. Verify that the File menu is not corrupted.

## Change Type

* Select a folder. Apple > Change Type. Modify only the type (e.g. `06`). Verify that an error is shown.
* Select a folder. Apple > Change Type. Modify only the aux type (e.g. `8000`). Verify that no error is shown.
* Select a non-folder and a folder. Apple > Change Type. Modify only the type (e.g. `06`). Verify that an error is shown, and only the non-folder is modified.
* Select a non-folder and a folder. Apple > Change Type. Modify only the aux type (e.g. `8000`). Verify that no error is shown.
* Select a non-folder. Apple > Change Type. Specify `0F` as the type and click OK. Verify that an error is shown.
* Select two folders. Apple > Change Type. Modify only the type (e.g. `06`). Verify that only a single error is shown.

## DOS 3.3 Import

For the following test cases, insert a DOS 3.3 disk then run the DA.

* Select nothing. Verify that the OK button is disabled.
* Select nothing. Press the Return key. Verify that nothing happens.
* Select a slot/drive. Verify that the OK button is enabled.
* Select a slot/drive. Click OK. Verify that the catalog screen is shown.
* Select a slot/drive. Press the Return key. Verify that the OK button flashes and that the catalog dialog is shown.
* Select a slot/drive. Click Cancel. Verify that the dialog closes.
* Select a slot/drive. Press the Escape key. Verify that the Cancel button flashes and that the dialog closes.
* Select a slot/drive. Click OK. Select a file. Press the Return key. Verify that the Import button flashes.
* Select a slot/drive. Click OK. Select a file. Press the Escape key. Verify that the Cancel button flashes and that the dialog closes.

# Shortcuts (Module)

Prerequisite: In DeskTop, Apple Menu > Control Panels > Options, check Show Shortcuts on startup. Launching `DESKTOP.SYSTEM` should load the Shortcuts module instead of DeskTop, as long as there is at least one shortcut configured.

* Load Shortcuts. Put a disk in Slot 6, Drive 1. Startup > Slot 6. Verify that the system boots the disk. Repeat for all other slots with drives.

* Launch Shortcuts, invoke `BASIC.SYSTEM`. Ensure `/RAM` exists.
* Launch Shortcuts, invoke DeskTop, File > Quit, run `BASIC.SYSTEM`. Ensure `/RAM` exists.
* Launch Shortcuts. Invoke a BIN program file. Verify that during launch the screen goes completely black before the program starts, with no text characters present.

* Launch Shortcuts. Type Open-Apple and R. Ensure "Run a Program..." dialog appears
* Launch Shortcuts. Type Solid-Apple and R. Ensure "Run a Program..." dialog appears
* Launch Shortcuts. Type Open-Apple and 6. Ensure machine boots from Slot 6
* Launch Shortcuts. Type Solid-Apple and 6. Ensure machine boots from Slot 6

* Launch Shortcuts. Eject the disk with DeskTop on it. Type D (don't click). Dismiss the dialog by hitting Esc. Verify that the dialog disappears, and the Apple menu is not shown.

* Configure a system without a RAMCard. Launch Shortcuts. File > Run a Program.... Click Drives. Verify that the volume containing Shortcuts is the first disk shown.
* Configure a system with a RAMCard, and set DeskTop to copy itself to the RAMCard on startup. Launch Shortcuts. File > Run a Program.... Click Drives. Verify that the non-RAMCard volume containing Shortcuts is the first disk shown.
* Configure a system with a RAMCard, and set DeskTop to not copy itself to the RAMCard on startup. Launch Shortcuts. File > Run a Program.... Click Drives. Verify that the non-RAMCard volume containing Shortcuts is the first disk shown.

* Using DeskTop, either delete `LOCAL/SELECTOR.LIST` or just delete all shortcuts. Configure Shortcuts to start. Launch Shortcuts. Ensure DeskTop is automatically invoked and starts correctly.

* Configure a shortcut for a program with many associated files to copy to RAMCard "at boot". Reboot, and launch `DESKTOP.SYSTEM`. While the program's files are being copied to RAMCard, press Escape to cancel. Verify that not all of the files were copied to the RAMCard. Once Shortcuts starts, invoke the shortcut. Verify that the program starts correctly.
* Configure a shortcut for a program with many associated files to copy to RAMCard "at boot". Reboot, and launch `DESKTOP.SYSTEM`. Verify that all of the files were copied to the RAMCard. Once Shortcuts starts, eject the disk containing the program. Invoke the shortcut. Verify that the program starts correctly.
* Configure a shortcut for a program with many associated files to copy to RAMCard "at first use". Invoke the shortcut. Verify that the files are copied to the RAMCard, and that the program starts correctly. Return to Shortcuts by quitting the program. Eject the disk containing the program. Invoke the shortcut. Verify that the program starts correctly.
* Configure a shortcut for a folder (or another target type that can't be run outside of DeskTop, e.g. an image or desk accessory) to copy to RAMCard "at first use". Invoke the shortcut. When the "Unable to run the program." alert is shown, verify that the list of shortcuts renders correctly. Click OK. Verify that the list of shortcuts renders correctly.
* Configure a shortcut for a program with many associated files to copy to RAMCard "at first use". Invoke the shortcut. While the program's files are being copied to RAMCard, press Escape to cancel. Verify that not all of the files were copied to the RAMCard. Invoke the shortcut again. Verify that the files are copied to the RAMCard and that the program starts correctly.
* Configure a shortcut for a program with a long path to copy to RAMCard "at first use". Invoke the shortcut. Verify that long paths do not render over the dialog's frame.

* Configure a shortcut for `EXTRAS\BINSCII`. Launch Shortcuts. Invoke BINSCII. Verify that the display is not truncated.

* Launch Shortcuts. Verify the OK button is disabled. Click on an item. Verify the OK button becomes enabled. Click on a blank option. Verify the OK button becomes disabled. Use the arrow keys to move selection. Verify that the OK button becomes enabled.
* Launch Shortcuts. Select an item. Verify that the OK button becomes enabled. File > Run a Program... Cancel the dialog. Verify that selection is cleared and that the OK button is disabled.

* Launch Shortcuts. File > Run a Program.... Select a folder. Verify that the OK button is disabled.

* Configure a system with DeskTop booting from slot 7 and a floppy drive in slot 6. Place a ProDOS formatted disk without `PRODOS` in the floppy drive. Invoke `DESKTOP.SYSTEM`. While the "Starting Shortcuts..." progress bar is displayed, hold down Apple and 6. Verify that when the progress bar disappears the screen clears completely to black and that the message "UNABLE TO LOAD PRODOS" is displayed properly in 40-column mode.

* Launch Shortcuts. File > Run a Program.... Select `/TESTS/ALIASES/BASIC.ALIAS`. Verify that the program starts.
* Launch Shortcuts. File > Run a Program.... Select `/TESTS/ALIASES/DELETED.ALIAS`. Verify that an alert is shown.
* Launch DeskTop. Create a shortcut for `/TESTS/ALIASES/BASIC.ALIAS`. Launch Shortcuts. Invoke the shortcut. Verify that the program starts.
* Launch DeskTop. Create a shortcut for `/TESTS/ALIASES/DELETED.ALIAS`. Launch Shortcuts. Invoke the shortcut. Verify that an alert is shown.
* Launch DeskTop. Create a shortcut for `/TESTS/ALIASES/BASIC.ALIAS`. Delete the alias. Launch Shortcuts. Invoke the shortcut. Verify that an alert is shown.

# Disk Copy

* Launch DeskTop. Special > Copy Disk.... File > Quit. Special > Copy Disk.... Ensure drive list is correct.

* Launch DeskTop. Special > Copy Disk.... Press Escape key. Verify that menu keyboard mode starts.
* Launch DeskTop. Special > Copy Disk.... Press Open-Apple Q. Verify that DeskTop launches.
* Launch DeskTop. Special > Copy Disk.... Press Solid-Apple Q. Verify that DeskTop launches.

* Launch DeskTop. Clear selection. Special > Copy Disk.... Verify that no volume is selected and the OK button is dimmed.
* Launch DeskTop. Select a volume icon. Special > Copy Disk.... Verify that the corresponding volume is selected and the OK button is not dimmed.

* Launch DeskTop. Special > Copy Disk. Copy a disk with more than 999 blocks. Verify thousands separators are shown in block counts.
* Launch DeskTop. Special > Copy Disk.... Copy a 32MB disk image using Quick Copy (the default mode). Verify that the screen is not garbled, the progress bar updates correctly, and that the copy is successful.
* Launch DeskTop. Special > Copy Disk.... Copy a 32MB disk image using Disk Copy (the other mode). Verify that the screen is not garbled, the progress bar updates correctly, and that the copy is successful.

* Launch DeskTop. Special > Copy Disk.... Make a device selection (using mouse or keyboard) but don't click OK. Open the menu (using mouse or keyboard) but dismiss it. Verify that source device wasn't accepted.
* Launch DeskTop. Special > Copy Disk.... Select a drive using the mouse or keyboard, but don't click OK. Double-click the same drive. Verify that it was accepted, and that a prompt for an appropriate destination drive was shown.
* Launch DeskTop. Special > Copy Disk.... Select a drive using the mouse or keyboard, but don't click OK. Double-click a different drive. Verify that it was accepted, and that a prompt for an appropriate destination drive was shown.

* Rename the `MODULES/DISK.COPY` file to something else. Launch DeskTop. Special > Copy Disk.... Verify that an alert is shown. Cancel the alert. Verify that DeskTop continues to run.
* Launch DeskTop. Eject the startup disk. Special > Copy Disk.... Verify that an alert is shown. Cancel the alert. Verify that DeskTop continues to run.
* Launch DeskTop. Eject the startup disk. Special > Copy Disk.... Verify that an alert is shown. Reinsert the startup disk. Click OK in the alert. Verify that Disk Copy starts.
* Configure a system with a RAMCard. Launch DeskTop, ensure it copies itself to RAMCard. Special > Copy Disk.... Verify that Disk Copy starts.
* Launch DeskTop. Open and position a window. Special > Copy Disk.... File > Quit. Verify that DeskTop restores the window.
* On a IIgs, go to Control Panel, check RGB Color. Verify that the display shows in color. Special > Copy Disk.... Enter the IIgs control panel (Control+Shift+Open-Apple+Esc), and exit. Verify that the display remains in color.
* On a IIgs, go to Control Panel, uncheck RGB Color. Verify that the display shows in monochrome. Special > Copy Disk.... Enter the IIgs control panel (Control+Shift+Open-Apple+Esc), and exit. Verify that the display resets to monochrome.

* Configure a system with a RAMDisk in Slot 3, e.g. using `RAM.DRV.SYSTEM` or `RAMAUX.SYSTEM`. Launch DeskTop. Special > Copy Disk.... Verify that the RAMDisk appears.
* Configure a system with 8 or fewer drives. Launch DeskTop. Special > Copy Disk.... Verify that the scrollbar is inactive.
* Configure a system with 9 or more drives. Launch DeskTop. Special > Copy Disk.... Verify that the scrollbar is active.

* Launch DeskTop. Special > Copy Disk.... Verify that ProDOS disk names in the device list have adjusted case (e.g. "Volume" not "VOLUME"). Verify that GS/OS disk names in the device list have correct case (e.g. "GS.OS.disk" not "Gs.Os.Disk").
* Launch DeskTop. Special > Copy Disk.... Verify that Pascal disk names in the device list do not have adjusted case (e.g. "TGP:" not "Tgp:").
* Launch DeskTop. Special > Copy Disk.... Verify that DOS 3.3 disk names in the device list appear as "DOS 3.3" and do not have adjusted case.

* Launch DeskTop. Special > Copy Disk.... Select a ProDOS disk as a source disk. Verify that after the "Insert source disk" prompt is dismissed, the volume name appears on the "Source" line and the name has adjusted case (e.g. "Volume" not "VOLUME").
* Launch DeskTop. Special > Copy Disk.... Select a GS/OS disk as a source disk. Verify that after the "Insert source disk" prompt is dismissed, the volume name appears on the "Source" line and the name has correct case (e.g. "GS.OS.disk" not "Gs.Os.Disk").
* Launch DeskTop. Special > Copy Disk.... Select a Pascal disk as a source disk. Verify that after the "Insert source disk" prompt is dismissed, the volume name appears on the "Source" line and the name does not have adjusted case (e.g. "TGP:" not "Tgp:").
* Launch DeskTop. Special > Copy Disk.... Select a DOS 3.3 disk as a source disk. Verify that after the "Insert source disk" prompt is dismissed, no volume name appears on the "Source" line.

* Launch DeskTop. Special > Copy Disk.... Select a ProDOS disk as a destination disk. Verify that in the "Are you sure you want to erase ...?" dialog that the name has adjusted case (e.g. "Volume" not "VOLUME"), and the name is quoted.
* Launch DeskTop. Special > Copy Disk.... Select a GS/OS disk as a destination disk. Verify that in the "Are you sure you want to erase ...?" dialog that the name has correct case (e.g. "GS.OS.disk" not "Gs.Os.Disk"), and the name is quoted.
* Launch DeskTop. Special > Copy Disk.... Select a Pascal disk as a destination disk. Verify that in the "Are you sure you want to erase ...?" dialog that the name does not have adjusted case (e.g. "TGP:" not "Tgp:"), and the name is quoted.
* Launch DeskTop. Special > Copy Disk.... Select a DOS 3.3 disk as a destination disk. Verify that in the "Are you sure you want to erase ...?" dialog that the prompt describes the disk as DOS 3.3 using slot and drive, and is not quoted.
* Launch DeskTop. Special > Copy Disk.... Select a CP/M disk as a destination disk. Verify that in the "Are you sure you want to erase ...?" dialog that the prompt describes the disk using slot and drive, and is not quoted.

* Configure Virtual II with two OmniDisks formatted as ProDOS volumes mounted. Launch DeskTop. Special > Copy Disk.... Select the OmniDisks as Source and Destination. Verify that after being prompted to insert the source and destination disks, a "Are you sure you want to erase ...?" confirmation prompt is shown.

* Launch DeskTop. Special > Copy Disk.... Verify that the OK button is disabled. Select an item in the list with the keyboard. Verify that the OK button enables. Click in the blank space in the list below the items. Verify that the OK button disables. Click an item in the list. Verify that the OK button enables. Click OK to specify a source disk. Verify that the OK button disables. Repeat the above cases when selecting the destination disk.
* Launch DeskTop. Special > Copy Disk.... Select a source disk. Verify that the OK button enables. Click Read Drives. Verify that the OK button disables. Select a source disk then click OK. Click OK. Select a destination disk. Click Read Drives. Verify that the OK button disables.
* Launch DeskTop. Special > Copy Disk.... Select a source disk and a destination disk. Cancel the copy. Verify that the OK button is disabled.
* Launch DeskTop. Special > Copy Disk.... Select a source disk and a destination disk. Allow the copy to complete. Verify that the OK button is disabled.

* Launch DeskTop. Special > Copy Disk.... Select a source disk and a destination disk. Allow the copy to start, but eject the destination disk in the middle of the copy. Verify that block write errors are shown (with alert sounds).
* Launch DeskTop. Special > Copy Disk.... Select a source disk and a destination disk. Allow the copy to start, but eject the source disk in the middle of the copy. Verify that block read errors are shown (with alert sounds), and that the error text does not overlap the progress bar.

* Configure a system with two drives capable of holding the same capacity non-140k disk (e.g. two 800k or 32MB drives). Start with a disk in first drive, but with the second drive empty. Launch DeskTop. Special > Copy Disk.... Verify that the second drive shows "Unknown" in the source drive list. Select the first drive and click OK. Verify that the second drive does not appear in the destination drive list. Place a disk in the second drive. Click Read Drives. Verify that the second drive now appears with the correct name in the source drive list. Select the first drive and click OK. Verify that the second drive now appears in the destination drive list.

* Populate a ProDOS disk with several large files, then delete all but the last. Launch DeskTop. Special > Copy Disk.... Select the prepared disk. Ensure Options > Quick Copy is checked. Select an appropriate destination disk. Proceed with the copy. Verify that the "Blocks to transfer" count is accurate (i.e. less than the total block count), and the blocks read/written count up to the transfer count accurately.
* Populate a ProDOS disk with several large files, then delete all but the last. Launch DeskTop. Special > Copy Disk.... Select the prepared disk. Select Options > Disk Copy. Select an appropriate destination disk. Proceed with the copy. Verify that the "Blocks to transfer" count is equal to the total block count of the device, and the blocks read/written count up to the transfer count accurately.

# Alerts

* Launch DeskTop. Trigger an alert with only OK (e.g. running a shortcut with disk ejected). Verify that Escape key closes alert.
* Launch Shortcuts. Trigger an alert with only OK (e.g. running a shortcut that only works in DeskTop, like a DA). Verify that Escape key closes alert.
* Launch DeskTop. Run Special > Copy Disk. Trigger an alert with only OK (e.g. let a copy complete successfully). Verify that Escape key closes alert.
* Launch DeskTop. Select 3 files and drag them to another volume. Drag the same 3 files to the other volume again. When the alert with Yes/No/All buttons appears, mouse down on the Yes button, drag the cursor off the button, and release the mouse button. Verify that nothing happens. Click Yes to allow the copy to continue. Repeat for No and All.

# File Picker

This covers:

* Shortcuts: File > Run a Program...
* DeskTop: File > Copy To...
* DeskTop: Shortcuts > Add a Shortcut...
* DeskTop: Shortcuts > Edit a Shortcut...

Test the following in all of the above, except where called out specifically:

* Browse to a directory containing multiple files. Hold an Apple key and start typing a filename. Verify that a prefix-matching file or the subsequent file is selected, or the last file. For example, if the files "Alfa", "November" and "Whiskey" are present, typing "A" selects "Alfa", typing "AB" selects "Alfa", typing "AL" selects "Alfa", typing "ALFAA" selects "November", typing "B" selects "November", typing "Z" selects "Whiskey". Repeat including filenames with numbers and periods.
* Browse to a directory containing multiple files. Hold an Apple key and start typing a filename. Move the mouse, or press a key without holding Apple. Hold an Apple key and start typing another filename. Verify that the matching is reset.
* Browse to a directory containing no files. Hold an Apple key and start typing a filename. Verify nothing happens.
* Browse to a directory containing one or more files starting with lowercase letters (AppleWorks or GS/OS). Verify the files appear with correct names. Press Apple+letter. Verify that the first file starting with that letter is selected.

* Browse to a directory containing one or more files with starting with mixed case (AppleWorks or GS/OS). Verify the filenames appear with correct case.
* Browse to a directory containing 7 files. Verify that the scrollbar is inactive.
* Browse to a directory containing 8 files. Verify that the scrollbar is active. Press Apple+Down. Verify that the scrollbar thumb moves to the bottom of the track.

* Launch DeskTop. Special > Format Disk.... Select a drive with no disk, let the format fail and cancel. File > Copy To.... Verify that the file list is populated.

* Browse to `/TESTS/SORTING`. Verify that "A" sorts before "A.B".

* Use DeskTop's Options Control Panel and enable "Show invisible files". Use the file picker to browse to `/TESTS/PROPERTIES/VISIBLE.HIDDEN`. Verify that `INVISIBLE` appears in the list. Disable the option. Use the file picker again, and verify that `INVISIBLE` does not appear in the list.

* In Shortcuts > Add/Edit a Shortcut... name field:
  * Type a non-path, non-control character. Verify that it is accepted.
  * Type a control character that is not an alias for an Arrow key (so not Control+H, J, K, or U), editing key (so not Control+F, Control+X), Return (Control+M), Escape (Control+[), or a button shortcut (so not Control+D, O, or C) e.g. Control+Q. Verify that it is ignored.
  * Move the cursor over the text field. Verify that the cursor changes to an I-beam.
  * Move the cursor off the text field. Verify that the cursor changes to a pointer.
  * Launch DeskTop. Shortcuts > Add a Shortcut.... Press Apple+1 through Apple+5. Verify that the radio buttons on the right are selected.

* Click the Drives button. Verify that on-line volumes are listed in alphabetical order.
* Click the Drives button. Manually eject a disk. Click the Drives button again. Verify that the ejected disk is removed from the list.

Repeat for each file picker:
* Select a folder in the list box. Verify that the Open button is not dimmed.
* Select a non-folder in the list box. Verify that the Open button is dimmed.
* Navigate to the root directory of a disk. Verify that the Close button is not dimmed.
* Open a folder. Verify that the Close button is not dimmed, that there is no selection, and that Open is dimmed. Hit Close until at the root. Verify that Close is dimmed.
* Click the Drives button. Verify that the Close button is dimmed.
* Click the Drives button. Verify that the OK button is dimmed.
* Verify that dimmed buttons don't respond to clicks.
* Verify that dimmed buttons don't respond to keyboard shortcuts (Return for OK, Control+O for Open, Control+C for Close).

For DeskTop's File > Copy To... file picker, start by selecting a file icon, then File > Copy To...:
* Open a volume or folder. Clear selection. Verify that the OK button is not dimmed.
* Click the Drives button. Verify that the OK button is dimmed.
* Click the Drives button. Select a volume icon. Verify that the OK button is not dimmed. Click OK. Verify that the file is copied into the selected volume's root directory.

For DeskTop's Shortcut > Edit a Shortcut... file picker:
* Create a shortcut not on the startup disk. Edit the shortcut. Verify that the file picker shows the shortcut target volume and file selected.
* Create a shortcut on a removable volume. Eject the volume. Edit the shortcut. Verify that the file picker initializes to the drives list, and does not crash or show corrupted results.
* Clear selection. Verify that the OK button is dimmed.
* Click the Drives button. Verify that the OK button is dimmed.
* Click the Drives button. Select a volume. Verify that the OK button is not dimmed.
* Select a folder. Verify that the OK button is not dimmed.

For Shortcuts's File > Run a Program... file picker:
* Navigate to an empty volume. Verify that OK is disabled.
* Move the mouse cursor over a folder in the list, and click to select it. Move the mouse cursor away from the click location but over the same item. Double-click. Verify that the folder opens with only the two clicks.
* Move the mouse cursor over a folder in the list that is not selected. Double-click. Verify that the folder opens with only the two clicks.
* Clear selection. Verify that the OK button is dimmed.
* Click the Drives button. Select a volume. Verify that the OK button is dimmed.
* Select a folder. Verify that the OK button is dimmed.

# Text Input Fields

This covers:
 * DeskTop's modal name dialog, used in:
   * Special > Format Disk...
   * Special > Erase Disk...
 * DeskTop's modeless rename prompt, used in:
   * File > New Folder
   * File > Duplicate
   * File > Rename
   * Note that this uniquely shows text centered, so pay close attention!
 * DeskTop's Add/Edit a Shortcut dialog (an extended File Picker)
 * Find Files DA.
 * Map DA:
   * With input field fully on screen.
   * With input field partially off screen.
   * With input field completely off screen.
   * With window moved to bottom of screen so that only the title bar is visible.

Repeat for each field:
 * Type a printable character.
   * Should insert a character at caret, unless invalid in context or length limit reached. Limits are:
     * File name: 15 characters; only alpha, numeric, and period accepted; only alpha at start
     * Find Files: 15 characters; only alpha, numeric, period, and * and ? accepted
     * Shortcut name: 14 characters
   * Mouse cursor should be hidden until moved.
   * Test with caret at start, in middle, and at end of the string.
 * Delete key
   * Should delete character to left of caret, unless at start of string.
   * Mouse cursor should be hidden until moved.
   * Test with caret at start, in middle, and at end of the string.
 * Control+F (Forward delete)
   * Should delete character to right of caret, unless at end of string.
   * Mouse cursor should be hidden until moved.
   * Test with caret at start, in middle, and at end of the string.
 * Control+X (or Clear key on IIgs)
   * Should clear all text.
   * Mouse cursor should be hidden until moved.
   * Test with caret at start, in middle, and at end of the string.
 * Left Arrow
   * Should move caret one character to the left, unless at start of string.
   * Mouse cursor should be hidden until moved.
   * Test with caret at start, in middle, and at end of the string.
 * Right Arrow
   * Should move caret one character to the right, unless at end of string.
   * Mouse cursor should be hidden until moved.
   * Test with caret at start, in middle, and at end of the string.
 * Apple+Left Arrow
   * Should move caret to start of string.
   * Mouse cursor should be hidden until moved.
   * Test with caret at start, in middle, and at end of the string.
 * Apple+Right Arrow
   * Should move caret to end of string.
   * Mouse cursor should be hidden until moved.
   * Test at start, in middle, and at end of the string.
 * Click to left of string. Verify the mouse cursor is not obscured.
 * Click to left of caret, within the string. Verify the mouse cursor is not obscured.
 * Click to right string. Verify the mouse cursor is not obscured.
 * Click to right of caret, within the string. Verify the mouse cursor is not obscured.
 * Place caret within string, click OK.
 * Place caret at start of string, click OK.
 * Place caret at end of string, click OK.

Watch out for:
 * Parts of the caret not erased.
 * Text being truncated when OK clicked.
 * Caret being placed in the wrong place by a click.
 * Mispaint when cleared with Control+X (or Clear key on IIgs)

# List Box Controls

This covers:
* File Pickers
* Disk Copy
* Sounds DA
* Find Files DA

Repeat for each list box:
* Verify the following keyboard shortcuts:
  * If the scrollbar is not enabled, the view should not scroll.
  * Up Arrow
    * If there is no selection, selects the last item and scrolls it into view.
    * Otherwise, selects the previous item and scrolls it into view.
  * Down Arrow
    * If there is no selection, selects the first item and scrolls it into view.
    * Otherwise, selects the next item and scrolls it into view.
  * Apple+Up Arrow
    * Scrolls one page up.
    * Selection is not changed.
  * Apple+Down Arrow
    * Scrolls one down up.
    * Selection is not changed.
  * Open-Apple+Solid-Apple+Up Arrow
    * Scrolls the view so that the first item is visible.
    * Selects the first item.
  * Open-Apple+Solid-Apple+Down Arrow
    * Scrolls the view so that the last item is visible.
    * Selects the last item.
* Hold down the mouse button on the scrollbar's up arrow or down arrow; verify that the scrolling continues as long as the button is held down.
* Click on an item. Verify it is selected. Click on white space below the items (if possible). Verify that selection is cleared.

For the Sounds DA:
* Click on an item. Verify it is selected, and plays the sound. Click on the same selected item. Verify it plays the sound again.

Repeat for each list box where the contents are dynamic:
* Populate the list so that the scrollbar is active. Scroll down by one row. Repopulate the list box so that the scrollbar is inactive. Verify that all expected items are shown, and hitting the Up Arrow key selects the last item.
* Populate the list so that the scrollbar is active, and scrolled to the top. Repopulate the list so that the scrollbar is still active. Verify that the scrollbar doesn't repaint/flicker. (This is easiest in the Shortcuts > Add a Shortcut File Picker.)

# Menus

* Click to open a menu. Without clicking again, move the mouse pointer up and down over the menu items, while simultaneously tapping the 'A' key. Verify that the key presses do not cause other menus to open instead.
* Click to open a menu. Move the mouse over menu bar items and menu items. Verify that the highlight changes immediately when the mouse pointer hot spot is over the next item, not delayed by one movement. For example, if the mouse moves down and the next item doesn't highlight, moving the mouse right also shouldn't cause it to highlight.

The following steps exercise the menu as "pull down" using the mouse:

* Mouse-over a menu bar item, and press and hold the mouse button to pull down the menu. Drag to an item and release the button. Verify the menu closes and the item is invoked.
* Mouse-over a menu bar item, and press and hold the mouse button to pull down the menu. Drag to a separator and release the button. Verify the menu closes.
* Mouse-over a menu bar item, and press and hold the mouse button to pull down the menu. Drag off of the menu and release the button. Verify the menu closes.

The following steps exercise the menu as "drop down" using the mouse:

* Click (press and release the mouse button) on a menu bar item. Move the mouse over an item and click it. Verify the menu closes and that the item is invoked.
* Click (press and release the mouse button) on a menu bar item. Move the mouse over a separator and click it. Verify the menu closes.
* Click (press and release the mouse button) on a menu bar item. Move the mouse off the menu and click. Verify the menu closes.

The following steps exercise the menu as "drop down" using the keyboard:

* Press the Escape key. Verify that the first menu opens. Press the Escape key again. Verify that the menu closes.
* Press the Escape key. Verify that the first menu opens. Use the Up, Down, Left and Right Arrow keys to move among menu items. Press the Escape key again. Verify that the menu closes.
* Press the Escape key. Verify that the first menu opens. Use the Up, Down, Left and Right Arrow keys to move among menu items. Press the Return key. Verify that the menu closes, and that the item is invoked.

The following steps exercise the menu as "drop down" using the mouse to initiate and finish the action, but with the keyboard as an intermediate step:

* Click (press and release the mouse button) on a menu bar item. Use the Up, Down, Left and Right Arrow keys to move among menu items. Move the mouse over an item and click it. Verify the menu closes, and that the item is invoked.
* Click (press and release the mouse button) on a menu bar item. Use the Up, Down, Left and Right Arrow keys to move among menu items. Move the mouse over a separator and click it. Verify the menu closes.
* Click (press and release the mouse button) on a menu bar item. Use the Up, Down, Left and Right Arrow keys to move among menu items. Move the mouse off the menu and click. Verify the menu closes.

The following steps exercise the menu as "drop down" using the keyboard to initiate and finish the action, but with the mouse as an intermediate step:

* Press the Escape key. Verify that the first menu opens. Move the mouse over menu items. Press the Escape key again. Verify that the menu closes.
* Press the Escape key. Verify that the first menu opens. Move the mouse over a menu item. Press the Return key. Verify that the menu closes, and that the item is invoked.

The following steps exercise the menu as "drop down" using the mouse to initiate the action and the keyboard to finish the action:

* Click (press and release the mouse button) on a menu bar item. Use the mouse to move over an item. Use the arrow keys to select a different item. Press Escape. Verify that the menu closes.
* Click (press and release the mouse button) on a menu bar item. Use the mouse to move over an item. Use the arrow keys to select a different item. Press Return. Verify that the menu closes, and that the item is invoked.

The following steps exercise the menu as "drop down" using the keyboard to initiate the action and the mouse to finish the action:

* Press the Escape key. Verify that the first menu opens. Click an item with the mouse. Verify that the menu closes, and that the item is invoked.
* Press the Escape key. Verify that the first menu opens. Click a separator with the mouse. Verify that the menu closes.
* Press the Escape key. Verify that the first menu opens. Click outside the menu. Verify that the menu closes.

* Click on a menu to show it. While it is open, press the shortcut key for a command (e.g. Open-Apple+Q to Quit). Verify that the menu closes and that the command is invoked.
* Press Escape to activate the menu. While it is open, press the shortcut key for a command (e.g. Open-Apple+Q to Quit). Verify that the menu closes and that the command is invoked.
* Press Escape to activate the menu. Arrow down to an item. Press a non-arrow, non-shortcut key (e.g. a punctuation key). Press Return. Verify that the menu item is activated.

* Launch DeskTop. Close all windows. Press the Escape key. Use the Left and Right Arrow keys to highlight the View menu. Verify that all menu items are disabled. Press the Up and Down arrow keys. Verify that the cursor position does not change.

# Mouse Keys

* Enter MouseKeys mode (Open-Apple+Solid-Apple+Space). Using the Left, Right, Up and Down Arrow keys to move the mouse and the Solid-Apple (or Option) key as the mouse button, "pull down" a menu and select an item. Verify that after the item is selected that MouseKeys mode is still active. Press Escape to exit MouseKeys mode.
* Enter MouseKeys mode (Open-Apple+Solid-Apple+Space). Using the Left, Right, Up and Down Arrow keys to move the mouse and the Solid-Apple (or Option) key as the mouse button, "drop down" a menu and select an item. Verify that after the item is selected that MouseKeys mode is still active. Press Escape to exit MouseKeys mode.

* Perform the following tests in DeskTop using Mouse Keys mode:
  * Use the arrow keys to move the mouse to the top, bottom, left, and right edges of the screen. Verify that the mouse is clamped to the edges and does not wrap.
  * Select an icon. Press the Return key. Verify that Mouse Keys mode is not silently exited, and the cursor is not distorted.
  * Use keys to click on a menu. Without holding the button down, move over the menu items. Verify that the menu does not spontaneously close.
  * Use keys to double-click on an icon. Verify it opens.


# Keyboard Window Control

These shortcuts only apply in DeskTop.

* Open a window. Press Apple+M. Use the Left, Right, Up and Down Arrow keys to move the window outline. Press Escape. Verify that the window does not move.
* Open a window. Press Apple+M. Use the Left, Right, Up and Down Arrow keys to move the window outline. Press Return. Verify that the window moves to the new location.
* Open a window. Press Apple+G. Use the Left, Right, Up and Down Arrow keys to resize the window outline. Press Escape. Verify that the window does not resize.
* Open a window. Press Apple+G. Use the Left, Right, Up and Down Arrow keys to resize the window outline. Press Return. Verify that the window resizes.

# Localization

Repeat these tests for all language builds:

* Launch DeskTop. Click the Apple Menu. Verify that no screen corruption occurs.
* Launch DeskTop. Click the Shortcuts menu. Verify that no screen corruption occurs.
* Launch DeskTop. Select a file. File > Copy To.... Verify that directories appear within volumes.

# Performance

For the following tests, run on non-IIgs system with any acceleration disabled.

* Launch DeskTop. Open `/TESTS/HUNDRED.FILES`. Click the down arrow in the vertical scroll bar. Verify that the window repaints in under 1s, and that the mouse cursor remains responsive.
* Launch DeskTop. Open `/TESTS/HUNDRED.FILES`. Press Apple-A to Select All. Verify that the visible icons all become selected in under 1s, and that the mouse cursor remains responsive. Click a blank area within the window to clear selection. Verify that the visible icons all become selected in under 1s, and that the mouse cursor remains responsive.
* Launch DeskTop. Open `/TESTS/HUNDRED.FILES`. Type `F`. Verify that icon `F1` becomes selected in under 2s. Without moving the mouse, type `9`. Verify that icon `F9` becomes selected in under 1s. Without moving the mouse, type `9`. Verify that icon `F99` becomes selected and scrolled into view in under 2s.
* Launch DeskTop. Open `/TESTS/HUNDRED.FILES`. Press the Left Arrow key. Verify that icon `F1` becomes selected. Use the arrow keys to move selection. Verify that changing selection takes under 0.5s when scrolling is not required.
* Launch DeskTop. Open `/TESTS/HUNDRED.FILES`. Drag a select rectangle around all the visible icons in the window. Verify that the icons all become selected in under 1s, and that the mouse cursor remains responsive.

