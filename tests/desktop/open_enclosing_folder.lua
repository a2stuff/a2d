a2d.ConfigureRepaintTime(1)

--[[
  Launch DeskTop. Open a volume window. Open a folder. Close the
  volume window. Press Open-Apple+Up. Verify that the volume window
  re-opens, and that the folder icon is selected. Press Open-Apple+Up
  again. Verify that the volume icon is selected.
]]
test.Step(
  "Open enclosing folder",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU", true)
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be on top")
    a2d.CloseWindow()
    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")

    a2d.OAUp()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be open again")
    test.Snap("verify folder icon is selected")

    a2d.OAUp()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.Snap("verify volume icon is selected")

    a2d.CloseAllWindows()
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
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU", true)
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")

    a2d.OAUp()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be open again")
    test.Snap("verify folder icon is selected")

    a2d.OAUp()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.Snap("verify volume icon is selected")

    a2d.CloseAllWindows()
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
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU", true)
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be on top")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "APPLE.MENU", "folder window should be on top")

    a2d.OAUp()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be open again")
    test.Snap("verify folder icon is selected")

    a2d.OAUp()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.Snap("verify volume icon is selected")

    a2d.CloseAllWindows()
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
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU", true)

    a2d.OAUp()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be open again")
    test.Snap("verify folder icon is selected")

    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify single icon is selected")

    a2d.CloseAllWindows()
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
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU")

    a2d.OAUp()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be open again")
    test.Snap("verify folder icon is selected")

    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify single icon is selected")

    a2d.CloseAllWindows()
end)

