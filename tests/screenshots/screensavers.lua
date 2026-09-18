--[[============================================================

  Dump all the Screen Savers

  ============================================================]]

test.Step(
  "Analog Clock",
  function()
    desktop.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/ANALOG.CLOCK"), {no_wait=true})
    emu.wait(0.5) -- screensaver launch
    test.Snap("Analog Clock")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Digital Clock",
  function()
    desktop.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/DIGITAL.CLOCK"), {no_wait=true})
    emu.wait(0.5) -- screensaver launch
    test.Snap("Digital Clock")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Flying Toasters",
  function()
    desktop.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/FLYING.TOASTERS"), {no_wait=true})
    emu.wait(2) -- let toasters fly onto screen
    test.Snap("Flying Toasters")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Helix",
  function()
    desktop.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/HELIX"), {no_wait=true})
    emu.wait(0.5) -- screensaver launch
    test.Snap("Helix")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Invert",
  function()
    desktop.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/INVERT"), {no_wait=true})
    emu.wait(0.5) -- screensaver launch
    test.Snap("Invert")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Matrix",
  function()
    desktop.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/MATRIX"), {no_wait=true})
    emu.wait(1) -- let the digital rain start
    test.Snap("Matrix")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Maze",
  function()
    desktop.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/MAZE"), {no_wait=true})
    emu.wait(5) -- let the maze get going
    test.Snap("Maze")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Melt",
  function()
    desktop.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/MELT"), {no_wait=true})
    emu.wait(1) -- let effect get going
    test.Snap("Melt")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Message",
  function()
    desktop.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/MESSAGE"), {no_wait=true})
    emu.wait(0.5) -- screensaver launch
    test.Snap("Message")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)

test.Step(
  "Rod's Pattern",
  function()
    desktop.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/RODS.PATTERN"), {no_wait=true})
    emu.wait(5) -- let effect get going
    test.Snap("Rod's Pattern")
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
end)
