--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]--

test.Step(
  "Search all volumes",
  function()
    a2d.CloseAllWindows()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.FIND_FILES)
    apple2.Type("PRODOS")
    a2d.DialogOK()
    emu.wait(10)
    test.Snap("verify all volumes searched")
    a2d.DialogCancel()
end)

test.Step(
  "Search open volume",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.FIND_FILES)
    apple2.Type("PRODOS")
    a2d.DialogOK()
    emu.wait(10)
    test.Snap("verify only open volume searched")
    a2d.DialogCancel()
end)

test.Step(
  "Search open volume",
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.FIND_FILES)
    apple2.Type("PRODOS")
    a2d.DialogOK()
    emu.wait(10)
    test.Snap("verify only open folder searched")
    a2d.DialogCancel()
end)

test.Step(
  "OA+O on selection",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.FIND_FILES)
    apple2.Type("CAL*")
    a2d.DialogOK()
    emu.wait(10)
    apple2.DownArrowKey() -- select first result
    a2d.OAShortcut("O")
    a2d.WaitForRepaint()
    test.Snap("verify window opened and file selected")
end)

test.Step(
  "SA+O on selection",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.FIND_FILES)
    apple2.Type("CAL*")
    a2d.DialogOK()
    emu.wait(10)
    apple2.DownArrowKey() -- select first result
    a2d.SAShortcut("O")
    a2d.WaitForRepaint()
    test.Snap("verify window opened and file selected")
end)

test.Step(
  "Double-click on selection in inactive window",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU", true) -- leave parent open
    a2d.CycleWindows() -- put volume in foreground
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.FIND_FILES)
    apple2.Type("CAL*")
    a2d.DialogOK()
    emu.wait(10)
    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x+23, dialog_y+2)
        m.DoubleClick()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify window activated and file selected")
end)

test.Step(
  "Deeply nested",
  function()
    a2d.OpenPath("/TESTS/FIND.FILES")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.FIND_FILES)
    apple2.Type("*")
    a2d.DialogOK()
    emu.wait(10)
    test.Snap("verify no crash")
end)

test.Step(
  "Long pathnames",
  function()
    a2d.RenamePath("/TESTS", "ABCDEF123456789")
    a2d.OpenPath("/ABCDEF123456789")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.FIND_FILES)
    apple2.Type("*")
    a2d.DialogOK()
    emu.wait(10)
    test.Snap("verify no crash")
    a2d.RenamePath("/ABCDEF123456789", "/TESTS")
end)

test.Step(
  "Selection",
  function()
    a2d.OpenPath("/TESTS/FOLDER")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.FIND_FILES)
    apple2.Type("*")
    a2d.DialogOK()
    emu.wait(10)
    apple2.DownArrowKey()
    apple2.ReturnKey()
    emu.wait(10)
    apple2.DownArrowKey()
    test.Snap("verify only one entry appears highlighted")
end)



