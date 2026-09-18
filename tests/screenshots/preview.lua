--[[============================================================

  Preview Accessories

  ============================================================]]

test.Step(
  "Image Preview",
  function()
    desktop.InvokePath("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH", {no_wait=true})
    emu.wait(10) -- compressed file load; full-screen DA
    test.Snap("Image Preview")
    apple2.EscapeKey()
    desktop.CloseAllWindows()
end)

test.Step(
  "Electric Duet Preview",
  function()
    desktop.InvokePath("/A2.DESKTOP/SAMPLE.MEDIA/JESU.JOY", {no_wait=true})
    emu.wait(5) -- file load; does not execute system tasks
    test.Snap("Electric Duet Preview")
    apple2.EscapeKey()
    desktop.CloseAllWindows()
end)

test.Step(
  "Font Preview",
  function()
    desktop.InvokePath("/A2.DESKTOP/SAMPLE.MEDIA/FONTS/MONACO.EN")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "MONACO.EN", "window title should match")
    test.Snap("Font Preview")
    desktop.CloseWindow()
    desktop.CloseAllWindows()
end)

test.Step(
  "Text Preview",
  function()
    desktop.InvokePath("/A2.DESKTOP/SAMPLE.MEDIA/LOREM.IPSUM")
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "LOREM.IPSUM", "window title should match")
    test.Snap("Text Preview")
    apple2.Type(" ") -- toggle fixed/proportional
    a2dtest.WaitForSystemTask()
    test.Snap("Text Preview")
    apple2.EscapeKey()
    desktop.CloseAllWindows()
end)
