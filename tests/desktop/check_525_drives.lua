--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl5 superdrive -sl7 cffa2"
DISKARGS="\
  -hard1 $HARDIMG \
  -flop1 floppy_with_files.2mg \
  -flop3 prodos_floppy1.dsk -flop4 prodos_floppy2.dsk"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(1)

--[[
  Start desktop. Verify 5 volumes are present. Toggle option to not
  check 5.25" volumes on startup. Restart. Verify 3 volumes are
  present. Check All Volumes. Verify 5 volumes are present.
]]
test.Step(
  "Option to not poll 5.25 drives at startup",
  function()
    a2d.CloseAllWindows()
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 6, "5 volumes + trash should be selected")

    a2d.ToggleOptionSkipChecking525Drives()
    a2d.Reboot()
    a2d.WaitForDesktopReady()

    a2d.CloseAllWindows()
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 4, "3 volumes + trash should be selected")

    a2d.CheckAllDrives()
    a2d.SelectAll()
    test.ExpectEquals(#a2d.GetSelectedIcons(), 6, "5 volumes + trash should be selected")

    -- cleanup
    a2d.ToggleOptionSkipChecking525Drives()
    a2d.CloseAllWindows()
end)
