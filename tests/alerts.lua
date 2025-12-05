--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv -flop1 res/prodos_floppy1.dsk -flop2 res/prodos_floppy2.dsk"

======================================== ENDCONFIG ]]--

test.Step(
  "DeskTop - Escape closes alert",
  function()
    a2d.AddShortcut("/A2.DESKTOP/READ.ME")
    a2d.RenamePath("/A2.DESKTOP/READ.ME", "README")
    a2dtest.ExpectNothingHappened(function()
        a2d.OAShortcut("1")
        test.Snap("verify alert shown")
        apple2.EscapeKey()
        a2d.WaitForRepaint()
    end)
end)

test.Step(
  "Shortcuts - Escape closes alert",
  function()
    a2d.AddShortcut("/A2.DESKTOP/APPLE.MENU/CALCULATOR")
    a2d.ToggleOptionShowShortcutsOnStartup() -- Enable
    a2d.Reboot()

    a2dtest.ExpectNothingHappened(function()
        apple2.Type("1")
        a2d.DialogOK()
        test.Snap("verify alert shown")
        apple2.EscapeKey()
        a2d.WaitForRepaint()
    end)

    apple2.Type("D") -- Desktop
    a2d.WaitForRestart()
    a2d.ToggleOptionShowShortcutsOnStartup() -- Disable
end)

test.Step(
  "Disk Copy - Escape closes alert",
  function()
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
    a2d.WaitForRestart()

    apple2.UpArrowKey() -- S6D2
    apple2.UpArrowKey() -- S6D1
    a2d.DialogOK()

    apple2.UpArrowKey() -- S6D2
    a2d.DialogOK()

    a2d.DialogOK() -- confirm inserting source
    a2d.DialogOK() -- confirm inserting destination
    a2d.DialogOK() -- confirm overwrite
    emu.wait(10) -- wait for copy to complete

    test.Snap("verify alert shown")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    test.Snap("verify alert dismissed")

    a2d.OAShortcut("Q")
    a2d.WaitForRestart()
    a2d.DialogOK() -- dismiss duplicate volume name alert
end)

test.Step(
  "Yes/No/All",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/TOYS")
    a2d.SelectAll()
    a2d.CopySelectionTo("/RAM1")
    emu.wait(5) -- allow copy to complete
    a2d.CopySelectionTo("/RAM1")
    a2d.InMouseKeysMode(function(m)
        local btn_y = 110
        local yes_x = 280
        local no_x  = 360
        local all_x = 420

        m.MoveToApproximately(yes_x,btn_y)
        m.ButtonDown()
        emu.wait(2/60)
        test.Snap("verify down on yes")
        m.MoveByApproximately(20, 20)
        a2dtest.ExpectNothingHappened(m.ButtonUp)
        m.MoveToApproximately(yes_x,btn_y)
        m.Click()
        emu.wait(5) -- allow copy to continue

        m.MoveToApproximately(no_x,btn_y)
        m.ButtonDown()
        emu.wait(2/60)
        test.Snap("verify down on no")
        m.MoveByApproximately(20, 20)
        a2dtest.ExpectNothingHappened(m.ButtonUp)
        m.MoveToApproximately(yes_x,btn_y)
        m.Click()
        emu.wait(5) -- allow copy to continue

        m.MoveToApproximately(all_x,btn_y)
        m.ButtonDown()
        emu.wait(2/60)
        test.Snap("verify down on all")
        m.MoveByApproximately(20, 20)
        a2dtest.ExpectNothingHappened(m.ButtonUp)
        m.MoveToApproximately(all_x,btn_y)
        m.Click()
        emu.wait(5) -- allow copy to continue
    end)
end)

