--[[============================================================

  "Close All" tests

  ============================================================]]--

-- TODO: Test with Solid Apple (not possible with MouseKeys mode)
test.Step(
  "Close all using modifier-click",
  function()
    a2d.ClearSelection()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", true) -- leave parent open
    local x, y = a2dtest.GetFrontWindowCloseBoxCoords()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        apple2.PressOA()
        m.Click()
        apple2.ReleaseOA()
    end)
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "all windows should be closed")
end)

test.Variants(
  {
    "Close all using shortcut",
    "Close all using shortcut - caps lock off",
  },
  function(idx)
    a2d.ClearSelection()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", true) -- leave parent open
    if idx == 1 then
      a2d.OASAShortcut("W")
    else
      a2d.OASAShortcut("w")
    end
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "all windows should be closed")
end)

--[[
  -- TODO: This doesn't work w/ keyboard-driven menu, or MouseKeys. Will need real mouse

test.Variants(
  {
    "Close all using menu and modifier - Solid Apple",
    "Close all using menu and modifier - Open Apple",
  },
  function(idx)
    a2d.OpenPath("/A2.DESKTOP/EXTRAS", true) -- leave parent open
    if idx == 1 then
      apple2.PressSA()
    else
      apple2.PressOA()
    end
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_CLOSE)
    a2d.WaitForRepaint()
    if idx == 1 then
      apple2.ReleaseSA()
    else
      apple2.ReleaseOA()
    end
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "all windows should be closed")
end)
]]--

--[[
  TODO: This actually requires holding OA or SA while opening the menu

  test.Variants(
  {
    "Close All shortcut with File menu open",
    "Close All shortcut with File menu open (caps lock off)",
  },
  function(idx)
    a2d.OpenPath("/A2.DESKTOP/EXTRAS") -- leave parent open
    a2d.OpenMenu(a2d.FILE_MENU)
    if idx == 1 then
      a2d.OASAShortcut("W")
    else
      a2d.OASAShortcut("w")
    end
    a2d.WaitForRepaint()
    test.ExpectEquals(a2dtest.GetWindowCount(), 0, "all windows should be closed")
end)
]]--
