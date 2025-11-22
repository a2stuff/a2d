--[[ BEGINCONFIG ========================================

MODEL="apple2e"
MODELARGS="-gameio joy -sl2 mouse -sl7 cffa202 -aux ext80"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]--

function SetJoy1(x,y)
  machine.ioport.ports[":gameio:joy:joystick_1_x"].fields["P1 Joystick X"]:set_value(x)
  machine.ioport.ports[":gameio:joy:joystick_1_y"].fields["P1 Joystick Y"]:set_value(y)
  emu.wait(1/10)
end
function SetJoy2(x,y)
  machine.ioport.ports[":gameio:joy:joystick_2_x"].fields["P2 Joystick X"]:set_value(x)
  machine.ioport.ports[":gameio:joy:joystick_2_y"].fields["P2 Joystick Y"]:set_value(y)
  emu.wait(1/10)
end

test.Step(
  "Joystick Limits",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/JOYSTICK")

    SetJoy1(0,0)
    test.Snap("verify indicator in top left")
    SetJoy1(255,0)
    test.Snap("verify indicator in top right")
    SetJoy1(255,255)
    test.Snap("verify indicator in bottom right")
    SetJoy1(0,255,0)
    test.Snap("verify indicator in bottom left")
    SetJoy1(128,128,0)
    test.Snap("verify indicator in center")

    a2d.CloseWindow()
end)

test.Step(
  "Second Joystick",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/JOYSTICK")

    SetJoy1(64,64)
    test.Snap("verify single indicator")
    SetJoy2(192, 192)
    test.Snap("verify second indicator")
end)
