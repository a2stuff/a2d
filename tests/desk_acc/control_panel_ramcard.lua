--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Configure a system with a RAMCard, and ensure DeskTop is configured
  to copy to RAMCard on startup. Launch DeskTop. Apple Menu > Control
  Panels. Open Control Panel. Modify a setting e.g. the desktop
  pattern. Close the window. Reboot the system. Verify that the
  setting is retained.
]]
test.Step(
  "Settings saved back to boot volume",
  function()
    a2d.ToggleOptionCopyToRAMCard() -- enable
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    apple2.RightArrowKey()
    apple2.RightArrowKey()
    apple2.ControlKey("D")
    a2d.WaitForRepaint()
    a2d.CloseWindow()
    a2d.CloseAllWindows()
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(function()
        a2d.Reboot()
        a2d.WaitForDesktopReady()
    end)
end)
