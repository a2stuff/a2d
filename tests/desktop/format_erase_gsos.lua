--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -flop1 res/gsos_floppy.dsk"

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
    apple2.DownArrowKey() -- select S7D1
    apple2.DownArrowKey() -- select S6D1
    a2d.DialogOK()

    -- Enter new name
    apple2.Type("NEW.NAME")
    a2d.DialogOK()

    -- Confirmation prompt
    a2dtest.WaitForAlert()
    test.Snap("verify prompt says GS/OS disk name with assigned case")

    a2d.DialogCancel()
end)
