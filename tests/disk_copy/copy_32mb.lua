--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl5 cffa2 -sl6 superdrive -aux ext80"
DISKARGS="-flop1 $HARDIMG -hard1 res/tests.hdv -hard2 res/empty_32mb.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

--[[
  Launch DeskTop. Special > Copy Disk.... Copy a 32MB disk image using
  Quick Copy (the default mode). Verify that the screen is not
  garbled, the progress bar updates correctly, and that the copy is
  successful.

  Launch DeskTop. Special > Copy Disk.... Copy a 32MB disk image using
  Disk Copy (the other mode). Verify that the screen is not garbled,
  the progress bar updates correctly, and that the copy is successful.
]]

test.Variants(
  {
    "Quick Copy 32MB",
    "Disk Copy 32MB",
  },
  function(idx)
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
    a2d.WaitForDesktopReady()

    a2d.InvokeMenuItem(3, idx) -- Options > Quick Copy or Disk Copy

    -- select source
    apple2.UpArrowKey() -- S5D2
    apple2.UpArrowKey() -- S5D1
    a2d.WaitForRepaint()
    a2d.DialogOK()

    -- select destination
    apple2.UpArrowKey() -- S5D2
    a2d.WaitForRepaint()
    a2d.DialogOK()

    -- insert source
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- insert destination
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- confirmation
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- Quick Copy - crashing to monitor!
    -- Disk Copy - trashing DHR screen!

    -- complete
    a2dtest.WaitForAlert()
    a2d.DialogOK()

    -- cleanup
    a2d.OAShortcut("Q") -- File > Quit
    a2d.WaitForDesktopReady()
end)



