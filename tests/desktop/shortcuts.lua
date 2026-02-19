--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Delete the `LOCAL/SELECTOR.LIST` file from the startup disk, if it
  was present. Launch DeskTop. Verify that DeskTop does not hang.
]]
test.Step(
  "Starting without SELECTOR.LIST present",
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    apple2.WaitForBasicSystem()
    apple2.TypeLine("DELETE /A2.DESKTOP/EXTRAS/SELECTOR.LIST")
    apple2.TypeLine("PR#7")
    a2d.WaitForDesktopReady()
end)

--[[
  Delete the `LOCAL/SELECTOR.LIST` file from the startup disk, if it
  was present. Launch DeskTop. Verify that Shortcuts > Edit a
  Shortcut..., Shortcuts > Delete a Shortcut..., and Shortcuts > Run a
  Shortcut... are disabled, and the menu has no separator. Add a
  shortcut. Verify that Shortcuts > Edit a Shortcut..., Shortcuts >
  Delete a Shortcut..., and Shortcuts > Run a Shortcut... are now
  enabled, and the menu has a separator, and the shortcut appears.
  Delete the shortcut. Verify that the menu has its initial state
  again.
]]
test.Step(
  "Menu states - menu and list",
  function()
    a2d.OpenMenu(a2d.SHORTCUTS_MENU)
    local ocr = a2dtest.OCRScreen()
    test.ExpectNotMatch(ocr, "Edit a Shortcut...", "Edit should be disabled")
    test.ExpectNotMatch(ocr, "Delete a Shortcut...", "Delete should be disabled")
    test.ExpectNotMatch(ocr, "Run a Shortcut...", "Run should be disabled")
    test.Snap("verify no separator present")
    apple2.EscapeKey()

    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    emu.wait(1)
    a2d.OpenMenu(a2d.SHORTCUTS_MENU)
    local ocr = a2dtest.OCRScreen()
    test.ExpectMatch(ocr, "Edit a Shortcut...", "Edit should be enabled")
    test.ExpectMatch(ocr, "Delete a Shortcut...", "Delete should be enabled")
    test.ExpectMatch(ocr, "Run a Shortcut...", "Run should be enabled")
    test.Snap("verify separator present")
    test.ExpectMatch(ocr, "BASIC.system", "Shortcut should be present")
    apple2.EscapeKey()

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
    apple2.DownArrowKey()
    a2d.DialogOK()

    a2d.OpenMenu(a2d.SHORTCUTS_MENU)
    local ocr = a2dtest.OCRScreen()
    test.ExpectNotMatch(ocr, "Edit a Shortcut...", "Edit should be disabled")
    test.ExpectNotMatch(ocr, "Delete a Shortcut...", "Delete should be disabled")
    test.ExpectNotMatch(ocr, "Run a Shortcut...", "Run should be disabled")
    test.Snap("verify no separator present")
    apple2.EscapeKey()
end)

--[[
  Delete the `LOCAL/SELECTOR.LIST` file from the startup disk, if it
  was present. Launch DeskTop. Verify that Shortcuts > Edit a
  Shortcut..., Shortcuts > Delete a Shortcut..., and Shortcuts > Run a
  Shortcut... are disabled, and the menu has no separator. Add a
  shortcut to "list only". Verify that Shortcuts > Edit a Shortcut...,
  Shortcuts > Delete a Shortcut..., and Shortcuts > Run a Shortcut...
  are now enabled, but the menu still has no separator or shortcuts.
  Delete the shortcut. Verify that the menu has its initial state
  again.
]]
test.Step(
  "Menu states - item in list only",
  function()
    a2d.OpenMenu(a2d.SHORTCUTS_MENU)
    local ocr = a2dtest.OCRScreen()
    test.ExpectNotMatch(ocr, "Edit a Shortcut...", "Edit should be disabled")
    test.ExpectNotMatch(ocr, "Delete a Shortcut...", "Delete should be disabled")
    test.ExpectNotMatch(ocr, "Run a Shortcut...", "Run should be disabled")
    test.Snap("verify no separator present")
    apple2.EscapeKey()

    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {list_only=true})
    emu.wait(1)
    a2d.OpenMenu(a2d.SHORTCUTS_MENU)
    local ocr = a2dtest.OCRScreen()
    test.ExpectMatch(ocr, "Edit a Shortcut...", "Edit should be enabled")
    test.ExpectMatch(ocr, "Delete a Shortcut...", "Delete should be enabled")
    test.ExpectMatch(ocr, "Run a Shortcut...", "Run should be enabled")
    test.Snap("verify no separator present")
    apple2.EscapeKey()

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
    apple2.DownArrowKey()
    a2d.DialogOK()

    a2d.OpenMenu(a2d.SHORTCUTS_MENU)
    local ocr = a2dtest.OCRScreen()
    test.ExpectNotMatch(ocr, "Edit a Shortcut...", "Edit should be disabled")
    test.ExpectNotMatch(ocr, "Delete a Shortcut...", "Delete should be disabled")
    test.ExpectNotMatch(ocr, "Run a Shortcut...", "Run should be disabled")
    test.Snap("verify no separator present")
    apple2.EscapeKey()

    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Shortcuts > Add a Shortcut.... Check "at boot".
  Click Cancel. Shortcuts > Add a Shortcut.... Verify "at boot" is not
  checked.
]]
test.Step(
  "radio button state not retained - 'at boot'",
  function()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    a2d.OAShortcut("3") -- at boot
    a2d.DialogCancel()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    emu.wait(5)
    test.Snap("verify 'at boot' not checked")
    a2d.DialogCancel()
end)

--[[
  Launch DeskTop. Shortcuts > Add a Shortcut.... Check "at first use".
  Click Cancel. Shortcuts > Add a Shortcut.... Verify "at first use"
  is not checked.
]]
test.Step(
  "radio button state not retained - 'at first use'",
  function()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    a2d.OAShortcut("4") -- at first use
    a2d.DialogCancel()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    emu.wait(5)
    test.Snap("verify 'at first use' not checked")
    a2d.DialogCancel()
end)

--[[
  Launch DeskTop. Shortcuts > Add a Shortcut.... Check "list only".
  Click Cancel. Shortcuts > Add a Shortcut.... Verify "list only" is
  not checked.
]]
test.Step(
  "radio button state not retained - 'list only'",
  function()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    a2d.OAShortcut("2") -- list only
    a2d.DialogCancel()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    emu.wait(2)
    test.Snap("verify 'list only' not checked")
    a2d.DialogCancel()
end)

--[[
  Launch DeskTop. Shortcuts > Add a Shortcut.... Select a target.
  Check "list only" and "at first use". Click OK. Restart DeskTop.
  Shortcuts > Edit a Shortcut... Select the previously created
  shortcut. Click Cancel. Shortcuts > Add a Shortcut.... Verify that
  "list only" and "at first use" are not checked.
]]
test.Step(
  "radio button state not retained redux - 'list only' and 'at use'",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME", {list_only=true, copy="use"})
    a2d.Reboot()

    -- Will time out here waiting for system disk, with skip=0..2

    a2d.WaitForDesktopReady()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    apple2.DownArrowKey()
    a2d.DialogOK()
    emu.wait(5)
    a2d.DialogCancel()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    emu.wait(5)
    test.Snap("verify 'list only' and 'at first use' are not checked")
    a2d.DialogCancel()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Create a shortcut, "menu and list" / "at boot".
  Create a second shortcut, "menu and list", "at first use". Create a
  third shortcut, "menu and list", "never". Delete the first shortcut.
  Verify that the remaining shortcuts are "at first use" and "never".
]]
test.Step(
  "deleting doesn't mess up shortcut properties, primary",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME", {copy="boot"})
    a2d.AddShortcut("/A2.DESKTOP/READ.ME", {copy="use"})
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
    apple2.DownArrowKey()
    a2d.DialogOK()
    emu.wait(5)

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    apple2.DownArrowKey()
    a2d.DialogOK()
    emu.wait(5)
    test.Snap("verify 'menu and list' and 'at first use' are checked")
    a2d.DialogCancel()

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    apple2.DownArrowKey()
    apple2.DownArrowKey()
    a2d.DialogOK()
    emu.wait(5)
    test.Snap("verify 'menu and list' and 'never' are checked")
    a2d.DialogCancel()

    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Create a shortcut, "list only" / "at boot". Create a
  second shortcut, "list only", "at first use". Create a third
  shortcut, "list only", "never". Delete the first shortcut. Verify
  that the remaining shortcuts are "at first use" and "never".
]]
test.Step(
  "deleting doesn't mess up shortcut properties, secondary",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME", {list_only=true, copy="boot"})
    a2d.AddShortcut("/A2.DESKTOP/READ.ME", {list_only=true, copy="use"})
    a2d.AddShortcut("/A2.DESKTOP/READ.ME", {list_only=true})

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
    apple2.DownArrowKey()
    a2d.DialogOK()
    emu.wait(5)

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    apple2.DownArrowKey()
    a2d.DialogOK()
    emu.wait(5)
    test.Snap("verify 'list only' and 'at first use' are checked")
    a2d.DialogCancel()

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    apple2.DownArrowKey()
    apple2.DownArrowKey()
    a2d.DialogOK()
    emu.wait(5)
    test.Snap("verify 'list only' and 'never' are checked")
    a2d.DialogCancel()

    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Delete all shortcuts. Create a shortcut, "list only"
  / "never". Edit the shortcut. Verify that it is still "list only" /
  "never". Change it to "menu and list", and click OK. Verify that it
  appears in the Shortcuts menu.
]]
test.Step(
  "editing list vs. menu",
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    apple2.WaitForBasicSystem()
    apple2.TypeLine("DELETE /A2.DESKTOP/EXTRAS/SELECTOR.LIST")
    apple2.TypeLine("PR#7")
    a2d.WaitForDesktopReady()

    a2d.AddShortcut("/A2.DESKTOP/READ.ME", {list_only=true})
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    apple2.DownArrowKey()
    a2d.DialogOK()
    emu.wait(5)
    test.Snap("verify 'list only', 'never' are checked")
    a2d.OAShortcut("1") -- menu and list
    a2d.DialogOK()
    emu.wait(5)

    a2d.OpenMenu(a2d.SHORTCUTS_MENU)
    test.ExpectIMatch(a2dtest.OCRScreen(), "READ.ME", "READ.ME shortcut should appear")
    apple2.EscapeKey()

    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Configure a shortcut with the target being a
  directory. Open a window. Select a file icon. Invoke the shortcut.
  Verify that the previously selected file is no longer selected.
]]
test.Step(
  "shortcut to directory",
  function()
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS")
    a2d.SelectPath("/A2.DESKTOP/APPLE.MENU/CALCULATOR")
    a2d.MoveWindowBy(0,100)
    emu.wait(5)
    a2d.OAShortcut("1")
    test.ExpectEquals(#a2d.GetSelectedIcons(), 0, "selection should be cleared")

    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Create 8 shortcuts. Shortcuts > Add a Shortcut....
  Check "menu and list". Pick a file, enter a name, OK. Verify that a
  relevant alert is shown.
]]
test.Step(
  "8 in primary, add one more",
  function()
    for i = 1, 8 do
      a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    end

    a2d.SelectPath("/A2.DESKTOP/EXTRAS")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    a2d.OAShortcut("1") -- menu and list
    a2d.DialogOK()
    a2dtest.WaitForAlert({match="list is full"})
    a2d.DialogOK()
    a2d.DialogCancel()

    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Create 1 shortcut which is "menu and list" and 16
  shortcuts which are "list only". Shortcuts > Edit a Shortcut....
  Select the "menu and list" shortcut and click OK. Check "list only",
  and click OK. Verify that an alert is shown.
]]
test.Step(
  "16 in secondary, add one more",
  function()
    for i = 1, 16 do
      a2d.AddShortcut("/A2.DESKTOP/READ.ME", {list_only=true})
    end

    a2d.SelectPath("/A2.DESKTOP/EXTRAS")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    a2d.OAShortcut("2") -- list only
    a2d.DialogOK()
    a2dtest.WaitForAlert({match="list is full"})
    a2d.DialogOK()
    a2d.DialogCancel()

    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Create 8 shortcuts which are "menu and list" and 1
  shortcut which is "list only". Shortcuts > Edit a Shortcut....
  Select the "list only" shortcut and click OK. Check "menu and list",
  and click OK. Verify that an alert is shown.
]]
test.Step(
  "8 in primary, edit one more in",
  function()
    for i = 1, 8 do
      a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    end
    a2d.AddShortcut("/A2.DESKTOP/READ.ME", {list_only=true})

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    for i = 1, 9 do
      apple2.DownArrowKey()
    end
    a2d.DialogOK()

    a2d.OAShortcut("1") -- menu and list
    a2d.DialogOK()
    a2dtest.WaitForAlert({match="list is full"})
    a2d.DialogOK()
    a2d.DialogCancel()

    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Shortcuts > Add a Shortcut... and create a shortcut
  for a volume that is not the first volume on the DeskTop. Shortcuts
  > Edit a Shortcut... and select the new shortcut. Verify that the
  file picker shows the volume name as selected.
]]
test.Step(
  "volume order in file picker",
  function()
    a2d.AddShortcut("/TESTS")

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    apple2.DownArrowKey()
    a2d.DialogOK()
    emu.wait(5)

    test.ExpectMatch(a2dtest.OCRScreen({invert=true}), "TESTS",
                     "TESTS volume should be selected")

    a2d.DialogCancel()

    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Shortcuts > Add a Shortcut.... Verify that if the
  target is a volume directory and either "at boot" or "at first use"
  is selected, then an alert is shown when trying to commit the
  dialog.
]]
test.Step(
  "volume shortcuts can't be copied to RAMCard",
  function()
    a2d.SelectPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)

    a2d.OAShortcut("3")
    a2d.DialogOK()
    a2dtest.WaitForAlert({match="not valid"})
    a2d.DialogCancel()

    a2d.OAShortcut("4")
    a2d.DialogOK()
    a2dtest.WaitForAlert({match="not valid"})
    a2d.DialogCancel()

    a2d.OAShortcut("5")
    a2d.DialogOK()
    a2dtest.ExpectAlertNotShowing()

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
    apple2.DownArrowKey()
    a2d.DialogOK()
end)

--[[
  Launch DeskTop. Shortcuts > Add a Shortcut.... Verify that if the
  target is an alias (link file) and either "at boot" or "at first
  use" is selected, then an alert is shown when trying to commit the
  dialog.
]]
test.Step(
  "aliases can't be copied to RAMCard",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, -1) -- Make Alias
    apple2.ReturnKey()
    emu.wait(5)

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)

    a2d.OAShortcut("3")
    a2d.DialogOK()
    a2dtest.WaitForAlert({match="not valid"})
    a2d.DialogCancel()

    a2d.OAShortcut("4")
    a2d.DialogOK()
    a2dtest.WaitForAlert({match="not valid"})
    a2d.DialogCancel()

    a2d.OAShortcut("5")
    a2d.DialogOK()
    a2dtest.ExpectAlertNotShowing()

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_DELETE_A_SHORTCUT)
    apple2.DownArrowKey()
    a2d.DialogOK()

    a2d.DeletePath("/A2.DESKTOP/READ.ME.ALIAS")
end)

--[[
  Launch DeskTop. Select a file icon. Shortcuts > Add a Shortcut...
  Verify that the file dialog is navigated to the selected file's
  folder and the file is selected.
]]
test.Step(
  "file picker navigated to selected file",
  function()
    a2d.SelectPath("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    emu.wait(5)

    test.ExpectIMatch(a2dtest.OCRScreen(), "SAMPLE%.MEDIA.*A2.DESKTOP",
                      "should be in SAMPLE.MEDIA")

    test.ExpectIMatch(a2dtest.OCRScreen({invert=true}), "KARATEKA%.YELL",
                      "KARATEKA.YELL should be selected")

    a2d.DialogCancel()
end)

--[[
  Launch DeskTop. Select a volume icon. Shortcuts > Add a Shortcut...
  Verify that the file dialog is initialized to the list of drives and
  the volume is selected.
]]
test.Step(
  "file picker navigated to selected volime",
  function()
    a2d.SelectPath("/TESTS")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    emu.wait(5)

    test.ExpectMatch(a2dtest.OCRScreen({invert=true}), "TESTS",
                     "TESTS volume should be selected")

    a2d.DialogCancel()
end)

--[[
  Launch DeskTop. Clear selection. Shortcuts > Add a Shortcut...
  Verify that the file dialog is initialized to the startup disk and
  no file is selected.
]]
test.Step(
  "file picker with no selection",
  function()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
    emu.wait(5)

    test.Snap("verify no selection, showing A2.DESKTOP")
    a2d.DialogCancel()
end)

--[[
  Configure at least two shortcuts. Launch DeskTop. Shortcuts > Run a
  Shortcut.... Cancel. Verify that neither shortcut is invoked.
]]
test.Step(
  "accidental invocation",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_RUN_A_SHORTCUT)
    a2d.DialogCancel()
    emu.wait(5)
    a2dtest.ExpectNotHanging()

    -- cleanup
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Shortcuts > Run a Shortcut. Verify the OK button is
  disabled. Click on an item. Verify the OK button becomes enabled.
  Click on a blank option. Verify the OK button becomes disabled. Use
  the arrow keys to move selection. Verify that the OK button becomes
  enabled.
]]
test.Step(
  "shortcut picker button states",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_RUN_A_SHORTCUT)
    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()

    test.ExpectNotMatch(a2dtest.OCRScreen(), "OK", "OK button should be disabled")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x + 60, dialog_y + 30)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectMatch(a2dtest.OCRScreen(), "OK", "OK button should be enabled")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x + 300, dialog_y + 90)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.ExpectNotMatch(a2dtest.OCRScreen(), "OK", "OK button should be disabled")

    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.ExpectMatch(a2dtest.OCRScreen(), "OK", "OK button should be enabled")

    a2d.DialogCancel()

    -- cleanup
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Create a shortcut for a folder that is the 8th entry
  in the menu. Shortcuts > Edit a Shortcut... Select the entry. Click
  OK. Verify that DeskTop does not hang.
]]
test.Step(
  "edge case around 8th entry and folders",
  function()
    for i = 1, 7 do
      a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    end
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS")

    a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_EDIT_A_SHORTCUT)
    for i = 1, 8 do
      apple2.DownArrowKey()
    end
    a2d.DialogOK()
    emu.wait(5)
    a2d.DialogOK()
    emu.wait(5)
    a2dtest.ExpectNotHanging()

    -- cleanup
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Add a shortcut for a file. Rename the file. Run the
  shortcut. Verify that the alert is specific e.g. "file not found",
  not an unknown error.
]]
test.Step(
  "running a deleted shortcut",
  function()
    a2d.DuplicatePath("/A2.DESKTOP/READ.ME", "DUPE")
    a2d.AddShortcut("/A2.DESKTOP/DUPE")
    a2d.DeletePath("/A2.DESKTOP/DUPE")
    a2d.OAShortcut("1")
    a2dtest.WaitForAlert({match="file cannot be found"})
    a2d.DialogOK()

    -- cleanup
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Regression test - make sure volume shortcuts are created correctly.
]]
test.Step(
  "volume shortcuts are created with correct paths",
  function()
    a2d.AddShortcut("/A2.DESKTOP")
    a2d.OAShortcut("1")
    emu.wait(1)
    a2dtest.ExpectAlertNotShowing()
    test.ExpectEquals(a2dtest.GetFrontWindowTitle():upper(), "A2.DESKTOP", "shortcut should have opened window")

    -- cleanup
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)
