--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 mouse -sl2 diskiing -sl7 cffa2 -aux ext80"

======================================== ENDCONFIG ]]--

test.Step(
  "Slot 2 can have drive controller",
  function()
    a2d.OpenMenu(a2d.STARTUP_MENU)
    test.Snap("verify Slot 2 is listed")
end)
