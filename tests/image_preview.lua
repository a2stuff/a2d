--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa202 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]--

apple2.SetMonitorType(apple2.MONITOR_TYPE_VIDEO7)

test.Step(
  "Escape exits",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    test.Snap("verify preview exited")
end)

test.Step(
  "OA+W exits",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH")
    a2d.OAShortcut("W")
    a2d.WaitForRepaint()
    test.Snap("verify preview exited")
end)

test.Step(
  "Space toggles color/mono",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH")
    apple2.SpaceKey()
    a2d.WaitForRepaint()
    test.Snap("verify space toggled to mono")
    apple2.SpaceKey()
    a2d.WaitForRepaint()
    test.Snap("verify space toggled to color")
    a2d.CloseWindow()
end)

test.Step(
  ".A2HR opens in mono",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/HRMONO.A2HR")
    test.Snap("verify opened in mono")
    a2d.CloseWindow()
end)

test.Step(
  ".A2LC opens in color",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/HRCOLOR.A2LC")
    test.Snap("verify opened in color")
    a2d.CloseWindow()
end)

test.Step(
  "Clock appears immediately",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH")
    apple2.EscapeKey()

    apple2.Type('@') -- no-op, wait for key to be consumed

    test.ExpectNotEquals(apple2.GetDoubleHiresByte(4, 78), 0x7F, "Clock should be visible already")
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
    test.Snap("verify preview does not exit spontaneously")
    a2d.CloseWindow()
end)


test.Step(
  "Slideshow - S starts and stops",
  function()
    a2d.OpenPath("/TESTS/PREVIEW/IMAGE/PICTURE1")
    apple2.Type("S") -- start
    for i=1,6 do
      emu.wait(3)
      test.Snap("verify slideshow running")
    end
    apple2.Type("S") -- anything (including S) stops
    for i=1,3 do
      emu.wait(3)
      test.Snap("verify slideshow stopped")
    end
    a2d.CloseWindow()
end)

test.Step(
  "Slideshow - S starts and anything stops and S restarts",
  function()
    a2d.OpenPath("/TESTS/PREVIEW/IMAGE/PICTURE1")
    apple2.Type("S") -- start
    for i=1,6 do
      emu.wait(3)
      test.Snap("verify slideshow running")
    end
    apple2.Type("D") -- anything stops
    for i=1,3 do
      emu.wait(3)
      test.Snap("verify slideshow stopped")
    end
    apple2.Type("S") -- start
    for i=1,6 do
      emu.wait(3)
      test.Snap("verify slideshow running")
    end
    a2d.CloseWindow()
end)

test.Step(
  "Slideshow - arrow keys work and abort slideshow",
  function()
    a2d.OpenPath("/TESTS/PREVIEW/IMAGE/PICTURE1")
    apple2.Type("S") -- start
    for i=1,6 do
      emu.wait(3)
      test.Snap("verify slideshow running")
    end
    apple2.LeftArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify backed up one slide")
    emu.wait(3)
    test.Snap("verify slideshow was stopped")

    apple2.Type("S") -- start
    for i=1,3 do
      emu.wait(3)
      test.Snap("verify slideshow running")
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

    test.Snap("verify file menu is not highlighted")
end)

test.Step(
  "Cursor reappears",
  function()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(280,96)
    end)

    a2d.OpenPath("/TESTS/PREVIEW/IMAGE/PICTURE1")
    test.Snap("verify cursor is hidden")

    a2d.CloseWindow()
    test.Snap("verify cursor is visible")
end)

