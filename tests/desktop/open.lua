--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 scsi"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)

--[[
  Open a volume with double-click.

  Launch DeskTop. Double-click a volume. Verify that the volume icon
  is still selected.
]]
test.Step(
  "Open volume with double-click",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(icon_x, icon_y)
        m.DoubleClick()
        a2d.WaitForRepaint()
    end)

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be on top")
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(a2d.GetSelectedIcons()[1].name, "A2.DESKTOP", "clicked icon should be selected")
    test.Expect(a2d.GetSelectedIcons()[1].dimmed, "selected icon should be dimmed")

    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

--[[
  Open a directory with double-click.

  Launch DeskTop. Double-click a folder. Verify that the folder icon
  is still selected.

  Launch DeskTop. Open a window containing a folder. Position the
  window so that the folder icon will not be obscured when opened.
  Double-click the folder. Verify that the folder icon is dimmed but
  still selected.
]]
test.Step(
  "Open folder with double-click",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")
    a2d.MoveWindowBy(0,80) -- ensure icon remains visible

    a2d.InMouseKeysMode(function(m)
        local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
        m.MoveToApproximately(icon_x, icon_y)
        m.DoubleClick()
    end)
    a2d.WaitForRepaint()

    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be on top")
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(a2d.GetSelectedIcons()[1].name, "EXTRAS", "clicked icon should be selected")
    test.Expect(a2d.GetSelectedIcons()[1].dimmed, "selected icon should be dimmed")

    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

--[[
  Open a text file with double-click.
]]
test.Step(
  "Open text file with double-click",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")

    a2d.InMouseKeysMode(function(m)
        local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
        m.MoveToApproximately(icon_x, icon_y)
        m.DoubleClick()
    end)
    a2d.WaitForRepaint()

    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "READ.ME", "folder window should be on top")
    a2d.CloseWindow() -- Preview
    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

--[[
  Open a volume with File > Open.

  Launch DeskTop. Select a volume. File > Open. Verify that the volume
  icon is dimmed but still selected.
]]
test.Step(
  "Open volume with File > Open",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_OPEN-1)

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be on top")
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(a2d.GetSelectedIcons()[1].name, "A2.DESKTOP", "clicked icon should be selected")
    test.Expect(a2d.GetSelectedIcons()[1].dimmed, "selected icon should be dimmed")

    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

--[[
  Open a directory with File > Open.

  Launch DeskTop. Select a folder. File > Open. Verify that the folder
  icon is dimmed but still selected.

  Launch DeskTop. Open a window containing a folder. Position the
  window so that the folder icon will not be obscured when opened.
  Select the folder. File > Open. Verify that the folder icon is
  dimmed but still selected.
]]
test.Step(
  "Open folder with File > Open",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")
    a2d.MoveWindowBy(0,80) -- ensure icon remains visible
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_OPEN)

    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be on top")
    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(a2d.GetSelectedIcons()[1].name, "EXTRAS", "clicked icon should be selected")
    test.Expect(a2d.GetSelectedIcons()[1].dimmed, "selected icon should be dimmed")

    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

--[[
  Open a text file with File > Open.
]]
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

--[[
  Launch DeskTop. Select a volume icon. Open it. Verify that the open
  animation starts at the icon location.
]]
test.Step(
  "Open - animation runs",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    a2d.OAShortcut("O", {no_wait=true})
    a2dtest.MultiSnap(120, "verify open animation starts at volume icon")
    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

--[[
  Launch DeskTop. Close all windows. Open an empty volume (e.g.
  `/RAMA`). Repeat File > New Folder... 7 times, accepting the default
  names (New.Folder through New.Folder.7). Edit > Select All. File >
  Open. File > New Folder. Verify that the new folder is created
  within New.Folder.7 and no alert appears.
]]
test.Step(
  "Open multiple",
  function()
    a2d.OpenPath("/RAM1")
    for i = 1, 7 do
      a2d.OAShortcut("N") -- File > New Folder
      apple2.ReturnKey() -- accept default name
      a2d.WaitForRepaint()
    end

    -- Close and re-open so they are visible
    a2d.CloseWindow()
    a2d.OpenPath("/RAM1")
    a2d.MoveWindowBy(0,80)
    a2d.SelectAll()
    a2d.OpenSelection()
    emu.wait(5)

    test.ExpectEquals(a2dtest.GetWindowCount(), 8, "8 windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "NEW.FOLDER.7", "folder name should be New.Folder.7")

    test.ExpectEquals(#a2d.GetSelectedIcons(), 7, "second icon should still be selected")
    for i = 1, 7 do
      test.Expect(a2d.GetSelectedIcons()[i].dimmed, "selected icon should be dimmed")
    end

    a2d.CloseAllWindows()
    emu.wait(5)

    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    a2d.DeleteSelection()
    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

--[[
  Configure a system with `/HD1`, `/HD1/FOLDER1`, and `/HD2`. Launch
  DeskTop. Open `/HD1`. Open `/HD1/FOLDER1`. Close `/HD1`. Open
  `/HD2`. Re-open `/HD1`. Re-open `/HD/FOLDER1`. Verify that the
  previously opened window is activated.
]]
test.Step(
  "Reactivating windows",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    local vol_icon_x, vol_icon_y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

    a2d.SelectPath("/RAM1")
    local vol_icon2_x, vol_icon2_y = a2dtest.GetSelectedIconCoords()
    a2d.ClearSelection()

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

--[[
  Launch DeskTop. Open a window and select multiple folder icons. File
  > Open. Verify that the folders open, and that the icons remain
  selected and become dimmed.
]]
test.Step(
  "Open multiple - menu",
  function()
    a2d.OpenPath("/RAM1")

    a2d.OAShortcut("N") -- File > New Folder
    apple2.ReturnKey() -- accept default name
    a2d.WaitForRepaint()

    a2d.OAShortcut("N") -- File > New Folder
    apple2.ReturnKey() -- accept default name
    a2d.WaitForRepaint()
    a2d.MoveWindowBy(0,80)

    -- Select multiple and File > Open
    a2d.SelectAll()
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_OPEN)
    emu.wait(5)

    test.ExpectEquals(a2dtest.GetWindowCount(), 3, "3 windows should be open")
    test.ExpectEquals(#a2d.GetSelectedIcons(), 2, "two icons should be selected")
    for i = 1, 2 do
      test.Expect(a2d.GetSelectedIcons()[i].dimmed, "selected icon should be dimmed")
    end

    a2d.CloseAllWindows()
    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    a2d.DeleteSelection()
    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

--[[
  Launch DeskTop. Select two volume icons. Double-click one of the
  volume icons. Verify that two windows open.
]]
test.Step(
  "Open multiple volumes - double-click",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    local icon1_x, icon1_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/RAM1")
    local icon2_x, icon2_y = a2dtest.GetSelectedIconCoords()

    a2d.ClearSelection()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(icon1_x, icon1_y)
        m.Click()

        m.MoveToApproximately(icon2_x, icon2_y)
        apple2.PressOA()
        m.Click()
        apple2.ReleaseOA()

        m.MoveToApproximately(icon1_x, icon1_y)
        m.DoubleClick()
    end)
    emu.wait(5)

    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "2 windows should be open")
end)

--[[
  Launch DeskTop. Open a window. Select two folder icons. Double-click
  one of the folder icons. Verify that two windows open.
]]
test.Step(
  "Open multiple - double-click",
  function()
    a2d.OpenPath("/RAM1")

    a2d.OAShortcut("N") -- File > New Folder
    apple2.ReturnKey() -- accept default name
    a2d.WaitForRepaint()

    a2d.OAShortcut("N") -- File > New Folder
    apple2.ReturnKey() -- accept default name
    a2d.WaitForRepaint()
    a2d.MoveWindowBy(0,80)

    -- Select multiple and double-click
    a2d.SelectAll()

    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.DoubleClick()
    end)
    emu.wait(5)

    test.ExpectEquals(a2dtest.GetWindowCount(), 3, "3 windows should be open")
    test.ExpectEquals(#a2d.GetSelectedIcons(), 2, "two icons should be selected")
    for i = 1, 2 do
      test.Expect(a2d.GetSelectedIcons()[i].dimmed, "selected icon should be dimmed")
    end

    a2d.CloseAllWindows()
    a2d.OpenPath("/RAM1")
    a2d.SelectAll()
    a2d.DeleteSelection()
    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)

--[[
  Launch DeskTop. Open a window. Select a folder icon. Open the File
  menu, then press Solid-Apple+O. Verify that the folder opens, and
  the original window remains open. Repeat with Caps Lock off.

  Launch DeskTop. Open a window. Select a folder icon. Open the File
  menu, then press Open-Apple+O. Verify that the folder opens, and the
  original window remains open. Repeat with Caps Lock off.
]]
test.Variants(
  {
    {"With menu showing, Open Apple + O", a2d.OAShortcut, "O"},
    {"With menu showing, Solid Apple + O", a2d.SAShortcut, "O"},
    {"With menu showing, Open Apple + o", a2d.OAShortcut, "o"},
    {"With menu showing, Solid Apple + o", a2d.SAShortcut, "o"},
  },
  function(idx, name, func, key)
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")
    local menu_x, menu_y = 30, 5
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(menu_x, menu_y)
        m.Click()
    end)

    func(key)
    emu.wait(5)

    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")

    a2d.CloseAllWindows()
    a2d.ClearSelection()
end)
