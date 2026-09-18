--[[============================================================

  Dump all the Screen Savers

  ============================================================]]

test.Step(
  "Analog Clock",
  function()
    a2d.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/ANALOG.CLOCK"))
    emu.wait(0.5) -- screensaver launch
    test.Snap("Analog Clock")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Digital Clock",
  function()
    a2d.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/DIGITAL.CLOCK"))
    emu.wait(0.5) -- screensaver launch
    test.Snap("Digital Clock")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Flying Toasters",
  function()
    a2d.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/FLYING.TOASTERS"))
    emu.wait(2) -- let toasters fly onto screen
    test.Snap("Flying Toasters")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Helix",
  function()
    a2d.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/HELIX"))
    emu.wait(0.5) -- screensaver launch
    test.Snap("Helix")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Invert",
  function()
    a2d.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/INVERT"))
    emu.wait(0.5) -- screensaver launch
    test.Snap("Invert")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Matrix",
  function()
    a2d.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/MATRIX"))
    emu.wait(1) -- let the digital rain start
    test.Snap("Matrix")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Maze",
  function()
    a2d.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/MAZE"))
    emu.wait(5) -- let the maze get going
    test.Snap("Maze")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Melt",
  function()
    a2d.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/MELT"))
    emu.wait(1) -- let effect get going
    test.Snap("Melt")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Message",
  function()
    a2d.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/MESSAGE"))
    emu.wait(0.5) -- screensaver launch
    test.Snap("Message")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Rod's Pattern",
  function()
    a2d.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/RODS.PATTERN"))
    emu.wait(5) -- let effect get going
    test.Snap("Rod's Pattern")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)
