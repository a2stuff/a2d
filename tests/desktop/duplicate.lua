--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 memexp -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Attempt to duplicate a file without sufficient space. Verifies
  that the copy fails and there is no prompt to rename.
]]
test.Step(
  "Failed duplicate (due to space)",
  function()
    a2d.CopyPath("/TESTS/COPYING/SIZES/IS.200K", "/RAM1")
    a2d.SelectPath("/RAM1/IS.200K") -- 200K

    a2d.DuplicateSelection("DUPE1") -- 400K
    a2d.DuplicateSelection("DUPE2") -- 600K
    a2d.DuplicateSelection("DUPE3") -- 800K
    a2d.DuplicateSelection("DUPE4") -- 1000K

    local id = mgtk.FrontWindow()
    a2d.OAShortcut("D")
    a2dtest.WaitForAlert({match="too large"})
    local ocr = a2dtest.OCRScreen()
    test.ExpectMatch(ocr, "OK", "OK button should be showing")
    test.ExpectNotMatch(ocr, "Cancel", "Cancel button should not be showing")
    a2d.DialogOK() -- dismiss with OK (should be same as cancel)
    emu.wait(5)
    test.ExpectEquals(mgtk.FrontWindow(), id, "rename prompt should not be showing")
    a2d.EraseVolume("RAM1")
end)

--[[
  Attempt to duplicate a GS/OS forked file. Verifies that the copy
  fails and there is no prompt to rename.
]]
test.Step(
  "Failed duplicate of GS/OS forked file",
  function()
    a2d.SelectPath("/TESTS/PROPERTIES/GS.OS.FILES/INSTALLER")

    local id = mgtk.FrontWindow()
    a2d.OAShortcut("D")
    a2dtest.WaitForAlert({match="Unsupported file type"})
    local ocr = a2dtest.OCRScreen()
    test.ExpectMatch(ocr, "OK", "OK button should be showing")
    test.ExpectNotMatch(ocr, "Cancel", "Cancel button should not be showing")
    a2d.DialogOK() -- dismiss with OK (should be same as cancel)
    emu.wait(5)
    test.ExpectEquals(mgtk.FrontWindow(), id, "rename prompt should not be showing")
end)
