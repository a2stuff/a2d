--[[ BEGINCONFIG ========================================

MODEL="apple2cp"
MODELARGS=""
DISKARGS="-flop3 $HARDIMG"

======================================== ENDCONFIG ]]--

test.Step(
  "Alert shown on File > Open if disk ejected",
  function()
    local drive = apple2.Get35Drive1()
    drive:unload()

    a2d.SelectPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_OPEN-1)
    a2dtest.ExpectAlertShowing()
end)

