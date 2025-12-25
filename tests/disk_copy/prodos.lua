--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -flop1 res/prodos_floppy1.dsk -flop2 res/prodos_floppy2.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Launch DeskTop. Special > Copy Disk.... Verify that ProDOS disk
  names in the device list have adjusted case (e.g. "Volume" not
  "VOLUME").
]]
test.Step(
  "ProDOS disk names in list",
  function()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
    a2d.WaitForDesktopReady()

    test.Snap("verify ProDOS disk names in list are adjusted case")

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Special > Copy Disk.... Select a ProDOS disk as a
  source disk. Verify that after the "Insert source disk" prompt is
  dismissed, the volume name appears on the "Source" line and the name
  has adjusted case (e.g. "Volume" not "VOLUME"), and that the line
  above reads "ProDOS disk copy".
]]
test.Step(
  "ProDOS disk names in source label",
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
    test.Snap("verify status line says 'ProDOS disk copy'")
    test.Snap("verify volume name after Source label is case-adjusted")

    -- cleanup
    a2d.DialogCancel()
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Special > Copy Disk.... Select a ProDOS disk as a
  destination disk. Verify that in the "Are you sure you want to erase
  ...?" dialog that the name has adjusted case (e.g. "Volume" not
  "VOLUME"), and the name is quoted.
]]
test.Step(
  "ProDOS disk names in overwrite prompt",
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
    test.Snap("verify prompt gives ProDOS volume name, quoted with adjusted case")

    -- cleanup
    a2d.DialogCancel()
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)
