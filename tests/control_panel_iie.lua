--[[
  Configure a system with a color display. Open the Control Panel DA.
  Check "RGB Color" if needed to ensure the display is in color.
  Select one of the vertically striped patterns that appears as a
  solid color. Click the preview area. Verify that the color matches
  the preview. Move the DA window. Verify that colors still match.
  Repeat with other patterns.
]]--
test.Step(
  "RGB Color desktop",
  function()
    apple2.SetMonitorType(apple2.MONITOR_TYPE_VIDEO7)

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    a2d.OAShortcut("1") -- check RGB Color
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
    end)

    for i=1, 14 do
      apple2.LeftArrowKey() -- change pattern
      apple2.ControlKey("D") -- set pattern
      a2d.WaitForRepaint()
      test.Snap("verify preview color matches desktop color")

      a2d.InMouseKeysMode(function(m)
          m.ButtonDown()
          m.MoveByApproximately(8, 0)
          m.ButtonUp()
          a2d.WaitForRepaint()
          test.Snap("verify preview color matches desktop color")
      end)
    end

    a2d.CloseWindow()
end)
