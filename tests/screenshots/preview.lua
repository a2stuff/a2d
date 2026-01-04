--[[============================================================

  Preview Accessories

  ============================================================]]

a2d.ConfigureRepaintTime(1)

test.Step(
  "Image Preview",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH")
    emu.wait(5) -- file load
    test.Snap("Image Preview")
    apple2.EscapeKey()
    a2d.CloseAllWindows()
end)

test.Step(
  "Electric Duet Preview",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/JESU.JOY")
    emu.wait(5) -- file load
    test.Snap("Electric Duet Preview")
    apple2.EscapeKey()
    a2d.CloseAllWindows()
end)

test.Step(
  "Font Preview",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/FONTS/MONACO.EN")
    emu.wait(5) -- file load
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "MONACO.EN", "window title should match")
    test.Snap("Font Preview")
    a2d.CloseAllWindows()
end)

test.Step(
  "Text Preview",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/LOREM.IPSUM")
    emu.wait(5) -- file load
    test.ExpectEqualsIgnoreCase(a2dtest.GetFrontWindowTitle(), "LOREM.IPSUM", "window title should match")
    test.Snap("Text Preview")
    apple2.Type(" ")
    a2d.WaitForRepaint()
    test.Snap("Text Preview")
    apple2.EscapeKey()
    a2d.CloseAllWindows()
end)
