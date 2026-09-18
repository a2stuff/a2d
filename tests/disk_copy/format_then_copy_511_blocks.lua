--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl6 cffa2 -sl7 cffa2"
DISKARGS="-hard3 $HARDIMG -hard1 sizes/image_511_blocks_random.hdv -hard2 sizes/image_511_blocks_random.hdv"

======================================== ENDCONFIG ]]

--[[
  Format then Disk Copy Disk Copy with 511 blocks.
]]
test.Variants(
  {
    {"Format then Smart Block Copy 511 blocks", "quick"},
    {"Format then Full Disk Copy 511 blocks", "disk"},
  },
  function(idx, name, what)
    if a2dtest.IsAlertShowing() then  -- duplicate volume
      a2d.DialogOK()
      a2dtest.WaitForSystemTask()
    end

    desktop.CloseAllWindows()
    desktop.ClearSelection()
    a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_FORMAT_DISK-2)

    desktop.FormatEraseSelectSlotDrive(6, 1)
    a2d.ClearTextField()
    apple2.Type("NEW.NAME" .. idx)
    a2d.DialogOK()
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()

    --[[
      BUG: MAME/CFFA2 reports device as 512 blocks so it gets
      formatted as 512 blocks
    ]]

    a2dtest.WaitForSystemTask()

    desktop.ClearSelection()
    desktop.CopyDisk()
    a2dtest.ConfigureForDiskCopy()

    a2d.InvokeMenuItem(3, idx) -- Options > Smart Block Copy or Full Disk Copy

    -- select source
    apple2.UpArrowKey() -- S6D2
    apple2.UpArrowKey() -- S6D1
    a2dtest.WaitForSystemTask()
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    -- select destination
    apple2.UpArrowKey() -- S6D2
    a2dtest.WaitForSystemTask()
    a2d.DialogOK()

    -- insert source
    a2dtest.WaitForAlert({match="Insert the source disk"})
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert({match="Insert the destination disk"})
    a2d.DialogOK()

    -- confirmation
    a2dtest.WaitForAlert({match="Are you sure"})
    a2d.DialogOK()

    -- complete
    a2dtest.WaitForAlert({timeout=7200, match="successful"})
    if what == "quick" then
      test.Snap("verify block counts are equal")
    else
      --[[
        BUG: MAME/CFFA2 will fail the read of the 512th block but
        successfully write it, expanding the size of the image and
        writing an arbitrary previously read block to it.
      ]]
      test.Snap("verify total block counts are 511")
    end
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2dtest.ConfigureForDeskTop()
    a2d.WaitForDesktopReady()
    a2dtest.WaitForAlert({match="2 volumes with the same name"})
    a2d.DialogOK()
    a2dtest.WaitForSystemTask()
end)
