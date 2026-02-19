a2d.ConfigureRepaintTime(0.25)

test.Step(
  "Basic OCR",
  function()
    local recognized = a2dtest.OCRScreen()
    test.ExpectMatch(recognized, "File", "screen should contain File")
    test.ExpectMatch(recognized, "Edit", "screen should contain Edit")
    test.ExpectMatch(recognized, "View", "screen should contain View")
    test.ExpectNotMatch(recognized, "Nope", "screen should not contain Nope")
end)

test.Step(
  "Inverted text",
  function()
    local recognized = a2dtest.OCRScreen({invert=true})
    test.ExpectNotMatch(recognized, "File", "screen should not contain inverted File")

    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)
    local recognized = a2dtest.OCRScreen({invert=true})
    test.ExpectMatch(recognized, "File", "screen should contain inverted File")

    a2d.DialogOK()
end)

test.Step(
  "Dimmed text",
  function()
    a2d.CloseAllWindows()
    a2d.ClearSelection()

    a2d.OpenMenu(a2d.FILE_MENU)
    local recognized = a2dtest.OCRScreen()
    test.ExpectNotMatch(recognized, "New Folder", "New Folder should be dimmed")
    test.ExpectNotMatch(recognized, "Open", "Open should be dimmed")
    test.ExpectNotMatch(recognized, "Close", "Close should be dimmed")
    test.ExpectMatch(recognized, "Quit", "Quit should not be dimmed")
    apple2.EscapeKey()

    a2d.SelectPath("/A2.DESKTOP")
    a2d.OpenMenu(a2d.FILE_MENU)
    local recognized = a2dtest.OCRScreen()
    test.ExpectNotMatch(recognized, "New Folder", "New Folder should be dimmed")
    test.ExpectMatch(recognized, "Open", "Open should not be dimmed")
    test.ExpectNotMatch(recognized, "Close", "Close should be dimmed")
    test.ExpectMatch(recognized, "Quit", "Quit should not be dimmed")
    apple2.EscapeKey()

    a2d.OpenPath("/A2.DESKTOP")
    a2d.OpenMenu(a2d.FILE_MENU)
    local recognized = a2dtest.OCRScreen()
    test.ExpectMatch(recognized, "New Folder", "New Folder should not be dimmed")
    test.ExpectMatch(recognized, "Open", "Open should not be dimmed")
    test.ExpectMatch(recognized, "Close", "Close should not be dimmed")
    test.ExpectMatch(recognized, "Quit", "Quit should not be dimmed")
    apple2.EscapeKey()
end)

test.Step(
  "Bounds",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.FILE_MENU, a2d.FILE_GET_INFO)

    if false then
    local recognized = a2dtest.OCRScreen()
    test.ExpectMatch(recognized, "Special", "screen should contain 'Special'")
    test.ExpectMatch(recognized, "Trash", "screen should contain 'Trash'")
    test.ExpectMatch(recognized, "Type", "screen should contain 'Type'")
    test.ExpectMatch(recognized, "Locked", "screen should contain 'Locked'")
    end

    local recognized = a2dtest.OCRScreen({x1=100, y1=20, x2=460, y2=152})
    test.ExpectNotMatch(recognized, "Special", "bounds should not contain 'Special'")
    test.ExpectNotMatch(recognized, "Trash", "bounds should not contain 'Trash'")
    test.ExpectMatch(recognized, "Type", "screen should contain 'Type'")
    test.ExpectMatch(recognized, "Locked", "screen should contain 'Locked'")

    a2d.DialogOK()
end)
