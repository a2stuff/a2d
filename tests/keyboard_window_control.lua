
--[[
  Open a window. Press Apple+M. Use the Left, Right, Up and Down Arrow
  keys to move the window outline. Press Escape. Verify that the
  window does not move.
]]--
test.Step(
  "Move window with keyboard - cancelled",
  function()
    a2d.OpenPath("A2.DESKTOP")
    a2d.WaitForRepaint()

    local before = mgtk.GetWinFrameRect(mgtk.FrontWindow())

    a2d.OAShortcut("M")
    for i=1,5 do
      apple2.RightArrowKey()
      apple2.DownArrowKey()
    end
    apple2.EscapeKey()

    local after = mgtk.GetWinFrameRect(mgtk.FrontWindow())

    test.ExpectEquals(before[1], after[1], "should not have moved")
    test.ExpectEquals(before[2], after[2], "should not have moved")
end)

--[[
  Open a window. Press Apple+M. Use the Left, Right, Up and Down Arrow
  keys to move the window outline. Press Return. Verify that the
  window moves to the new location.
]]--
test.Step(
  "Move window with keyboard",
  function()
    a2d.OpenPath("A2.DESKTOP")
    a2d.WaitForRepaint()

    local before = mgtk.GetWinFrameRect(mgtk.FrontWindow())

    a2d.OAShortcut("M")
    for i=1,5 do
      apple2.RightArrowKey()
      apple2.DownArrowKey()
    end
    apple2.ReturnKey()
    a2d.WaitForRepaint()

    local after = mgtk.GetWinFrameRect(mgtk.FrontWindow())

    test.ExpectLessThan(before[1], after[1], "should have moved right and down")
    test.ExpectLessThan(before[2], after[2], "should have moved right and down")
end)

--[[
  Open a window. Press Apple+G. Use the Left, Right, Up and Down Arrow
  keys to resize the window outline. Press Escape. Verify that the
  window does not resize.
]]--
test.Step(
  "Resize window with keyboard - cancelled",
  function()
    a2d.OpenPath("A2.DESKTOP")
    a2d.WaitForRepaint()

    local before = mgtk.GetWinFrameRect(mgtk.FrontWindow())

    a2d.OAShortcut("G")
    for i=1,5 do
      apple2.RightArrowKey()
      apple2.DownArrowKey()
    end
    apple2.EscapeKey()

    local after = mgtk.GetWinFrameRect(mgtk.FrontWindow())

    test.ExpectEquals(before[3], after[3], "should not have grown")
    test.ExpectEquals(before[4], after[4], "should not have grown")
end)

--[[
  Open a window. Press Apple+G. Use the Left, Right, Up and Down Arrow
  keys to resize the window outline. Press Return. Verify that the
  window resizes.
]]--
test.Step(
  "Resize window with keyboard",
  function()
    a2d.OpenPath("A2.DESKTOP")
    a2d.WaitForRepaint()

    local before = mgtk.GetWinFrameRect(mgtk.FrontWindow())

    a2d.OAShortcut("G")
    for i=1,5 do
      apple2.RightArrowKey()
      apple2.DownArrowKey()
    end
    apple2.ReturnKey()
    a2d.WaitForRepaint()

    local after = mgtk.GetWinFrameRect(mgtk.FrontWindow())

    test.ExpectLessThan(before[3], after[3], "should have grown")
    test.ExpectLessThan(before[4], after[4], "should have grown")
end)
