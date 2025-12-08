
--[[============================================================

  Test Script

  ============================================================]]--

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
