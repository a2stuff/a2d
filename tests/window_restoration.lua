--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv -flop1 res/prodos_floppy1.dsk"

======================================== ENDCONFIG ]]--

-- Need to ensure DESKTOP.FILE gets written out or window headers
-- will change

a2d.QuitAndRestart()

test.Step(
  "Subdirectory header values",
  function()
    a2d.OpenPath("/A2.DESKTOP/EXTRAS")
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(a2d.QuitAndRestart)
    a2d.CloseAllWindows()
end)

test.Step(
  "Launching Disk Copy",
  function()
    a2d.SelectAll()
    a2d.OAShortcut("O") -- File > Open
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(function()
        a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
        a2d.WaitForRestart()
        a2d.OAShortcut("Q") -- File > Quit
        a2d.WaitForRestart()
    end)

    a2d.CloseAllWindows()
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(function()
        a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
        a2d.WaitForRestart()
        a2d.OAShortcut("Q") -- File > Quit
        a2d.WaitForRestart()
    end)
    a2d.CloseAllWindows()
end)

test.Step(
  "Window geometry and scroll position",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES")
    a2d.GrowWindowBy(-40, -20)
    for i = 1,10 do
      apple2.RightArrowKey()
      apple2.DownArrowKey()
    end
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(a2d.QuitAndRestart)
    a2d.CloseAllWindows()
end)

test.Step(
  "Parent icon of restored window undims",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(a2d.QuitAndRestart)
    a2d.CloseAllWindows()
    test.Snap("verify volume icon not dimmed")
end)

test.Variants(
  {
    "As Icons",
    "As Small Icons",
    "By Name",
    "By Date",
    "By Size",
    "By Type",
  },
  function(idx, name)
    a2d.OpenPath("/TESTS/FILE.TYPES")
    a2d.InvokeMenuItem(a2d.VIEW_MENU, idx)
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(a2d.QuitAndRestart)
    a2d.OpenMenu(a2d.VIEW_MENU)
    test.Snap("verify "..name.." is checked")
    apple2.EscapeKey()
    a2d.CloseAllWindows()
end)

test.Step(
  "Disk II Drive polling",
  function()
    a2d.OpenPath("/FLOPPY1")
    a2d.Quit()
    apple2.GetDiskIIS6D1():unload()
    apple2.ReturnKey() -- run PRODOS from Bitsy Bye

    -- TODO: Verify only polled once - watch drive access?

    a2d.WaitForRestart()
end)

test.Step(
  "Drag selection still functions",
  function()
    a2d.OpenPath("/TEST/FILE.TYPES")
    a2d.ClearSelection()
    a2dtest.ExpectNothingChanged(a2d.QuitAndRestart)
    a2d.DragSelectMultipleVolumes()
    test.Snap("verify icons selected")
end)
