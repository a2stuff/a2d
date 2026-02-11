--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl6 superdrive -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -flop1 empty_800k.2mg -flop2 full_800k.2mg"

======================================== ENDCONFIG ]]

local s6d1 = manager.machine.images[":sl6:superdrive:fdc:0:35hd"]
local s6d2 = manager.machine.images[":sl6:superdrive:fdc:1:35hd"]

a2d.ConfigureRepaintTime(0.25)

a2d.RenamePath("/EMPTY", "FLOPPY1")
a2d.EraseVolume("FULL", "FLOPPY2")

--[[
  Create two floppies named /VOLUME, one at a time. On the first add
  folders /VOLUME/SUBDIR/FOLDER. Open FOLDER. Swap floppies. Drag a
  from another disk into FOLDER. Verify that the error is about the
  missing subdirectory, not volume or file.
]]
test.Step(
  "Drag operation with missing subdirectory",
  function()
    local drive1 = s6d1
    local disk1 = drive1.filename
    local drive2 = s6d2
    local disk2 = drive2.filename

    a2d.RenamePath("/FLOPPY2", "VOLUME")
    emu.wait(5)
    drive2:unload()

    a2d.CheckAllDrives()
    emu.wait(10)

    a2d.RenamePath("/FLOPPY1", "VOLUME")
    a2d.CreateFolder("/VOLUME/SUBDIR")
    a2d.CreateFolder("/VOLUME/SUBDIR/FOLDER")
    a2d.OpenPath("/VOLUME/SUBDIR/FOLDER")
    a2d.MoveWindowBy(0, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.SelectPath("/A2.DESKTOP/READ.ME", {keep_windows=true})
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    -- Swap to the /VOLUME disk that doesn't have SUBDIR
    drive1:load(disk2)

    a2d.Drag(src_x, src_y, dst_x, dst_y)

    a2dtest.WaitForAlert({match="subdirectory cannot be found"})
    local ocr = a2dtest.OCRScreen()
    test.Expect(not ocr:match("Try Again"), "no Try Again button should be present")
    test.Expect(not ocr:match("Cancel"), "no Cancel button should be present")
    a2d.DialogOK()

    -- cleanup
    a2d.RenamePath("/VOLUME", "FLOPPY2")
    emu.wait(5)
    drive1:unload()
    drive2:load(disk2)
    drive1:load(disk1)
    a2d.CheckAllDrives()
    a2d.RenamePath("/VOLUME", "FLOPPY1")
    emu.wait(5)
    a2d.EraseVolume("FLOPPY1")
end)

--[[
  Create two floppies named /VOLUME, one at a time. On the first add
  folder /VOLUME/FOLDER. Open FOLDER. Swap floppies. Drag a
  from another disk into FOLDER. Verify that the error is about the
  missing subdirectory, not volume or file.
]]
test.Step(
  "Drag operation with missing target",
  function()
    local drive1 = s6d1
    local disk1 = drive1.filename
    local drive2 = s6d2
    local disk2 = drive2.filename

    a2d.RenamePath("/FLOPPY2", "VOLUME")
    emu.wait(5)
    drive2:unload()

    a2d.CheckAllDrives()

    a2d.RenamePath("/FLOPPY1", "VOLUME")
    a2d.CreateFolder("/VOLUME/FOLDER")
    a2d.OpenPath("/VOLUME/FOLDER")
    a2d.MoveWindowBy(0, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.SelectPath("/A2.DESKTOP/READ.ME", {keep_windows=true})
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    -- Swap to the /VOLUME disk that doesn't have FOLDER
    drive1:load(disk2)

    a2d.Drag(src_x, src_y, dst_x, dst_y)

    a2dtest.WaitForAlert({match="file cannot be found"})
    local ocr = a2dtest.OCRScreen()
    test.Expect(not ocr:match("Try Again"), "no Try Again button should be present")
    test.Expect(not ocr:match("Cancel"), "no Cancel button should be present")
    a2d.DialogOK()

    -- cleanup
    a2d.RenamePath("/VOLUME", "FLOPPY2")
    emu.wait(5)
    drive1:unload()
    drive2:load(disk2)
    drive1:load(disk1)
    a2d.CheckAllDrives()
    a2d.RenamePath("/VOLUME", "FLOPPY1")
    emu.wait(5)
    a2d.EraseVolume("FLOPPY1")
end)

--[[
]]
test.Step(
  "Drag operation with missing volume",
  function()
    local drive1 = s6d1
    local disk1 = drive1.filename

    a2d.OpenPath("/FLOPPY1")
    a2d.MoveWindowBy(0, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    a2d.SelectPath("/A2.DESKTOP/READ.ME", {keep_windows=true})
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(src_x, src_y)
        m.ButtonDown()
        m.MoveToApproximately(dst_x, dst_y)

        -- Eject
        drive1:unload()

        m.ButtonUp()
    end)

    a2dtest.WaitForAlert({imatch="Insert the disk: FLOPPY1"})
    local ocr = a2dtest.OCRScreen()
    test.Expect(ocr:match("OK"), "Try Again button should be present")
    test.Expect(ocr:match("Cancel"), "Cancel button should be present")
    a2d.DialogCancel()
    drive1:load(disk1)
end)
