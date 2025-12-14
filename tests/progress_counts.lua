--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/disk_a.2mg"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)

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
    a2d.ToggleOptionCopyToRAMCard()
    a2d.CloseAllWindows()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    -- Copy to RAMDisk, (shortcut in root directory)
    a2d.OpenPath("/A")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    apple2.WaitForBasicSystem()
    apple2.TypeLine("CREATE DUMMY,T$01")
    apple2.TypeLine("BSAVE DUMMY,T$01,,A$2000,L123")
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
    a2d.AddShortcut("/A/DUMMY", {copy="use"})
    a2d.OAShortcut("1", {no_wait=true})
    a2dtest.MultiSnap(120, "shortcut copy progress bottoms out at 0")
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- cleanup
    a2d.EraseVolume("RAM1")
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
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
    a2d.ToggleOptionCopyToRAMCard()
    a2d.CloseAllWindows()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    -- Copy to RAMDisk, (shortcut in non-root directory)
    a2d.CreateFolder("/A/F")
    a2d.OpenPath("/A/F")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    apple2.WaitForBasicSystem()
    apple2.TypeLine("CREATE DUMMY,T$01")
    apple2.TypeLine("BSAVE DUMMY,T$01,,A$2000,L123")
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
    a2d.AddShortcut("/A/F/DUMMY", {copy="use"})
    a2d.OAShortcut("1", {no_wait=true})
    a2dtest.MultiSnap(120, "shortcut copy progress bottoms out at 0")
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- cleanup
    a2d.EraseVolume("RAM1")
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
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
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/A")
    a2d.CopyPath("/A", "/RAM1", {no_wait=true})
    emu.wait(20/60)
    a2dtest.MultiSnap(120, "volume copy progress bottoms out at 0")
end)
