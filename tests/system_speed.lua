--[[ BEGINCONFIG ========================================

MODEL="apple2c4"
MODELARGS=""
DISKARGS="-flop1 $FLOP1IMG -flop2 $FLOP2IMG"

======================================== ENDCONFIG ]]--


-- Wait for DeskTop to start
emu.wait(50) -- floppy drives are slow


--[[
  Run System Speed DA. Click Normal then click OK. Verify DeskTop does
  not lock up.
]]--
test.Step(
  "Normal + OK doesn't crash",
  function()
    a2d.OpenPath("/A2.DESKTOP.2/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    emu.wait(5) -- floppy drives are slow
    apple2.Type("N") -- Normal Speed
    a2d.DialogOK()
    a2d.CloseAllWindows()
    a2dtest.ExpectNotHanging()
end)

--[[
  Run System Speed DA. Click Fast then click OK. Verify DeskTop does
  not lock up.
]]--
test.Step(
  "Fast + OK doesn't crash",
  function()
    a2d.OpenPath("/A2.DESKTOP.2/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    emu.wait(5) -- floppy drives are slow
    apple2.Type("F") -- Fast Speed
    a2d.DialogOK()
    a2d.CloseAllWindows()
    a2dtest.ExpectNotHanging()
end)

--[[
  Run DeskTop on a IIc. Launch Control Panel > System Speed. Click
  Normal and Fast. Verify that the display does not switch from DHR to
  HR.
]]--
test.Step(
  "IIc - speed doesn't affect DHR display",
  function()
    a2d.OpenPath("/A2.DESKTOP.2/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    emu.wait(5) -- floppy drives are slow
    apple2.Type("N") -- Normal Speed
    apple2.Type("F") -- Fast Speed
    test.Expect(apple2.ReadSSW("RDDHIRES") < 128, "Should still be in DHR mode")
    a2d.CloseAllWindows()
end)

--[[
  Run System Speed DA. Position the cursor to the left of the
  animation, where it is not flickering, and move it up and down.
  Verify that stray pixels are not left behind by the animation.
]]--
test.Step(
  "Animation shields cursor correctly",
  function()
    a2d.OpenPath("/A2.DESKTOP.2/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    emu.wait(5) -- floppy drives are slow

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
        a2d.CloseAllWindows()
    end)
end)
