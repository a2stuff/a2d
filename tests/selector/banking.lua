--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS="-ramsize 1152K"
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]

--[[
  Configure a disk with ProDOS 2.4.3. Run DeskTop on a IIc+. Create a
  shortcut to launch `BASIC.SYSTEM`. Use Control Panel > Options to
  set Shortcuts to run on startup. Restart. From Shortcuts, invoke the
  `BASIC.SYSTEM` shortcut. Verify that it doesn't crash. Restart. From
  Shortcuts, invoke DeskTop. Verify that it doesn't crash.
]]
test.Step(
  "Regression test for #789",
  function()
    desktop.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    desktop.ToggleOptionShowShortcutsOnStartup()
    desktop.Reboot()
    a2d.WaitForDesktopReady()
    apple2.Type("1")
    a2d.DialogOK()
    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2dtest.ExpectNotHanging()
end)
