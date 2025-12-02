--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]--

test.Step(
  "Settings saved back to boot volume",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
    a2d.OAShortcut("1") -- Enable "Copy to RAMCard"
    a2d.CloseWindow()
    a2d.CloseAllWindows()
    a2d.InvokeMenuItem(a2d.STARTUP_MENU, 1) -- slot 7
    a2d.WaitForCopyToRAMCard()

    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/CONTROL.PANEL")
    apple2.RightArrowKey()
    apple2.RightArrowKey()
    apple2.ControlKey("D")
    a2d.WaitForRepaint()
    a2d.CloseWindow()
    a2d.CloseAllWindows()
    a2d.InvokeMenuItem(a2d.STARTUP_MENU, 1) -- slot 7
    a2d.WaitForCopyToRAMCard()

    test.Snap("verify changed desktop is retained")
end)
