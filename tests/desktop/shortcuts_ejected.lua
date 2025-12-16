--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS="-ramsize 1152K"
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(5)

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
    "Edit a Shortcut, startup disk ejected",
    "Delete a Shortcut, startup disk ejected",
    "Run a Shortcut, startup disk ejected",
  },
  function(idx)
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")

    local drive = apple2.Get35Drive1()
    local image = drive.filename
    drive:unload()

    if idx == 1 then
      a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    elseif idx == 2 then
      a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
    else
      a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_RUN_A_SHORTCUT)
    end

    a2dtest.WaitForAlert()
    a2d.DialogCancel()

    drive:load(image)

    if idx == 1 then
      a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    elseif idx == 2 then
      a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
    else
      a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_RUN_A_SHORTCUT)
    end

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
    a2d.CloseAllWindows()
    a2d.Reboot()
    a2d.WaitForDesktopReady({timeout=360})

    a2d.OpenPath("/RAM4/EXTRAS")
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "all files should have copied")
    a2d.CloseAllWindows()

    local drive = apple2.Get35Drive1()
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
    a2d.CloseAllWindows()
    a2d.OAShortcut("1")
    apple2.WaitForBasicSystem({timeout=120})
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    a2d.OpenPath("/RAM4/EXTRAS")
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "all files should have copied")
    a2d.CloseAllWindows()

    local drive = apple2.Get35Drive1()
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
