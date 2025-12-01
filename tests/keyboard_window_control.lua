
--[[============================================================

  Test Script

  ============================================================]]--

test.Step(
  "Move window with keyboard - cancelled",
  function()
    a2d.OpenPath("A2.DESKTOP")
    a2d.WaitForRepaint()

    a2d.OAShortcut("M")
    for i=1,3 do
      apple2.RightArrowKey()
      apple2.DownArrowKey()
    end
    apple2.EscapeKey()
    test.Snap("should not have moved")
end)

test.Step(
  "Move window with keyboard",
  function()
    a2d.OpenPath("A2.DESKTOP")
    a2d.WaitForRepaint()

    a2d.OAShortcut("M")
    for i=1,3 do
      apple2.RightArrowKey()
      apple2.DownArrowKey()
    end
    apple2.ReturnKey()
    a2d.WaitForRepaint()
    test.Snap("should have moved right and down")
end)

test.Step(
  "Resize window with keyboard - cancelled",
  function()
    a2d.OpenPath("A2.DESKTOP")
    a2d.WaitForRepaint()

    a2d.OAShortcut("G")
    for i=1,3 do
      apple2.RightArrowKey()
      apple2.DownArrowKey()
    end
    apple2.EscapeKey()
    test.Snap("should not have resized")
end)

test.Step(
  "Resize window with keyboard",
  function()
    a2d.OpenPath("A2.DESKTOP")
    a2d.WaitForRepaint()

    a2d.OAShortcut("G")
    for i=1,3 do
      apple2.RightArrowKey()
      apple2.DownArrowKey()
    end
    apple2.ReturnKey()
    a2d.WaitForRepaint()
    test.Snap("should have resized")
end)
