--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv "

======================================== ENDCONFIG ]]--

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
    test.Snap("verify header says '2 Ites'")
end)

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

test.Step(
  "Header clipping",
  function()
    a2d.OpenPath("/TESTS")
    a2d.MoveWindowBy(-150, 0)
    test.Snap("verify left edge of header text is cut off")
    a2d.MoveWindowBy(400, 0)
    test.Snap("verify right edge of header text is cut off")
    a2d.MoveWindowBy(-250, 0)

    a2d.GrowWindowBy(-100,-50)
    test.Snap("both scrollbars?")

    a2d.MoveWindowBy(-150, 0)
    test.Snap("verify left edge of header text is cut off")
    a2d.MoveWindowBy(450, 0)
    test.Snap("verify right edge of header text is cut off")
end)
