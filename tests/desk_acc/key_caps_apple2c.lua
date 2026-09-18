--[[ BEGINCONFIG ========================================

MODEL="apple2c4"
MODELARGS=""
DISKARGS="-flop1 $FLOP1IMG -flop2 $FLOP2IMG"

======================================== ENDCONFIG ]]

--[[
  Launch DeskTop. Apple Menu > Key Caps. Verify that the "original"
  layout is shown, with the backslash above the Return key.
]]
test.Step(
  "Key Caps - Apple IIc",
  function()
    desktop.InvokePath("/A2.DESKTOP.2/APPLE.MENU/KEY.CAPS")
    test.Snap("verify the keyboard layout is \"original\"")
end)
