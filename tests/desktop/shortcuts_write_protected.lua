--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl6 superdrive"
DISKARGS="-flop1 $ROHARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)

--[[
  Boot with an 800K image that is write protected. Add a shortcut.
  Verify the prompt asks about saving changes. Cancel. Verify that
  the Edit/Delete/Run a Shortcut menu items are enabled and that
  the shortcut has been added.
]]
test.Step(
  "Add a shortcut - write protected - Cancel",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    emu.wait(5)
    a2d.ClearTextField()
    apple2.Type("Shortcut~Name")
    a2d.DialogOK()

    a2dtest.WaitForAlert({match="save the changes"})
    a2d.DialogCancel()
    emu.wait(5)

    a2d.OpenMenu(a2d.SHORTCUTS_MENU)
    local ocr = a2dtest.OCRScreen()
    test.ExpectMatch(ocr, "Edit a Shortcut", "menu item should be disabled")
    test.ExpectMatch(ocr, "Delete a Shortcut", "menu item should be disabled")
    test.ExpectMatch(ocr, "Run a Shortcut", "menu item should be disabled")
    test.ExpectMatch(ocr, "Shortcut~Name", "shortcut should be in menu")
    apple2.EscapeKey()

    -- cleanup
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Boot with an 800K image that is write protected. Add a shortcut.
  Verify the prompt asks about saving changes. OK. Verify the
  prompt is about write protected disk. Try Again. Verify the
  prompt is about write protected disk. Cancel.
]]
test.Step(
  "Add a shortcut - write protected - OK, Try Again, Cancel",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    emu.wait(5)
    a2d.ClearTextField()
    apple2.Type("Shortcut~Name")
    a2d.DialogOK()

    a2dtest.WaitForAlert({match="save the changes"})
    a2d.DialogOK()
    emu.wait(5)

    a2dtest.WaitForAlert({match="write protected"})
    a2d.DialogOK()
    emu.wait(5)

    a2dtest.WaitForAlert({match="write protected"})
    a2d.DialogCancel()
    emu.wait(5)

    a2dtest.ExpectNotHanging()

    -- cleanup
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)
