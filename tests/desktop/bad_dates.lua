--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

test.Step(
  "bad file date in list view",
  function()
    a2d.OpenWindow("/TESTS/DATES/BAD.DATE")
    a2d.GrowWindowBy(200, 0)
    a2d.InvokeMenuItem(a2d.VIEW_MENU, a2d.VIEW_BY_DATE)
    a2dtest.WaitForSystemTask()
    test.ExpectMatch(a2dtest.OCRScreen(), "no date", "file should have no date")
    a2d.CloseAllWindows()
end)

test.Step(
  "bad file date in Get Info window",
  function()
    a2d.SelectPath("/TESTS/DATES/BAD.DATE/BAD")
    a2d.OAShortcut("I") -- File > Get Info
    a2dtest.WaitForSystemTask()
    test.ExpectMatch(a2dtest.OCRScreen(), "no date", "file should have no date")
    a2d.DialogCancel()
    a2d.CloseAllWindows()
end)

