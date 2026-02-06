--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 pascal_floppy.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(5)

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
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK-2+idx-1)

    -- Select drive (S6D1)
    a2d.FormatEraseSelectSlotDrive(6, 1)

    -- Enter new name
    apple2.Type("NEW.NAME")
    a2d.DialogOK()

    -- Confirmation prompt
    a2dtest.WaitForAlert()
    test.Expect(a2dtest.OCRScreen():find("erase \"TK:\""),
                "prompt should name Pascal disk in uppercase")

    a2d.DialogCancel()
end)
