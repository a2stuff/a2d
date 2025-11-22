--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl1 ssc -sl2 mouse -sl5 ramfactor -sl7 cffa2 -aux rw3"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]--

test.Step(
  "Apple > About This Apple II",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    test.Snap()
    a2d.CloseWindow()
    return test.PASS
end)
