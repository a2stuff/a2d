--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl5 superdrive -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -flop1 pascal_800k.woz -flop2 empty_800k.2mg -flop3 pascal_floppy.dsk -flop4 prodos_floppy1.dsk"

======================================== ENDCONFIG ]]

--[[
  Source drive list:
  * S7,D1 - A2.DeskTop  (ProDOS 800K)
  * S5,D1 - 1PASCAL:    (Pascal 800K)
  * S5,D2 - EMPTY       (ProDOS 800K)
  * S6,D1 - TK:         (Pascal 140K)
  * S6,D2 - Floppy1     (ProDOS 140K)

  800K destination drive list:
  * S7,D1 - A2.DeskTop  (ProDOS 800K)
  * S5,D1 - 1PASCAL:    (Pascal 800K)
  * S5,D2 - EMPTY       (ProDOS 800K)

  140K destination drive list:
  * S6,D1 - TK:         (Pascal 140K)
  * S6,D2 - Floppy1     (ProDOS 140K)
]]

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

    local ocr = a2dtest.OCRScreen()
    test.Expect(ocr:find("1PASCAL:"), "Pascal disk names in list should be in uppercase")
    test.Expect(ocr:find("TK:"), "Pascal disk names in list should be in uppercase")

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
test.Variants(
  {
    {"Pascal disk names in source label - 140K", 4, 2, "TK:"},
    {"Pascal disk names in source label - 800K", 2, 3, "1PASCAL:"},
  },
  function(idx, name, source_index, dest_index, disk_name)
    a2d.CopyDisk()

    -- source
    for i = 1, source_index do
      apple2.DownArrowKey()
    end
    a2d.DialogOK()

    -- destination
    for i = 1, dest_index do
      apple2.DownArrowKey()
    end
    a2d.DialogOK()

    -- insert source
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert()
    local ocr = a2dtest.OCRScreen()
    test.Expect(ocr:find("Pascal disk copy"), "status line should say 'Pascal disk copy'")
    test.Expect(ocr:find("Source .* " .. disk_name), "volume name after Source label should be uppercase")

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
test.Variants(
  {
    {"Pascal disk names in overwrite prompt - 140K", 5, 1, "TK:"},
    {"Pascal disk names in overwrite prompt - 800K", 3, 2, "1PASCAL:"},
  },
  function(idx, name, source_index, dest_index, disk_name)
    a2d.CopyDisk()

    -- source
    for i = 1, source_index do
      apple2.DownArrowKey()
    end
    a2d.DialogOK()

    -- destination
    for i = 1, dest_index do
      apple2.DownArrowKey()
    end
    a2d.DialogOK()

    -- insert source
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- confirmation
    a2dtest.WaitForAlert()
    test.Expect(a2dtest.OCRScreen():find(
                  "Are you sure you want to erase \""..disk_name.. "\"%?"),
                "prompt should give Pascal disk name, quoted and uppercase")

    -- cleanup
    a2d.DialogCancel()
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)
