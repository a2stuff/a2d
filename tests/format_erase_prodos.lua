--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -flop1 res/prodos_floppy1.dsk"

======================================== ENDCONFIG ]]--

--[[
  Launch DeskTop. Run the command. Select a slot/drive containing an
  existing volume. Enter a new name and click OK. Verify that the
  confirmation prompt shows the volume with adjusted case matching the
  volume's icon, with quotes around the name.
]]--
test.Variants(
  {
    "Format ProDOS disk",
    "Erase ProDOS disk",
  }, function(idx)
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK-2+idx-1)

    -- Select drive (S6D1)
    apple2.DownArrowKey() -- select S7D1
    apple2.DownArrowKey() -- select S6D1
    a2d.DialogOK()

    -- Enter new name
    apple2.Type("NEW.NAME")
    a2d.DialogOK()

    -- Confirmation prompt
    a2dtest.ExpectAlertShowing()
    test.Snap("verify prompt says ProDOS disk name with adjusted case")

    a2d.DialogCancel()
end)
