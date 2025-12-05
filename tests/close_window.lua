--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]--

--[[============================================================

  "Close Window" tests

  ============================================================]]--

test.Step(
  "Close box normally closes only one window",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.SelectAndOpen("EXTRAS")
    local count = a2dtest.GetWindowCount()
    local x,y = a2dtest.GetFrontWindowCloseBoxCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x,y)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), count - 1, "one window should have closed")
    a2d.CloseAllWindows()
end)

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

test.Step(
  "Close box - animation runs",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(20, 20)
        m.Click()
        test.MultiSnap(10, "verify close animation ran")
    end)
    a2d.CloseAllWindows()
end)

test.Step(
  "Close shortcut - animation runs",
  function()
    a2d.OpenPath("/A2.DESKTOP")

    -- NOTE: This is extremely timing-sensitive
    apple2.OAKey("W")
    test.MultiSnap(10, "verify close animation ran")

    a2d.CloseAllWindows()
end)

test.Step(
  "Close animation doesn't dirty menu bar",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.SelectAndOpen("EXTRAS")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(20, 20)
        m.Click()
        a2d.WaitForRepaint()
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify menu bar is not dirty")
    a2d.CloseAllWindows()
end)

test.Step(
  "Close animation doesn't leave stray rectangle",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(20, 20)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify desktop is not dirty")
    a2d.CloseAllWindows()
end)

test.Step(
  "Close animates into volume icon if parent not available",
  function()
    a2d.OpenPath("/TESTS")
    a2d.SelectAndOpen("FOLDER")
    a2d.CycleWindows()
    a2d.CloseWindow()

    -- NOTE: This is extremely timing-sensitive
    apple2.OAKey("W")
    test.MultiSnap(8, "verify windows animates into volume icon")

    a2d.WaitForRepaint()
    test.Snap("verify volume icon is selected")

    a2d.CloseAllWindows()
end)

test.Step(
  "Close animates into parent icon if available",
  function()
    a2d.OpenPath("/TESTS")
    a2d.SelectAndOpen("FOLDER")
    a2d.SelectAndOpen("SUBFOLDER")

    -- NOTE: This is extremely timing-sensitive
    apple2.OAKey("W")
    test.MultiSnap(32, "verify windows animates into folder icon")

    a2d.WaitForRepaint()
    test.Snap("verify SUBFOLDER icon is selected")

    a2d.CloseAllWindows()
end)

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
    apple2.OAKey("W")
    test.MultiSnap(10, "verify windows animates into volume icon")

    a2d.WaitForRepaint()
    test.Snap("verify volume icon is selected")

    a2d.CloseAllWindows()
end)

