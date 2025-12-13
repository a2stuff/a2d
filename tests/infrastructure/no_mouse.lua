--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl6 '' -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

test.Step(
  "No Mouse",
  function()
    test.ExpectError("Failed to find device", function()
        apple2.MoveMouse(480, 170)
    end, "should have reported no device found")
end)
