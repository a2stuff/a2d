--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl1 ramfactor -sl2 mouse -sl6 '' -sl7 cffa2 -aux rw3"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

test.Step(
  "Apple > About This Apple II",
  function()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.ABOUT_THIS_APPLE_II)
    a2dtest.WaitForSystemTask()
    test.Snap(manager.machine.system.name)
end)
