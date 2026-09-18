--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 prodos_floppy1.dsk"

======================================== ENDCONFIG ]]

--[[
  Launch DeskTop. Run the command. Select a slot/drive containing an
  existing volume. Enter a new name and click OK. Verify that the
  confirmation prompt shows the volume with adjusted case matching the
  volume's icon, with quotes around the name.
]]
test.Variants(
  {
    "Format ProDOS disk",
    "Erase ProDOS disk",
  }, function(idx)
    desktop.ClearSelection()
    a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_FORMAT_DISK-2+idx-1)
    a2dtest.WaitForSystemTask()

    -- Select drive (S6D1)
    desktop.FormatEraseSelectSlotDrive(6, 1)

    -- Enter new name
    a2d.ClearTextField()
    apple2.Type("NEW.NAME")
    a2d.DialogOK()

    -- Confirmation prompt
    a2dtest.WaitForAlert({match="erase \"Floppy1\""})

    a2d.DialogCancel()
end)
