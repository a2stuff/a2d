--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS="-ramsize 1152K"
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Run DeskTop on a IIc+. Apple Menu > About This Apple II. Verify that
  a ZIP CHIP is not reported.
]]
test.Step(
  "No ZIP on IIc+",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(5)
    test.ExpectNotIMatch(a2dtest.OCRScreen(), "ZIP CHIP",
                "a ZIP CHIP should not be not reported")
end)
