--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl6 cffa2 -sl7 cffa2"
DISKARGS="-hard3 $HARDIMG -hard1 sizes/image_511_blocks.hdv -hard2 sizes/image_511_blocks.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Disk Copy with 511 blocks. Verify block count is correct.
]]
test.Variants(
  {
    {"Quick Copy 511 blocks", "quick"},
    {"Disk Copy 511 blocks", "disk"},
  },
  function(idx, name, what)
    a2dtest.WaitForAlert() -- duplicate volume
    a2d.DialogOK()

    a2d.CopyDisk()

    a2d.InvokeMenuItem(3, idx) -- Options > Quick Copy or Disk Copy

    -- select source
    apple2.UpArrowKey() -- S6D2
    apple2.UpArrowKey() -- S6D1
    a2d.WaitForRepaint()
    a2d.DialogOK()

    -- select destination
    apple2.UpArrowKey() -- S6D2
    a2d.WaitForRepaint()
    a2d.DialogOK()

    -- insert source
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- confirmation
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- complete
    a2dtest.WaitForAlert({timeout=7200})
    if what == "quick" then
      test.Snap("verify block counts are equal")
    else
      test.Snap("verify total block counts are 511")
    end
    a2d.DialogOK()

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)
