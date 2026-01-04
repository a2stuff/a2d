--[[============================================================

  Dump all the Screen Savers

  ============================================================]]

a2d.ConfigureRepaintTime(1)

test.Step(
  "Analog Clock",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/ANALOG.CLOCK")
    emu.wait(0.5)
    test.Snap("Analog Clock")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
end)

test.Step(
  "Digital Clock",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/DIGITAL.CLOCK")
    emu.wait(0.5)
    test.Snap("Digital Clock")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
end)

test.Step(
  "Flying Toasters",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/FLYING.TOASTERS")
    emu.wait(2)
    test.Snap("Flying Toasters")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
end)

test.Step(
  "Helix",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/HELIX")
    emu.wait(0.5)
    test.Snap("Helix")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
end)

test.Step(
  "Invert",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/INVERT")
    emu.wait(0.5)
    test.Snap("Invert")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
end)

test.Step(
  "Matrix",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/MATRIX")
    emu.wait(1)
    test.Snap("Matrix")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
end)

test.Step(
  "Melt",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/MELT")
    emu.wait(1)
    test.Snap("Melt")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
end)

test.Step(
  "Message",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/MESSAGE")
    emu.wait(0.5)
    test.Snap("Message")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
end)

test.Step(
  "Rod's Pattern",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/SCREEN.SAVERS/RODS.PATTERN")
    emu.wait(5)
    test.Snap("Rod's Pattern")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
end)
