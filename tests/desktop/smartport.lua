--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
  MODELARGS="-sl2 mouse -sl5 scsi -sl6 '' -sl7 cffa2 \
  -sl5:scsi:scsibus:1 ''                    \
  -sl5:scsi:scsibus:3 harddisk              \
  -sl5:scsi:scsibus:4 harddisk              \
  -sl5:scsi:scsibus:5 harddisk              \
  -sl5:scsi:scsibus:6 harddisk              \
  "
DISKARGS="\
  -hard1 disk_d.2mg \
  -hard2 disk_c.2mg \
  -hard3 disk_b.2mg \
  -hard4 disk_a.2mg \
  -hard5 $HARDIMG \
  -hard6 tests.hdv \
  "

======================================== ENDCONFIG ]]

--[[
  Configure a system with more than 2 drives on a SmartPort
  controller. Boot ProDOS 2.4 (any patch version). Launch DeskTop.
  Special > Format Disk. Verify that correct device names are shown
  for the mirrored drives.

  Configure a system with more than 2 drives on a SmartPort
  controller. Boot into ProDOS 2.0.1, 2.0.2, or 2.0.3. Launch DeskTop.
  Special > Format Disk. Verify that correct device names are shown
  for the mirrored drives.
]]
test.Variants(
  {
    {"Device names - ProDOS 2.4", 2.4},
    {"Device names - ProDOS 2.0", 2.0},
  },
  function(idx, name, version)
    if version == 2.0 then
      desktop.CopyPath("/TESTS/PRODOS/PRODOS.203", "/A2.DESKTOP")
      desktop.RenamePath("/A2.DESKTOP/PRODOS", "PRODOS.24")
      desktop.RenamePath("/A2.DESKTOP/PRODOS.203", "PRODOS")
      desktop.CloseAllWindows()
      desktop.Reboot()
      a2d.WaitForDesktopReady()
    end

    desktop.CloseAllWindows()
    desktop.ClearSelection()
    a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_FORMAT_DISK-2)
    a2dtest.WaitForSystemTask()

    local ocr = a2dtest.OCRScreen()
    test.ExpectIMatch(ocr, "S7,D1: Compact Flash", "S7,D1 HD should be present")
    test.ExpectIMatch(ocr, "S7,D2: Compact Flash", "S7,D1 HD should be present")
    test.ExpectIMatch(ocr, "S5,D1: Seagate", "S5,D1 should be present")
    test.ExpectIMatch(ocr, "S5,D2: Seagate", "S5,D2 should be present")
    test.ExpectIMatch(ocr, "S2,D1: Seagate", "S2,D1 (mirrored) should be present")
    test.ExpectIMatch(ocr, "S2,D2: Seagate", "S2,D2 (mirrored) should be present")

    a2d.DialogCancel()

    for i, name in ipairs({"A", "B", "C", "D"}) do
      desktop.CopyPath("/A2.DESKTOP/READ.ME", "/"..name)
      desktop.CloseAllWindows()
      desktop.ClearSelection()
      a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_FORMAT_DISK-2)
      for j = 1, i+2 do -- skip over S7,D1/2
        apple2.DownArrowKey()
      end
      a2d.DialogOK()
      a2dtest.WaitForSystemTask()
      apple2.Type(name) -- should match existing, so no alert
      a2d.DialogOK()
      a2dtest.WaitForSystemTask()
      a2dtest.WaitForAlert({match="Are you sure"})
      a2d.DialogOK()
      a2dtest.WaitForSystemTask()
      desktop.OpenWindow("/"..name)
      desktop.SelectAll()
      test.ExpectEquals(#desktop.GetSelectedIcons(), 0, "should have been formatted")
    end
    desktop.CloseAllWindows()

    if version == 2.0 then
      desktop.DeletePath("/A2.DESKTOP/PRODOS")
      desktop.RenamePath("/A2.DESKTOP/PRODOS.24", "PRODOS")
      desktop.CloseAllWindows()
      desktop.Reboot()
      a2d.WaitForDesktopReady()
    end
end)

--[[
  Run on a system with a single slot providing 3 or 4 drives (e.g.
  CFFA, BOOTI, Floppy Emu); verify that all show up.
]]
test.Step(
  "mirrored drives show up",
  function()
    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 7, "expect Trash plus 6 volumes")
end)
