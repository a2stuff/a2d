--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl4 ramfactor -sl5 superdrive -sl6 '' -aux ext80"
DISKARGS="-flop1 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)
local s5d1 = manager.machine.images[":sl5:superdrive:fdc:0:35hd"]

--[[
  Repeat for the Shortcuts > Edit, Delete, and Run a Shortcut commands

  Ensure at least one Shortcut exists. Launch DeskTop. Eject the
  startup disk. Run the command from the Shortcuts menu. Verify that a
  prompt is shown asking to insert the system disk. Click Cancel.
  Verify that DeskTop does not crash or hang. Reinsert the startup
  disk. Run the command again. Verify that the dialog appears
  correctly.
]]
test.Variants(
  {
    {"Edit a Shortcut, startup disk ejected", a2d.SHORTCUTS_EDIT_A_SHORTCUT},
    {"Delete a Shortcut, startup disk ejected", a2d.SHORTCUTS_DELETE_A_SHORTCUT},
    {"Run a Shortcut, startup disk ejected", a2d.SHORTCUTS_RUN_A_SHORTCUT},
  },
  function(idx, name, item)
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    emu.wait(5) -- floppy needs a little extra time

    local drive = s5d1
    local image = drive.filename
    drive:unload()

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, item)

    a2dtest.WaitForAlert()
    a2d.DialogCancel()

    drive:load(image)

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, item)

    a2dtest.ExpectAlertNotShowing()
    a2d.DialogCancel()
    emu.wait(5)

    a2d.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a shortcut for a program with many associated files to
  copy to RAMCard "at boot". Reboot, and launch `DESKTOP.SYSTEM`.
  Verify that all of the files were copied to the RAMCard. Once
  DeskTop starts, eject the disk containing the program. Invoke the
  shortcut. Verify that the program starts correctly.
]]
test.Step(
  "shortcut copied on boot does not rely on original disk",
  function()
    a2d.ToggleOptionCopyToRAMCard()

    a2d.OpenPath("/A2.DESKTOP/EXTRAS")
    a2d.SelectAll()
    local count = #a2d.GetSelectedIcons()
    a2d.CloseAllWindows()

    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="boot"})
    emu.wait(5) -- floppy needs a little extra time
    a2d.CloseAllWindows()
    a2d.Reboot()
    a2d.WaitForDesktopReady({timeout=360})

    a2d.OpenPath("/RAM4/EXTRAS")
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "all files should have copied")
    a2d.CloseAllWindows()

    local drive = s5d1
    local image = drive.filename
    drive:unload()

    a2d.OAShortcut("1")
    apple2.WaitForBasicSystem()

    drive:load(image)

    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM4")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a shortcut for a program with many associated files to
  copy to RAMCard "at first use". Invoke the shortcut. Verify that the
  files are copied to the RAMCard, and that the program starts
  correctly. Return to DeskTop by quitting the program. Eject the disk
  containing the program. Invoke the shortcut. Verify that the program
  starts correctly.
]]
test.Step(
  "shortcut copied on use does not rely on original disk",
  function()
    a2d.ToggleOptionCopyToRAMCard()
    a2d.Reboot()
    a2d.WaitForDesktopReady({timeout=240})

    a2d.OpenPath("/A2.DESKTOP/EXTRAS")
    a2d.SelectAll()
    local count = #a2d.GetSelectedIcons()
    a2d.CloseAllWindows()

    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    emu.wait(5) -- floppy needs a little extra time
    a2d.CloseAllWindows()
    a2d.OAShortcut("1")
    apple2.WaitForBasicSystem({timeout=120})
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    a2d.OpenPath("/RAM4/EXTRAS")
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "all files should have copied")
    a2d.CloseAllWindows()

    local drive = s5d1
    local image = drive.filename
    drive:unload()

    a2d.OAShortcut("1")
    apple2.WaitForBasicSystem()

    drive:load(image)

    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.EraseVolume("RAM4")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)
