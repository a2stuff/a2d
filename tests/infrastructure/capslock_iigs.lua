--[[ BEGINCONFIG ========================================

MODEL="apple2gsr0"
MODELARGS="-sl7 cffa2 -ramsize 8M"
DISKARGS="-hard1 $HARDIMG"
RESOLUTION="704x462"

======================================== ENDCONFIG ]]--

test.Step(
  "Caps lock on non-IIgs model",
  function()
    apple2.CapsLockOff()
    a2d.RenamePath("/A2.DESKTOP", "MiXeD.CaSe")
    test.Snap("should be MiXeD.CaSe")
    apple2.CapsLockOn()
    a2d.RenamePath("/MIXED.CASE", "uPpEr.cAsE")
    test.Snap("should be UPPER.CASE")
    apple2.CapsLockOff()
    a2d.RenamePath("/UPPER.CASE", "MiXeD.CaSe")
    test.Snap("should be MiXeD.CaSe")
end)
