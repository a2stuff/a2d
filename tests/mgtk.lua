--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS="-ramsize 1152K"
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

test.Step(
  "Verify IOUDIS is on normally",
  function()
    apple2.MoveMouse(560, 192)
    test.Expect(apple2.ReadSSW('RDIOUDIS') > 127, "IOUDIS should be on")
end)

