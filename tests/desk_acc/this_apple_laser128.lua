--[[ BEGINCONFIG ========================================

MODEL="las128e2"
MODELARGS="-ramsize 1152K"
DISKARGS="-flop1 $FLOP1IMG"

======================================== ENDCONFIG ]]

--[[
  Run on Laser 128 with memory expansion. Launch DeskTop. Copy a file
  to `/RAM5`. Apple Menu > About This Apple II, close it. Verify that
  the file is still present on `/RAM5`.
]]
test.Step(
  "About This Apple doesn't mess up RAM5",
  function()
    desktop.CopyPath("/A2.DESKTOP.1/READ.ME", "/RAM5")

    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.ABOUT_THIS_APPLE_II)
    a2dtest.WaitForSystemTask()
    desktop.CloseWindow()

    desktop.OpenWindow("/RAM5")
    desktop.SelectAll()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "file should still be present")
end)
