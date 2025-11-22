--[[ BEGINCONFIG ========================================

MODEL="apple2e"
MODELARGS="-gameio joy -sl2 mouse -sl7 cffa202 -aux ext80"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]--

test.Step(
  "Joystick Limits",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/JOYSTICK")

    apple2.SetJoy1(0,0)
    test.Snap("verify indicator in top left")
    apple2.SetJoy1(255,0)
    test.Snap("verify indicator in top right")
    apple2.SetJoy1(255,255)
    test.Snap("verify indicator in bottom right")
    apple2.SetJoy1(0,255,0)
    test.Snap("verify indicator in bottom left")
    apple2.SetJoy1(128,128,0)
    test.Snap("verify indicator in center")

    a2d.CloseWindow()
end)

test.Step(
  "Second Joystick",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/JOYSTICK")

    apple2.SetJoy1(64,64)
    test.Snap("verify single indicator")
    apple2.SetJoy2(192, 192)
    test.Snap("verify second indicator")
end)
