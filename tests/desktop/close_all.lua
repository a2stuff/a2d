
a2d.ConfigureRepaintTime(0.5)

--[[
  Repeat the following case with these modifiers: Open-Apple,
  Solid-Apple:

  Open two windows. Hold modifier and click the close box on the
  active window. Verify that all windows close.
]]
test.Variants(
  {
    {"Close all using Open Apple click on close box", apple2.PressOA, apple2.ReleaseOA},
    {"Close all using Solid Apple click on close box", apple2.PressSA, apple2.ReleaseSA},
  },
  function(idx, name, press, release)
    a2d.ClearSelection()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", {leave_parent=true})
    local x, y = a2dtest.GetFrontWindowCloseBoxCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        press()
        m.Click()
        release()
    end)
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "all windows should be closed")
end)

--[[
  Open two windows. Press Open-Apple+Solid-Apple+W. Verify that all
  windows close. Repeat with Caps Lock off.
]]
test.Variants(
  {
    {"Close all using Open Apple + Solid Apple + W", "W"},
    {"Close all using Open Apple + Solid Apple + w", "w"},
  },
  function(idx, name, key)
    a2d.ClearSelection()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", {leave_parent=true})
    a2d.OASAShortcut(key)
    emu.wait(1)
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "all windows should be closed")
end)

--[[
  Open two windows. Hold Solid-Apple and select File > Close. Verify
  that all windows close.

  Open two windows. Hold Open-Apple and select File > Close. Verify
  that all windows close.
]]
test.Variants(
  {
    {"Close all using menu and Solid Apple", apple2.PressSA, apple2.ReleaseSA},
    {"Close all using menu and Open Apple", apple2.PressOA, apple2.ReleaseOA},
  },
  function(idx, name, press, release)
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", {leave_parent=true})

    local file_menu_x, file_menu_y
    a2dtest.OCRIterate(function(run, x, y)
        if run == "File" then
          file_menu_x, file_menu_y = x, y
          return false
        end
    end)

    a2d.InMouseKeysMode(function(m)
        press()

        m.MoveToApproximately(file_menu_x, file_menu_y)
        m.Click()
        m.MoveByApproximately(0, 35) -- File > Close
        m.Click()

        release()
    end)
    a2d.WaitForRepaint()

    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "all windows should be closed")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(0, 0)
    end)
end)

--[[
  Open two windows. Hold Open-Apple and open the File menu, then press
  Open-Apple+Solid-Apple+W. Verify that all windows close. Repeat with
  Caps Lock off.
]]
test.Variants(
  {
    {"Close all using Open Apple + Solid Apple + W, with File menu open", "W"},
    {"Close all using Open Apple + Solid Apple + w, with File menu open", "w"},
  },
  function(idx, name, key)
    a2d.OpenPath("/A2.DESKTOP/EXTRAS") -- leave parent open
    a2d.OpenMenu(a2d.FILE_MENU)
    a2d.OASAShortcut(key)
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "all windows should be closed")
end)

--[[
  Open two windows. Hold Solid-Apple and open the File menu, then
  press Open-Apple+Solid-Apple+W. Verify that all windows close.
  Repeat with Caps Lock off.
]]
test.Variants(
  {
    {"Holding SA open menu, then OA+SA+W", "W"},
    {"Holding SA open menu, then OA+SA+w", "w"},
  },
  function(idx, name, key)
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", {leave_parent=true})

    local file_menu_x, file_menu_y
    a2dtest.OCRIterate(function(run, x, y)
        if run == "File" then
          file_menu_x, file_menu_y = x, y
          return false
        end
    end)

    a2d.InMouseKeysMode(function(m)
        apple2.PressSA()
        m.MoveToApproximately(file_menu_x, file_menu_y)
        m.Click()
    end)

    a2d.OASAShortcut(key)
    a2d.WaitForRepaint()

    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "all windows should be closed")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(0, 0)
    end)
end)
