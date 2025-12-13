--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl7 cffa2"
DISKARGS="-hard1 $HARDIMG -hard2 res/tests.hdv"

======================================== ENDCONFIG ]]--

--[[
  Launch DeskTop. Open a volume window. Apple Menu > Run Basic Here.
  Verify that `/RAM` exists.
]]--
test.Step(
  "/RAM exists",
  function()
    a2d.OpenPath("/A2.DESKTOP")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    a2d.WaitForRestart()
    apple2.TypeLine("CAT /RAM")
    emu.wait(1)
    test.Expect(apple2.GrabTextScreen():match("BLOCKS FREE"), "/RAM should exist")
    apple2.TypeLine("BYE")
    a2d.WaitForRestart()
    a2d.CloseAllWindows()
end)

--[[
  Launch DeskTop. Open a window for a volume that is not the startup
  disk. Apple Menu > Run Basic Here. Verify that the PREFIX is set
  correctly.
]]--
test.Step(
  "PREFIX set correctly",
  function()
    a2d.OpenPath("/TESTS")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    a2d.WaitForRestart()
    apple2.TypeLine("PREFIX")
    emu.wait(1)
    test.Expect(apple2.GrabTextScreen():match("/TESTS/"), "Prefix should be /TESTS/")
    apple2.TypeLine("BYE")
    a2d.WaitForRestart()
    a2d.CloseAllWindows()
end)

--[[
  Configure a system with a RAMCard. Launch DeskTop, ensure it copies
  itself to RAMCard. Ensure `BASIC.SYSTEM` is present on the startup
  disk. Open a window. Apple Menu > Run Basic Here. Verify that
  `BASIC.SYSTEM` starts.
]]--
test.Step(
  "Copied to RAMCard",
  function()
    a2d.ToggleOptionCopyToRAMCard() -- enable
    a2d.Reboot()

    a2d.OpenPath("/TESTS")
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.RUN_BASIC_HERE)
    a2d.WaitForRestart()
    test.Expect(apple2.GrabTextScreen():match("PRODOS BASIC"), "BASIC should start")
end)

