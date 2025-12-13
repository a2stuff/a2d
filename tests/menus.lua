--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv -flop1 res/prodos_floppy1.dsk"

======================================== ENDCONFIG ]]--

a2d.SelectPath("/A2.DESKTOP")
local vol_icon_x, vol_icon_y = a2dtest.GetSelectedIconCoords()
a2d.ClearSelection()

function PutSelectionOnDesktop()
  a2d.InMouseKeysMode(function(m)
      m.MoveToApproximately(vol_icon_x, vol_icon_y)
      m.Click()
  end)
end

test.Step(
  "No selection, no windows",
  function()
    a2d.ClearSelection()
    a2d.OpenMenu(a2d.FILE_MENU)
    test.Snap("verify ❌New Folder, ❌Open, ❌Close, ❌Close All, ❌Get Info, ❌Rename, ❌Duplicate, ❌Copy To, ❌Delete, ✅Quit")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.EDIT_MENU)
    test.Snap("verify ❌Cut, ❌Copy, ❌Paste, ❌Clear, ✅Select All")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.VIEW_MENU)
    test.Snap("verify ❌")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.SPECIAL_MENU)
    test.Snap("verify ✅Check All Drives, ❌Check Drive, ❌Eject Disk, ✅Format Disk, ✅Erase Disk, ✅Copy Disk, ❌Make Alias, ❌Show Original")
    apple2.EscapeKey()
end)

test.Step(
  "No selection, open window",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.ClearSelection()
    a2d.OpenMenu(a2d.FILE_MENU)
    test.Snap("verify ✅New Folder, ❌Open, ✅Close, ✅Close All, ❌Get Info, ❌Rename, ❌Duplicate, ❌Copy To, ❌Delete, ✅Quit")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.EDIT_MENU)
    test.Snap("verify ❌Cut, ❌Copy, ❌Paste, ❌Clear, ✅Select All")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.VIEW_MENU)
    test.Snap("verify ✅")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.SPECIAL_MENU)
    test.Snap("verify ✅Check All Drives, ❌Check Drive, ❌Eject Disk, ✅Format Disk, ✅Erase Disk, ✅Copy Disk, ❌Make Alias, ❌Show Original")
    apple2.EscapeKey()
    a2d.CloseAllWindows()
end)

test.Step(
  "Trash selected, no window",
  function()
    a2d.Select("Trash")
    a2d.OpenMenu(a2d.FILE_MENU)
    test.Snap("verify ❌New Folder, ❌Open, ❌Close, ❌Close All, ❌Get Info, ❌Rename, ❌Duplicate, ❌Copy To, ❌Delete, ✅Quit")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.EDIT_MENU)
    test.Snap("verify ❌Cut, ❌Copy, ❌Paste, ❌Clear, ✅Select All")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.VIEW_MENU)
    test.Snap("verify ❌")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.SPECIAL_MENU)
    test.Snap("verify ✅Check All Drives, ❌Check Drive, ❌Eject Disk, ✅Format Disk, ✅Erase Disk, ✅Copy Disk, ❌Make Alias, ❌Show Original")
    apple2.EscapeKey()
end)

test.Step(
  "Trash selected, open window",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    PutSelectionOnDesktop()
    a2d.Select("Trash")
    a2d.OpenMenu(a2d.FILE_MENU)
    test.Snap("verify ✅New Folder, ❌Open, ✅Close, ✅Close All, ❌Get Info, ❌Rename, ❌Duplicate, ❌Copy To, ❌Delete, ✅Quit")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.EDIT_MENU)
    test.Snap("verify ❌Cut, ❌Copy, ❌Paste, ❌Clear, ✅Select All")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.VIEW_MENU)
    test.Snap("verify ✅")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.SPECIAL_MENU)
    test.Snap("verify ✅Check All Drives, ❌Check Drive, ❌Eject Disk, ✅Format Disk, ✅Erase Disk, ✅Copy Disk, ❌Make Alias, ❌Show Original")
    apple2.EscapeKey()
    a2d.CloseAllWindows()
end)

test.Step(
  "Volume selected, no windows",
  function()
    a2d.Select("A2.DESKTOP")
    a2d.OpenMenu(a2d.FILE_MENU)
    test.Snap("verify ❌New Folder, ✅Open, ❌Close, ❌Close All, ✅Get Info, ✅Rename, ❌Duplicate, ✅Copy To, ❌Delete, ✅Quit")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.EDIT_MENU)
    test.Snap("verify ✅Cut, ✅Copy, ✅Paste, ✅Clear, ✅Select All")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.VIEW_MENU)
    test.Snap("verify ❌")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.SPECIAL_MENU)
    test.Snap("verify ✅Check All Drives, ✅Check Drive, ✅Eject Disk, ✅Format Disk, ✅Erase Disk, ✅Copy Disk, ❌Make Alias, ❌Show Original")
    apple2.EscapeKey()
end)

test.Step(
  "Volume selected, open window",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    PutSelectionOnDesktop()
    a2d.Select("A2.DESKTOP")
    a2d.OpenMenu(a2d.FILE_MENU)
    test.Snap("verify ✅New Folder, ✅Open, ✅Close, ✅Close All, ✅Get Info, ✅Rename, ❌Duplicate, ✅Copy To, ❌Delete, ✅Quit")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.EDIT_MENU)
    test.Snap("verify ✅Cut, ✅Copy, ✅Paste, ✅Clear, ✅Select All")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.VIEW_MENU)
    test.Snap("verify ✅")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.SPECIAL_MENU)
    test.Snap("verify ✅Check All Drives, ✅Check Drive, ✅Eject Disk, ✅Format Disk, ✅Erase Disk, ✅Copy Disk, ❌Make Alias, ❌Show Original")
    apple2.EscapeKey()
    a2d.CloseAllWindows()
end)

test.Step(
  "Multiple volumes selected, no windows",
  function()
    a2d.DragSelectMultipleVolumes()
    a2d.OpenMenu(a2d.FILE_MENU)
    test.Snap("verify ❌New Folder, ✅Open, ❌Close, ❌Close All, ✅Get Info, ❌Rename, ❌Duplicate, ✅Copy To, ❌Delete, ✅Quit")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.EDIT_MENU)
    test.Snap("verify ❌Cut, ❌Copy, ❌Paste, ❌Clear, ✅Select All")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.VIEW_MENU)
    test.Snap("verify ❌")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.SPECIAL_MENU)
    test.Snap("verify ✅Check All Drives, ✅Check Drive, ✅Eject Disk, ✅Format Disk, ✅Erase Disk, ✅Copy Disk, ❌Make Alias, ❌Show Original")
    apple2.EscapeKey()
end)

test.Step(
  "Multiple volumes selected, open window",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.DragSelectMultipleVolumes()
    a2d.OpenMenu(a2d.FILE_MENU)
    test.Snap("verify ✅New Folder, ✅Open, ✅Close, ✅Close All, ✅Get Info, ❌Rename, ❌Duplicate, ✅Copy To, ❌Delete, ✅Quit")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.EDIT_MENU)
    test.Snap("verify ❌Cut, ❌Copy, ❌Paste, ❌Clear, ✅Select All")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.VIEW_MENU)
    test.Snap("verify ✅")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.SPECIAL_MENU)
    test.Snap("verify ✅Check All Drives, ✅Check Drive, ✅Eject Disk, ✅Format Disk, ✅Erase Disk, ✅Copy Disk, ❌Make Alias, ❌Show Original")
    apple2.EscapeKey()
    a2d.CloseAllWindows()
end)

test.Step(
  "Volumes and Trash selected, no windows",
  function()
    a2d.SelectAll()
    a2d.OpenMenu(a2d.FILE_MENU)
    test.Snap("verify ❌New Folder, ✅Open, ❌Close, ❌Close All, ✅Get Info, ❌Rename, ❌Duplicate, ✅Copy To, ❌Delete, ✅Quit")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.EDIT_MENU)
    test.Snap("verify ❌Cut, ❌Copy, ❌Paste, ❌Clear, ✅Select All")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.VIEW_MENU)
    test.Snap("verify ❌")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.SPECIAL_MENU)
    test.Snap("verify ✅Check All Drives, ✅Check Drive, ✅Eject Disk, ✅Format Disk, ✅Erase Disk, ✅Copy Disk, ❌Make Alias, ❌Show Original")
    apple2.EscapeKey()
end)

test.Step(
  "Volumes and Trash selected, open window",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    PutSelectionOnDesktop()
    a2d.SelectAll()
    a2d.OpenMenu(a2d.FILE_MENU)
    test.Snap("verify ✅New Folder, ✅Open, ✅Close, ✅Close All, ✅Get Info, ❌Rename, ❌Duplicate, ✅Copy To, ❌Delete, ✅Quit")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.EDIT_MENU)
    test.Snap("verify ❌Cut, ❌Copy, ❌Paste, ❌Clear, ✅Select All")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.VIEW_MENU)
    test.Snap("verify ✅")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.SPECIAL_MENU)
    test.Snap("verify ✅Check All Drives, ✅Check Drive, ✅Eject Disk, ✅Format Disk, ✅Erase Disk, ✅Copy Disk, ❌Make Alias, ❌Show Original")
    apple2.EscapeKey()
    a2d.CloseAllWindows()
end)

test.Step(
  "Single non-alias file selected, open window",
  function()
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    a2d.OpenMenu(a2d.FILE_MENU)
    test.Snap("verify ✅New Folder, ✅Open, ✅Close, ✅Close All, ✅Get Info, ✅Rename, ✅Duplicate, ✅Copy To, ✅Delete, ✅Quit")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.EDIT_MENU)
    test.Snap("verify ✅Cut, ✅Copy, ✅Paste, ✅Clear, ✅Select All")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.VIEW_MENU)
    test.Snap("verify ✅")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.SPECIAL_MENU)
    test.Snap("verify ✅Check All Drives, ❌Check Drive, ❌Eject Disk, ✅Format Disk, ✅Erase Disk, ✅Copy Disk, ✅Make Alias, ❌Show Original")
    apple2.EscapeKey()
end)

test.Step(
  "Single alias file selected, open window",
  function()
    a2d.SelectPath("/TESTS/ALIASES/BASIC.ALIAS")
    a2d.OpenMenu(a2d.FILE_MENU)
    test.Snap("verify ✅New Folder, ✅Open, ✅Close, ✅Close All, ✅Get Info, ✅Rename, ✅Duplicate, ✅Copy To, ✅Delete, ✅Quit")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.EDIT_MENU)
    test.Snap("verify ✅Cut, ✅Copy, ✅Paste, ✅Clear, ✅Select All")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.VIEW_MENU)
    test.Snap("verify ✅")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.SPECIAL_MENU)
    test.Snap("verify ✅Check All Drives, ❌Check Drive, ❌Eject Disk, ✅Format Disk, ✅Erase Disk, ✅Copy Disk, ✅Make Alias, ✅Show Original")
    apple2.EscapeKey()
end)

test.Step(
  "Multiple files, open window",
  function()
    a2d.OpenPath("/TESTS/FILE.TYPES")
    a2d.SelectAll()
    a2d.OpenMenu(a2d.FILE_MENU)
    test.Snap("verify ✅New Folder, ✅Open, ✅Close, ✅Close All, ✅Get Info, ❌Rename, ❌Duplicate, ✅Copy To, ✅Delete, ✅Quit")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.EDIT_MENU)
    test.Snap("verify ❌Cut, ❌Copy, ❌Paste, ❌Clear, ✅Select All")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.VIEW_MENU)
    test.Snap("verify ✅")
    apple2.EscapeKey()
    a2d.OpenMenu(a2d.SPECIAL_MENU)
    test.Snap("verify ✅Check All Drives, ❌Check Drive, ❌Eject Disk, ✅Format Disk, ✅Erase Disk, ✅Copy Disk, ❌Make Alias, ❌Show Original")
    apple2.EscapeKey()
end)

--[[
  Launch DeskTop. Open a window. Verify that File > New Folder, File >
  Close, File > Close All, and everything in the View menu are
  enabled.
]]--
test.Step(
  "File menu options needing window are correct",
  function()
    a2d.OpenPath("/FLOPPY1")
    emu.wait(5) -- floppies are slow
    a2d.Quit()
    apple2.GetDiskIIS6D1():unload()

    apple2.BitsyInvokeFile("PRODOS")
    a2d.WaitForRestart()

    a2d.OpenPath("/A2.DESKTOP")
    a2d.CloseWindow()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.OpenMenu(a2d.FILE_MENU)
    test.Snap("verify New Folder, Close, Close All are enabled")
    apple2.EscapeKey()
end)

test.Step(
  "Control-Shift-2 doesn't show first menu item without shortcut",
  function()
    a2dtest.ExpectNothingChanged(function()
        apple2.ControlKey("@")
        a2d.WaitForRepaint()
    end)
end)
