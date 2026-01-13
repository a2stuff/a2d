--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 memexp -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)

--[[
  Launch DeskTop. Drag a volume icon onto another volume icon where
  there is not enough capacity for all of the files but there is
  capacity for some files. Verify that the copy starts and that when
  an alert is shown the progress dialog references a specific file,
  not the source volume itself.
]]
test.Step(
  "Volume copy can partially succeed",
  function()
    -- leave around 200K free
    a2d.CreateFolder("/RAM1/CONSUMED")
    a2d.CopyPath("/TESTS/COPYING/SIZES/IS.200K", "/RAM1/CONSUMED") -- 200k
    a2d.DuplicatePath("/RAM1/CONSUMED/IS.200K", "DUPE1") -- 400k
    a2d.DuplicatePath("/RAM1/CONSUMED/IS.200K", "DUPE2") -- 600k
    a2d.DuplicatePath("/RAM1/CONSUMED/IS.200K", "DUPE3") -- 800k

    -- copy volume
    a2d.CopyPath("/A2.DESKTOP", "/RAM1")
    a2dtest.WaitForAlert()
    test.Snap("verify progress dialog references specific file")
    a2d.DialogCancel()

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Try to move a file (drag on same volume) where there
  is not enough space to make a temporary copy, e.g. a 100K file on a
  140K disk. Verify that the file is moved successfully and no error
  is shown.
]]
test.Step(
  "Can move file even if there isn't space to copy",
  function()
    -- leave less than 200K free
    a2d.CreateFolder("/RAM1/CONSUMED")
    a2d.CopyPath("/TESTS/COPYING/SIZES/IS.200K", "/RAM1/CONSUMED") -- 200k
    a2d.DuplicatePath("/RAM1/CONSUMED/IS.200K", "DUPE1") -- 400k
    a2d.DuplicatePath("/RAM1/CONSUMED/IS.200K", "DUPE2") -- 600k
    a2d.DuplicatePath("/RAM1/CONSUMED/IS.200K", "DUPE3") -- 800k

    a2d.CopyPath("/TESTS/COPYING/SIZES/IS.200K", "/RAM1") -- 1000k
    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.OpenPath("/RAM1")

    a2d.Select("IS.200K")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    a2d.Select("FOLDER")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()

    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(5)
    a2dtest.ExpectAlertNotShowing()

    a2d.SelectPath("/RAM1/FOLDER/IS.200K") -- verify file was moved

    -- cleanup
    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Try to copy a file (drag to different volume) where
  there is not enough space to make the copy. Verify that the error
  message says that the file is too large to copy.
]]
test.Step(
  "Copy to folder without capacity",
  function()
    -- leave less than 200K free
    a2d.CreateFolder("/RAM1/CONSUMED")
    a2d.CopyPath("/TESTS/COPYING/SIZES/IS.200K", "/RAM1/CONSUMED") -- 200k
    a2d.DuplicatePath("/RAM1/CONSUMED/IS.200K", "DUPE1") -- 400k
    a2d.DuplicatePath("/RAM1/CONSUMED/IS.200K", "DUPE2") -- 600k
    a2d.DuplicatePath("/RAM1/CONSUMED/IS.200K", "DUPE3") -- 800k
    a2d.DuplicatePath("/RAM1/CONSUMED/IS.200K", "DUPE4") -- 1000k

    a2d.CopyPath("/TESTS/COPYING/SIZES/IS.200K", "/RAM1")
    a2dtest.WaitForAlert()
    test.Snap("verify alert is about file size")
    a2d.DialogOK()

    -- cleanup
    a2d.EraseVolume("RAM1")
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
    -- leave around 200K free
    a2d.CreateFolder("/RAM1/CONSUMED")
    a2d.CopyPath("/TESTS/COPYING/SIZES/IS.200K", "/RAM1/CONSUMED") -- 200k
    a2d.DuplicatePath("/RAM1/CONSUMED/IS.200K", "DUPE1") -- 400k
    a2d.DuplicatePath("/RAM1/CONSUMED/IS.200K", "DUPE2") -- 600k
    a2d.DuplicatePath("/RAM1/CONSUMED/IS.200K", "DUPE3") -- 800k
    a2d.CopyPath("/TESTS/COPYING/SIZES/IS.16K", "/RAM1/CONSUMED") -- 200k

    a2d.OpenPath("/TESTS/COPYING/SIZES")
    a2d.SelectAll()
    a2d.CopySelectionTo("/RAM1")
    a2dtest.WaitForAlert()
    test.Snap("verify error is about file size")
    a2d.DialogOK()

    -- cleanup
    a2d.EraseVolume("RAM1")
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
    -- leave around 200K free
    a2d.CreateFolder("/RAM1/CONSUMED")
    a2d.CopyPath("/TESTS/COPYING/SIZES/IS.200K", "/RAM1/CONSUMED") -- 200k
    a2d.DuplicatePath("/RAM1/CONSUMED/IS.200K", "DUPE1") -- 400k
    a2d.DuplicatePath("/RAM1/CONSUMED/IS.200K", "DUPE2") -- 600k
    a2d.DuplicatePath("/RAM1/CONSUMED/IS.200K", "DUPE3") -- 800k
    a2d.CopyPath("/TESTS/COPYING/SIZES/IS.16K", "/RAM1/CONSUMED") -- 200k

    a2d.CopyPath("/TESTS/COPYING/SIZES", "/RAM1")
    a2dtest.WaitForAlert()
    test.Snap("verify error is about file size")
    a2d.DialogOK()

    a2d.OpenPath("/RAM1/SIZES")
    a2d.SelectAll()
    test.Expect(#a2d.GetSelectedIcons(), 2, "2 files should have fit")

    -- cleanup
    a2d.EraseVolume("RAM1")
end)
