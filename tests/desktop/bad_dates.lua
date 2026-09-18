--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

test.Step(
  "bad file date in list view",
  function()
    desktop.OpenWindow("/TESTS/DATES/BAD.DATE")
    desktop.GrowWindowBy(200, 0)
    a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_DATE)
    a2dtest.WaitForSystemTask()
    test.ExpectMatch(a2dtest.OCRScreen(), "no date", "file should have no date")
    desktop.CloseAllWindows()
end)

test.Step(
  "bad file date in Get Info window",
  function()
    desktop.SelectPath("/TESTS/DATES/BAD.DATE/BAD")
    a2d.OAShortcut("I") -- File > Get Info
    a2dtest.WaitForSystemTask()
    test.ExpectMatch(a2dtest.OCRScreen(), "no date", "file should have no date")
    a2d.DialogCancel()
    desktop.CloseAllWindows()
end)

