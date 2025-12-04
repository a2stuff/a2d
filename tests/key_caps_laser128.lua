--[[ BEGINCONFIG ========================================

MODEL="las128ex"
MODELARGS="-sl7 cffa2"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]--

test.Step(
  "Key Caps - Laser 128",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/KEY.CAPS")
    test.Snap("verify the keyboard layout is \"original\"")
end)
