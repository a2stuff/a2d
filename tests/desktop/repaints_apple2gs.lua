--[[ BEGINCONFIG ========================================

MODEL="apple2gsr1"
MODELARGS="-sl7 cffa2"
DISKARGS="-hard1 $HARDIMG"
RESOLUTION="704x462"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  * Launch DeskTop. Open a volume window with many icons. Click on a file icon to select it. Modifier-click the icon to deselect it. Drag-select on the desktop covering a large area. Verify that no file icons are erroneously painted.
  * Launch DeskTop. Open a volume window with many icons. Modifier-click on a file icon to select it. Drag-select on the desktop covering a large area. Verify that no file icons are erroneously painted.
]]
test.Variants(
  {
    {"modifier de-select - Shift (Apple IIgs)", function() end},
    {"modifier select - Shift (Apple IIgs)", a2d.ClearSelection},
  },
  function(idx, name, func)
    a2d.SelectPath("/A2.DESKTOP/READ.ME")
    local x, y = a2dtest.GetSelectedIconCoords()

    func()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(x, y)

        apple2.PressShift()
        m.Click()
        apple2.ReleaseShift()
    end)

    a2d.Drag(0, 60, 450, 190)
    test.Snap("verify no file icons repaint on desktop")
end)
