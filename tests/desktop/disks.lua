--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

test.Step(
  "No error",
  function()
    test.Snap("verify boot volume is in top right")
    desktop.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(desktop.FILE_MENU, desktop.FILE_COPY_TO)
    a2dtest.WaitForSystemTask()
    apple2.ControlKey("D") -- Drives
    a2dtest.WaitForSystemTask()
    test.Snap("verify boot volume is first disk")
end)
