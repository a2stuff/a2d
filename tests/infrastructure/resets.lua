-- Does this apply globally? Not sure.
a2d.ConfigureRepaintTime(0.25)

test.Step(
  "before the reset",
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS")
    emu.wait(5)
    test.Snap("before reset")
end)

test.Step(
  "after the reset",
  function()
    test.Snap("after reset")
    a2d.OpenPath("/RAM1")
    apple2.EscapeKey()
    emu.wait(1)
    test.Snap("with RAM1")
end)
