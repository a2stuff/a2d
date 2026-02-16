--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Launch DeskTop. Open a volume window with many items. Adjust the
  window so that the scrollbars are active. Drag a file icon slightly
  within the middle of the view, so that the scrollbars don't change.
  Verify that the scrollbars don't repaint/flicker.
]]
test.Step(
  "moving an icon doesn't always cause scrollbars to repaint",
  function()
    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH")
    a2d.GrowWindowBy(-100, -50)
    emu.wait(1)
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        m.MoveByApproximately(10, 10)
        a2dtest.ExpectRepaintFraction(
          0, 0.1,
          function()
            m.ButtonUp()
            emu.wait(1)
          end,
          "scrollbars do not repaint")
    end)
end)

--[[
  Launch DeskTop. Open a volume window with icons. Resize the window
  so that the horizontal scrollbar is active. Move the window so the
  left edge of the scrollbar thumb is off-screen to the left. Click on
  the right arrow, and verify that the window scrolls correctly.
  Repeat for the page right region.
]]
test.Variants(
  {
    {"scrollbar with clipped thumb still works - right arrow", "arrow"},
    {"scrollbar with clipped thumb still works - right pager", "page"},
  },
  function(idx, name, where)
    a2d.OpenPath("/A2.DESKTOP")
    a2d.GrowWindowBy(-50, 0)
    a2d.MoveWindowBy(-40, 0)
    emu.wait(1)
    test.Snap("verify thumb cut off on left")

    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        if where == "arrow" then
          m.MoveToApproximately(x + w - 5, y + h + 5)
        else
          m.MoveToApproximately(x + w - 50, y + h + 5)
        end
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify window scrolled right")
end)

--[[
  Launch DeskTop. Open a window with a single icon. Move the icon so
  it overlaps the left edge of the window. Verify scrollbar appears.
  Hold scroll arrow. Verify icon scrolls into view, and eventually the
  scrollbar deactivates. Repeat with right edge.
]]
test.Step(
  "scrollbar deactivates when not needed",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.SelectPath("/RAM1/READ.ME")

    -- Left
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    a2d.Drag(icon_x, icon_y, x+5, icon_y)
    a2d.WaitForRepaint()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectNotEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be active")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + 5, y + h + 5)
        m.ButtonDown()
        emu.wait(1)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be inactive")

    -- Right
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    a2d.Drag(icon_x, icon_y, x+w-5, icon_y)
    a2d.WaitForRepaint()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectNotEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be active")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w - 5, y + h + 5)
        m.ButtonDown()
        emu.wait(1)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be inactive")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a window with 11-15 icons. Verify scrollbars
  are not active.
]]
test.Step(
  "No scrollbars for 11-15 icons",
  function()
    a2d.OpenPath("/RAM1")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    apple2.WaitForBasicSystem()
    apple2.TypeLine("10 FOR I = 1 TO 15 : ?CHR$(4)\"CREATE F\"I : NEXT")
    apple2.TypeLine("RUN")
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
    a2d.OpenPath("/RAM1")
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "h scrollbar should be inactive")
    test.ExpectEquals(vscroll & mgtk.scroll.option_active, 0, "v scrollbar should be inactive")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Open a window that will require vertical scrollbars. Verify that the
  scrollbars do not repaint after the contents.
]]
test.Step(
  "Scrollbars in new window paint before items",
  function()
    a2d.OpenPath("/TESTS", {no_wait=true})
    a2dtest.MultiSnap(60, "verify scrollbars paint before items")
end)

--[[
  Open an empty window. Exit desktop, add a file to the directory, and
  restart. Verify scrollbars don't appear.
]]
test.Step(
  "No scrollbars when file added to empty directory outside DeskTop",
  function()
    a2d.OpenPath("/RAM1")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    apple2.WaitForBasicSystem()
    apple2.TypeLine("10 NEW")
    apple2.TypeLine("SAVE MMMMMMMMMMMMMMM")
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "h scrollbar should be inactive")
    test.ExpectEquals(vscroll & mgtk.scroll.option_active, 0, "v scrollbar should be inactive")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a volume window with multiple icons but that do
  not require the scrollbars to be active. Drag the first icon over to
  the right so that it is partially clipped by the window's right or
  bottom edge. Verify that the appropriate scrollbars activate.
]]
test.Step(
  "scrollbar activates even for first icon if on right",
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS")
    emu.wait(1)
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be inactive")

    apple2.DownArrowKey() -- select first
    emu.wait(1)

    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    a2d.Drag(icon_x, icon_y, x + w - 10, icon_y)
    a2d.WaitForRepaint()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectNotEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be active")
end)

--[[
  Launch DeskTop. Open a window containing folders and files. Open
  another window, for an empty volume. Drag an icon from the first to
  the second. Ensure no scrollbars activate in the target window.
]]
test.Step(
  "Dragging file to empty window doesn't activate scrollbars",
  function()
    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(0, 90)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.OpenPath("/A2.DESKTOP", {keep_windows=true})
    a2d.GrowWindowBy(0, -40)
    a2d.Select("READ.ME")
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(icon_x, icon_y, dst_x, dst_y)
    emu.wait(1)

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "window should be activated")
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "h scrollbar should be inactive")
    test.ExpectEquals(vscroll & mgtk.scroll.option_active, 0, "v scrollbar should be inactive")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a window containing folders and files, with no
  scrollbars active. Open another window. Drag an icon from the first
  to the second. Ensure no scrollbars activate in the source window.
]]
test.Step(
  "Moving file doesn't activate source window scrollbars",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.CreateFolder("/RAM1/FOLDER")

    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(0, 90)

    a2d.SelectAndOpen("FOLDER", {leave_parent=true})
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.CycleWindows()

    a2d.Select("READ.ME")
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(icon_x, icon_y, dst_x, dst_y)
    emu.wait(1)

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "FOLDER", "window should be activated")
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "window should be activated")
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "h scrollbar should be inactive")
    test.ExpectEquals(vscroll & mgtk.scroll.option_active, 0, "v scrollbar should be inactive")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Open `/TESTS/HUNDRED.FILES`, without resizing the window. Scroll up
  and down by one tick, by one page, and to the top/bottom. Verify
  that such operations scroll by an integral number of icons, i.e. the
  last row of labels are always the same distance from the bottom of
  the window.
]]
test.Step(
  "Default scrolling is by integral number of icons",
  function()
    a2d.OpenPath("/TESTS/HUNDRED.FILES")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    emu.wait(5)
    a2d.InMouseKeysMode(function(m)
        test.Snap("note icon positions")
        for i = 1, 2 do
          -- Down by one tick
          m.MoveToApproximately(x + w + 10, y + h - 5)
          m.Click()
          emu.wait(2)
          test.Snap("icons should still be aligned")
        end
        for i = 1, 2 do
          -- Up by one tick
          m.MoveToApproximately(x + w + 10, y + 5)
          m.Click()
          emu.wait(2)
          test.Snap("icons should still be aligned")
        end
        for i = 1, 2 do
          -- Down by one page
          m.MoveToApproximately(x + w + 10, y + h - 20)
          m.Click()
          emu.wait(2)
          test.Snap("icons should still be aligned")
        end
        for i = 1, 2 do
          -- Up by one page
          m.MoveToApproximately(x + w + 10, y + 20)
          m.Click()
          emu.wait(2)
          test.Snap("icons should still be aligned")
        end
        m.Home()
        -- to bottom
        m.MoveToApproximately(x + w + 10, y + h - 5)
        for i = 1, 20 do
          m.Click()
          emu.wait(2)
        end
        test.Snap("icons should still be aligned")
        -- to top
        m.MoveToApproximately(x + w + 10, y + 5)
        for i = 1, 20 do
          m.Click()
          emu.wait(2)
        end
        test.Snap("icons should still be aligned")
    end)
end)

--[[
  Launch DeskTop. Open a volume window with enough icons that a
  scrollbar appears. Click on an active part of the scrollbar. Verify
  that the scrollbar responds immediately, not after the double-click
  detection delay expires.
]]
test.Step(
  "Active scrollbars respond immediately",
  function()
    a2d.OpenPath("/TESTS")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w + 5, y + h / 2)
        m.Click()
        a2dtest.MultiSnap(60, "should repaint quickly")
    end)
end)

--[[
  Launch DeskTop. Open a volume window where the vertical and
  horizontal scrollbars are inactive. Click on each inactive
  scrollbar. Verify nothing happens.
]]
test.Step(
  "Inactive scrollbar are inactive",
  function()
    a2d.OpenPath("/RAM1")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m) m.Home() end)
    a2dtest.ExpectNothingChanged(function()
        a2d.InMouseKeysMode(function(m)
            m.MoveToApproximately(x + w + 5, y + h / 2)
            m.Click()
            m.MoveToApproximately(x + w / 2, y + h + 5)
            m.Click()
            m.Home()
        end)
    end)
end)
