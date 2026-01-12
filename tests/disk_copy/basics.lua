a2d.ConfigureRepaintTime(0.25)

--[[
  Launch DeskTop. Special > Copy Disk.... File > Quit. Special > Copy
  Disk.... Ensure drive list is correct.
]]
test.Step(
  "drive list not corrupted on re-launch",
  function()
    a2d.CopyDisk()

    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()

    a2d.CopyDisk()
    test.Snap("verify drive list is correct (S7D1, S6D1, S6D2)")

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Special > Copy Disk.... Press Escape key. Verify
  that menu keyboard mode starts.
]]
test.Step(
  "escape key works to control menu",
  function()
    a2d.CopyDisk()

    apple2.EscapeKey()
    a2d.WaitForRepaint()
    test.Snap("verify menu showing")

    -- cleanup
    apple2.EscapeKey()
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Special > Copy Disk.... Press Open-Apple Q. Verify
  that DeskTop launches.
]]
test.Step(
  "OA+Q returns to DeskTop",
  function()
    a2d.CopyDisk()

    a2d.OAShortcut("Q")
    a2d.WaitForDesktopReady()
    a2dtest.ExpectNotHanging()
end)

--[[
  Launch DeskTop. Special > Copy Disk.... Press Solid-Apple Q. Verify
  that DeskTop launches.
]]
test.Step(
  "SA+Q returns to DeskTop",
  function()
    a2d.CopyDisk()

    a2d.SAShortcut("Q")
    a2d.WaitForDesktopReady()
    a2dtest.ExpectNotHanging()
end)

--[[
  Launch DeskTop. Clear selection. Special > Copy Disk.... Verify that
  no volume is selected and the OK button is dimmed.
]]
test.Step(
  "Invoke with no selection",
  function()
    a2d.CopyDisk()

    test.Snap("verify no selection, OK button is dimmed")
    a2dtest.ExpectNothingChanged(apple2.ReturnKey)

    -- cleanup
    a2d.OAShortcut("Q")
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Select a volume icon. Special > Copy Disk.... Verify
  that the corresponding volume is selected and the OK button is not
  dimmed.
]]
test.Step(
  "Invoke with selection",
  function()
    a2d.CopyDisk("/A2.DESKTOP")

    test.Snap("verify selection, OK button is not dimmed")

    a2dtest.ExpectRepaintFraction(
      0.1, 1.0,
      function()
        apple2.ReturnKey()
        emu.wait(5)
      end, "dialog should update")

    -- cleanup
    a2d.OAShortcut("Q")
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Special > Copy Disk.... Make a device selection
  (using mouse or keyboard) but don't click OK. Open the menu (using
  mouse or keyboard) but dismiss it. Verify that source device wasn't
  accepted.
]]
test.Step(
  "Using menu with keyboard doesn't commit selection",
  function()
    a2d.CopyDisk()

    -- make selection
    apple2.DownArrowKey()

    -- interact with menu
    apple2.EscapeKey()
    emu.wait(1)
    apple2.EscapeKey()
    emu.wait(1)

    test.Snap("verify still selecting source")

    -- cleanup
    a2d.OAShortcut("Q")
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Special > Copy Disk.... Select a drive using the
  mouse or keyboard, but don't click OK. Double-click the same drive.
  Verify that it was accepted, and that a prompt for an appropriate
  destination drive was shown.
]]
test.Step(
  "Double-clicking selected item commits",
  function()
    a2d.CopyDisk()

    -- select first item
    apple2.DownArrowKey()

    -- double-click first item
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w / 2, y + 5)
        m.DoubleClick()
    end)
    a2d.WaitForRepaint()

    test.Snap("verify now selecting destination (S7D1)")

    -- cleanup
    a2d.OAShortcut("Q")
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Special > Copy Disk.... Select a drive using the
  mouse or keyboard, but don't click OK. Double-click a different
  drive. Verify that it was accepted, and that a prompt for an
  appropriate destination drive was shown.
]]
test.Step(
  "Double-clicking other item commits",
  function()
    a2d.CopyDisk()

    -- select second first item
    apple2.DownArrowKey()
    apple2.DownArrowKey()

    -- double-click first item
    local x, y, w, h = a2dtest.GetFrontWindowContentRect()
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w / 2, y + 5)
        m.DoubleClick()
    end)
    a2d.WaitForRepaint()

    test.Snap("verify now selecting destination (S7D1)")

    -- cleanup
    a2d.OAShortcut("Q")
    a2d.WaitForDesktopReady()
end)

--[[
  Rename the `MODULES/DISK.COPY` file to something else. Launch
  DeskTop. Special > Copy Disk.... Verify that an alert is shown.
  Cancel the alert. Verify that DeskTop continues to run.
]]
test.Step(
  "Graceful failure if module not present",
  function()
    a2d.RenamePath("/A2.DESKTOP/MODULES/DISK.COPY", "TEMP")
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
    a2dtest.WaitForAlert()
    a2d.DialogCancel()
    a2d.RenamePath("/A2.DESKTOP/MODULES/TEMP", "DISK.COPY")
end)

--[[
  Launch DeskTop. Open and position a window. Special > Copy Disk....
  File > Quit. Verify that DeskTop restores the window.
]]
test.Step(
  "window restoration",
  function()
    a2d.Reboot() -- Ensure LOCAL/DESKTOP.FILE is written out
    a2d.WaitForDesktopReady()

    a2d.OpenPath("/A2.DESKTOP")
    a2d.ClearSelection()
    test.Snap("before")
    a2dtest.ExpectNothingChanged(function()
        a2d.CopyDisk()
        a2d.OAShortcut("Q")
        a2d.WaitForDesktopReady()
        a2d.ClearSelection()
    end)
end)

--[[
  Configure a system with 8 or fewer drives. Launch DeskTop. Special >
  Copy Disk.... Verify that the scrollbar is inactive.
]]
test.Step(
  "scrollbar disabled with 8 or fewer drives",
  function()
    a2d.CopyDisk()

    local hscroll, vscroll = a2dtest.GetFrontWindowScrollOptions()
    test.ExpectEquals(hscroll & mgtk.scroll.option_active, 0, "h scrollbar should be inactive")

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Special > Copy Disk.... Verify that the OK button is
  disabled. Select an item in the list with the keyboard. Verify that
  the OK button enables. Click in the blank space in the list below
  the items. Verify that the OK button disables. Click an item in the
  list. Verify that the OK button enables. Click OK to specify a
  source disk. Verify that the OK button disables. Repeat the above
  cases when selecting the destination disk.
]]
test.Step(
  "OK button disabled when selection cleared",
  function()
    a2d.CopyDisk()

    test.Snap("verify OK button disabled")
    a2dtest.ExpectNothingChanged(apple2.ReturnKey)

    ----------------------------------------
    -- Source
    ----------------------------------------

    -- select using keyboard
    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify OK button enabled")

    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    -- click in blank space
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w / 2, y + h - 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify OK button disabled")
    a2dtest.ExpectNothingChanged(apple2.ReturnKey)

    -- click on item
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w / 2, y + 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify OK button enabled")

    a2d.DialogOK()

    ----------------------------------------
    -- Destination
    ----------------------------------------

    -- select using keyboard
    apple2.DownArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify OK button enabled")

    local x, y, w, h = a2dtest.GetFrontWindowContentRect()

    -- click in blank space
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w / 2, y + h - 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify OK button disabled")
    a2dtest.ExpectNothingChanged(apple2.ReturnKey)

    -- click on item
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x + w / 2, y + 5)
        m.Click()
    end)
    a2d.WaitForRepaint()
    test.Snap("verify OK button enabled")

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Special > Copy Disk.... Select a source disk. Verify
  that the OK button enables. Click Read Drives. Verify that the OK
  button disables. Select a source disk then click OK. Click OK.
  Select a destination disk. Click Read Drives. Verify that the OK
  button disables.
]]
test.Step(
  "Read Drives resets OK button state",
  function()
    a2d.CopyDisk()

    a2dtest.ExpectNothingChanged(apple2.ReturnKey)

    -- select source
    apple2.UpArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify OK button enabled")

    -- Read Drives
    apple2.Type("R")
    emu.wait(5)
    test.Snap("verify OK button disabled")
    a2dtest.ExpectNothingChanged(apple2.ReturnKey)

    -- select source and click OK
    apple2.UpArrowKey()
    a2d.WaitForRepaint()
    a2d.DialogOK()
    test.Snap("verify OK button disabled")
    a2dtest.ExpectNothingChanged(apple2.ReturnKey)

    -- select destination
    apple2.UpArrowKey()
    a2d.WaitForRepaint()
    test.Snap("verify OK button enabled")

    -- Read Drives
    apple2.Type("R")
    emu.wait(5)
    test.Snap("verify OK button disabled")
    a2dtest.ExpectNothingChanged(apple2.ReturnKey)

    -- cleanup
    apple2.EscapeKey()
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)
