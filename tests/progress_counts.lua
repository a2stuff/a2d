--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 disk_a.2mg"

======================================== ENDCONFIG ]]

--[[
  Launch DeskTop, ensure it copies itself to RAMCard. Configure a
  shortcut with the target in the root of a volume, and to Copy to
  RAMCard at first use. Quit DeskTop. Launch Shortcuts. Invoke the
  shortcut. Verify that the copy count goes to zero and doesn't blank
  out.
]]
test.Step(
  "Copy progress of shortcut in root directory",
  function()
    -- configuration
    desktop.ToggleOptionCopyToRAMCard()
    desktop.CloseAllWindows()
    desktop.Reboot()
    a2d.WaitForDesktopReady()

    -- Copy to RAMDisk, (shortcut in root directory)
    desktop.OpenWindow("/A")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.RUN_BASIC_HERE)
    apple2.WaitForBasicSystem()
    apple2.TypeLine("CREATE DUMMY,T$01")
    apple2.TypeLine("BSAVE DUMMY,T$01,,A$2000,L123")
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
    desktop.AddShortcut("/A/DUMMY", {copy="use"})
    a2d.OAShortcut("1", {no_wait=true})
    a2dtest.VerifyFilesRemainingCountdown(120, "shortcut copy")
    a2dtest.WaitForAlert({match="cannot be opened"})
    a2d.DialogOK()

    -- cleanup
    desktop.EraseVolume("RAM1")
    desktop.DeletePath("/A2.DESKTOP/LOCAL")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop, ensure it copies itself to RAMCard. Configure a
  shortcut with the target in a directory, not the root of a volume,
  and to Copy to RAMCard at first use. Quit DeskTop. Launch Shortcuts.
  Invoke the shortcut. Verify that the copy count goes to zero and
  doesn't blank out.
]]
test.Step(
  "Copy progress of shortcut in non-root directory",
  function()
    -- configuration
    desktop.ToggleOptionCopyToRAMCard()
    desktop.CloseAllWindows()
    desktop.Reboot()
    a2d.WaitForDesktopReady()

    -- Copy to RAMDisk, (shortcut in non-root directory)
    desktop.CreateFolder("/A/F")
    desktop.OpenWindow("/A/F")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.RUN_BASIC_HERE)
    apple2.WaitForBasicSystem()
    apple2.TypeLine("CREATE DUMMY,T$01")
    apple2.TypeLine("BSAVE DUMMY,T$01,,A$2000,L123")
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
    desktop.AddShortcut("/A/F/DUMMY", {copy="use"})
    a2d.OAShortcut("1", {no_wait=true})
    a2dtest.VerifyFilesRemainingCountdown(120, "shortcut copy")
    a2dtest.WaitForAlert({match="cannot be opened"})
    a2d.DialogOK()

    -- cleanup
    desktop.EraseVolume("RAM1")
    desktop.DeletePath("/A2.DESKTOP/LOCAL")
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a system with a RAMCard, and set DeskTop to copy itself to
  the RAMCard on startup. Launch DeskTop. Create a shortcut for a
  non-executable file at the root of a volume, set to "Copy to
  RAMCard" "at first use". Run the shortcut. Verify that the "Files
  remaining" count bottoms out at 0. Close the alert. Drag a volume
  icon to another volume. Verify that the "Files remaining" count
  bottoms out at 0.
]]
test.Step(
  "Copy progress of a volume",
  function()
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/A")
    desktop.CopyPath("/A", "/RAM1", {no_wait=true})
    a2dtest.VerifyFilesRemainingCountdown(240, "volume copy")
end)
