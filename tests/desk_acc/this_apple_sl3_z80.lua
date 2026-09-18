--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl3 softcard -sl7 cffa202 -aux rw3"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

test.Step(
  "Slot 3 - Z-80",
  function()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.ABOUT_THIS_APPLE_II)
    a2dtest.WaitForSystemTask()
    test.ExpectMatch(a2dtest.OCRFrontWindowContent(), "Slot 3: +Z%-80 SoftCard",
                "Slot 3: Z-80 SoftCard should be detected")
end)
