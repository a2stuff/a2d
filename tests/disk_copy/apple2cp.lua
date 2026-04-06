--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS=""
DISKARGS="-flop1 prodos_floppy1.dsk -flop2 prodos_floppy2.dsk -flop3 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(2)

--[[
  On an Apple IIc, copy a 140k disk from one to another. Before the
  copy starts, move the mouse. Verify no hang after the copy is
  complete.

  This exercises a bug where the disk copy trashes the Aux copy of the
  vectors at $FFFx. https://github.com/a2stuff/a2d/issues/900
]]
test.Step(
  "no hang after 140k disk copy",
  function()
    a2d.CopyDisk()

    -- Use Disk Copy so all memory blocks are used.
    a2d.InvokeMenuItem(3, 2) -- Options > Disk Copy

    apple2.DownArrowKey() -- S5,D1
    apple2.DownArrowKey() -- S6,D1
    a2d.WaitForRepaint()
    a2d.DialogOK()

    apple2.DownArrowKey() -- S6,D1
    apple2.DownArrowKey() -- S6,D2
    a2d.WaitForRepaint()
    a2d.DialogOK()

    -- insert source
    a2dtest.WaitForAlert({match="Insert the source disk"})
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert({match="Insert the destination disk"})
    a2d.DialogOK()

    -- confirmation
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()

    -- Wait for formatting to finish, since that blocks everything
    util.WaitFor(
      "formatting complete", function()
        return a2dtest.OCRScreen():match("Reading%.%.%.")
    end)

    -- Generate some mouse activity, which should fire interrupts
    for i = 1, 10 do
      apple2.MoveMouse(100, 100)
      apple2.MoveMouse(-100, -100)
    end

    -- complete
    a2dtest.WaitForAlert({timeout=120, match="The copy was successful"})
    a2d.DialogOK()

    -- Generate some mouse activity, which should fire interrupts
    for i = 1, 5 do
      apple2.MoveMouse(100, 100)
      apple2.MoveMouse(-100, -100)
    end

    -- verify no hang
    a2d.OpenMenu(1) -- Apple
    apple2.DownArrowKey()
    test.ExpectMatch(a2dtest.OCRScreen({invert=true}), "Apple II DeskTop Version")
end)

