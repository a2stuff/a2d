--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa202"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(2)

--[[
  Verify that Escape key exits.
]]
test.Step(
  "Escape exits text preview",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/TOGGLE.ME")
    local window_id = a2dtest.GetFrontWindowID()
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    test.ExpectNotEquals(a2dtest.GetFrontWindowID(), window_id, "preview should have exited")
end)

--[[
  Verify that Space toggles Proportional/Fixed mode.
]]
test.Step(
  "Space toggles modes",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/TOGGLE.ME")

    apple2.SpaceKey() -- toggle modes
    a2d.WaitForRepaint()
    test.ExpectMatch(a2dtest.OCRScreen(), "Fixed", "should be in Fixed mode")

    apple2.SpaceKey() -- toggle modes
    a2d.WaitForRepaint()
    test.ExpectMatch(a2dtest.OCRScreen(), "Proportional", "should be in Proportional mode")

    a2d.CloseWindow()
end)

--[[
  Verify that clicking in the right part of the title bar toggles
  Proportional/Fixed mode.

  Verify that the "Proportional" label has the same baseline as the
  window title. Click on "Proportional". Verify that the "Fixed" label
  has the same baseline as the window title.
]]
test.Step(
  "Click toggles modes",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/TOGGLE.ME")
    test.ExpectMatch(a2dtest.OCRScreen(), "TOGGLE%.ME .* Proportional",
                "Proportional label baseline should align with window title")

    local wx, wy, ww, wh = a2dtest.GetFrontWindowContentRect()
    local x, y = wx + ww + 12, wy - 8

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
    end)
    local dhr = a2dtest.SnapshotDHRWithoutClock()

    a2d.InMouseKeysMode(function(m)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectMatch(a2dtest.OCRScreen(), "TOGGLE%.ME .* Fixed",
                "Fixed label baseline should align with window title")

    a2d.InMouseKeysMode(function(m)
        m.Click()
    end)
    a2d.WaitForRepaint()
    a2dtest.ExpectUnchangedExceptClock(dhr, "should have toggled back to Proportional")

    a2d.CloseWindow()
end)

--[[
  Verify that DeskTop's selection is not cleared on exit.
]]
test.Step(
  "Selection retained",
  function()
    a2d.SelectPath("/TESTS/FILE.TYPES/TOGGLE.ME")
    a2dtest.ExpectNothingChanged(function()
        a2d.OpenSelection()
        a2d.CloseWindow()
    end)
end)

--[[
  Open `/TESTS/FILE.TYPES/SHORT.TEXT`.

  * Verify that the scrollbar is inactive.

  * Click "Proportional". Verify that the scrollbar remains inactive.

  * Click "Fixed". Verify that the scrollbar remains inactive.
]]
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

--[[
  Open `/TESTS/FILE.TYPES/LONG.TEXT`.

  * Verify that the scrollbar is active.

  * Verify that Up/Down Arrow keys scroll by one line.

  * Verify that Open-Apple plus Up/Down Arrow keys scroll by page.

  * Verify that Solid-Apple plus Up/Down Arrow keys scroll by page.

  * Verify that Open-Apple plus Solid-Apple plus Up/Down Arrow keys
    scroll to start/end.

  * Click the Proportional/Fixed button on the title bar. Verify that
    the view is scrolled to the top.
]]
test.Step(
  "Long file and scrolling",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/LONG.TEXT")
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectNotEquals(vscroll & mgtk.scroll.option_active, 0, "scrollbar should be active")

    local dhr = a2dtest.SnapshotDHRWithoutClock()
    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    local ocr = a2dtest.OCRScreen()
    test.Expect(ocr:find("THIS IS LINE 2") and
                ocr:find("THIS IS LINE 16"), "should have scrolled down by one line")

    apple2.UpArrowKey()
    a2d.WaitForRepaint()
    local ocr = a2dtest.OCRScreen()
    test.Expect(ocr:find("THIS IS LINE 1") and
                ocr:find("THIS IS LINE 15"), "should have scrolled back up by one line")

    -- Page Down/Up using OA
    a2d.OADown()
    a2d.WaitForRepaint()
    local ocr = a2dtest.OCRScreen()
    test.Expect(ocr:find("THIS IS LINE 15") and
                ocr:find("THIS IS LINE 29"), "should have scrolled down by one page")
    local dhr2 = a2dtest.SnapshotDHRWithoutClock()

    a2d.OAUp()
    a2d.WaitForRepaint()
    a2dtest.ExpectUnchangedExceptClock(dhr, "should have scrolled back up by one page")

    -- Page Down/Up using SA
    a2d.SADown()
    a2d.WaitForRepaint()
    a2dtest.ExpectUnchangedExceptClock(dhr2, "should have scrolled down by one page")

    a2d.SAUp()
    a2d.WaitForRepaint()
    a2dtest.ExpectUnchangedExceptClock(dhr, "should have scrolled back up by one page")

    -- Home/End using OA+SA
    a2d.OASADown()
    a2d.WaitForRepaint()
    test.ExpectMatch(a2dtest.OCRScreen(), "THIS IS LINE 2000",
                "should have scrolled to end")

    a2d.OASAUp()
    a2d.WaitForRepaint()
    a2dtest.ExpectUnchangedExceptClock(dhr, "should have scrolled back to start")

    a2d.OASADown()
    apple2.SpaceKey() -- toggle mode
    a2d.WaitForRepaint()
    test.Snap("verify scrolled to top and Fixed mode")

    a2d.CloseWindow()
end)

--[[
  Open `/TESTS/FILE.TYPES/LONG.TEXT`.

  * Scroll somewhere in the file. Click the scrollbar thumb without
    moving it. Verify the thumb doesn't move and the content doesn't
    scroll.
]]
test.Step(
  "Touching thumb doesn't cause repaint",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/LONG.TEXT")

    local up_x, up_y = a2dtest.GetFrontWindowUpScrollArrowCoords()

    apple2.PressSA()
    for i = 1, 70 do
      apple2.DownArrowKey()
      emu.wait(0.25)
    end
    apple2.ReleaseSA()
    emu.wait(1)
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(up_x, up_y + 70)
        a2dtest.ExpectNoRepaint(function()
            m.ButtonDown()
            emu.wait(1)
            test.Snap("verify thumb highlighted")
            m.ButtonUp()
            a2d.WaitForRepaint()
        end)
    end)
    a2d.CloseWindow()
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Open `/TESTS/FILE.TYPES/LONG.TEXT`.

  * Verify that dragging the scroll thumb to the middle shows
  approximately the middle of the file.

  * Verify that Up/Down Arrow keys scroll by one line consistently.
]]
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

--[[
  Open `/TESTS/FILE.TYPES/LONG.TEXT`.

  * Verify that the first page of content appears immediately, and
    that the watch cursor is shown while the rest of the file is
    parsed. With any acceleration disabled, use
    Open-Apple+Solid-Apple+Down to jump to the bottom of the file.
    Verify that the view is displayed without undue delay.
]]
test.Step(
  "Performance: First page displays immediately",
  function()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/2)
    end)

    -- Disable ZIP Chip
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    apple2.Type("N") -- Normal Speed
    a2d.CloseWindow()

    a2d.SelectPath("/TESTS/FILE.TYPES/LONG.TEXT")
    a2d.OADown()
    emu.wait(3)
    test.Snap("verify text is displayed within 3s")
    emu.wait(15) -- let loading finish
    a2d.CloseWindow()

    -- Enable ZIP Chip
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    apple2.Type("F") -- Fast Speed
    a2d.CloseWindow()
end)

--[[
  Open `/TESTS/FILE.TYPES/TABS`. Verify that the file displays all
  lines correctly.
]]
test.Step(
  "Tabs",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/TABS")
    test.Snap("verify all lines displayed correctly")
    a2d.CloseWindow()
end)

--[[
  Open `/TESTS/FILE.TYPES/SUDOKU.STORY`. Click on "Proportional" to
  change to "Fixed" font. Scroll down using down arrow key until
  bottom line reads "with". Scroll down again using down arrow key.
  Verify that the file correctly scrolled down one line. Scroll to the
  bottom of the file. Ensure the entire file is visible.
]]
test.Step(
  "Scroll edge case",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/SUDOKU.STORY")
    apple2.SpaceKey() -- toggle to Fixed
    a2d.WaitForRepaint()
    for i = 1, 15 do
      apple2.DownArrowKey()
    end
    a2d.WaitForRepaint()
    test.Snap("verify 'with' on last line")
    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify scrolled down one line")
    a2d.OASADown()
    a2d.WaitForRepaint()
    test.Snap("verify scrolled to bottom of file")
    a2d.CloseWindow()
end)

--[[
  Open `/TESTS/FILE.TYPES/TOGGLE.ME`. Click "Proportional" to toggle
  to "Fixed". Verify that the scrollbar activates and that the thumb
  is at the top. Scroll down. Click "Fixed" to toggle to
  "Proportional". Verify that the scrollbar deactivates.
]]
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
    a2d.CloseWindow()
end)

--[[
  Open `/TESTS/PREVIEW/TEXT/MORE.THAN.64K`. Verify the screen does not
  get corrupted and the file load completes. Scroll to the bottom. Verify
  that the last lines are around "L 9440" not "L 220".
]]
test.Step(
  "File bigger than 64K",
  function()
    a2d.OpenPath("/TESTS/PREVIEW/TEXT/MORE.THAN.64K")
    emu.wait(20)
    a2d.OASADown()

    local ocr = a2dtest.OCRScreen();
    test.ExpectNotMatch(ocr, "L 283", "file should not be truncated to about 200 lines")
    test.ExpectMatch(ocr, "L 9440", "file should show about 9400 lines")
    a2d.CloseWindow()
end)
