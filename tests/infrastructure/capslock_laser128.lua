--[[ BEGINCONFIG ========================================

MODEL="laser128"
MODELARGS="-sl7 cffa2"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]
test.Step(
  "Caps lock on Laser 128 model",
  function()
    apple2.CapsLockOff()
    desktop.RenamePath("/A2.DESKTOP", "MiXeD.CaSe")
    test.ExpectEquals(a2dtest.GetSelectedIconName(), "MiXeD.CaSe", "case should match")

    apple2.CapsLockOn()
    desktop.RenamePath("/MIXED.CASE", "uPpEr.cAsE")
    test.ExpectEquals(a2dtest.GetSelectedIconName(), "UPPER.CASE", "case should match")

    apple2.CapsLockOff()
    desktop.RenamePath("/UPPER.CASE", "MiXeD.CaSe")
    test.ExpectEquals(a2dtest.GetSelectedIconName(), "MiXeD.CaSe", "case should match")
end)
