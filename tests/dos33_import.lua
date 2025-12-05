--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 res/dos33_floppy.dsk"

======================================== ENDCONFIG ]]--

--[[============================================================

  "DOS 3.3 Import" tests

  ============================================================]]--

a2d.OpenPath("/A2.DESKTOP/EXTRAS")

test.Step(
  "Drive selection - OK button - Shortcut",
  function()
    a2d.SelectAndOpen("DOS33.IMPORT")
    test.Snap("verify OK button is disabled ")
    a2dtest.ExpectNothingHappened(apple2.ReturnKey)
    apple2.DownArrowKey() -- select drive
    test.Snap("verify OK button is enabled")
    apple2.ReturnKey()
    test.Snap("verify OK button flashes")
    emu.wait(10) -- floppy catalog
    test.Snap("verify catalog screen is shown")
    a2d.CloseWindow()
end)

test.Step(
  "Drive selection - OK button - Click",
  function()
    a2d.SelectAndOpen("DOS33.IMPORT")
    apple2.DownArrowKey() -- select drive
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(260,140)
        m.Click()
    end)
    emu.wait(10) -- floppy catalog
    test.Snap("verify catalog screen is shown")
    a2d.CloseWindow()
end)


test.Step(
  "Drive selection - Cancel button - Shortcut",
  function()
    a2d.SelectAndOpen("DOS33.IMPORT")
    apple2.EscapeKey()
    test.Snap("verify Cancel button flashes")
    a2d.WaitForRepaint()
    test.Snap("verify dialog closes")
end)

test.Step(
  "Drive selection - Cancel button - Click",
  function()
    a2d.SelectAndOpen("DOS33.IMPORT")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(320,140)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify dialog closes")
end)

test.Step(
  "File selection - Import button - Shortcut",
  function()
    a2d.SelectAndOpen("DOS33.IMPORT")
    apple2.DownArrowKey() -- select drive
    apple2.ReturnKey()
    emu.wait(10) -- floppy catalog
    a2dtest.ExpectNothingHappened(apple2.ReturnKey)
    apple2.DownArrowKey() -- select file
    apple2.ReturnKey()
    test.Snap("verify Import button flashes")
    emu.wait(10) -- floppy read
    a2d.CloseWindow()
end)

test.Step(
  "File selection - Cancel button - Shortcut",
  function()
    a2d.SelectAndOpen("DOS33.IMPORT")
    apple2.DownArrowKey() -- select drive
    apple2.ReturnKey()
    emu.wait(10) -- floppy catalog
    apple2.EscapeKey()
    test.Snap("verify Cancel button flashes")
    a2d.WaitForRepaint()
    test.Snap("verify dialog closes")
end)

