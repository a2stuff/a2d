--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 gsos_floppy.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(5)

--[[
  Launch DeskTop. Run the command. Select a slot/drive containing an
  existing volume with a GS/OS-cased name and click OK. Enter a new
  name and click OK. Verify that the confirmation prompt shows the
  volume with the correct case matching the volume's icon, with quotes
  around the name.
]]
test.Variants(
  {
    "Format GS/OS disk",
    "Erase GS/OS disk",
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
    test.Expect(a2dtest.OCRScreen():find("erase \"GS%.OS%.mixed\""),
                "prompt should say GS/OS disk name with assigned case")

    a2d.DialogCancel()
end)
