--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Create a new folder (File > New Folder) - verify that it is selected
  / scrolled into view.
]]
test.Step(
  "New folders are scrolled into view",
  function()
    a2d.OpenPath("/TESTS")
    emu.wait(1)
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_NEW_FOLDER)
    emu.wait(1)
    apple2.ReturnKey() -- default name
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "NEW.FOLDER", "new folder should be selected")
    test.Snap("verify scrolled into view")
    a2d.DeletePath("/TESTS/NEW.FOLDER")
end)

--[[
  Select a file. File > Duplicate. Verify that the new file is
  selected / scrolled into view / prompting for rename.
]]
test.Step(
  "Duplicates are scrolled into view",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_DUPLICATE)
    a2d.ClearTextField()
    apple2.Type("DUPE")
    apple2.ReturnKey() -- commit
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "DUPE", "duplicate should be selected")
    test.Snap("verify scrolled into view")
    a2d.DeletePath("/A2.DESKTOP/DUPE")
end)

--[[
  Select a file, ensuring that the file's containing window's folder
  or volume icon is present. File > Duplicate. Verify that only the
  new file is selected, and not the parent window's folder or volume
  icon.
]]
test.Step(
  "Duplicates updates selection correctly",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_DUPLICATE)
    a2d.ClearTextField()
    apple2.Type("DUPE")
    apple2.ReturnKey() -- commit
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "DUPE", "duplicate should be selected")
    test.Snap("verify only one icon appears selected")
    a2d.DeletePath("/A2.DESKTOP/DUPE")
end)

--[[
  Launch DeskTop. Select an icon. File > Rename. Enter a new name.
  Press Return. Verify that the icon updates with the new name.
]]
test.Step(
  "Rename works",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_RENAME)
    a2d.ClearTextField()
    apple2.Type("NEW.NAME")
    apple2.ReturnKey() -- commit
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "NEW.NAME", "file should have new name")
    a2d.RenamePath("/A2.DESKTOP/NEW.NAME", "READ.ME")
end)

--[[
  Launch DeskTop. Select an icon. File > Rename. Enter a new name.
  Press Escape. Verify that the icon doesn't change.
]]
test.Step(
  "Aborting rename works",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    apple2.ReturnKey() -- File > Rename
    a2d.ClearTextField()
    apple2.Type("NEW.NAME")
    apple2.EscapeKey()
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "file should have old name")
end)

--[[
  Launch DeskTop. Select an icon. File > Rename. Enter a new name.
  Click away. Verify that the icon updates with the new name.
]]
test.Step(
  "Clicking away to commit works",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    apple2.ReturnKey() -- File > Rename
    a2d.ClearTextField()
    apple2.Type("NEW.NAME")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(0, apple2.SCREEN_HEIGHT)
        m.Click()
    end)

    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "NEW.NAME", "file should have new name")
    a2d.RenamePath("/A2.DESKTOP/NEW.NAME", "READ.ME")
end)

--[[
  Launch DeskTop. Select an icon. File > Rename. Make the name empty.
  Press Return. Verify that the icon doesn't change.
]]
test.Step(
  "Trying to commit rename while empty is no-op",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    apple2.ReturnKey() -- File > Rename
    a2d.ClearTextField()
    apple2.ReturnKey() -- commit
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "file should have old name")
end)

--[[
  Launch DeskTop. Select an icon. File > Rename. Make the name empty.
  Press Escape. Verify that the icon doesn't change.
]]
test.Step(
  "Trying to abort rename while empty is no-op",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    apple2.ReturnKey() -- File > Rename
    a2d.ClearTextField()
    apple2.EscapeKey()
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "file should have old name")
end)

--[[
  Launch DeskTop. Select an icon. File > Rename. Make the name empty.
  Click away. Verify that the icon doesn't change.
]]
test.Step(
  "Clicking away while empty is no-op",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    apple2.ReturnKey() -- File > Rename
    a2d.ClearTextField()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(0, apple2.SCREEN_HEIGHT)
        m.Click()
    end)

    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "file should have old name")
end)

--[[
  Launch DeskTop. Select a file icon. File > Rename. Enter a unique
  name. Verify that the icon updates with the new name.
]]
test.Step(
  "Rename file icon works",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    apple2.ReturnKey() -- File > Rename
    a2d.ClearTextField()
    apple2.Type("NEW.NAME")
    apple2.ReturnKey() -- commit
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "NEW.NAME", "file should have new name")
    a2d.RenamePath("/A2.DESKTOP/NEW.NAME", "READ.ME")
end)

--[[
  Launch DeskTop. Select a file icon. File > Rename. Click away
  without changing the name. Verify that icon doesn't change.
]]
test.Step(
  "Clicking away without changing file icon name is okay",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    apple2.ReturnKey() -- File > Rename

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(0, apple2.SCREEN_HEIGHT)
        m.Click()
    end)

    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "file should have old name")
end)


--[[
  Launch DeskTop. Select a volume icon. File > Rename. Enter a unique
  name. Verify that the icon updates with the new name.
]]
test.Step(
  "Rename volume icon works",
  function()
    a2d.SelectPath("/TESTS")
    apple2.ReturnKey() -- File > Rename

    a2d.ClearTextField()
    apple2.Type("NEW.NAME")
    apple2.ReturnKey() -- commit
    emu.wait(5)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "NEW.NAME", "volume should have new name")
    a2d.RenamePath("/NEW.NAME", "TESTS")
end)

--[[
  Launch DeskTop. Select a volume icon. File > Rename. Click away
  without changing the name. Verify that the icon doesn't change.
]]
test.Step(
  "Clicking away without changing volume icon name is okay",
  function()
    a2d.SelectPath("/TESTS")
    apple2.ReturnKey() -- File > Rename
    a2d.WaitForRepaint()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(0, apple2.SCREEN_HEIGHT)
        m.Click()
    end)

    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "TESTS", "volume should have old name")
end)

--[[
  Repeat the following for volume icons and file icons:

  * Launch DeskTop. Select the icon. Click the icon's name. Verify
    that a rename prompt appears.

  * Launch DeskTop. Select the icon. Click the icon's bitmap. Verify
    that no rename prompt appears.

  * Launch DeskTop. With no selection, click the icon's name. Verify
    that no rename prompt appears.

  * Launch DeskTop. With multiple icons selected, click an icon's
    name. Verify that no rename prompt appears.
]]
test.Variants(
  {
    {"file icon hit testing", "/A2.DESKTOP/READ.ME"},
    {"volume icon hit testing", "/A2.DESKTOP"},
  },
  function(idx, name, path)
    a2d.SelectPath(path)
    local icons = a2d.GetSelectedIcons()
    test.Expect(#icons, 1, "only one icon should be selected")
    local icon = icons[1]

    -- click icon's name
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(icon.x+15, icon.y+22)
        m.Click()
    end)
    emu.wait(2)
    test.Snap("verify a rename prompt is visible")
    apple2.EscapeKey()

    -- click icon's bitmap
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(icon.x+15, icon.y+5)
        m.Click()
    end)
    emu.wait(2)
    test.Snap("verify no rename prompt is visible")

    -- with no selection, click icon's name
    a2d.ClearSelection()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(icon.x+15, icon.y+22)
        m.Click()
    end)
    emu.wait(2)
    test.Snap("verify no rename prompt is visible")

    -- with many icons selected, click icon's name
    a2d.SelectAll()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(icon.x+15, icon.y+22)
        m.Click()
    end)
    emu.wait(2)
    test.Snap("verify no rename prompt is visible")
end)

--[[
  Launch DeskTop. Select the Trash icon. Click the icon's name. Verify
  that no rename prompt appears.
]]
test.Step(
  "can't rename Trash",
  function()
    a2d.SelectPath("/Trash")
    local icons = a2d.GetSelectedIcons()
    test.Expect(#icons, 1, "only one icon should be selected")
    local icon = icons[1]
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(icon.x+15, icon.y+22)
        m.Click()
    end)
    emu.wait(2)
    test.Snap("verify no rename prompt is visible")
end)

--[[
  Launch DeskTop. Select a file icon. Position the window so that the
  icon is entirely off-screen. File > Rename. Press Escape to cancel.
  Verify that the window title bar activates and nothing mispaints on
  the desktop.
]]
test.Step(
  "rename obscured icon",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.MoveWindowBy(0, 190)
    a2dtest.ExpectNothingChanged(function()
        a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_RENAME)
        a2d.WaitForRepaint()
        apple2.EscapeKey()
        a2d.WaitForRepaint()
    end)
end)

--[[
  Launch DeskTop. Close all windows. Select a volume icon. Move the
  icon so that the name is entirely off-screen. File > Rename. Press
  Escape to cancel. Verify that nothing mispaints on the desktop.
]]
test.Step(
  "renaming an offscreen volume icon, no window open",
  function()
    a2d.SelectPath("/TESTS")
    local icons = a2d.GetSelectedIcons()
    test.Expect(#icons, 1, "only one icon should be selected")
    local icon = icons[1]
    a2d.Drag(icon.x+5, icon.y+5, 100, apple2.SCREEN_HEIGHT)
    a2d.WaitForRepaint()

    a2dtest.ExpectNothingChanged(function()
        apple2.ReturnKey() -- File > Rename
        emu.wait(1)
        apple2.EscapeKey() -- abort
    end)

    a2d.Reboot() -- get icon back where it belongs
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Open a window. Select a volume icon. Move the icon
  so that the name is entirely off-screen. File > Rename. Press Escape
  to cancel. Verify that the window title bar activates and nothing
  mispaints on the desktop.
]]
test.Step(
  "renaming an offscreen volume icon, window open",
  function()
    a2d.SelectPath("/TESTS")
    local icons = a2d.GetSelectedIcons()
    test.Expect(#icons, 1, "only one icon should be selected")
    local icon = icons[1]

    a2d.OpenSelection()

    a2d.Drag(icon.x+5, icon.y+5, 100, apple2.SCREEN_HEIGHT)
    a2d.WaitForRepaint()

    a2dtest.ExpectNothingChanged(function()
        apple2.ReturnKey() -- File > Rename
        emu.wait(1)
        apple2.EscapeKey() -- abort
        a2d.WaitForRepaint()
    end)

    a2d.Reboot() -- get icon back where it belongs
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Open two windows. Select a volume icon. Move the
  icon so that the name is entirely off-screen. File > Rename. Press
  Escape to cancel. Verify that the previously active window title bar
  is reactivated and that nothing mispaints on the desktop.
]]
test.Step(
  "renaming an offscreen volume icon, window open",
  function()
    a2d.SelectPath("/TESTS")
    local icons = a2d.GetSelectedIcons()
    test.Expect(#icons, 1, "only one icon should be selected")
    local icon = icons[1]

    a2d.CloseAllWindows()
    a2d.SelectAll()
    a2d.OpenSelection()
    a2d.ClearSelection()

    a2d.Drag(icon.x+5, icon.y+5, 100, apple2.SCREEN_HEIGHT)
    a2d.WaitForRepaint()

    a2dtest.ExpectNothingChanged(function()
        apple2.ReturnKey() -- File > Rename
        emu.wait(1)
        apple2.EscapeKey() -- abort
        a2d.WaitForRepaint()
    end)

    a2d.Reboot() -- get icon back where it belongs
    a2d.WaitForDesktopReady()
end)

--[[
  Repeat the following cases for File > New Folder, File > Rename, and
  File > Duplicate:

  * Launch DeskTop. Open a window and (if needed) select a file. Run
    the command. Enter a name, but place the caret in the middle of
    the name (e.g. "exam|ple"). Click away. Verify that the full name
    is used.
]]
test.Step(
  "caret in middle of name",
  function()
    a2d.OpenPath("/RAM1")

    -- New Folder
    a2d.OAShortcut("N") -- File > New Folder
    emu.wait(1)
    a2d.ClearTextField()
    apple2.Type("BEFORE.AFTER")
    apple2.LeftArrowKey()
    apple2.LeftArrowKey()
    apple2.LeftArrowKey()
    apple2.LeftArrowKey()
    apple2.LeftArrowKey()
    apple2.ReturnKey() -- commit
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "BEFORE.AFTER", "whole name should be used")

    -- Rename
    apple2.ReturnKey() -- File > Rename
    a2d.ClearTextField()
    apple2.Type("ALPHA.BETA")
    apple2.LeftArrowKey()
    apple2.LeftArrowKey()
    apple2.LeftArrowKey()
    apple2.LeftArrowKey()
    apple2.ReturnKey() -- commit
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "ALPHA.BETA", "whole name should be used")

    -- Duplicate
    a2d.OAShortcut("D") -- File > Duplicate
    emu.wait(1)
    a2d.ClearTextField()
    apple2.Type("GAMMA.DELTA")
    apple2.LeftArrowKey()
    apple2.LeftArrowKey()
    apple2.LeftArrowKey()
    apple2.LeftArrowKey()
    apple2.ReturnKey() -- commit
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "GAMMA.DELTA", "whole name should be used")

    a2d.EraseVolume("RAM1")
end)

--[[
  * Launch DeskTop. Open
    `/TESTS/ABCDEF123456789/ABCDEF123456789/ABCDEF123456789`. Use the
    command to try creating, duplicating, or renaming a folder within
    the nested folders that is longer than the path limit (e.g.
    `NAMEISTOOLARGE`). Verify that an error is shown but the dialog is
    not dismissed. Shorten the name under the length limit (e.g.
    `NAMEISOK`) and verify that the command is successful.
]]
test.Step(
  "overlong path",
  function()
    a2d.CreateFolder("/RAM1/ABDEF123456789")
    a2d.CreateFolder("/RAM1/ABDEF123456789/ABDEF123456789")
    a2d.CreateFolder("/RAM1/ABDEF123456789/ABDEF123456789/ABDEF123456789")
    a2d.OpenPath("/RAM1/ABDEF123456789/ABDEF123456789/ABDEF123456789")
    emu.wait(1)

    -- New Folder
    a2d.OAShortcut("N") -- File > New Folder
    a2d.ClearTextField()
    apple2.Type("NAMEISTOOLARGE")
    apple2.ReturnKey() -- try to commit
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    a2d.ClearTextField()
    apple2.Type("NAMEISOK")
    apple2.ReturnKey() -- commit
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "NAMEISOK", "shorter name should work")

    -- Rename
    apple2.ReturnKey() -- File > Rename
    a2d.ClearTextField()
    apple2.Type("NAMEISTOOLARGE")
    apple2.ReturnKey() -- try to commit
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    a2d.ClearTextField()
    apple2.Type("NAMEISOK")
    apple2.ReturnKey() -- commit
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "NAMEISOK", "shorter name should work")

    -- Duplicate
    a2d.OAShortcut("D")
    a2d.ClearTextField()
    apple2.Type("NAMEISTOOLARGE")
    apple2.ReturnKey() -- try to commit
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    a2d.ClearTextField()
    apple2.Type("NAME2ISOK")
    apple2.ReturnKey() -- commit
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "NAME2ISOK", "shorter name should work")

    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Open a volume. File > New Folder, create A. File >
  New Folder, create B. Drag B onto A. File > New Folder. Verify
  DeskTop doesn't hang.
]]
test.Step(
  "dragging folders",
  function()
    a2d.OpenPath("/RAM1")

    a2d.OAShortcut("N") -- File > New Folder
    apple2.ControlKey("X")
    apple2.Type("A")
    apple2.ReturnKey()
    emu.wait(1)

    a2d.OAShortcut("N") -- File > New Folder
    apple2.ControlKey("X")
    apple2.Type("B")
    apple2.ReturnKey()
    emu.wait(1)

    a2d.Select("A")
    local a_x, a_y = a2dtest.GetSelectedIconCoords()

    a2d.Select("B")
    local b_x, b_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(b_x, b_y, a_x, a_y)
    emu.wait(1)

    a2d.OAShortcut("N") -- File > New Folder
    apple2.ReturnKey()
    emu.wait(1)
    a2dtest.ExpectNotHanging()
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Try to rename a volume to have the same name as
  another. Verify that an error is shown.
]]
test.Step(
  "colliding volume names",
  function()
    a2d.SelectPath("/RAM1")
    apple2.ReturnKey()
    a2d.ClearTextField()
    apple2.Type("TESTS")
    apple2.ReturnKey() -- try to commit
    a2dtest.WaitForAlert() -- error
    a2d.DialogOK() -- dismiss
    apple2.EscapeKey() -- cancel
    emu.wait(1)
end)

--[[
  Launch DeskTop. Select a volume icon. File > Rename. Enter the name
  of another volume. Verify that a "That name already exists." alert
  is shown. Click OK. Verify that the rename prompt is still showing
  with the entered name and it is editable.
]]
test.Step(
  "colliding volume names - still editable",
  function()
    a2d.SelectPath("/RAM1")
    apple2.ReturnKey()
    a2d.ClearTextField()
    apple2.Type("TESTS")
    apple2.ReturnKey() -- try to commit
    a2dtest.WaitForAlert() -- error
    a2d.DialogOK() -- dismiss

    apple2.Type("2")
    apple2.ReturnKey()
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "TESTS2", "name should be accepted")

    a2d.RenamePath("/TESTS2", "RAM1")
end)

--[[
  Launch DeskTop. Open a window. Select a file icon. File > Rename.
  Enter the name of a file in the same window. Verify that a "That
  name already exists." alert is shown. Click OK. Verify that the
  rename prompt is still showing with the entered name and it is
  editable.
]]
test.Step(
  "colliding file names - still editable",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    apple2.ReturnKey()
    a2d.ClearTextField()
    apple2.Type("PRODOS")
    apple2.ReturnKey() -- try to commit
    a2dtest.WaitForAlert() -- error
    a2d.DialogOK() -- dismiss

    apple2.Type("2")
    apple2.ReturnKey()
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "PRODOS2", "name should be accepted")

    a2d.RenamePath("/A2.DESKTOP/PRODOS2", "READ.ME")
end)

--[[
  Launch DeskTop. Open a volume window. Open a folder window. Select
  the volume icon and rename it. Verify that neither window is closed,
  and volume window is renamed.
]]
test.Step(
  "windows renamed",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", {leave_parent=true})
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x+5, y+5)
        m.Click()
    end)
    apple2.ReturnKey() -- File > Rename
    a2d.ClearTextField()
    apple2.Type("NEW.NAME")
    apple2.ReturnKey() -- commit
    emu.wait(5)
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "both windows should still be open")
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "NEW.NAME", "volume window should be renamed")

    a2d.RenamePath("/NEW.NAME", "A2.DESKTOP")
end)

--[[
  Launch DeskTop. Open a volume window. Open a folder window. Activate
  the volume window. View > By Name. Select the folder icon. Rename
  it. Verify that the folder window is renamed.
]]
test.Step(
  "windows renamed, with a view switch",
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", {leave_parent=true})
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be active")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    emu.wait(1)
    a2d.Select("EXTRAS")
    apple2.ReturnKey() -- File > Rename
    a2d.ClearTextField()
    apple2.Type("NEW.NAME")
    apple2.ReturnKey() -- commit
    emu.wait(5)
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "both windows should still be open")
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "NEW.NAME", "folder window should be renamed")
    a2d.RenamePath("/A2.DESKTOP/NEW.NAME", "EXTRAS")
end)

--[[
  Launch DeskTop. Open a volume window. Position a file icon with a
  short name near the left edge of the window, but far enough away
  that the scrollbars are not active. Rename the file icon with a long
  name. Verify that the window's scrollbars activate.

  Launch DeskTop. Open a volume window. Position a file icon with a
  long name near the left edge of the window, so that the name is
  partially cut off and the scrollbars activate. Rename the file icon
  with a short name. Verify that the window's scrollbars deactivate.
]]
test.Step(
  "renaming can activate/deactivate scrollbars",
  function()
    a2d.OpenPath("/RAM1")

    a2d.CreateFolder("SHORT")

    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be inactive")

    a2d.RenameSelection("LONG.FILE.NAME")

    hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectNotEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be active")

    a2d.RenameSelection("SHORT")

    hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "scrollbar should be inactive")

    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Close all windows. Select a volume icon. File >
  Rename, enter a new name. Verify that there is no mis-painting of a
  scrollbar on the desktop.
]]
test.Step(
  "renaming volume doesn't mis-paint",
  function()
    a2d.RenamePath("/RAM1", "RAM1") -- avoid case issues
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(function()
        a2d.RenamePath("/RAM1", "NEW.NAME")
        a2d.RenamePath("/NEW.NAME", "RAM1")
        a2d.ClearSelection()
    end)
end)

--[[
  Launch DeskTop. Give a volume a long name (e.g. 15 'M's). Move the
  icon to the top third of the screen, and so that the name is
  partially offscreen to the right. Verify that the name is clipped by
  the right edge of the screen and doesn't mispaint on the left edge.
  Open the volume. Move the window so the name in the title bar is in
  the top third of the screen and partially offscreen to the right.
  Verify that the name is clipped and does not mispaint within the
  window.
]]
test.Step(
  "icon painting with long renames",
  function()
    a2d.RenamePath("/RAM1", "MMMMMMMMMMMMMMM")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(x+5, y+5, apple2.SCREEN_WIDTH, apple2.SCREEN_HEIGHT/6)
    a2d.WaitForRepaint()
    test.Snap("verify no mispaint on left edge of screen")

    a2d.OpenSelection()
    local x, y = a2dtest.GetFrontWindowDragCoords()
    a2d.Drag(x+5, y+5, apple2.SCREEN_WIDTH, apple2.SCREEN_HEIGHT/6)
    a2d.WaitForRepaint()
    test.Snap("verify no mispaint on left edge of screen")

    a2d.CloseAllWindows()
    a2d.RenamePath("/MMMMMMMMMMMMMMM", "RAM1")
    a2d.Reboot() -- put icon back where it belongs
    a2d.WaitForDesktopReady()
end)


--[[
  Launch DeskTop. Open a window. File > New Folder, enter a unique
  name. File > New Folder, enter the same name. Verify that an alert
  is shown. Dismiss the alert. Verify that the input field still has
  the previously typed name.
]]
test.Step(
  "new folder name collision retains what is typed",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.OAShortcut("N") -- File > New Folder
    a2d.ClearTextField()
    apple2.Type("PRODOS")
    apple2.ReturnKey() -- try to commit
    a2dtest.WaitForAlert()
    a2d.DialogOK() -- dismiss

    apple2.Type("2")
    apple2.ReturnKey() -- commit
    emu.wait(1)
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "PRODOS2", "previous typing should be retained")
    a2d.DeletePath("/A2.DESKTOP/PRODOS2")
end)

--[[
  Launch DeskTop. Open a window. File > New Folder, enter a unique
  name. File > New Folder, enter the same name. Verify that an alert
  is shown. Dismiss the alert. Enter a new unique name. Verify that
  the second folder is created as a sibling to the first folder, not
  as a child.
]]
test.Step(
  "new folder after collision doesn't end up as child",
  function()
    a2d.OpenPath("/RAM1")

    a2d.OAShortcut("N") -- File > New Folder
    a2d.ClearTextField()
    apple2.Type("NEW1")
    apple2.ReturnKey() -- commit
    emu.wait(1)

    a2d.OAShortcut("N") -- File > New Folder
    a2d.ClearTextField()
    apple2.Type("NEW1")
    apple2.ReturnKey() -- try to commit
    a2dtest.WaitForAlert()
    a2d.DialogOK() -- dismiss alert
    a2d.ClearTextField()
    apple2.Type("NEW2")
    apple2.ReturnKey() -- commit
    emu.wait(1)

    -- Verify that they end up as siblings
    a2d.OpenPath("/RAM1/NEW1")
    a2d.OpenPath("/RAM1/NEW2")

    a2d.EraseVolume("RAM1")
end)

--[[
  Repeat the following cases for File > New Folder, File > Duplicate,
  and File > Delete:

  Launch DeskTop. Open a window and (if needed) select a file. Run the
  command. Verify that when the window is refreshed, the scrollbars
  are inactive or at the top/left positions.
]]
test.Step(
  "scrollbar positions",
  function()
    local hscroll, vscroll, hthumbpos, vthumbpos

    a2d.OpenPath("/RAM1")
    a2d.OAShortcut("N") -- File > New Folder
    emu.wait(1)
    apple2.ReturnKey() -- accept default name
    emu.wait(1)

    hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    hthumbpos, vthumbpos = a2dtest.GetFrontWindowScrollPos()
    test.Expect(
      (hscroll & mgtk.scroll.option_active) == 0 or (hthumbpos == 0),
      "horizontal scrollbar should be inactive or at left")
    test.Expect(
      (vscroll & mgtk.scroll.option_active) == 0 or (vthumbpos == 0),
      "vertical scrollbar should be inactive or at top")

    a2d.OAShortcut("D") -- File > Duplicate
    emu.wait(1)
    apple2.ReturnKey() -- accept default name
    emu.wait(1)

    hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    hthumbpos, vthumbpos = a2dtest.GetFrontWindowScrollPos()
    test.Expect(
      (hscroll & mgtk.scroll.option_active) == 0 or (hthumbpos == 0),
      "horizontal scrollbar should be inactive or at left")
    test.Expect(
      (vscroll & mgtk.scroll.option_active) == 0 or (vthumbpos == 0),
      "vertical scrollbar should be inactive or at top")

    a2d.OADelete() -- File > Delete
    a2dtest.WaitForAlert() -- confirmation prompt
    a2d.DialogOK() -- confirm
    emu.wait(1)

    hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    hthumbpos, vthumbpos = a2dtest.GetFrontWindowScrollPos()
    test.Expect(
      (hscroll & mgtk.scroll.option_active) == 0 or (hthumbpos == 0),
      "horizontal scrollbar should be inactive or at left")
    test.Expect(
      (vscroll & mgtk.scroll.option_active) == 0 or (vthumbpos == 0),
      "vertical scrollbar should be inactive or at top")

    a2d.EraseVolume("RAM1")
end)

--[[
  Select a folder containing many files. File > Duplicate. During the
  initial count of the files, press Escape. Verify that the count is
  canceled and the progress dialog is closed, and that the window
  contents do not refresh.
]]
test.Step(
  "no name prompt and no refresh after early aborted duplicate",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")
    a2d.OAShortcut("D", {no_wait=true})
    emu.wait(0.1)
    apple2.EscapeKey()
    emu.wait(2)
    test.ExpectError(
      "Failed to select",
      function() a2d.SelectPath("/A2.DESKTOP/EXTRAS.2") end,
      "should not have created file")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Select a folder containing many files. File > Duplicate. After the
  initial count of the files is complete and the actual operation has
  started, press Escape. Verify that the operation is canceled and the
  progress dialog is closed, and that the window contents do refresh,
  but that no rename prompt appears.
]]
test.Step(
  "refresh but no name prompt after late aborted duplicate",
  function()
    a2d.SelectPath("/A2.DESKTOP/EXTRAS")
    a2d.OAShortcut("D", {no_wait=true})
    emu.wait(2)
    apple2.EscapeKey()
    emu.wait(2)
    a2d.Select("EXTRAS.2") -- ensure it was created and window refreshed
    a2d.DeletePath("/A2.DESKTOP/EXTRAS.2")
end)

--[[
  Make a copy of a `PRODOS` system file. Rename it to have a
  ".SYSTEM" suffix. Verify that it updates to have an application
  icon. Rename it again to remove the suffix. Verify that it updates
  to have a system file icon. Repeat several times. Verify that the
  icon has not shifted in position.
]]
test.Step(
  "renaming SYS file doesn't move it",
  function()
    a2d.CopyPath("/A2.DESKTOP/PRODOS", "/RAM1")
    a2d.SelectPath("/RAM1/PRODOS")
    a2d.RenameSelection("PRODOS") -- avoid case changing
    a2dtest.ExpectNothingChanged(function()
        for i = 1, 10 do
          a2d.RenameSelection("PRODOS.SYSTEM")
          a2d.RenameSelection("PRODOS")
        end
    end)
end)

