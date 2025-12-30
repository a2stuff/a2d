--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl5 superdrive -sl6 superdrive -aux ext80"
DISKARGS="-flop3 $HARDIMG -flop1 res/full_800k.2mg -flop2 res/empty_800k.2mg"

======================================== ENDCONFIG ]]

local s6d1 = manager.machine.images[":sl6:superdrive:fdc:0:35hd"]
local s5d1 = manager.machine.images[":sl5:superdrive:fdc:0:35hd"]
local s5d2 = manager.machine.images[":sl5:superdrive:fdc:1:35hd"]

a2d.ConfigureRepaintTime(0.25)

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
    emu.wait(5)

    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
    a2dtest.WaitForAlert()
    a2d.DialogCancel()

    -- cleanup
    s6d1:load(image)
    emu.wait(5)

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
    emu.wait(5)

    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
    a2dtest.WaitForAlert()

    s6d1:load(image)
    emu.wait(5)

    a2d.DialogOK()
    a2d.WaitForDesktopReady()
    test.Snap("verify Disk Copy started")

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
    emu.wait(5)

    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
    a2d.WaitForDesktopReady()

    test.Snap("verify S5D2 shows 'Unknown' in source list")

    -- select source
    apple2.UpArrowKey() -- S5D2
    apple2.UpArrowKey() -- S5D1
    apple2.ReturnKey()
    emu.wait(5)

    test.Snap("verify S5D2 is not in destination list")

    s5d2:load(image)

    apple2.Type("R")
    emu.wait(5)

    test.Snap("verify S5D2 shows a disk in source list")

    apple2.UpArrowKey() -- S5D2
    apple2.UpArrowKey() -- S5D1
    apple2.ReturnKey()
    emu.wait(5)

    test.Snap("verify S5D2 is in destination list")

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
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
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
    a2d.WaitForDesktopReady()

    -- source
    apple2.UpArrowKey() -- S5D2
    apple2.UpArrowKey() -- S5D1
    a2d.DialogOK()

    -- destination
    apple2.UpArrowKey() -- S5D2
    a2d.DialogOK()

    -- insert source
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- confirm overwrite
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    emu.wait(5)
    local image = s5d2.filename
    s5d2:unload()

    emu.wait(5)
    test.Snap("verify block errors writing")

    -- cleanup
    apple2.EscapeKey() -- abort the copy
    a2dtest.WaitForAlert()

    a2d.DialogOK()
    s5d2:load(image)
    apple2.ControlOAReset()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Special > Copy Disk.... Select a source disk and a
  destination disk. Allow the copy to start, but eject the source disk
  in the middle of the copy. Verify that block read errors are shown
  (with alert sounds), and that the error text does not overlap the
  progress bar.
]]
test.Step(
  "errors if source disk ejected",
  function()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
    a2d.WaitForDesktopReady()

    -- source
    apple2.UpArrowKey() -- S5D2
    apple2.UpArrowKey() -- S5D1
    a2d.DialogOK()

    -- destination
    apple2.UpArrowKey() -- S5D2
    a2d.DialogOK()

    -- insert source
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- confirm overwrite
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    emu.wait(5)
    local image = s5d1.filename
    s5d1:unload()

    emu.wait(5)
    test.Snap("verify block errors reading")

    -- BUG: Not seeing errors - just hangs? No repro in Virtual ][

    -- cleanup
    apple2.EscapeKey()
    -- NOTE: Doesn't timeout as we never process the Escape keypress!
    a2dtest.WaitForAlert()

    a2d.DialogOK()
    s5d1:load(image)
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)
