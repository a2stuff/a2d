--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl6 superdrive"
DISKARGS="-flop1 $ROHARDIMG"

======================================== ENDCONFIG ]]

function SaveSettingsTest(name, filename, toggle_func)
  test.Step(
    name .. " - Prompt and Cancel",
    function()
      a2d.InvokePath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/" .. filename)
      toggle_func()
      a2d.CloseWindow()
      a2dtest.WaitForAlert({match="Do you want to save"})
      a2d.DialogCancel()
      a2dtest.ExpectAlertNotShowing()
      a2dtest.ExpectNotHanging()
  end)
  test.Step(
    name .. " - Prompt and OK and Cancel",
    function()
      a2d.InvokePath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/" .. filename)
      toggle_func()
      a2d.CloseWindow()
      a2dtest.WaitForAlert({match="Do you want to save"})
      a2d.DialogOK()
      a2dtest.WaitForAlert({match="write protected"})
      a2d.DialogCancel()
      a2dtest.ExpectAlertNotShowing()
      a2dtest.ExpectNotHanging()
  end)
  test.Step(
    name .. " - Prompt and OK and OK",
    function()
      a2d.InvokePath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/" .. filename)
      toggle_func()
      a2d.CloseWindow()
      a2dtest.WaitForAlert({match="Do you want to save"})
      a2d.DialogOK()
      a2dtest.WaitForAlert({match="write protected"})
      a2d.DialogOK()
      a2dtest.WaitForAlert({match="write protected"})
      a2d.DialogCancel()
      a2dtest.ExpectAlertNotShowing()
      a2dtest.ExpectNotHanging()
  end)
end


SaveSettingsTest("Options", "OPTIONS", function()
                   a2d.OAShortcut("1") -- toggle checkbox
                   a2d.OAShortcut("1")
end)

SaveSettingsTest("International", "INTERNATIONAL", function()
                   a2d.OAShortcut("1") -- toggle checkbox
                   a2d.OAShortcut("1")
end)

SaveSettingsTest("Control Panel", "CONTROL.PANEL", function()
                   a2d.OAShortcut("1") -- toggle checkbox
                   a2d.OAShortcut("1")
end)

SaveSettingsTest("Views", "VIEWS", function()
                   a2d.OAShortcut("2") -- change radio buttons
                   a2d.OAShortcut("1")
end)

SaveSettingsTest("Sounds", "SOUNDS", function()
                   apple2.DownArrowKey() -- change listbox index
                   a2dtest.WaitForSystemTask()
                   apple2.UpArrowKey()
                   a2dtest.WaitForSystemTask()
end)

SaveSettingsTest("Date & Time", "DATE.AND.TIME", function()
                   apple2.DownArrowKey() -- adjust time
                   apple2.UpArrowKey()
                   a2d.OAShortcut("2") -- change radio buttons
                   a2d.OAShortcut("1")
end)
