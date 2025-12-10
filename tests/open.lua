local vol_icon_x, vol_icon_y = 520, 25 -- A2.DESKTOP
local vol_icon2_x, vol_icon2_y = 520, 55 -- RAM1
local folder_icon_x, folder_icon_y = 30, 60
local text_icon_x, text_icon_y = 200, 40

test.Step(
  "Open volume with double-click",
  function()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon_x, vol_icon_y)
        m.DoubleClick()
        a2d.WaitForRepaint()
    end)

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be on top")
    test.Snap("verify volume icon is selected and dimmed")

    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

test.Step(
  "Open folder with double-click",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.MoveWindowBy(0,80) -- ensure icon remains visible

    local window_x, window_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(window_x + folder_icon_x, window_y + folder_icon_y)
        m.DoubleClick()
    end)
    a2d.WaitForRepaint()

    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be on top")
    test.Snap("verify folder icon is selected and dimmed")

    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

test.Step(
  "Open text file with double-click",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    local window_x, window_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(window_x + text_icon_x, window_y + text_icon_y)
        m.DoubleClick()
    end)
    a2d.WaitForRepaint()

    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "READ.ME", "folder window should be on top")
    a2d.CloseWindow() -- Preview
    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

test.Step(
  "Open volume with File > Open",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_OPEN-1)

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be on top")
    test.Snap("verify volume icon is selected and dimmed")

    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

test.Step(
  "Open folder with File > Open",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")
    a2d.MoveWindowBy(0,80) -- ensure icon remains visible
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_OPEN)

    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be on top")
    test.Snap("verify folder icon is selected and dimmed")

    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

test.Step(
  "Open text file with File > Open",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_OPEN)

    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "READ.ME", "folder window should be on top")

    a2d.CloseWindow() -- Preview
    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

test.Step(
  "Open - animation runs",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    a2d.OpenMenu(a2d.FILE_MENU)
    apple2.DownArrowKey() -- File > Open
    apple2.ReturnKey()
    test.MultiSnap(15, "verify open animation starts at volume icon")
    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

test.Step(
  "Open multiple",
  function()
    a2d.OpenPath("/RAM1")
    for i = 1, 7 do
      a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_NEW_FOLDER)
      apple2.ReturnKey()
      a2d.WaitForRepaint()
    end

    -- Close and re-open so they are visible
    a2d.CloseWindow()
    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(0,80)
    a2d.SelectAll()
    a2d.OpenSelection()

    test.ExpectEquals(a2dtest.GetWindowCount(), 8, "8 windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "NEW.FOLDER.7", "folder name should be New.Folder.7")
    test.Snap("verify folder icons selected and dimmed")

    a2d.CloseAllWindows()
    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    a2d.DeleteSelection()
    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

test.Step(
  "Reactivating windows",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.Select("EXTRAS")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_OPEN)
    a2d.CycleWindows()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "2 windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be on top")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_CLOSE)

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon2_x, vol_icon2_y)
        m.Click()
    end)

    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_OPEN)
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "2 windows should be open")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon_x, vol_icon_y)
        m.Click()
    end)

    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_OPEN)
    test.ExpectEquals(a2dtest.GetWindowCount(), 3, "3 windows should be open")

    a2d.Select("EXTRAS")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_OPEN)

    test.ExpectEquals(a2dtest.GetWindowCount(), 3, "3 windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "previously open window should be activated")

    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

test.Step(
  "Open multiple - menu",
  function()
    a2d.OpenPath("/RAM1")

    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_NEW_FOLDER)
    apple2.ReturnKey()
    a2d.WaitForRepaint()

    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_NEW_FOLDER)
    apple2.ReturnKey()
    a2d.WaitForRepaint()
    a2d.MoveWindowBy(0,80)

    -- Select multiple and File > Open
    a2d.SelectAll()
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_OPEN)

    test.ExpectEquals(a2dtest.GetWindowCount(), 3, "3 windows should be open")
    test.Snap("verify folder icons selected and dimmed")

    a2d.CloseAllWindows()
    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    a2d.DeleteSelection()
    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

test.Step(
  "Open multiple - double-click",
  function()
    a2d.OpenPath("/RAM1")

    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_NEW_FOLDER)
    apple2.ReturnKey()
    a2d.WaitForRepaint()

    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_NEW_FOLDER)
    apple2.ReturnKey()
    a2d.WaitForRepaint()
    a2d.MoveWindowBy(0,80)

    -- Select multiple and double-click
    a2d.SelectAll()

    local window_x, window_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(window_x + 40, window_y + 30)
        m.DoubleClick()
    end)
    a2d.WaitForRepaint()

    test.ExpectEquals(a2dtest.GetWindowCount(), 3, "3 windows should be open")
    test.Snap("verify folder icons selected and dimmed")

    a2d.CloseAllWindows()
    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    a2d.DeleteSelection()
    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

test.Variants(
  {
    "With menu showing, Open Apple + O",
    "With menu showing, Solid Apple + O",
    "With menu showing, Open Apple + o",
    "With menu showing, Solid Apple + o",
  },
  function(idx)
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(30, 5)
        m.Click()
    end)

    local key = "O"
    if idx == 3 or idx == 4 then
      key = "o"
    end
    if idx == 1 or idx == 3 then
      a2d.OAShortcut(key)
    else
      a2d.SAShortcut(key)
    end
    a2d.WaitForRepaint()

    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")

    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)
