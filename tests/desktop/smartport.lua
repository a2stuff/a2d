--[[ BEGINCONFIG ==================================================

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

================================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

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
      a2d.CopyPath("/TESTS/PRODOS/PRODOS.203", "/A2.DESKTOP")
      a2d.RenamePath("/A2.DESKTOP/PRODOS", "PRODOS.24")
      a2d.RenamePath("/A2.DESKTOP/PRODOS.203", "PRODOS")
      a2d.CloseAllWindows()
      a2d.Reboot()
      a2d.WaitForDesktopReady()
    end

    a2d.CloseAllWindows()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK-2)
    test.Snap("verify hard drives in S7,D1/2, S5D1/2 and S2,D1/2 (mirrored)")
    a2d.DialogCancel()

    for i, name in ipairs({"A", "B", "C", "D"}) do
      a2d.CopyPath("/A2.DESKTOP/READ.ME", "/"..name)
      a2d.CloseAllWindows()
      a2d.ClearSelection()
      a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK-2)
      for j = 1, i+2 do -- skip over S7,D1/2
        apple2.DownArrowKey()
      end
      a2d.DialogOK()
      apple2.Type(name) -- should match existing, so no alert
      a2d.DialogOK()
      a2dtest.WaitForAlert() -- confirmation, not new name
      a2d.DialogOK()
      emu.wait(5)
      a2d.OpenPath("/"..name)
      a2d.SelectAll()
      test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "should have been formatted")
    end
    a2d.CloseAllWindows()

    if version == 2.0 then
      a2d.DeletePath("/A2.DESKTOP/PRODOS")
      a2d.RenamePath("/A2.DESKTOP/PRODOS.24", "PRODOS")
      a2d.CloseAllWindows()
      a2d.Reboot()
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
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 7, "expect Trash plus 6 volumes")
end)
