--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

--[[
  File > Get Info a non-folder file. Verify that the size shows as
  "_size_K".
]]
test.Step(
  "non-folder file",
  function()
    desktop.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.OAShortcut("I")
    a2dtest.WaitForSystemTask()
    test.ExpectMatch(a2dtest.OCRScreen(), "Size: +.*%dK", "size should be in K")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
end)

--[[
  File > Get Info a folder containing 0 files. Verify that the size
  shows as "_size_K for 1 item".
]]
test.Step(
  "empty folder",
  function()
    desktop.SelectPath("/TESTS/VIEW/BY.NAME/EMPTY")
    a2d.OAShortcut("I")
    a2dtest.WaitForSystemTask()
    local ocr = a2dtest.OCRScreen()
    test.ExpectMatch(ocr, "Size: +.*%dK", "size should be in K")
    test.ExpectMatch(ocr, "Size: +.* for 1 item", "size should be for 1 item")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
end)

--[[
  File > Get Info a folder containing 1 file. Verify that the size
  shows as "_size_K for 2 items".
]]
test.Step(
  "one item in folder",
  function()
    desktop.SelectPath("/TESTS/VIEW/BY.NAME/ONE.FILE")
    a2d.OAShortcut("I")
    a2dtest.WaitForSystemTask()
    local ocr = a2dtest.OCRScreen()
    test.ExpectMatch(ocr, "Size: +.*%dK", "size should be in K")
    test.ExpectMatch(ocr, "Size: +.* for 2 items", "size should be for 2 items")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
end)

--[[
  File > Get Info a folder containing 2 or more files. Verify that the
  size shows as "_size_K for _count_ items", including the folder
  itself.
]]
test.Step(
  "many items in folder",
  function()
    desktop.SelectPath("/TESTS/VIEW/BY.NAME/A1.B1.A.B")
    a2d.OAShortcut("I")
    a2dtest.WaitForSystemTask()
    local ocr = a2dtest.OCRScreen()
    test.ExpectMatch(ocr, "Size: +.*%dK", "size should be in K")
    test.ExpectMatch(ocr, "Size: +.* for 5 items", "size should be for 5 items")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
end)

--[[
  File > Get Info a volume containing 0 files. Verify that the size
  shows as "_size_K for 0 items / _total_K".

  Launch DeskTop. Select a volume icon, where the volume contains no
  files. File > Get Info. Verify that numbers are shown for number of
  files (0) and space used (a few K).
]]
test.Step(
  "empty volume",
  function()
    desktop.SelectPath("/RAM1")
    a2d.OAShortcut("I")
    a2dtest.WaitForSystemTask()
    local ocr = a2dtest.OCRScreen()
    test.ExpectMatch(ocr, "Size used/total: +%dK for 0 items / .*K", "size should be _K for 0 items / %d+K")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
end)

--[[
  File > Get Info a volume containing 1 file. Verify that the size
  shows as "_size_K for 1 item / _total_K".
]]
test.Step(
  "volume with 1 file",
  function()
    desktop.CopyPath("/A2.DESKTOP/READ.ME", "/RAM1")
    desktop.SelectPath("/RAM1")
    a2d.OAShortcut("I")
    a2dtest.WaitForSystemTask()
    local ocr = a2dtest.OCRScreen()
    test.ExpectMatch(ocr, "Size used/total: +.*K for 1 item / .*K", "size should be _K for 1 item / %d+K")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    desktop.EraseVolume("RAM1")
end)

--[[
  File > Get Info a volume containing 2 or more files. Verify that the
  size shows as "_size_K for _count_ items / _total_K".
]]
test.Step(
  "volume with 2 or more files",
  function()
    desktop.CopyPath("/TESTS/VIEW/BY.NAME/A1.B1.A.B", "/RAM1")
    desktop.SelectPath("/RAM1")
    a2d.OAShortcut("I")
    a2dtest.WaitForSystemTask()
    local ocr = a2dtest.OCRScreen()
    test.ExpectMatch(ocr, "Size used/total: +.*K for 5 items / .*K", "size should be _K for 5 items / %d+K")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    desktop.EraseVolume("RAM1")
end)

--[[
  Open folder with new files. Use File > Get Info; verify dates after
  1999 show correctly.
]]
test.Step(
  "new file dates",
  function()
    desktop.SelectPath("/TESTS/FILE.TYPES/IIGS.50")
    a2d.OAShortcut("I")
    a2dtest.WaitForSystemTask()
    test.ExpectMatch(a2dtest.OCRScreen(), "Created: .* 20%d%d ", "date after 1999 should show correctly")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
end)

--[[
  Launch DeskTop. Select a 32MB volume. File > Get Info. Verify total
  size shows as 32,768K not 0K.
]]
test.Step(
  "32MB volume",
  function()
    desktop.SelectPath("/TESTS")
    a2d.OAShortcut("I")
    a2dtest.WaitForSystemTask()
    test.ExpectMatch(a2dtest.OCRScreen(), "Size used/total: .* 32,768K", "total size should be 32,768K, not 0K")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
end)

--[[
  Launch DeskTop. Select a file icon. File > Get Info. Verify that the
  size shown is correct. Select a directory. File > Get Info, and
  dismiss. Now select the original file icon again, and File > Get
  Info. Verify that the size shown is still correct.
]]
test.Step(
  "file, folder, file",
  function()
    desktop.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/LOREM.IPSUM")
    a2d.OAShortcut("I")
    a2dtest.WaitForSystemTask()
    a2dtest.ExpectNothingChanged(function()
        a2d.DialogOK()
        a2dtest.WaitForSystemTask()
        desktop.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/FONTS")
        a2d.OAShortcut("I")
        a2dtest.WaitForSystemTask()
        a2d.DialogOK()
        a2dtest.WaitForSystemTask()
        desktop.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/LOREM.IPSUM")
        a2d.OAShortcut("I")
        a2dtest.WaitForSystemTask()
    end)
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
end)

--[[
  Use real hardware, not an emulator. Launch DeskTop. Select a volume
  icon. File > Get Info. Verify that a "The specified path name is
  invalid." alert is not shown.

  TODO: See if we can repro the inspiration for this one in an emulator.
]]


--[[
  Launch DeskTop. Select a volume with more than 255 files in a folder
  (e.g. Total Replay). File > Get Info. Verify that the count
  finishes.
]]
test.Step(
  "more than 255 files",
  function()
    desktop.SelectPath("/TESTS/RAMCARD/SHORTCUT/HAS.256.FILES")
    a2d.OAShortcut("I")
    a2dtest.WaitForSystemTask()
    local ocr = a2dtest.OCRScreen()
    local _, _, count = ocr:find("Size: .* for (%d+) items")
    test.ExpectGreaterThan(tonumber(count), 255, "count should be greater than 255")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
end)

--[[
  Launch DeskTop. Select `/TESTS/PROPERTIES/KNOWN.SIZE`. File > Get
  Info. Verify that "Size" is "17K for 2 items".
]]
test.Step(
  "known size",
  function()
    desktop.SelectPath("/TESTS/PROPERTIES/KNOWN.SIZE")
    a2d.OAShortcut("I")
    a2dtest.WaitForSystemTask()
    test.ExpectMatch(a2dtest.OCRScreen(), "Size: +17K for 2 items", "size should be 17K for 2 items")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
end)

--[[
  Select a volume or folder containing multiple files. File > Get
  Info. During the count of the files, press Escape. Verify that the
  count is canceled.
]]
test.Step(
  "cancel enumeration",
  function()
    desktop.SelectPath("/TESTS")
    a2d.OAShortcut("I", {no_wait=true})
    emu.wait(5) -- cancel enumeration
    apple2.EscapeKey()
    local ocr = a2dtest.OCRScreen()
    local _, _, count = ocr:find("Size used/total: .* for (%d+) items")
    test.ExpectLessThan(tonumber(count), 100, "count should be canceled (less than 100 items)")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
end)

--[[
  Open `/TESTS/FILE.TYPES`. Select `PACKED.FOT`. File > Get Info.
  Verify that the AuxType displays as `$4001`. Click OK. View > by
  Name. View > as Icons. File > Get Info. Verify that the AuxType
  still displays correctly.
]]
test.Step(
  "auxtype",
  function()
    desktop.SelectPath("/TESTS/FILE.TYPES/PACKED.FOT")
    a2d.OAShortcut("I")
    a2dtest.WaitForSystemTask()
    a2dtest.ExpectNothingChanged(function()
        a2d.DialogOK()
        a2dtest.WaitForSystemTask()
        a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_BY_NAME)
        a2d.InvokeMenuItem(desktop.VIEW_MENU, desktop.VIEW_AS_ICONS)
        a2d.OAShortcut("I")
    end)
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
end)

--[[
  Open a volume window containing a folder. Select the folder. File >
  Get Info. Check Locked. Click OK. Close the volume window. Re-open
  the volume window. Verify that the folder is still a folder.
]]
test.Step(
  "locking folder",
  function()
    desktop.SelectPath("/TESTS/FILE.TYPES/FOLDER")
    a2dtest.WaitForSystemTask()
    a2dtest.ExpectNothingChanged(function()
        a2d.OAShortcut("I")
        a2dtest.WaitForSystemTask()
        apple2.ControlKey("L") -- Toggle Locked
        a2d.DialogOK()
        a2dtest.WaitForSystemTask()
        desktop.SelectPath("/TESTS/FILE.TYPES/FOLDER")
        a2dtest.WaitForSystemTask()
    end)
end)

