--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 '' -sl2 mouse -sl4 ramfactor -sl6 superdrive"
DISKARGS="-flop1 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)
local s6d1 = manager.machine.images[":sl6:superdrive:fdc:0:35hd"]

--[[
  Launch Shortcuts. Eject the disk with DeskTop on it. Type D (don't
  click). Dismiss the dialog by hitting Esc. Verify that the dialog
  disappears, and the Apple menu is not shown.
]]
test.Step(
  "Startup disk ejected",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    local drive = s6d1
    local image = drive.filename
    drive:unload()

    apple2.Type("D")
    a2dtest.WaitForAlert()
    apple2.EscapeKey()
    a2d.WaitForRepaint()

    drive:load(image)

    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    emu.wait(5) -- floppies are slow
    a2d.Reboot()
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
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="boot"})
    a2d.ToggleOptionShowShortcutsOnStartup() -- enable
    a2d.ToggleOptionCopyToRAMCard() -- enable
    a2d.Reboot()
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
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    emu.wait(5) -- floppies are slow
    a2d.EraseVolume("RAM4")
    a2d.Reboot()
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
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    a2d.ToggleOptionShowShortcutsOnStartup() -- enable
    a2d.ToggleOptionCopyToRAMCard() -- enable
    a2d.Reboot()
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
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    emu.wait(5) -- floppies are slow
    a2d.EraseVolume("RAM4")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)
