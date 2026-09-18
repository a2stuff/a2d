--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl6 superdrive -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -flop1 full_800k.2mg -flop2 empty_800k.2mg"

======================================== ENDCONFIG ]]

--[[
  Launch DeskTop. Special > Copy Disk.... Select a source disk and a
  destination disk. Cancel the copy. Verify that the OK button is
  disabled.
]]
test.Step(
  "OK button resets after cancel",
  function()
    desktop.CopyDisk()
    a2dtest.ConfigureForDiskCopy()

    -- select source
    apple2.UpArrowKey() -- S6D2
    apple2.UpArrowKey() -- S6D1
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    -- select destination
    apple2.UpArrowKey() -- S6D2
    a2d.DialogOK()

    -- insert source
    a2dtest.WaitForAlert({match="Insert the source disk"})
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert({match="Insert the destination disk"})
    a2d.DialogOK()

    -- confirm overwrite
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()

    -- copying...
    emu.wait(20) -- cancel copy
    apple2.EscapeKey() -- cancel
    a2dtest.WaitForAlert({match="not completed"})
    a2d.DialogOK()

    a2dtest.WaitForSystemTask()
    test.ExpectNotMatch(a2dtest.OCRScreen(), "OK", "the OK button should be disabled")

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2dtest.ConfigureForDeskTop()
    a2d.WaitForDesktopReady()
end)


--[[
  Launch DeskTop. Special > Copy Disk.... Select a source disk and a
  destination disk. Allow the copy to complete. Verify that the OK
  button is disabled.

  Launch DeskTop. Special > Copy Disk. Copy a disk with more than 999
  blocks. Verify thousands separators are shown in block counts.
]]
test.Step(
  "OK button reset after success",
  function()
    desktop.CopyDisk()
    a2dtest.ConfigureForDiskCopy()

    -- select source
    apple2.UpArrowKey() -- S6D2
    apple2.UpArrowKey() -- S6D1
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    -- select destination
    apple2.UpArrowKey() -- S6D2
    a2d.DialogOK()

    -- insert source
    a2dtest.WaitForAlert({match="Insert the source disk"})
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert({match="Insert the destination disk"})
    a2d.DialogOK()

    -- confirm overwrite
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()

    -- copying...
    a2dtest.WaitForAlert({timeout=480, match="successful"})
    local ocr = a2dtest.OCRScreen()
    test.ExpectMatch(ocr, "Blocks to transfer: %d+,%d+",
                "the transfer block count should have thousands separator")
    test.ExpectMatch(ocr, "Blocks Read: %d+,%d+",
                "the read block count should have thousands separator")
    test.ExpectMatch(ocr, "Blocks Written: %d+,%d+",
                "the written block count should have thousands separator")
    test.ExpectNotMatch(ocr, "Press Esc to stop copying",
                "the tip should be erased")
    a2d.DialogOK()

    a2dtest.WaitForSystemTask()
    test.ExpectNotMatch(a2dtest.OCRScreen(), "OK", "the OK button should be disabled")

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2dtest.ConfigureForDeskTop()
    a2d.WaitForDesktopReady()
end)
