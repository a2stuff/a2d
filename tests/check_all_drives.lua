--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]
-- NOTE: Need at least one empty Disk II drive

a2d.ConfigureRepaintTime(5)

test.Step(
  "No error if floppy is empty",
  function()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_CHECK_ALL_DRIVES)
    a2d.WaitForRepaint()
    a2dtest.ExpectAlertNotShowing()
end)
