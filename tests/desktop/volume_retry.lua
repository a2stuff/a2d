--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl6 superdrive -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -flop1 empty_800k.2mg -flop2 full_800k.2mg"

======================================== ENDCONFIG ]]

local s6d1 = manager.machine.images[":sl6:superdrive:fdc:0:35hd"]
local s6d2 = manager.machine.images[":sl6:superdrive:fdc:1:35hd"]

desktop.RenamePath("/EMPTY", "FLOPPY1")
desktop.EraseVolume("FULL", "FLOPPY2")

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

    desktop.RenamePath("/FLOPPY2", "VOLUME")
    a2dtest.WaitForSystemTask()
    drive2:unload()

    desktop.CheckAllDrives()
    a2dtest.WaitForSystemTask()

    desktop.RenamePath("/FLOPPY1", "VOLUME")
    desktop.CreateFolder("/VOLUME/SUBDIR")
    desktop.CreateFolder("/VOLUME/SUBDIR/FOLDER")
    desktop.OpenWindow("/VOLUME/SUBDIR/FOLDER")
    desktop.MoveWindowBy(0, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    desktop.SelectPath("/A2.DESKTOP/READ.ME", {keep_windows=true})
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    -- Swap to the /VOLUME disk that doesn't have SUBDIR
    drive1:load(disk2)

    a2d.Drag(src_x, src_y, dst_x, dst_y)

    a2dtest.WaitForAlert({match="subdirectory cannot be found"})
    local ocr = a2dtest.OCRScreen()
    test.ExpectNotMatch(ocr, "Try Again", "no Try Again button should be present")
    test.ExpectNotMatch(ocr, "Cancel", "no Cancel button should be present")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    -- cleanup
    desktop.RenamePath("/VOLUME", "FLOPPY2")
    a2dtest.WaitForSystemTask()
    drive1:unload()
    drive2:load(disk2)
    drive1:load(disk1)
    desktop.CheckAllDrives()
    desktop.RenamePath("/VOLUME", "FLOPPY1")
    a2dtest.WaitForSystemTask()
    desktop.EraseVolume("FLOPPY1")
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

    desktop.RenamePath("/FLOPPY2", "VOLUME")
    a2dtest.WaitForSystemTask()
    drive2:unload()

    desktop.CheckAllDrives()

    desktop.RenamePath("/FLOPPY1", "VOLUME")
    desktop.CreateFolder("/VOLUME/FOLDER")
    desktop.OpenWindow("/VOLUME/FOLDER")
    desktop.MoveWindowBy(0, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    desktop.SelectPath("/A2.DESKTOP/READ.ME", {keep_windows=true})
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    -- Swap to the /VOLUME disk that doesn't have FOLDER
    drive1:load(disk2)

    a2d.Drag(src_x, src_y, dst_x, dst_y)

    a2dtest.WaitForAlert({match="file cannot be found"})
    local ocr = a2dtest.OCRScreen()
    test.ExpectNotMatch(ocr, "Try Again", "no Try Again button should be present")
    test.ExpectNotMatch(ocr, "Cancel", "no Cancel button should be present")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    -- cleanup
    desktop.RenamePath("/VOLUME", "FLOPPY2")
    a2dtest.WaitForSystemTask()
    drive1:unload()
    drive2:load(disk2)
    drive1:load(disk1)
    desktop.CheckAllDrives()
    desktop.RenamePath("/VOLUME", "FLOPPY1")
    a2dtest.WaitForSystemTask()
    desktop.EraseVolume("FLOPPY1")
end)

--[[
]]
test.Step(
  "Drag operation with missing volume",
  function()
    local drive1 = s6d1
    local disk1 = drive1.filename

    desktop.OpenWindow("/FLOPPY1")
    desktop.MoveWindowBy(0, 100)
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    local dst_x, dst_y = x + w / 2, y + h / 2

    desktop.SelectPath("/A2.DESKTOP/READ.ME", {keep_windows=true})
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
    test.ExpectMatch(ocr, "OK", "Try Again button should be present")
    test.ExpectMatch(ocr, "Cancel", "Cancel button should be present")
    a2d.DialogCancel()
    drive1:load(disk1)
end)
