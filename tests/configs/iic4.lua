--[[ BEGINCONFIG ========================================

MODEL="apple2c4"
MODELARGS="-ramsize 1152K -gameio joy"
DISKARGS="-flop1 $FLOP1IMG"

======================================== ENDCONFIG ]]--

test.Step(
  "Apple > About This Apple II",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(5) -- IIc emulation is very slow
    test.Snap()
    return test.PASS
end)
