--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl4 superdrive -sl5 superdrive -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -flop1 res/disk_c.2mg -flop2 res/disk_d.2mg -flop3 res/disk_a.2mg -flop4 res/disk_b.2mg -flop5 res/pascal_floppy.dsk -flop6 res/prodos_floppy1.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

local s6d1 = apple2.GetDiskIIS6D1()
local s6d2 = apple2.GetDiskIIS6D2()

local pascal_image = s6d1.filename
s6d1:unload()
local prodos_image = s6d2.filename
s6d2:unload()

local s5d1 = manager.machine.images[":sl5:superdrive:fdc:0:35hd"]
local s5d2 = manager.machine.images[":sl5:superdrive:fdc:1:35hd"]
local s4d1 = manager.machine.images[":sl4:superdrive:fdc:0:35hd"]
local s4d2 = manager.machine.images[":sl4:superdrive:fdc:1:35hd"]

local disk_a = s5d1.filename
s5d1:unload()
local disk_b = s5d2.filename
s5d2:unload()
local disk_c = s4d1.filename
s4d1:unload()
local disk_d = s4d2.filename
s4d2:unload()

a2d.CheckAllDrives()

--[[
  Launch DeskTop. Open a window for a volume icon. Open a folder
  within the window. Select the volume icon. Special > Check Drive.
  Verify that both windows are closed.
]]
test.Step(
  "windows close on Check Drive",
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", {leave_parent=true})
    a2d.SelectPath("/A2.DESKTOP", {keep_windows=true})
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_CHECK_DRIVE)
    emu.wait(5)
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "both windows should close")
end)

--[[
  Launch DeskTop. Open a window for a volume icon. Special > Check All
  Drives. Verify that all windows close, and that volume icons are
  correctly updated.
]]
test.Step(
  "window close on Check All Drives",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.CheckAllDrives()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "window should close")
end)

--[[
  Launch DeskTop. Special > Check All Drives. Verify that no error is
  shown.
]]
test.Step(
  "Check All Drives works",
  function()
    a2d.CloseAllWindows()
    a2d.ClearSelection()
    a2d.Reboot()
    a2d.WaitForDesktopReady()
    a2d.CheckAllDrives()
    a2dtest.ExpectAlertNotShowing()
end)

--[[
  Launch DeskTop. Mount a new drive that will appear in the middle of
  the drive order. Special > Check All Drives. Verify that no new
  volumes overdraw old volumes.
]]
test.Step(
  "new drive does not overdraw old volumes",
  function()
    a2d.CloseAllWindows()
    a2d.Reboot()
    a2d.WaitForDesktopReady()
    test.Snap("note volume icon positions")
    s5d1:load(disk_a)
    a2d.CheckAllDrives()
    test.Snap("verify new icon does not overlap old icons")

    -- cleanup
    s5d1:unload()
    a2d.CheckAllDrives()
end)

--[[
  Launch DeskTop. Select a volume icon and Special > Eject Disk....
  Special > Check All Drives. Verify that DeskTop doesn't hang or
  crash.
]]
test.Step(
  "Eject then Check All Drives works",
  function()
    s5d1:load(disk_a)
    a2d.CheckAllDrives()

    a2d.SelectPath("/A")
    a2d.OAShortcut("E") -- Special > Eject Disk
    emu.wait(10)
    a2d.CheckAllDrives()
    a2dtest.ExpectNotHanging()

    test.ExpectError(
      "Failed to select",
      function()
        a2d.SelectPath("/A")
      end,
      "disk should be ejected")
end)

--[[
  Insert a ProDOS formatted disk in a Disk II drive. Launch DeskTop.
  Select the 5.25" disk icon. Replace the disk in the Disk II drive
  with a Pascal formatted disk. Special > Check Drive. When prompted
  to format it, click Cancel. Edit > Select All. Verify that DeskTop
  doesn't crash or hang.
]]
test.Step(
  "format floppy prompt - Check Drive",
  function()
    s6d1:load(prodos_image)
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2d.SelectPath("/FLOPPY1")

    s6d1:load(pascal_image)

    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_CHECK_DRIVE)
    a2dtest.WaitForAlert()
    a2d.DialogCancel()
    a2d.SelectAll()
    a2dtest.ExpectNotHanging()

    -- cleanup
    s6d1:unload()
    a2d.CheckAllDrives()
end)

--[[
  Launch DeskTop. Insert a Pascal formatted disk in a Disk II drive.
  Special > Check All Drives. Verify that a prompt to format the disk
  is shown.
]]
test.Step(
  "format floppy prompt - Check All Drives",
  function()
    s6d1:load(pascal_image)
    a2d.CheckAllDrives()
    a2d.DialogCancel()

    -- cleanup
    s6d1:unload()
    a2d.CheckAllDrives()
end)

--[[
  Start DeskTop with a hard disk and a 5.25" floppy mounted. Remove
  the floppy, and double-click the floppy icon, and dismiss the "The
  volume cannot be found." dialog. Verify that the floppy icon
  disappears, and that no additional icons are added.
]]
test.Step(
  "Open ejected floppy",
  function()
    s6d1:load(prodos_image)
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2d.SelectPath("/FLOPPY1")
    s6d1:unload()
    a2d.OpenSelection()
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    emu.wait(5)
    test.Snap("verify floppy icon is gone")
end)

--[[
  Configure a system with removable disks. (e.g. Virtual II OmniDisks)
  Launch DeskTop. Verify that volume icons are positioned without gaps
  (down from the top-right, then across the bottom right to left).
  Eject one of the middle volumes. Verify icon disappears. Insert a
  new volume. Verify icon takes up the vacated spot. Repeat test,
  ejecting multiple volumes verify that positions are filled in order
  (down from the top-right, etc).
]]
test.Step(
  "multiple volumes",
  function()
    s6d1:load(prodos_image)
    s5d1:load(disk_a)
    s5d2:load(disk_b)
    s4d1:load(disk_c)

    a2d.Reboot()
    a2d.WaitForDesktopReady()
    test.Snap("verify volume icons are positioned without gaps")
    s5d2:unload()
    emu.wait(10)
    test.Snap("verify volume 'B' icon disappeared")
    s5d2:load(disk_d)
    emu.wait(30)
    test.Snap("verify gap was filled by volume 'D'")
    s5d2:unload()
    s4d1:unload()
    emu.wait(30)
    test.Snap("verify volume 'D' and 'C' icons disappeared")
    s5d2:load(disk_b)
    s4d1:load(disk_c)
    emu.wait(30)
    test.Snap("verify gap was filled by volumes 'B' and 'C'")

    -- cleanup
    s6d1:unload()
    s5d1:unload()
    s5d2:unload()
    s4d1:unload()
end)

--[[
  Configure a system with removable disks. (e.g. Virtual II OmniDisks)
  Launch DeskTop. Open a volume icon. Open a folder icon. Eject the
  disk using the hardware (or emulator). Verify that DeskTop doesn't
  crash and that both windows close.
]]
test.Step(
  "volume and folder window close when disk ejected",
  function()
    s5d1:load(disk_a)
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2d.CreateFolder("/A/FOLDER")
    a2d.OpenPath("/A/FOLDER", {leave_parent=true})

    emu.wait(5)
    s5d1:unload()
    emu.wait(5)

    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "both windows should close")
end)

--[[
  Use an emulator that supports dynamically inserting SmartPort disks,
  e.g. Virtual ][. Insert disks A, B, C, D in drives starting at the
  highest slot first, e.g. S7D1, S7D2, S5D1, S5D2. Launch DeskTop.
  Verify that the disks appear in order A, B, C, D. Eject the disks,
  and wait for DeskTop to remove the icons. Pause the emulator, and
  reinsert the disks in the same drives. Un-pause the emulator. Verify
  that the disks appear on the DeskTop in the same order. Eject the
  disks again, pause, and insert the disks into the drives in reverse
  order (A in S5D2, etc). Un-pause the emulator. Verify that the disks
  appear in reverse order on the DeskTop.
]]
test.Step(
  "insertion order",
  function()
    s5d1:load(disk_a)
    s5d2:load(disk_b)
    s4d1:load(disk_c)
    s4d2:load(disk_d)
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    test.Snap("verify disks appear in order A/B/C/D")
    s5d1:unload()
    s5d2:unload()
    s4d1:unload()
    s4d2:unload()
    emu.wait(30) -- TODO: Fix need for this

    s5d1:load(disk_a)
    s5d2:load(disk_b)
    s4d1:load(disk_c)
    s4d2:load(disk_d)
    emu.wait(30) -- TODO: Fix need for this
    test.Snap("verify disks appear in order A/B/C/D")

    s5d1:unload()
    s5d2:unload()
    s4d1:unload()
    s4d2:unload()
    emu.wait(30) -- TODO: Fix need for this

    s4d2:load(disk_a)
    s4d1:load(disk_b)
    s5d2:load(disk_c)
    s5d1:load(disk_d)
    emu.wait(30) -- TODO: Fix need for this
    test.Snap("verify disks appear in order D/C/B/A")

    -- cleanup
    s5d1:unload()
    s5d2:unload()
    s4d1:unload()
    s4d2:unload()
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Use an emulator that supports dynamically inserting SmartPort disks,
  e.g. Virtual ][. Launch DeskTop. Insert an unformatted SmartPort
  disk image. When prompted to format, click OK. Verify that the
  prompt for the name includes the correct slot and drive designation
  for the disk.
]]
test.Step(
  "inserting unformatted disk",
  function()
    s5d1:load(emu.subst_env("$UNFORMATTED_IMG"))
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    emu.wait(5)
    test.Snap("verify S5,D1 specified")
    a2d.DialogCancel()
    s5d1:unload()
end)

--[[
  Launch DeskTop. Open a window for a removable disk. Quit DeskTop.
  Remove the disk. Restart DeskTop. Verify that 8 windows can be
  opened, and no render glitches occur.
]]
test.Step(
  "failed window restore does not consume a window",
  function()
    s5d1:load(disk_a)
    emu.wait(10)
    a2d.Quit()
    s5d1:unload()

    apple2.WaitForBitsy()
    apple2.BitsySelectSlotDrive("S7,D1")
    apple2.BitsyInvokeFile("DESKTOP.SYSTEM")
    a2d.WaitForDesktopReady()

    for i = 1, 7 do
      a2d.CreateFolder("/RAM1/F" .. i)
    end
    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    a2d.OpenSelection({leave_parent=true})
    emu.wait(5)
    test.ExpectEquals(a2dtest.GetWindowCount(), 8, "8 windows should be open")
end)
