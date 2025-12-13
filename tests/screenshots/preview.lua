--[[============================================================

  Preview Accessories

  ============================================================]]

test.Step(
  "Image Preview",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/MONARCH")
    emu.wait(5) -- file load
    test.Snap("Image Preview")
    apple2.EscapeKey()
    a2d.CloseAllWindows()
    return test.PASS
end)

test.Step(
  "Electric Duet Preview",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/JESU.JOY")
    test.Snap("Electric Duet Preview")
    apple2.EscapeKey()
    a2d.CloseAllWindows()
    return test.PASS
end)

test.Step(
  "Font Preview",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/FONTS/MONACO.EN")
    test.Snap("Font Preview")
    a2d.CloseAllWindows()
    return test.PASS
end)

test.Step(
  "Text Preview",
  function()
    a2d.OpenPath("/A2.DESKTOP/SAMPLE.MEDIA/LOREM.IPSUM")
    test.Snap("Text Preview")
    apple2.Type(" ")
    a2d.WaitForRepaint()
    test.Snap("Text Preview")
    apple2.EscapeKey()
    a2d.CloseAllWindows()
    return test.PASS
end)
