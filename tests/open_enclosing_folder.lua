
function OAUp()
  apple2.PressOA()
  apple2.UpArrowKey()
  emu.wait(1/60)
  apple2.ReleaseOA()
end

test.Step(
  "Open enclosing folder",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU", true)
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be on top")
    a2d.CloseWindow()
    test.ExpectEquals(a2dtest.GetWindowCount(), 1, "one window should be open")

    OAUp()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be open again")
    test.Snap("verify folder icon is selected")

    OAUp()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.Snap("verify volume icon is selected")

    a2d.CloseAllWindows()
end)

test.Step(
  "Reactivate existing window",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU", true)
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")

    OAUp()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be open again")
    test.Snap("verify folder icon is selected")

    OAUp()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.Snap("verify volume icon is selected")

    a2d.CloseAllWindows()
end)


test.Step(
  "View change",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU", true)
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be on top")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_NAME)
    a2d.CycleWindows()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "APPLE.MENU", "folder window should be on top")

    OAUp()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be open again")
    test.Snap("verify folder icon is selected")

    OAUp()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.Snap("verify volume icon is selected")

    a2d.CloseAllWindows()
end)

test.Step(
  "Icon selection with keyboard",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU", true)

    OAUp()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be open again")
    test.Snap("verify folder icon is selected")

    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify single icon is selected")

    a2d.CloseAllWindows()
end)

test.Step(
  "Icon selection with keyboard with window cycling",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU")

    OAUp()
    test.ExpectEquals(a2dtest.GetWindowCount(), 2, "two windows should be open")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "A2.DESKTOP", "volume window should be open again")
    test.Snap("verify folder icon is selected")

    apple2.RightArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify single icon is selected")

    a2d.CloseAllWindows()
end)

