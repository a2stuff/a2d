--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa202 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]--

apple2.SetMonitorType(apple2.MONITOR_TYPE_VIDEO7)

function IsMono()
  emu.wait_next_frame()
  -- https://docs.mamedev.org/luascript/ref-core.html#video-manager
  local pixels = manager.machine.video:snapshot_pixels()
  local width, height = manager.machine.video:snapshot_size()

  -- TODO: Make this work with IIgs border

  function pixel(x,y)
    local a = string.byte(pixels, (x + y * width) * 4 + 0)
    local b = string.byte(pixels, (x + y * width) * 4 + 1)
    local g = string.byte(pixels, (x + y * width) * 4 + 2)
    local r = string.byte(pixels, (x + y * width) * 4 + 3)
    return r,g,b,a
  end

  for y = 0,height-1 do
    for x = 0,width-1 do
      local r,g,b,a = pixel(x,y)
      if r ~= g or r ~=b then
        return false
      end
    end
  end

  return true
end

function IsColor()
  return not IsMono()
end

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
    test.Expect(IsMono(), "should be mono")
    apple2.SpaceKey()
    a2d.WaitForRepaint()
    test.Expect(IsColor(), "should be color")
    a2d.CloseWindow()
end)

test.Step(
  ".A2HR opens in mono",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/HRMONO.A2HR")
    test.Expect(IsMono(), "should be mono")
    a2d.CloseWindow()
end)

test.Step(
  ".A2LC opens in color",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/HRCOLOR.A2LC")
    test.Expect(IsColor(), "should be color")
    a2d.CloseWindow()
end)

test.Step(
  ".A2FM opens in mono",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/DHRMONO.A2FM")
    test.Expect(IsMono(), "should be mono")
    a2d.CloseWindow()
end)

test.Step(
  ".A2FC opens in color",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/DHRCOLOR.A2FC")
    test.Expect(IsColor(), "should be color")
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

    local file_menu_x, file_menu_y = 30, 5
    -- Drop file menu without activating anything
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_menu_x, file_menu_y)
        m.Click()
        emu.wait(10)
        m.Click()
    end)

    -- Double-click on image file
    local window_x,window_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(window_x + 35, window_y + 23)
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
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/2)
    end)

    a2d.OpenPath("/TESTS/PREVIEW/IMAGE/PICTURE1")
    test.Snap("verify cursor is hidden")

    a2d.CloseWindow()
    test.Snap("verify cursor is visible")
end)

