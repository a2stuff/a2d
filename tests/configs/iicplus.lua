--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS="-ramsize 1152K -gameio joy"
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]--

test.Step(
  "Apple > About This Apple II",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(3) -- IIc emulation is very slow
    test.Snap()
    return test.PASS
end)
