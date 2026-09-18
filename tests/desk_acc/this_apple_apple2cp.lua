--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS="-ramsize 1152K"
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]

--[[
  Run DeskTop on a IIc+. Apple Menu > About This Apple II. Verify that
  a ZIP CHIP is not reported.
]]
test.Step(
  "No ZIP on IIc+",
  function()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.ABOUT_THIS_APPLE_II)
    a2dtest.WaitForSystemTask()
    test.ExpectNotIMatch(a2dtest.OCRFrontWindowContent(), "ZIP CHIP",
                "a ZIP CHIP should not be not reported")
end)
