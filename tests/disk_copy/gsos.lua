--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -flop1 res/gsos_floppy.dsk -flop2 res/prodos_floppy1.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Launch DeskTop. Special > Copy Disk.... Verify that ProDOS disk
  names in the device list have adjusted case (e.g. "Volume" not
  "VOLUME"). Verify that GS/OS disk names in the device list have
  correct case (e.g. "GS.OS.disk" not "Gs.Os.Disk").
]]
test.Step(
  "GS/OS disk names in list",
  function()
    a2d.CopyDisk()

    test.Snap("verify GS/OS disk names in list have assigned case")

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Special > Copy Disk.... Select a GS/OS disk as a
  source disk. Verify that after the "Insert source disk" prompt is
  dismissed, the volume name appears on the "Source" line and the name
  has correct case (e.g. "GS.OS.disk" not "Gs.Os.Disk"), and that the
  line above reads "ProDOS disk copy".
]]
test.Step(
  "GS/OS disk names in source label",
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
    test.Snap("verify status line says 'ProDOS disk copy'")
    test.Snap("verify volume name after Source label has assigned case")

    -- cleanup
    a2d.DialogCancel()
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Special > Copy Disk.... Select a GS/OS disk as a
  destination disk. Verify that in the "Are you sure you want to erase
  ...?" dialog that the name has correct case (e.g. "GS.OS.disk" not
  "Gs.Os.Disk"), and the name is quoted.
]]
test.Step(
  "GS/OS disk names in overwrite prompt",
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
    test.Snap("verify prompt gives GS/OS name, quoted with assigned case")

    -- cleanup
    a2d.DialogCancel()
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)
