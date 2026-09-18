--[[
  Launch DeskTop, File > Quit, run `BASIC.SYSTEM`. Ensure `/RAM`
  exists.
]]
test.Step(
  "/RAM exists",
  function()
    desktop.Quit()
    apple2.WaitForBitsy()
    apple2.BitsyInvokePath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM")
    apple2.WaitForBasicSystem()
    apple2.TypeLine("CAT /RAM")
    util.WaitFor(
      "CAT output", function()
        return apple2.GrabTextScreen():match("BLOCKS FREE")
      end, {wait=1})
    apple2.TypeLine("BYE")
    apple2.WaitForBitsy()
    apple2.BitsyInvokePath("/A2.DESKTOP/DESKTOP.SYSTEM")
    a2d.WaitForDesktopReady()
end)

--[[
  File > Quit - verify that there is no crash under ProDOS 8.
]]
test.Step(
  "Can quit without crashing in ProDOS-8",
  function()
    desktop.Quit()
    apple2.WaitForBitsy()
    apple2.BitsyInvokePath("/A2.DESKTOP/DESKTOP.SYSTEM")
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Special > Copy Disk. Quit back to DeskTop. Invoke
  `BASIC.SYSTEM`. Ensure `/RAM` exists.
]]
test.Step(
  "/RAM exists after Disk Copy",
  function()
    desktop.CloseAllWindows()
    desktop.CopyDisk()
    a2d.OAShortcut("Q")
    a2d.WaitForDesktopReady()
    desktop.InvokePath("/A2.DESKTOP/EXTRAS/BASIC.SYSTEM", {no_wait=true})
    apple2.WaitForBasicSystem()
    apple2.TypeLine("CAT /RAM")
    util.WaitFor(
      "CAT output", function()
        return apple2.GrabTextScreen():match("BLOCKS FREE")
      end, {wait=1})
    apple2.TypeLine("BYE")
    a2d.WaitForDesktopReady()
end)

--[[
  Launch DeskTop. Invoke `EXTRAS/BINSCII`. Verify that the display is
  not truncated.
]]
test.Step(
  "text screen not truncated launching BINSCII",
  function()
    desktop.InvokePath("/A2.DESKTOP/EXTRAS/BINSCII", {no_wait=true})

    util.WaitFor(
      "BINSCII", function()
        local text = apple2.GrabTextScreen()
        return text:match("BinSCII") and text:match("Which")
      end, {wait=1})

    apple2.Type("Q")
    a2d.WaitForDesktopReady()
end)

--[[
  Preview an image file (e.g. SAMPLE.MEDIA/ROOM). Press Right Arrow to
  preview the next image. Press Escape to exit. Invoke a system file
  or binary file (e.g. KARATEKA.YELL). Verify it launches correctly
  with no crash.
]]
test.Step(
  "Invoking files after previewing",
  function()
    desktop.InvokePath("/A2.DESKTOP/SAMPLE.MEDIA/ROOM", {no_wait=true})
    emu.wait(10) -- full-screen DA
    apple2.RightArrowKey()
    emu.wait(10) -- full-screen DA
    apple2.EscapeKey()
    a2dtest.WaitForSystemTask()
    desktop.InvokePath("/A2.DESKTOP/SAMPLE.MEDIA/KARATEKA.YELL", {no_wait=true})
    a2d.WaitForDesktopReady()
    a2dtest.ExpectNotHanging()
end)

--[[
  Configure a system with a Mockingboard. Launch DeskTop. Open
  `AUTUMN.PT3` in the `SAMPLE.MEDIA` folder. Verify that the
  `PT3PLR.SYSTEM` player launches correctly and that it plays the
  selected song.
]]
test.Step(
  "Invoking PT3PLR",
  function()
    desktop.InvokePath("/A2.DESKTOP/SAMPLE.MEDIA/AUTUMN.PT3", {no_wait=true})
    util.WaitFor(
      "Song title", function()
        return apple2.GrabTextScreen():match("AuTumn")
      end, {wait=1})
    apple2.EscapeKey()
    a2d.WaitForDesktopReady()
end)
