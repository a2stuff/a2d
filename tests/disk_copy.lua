--[[ BEGINCONFIG ========================================

DISKARGS="-hard1 $HARDIMG -flop1 res/prodos_floppy1.dsk -flop2 res/dos33_floppy.dsk"

======================================== ENDCONFIG ]]--

--[[============================================================

  "Disk Copy" tests

  ============================================================]]--

test.Step(
  "Disk Selection - Double-click",
  function()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
    a2d.WaitForRestart()

    a2d.InMouseKeysMode(function(m)
        m.GoToApproximately(180,90)
        m.DoubleClick()
        test.Snap("verify OK button flashes")
    end)
    a2d.WaitForRepaint()

    a2d.InMouseKeysMode(function(m)
        m.GoToApproximately(180,60)
        m.DoubleClick()
        test.Snap("verify OK button flashes")
    end)
end)
