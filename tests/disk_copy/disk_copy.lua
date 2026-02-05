--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 prodos_floppy1.dsk -flop2 dos33_floppy.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Double-click an item. Verify that the corresponding action button
  flashes
]]
test.Step(
  "Disk Selection - Double-click",
  function()
    a2d.CopyDisk()
    local listbox_x, listbox_y = a2dtest.GetFrontWindowContentRect()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(listbox_x+130, listbox_y+25)
        m.DoubleClick()
        test.Expect(a2dtest.OCRScreen({invert=true}):find("OK"), "OK button should flash")
    end)
    a2d.WaitForRepaint()

    a2d.InMouseKeysMode(function(m)
        m.MoveToApproximately(listbox_x+130, listbox_y+15)
        m.DoubleClick()
        test.Expect(a2dtest.OCRScreen({invert=true}):find("OK"), "OK button should flash")
    end)
end)
