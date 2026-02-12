--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 superdrive"
DISKARGS="-flop3 $HARDIMG -flop1 floppy_with_files.dsk"

======================================== ENDCONFIG ]]

local s7d1 = manager.machine.images[":sl7:superdrive:fdc:0:35hd"]
local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]

a2d.ConfigureRepaintTime(2)

--[[
  Eject a floppy disk. Select the disk. File > Open. Verify that the
  prompt for system disk offers only "OK".
]]
test.Step(
  "failed open has no Try Again option",
  function()
    local disk = s6d1.filename
    s6d1:unload()

    a2d.OpenPath("/WITH.FILES")

    a2d.OAShortcut("O") -- File > Open

    a2dtest.WaitForAlert({match="volume cannot be found"})
    local ocr = a2dtest.OCRScreen()
    test.Expect(not ocr:find("Try Again"), "no Try Again button should be present")
    test.Expect(not ocr:find("Cancel"), "no Cancel button should be present")
    a2d.DialogOK()

    s6d1:load(disk)
    a2d.CheckAllDrives()
end)

--[[
  Open a window for a floppy disk. Eject the disk. File > New Folder.
  Verify that the error does not offer "Try Again" or "Cancel".
]]
test.Step(
  "Alert after New Folder on ejected disk has no Try Again option",
  function()
    local disk = s6d1.filename
    a2d.OpenPath("/WITH.FILES")

    s6d1:unload()

    a2d.OAShortcut("N") -- File > New Folder

    a2dtest.WaitForAlert({match="volume cannot be found"})
    local ocr = a2dtest.OCRScreen()
    test.Expect(not ocr:find("Try Again"), "no Try Again button should be present")
    test.Expect(not ocr:find("Cancel"), "no Cancel button should be present")
    a2d.DialogOK()

    s6d1:load(disk)
end)

--[[
  Open a window for a floppy with disk files. Select a file. Eject the
  disk. File > Duplicate. Verify that the error does not offer "Try
  Again" or "Cancel".
]]
test.Step(
  "Alert after Duplicate on ejected disk has no Try Again option",
  function()
    local disk = s6d1.filename
    a2d.SelectPath("/WITH.FILES/LOREM.IPSUM")

    s6d1:unload()

    a2d.OAShortcut("D") -- File > Duplicate

    a2dtest.WaitForAlert({match="volume cannot be found"})
    local ocr = a2dtest.OCRScreen()
    test.Expect(not ocr:find("Try Again"), "no Try Again button should be present")
    test.Expect(not ocr:find("Cancel"), "no Cancel button should be present")
    a2d.DialogOK()

    s6d1:load(disk)
end)

--[[
  Open a window for a floppy disk. Select a file. Eject the disk.
  Special > Make Alias. Verify that the error does not offer "Try
  Again" or "Cancel".
]]
test.Step(
  "Alert after Make Alias on ejected disk has no Try Again option",
  function()
    local disk = s6d1.filename
    a2d.SelectPath("/WITH.FILES/LOREM.IPSUM")

    s6d1:unload()

    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, -1) -- Special > Make Alias

    a2dtest.WaitForAlert({match="volume cannot be found"})
    local ocr = a2dtest.OCRScreen()
    test.Expect(not ocr:find("Try Again"), "no Try Again button should be present")
    test.Expect(not ocr:find("Cancel"), "no Cancel button should be present")
    a2d.DialogOK()

    s6d1:load(disk)
end)

--[[
  Eject the system disk. Shortcuts > Add a Shortcut. Verify that the
  prompt for system disk offers "Try Again" and "Cancel".
]]
test.Step(
  "prompt on loading overlay has Cancel",
  function()
    local disk = s7d1.filename
    s7d1:unload()

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    a2dtest.WaitForAlert({match="insert the system disk"})

    local ocr = a2dtest.OCRScreen()
    test.Expect(ocr:find("Try Again"), "Try Again button should be present")
    test.Expect(ocr:find("Cancel"), "Cancel button should be present")

    a2d.DialogCancel()

    s7d1:load(disk)
    emu.wait(5)
end)

--[[
  Shortcuts > Add a Shortcut. Eject the system disk. Cancel. Verify
  that the prompt for system disk offers only "OK".
]]
test.Step(
  "prompt on restoring overlay does not have Cancel",
  function()
    local disk = s7d1.filename

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    emu.wait(10)

    s7d1:unload()
    a2d.DialogCancel()

    a2dtest.WaitForAlert({match="insert the system disk"})

    local ocr = a2dtest.OCRScreen()
    test.Expect(ocr:find("OK"), "OK button should be present")
    test.Expect(not ocr:find("Cancel"), "no Cancel button should be present")

    s7d1:load(disk)

    a2d.DialogOK()
end)
