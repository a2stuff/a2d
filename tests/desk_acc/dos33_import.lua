--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 dos33_floppy.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)

a2d.OpenPath("/A2.DESKTOP/EXTRAS")

--[[
  Select nothing. Verify that the OK button is disabled.

  Select nothing. Press the Return key. Verify that nothing happens.

  Select a slot/drive. Verify that the OK button is enabled.

  Select a slot/drive. Press the Return key. Verify that the OK button
  flashes and that the catalog dialog is shown.
]]
test.Step(
  "Drive selection - OK button - Shortcut",
  function()
    a2d.SelectAndOpen("DOS33.IMPORT")
    test.ExpectNotMatch(a2dtest.OCRScreen(), "OK", "OK button should be disabled ")

    a2dtest.ExpectNothingChanged(apple2.ReturnKey)

    apple2.DownArrowKey() -- select drive
    test.ExpectMatch(a2dtest.OCRScreen(), "OK", "OK button should be enabled ")

    apple2.ReturnKey()
    test.ExpectMatch(a2dtest.OCRScreen({invert=true}), "OK", "OK button should flash")

    emu.wait(10) -- floppy catalog
    test.ExpectMatch(a2dtest.OCRScreen(), "Disk Volume 254", "catalog screen should be shown")
    a2d.CloseWindow()
end)

--[[
  Select a slot/drive. Click OK. Verify that the catalog screen is
  shown.
]]
test.Step(
  "Drive selection - OK button - Click",
  function()
    a2d.SelectAndOpen("DOS33.IMPORT")
    apple2.DownArrowKey() -- select drive
    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x+95, dialog_y+70)
        m.Click()
    end)
    emu.wait(10) -- floppy catalog
    test.ExpectMatch(a2dtest.OCRScreen(), "Disk Volume 254", "catalog screen should be shown")
    a2d.CloseWindow()
end)

--[[
  Select a slot/drive. Press the Escape key. Verify that the Cancel
  button flashes and that the dialog closes.
]]
test.Step(
  "Drive selection - Cancel button - Shortcut",
  function()
    apple2.DownArrowKey() -- select drive

    a2d.SelectAndOpen("DOS33.IMPORT")
    local count = a2dtest.GetWindowCount()
    apple2.EscapeKey()
    test.ExpectMatch(a2dtest.OCRScreen({invert=true}), "Cancel", "Cancel button should flash")
    emu.wait(5)
    test.ExpectNotEquals(a2dtest.GetWindowCount(), count, "dialog should have closed")
end)

--[[
  Select a slot/drive. Click Cancel. Verify that the dialog closes.
]]
test.Step(
  "Drive selection - Cancel button - Click",
  function()
    apple2.DownArrowKey() -- select drive

    a2d.SelectAndOpen("DOS33.IMPORT")
    local count = a2dtest.GetWindowCount()
    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x+155, dialog_y+70)
        m.Click()
    end)
    a2d.WaitForRepaint()
    emu.wait(5)
    test.ExpectNotEquals(a2dtest.GetWindowCount(), count, "dialog should have closed")
end)

--[[
  Select a slot/drive. Click OK. Select a file. Press the Return key.
  Verify that the Import button flashes.
]]
test.Step(
  "File selection - Import button - Shortcut",
  function()
    a2d.SelectAndOpen("DOS33.IMPORT")
    apple2.DownArrowKey() -- select drive
    apple2.ReturnKey()
    emu.wait(10) -- floppy catalog
    a2dtest.ExpectNothingChanged(apple2.ReturnKey)
    apple2.DownArrowKey() -- select file
    apple2.ReturnKey()
    test.ExpectMatch(a2dtest.OCRScreen({invert=true}), "Import", "Import button should flash")
    emu.wait(10) -- floppy read
    a2d.CloseWindow()
end)

--[[
  Select a slot/drive. Click OK. Select a file. Press the Escape key.
  Verify that the Cancel button flashes and that the dialog closes.
]]
test.Step(
  "File selection - Cancel button - Shortcut",
  function()
    a2d.SelectAndOpen("DOS33.IMPORT")
    apple2.DownArrowKey() -- select drive
    apple2.ReturnKey()
    emu.wait(10) -- floppy catalog
    local count = a2dtest.GetWindowCount()
    apple2.EscapeKey()
    test.ExpectMatch(a2dtest.OCRScreen({invert=true}), "Close", "Close button should flash")
    a2d.WaitForRepaint()
    test.ExpectNotEquals(a2dtest.GetWindowCount(), count, "dialog should have closed")
end)

