
a2d.ConfigureRepaintTime(0.25)

test.Step(
  "Print Screen shows alert if no SSC in slot 1",
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS/PRINT.SCREEN")
    a2dtest.WaitForAlert()
    a2d.DialogOK()
end)




