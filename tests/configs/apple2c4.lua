--[[ BEGINCONFIG ========================================

MODEL="apple2c4"
MODELARGS="-ramsize 1152K"
DISKARGS="-flop1 $FLOP1IMG"

======================================== ENDCONFIG ]]

test.Step(
  "Apple > About This Apple II",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    test.Snap(manager.machine.system.name)
end)
