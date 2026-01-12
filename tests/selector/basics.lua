--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv -flop1 res/ProDOS_2_4_3.po"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)
a2dtest.SetBankOffsetForSelectorModule()

--[[
  Load Shortcuts. Put a disk in Slot 6, Drive 1. Startup > Slot 6.
  Verify that the system boots the disk. Repeat for all other slots
  with drives.

  TODO: Other slots?
]]
test.Step(
  "Startup menu",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2d.InvokeMenuItem(3, 2) -- Startup, Slot 6

    apple2.WaitForBitsy()
    apple2.BitsyInvokePath("/A2.DESKTOP/DESKTOP.SYSTEM")

    a2d.WaitForDesktopReady()
    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch Shortcuts, invoke `BASIC.SYSTEM`. Ensure `/RAM` exists.
]]
test.Step(
  "/RAM exists",
  function()
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    apple2.Type("1")
    a2d.DialogOK()
    apple2.WaitForBasicSystem()
    apple2.TypeLine("CAT /RAM")
    util.WaitFor(
      "CAT output", function()
        return apple2.GrabTextScreen():match("BLOCKS FREE")
    end)
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch Shortcuts, invoke DeskTop, File > Quit, run `BASIC.SYSTEM`.
  Ensure `/RAM` exists.
]]
test.Step(
  "/RAM exists after Shortcuts and DeskTop",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.Quit()

    apple2.WaitForBitsy()
    apple2.BitsyInvokePath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")

    apple2.WaitForBasicSystem()
    apple2.TypeLine("CAT /RAM")
    util.WaitFor(
      "CAT output", function()
        return apple2.GrabTextScreen():match("BLOCKS FREE")
    end)
    apple2.TypeLine("-/A2.DESKTOP/DESKTOP.SYSTEM")
    a2d.WaitForDesktopReady()

    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch Shortcuts. Invoke a BIN program file. Verify that during
  launch the screen goes completely black before the program starts,
  with no text characters present.
]]
test.Step(
  "BIN goes black",
  function()
    a2d.AddShortcut("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2d.WaitForDesktopReady()
    apple2.Type("1")
    a2d.DialogOK({no_wait=true})
    while not apple2.GrabTextScreen():match("^%s*$") do
      emu.wait(1/60)
    end
    a2d.WaitForDesktopReady()
    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch Shortcuts. Type Open-Apple and R. Ensure "Run a Program..."
  dialog appears

  Launch Shortcuts. Type Solid-Apple and R. Ensure "Run a Program..."
  dialog appears
]]
test.Variants(
  {
    {"OA+R shortcut", a2d.OAShortcut},
    {"SA+R shortcut", a2d.SAShortcut},
  },
  function(idx, name, func)
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    func("R")
    emu.wait(5)
    test.Snap("verify 'Run a Program...' dialog appears")
    a2d.DialogCancel()

    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)


--[[
  Launch Shortcuts. Type Open-Apple and 6. Ensure machine boots from
  Slot 6

  Launch Shortcuts. Type Solid-Apple and 6. Ensure machine boots from
  Slot 6
]]
test.Variants(
  {
    {"OA+6 shortcut", a2d.OAShortcut},
    {"SA+6 shortcut", a2d.SAShortcut},
  },
  function(idx, name, func)
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    func("6")

    apple2.WaitForBitsy()
    apple2.BitsyInvokePath("/A2.DESKTOP/DESKTOP.SYSTEM")

    a2d.WaitForDesktopReady()
    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a system without a RAMCard. Launch Shortcuts. File > Run a
  Program.... Click Drives. Verify that the volume containing
  Shortcuts is the first disk shown.
]]
test.Step(
  "no ramcard, volume order",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2d.OAShortcut("R")
    emu.wait(5)
    apple2.ControlKey("D")
    emu.wait(5)
    test.Snap("verify boot volume is first")
    a2d.DialogCancel()

    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Using DeskTop, either delete `LOCAL/SELECTOR.LIST` or just delete
  all shortcuts. Configure Shortcuts to start. Launch Shortcuts.
  Ensure DeskTop is automatically invoked and starts correctly.
]]
test.Step(
  "no shortcuts",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.DeletePath("/A2.DESKTOP/LOCAL/SELECTOR.LIST")
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2dtest.ExpectNotHanging()

    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Configure a shortcut for `EXTRAS/BINSCII`. Launch Shortcuts. Invoke
  BINSCII. Verify that the display is not truncated.
]]
test.Step(
  "text screen not truncated launching BINSCII",
  function()
    a2d.AddShortcut("/A2.DESKTOP/EXTRAS/BINSCII")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    apple2.Type("1")
    a2d.DialogOK()

    util.WaitFor(
      "BINSCII", function()
        local text = apple2.GrabTextScreen()
        return text:match("BinSCII") and text:match("Which")
    end)

    apple2.Type("Q")

    a2d.WaitForDesktopReady()
    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch Shortcuts. Verify the OK button is disabled. Click on an
  item. Verify the OK button becomes enabled. Click on a blank option.
  Verify the OK button becomes disabled. Use the arrow keys to move
  selection. Verify that the OK button becomes enabled.
]]
test.Step(
  "button states",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    test.Snap("verify OK button is disabled")

    -- TODO: Expect this to fail - need banking support
    local dialog_x, dialog_y = a2dtest.GetFrontWindowContentRect()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(dialog_x + 100, dialog_y + 25)
        m.Click()
        a2d.WaitForRepaint()
        test.Snap("verify OK button enabled")

        m.MoveToApproximately(dialog_x + 400, dialog_y + 90)
        m.Click()
        a2d.WaitForRepaint()
        test.Snap("verify OK button disabled")
    end)

    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify OK button enabled")

    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch Shortcuts. Select an item. Verify that the OK button becomes
  enabled. File > Run a Program... Cancel the dialog. Verify that
  selection is cleared and that the OK button is disabled.
]]
test.Step(
  "button states after Run a Program",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify OK button enabled")

    a2d.OAShortcut("R")
    a2d.DialogCancel()
    emu.wait(1)

    test.Snap("verify OK button disabled and selection cleared")

    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch Shortcuts. File > Run a Program.... Select a folder. Verify
  that the OK button is disabled.
]]
test.Step(
  "Run a Program - can't select a folder",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2d.OAShortcut("R")
    apple2.ControlKey("D") -- Drives
    apple2.Type("A2.DESKTOP")
    apple2.ControlKey("O") -- Open
    apple2.Type("EXTRAS")
    test.Snap("verify OK button disabled")

    a2d.DialogCancel()
    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch Shortcuts. File > Run a Program.... Select
  `/TESTS/ALIASES/BASIC.ALIAS`. Verify that the program starts.
]]
test.Step(
  "Run an alias",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2d.OAShortcut("R")
    apple2.ControlKey("D") -- Drives
    apple2.Type("TESTS")
    apple2.ControlKey("O") -- Open
    apple2.Type("ALIASES")
    apple2.ControlKey("O") -- Open
    apple2.Type("BASIC.ALIAS")

    a2d.DialogOK()
    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch Shortcuts. File > Run a Program.... Select
  `/TESTS/ALIASES/DELETED.ALIAS`. Verify that an alert is shown.
]]
test.Step(
  "Run an alias for a deleted target",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2d.OAShortcut("R")
    apple2.ControlKey("D") -- Drives
    apple2.Type("TESTS")
    apple2.ControlKey("O") -- Open
    apple2.Type("ALIASES")
    apple2.ControlKey("O") -- Open
    apple2.Type("DELETED.ALIAS")

    a2d.DialogOK()
    a2dtest.WaitForAlert()
    a2d.DialogOK() -- dismiss alert
    a2d.DialogCancel() -- close file picker

    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Create a shortcut for `/TESTS/ALIASES/BASIC.ALIAS`.
  Launch Shortcuts. Invoke the shortcut. Verify that the program
  starts.
]]
test.Step(
  "Run an alias via a shortcut",
  function()
    a2d.AddShortcut("/TESTS/ALIASES/BASIC.ALIAS")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    apple2.Type("1")
    a2d.DialogOK()

    apple2.WaitForBasicSystem()
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()

    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Create a shortcut for
  `/TESTS/ALIASES/DELETED.ALIAS`. Launch Shortcuts. Invoke the
  shortcut. Verify that an alert is shown.
]]
test.Step(
  "Run an alias for a deleted target via a shortcut",
  function()
    a2d.AddShortcut("/TESTS/ALIASES/DELETED.ALIAS")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    apple2.Type("1")
    a2d.DialogOK()

    a2dtest.WaitForAlert()
    a2d.DialogOK() -- dismiss alert

    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Create a shortcut for `/TESTS/ALIASES/BASIC.ALIAS`.
  Delete the alias. Launch Shortcuts. Invoke the shortcut. Verify that
  an alert is shown.
]]
test.Step(
  "Run a deleted alias via a shortcut",
  function()
    a2d.AddShortcut("/TESTS/ALIASES/BASIC.ALIAS")
    -- Rename instead of delete; same effect, but lets us restore state
    a2d.RenamePath("/TESTS/ALIASES/BASIC.ALIAS", "RENAMED")
    a2d.ToggleOptionShowShortcutsOnStartup()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    apple2.Type("1")
    a2d.DialogOK()
    a2dtest.WaitForAlert()
    a2d.DialogOK() -- dismiss alert

    apple2.Type("D")
    a2d.WaitForDesktopReady()
    a2d.DeletePath("/A2.DESKTOP/LOCAL")
    a2d.Reboot()
    a2d.WaitForDesktopReady()
    a2d.RenamePath("/TESTS/ALIASES/RENAMED", "BASIC.ALIAS")
end)
