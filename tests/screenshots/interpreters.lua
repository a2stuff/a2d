--[[============================================================

  Exercise all the "Interpreters" (file type handlers)

  ============================================================]]

a2d.ConfigureRepaintTime(0.25)

test.Step(
  "Applesoft BASIC",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/HELLO.WORLD")
    while not apple2.GrabTextScreen():match("Hello world!") do
      emu.wait(1)
    end
    test.Snap("Applesoft BASIC")
    apple2.ControlOAReset()
    a2d.WaitForDesktopReady()
    return test.PASS
end)

test.Step(
  "Integer BASIC",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/APPLEVISION")
    emu.wait(5)
    apple2.ReturnKey()
    emu.wait(15)
    test.Snap("Integer BASIC")
    apple2.ControlOAReset()
    a2d.WaitForDesktopReady()
    return test.PASS
end)

test.Step(
  "S.A.M.",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/EMERGENCY")
    emu.wait(5)
    test.Snap("S.A.M. Text-To-Speech")
    apple2.ControlOAReset()
    a2d.WaitForDesktopReady()
    return test.PASS
end)

test.Step(
  "PT3",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/AUTUMN.PT3")
    emu.wait(5)
    test.Snap("Noise Tracker PT3")
    apple2.ControlOAReset()
    a2d.WaitForDesktopReady()
    return test.PASS
end)

-- TODO: AW
-- TODO: Unshrink
-- TODO: BinSCII
