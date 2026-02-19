--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 floppy_with_files.dsk"

======================================== ENDCONFIG ]]

local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]

a2d.ConfigureRepaintTime(2)

--[[
  Launch DeskTop. Select a 5.25 disk volume. Remove the disk. File >
  Get Info. Verify that an alert is shown. Click OK. Verify that
  DeskTop doesn't hang or crash.
]]
test.Step(
  "Alert shown on File > Get Info for disk if disk ejected",
  function()
    local drive = s6d1
    local current = drive.filename

    a2d.SelectPath("/WITH.FILES")
    drive:unload()
    a2d.OAShortcut("I") -- File > Get Info
    a2dtest.WaitForAlert({match="volume cannot be found"})
    a2d.DialogCancel()
    a2dtest.ExpectNotHanging()
    drive:load(current)
end)

--[[
  Launch DeskTop. Select a file on a 5.25 disk. Remove the disk. File
  > Get Info. Verify that an alert is shown. Click OK. Verify that
  DeskTop doesn't hang or crash.
]]
test.Step(
  "Alert shown on File > Get Info for single file if disk ejected",
  function()
    local drive = s6d1
    local current = drive.filename

    a2d.SelectPath("/WITH.FILES/LOREM.IPSUM")
    drive:unload()
    a2d.OAShortcut("I") -- File > Get Info
    a2dtest.WaitForAlert({match="volume cannot be found"})
    a2d.DialogCancel()
    a2dtest.ExpectNotHanging()
    drive:load(current)
end)

--[[
  Launch DeskTop. Select two files on a 5.25 disk. Remove the disk.
  File > Get Info. Verify that an alert is shown. Insert the disk
  again. Click Try Again. Verify that details are shown for the first file.
]]
test.Step(
  "Alert shown on File > Get Info for multiple files if disk ejected - try again",
  function()
    local drive = s6d1
    local current = drive.filename

    a2d.OpenPath("/WITH.FILES")
    a2d.SelectAll()
    drive:unload()
    a2d.OAShortcut("I") -- File > Get Info
    a2dtest.WaitForAlert({match="volume cannot be found"})
    drive:load(current)
    apple2.Type("A") -- Try Again
    emu.wait(5)
    test.ExpectIMatch(a2dtest.OCRScreen(), "LOREM%.IPSUM",
                "details should be shown for second file")
    a2d.DialogCancel()
    emu.wait(5)
end)

--[[
  Launch DeskTop. Select two files on a 5.25 disk. Remove the disk.
  File > Get Info. Verify that an alert is shown. Insert the disk
  again. Click Cancel. Verify that details are shown for the second file.
]]
test.Step(
  "Alert shown on File > Get Info for multiple files if disk ejected - cancel",
  function()
    local drive = s6d1
    local current = drive.filename

    a2d.OpenPath("/WITH.FILES")
    a2d.SelectAll()
    drive:unload()
    a2d.OAShortcut("I") -- File > Get Info
    a2dtest.WaitForAlert({match="volume cannot be found"})
    drive:load(current)

    -- Cancel attempt to show info on first file, proceed wth second
    a2d.DialogCancel()
    emu.wait(5)
    test.ExpectIMatch(a2dtest.OCRScreen(), "SHAKESPEARE",
                "details should be shown for second file")
    a2d.DialogOK()
end)

