--[[ BEGINCONFIG ========================================

MODEL="las128ex"
MODELARGS="-sl7 cffa2"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)

--[[
  Launch DeskTop. Apple Menu > Key Caps. Verify that the "original"
  layout is shown, with the backslash above the Return key.
]]
test.Step(
  "Key Caps - Laser 128",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/KEY.CAPS")
    emu.wait(2)
    test.Snap("verify the keyboard layout is \"original\"")
end)
