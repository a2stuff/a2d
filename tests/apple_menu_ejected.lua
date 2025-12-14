--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS=""
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(5)

--[[
  Eject the startup disk. Select an accessory (e.g. Calculator) from
  the Apple Menu. Verify that an alert is shown prompting to reinsert
  the startup disk. Insert the startup disk and click OK. Verify that
  the accessory launches.
]]
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

--[[
  Eject the startup disk. Select a folder (e.g. Control Panels) from
  the Apple Menu. Verify that an alert is shown prompting to reinsert
  the startup disk. Insert the startup disk and click OK. Verify that
  the folder window opens.
]]
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
