--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -flop1 res/floppy_with_files.dsk -flop2 res/prodos_floppy2.dsk"

======================================== ENDCONFIG ]]

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
    local drive2 = apple2.GetDiskIIS6D2()
    local dst = drive2.filename
    drive2:unload()

    local drive = apple2.GetDiskIIS6D1()
    local src = drive.filename

    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_CHECK_ALL_DRIVES)
    emu.wait(8)

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
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_CHECK_ALL_DRIVES)
    emu.wait(5)

    a2d.OpenPath("/FLOPPY2/LOREM.IPSUM")

    emu.wait(5)
    test.Snap("verify file contents")

    a2d.CloseWindow()

    drive:unload()
    drive:load(src)

    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_CHECK_ALL_DRIVES)
    emu.wait(5)
end)


--[[
  Load DeskTop. Open a window for a volume in a Disk II drive. Remove
  the disk from the Disk II drive. Hold Solid-Apple and drag a file to
  another volume to move it. When prompted to insert the disk, click
  Cancel. Verify that when the window closes the disk icon is no
  longer dimmed.
]]
test.Step(
  "Drag with disk ejected",
  function()
    local drive = apple2.GetDiskIIS6D1()
    local src = drive.filename

    a2d.SelectPath("/RAM1")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.SelectPath("/WITH.FILES/LOREM.IPSUM")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    drive:unload()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_x, src_y)
        m.ButtonDown()
        m.MoveToApproximately(dst_x, dst_y)
        m.ButtonUp()
    end)

    a2dtest.WaitForAlert()
    a2d.DialogCancel()

    emu.wait(5)

    test.Snap("verify that floppy icon is not dimmed")

    drive:load(src)
end)

