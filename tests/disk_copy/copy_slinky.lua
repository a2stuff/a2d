--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 memexp -sl2 memexp -sl4 mouse -sl6 '' -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Copy /RAM1 to /RAM2. Verify success message at end.
]]
test.Variants(
  {
    "Slinky - Quick Copy",
    "Slinky - Disk Copy",
  },
  function(idx, name)
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
    a2dtest.WaitForAlert({timeout=240})
    test.Snap("verify success message copying S1D1 to S2D1")
    a2d.DialogOK()

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
    a2dtest.WaitForAlert() -- duplicate volumes
    a2d.DialogOK()
end)
