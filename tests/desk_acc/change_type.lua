--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

--[[
  Select a folder. Apple > Change Type. Modify only the type (e.g.
  `06`). Verify that an error is shown.
]]
test.Step(
  "Change type of folder fails",
  function()
    desktop.SelectPath("/TESTS/EMPTY.FOLDER")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.CHANGE_TYPE)
    a2dtest.WaitForSystemTask()
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.Type("06")
    a2d.DialogOK()
    a2dtest.WaitForAlert({match="Modifying directories is not supported"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
end)

--[[
  Select a folder. Apple > Change Type. Modify only the aux type (e.g.
  `8000`). Verify that no error is shown.
]]
test.Step(
  "Change auxtype of folder succeeds",
  function()
    desktop.SelectPath("/TESTS/EMPTY.FOLDER")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.CHANGE_TYPE)
    a2dtest.WaitForSystemTask()
    apple2.TabKey()
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.Type("8000")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    a2dtest.ExpectAlertNotShowing()
end)

--[[
  Select a non-folder and a folder. Apple > Change Type. Modify only
  the type (e.g. `06`). Verify that an error is shown, and only the
  non-folder is modified.
]]
test.Step(
  "Change file types of folder and non-folder leaves folders alone",
  function()
    desktop.OpenWindow("/TESTS/FILE.TYPES")
    desktop.SelectAll()
    a2dtest.WaitForSystemTask()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.CHANGE_TYPE)
    a2dtest.WaitForSystemTask()
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.Type("06")
    a2d.DialogOK()
    a2dtest.WaitForAlert({match="Modifying directories is not supported"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    test.Snap("verify only non-folders are modified")
end)

--[[
  Select a non-folder and a folder. Apple > Change Type. Modify only
  the aux type (e.g. `8000`). Verify that no error is shown.
]]
test.Step(
  "Change aux types of folder and non-folders",
  function()
    desktop.OpenWindow("/TESTS/FILE.TYPES")
    desktop.SelectAll()
    a2dtest.WaitForSystemTask()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.CHANGE_TYPE)
    a2dtest.WaitForSystemTask()
    apple2.TabKey()
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.Type("8000")
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    a2dtest.ExpectAlertNotShowing()
end)

--[[
  Select a non-folder. Apple > Change Type. Specify `0F` as the type
  and click OK. Verify that an error is shown.
]]
test.Step(
  "Change type to folder is not allowed",
  function()
    desktop.SelectPath("/TESTS/FILE.TYPES/TEST08")
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.CHANGE_TYPE)
    a2dtest.WaitForSystemTask()
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.Type("0F")
    a2d.DialogOK()
    a2dtest.WaitForAlert({match="Modifying directories is not supported"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
end)

--[[
  Select two folders. Apple > Change Type. Modify only the type (e.g.
  `06`). Verify that only a single error is shown.
]]
test.Step(
  "Single alert when modifying folder types",
  function()
    desktop.OpenWindow("/TESTS/FILE.TYPES/FOLDER")
    desktop.SelectAll()
    a2d.InvokeMenuItem(desktop.APPLE_MENU, desktop.CHANGE_TYPE)
    a2dtest.WaitForSystemTask()
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.Type("06")
    a2d.DialogOK()
    a2dtest.WaitForAlert({match="Modifying directories is not supported"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
    a2dtest.ExpectAlertNotShowing()
end)
