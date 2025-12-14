--[[ BEGINCONFIG ========================================

MODEL="las128e2"
MODELARGS="-ramsize 1152K"
DISKARGS="-flop1 $FLOP1IMG"

# Doesn't recognize -sl7
# MODELARGS="-ramsize 1152K -sl7 cffa2"
# DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

test.Step(
  "Apple > About This Apple II",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(5)
    test.Snap(manager.machine.system.name)
end)
