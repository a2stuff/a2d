--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl6 superdrive -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv -flop1 floppy_with_files.2mg"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)

--[[
  Launch DeskTop. Drag a volume icon onto a folder icon (with
  sufficient capacity). Verify that no alert is shown, and that the
  folder's creation date is unchanged and its modification date is
  updated. Repeat, but drag onto a folder window instead.
]]
test.Step(
  "copy volume to folder, verify dates",
  function()
    a2d.CreateFolder("/RAM1/FOLDER")
    a2d.SelectPath("/RAM1/FOLDER")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)
    test.Snap("note creation and modification")
    a2d.DialogOK()

    a2d.SelectPath("/WITH.FILES")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    emu.wait(120) -- let minutes advance

    a2d.SelectPath("/RAM1/FOLDER")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(src_x, src_y, dst_x, dst_y)

    a2d.SelectPath("/RAM1/FOLDER")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)
    test.Snap("verify creation date unchanged, modification date updated")
    a2d.DialogOK()

    -- TODO: Potentially flaky?

    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Find a folder containing a file where the folder and
  file's creation dates (File > Get Info) differ. Copy the folder.
  Select the file in the copied folder. File > Get Info. Verify that
  the file creation and modification dates match the original.
]]
test.Step(
  "file dates match original",
  function()
    a2d.SelectPath("/TESTS/COPYING/DATES/C.92.M.93")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)
    test.Snap("note creation and modification dates")
    a2d.DialogOK()

    a2d.CopyPath("/TESTS/COPYING/DATES", "/RAM1")
    a2d.SelectPath("/RAM1/DATES/C.92.M.93")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)
    test.Snap("verify creation and modification dates match original")
    a2d.DialogOK()

    a2d.EraseVolume("RAM1")
end)

--[[
  Launch DeskTop. Find a folder containing files and folders. Copy the
  folder to another volume. Using File > Get Info, compare the source
  and destination folders and files (both the top level folder and
  nested folders). Verify that the creation and modification dates
  match the original.
]]
test.Step(
  "folder dates match original",
  function()
    a2d.SelectPath("/TESTS/COPYING/DATES")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)
    test.Snap("note creation and modification dates")
    a2d.DialogOK()

    a2d.SelectPath("/TESTS/COPYING/DATES/C.16.M.16")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)
    test.Snap("note creation and modification dates")
    a2d.DialogOK()

    a2d.CopyPath("/TESTS/COPYING/DATES", "/RAM1")

    a2d.SelectPath("/RAM1/DATES")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)
    test.Snap("verify creation and modification dates match original")
    a2d.DialogOK()

    a2d.SelectPath("/RAM1/DATES/C.16.M.16")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)
    test.Snap("verify creation and modification dates match original")
    a2d.DialogOK()


    a2d.EraseVolume("RAM1")
end)
