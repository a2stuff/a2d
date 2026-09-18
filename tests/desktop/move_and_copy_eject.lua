--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -flop1 floppy_with_files.dsk -flop2 prodos_floppy2.dsk"

======================================== ENDCONFIG ]]

local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]
local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]

--[[
  Configure a system with removable disks, e.g. Disk II in S6D1, and
  prepare two ProDOS disks with volume names `SRC` and `DST`, and a
  small file (2K or less is ideal) on `SRC`. Mount `SRC`. Launch
  DeskTop. Open `SRC` and select the file. File > Copy To.... Eject
  the disk and insert `DST`. Click Drives. Select `DST` and click OK.
  When prompted, insert the appropriate source and destination disks
  until the copy is complete. Inspect the contents of the file and
  verify that it was copied byte-for-byte correctly.
]]
test.Step(
  "File > Copy To with disk swapping",
  function()
    local drive2 = s6d2
    local dst = drive2.filename
    drive2:unload()

    local drive = s6d1
    local src = drive.filename

    desktop.CheckAllDrives()

    desktop.SelectPath("/WITH.FILES/LOREM.IPSUM")
    a2d.InvokeMenuItem(desktop.FILE_MENU, desktop.FILE_COPY_TO)
    a2dtest.WaitForSystemTask()
    drive:unload()
    drive:load(dst)
    apple2.ControlKey("D") -- Drives
    a2dtest.WaitForSystemTask()
    apple2.Type("FLOPPY2")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    -- This count can change if DeskTop's copy buffer changes size.
    -- TODO: Make this dynamic somehow?
    for i = 1, 4 do
      a2dtest.WaitForAlert({imatch="insert the disk: WITH%.FILES"})
      drive:unload()
      drive:load(src)
      a2d.DialogOK()

      a2dtest.WaitForAlert({imatch="insert the disk: FLOPPY2"})
      drive:unload()
      drive:load(dst)
      a2d.DialogOK()
      a2dtest.WaitForSystemTask()
    end

    desktop.CheckAllDrives()

    desktop.InvokePath("/FLOPPY2/LOREM.IPSUM")
    test.ExpectMatch(a2dtest.OCRScreen(), "Lorem ipsum.*hac habitasse", "file contents should be the same")

    -- cleanup
    desktop.CloseWindow()
    drive:unload()
    drive:load(src)
    desktop.CheckAllDrives()
end)


--[[
  Load DeskTop. Open a window for a volume in a Disk II drive. Remove
  the disk from the Disk II drive. Hold Solid-Apple and drag a file to
  another volume to move it. When prompted to insert the disk, click
  Cancel. Verify that when the window closes selection remains.
]]
test.Step(
  "Drag with disk ejected - before enumeration",
  function()
    local drive = s6d1
    local src = drive.filename

    desktop.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/WITH.FILES/LOREM.IPSUM")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    drive:unload()
    a2d.Drag(src_x, src_y, dst_x, dst_y, {sa_drop=true})

    a2dtest.WaitForAlert({match="Insert the disk: WITH%.FILES"})
    a2d.DialogCancel()

    a2dtest.WaitForSystemTask()

    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "LOREM.IPSUM", "clicked icon should be selected")

    -- cleanup
    drive:load(src)
end)


--[[
  Load DeskTop. Open a window for a volume in a Disk II drive. Remove
  the disk from the Disk II drive. Hold Solid-Apple and drag a file to
  another volume to move it. After enumeration, when prompted to
  insert the disk, click Cancel. Verify that when the window closes
  the disk icon is no longer dimmed.
]]
test.Step(
  "Drag with disk ejected - after enumeration",
  function()
    local drive = s6d1
    local src = drive.filename

    desktop.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    desktop.SelectPath("/WITH.FILES/LOREM.IPSUM")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y, {sa_drop=true})
    drive:unload()

    a2dtest.WaitForAlert({match="Insert the disk: WITH%.FILES"})
    a2d.DialogCancel()

    a2dtest.WaitForAlert({match="volume cannot be found"})
    a2d.DialogOK() -- OK
    a2dtest.WaitForSystemTask()

    test.ExpectEquals(#desktop.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(desktop.GetSelectedIcons()[1].name, "WITH.FILES", "clicked icon should be selected")
    test.Expect(not desktop.GetSelectedIcons()[1].dimmed, "selected icon should not be dimmed")

    -- cleanup
    drive:load(src)
end)

--[[
  Open a window for a floppy disk. Drag a file to a folder on the same
  disk. When alert shows, click Cancel. Verify that DeskTop doesn't
  crash.
]]
test.Step(
  "no crash on cancel after failed copy-or-move check",
  function()
    local drive = s6d1
    local src = drive.filename

    desktop.CreateFolder("/WITH.FILES/FOLDER")
    a2dtest.WaitForSystemTask()

    desktop.OpenWindow("/WITH.FILES")
    a2dtest.WaitForSystemTask()

    desktop.Select("FOLDER")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    desktop.Select("LOREM.IPSUM")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    drive:unload()
    a2d.Drag(src_x, src_y, dst_x, dst_y)

    a2dtest.WaitForAlert({match="Insert the disk: WITH%.FILES"})
    a2d.DialogCancel()
    a2dtest.WaitForSystemTask()

    a2dtest.ExpectNotHanging()

    -- cleanup
    drive:load(src)
    desktop.DeletePath("/WITH.FILES/FOLDER")
end)
