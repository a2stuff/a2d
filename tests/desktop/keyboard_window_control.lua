
a2d.ConfigureRepaintTime(0.25)

--[[
  Open a window. Press Apple+M. Use the Left, Right, Up and Down Arrow
  keys to move the window outline. Press Escape. Verify that the
  window does not move.
]]
test.Step(
  "Move window with keyboard - cancelled",
  function()
    a2d.OpenPath("A2.DESKTOP")
    a2d.WaitForRepaint()

    local bx, by, bw, bh = a2dtest.GetFrontWindowContentRect()

    a2d.OAShortcut("M")
    for i=1,5 do
      apple2.RightArrowKey()
      apple2.DownArrowKey()
    end
    apple2.EscapeKey()

    local ax, ay, aw, ah = a2dtest.GetFrontWindowContentRect()

    test.ExpectEquals(bx, ax, "should not have moved")
    test.ExpectEquals(by, ay, "should not have moved")
end)

--[[
  Open a window. Press Apple+M. Use the Left, Right, Up and Down Arrow
  keys to move the window outline. Press Return. Verify that the
  window moves to the new location.
]]
test.Step(
  "Move window with keyboard",
  function()
    a2d.OpenPath("A2.DESKTOP")
    a2d.WaitForRepaint()

    local bx, by, bw, bh = a2dtest.GetFrontWindowContentRect()

    a2d.OAShortcut("M")
    for i=1,5 do
      apple2.RightArrowKey()
      apple2.DownArrowKey()
    end
    apple2.ReturnKey()
    a2d.WaitForRepaint()

    local ax, ay, aw, ah = a2dtest.GetFrontWindowContentRect()

    test.ExpectLessThan(bx, ax, "should have moved right and down")
    test.ExpectLessThan(by, ay, "should have moved right and down")
end)

--[[
  Open a window. Press Apple+G. Use the Left, Right, Up and Down Arrow
  keys to resize the window outline. Press Escape. Verify that the
  window does not resize.
]]
test.Step(
  "Resize window with keyboard - cancelled",
  function()
    a2d.OpenPath("A2.DESKTOP")
    a2d.WaitForRepaint()

    local bx, by, bw, bh = a2dtest.GetFrontWindowContentRect()

    a2d.OAShortcut("G")
    for i=1,5 do
      apple2.RightArrowKey()
      apple2.DownArrowKey()
    end
    apple2.EscapeKey()

    local ax, ay, aw, ah = a2dtest.GetFrontWindowContentRect()

    test.ExpectEquals(bw, aw, "should not have grown")
    test.ExpectEquals(bh, ah, "should not have grown")
end)

--[[
  Open a window. Press Apple+G. Use the Left, Right, Up and Down Arrow
  keys to resize the window outline. Press Return. Verify that the
  window resizes.
]]
test.Step(
  "Resize window with keyboard",
  function()
    a2d.OpenPath("A2.DESKTOP")
    a2d.WaitForRepaint()

    local bx, by, bw, bh = a2dtest.GetFrontWindowContentRect()

    a2d.OAShortcut("G")
    for i=1,5 do
      apple2.RightArrowKey()
      apple2.DownArrowKey()
    end
    apple2.ReturnKey()
    a2d.WaitForRepaint()

    local ax, ay, aw, ah = a2dtest.GetFrontWindowContentRect()

    test.ExpectLessThan(bw, aw, "should have grown")
    test.ExpectLessThan(bh, ah, "should have grown")
end)
