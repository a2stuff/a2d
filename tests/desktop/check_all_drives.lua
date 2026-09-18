-- NOTE: Need at least one empty Disk II drive

test.Step(
  "No error if floppy is empty",
  function()
    a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_CHECK_ALL_DRIVES)
    a2dtest.WaitForSystemTask()
    a2dtest.ExpectAlertNotShowing()
end)
