--[[ BEGINCONFIG ========================================

MODEL="apple2c4"
MODELARGS="-gameio joy"
DISKARGS="-flop1 $FLOP1IMG -flop2 $FLOP2IMG"

======================================== ENDCONFIG ]]--

--[[============================================================

  "System Speed" tests

  ============================================================]]--

-- Wait for DeskTop to start
emu.wait(50) -- floppy drives are slow

test.Step(
  "Normal + OK doesn't crash",
  function()
    a2d.OpenPath("/A2.DESKTOP.2/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    emu.wait(5) -- floppy drives are slow
    apple2.Type("N")
    a2d.DialogOK()
    a2d.CloseAllWindows()
    -- TODO: Expect still running
end)

test.Step(
  "Fast + OK doesn't crash",
  function()
    a2d.OpenPath("/A2.DESKTOP.2/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    emu.wait(5) -- floppy drives are slow
    apple2.Type("F")
    a2d.DialogOK()
    a2d.CloseAllWindows()
    -- TODO: Expect still running
end)

test.Step(
  "IIc - speed doesn't affect DHR display",
  function()
    a2d.OpenPath("/A2.DESKTOP.2/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    emu.wait(5) -- floppy drives are slow
    apple2.Type("N")
    apple2.Type("F")
    test.Expect(apple2.ReadSSW("RDDHIRES") < 128, "Should still be in DHR mode")
    a2d.CloseAllWindows()
end)

test.Step(
  "Animation shields cursor correctly",
  function()
    a2d.OpenPath("/A2.DESKTOP.2/APPLE.MENU/CONTROL.PANELS/SYSTEM.SPEED")
    emu.wait(5) -- floppy drives are slow
    a2d.InMouseKeysMode(function(m)
        m.GoToApproximately(115,124)
        for i=1,15 do
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
