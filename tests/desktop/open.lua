--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 scsi"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

-- SCSI card required for CD Remote DA (default is CD-ROM at ID1)

--[[
  Open a volume with double-click.

  Launch DeskTop. Double-click a volume. Verify that the volume icon
  is still selected.
]]
test.Step(
  "Open volume with double-click",
  function()
    desktop.SelectPath("/A2.DESKTOP")
    local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
    desktop.ClearSelection()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(icon_x, icon_y)
        m.DoubleClick()
        a2dtest.WaitForSystemTask()
    end)

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be on top")
    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "A2.DESKTOP", "clicked icon should be selected")
    test.Expect(desktop.GetSelectedIcons()[1].dimmed, "selected icon should be dimmed")

    desktop.CloseAllWindows()
    desktop.ClearSelection()
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
    desktop.SelectPath("/A2.DESKTOP/EXTRAS")
    desktop.MoveWindowBy(0,80) -- ensure icon remains visible

    a2d.InMouseKeysMode(function(m)
        local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
        m.MoveToApproximately(icon_x, icon_y)
        m.DoubleClick()
    end)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be on top")
    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "EXTRAS", "clicked icon should be selected")
    test.Expect(desktop.GetSelectedIcons()[1].dimmed, "selected icon should be dimmed")

    desktop.CloseAllWindows()
    desktop.ClearSelection()
end)

--[[
  Open a text file with double-click.
]]
test.Step(
  "Open text file with double-click",
  function()
    desktop.SelectPath("/A2.DESKTOP/READ.ME")

    a2d.InMouseKeysMode(function(m)
        local icon_x, icon_y = a2dtest.GetSelectedIconCoords()
        m.MoveToApproximately(icon_x, icon_y)
        m.DoubleClick()
    end)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "READ.ME", "folder window should be on top")
    desktop.CloseWindow() -- Preview
    desktop.CloseAllWindows()
    desktop.ClearSelection()
end)

--[[
  Open a volume with File > Open.

  Launch DeskTop. Select a volume. File > Open. Verify that the volume
  icon is dimmed but still selected.
]]
test.Step(
  "Open volume with File > Open",
  function()
    desktop.SelectPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(desktop.FILE_MENU, desktop.FILE_OPEN-1)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be on top")
    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "A2.DESKTOP", "clicked icon should be selected")
    test.Expect(desktop.GetSelectedIcons()[1].dimmed, "selected icon should be dimmed")

    desktop.CloseAllWindows()
    desktop.ClearSelection()
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
    desktop.SelectPath("/A2.DESKTOP/EXTRAS")
    desktop.MoveWindowBy(0,80) -- ensure icon remains visible
    a2d.InvokeMenuItem(desktop.FILE_MENU, desktop.FILE_OPEN)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be on top")
    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "EXTRAS", "clicked icon should be selected")
    test.Expect(desktop.GetSelectedIcons()[1].dimmed, "selected icon should be dimmed")

    desktop.CloseAllWindows()
    desktop.ClearSelection()
end)

--[[
  Open a text file with File > Open.
]]
test.Step(
  "Open text file with File > Open",
  function()
    desktop.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(desktop.FILE_MENU, desktop.FILE_OPEN)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "READ.ME", "folder window should be on top")

    desktop.CloseWindow() -- Preview
    desktop.CloseAllWindows()
    desktop.ClearSelection()
end)

--[[
  Launch DeskTop. Select a volume icon. Open it. Verify that the open
  animation starts at the icon location.
]]
test.Step(
  "Open - animation runs",
  function()
    desktop.SelectPath("/A2.DESKTOP")
    a2d.OAShortcut("O", {no_wait=true})
    a2dtest.MultiSnap(120, "verify open animation starts at volume icon")
    desktop.CloseAllWindows()
    desktop.ClearSelection()
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
    desktop.OpenWindow("/RAM1")
    for i = 1, 7 do
      a2d.OAShortcut("N") -- File > New Folder
      apple2.ReturnKey() -- accept default name
      a2dtest.WaitForSystemTask()
    end

    -- Close and re-open so they are visible
    desktop.CloseWindow()
    desktop.OpenWindow("/RAM1")
    desktop.MoveWindowBy(0,80)
    desktop.SelectAll()
    desktop.OpenSelection()

    test.ExpectEquals(a2dtest.GetWindowCount(), 8, "8 windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "NEW.FOLDER.7", "folder name should be New.Folder.7")

    test.ExpectEquals(#desktop.GetSelectedIcons(), 7, "second icon should still be selected")
    for i = 1, 7 do
      test.Expect(desktop.GetSelectedIcons()[i].dimmed, "selected icon should be dimmed")
    end

    desktop.CloseAllWindows()
    a2dtest.WaitForSystemTask()

    desktop.OpenWindow("/RAM1")
    desktop.SelectAll()
    desktop.DeleteSelection()
    desktop.CloseAllWindows()
    desktop.ClearSelection()
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
    desktop.SelectPath("/A2.DESKTOP")
    local vol_icon_x, vol_icon_y = a2dtest.GetSelectedIconCoords()
    desktop.ClearSelection()

    desktop.SelectPath("/RAM1")
    local vol_icon2_x, vol_icon2_y = a2dtest.GetSelectedIconCoords()
    desktop.ClearSelection()

    desktop.OpenWindow("/A2.DESKTOP")
    desktop.Select("EXTRAS")
    a2d.InvokeMenuItem(desktop.FILE_MENU, desktop.FILE_OPEN)
    a2dtest.WaitForSystemTask()
    desktop.CycleWindows()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "2 windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be on top")
    a2d.InvokeMenuItem(desktop.FILE_MENU, desktop.FILE_CLOSE)
    a2dtest.WaitForSystemTask()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon2_x, vol_icon2_y)
        m.Click()
    end)

    a2d.InvokeMenuItem(desktop.FILE_MENU, desktop.FILE_OPEN)
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "2 windows should be open")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(vol_icon_x, vol_icon_y)
        m.Click()
    end)

    a2d.InvokeMenuItem(desktop.FILE_MENU, desktop.FILE_OPEN)
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(a2dtest.GetWindowCount(), 3, "3 windows should be open")

    desktop.Select("EXTRAS")
    a2d.InvokeMenuItem(desktop.FILE_MENU, desktop.FILE_OPEN)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(a2dtest.GetWindowCount(), 3, "3 windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "previously open window should be activated")

    desktop.CloseAllWindows()
    desktop.ClearSelection()
end)

--[[
  Launch DeskTop. Open a window and select multiple folder icons. File
  > Open. Verify that the folders open, and that the icons remain
  selected and become dimmed.
]]
test.Step(
  "Open multiple - menu",
  function()
    desktop.OpenWindow("/RAM1")

    a2d.OAShortcut("N") -- File > New Folder
    apple2.ReturnKey() -- accept default name
    a2dtest.WaitForSystemTask()

    a2d.OAShortcut("N") -- File > New Folder
    apple2.ReturnKey() -- accept default name
    a2dtest.WaitForSystemTask()
    desktop.MoveWindowBy(0,80)

    -- Select multiple and File > Open
    desktop.SelectAll()
    a2d.InvokeMenuItem(desktop.FILE_MENU, desktop.FILE_OPEN)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(a2dtest.GetWindowCount(), 3, "3 windows should be open")
    test.ExpectEquals(#desktop.GetSelectedIcons(), 2, "two icons should be selected")
    for i = 1, 2 do
      test.Expect(desktop.GetSelectedIcons()[i].dimmed, "selected icon should be dimmed")
    end

    desktop.CloseAllWindows()
    desktop.OpenWindow("/RAM1")
    desktop.SelectAll()
    desktop.DeleteSelection()
    desktop.CloseAllWindows()
    desktop.ClearSelection()
end)

--[[
  Launch DeskTop. Select two volume icons. Double-click one of the
  volume icons. Verify that two windows open.
]]
test.Step(
  "Open multiple volumes - double-click",
  function()
    desktop.SelectPath("/A2.DESKTOP")
    local icon1_x, icon1_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/RAM1")
    local icon2_x, icon2_y = a2dtest.GetSelectedIconCoords()

    desktop.ClearSelection()

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
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "2 windows should be open")
end)

--[[
  Launch DeskTop. Open a window. Select two folder icons. Double-click
  one of the folder icons. Verify that two windows open.
]]
test.Step(
  "Open multiple - double-click",
  function()
    desktop.OpenWindow("/RAM1")

    a2d.OAShortcut("N") -- File > New Folder
    apple2.ReturnKey() -- accept default name
    a2dtest.WaitForSystemTask()

    a2d.OAShortcut("N") -- File > New Folder
    apple2.ReturnKey() -- accept default name
    a2dtest.WaitForSystemTask()
    desktop.MoveWindowBy(0,80)

    -- Select multiple and double-click
    desktop.SelectAll()

    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.DoubleClick()
    end)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(a2dtest.GetWindowCount(), 3, "3 windows should be open")
    test.ExpectEquals(#desktop.GetSelectedIcons(), 2, "two icons should be selected")
    for i = 1, 2 do
      test.Expect(desktop.GetSelectedIcons()[i].dimmed, "selected icon should be dimmed")
    end

    desktop.CloseAllWindows()
    desktop.OpenWindow("/RAM1")
    desktop.SelectAll()
    desktop.DeleteSelection()
    desktop.CloseAllWindows()
    desktop.ClearSelection()
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
    desktop.SelectPath("/A2.DESKTOP/EXTRAS")

    local menu_x, menu_y
    a2dtest.OCRIterate(function(run, x, y)
        if run == "File" then
          menu_x, menu_y = x, y
          return false
        end
    end)

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(menu_x, menu_y)
        m.Click()
    end)

    func(key)
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "EXTRAS", "folder window should be open")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(0, 0)
    end)

    desktop.CloseAllWindows()
    desktop.ClearSelection()
end)
