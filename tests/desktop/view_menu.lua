--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

  ======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(2)

--[[
  Open folder with files. View > by Date. Verify that DeskTop does not
  hang.
]]
test.Step(
  "View by Date - doesn't hang",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_DATE)
    a2d.WaitForRepaint()
    test.Snap("verify no hang")
    a2d.CloseAllWindows()
end)

--[[
  Open folder with new files. Use View > by Date; verify dates after
  1999 show correctly.
]]
test.Step(
  "View by Date - Y2K",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_DATE)
    a2d.WaitForRepaint()
    test.Snap("verify dates after 1999 show correctly")
    a2d.CloseAllWindows()
end)

--[[
  Open folder with new files. Use View > by Date. Verify that two
  files modified on the same date are correctly ordered by time.
]]
test.Step(
  "View by Date - Secondarily sorted by time",
  function()
    a2d.OpenPath("/TESTS/VIEW/BY.DATE")
    a2d.GrowWindowBy(300, 0)
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_DATE)
    a2d.WaitForRepaint()
    test.Snap("verify same dates sort by time")
    a2d.CloseAllWindows()
end)

--[[
  Open folder with zero files. Use View > by Name. Verify that there
  is no crash.
]]
test.Step(
  "View by Name - Empty folder doesn't crash",
  function()
    a2d.OpenPath("/TESTS/VIEW/BY.NAME/EMPTY")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.WaitForRepaint()
    test.Snap("verify no crash")
    a2d.CloseAllWindows()
end)

--[[
  Open folder with one file. Use View > by Name. Verify that the entry
  paints correctly.
]]
test.Step(
  "View by Name - Folder with 1 file paints correctly",
  function()
    a2d.OpenPath("/TESTS/VIEW/BY.NAME/ONE.FILE")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.WaitForRepaint()
    test.Snap("verify paints correctly")
    a2d.CloseAllWindows()
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
    a2d.OpenPath("/TESTS/VIEW/BY.NAME/LONG.MONTHS")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.WaitForRepaint()
    local arrow_x, arrow_y = a2dtest.GetFrontWindowRightScrollArrowCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(arrow_x, arrow_y)
        for i=1,20 do
          m.Click()
        end
    end)
    test.Snap("verify date not cut off on right")
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window containing a folder. View > by Name.
  Open the folder. Verify that in the new window, the horizontal
  scrollbar is inactive.
]]
test.Step(
  "View by Name - Child windows resized to fit",
  function()
    a2d.OpenPath("/TESTS/VIEW/BY.NAME")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.SelectAndOpen("LONG.MONTHS")
    a2d.WaitForRepaint()
    test.Snap("verify no horizontal scrollbar")
    a2d.CloseAllWindows()
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
    a2d.SelectPath("/A2.DESKTOP")
    local vol_icon_x, vol_icon_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/TESTS")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon_x, vol_icon_y)
        m.DoubleClick()
    end)
    a2d.SelectAndOpen("APPLE.MENU")
    a2d.SelectAndOpen("CONTROL.PANELS")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.CloseWindow()
    test.Snap("verify no crash")
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a volume window. Open a folder window. View >
  by Name. Verify that the selection is still in the volume window,
  and that there is no selection in the folder window.
]]
test.Step(
  "View by Name - Selection unchanged in volume",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.SelectAndOpen("APPLE.MENU")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.MoveWindowBy(0,100)
    test.Snap("verify selection still in volume window")
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a volume window. Open a folder window. Select a
  file in the folder window. View > by Name. Verify that the selection
  is still in the folder window.
]]
test.Step(
  "View by Name - Selection unchanged in folder",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.SelectAndOpen("APPLE.MENU")
    apple2.DownArrowKey()
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.MoveWindowBy(0,100)
    test.Snap("verify selection still in folder window")
    a2d.CloseAllWindows()
end)

a2d.AddShortcut("/A2.DESKTOP")

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
    a2d.OpenPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, idx)
    a2d.DialogCancel()
    test.Snap("verify window correctly repaints")
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. On a volume, create folders named "A1", "B1", "A",
  and "B". View > by Name. Verify that the order is: "A", "A1", "B",
  "B1".
]]
test.Step(
  "View by Name - Ordering",
  function()
    a2d.OpenPath("/TESTS/VIEW/BY.NAME/A1.B1.A.B")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.GrowWindowBy(100,20)
    test.Snap("verify order is A, A1, B, B1")
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open `/TESTS/FILE.TYPES`. View > by Type. Verify
  that the files are sorted by type name, first alphabetically
  followed by $XX types in numeric order.
]]
test.Step(
  "View by Type - Ordering",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_TYPE)
    test.Snap("verify sorted by type alpha then $XX")
    for i=1,20 do
      apple2.DownArrowKey()
      a2d.WaitForRepaint()
    end
    test.Snap("verify sorted by type alpha then $XX")
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window containing multiple files. View > by
  Size. Verify that the files are sorted by size in descending order,
  with directories at the end.
]]
test.Step(
  "View by Size - Ordering",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_SIZE)
    test.Snap("verify sorted large to small then dirs")
    for i=1,20 do
      apple2.DownArrowKey()
      a2d.WaitForRepaint()
    end
    test.Snap("verify sorted large to small then dirs")
    a2d.CloseAllWindows()
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
    a2d.SelectPath("/A2.DESKTOP")
    local vol_icon_x, vol_icon_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/TESTS/VIEW/DRAGGING")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)

    local window_x,window_y = a2dtest.GetFrontWindowContentRect()

    a2d.ClearSelection()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(window_x+11, window_y+21)
        m.Click()
        a2d.WaitForRepaint()
    end)
    test.Snap("verify clicking bitmap selects")

    a2d.ClearSelection()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(window_x+35, window_y+21)
        m.Click()
        a2d.WaitForRepaint()
    end)
    test.Snap("verify clicking name selects")

    a2d.ClearSelection()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(window_x+35, window_y+21)
        m.ButtonDown()
        m.MoveToApproximately(vol_icon_x, vol_icon_y)
        m.ButtonUp()
        a2dtest.MultiSnap(30, "verify drag to other volume icon initiates copy")
    end)
    emu.wait(10) -- wait for copy

    a2d.ClearSelection()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(window_x+35, window_y+18)
        m.ButtonDown()
        m.MoveByApproximately(0, 12)
        a2d.WaitForRepaint()
        test.Snap("verify dragging over folder icon highlights")
        m.ButtonUp()
        emu.wait(20/60)
        test.Snap("verify drop on folder icon initiates move")
    end)
    emu.wait(10) -- wait for move

    a2d.CloseAllWindows()
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
    a2d.OpenPath("/TESTS/VIEW/DRAGGING")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)

    apple2.DownArrowKey() -- select first item
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
            a2d.WaitForRepaint()
            m.Home()
        end)
    end)

    a2d.CloseAllWindows()
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
    a2d.OpenPath("/TESTS/VIEW/RENAME.REFRESH")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.Select("ANTEATER")
    a2d.RenameSelection("YAK")
    test.Snap("verify selection retained, in order, and in view")
    a2d.CloseAllWindows()
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
    a2d.OpenPath("/TESTS/VIEW")
    a2d.SelectAndOpen("RENAME.REFRESH")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.Select("BUNYIP")
    a2d.CycleWindows()
    a2d.MoveWindowBy(0,100)
    a2d.RenameSelection("ZEBRA")
    test.Snap("verify selection retained, in order, and in view")
    a2d.CloseAllWindows()
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
    a2d.OpenPath("/TESTS")
    a2d.SelectAndOpen("ALIASES")
    a2d.CycleWindows()
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    test.Snap("verify folder icon is dimmed")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_AS_ICONS)
    test.Snap("verify folder icon is still dimmed")
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window containing a folder. View > by Name.
  Verify that the volume's icon is dimmed. View > as Icon. Verify that
  the volume's icon is still dimmed.
]]
test.Step(
  "Volume icons stay dimmed",
  function()
    a2d.OpenPath("/TESTS")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    test.Snap("verify volume icon is dimmed")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_AS_ICONS)
    test.Snap("verify volume icon is still dimmed")
    a2d.CloseAllWindows()
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
    a2d.SelectPath("/A2.DESKTOP")
    local vol_icon_x, vol_icon_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/TESTS")
    test.Snap("verify icon view")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.SelectAndOpen("FILE.TYPES")
    test.Snap("verify name view")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon_x, vol_icon_y)
        m.DoubleClick()
        a2d.WaitForRepaint()
    end)
    test.Snap("verify icon view")
    a2d.CloseAllWindows()
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
    a2d.OpenPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_AS_SMALL_ICONS)
    a2d.SelectAndOpen("APPLE.MENU")
    a2d.SelectAndOpen("CONTROL.PANELS")
    test.Snap("verify small icon view")
    a2d.CycleWindows()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    test.Snap("verify small icon view")
    a2d.CloseAllWindows()
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
    a2d.SelectPath("/A2.DESKTOP")
    local vol_icon_x, vol_icon_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/TESTS")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon_x, vol_icon_y)
        m.Click()
    end)
    a2d.SelectAll()
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    test.Snap("verify volume icons still selected")
    a2d.OAShortcut("I") -- File > Get Info
    emu.wait(10)
    test.Snap("verify File > Get File Info show volume info")
    a2d.DialogCancel()
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_AS_ICONS)
    test.Snap("verify volume icons still selected")
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window containing file icons. Select one or
  more file icons in the window. Select a different View option.
  Verify that the icons in the window remain selected.
]]
test.Step(
  "File icon selection retained",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.SelectAll()
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    test.Snap("verify file icons still selected")
    a2d.CloseAllWindows()
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
    a2d.OpenPath("/TESTS/VIEW/SELECTION.ORDER")

    a2d.Select("ONE")
    local x1, y1 = a2dtest.GetSelectedIconCoords()
    a2d.Select("TWO")
    local x2, y2 = a2dtest.GetSelectedIconCoords()
    a2d.Select("THREE")
    local x3, y3 = a2dtest.GetSelectedIconCoords()
    a2d.Select("FOUR")
    local x4, y4 = a2dtest.GetSelectedIconCoords()
    a2d.Select("FIVE")
    local x5, y5 = a2dtest.GetSelectedIconCoords()
    a2d.Select("SIX")
    local x6, y6 = a2dtest.GetSelectedIconCoords()

    a2d.ClearSelection()

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
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.SORT_DIRECTORY)
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_AS_ICONS)
    test.Snap("verify sorted order")
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window containing file icons. Select one or
  more volume icons on the desktop. Select a different View option.
  Verify that the volume icons on the desktop remain selected.
]]
test.Step(
  "Volume icon selection",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    local vol_icon_x, vol_icon_y = a2dtest.GetSelectedIconCoords()

    a2d.OpenPath("/TESTS")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon_x, vol_icon_y)
        m.Click()
    end)
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    test.Snap("verify A2.DESKTOP volume icon still selected")
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window. Verify that the appropriate View
  option is checked. Close the window. Verify that the View menu items
  are all disabled, and that none are checked.
]]
test.Step(
  "View menu item states",
  function()
    a2d.OpenPath("/TESTS")
    a2d.OpenMenu(a2d.VIEW_MENU)
    test.Snap("verify 'by icon' is checked")
    apple2.EscapeKey()
    a2d.CloseAllWindows()
    a2d.OpenMenu(a2d.VIEW_MENU)
    test.Snap("verify all menu items disabled")
end)
