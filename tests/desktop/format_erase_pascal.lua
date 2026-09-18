--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 pascal_floppy.dsk"

======================================== ENDCONFIG ]]

--[[
  Launch DeskTop. Run the command. Select a slot/drive containing a
  Pascal disk. Enter a new name and click OK. Verify that the
  confirmation prompt shows the Pascal volume name (e.g. "TGP:"), with
  quotes around the name.
]]
test.Variants(
  {
    "Format Pascal disk",
    "Erase Pascal disk",
  }, function(idx)
    desktop.ClearSelection()
    a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_FORMAT_DISK-2+idx-1)

    -- Select drive (S6D1)
    desktop.FormatEraseSelectSlotDrive(6, 1)

    -- Enter new name
    apple2.Type("NEW.NAME")
    a2d.DialogOK()

    -- Confirmation prompt
    a2dtest.WaitForAlert({match="erase \"TK:\""})

    a2d.DialogCancel()
end)
