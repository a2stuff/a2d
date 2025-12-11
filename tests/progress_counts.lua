--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/disk_a.2mg"

======================================== ENDCONFIG ]]--

test.Step(
  "Copy progress of shortcut in root directory",
  function()
    -- configuration
    a2d.ToggleOptionCopyToRAMCard()
    a2d.CloseAllWindows()
    a2d.Reboot()
    a2d.WaitForCopyToRAMCard()

    -- Copy to RAMDisk, (shortcut in root directory)
    a2d.OpenPath("/A")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    a2d.WaitForRestart()
    apple2.TypeLine("CREATE DUMMY,T$01")
    apple2.TypeLine("BSAVE DUMMY,T$01,,A$2000,L123")
    apple2.TypeLine("BYE")
    a2d.WaitForRestart()
    a2d.AddShortcut("/A/DUMMY", {copy="use"})
    a2d.OAShortcut("1", {no_wait=true})
    a2dtest.MultiSnap(120, "shortcut copy progress bottoms out at 0")
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- cleanup
    a2d.EraseVolume("RAM1")
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
end)

test.Step(
  "Copy progress of a volume",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/A")
    a2d.CopyPath("/A", "/RAM1", {no_wait=true})
    emu.wait(20/60)
    a2dtest.MultiSnap(120, "volume copy progress bottoms out at 0")
end)
