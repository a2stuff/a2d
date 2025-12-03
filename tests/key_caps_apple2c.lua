--[[ BEGINCONFIG ========================================

MODEL="apple2c4"
MODELARGS="-ramsize 1152K -gameio joy"
DISKARGS="-flop1 $FLOP1IMG -flop2 $FLOP2IMG"

======================================== ENDCONFIG ]]--

test.Step(
  "Key Caps - Apple IIc",
  function()
    a2d.OpenPath("/A2.DESKTOP.2/APPLE.MENU/KEY.CAPS")
    emu.wait(5) -- IIc emulation is very slow
    test.Snap("verify the keyboard layout is \"original\"")
end)
