--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

desktop.AddShortcut("/TESTS/HUNDRED.FILES")
desktop.CloseAllWindows()

--[[
  Launch DeskTop. Open a volume window with many items. Adjust the
  window so that the scrollbars are active. Drag a file icon slightly
  within the middle of the view, so that the scrollbars don't change.
  Verify that the scrollbars don't repaint/flicker.
]]
test.Step(
  "moving an icon doesn't always cause scrollbars to repaint",
  function()
    desktop.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH")
    desktop.GrowWindowBy(-100, -50)
    a2dtest.WaitForSystemTask()
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        m.MoveByApproximately(10, 10)
        a2dtest.ExpectRepaintFraction(
          0, 0.1,
          function()
            m.ButtonUp()
            a2dtest.WaitForSystemTask()
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
    desktop.OpenWindow("/A2.DESKTOP")
    desktop.GrowWindowBy(-50, 0)
    desktop.MoveWindowBy(-40, 0)
    a2dtest.WaitForSystemTask()
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
    a2dtest.WaitForSystemTask()
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
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    desktop.SelectPath("/RAM1/READ.ME")

    -- Left
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    a2d.Drag(icon_x, icon_y, x+5, icon_y)
    a2dtest.WaitForSystemTask()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectNotEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be active")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + 5, y + h + 5)
        m.ButtonDown()
        emu.wait(1) -- scroll all the way to the bottom
        m.ButtonUp()
    end)
    a2dtest.WaitForSystemTask()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be inactive")

    -- Right
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    a2d.Drag(icon_x, icon_y, x+w-5, icon_y)
    a2dtest.WaitForSystemTask()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectNotEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be active")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w - 5, y + h + 5)
        m.ButtonDown()
        emu.wait(1) -- scroll all the way to the bottom
        m.ButtonUp()
    end)
    a2dtest.WaitForSystemTask()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be inactive")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a window with 11-15 icons. Verify scrollbars
  are not active.
]]
test.Step(
  "No scrollbars for 11-15 icons",
  function()
    desktop.OpenWindow("/RAM1")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.RUN_BASIC_HERE)
    apple2.WaitForBasicSystem()
    apple2.TypeLine("10 FOR I = 1 TO 15 : ?CHR$(4)\"CREATE F\"I : NEXT")
    apple2.TypeLine("RUN")
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
    desktop.OpenWindow("/RAM1")
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "h scrollbar should be inactive")
    test.ExpectEquals(vscroll & mgtk.scroll.option_active, 0, "v scrollbar should be inactive")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Open a window that will require vertical scrollbars. Verify that the
  scrollbars do not repaint after the contents.
]]
test.Step(
  "Scrollbars in new window paint before items",
  function()
    desktop.OpenWindow("/TESTS", {no_wait=true})
    a2dtest.MultiSnap(60, "verify scrollbars paint before items")
end)

--[[
  Open an empty window. Exit desktop, add a file to the directory, and
  restart. Verify scrollbars don't appear.
]]
test.Step(
  "No scrollbars when file added to empty directory outside DeskTop",
  function()
    desktop.OpenWindow("/RAM1")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.RUN_BASIC_HERE)
    apple2.WaitForBasicSystem()
    apple2.TypeLine("10 NEW")
    apple2.TypeLine("SAVE MMMMMMMMMMMMMMM")
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "h scrollbar should be inactive")
    test.ExpectEquals(vscroll & mgtk.scroll.option_active, 0, "v scrollbar should be inactive")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Open an empty window. Set the view to "By Name". Exit desktop, add a
  file to the directory, and restart. Verify the icon is at the left
  edge of the window.
]]
test.Variants(
  {
    {"Empty window in list view restored scroll position", desktop.VIEW_BY_NAME},
    {"Empty window in small icon view restored scroll position", desktop.VIEW_AS_SMALL_ICONS},
  },
  function(idx, name, item_id)
    desktop.OpenWindow("/RAM1")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, item_id)
    a2dtest.WaitForSystemTask()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.RUN_BASIC_HERE)
    apple2.WaitForBasicSystem()
    local filename = "MMMMMMMMMMMMMMM"
    apple2.TypeLine("CREATE " .. filename)
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
    desktop.Select(filename)

    local icon = desktop.GetSelectedIcons()[1]

    -- screen to window coords
    local HEADER_HEIGHT = 14
    local wx, wy = a2dtest.GetFrontWindowContentRect()
    local ix, iy = icon.x - wx, icon.y - wy - HEADER_HEIGHT

    local vx, vy = mgtk.GetScrollPos(mgtk.FrontWindow())

    test.ExpectLessThanOrEqual(ix, 8, "x position should be at left")
    test.ExpectLessThanOrEqual(iy, 4, "y position should be at top")

    -- cleanup
    desktop.EraseVolume("RAM1")
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
    desktop.OpenWindow("/A2.DESKTOP/EXTRAS")
    a2dtest.WaitForSystemTask()
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be inactive")

    apple2.DownArrowKey() -- select first
    a2dtest.WaitForSystemTask()

    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    a2d.Drag(icon_x, icon_y, x + w - 10, icon_y)
    a2dtest.WaitForSystemTask()
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
    desktop.OpenWindow("/RAM1")
    desktop.MoveWindowBy(0, 90)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    desktop.OpenWindow("/A2.DESKTOP", {keep_windows=true})
    desktop.GrowWindowBy(0, -40)
    desktop.Select("READ.ME")
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(icon_x, icon_y, dst_x, dst_y)
    a2dtest.WaitForSystemTask()

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "window should be activated")
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "h scrollbar should be inactive")
    test.ExpectEquals(vscroll & mgtk.scroll.option_active, 0, "v scrollbar should be inactive")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a window containing folders and files, with no
  scrollbars active. Open another window. Drag an icon from the first
  to the second. Ensure no scrollbars activate in the source window.
]]
test.Step(
  "Moving file doesn't activate source window scrollbars",
  function()
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    desktop.CreateFolder("/RAM1/FOLDER")

    desktop.OpenWindow("/RAM1")
    desktop.MoveWindowBy(0, 90)

    desktop.SelectAndOpen("FOLDER", {leave_parent=true})
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    desktop.CycleWindows()

    desktop.Select("READ.ME")
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(icon_x, icon_y, dst_x, dst_y)
    a2dtest.WaitForSystemTask()

    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "FOLDER", "window should be activated")
    desktop.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "window should be activated")
    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "h scrollbar should be inactive")
    test.ExpectEquals(vscroll & mgtk.scroll.option_active, 0, "v scrollbar should be inactive")

    -- cleanup
    desktop.EraseVolume("RAM1")
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
    desktop.CloseAllWindows()
    a2d.OAShortcut("1") -- Open /TESTS/HUNDRED.FILES
    a2dtest.WaitForSystemTask()
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        test.Snap("note icon positions")
        for i = 1, 2 do
          -- Down by one tick
          m.MoveToApproximately(x + w + 10, y + h - 5)
          m.Click()
          a2dtest.WaitForSystemTask()
          test.Snap("icons should still be aligned")
        end
        for i = 1, 2 do
          -- Up by one tick
          m.MoveToApproximately(x + w + 10, y + 5)
          m.Click()
          a2dtest.WaitForSystemTask()
          test.Snap("icons should still be aligned")
        end
        for i = 1, 2 do
          -- Down by one page
          m.MoveToApproximately(x + w + 10, y + h - 20)
          m.Click()
          a2dtest.WaitForSystemTask()
          test.Snap("icons should still be aligned")
        end
        for i = 1, 2 do
          -- Up by one page
          m.MoveToApproximately(x + w + 10, y + 20)
          m.Click()
          a2dtest.WaitForSystemTask()
          test.Snap("icons should still be aligned")
        end
        m.Home()
        -- to bottom
        m.MoveToApproximately(x + w + 10, y + h - 5)
        for i = 1, 20 do
          m.Click()
          a2dtest.WaitForSystemTask()
        end
        test.Snap("icons should still be aligned")
        -- to top
        m.MoveToApproximately(x + w + 10, y + 5)
        for i = 1, 20 do
          m.Click()
          a2dtest.WaitForSystemTask()
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
    desktop.OpenWindow("/TESTS")
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
    desktop.OpenWindow("/RAM1")
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
