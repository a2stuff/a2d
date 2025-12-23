--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv -flop1 res/prodos_floppy1.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(5)

-- NOTE: Super flaky, c/o https://github.com/mamedev/mame/issues/14474

--[[
  Launch DeskTop. Drag a volume icon onto another volume icon where
  there is not enough capacity for all of the files but there is
  capacity for some files. Verify that the copy starts and that when
  an alert is shown the progress dialog references a specific file,
  not the source volume itself.
]]
-- Skipping this until MAME gets floppies under control.

--[[
  Launch DeskTop. Try to move a file (drag on same volume) where there
  is not enough space to make a temporary copy, e.g. a 100K file on a
  140K disk. Verify that the file is moved successfully and no error
  is shown.
]]
test.Step(
  "Can move file even if there isn't space to copy",
  function()
    -- consume space
    a2d.CopyPath("/A2.DESKTOP/MODULES/DESKTOP", "/FLOPPY1")
    emu.wait(60)

    a2d.CreateFolder("/FLOPPY1/FOLDER")
    emu.wait(10)
    a2d.OpenPath("/FLOPPY1")
    emu.wait(5)

    a2d.Select("DESKTOP")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Select("FOLDER")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(40)
    a2dtest.ExpectAlertNotShowing()

    a2d.SelectPath("/FLOPPY1/FOLDER/DESKTOP")

    a2d.OpenPath("/FLOPPY1")
    a2d.SelectAll()
    a2d.DeleteSelection()
end)

--[[
  Launch DeskTop. Try to copy a file (drag to different volume) where
  there is not enough space to make the copy. Verify that the error
  message says that the file is too large to copy.
]]
test.Step(
  "Copy to folder without capacity",
  function()
    a2d.CopyPath("/TESTS/COPYING/SIZES/IS.200K", "/FLOPPY1")
    a2dtest.WaitForAlert()
    test.Snap("verify alert is about file size")
    a2d.DialogOK()
end)

--[[
  Launch DeskTop. Drag multiple selected files to a different volume,
  where one of the middle files will be too large to fit on the target
  volume but that subsequently selected files will fit. Verify that an
  error message says that the file is too large to copy, and that
  clicking OK continues to copy the remaining files.
]]
test.Step(
  "Copy files to volume with capacity for some but not all files",
  function()
    a2d.OpenPath("/TESTS/COPYING/SIZES")
    a2d.SelectAll()
    a2d.CopySelectionTo("/FLOPPY1")
    a2dtest.WaitForAlert()
    test.Snap("verify error is about file size")
    a2d.DialogOK()
    emu.wait(30)

    a2d.OpenPath("/FLOPPY1")
    a2d.SelectAll()
    test.Expect(#a2d.GetSelectedIcons(), 2, "2 files should have fit")
    a2d.DeleteSelection()
end)

--[[
  Launch DeskTop. Drag a single folder or volume containing multiple
  files to a different volume, where one of the files will be too
  large to fit on the target volume but all other files will fit.
  Verify that an error message says that the file is too large to
  copy, and that clicking OK continues to copy the remaining files.
]]
test.Step(
  "Copy folder to volume with capacity for some but not all files",
  function()
    a2d.CopyPath("/TESTS/COPYING/SIZES", "/FLOPPY1")
    a2dtest.WaitForAlert()
    test.Snap("verify error is about file size")
    a2d.DialogOK()
    emu.wait(30)

    a2d.OpenPath("/FLOPPY1/COPYING/SIZES")
    a2d.SelectAll()
    test.Snap("selected all")
    test.Expect(#a2d.GetSelectedIcons(), 2, "2 files should have fit")
    a2d.OpenPath("/FLOPPY1")
    a2d.DeleteSelection()
end)
