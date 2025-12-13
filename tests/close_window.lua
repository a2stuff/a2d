--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]--

--[[
  Open two windows. Click the close box on the active window. Verify
  that only the active window closes.
]]--
test.Step(
  "Close box normally closes only one window",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.SelectAndOpen("EXTRAS")
    local count = a2dtest.GetWindowCount()
    local x, y = a2dtest.GetFrontWindowCloseBoxCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), count - 1, "one window should have closed")
    a2d.CloseAllWindows()
end)

--[[
  Open two windows. Open the File menu, then press Solid-Apple+W.
  Verify that only the top window closes. Repeat with Caps Lock off.

  Open two windows. Open the File menu, then press Open-Apple+W.
  Verify that only the top window closes. Repeat with Caps Lock off.
]]--
test.Variants(
  {
    "Close shortcut with File menu open (Open Apple)",
    "Close shortcut with File menu open (Open Apple, caps lock off)",
    "Close shortcut with File menu open (Solid Apple)",
    "Close shortcut with File menu open (Solid Apple, caps lock off)",
  },
  function(idx)
    a2d.OpenPath("/A2.DESKTOP")
    a2d.SelectAndOpen("EXTRAS")
    local count = a2dtest.GetWindowCount()
    a2d.OpenMenu(a2d.FILE_MENU)
    if idx == 1 then
      a2d.OAShortcut("W")
    elseif idx == 2 then
      a2d.OAShortcut("w")
    elseif idx == 3 then
      a2d.SAShortcut("W")
    else
      a2d.SAShortcut("w")
    end
    a2d.WaitForRepaint()
    test.Snap("verify only one window closed")
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window. Click the close box. Verify that the
  close animation runs.
]]--
test.Step(
  "Close box - animation runs",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    local x, y = a2dtest.GetFrontWindowCloseBoxCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
        a2dtest.MultiSnap(120, "verify close animation ran")
    end)
    a2d.CloseAllWindows()
end)

--[[
   Open a window. File > Close. Verify that the close animation runs.
]]--
test.Step(
  "Close shortcut - animation runs",
  function()
    a2d.OpenPath("/A2.DESKTOP")

    -- NOTE: This is extremely timing-sensitive
    a2d.OAShortcut("W", {no_wait=true})
    a2dtest.MultiSnap(120, "verify close animation ran")

    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a volume icon. Open a folder icon. Activate the
  volume window. Click the close box. Verify that the close animation
  doesn't leave garbage in the menu bar.
]]--
test.Step(
  "Close animation doesn't dirty menu bar",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.SelectAndOpen("EXTRAS")
    local x, y = a2dtest.GetFrontWindowCloseBoxCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
        a2d.WaitForRepaint()
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify menu bar is not dirty")
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window. Click the close box. Verify that the
  close animation does not leave a stray rectangle on the screen.
]]--
test.Step(
  "Close animation doesn't leave stray rectangle",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    local x, y = a2dtest.GetFrontWindowCloseBoxCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify desktop is not dirty")
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open `/TESTS/FOLDER`. Close the `TESTS` window.
  Close the `FOLDER` window. Verify that it animates into the volume
  icon, which becomes selected.
]]--
test.Step(
  "Close animates into volume icon if parent not available",
  function()
    a2d.OpenPath("/TESTS")
    a2d.SelectAndOpen("FOLDER")
    a2d.CycleWindows()
    a2d.CloseWindow()

    -- NOTE: This is extremely timing-sensitive
    a2d.OAShortcut("W", {no_wait=true})
    a2dtest.MultiSnap(120, "verify windows animates into volume icon")

    a2d.WaitForRepaint()
    test.Snap("verify volume icon is selected")

    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open `/TESTS/FOLDER/SUBFOLDER`. Close the
  `SUBFOLDER` window. Verify that it animates into the `SUBFOLDER`
  icon in the `FOLDER` window and becomes selected.
]]--
test.Step(
  "Close animates into parent icon if available",
  function()
    a2d.OpenPath("/TESTS")
    a2d.SelectAndOpen("FOLDER")
    a2d.SelectAndOpen("SUBFOLDER")

    -- NOTE: This is extremely timing-sensitive
    a2d.OAShortcut("W", {no_wait=true})
    a2dtest.MultiSnap(120, "verify windows animates into folder icon")

    a2d.WaitForRepaint()
    test.Snap("verify SUBFOLDER icon is selected")

    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open `/TESTS/FOLDER/SUBFOLDER`. Close the `TESTS`
  window. Close the `FOLDER` window. Verify that it animates into the
  volume icon, which becomes selected.
]]--
test.Step(
  "Close animates into volume icon if not available but with other windows",
  function()
    a2d.OpenPath("/TESTS")
    a2d.SelectAndOpen("FOLDER")
    a2d.SelectAndOpen("SUBFOLDER")
    a2d.CycleWindows() -- put TESTS on top
    a2d.CloseWindow()
    a2d.CycleWindows() -- put FOLDER on top

    -- NOTE: This is extremely timing-sensitive
    a2d.OAShortcut("W", {no_wait=true})
    a2dtest.MultiSnap(120, "verify windows animates into volume icon")

    a2d.WaitForRepaint()
    test.Snap("verify volume icon is selected")

    a2d.CloseAllWindows()
end)

