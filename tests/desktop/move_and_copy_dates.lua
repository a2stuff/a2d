--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl6 superdrive -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv -flop1 floppy_with_files.2mg"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)

function GetCreatedModifiedDates()
  local ocr = a2dtest.OCRScreen()
  local _, _, created_date = ocr:find("Created: +([^\n]*)  ")
  local _, _, modified_date = ocr:find("Modified: +([^\n]*)  ")
  return assert(created_date), assert(modified_date)
end

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
    local created_date, modified_date = GetCreatedModifiedDates()
    a2d.DialogOK()

    a2d.SelectPath("/WITH.FILES")
    local src_x, src_y = a2dtest.GetSelectedIconCoords()

    print("letting time advance 1 minute...")
    emu.wait(120) -- let minutes advance

    a2d.SelectPath("/RAM1/FOLDER")
    local dst_x, dst_y = a2dtest.GetSelectedIconCoords()
    a2d.Drag(src_x, src_y, dst_x, dst_y)
    emu.wait(10)

    a2d.SelectPath("/RAM1/FOLDER")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)

    local new_created_date, new_modified_date = GetCreatedModifiedDates()
    test.ExpectEquals(new_created_date, created_date, "creation date should be unchanged")
    test.ExpectNotEquals(new_modified_date, modified_date, "modification date should be updated")

    a2d.DialogOK()

    -- cleanup
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
    local created_date, modified_date = GetCreatedModifiedDates()
    a2d.DialogOK()

    a2d.CopyPath("/TESTS/COPYING/DATES", "/RAM1")
    a2d.SelectPath("/RAM1/DATES/C.92.M.93")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)

    local new_created_date, new_modified_date = GetCreatedModifiedDates()
    test.ExpectEquals(new_created_date, created_date, "creation date should match original")
    test.ExpectEquals(new_modified_date, modified_date, "modification date should match original")

    a2d.DialogOK()

    -- cleanup
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
    local folder_created_date, folder_modified_date = GetCreatedModifiedDates()
    a2d.DialogOK()

    a2d.SelectPath("/TESTS/COPYING/DATES/C.16.M.16")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)
    local file_created_date, file_modified_date = GetCreatedModifiedDates()
    a2d.DialogOK()

    a2d.CopyPath("/TESTS/COPYING/DATES", "/RAM1")

    a2d.SelectPath("/RAM1/DATES")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)
    local new_created_date, new_modified_date = GetCreatedModifiedDates()
    test.ExpectEquals(new_created_date, folder_created_date, "creation date should match original")
    test.ExpectEquals(new_modified_date, folder_modified_date, "modification date should match original")
    a2d.DialogOK()

    a2d.SelectPath("/RAM1/DATES/C.16.M.16")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)
    local new_created_date, new_modified_date = GetCreatedModifiedDates()
    test.ExpectEquals(new_created_date, file_created_date, "creation date should match original")
    test.ExpectEquals(new_modified_date, file_modified_date, "modification date should match original")
    a2d.DialogOK()

    -- cleanup
    a2d.EraseVolume("RAM1")
end)
