--[[ BEGINCONFIG ========================================

MODEL="apple2e"
MODELARGS="-sl2 mouse -sl7 cffa202 -aux ext80"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]--

test.Step(
  "Apple > About This Apple II",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    test.Snap()
    return test.PASS
end)
