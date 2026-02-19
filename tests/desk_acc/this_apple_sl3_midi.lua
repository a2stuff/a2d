--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl3 midi -sl4 '' -sl7 cffa202 -aux rw3"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

test.Step(
  "Slot 3 - Passport MIDI",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(5)
    test.ExpectMatch(a2dtest.OCRScreen(), "Slot 3: .* Passport MIDI",
                "Slot 3: Passport MIDI should be detected")
end)
