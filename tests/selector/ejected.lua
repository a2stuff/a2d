--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 '' -sl2 mouse -sl4 ramfactor -sl6 superdrive"
DISKARGS="-flop1 $HARDIMG"

======================================== ENDCONFIG ]]

local s6d1 = manager.machine.images[":sl6:superdrive:fdc:0:35hd"]

--[[
  Launch Shortcuts. Eject the disk with DeskTop on it. Type D (don't
  click). Dismiss the dialog by hitting Esc. Verify that the dialog
  disappears, and the Apple menu is not shown.
]]
test.Step(
  "Startup disk ejected",
  function()
    desktop.AddShortcut("/A2.DESKTOP/READ.ME")
    desktop.ToggleOptionShowShortcutsOnStartup()
    desktop.Reboot()
    a2dtest.ConfigureForSelector()
    a2d.WaitForDesktopReady()

    local drive = s6d1
    local image = drive.filename
    drive:unload()

    apple2.Type("D")
    a2dtest.WaitForAlert({match="insert the system disk"})
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()

    drive:load(image)

    apple2.Type("D")
    a2dtest.ConfigureForDeskTop()
    a2d.WaitForDesktopReady()
    desktop.DeletePath("/A2.DESKTOP/LOCAL")
    a2dtest.WaitForSystemTask()
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a shortcut for a program with many associated files to
  copy to RAMCard "at boot". Reboot, and launch `DESKTOP.SYSTEM`.
  Verify that all of the files were copied to the RAMCard. Once
  Shortcuts starts, eject the disk containing the program. Invoke the
  shortcut. Verify that the program starts correctly.
]]
test.Step(
  "Shortcut copied at boot",
  function()
    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="boot"})
    desktop.ToggleOptionShowShortcutsOnStartup() -- enable
    desktop.ToggleOptionCopyToRAMCard() -- enable
    desktop.Reboot()
    a2d.WaitForDesktopReady({timeout=360})

    local drive = s6d1
    local image = drive.filename
    drive:unload()

    apple2.Type("1")
    a2d.DialogOK()
    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    drive:load(image)

    -- cleanup
    apple2.Type("D")
    a2d.WaitForDesktopReady()
    desktop.DeletePath("/A2.DESKTOP/LOCAL")
    a2dtest.WaitForSystemTask()
    desktop.EraseVolume("RAM4")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a shortcut for a program with many associated files to
  copy to RAMCard "at first use". Invoke the shortcut. Verify that the
  files are copied to the RAMCard, and that the program starts
  correctly. Return to Shortcuts by quitting the program. Eject the
  disk containing the program. Invoke the shortcut. Verify that the
  program starts correctly.
]]
test.Step(
  "Shortcut copied at use",
  function()
    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    desktop.ToggleOptionShowShortcutsOnStartup() -- enable
    desktop.ToggleOptionCopyToRAMCard() -- enable
    desktop.Reboot()
    a2d.WaitForDesktopReady({timeout=240})

    -- Run normally, let it copy to RAMCard
    apple2.Type("1")
    a2d.DialogOK()
    apple2.WaitForBasicSystem({timeout=120})
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    -- Run with the disk ejected
    local drive = s6d1
    local image = drive.filename
    drive:unload()

    apple2.Type("1")
    a2d.DialogOK()
    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    drive:load(image)

    -- cleanup
    apple2.Type("D")
    a2d.WaitForDesktopReady()
    desktop.DeletePath("/A2.DESKTOP/LOCAL")
    a2dtest.WaitForSystemTask()
    desktop.EraseVolume("RAM4")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Set up a shortcut to copy on use. Run Selector. Invoke the shortcut.
  While it is copying, eject the disk. Verify an alert is shown and
  the copy fails.
]]
test.DISABLED_Step(
  "Shortcut copied at use - eject during the copy",
  "hangs in the device firmware if unloaded when reading",
  function()
    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    desktop.ToggleOptionShowShortcutsOnStartup() -- enable
    desktop.ToggleOptionCopyToRAMCard() -- enable
    desktop.Reboot()
    a2d.WaitForDesktopReady({timeout=240})
    a2dtest.ConfigureForSelector()

    -- Run normally, let it copy to RAMCard
    apple2.Type("1")
    a2d.DialogOK({no_wait=true})

    -- BUG: Timing sensitive - may hang in device driver.
    emu.wait(1.25) -- eject during copy
    local drive = s6d1
    local image = drive.filename
    drive:unload()

    a2dtest.WaitForAlert()
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    drive:load(image)

    -- cleanup
    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2dtest.ConfigureForDeskTop()
    desktop.DeletePath("/A2.DESKTOP/LOCAL")
    a2dtest.WaitForSystemTask()
    desktop.EraseVolume("RAM4")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)
