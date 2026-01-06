--[[ BEGINCONFIG ========================================

MODEL="apple2c0"
MODELARGS=""
DISKARGS="-flop1 $FLOP1IMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

test.Step(
  "Apple > About This Apple II",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(10)
    test.Snap(manager.machine.system.name)
end)
