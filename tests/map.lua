a2d.ConfigureRepaintTime(0.25)

--[[
  Launch DeskTop. Apple Menu > Control Panels. Open Map. Type a known
  city name e.g. "San Francisco". Click Find. Verify that the city is
  highlighted on the map and the Latitude/Longitude are updated.
]]
test.Step(
  "Map - Search",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/MAP")
    emu.wait(1)

    apple2.Type("San Francisco")
    apple2.ReturnKey()
    a2d.WaitForRepaint()
    test.Snap("verify lat/long updated")
    a2dtest.MultiSnap(60, "verify indicator positioned")
    a2d.CloseWindow()
end)

--[[
  Launch DeskTop. Apple Menu > Control Panels. Open Map. Wait for the
  blinking indicator to be visible (this will be easier to observe in
  emulators with acceleration disabled), and drag the window to a new
  location. Type a city name (e.g. "San Francisco"). Click Find.
  Verify that the indicator blinks correctly only in the new location.
]]
test.Step(
  "Map - Indicator",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/MAP")
    emu.wait(1)

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
    a2dtest.MultiSnap(60, "verify only single indicator position")
    a2d.CloseWindow()
end)
