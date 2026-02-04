a2d.ConfigureRepaintTime(1)

--[[
  Run System Speed DA. Click Normal then click OK. Verify DeskTop does
  not lock up.

  Run System Speed DA. Click Fast then click OK. Verify DeskTop does
  not lock up.
]]
test.Step(
  "Normal + OK / Fast + OK doesn't crash",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    apple2.Type("N") -- Normal Speed
    a2d.DialogOK()
    emu.wait(1) -- slow now
    a2d.CloseAllWindows()
    emu.wait(1) -- slow now
    a2dtest.ExpectNotHanging()

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    apple2.Type("F") -- Fast Speed
    a2d.DialogOK()
    a2d.CloseAllWindows()
    a2dtest.ExpectNotHanging()
end)

--[[
  Run System Speed DA. Position the cursor to the left of the
  animation, where it is not flickering, and move it up and down.
  Verify that stray pixels are not left behind by the animation.
]]
test.Step(
  "Animation shields cursor correctly",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")

    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x-20, dialog_y+56)
        for i=1, 15 do
          m.Up(2)
          emu.wait(0.15)
          test.Snap("visually confirm no garbage")
          m.Down(2)
          emu.wait(0.15)
          test.Snap("visually confirm no garbage")
        end
    end)
    a2d.DialogOK()
    a2d.CloseAllWindows()
end)
