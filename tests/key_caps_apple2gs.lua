--[[ BEGINCONFIG ========================================

MODEL="apple2gsr0"
MODELARGS="-sl7 cffa2 -ramsize 8M"
DISKARGS="-hard1 $HARDIMG"
RESOLUTION="704x462"

======================================== ENDCONFIG ]]--

test.Step(
  "Key Caps - Apple IIgs",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/KEY.CAPS")
    test.Snap("verify the keyboard layout is \"extended\"")
end)

