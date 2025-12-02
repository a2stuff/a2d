test.Step(
  "RGB Color desktop",
  function()
    apple2.SetMonitorType(apple2.MONITOR_TYPE_VIDEO7)

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    a2d.OAShortcut("1") -- check RGB Color
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(280, 30)
    end)

    for i=1,14 do
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
