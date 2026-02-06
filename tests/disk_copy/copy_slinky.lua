--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 memexp -sl2 memexp -sl4 mouse -sl6 '' -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

local s6d1 = manager.machine.images[":sl6:cffa2:cffa2_ata:0:hdd:image"]
local s6d2 = manager.machine.images[":sl6:cffa2:cffa2_ata:1:hdd:image"]

--[[
  Copy /RAM1 to /RAM2. Verify success message at end.
]]
test.Variants(
  {
    {"Slinky - Quick Copy", "quick"},
    {"Slinky - Disk Copy", "disk"},
  },
  function(idx, name, what)
    if a2dtest.IsAlertShowing() then  -- duplicate volume
      a2d.DialogOK()
    end

    a2d.CopyDisk()

    a2d.InvokeMenuItem(3, idx) -- Quick Copy or Disk Cop

    -- select source
    apple2.UpArrowKey() -- S1D1
    a2d.DialogOK()

    -- select destination
    apple2.UpArrowKey() -- S1D1
    apple2.UpArrowKey() -- S2D1
    a2d.DialogOK()

    -- insert source
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- confirm overwrite
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- copying...
    a2dtest.WaitForAlert({timeout=7200})
    test.Expect(a2dtest.OCRScreen():find("The copy was successful"), "copy should succeed")
    local transfer, read, written = a2dtest.DiskCopyGetBlockCounts()
    local total = 2048
    test.ExpectEquals(read, transfer, "blocks read should match transfer count")
    test.ExpectEquals(written, transfer, "blocks written should match transfer count")
    if what == "quick" then
      test.ExpectLessThan(transfer, total, "block counts should be less than total blocks")
    else
      test.ExpectEquals(transfer, total, "block counts should be total blocks")
    end
    a2d.DialogOK()

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
    a2dtest.WaitForAlert() -- duplicate volumes
    a2d.DialogOK()
end)
