--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

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
    desktop.ToggleOptionCopyToRAMCard() -- enable
    desktop.Reboot()
    a2d.WaitForDesktopReady()

    desktop.InvokePath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    apple2.RightArrowKey()
    apple2.RightArrowKey()
    apple2.ControlKey("D") -- Set Desktop Pattern
    a2dtest.WaitForSystemTask()
    desktop.CloseWindow()
    desktop.CloseAllWindows()
    desktop.ClearSelection()
    a2dtest.ExpectNothingChanged(function()
        desktop.Reboot()
        a2d.WaitForDesktopReady()
    end)
end)
