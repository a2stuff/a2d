--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl7 scsi -aux ext80"
DISKARGS="-hard1 $HARDIMG -flop1 $FLOP1IMG"

======================================== ENDCONFIG ]]--


--[[============================================================

  Test Script

  ============================================================]]--

test.Step(
  "Move Mouse",
  function()
    -- Move the mouse
    apple2.MoveMouse(480, 170)
    test.Snap("Mouse to 480,170")

    -- Move the mouse
    apple2.MoveMouse(0, 0)
    test.Snap("Mouse to 0,0")
end)

test.Step(
  "swap images",
  function()

    apple2.GetSCSIHD(7, 6):load("/Users/josh/dev/a2d/res/tests.hdv")
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_CHECK_ALL_DRIVES)
    a2d.WaitForRepaint()
    test.Snap("swapped hard1")

    apple2.GetDiskIIS6D1():unload()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_CHECK_ALL_DRIVES)
    a2d.WaitForRepaint()
    test.Snap("flop1 ejected")

    apple2.GetDiskIIS6D2():unload() -- harmless if already empty
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_CHECK_ALL_DRIVES)
    a2d.WaitForRepaint()
    test.Snap("flop2 ejected")
end)
