--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl5 superdrive -sl6 superdrive"
DISKARGS="-flop3 $HARDIMG -flop1 full_800k.2mg -flop2 empty_800k.2mg"

======================================== ENDCONFIG ]]

local s6d1 = manager.machine.images[":sl6:superdrive:fdc:0:35hd"]
local s5d1 = manager.machine.images[":sl5:superdrive:fdc:0:35hd"]
local s5d2 = manager.machine.images[":sl5:superdrive:fdc:1:35hd"]

--[[
  Launch DeskTop. Eject the startup disk. Special > Copy Disk....
  Verify that an alert is shown. Cancel the alert. Verify that DeskTop
  continues to run.
]]
test.Step(
  "graceful failure if startup disk ejected",
  function()

    local image = s6d1.filename
    s6d1:unload()
    emu.wait(5) -- async drive validation

    desktop.ClearSelection()
    a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_COPY_DISK-2)
    a2dtest.WaitForAlert({match="insert the system disk"})
    a2d.DialogCancel()

    -- cleanup
    s6d1:load(image)
    emu.wait(5) -- async drive validation

end)

--[[
  Launch DeskTop. Eject the startup disk. Special > Copy Disk....
  Verify that an alert is shown. Reinsert the startup disk. Click OK
  in the alert. Verify that Disk Copy starts.
]]
test.Step(
  "retry successful if startup disk ejected",
  function()

    local image = s6d1.filename
    s6d1:unload()
    emu.wait(5) -- async drive validation

    desktop.ClearSelection()
    a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_COPY_DISK-2)
    a2dtest.WaitForAlert({match="insert the system disk"})

    s6d1:load(image)
    emu.wait(5) -- async drive validation

    a2d.DialogOK()
    a2d.WaitForDesktopReady()
    test.ExpectMatch(a2dtest.OCRScreen(), "Select source disk",
                "Disk Copy should be started")

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)

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
test.Step(
  "empty drive",
  function()

    local image = s5d2.filename
    s5d2:unload()
    emu.wait(5) -- async drive validation

    desktop.CopyDisk()
    a2dtest.ConfigureForDiskCopy()

    test.ExpectMatch(a2dtest.OCRScreen(), "5 +2 +Unknown",
                "S5D2 should show 'Unknown' in source list")

    -- select source
    apple2.UpArrowKey() -- S5D2
    apple2.UpArrowKey() -- S5D1
    apple2.ReturnKey()
    a2dtest.WaitForSystemTask()

    test.ExpectNotMatch(a2dtest.OCRScreen(), "5 +2 +Unknown",
                "S5D2 should not be in destination list")

    s5d2:load(image)

    apple2.Type("R")
    a2dtest.WaitForSystemTask()

    test.ExpectMatch(a2dtest.OCRScreen(), "5 +2 +EMPTY",
                "S5D2 should show a disk in source list")

    apple2.UpArrowKey() -- S5D2
    apple2.UpArrowKey() -- S5D1
    apple2.ReturnKey()
    a2dtest.WaitForSystemTask()

    test.ExpectMatch(a2dtest.OCRScreen(), "5 +2 +EMPTY",
                "S5D2 should show a disk in destination list")

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2dtest.ConfigureForDeskTop()
    a2d.WaitForDesktopReady()
end)


--[[
  Launch DeskTop. Special > Copy Disk.... Select a source disk and a
  destination disk. Allow the copy to start, but eject the destination
  disk in the middle of the copy. Verify that block write errors are
  shown (with alert sounds).
]]
test.Step(
  "errors if destination disk ejected",
  function()


    -- TODO: HANG in here

    desktop.CopyDisk()
    a2dtest.ConfigureForDiskCopy()

    -- source
    apple2.UpArrowKey() -- S5D2
    apple2.UpArrowKey() -- S5D1
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    -- destination
    apple2.UpArrowKey() -- S5D2
    a2d.DialogOK()

    -- insert source
    a2dtest.WaitForAlert({match="Insert the source disk"})
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert({match="Insert the destination disk"})
    a2d.DialogOK()

    -- confirm overwrite
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()

    emu.wait(5) -- eject during copy
    local image = s5d2.filename
    s5d2:unload()

    util.WaitFor(
      "error seen", function()
        return a2dtest.OCRFrontWindowContent():match("Error when writing block")
      end, {wait=0.25})

    -- cleanup
    apple2.EscapeKey() -- abort the copy
    a2dtest.WaitForAlert({match="not completed"})

    test.ExpectNotMatch(a2dtest.OCRScreen(), "Press Esc to stop copying",
                "tip should be erased")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    s5d2:load(image)

    a2d.OAShortcut("Q")
    a2d.WaitForDesktopReady()
    a2dtest.ConfigureForDeskTop()
end)

--[[
  Launch DeskTop. Special > Copy Disk.... Select a source disk and a
  destination disk. Allow the copy to start, but eject the source disk
  in the middle of the copy. Verify that block read errors are shown
  (with alert sounds), and that the error text does not overlap the
  progress bar.
]]
test.DISABLED_Step(
  "errors if source disk ejected",
  "hangs in the device firmware if unloaded when reading",
  function()
    desktop.ClearSelection()
    a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_COPY_DISK-2)
    a2d.WaitForDesktopReady()
    a2dtest.ConfigureForDiskCopy()

    -- source
    apple2.UpArrowKey() -- S5D2
    apple2.UpArrowKey() -- S5D1
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    -- destination
    apple2.UpArrowKey() -- S5D2
    a2d.DialogOK()

    -- insert source
    a2dtest.WaitForAlert({match="Insert the source disk"})
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert({match="Insert the destination disk"})
    a2d.DialogOK()

    -- confirm overwrite
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()

    emu.wait(5) -- eject during copy
    local image = s5d1.filename
    s5d1:unload()

    emu.wait(5) -- eject during copy
    test.Snap("verify block errors reading")

    -- cleanup
    apple2.EscapeKey()
    a2dtest.WaitForAlert({match="not completed"})

    a2d.DialogOK()
    s5d1:load(image)
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
    a2dtest.ConfigureForDeskTop()
end)
