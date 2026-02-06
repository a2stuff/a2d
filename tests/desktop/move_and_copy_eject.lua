--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -flop1 floppy_with_files.dsk -flop2 prodos_floppy2.dsk"

======================================== ENDCONFIG ]]

local s6d1 = manager.machine.images[":sl6:diskiing:0:525"]
local s6d2 = manager.machine.images[":sl6:diskiing:1:525"]

a2d.ConfigureRepaintTime(1)

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

    a2d.CheckAllDrives()

    a2d.SelectPath("/WITH.FILES/LOREM.IPSUM")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_COPY_TO)
    emu.wait(2)
    drive:unload()
    drive:load(dst)
    apple2.ControlKey("D") -- Drives
    emu.wait(2)
    apple2.Type("FLOPPY2")
    a2d.DialogOK()

    for i = 1, 3 do
      a2dtest.WaitForAlert()
      drive:unload()
      drive:load(src)
      a2d.DialogOK()

      a2dtest.WaitForAlert()
      drive:unload()
      drive:load(dst)
      a2d.DialogOK()
    end

    emu.wait(8)
    a2d.CheckAllDrives()

    a2d.OpenPath("/FLOPPY2/LOREM.IPSUM")

    emu.wait(5)
    test.Expect(a2dtest.OCRScreen():find("Lorem ipsum.*hac habitasse"), "file contents should be the same")

    -- cleanup
    a2d.CloseWindow()
    drive:unload()
    drive:load(src)
    a2d.CheckAllDrives()
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

    a2d.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/WITH.FILES/LOREM.IPSUM")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    drive:unload()
    a2d.Drag(src_x, src_y, dst_x, dst_y, {sa_drop=true})

    a2dtest.WaitForAlert()
    a2d.DialogCancel()

    emu.wait(5)

    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(a2d.GetSelectedIcons()[1].name, "LOREM.IPSUM", "clicked icon should be selected")

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

    a2d.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/WITH.FILES/LOREM.IPSUM")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y, {sa_drop=true})
    drive:unload()

    a2dtest.WaitForAlert() -- Insert the disk
    a2d.DialogCancel()
    a2d.WaitForRepaint()

    a2dtest.WaitForAlert() -- The volume cannot be found
    a2d.DialogOK()
    emu.wait(5)

    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "one icon should be selected")
    test.ExpectEqualsIgnoreCase(a2d.GetSelectedIcons()[1].name, "WITH.FILES", "clicked icon should be selected")
    test.Expect(not a2d.GetSelectedIcons()[1].dimmed, "selected icon should not be dimmed")

    -- cleanup
    drive:load(src)
end)

