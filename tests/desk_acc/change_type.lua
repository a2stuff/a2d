--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)

--[[
  Select a folder. Apple > Change Type. Modify only the type (e.g.
  `06`). Verify that an error is shown.
]]
test.Step(
  "Change type of folder fails",
  function()
    a2d.SelectPath("/TESTS/EMPTY.FOLDER")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CHANGE_TYPE)
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.Type("06")
    a2d.DialogOK()
    a2dtest.ExpectAlertShowing()
    a2d.DialogOK()
end)

--[[
  Select a folder. Apple > Change Type. Modify only the aux type (e.g.
  `8000`). Verify that no error is shown.
]]
test.Step(
  "Change auxtype of folder succeeds",
  function()
    a2d.SelectPath("/TESTS/EMPTY.FOLDER")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CHANGE_TYPE)
    apple2.TabKey()
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.Type("8000")
    a2d.DialogOK()
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
    a2d.OpenPath("/TESTS/FILE.TYPES")
    a2d.SelectAll()
    emu.wait(2)
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CHANGE_TYPE)
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.Type("06")
    a2d.DialogOK()
    a2dtest.ExpectAlertShowing()
    a2d.DialogOK()
    emu.wait(1)
    test.Snap("verify only non-folders are modified")
end)

--[[
  Select a non-folder and a folder. Apple > Change Type. Modify only
  the aux type (e.g. `8000`). Verify that no error is shown.
]]
test.Step(
  "Change aux types of folder and non-folders",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES")
    a2d.SelectAll()
    emu.wait(2)
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CHANGE_TYPE)
    apple2.TabKey()
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.Type("8000")
    a2d.DialogOK()
    a2dtest.ExpectAlertNotShowing()
end)

--[[
  Select a non-folder. Apple > Change Type. Specify `0F` as the type
  and click OK. Verify that an error is shown.
]]
test.Step(
  "Change type to folder is not allowed",
  function()
    a2d.SelectPath("/TESTS/FILE.TYPES/TEST08")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CHANGE_TYPE)
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.Type("0F")
    a2d.DialogOK()
    a2dtest.ExpectAlertShowing()
    a2d.DialogOK()
end)

--[[
  Select two folders. Apple > Change Type. Modify only the type (e.g.
  `06`). Verify that only a single error is shown.
]]
test.Step(
  "Single alert when modifying folder types",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES/FOLDER")
    a2d.SelectAll()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CHANGE_TYPE)
    apple2.DeleteKey()
    apple2.DeleteKey()
    apple2.Type("06")
    a2d.DialogOK()
    a2dtest.ExpectAlertShowing()
    a2d.DialogOK()
    a2dtest.ExpectAlertNotShowing()
end)
