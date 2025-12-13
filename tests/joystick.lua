--[[ BEGINCONFIG ========================================

MODEL="apple2e"
MODELARGS="-gameio joy -sl2 mouse -sl7 cffa202 -aux ext80"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

--[[
  Configure a system with a single joystick. Run the DA. Move the
  joystick to the right and bottom extremes. Verify that the indicator
  does not wrap to the left or top edges.
]]
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

--[[
  Configure a system with only a single joystick (or paddles 0 and 1).
  Run the DA. Verify that only a single indicator is shown.

  Configure a system with two joysticks (or paddles 2 and 3). Run the
  DA. Verify that after the second joystick is moved, a second
  indicator is shown.
]]
test.Step(
  "Second Joystick",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/JOYSTICK")

    apple2.SetJoy1(64,64)
    test.Snap("verify single indicator")
    apple2.SetJoy2(192, 192)
    test.Snap("verify second indicator")
end)
