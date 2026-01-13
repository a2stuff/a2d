--[[ BEGINCONFIG ========================================

MODEL="apple2gsr1"
MODELARGS="-sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 disk_a.2mg"
RESOLUTION="704x462"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

-- Smoke tests for verifying shift works as a modifier on the IIgs

--[[
  * Launch DeskTop. Click on a volume icon. Hold modifier and click a
    different volume icon. Verify that selection is extended.
]]
test.Step(
  "click second volume icon",
  function()
    a2d.Select("A")
    local x, y = a2dtest.GetSelectedIconCoords()
    a2d.SelectPath("/A2.DESKTOP")

    test.ExpectEquals(#a2d.GetSelectedIcons(), 1, "single icon selected")
    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)
        apple2.PressShift()
        m.Click()
        a2d.WaitForRepaint()
        apple2.ReleaseShift()
        emu.wait(1)
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), 2, "selection should be extended")
end)


--[[
  * Launch DeskTop. Select a volume icon. Hold modifier down and drag
    a selection rectangle around another volume icon. Verify that both
    are selected.
]]
test.Step(
  "mod-drag-select a second volume icon",
  function()
    a2d.Select("A")
    local x, y = a2dtest.GetSelectedIconCoords()

    a2d.Select("A2.DESKTOP")

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x-20, y-10)
        apple2.PressShift()
        m.ButtonDown()
        m.MoveByApproximately(40, 30)
        m.ButtonUp()
        apple2.ReleaseShift()
        emu.wait(1)
    end)
    test.ExpectEquals(#a2d.GetSelectedIcons(), 2, "selection should have been extended")
end)
