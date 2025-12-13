--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS=""
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]

--[[
  Launch DeskTop. Apple Menu > Key Caps. Verify that the "extended"
  layout is shown, with the backslash to the right of the space bar.
]]
test.Step(
  "Key Caps - Apple IIc+",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/KEY.CAPS")
    emu.wait(5) -- IIc emulation is very slow
    test.Snap("verify the keyboard layout is \"extended\"")
end)
