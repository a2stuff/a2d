test.Step(
  "Map - Search",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/MAP")

    apple2.Type("San Francisco")
    apple2.ReturnKey()
    a2d.WaitForRepaint()
    test.Snap("verify lat/long updated")
    for i = 1, 4 do
      emu.wait(0.25)
      test.Snap("verify indicator positioned")
    end
    a2d.CloseWindow()
end)

test.Step(
  "Map - Indicator",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/MAP")
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        emu.wait(10/60)
        test.Snap("verify indicator visible")
        m.MoveByApproximately(80, 40)
        m.ButtonUp()
        a2d.WaitForRepaint()
    end)
    apple2.Type("San Francisco")
    apple2.ReturnKey()
    a2d.WaitForRepaint()
    for i = 1, 4 do
      emu.wait(0.25)
      test.Snap("verify only single indicator position")
    end
    a2d.CloseWindow()
end)
