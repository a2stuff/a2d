--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS="-ramsize 1152K -gameio joy"
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]--

emu.wait(50) -- IIc emulation is very slow

test.Step(
  "Key Caps - Apple IIc+",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/KEY.CAPS")
    emu.wait(5) -- IIc emulation is very slow
    test.Snap("verify the keyboard layout is \"extended\"")
end)
