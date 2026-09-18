--[[ BEGINCONFIG ========================================

MODEL="apple2c3"
MODELARGS="-ramsize 1152K"
DISKARGS="-flop1 $FLOP1IMG"

======================================== ENDCONFIG ]]

test.Step(
  "Apple > About This Apple II",
  function()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.ABOUT_THIS_APPLE_II)
    a2dtest.WaitForSystemTask()
    test.Snap(manager.machine.system.name)
end)
