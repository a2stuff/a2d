--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 res/floppy_with_files.dsk"

======================================== ENDCONFIG ]]--

--[[
  Launch DeskTop. Select a 5.25 disk volume. Remove the disk. File >
  Get Info. Verify that an alert is shown. Click OK. Verify that
  DeskTop doesn't hang or crash.
]]--
test.Step(
  "Alert shown on File > Get Info for disk if disk ejected",
  function()
    local drive = apple2.GetDiskIIS6D1()
    local current = drive.filename

    a2d.SelectPath("/WITH.FILES")
    drive:unload()
    a2d.OAShortcut("I")
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    a2dtest.ExpectNotHanging()
    drive:load(current)
end)

--[[
  Launch DeskTop. Select a file on a 5.25 disk. Remove the disk. File
  > Get Info. Verify that an alert is shown. Click OK. Verify that
  DeskTop doesn't hang or crash.
]]--
test.Step(
  "Alert shown on File > Get Info for single file if disk ejected",
  function()
    local drive = apple2.GetDiskIIS6D1()
    local current = drive.filename

    a2d.SelectPath("/WITH.FILES/LOREM.IPSUM")
    drive:unload()
    a2d.OAShortcut("I")
    a2dtest.WaitForAlert()
    a2d.DialogOK()
    a2dtest.ExpectNotHanging()
    drive:load(current)
end)

--[[
  Launch DeskTop. Select two files on a 5.25 disk. Remove the disk.
  File > Get Info. Verify that an alert is shown. Insert the disk
  again. Click OK. Verify that details are shown for the second file.
]]--
test.Step(
  "Alert shown on File > Get Info for multiple files if disk ejected",
  function()
    local drive = apple2.GetDiskIIS6D1()
    local current = drive.filename

    a2d.OpenPath("/WITH.FILES")
    a2d.SelectAll()
    drive:unload()
    a2d.OAShortcut("I")
    a2dtest.WaitForAlert()
    drive:load(current)
    a2d.DialogOK()
    test.Snap("verify details shown for second file")
    a2d.DialogOK()
end)

