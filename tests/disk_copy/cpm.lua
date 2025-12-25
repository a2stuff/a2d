--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -flop1 res/cpm_floppy.dsk -flop2 res/prodos_floppy1.dsk"

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
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
    a2d.WaitForDesktopReady()

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
    test.Snap("verify no status line identifying disk type")
    test.Snap("verify no volume name after Source label")

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
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
    a2d.WaitForDesktopReady()

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
    test.Snap("verify prompt gives S6,D1 but no disk type and is not quoted")

    -- cleanup
    a2d.DialogCancel()
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)
