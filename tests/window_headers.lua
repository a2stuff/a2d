--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv "

======================================== ENDCONFIG ]]

--[[
  Open a folder with no items. Verify window header says "0 Items"

  Open a folder with only one item. Verify window header says "1 Item"

  Open a folder with two items. Verify window header says "2 Items"

  Open a folder with no items. File > New Folder. Enter a name. Verify
  that the window header says "1 Item"

  Open a folder with only one item. File > New Folder. Enter a name.
  Verify that the window header says "2 Items"
]]
test.Step(
  "Item counts",
  function()
    a2d.OpenPath("/TESTS/WINDOWS/HEADERS/EMPTY")
    test.Snap("verify header says '0 Items'")
    a2d.OpenPath("/TESTS/WINDOWS/HEADERS/ONE.ITEM")
    test.Snap("verify header says '1 Item'")
    a2d.OpenPath("/TESTS/WINDOWS/HEADERS/TWO.ITEMS")
    test.Snap("verify header says '2 Items'")

    a2d.OpenPath("/TESTS/WINDOWS/HEADERS/EMPTY")
    a2d.CreateFolder("NEW")
    test.Snap("verify header says '1 Item'")

    a2d.OpenPath("/TESTS/WINDOWS/HEADERS/ONE.ITEM")
    a2d.CreateFolder("NEW")
    test.Snap("verify header says '2 Items'")
end)

--[[
  Open window for an otherwise empty RAMDisk volume. Note the "K in
  disk" and "K available" values in the header. File > New Folder.
  Enter a name. Verify that the "K in disk" increases by 0.5, and that
  the "K available" decreases by 0 or 1. File > New Folder. Enter
  another name. Verify that the "K in disk" increases by 0.5, and that
  the "K available" decreases by 0 or 1.

  Open two windows for different volumes. Note the "items", "K in
  disk" and "K available" values in the header of the second window.
  File > New Folder. Enter a name. Verify that the "items" value
  increases by one, and "K in disk" increases by 0, 0.5 or 1, and that
  the "K available" decreases by 0, 0.5 or 1.
]]
test.Step(
  "Available space",
  function()
    a2d.OpenPath("/RAM1")
    test.Snap("note 'K in disk' and 'K available'")
    a2d.CreateFolder("NEW")
    test.Snap("verify 'K in disk' increased by 0.5 and 'K available' decreased by 0 or 1")
    a2d.CreateFolder("NEW2")
    test.Snap("verify 'K in disk' increased by 0.5 and 'K available' decreased by 0 or 1")

    a2d.CloseAllWindows()
    a2d.SelectAll()
    a2d.OAShortcut("O") -- File > Open
    a2d.CycleWindows()
    test.Snap("note 'K in disk' and 'K available'")
    a2d.CreateFolder("NEW3")
    test.Snap("verify 'K in disk' increased by 0, 0.5, or 1 and 'K available' decreased by 0, 0.5, or 1")
    a2d.CreateFolder("NEW4")
    test.Snap("verify 'K in disk' increased by 0, 0.5, or 1 and 'K available' decreased by 0, 0.5, or 1")
end)

--[[
  Open a window. Drag the window so that the left edge of the window
  is offscreen. Verify that the "X Items" display gets cut off. Drag
  the window so that the right edge of the window is offscreen. Verify
  that the "XK available" display gets cut off. Repeat with the window
  sized so that both scrollbars appear and thumbs moved to the middle
  of the scrollbars.
]]
test.Step(
  "Header clipping",
  function()
    a2d.OpenPath("/TESTS")
    a2d.MoveWindowBy(-150, 0)
    test.Snap("verify left edge of header text is cut off")
    a2d.MoveWindowBy(400, 0)
    test.Snap("verify right edge of header text is cut off")
    a2d.MoveWindowBy(-250, 0)

    -- Get both scrollbars showing
    a2d.GrowWindowBy(-100,-50)

    a2d.MoveWindowBy(-150, 0)
    test.Snap("verify left edge of header text is cut off")
    a2d.MoveWindowBy(450, 0)
    test.Snap("verify right edge of header text is cut off")
end)
