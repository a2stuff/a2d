a2d.ConfigureRepaintTime(0.25)

--[[
  Launch DeskTop. Special > Copy Disk.... File > Quit. Special > Copy
  Disk.... Ensure drive list is correct.
]]
--[[
  Launch DeskTop. Special > Copy Disk.... Press Escape key. Verify
  that menu keyboard mode starts.
]]
--[[
  Launch DeskTop. Special > Copy Disk.... Press Open-Apple Q. Verify
  that DeskTop launches.
]]
--[[
  Launch DeskTop. Special > Copy Disk.... Press Solid-Apple Q. Verify
  that DeskTop launches.
]]
--[[
  Launch DeskTop. Clear selection. Special > Copy Disk.... Verify that
  no volume is selected and the OK button is dimmed.
]]
--[[
  Launch DeskTop. Select a volume icon. Special > Copy Disk.... Verify
  that the corresponding volume is selected and the OK button is not
  dimmed.
]]
--[[
  Launch DeskTop. Special > Copy Disk. Copy a disk with more than 999
  blocks. Verify thousands separators are shown in block counts.
]]
--[[
  Launch DeskTop. Special > Copy Disk.... Copy a 32MB disk image using
  Quick Copy (the default mode). Verify that the screen is not
  garbled, the progress bar updates correctly, and that the copy is
  successful.
]]
--[[
  Launch DeskTop. Special > Copy Disk.... Copy a 32MB disk image using
  Disk Copy (the other mode). Verify that the screen is not garbled,
  the progress bar updates correctly, and that the copy is successful.
]]
--[[
  Launch DeskTop. Special > Copy Disk.... Make a device selection
  (using mouse or keyboard) but don't click OK. Open the menu (using
  mouse or keyboard) but dismiss it. Verify that source device wasn't
  accepted.
]]
--[[
  Launch DeskTop. Special > Copy Disk.... Select a drive using the
  mouse or keyboard, but don't click OK. Double-click the same drive.
  Verify that it was accepted, and that a prompt for an appropriate
  destination drive was shown.
]]
--[[
  Launch DeskTop. Special > Copy Disk.... Select a drive using the
  mouse or keyboard, but don't click OK. Double-click a different
  drive. Verify that it was accepted, and that a prompt for an
  appropriate destination drive was shown.
]]
--[[
  Rename the `MODULES/DISK.COPY` file to something else. Launch
  DeskTop. Special > Copy Disk.... Verify that an alert is shown.
  Cancel the alert. Verify that DeskTop continues to run.
]]
--[[
  Launch DeskTop. Eject the startup disk. Special > Copy Disk....
  Verify that an alert is shown. Cancel the alert. Verify that DeskTop
  continues to run.
]]
--[[
  Launch DeskTop. Eject the startup disk. Special > Copy Disk....
  Verify that an alert is shown. Reinsert the startup disk. Click OK
  in the alert. Verify that Disk Copy starts.
]]
--[[
  Launch DeskTop. Open and position a window. Special > Copy Disk....
  File > Quit. Verify that DeskTop restores the window.
]]
--[[
  Configure a system with 8 or fewer drives. Launch DeskTop. Special >
  Copy Disk.... Verify that the scrollbar is inactive.
]]
--[[
  Configure a system with 9 or more drives. Launch DeskTop. Special >
  Copy Disk.... Verify that the scrollbar is active.
]]
--[[
  Configure Virtual II with two OmniDisks formatted as ProDOS volumes
  mounted. Launch DeskTop. Special > Copy Disk.... Select the
  OmniDisks as Source and Destination. Verify that after being
  prompted to insert the source and destination disks, a "Are you sure
  you want to erase ...?" confirmation prompt is shown.
]]
--[[
  Launch DeskTop. Special > Copy Disk.... Verify that the OK button is
  disabled. Select an item in the list with the keyboard. Verify that
  the OK button enables. Click in the blank space in the list below
  the items. Verify that the OK button disables. Click an item in the
  list. Verify that the OK button enables. Click OK to specify a
  source disk. Verify that the OK button disables. Repeat the above
  cases when selecting the destination disk.
]]
--[[
  Launch DeskTop. Special > Copy Disk.... Select a source disk. Verify
  that the OK button enables. Click Read Drives. Verify that the OK
  button disables. Select a source disk then click OK. Click OK.
  Select a destination disk. Click Read Drives. Verify that the OK
  button disables.
]]
--[[
  Launch DeskTop. Special > Copy Disk.... Select a source disk and a
  destination disk. Cancel the copy. Verify that the OK button is
  disabled.
]]
--[[
  Launch DeskTop. Special > Copy Disk.... Select a source disk and a
  destination disk. Allow the copy to complete. Verify that the OK
  button is disabled.
]]
--[[
  Launch DeskTop. Special > Copy Disk.... Select a source disk and a
  destination disk. Allow the copy to start, but eject the destination
  disk in the middle of the copy. Verify that block write errors are
  shown (with alert sounds).
]]
--[[
  Launch DeskTop. Special > Copy Disk.... Select a source disk and a
  destination disk. Allow the copy to start, but eject the source disk
  in the middle of the copy. Verify that block read errors are shown
  (with alert sounds), and that the error text does not overlap the
  progress bar.
]]
--[[
  Configure a system with two drives capable of holding the same
  capacity non-140k disk (e.g. two 800k or 32MB drives). Start with a
  disk in first drive, but with the second drive empty. Launch
  DeskTop. Special > Copy Disk.... Verify that the second drive shows
  "Unknown" in the source drive list. Select the first drive and click
  OK. Verify that the second drive does not appear in the destination
  drive list. Place a disk in the second drive. Click Read Drives.
  Verify that the second drive now appears with the correct name in
  the source drive list. Select the first drive and click OK. Verify
  that the second drive now appears in the destination drive list.
]]
--[[
  Populate a ProDOS disk with several large files, then delete all but
  the last. Launch DeskTop. Special > Copy Disk.... Select the
  prepared disk. Ensure Options > Quick Copy is checked. Select an
  appropriate destination disk. Proceed with the copy. Verify that the
  "Blocks to transfer" count is accurate (i.e. less than the total
  block count), and the blocks read/written count up to the transfer
  count accurately.
]]
--[[
  Populate a ProDOS disk with several large files, then delete all but
  the last. Launch DeskTop. Special > Copy Disk.... Select the
  prepared disk. Select Options > Disk Copy. Select an appropriate
  destination disk. Proceed with the copy. Verify that the "Blocks to
  transfer" count is equal to the total block count of the device, and
  the blocks read/written count up to the transfer count accurately.
]]
