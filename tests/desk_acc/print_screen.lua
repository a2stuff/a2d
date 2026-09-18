
test.Step(
  "Print Screen shows alert if no SSC in slot 1",
  function()
    a2d.InvokePath("/A2.DESKTOP/EXTRAS/PRINT.SCREEN")
    a2dtest.WaitForAlert({match="Device not connected"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
end)




