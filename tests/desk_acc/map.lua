a2d.ConfigureRepaintTime(0.25)

--[[
  Launch DeskTop. Apple Menu > Control Panels. Open Map. Type a known
  city name e.g. "San Francisco". Click Find. Verify that the city is
  highlighted on the map and the Latitude/Longitude are updated.
]]
test.Step(
  "Map - Search",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/MAP", {no_validate=true})
    emu.wait(1)

    apple2.Type("San Francisco")
    apple2.ReturnKey()
    a2d.WaitForRepaint()
    local ocr = a2dtest.OCRFrontWindowContent()
    test.Expect(ocr:find("Latitude: +37° N"), "latitude should be updated")
    test.Expect(ocr:find("Longitude: +122° W"), "longitude should be updated")
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
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/MAP", {no_validate=true})
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

test.Step(
  "Search is case insensitive",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/MAP", {no_validate=true})
    emu.wait(1)

    function TryString(search, match)
      a2d.ClearTextField()
      apple2.Type(search)
      apple2.ReturnKey()
      a2d.WaitForRepaint()
      apple2.Type("    ") -- ensure OCR doesn't get confused by caret
      a2d.WaitForRepaint()
      test.ExpectMatch(a2dtest.OCRFrontWindowContent(), match,
                       string.format("should have matched %q", match))
    end

    TryString("VAN", "Vancouver")
    TryString("VIC", "Victoria")
    TryString("van", "Vancouver")
    TryString("vic", "Victoria")
    TryString("VaNcOuVeR", "Vancouver")
    TryString("ViCtOrIa", "Victoria")

    a2d.ClearTextField()
    apple2.Type("VICTORIAX")
    apple2.ReturnKey()
    a2d.WaitForRepaint()
    apple2.Type("    ") -- ensure OCR doesn't get confused by caret
    a2d.WaitForRepaint()
    test.ExpectMatch(a2dtest.OCRFrontWindowContent(), "VICTORIAX", "should not have matched")

    -- and hasn't crashed
    TryString("vic", "Victoria")

    -- clean up
    a2d.CloseWindow()
end)
