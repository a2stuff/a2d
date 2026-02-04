--[[ BEGINCONFIG ========================================

MODEL="las128e2"
MODELARGS="-ramsize 1152K"
DISKARGS="-flop1 $FLOP1IMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(3) -- slow floppies

--[[
  Run on Laser 128 with memory expansion. Launch DeskTop. Copy a file
  to `/RAM5`. Apple Menu > About This Apple II, close it. Verify that
  the file is still present on `/RAM5`.
]]
test.Step(
  "About This Apple doesn't mess up RAM5",
  function()
    a2d.CopyPath("/A2.DESKTOP.1/READ.ME", "/RAM5")

    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(5)
    a2d.CloseWindow()

    a2d.OpenPath("/RAM5")
    a2d.SelectAll()
    test.ExpectEqualsIgnoreCase(a2dtest.GetSelectedIconName(), "READ.ME", "file should still be present")
end)
