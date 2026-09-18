--[[
  Launch DeskTop. Open a volume window. Open a folder. Close the
  volume window. Press Open-Apple+Up. Verify that the volume window
  re-opens, and that the folder icon is selected. Press Open-Apple+Up
  again. Verify that the volume icon is selected.
]]
test.Step(
  "Open enclosing folder",
  function()
    desktop.OpenWindow("/A2.DESKTOP/APPLE.MENU", {leave_parent=true})
    desktop.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be on top")
    desktop.CloseWindow()
    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")

    a2d.OAUp()
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be open again")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "APPLE.MENU", "folder icon should be selected")

    a2d.OAUp()
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be selected")

    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a volume window. Open a folder. Press
  Open-Apple+Up. Verify that the volume window is activated, and that
  the folder icon is selected. Press Open-Apple+Up again. Verify that
  the volume icon is selected.
]]
test.Step(
  "Reactivate existing window",
  function()
    desktop.OpenWindow("/A2.DESKTOP/APPLE.MENU", {leave_parent=true})
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")

    a2d.OAUp()
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be open again")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "APPLE.MENU", "folder icon should be selected")

    a2d.OAUp()
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be selected")

    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a volume window. Open a folder. Activate the
  volume window. Switch the window's view to by Name. Activate the
  folder window. Press Open-Apple+Up. Verify that the volume window is
  activated, and that the folder icon is selected. Press Open-Apple+Up
  again. Verify that the volume icon is selected.
]]
test.Step(
  "View change",
  function()
    desktop.OpenWindow("/A2.DESKTOP/APPLE.MENU", {leave_parent=true})
    desktop.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be on top")
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
    desktop.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "APPLE.MENU", "folder window should be on top")

    a2d.OAUp()
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be open again")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "APPLE.MENU", "folder icon should be selected")

    a2d.OAUp()
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "A2.DESKTOP", "volume icon should be selected")

    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a volume window with multiple files. Open a
  folder. Press Open-Apple+Up. Verify that the volume window is shown
  and the folder is selected. Press Right Arrow. Verify that only a
  single icon shows as selected.
]]
test.Step(
  "Icon selection with keyboard",
  function()
    desktop.OpenWindow("/A2.DESKTOP/APPLE.MENU", {leave_parent=true})

    a2d.OAUp()
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be open again")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "APPLE.MENU", "folder icon should be selected")

    apple2.RightArrowKey()
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "single icon should be selected")

    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a volume window with multiple files. Open a
  folder. Close the volume window. Press Open-Apple+Up. Verify that
  the volume window is shown and the folder is selected. Press Right
  Arrow. Verify that only a single icon shows as selected.
]]
test.Step(
  "Icon selection with keyboard with window cycling",
  function()
    desktop.OpenWindow("/A2.DESKTOP/APPLE.MENU")

    a2d.OAUp()
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be open again")
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "APPLE.MENU", "folder icon should be selected")

    apple2.RightArrowKey()
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "single icon should be selected")

    desktop.CloseAllWindows()
end)

