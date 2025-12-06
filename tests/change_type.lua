--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]--

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
    test.Snap("verify only non-folders are modified")
end)

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
