a2d.ConfigureRepaintTime(0.25)

--[[
  Rename the `APPLE.MENU` directory. Launch DeskTop. Verify that the
  Apple Menu has two "About" items and no separator.

  Create a new `APPLE.MENU` directory. Launch DeskTop. Verify that the
  Apple Menu has two "About" items and no separator.

  Create a new `APPLE.MENU` directory. Copy the `CHANGE.TYPE`
  accessory into it. Launch DeskTop. Verify that the Apple Menu has
  two "About" items, a separator, and "Change Type". Select the Change
  Type icon. Apple Menu > Change Type. Change the type to $8642.
  Restart DeskTop. Verify that the Apple Menu has two "About" items,
  and no separator.
]]
test.Step(
  "separator in Apple Menu",
  function()
    -- Folder missing
    a2d.RenamePath("/A2.DESKTOP/APPLE.MENU","AM")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
    a2d.OpenMenu(a2d.APPLE_MENU)
    test.Snap("verify two About items, no separator")
    apple2.EscapeKey()

    -- Folder empty
    a2d.CreateFolder("/A2.DESKTOP/APPLE.MENU")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
    a2d.OpenMenu(a2d.APPLE_MENU)
    test.Snap("verify two About items, no separator")
    apple2.EscapeKey()

    -- Folder single item
    a2d.CopyPath("/A2.DESKTOP/AM/CHANGE.TYPE", "/A2.DESKTOP/APPLE.MENU")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
    a2d.OpenMenu(a2d.APPLE_MENU)
    test.Snap("verify two About items, separator, one accessory")
    apple2.EscapeKey()

    -- Folder, single item but auxtype $8642
    a2d.SelectPath("/A2.DESKTOP/APPLE.MENU/CHANGE.TYPE")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, 3)
    apple2.TabKey() -- focus on auxtype
    a2d.ClearTextField()
    apple2.Type("8642")
    a2d.DialogOK()
    a2d.Reboot()
    a2d.WaitForDesktopReady()
    a2d.OpenMenu(a2d.APPLE_MENU)
    test.Snap("verify two About items, no separator")
    apple2.EscapeKey()

    a2d.DeletePath("/A2.DESKTOP/APPLE.MENU")
    a2d.RenamePath("/A2.DESKTOP/AM", "APPLE.MENU")
    a2d.CloseAllWindows()
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Open the `APPLE.MENU` directory. Use Apple Menu > Change Type
  accessory to change the AuxType of an accessory (e.g. `CALCULATOR`)
  from $0642 to $8642. Restart DeskTop. Verify that the accessory is
  not shown in the Apple Menu.

  TODO: Missing?
]]
