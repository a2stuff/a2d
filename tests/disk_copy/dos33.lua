--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 dos33_floppy.dsk -flop2 prodos_floppy1.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Launch DeskTop. Special > Copy Disk.... Verify that DOS 3.3 disk
  names in the device list appear as "DOS 3.3" and do not have
  adjusted case.
]]
test.Step(
  "DOS 3.3 disk names in list",
  function()
    a2d.CopyDisk()

    test.Snap("verify DOS 3.3 disk in list is uppercase")

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Special > Copy Disk.... Select a DOS 3.3 disk as a
  source disk. Verify that after the "Insert source disk" prompt is
  dismissed, no volume name appears on the "Source" line, and that the
  line above reads "DOS 3.3 disk copy".
]]
test.Step(
  "DOS 3.3 disk names in source label",
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
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert()
    test.Snap("verify status line says 'DOS 3.3 disk copy'")
    test.Snap("verify no volume name after Source label")

    -- cleanup
    a2d.DialogCancel()
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Special > Copy Disk.... Select a DOS 3.3 disk as a
  destination disk. Verify that in the "Are you sure you want to erase
  ...?" dialog that the prompt describes the disk as DOS 3.3 using
  slot and drive, and is not quoted.
]]
test.Step(
  "DOS 3.3 disk names in overwrite prompt",
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
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- confirmation
    a2dtest.WaitForAlert()
    test.Snap("verify prompt references DOS 3.3 disk in S6,D1 with no name and no quote")

    -- cleanup
    a2d.DialogCancel()
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)
