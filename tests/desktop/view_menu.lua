--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

--[[
  Open folder with files. View > by Date. Verify that DeskTop does not
  hang.
]]
test.Step(
  "View by Date - doesn't hang",
  function()
    desktop.OpenWindow("/A2.DESKTOP")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_DATE)
    a2dtest.WaitForSystemTask()
    test.Snap("verify no hang")
    desktop.CloseAllWindows()
end)

--[[
  Open folder with new files. Use View > by Date; verify dates after
  1999 show correctly.
]]
test.Step(
  "View by Date - Y2K",
  function()
    desktop.OpenWindow("/TESTS/FILE.TYPES")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_DATE)
    a2dtest.WaitForSystemTask()
    test.Snap("verify dates after 1999 show correctly")
    desktop.CloseAllWindows()
end)

--[[
  Open folder with new files. Use View > by Date. Verify that two
  files modified on the same date are correctly ordered by time.
]]
test.Step(
  "View by Date - Secondarily sorted by time",
  function()
    desktop.OpenWindow("/TESTS/VIEW/BY.DATE")
    desktop.GrowWindowBy(300, 0)
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_DATE)
    a2dtest.WaitForSystemTask()
    test.Snap("verify same dates sort by time")
    desktop.CloseAllWindows()
end)

--[[
  Open folder with zero files. Use View > by Name. Verify that there
  is no crash.
]]
test.Step(
  "View by Name - Empty folder doesn't crash",
  function()
    desktop.OpenWindow("/TESTS/VIEW/BY.NAME/EMPTY")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
    a2dtest.ExpectNotHanging()
    desktop.CloseAllWindows()
end)

--[[
  Open folder with one file. Use View > by Name. Verify that the entry
  paints correctly.
]]
test.Step(
  "View by Name - Folder with 1 file paints correctly",
  function()
    desktop.OpenWindow("/TESTS/VIEW/BY.NAME/ONE.FILE")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
    test.Snap("verify paints correctly")
    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window with files with dates with long month
  names (e.g. "February 29, 2020"). View > by Name. Resize the window
  so the lines are cut off on the right. Move the horizontal scrollbar
  all the way to the right. Verify that the right edges of all lines
  are visible.
]]
test.Step(
  "View by Name - Long month names can be scrolled into view",
  function()
    desktop.OpenWindow("/TESTS/VIEW/BY.NAME/LONG.MONTHS")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
    local arrow_x, arrow_y = a2dtest.GetFrontWindowRightScrollArrowCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(arrow_x, arrow_y)
        for i=1,20 do
          m.Click()
        end
    end)
    test.Snap("verify date not cut off on right")
    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window containing a folder. View > by Name.
  Open the folder. Verify that in the new window, the horizontal
  scrollbar is inactive.
]]
test.Step(
  "View by Name - Child windows resized to fit",
  function()
    desktop.OpenWindow("/TESTS/VIEW/BY.NAME")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
    desktop.SelectAndOpen("LONG.MONTHS")
    a2dtest.WaitForSystemTask()
    test.Snap("verify no horizontal scrollbar")
    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a volume window. View > by Name. Open a
  separate volume window. Open a folder window. Open a subfolder
  window. View > by Name. Close the window. Verify DeskTop doesn't
  crash.
]]
test.Step(
  "View by Name - No crash",
  function()
    desktop.SelectPath("/A2.DESKTOP")
    local vol_icon_x, vol_icon_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/TESTS")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon_x, vol_icon_y)
        m.DoubleClick()
    end)
    desktop.SelectAndOpen("APPLE.MENU")
    desktop.SelectAndOpen("CONTROL.PANELS")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
    desktop.CloseWindow()
    a2dtest.ExpectNotHanging()
    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a volume window. Open a folder window. View >
  by Name. Verify that the selection is still in the volume window,
  and that there is no selection in the folder window.
]]
test.Step(
  "View by Name - Selection unchanged in volume",
  function()
    desktop.OpenWindow("/A2.DESKTOP")
    desktop.SelectAndOpen("APPLE.MENU")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
    desktop.MoveWindowBy(0,100)
    test.Snap("verify selection still in volume window")
    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a volume window. Open a folder window. Select a
  file in the folder window. View > by Name. Verify that the selection
  is still in the folder window.
]]
test.Step(
  "View by Name - Selection unchanged in folder",
  function()
    desktop.OpenWindow("/A2.DESKTOP")
    desktop.SelectAndOpen("APPLE.MENU")
    apple2.DownArrowKey()
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
    desktop.MoveWindowBy(0,100)
    test.Snap("verify selection still in folder window")
    desktop.CloseAllWindows()
end)

desktop.AddShortcut("/A2.DESKTOP")

--[[
  Repeat for the Shortcuts > Add, Edit, Delete, and Run a Shortcut
  commands

  Launch DeskTop. Open a volume window. View > by Name. Run the
  command from the Shortcuts menu. Cancel. Verify that the window
  entries repaint correctly (correct types, sizes, dates) and DeskTop
  doesn't crash.
]]
test.Variants(
  {
    "Repaint after Add Shortcut",
    "Repaint after Edit Shortcut",
    "Repaint after Delete Shortcut",
    "Repaint after Run Shortcut",
  },
  function(idx)
    desktop.OpenWindow("/A2.DESKTOP")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
    a2d.InvokeMenuItem(desktop.SHORTCUTS_MENU, idx)
    a2dtest.WaitForSystemTask()
    a2d.DialogCancel()
    test.Snap("verify window correctly repaints")
    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. On a volume, create folders named "A1", "B1", "A",
  and "B". View > by Name. Verify that the order is: "A", "A1", "B",
  "B1".
]]
test.Step(
  "View by Name - Ordering",
  function()
    desktop.OpenWindow("/TESTS/VIEW/BY.NAME/A1.B1.A.B")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
    desktop.GrowWindowBy(100,20)
    test.Snap("verify order is A, A1, B, B1")
    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open `/TESTS/FILE.TYPES`. View > by Type. Verify
  that the files are sorted by type name, first alphabetically
  followed by $XX types in numeric order.
]]
test.Step(
  "View by Type - Ordering",
  function()
    desktop.OpenWindow("/TESTS/FILE.TYPES")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_TYPE)
    a2dtest.WaitForSystemTask()
    test.Snap("verify sorted by type alpha then $XX")
    for i=1,20 do
      apple2.DownArrowKey()
      a2dtest.WaitForSystemTask()
    end
    test.Snap("verify sorted by type alpha then $XX")
    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window containing multiple files. View > by
  Size. Verify that the files are sorted by size in descending order,
  with directories at the end.
]]
test.Step(
  "View by Size - Ordering",
  function()
    desktop.OpenWindow("/TESTS/FILE.TYPES")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_SIZE)
    a2dtest.WaitForSystemTask()
    test.Snap("verify sorted large to small then dirs")
    for i=1,20 do
      apple2.DownArrowKey()
      a2dtest.WaitForSystemTask()
    end
    test.Snap("verify sorted large to small then dirs")
    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open window containing icons. View > by Name. Verify
  that selection is supported:

  The icon bitmap and name can be clicked on.

  Drag-selecting the icon bitmap and/or name selects.

  Selected icons can be dragged to other windows or volume icons to
  initiate a move or copy.

  Dragging a selected icon over a non-selected folder icon in the same
  window causes it to highlight, and initiates a move or copy
  (depending on modifier keys).
]]
test.Step(
  "Icons in list can be selected and dragged",
  function()
    desktop.SelectPath("/A2.DESKTOP")
    local vol_icon_x, vol_icon_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/TESTS/VIEW/DRAGGING")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()

    local window_x,window_y = a2dtest.GetFrontWindowContentRect()

    desktop.ClearSelection()
    test.ExpectNotIMatch(a2dtest.OCRScreen({invert=true}), "FILE", "file should not be selected")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(window_x+11, window_y+21)
        m.Click()
        a2dtest.WaitForSystemTask()
        m.MoveByApproximately(20, 20)
    end)
    test.ExpectIMatch(a2dtest.OCRScreen({invert=true}), "FILE", "clicking bitmap should select")

    desktop.ClearSelection()
    test.ExpectNotIMatch(a2dtest.OCRScreen({invert=true}), "FILE", "file should not be selected")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(window_x+35, window_y+21)
        m.Click()
        a2dtest.WaitForSystemTask()
        m.MoveByApproximately(20, 20)
    end)
    test.ExpectIMatch(a2dtest.OCRScreen({invert=true}), "FILE", "clicking name should select")

    desktop.ClearSelection()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(window_x+35, window_y+21)
        m.ButtonDown()
        m.MoveToApproximately(vol_icon_x, vol_icon_y)
        m.ButtonUp()
        util.WaitFor(
          "progress displayed", function()
            return a2dtest.OCRFrontWindowContent():match("Files remaining")
        end)
        test.ExpectMatch(a2dtest.OCRFrontWindowContent(), "Copying: 1 file", "drag to other volume icon should initiate copy")
    end)
    a2dtest.WaitForSystemTask() -- wait for copy

    desktop.ClearSelection()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(window_x+35, window_y+18)
        m.ButtonDown()
        m.MoveByApproximately(0, 12)
        emu.wait(1) -- during drag
        test.Snap("verify dragging over folder icon highlights")
        m.ButtonUp()
        util.WaitFor(
          "progress displayed", function()
            return a2dtest.OCRFrontWindowContent():match("Files remaining")
        end)
        test.ExpectMatch(a2dtest.OCRFrontWindowContent(), "Moving: 1 file", "drop on folder icon should initiate move")
    end)
    a2dtest.WaitForSystemTask() -- wait for move

    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open window containing icons. View > by Name. Select
  one or more icons. Drag them within the window but not over any
  other icons. Release the mouse button. Verify that the icons do not
  move.
]]
test.Step(
  "Icons in list view don't move",
  function()
    desktop.OpenWindow("/TESTS/VIEW/DRAGGING")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()

    apple2.DownArrowKey() -- select first item
    util.WaitFor(
      "selection to update", function()
        return a2dtest.IsSelectionInFrontWindow()
      end, {wait=0.25})
    local x, y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.Home()
    end)

    a2dtest.ExpectNothingChanged(function()
        local window_x,window_y = a2dtest.GetFrontWindowContentRect()
        a2d.InMouseKeysMode(function(m)
            m.MoveToApproximately(x, y)
            m.ButtonDown()
            m.MoveByApproximately(100, 0)
            m.ButtonUp()
            a2dtest.WaitForSystemTask()
            m.Home()
        end)
    end)

    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open window containing icons. View > by Name. Select
  an icon. File > Rename. Enter a new name that would change the
  ordering. Verify that the window is refreshed and the icons are
  correctly sorted by name, and that the icon is still selected.
]]
test.Step(
  "Rename causes refresh",
  function()
    desktop.OpenWindow("/TESTS/VIEW/RENAME.REFRESH")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
    desktop.Select("ANTEATER")
    desktop.RenameSelection("YAK")
    test.Snap("verify selection retained, in order, and in view")
    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open two windows containing icons. View > by Name.
  Select an icon. Activate the other window. Verify that selection
  remains in the first window. File > Rename. Enter a new name that
  would change the ordering. Verify that the first window is activated
  and refreshed and the icons are correctly sorted by name, and that
  the icon is still selected and scrolled into view.
]]
test.Step(
  "Rename causes refresh with two windows",
  function()
    desktop.OpenWindow("/TESTS/VIEW")
    desktop.SelectAndOpen("RENAME.REFRESH")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
    desktop.Select("BUNYIP")
    desktop.CycleWindows()
    desktop.MoveWindowBy(0,100)
    desktop.RenameSelection("ZEBRA")
    test.Snap("verify selection retained, in order, and in view")
    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window containing a folder. Open a folder.
  Activate the parent window and verify that the folder's icon is
  dimmed. View > by Name. Verify that the folder's icon is still
  dimmed. View > as Icons. Verify that the folder's icon is still
  dimmed.
]]
test.Step(
  "Folder icons stay dimmed",
  function()
    desktop.OpenWindow("/TESTS")
    desktop.SelectAndOpen("ALIASES")
    desktop.CycleWindows()
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "ALIASES", "clicked icon should be selected")
    test.Expect(desktop.GetSelectedIcons()[1].dimmed, "selected icon should be dimmed")

    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_AS_ICONS)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "ALIASES", "clicked icon should be selected")
    test.Expect(desktop.GetSelectedIcons()[1].dimmed, "selected icon should be dimmed")

    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window containing a folder. View > by Name.
  Verify that the volume's icon is dimmed. View > as Icon. Verify that
  the volume's icon is still dimmed.
]]
test.Step(
  "Volume icons stay dimmed",
  function()
    desktop.OpenWindow("/TESTS")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "TESTS", "volume icon should be selected")
    test.Expect(desktop.GetSelectedIcons()[1].dimmed, "selected icon should be dimmed")

    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_AS_ICONS)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "TESTS", "volume icon should be selected")
    test.Expect(desktop.GetSelectedIcons()[1].dimmed, "selected icon should be dimmed")

    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a volume window. Verify that the default view
  is "as Icons". View > by Name. Open a folder. Verify that the new
  folder's view is "by Name". Open a different volume window. Verify
  that it is "as Icons".
]]
test.Step(
  "Volumes default to icon",
  function()
    desktop.SelectPath("/A2.DESKTOP")
    local vol_icon_x, vol_icon_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/TESTS")
    test.Snap("verify icon view")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
    desktop.SelectAndOpen("FILE.TYPES")
    test.Snap("verify name view")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon_x, vol_icon_y)
        m.DoubleClick()
        a2dtest.WaitForSystemTask()
    end)
    test.Snap("verify icon view")
    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open the A2.Desktop volume. View > as Small Icons.
  Open the Apple.Menu folder. Open the Control.Panels folder. Verify
  that the view is still "as Small Icons". Activate a different
  window. Apple Menu > Control Panels. Verify that the Control.Panels
  window is activated, and the view is still "as Small Icons".
]]
test.Step(
  "Folders in Apple menu",
  function()
    desktop.OpenWindow("/A2.DESKTOP")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_AS_SMALL_ICONS)
    a2dtest.WaitForSystemTask()
    desktop.SelectAndOpen("APPLE.MENU")
    desktop.SelectAndOpen("CONTROL.PANELS")
    test.Snap("verify small icon view")
    desktop.CycleWindows()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.CONTROL_PANELS)
    a2dtest.WaitForSystemTask()
    test.Snap("verify small icon view")
    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a volume window. Select volume icons on the
  desktop. Switch window's view to by Name. Verify that the volume
  icons are still selected, and that File > Get Info is still enabled
  (and shows the volume info). Switch window's view back to as Icons.
  Verify that the desktop volume icons are still selected.
]]
test.Step(
  "Volume icon selection and multiple view switches",
  function()
    desktop.SelectPath("/A2.DESKTOP")
    local vol_icon_x, vol_icon_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/TESTS")

    desktop.ClearSelectionAndFocusDesktop()
    desktop.SelectAll()
    a2dtest.WaitForSystemTask()

    local count = #desktop.GetSelectedIcons()
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "icons should still be selected")

    a2d.OAShortcut("I") -- File > Get Info
    a2dtest.WaitForSystemTask()
    test.Snap("verify File > Get File Info show volume info")
    a2d.DialogCancel()
    a2dtest.WaitForSystemTask()

    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_AS_ICONS)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "icons should still be selected")

    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window containing file icons. Select one or
  more file icons in the window. Select a different View option.
  Verify that the icons in the window remain selected.
]]
test.Step(
  "File icon selection retained",
  function()
    desktop.OpenWindow("/A2.DESKTOP")
    desktop.SelectAll()
    local count = #desktop.GetSelectedIcons()
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(#desktop.GetSelectedIcons(), count, "icons should still be selected")
    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window containing file icons. Hold Open-Apple
  and select multiple files in a specific order. Select a different
  View option. Apple Menu > Sort Directory. View > as Icons. Verify
  that the icons appear in the selected order.
]]
test.Step(
  "Selection order retained",
  function()
    desktop.OpenWindow("/TESTS/VIEW/SELECTION.ORDER")

    desktop.Select("ONE")
    local x1, y1 = a2dtest.GetSelectedIconCoords()
    desktop.Select("TWO")
    local x2, y2 = a2dtest.GetSelectedIconCoords()
    desktop.Select("THREE")
    local x3, y3 = a2dtest.GetSelectedIconCoords()
    desktop.Select("FOUR")
    local x4, y4 = a2dtest.GetSelectedIconCoords()
    desktop.Select("FIVE")
    local x5, y5 = a2dtest.GetSelectedIconCoords()
    desktop.Select("SIX")
    local x6, y6 = a2dtest.GetSelectedIconCoords()

    desktop.ClearSelection()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x1, y1)
        m.Click()
        m.MoveToApproximately(x2, y2)
        m.OAClick()
        m.MoveToApproximately(x3, y3)
        m.OAClick()
        m.MoveToApproximately(x4, y4)
        m.OAClick()
        m.MoveToApproximately(x5, y5)
        m.OAClick()
        m.MoveToApproximately(x6, y6)
        m.OAClick()
    end)
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.SORT_DIRECTORY)
    a2dtest.WaitForSystemTask()
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_AS_ICONS)
    a2dtest.WaitForSystemTask()

    desktop.SelectAll()
    local icons = desktop.GetSelectedIcons()
    test.ExpectEquals(#icons, 6, "five icons should be selected")
    test.ExpectEqualsIgnoreCase(icons[1].name, "ONE", "selection order should be retained")
    test.ExpectEqualsIgnoreCase(icons[2].name, "TWO", "selection order should be retained")
    test.ExpectEqualsIgnoreCase(icons[3].name, "THREE", "selection order should be retained")
    test.ExpectEqualsIgnoreCase(icons[4].name, "FOUR", "selection order should be retained")
    test.ExpectEqualsIgnoreCase(icons[5].name, "FIVE", "selection order should be retained")
    test.ExpectEqualsIgnoreCase(icons[6].name, "SIX", "selection order should be retained")

    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window containing file icons. Select one or
  more volume icons on the desktop. Select a different View option.
  Verify that the volume icons on the desktop remain selected.
]]
test.Step(
  "Volume icon selection",
  function()
    desktop.SelectPath("/A2.DESKTOP")
    local vol_icon_x, vol_icon_y = a2dtest.GetSelectedIconCoords()

    desktop.OpenWindow("/TESTS")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon_x, vol_icon_y)
        m.Click()
    end)
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "A2.DESKTOP", "clicked icon should be selected")

    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window. Verify that the appropriate View
  option is checked. Close the window. Verify that the View menu items
  are all disabled, and that none are checked.
]]
test.Step(
  "View menu item states",
  function()
    desktop.OpenWindow("/TESTS")
    a2d.OpenMenu(desktop.VIEW_MENU)
    test.Snap("verify 'as Icons' is checked")
    apple2.EscapeKey()
    desktop.CloseAllWindows()
    a2d.OpenMenu(desktop.VIEW_MENU)
    local ocr = a2dtest.OCRScreen()
    test.ExpectNotMatch(ocr, "as Icons", "all menu items should be disabled")
    test.ExpectNotMatch(ocr, "as Small Icons", "all menu items should be disabled")
    test.ExpectNotMatch(ocr, "by Name", "all menu items should be disabled")
    test.ExpectNotMatch(ocr, "by Date", "all menu items should be disabled")
    test.ExpectNotMatch(ocr, "by Size", "all menu items should be disabled")
    test.ExpectNotMatch(ocr, "by Type", "all menu items should be disabled")
end)

--[[
  File > New Folder. View > by Date / Size / Type. File > Rename
  Give it a new name. Verify that the icon is correctly "small" style
  and cannot be dragged.
]]
test.Step(
  "Rename in list view doesn't lose icon flags",
  function()
    for i, item in ipairs({
      desktop.VIEW_AS_ICONS, desktop.VIEW_AS_SMALL_ICONS,
      desktop.VIEW_BY_NAME, desktop.VIEW_BY_DATE, desktop.VIEW_BY_SIZE, desktop.VIEW_BY_TYPE }) do
      desktop.OpenWindow("/RAM1")
      desktop.CreateFolder("SAMPLE.FOLDER")
      a2d.InvokeMenuItem(desktop.VIEW_MENU, item)
      a2dtest.WaitForSystemTask()
      local flags = desktop.GetSelectedIcons()[1].flags
      desktop.RenameSelection("SOME.NEW.NAME")
      -- TODO: Would be better to test behavior rather than internal state.
      test.ExpectEquals(desktop.GetSelectedIcons()[1].flags, flags, "flags should not have changed")
      desktop.EraseVolume("RAM1")
    end
end)
