--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

  ======================================== ENDCONFIG ]]--

test.Step(
  "View by Date - doesn't hang",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_DATE)
    a2d.WaitForRepaint()
    test.Snap("verify no hang")
    a2d.CloseAllWindows()
end)

test.Step(
  "View by Date - Y2K",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_DATE)
    a2d.WaitForRepaint()
    test.Snap("verify dates after 1999 show correctly")
    a2d.CloseAllWindows()
end)

test.Step(
  "View by Date - Secondarily sorted by time",
  function()
    a2d.OpenPath("/TESTS/VIEW/BY.DATE")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_DATE)
    a2d.WaitForRepaint()
    test.Snap("verify same dates sort by time")
    a2d.CloseAllWindows()
end)

test.Step(
  "View by Name - Empty folder doesn't crash",
  function()
    a2d.OpenPath("/TESTS/VIEW/BY.NAME/EMPTY")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.WaitForRepaint()
    test.Snap("verify no crash")
    a2d.CloseAllWindows()
end)

test.Step(
  "View by Name - Folder with 1 file paints correctly",
  function()
    a2d.OpenPath("/TESTS/VIEW/BY.NAME/ONE.FILE")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.WaitForRepaint()
    test.Snap("verify paints correctly")
    a2d.CloseAllWindows()
end)

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

local vol_icon_x = 520
local vol_icon_y = 25

test.Step(
  "View by Name - No crash",
  function()
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

test.Step(
  "View by Name - Selection unchanged",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.SelectAndOpen("APPLE.MENU")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.MoveWindowBy(0,100)
    test.Snap("verify selection still in volume window")
    a2d.CloseAllWindows()
end)

a2d.AddShortcut("/A2.DESKTOP")

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

test.Step(
  "View by Name - Ordering",
  function()
    a2d.OpenPath("/TESTS/VIEW/BY.NAME/A1.B1.A.B")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.GrowWindowBy(100,20)
    test.Snap("verify order is A, A1, B, B1")
    a2d.CloseAllWindows()
end)

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

test.Step(
  "Icons in list can be selected and dragged",
  function()
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
        emu.wait(20/60)
        test.Snap("verify drag to other volume icon initiates copy")
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

test.Step(
  "Icons in list view don't move",
  function()
    a2d.OpenPath("/TESTS/VIEW/DRAGGING")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(30, 45)
        m.ButtonDown()
        m.MoveByApproximately(100, 0)
        m.ButtonUp()
        a2d.WaitForRepaint()
    end)
    test.Snap("verify icon did not move")
    a2d.CloseAllWindows()
end)

test.Step(
  "Rename causes refresh",
  function()
    a2d.OpenPath("/TESTS/VIEWS/.REFRESH")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.Select("ANTEATER")
    a2d.RenameSelection("YAK")
    test.Snap("verify selection retained, in order, and in view")
    a2d.CloseAllWindows()
end)

test.Step(
  "Rename causes refresh with two windows",
  function()
    a2d.OpenPath("/TESTS/VIEWS")
    a2d.SelectAndOpen("RENAME.REFRESH")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.Select("BUNYIP")
    a2d.CycleWindows()
    a2d.MoveWindowBy(0,100)
    a2d.RenameSelection("ZEBRA")
    test.Snap("verify selection retained, in order, and in view")
    a2d.CloseAllWindows()
end)

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

test.Step(
  "Volumes default to icon",
  function()
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

test.Step(
  "Volume icon selection and multiple view switches",
  function()
    a2d.OpenPath("/TESTS")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon_x, vol_icon_y)
        m.Click()
    end)
    a2d.SelectAll()
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    test.Snap("verify volume icons still selected")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)
    emu.wait(10)
    test.Snap("verify File > Get File Info show volume info")
    a2d.DialogCancel()
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_AS_ICONS)
    test.Snap("verify volume icons still selected")
    a2d.CloseAllWindows()
end)

test.Step(
  "File icon selection retained",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.SelectAll()
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    test.Snap("verify file icons still selected")
    a2d.CloseAllWindows()
end)

local file_row1 = 50
local file_row2 = 80
local file_col1 = 20
local file_col2 = 100
local file_col3 = 180
local file_col4 = 260
local file_col5 = 340

test.Step(
  "Selection order retained",
  function()
    a2d.OpenPath("/TESTS/VIEW/SELECTION.ORDER")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(file_col2, file_row1)
        m.Click()
        m.MoveToApproximately(file_col5, file_row1)
        m.OAClick()
        m.MoveToApproximately(file_col3, file_row1)
        m.OAClick()
        m.MoveToApproximately(file_col1, file_row2)
        m.OAClick()
        m.MoveToApproximately(file_col1, file_row1)
        m.OAClick()
        m.MoveToApproximately(file_col4, file_row1)
        m.OAClick()
    end)
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.SORT_DIRECTORY)
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_AS_ICONS)
    test.Snap("verify sorted order")
    a2d.CloseAllWindows()
end)

test.Step(
  "Volume icon selection",
  function()
    a2d.OpenPath("/TESTS")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon_x, vol_icon_y)
        m.Click()
    end)
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    test.Snap("verify A2.DESKTOP volume icon still selected")
    a2d.CloseAllWindows()
end)

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
