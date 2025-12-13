--[[ BEGINCONFIG ========================================

MODEL="apple2c4"
MODELARGS=""
DISKARGS="-flop1 $FLOP1IMG -flop2 $FLOP2IMG"

======================================== ENDCONFIG ]]--

--[[
  Launch DeskTop. Apple Menu > Key Caps. Verify that the "original"
  layout is shown, with the backslash above the Return key.
]]--
test.Step(
  "Key Caps - Apple IIc",
  function()
    a2d.OpenPath("/A2.DESKTOP.2/APPLE.MENU/KEY.CAPS")
    emu.wait(5) -- IIc emulation is very slow
    test.Snap("verify the keyboard layout is \"original\"")
end)
