--[[============================================================

  Exercise all the "Interpreters" (file type handlers)

  ============================================================]]

a2d.ConfigureRepaintTime(0.25)

test.Step(
  "Applesoft BASIC",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/HELLO.WORLD")
    util.WaitFor(
      "hello world", function()
        apple2.GrabTextScreen():match("Hello world!")
    end)
    test.Snap("Applesoft BASIC")
    apple2.ControlOAReset()
    a2d.WaitForDesktopReady()
end)

test.Step(
  "Integer BASIC",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/APPLEVISION")
    util.WaitFor(
      "APPLE-VISION", function()
        return apple2.GrabTextScreen():match("APPLE%-VISION")
    end)
    apple2.ReturnKey()
    emu.wait(15)
    test.Snap("Integer BASIC")
    apple2.ControlOAReset()
    a2d.WaitForDesktopReady()
end)

test.Step(
  "S.A.M.",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/EMERGENCY")
    util.WaitFor(
      "message", function()
        return apple2.GrabTextScreen():match("This is only a test")
    end)
    test.Snap("S.A.M. Text-To-Speech")
    apple2.ControlOAReset()
    a2d.WaitForDesktopReady()
end)

test.Step(
  "PT3",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/AUTUMN.PT3")
    util.WaitFor(
      "lores mixed",
      function()
        return apple2.ReadSSW("RDTEXT") < 128 and apple2.ReadSSW("RDMIXED") > 127 and
          apple2.ReadSSW("RDHIRES") < 128
    end)
    emu.wait(1)
    test.Snap("Noise Tracker PT3")
    apple2.ControlOAReset()
    a2d.WaitForDesktopReady()
end)

test.Step(
  "CHIP-8",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/BLINKY.CH8")
    util.WaitFor(
      "lores full",
      function()
        return apple2.ReadSSW("RDTEXT") < 128 and apple2.ReadSSW("RDMIXED") < 128 and
          apple2.ReadSSW("RDHIRES") < 128
    end)
    emu.wait(10)
    test.Snap("CHIP-8")
    apple2.ControlOAReset()
    a2d.WaitForDesktopReady()
end)

-- TODO: AW
-- TODO: Unshrink
-- TODO: BinSCII
