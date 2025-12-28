--[[ BEGINCONFIG ========================================

MODEL="apple2ep"
MODELARGS="-sl1 ramfactor -sl2 mouse -sl5 ramfactor -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Open a window. Position two icons so one overlaps another. Select
  both. Drag both to a new location. Verify that the icons are
  repainted in the new location, and erased from the old location.
]]
test.Step(
  "overlapping icons - both dragged",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.SelectPath("/RAM1/READ.ME")
    a2d.DuplicateSelection("DUPE")
    a2d.OpenPath("/RAM1")
    a2d.Select("READ.ME")
    local x1, y1 = a2dtest.GetSelectedIconCoords()
    a2d.Select("DUPE")
    local x2, y2 = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x2, y2, x1, y1)
    a2d.SelectAll()
    test.Snap("note previous location")
    a2d.Drag(x1, y1, x2, y2)
    a2d.WaitForRepaint()
    test.Snap("verify both icons moved")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Open a window. Position two icons so one overlaps another. Select
  only one icon. Drag it to a new location. Verify that the the both
  icons repaint correctly.
]]
test.Step(
  "overlapping icons - one dragged",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.SelectPath("/RAM1/READ.ME")
    a2d.DuplicateSelection("DUPE")
    a2d.OpenPath("/RAM1")
    a2d.Select("READ.ME")
    local x1, y1 = a2dtest.GetSelectedIconCoords()
    a2d.Select("DUPE")
    local x2, y2 = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x2, y2, x1, y1)
    a2d.Select("DUPE")
    test.Snap("note previous location")
    a2d.Drag(x1, y1, x2, y2)
    a2d.WaitForRepaint()
    test.Snap("verify one icon moved, both repaint correctly")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Position a volume icon in the middle of the DeskTop. Incrementally
  move a window so that it obscures all 8 positions around it (top,
  top right, right, etc). Select and deselect the icon at each
  position. Ensure the icon repaints fully, and no part of the window
  is over-drawn.
]]
test.Step(
  "volume icon clipping",
  function()
    a2d.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(dst_x, dst_y, apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/2)
    a2d.WaitForRepaint()
    a2d.InMouseKeysMode(function(m)
        m.Home()
    end)

    a2d.OpenSelection()

    a2d.MoveWindowBy(90, 10)
    a2d.ClearSelection()
    test.Snap("verify correct repaint")
    a2d.SelectPath("/RAM1", {keep_windows=true})
    test.Snap("verify correct repaint")

    a2d.MoveWindowBy(100, 0)
    a2d.ClearSelection()
    test.Snap("verify correct repaint")
    a2d.SelectPath("/RAM1", {keep_windows=true})
    test.Snap("verify correct repaint")

    a2d.MoveWindowBy(100, 0)
    a2d.ClearSelection()
    test.Snap("verify correct repaint")
    a2d.SelectPath("/RAM1", {keep_windows=true})
    test.Snap("verify correct repaint")

    a2d.MoveWindowBy(0, 35)
    a2d.ClearSelection()
    test.Snap("verify correct repaint")
    a2d.SelectPath("/RAM1", {keep_windows=true})
    test.Snap("verify correct repaint")

    a2d.MoveWindowBy(0, 35)
    a2d.ClearSelection()
    test.Snap("verify correct repaint")
    a2d.SelectPath("/RAM1", {keep_windows=true})
    test.Snap("verify correct repaint")

    a2d.MoveWindowBy(-100, 0)
    a2d.ClearSelection()
    test.Snap("verify correct repaint")
    a2d.SelectPath("/RAM1", {keep_windows=true})
    test.Snap("verify correct repaint")

    a2d.MoveWindowBy(-100, 0)
    a2d.ClearSelection()
    test.Snap("verify correct repaint")
    a2d.SelectPath("/RAM1", {keep_windows=true})
    test.Snap("verify correct repaint")

    a2d.MoveWindowBy(0, -35)
    a2d.ClearSelection()
    test.Snap("verify correct repaint")
    a2d.SelectPath("/RAM1", {keep_windows=true})
    test.Snap("verify correct repaint")

    -- cleanup
    a2d.CheckAllDrives()
end)

--[[
  Position a window partially overlapping desktop icons. Select
  overlapped desktop icons. Drag icons a few pixels to the right.
  Verify that window is not over-drawn.
]]
test.Step(
  "desktop icons vs. windows",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(300, 0)
    a2d.FocusDesktop()
    a2d.SelectAll()
    test.Snap("verify icons clipped by window")
    a2d.Drag(x, y, x+10, y)
    test.Snap("verify moved icons clipped by window")
end)

--[[
  Position two windows so that the right edges are exactly aligned,
  and the windows vertically overlap by several pixels. Activate the
  upper window. Drag a floppy disk volume icon so that it is partially
  occluded by the bottom-right of the upper window. Verify that the
  visible parts of the icon repaint correctly and that DeskTop does
  not hang.
]]
--[[
  Position two windows so that the left edges are exactly aligned, and
  the windows vertically overlap by several pixels. Activate the upper
  window. Drag a floppy disk volume icon so that it is partially
  occluded by the bottom-left corner of the upper window. Verify that
  the visible parts of the icon repaint correctly and that DeskTop
  does not hang.
]]
--[[
  Position two windows so that the bottom-right corner of one overlaps
  the top-left corner of the other by several pixels. Drag a
  floppy disk volume icon so that it should show on both sides of
  overlap. Verify that the visible parts of the icon repaint
  correctly.
]]
--[[
  Position a window so that the right edge overlaps volume icons.
  Select the volume icons. Clear selection by clicking on the desktop.
  Verify that the right edge of the window is not overdrawn.
]]
--[[
  Open five volume windows containing many files so that the windows
  have large initial sizes. Drag the top-most so that the right edge
  aligns with another window's right edge and overlaps a volume icon.
  Drag another window that was previously overlapping the same icon so
  that the right edge aligns with the other windows. Verify that the
  volume icons repaint correctly and that the system does not hang.
]]

--[[
  Repeat the following cases with these modifiers: Open-Apple, Shift
  (on a IIgs), Shift (on a Platinum IIe):

  * Launch DeskTop. Open a volume window with many icons. Click on a file icon to select it. Modifier-click the icon to deselect it. Drag-select on the desktop covering a large area. Verify that no file icons are erroneously painted.
  * Launch DeskTop. Open a volume window with many icons. Modifier-click on a file icon to select it. Drag-select on the desktop covering a large area. Verify that no file icons are erroneously painted.
]]
test.Variants(
  {
    "modifier de-select - Open Apple",
    "modifier de-select - Shift (Platinum IIe)",
    "modifier select - Open Apple",
    "modifier select - Shift (Platinum IIe)",
  },
  function(idx)
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    local x, y = a2dtest.GetSelectedIconCoords()

    if idx == 3 or idx == 4 then
      a2d.ClearSelection()
    end

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)

        if idx == 1 or idx == 3 then
          apple2.PressOA()
        elseif idx == 2 or idx == 4 then
          apple2.PressShift()
        end

        m.Click()

        if idx == 1 or idx == 3 then
          apple2.ReleaseOA()
        elseif idx == 2 or idx == 4 then
          apple2.ReleaseShift()
        end
    end)

    a2d.Drag(0, 60, 450, 190)
    test.Snap("verify no file icons repaint on desktop")
end)

--[[
  Launch DeskTop. Open a volume window. Click in the header area
  (items/use/etc). On the desktop, drag a selection rectangle around
  the window. Verify that nothing is selected, and that file icons
  don't paint onto the desktop.
]]
test.Step(
  "drag select on desktop doesn't select file icons - after header click",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.MoveWindowBy(40, 30)

    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w / 2, y + 5)
        m.Click()
    end)

    local rect = mgtk.GetWinFrameRect(mgtk.FrontWindow())
    a2d.Drag(rect[1] - 20, rect[2] - 10,
             rect[3] + 20, rect[4] + 10)
    a2d.InMouseKeysMode(function(m) m.Home() end)

    test.Snap("verify no mispaint")
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "nothing should be selected")
end)

--[[
  Launch DeskTop. Open a volume window. Select a file icon. On the
  desktop, drag a selection rectangle around the window. Verify that
  nothing is selected, and that nothing repaints incorrectly in
  window.
]]
test.Step(
  "drag select on desktop doesn't select file icons - with file icon selection",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.MoveWindowBy(40, 30)

    local rect = mgtk.GetWinFrameRect(mgtk.FrontWindow())
    a2d.Drag(rect[1] - 20, rect[2] - 10,
             rect[3] + 20, rect[4] + 10)
    a2d.InMouseKeysMode(function(m) m.Home() end)

    test.Snap("verify no mispaint")
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "nothing should be selected")
end)


--[[
  Launch DeskTop. Open a volume window. Adjust the window so that the
  scrollbars are active. Scroll the window. On the desktop, drag a
  selection rectangle around the window. Verify that nothing is
  selected, and that file icons don't paint onto the desktop.
]]
test.Step(
  "drag select on desktop doesn't select file icons - after scroll",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.GrowWindowBy(-50, -50)
    a2d.MoveWindowBy(40, 30)

    local x, y = a2dtest.GetFrontWindowRightScrollArrowCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
        m.Click()
        m.Click()
    end)

    local x, y = a2dtest.GetFrontWindowDownScrollArrowCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
        m.Click()
        m.Click()
    end)

    local rect = mgtk.GetWinFrameRect(mgtk.FrontWindow())
    a2d.Drag(rect[1] - 20, rect[2] - 10,
             rect[3] + 20, rect[4] + 10)
    a2d.InMouseKeysMode(function(m) m.Home() end)
    test.Snap("verify no mispaint")
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "nothing should be selected")
end)

--[[
  Launch DeskTop. Open two windows. Select a file in one window.
  Activate the other window and move it so that it partially obscures
  the selected file (e.g. with the title bar). File > Rename. Enter a
  new name. Verify that the active window is not mis-painted.
]]

--[[
  Launch DeskTop. Open 3 windows. Close the top one. Verify that the
  repaint is correct.
]]
test.Step(
  "closing top window repaints correctly",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/TOYS", {leave_parent=true})
    a2d.CloseWindow()
    emu.wait(5)
    test.Snap("verify no mispaint")
end)

--[[
  Launch DeskTop. Close all windows. Press an arrow key multiple
  times. Verify that only one volume icon is highlighted at a time.
]]
test.Step(
  "arrow key doesn't select multiple volumes",
  function()
    a2d.CloseAllWindows()
    emu.wait(5)
    a2d.ClearSelection()
    for i = 1, 4 do
      apple2.DownArrowKey()
      a2d.WaitForRepaint()
      test.Snap("verify only one volume selected")
    end
end)

--[[
  For the following cases, "obscure a window" means to move a window to the bottom of the screen so that only the title bar is visible:
]]
function ObscuredWindowTest(name, pre_func, mid_func, post_func)
  test.Step(
    "obscured window - " .. name,
    function()
      pre_func()
      a2d.WaitForRepaint()

      local x, y = a2dtest.GetFrontWindowDragCoords()
      a2d.Drag(x, y, apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT)
      a2d.WaitForRepaint()

      mid_func()
      a2d.WaitForRepaint()

      if post_func then
        local x2, y2 = a2dtest.GetFrontWindowDragCoords()
        a2d.Drag(x2, y2, x, y)
        a2d.WaitForRepaint()

        post_func()
        a2d.WaitForRepaint()
      end
  end)
end

--[[
  Launch DeskTop. Open a window with icons. View > by Name. Obscure
  the window. View > as Icons. Verify that the window contents don't
  appear on the desktop. Move the window so the contents are visible.
  Verify that it contains icons.
]]
ObscuredWindowTest(
  "View by name, then as icons",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
  end,
  function()
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_AS_ICONS)
    a2d.WaitForRepaint()
    test.Snap("verify file icons don't mispaint on desktop")
  end,
  function()
    test.Snap("verify window contains icons")
  end
)

--[[
  Launch DeskTop. Open a window with icons. Obscure the window. View >
  by Name. Verify that the window contents don't appear on the
  desktop. Move the window so the contents are visible. Verify that
  the contents display as a list.
]]
ObscuredWindowTest(
  "View by name while obscured",
  function()
    a2d.OpenPath("/A2.DESKTOP")
  end,
  function()
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.WaitForRepaint()
    test.Snap("verify contents don't mispaint on desktop")
  end,
  function()
    test.Snap("verify contents display as list")
  end
)

--[[
  Launch DeskTop. Open a window with at least two icons. Select the
  first icon. Obscure the window. Press the right arrow key. Verify
  that the icons don't appear on the desktop.
]]
ObscuredWindowTest(
  "Arrow navigation",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    apple2.RightArrowKey()
  end,
  function()
    apple2.RightArrowKey()
    test.Snap("verify icons don't mispaint on desktop")
  end
)

--[[
  Launch DeskTop. Open a window with icons. Obscure the window. Edit >
  Select All. Verify that the icons don't appear on the desktop.
]]
ObscuredWindowTest(
  "Select All",
  function()
    a2d.OpenPath("/A2.DESKTOP")
  end,
  function()
    a2d.SelectAll()
    test.Snap("verify icons don't mispaint on desktop")
  end
)

--[[
  Launch DeskTop. Open a window with icons. Edit > Select All. Obscure
  the window. Click on the desktop to clear selection. Verify that the
  icons don't appear on the desktop.
]]
ObscuredWindowTest(
  "Clearing selection",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.SelectAll()
  end,
  function()
    a2d.ClearSelection()
    test.Snap("verify icons don't mispaint on desktop")
  end
)

--[[
  Launch DeskTop. Open a window with folder icons. Open a second
  window from one of the folders. Verify that the folder icon in the
  first window is dimmed. Obscure the first window. Close the second
  window. Verify that the folder icon doesn't appear on the desktop.
]]
ObscuredWindowTest(
  "Un-dimming",
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", {leave_parent=true})
    a2d.MoveWindowBy(0, 100)
    emu.wait(5)
    test.Snap("verify EXTRAS is dimmed")
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "window should be active")
  end,
  function()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "window should be active")
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "window should be active")
    a2d.CloseWindow()
    emu.wait(5)
    test.Snap("verify EXTRAS icon doesn't mispaint on desktop")
  end
)

--[[
  Launch DeskTop. Open a window with icons. Select (but don't open) a
  folder. Obscure the window. File > Open. Verify that the folder icon
  does not appear on the desktop.
]]
ObscuredWindowTest(
  "dimming",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")
  end,
  function()
    a2d.OpenSelection()
    emu.wait(5)
    test.Snap("verify EXTRAS icon doesn't mispaint on desktop")
  end
)

--[[
  Launch DeskTop. Open `/TESTS`. Select (but don't open)
  `TOO.MANY.FILES`. Obscure the window. File > Open. Verify that the
  folder icon does not appear on the desktop.
]]
ObscuredWindowTest(
  "failed open",
  function()
    a2d.SelectPath("/TESTS/TOO.MANY.FILES")
  end,
  function()
    a2d.OpenSelection()
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    emu.wait(5)
    test.Snap("verify TOO.MANY.FILES icon doesn't mispaint on desktop")
  end
)

--[[
  Launch DeskTop. Open a window. Obscure the window. File > New
  Folder, enter a name. Verify that the folder icon doesn't appear on
  the desktop.
]]
ObscuredWindowTest(
  "new folder",
  function()
    a2d.OpenPath("/RAM1")
  end,
  function()
    a2d.CreateFolder("NEW.NAME")
    emu.wait(5)
    test.Snap("verify folder icon doesn't mispaint on desktop")
  end,
  function()
    -- cleanup
    a2d.EraseVolume("RAM1")
  end
)

--[[
  Launch DeskTop. Open a window with icons. Obscure the window. File >
  Quit. Relaunch DeskTop. Verify that the restored window's icons
  don't appear on the desktop, and that the menu bar is not glitched.
]]
ObscuredWindowTest(
  "window restoration",
  function()
    a2d.OpenPath("/A2.DESKTOP")
  end,
  function()
    a2d.Quit()
    apple2.WaitForBitsy()
    apple2.BitsyInvokePath("/A2.DESKTOP/DESKTOP.SYSTEM")
    a2d.WaitForDesktopReady()
    test.Snap("verify file icons don't mispaint on desktop or menu")
  end
)

--[[
  Launch DeskTop. Open two windows with icons. Obscure one window.
  Click on the other window's title bar. Click on the obscured
  window's title bar. Verify that the window contents don't repaint on
  the desktop.
]]
ObscuredWindowTest(
  "activating window",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.OpenPath("/TESTS", {keep_windows=true})
  end,
  function()
    local id1 = mgtk.FrontWindow()
    local x1, y1 = a2dtest.GetWindowDragCoords(id1)

    local id2 = a2dtest.GetNextWindowID(id1)
    local x2, y2 = a2dtest.GetWindowDragCoords(id2)

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x2, y2)
        m.Click()
        m.MoveToApproximately(x1, y1)
        m.Click()
    end)
    test.Snap("verify window contents don't mispaint on desktop")
  end
)

--[[
  Launch DeskTop. Open two windows with icons. Activate a window, View
  > by Name, and then obscure the window. Click on the other window's
  title bar. Click on the obscured window's title bar. Verify that the
  window contents don't repaint on the desktop.
]]
ObscuredWindowTest(
  "activating window with list view",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.OpenPath("/TESTS", {keep_windows=true})
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
  end,
  function()
    local id1 = mgtk.FrontWindow()
    local x1, y1 = a2dtest.GetWindowDragCoords(id1)

    local id2 = a2dtest.GetNextWindowID(id1)
    local x2, y2 = a2dtest.GetWindowDragCoords(id2)

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x2, y2)
        m.Click()
        m.MoveToApproximately(x1, y1)
        m.Click()
    end)
    test.Snap("verify window contents don't mispaint on desktop")
  end
)

--[[
  Launch DeskTop. Open a window with icons. Select an icon. Obscure
  the window. File > Rename, enter a new name. Verify that the icon
  does not paint on the desktop.
]]
ObscuredWindowTest(
  "rename while obscured",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.SelectPath("/RAM1/READ.ME")
  end,
  function()
    a2d.RenameSelection("NEW.NAME")
    test.Snap("verify file icon doesn't mispaint on desktop")
  end,
  function()
    -- cleanup
    a2d.EraseVolume("RAM1")
  end
)

--[[
  Launch DeskTop. Open a window. Try to move the window so that the
  title bar intersects the menu bar. Verify that the window ends up
  positioned partially behind the menu bar.
]]
test.Step(
  "window clipped by menu bar",
  function()
    a2d.OpenPath("/RAM1")
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.Drag(x, y, apple2.SCREEN_WIDTH/2, 0)
    emu.wait(5)
    test.Snap("verify window title bars positioned behind menu bar")
end)

--[[
  Launch DeskTop. Open two windows. Move them both so their title bars
  are partially behind the menu bar. Apple+Tab between the windows.
  Verify that the title bars do not mispaint on top of the menu bar.
]]
test.Step(
  "windows clipped by menu bar",
  function()
    a2d.OpenPath("/RAM1")
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.Drag(x, y, apple2.SCREEN_WIDTH*1/3, 0)
    emu.wait(5)

    a2d.OpenPath("/RAM5", {keep_windows=true})
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.Drag(x, y, apple2.SCREEN_WIDTH*2/3, 0)
    emu.wait(5)

    a2d.CycleWindows()
    a2d.CycleWindows()
    a2d.CycleWindows()

    test.Snap("verify window title bars don't paint on top of menu bar")
end)

--[[
  Launch DeskTop. Drag a volume icon so that it overlaps the menu bar,
  but the mouse pointer is below the menu bar. Release the mouse
  button. Verify that the icon doesn't paint on top of the menu bar.
  Edit > Select All. Verify that the icon doesn't repaint on top of
  the menu bar.
]]
test.Step(
  "volume icon clipped by menu bar",
  function()
    a2d.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x, y+5, apple2.SCREEN_WIDTH/2, 15)
    emu.wait(5)

    test.Snap("verify that icon doesn't paint on top of menu bar")

    a2d.SelectAll()

    test.Snap("verify that icon doesn't paint on top of menu bar")

    -- cleanup
    a2d.CheckAllDrives()
end)

--[[
  Launch DeskTop. Open a window containing many folders. Select up to
  7 folders. File > Open. Verify that as windows continue to open, the
  originally selected folders don't mispaint on top of them. (This
  will be easier to observe in emulators with acceleration disabled.)
]]
test.Step(
  "selected folders are clipped as windows open",
  function()
    a2d.OpenPath("/RAM1")
    for i = 1, 7 do
      a2d.CreateFolder("F" .. i)
    end
    a2d.CloseWindow()
    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    a2d.OpenSelection({no_wait=true})
    a2dtest.MultiSnap(360, "verify no mispainted icons")

    -- cleanup
    a2d.CloseAllWindows()
    emu.wait(5)
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a window containing multiple icons. Drag-select
  several icons. Click on the desktop to clear selection. Click on a
  volume icon. Click elsewhere on the desktop. Verify the icon isn't
  mispainted.
]]
test.Step(
  "mispaints after drag selection and clearing selection",
  function()
    a2d.SelectPath("/RAM1")
    local vol_x, vol_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/A2.DESKTOP")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.Drag(x + 5, y + 15, x + w - 5, y + h - 5)
    a2d.InMouseKeysMode(function(m)
        -- click to clear selection
        m.MoveToApproximately(0, apple2.SCREEN_HEIGHT)
        m.Click()
        m.Home()

        -- click on volume icon
        m.MoveToApproximately(vol_x, vol_y)
        m.Click()

        -- click elsewhere
        m.MoveToApproximately(0, apple2.SCREEN_HEIGHT)
        m.Click()
    end)
    a2d.WaitForRepaint()

    test.Snap("verify no mispaint")
end)

--[[
  Launch DeskTop. Open a window containing multiple icons. Drag-select
  several icons. Click on the desktop to clear selection. Click on a
  volume icon. File > Rename. Enter a new valid name. Verify that no
  alert is shown.
]]
test.Step(
  "mispaints after drag selection, clearing selection, and rename",
  function()
    a2d.SelectPath("/RAM1")
    local vol_x, vol_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/A2.DESKTOP")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.Drag(x + 5, y + 15, x + w - 5, y + h - 5)
    a2d.InMouseKeysMode(function(m)
        -- click to clear selection
        m.MoveToApproximately(0, apple2.SCREEN_HEIGHT)
        m.Click()
        m.Home()

        -- click on volume icon
        m.MoveToApproximately(vol_x, vol_y)
        m.Click()
    end)
    a2d.WaitForRepaint()

    a2d.RenameSelection("NEW.NAME")
    emu.wait(5)
    a2dtest.ExpectAlertNotShowing()

    -- cleanup
    a2d.RenamePath("/NEW.NAME", "RAM1")
end)

--[[
  Launch DeskTop. Open a window. Create a folder with a short name
  (e.g. "A"). Open the folder. Drag the folder's window so it covers
  just the left edge of the icon. Drag it away. Verify that the folder
  repaints. Repeat for the right edge.
]]

--[[
  Launch DeskTop. Open a volume window containing a folder. Open the
  folder. Verify that the folder appears as dimmed. Position the
  window partially over the dimmed folder. Move the window to reveal
  the whole folder. Verify that the folder is repainted cleanly (no
  visual glitches).
]]
--[[
  Launch DeskTop. Open a volume window containing two folders (1 and
  2). Open both folder windows, and verify that both folder icons are
  dimmed. Position folder 1's window partially covering folder 1's and
  folder 2's icons. Activate folder 1's window, and close it. Verify
  that the visible portions of folder 1 repaint (not dimmed) and
  folder 2 repaint (dimmed).
]]

--[[
  Disable any acceleration. Launch DeskTop. Open a volume window
  containing a folder with a long name. Double-click the folder to
  open it. Verify that when the icon is painting as dimmed that the
  dimming effect doesn't extend past the bounding box of the icon,
  even temporarily.
]]
test.Step(
  "dimming effect",
  function()
    -- Disable ZIP Chip
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    apple2.Type("N") -- Normal Speed
    a2d.CloseWindow()

    a2d.CreateFolder("/RAM1/MMMMMMMMMMMMMMM")
    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(0, 80)
    a2d.Select("MMMMMMMMMMMMMMM")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.DoubleClick()
        a2dtest.MultiSnap(30, "verify dimming doesn't extend past icon bounding box")
    end)
    emu.wait(5)

    -- cleanup
    -- Enable ZIP Chip
    a2d.ConfigureRepaintTime(1)
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    a2d.ConfigureRepaintTime(0.25)
    apple2.Type("F") -- Fast Speed
    a2d.CloseWindow()

    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Apple Menu > Control Panels. Close the window by
  clicking on the close box. Verify nothing mis-paints.
]]
test.Step(
  "no mispaints when closing window opened from menu",
  function()
    a2d.CloseAllWindows()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    local x, y = a2dtest.GetFrontWindowCloseBoxCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify no garbage")
end)

--[[
  Launch DeskTop. Open a window containing a folder. Open the folder
  window. Position the folder window so that it partially covers the
  "in disk" and "available" entries in the lower window. Drag a large
  file into the folder window. Verify that the "in disk" and
  "available" values update in the folder window. Drag the folder
  window away. Verify that the parent window "in disk" and "available"
  values repaint with the old values, and without visual artifacts.
  Activate the parent window. Verify that the "in disk" and
  "available" values now update.
]]

--[[
  Launch DeskTop. Open a volume window with icons. Move window so only
  header is visible. Verify that DeskTop doesn't render garbage or
  lock up.
]]
test.Step(
  "header painting and content obscured",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        m.MoveToApproximately(200, apple2.SCREEN_HEIGHT - 20)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()
    a2dtest.ExpectNotHanging()
    test.Snap("verify no garbage")
end)

--[[
  Launch DeskTop. Open two volume windows with icons. Move top window
  down so only header is visible. Click on other window to activate
  it. Verify that the window header does not disappear.
]]
test.Step(
  "header painting and activation",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.OpenPath("/TESTS", {keep_windows=true})
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        m.MoveToApproximately(200, apple2.SCREEN_HEIGHT - 20)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()
    a2d.CycleWindows()
    test.Snap("verify window headers render correctly")
end)

--[[
  Launch DeskTop. Position a volume icon near the center of the
  screen. Drag another volume onto it. Verify that after the copy
  dialog closes, the volume icon is still visible.
]]
test.Step(
  "volume icon repaints after copy dialog closes - drop on volume icon",
  function()
    a2d.SelectPath("/RAM5")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(dst_x, dst_y, apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/3)
    a2d.WaitForRepaint()
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(5)
    test.Snap("verify icon in middle of screen repainted")

    -- cleanup
    a2d.EraseVolume("RAM1")
    a2d.CheckAllDrives()
end)

--[[
  Launch DeskTop. Position a volume icon near the center of the
  screen. Open the volume icon, and move/size the window to ensure the
  volume icon is visible. Drag another volume onto the window. Verify
  that after the copy dialog closes, the volume icon is still visible.
]]
test.Step(
  "volume icon repaints after copy dialog closes - drop on window",
  function()
    a2d.SelectPath("/RAM5")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x, y, apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/3)
    a2d.WaitForRepaint()

    a2d.OpenSelection()
    a2d.MoveWindowBy(0, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(5)
    test.Snap("verify icon in middle of screen repainted")

    -- cleanup
    a2d.EraseVolume("RAM1")
    a2d.CheckAllDrives()
end)

--[[
  Launch DeskTop. Position a volume icon near the center of the
  screen. Open the volume icon, and move/size the window to ensure the
  volume icon is visible. Drag another volume onto the window. Drag
  the same volume icon onto the window. Cancel the copy. Verify that
  after the copy dialog closes, the volume icon is still visible.
]]
test.Step(
  "volume icon repaints after copy dialog closes - drop on window canceled",
  function()
    a2d.SelectPath("/RAM5")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x, y, apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/3)
    a2d.WaitForRepaint()

    a2d.OpenSelection()
    a2d.MoveWindowBy(0, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(5)

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert()
    a2d.DialogCancel()
    emu.wait(5)

    test.Snap("verify icon in middle of screen repainted")

    -- cleanup
    a2d.EraseVolume("RAM1")
    a2d.CheckAllDrives()
end)

--[[
  Launch DeskTop. Position a volume icon near the center of the
  screen. Open a second volume icon, and move/size the window to
  ensure the first volume icon is visible. Drag a file icon onto the
  first volume icon. Verify that after the copy dialog closes, the
  volume icon is still visible.
]]
test.Step(
  "volume icon repaints after copy dialog closes - drag from window, drop on icon",
  function()
    a2d.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x, y, apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/3)
    a2d.WaitForRepaint()
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/A2.DESKTOP", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)
    a2d.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(5)
    test.Snap("verify icon in middle of screen repainted")

    -- cleanup
    a2d.EraseVolume("RAM1")
    a2d.CheckAllDrives()
end)

--[[
  Launch DeskTop. Position a volume icon near the center of the
  screen. Open the volume icon, and move/size the window to ensure the
  volume icon is visible. Open a second volume icon, and move/size the
  window to ensure the first volume icon is visible. Drag a file icon
  from the second window into the first window. Verify that after the
  copy dialog closes, the volume icon is still visible.
]]
test.Step(
  "volume icon repaints after copy dialog closes - drag from window to window",
  function()
    a2d.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x, y, apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/3)
    a2d.WaitForRepaint()
    a2d.OpenSelection()
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.OpenPath("/A2.DESKTOP", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)
    a2d.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(5)
    test.Snap("verify icon in middle of screen repainted")

    -- cleanup
    a2d.EraseVolume("RAM1")
    a2d.CheckAllDrives()
end)

--[[
  Launch DeskTop. Position a volume icon near the center of the
  screen. Open the volume icon, and move/size the window to ensure the
  volume icon is visible. Open a second volume icon, and move/size the
  window to ensure the first volume icon is visible. Drag a file icon
  from the second window into the first window. Repeat the drag, and
  cancel the copy dialog. Verify that after the copy dialog closes,
  the volume icon is still visible.
]]
test.Step(
  "volume icon repaints after copy dialog closes - drag from window to window canceled",
  function()
    a2d.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x, y, apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/3)
    a2d.WaitForRepaint()
    a2d.OpenSelection()
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.OpenPath("/A2.DESKTOP", {keep_windows=true})
    a2d.MoveWindowBy(0, 100)
    a2d.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(5)

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert()
    a2d.DialogCancel()

    test.Snap("verify icon in middle of screen repainted")

    -- cleanup
    a2d.EraseVolume("RAM1")
    a2d.CheckAllDrives()
end)

--[[
  Launch DeskTop. Position a volume icon near the center of the
  screen. Open the volume icon, and move/size the window to ensure the
  volume icon is visible. Drag a file icon to the trash. Verify that
  after the delete dialog closes, the volume icon is still visible.
]]
test.Step(
  "volume icon repaints after delete dialog closes",
  function()
    a2d.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    a2d.SelectPath("/Trash")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x, y, apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/3)
    a2d.WaitForRepaint()
    a2d.SelectPath("/RAM1/READ.ME")
    a2d.MoveWindowBy(0, 80)
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    emu.wait(5)

    test.Snap("verify icon in middle of screen repainted")

    -- cleanup
    a2d.EraseVolume("RAM1")
    a2d.CheckAllDrives()
end)

--[[
  Launch DeskTop. Open two windows. In the first window, position two
  icons so they overlap. Select the first icon. Verify that it draws
  "on top" of the other icon. Activate the other window without
  changing selection. Drag it over the icons. Drag it off the icons.
  Verify that the selected icon is still "on top". Hold Open-Apple and
  click the selected icon to deselect it. Verify that it draws "on
  top" of the other icon. Activate the other window without changing
  selection. Drag it over the icons. Drag it off the icons. Verify
  that the previously selected icon is still "on top". Repeat the
  above tests with the other icon.
]]

--[[
  Launch DeskTop. Open a volume. Open a folder within the volume.
  Activate the first window. Special > Check All Drives. Verify that
  the icons are erased and repaint properly.
]]
test.Step(
  "Check All Drives and icon repaint",
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", {leave_parent=true})
    a2d.CycleWindows()
    a2d.CheckAllDrives()
    a2dtest.ExpectNotHanging()
    test.Snap("verify correct repaint")
end)

--[[
  Launch DeskTop. Open a volume. Open a folder. Drag the folder window
  so that it obscures the top-most edge of an icon in the volume
  window. Drag the folder away. Verify that the icon in the volume
  window repaints.
]]

--[[
  Launch DeskTop. Open a volume. Drag the window so that it partially
  covers some volume icons. Drag the window to the bottom of the
  screen so that only the top of the title bar is visible. Verify that
  the volume icons repaint correctly.
]]
test.Step(
  "volume icon repaint after obscured window",
  function()
    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(330, 0)
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        m.MoveToApproximately(200, apple2.SCREEN_HEIGHT)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify volume icons repaint correctly")
end)

--[[
  Launch DeskTop. Open a volume containing a file icon. Select the
  file icon. Drag the window to the bottom of the screen so that only
  the top of the title bar is visible. Verify that the file icon
  doesn't mispaint onto the desktop.
]]
test.Step(
  "file icon repaint after obscured window",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        m.MoveToApproximately(200, apple2.SCREEN_HEIGHT)
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify no file icons mispaint onto desktop")
end)
