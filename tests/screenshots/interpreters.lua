--[[============================================================

  Exercise all the "Interpreters" (file type handlers)

  ============================================================]]

test.Step(
  "Applesoft BASIC",
  function()
    desktop.InvokePath("/A2.DESKTOP/SAMPLE.MEDIA/HELLO.WORLD", {no_wait=true})
    util.WaitFor(
      "hello world", function()
        return apple2.GrabTextScreen():match("Hello world!")
    end)
    test.Snap("Applesoft BASIC")
    apple2.ControlOAReset()
    a2d.WaitForDesktopReady()
end)

test.Step(
  "Integer BASIC",
  function()
    desktop.InvokePath("/A2.DESKTOP/SAMPLE.MEDIA/APPLEVISION", {no_wait=true})
    util.WaitFor(
      "APPLE-VISION", function()
        return apple2.GrabTextScreen():match("APPLE%-VISION")
    end)
    apple2.ReturnKey()
    emu.wait(15) -- wait for IntBASIC to launch
    test.Snap("Integer BASIC")
    apple2.ControlOAReset()
    a2d.WaitForDesktopReady()
end)

test.Step(
  "S.A.M.",
  function()
    desktop.InvokePath("/A2.DESKTOP/SAMPLE.MEDIA/EMERGENCY", {no_wait=true})
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
    desktop.InvokePath("/A2.DESKTOP/SAMPLE.MEDIA/AUTUMN.PT3", {no_wait=true})
    util.WaitFor(
      "lores mixed",
      function()
        return apple2.ReadSSW("RDTEXT") < 128 and apple2.ReadSSW("RDMIXED") > 127 and
          apple2.ReadSSW("RDHIRES") < 128
    end)
    emu.wait(1) -- wait for PT3 player to launch
    test.Snap("Noise Tracker PT3")
    apple2.ControlOAReset()
    a2d.WaitForDesktopReady()
end)

test.Step(
  "CHIP-8",
  function()
    desktop.InvokePath("/A2.DESKTOP/SAMPLE.MEDIA/BLINKY.CH8", {no_wait=true})
    util.WaitFor(
      "lores full",
      function()
        return apple2.ReadSSW("RDTEXT") < 128 and apple2.ReadSSW("RDMIXED") < 128 and
          apple2.ReadSSW("RDHIRES") < 128
    end)
    emu.wait(10) -- wait for Chip-8 game to launch
    test.Snap("CHIP-8")
    apple2.ControlOAReset()
    a2d.WaitForDesktopReady()
end)

-- TODO: AW
-- TODO: Unshrink
-- TODO: BinSCII
