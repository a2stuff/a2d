--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 pascal_floppy.dsk -flop2 prodos_floppy1.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Launch DeskTop. Special > Copy Disk.... Verify that Pascal disk
  names in the device list do not have adjusted case (e.g. "TGP:" not
  "Tgp:").
]]
test.Step(
  "Pascal disk names in list",
  function()
    a2d.CopyDisk()

    test.Snap("verify Pascal disk name in list is uppercase")

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Special > Copy Disk.... Select a Pascal disk as a
  source disk. Verify that after the "Insert source disk" prompt is
  dismissed, the volume name appears on the "Source" line and the name
  does not have adjusted case (e.g. "TGP:" not "Tgp:"), and that the
  line above reads "Pascal disk copy".
]]
test.Step(
  "Pascal disk names in source label",
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
    test.Snap("verify status line says 'Pascal disk copy'")
    test.Snap("verify volume name after Source label is in uppercase")

    -- cleanup
    a2d.DialogCancel()
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)


--[[
  Launch DeskTop. Special > Copy Disk.... Select a Pascal disk as a
  destination disk. Verify that in the "Are you sure you want to erase
  ...?" dialog that the name does not have adjusted case (e.g. "TGP:"
  not "Tgp:"), and the name is quoted.
]]
test.Step(
  "Pascal disk names in overwrite prompt",
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
    test.Snap("verify prompt gives Pascal disk name, quoted and uppercase")

    -- cleanup
    a2d.DialogCancel()
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)
