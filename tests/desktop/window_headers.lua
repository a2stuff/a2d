--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 tests.hdv "

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)

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
    test.Expect(a2dtest.OCRScreen():find("0 Items"), "header should say '0 Items'")
    a2d.OpenPath("/TESTS/WINDOWS/HEADERS/ONE.ITEM")
    test.Expect(a2dtest.OCRScreen():find("1 Item"), "header should say '1 Item'")
    a2d.OpenPath("/TESTS/WINDOWS/HEADERS/TWO.ITEMS")
    test.Expect(a2dtest.OCRScreen():find("2 Items"), "header should say '2 Items'")

    a2d.OpenPath("/TESTS/WINDOWS/HEADERS/EMPTY")
    a2d.CreateFolder("NEW")
    test.Expect(a2dtest.OCRScreen():find("1 Item"), "header should say '1 Item'")

    a2d.OpenPath("/TESTS/WINDOWS/HEADERS/ONE.ITEM")
    a2d.CreateFolder("NEW")
    test.Expect(a2dtest.OCRScreen():find("2 Items"), "header should say '2 Items'")
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
    function GetUsedFree()
      local _, _, used, free = a2dtest.OCRScreen():find(
        "Items? +(%d+[,.]?%d*)K in disk + (%d+[,.]?%d*)K available")
      used = assert(used):gsub(",", "")
      free = assert(free):gsub(",", "")
      return tonumber(used), tonumber(free)
    end

    a2d.OpenPath("/RAM1")
    a2d.GrowWindowBy(100, 0)
    local used, free = GetUsedFree()

    a2d.CreateFolder("NEW")
    local new_used, new_free = GetUsedFree()
    test.ExpectEquals(new_used - used, 0.5, "'K in disk' should increase by 0.5")
    test.ExpectLessThanOrEqual(free - new_free, 1, "'K available' should decrease by 0 or 1")
    used, free = new_used, new_free

    a2d.CreateFolder("NEW2")
    local new_used, new_free = GetUsedFree()
    test.ExpectEquals(new_used - used, 0.5, "'K in disk' should increase by 0.5")
    test.ExpectLessThanOrEqual(free - new_free, 1, "'K available' should decrease by 0 or 1")

    a2d.CloseAllWindows()
    a2d.SelectAll()
    a2d.OAShortcut("O") -- File > Open
    a2d.CycleWindows()
    emu.wait(1)
    local used, free = GetUsedFree()

    a2d.CreateFolder("NEW3")
    local new_used, new_free = GetUsedFree()
    test.ExpectLessThanOrEqual(new_used - used, 1, "'K in disk' should increase by 0, 0.5, or 1")
    test.ExpectLessThanOrEqual(free - new_free, 1, "'K available' should decrease by 0, 0.5 or 1")
    used, free = new_used, new_free

    a2d.CreateFolder("NEW4")
    local new_used, new_free = GetUsedFree()
    test.ExpectLessThanOrEqual(new_used - used, 1, "'K in disk' should increase by 0, 0.5, or 1")
    test.ExpectLessThanOrEqual(free - new_free, 1, "'K available' should decrease by 0, 0.5 or 1")
    used, free = new_used, new_free
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

    local ocr = a2dtest.OCRScreen()
    test.Expect(not ocr:find("Items"), "left edge of header text should be cut off")
    test.Expect(ocr:find("available"), "right edge of header text should be visible")

    a2d.MoveWindowBy(400, 0)

    local ocr = a2dtest.OCRScreen()
    test.Expect(ocr:find("Items"), "left edge of header text should be visible")
    test.Expect(not ocr:find("available"), "right edge of header text should be cut off")

    a2d.MoveWindowBy(-250, 0)

    -- Get both scrollbars showing
    a2d.GrowWindowBy(-100,-50)

    a2d.MoveWindowBy(-150, 0)

    local ocr = a2dtest.OCRScreen()
    test.Expect(not ocr:find("Items"), "left edge of header text should be cut off")
    test.Expect(ocr:find("available"), "right edge of header text should be visible")

    a2d.MoveWindowBy(450, 0)

    local ocr = a2dtest.OCRScreen()
    test.Expect(ocr:find("Items"), "left edge of header text should be visible")
    test.Expect(not ocr:find("available"), "right edge of header text should be cut off")
end)
