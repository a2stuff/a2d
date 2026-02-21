--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv -flop1 prodos_floppy1.dsk -flop2 prodos_floppy2.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)

--[[
  Launch DeskTop. Trigger an alert with only OK (e.g. running a
  shortcut with disk ejected). Verify that Escape key closes alert.
]]
test.Step(
  "DeskTop - Escape closes alert",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.RenamePath("/A2.DESKTOP/READ.ME", "README")
    a2dtest.ExpectNothingChanged(function()
        a2d.OAShortcut("1")
        a2dtest.WaitForAlert({match="file cannot be found"})
        apple2.EscapeKey()
        a2d.WaitForRepaint()
    end)

    -- cleanup
    a2d.RenamePath("/A2.DESKTOP/README", "READ.ME")
end)

--[[
  Launch Shortcuts. Trigger an alert with only OK (e.g. running a
  shortcut that only works in DeskTop, like a DA). Verify that Escape
  key closes alert.
]]
test.Step(
  "Shortcuts - Escape closes alert",
  function()
    a2d.AddShortcut("/A2.DESKTOP/APPLE.MENU/CALCULATOR")
    a2d.ToggleOptionShowShortcutsOnStartup() -- Enable
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2dtest.ExpectNothingChanged(function()
        apple2.Type("1")
        a2d.DialogOK()
        a2dtest.WaitForAlert({match="Unable to run the program"})
        apple2.EscapeKey()
        a2d.WaitForRepaint()
    end)

    -- cleanup
    apple2.Type("D") -- Desktop
    a2d.WaitForDesktopReady()
    a2d.ToggleOptionShowShortcutsOnStartup() -- Disable
end)

--[[
  Launch DeskTop. Run Special > Copy Disk. Trigger an alert with only
  OK (e.g. let a copy complete successfully). Verify that Escape key
  closes alert.
]]
test.Step(
  "Disk Copy - Escape closes alert",
  function()
    a2d.CopyDisk()
    a2d.WaitForDesktopReady()

    apple2.UpArrowKey() -- S6D2
    apple2.UpArrowKey() -- S6D1
    a2d.DialogOK()

    apple2.UpArrowKey() -- S6D2
    a2d.DialogOK()

    a2d.DialogOK() -- confirm inserting source
    a2d.DialogOK() -- confirm inserting destination
    a2d.DialogOK() -- confirm overwrite

    a2dtest.WaitForAlert({match="copy was successful"})
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    a2dtest.ExpectAlertNotShowing()

    a2d.OAShortcut("Q")
    a2d.WaitForDesktopReady()
    a2d.DialogOK() -- dismiss duplicate volume name alert
end)

--[[
  Launch DeskTop. Select 3 files and drag them to another volume. Drag
  the same 3 files to the other volume again. When the alert with
  Yes/No/All buttons appears, mouse down on the Yes button, drag the
  cursor off the button, and release the mouse button. Verify that
  nothing happens. Click Yes to allow the copy to continue. Repeat for
  No and All.
]]
test.Step(
  "Yes/No/All",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/TOYS")
    a2d.SelectAll()
    a2d.CopySelectionTo("/RAM1")
    emu.wait(5) -- allow copy to complete
    a2d.CopySelectionTo("/RAM1")

    local yes_x, yes_y, no_x, no_y, all_x, all_y
    local delta_x, delta_y = 30, 5

    a2dtest.OCRIterate(function(run, x, y)
        if run:match("Yes") then
          yes_x, yes_y = x + delta_x, y + delta_y
        elseif run:match("No") then
          no_x, no_y = x + delta_x, y + delta_y
        elseif run:match("All") then
          all_x, all_y = x + delta_x, y + delta_y
        end
    end)

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(yes_x, yes_y)
        m.ButtonDown()
        emu.wait(2/60)
        test.Expect(a2dtest.OCRScreen({invert=true}):match("Yes"), "should be down on Yes")
        m.MoveByApproximately(20, 20)
        a2dtest.ExpectNothingChanged(m.ButtonUp)
        m.MoveToApproximately(yes_x, yes_y)
        m.Click()
        emu.wait(5) -- allow copy to continue

        m.MoveToApproximately(no_x, no_y)
        m.ButtonDown()
        emu.wait(2/60)
        test.Expect(a2dtest.OCRScreen({invert=true}):match("No"), "should be down on No")
        m.MoveByApproximately(20, 20)
        a2dtest.ExpectNothingChanged(m.ButtonUp)
        m.MoveToApproximately(no_x, no_y)
        m.Click()
        emu.wait(5) -- allow copy to continue

        m.MoveToApproximately(all_x, all_y)
        m.ButtonDown()
        emu.wait(2/60)
        test.Expect(a2dtest.OCRScreen({invert=true}):match("All"), "should be down on All")
        m.MoveByApproximately(20, 20)
        a2dtest.ExpectNothingChanged(m.ButtonUp)
        m.MoveToApproximately(all_x, all_y)
        m.Click()
        emu.wait(5) -- allow copy to continue
    end)
end)

