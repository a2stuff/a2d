--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 memexp -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

--[[
  Attempt to duplicate a file without sufficient space. Verifies
  that the copy fails and there is no prompt to rename.
]]
test.Step(
  "Failed duplicate (due to space)",
  function()
    desktop.CopyPath("/TESTS/COPYING/SIZES/IS.200K", "/RAM1")
    desktop.SelectPath("/RAM1/IS.200K") -- 200K

    desktop.DuplicateSelection("DUPE1") -- 400K
    desktop.DuplicateSelection("DUPE2") -- 600K
    desktop.DuplicateSelection("DUPE3") -- 800K
    desktop.DuplicateSelection("DUPE4") -- 1000K

    local id = mgtk.FrontWindow()
    a2d.OAShortcut("D")
    a2dtest.WaitForAlert({match="too large"})
    local ocr = a2dtest.OCRScreen()
    test.ExpectMatch(ocr, "OK", "OK button should be showing")
    test.ExpectNotMatch(ocr, "Cancel", "Cancel button should not be showing")
    a2d.DialogOK() -- dismiss with OK (should be same as cancel)
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(mgtk.FrontWindow(), id, "rename prompt should not be showing")
    desktop.EraseVolume("RAM1")
end)

--[[
  Attempt to duplicate a GS/OS forked file. Verifies that the copy
  fails and there is no prompt to rename.
]]
test.Step(
  "Failed duplicate of GS/OS forked file",
  function()
    desktop.SelectPath("/TESTS/PROPERTIES/GS.OS.FILES/INSTALLER")

    local id = mgtk.FrontWindow()
    a2d.OAShortcut("D")
    a2dtest.WaitForAlert({match="Unsupported file type"})
    local ocr = a2dtest.OCRScreen()
    test.ExpectMatch(ocr, "OK", "OK button should be showing")
    test.ExpectNotMatch(ocr, "Cancel", "Cancel button should not be showing")
    a2d.DialogOK() -- dismiss with OK (should be same as cancel)
    a2dtest.WaitForSystemTask()
    test.ExpectEquals(mgtk.FrontWindow(), id, "rename prompt should not be showing")
end)
