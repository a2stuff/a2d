--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa202 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]--

apple2.SetMonitorType(apple2.MONITOR_TYPE_VIDEO7)

test.Step(
  "Escape exits",
  function()
    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH")
    a2dtest.ExpectNothingChanged(function()
        a2d.OpenSelection()
        apple2.EscapeKey()
        a2d.WaitForRepaint()
    end)
end)

test.Step(
  "OA+W exits",
  function()
    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH")
    a2dtest.ExpectNothingChanged(function()
        a2d.OpenSelection()
        a2d.OAShortcut("W")
        a2d.WaitForRepaint()
    end)
end)

test.Step(
  "Space toggles color/mono",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH")
    apple2.SpaceKey()
    a2d.WaitForRepaint()
    test.Snap("verify mono")
    apple2.SpaceKey()
    a2d.WaitForRepaint()
    test.Snap("verify color")
    a2d.CloseWindow()
end)

test.Step(
  ".A2HR opens in mono",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/HRMONO.A2HR")
    test.Snap("verify mono")
    a2d.CloseWindow()
end)

test.Step(
  ".A2LC opens in color",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/HRCOLOR.A2LC")
    test.Snap("verify color")
    a2d.CloseWindow()
end)

test.Step(
  "Clock appears immediately",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH")
    apple2.EscapeKey()

    apple2.Type('@') -- no-op, wait for key to be consumed

    a2dtest.ExpectClockVisible()

    a2d.WaitForRepaint()
end)

test.Step(
  "Arrow keys",
  function()
    a2d.OpenPath("/TESTS/PREVIEW/IMAGE/PICTURE1")
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify picture2")
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify picture3")
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify picture4")
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify picture5")
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify picture1")
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify picture2")
    apple2.LeftArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify picture1")
    apple2.LeftArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify picture5")

    apple2.PressOA()
    apple2.LeftArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify picture1")
    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify picture5")
    apple2.ReleaseOA()
    a2d.CloseWindow()
end)

test.Step(
  "Packed images",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/PACKED.FOT")
    emu.wait(10)
    test.Snap("verify preview still showing")
    a2d.CloseWindow()
end)


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

test.Step(
  "Menus not highlighted after exit",
  function()
    a2d.OpenPath("/TESTS/PREVIEW/IMAGE")

    -- Drop file menu without activating anything
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(30,5)
        m.Click()
        emu.wait(10)
        m.Click()
    end)

    -- Double-click on image file
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(40,50)
        m.DoubleClick()
    end)

    a2d.WaitForRepaint()
    apple2.EscapeKey()
    a2d.WaitForRepaint()

    a2dtest.ExpectMenuNotHighlighted()
end)

test.Step(
  "Cursor reappears",
  function()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2,apple2.SCREEN_HEIGHT/2)
    end)

    a2d.OpenPath("/TESTS/PREVIEW/IMAGE/PICTURE1")
    test.Snap("verify cursor is hidden")

    a2d.CloseWindow()
    test.Snap("verify cursor is visible")
end)

