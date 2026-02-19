--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl3 softcard -sl7 cffa202 -aux rw3"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

test.Step(
  "Slot 3 - Z-80",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(5)
    test.ExpectMatch(a2dtest.OCRScreen(), "Slot 3: +Z%-80 SoftCard",
                "Slot 3: Z-80 SoftCard should be detected")
end)
