--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS=""
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]--

test.Step(
  "separator in Apple Menu",
  function()
    -- Folder missing
    a2d.RenamePath("/A2.DESKTOP/APPLE.MENU","AM")
    a2d.Reboot()
    a2d.OpenMenu(a2d.APPLE_MENU)
    test.Snap("verify two About items, no separator")
    apple2.EscapeKey()

    -- Folder empty
    a2d.CreateFolder("/A2.DESKTOP/APPLE.MENU")
    a2d.Reboot()
    a2d.OpenMenu(a2d.APPLE_MENU)
    test.Snap("verify two About items, no separator")
    apple2.EscapeKey()

    -- Folder single item
    a2d.CopyPath("/A2.DESKTOP/AM/CHANGE.TYPE", "/A2.DESKTOP/APPLE.MENU")
    a2d.Reboot()
    a2d.OpenMenu(a2d.APPLE_MENU)
    test.Snap("verify two About items, separator, one accessory")
    apple2.EscapeKey()

    -- Folder, single item but auxtype $8642
    a2d.SelectPath("/A2.DESKTOP/APPLE.MENU/CHANGE.TYPE")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, 3)
    apple2.TabKey() -- focus on auxtype
    apple2.ControlKey("X") -- clear
    apple2.Type("8642")
    a2d.DialogOK()
    a2d.Reboot()
    a2d.OpenMenu(a2d.APPLE_MENU)
    test.Snap("verify two About items, no separator")
    apple2.EscapeKey()

    a2d.DeletePath("/A2.DESKTOP/APPLE.MENU")
    a2d.RenamePath("/A2.DESKTOP/AM", "APPLE.MENU")
    a2d.CloseAllWindows()
    a2d.Reboot()
end)

test.Step(
  "Accessories with disk ejected",
  function()
    local drive = apple2.Get35Drive1()
    local current = drive.filename
    drive:unload()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CALCULATOR)
    a2dtest.ExpectAlertShowing()
    drive:load(current)
    a2d.DialogOK()
    test.ExpectEquals(a2dtest.GetFrontWindowTitle(), "Calc", "Calculator should be open")
    a2d.CloseWindow()
end)

test.Step(
  "Folder with disk ejected",
  function()
    local drive = apple2.Get35Drive1()
    local current = drive.filename
    drive:unload()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.CONTROL_PANELS)
    a2dtest.ExpectAlertShowing()
    drive:load(current)
    a2d.DialogOK()
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "CONTROL.PANELS", "Control Panels window should be open")
    a2d.CloseWindow()
end)
