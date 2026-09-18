--[[ BEGINCONFIG ========================================

MODEL="apple2ep"
MODELARGS="-sl1 ramfactor -sl2 mouse -sl5 ramfactor -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

--[[
  Open a window. Position two icons so one overlaps another. Select
  both. Drag both to a new location. Verify that the icons are
  repainted in the new location, and erased from the old location.
]]
test.Step(
  "overlapping icons - both dragged",
  function()
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    desktop.SelectPath("/RAM1/READ.ME")
    desktop.DuplicateSelection("DUPE")
    desktop.OpenWindow("/RAM1")
    desktop.Select("READ.ME")
    local x1, y1 = a2dtest.GetSelectedIconCoords()
    desktop.Select("DUPE")
    local x2, y2 = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x2, y2, x1, y1)
    desktop.SelectAll()
    test.Snap("note previous location")
    a2d.Drag(x1, y1, x2, y2)
    a2dtest.WaitForSystemTask()
    test.Snap("verify both icons moved")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Open a window. Position two icons so one overlaps another. Select
  only one icon. Drag it to a new location. Verify that the the both
  icons repaint correctly.
]]
test.Step(
  "overlapping icons - one dragged",
  function()
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    desktop.SelectPath("/RAM1/READ.ME")
    desktop.DuplicateSelection("DUPE")
    desktop.OpenWindow("/RAM1")
    desktop.Select("READ.ME")
    local x1, y1 = a2dtest.GetSelectedIconCoords()
    desktop.Select("DUPE")
    local x2, y2 = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x2, y2, x1, y1)
    desktop.Select("DUPE")
    test.Snap("note previous location")
    a2d.Drag(x1, y1, x2, y2)
    a2dtest.WaitForSystemTask()
    test.Snap("verify one icon moved, both repaint correctly")

    -- cleanup
    desktop.EraseVolume("RAM1")
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
    desktop.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(dst_x, dst_y, apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/2)
    a2dtest.WaitForSystemTask()
    a2d.InMouseKeysMode(function(m)
        m.Home()
    end)

    desktop.OpenSelection()

    desktop.MoveWindowBy(90, 10)
    desktop.ClearSelection()
    test.Snap("verify correct repaint")
    desktop.SelectPath("/RAM1", {keep_windows=true})
    test.Snap("verify correct repaint")

    desktop.MoveWindowBy(100, 0)
    desktop.ClearSelection()
    test.Snap("verify correct repaint")
    desktop.SelectPath("/RAM1", {keep_windows=true})
    test.Snap("verify correct repaint")

    desktop.MoveWindowBy(100, 0)
    desktop.ClearSelection()
    test.Snap("verify correct repaint")
    desktop.SelectPath("/RAM1", {keep_windows=true})
    test.Snap("verify correct repaint")

    desktop.MoveWindowBy(0, 35)
    desktop.ClearSelection()
    test.Snap("verify correct repaint")
    desktop.SelectPath("/RAM1", {keep_windows=true})
    test.Snap("verify correct repaint")

    desktop.MoveWindowBy(0, 35)
    desktop.ClearSelection()
    test.Snap("verify correct repaint")
    desktop.SelectPath("/RAM1", {keep_windows=true})
    test.Snap("verify correct repaint")

    desktop.MoveWindowBy(-100, 0)
    desktop.ClearSelection()
    test.Snap("verify correct repaint")
    desktop.SelectPath("/RAM1", {keep_windows=true})
    test.Snap("verify correct repaint")

    desktop.MoveWindowBy(-100, 0)
    desktop.ClearSelection()
    test.Snap("verify correct repaint")
    desktop.SelectPath("/RAM1", {keep_windows=true})
    test.Snap("verify correct repaint")

    desktop.MoveWindowBy(0, -35)
    desktop.ClearSelection()
    test.Snap("verify correct repaint")
    desktop.SelectPath("/RAM1", {keep_windows=true})
    test.Snap("verify correct repaint")

    -- cleanup
    desktop.CheckAllDrives()
end)

--[[
  Position a window partially overlapping desktop icons. Select
  overlapped desktop icons. Drag icons a few pixels to the right.
  Verify that window is not over-drawn.

  Position a window so that the right edge overlaps volume icons.
  Select the volume icons. Clear selection by clicking on the desktop.
  Verify that the right edge of the window is not overdrawn.
]]
test.Step(
  "desktop icons vs. windows",
  function()
    desktop.SelectPath("/A2.DESKTOP")
    local x, y = a2dtest.GetSelectedIconCoords()
    desktop.OpenWindow("/RAM1")
    desktop.MoveWindowBy(300, 0)
    desktop.ClearSelectionAndFocusDesktop()
    desktop.SelectAll()
    test.Snap("verify icons clipped by window")
    a2d.Drag(x, y, x+10, y)
    test.Snap("verify icons clipped by window")

    a2d.Drag(x+10, y, x, y)
    desktop.ClearSelection()
    test.Snap("verify icons clipped by window")
end)

--[[
  Repeat the following cases with these modifiers: Open-Apple, Shift
  (on a IIgs), Shift (on a Platinum IIe):

  * Launch DeskTop. Open a volume window with many icons. Click on a file icon to select it. Modifier-click the icon to deselect it. Drag-select on the desktop covering a large area. Verify that no file icons are erroneously painted.
  * Launch DeskTop. Open a volume window with many icons. Modifier-click on a file icon to select it. Drag-select on the desktop covering a large area. Verify that no file icons are erroneously painted.
]]
test.Variants(
  {
    {"modifier de-select - Open Apple", false, apple2.PressOA, apple2.ReleaseOA},
    {"modifier de-select - Shift (Platinum IIe)", false, apple2.PressShift, apple2.ReleaseShift},
    {"modifier select - Open Apple", true, apple2.PressOA, apple2.ReleaseOA},
    {"modifier select - Shift (Platinum IIe)", true, apple2.PressShift, apple2.ReleaseShift},
  },
  function(idx, name, do_select, press, release)
    desktop.SelectPath("/A2.DESKTOP/READ.ME")
    local x, y = a2dtest.GetSelectedIconCoords()

    if do_select then
      desktop.ClearSelection()
    end

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)

        press()
        m.Click()
        release()
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
    desktop.OpenWindow("/A2.DESKTOP")
    desktop.MoveWindowBy(40, 30)

    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w / 2, y + 5)
        m.Click()
    end)

    a2d.Drag(x - 20, y - 30,
             x + w + 40, y + h + 20)
    a2d.InMouseKeysMode(function(m) m.Home() end)

    test.Snap("verify no mispaint")
    test.ExpectEquals(#desktop.GetSelectedIcons(), 0, "nothing should be selected")
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
    desktop.SelectPath("/A2.DESKTOP/READ.ME")
    desktop.MoveWindowBy(40, 30)

    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.Drag(x - 20, y - 30,
             x + w + 40, y + h + 20)
    a2d.InMouseKeysMode(function(m) m.Home() end)

    test.Snap("verify no mispaint")
    test.ExpectEquals(#desktop.GetSelectedIcons(), 0, "nothing should be selected")
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
    desktop.OpenWindow("/A2.DESKTOP")
    desktop.GrowWindowBy(-50, -50)
    desktop.MoveWindowBy(40, 30)

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

    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.Drag(x - 20, y - 30,
             x + w + 40, y + h + 20)
    a2d.InMouseKeysMode(function(m) m.Home() end)
    test.Snap("verify no mispaint")
    test.ExpectEquals(#desktop.GetSelectedIcons(), 0, "nothing should be selected")
end)

--[[
  Launch DeskTop. Open two windows. Select a file in one window.
  Activate the other window and move it so that it partially obscures
  the selected file (e.g. with the title bar). File > Rename. Enter a
  new name. Verify that the active window is not mis-painted.
]]
test.Step(
  "rename in inactive window",
  function()
    desktop.OpenWindow("/A2.DESKTOP")

    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.CreateFolder("FOLDER")
    local x, y = a2dtest.GetSelectedIconCoords()

    desktop.CycleWindows()
    local drag_x, drag_y = a2dtest.GetFrontWindowDragCoords()
    a2d.Drag(drag_x, drag_y, x, y+5)

    desktop.RenameSelection("NEW.NAME")
    test.Snap("verify no mispaint")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open 3 windows. Close the top one. Verify that the
  repaint is correct.
]]
test.Step(
  "closing top window repaints correctly",
  function()
    desktop.OpenWindow("/A2.DESKTOP/APPLE.MENU/TOYS", {leave_parent=true})
    desktop.CloseWindow()
    a2dtest.WaitForSystemTask()
    test.Snap("verify no mispaint")
end)

--[[
  Launch DeskTop. Close all windows. Press an arrow key multiple
  times. Verify that only one volume icon is highlighted at a time.
]]
test.Step(
  "arrow key doesn't select multiple volumes",
  function()
    desktop.CloseAllWindows()
    a2dtest.WaitForSystemTask()
    desktop.ClearSelection()
    for i = 1, 4 do
      apple2.DownArrowKey()
      a2dtest.WaitForSystemTask()
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
      a2dtest.WaitForSystemTask()

      local x, y = a2dtest.GetFrontWindowDragCoords()
      a2d.Drag(x, y, apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT)
      a2dtest.WaitForSystemTask()

      mid_func()
      a2dtest.WaitForSystemTask()

      if post_func then
        local x2, y2 = a2dtest.GetFrontWindowDragCoords()
        a2d.Drag(x2, y2, x, y)
        a2dtest.WaitForSystemTask()

        post_func()
        a2dtest.WaitForSystemTask()
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
    desktop.OpenWindow("/A2.DESKTOP")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
  end,
  function()
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_AS_ICONS)
    a2dtest.WaitForSystemTask()
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
    desktop.OpenWindow("/A2.DESKTOP")
  end,
  function()
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
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
    desktop.OpenWindow("/A2.DESKTOP")
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
    desktop.OpenWindow("/A2.DESKTOP")
  end,
  function()
    desktop.SelectAll()
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
    desktop.OpenWindow("/A2.DESKTOP")
    desktop.SelectAll()
  end,
  function()
    desktop.ClearSelection()
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
    desktop.OpenWindow("/A2.DESKTOP/EXTRAS", {leave_parent=true})
    desktop.MoveWindowBy(0, 100)
    a2dtest.WaitForSystemTask()
    test.Snap("verify EXTRAS is dimmed")
    desktop.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "window should be active")
  end,
  function()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "window should be active")
    desktop.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "window should be active")
    desktop.CloseWindow()
    a2dtest.WaitForSystemTask()
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
    desktop.SelectPath("/A2.DESKTOP/EXTRAS")
  end,
  function()
    desktop.OpenSelection()
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
    desktop.SelectPath("/TESTS/TOO.MANY.FILES")
  end,
  function()
    desktop.OpenSelection()
    a2dtest.WaitForAlert({match="window must be closed"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
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
    desktop.OpenWindow("/RAM1")
  end,
  function()
    desktop.CreateFolder("NEW.NAME")
    a2dtest.WaitForSystemTask()
    test.Snap("verify folder icon doesn't mispaint on desktop")
  end,
  function()
    -- cleanup
    desktop.EraseVolume("RAM1")
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
    desktop.OpenWindow("/A2.DESKTOP")
  end,
  function()
    desktop.Quit()
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
    desktop.OpenWindow("/A2.DESKTOP")
    desktop.OpenWindow("/TESTS", {keep_windows=true})
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
    desktop.OpenWindow("/A2.DESKTOP")
    desktop.OpenWindow("/TESTS", {keep_windows=true})
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
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
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    desktop.SelectPath("/RAM1/READ.ME")
  end,
  function()
    desktop.RenameSelection("NEW.NAME")
    test.Snap("verify file icon doesn't mispaint on desktop")
  end,
  function()
    -- cleanup
    desktop.EraseVolume("RAM1")
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
    desktop.OpenWindow("/RAM1")
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.Drag(x, y, apple2.SCREEN_WIDTH/2, 0)
    a2dtest.WaitForSystemTask()
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
    desktop.OpenWindow("/RAM1")
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.Drag(x, y, apple2.SCREEN_WIDTH*1/3, 0)
    a2dtest.WaitForSystemTask()

    desktop.OpenWindow("/RAM5", {keep_windows=true})
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.Drag(x, y, apple2.SCREEN_WIDTH*2/3, 0)
    a2dtest.WaitForSystemTask()

    desktop.CycleWindows()
    desktop.CycleWindows()
    desktop.CycleWindows()

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
    desktop.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x, y+5, apple2.SCREEN_WIDTH/2, 15)
    a2dtest.WaitForSystemTask()

    test.Snap("verify that icon doesn't paint on top of menu bar")

    desktop.SelectAll()

    test.Snap("verify that icon doesn't paint on top of menu bar")

    -- cleanup
    desktop.CheckAllDrives()
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
    desktop.OpenWindow("/RAM1")
    for i = 1, 7 do
      desktop.CreateFolder("F" .. i)
    end
    desktop.CloseWindow()
    desktop.OpenWindow("/RAM1")
    desktop.SelectAll()
    desktop.OpenSelection({no_wait=true})
    a2dtest.MultiSnap(360, "verify no mispainted icons")

    -- cleanup
    desktop.CloseAllWindows()
    a2dtest.WaitForSystemTask()
    desktop.EraseVolume("RAM1")
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
    desktop.SelectPath("/RAM1")
    local vol_x, vol_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/A2.DESKTOP")
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
    a2dtest.WaitForSystemTask()

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
    desktop.SelectPath("/RAM1")
    local vol_x, vol_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/A2.DESKTOP")
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
    a2dtest.WaitForSystemTask()

    desktop.RenameSelection("NEW.NAME")
    a2dtest.WaitForSystemTask()
    a2dtest.ExpectAlertNotShowing()

    -- cleanup
    desktop.RenamePath("/NEW.NAME", "RAM1")
end)

--[[
  Launch DeskTop. Open a volume window containing a folder. Open the
  folder. Verify that the folder appears as dimmed. Position the
  window partially over the dimmed folder. Move the window to reveal
  the whole folder. Verify that the folder is repainted cleanly (no
  visual glitches).
]]
test.Step(
  "dimmed folder partial repaint",
  function()
    desktop.CreateFolder("/RAM1/FOLDER")
    desktop.OpenWindow("/RAM1/FOLDER", {leave_parent=true})
    desktop.ClearSelection()
    desktop.MoveWindowBy(15, 30)
    desktop.MoveWindowBy(50, 50)
    test.Snap("verify dimmed folder pattern painted perfectly")

    desktop.OpenWindow("/RAM1")
    desktop.MoveWindowBy(10, 10)
    desktop.Select("FOLDER")
    desktop.OpenSelection()
    desktop.ClearSelection()
    desktop.MoveWindowBy(25, 45)
    desktop.MoveWindowBy(50, 50)
    test.Snap("verify dimmed folder pattern painted perfectly")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a volume window containing two folders (1 and
  2). Open both folder windows, and verify that both folder icons are
  dimmed. Position folder 1's window partially covering folder 1's and
  folder 2's icons. Activate folder 1's window, and close it. Verify
  that the visible portions of folder 1 repaint (not dimmed) and
  folder 2 repaint (dimmed).
]]
test.Step(
  "folder repaint dimmed and not dimmed",
  function()
    desktop.CreateFolder("/RAM1/F1")
    desktop.CreateFolder("/RAM1/F2")
    desktop.OpenWindow("/RAM1")
    desktop.SelectAll()
    desktop.OpenSelection()
    desktop.MoveWindowBy(200, 100)
    while a2dtest.GetFrontWindowTitle():upper() ~= "F1" do
      desktop.CycleWindows()
      a2dtest.WaitForSystemTask()
    end
    desktop.MoveWindowBy(0, 30)
    test.Snap("verify window F1 overlaps both folder icons")
    desktop.CloseWindow()
    test.Snap("verify icons repaint correctly (F1 not dimmed, F2 dimmed)")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

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
    desktop.InvokePath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    apple2.Type("N") -- Normal Speed
    desktop.CloseWindow()

    desktop.CreateFolder("/RAM1/MMMMMMMMMMMMMMM")
    desktop.OpenWindow("/RAM1")
    desktop.MoveWindowBy(0, 80)
    desktop.Select("MMMMMMMMMMMMMMM")
    local x, y = a2dtest.GetSelectedIconCoords()
    desktop.ClearSelection()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.DoubleClick()
        a2dtest.MultiSnap(30, "verify dimming doesn't extend past icon bounding box")
    end)
    a2dtest.WaitForSystemTask()

    -- cleanup
    -- Enable ZIP Chip
    desktop.InvokePath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    apple2.Type("F") -- Fast Speed
    desktop.CloseWindow()

    desktop.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Apple Menu > Control Panels. Close the window by
  clicking on the close box. Verify nothing mis-paints.
]]
test.Step(
  "no mispaints when closing window opened from menu",
  function()
    desktop.CloseAllWindows()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.CONTROL_PANELS)
    a2dtest.WaitForSystemTask()
    local x, y = a2dtest.GetFrontWindowCloseBoxCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
    end)
    a2dtest.WaitForSystemTask()
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
test.Step(
  "header partial repaint doesn't glitch",
  function()
    desktop.CreateFolder("/RAM1/FOLDER")
    desktop.OpenWindow("/RAM1/FOLDER", {leave_parent=true})
    desktop.MoveWindowBy(0, 10)
    test.Snap("verify FOLDER partially covers RAM1's header")

    desktop.SelectPath("/TESTS/COPYING/SIZES/IS.200K", {keep_windows=true})
    desktop.MoveWindowBy(0, 60)
    desktop.CopySelectionTo("/RAM1/FOLDER")

    test.Snap("verify FOLDER header updated")
    desktop.MoveWindowBy(0, 50)
    a2dtest.WaitForSystemTask()
    test.Snap("verify RAM1 header repainted with old values (and no glitches)")
    while a2dtest.GetFrontWindowTitle():upper() ~= "RAM1" do
      desktop.CycleWindows()
      a2dtest.WaitForSystemTask()
    end
    test.Snap("verify RAM1 header repainted with new values")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a volume window with icons. Move window so only
  header is visible. Verify that DeskTop doesn't render garbage or
  lock up.
]]
test.Step(
  "header painting and content obscured",
  function()
    desktop.OpenWindow("/A2.DESKTOP")
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        m.MoveToApproximately(200, apple2.SCREEN_HEIGHT - 20)
        m.ButtonUp()
    end)
    a2dtest.WaitForSystemTask()
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
    desktop.OpenWindow("/A2.DESKTOP")
    desktop.OpenWindow("/TESTS", {keep_windows=true})
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        m.MoveToApproximately(200, apple2.SCREEN_HEIGHT - 20)
        m.ButtonUp()
    end)
    a2dtest.WaitForSystemTask()
    desktop.CycleWindows()
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
    desktop.SelectPath("/RAM5")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(dst_x, dst_y, apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/3)
    a2dtest.WaitForSystemTask()
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForSystemTask()
    test.Snap("verify icon in middle of screen repainted")

    -- cleanup
    desktop.EraseVolume("RAM1")
    desktop.CheckAllDrives()
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
    desktop.SelectPath("/RAM5")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x, y, apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/3)
    a2dtest.WaitForSystemTask()

    desktop.OpenSelection()
    desktop.MoveWindowBy(0, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForSystemTask()
    test.Snap("verify icon in middle of screen repainted")

    -- cleanup
    desktop.EraseVolume("RAM1")
    desktop.CheckAllDrives()
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
    desktop.SelectPath("/RAM5")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x, y, apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/3)
    a2dtest.WaitForSystemTask()

    desktop.OpenSelection()
    desktop.MoveWindowBy(0, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForSystemTask()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert({match="folder cannot be replaced"})
    a2d.DialogCancel()
    a2dtest.WaitForSystemTask()

    test.Snap("verify icon in middle of screen repainted")

    -- cleanup
    desktop.EraseVolume("RAM1")
    desktop.CheckAllDrives()
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
    desktop.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x, y, apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/3)
    a2dtest.WaitForSystemTask()
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/A2.DESKTOP", {keep_windows=true})
    desktop.MoveWindowBy(0, 100)
    desktop.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForSystemTask()
    test.Snap("verify icon in middle of screen repainted")

    -- cleanup
    desktop.EraseVolume("RAM1")
    desktop.CheckAllDrives()
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
    desktop.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x, y, apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/3)
    a2dtest.WaitForSystemTask()
    desktop.OpenSelection()
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    desktop.OpenWindow("/A2.DESKTOP", {keep_windows=true})
    desktop.MoveWindowBy(0, 100)
    desktop.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForSystemTask()
    test.Snap("verify icon in middle of screen repainted")

    -- cleanup
    desktop.EraseVolume("RAM1")
    desktop.CheckAllDrives()
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
    desktop.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x, y, apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/3)
    a2dtest.WaitForSystemTask()
    desktop.OpenSelection()
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    desktop.OpenWindow("/A2.DESKTOP", {keep_windows=true})
    desktop.MoveWindowBy(0, 100)
    desktop.Select("READ.ME")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForSystemTask()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert({match="file already exists"})
    a2d.DialogCancel()

    test.Snap("verify icon in middle of screen repainted")

    -- cleanup
    desktop.EraseVolume("RAM1")
    desktop.CheckAllDrives()
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
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    desktop.SelectPath("/Trash")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x, y, apple2.SCREEN_WIDTH/2, apple2.SCREEN_HEIGHT/3)
    a2dtest.WaitForSystemTask()
    desktop.SelectPath("/RAM1/READ.ME")
    desktop.MoveWindowBy(0, 80)
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    test.Snap("verify icon in middle of screen repainted")

    -- cleanup
    desktop.EraseVolume("RAM1")
    desktop.CheckAllDrives()
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
test.Step(
  "overlapping icon repaint order is persistent",
  function()
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    desktop.DuplicatePath("/RAM1/READ.ME", "BBBBBBBBBBBBBBB")
    desktop.RenamePath("/RAM1/READ.ME", "AAAAAAAAAAAAAAA")

    desktop.OpenWindow("/RAM1")

    desktop.Select("AAAAAAAAAAAAAAA")
    local x1, y1 = a2dtest.GetSelectedIconCoords()
    desktop.Select("BBBBBBBBBBBBBBB")
    local x2, y2 = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x2, y2, x1+10, y1+5)

    -- Start with first icon selected
    desktop.Select("AAAAAAAAAAAAAAA")
    local x, y = a2dtest.GetSelectedIconCoords()
    test.Snap("verify AAAAAAAAAAAAAAA is on top")

    -- Just open/close rather than activating/dragging over/dragging off
    desktop.OpenWindow("/RAM5", {keep_windows=true})
    desktop.CloseWindow()
    test.Snap("verify AAAAAAAAAAAAAAA is on top")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.OAClick()
    end)
    test.Snap("verify AAAAAAAAAAAAAAA is on top")

    desktop.OpenWindow("/RAM5", {keep_windows=true})
    desktop.CloseWindow()
    test.Snap("verify AAAAAAAAAAAAAAA is on top")

    -- Now with second icon selected
    desktop.Select("BBBBBBBBBBBBBBB")
    local x, y = a2dtest.GetSelectedIconCoords()
    test.Snap("verify BBBBBBBBBBBBBBB is on top")

    -- Just open/close rather than activating/dragging over/dragging off
    desktop.OpenWindow("/RAM5", {keep_windows=true})
    desktop.CloseWindow()
    test.Snap("verify BBBBBBBBBBBBBBB is on top")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.OAClick()
    end)
    test.Snap("verify BBBBBBBBBBBBBBB is on top")

    desktop.OpenWindow("/RAM5", {keep_windows=true})
    desktop.CloseWindow()
    test.Snap("verify BBBBBBBBBBBBBBB is on top")

    -- cleanup
    desktop.EraseVolume("RAM1")
end)


--[[
  Launch DeskTop. Open a volume. Open a folder within the volume.
  Activate the first window. Special > Check All Drives. Verify that
  the icons are erased and repaint properly.
]]
test.Step(
  "Check All Drives and icon repaint",
  function()
    desktop.OpenWindow("/A2.DESKTOP/EXTRAS", {leave_parent=true})
    desktop.CycleWindows()
    desktop.CheckAllDrives()
    a2dtest.ExpectNotHanging()
    test.Snap("verify correct repaint")
end)

--[[
  Launch DeskTop. Open a volume. Drag the window so that it partially
  covers some volume icons. Drag the window to the bottom of the
  screen so that only the top of the title bar is visible. Verify that
  the volume icons repaint correctly.
]]
test.Step(
  "volume icon repaint after obscured window",
  function()
    desktop.OpenWindow("/RAM1")
    desktop.MoveWindowBy(330, 0)
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        m.MoveToApproximately(200, apple2.SCREEN_HEIGHT)
        m.ButtonUp()
    end)
    a2dtest.WaitForSystemTask()
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
    desktop.SelectPath("/A2.DESKTOP/READ.ME")
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        m.MoveToApproximately(200, apple2.SCREEN_HEIGHT)
        m.ButtonUp()
    end)
    a2dtest.WaitForSystemTask()
    test.Snap("verify no file icons mispaint onto desktop")
end)

--[[
  Open a window. View > By Name. Scroll down so some icons are hidden
  behind the header. Open another window. Move it so it overlaps only
  the header of the first window. Close the window. Verify no crash.
]]
test.Step(
  "degenerate entry update rect",
  function()
    desktop.OpenWindow("/A2.DESKTOP")
    desktop.MoveWindowBy(0, 55)
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
    for i = 1, 20 do
      apple2.DownArrowKey()
      a2dtest.WaitForSystemTask()
    end
    desktop.OpenWindow("/RAM1", {keep_windows=true})
    desktop.CloseWindow()
    a2dtest.WaitForSystemTask()

    a2dtest.ExpectNotHanging()
end)
