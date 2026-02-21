--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl1 ramfactor -sl2 ramfactor -sl4 ramfactor -sl5 ramfactor -sl6 ramfactor -sl7 cffa2 -aux rw3"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

-- TODO: See if we can get MAME to support 16MB RamWorks and RamFactor

test.Step(
  "Lots and lots of memory",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(5)
    test.Expect(a2dtest.OCRFrontWindowContent():match("Memory: 49,216K"), "memory count should be 49,216K")
end)
