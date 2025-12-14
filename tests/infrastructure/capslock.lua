a2d.ConfigureRepaintTime(0.25)

test.Step(
  "Caps lock on non-IIgs model",
  function()
    apple2.CapsLockOff()
    a2d.RenamePath("/A2.DESKTOP", "MiXeD.CaSe")
    test.ExpectEquals(a2dtest.GetSelectedIconName(), "MiXeD.CaSe", "case should match")

    apple2.CapsLockOn()
    a2d.RenamePath("/MIXED.CASE", "uPpEr.cAsE")
    test.ExpectEquals(a2dtest.GetSelectedIconName(), "UPPER.CASE", "case should match")

    apple2.CapsLockOff()
    a2d.RenamePath("/UPPER.CASE", "MiXeD.CaSe")
    test.ExpectEquals(a2dtest.GetSelectedIconName(), "MiXeD.CaSe", "case should match")
end)
