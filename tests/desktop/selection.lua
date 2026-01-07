--[[ BEGINCONFIG ========================================

MODEL="apple2ep"
MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

a2d.AddShortcut("/A2.DESKTOP")
function OpenVolumeWindow() a2d.OAShortcut("1") end

a2d.AddShortcut("/A2.DESKTOP/EXTRAS")
function OpenFolderWindow() a2d.OAShortcut("2") end

--[[
  Launch DeskTop. Open a window. Select a file icon. Drag a selection
  rectangle around another file icon in the same window. Verify that
  the initial selection is cleared and only the second icon is
  selected.
]]
test.Step(
  "selection rectangle around file icons",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.Select("READ.ME")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Select("PRODOS")

    a2d.Drag(x-30, y-5, x+30, y+20)
    a2d.WaitForRepaint()

    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "only new icon should be selected")
end)

--[[
  Launch DeskTop. Select a volume icon. Drag a selection rectangle
  around another volume icon. Verify that the initial selection is
  cleared and only the second icon is selected.
]]
test.Step(
  "selection rectangle around volume icons",
  function()
    a2d.CloseAllWindows()

    a2d.Select("RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Select("A2.DESKTOP")

    a2d.Drag(x-30, y-5, x+30, y+20)
    a2d.WaitForRepaint()

    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "RAM1", "only new icon should be selected")
end)

--[[
  Repeat the following cases with these modifiers: Open-Apple, Shift
  (on a IIgs), Shift (on a Platinum IIe):
]]
function ModifierTest(name, func)
  test.Variants(
    {
      {name .. " - Open Apple", apple2.PressOA, apple2.ReleaseOA},
      {name .. " - Shift", apple2.PressShift, apple2.ReleaseShift},
      -- TODO: Apple IIgs as well
    },
    function(idx, name, Press, Release)
      a2d.CloseAllWindows()
      a2d.ClearSelection()

      func(Press, Release)
  end)
end

--[[
  * Launch DeskTop. Click on a volume icon. Hold modifier and click a
    different volume icon. Verify that selection is extended.
]]
ModifierTest(
  "click second volume icon",
  function(Press, Release)
    a2d.Select("RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.SelectPath("/A2.DESKTOP")

    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "single icon selected")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        Press()
        m.Click()
        a2d.WaitForRepaint()
        Release()
        emu.wait(1)
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), 2, "selection should be extended")
end)

--[[
  * Launch DeskTop. Select two volume icons. Hold modifier and click
    on the desktop, not on an icon. Verify that selection is not
    cleared.
]]
ModifierTest(
  "with volume icons selected, modifier-click desktop",
  function(Press, Release)
    a2d.SelectAll()
    local count = #a2d.GetSelectedIcons()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(0, apple2.SCREEN_HEIGHT)
        Press()
        m.Click()
        a2d.WaitForRepaint()
        Release()
        emu.wait(1)
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not be cleared")
end)

--[[
  * Launch DeskTop. Select one or more volume icons. Hold modifier and
    click a selected volume icon. Verify that it is deselected.
]]
ModifierTest(
  "mod-click a selected volume icon",
  function(Press, Release)
    a2d.Select("A2.DESKTOP")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.SelectAll()

    local count = #a2d.GetSelectedIcons()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        Press()
        m.Click()
        a2d.WaitForRepaint()
        Release()
        emu.wait(1)
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), count-1, "clicked icon should be de-selected")
end)

--[[
  * Launch DeskTop. Hold modifier and double-click on a non-selected
    volume icon. Verify that it highlights then unhighlights, and does
    not open.
]]
ModifierTest(
  "mod-double-click a non-selected volume icon",
  function(Press, Release)
    a2d.Select("A2.DESKTOP")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        Press()
        m.Click()
        emu.wait(2/60)
        test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "selection should have toggled")
        m.Click()
        emu.wait(2/60)
        test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "selection should have toggled")
        Release()
        emu.wait(1)
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "selection should have toggled")
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "no windows should be open")
end)

--[[
  * Launch DeskTop. Select a volume icon. Wait a few seconds for the
    double-click timer to expire. Hold modifier and double-click the
    selected volume icon. Verify that it unhighlights then highlights,
    and does not open.
]]
ModifierTest(
  "mod-double-click a selected volume icon",
  function(Press, Release)
    a2d.Select("A2.DESKTOP")
    local x, y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        Press()
        m.Click()
        emu.wait(2/60)
        test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "selection should have toggled")
        m.Click()
        emu.wait(2/60)
        test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "selection should have toggled")
        Release()
        emu.wait(1)
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "selection should have toggled")
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "no windows should be open")
end)

--[[
  * Launch DeskTop. Select a volume icon. Hold modifier down and drag
    a selection rectangle around another volume icon. Verify that both
    are selected.
]]
ModifierTest(
  "mod-drag-select a second volume icon",
  function(Press, Release)
    a2d.Select("RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()

    a2d.Select("A2.DESKTOP")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x-20, y-10)
        Press()
        m.ButtonDown()
        m.MoveByApproximately(40, 30)
        m.ButtonUp()
        Release()
        emu.wait(1)
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), 2, "selection should have been extended")
end)

--[[
  * Launch DeskTop. Open a volume containing files. Click on a file
    icon. Hold modifier and click a different file icon. Verify that
    selection is extended.
]]
ModifierTest(
  "click second file icon",
  function(Press, Release)
    a2d.OpenPath("/A2.DESKTOP")

    a2d.Select("EXTRAS")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Select("READ.ME")

    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "single icon selected")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        Press()
        m.Click()
        a2d.WaitForRepaint()
        Release()
        emu.wait(1)
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), 2, "selection should be extended")
end)

--[[
  * Launch DeskTop. Open a volume containing files. Select two file
    icons. Hold modifier and click on the window, not on an icon.
    Verify that selection is not cleared.
]]
ModifierTest(
  "with file icons selected, modifier-click window",
  function(Press, Release)
    a2d.OpenPath("/A2.DESKTOP")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    a2d.SelectAll()
    local count = #a2d.GetSelectedIcons()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w - 5, y + h - 5)
        Press()
        m.Click()
        a2d.WaitForRepaint()
        Release()
        emu.wait(1)
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not be cleared")
end)

--[[
  * Launch DeskTop. Open a window. Select an icon. Hold modifier and
    double-click an empty spot in the window (not on an icon). Verify
    that the selection is not cleared.
]]
ModifierTest(
  "with file icon selected, modifier-double-click window",
  function(Press, Release)
    a2d.OpenPath("/A2.DESKTOP")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    a2d.SelectAll()
    local count = #a2d.GetSelectedIcons()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w - 5, y + h - 5)
        Press()
        m.DoubleClick()
        a2d.WaitForRepaint()
        Release()
        emu.wait(1)
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), count, "selection should not be cleared")
end)

--[[
  * Launch DeskTop. Open a window. Select an icon. Hold modifier down
    and drag a selection rectangle around another icon. Verify that
    both are selected.
]]
ModifierTest(
  "mod-drag-select a second file icon",
  function(Press, Release)
    a2d.OpenPath("/A2.DESKTOP")

    a2d.Select("EXTRAS")
    local x, y = a2dtest.GetSelectedIconCoords()

    a2d.Select("READ.ME")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x-20, y-10)
        Press()
        m.ButtonDown()
        m.MoveByApproximately(40, 30)
        m.ButtonUp()
        Release()
        emu.wait(1)
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), 2, "selection should have been extended")
end)

--[[
  * Launch DeskTop. Open a volume window. Select two file icons. Hold
    modifier and click a selected file icon. Verify that it is
    deselected.
]]
ModifierTest(
  "mod-click one of many selected file icons",
  function(Press, Release)
    a2d.OpenPath("/A2.DESKTOP")

    a2d.Select("READ.ME")
    local x, y = a2dtest.GetSelectedIconCoords()

    a2d.SelectAll()

    local count = #a2d.GetSelectedIcons()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        Press()
        m.Click()
        a2d.WaitForRepaint()
        Release()
        emu.wait(1)
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), count - 1, "clicked icon should be de-selected")
end)

--[[
  * Launch DeskTop. Open a volume window. Select one file icon. Hold
    modifier and click the selected file icon. Verify that it is
    deselected, and that the volume icon does not become selected.
]]
ModifierTest(
  "mod-click a single selected file icon",
  function(Press, Release)
    a2d.OpenPath("/A2.DESKTOP")

    a2d.Select("READ.ME")
    local x, y = a2dtest.GetSelectedIconCoords()

    local count = #a2d.GetSelectedIcons()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        Press()
        m.Click()
        a2d.WaitForRepaint()
        Release()
        emu.wait(1)
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "clicked icon should be de-selected")
end)

--[[
  * Launch DeskTop. Open a window. Hold modifier and double-click on a
    non-selected file icon. Verify that it highlights then
    unhighlights, and does not open.
]]
ModifierTest(
  "mod-double-click a non-selected file icon",
  function(Press, Release)
    a2d.OpenPath("/A2.DESKTOP")
    a2d.Select("EXTRAS")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        Press()
        m.Click()
        emu.wait(2/60)
        test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "selection should have toggled")
        m.Click()
        emu.wait(2/60)
        test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "selection should have toggled")
        Release()
        emu.wait(1)
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "selection should have toggled")
    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "no new windows should be open")
end)

--[[
  * Launch DeskTop. Open a window. Select a file icon. Wait a few
    seconds for the double-click timer to expire. Hold modifier and
    double-click the selected file icon. Verify that it unhighlights
    then highlights, and does not open.
]]
ModifierTest(
  "mod-double-click a selected file icon",
  function(Press, Release)
    a2d.OpenPath("/A2.DESKTOP")
    a2d.Select("EXTRAS")
    local x, y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        Press()
        m.Click()
        emu.wait(2/60)
        test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "selection should have toggled")
        m.Click()
        emu.wait(2/60)
        test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "selection should have toggled")
        Release()
        emu.wait(1)
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "selection should have toggled")
    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "no new windows should be open")
end)

--[[
  * Launch DeskTop. Open a volume window. Hold modifier, and
    drag-select icons in the window. Release the modifier. Verify that
    the volume icon is no longer selected. Click an empty area in the
    window to clear selection. Verify that the selection in the window
    clears, and that the volume icon becomes selected.
]]
ModifierTest(
  "drag selection in window with modifier",
  function(Press, Release)
    a2d.OpenPath("/A2.DESKTOP")
    a2d.ClearSelection()
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + 5, y + 15)
        Press()
        m.ButtonDown()
        m.MoveByApproximately(w - 10, h - 20)
        m.ButtonUp()
        Release()
    end)
    emu.wait(1)
    test.ExpectGreaterThan(#a2d.GetSelectedIcons(), 1, "selection should have changed")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w - 5, y + h - 5)
        test.Snap("clicking?")
        m.Click()
    end)
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be selected")
end)

--[[
  * Launch DeskTop. Open a volume window. Select a folder icon. Hold
    modifier, and double-click another folder icon. Verify that
    selection toggles on the second folder, and no folders are opened.
]]
ModifierTest(
  "mod-double-click a folder icon with another folder selected",
  function(Press, Release)
    a2d.OpenPath("/A2.DESKTOP")
    a2d.Select("EXTRAS")
    local x, y = a2dtest.GetSelectedIconCoords()

    a2d.Select("APPLE.MENU")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        Press()
        m.Click()
        emu.wait(2/60)
        test.ExpectEquals(#a2d.GetSelectedIcons(), 2, "selection should have toggled")
        m.Click()
        emu.wait(2/60)
        test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "selection should have toggled")
        Release()
        emu.wait(1)
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "selection should have toggled")
    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "no new windows should be open")
end)

--[[
  Launch DeskTop. Open two windows containing file icons. Clear
  selection by clicking on the desktop. Run these cases:

  * Click on an icon in the inactive window. Verify that the icon
    highlights on mouse down, and the window activates on mouse up.
]]
test.Step(
  "click icon in inactive window",
  function()
    a2d.CloseAllWindows()
    OpenVolumeWindow()
    OpenFolderWindow()
    a2d.MoveWindowBy(0, 80)

    a2d.Select("BASIC.SYSTEM")
    local x, y = a2dtest.GetSelectedIconCoords()

    a2d.ClearSelection()
    a2d.CycleWindows()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        emu.wait(1)
        test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "icon should be selected")
        test.Snap("verify window inactive")
        m.ButtonUp()
        emu.wait(2)
    end)
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "window should be active")
end)

--[[
  * Drag an icon within in the inactive window. Verify that the icon
    moves and the window does not activate until mouse-up.
]]
test.Step(
  "drag icon in inactive window",
  function()
    a2d.CloseAllWindows()
    OpenVolumeWindow()
    OpenFolderWindow()
    a2d.MoveWindowBy(0, 80)

    a2d.Select("BASIC.SYSTEM")
    local x, y = a2dtest.GetSelectedIconCoords()

    a2d.ClearSelection()
    a2d.CycleWindows()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        emu.wait(1)
        test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "icon should be selected")
        test.Snap("verify window inactive")
        m.MoveByApproximately(20, 10)
        m.ButtonUp()
        emu.wait(1)
    end)
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "window should be active")
end)

--[[
  * Drag an icon from the inactive window to a volume icon that does
    not have an open window. Verify that the active window remains
    active.
]]
test.Step(
  "drag icon in inactive window to volume icon",
  function()
    a2d.CloseAllWindows()
    a2d.Select("RAM1")
    local vol_x, vol_y = a2dtest.GetSelectedIconCoords()

    OpenVolumeWindow()
    OpenFolderWindow()
    a2d.MoveWindowBy(0, 80)

    a2d.Select("BASIC.SYSTEM")
    local x, y = a2dtest.GetSelectedIconCoords()

    a2d.ClearSelection()
    a2d.CycleWindows()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        emu.wait(1)
        test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "icon should be selected")
        test.Snap("verify window inactive")
        m.MoveToApproximately(vol_x, vol_y)
        m.ButtonUp()
        emu.wait(5)
    end)
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "window should remain active")

    a2d.EraseVolume("RAM1")
end)

--[[
  * Open a volume icon so a third window appears. Click the first
    window to activate it. Drag an icon from the second window to the
    volume icon. Verify that the third window activates.
]]
test.Step(
  "drag icon in inactive window to volume icon with window",
  function()
    a2d.CloseAllWindows()
    a2d.Select("RAM1")
    local vol_x, vol_y = a2dtest.GetSelectedIconCoords()

    OpenVolumeWindow()
    local win_x, win_y = a2dtest.GetFrontWindowDragCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_x, vol_y)
        m.DoubleClick()
    end)
    a2d.MoveWindowBy(500, 80)

    OpenFolderWindow()
    a2d.MoveWindowBy(0, 80)
    a2d.Select("BASIC.SYSTEM")
    local x, y = a2dtest.GetSelectedIconCoords()

    a2d.ClearSelection()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(win_x, win_y)
        m.Click()
    end)
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.ButtonDown()
        emu.wait(1)
        test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "icon should be selected")
        test.Snap("verify window inactive")
        m.MoveToApproximately(vol_x, vol_y)
        m.ButtonUp()
        emu.wait(5)
    end)
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "RAM1", "volume window should be activated")

    a2d.EraseVolume("RAM1")
end)


--[[
  Launch DeskTop. Open two windows containing file icons. Clear
  selection by clicking on the desktop. Repeat the following cases
  with these modifiers: Open-Apple, Shift (on a IIgs), Shift (on a
  Platinum IIe):

  * Select an icon. Activate the other window by clicking on the title
    bar. Hold modifier and click another icon in the inactive window.
    Verify that the icon highlights on mouse down, and the window
    activates on mouse up, and both icons are selected.

  * Select an icon. Activate the other window by clicking on the title
    bar. Hold modifier and click the selected icon in the inactive
    window. Verify that the icon unhighlights and the window activates
    on mouse down.

  * Select an icon. Activate the other window by clicking on the title
    bar. Hold modifier and drag another icon within the inactive
    window. Verify that the icon highlights and both icons are
    dragged. Release the modifier before ending the drag. Verify that
    the window activates on mouse up, and that both icons are moved.
]]
ModifierTest(
  "clicking and dragging - multiple windows",
  function(Press, Release)
    OpenVolumeWindow()
    local volume_x, volume_y = a2dtest.GetFrontWindowDragCoords()
    OpenFolderWindow()
    a2d.MoveWindowBy(0, 80)
    local folder_x, folder_y = a2dtest.GetFrontWindowDragCoords()
    a2d.ClearSelection()

    a2d.Select("BASIC.SYSTEM")
    local file_x, file_y = a2dtest.GetSelectedIconCoords()

    -- Select an icon
    a2d.Select("INTBASIC.SYSTEM")
    a2d.InMouseKeysMode(function(m)
        -- Activate other window by clicking in title bar
        m.MoveToApproximately(volume_x, volume_y)
        m.Click()
        -- Hold modifier and click another icon in now inactive window
        m.MoveToApproximately(file_x, file_y)
        Press()
        m.ButtonDown()
        emu.wait(1)
        test.Snap("verify both icons selected, window still inactive")
        Release()
        m.ButtonUp()
        emu.wait(1)
        test.Snap("verify window active")
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), 2, "both icons should be selected")

    -- Select an icon
    a2d.Select("BASIC.SYSTEM")
    a2d.InMouseKeysMode(function(m)
        -- Activate other window by clicking in title bar
        m.MoveToApproximately(volume_x, volume_y)
        m.Click()
        -- Hold modifier and click selected icon in now inactive window
        m.MoveToApproximately(file_x, file_y)
        Press()
        m.ButtonDown()
        emu.wait(1)
        test.Snap("verify icon deselected, and window activated")
        Release()
        m.ButtonUp()
        emu.wait(1)
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "icon should be deselected")

    -- Select an icon
    a2d.Select("INTBASIC.SYSTEM")

    a2d.InMouseKeysMode(function(m)
        -- Activate other window by clicking in title bar
        m.MoveToApproximately(volume_x, volume_y)
        m.Click()
        -- Hold modifier and drag another icon in now inactive window
        m.MoveToApproximately(file_x, file_y)
        Press()
        m.ButtonDown()
        emu.wait(1)
        test.Snap("verify both icons selected, window still inactive")
        Release()
        m.MoveByApproximately(20, 20)
        m.ButtonUp()
        emu.wait(1)
        test.Snap("verify window active")
    end)
    test.Snap("verify icons moved")
    test.ExpectEquals(#a2d.GetSelectedIcons(), 2, "both icons should be selected")
end)

--[[
  Launch DeskTop. Click on a volume icon. Hold Solid-Apple and click
  on a different volume icon. Verify that selection changes to the
  second icon.
]]
test.Step(
  "SA+Click changes volume selection",
  function()
    a2d.SelectPath("/RAM1")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.SelectPath("/A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        apple2.PressSA()
        m.Click()
        apple2.ReleaseSA()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "RAM1", "icon should be selected")
end)

--[[
  Launch DeskTop. Open a volume containing files. Click on a file
  icon. Hold Solid-Apple and click on a different file icon. Verify
  that selection changes to the second icon.
]]
test.Step(
  "SA+Click changes file selection",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.Select("READ.ME")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Select("PRODOS")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        apple2.PressSA()
        m.Click()
        apple2.ReleaseSA()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "icon should be selected")
end)

--[[
  Launch DeskTop. Open a volume window. Select an icon. Click in the
  header area (items/use/etc). Verify that selection is not cleared.
]]
test.Step(
  "click in header does not change selection",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        -- Click in header
        m.MoveToApproximately(x + w / 2, y + 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "icon should be selected")
end)

--[[
  Launch DeskTop. Open a volume window. Adjust the window so it is
  small and roughly centered on the screen. In the middle of the
  window, start a drag-selection. Move the mouse cursor in circles
  around the outside of the window and within the window. Verify that
  one corner of the selection rectangle remains fixed where the
  drag-selection was started.
]]
test.Step(
  "drag selection fixed point",
  function()
    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(150, 40)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w / 2, y + h / 2)
        m.ButtonDown()
        test.Snap("note start of drag selection")
        m.MoveByApproximately(0, -apple2.SCREEN_HEIGHT/2)
        m.MoveByApproximately(apple2.SCREEN_WIDTH/2, 0)
        test.Snap("verify rect has one corner fixed at drag start")
        m.MoveByApproximately(0, apple2.SCREEN_HEIGHT)
        test.Snap("verify rect has one corner fixed at drag start")
        m.MoveByApproximately(-apple2.SCREEN_WIDTH, 0)
        test.Snap("verify rect has one corner fixed at drag start")
        m.MoveByApproximately(0, -apple2.SCREEN_HEIGHT)
        test.Snap("verify rect has one corner fixed at drag start")
        m.MoveByApproximately(apple2.SCREEN_WIDTH/2, 0)
        test.Snap("verify rect has one corner fixed at drag start")
        m.ButtonUp()
    end)
end)

--[[
  Launch DeskTop. Open two windows for two different volumes. Select
  an icon in one window. Click on the title bar, scroll bars, or
  header of the other window to activate it. Verify that the icon in
  the first window is still selected. Click on the title bar, scroll
  bar or header of the active window. Verify that the icon in the
  first window is still selected. Click on the content area of the
  active window. Verify that the icon is no longer selected, and the
  window's corresponding volume icon becomes selected when the mouse
  button is released.
]]
test.Step(
  "clicking non-content area doesn't change selection",
  function()
    a2d.OpenPath("/RAM1")
    local ram_id = a2dtest.GetFrontWindowID()
    a2d.MoveWindowBy(0, 100)

    OpenVolumeWindow()
    a2d.GrowWindowBy(0, -20)

    a2d.Select("READ.ME")

    local x,y,w,h = a2dtest.GetWindowContentRect(ram_id)
    -- click title bar
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w / 2, y - 5)
        m.Click()
    end)
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "selection should not change")

    -- click scroll bar
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w / 2, y + h + 5)
        m.Click()
    end)
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "selection should not change")

    -- click header
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w / 2, y + 5)
        m.Click()
    end)
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "selection should not change")

    -- click content area
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w - 5, y + h - 5)
        m.Click()
    end)
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "RAM1", "volume should be selected")
end)

--[[
  Launch DeskTop. Open a window for a volume icon and a window for a
  folder icon. Click in the content area of the volume icon's window.
  Verify that the volume icon is selected. Click in the content area
  of the folder icon's window. Verify that the folder icon is
  selected.
]]
test.Step(
  "clicking content area",
  function()
    a2d.CloseAllWindows()
    OpenVolumeWindow()
    local volume_id = a2dtest.GetFrontWindowID()

    OpenFolderWindow()
    local folder_id = a2dtest.GetFrontWindowID()
    a2d.GrowWindowBy(0, -40)
    a2d.MoveWindowBy(0, 80)

    local x,y,w,h = a2dtest.GetWindowContentRect(volume_id)
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w - 5, y + h - 5)
        m.Click()
    end)
    a2d.WaitForRepaint()

    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be selected")

    x,y,w,h = a2dtest.GetWindowContentRect(folder_id)
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w - 5, y + h - 5)
        m.Click()
    end)
    a2d.WaitForRepaint()

    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "EXTRAS", "folder icon should be selected")
end)


--[[
  Launch DeskTop. Open a window for a volume icon and a window for a
  folder icon within that volume. Close the window for the volume
  icon. Click in the content area of the folder icon's window. Verify
  that the volume icon is selected.
]]
test.Step(
  "volume icon selected when window clicked",
  function()
    a2d.CloseAllWindows()
    OpenVolumeWindow()
    OpenFolderWindow()
    a2d.CycleWindows()
    a2d.CloseWindow()

    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w - 5, y + h - 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be selected")
end)

--[[
  Launch DeskTop. Open a window. Select a file icon. Apple Menu >
  Control Panels. Verify that the previously selected file is no
  longer selected.
]]
test.Step(
  "selection after window opened from Apple Menu item",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2d.WaitForRepaint()
    test.Expect(#a2d.GetSelectedIcons(), 0, "no icons should be selected")
end)

--[[
  Launch DeskTop, ensuring no windows are open. Edit > Select All.
  Verify that the volume icons are selected.
]]
test.Step(
  "focus with no windows",
  function()
    a2d.CloseAllWindows()
    a2d.ClearSelection()

    -- Edit > Select All
    a2d.InvokeMenuItem(a2d.EDIT_MENU, a2d.EDIT_SELECT_ALL)
    a2d.WaitForRepaint()

    local icons = a2d.GetSelectedIcons()
    test.ExpectGreaterThan(#icons, 0, "multiple icons should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "Trash", "volume icons should be selected")
end)

--[[
  Launch DeskTop. Open a window. Click a volume icon. Edit > Select
  All. Verify that volume icons are selected.
]]
test.Step(
  "focus after click volume icon",
  function()
    a2d.CloseAllWindows()

    a2d.Select("A2.DESKTOP")
    local x, y = a2dtest.GetSelectedIconCoords()

    -- open a window
    a2d.OpenPath("/A2.DESKTOP")
    a2d.ClearSelection()

    -- click volume icon
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + 5, y + 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be clicked")

    -- Edit > Select All
    a2d.InvokeMenuItem(a2d.EDIT_MENU, a2d.EDIT_SELECT_ALL)
    a2d.WaitForRepaint()

    local icons = a2d.GetSelectedIcons()
    test.ExpectGreaterThan(#icons, 0, "multiple icons should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "Trash", "volume icons should be selected")
end)

--[[
  Launch DeskTop. Open a window. Click a volume icon. Click on the
  open window's title bar. Edit > Select All. Verify that icons within
  the window are selected. Repeat for the window's header and scroll
  bars.
]]
test.Variants(
  {
    {"focus after clicking title bar of window", "titlebar"},
    {"focus after clicking header of window", "header"},
    {"focus after clicking scroll bar of window", "scrollbar"},
  },
  function(idx, name, where)
    a2d.CloseAllWindows()

    a2d.Select("A2.DESKTOP")
    local vol_x, vol_y = a2dtest.GetSelectedIconCoords()

    -- open a window
    a2d.OpenPath("/A2.DESKTOP")
    a2d.ClearSelection()

    -- click volume icon
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_x + 5, vol_y + 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be clicked")

    -- click target
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        if where == "title" then
          m.MoveToApproximately(x + w / 2, y - 5)
        elseif where == "header" then
          m.MoveToApproximately(x + w / 2, y + 5)
        elseif where == "scrollbar" then
          m.MoveToApproximately(x + w / 2, y + h + 5)
        end
        m.Click()
    end)
    a2d.WaitForRepaint()

    -- Edit > Select All
    a2d.InvokeMenuItem(a2d.EDIT_MENU, a2d.EDIT_SELECT_ALL)
    a2d.WaitForRepaint()

    local icons = a2d.GetSelectedIcons()
    test.ExpectGreaterThan(#icons, 0, "multiple icons should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "PRODOS", "file icons should be selected")
end)

--[[
  Launch DeskTop. Open a window. Click a volume icon. Click an empty
  area within the window. Edit > Select All. Verify that icons within
  the window are selected.
]]
test.Step(
  "focus after click volume icon, click window",
  function()
    a2d.CloseAllWindows()

    a2d.Select("A2.DESKTOP")
    local vol_x, vol_y = a2dtest.GetSelectedIconCoords()

    -- open a window
    a2d.OpenPath("/A2.DESKTOP")
    a2d.Select("READ.ME")
    a2d.ClearSelection()

    -- click volume icon
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_x + 5, vol_y + 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be clicked")

    -- click window
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w - 5, y + h - 5)
        m.Click()
    end)
    a2d.WaitForRepaint()

    -- Edit > Select All
    a2d.InvokeMenuItem(a2d.EDIT_MENU, a2d.EDIT_SELECT_ALL)
    a2d.WaitForRepaint()

    local icons = a2d.GetSelectedIcons()
    test.ExpectGreaterThan(#icons, 0, "multiple icons should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "PRODOS", "file icons should be selected")
end)

--[[
  Launch DeskTop. Open a window. Click a volume icon. Click an icon
  within the window. Edit > Select All. Verify that icons within the
  window are selected.
]]
test.Step(
  "focus after click volume icon, click file icon",
  function()
    a2d.CloseAllWindows()

    a2d.Select("A2.DESKTOP")
    local vol_x, vol_y = a2dtest.GetSelectedIconCoords()

    -- open a window
    a2d.OpenPath("/A2.DESKTOP")
    a2d.Select("READ.ME")
    local file_x, file_y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

    -- click volume icon
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_x + 5, vol_y + 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be clicked")

    -- click file icon
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_x + 5, file_y + 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "file icon should be clicked")

    -- Edit > Select All
    a2d.InvokeMenuItem(a2d.EDIT_MENU, a2d.EDIT_SELECT_ALL)
    a2d.WaitForRepaint()

    local icons = a2d.GetSelectedIcons()
    test.ExpectGreaterThan(#icons, 0, "multiple icons should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "PRODOS", "file icons should be selected")
end)

--[[
  Launch DeskTop. Open a window. Click a volume icon. Click an empty
  space on the desktop. Edit > Select All. Verify that volume icons
  are selected.
]]
test.Step(
  "focus after click volume icon, click desktop",
  function()
    a2d.CloseAllWindows()

    a2d.Select("A2.DESKTOP")
    local x, y = a2dtest.GetSelectedIconCoords()

    -- open a window
    a2d.OpenPath("/A2.DESKTOP")
    a2d.ClearSelection()

    -- click volume icon
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + 5, y + 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be clicked")

    -- click empty space
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(0, apple2.SCREEN_HEIGHT)
        m.Click()
    end)

    -- Edit > Select All
    a2d.InvokeMenuItem(a2d.EDIT_MENU, a2d.EDIT_SELECT_ALL)
    a2d.WaitForRepaint()

    local icons = a2d.GetSelectedIcons()
    test.ExpectGreaterThan(#icons, 0, "multiple icons should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "Trash", "volume icons should be selected")
end)

--[[
  Launch DeskTop. Open a window. Click a file icon. Click an empty
  space on the desktop. Edit > Select All. Verify that file icons
  are selected.
]]
test.Step(
  "focus after click file icon, click desktop",
  function()
    a2d.CloseAllWindows()

    -- open a window
    a2d.OpenPath("/A2.DESKTOP")
    a2d.Select("READ.ME")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

    -- click file icon
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + 5, y + 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "file icon should be clicked")

    -- click empty space
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(0, apple2.SCREEN_HEIGHT)
        m.Click()
    end)

    -- Edit > Select All
    a2d.InvokeMenuItem(a2d.EDIT_MENU, a2d.EDIT_SELECT_ALL)
    a2d.WaitForRepaint()

    local icons = a2d.GetSelectedIcons()
    test.ExpectGreaterThan(#icons, 0, "multiple icons should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "PRODOS", "file icons should be selected")
end)

--[[
  Launch DeskTop. Open a volume window. Drag a selection rectangle so
  that it covers only the top row of pixels of an icon. Verify that
  the icon is selected.
]]
test.Step(
  "drag selection and icon bounds",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.Select("CLOCK.SYSTEM")
    local icon = a2d.GetSelectedIcons()[1]
    a2d.ClearSelection()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(icon.x-5, icon.y)
        m.ButtonDown()
        m.MoveByApproximately(40, -10)
        test.Snap("verify only top pixel of icon is in rect")
        m.ButtonUp()
    end)
    a2d.WaitForRepaint()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "CLOCK.SYSTEM", "icon should be selected")
end)
