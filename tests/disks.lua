a2d.ConfigureRepaintTime(5)

test.Step(
  "No error",
  function()
    test.Snap("verify boot volume is in top right")
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_COPY_TO)
    apple2.ControlKey("D")
    a2d.WaitForRepaint()
    test.Snap("verify boot volume is first disk")
end)
