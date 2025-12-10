--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa202 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]--

test.Step(
  "Escape exits text preview",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/TOGGLE.ME")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    test.Snap("verify preview exited")
end)

test.Step(
  "Space toggles modes",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/TOGGLE.ME")

    apple2.SpaceKey() -- toggle modes
    a2d.WaitForRepaint()
    test.Snap("verify Fixed mode")

    apple2.SpaceKey() -- toggle modes
    a2d.WaitForRepaint()
    test.Snap("verify Proportional mode")

    a2d.CloseWindow()
end)

test.Step(
  "Click toggles modes",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/TOGGLE.ME")
    test.Snap("verify Proportional label baseline aligns with window title")

    local rect = mgtk.GetWinFrameRect(mgtk.FrontWindow())
    local x = rect[1] + rect[3] - 70
    local y = rect[2] + 4

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
    end)
    local dhr = a2dtest.SnapshotDHRWithoutClock()

    a2d.InMouseKeysMode(function(m)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify Fixed mode")
    test.Snap("verify Fixed label baseline aligns with window title")

    a2d.InMouseKeysMode(function(m)
        m.Click()
    end)
    a2d.WaitForRepaint()
    a2dtest.ExpectUnchangedExceptClock(dhr, "should have toggled back to Proportional")

    a2d.CloseWindow()
end)

test.Step(
  "Selection retained",
  function()
    a2d.SelectPath("/TESTS/FILE.TYPES/TOGGLE.ME")
    a2dtest.ExpectNothingChanged(function()
        a2d.OpenSelection()
        a2d.CloseWindow()
    end)
end)

test.Step(
  "Short file keeps scrollbar inactive",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/SHORT.TEXT")
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(vscroll & mgtk.scroll.option_active, 0, "scrollbar should be inactive")
    apple2.SpaceKey() -- toggle modes
    a2d.WaitForRepaint()
    hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(vscroll & mgtk.scroll.option_active, 0, "scrollbar should be inactive")
    a2d.CloseWindow()
end)

test.Step(
  "Long file and scrolling",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/LONG.TEXT")
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectNotEquals(vscroll & mgtk.scroll.option_active, 0, "scrollbar should be active")

    local dhr = a2dtest.SnapshotDHRWithoutClock()
    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify scrolled down by one line")

    apple2.UpArrowKey()
    a2d.WaitForRepaint()
    a2dtest.ExpectUnchangedExceptClock(dhr, "should have scrolled back up by one line")

    -- Page Down/Up using OA
    a2d.OADown()
    a2d.WaitForRepaint()
    test.Snap("verify scrolled down by one page")
    local dhr2 = a2dtest.SnapshotDHRWithoutClock()

    a2d.OAUp()
    a2d.WaitForRepaint()
    a2dtest.ExpectUnchangedExceptClock(dhr, "should have scrolled back up by one page")

    -- Page Down/Up using SA
    apple2.PressSA()
    apple2.DownArrowKey()
    apple2.ReleaseSA()
    a2d.WaitForRepaint()
    a2dtest.ExpectUnchangedExceptClock(dhr2, "should have scrolled down by one page")

    apple2.PressSA()
    apple2.UpArrowKey()
    apple2.ReleaseSA()
    a2d.WaitForRepaint()
    a2dtest.ExpectUnchangedExceptClock(dhr, "should have scrolled back up by one page")

    a2d.OASADown()
    a2d.WaitForRepaint()
    test.Snap("verify scrolled to end")

    a2d.OASAUp()
    a2d.WaitForRepaint()
    a2dtest.ExpectUnchangedExceptClock(dhr, "should have scrolled back to start")

    a2d.OASADown()
    apple2.SpaceKey() -- toggle mode
    a2d.WaitForRepaint()
    test.Snap("verify scrolled to top and Fixed mode")

    a2d.CloseWindow()
end)

test.Step(
  "Touching thumb doesn't cause repaint",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/LONG.TEXT")

    local up_x, up_y = a2dtest.GetFrontWindowUpScrollArrowCoords()

    apple2.PressSA()
    for i = 1, 70 do
      apple2.DownArrowKey()
    end
    apple2.ReleaseSA()
    a2d.WaitForRepaint()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(up_x, up_y + 70)
        a2dtest.ExpectNoRepaint(function()
            m.ButtonDown()
            emu.wait(10/60)
            test.Snap("verify thumb highlighted")
            m.ButtonUp()
            a2d.WaitForRepaint()
        end)
    end)
    a2d.CloseWindow()
    a2d.Reboot()
end)

test.Step(
  "Scroll is proportional",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/LONG.TEXT")

    local up_x, up_y = a2dtest.GetFrontWindowUpScrollArrowCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(up_x, up_y + 10)
        m.ButtonDown()
        m.MoveByApproximately(0, 60)
        m.ButtonUp()
    end)
    test.Snap("verify scrolled to about halfway through file")

    local dhr = a2dtest.SnapshotDHRWithoutClock()
    apple2.UpArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify scrolled up one line")

    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    a2dtest.ExpectUnchangedExceptClock(dhr, "should have scrolled down one line")

    a2d.CloseWindow()
end)

test.Step(
  "Performance: First page displays immediately",
  function()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/2)
    end)

    -- Disable ZIP Chip
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    apple2.Type("N")
    a2d.CloseWindow()

    a2d.SelectPath("/TESTS/FILE.TYPES/LONG.TEXT")
    a2d.OADown()
    emu.wait(3)
    test.Snap("verify text is displayed within 3s")
    emu.wait(15) -- let loading finish
    a2d.CloseWindow()

    -- Enable ZIP Chip
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    apple2.Type("F")
    a2d.CloseWindow()
end)

test.Step(
  "Tabs",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/TABS")
    test.Snap("verify all lines displayed correctly")
    a2d.CloseWindow()
end)

test.Step(
  "Scroll edge case",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/SUDOKU.STORY")
    apple2.SpaceKey() -- toggle to Fixed
    a2d.WaitForRepaint()
    for i = 1, 16 do
      apple2.DownArrowKey()
    end
    test.Snap("verify 'with' on last line")
    apple2.DownArrowKey()
    test.Snap("verify scrolled down one line")
    a2d.OASADown()
    test.Snap("verify scrolled to bottom of file")
    a2d.CloseWindow()
end)

test.Step(
  "Toggling and scrollbar",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/TOGGLE.ME")
    apple2.SpaceKey() -- toggle to Fixed
    a2d.WaitForRepaint()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectNotEquals(vscroll & mgtk.scroll.option_active, 0, "scrollbar should be active")
    local hthumbpos, vthumbpos = a2dtest.GetFrontWindowScrollPos()
    test.ExpectEquals(vthumbpos, 0, "scrollbar should be at top")

    a2d.OASADown()
    apple2.SpaceKey() -- toggle to Proportional
    a2d.WaitForRepaint()

    hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(vscroll & mgtk.scroll.option_active, 0, "scrollbar should be inactive")
end)
