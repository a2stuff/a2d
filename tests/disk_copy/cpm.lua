--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 cpm_floppy.dsk -flop2 prodos_floppy1.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Launch DeskTop. Special > Copy Disk.... Select a CP/M disk as a
  source disk. Verify that after the "Insert source disk" prompt is
  dismissed, no volume name appears on the "Source" line, and that
  there is no line immediately above incorrectly identifying the
  source disk type.
]]
test.Step(
  "CP/M Pascal disk names in source label",
  function()
    a2d.CopyDisk()

    -- source
    apple2.DownArrowKey() -- S7,D1
    apple2.DownArrowKey() -- S6,D1
    a2d.DialogOK()

    -- destination
    apple2.DownArrowKey() -- S6,D1
    apple2.DownArrowKey() -- S6,D2
    a2d.DialogOK()

    -- insert source
    a2dtest.WaitForAlert({match="Insert the source disk"})
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert({match="Insert the destination disk"})

    local ocr = a2dtest.OCRScreen()
    test.ExpectNotMatch(ocr, "disk copy",
                "should be no status line identifying disk type")
    test.ExpectMatch(ocr, "Source .* Slot 6 +Drive 1 +\n",
                "should be no volume name after Source label")

    -- cleanup
    a2d.DialogCancel()
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Special > Copy Disk.... Select a CP/M disk as a
  destination disk. Verify that in the "Are you sure you want to erase
  ...?" dialog that the prompt describes the disk using slot and
  drive, and is not quoted.
]]
test.Step(
  "CP/M disk names in overwrite prompt",
  function()
    a2d.CopyDisk()

    -- source
    apple2.DownArrowKey() -- S7,D1
    apple2.DownArrowKey() -- S6,D1
    apple2.DownArrowKey() -- S6,D2
    a2d.DialogOK()

    -- destination
    apple2.DownArrowKey() -- S6,D1
    a2d.DialogOK()

    -- insert source
    a2dtest.WaitForAlert({match="Insert the source disk"})
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert({match="Insert the destination disk"})
    a2d.DialogOK()

    -- confirmation
    a2dtest.WaitForAlert({match="Are you sure you want to erase the disk in slot"})

    -- cleanup
    a2d.DialogCancel()
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)
