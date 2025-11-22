--[[ BEGINCONFIG ========================================

MODEL="apple2e"
MODELARGS="-sl2 mouse -sl7 cffa202 -aux ext80"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]--

test.Step(
  "Key Caps - Apple IIe",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/KEY.CAPS")
    test.Snap("verify the keyboard layout is \"original\"")
end)
