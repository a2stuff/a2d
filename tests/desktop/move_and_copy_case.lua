--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl5 ramfactor -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Ensure the startup disk has a name that would be case-adjusted by
  DeskTop, e.g. `/HD` but that shows as "Hd". Launch DeskTop. Open the
  startup disk. Apple Menu > Control Panels. Drag a DA file to the
  startup disk window. Verify that the file is moved, not copied.
]]
test.Step(
  "Move/Copy detection vs. case sensitivity",
  function()
    a2d.ToggleOptionPreserveCase() -- disable
    a2d.RenamePath("/A2.DESKTOP", "HARD.DISK")
    a2d.CloseAllWindows()
    a2d.Reboot()
    a2d.WaitForDesktopReady()
    a2d.SelectPath("/HARD.DISK")
    test.ExpectEquals(a2dtest.GetSelectedIconName(), "Hard.Disk", "Name should be case adjusted")

    a2d.OpenPath("/HARD.DISK")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w - 5, y + h - 5

    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.MoveWindowBy(0, 100)
    a2d.Select("CONTROL.PANEL")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(5)

    a2d.SelectPath("/HARD.DISK/CONTROL.PANEL")
    test.ExpectError(
      "Failed to select",
      function() a2d.SelectPath("/HARD.DISK/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL") end,
      "should have moved not copied file")
end)

