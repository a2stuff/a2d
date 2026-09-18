--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

--[[
  Open two windows. Click the close box on the active window. Verify
  that only the active window closes.
]]
test.Step(
  "Close box normally closes only one window",
  function()
    desktop.OpenWindow("/A2.DESKTOP")
    desktop.SelectAndOpen("EXTRAS")
    local count = a2dtest.GetWindowCount()
    local x, y = a2dtest.GetFrontWindowCloseBoxCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
    end)
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(a2dtest.GetWindowCount(), count - 1, "one window should have closed")
    desktop.CloseAllWindows()
end)

--[[
  Open two windows. Open the File menu, then press Solid-Apple+W.
  Verify that only the top window closes. Repeat with Caps Lock off.

  Open two windows. Open the File menu, then press Open-Apple+W.
  Verify that only the top window closes. Repeat with Caps Lock off.
]]
test.Variants(
  {
    { "Close shortcut with File menu open (Open Apple)", a2d.OAShortcut, "W" },
    { "Close shortcut with File menu open (Open Apple, caps lock off)", a2d.OAShortcut, "w"},
    { "Close shortcut with File menu open (Solid Apple)", a2d.SAShortcut, "W"},
      { "Close shortcut with File menu open (Solid Apple, caps lock off)", a2d.SAShortcut, "W"},
  },
  function(idx, name, func, arg)
    desktop.OpenWindow("/A2.DESKTOP")
    desktop.SelectAndOpen("EXTRAS")
    local count = a2dtest.GetWindowCount()
    a2d.OpenMenu(desktop.FILE_MENU)
    func(arg)
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(a2dtest.GetWindowCount(), count - 1, "one window should have closed")
    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window. Click the close box. Verify that the
  close animation runs.
]]
test.Step(
  "Close box - animation runs",
  function()
    desktop.OpenWindow("/A2.DESKTOP")
    local x, y = a2dtest.GetFrontWindowCloseBoxCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
        a2dtest.MultiSnap(120, "verify close animation ran")
    end)
    desktop.CloseAllWindows()
end)

--[[
   Open a window. File > Close. Verify that the close animation runs.
]]
test.Step(
  "Close shortcut - animation runs",
  function()
    desktop.OpenWindow("/A2.DESKTOP")

    -- NOTE: This is extremely timing-sensitive
    a2d.OAShortcut("W", {no_wait=true})
    a2dtest.MultiSnap(120, "verify close animation ran")

    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a volume icon. Open a folder icon. Activate the
  volume window. Click the close box. Verify that the close animation
  doesn't leave garbage in the menu bar.
]]
test.Step(
  "Close animation doesn't dirty menu bar",
  function()
    desktop.OpenWindow("/A2.DESKTOP")
    desktop.SelectAndOpen("EXTRAS")
    local x, y = a2dtest.GetFrontWindowCloseBoxCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
    end)
    a2dtest.WaitForSystemTask()
    test.Snap("verify menu bar is not dirty")
    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window. Click the close box. Verify that the
  close animation does not leave a stray rectangle on the screen.
]]
test.Step(
  "Close animation doesn't leave stray rectangle",
  function()
    desktop.OpenWindow("/A2.DESKTOP")
    local x, y = a2dtest.GetFrontWindowCloseBoxCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
    end)
    a2dtest.WaitForSystemTask()
    test.Snap("verify desktop is not dirty")
    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open `/TESTS/FOLDER`. Close the `TESTS` window.
  Close the `FOLDER` window. Verify that it animates into the volume
  icon, which becomes selected.
]]
test.Step(
  "Close animates into volume icon if parent not available",
  function()
    desktop.OpenWindow("/TESTS")
    desktop.SelectAndOpen("FOLDER")
    desktop.CycleWindows()
    desktop.CloseWindow()

    -- NOTE: This is extremely timing-sensitive
    a2d.OAShortcut("W", {no_wait=true})
    a2dtest.MultiSnap(120, "verify windows animates into volume icon")

    a2dtest.WaitForSystemTask()

    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "TESTS", "clicked icon should be selected")
    test.Expect(not desktop.GetSelectedIcons()[1].dimmed, "selected icon should not be dimmed")

    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open `/TESTS/FOLDER/SUBFOLDER`. Close the
  `SUBFOLDER` window. Verify that it animates into the `SUBFOLDER`
  icon in the `FOLDER` window and becomes selected.
]]
test.Step(
  "Close animates into parent icon if available",
  function()
    desktop.OpenWindow("/TESTS")
    desktop.SelectAndOpen("FOLDER")
    desktop.SelectAndOpen("SUBFOLDER")

    -- NOTE: This is extremely timing-sensitive
    a2d.OAShortcut("W", {no_wait=true})
    a2dtest.MultiSnap(120, "verify windows animates into folder icon")

    a2dtest.WaitForSystemTask()

    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "SUBFOLDER", "clicked icon should be selected")
    test.Expect(not desktop.GetSelectedIcons()[1].dimmed, "selected icon should not be dimmed")

    desktop.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open `/TESTS/FOLDER/SUBFOLDER`. Close the `TESTS`
  window. Close the `FOLDER` window. Verify that it animates into the
  volume icon, which becomes selected.
]]
test.Step(
  "Close animates into volume icon if not available but with other windows",
  function()
    desktop.OpenWindow("/TESTS")
    desktop.SelectAndOpen("FOLDER")
    desktop.SelectAndOpen("SUBFOLDER")
    desktop.CycleWindows() -- put TESTS on top
    desktop.CloseWindow()
    desktop.CycleWindows() -- put FOLDER on top

    -- NOTE: This is extremely timing-sensitive
    a2d.OAShortcut("W", {no_wait=true})
    a2dtest.MultiSnap(120, "verify windows animates into volume icon")

    a2dtest.WaitForSystemTask()

    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "TESTS", "clicked icon should be selected")
    test.Expect(not desktop.GetSelectedIcons()[1].dimmed, "selected icon should not be dimmed")

    desktop.CloseAllWindows()
end)

