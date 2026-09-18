--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 ramfactor -sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

--[[
  Configure a system with a RAMCard. Launch DeskTop, ensure it copies
  itself to RAMCard. Special > Copy Disk.... Verify that Disk Copy
  starts.
]]
test.Step(
  "Disk Copy works when copied to RAMCard",
  function()
    desktop.ToggleOptionCopyToRAMCard() -- Enable
    desktop.CloseAllWindows()
    desktop.Reboot()
    a2d.WaitForDesktopReady()

    desktop.CopyDisk()
    test.ExpectMatch(a2dtest.OCRScreen(), "Select source disk",
                "Disk Copy should be started")

    -- cleanup
    a2d.OAShortcut("Q")
    a2d.WaitForDesktopReady()
    desktop.ToggleOptionCopyToRAMCard() -- Disable
    desktop.Reboot()
    a2d.WaitForDesktopReady()
end)
