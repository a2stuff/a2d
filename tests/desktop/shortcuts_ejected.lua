--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl4 ramfactor -sl5 superdrive -sl6 ''"
DISKARGS="-flop1 $HARDIMG"

======================================== ENDCONFIG ]]

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
    {"Edit a Shortcut, startup disk ejected", desktop.SHORTCUTS_EDIT_A_SHORTCUT},
    {"Delete a Shortcut, startup disk ejected", desktop.SHORTCUTS_DELETE_A_SHORTCUT},
    {"Run a Shortcut, startup disk ejected", desktop.SHORTCUTS_RUN_A_SHORTCUT},
  },
  function(idx, name, item)
    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    a2dtest.WaitForSystemTask()

    local drive = s5d1
    local image = drive.filename
    drive:unload()

    a2d.InvokeMenuItem(desktop.SHORTCUTS_MENU, item)

    a2dtest.WaitForAlert({match="insert the system disk"})
    a2d.DialogCancel()

    drive:load(image)
    emu.wait(5) -- async drive validation (so it doesn't interrupt menu action)

    a2dtest.WaitForSystemTask()
    a2d.InvokeMenuItem(desktop.SHORTCUTS_MENU, item)
    a2dtest.WaitForSystemTask()

    a2dtest.ExpectAlertNotShowing()
    a2d.DialogCancel()
    a2dtest.WaitForSystemTask()

    desktop.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    desktop.Reboot()
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
    desktop.ToggleOptionCopyToRAMCard()

    desktop.OpenWindow("/A2.DESKTOP/EXTRAS")
    desktop.SelectAll()
    local count = #desktop.GetSelectedIcons()
    desktop.CloseAllWindows()

    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="boot"})
    a2dtest.WaitForSystemTask()
    desktop.CloseAllWindows()
    desktop.Reboot()
    a2d.WaitForDesktopReady({timeout=360})

    desktop.OpenWindow("/RAM4/EXTRAS")
    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "all files should have copied")
    desktop.CloseAllWindows()

    local drive = s5d1
    local image = drive.filename
    drive:unload()

    a2d.OAShortcut("1")
    apple2.WaitForBasicSystem()

    drive:load(image)

    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    desktop.DeletePath("/A2.DESKTOP/LOCAL")
    desktop.EraseVolume("RAM4")
    desktop.Reboot()
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
    desktop.ToggleOptionCopyToRAMCard()
    desktop.Reboot()
    a2d.WaitForDesktopReady({timeout=240})

    desktop.OpenWindow("/A2.DESKTOP/EXTRAS")
    desktop.SelectAll()
    local count = #desktop.GetSelectedIcons()
    desktop.CloseAllWindows()

    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {copy="use"})
    a2dtest.WaitForSystemTask()
    desktop.CloseAllWindows()
    a2d.OAShortcut("1")
    apple2.WaitForBasicSystem({timeout=120})
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    desktop.OpenWindow("/RAM4/EXTRAS")
    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "all files should have copied")
    desktop.CloseAllWindows()

    local drive = s5d1
    local image = drive.filename
    drive:unload()

    a2d.OAShortcut("1")
    apple2.WaitForBasicSystem()

    drive:load(image)

    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    desktop.DeletePath("/A2.DESKTOP/LOCAL")
    desktop.EraseVolume("RAM4")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)
