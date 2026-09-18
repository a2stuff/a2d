--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl5 superdrive -sl7 cffa2"
DISKARGS="\
  -hard1 $HARDIMG \
  -flop1 floppy_with_files.2mg \
  -flop3 prodos_floppy1.dsk -flop4 prodos_floppy2.dsk"

======================================== ENDCONFIG ]]

--[[
  Start desktop. Verify 5 volumes are present. Toggle option to not
  check 5.25" volumes on startup. Restart. Verify 3 volumes are
  present. Check All Volumes. Verify 5 volumes are present.
]]
test.Step(
  "Option to not poll 5.25 drives at startup",
  function()
    desktop.CloseAllWindows()
    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 6, "5 volumes + trash should be selected")

    desktop.ToggleOptionSkipChecking525Drives()
    desktop.Reboot()
    a2d.WaitForDesktopReady()

    desktop.CloseAllWindows()
    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 4, "3 volumes + trash should be selected")

    desktop.CheckAllDrives()
    desktop.SelectAll()
    test.ExpectEquals(#desktop.GetSelectedIcons(), 6, "5 volumes + trash should be selected")

    -- cleanup
    desktop.ToggleOptionSkipChecking525Drives()
    desktop.CloseAllWindows()
end)
