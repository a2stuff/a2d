a2d.ConfigureRepaintTime(0.25)

test.Step(
  "Basic OCR",
  function()
    local recognized = a2dtest.OCRScreen()
    test.Expect(recognized:find("File"), "screen should contain File")
    test.Expect(recognized:find("Edit"), "screen should contain Edit")
    test.Expect(recognized:find("View"), "screen should contain View")
    test.Expect(not recognized:find("Nope"), "screen should not contain Nope")
end)

test.Step(
  "Inverted text",
  function()
    local recognized = a2dtest.OCRScreen({invert=true})
    test.Expect(not recognized:find("File"), "screen should not contain inverted File")

    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)
    local recognized = a2dtest.OCRScreen({invert=true})
    test.Expect(recognized:find("File"), "screen should contain inverted File")

    a2d.DialogOK()
end)

test.Step(
  "Dimmed text",
  function()
    a2d.CloseAllWindows()
    a2d.ClearSelection()

    a2d.OpenMenu(a2d.FILE_MENU)
    local recognized = a2dtest.OCRScreen()
    test.Expect(not recognized:find("New Folder"), "New Folder should be dimmed")
    test.Expect(not recognized:find("Open"), "Open should be dimmed")
    test.Expect(not recognized:find("Close"), "Close should be dimmed")
    test.Expect(recognized:find("Quit"), "Quit should not be dimmed")
    apple2.EscapeKey()

    a2d.SelectPath("/A2.DESKTOP")
    a2d.OpenMenu(a2d.FILE_MENU)
    local recognized = a2dtest.OCRScreen()
    test.Expect(not recognized:find("New Folder"), "New Folder should be dimmed")
    test.Expect(recognized:find("Open"), "Open should not be dimmed")
    test.Expect(not recognized:find("Close"), "Close should be dimmed")
    test.Expect(recognized:find("Quit"), "Quit should not be dimmed")
    apple2.EscapeKey()

    a2d.OpenPath("/A2.DESKTOP")
    a2d.OpenMenu(a2d.FILE_MENU)
    local recognized = a2dtest.OCRScreen()
    test.Expect(recognized:find("New Folder"), "New Folder should not be dimmed")
    test.Expect(recognized:find("Open"), "Open should not be dimmed")
    test.Expect(recognized:find("Close"), "Close should not be dimmed")
    test.Expect(recognized:find("Quit"), "Quit should not be dimmed")
    apple2.EscapeKey()
end)
