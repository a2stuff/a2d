--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 cpm_floppy.dsk"

======================================== ENDCONFIG ]]

--[[
  Launch DeskTop. Run the command. Select a slot/drive containing an
  unformatted disk. Enter a new name and click OK. Verify that the
  confirmation prompt shows "the disk in slot # drive #", without
  quotes.
]]
test.Variants(
  {
    "Format CP/M disk",
    "Erase CP/M disk",
  }, function(idx)
    desktop.ClearSelection()
    a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_FORMAT_DISK-2+idx-1)
    a2dtest.WaitForSystemTask()

    -- Select drive (S6D1)
    desktop.FormatEraseSelectSlotDrive(6, 1)

    -- Enter new name
    apple2.Type("NEW.NAME")
    a2d.DialogOK()

    -- Confirmation prompt
    a2dtest.WaitForAlert({match="erase .*slot.*6.*drive.*1"})

    a2d.DialogCancel()
end)
