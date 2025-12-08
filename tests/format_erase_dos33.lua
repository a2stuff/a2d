--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -flop1 res/dos33_floppy.dsk"

======================================== ENDCONFIG ]]--

test.Variants(
  {
    "Format DOS 3.3 disk",
    "Erase DOS 3.3 disk",
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
    test.Snap("verify prompt says DOS 3.3 disk in slot 6, drive 1")
    
    a2d.DialogCancel()
end)
