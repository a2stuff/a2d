--[[ BEGINCONFIG ========================================

MODEL="las128ex"
MODELARGS="-ramsize 1152K -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

test.Step(
  "Apple > About This Apple II",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    test.Snap(manager.machine.system.name)
end)
