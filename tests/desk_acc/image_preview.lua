--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa202"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)
apple2.SetMonitorType(apple2.MONITOR_TYPE_VIDEO7)

--[[
  Verify that Escape key exits.
]]
test.Step(
  "Escape exits",
  function()
    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/ROOM")
    a2dtest.ExpectNothingChanged(function()
        a2d.OpenSelection()
        apple2.EscapeKey()
        a2d.WaitForRepaint()
    end)
end)

--[[
  Verify that Apple+W exits.
]]
test.Step(
  "OA+W exits",
  function()
    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/ROOM")
    a2dtest.ExpectNothingChanged(function()
        a2d.OpenSelection()
        a2d.OAShortcut("W")
        a2d.WaitForRepaint()
    end)
end)

--[[
  Verify that space bar toggles color/mono.
]]
test.Step(
  "Space toggles color/mono",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/ROOM")
    apple2.SpaceKey()
    a2d.WaitForRepaint()
    test.Expect(apple2.IsMono(), "should be mono")
    apple2.SpaceKey()
    a2d.WaitForRepaint()
    test.Expect(apple2.IsColor(), "should be color")
    a2d.CloseWindow()
end)

--[[
  Open `/TESTS/FILE.TYPES/HRMONO.A2HR`. Verify it displays as mono by
  default.
]]
test.Step(
  ".A2HR opens in mono",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/HRMONO.A2HR")
    test.Expect(apple2.IsMono(), "should be mono")
    a2d.CloseWindow()
end)

--[[
  Open `/TESTS.FILE.TYPES/HRCOLOR.A2LC`. Verify it displays as color
  by default.
]]
test.Step(
  ".A2LC opens in color",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/HRCOLOR.A2LC")
    test.Expect(apple2.IsColor(), "should be color")
    a2d.CloseWindow()
end)

test.Step(
  ".A2FM opens in mono",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/DHRMONO.A2FM")
    test.Expect(apple2.IsMono(), "should be mono")
    a2d.CloseWindow()
end)

test.Step(
  ".A2FC opens in color",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/DHRCOLOR.A2FC")
    test.Expect(apple2.IsColor(), "should be color")
    a2d.CloseWindow()
end)

--[[
  Configure a system with a real-time clock. Launch DeskTop. Preview
  an image file. Exit the preview. Verify that the menu bar clock
  reappears immediately.
]]
test.Step(
  "Clock appears immediately",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/ROOM")
    apple2.EscapeKey()

    apple2.Type('@') -- no-op, wait for key to be consumed

    a2dtest.ExpectClockVisible()

    a2d.WaitForRepaint()
end)

--[[
  In a directory with multiple images, preview one image. Verify that
  Left Arrow shows the previous image (and wraps around), Right Arrow
  shows the next image (and wraps around), Apple+Left Arrow shows the
  first image, and Apple+Right Arrow shows the last image. Note that
  order is per the natural directory order, e.g. as shown in View > as
  Icons.
]]
test.Step(
  "Arrow keys",
  function()
    local pics = {}
    a2d.OpenPath("/TESTS/PREVIEW/IMAGE")
    for i = 1, 5 do
      a2d.SelectAndOpen("PICTURE" .. i)
      pics[i] = apple2.SnapshotDHR()
      apple2.EscapeKey()
      a2d.WaitForRepaint()
    end
    function ExpectPicture(n)
      test.Expect(
        a2dtest.CompareDHR(pics[n], apple2.SnapshotDHR()),
        "should be picture " .. n, {}, 1)
    end

    a2d.OpenPath("/TESTS/PREVIEW/IMAGE/PICTURE1")
    ExpectPicture(1)
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    ExpectPicture(2)
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    ExpectPicture(3)
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    ExpectPicture(4)
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    ExpectPicture(5)
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    ExpectPicture(1)
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    ExpectPicture(2)
    apple2.LeftArrowKey()
    a2d.WaitForRepaint()
    ExpectPicture(1)
    apple2.LeftArrowKey()
    a2d.WaitForRepaint()
    ExpectPicture(5)

    a2d.OALeft()
    a2d.WaitForRepaint()
    ExpectPicture(1)

    a2d.OARight()
    a2d.WaitForRepaint()
    ExpectPicture(5)

    a2d.CloseWindow()
end)

--[[
  Open `/TESTS/FILE.TYPES/PACKED.FOT`. Verify that the preview does
  not immediately exit after the image loads.
]]
test.Step(
  "Packed images",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/PACKED.FOT")
    emu.wait(10)
    test.Snap("verify preview still showing")
    a2d.CloseWindow()
end)

--[[
  In a directory with multiple images, preview one image. Press S.
  Verify that a slideshow starts. Press S again, verify that the
  slideshow stops.
]]
test.Step(
  "Slideshow - S starts and stops",
  function()
    a2d.OpenPath("/TESTS/PREVIEW/IMAGE/PICTURE1")
    apple2.Type("S") -- start
    local dhr = apple2.SnapshotDHR()
    for i=1,6 do
      emu.wait(3)
      local new = apple2.SnapshotDHR()
      test.Expect(not a2dtest.CompareDHR(dhr, new), "slideshow should be running", {snap=true})
      dhr = new
    end
    apple2.Type("S") -- anything (including S) stops
    dhr = apple2.SnapshotDHR()
    for i=1,3 do
      emu.wait(3)
      local new = apple2.SnapshotDHR()
      test.Expect(a2dtest.CompareDHR(dhr, new), "slideshow should be stopped", {snap=true})
    end
    a2d.CloseWindow()
end)

--[[
  In a directory with multiple images, preview one image. Press S.
  Verify that a slideshow starts. Press D (or any key that doesn't
  have a special purpose). Verify that the slideshow stops. Press S.
  Verify that a slideshow starts again.
]]
test.Step(
  "Slideshow - S starts and anything stops and S restarts",
  function()
    a2d.OpenPath("/TESTS/PREVIEW/IMAGE/PICTURE1")
    apple2.Type("S") -- start
    local dhr = apple2.SnapshotDHR()
    for i=1,6 do
      emu.wait(3)
      local new = apple2.SnapshotDHR()
      test.Expect(not a2dtest.CompareDHR(dhr, new), "slideshow should be running", {snap=true})
      dhr = new
    end
    apple2.Type("D") -- anything stops
    dhr = apple2.SnapshotDHR()
    for i=1,3 do
      emu.wait(3)
      local new = apple2.SnapshotDHR()
      test.Expect(a2dtest.CompareDHR(dhr, new), "slideshow should be stopped", {snap=true})
    end
    apple2.Type("S") -- start
    dhr = apple2.SnapshotDHR()
    for i=1,6 do
      emu.wait(3)
      local new = apple2.SnapshotDHR()
      test.Expect(not a2dtest.CompareDHR(dhr, new), "slideshow should be running", {snap=true})
      dhr = new
    end
    a2d.CloseWindow()
end)

--[[
  In a directory with multiple images, preview one image. Press S.
  Verify that a slideshow starts. Press Left Arrow. Verify that the
  previous image is shown, and that the slideshow stops. Press S.
  Verify that a slideshow starts again.
]]
test.Step(
  "Slideshow - arrow keys work and abort slideshow",
  function()
    a2d.OpenPath("/TESTS/PREVIEW/IMAGE/PICTURE1")
    apple2.Type("S") -- start
    local dhr = apple2.SnapshotDHR()
    for i=1,6 do
      emu.wait(3)
      local new = apple2.SnapshotDHR()
      test.Expect(not a2dtest.CompareDHR(dhr, new), "slideshow should be running", {snap=true})
      dhr = new
    end
    test.Snap("note current slide")
    apple2.LeftArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify backed up one slide")
    a2dtest.ExpectNothingChanged(function()
        emu.wait(3)
    end)

    apple2.Type("S") -- start
    dhr = apple2.SnapshotDHR()
    for i=1,3 do
      emu.wait(3)
      local new = apple2.SnapshotDHR()
      test.Expect(not a2dtest.CompareDHR(dhr, new), "slideshow should be running", {snap=true})
      dhr = new
    end
    a2d.CloseWindow()
end)

--[[
  Click on the File menu, then close it. Double-click an image file.
  Press Escape to close the preview. Verify that the File menu is not
  highlighted.
]]
test.Step(
  "Menus not highlighted after exit",
  function()
    a2d.OpenPath("/TESTS/PREVIEW/IMAGE")

    a2d.Select("PICTURE1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

    local file_menu_x, file_menu_y = 30, 5
    -- Drop file menu without activating anything
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_menu_x, file_menu_y)
        m.Click()
        emu.wait(10)
        m.Click()
    end)

    -- Double-click on image file
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.DoubleClick()
    end)

    a2d.WaitForRepaint()
    apple2.EscapeKey()
    a2d.WaitForRepaint()

    a2dtest.ExpectMenuNotHighlighted()
end)

--[[
  Preview an image file. Verify that the mouse cursor is hidden.
  Without moving the mouse, press the Escape key. Verify that after
  the desktop repaints the mouse cursor becomes visible without
  needing to move the mouse first.
]]
test.Step(
  "Cursor reappears",
  function()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/2)
    end)

    a2d.OpenPath("/TESTS/PREVIEW/IMAGE/PICTURE1")
    test.Snap("verify cursor is hidden")

    a2d.CloseWindow()
    test.Snap("verify cursor is visible")
end)

